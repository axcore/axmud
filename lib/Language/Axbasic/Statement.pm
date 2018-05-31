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
# Language::Axbasic::Statement, based on Language::Basic by Amir Karger

{ package Language::Axbasic::Statement;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::ISA = qw(
        Language::Axbasic
    );

    # Sub-classes
    {
        package Language::Axbasic::Statement::addalias;
        package Language::Axbasic::Statement::addcongauge;
        package Language::Axbasic::Statement::addconstatus;
        package Language::Axbasic::Statement::addgauge;
        package Language::Axbasic::Statement::addhook;
        package Language::Axbasic::Statement::addmacro;
        package Language::Axbasic::Statement::addstatus;
        package Language::Axbasic::Statement::addtimer;
        package Language::Axbasic::Statement::addtrig;
        package Language::Axbasic::Statement::beep;
        package Language::Axbasic::Statement::break;
        package Language::Axbasic::Statement::bypass;
        package Language::Axbasic::Statement::call;
        package Language::Axbasic::Statement::case;
        package Language::Axbasic::Statement::client;
        package Language::Axbasic::Statement::cls;
        package Language::Axbasic::Statement::close;
        package Language::Axbasic::Statement::closewin;
        package Language::Axbasic::Statement::data;
        package Language::Axbasic::Statement::debug;
        package Language::Axbasic::Statement::def;
        package Language::Axbasic::Statement::delalias;
        package Language::Axbasic::Statement::delgauge;
        package Language::Axbasic::Statement::delhook;
        package Language::Axbasic::Statement::deliface;
        package Language::Axbasic::Statement::delmacro;
        package Language::Axbasic::Statement::delstatus;
        package Language::Axbasic::Statement::deltimer;
        package Language::Axbasic::Statement::deltrig;
        package Language::Axbasic::Statement::dim;
        package Language::Axbasic::Statement::do;
        package Language::Axbasic::Statement::else;
        package Language::Axbasic::Statement::emptywin;
        package Language::Axbasic::Statement::end;
        package Language::Axbasic::Statement::erase;
        package Language::Axbasic::Statement::error;
        package Language::Axbasic::Statement::exit;
        package Language::Axbasic::Statement::flashwin;
        package Language::Axbasic::Statement::for;
        package Language::Axbasic::Statement::global;
        package Language::Axbasic::Statement::gosub;
        package Language::Axbasic::Statement::goto;
        package Language::Axbasic::Statement::help;
        package Language::Axbasic::Statement::if;
        package Language::Axbasic::Statement::input;
        package Language::Axbasic::Statement::let;
        package Language::Axbasic::Statement::local;
        package Language::Axbasic::Statement::login;
        package Language::Axbasic::Statement::loop;
        package Language::Axbasic::Statement::move;
        package Language::Axbasic::Statement::multi;
        package Language::Axbasic::Statement::next;
        package Language::Axbasic::Statement::nextiface;
        package Language::Axbasic::Statement::on;
        package Language::Axbasic::Statement::open;
        package Language::Axbasic::Statement::openentry;
        package Language::Axbasic::Statement::openwin;
        package Language::Axbasic::Statement::option;
        package Language::Axbasic::Statement::paintwin;
        package Language::Axbasic::Statement::pause;
        package Language::Axbasic::Statement::peek;
        package Language::Axbasic::Statement::peekequals;
        package Language::Axbasic::Statement::peekexists;
        package Language::Axbasic::Statement::peekfind;
        package Language::Axbasic::Statement::peekfirst;
        package Language::Axbasic::Statement::peekget;
        package Language::Axbasic::Statement::peekindex;
        package Language::Axbasic::Statement::peekkeys;
        package Language::Axbasic::Statement::peeklast;
        package Language::Axbasic::Statement::peekmatch;
        package Language::Axbasic::Statement::peeknumber;
        package Language::Axbasic::Statement::peekpairs;
        package Language::Axbasic::Statement::peekpop;
        package Language::Axbasic::Statement::peekshift;
        package Language::Axbasic::Statement::peekshow;
        package Language::Axbasic::Statement::peekvalues;
        package Language::Axbasic::Statement::perl;
        package Language::Axbasic::Statement::play;
        package Language::Axbasic::Statement::poke;
        package Language::Axbasic::Statement::pokedec;
        package Language::Axbasic::Statement::pokedelete;
        package Language::Axbasic::Statement::pokedechash;
        package Language::Axbasic::Statement::pokeempty;
        package Language::Axbasic::Statement::pokefalse;
        package Language::Axbasic::Statement::pokeinc;
        package Language::Axbasic::Statement::pokeinchash;
        package Language::Axbasic::Statement::pokeint;
        package Language::Axbasic::Statement::pokeadd;
        package Language::Axbasic::Statement::pokedivide;
        package Language::Axbasic::Statement::pokeminus;
        package Language::Axbasic::Statement::pokemultiply;
        package Language::Axbasic::Statement::pokeplus;
        package Language::Axbasic::Statement::pokepush;
        package Language::Axbasic::Statement::pokereplace;
        package Language::Axbasic::Statement::pokeset;
        package Language::Axbasic::Statement::poketrue;
        package Language::Axbasic::Statement::pokeundef;
        package Language::Axbasic::Statement::pokeunshift;
        package Language::Axbasic::Statement::print;
        package Language::Axbasic::Statement::profile;
        package Language::Axbasic::Statement::read;
        package Language::Axbasic::Statement::redim;
        package Language::Axbasic::Statement::relay;
        package Language::Axbasic::Statement::rem;
        package Language::Axbasic::Statement::reset;
        package Language::Axbasic::Statement::restore;
        package Language::Axbasic::Statement::return;
        package Language::Axbasic::Statement::revpath;
        package Language::Axbasic::Statement::select;
        package Language::Axbasic::Statement::send;
        package Language::Axbasic::Statement::setgauge;
        package Language::Axbasic::Statement::setstatus;
        package Language::Axbasic::Statement::settrig;
        package Language::Axbasic::Statement::skipiface;
        package Language::Axbasic::Statement::sort;
        package Language::Axbasic::Statement::sortcase;
        package Language::Axbasic::Statement::sortcaser;
        package Language::Axbasic::Statement::sortr;
        package Language::Axbasic::Statement::speak;
        package Language::Axbasic::Statement::speed;
        package Language::Axbasic::Statement::stop;
        package Language::Axbasic::Statement::sub;
        package Language::Axbasic::Statement::titlewin;
        package Language::Axbasic::Statement::unflashwin;
        package Language::Axbasic::Statement::until;
        package Language::Axbasic::Statement::waitactive;
        package Language::Axbasic::Statement::waitalive;
        package Language::Axbasic::Statement::waitarrive;
        package Language::Axbasic::Statement::waitdead;
        package Language::Axbasic::Statement::waitep;
        package Language::Axbasic::Statement::waitgp;
        package Language::Axbasic::Statement::waithp;
        package Language::Axbasic::Statement::waitmp;
        package Language::Axbasic::Statement::waitnextxp;
        package Language::Axbasic::Statement::waitnotactive;
        package Language::Axbasic::Statement::waitpassout;
        package Language::Axbasic::Statement::waitscript;
        package Language::Axbasic::Statement::waitsleep;
        package Language::Axbasic::Statement::waitsp;
        package Language::Axbasic::Statement::waittask;
        package Language::Axbasic::Statement::waittotalxp;
        package Language::Axbasic::Statement::waittrig;
        package Language::Axbasic::Statement::waitxp;
        package Language::Axbasic::Statement::warning;
        package Language::Axbasic::Statement::while;
        package Language::Axbasic::Statement::write;
        package Language::Axbasic::Statement::writewin;
    }

    ##################
    # Constructors

    sub new {

        # Called by LA::Line->parse (or by the ->parse function of another LA::Statement::xxx
        #   object)
        # The class that handles the parsing of a single Axbasic statement
        # This function blesses itself, then calls $self->refine to decide what kind of statement it
        #   is (PRINT, LET, DATA, etc)
        # $self->refine creates a LA::Statement::<keyword> object, where <keyword> is the first
        #   keyword in the statement (matches an element in LA::Token->keywordList). <keyword> is
        #   set to the implied LET for a statement beginning with a variable.
        # This function then returns the blessed reference of the LA::Statement::<keyword> object (a
        #   subclass which inherits from this one)
        #
        # Expected arguments
        #   $scriptObj      - Blessed reference of the parent LA::Script
        #   $lineObj        - Blessed reference of the calling LA::Line
        #   $tokenGroupObj  - Blessed reference of the line's LA::TokenGroup
        #
        # Optional arguments
        #   $lineNumOk      - Set to 'line_num_ok' when called by LA::Statement::if, in situations
        #                       like 'IF ... THEN 20' in which case, this statement knows that the
        #                       'THEN 20' part should be parsed as 'THEN GOTO 20'. Otherwise, set to
        #                       'undef'
        #
        # Return values
        #   'undef' on improper arguments, or if the statement can't be parsed at all (i.e. doesn't
        #       begin with a keyword, including an implied LET), or begins with a 'weak' keyword
        #       like STEP (matching a key in LA::Script->weakKeywordHash)
        #   Blessed reference to the newly-created object on success

        my ($class, $scriptObj, $lineObj, $tokenGroupObj, $lineNumOk, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $scriptObj || ! defined $lineObj
            || ! defined $tokenGroupObj || (defined $lineNumOk && $lineNumOk ne 'line_num_ok')
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
            # Blessed reference of the calling LA::Line
            lineObj                     => $lineObj,
            # Blessed reference of the line's token group
            tokenGroupObj               => $tokenGroupObj,

            # IVs
            # ----

            # What kind of statement this is (set to <keyword> by the subclass)
            keyword                     => undef,
            # For keywords that are a synonym of another (e.g., SLEEP is a synonym of PAUSE) and for
            #   keywords that share an LA::Statement with another (e.g. ADDCONGAUGE shares code
            #   with ADDGAUGE), the keyword that was actually used when deciding which class of
            #   LA::Statement:: object to use
            # For all other keywords, $self->keyword is the same as $self->modKeyword
            modKeyword                  => undef,
            # The statement's status: 0 being parsed/implemented, 1 parsed/implemented, 2 parsed but
            #   caused an error
            status                      => 0,

            # Set by LA::Line->parse - blessed reference of the next statement in a single line, to
            #   be executed after this one (e.g. the 'print "hello" : print 'there" ' contains two
            #   statements)
            nextStatement               => undef,

            # The call to ->parse can sometimes create data which must be stored until the call to
            #   ->implement (if there is one). This data is stored in either of these two variables
            parseDataList               => [],
            parseDataHash               => {},

            # Defined if this statement is a 'then' statement, so that 'then 20' can be parsed as
            #   'then goto 20'
            lineNumOk                   => $lineNumOk,
        };

        bless $self, $class;

        # Create the subclass object
        if (! $self->refine()) {

            return undef;
        }

        # Return the subclass object, if it was created
        return $self;
    }

    sub refine {

        # Called by $self->new to bless a sub-class (see the comments for $self-new)
        # Reads the keyword the statement starts with - which might be an implied LET - and uses it
        #   to bless the sub-class
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or if there is an error
        #   Otherwise returns the blessed reference of the subclass

        my ($self, $check) = @_;

        # Local variables
        my ($token, $subClass, $keyword, $modKeyword);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->refine', @_);
        }

        # Get the first token from the statement
        $token = $self->tokenGroupObj->lookAhead();
        if (! defined $token) {

            if (! $self->tokenGroupObj->shortCommentFlag) {

                return $self->scriptObj->setDebug(
                    'Empty statement error',
                    $self->_objClass . '->refine',
                );

            } else {

                # First token on the line was ! (short comment token). Treat it like a REM
                #   statement
                $keyword = 'rem';
            }

        # If the first token is a recognised Axbasic keyword...
        } elsif ($token->category eq 'keyword') {

            # Check that it's not a weak keyword like STEP which isn't allowed to begin a statement
            if ($self->scriptObj->ivExists('weakKeywordHash', $token->tokenText)) {

                return $self->scriptObj->setError(
                    'statements_cannot_start_with_keyword_STRING',
                    $self->_objClass . '->refine',
                    'STRING', $token->tokenText,
                );

            } else {

                # Remove the token containing the keyword from the token group's token list
                #   (->lookAhead has already returned a defined value, so there's no need to check
                #   the return value of ->shiftToken)
                $self->tokenGroupObj->shiftToken();
                # Set $keyword to the keyword itself
                $keyword = $token->tokenText;

                # Check if this keyword is a synonym of another (e.g., SLEEP is a synonym of PAUSE)
                #   or if the keyword shares an LA::Statement with another (e.g. ADDCONGAUGE
                #   shares code with ADDGAUGE)
                if ($self->scriptObj->ivExists('equivKeywordHash', $keyword)) {

                    $modKeyword = $self->scriptObj->ivShow('equivKeywordHash', $keyword);
                }
            }

        # If the first token is a comment...
        } elsif ($token->category eq 'comment') {

            $keyword = 'rem';

        # If the first token is an implied 'let' keyword...
        } elsif ($token->category eq 'identifier') {

            # Are we allowed to use implied LETs?
            if (
                $self->scriptObj->ivShow('optionStatementHash', 'nolet')
                || $self->scriptObj->executionMode eq 'line_num'
            ) {
                $keyword = 'let';

            } else {

                return $self->scriptObj->setError(
                    'syntax_error',
                    $self->_objClass . '->refine',
                );
            }

        # If we're in a NEXT clause of an IF statement...
        } elsif (
            $self->lineNumOk
            && $token->category eq 'numeric_constant'
            && $token->tokenText =~ /^\d+$/
        ) {
            $keyword = 'goto';

        } else {

            # Statement doesn't start with a keyword, comment or variable
            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->refine',
            );
        }

        # Decide which sub-class to use
        if (! $modKeyword) {

            $modKeyword = $keyword;
        }

        $subClass = 'Language::Axbasic::Statement::' . $modKeyword;

        # Bless the subclass object into existence, replacing the blessed reference of the calling
        #   LA::Statement object (as explained in the comments for $self->new)
        bless $self, $subClass;

        # Store the statement type
        $self->ivPoke('keyword', $keyword);
        $self->ivPoke('modKeyword', $modKeyword);

        return $self;
    }

    ##################
    # Methods

    sub parse {

        # This generic ->parse function does nothing (it is inherited by LA::Statement::rem which
        #   doesn't have its own ->parse method)

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Do nothing
        return 1;
    }

    sub implement {

        # This generic ->implement function does nothing (it is inherited by LA::Statement::rem
        #   which doesn't have its own ->parse method)

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Do nothing
        return 1;
    }

    sub parsePeek {

        # Called by $self->parse for all PEEK... statements (including PEEK itself)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $forceFlag  - Set to TRUE for statements like PEEKKEYS, which use an Axbasic array
        #                   variable regardless of whether the statement is in the form
        #                   'PEEKKEYS var = string' or 'PEEKKEYS ARRAY var = string'. Set to FALSE
        #                   (or 'undef') for all other PEEK... statements
        #   $extraFlag  - Set to TRUE for statements like PEEKINDEX, which use an extra argument
        #                   at the end of the statement, which must be extracted and stored
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $forceFlag, $extraFlag, $check) = @_;

        # Local variables
        my ($token, $arrayFlag, $varName, $varObj, $result, $expression, $extraExp);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parsePeek', @_);
        }

        # Extract the optional ARRAY keyword
        $token = $self->tokenGroupObj->shiftMatchingToken('array');
        if ($token || $forceFlag) {
            $arrayFlag = TRUE;
        } else {
            $arrayFlag = FALSE;
        }

        # Extract a token comprising a whole variable identifier (e.g. A, a$, array)
        $token = $self->tokenGroupObj->shiftTokenIfCategory('identifier');
        if (! defined $token) {

            return $self->scriptObj->setError(
                'missing_or_illegal_variable',
                $self->_objClass . '->parse',
            );

        } else {

            $varName = $token->tokenText;

            # Look up the LA::Variable. Use the local variable, if it exists. Otherwise use the
            #   global variable, if it exists. Otherwise, create a global variable.
            # (If the user wants to PEEK a Perl list/hash into an Axbasic array that's a local
            #   variable, they can use a DIM LOCAL statement before this one)
            if (! $arrayFlag) {

                $self->scriptObj->set_declareMode('peek_scalar');
                $varObj = Language::Axbasic::Variable->lookup($self->scriptObj, $varName);

            } else {

                # If it's an array, ->lookup expects a LA::Expression::Arglist; but we only need to
                #   supply it with a defined value
                $self->scriptObj->set_declareMode('peek_array');
                $varObj = Language::Axbasic::Variable->lookup(
                    $self->scriptObj,
                    $varName,
                    'fake_arg_list'
                );
            }

            $self->scriptObj->set_declareMode('default');

            if (! $varObj) {

                # This shouldn't happen...
                return $self->scriptObj->setError(
                    'syntax_error',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Extract the assignment operator
        $result = $self->tokenGroupObj->shiftTokenIfCategory('assignment_operator');
        if (! defined $result) {

            return $self->scriptObj->setError(
                'missing_assignment_operator',
                $self->_objClass . '->parse',
            );
        }

        # The next token is either an expression representing an Axmud internal variable (a scalar,
        #   e.g. "current.world.name"; an array, e.g. "current.world.displayFormatList"; or a hash,
        #   e.g. "current.world.currencyHash")
        $token = $self->tokenGroupObj->lookAhead();
        if (! defined $token) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );

        } else {

            $expression = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $expression) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Save the array flag, variable object and expression object so $self->implement can use
        #   them, if it is called
        $self->ivAdd('parseDataHash', 'array_flag', $arrayFlag);
        $self->ivAdd('parseDataHash', 'var_name', $varName);
        $self->ivAdd('parseDataHash', 'expression', $expression);

        if ($extraFlag) {

            # This statement uses further, which must be extracted
            # Extract the comma
            if (! defined $self->tokenGroupObj->shiftMatchingToken(',')) {

                return $self->scriptObj->setError(
                    'syntax_error',
                    $self->_objClass . '->parse',
                );
            }

            # Extract the extra expression
            $token = $self->tokenGroupObj->lookAhead();
            if (! defined $token) {

                return $self->scriptObj->setError(
                    'syntax_error',
                    $self->_objClass . '->parse',
                );

            } else {

                $extraExp = Language::Axbasic::Expression::Arithmetic->new(
                    $self->scriptObj,
                    $self->tokenGroupObj,
                );

                if (! defined $extraExp) {

                    return $self->scriptObj->setError(
                        'missing_or_illegal_expression',
                        $self->_objClass . '->parse',
                    );
                }
            }

            # Save the extra expression object so $self->implement can use it, if it is called
            $self->ivAdd('parseDataHash', 'extra_exp', $extraExp);
        }

        # There should be nothing after the expression
        if (defined $self->tokenGroupObj->lookAhead()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Initial parsing complete
        return 1;
    }

    sub parsePoke {

        # Called by $self->parse for many POKE... statements (but not POKE itself)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $number   - The number of expressions to extract, after the first (compulsory) one. An
        #                   integer, 0 or above (or 'undef' to extract no optional expressions)
        #   $max        - The maximum number or expressions to extract, after the first (compulsory)
        #                   one. If defined, $number must be defined too, and $number represents
        #                   the minimum. Set to 'undef' if the maximum number is the same as the
        #                   minimum (or if no optional expressions are to be extracted)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $number, $max, $check) = @_;

        # Local variables
        my (
            $token, $varExp,
            @expList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parsePoke', @_);
        }

        # The first token is either an expression representing an Axmud internal variable (a scalar,
        #   e.g. "current.world.name"; an array, e.g. "current.world.displayFormatList"; or a hash,
        #   e.g. "current.world.currencyHash")
        $token = $self->tokenGroupObj->lookAhead();
        if (! defined $token) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );

        } else {

            $varExp = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $varExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # (Extract expressions, even if the minimum is 0 and the maximum is 1)
        if ($number || $max) {

            if (! defined $max) {

                # Minimum and maximum number of expressions is the same
                $max = $number;

            } elsif ($number > $max) {

                # Emergency failsafe to prevent infinite loops
                $number = $max;
            }

            # Extract expressions until there are none left
            OUTER: for (my $count = 1; $count <= $max; $count++) {

                my $expression;

                if (! defined $self->tokenGroupObj->shiftMatchingToken(',')) {

                    if ($count > $number) {

                        # We have at least the minimum number of expressions we need
                        last OUTER;

                    } else {

                        return $self->scriptObj->setError(
                            'syntax error',
                            $self->_objClass . '->parse',
                        );
                    }
                }

                $expression = Language::Axbasic::Expression::Constant->new(
                    $self->scriptObj,
                    $self->tokenGroupObj,
                );

                if (! defined $expression) {

                    return $self->scriptObj->setError(
                        'missing_or_illegal_expression',
                        $self->_objClass . '->parse',
                    );

                } else {

                    push (@expList, $expression);
                }
            }
        }

        # There are no further expressions to extract
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Save the expressions so $self->implement can use them, if it is called
        $self->ivAdd('parseDataHash', 'var_exp', $varExp);
        $self->ivPoke('parseDataList', @expList);

        # Initial parsing complete
        return 1;
    }

    sub fetchVar {

        # Called by $self->parse for most PEEK... statements (including PEEK itself)
        # Looks up an Axbasic scalar variable or array, calling $self->scriptObj->setError if the
        #   variable can't be found
        #
        # Expected arguments
        #   $statement  - The statement keyword, e.g. 'PEEK'
        #   $varName    - The name of the variable, e.g. 'var$'
        #
        # Optional arguments
        #   $arrayFlag  - Flag set to TRUE if the ARRAY keyword was also used (e.g. PEEK ARRAY); set
        #                   to FALSE (or 'undef') if not
        #
        # Return values
        #   'undef' on improper arguments or the variable can't be found
        #   Otherwise, returns the LA::Variable object

        my ($self, $statement, $varName, $arrayFlag, $check) = @_;

        # Local variables
        my $varObj;

        # Check for improper arguments
        if (! defined $statement || ! defined $varName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->fetchVar', @_);
        }

        # Look up the LA::Variable
        if (! $arrayFlag) {

            $varObj = Language::Axbasic::Variable->lookup($self->scriptObj, $varName);

        } else {

            # If it's an array, ->lookup expects a LA::Expression::Arglist; but we only need to
            #   supply it with a defined value
            $varObj = Language::Axbasic::Variable->lookup(
                $self->scriptObj,
                $varName,
                'fake_arg_list'
            );
        }

        if (! $varObj) {

            # This shouldn't happen...
            return $self->scriptObj->setError(
                $statement . '_operation_failure',
                $self->_objClass . '->implement',
            );

        } else {

            return $varObj;
        }
    }

    sub importAsScalar {

        # Called by $self->parse for all PEEK... statements (including PEEK itself)
        # Sets the value of an Axbasic scalar variable, converting Perl 'undef' to an Axbasic string
        #   or numeric value, as required
        #
        # Expected arguments
        #   $varObj     - A LA::Variable::Array object
        #
        # Optional arguments
        #   $scalar     - A value to store in the Axbasic scalar variable (may be 'undef')

        my ($self, $varObj, $scalar) = @_;

        # Check for improper arguments
        if (! defined $varObj) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->importAsScalar', @_);
        }

        # Perl 'undef' values are converted to Axbasic strings "<<undef>>" or the number 0
        if (defined $scalar) {
            $varObj->set($scalar);
        } elsif (ref($varObj) =~ m/Numeric/) {
            $varObj->set(0);
        } else {
            $varObj->set('<<undef>>');
        }

        # Do nothing
        return 1;
    }

    sub importAsArray {

        # Called by $self->parse for all PEEK... statements (including PEEK itself)
        # Replaces the contents of an Axbasic array variable with a Perl list, redimensioning the
        #   array as required
        #
        # Expected arguments
        #   $varObj     - A LA::Variable::Array object
        #
        # Optional arguments
        #   @array      - A list of values to put into the Axbasic array (can be an empty list)

        my ($self, $varObj, @array) = @_;

        # Local variables
        my (
            $count,
            @cellList,
        );

        # Check for improper arguments
        if (! defined $varObj) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->importAsArray', @_);
        }

        # Re-dimension the array to match the size of @array
        $varObj->dimension(scalar @array);

        # Set each element in the Axbasic array to match the values of the elements in the Axmud
        #   list/hash
        @cellList = $varObj->cellList;
        # Axbasic arrays don't use element 0, so dispense with the unusable $cellList[0]
        shift @cellList;
        # (But the first element of @array that we want is, of course, element 0)
        $count = -1;

        foreach my $arrayVar (@cellList) {

            $count++;

            # Perl 'undef' values are converted to Axbasic strings "<<undef>>" or the number 0
            if (defined $array[$count]) {
                $arrayVar->set($array[$count]);
            } elsif (ref($varObj) =~ m/Numeric/) {
                $arrayVar->set(0);
            } else {
                $arrayVar->set("<<undef>>");
            }
        }

        # Do nothing
        return 1;
    }

    ##################
    # Accessors - set

    sub set_nextStatement {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_nextStatement', @_);
        }

        # Update IVs
        $self->ivPoke('nextStatement', $obj);

        return 1;
    }

    sub add_parseDataHash {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $string, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $string || ! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_parseDataHash', @_);
        }

        # Update IVs
        $self->ivAdd('parseDataHash', $string, $obj);

        return 1;
    }

    sub push_parseDataList {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->push_parseDataList', @_);
        }

        # Update IVs
        $self->ivPush('parseDataList', $obj);

        return 1;
    }

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }
    sub lineObj
        { $_[0]->{lineObj} }
    sub tokenGroupObj
        { $_[0]->{tokenGroupObj} }

    sub keyword
        { $_[0]->{keyword} }
    sub modKeyword
        { $_[0]->{modKeyword} }
    sub status
        { $_[0]->{status} }

    sub nextStatement
        { $_[0]->{nextStatement} }

    sub parseDataList
        { my $self = shift; return @{$self->{parseDataList}}; }
    sub parseDataHash
        { my $self = shift; return %{$self->{parseDataHash}}; }

    sub lineNumOk
        { $_[0]->{lineNumOk} }
}

{ package Language::Axbasic::Statement::addalias;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::addalias::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # ADDALIAS expression , expression [ , expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($stimulusExp, $responseExp, $nameExp, $token);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the stimulus and response strings into expressions
        $stimulusExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $stimulusExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        if (! defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );
        }

        $responseExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $responseExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Get the alias name, if specified
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $token = $self->tokenGroupObj->lookAhead();
            if (defined $token) {

                $nameExp = Language::Axbasic::Expression::Arithmetic->new(
                    $self->scriptObj,
                    $self->tokenGroupObj,
                );

                if (! defined $nameExp) {

                    return $self->scriptObj->setError(
                        'missing_or_illegal_expression',
                        $self->_objClass . '->parse',
                    );
                }
            }
        }

        # Check that nothing follows the expressions
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expressions, so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'stimulus', $stimulusExp);
        $self->ivAdd('parseDataHash', 'response', $responseExp);
        # (If the third expession wasn't specified, $name will be 'undef'
        $self->ivAdd('parseDataHash', 'name', $nameExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $stimulusExp, $stimulus, $responseExp, $response, $nameExp, $name, $string, $profile,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the arguments stored by $self->parse
        $stimulusExp = $self->ivShow('parseDataHash', 'stimulus');
        $responseExp = $self->ivShow('parseDataHash', 'response');
        $nameExp = $self->ivShow('parseDataHash', 'name');  # May be 'undef'

        # Evaluate each expression
        $stimulus = $stimulusExp->evaluate();
        $response = $responseExp->evaluate();
        if (defined $nameExp) {

            $name = $nameExp->evaluate();
        }

        # Specify which profile to use
        if (defined $self->scriptObj->useProfile) {
            $profile = $self->scriptObj->useProfile;
        } else {
            $profile = $self->scriptObj->session->currentWorld->name;
        }

        # Prepare the client command
        $string = 'addalias -s <' . $stimulus . '> -p <' . $response . '> -d ' . $profile;
        if ($name) {

            $string .= ' -n <' . $name . '>';
        }

        # Send the command
        if ($self->scriptObj->session->pseudoCmd($string, $self->scriptObj->pseudoCmdMode)) {

            # Alias created successfully. Update the LA::Script IVs
            if (! $name) {

                # GA::Generic::Cmd->addInterface uses the stimulus as a name, if no name is
                #   specified
                $name = $stimulus;
            }

            $self->scriptObj->push_indepInterfaceList($name, $profile, 'alias');
            $self->scriptObj->set_indepInterfaceName($name);

        } else {

            # Store the fact that creation of the alias failed
            $self->scriptObj->set_indepInterfaceName(undef);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::addgauge;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::addgauge::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # ADDGAUGE expression , expression [ , expression ] [ , expression ] [ , expression ]
    # ADDCONGAUGE expression , expression [ , expression ] [ , expression ] [ , expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($numberExp, $labelExp, $fullColExp, $emptyColExp, $labelColExp, $token);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the compulsory arguments into expressions
        $numberExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $numberExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        if (! defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );
        }

        $labelExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $labelExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Get the optional arguments, if specified
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $token = $self->tokenGroupObj->lookAhead();
            if (defined $token) {

                $fullColExp = Language::Axbasic::Expression::Arithmetic->new(
                    $self->scriptObj,
                    $self->tokenGroupObj,
                );

                if (! defined $fullColExp) {

                    return $self->scriptObj->setError(
                        'missing_or_illegal_expression',
                        $self->_objClass . '->parse',
                    );
                }
            }
        }

        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $token = $self->tokenGroupObj->lookAhead();
            if (defined $token) {

                $emptyColExp = Language::Axbasic::Expression::Arithmetic->new(
                    $self->scriptObj,
                    $self->tokenGroupObj,
                );

                if (! defined $emptyColExp) {

                    return $self->scriptObj->setError(
                        'missing_or_illegal_expression',
                        $self->_objClass . '->parse',
                    );
                }
            }
        }

        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $token = $self->tokenGroupObj->lookAhead();
            if (defined $token) {

                $labelColExp = Language::Axbasic::Expression::Arithmetic->new(
                    $self->scriptObj,
                    $self->tokenGroupObj,
                );

                if (! defined $labelColExp) {

                    return $self->scriptObj->setError(
                        'missing_or_illegal_expression',
                        $self->_objClass . '->parse',
                    );
                }
            }
        }

        # Check that nothing follows the expressions
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expressions, so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'number', $numberExp);
        $self->ivAdd('parseDataHash', 'label', $labelExp);
        $self->ivAdd('parseDataHash', 'full_col', $fullColExp);         # 'undef' if not specified
        $self->ivAdd('parseDataHash', 'empty_col', $emptyColExp);       # 'undef' if not specified
        $self->ivAdd('parseDataHash', 'label_col', $labelColExp);       # 'undef' if not specified

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $numberExp, $labelExp, $fullColExp, $emptyColExp, $labelColExp, $number, $label,
            $fullCol, $emptyCol, $labelCol, $addFlag,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Retrieve the arguments stored by $self->parse
        $numberExp = $self->ivShow('parseDataHash', 'number');
        $labelExp = $self->ivShow('parseDataHash', 'label');
        $fullColExp = $self->ivShow('parseDataHash', 'full_col');       # May be 'undef'
        $emptyColExp = $self->ivShow('parseDataHash', 'empty_col');     # May be 'undef'
        $labelColExp = $self->ivShow('parseDataHash', 'label_col');     # May be 'undef'

        # Evaluate each expression
        $number = $numberExp->evaluate();
        $label = $labelExp->evaluate();
        if (defined $fullColExp) {

            $fullCol = $fullColExp->evaluate();
        }

        if (defined $emptyColExp) {

            $emptyCol = $emptyColExp->evaluate();
        }

        if (defined $labelColExp) {

            $labelCol = $labelColExp->evaluate();
        }

        # Check that the gauge number and label are valid. $number must be an integer, >= 0
        if ($number =~ m/\D/ || $number < 0) {

            return $self->scriptObj->setError(
                'invalid_gauge_number',
                $self->_objClass . '->implement',
            );
        }

        # Tell the Script task to add the gauge
        if ($self->keyword eq 'addcongauge') {
            $addFlag = TRUE;
        } else {
            $addFlag = FALSE;
        }

        $self->scriptObj->parentTask->addGauge(
            $number,
            $label,
            $addFlag,
            $fullCol,
            $emptyCol,
            $labelCol,
        );

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::addstatus;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::addstatus::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # ADDSTATUS expression , expression
    # ADDCONSTATUS expression , expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($numberExp, $labelExp, $token);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the compulsory arguments into expressions
        $numberExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $numberExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        if (! defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );
        }

        $labelExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $labelExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Check that nothing follows the expressions
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expressions, so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'number', $numberExp);
        $self->ivAdd('parseDataHash', 'label', $labelExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($numberExp, $labelExp, $number, $label, $addFlag);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Retrieve the arguments stored by $self->parse
        $numberExp = $self->ivShow('parseDataHash', 'number');
        $labelExp = $self->ivShow('parseDataHash', 'label');

        # Evaluate each expression
        $number = $numberExp->evaluate();
        $label = $labelExp->evaluate();

        # Check that the status bar number and label are valid. $number must be an integer, >= 0
        if ($number =~ m/\D/ || $number < 0) {

            return $self->scriptObj->setError(
                'invalid_status_bar_number',
                $self->_objClass . '->implement',
            );
        }

        # Tell the Script task to add the status bar
        if ($self->keyword eq 'addconstatus') {
            $addFlag = TRUE;
        } else {
            $addFlag = FALSE;
        }

        $self->scriptObj->parentTask->addStatusBar(
            $number,
            $label,
            $addFlag,
        );

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::addhook;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::addhook::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # ADDHOOK expression , expression [ , expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($stimulusExp, $responseExp, $nameExp, $token);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the stimulus and response strings into expressions
        $stimulusExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $stimulusExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        if (! defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );
        }

        $responseExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $responseExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Get the hook name, if specified
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $token = $self->tokenGroupObj->lookAhead();
            if (defined $token) {

                $nameExp = Language::Axbasic::Expression::Arithmetic->new(
                    $self->scriptObj,
                    $self->tokenGroupObj,
                );

                if (! defined $nameExp) {

                    return $self->scriptObj->setError(
                        'missing_or_illegal_expression',
                        $self->_objClass . '->parse',
                    );
                }
            }
        }

        # Check that nothing follows the expressions
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expressions, so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'stimulus', $stimulusExp);
        $self->ivAdd('parseDataHash', 'response', $responseExp);
        # (If the third expession wasn't specified, $name will be 'undef'
        $self->ivAdd('parseDataHash', 'name', $nameExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $stimulusExp, $stimulus, $responseExp, $response, $nameExp, $name, $string, $profile,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the arguments stored by $self->parse
        $stimulusExp = $self->ivShow('parseDataHash', 'stimulus');
        $responseExp = $self->ivShow('parseDataHash', 'response');
        $nameExp = $self->ivShow('parseDataHash', 'name');      # May be 'undef'

        # Evaluate each expression
        $stimulus = $stimulusExp->evaluate();
        $response = $responseExp->evaluate();
        if (defined $nameExp) {

            $name = $nameExp->evaluate();
        }

        # Specify which profile to use
        if (defined $self->scriptObj->useProfile) {
            $profile = $self->scriptObj->useProfile;
        } else {
            $profile = $self->scriptObj->session->currentWorld->name;
        }

        # Prepare the client command
        $string = 'addhook -s <' . $stimulus . '> -p <' . $response . '> -d ' . $profile;
        if ($name) {

            $string .= ' -n <' . $name . '>';
        }

        # Send the command
        if ($self->scriptObj->session->pseudoCmd($string, $self->scriptObj->pseudoCmdMode)) {

            # Hook created successfully. Update the LA::Script IVs
            if (! $name) {

                # GenericCommand->addHookEtc uses the stimulus as a name, if no name is specified
                $name = $stimulus;
            }

            $self->scriptObj->push_indepInterfaceList($name, $profile, 'hook');
            $self->scriptObj->set_indepInterfaceName($name);


        } else {

            # Store the fact that creation of the hook failed
            $self->scriptObj->set_indepInterfaceName(undef);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::addmacro;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::addmacro::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # ADDMACRO expression , expression [ , expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($stimulusExp, $responseExp, $nameExp, $token);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the stimulus and response strings into expressions
        $stimulusExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $stimulusExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        if (! defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );
        }

        $responseExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $responseExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Get the macro name, if specified
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $token = $self->tokenGroupObj->lookAhead();
            if (defined $token) {

                $nameExp = Language::Axbasic::Expression::Arithmetic->new(
                    $self->scriptObj,
                    $self->tokenGroupObj,
                );

                if (! defined $nameExp) {

                    return $self->scriptObj->setError(
                        'missing_or_illegal_expression',
                        $self->_objClass . '->parse',
                    );
                }
            }
        }

        # Check that nothing follows the expressions
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expressions, so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'stimulus', $stimulusExp);
        $self->ivAdd('parseDataHash', 'response', $responseExp);
        # (If the third expession wasn't specified, $name will be 'undef'
        $self->ivAdd('parseDataHash', 'name', $nameExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $stimulusExp, $stimulus, $responseExp, $response, $nameExp, $name, $string, $profile,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the arguments stored by $self->parse
        $stimulusExp = $self->ivShow('parseDataHash', 'stimulus');
        $responseExp = $self->ivShow('parseDataHash', 'response');
        $nameExp = $self->ivShow('parseDataHash', 'name');          # May be 'undef'

        # Evaluate each expression
        $stimulus = $stimulusExp->evaluate();
        $response = $responseExp->evaluate();
        if (defined $nameExp) {

            $name = $nameExp->evaluate();
        }

        # Specify which profile to use
        if (defined $self->scriptObj->useProfile) {
            $profile = $self->scriptObj->useProfile;
        } else {
            $profile = $self->scriptObj->session->currentWorld->name;
        }

        # Prepare the client command
        $string = 'addmacro -s <' . $stimulus . '> -p <' . $response . '> -d ' . $profile;
        if ($name) {

            $string .= ' -n <' . $name . '>';
        }

        # Send the command
        if ($self->scriptObj->session->pseudoCmd($string, $self->scriptObj->pseudoCmdMode)) {

            # Macro created successfully. Update the LA::Script IVs
            if (! $name) {

                # GA::Generic::Cmd->addInterface uses the stimulus as a name, if no name is
                #   specified
                $name = $stimulus;
            }

            $self->scriptObj->push_indepInterfaceList($name, $profile, 'macro');
            $self->scriptObj->set_indepInterfaceName($name);

        } else {

            # Store the fact that creation of the macro failed
            $self->scriptObj->set_indepInterfaceName(undef);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::addtimer;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::addtimer::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # ADDTIMER expression , expression [ , expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($stimulusExp, $responseExp, $nameExp, $token);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the interval and action strings into expressions
        $stimulusExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $stimulusExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        if (! defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );
        }

        $responseExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $responseExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Get the timer name, if specified
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $token = $self->tokenGroupObj->lookAhead();
            if (defined $token) {

                $nameExp = Language::Axbasic::Expression::Arithmetic->new(
                    $self->scriptObj,
                    $self->tokenGroupObj,
                );

                if (! defined $nameExp) {

                    return $self->scriptObj->setError(
                        'missing_or_illegal_expression',
                        $self->_objClass . '->parse',
                    );
                }
            }
        }

        # Check that nothing follows the expressions
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expressions, so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'stimulus', $stimulusExp);
        $self->ivAdd('parseDataHash', 'response', $responseExp);
        # (If the third expession wasn't specified, $name will be 'undef'
        $self->ivAdd('parseDataHash', 'name', $nameExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $stimulusExp, $stimulus, $responseExp, $response, $nameExp, $name, $string, $profile,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the arguments stored by $self->parse
        $stimulusExp = $self->ivShow('parseDataHash', 'stimulus');
        $responseExp = $self->ivShow('parseDataHash', 'response');
        $nameExp = $self->ivShow('parseDataHash', 'name');  # May be 'undef'

        # Evaluate each expression
        $stimulus = $stimulusExp->evaluate();
        $response = $responseExp->evaluate();
        if (defined $nameExp) {

            $name = $nameExp->evaluate();
        }

        # Specify which profile to use
        if (defined $self->scriptObj->useProfile) {
            $profile = $self->scriptObj->useProfile;
        } else {
            $profile = $self->scriptObj->session->currentWorld->name;
        }

        # Prepare the client command
        $string = 'addtimer -s <' . $stimulus . '> -p <' . $response . '> -d ' . $profile;
        if ($name) {

            $string .= ' -n <' . $name . '>';
        }

        # Send the command
        if ($self->scriptObj->session->pseudoCmd($string, $self->scriptObj->pseudoCmdMode)) {

            # Timer created successfully. Update the LA::Script IVs
            if (! $name) {

                # GA::Generic::Cmd->addInterface uses the stimulus as a name, if no name is
                #   specified
                $name = $stimulus;
            }

            $self->scriptObj->push_indepInterfaceList($name, $profile, 'timer');
            $self->scriptObj->set_indepInterfaceName($name);

        } else {

            # Store the fact that creation of the timer failed
            $self->scriptObj->set_indepInterfaceName(undef);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::addtrig;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::addtrig::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # ADDTRIG expression , expression [ , expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($stimulusExp, $responseExp, $nameExp, $token);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the pattern and action strings into expressions
        $stimulusExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $stimulusExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        if (! defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );
        }

        $responseExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $responseExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Get the trigger name, if specified
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $token = $self->tokenGroupObj->lookAhead();
            if (defined $token) {

                $nameExp = Language::Axbasic::Expression::Arithmetic->new(
                    $self->scriptObj,
                    $self->tokenGroupObj,
                );

                if (! defined $nameExp) {

                    return $self->scriptObj->setError(
                        'missing_or_illegal_expression',
                        $self->_objClass . '->parse',
                    );
                }
            }
        }

        # Check that nothing follows the expressions
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expressions, so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'stimulus', $stimulusExp);
        $self->ivAdd('parseDataHash', 'response', $responseExp);
        # (If the third expession wasn't specified, $name will be 'undef'
        $self->ivAdd('parseDataHash', 'name', $nameExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $stimulusExp, $stimulus, $responseExp, $response, $nameExp, $name, $string, $profile,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the arguments stored by $self->parse
        $stimulusExp = $self->ivShow('parseDataHash', 'stimulus');
        $responseExp = $self->ivShow('parseDataHash', 'response');
        $nameExp = $self->ivShow('parseDataHash', 'name');          # May be 'undef'

        # Evaluate each expression
        $stimulus = $stimulusExp->evaluate();
        $response = $responseExp->evaluate();
        if (defined $nameExp) {

            $name = $nameExp->evaluate();
        }

        # Specify which profile to use
        if (defined $self->scriptObj->useProfile) {
            $profile = $self->scriptObj->useProfile;
        } else {
            $profile = $self->scriptObj->session->currentWorld->name;
        }

        # Prepare the client command
        $string = 'addtrigger -s <' . $stimulus . '> -p <' . $response . '> -d ' . $profile;
        if ($name) {

            $string .= ' -n <' . $name . '>';
        }

        # Send the command
        if ($self->scriptObj->session->pseudoCmd($string, $self->scriptObj->pseudoCmdMode)) {

            # Trigger created successfully. Update the LA::Script IVs
            if (! $name) {

                # GA::Generic::Cmd->addInterface uses the stimulus as a name, if no name is
                #   specified
                $name = $stimulus;
            }

            $self->scriptObj->push_indepInterfaceList($name, $profile, 'trigger');
            $self->scriptObj->set_indepInterfaceName($name);

        } else {

            # Store the fact that creation of the trigger failed
            $self->scriptObj->set_indepInterfaceName(undef);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::beep;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::beep::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # BEEP

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # BEEP statements always appear on their own
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Check that the sound effect exists
        if (
            ! $axmud::CLIENT->ivExists('customSoundHash', 'beep')
            || ! $axmud::CLIENT->ivShow('customSoundHash', 'beep')
        ) {
            return $self->scriptObj->setError(
                'beep_not_available',
                $self->_objClass . '->implement',
            );

        } else {

            # Play the sound effect (if allowed)
            $axmud::CLIENT->playSound('beep');
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::break;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::break::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # BREAK

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # BREAK statements always appear on their own
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script is being run from within an Axmud task, pause execution until the
        #   next task loop. Otherwise, do nothing
        if ($self->scriptObj->parentTask) {

            $self->scriptObj->set_scriptStatus('paused');

            # Reset the number of steps to take, before taking an automatic pause
            $self->scriptObj->set_stepCount(0);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::bypass;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::bypass::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # BYPASS expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the expression and store it for ->implement to use
        $expression = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );

        } else {

            $self->ivAdd('parseDataHash', 'expression', $expression);
        }

        # There should be nothing after the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression, $string);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the expression to be written
        $expression = $self->ivShow('parseDataHash', 'expression');
        # Evaluate the expression to get a scalar value
        $string = $expression->evaluate();

        # Execute the expression as a bypass command
        $self->scriptObj->session->worldCmd($string, undef, undef, TRUE);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::call;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::call::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # CALL subroutine-name ( [ expression [ , expression ... ] ] )

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $letStatement   - When this function is called from within a LET statement,
        #                       i.e. 'LET a$ = CALL func_name (arg$)', which LET statement called
        #                       this one
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $letStatement, $check) = @_;

        # Local variables
        my ($subNameToken, $subName, $argListObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # If $letStatement was specified, use it
        if ($letStatement) {

            $self = $letStatement;
        }

        # The 'call' keyword is not available in primitive numbering mode
        if ($self->scriptObj->executionMode ne 'no_line_num') {

            return $self->scriptObj->setError(
                'statement_not_available_with_line_numbers',
                $self->_objClass . '->parse',
            );
        }

        # Check there's a subroutine name to be got...
        if (defined $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unspecified_subroutine',
                $self->_objClass . '->parse',
            );
        }

        # Get the subroutine name
        $subNameToken = $self->tokenGroupObj->shiftToken();
        if (! defined $subNameToken) {

            return $self->scriptObj->setError(
                'unspecified_subroutine',
                $self->_objClass . '->parse',
            );
        }

        # Get an argument list
        $argListObj = Language::Axbasic::Expression::ArgList->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $argListObj) {

            return $self->scriptObj->setError(
                'missing_or_invalid_argument_list',
                $self->_objClass . '->parse',
            );
        }

        # Check that there is nothing after the list of arguments (except for the statement
        #   separator, : )
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the subroutine name and its argument list for ->implement to use
        $self->ivAdd('parseDataHash', 'sub_name', $subNameToken->tokenText);
        $self->ivAdd('parseDataHash', 'arg_list_obj', $argListObj);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $letStatement   - When this function is called from within a LET statement,
        #                       i.e. 'LET a$ = CALL func_name (arg$)', which LET statement called
        #                       this one
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $letStatement, $check) = @_;

        # Local variables
        my (
            $returnVar, $subName, $argListObj, $subObj, $declareStatement,
            @callArgList, @subArgList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If $letStatement was specified, use it
        if ($letStatement) {

            $self = $letStatement;
            # The subroutine's return value must be assigned to this variable
            $returnVar = $self->ivShow('parseDataHash', 'call_var');
        }

        # Retrieve the variables stored by ->parse
        $subName = $self->ivShow('parseDataHash', 'sub_name');
        $argListObj = $self->ivShow('parseDataHash', 'arg_list_obj');

        # Check that a subroutine with the same name has been declared
        if (! $self->scriptObj->ivExists('subNameHash', $subName)) {

            return $self->scriptObj->setError(
                'no_such_function_or_subroutine',
                $self->_objClass . '->implement',
            );

        } else {

            $subObj = $self->scriptObj->ivShow('subNameHash', $subName);
        }

        # We need to check that the arguments specified in the CALL statement are of the same
        #   number, and of the same type, as the arguments specified in the subroutine declaration
        @callArgList = $argListObj->argList;
        @subArgList = $subObj->argListObj->argList;

        # Check that there are the right number of arguments
        if ((scalar @callArgList) != (scalar @subArgList)) {

            return $self->scriptObj->setError(
                'wrong_number_of_arguments',
                $self->_objClass . '->implement',
            );
        }

        # Check that each argument is of the right type
        if (@callArgList) {

            for (my $count = 0; $count < scalar @callArgList; $count++) {

                my $value = $callArgList[$count]->evaluate();

                if (
                    ref($subArgList[$count]) =~ m/Numeric/
                    && ! Scalar::Util::looks_like_number($value)
                ) {
                    return $self->scriptObj->setError(
                        'type_mismatch_error',
                        $self->_objClass . '->implement',
                    );
                }
            }
        }

        # Make sure the subroutine's local variable and code block stores are empty
        $subObj->set_localScalarHash();
        $subObj->set_localArrayHash();
        $subObj->set_blockStackList();
        # Set the variable that will be assigned the subroutine's return value
        if ($returnVar) {

            $subObj->set_returnVar($returnVar);

        } else {

            # Empty a variable from any previous call
            $subObj->set_returnVar(undef);
        }

        # Evaluate each argument in the CALL statement's argument list, then create local variables
        #   in the subroutine initialised with those values
        if (@callArgList) {

            for (my $count = 0; $count < scalar @callArgList; $count++) {

                my ($callArg, $value, $subArg);

                $callArg = $callArgList[$count];
                $value = $callArg->evaluate();

                $subArg = $subArgList[$count];
                $subArg->variable->set($value);

                # Initialise local variable $subArg->varName (e.g. name$) with $value
                $subObj->add_localScalar($subArg->varName, $subArg);
            }
        }

        # Execution will shortly at the first statement after the SUB declaration statement
        $declareStatement = $subObj->declareStatement;

        # The next statement to execute is the statement after that
        if (defined $declareStatement->nextStatement) {

            $self->scriptObj->set_nextStatement($declareStatement->nextStatement);
            $self->scriptObj->set_nextLine($declareStatement->lineObj->procLineNum);

        } else {

            $self->scriptObj->set_nextStatement(undef);
            $self->scriptObj->set_nextLine($declareStatement->lineObj->procLineNum + 1);
        }

        # At the end of the subroutine, execution will continue at the first statement after this
        #   one
        $subObj->set_callStatement($self);

        # Add this subroutine to the script's subroutine stack
        $self->scriptObj->pushSubStack($subObj);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::case;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::case::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # CASE constant [ , constant ...]
    # CASE ELSE

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($subObj, $selectStatement);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # The 'case' keyword is not available in primitive numbering mode
        if ($self->scriptObj->executionMode ne 'no_line_num') {

            return $self->scriptObj->setError(
                'statement_not_available_with_line_numbers',
                $self->_objClass . '->parse',
            );
        }

        # Get the SELECT CASE statement which starts this code block
        $subObj = $self->scriptObj->returnCurrentSub();
        if (! $subObj->selectStackList) {

            return $self->scriptObj->setError(
                'CASE_statement_without_matching_SELECT_CASE',
                $self->_objClass . '->parse',
            );

        } else {

            # The matching SELECT CASE statement is the last one in the stack
            $selectStatement = $subObj->pop_selectStackList();
        }

        if (! $self->tokenGroupObj->shiftMatchingToken('else')) {

            # CASE ELSE statement

            # If the SELECT CASE statement has already seen a CASE ELSE, it's an error
            if (defined $selectStatement->ivShow('parseDataHash', 'case_else_statement')) {

                return $self->scriptObj->setError(
                    'multiple_CASE_ELSE_statements_in_SELECT_block',
                    $self->_objClass . '->parse',
                );

            } else {

                # Inform the SELECT CASE statement where its CASE ELSE statement is
                $selectStatement->add_parseDataHash('case_else_statement', $self);
            }

        } else {

            # CASE constant [ , constant ...] statement

            # Read the constants, one by one, and store them
            do {

                my $expression = Language::Axbasic::Expression::Constant->new(
                    $self->scriptObj,
                    $self->tokenGroupObj,
                );

                if (! defined $expression) {

                    return $self->scriptObj->setError(
                        'missing_or_illegal_constant',
                        $self->_objClass . '->parse',
                    );

                } else {

                    $self->ivPush('parseDataList', $expression->evaluate);
                }

            } while (defined $self->tokenGroupObj->shiftMatchingToken(','));

            # Add this statement to the SELECT CASE statement's list of CASE statements
            $selectStatement->push_parseDataList($self);
        }

        # Store the SELECT CASE statement so this statement's ->implement can use it
        $self->ivAdd('parseDataHash', 'select_statement', $selectStatement);
        # Re-insert the SELECT CASE statement back into its stack
        $subObj->push_selectStackList($selectStatement);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($selectStatement, $endSelectStatement, $subObj, $topStatement);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the SELECT CASE statement which starts this code block
        $selectStatement = $self->ivShow('parseDataHash', 'select_statement');
        # Get the matching END SELECT statement
        $endSelectStatement = $selectStatement->ivShow('parseDataHash', 'end_select_statement');

        # This SELECT CASE..CASE..END SELECT code block has now finished
        $subObj = $self->scriptObj->returnCurrentSub();
        $subObj->pop_selectStackList();

        # Execution continues at the next statement after END SELECT
        if (defined $endSelectStatement->nextStatement) {

            $self->scriptObj->set_nextStatement($endSelectStatement->nextStatement);

        } else {

            # The case statement was the last (or only) statement on the line: use the next line
            $self->scriptObj->set_nextLine($endSelectStatement->lineObj->procLineNum + 1);
        }

        # Remove this code block from the standard code block stack.
        if (! $subObj->blockStackList) {

            return $self->scriptObj->setError(
                'CASE_statement_without_matching_SELECT_CASE',
                $self->_objClass . '->implement',
            );

        } else {

            $topStatement = $subObj->pop_blockStackList();

            # The statement at the top of the stack must be a WHILE statement, not another kind of
            #   code block
            if ($topStatement->keyword ne 'select') {

                return $self->scriptObj->setError(
                    'CASE_statement_without_matching_SELECT_CASE',
                    $self->_objClass . '->implement',
                );
            }
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::client;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::client::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # CLIENT expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the expression and store it for ->implement to use
        $expression = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );

        } else {

            $self->ivAdd('parseDataHash', 'expression', $expression);
        }

        # There should be nothing after the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression, $cmd);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the expression to be played
        $expression = $self->ivShow('parseDataHash', 'expression');
        # Evaluate the expression to get a client command
        $cmd = $expression->evaluate();

        # Execute the client command
        $self->scriptObj->session->pseudoCmd($cmd, $self->scriptObj->pseudoCmdMode);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::cls;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::cls::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # CLS

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # EMPTYWIN statements always appear on their own
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script is being run from within an Axmud task and the task window is open,
        #   empty it. Otherwise, do nothing
        if ($self->scriptObj->parentTask && $self->scriptObj->parentTask->taskWinFlag) {

            # Clears a task window's default tab
            $self->scriptObj->parentTask->clearBuffer();
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::close;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::close::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # CLOSE #channel

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($channelToken, $channel, $nameFlag);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the channel token. For CLOSE statements, it must not include a colon at the end
        $channelToken = $self->tokenGroupObj->shiftTokenIfCategory('file_channel');
        if (! defined $channelToken || $channelToken->tokenText =~ m/\:$/) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );

        } else {

            # Store the channel number
            $channelToken->tokenText =~ m/([0-9]+)/;
            $channel = $1;

            # True BASIC specifies that the channel must be in the range 1-999; same range used by
            #   Axbasic
            if ($channel < 1 || $channel > 999) {

                return $self->scriptObj->setError(
                    'file_channel_NUM_out_of_range',
                    $self->_objClass . '->parse',
                    'NUM', $channel,
                );

            } else {

                $self->ivAdd('parseDataHash', 'channel', $channel);
            }
        }

        # Check that nothing follows the file channel
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($channel, $channelObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the variables stored by ->parse
        $channel = $self->ivShow('parseDataHash', 'channel');

        # Check that the file channel exists
        if (! $self->scriptObj->ivExists('fileChannelHash', $channel)) {

            return $self->scriptObj->setError(
                'file_channel_NUM_not_open',
                $self->_objClass . '->implement',
                'NUM', $channel,
            );

        } else {

            $channelObj = $self->scriptObj->ivShow('fileChannelHash', $channel);
        }

        # Update the LA::Script IVs
        $self->scriptObj->del_fileChannel($channelObj);

        # Close the filehandle
        if (! close ($channelObj->fileHandle)) {

            return $self->scriptObj->setError(
                'failed_to_close_file',
                $self->_objClass . '->implement',
            );
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::closewin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::closewin::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # CLOSEWIN

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # CLOSEWIN statements always appear on their own
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script is being run from within an Axmud task and the task window is open,
        #   close it. Otherwise, do nothing
        if ($self->scriptObj->parentTask && $self->scriptObj->parentTask->taskWinFlag) {

            # Close the task window
            $self->scriptObj->parentTask->closeWin();
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::data;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::data::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # DATA constant [ , constant ... ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # The rest of the statement is a list of things to add to the script's global data list
        #   - the things can be retrieved later on by the 'read' statement
        do {

            $expression = Language::Axbasic::Expression::Constant->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $expression) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_constant',
                $self->_objClass . '->parse',
                );

            } else {

                # One copy of the constant goes in a permanent list...
                $self->scriptObj->push_globalDataList($expression);
                # ...and another copy goes into a list from which items are removed by each
                #   successive 'read' statement
                $self->scriptObj->push_readDataList($expression);
            }

        } while (defined $self->tokenGroupObj->shiftMatchingToken(','));

        # Parsing complete
        return 1;
    }

#   sub implement {}        # No ->implement method necessary
}

{ package Language::Axbasic::Statement::debug;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::debug::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # DEBUG expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)

        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the expression and store it for ->implement to use
        $expression = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );

        } else {

            $self->ivAdd('parseDataHash', 'expression', $expression);
        }

        # There should be nothing after the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression, $string);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the expression to be written
        $expression = $self->ivShow('parseDataHash', 'expression');
        # Evaluate the expression to get a scalar value
        $string = $expression->evaluate();

        # If the last PRINT statement was followed by a semicolon, we need to reset the column so
        #   the error message appears on a new line
        if ($self->scriptObj->column != 0) {

            $self->scriptObj->session->writeText('', 'after');
            $self->scriptObj->set_column(0);
        }

        # Write the error message to the 'main' window
        $self->scriptObj->session->writeDebug($string);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::def;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::def::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # DEF function-name ( variable-name [ , variable-name ... ] ) = expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($funcExpression, $funcObj, $expression);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # The function name, and its arguments, consist of all the tokens up until the equals
        # Call LA::Expression::Function->new with an extra argument so it knows not to complain
        #   about an unknown function
        $funcExpression = Language::Axbasic::Expression::Function->new(
            $self->scriptObj,
            $self->tokenGroupObj,
            'defining_flag',
        );

        if (! defined $funcExpression) {

            return $self->scriptObj->setError(
                'bad_function_definition',
                $self->_objClass . '->parse',
            );
        }

        if (! $self->tokenGroupObj->shiftTokenIfCategory('assignment_operator')) {

            return $self->scriptObj->setError(
                'missing_assignment_operator',
                $self->_objClass . '->parse',
            );
        }

        # We don't actually want the LA::Expression, just the LA::Function object we've declared
        $funcObj = $funcExpression->funcObj;

        # Read the function definition
        $expression = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'bad_function_definition',
                $self->_objClass . '->parse',
            );
        }

        # Now actually define the function (tell it how many arguments, and of which type, it has)
        $funcObj->set_defFuncExp($expression);
        # Save the function object (it doesn't appear to be retrieved by any other part of the
        #   Axbasic code)
        $self->ivAdd('parseDataHash', 'func_obj', $funcObj);

        # Parsing complete
        return 1;
    }

#   sub implement {}        # No ->implement method - function definition happens at parse time
}

{ package Language::Axbasic::Statement::delalias;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::delalias::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # DELALIAS expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #   when the first token in the statement is the keyword 'delalias'
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $nameExp;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the name string into an expression
        $nameExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $nameExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Check that nothing follows the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression, so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'name', $nameExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $nameExp, $name, $profile, $result,
            @interfaceList, @newList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the argument stored by $self->parse
        $nameExp = $self->ivShow('parseDataHash', 'name');
        # Evaluate the expression
        $name = $nameExp->evaluate();

        # Specify which profile to use
        if (defined $self->scriptObj->useProfile) {
            $profile = $self->scriptObj->useProfile;
        } else {
            $profile = $self->scriptObj->session->currentWorld->name;
        }

        # Send the command
        $result = $self->scriptObj->session->pseudoCmd(
            'deletealias <' . $name . '> -d ' . $profile,
            $self->scriptObj->pseudoCmdMode,
        );

        if ($result) {

            # Update the LA::Script's IVs
            @interfaceList = $self->scriptObj->indepInterfaceList;
            if (@interfaceList) {

                do {
                    my ($tempName, $tempProfile, $tempCategory);

                    $tempName = shift @interfaceList;
                    $tempProfile = shift @interfaceList;
                    $tempCategory = shift @interfaceList;

                    if ($tempName ne $name || $tempProfile ne $profile) {

                        # This isn't the interface just deleted - reinstate it in the list
                        push (@newList, $tempName, $tempProfile, $tempCategory);
                    }

                } until (! @interfaceList);

                # Replace the list, missing the alias we've removed
                $self->scriptObj->set_indepInterfaceList(@newList);
            }

            if ($self->scriptObj->indepInterfaceName eq $name) {

                $self->scriptObj->set_indepInterfaceName(undef);
            }

        } else {

            # Store the fact that creation of the alias failed
            $self->scriptObj->set_indepInterfaceName(undef);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::delgauge;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::delgauge::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # DELGAUGE expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $numberExp;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the number into an expression
        $numberExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $numberExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Check that nothing follows the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression, so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'number', $numberExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($numberExp, $number);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Retrieve the argument stored by $self->parse
        $numberExp = $self->ivShow('parseDataHash', 'number');
        # Evaluate the expression
        $number = $numberExp->evaluate();

        # $number must be an integer, >= 0 (but it doesn't need to be a gauge number which has
        #   actually been created with an ADDGAUGE or ADDCONGAUGE statement)
        if ($number =~ m/\D/ || $number < 0) {

            return $self->scriptObj->setError(
                'invalid_gauge_number',
                $self->_objClass . '->implement',
            );
        }

        # Tell the Script task to delete the gauge
        $self->scriptObj->parentTask->deleteGauge($number);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::delhook;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::delhook::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # DELHOOK expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($nameExp);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the name string into an expression
        $nameExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $nameExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Check that nothing follows the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression, so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'name', $nameExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $nameExp, $name, $profile, $result,
            @interfaceList, @newList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the argument stored by $self->parse
        $nameExp = $self->ivShow('parseDataHash', 'name');
        # Evaluate the expression
        $name = $nameExp->evaluate();

        # Specify which profile to use
        if (defined $self->scriptObj->useProfile) {
            $profile = $self->scriptObj->useProfile;
        } else {
            $profile = $self->scriptObj->session->currentWorld->name;
        }

        # Send the command
        $result = $self->scriptObj->session->pseudoCmd(
            'deletehook <' . $name . '> -d ' . $profile,
            $self->scriptObj->pseudoCmdMode,
        );

        if ($result) {

            # Update the LA::Script's IVs
            @interfaceList = $self->scriptObj->indepInterfaceList;
            if (@interfaceList) {

                do {

                    my ($tempName, $tempProfile, $tempCategory);

                    $tempName = shift @interfaceList;
                    $tempProfile = shift @interfaceList;
                    $tempCategory = shift @interfaceList;

                    if ($tempName ne $name || $tempProfile ne $profile) {

                        # This isn't the interface just deleted - reinstate it in the list
                        push (@newList, $tempName, $tempProfile, $tempCategory);
                    }

                } until (! @interfaceList);

                # Replace the list, missing the hook we've removed
                $self->scriptObj->set_indepInterfaceList(@newList);
            }

            if ($self->scriptObj->indepInterfaceName eq $name) {

                $self->scriptObj->set_indepInterfaceName(undef);
            }

        } else {

            # Store the fact that creation of the hook failed
            $self->scriptObj->set_indepInterfaceName(undef);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::deliface;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::deliface::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # DELIFACE expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $nameExp;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the name string into an expression
        $nameExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $nameExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Check that nothing follows the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression, so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'name', $nameExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $nameExp, $name, $obj,
            @interfaceList, @newList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the argument stored by $self->parse
        $nameExp = $self->ivShow('parseDataHash', 'name');
        # Evaluate the expression
        $name = $nameExp->evaluate();

        # Check that the interface still exists and, if not, don't try to delete it
        if ($self->scriptObj->session->ivExists('interfaceHash', $name)) {

            $obj = $self->scriptObj->session->ivShow('interfaceHash', $name);

            # Delete the interface
            $self->scriptObj->session->pseudoCmd(
                'delete' . $obj->category . ' -i <' . $name . '>',
                $self->scriptObj->pseudoCmdMode,
            );

            # Update the LA::Script's list of interfaces
            @interfaceList = $self->scriptObj->depInterfaceList;
            foreach my $otherObj (@interfaceList) {

                if ($otherObj ne $obj) {

                    push (@newList, $otherObj);
                }
            }

            $self->scriptObj->set_depInterfaceList(@newList);

            # Update the accompanying IV, if necessary
            if (
                defined $self->scriptObj->depInterfaceName
                && $self->scriptObj->depInterfaceName eq $name
            ) {
                $self->scriptObj->set_depInterfaceName(undef);
            }

            # Now, if we've just deleted an interface created by (for example) a WAITTRIG statement
            #   - and if the parent task is waiting for that trigger to fire - it will now be
            #   waiting forever; so we need to tell the task to stop waiting
            if (
                $self->scriptObj->parentTask
                && defined $self->scriptObj->parentTask->waitForInterface
                && $self->scriptObj->parentTask->waitForInterface eq $name
            ) {
                # Tell the task that the interface has expired
                $self->scriptObj->parentTask->resetInterface($obj);
            }
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::delmacro;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::delmacro::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # DELMACRO expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $nameExp;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the name string into an expression
        $nameExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $nameExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Check that nothing follows the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression, so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'name', $nameExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse when the
        #   first token in the statement is the keyword 'delmacro'
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $nameExp, $name, $profile, $result,
            @interfaceList, @newList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the argument stored by $self->parse
        $nameExp = $self->ivShow('parseDataHash', 'name');
        # Evaluate the expression
        $name = $nameExp->evaluate();

        # Specify which profile to use
        if (defined $self->scriptObj->useProfile) {
            $profile = $self->scriptObj->useProfile;
        } else {
            $profile = $self->scriptObj->session->currentWorld->name;
        }

        # Send the command
        $result = $self->scriptObj->session->pseudoCmd(
            'deletemacro <' . $name . '> -d ' . $profile,
            $self->scriptObj->pseudoCmdMode,
        );

        if ($result) {

            # Update the LA::Script's IVs
            @interfaceList = $self->scriptObj->indepInterfaceList;
            if (@interfaceList) {

                do {
                    my ($tempName, $tempProfile, $tempCategory);

                    $tempName = shift @interfaceList;
                    $tempProfile = shift @interfaceList;
                    $tempCategory = shift @interfaceList;

                    if ($tempName ne $name || $tempProfile ne $profile) {

                        # This isn't the interface just deleted - reinstate it in the list
                        push (@newList, $tempName, $tempProfile, $tempCategory);
                    }

                } until (! @interfaceList);

                # Replace the list, missing the macro we've removed
                $self->scriptObj->set_indepInterfaceList(@newList);
            }

            if ($self->scriptObj->indepInterfaceName eq $name) {

                $self->scriptObj->set_indepInterfaceName(undef);
            }

        } else {

            # Store the fact that creation of the macro failed
            $self->scriptObj->set_indepInterfaceName(undef);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::delstatus;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::delstatus::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # DELSTATUS expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $numberExp;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the number into an expression
        $numberExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $numberExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Check that nothing follows the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression, so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'number', $numberExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($numberExp, $number);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Retrieve the argument stored by $self->parse
        $numberExp = $self->ivShow('parseDataHash', 'number');
        # Evaluate the expression
        $number = $numberExp->evaluate();

        # $number must be an integer, >= 0 (but it doesn't need to be a status bar number which has
        #   actually been created with an ADDSTATUS or ADDCONSTATUS statement)
        if ($number =~ m/\D/ || $number < 0) {

            return $self->scriptObj->setError(
                'invalid_status_bar_number',
                $self->_objClass . '->implement',
            );
        }

        # Tell the Script task to delete the status bar
        $self->scriptObj->parentTask->deleteStatusBar($number);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::deltimer;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::deltimer::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # DELTIMER expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($nameExp);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the name string into an expression
        $nameExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $nameExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Check that nothing follows the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression, so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'name', $nameExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $nameExp, $name, $profile, $result,
            @interfaceList, @newList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the argument stored by $self->parse
        $nameExp = $self->ivShow('parseDataHash', 'name');
        # Evaluate the expression
        $name = $nameExp->evaluate();

        # Specify which profile to use
        if (defined $self->scriptObj->useProfile) {
            $profile = $self->scriptObj->useProfile;
        } else {
            $profile = $self->scriptObj->session->currentWorld->name;
        }

        # Send the command
        $result = $self->scriptObj->session->pseudoCmd(
            'deletetimer <' . $name . '> -d ' . $profile,
            $self->scriptObj->pseudoCmdMode,
        );

        if ($result) {

            # Update the LA::Script's IVs
            @interfaceList = $self->scriptObj->indepInterfaceList;
            if (@interfaceList) {

                do {
                    my ($tempName, $tempProfile, $tempCategory);

                    $tempName = shift @interfaceList;
                    $tempProfile = shift @interfaceList;
                    $tempCategory = shift @interfaceList;

                    if ($tempName ne $name || $tempProfile ne $profile) {

                        # This isn't the interface just deleted - reinstate it in the list
                        push (@newList, $tempName, $tempProfile, $tempCategory);
                    }

                } until (! @interfaceList);

                # Replace the list, missing the timer we've removed
                $self->scriptObj->set_indepInterfaceList(@newList);
            }

            if ($self->scriptObj->indepInterfaceName eq $name) {

                $self->scriptObj->set_indepInterfaceName(undef);
            }

        } else {

            # Store the fact that creation of the timer failed
            $self->scriptObj->set_indepInterfaceName(undef);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::deltrig;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::deltrig::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # DELTRIG expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $nameExp;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the name string into an expression
        $nameExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $nameExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Check that nothing follows the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression, so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'name', $nameExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $nameExp, $name, $profile, $result,
            @interfaceList, @newList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the argument stored by $self->parse
        $nameExp = $self->ivShow('parseDataHash', 'name');
        # Evaluate the expression
        $name = $nameExp->evaluate();

        # Specify which profile to use
        if (defined $self->scriptObj->useProfile) {
            $profile = $self->scriptObj->useProfile;
        } else {
            $profile = $self->scriptObj->session->currentWorld->name;
        }

        # Send the command
        $result = $self->scriptObj->session->pseudoCmd(
            'deletetrigger <' . $name . '> -d ' . $profile,
            $self->scriptObj->pseudoCmdMode,
        );

        if ($result) {

            # Update the LA::Script's IVs
            @interfaceList = $self->scriptObj->indepInterfaceList;
            if (@interfaceList) {

                do {
                    my ($tempName, $tempProfile, $tempCategory);

                    $tempName = shift @interfaceList;
                    $tempProfile = shift @interfaceList;
                    $tempCategory = shift @interfaceList;

                    if ($tempName ne $name || $tempProfile ne $profile) {

                        # This isn't the interface just deleted - reinstate it in the list
                        push (@newList, $tempName, $tempProfile, $tempCategory);
                    }

                } until (! @interfaceList);

                # Replace the list, missing the trigger we've removed
                $self->scriptObj->set_indepInterfaceList(@newList);
            }

            if ($self->scriptObj->indepInterfaceName eq $name) {

                $self->scriptObj->set_indepInterfaceName(undef);
            }

        } else {

            # Store the fact that creation of the trigger failed
            $self->scriptObj->set_indepInterfaceName(undef);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::dim;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::dim::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # DIM variable-name [ arg-list ] [ , variable-name [ arg-list ] ... ]
    # DIM GLOBAL variable-name [ arg-list ] [ , variable-name [ arg-list ] ... ]
    # DIM LOCAL variable-name [ arg-list ] [ , variable-name [ arg-list ] ... ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $token;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # DIM GLOBAL statement
        $token = $self->tokenGroupObj->shiftMatchingToken('global');
        if (defined $token) {

            # Temporarily set the IV that allows undeclared global arrays to be created
            $self->scriptObj->set_declareMode('global_array');

            # Check for DIM GLOBAL LOCAL
            $token = $self->tokenGroupObj->shiftMatchingToken('local');
            if (defined $token) {

                return $self->scriptObj->setError(
                    'unexpected_keywords,_operators_or_expressions',
                    $self->_objClass . '->parse',
                );
            }
        }

        # DIM LOCAL statement
        $token = $self->tokenGroupObj->shiftMatchingToken('local');
        if (defined $token) {

            # Temporarily set the IV that allows undeclared local arrays to be created
            $self->scriptObj->set_declareMode('local_array');

            # Check for DIM LOCAL GLOBAL
            $token = $self->tokenGroupObj->shiftMatchingToken('global');
            if (defined $token) {

                return $self->scriptObj->setError(
                    'unexpected_keywords,_operators_or_expressions',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Check there is at least one variable name (e.g. that we don't have a solo 'DIM' or
        #   'DIM GLOBAL' statement)
        if (! defined $self->tokenGroupObj->lookAhead()) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );
        }

        if ($self->scriptObj->declareMode eq 'default') {

            # Temporarily set the IV that allows undeclared global arrays to be created
            $self->scriptObj->set_declareMode('global_array');
        }

        # Process each array in turn (if several appear on the same line, they are separated by
        #   commas)
        do {

            my $expression = Language::Axbasic::Expression::Lvalue->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $expression) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );

            } else {

                # Save the expression object so $self->implement can use it, if it is called
                $self->ivPush('parseDataList', $expression);
            }

        } while (defined $self->tokenGroupObj->shiftMatchingToken(','));

        # We're finished creating arrays
        $self->scriptObj->set_declareMode('default');

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (@expList, @indices);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Import the list of expressions saved by $self->parse
        @expList = $self->parseDataList;

        # Create each array, and set its dimensions
        foreach my $expression (@expList) {

            # If the $expression appeared in a line like DIM var, rather than the correct
            #   DIM var(10), then ->argListObj won't be defined
            if (! defined $expression->argListObj) {

                return $self->scriptObj->setError(
                    'invalid_expression_in_DIM_statement',
                    $self->_objClass . '->implement',
                );
            }

            # Set up the array
            @indices = $expression->argListObj->evaluate();
            if (! @indices) {

                # DIM var() statements not allowed
                return $self->scriptObj->setError(
                    'invalid_expression_in_DIM_statement',
                    $self->_objClass . '->implement',
                );

            } elsif (scalar @indices == 1 && $indices[0] == 0) {

                # LA::Variable::Array allows empty one-dimensional arrays, which PEEK and PEEK...
                #   statements need, but we can't create an empty one-dimensional array with DIM
                #   statements
                return $self->scriptObj->setError(
                    'invalid_array_dimension_size_NUM',
                    $self->_objClass . '->implement',
                    'NUM', $indices[0],
                );

            } else {

                $expression->varObj->dimension(@indices);
            }
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::do;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::do::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # DO

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $subObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # The 'do' keyword is not available in primitive numbering mode
        if ($self->scriptObj->executionMode ne 'no_line_num') {

            return $self->scriptObj->setError(
                'statement_not_available_with_line_numbers',
                $self->_objClass . '->parse',
            );
        }

        # DO statements always appear on their own
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Add this DO statement to the DO code block stack for the current subroutine
        $subObj = $self->scriptObj->returnCurrentSub();
        $subObj->push_doStackList($self);

        # We don't know what the corresponding UNTIL statement is, yet
        $self->ivAdd('parseDataHash', 'until_statement', undef);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $subObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Add this 'do' statement to the code block stack for the current subroutine
        $subObj = $self->scriptObj->returnCurrentSub();
        $subObj->push_blockStackList($self);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::else;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::else::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # ELSE IF condition THEN
    # ELSE

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($subObj, $ifStatement, $token, $condition);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # The 'else' keyword is not available in primitive numbering mode
        if ($self->scriptObj->executionMode ne 'no_line_num') {

            return $self->scriptObj->setError(
                'statement_not_available_with_line_numbers',
                $self->_objClass . '->parse',
            );
        }

        # Get the IF statement which starts this code block
        $subObj = $self->scriptObj->returnCurrentSub();
        if (! $subObj->ifStackList) {

            return $self->scriptObj->setError(
                'ELSE_statement_without_matching_IF',
                $self->_objClass . '->parse',
            );

        } else {

            # The matching IF statement is the last one in the stack
            $ifStatement = $subObj->pop_ifStackList();
        }

        $token = $self->tokenGroupObj->shiftMatchingToken('if');
        if (defined $token) {

            # ELSE IF statement

            # If the IF statement has already seen a plain ELSE, it must not be be followed by
            #   another ELSE IF
            if (defined $ifStatement->ivShow('parseDataHash', 'else_statement')) {

                return $self->scriptObj->setError(
                    'ELSE_IF_statement_cannot_follow_ELSE',
                    $self->_objClass . '->parse',
                );
            }

            # Everything up until 'then' is a conditional expression
            $condition = Language::Axbasic::Expression::LogicalOr->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $condition) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_conditional_expression',
                    $self->_objClass . '->parse',
                );

            } else {

                # Store the condition expression, so $self->implement can retrieve it
                $self->ivAdd('parseDataHash', 'condition', $condition);
            }

            if (! defined $self->tokenGroupObj->shiftMatchingToken('then')) {

                return $self->scriptObj->setError(
                    'missing_THEN_in_ELSE_IF_statement',
                    $self->_objClass . '->parse',
                );
            }

            # There should be nothing after the THEN keyword
            if (! $self->tokenGroupObj->testStatementEnd()) {

                return $self->scriptObj->setError(
                    'ELSE_IF_statement_not_terminated_by_THEN',
                    $self->_objClass . '->parse',
                );
            }

            # Save this statement in the IF statement's list of ElSE IF statements
            $ifStatement->push_parseDataList($self);

        } else {

            # Plain ELSE statement

            # If the IF statement has already seen a plain ELSE, it must not be followed by another
            #   ELSE
            if (defined $ifStatement->ivShow('parseDataHash', 'else_statement')) {

                return $self->scriptObj->setError(
                    'multiple_ELSE_statements_in_IF_block',
                    $self->_objClass . '->parse',
                );
            }

            # There should be nothing after the ELSE keyword. Use a unique error message to make
            #   clear that ELSE must occur alone
            if (! $self->tokenGroupObj->testStatementEnd()) {

                return $self->scriptObj->setError(
                    'unexpected_keywords,_operators_or_expressions_in_ELSE_statement',
                    $self->_objClass . '->parse',
                )
            }

            # Inform the IF statement where its ELSE statement is
            $ifStatement->ivAdd('parseDataHash', 'else_statement', $self);
        }

        # Store the IF statement so this statement's ->implement can use it
        $self->add_parseDataHash('if_statement', $ifStatement);
        # Re-insert the IF statement back into its stack
        $subObj->push_ifStackList($ifStatement);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($ifStatement, $endIfStatement, $subObj, $topStatement);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the IF statement which starts this code block
        $ifStatement = $self->ivShow('parseDataHash', 'if_statement');
        # Get the matching END IF statement
        $endIfStatement = $ifStatement->ivShow('parseDataHash', 'end_if_statement');

        # This IF..ELSE IF..ELSE..END IF code block has now finished
        $subObj = $self->scriptObj->returnCurrentSub();

        # Execution continues at the next statement after END IF
        if (defined $endIfStatement->nextStatement) {

            $self->scriptObj->set_nextStatement($endIfStatement->nextStatement);

        } else {

            # The case statement was the last (or only) statement on the line: use the next line
            $self->scriptObj->set_nextLine($endIfStatement->lineObj->procLineNum + 1);
        }

        # Remove this code block from the standard code block stack.
        if (! $subObj->blockStackList) {

            return $self->scriptObj->setError(
                'ELSE_statement_without_matching_IF',
                $self->_objClass . '->implement',
            );

        } else {

            $topStatement = $subObj->pop_blockStackList();

            # The statement at the top of the stack must be an IF statement, not another kind of
            #   code block
            if ($topStatement->keyword ne 'if') {

                return $self->scriptObj->setError(
                    'ELSE_statement_without_matching_IF',
                    $self->_objClass . '->implement',
                );
            }
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::emptywin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::emptywin::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # EMPTYWIN

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # EMPTYWIN statements always appear on their own
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script is being run from within an Axmud task and the task window is open,
        #   empty it. Otherwise, do nothing
        if ($self->scriptObj->parentTask && $self->scriptObj->parentTask->taskWinFlag) {

            # Clears the task window's textview
            $self->scriptObj->parentTask->clearBuffer();
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::end;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::end::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # END
    # END IF
    # END SUB
    # END SELECT

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($token, $currentSub, $selectStatement, $ifStatement);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Is this an 'END', 'END IF', 'END SELECT', 'END SUB'?
        $token = $self->tokenGroupObj->shiftToken();
        if (! defined $token) {

            # END statement
            $self->ivAdd('parseDataHash', 'end_sub_flag', FALSE);

            # Check that there isn't more than one 'end' statement in the script
            if ($self->scriptObj->endStatementFlag) {

                return $self->scriptObj->setError(
                    'duplicate_END_statement',
                    $self->_objClass . '->parse',
                );

            } else {

                # LA::Script->parse produces an error if, after parsing, it hasn't noticed one
                #   (and only one) END statement
                $self->scriptObj->set_endStatementFlag(TRUE);
            }

        } elsif ($token->tokenText eq 'if') {

            # END IF statement
            $self->ivAdd('parseDataHash', 'end_if_flag', 1);

            # Check that nothing follows the END IF keywords
            if (! defined $self->tokenGroupObj->testStatementEnd()) {

                return $self->scriptObj->setError(
                    'unexpected_keywords,_operators_or_expressions',
                    $self->_objClass . '->parse',
                );
            }

            # Find the matching IF statement
            $currentSub = $self->scriptObj->returnCurrentSub();
            if (! $currentSub->ifStackList) {

                return $self->scriptObj->setError(
                    'END_IF_statement_without_matching_IF',
                    $self->_objClass . '->parse',
                );

            } else {

                # The matching IF statement is the last one in the stack
                $ifStatement = $currentSub->pop_ifStackList();
                $ifStatement->add_parseDataHash('end_if_statement', $self);
                # Store the matching statement for ->implement to use
                $self->ivAdd('parseDataHash', 'if_statement', $ifStatement);
            }

        } elsif ($token->tokenText eq 'select') {

            # END SELECT statement
            $self->ivAdd('parseDataHash', 'end_select_flag', 1);

            # END SELECT is not available in primitive numbering mode
            if ($self->scriptObj->executionMode ne 'no_line_num') {

                return $self->scriptObj->setError(
                    'statement_not_available_with_line_numbers',
                    $self->_objClass . '->parse',
                );
            }

            # Check that nothing follows the END SELECT keywords
            if (! defined $self->tokenGroupObj->testStatementEnd()) {

                return $self->scriptObj->setError(
                    'unexpected_keywords,_operators_or_expressions',
                    $self->_objClass . '->parse',
                );
            }

            # Find the matching SELECT CASE statement
            $currentSub = $self->scriptObj->returnCurrentSub();
            if (! $currentSub->selectStackList) {

                return $self->scriptObj->setError(
                    'END_SELECT_statement_without_matching_SELECT_CASE',
                    $self->_objClass . '->parse',
                );

            } else {

                # The matching SELECT CASE statement is the last one in the stack
                $selectStatement = $currentSub->pop_selectStackList();
                $selectStatement->add_parseDataHash('end_select_statement', $self);
                # Store the matching statement for ->implement to use
                $self->ivAdd('parseDataHash', 'select_statement', $selectStatement);
            }

        } elsif ($token->tokenText eq 'sub') {

            # END SUB statement
            $self->ivAdd('parseDataHash', 'end_sub_flag', TRUE);

            # END SUB is not available in primitive numbering mode
            if ($self->scriptObj->executionMode ne 'no_line_num') {

                return $self->scriptObj->setError(
                    'statement_not_available_with_line_numbers',
                    $self->_objClass . '->parse',
                );
            }

            # Check that nothing follows the END SUB keywords
            if (! defined $self->tokenGroupObj->testStatementEnd()) {

                return $self->scriptObj->setError(
                    'unexpected_keywords,_operators_or_expressions',
                    $self->_objClass . '->parse',
                );
            }

            # Check that we're inside a subroutine declaration
            if (! $self->scriptObj->currentParseSub) {

                return $self->scriptObj->setError(
                    'mismatched_\'end_sub\'_statement',
                    $self->_objClass . '->parse',
                );
            }

            # Otherwise, this is the end of the currently parsed subroutine declaration
            $currentSub = $self->scriptObj->currentParseSub;
            $currentSub->set_terminateStatement($self);
            $self->scriptObj->set_currentParseSub(undef);

            # $self->implement needs to know which subroutine is being ended
            $self->ivAdd('parseDataHash', 'sub_ref', $currentSub);

        } else {

            # END followed by something other than IF, SELECT or SUB
            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($subObj, $callStatement, $topStatement);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        $subObj = $self->scriptObj->returnCurrentSub();

        if ($self->ivShow('parseDataHash', 'end_if_flag')) {

            # END IF statement

            # This IF..END IF code block has now finished
            if (! $subObj->blockStackList) {

                return $self->scriptObj->setError(
                    'END_IF_statement_without_matching_IF',
                    $self->_objClass . '->implement',
                );

            } else {

                $topStatement = $subObj->pop_blockStackList();
                # The statement at the top of the stack must be a IF statement, not another kind of
                #   code block
                if ($topStatement->keyword ne 'if') {

                    return $self->scriptObj->setError(
                        'END_IF_statement_without_matching_IF',
                        $self->_objClass . '->implement',
                    );
                }
            }

        } elsif ($self->ivShow('parseDataHash', 'end_select_flag')) {

            # END SELECT statement

            # This SELECT CASE..CASE..END SELECT code block has now finished
            $subObj->pop_selectStackList();

            # Also remove this code block from the standard code block stack.
            if (! $subObj->blockStackList) {

                return $self->scriptObj->setError(
                    'END_SELECT_statement_without_matching_SELECT_CASE',
                    $self->_objClass . '->implement',
                );

            } else {

                $topStatement = $subObj->pop_blockStackList();

                # The statement at the top of the stack must be a WHILE statement, not another kind
                #   of code block
                if ($topStatement->keyword ne 'select') {

                    return $self->scriptObj->setError(
                        'END_SELECT_statement_without_matching_SELECT_CASE',
                        $self->_objClass . '->implement',
                    );
                }
            }

        } elsif ($self->ivShow('parseDataHash', 'end_sub_flag')) {

            # END SUB statement
            $subObj = $self->ivShow('parseDataHash', 'sub_ref');

            # Execution resumes at the first statement after the one that called the subroutine
            $callStatement = $subObj->callStatement;

            # The next statement to execute is the statement after that
            if (defined $callStatement->nextStatement) {

                $self->scriptObj->set_nextStatement($callStatement->nextStatement);
                $self->scriptObj->set_nextLine($callStatement->lineObj->procLineNum);

            } else {

                $self->scriptObj->set_nextStatement(undef);
                $self->scriptObj->set_nextLine($callStatement->lineObj->procLineNum + 1);
            }

            # The subroutine's return value is 0 (for numeric) and '' (for strings). Set the return
            #   variable, if there is one
            if (defined $subObj->returnVar) {

                if ($subObj->returnVarType eq 'numeric') {
                    $subObj->returnVar->set(0);
                } else {
                    $subObj->returnVar->set('');
                }
            }

            # Update the script's subroutine stack
            $self->scriptObj->popSubStack();

        } else {

            # END statement

            # Execution of the Axbasic script can now stop
            if ($self->scriptObj->executionStatus ne 'finished') {

                # 'wait_input' means that parsing/implementation of the script has finished
                $self->scriptObj->set_executionStatus('finished');
                # 'finished' means that parsing/implementation finished without an error
                $self->scriptObj->set_scriptStatus('finished')
            }

            # (Do nothing if the execution status has already been set to 3)
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::erase;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::erase::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # ERASE #channel

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($channelToken, $channel, $nameFlag);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the channel token. For ERASE statements, it must not include a colon at the end
        $channelToken = $self->tokenGroupObj->shiftTokenIfCategory('file_channel');
        if (! defined $channelToken || $channelToken->tokenText =~ m/\:$/) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );

        } else {

            # Store the channel number
            $channelToken->tokenText =~ m/([0-9]+)/;
            $channel = $1;

            # True BASIC specifies that the channel must be in the range 1-999; same range used by
            #   Axbasic
            if ($channel < 1 || $channel > 999) {

                return $self->scriptObj->setError(
                    'file_channel_NUM_out_of_range',
                    $self->_objClass . '->parse',
                    'NUM', $channel,
                );

            } else {

                $self->ivAdd('parseDataHash', 'channel', $channel);
            }
        }

        # Check that nothing follows the file channel
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($channel, $channelObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the variables stored by ->parse
        $channel = $self->ivShow('parseDataHash', 'channel');

        # Check that the file channel exists
        if (! $self->scriptObj->ivExists('fileChannelHash', $channel)) {

            return $self->scriptObj->setError(
                'file_channel_NUM_not_open',
                $self->_objClass . '->implement',
                'NUM', $channel,
            );

        } else {

            $channelObj = $self->scriptObj->ivShow('fileChannelHash', $channel);
        }

        # Check that writing to the file channel is allowed
        if ($channelObj->accessType eq 'input') {

            return $self->scriptObj->setError(
                'file_channel_NUM_is_read_only',
                $self->_objClass . '->implement',
                'NUM', $channel,
               );
        }

        # Move the pointer to the beginning of the file, then erase its contents
        seek($channelObj->fileHandle, 0, Fcntl::SEEK_SET);
        truncate($channelObj->fileHandle, 0);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::error;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::error::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # ERROR expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the expression and store it for ->implement to use
        $expression = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression ',
                $self->_objClass . '->parse',
            );

        } else {

            $self->ivAdd('parseDataHash', 'expression', $expression);
        }

        # There should be nothing after the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression, $string);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the expression to be written
        $expression = $self->ivShow('parseDataHash', 'expression');
        # Evaluate the expression to get a scalar value
        $string = $expression->evaluate();

        # If the last PRINT statement was followed by a semicolon, we need to reset the column so
        #   the error message appears on a new line
        if ($self->scriptObj->column != 0) {

            $self->scriptObj->session->writeText('', 'after');
            $self->scriptObj->set_column(0);
        }

        # Write the error message to the 'main' window
        $self->scriptObj->session->writeError($string);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::exit;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::exit::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # EXIT DO
    # EXIT SUB
    # EXIT WHILE

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $token;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # The 'exit' keyword is not available in primitive numbering mode
        if ($self->scriptObj->executionMode ne 'no_line_num') {

            return $self->scriptObj->setError(
                'statement_not_available_with_line_numbers',
                $self->_objClass . '->parse',
            );
        }

        $token = $self->tokenGroupObj->shiftToken();
        if (
            ! defined $token
            || (
                $token->tokenText ne 'do'           # EXIT DO
                && $token->tokenText ne 'sub'       # EXIT SUB
                && $token->tokenText ne 'while'     # EXIT WHILE
            )
        ) {
            # EXIT must be followed by DO, SUB or WHILE
            return $self->scriptObj->setError(
                'syntax error',
                $self->_objClass . '->parse',
            );

        } elsif (defined $self->tokenGroupObj->lookAhead()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );

        } else {

            # Save the type of exit for ->implement
            $self->ivAdd('parseDataHash', 'keyword', $token->tokenText);

            # Parsing complete
            return 1;
        }
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($keyword, $subObj, $matchStatement, $resumeStatement, $exitFlag);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the keyword that followed the EXIT keyword
        $keyword = $self->ivShow('parseDataHash', 'keyword');
        # Get the current subroutine
        $subObj = $self->scriptObj->returnCurrentSub();

        if ($keyword eq 'do' || $keyword eq 'while') {

            # Get the corresponding DO/WHILE statement from the current subroutine's code block
            #   stack. Keep removing code blocks from the top of the stack until we get the right
            #   one
            if (! $subObj->blockStackList) {

                # EXIT_DO_statement_without_matching_DO
                # EXIT_WHILE_statement_without_matching_WHILE
                return $self->scriptObj->setError(
                    'EXIT_' . uc($keyword) . '_statement_without_matching_' . uc($keyword),
                    $self->_objClass . '->implement',
                );
            }

            do {
                $matchStatement = $subObj->pop_blockStackList();

                # Check that it's a DO/WHILE statement - not the start of another kind of code block
                if ($matchStatement->keyword eq $keyword) {

                    # We've found the statement we're looking for
                    $exitFlag = TRUE;
                }

            } until ($exitFlag || ! $subObj->blockStackList);

            if (! $exitFlag) {

                # EXIT_DO_statement_without_matching_DO
                # EXIT_WHILE_statement_without_matching_WHILE
                return $self->scriptObj->setError(
                    'EXIT_' . uc($keyword) . '_statement_without_matching_' . uc($keyword),
                    $self->_objClass . '->implement',
                );

            } elsif ($keyword eq 'do') {

                # Get the DO statement's corresponding UNTIL statement
                $resumeStatement = $matchStatement->ivShow('parseDataHash', 'until_statement');

            } else {

                # Get the WHILE statement's corresponding LOOP statement
                $resumeStatement = $matchStatement->ivShow('parseDataHash', 'loop_statement');
            }

        } elsif ($keyword eq 'sub') {

            # EXIT SUB is interpreted exactly the same way as END SUB, except that EXIT SUB won't
            #   cause an error at the ->parse stage if it doesn't match an earlier SUB statement
            if ($subObj->name eq '*main') {

                return $self->scriptObj->setError(
                    'EXIT_SUB_statement_used_outside_subroutine',
                    $self->_objClass . '->implement',
                );
            }

            # Execution resumes at the first statement after the one that called the subroutine
            $resumeStatement = $subObj->callStatement;

            # The subroutine's return value is 0 (for numeric) and '' (for strings). Set the return
            #   variable, if there is one
            if (defined $subObj->returnVar) {

                if ($subObj->returnVarType eq 'numeric') {
                    $subObj->returnVar->set(0);
                } else {
                    $subObj->returnVar->set('');
                }
            }

            # Update the script's subroutine stack
            $self->scriptObj->popSubStack();
        }

        if ($resumeStatement) {

            # The next statement to execute is the statement after that
            if (defined $resumeStatement->nextStatement) {

                $self->scriptObj->set_nextStatement($resumeStatement->nextStatement);
                $self->scriptObj->set_nextLine($resumeStatement->lineObj->procLineNum);

            } else {

                $self->scriptObj->set_nextStatement(undef);
                $self->scriptObj->set_nextLine($resumeStatement->lineObj->procLineNum + 1);
            }
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::flashwin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::flashwin::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # FLASHWIN

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # FLASHWIN statements always appear on their own
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script is being run from within an Axmud task and the task window is open,
        #   set the window's urgency hint. Otherwise, do nothing
        if ($self->scriptObj->parentTask && $self->scriptObj->parentTask->winObj) {

            # Sets the window urgency hint
            $self->scriptObj->parentTask->winObj->setUrgent();
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::for;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::for::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # FOR variable-name = expression TO expression [ STEP expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($lvalue, $token, $initExp, $termExp, $stepExp, $newTokenGroup);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Read the iterator variable name
        $lvalue = Language::Axbasic::Expression::Lvalue->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $lvalue) {

            return $self->scriptObj->setError(
                'missing_or_illegal_iterator',
                $self->_objClass . '->parse',
            );

        } elsif ($lvalue->isa('Language::Axbasic::Expression::String')) {

            return $self->scriptObj->setError(
                'missing_or_illegal_iterator',
                $self->_objClass . '->parse',
            );

        } else {

            # Store the iterator, so $self->implement can retrieve it
            $self->ivAdd('parseDataHash', 'lvalue', $lvalue);
        }

        # Read the assignment operator
        $token = $self->tokenGroupObj->shiftMatchingToken('=');
        if (! defined $token) {

            return $self->scriptObj->setError(
                'missing_assignment_operator',
                $self->_objClass . '->parse',
            );
        }

        # Read the initialisation expression
        $initExp = Language::Axbasic::Expression::Arithmetic::Numeric->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $initExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );

        } else {

            # Store the initialisation expression, so $self->implement can retrieve it
            $self->ivAdd('parseDataHash', 'init_exp', $initExp);
        }

        # Read the 'to' keyword
        $token = $self->tokenGroupObj->shiftMatchingToken('to');
        if (! defined $token) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );
        }

        # Until the keyword 'step', or the end of the statement, we're copying the termination
        #   expression
        $termExp = Language::Axbasic::Expression::Arithmetic::Numeric->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $termExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );

        } else {

            # Store the initialisation expression, so $self->implement can retrieve it
            $self->ivAdd('parseDataHash', 'term_exp', $termExp);
        }

        # If there is anything left, it should be a 'step' keyword. If 'step' isn't specified, use
        #   the default increment of +1
        $token = $self->tokenGroupObj->shiftMatchingToken('step');
        if (defined $token) {

            $stepExp = Language::Axbasic::Expression::Arithmetic::Numeric->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $stepExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );

            } else {

                # Store the step expression, so $self->implement can retrieve it
                $self->ivAdd('parseDataHash', 'step_exp', $stepExp);
            }

        } elsif (! $self->tokenGroupObj->testStatementEnd()) {

            # There shouldn't be anything after the 'step' expression
            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );

        } else {

            # Create a separate token group to hold a token containing '1', and lex it, so we can
            #   save the '1' as an expression
            $newTokenGroup = Language::Axbasic::TokenGroup->new($self->scriptObj, '1');
            $newTokenGroup->lex();
            $stepExp = Language::Axbasic::Expression::Arithmetic::Numeric->new(
                $self->scriptObj,
                $newTokenGroup,
            );

            # Store the step expression, so $self->implement can retrieve it
            $self->ivAdd('parseDataHash', 'step_exp', $stepExp);
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($lvalue, $initExp, $result, $var, $subObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the variables stored by ->parse
        $lvalue = $self->ivShow('parseDataHash', 'lvalue');
        $initExp = $self->ivShow('parseDataHash', 'init_exp');

        # Get the variable object for the iterator
        $var = $lvalue->variable;
        if (! defined $var) {

            return $self->scriptObj->setDebug(
                'Couldn\'t set up iterator in FOR statement',
                $self->_objClass . '->implement',
            );
        }

        # Evaluate the  initialisation expression, and set the iterator with the value
        $result = $initExp->evaluate();
        if (! defined $result) {

            return $self->scriptObj->setDebug(
                'Couldn\'t evaluate set up  initialisation expression in FOR statement',
                $self->_objClass . '->implement',
            );

        } else {

            $var->set($result);
        }

        # Add this 'for' statement to the code block stack for the current subroutine
        $subObj = $self->scriptObj->returnCurrentSub();
        $subObj->push_blockStackList($self);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::global;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::global::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # GLOBAL variable-name [ , variable-name ... ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($token, $argListObj, $lvalue, $result);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # The 'global' keyword is not available in primitive numbering mode
        if ($self->scriptObj->executionMode ne 'no_line_num') {

            return $self->scriptObj->setError(
                'statement_not_available_with_line_numbers',
                $self->_objClass . '->parse',
            );
        }

        # Temporarily set the IV that allows undeclared variables to be created
        $self->scriptObj->set_declareMode('global_scalar');

        # Process each array in turn (if several appear on the same line, they are separated by
        #   commas)
        do {

            $lvalue = Language::Axbasic::Expression::Lvalue->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $lvalue) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_variable',
                    $self->_objClass . '->parse',
                );
            }

        } while (defined $self->tokenGroupObj->shiftMatchingToken(','));

        # Reset the temporary IV
        $self->scriptObj->set_declareMode('default');

        # Check there is nothing else (except for the statement separator, :)
        $result = $self->tokenGroupObj->testStatementEnd();
        if (! defined $result) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

#   sub implement {}        # No ->implement method - LA::Variable->lookup has already added the
                            #   variable to LA::Script->globalScalarHash or ->globalArrayHash
}

{ package Language::Axbasic::Statement::gosub;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::gosub::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # GOSUB expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # The 'gosub' keyword is only available in primitive numbering mode
        if ($self->scriptObj->executionMode ne 'line_num') {

            return $self->scriptObj->setError(
                'statement_not_available_without_line_numbers',
                $self->_objClass . '->parse',
            );
        }

        # The rest of the statement is an expression for the line to call
        $expression = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Check that nothing follows the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expression',
                $self->_objClass . '->parse',
            );
        }

        # Store the gosub expression, so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'expression', $expression);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression, $lineNumber);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the variable stored by ->parse
        $expression = $self->ivShow('parseDataHash', 'expression');

        # Evaluate the expression to get the line number (because $expression could be 'x+17/3' as
        #   well as '20')
        $lineNumber = $expression->evaluate();
        if (! defined $lineNumber || ! ($lineNumber =~  /^\d+$/)) {

            return $self->scriptObj->setError(
                'illegal_line_number_NUM',
                $self->_objClass . '->implement',
                'NUM', $lineNumber,
            );
        }

        # Check that the primitive line number exists
        if (! $self->scriptObj->ivExists('primLineHash', $lineNumber)) {

            return $self->scriptObj->setError(
                'line_number_NUM_not_found',
                $self->_objClass . '->implement',
                'NUM', $lineNumber,
            );

        } else {

            # Push the current statement onto the GOSUB stack
            $self->scriptObj->push_gosubStackList($self);

            # The line in the expression is the next line to be executed
            $self->scriptObj->set_nextLine($self->scriptObj->ivShow('primLineHash', $lineNumber));

            $self->scriptObj->set_nextStatement(undef);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::goto;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::goto::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # GOTO expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # The 'goto' keyword is only available in primitive numbering mode
        if ($self->scriptObj->executionMode ne 'line_num') {

            return $self->scriptObj->setError(
                'statement_not_available_without_line_numbers',
                $self->_objClass . '->parse',
            );
        }

        # The rest of the statement is an expression for the line to go to
        $expression = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression ',
                $self->_objClass . '->parse',
            );
        }

        # Check that nothing follows the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the arithmetic expression, so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'expression', $expression);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression, $lineNumber);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the variable stored by ->parse
        $expression = $self->ivShow('parseDataHash', 'expression');

        # Evaluate the expression to get the line number (because $expression could be 'x+17/3' as
        #   well as '20')
        $lineNumber = $expression->evaluate();
        if (! defined $lineNumber || ! ($lineNumber =~  /^\d+$/)) {

            return $self->scriptObj->setError(
                'illegal_line_number_NUM',
                $self->_objClass . '->implement',
                'NUM', $lineNumber,
            );
        }

        # Check that the primitive line number exists
        if (! $self->scriptObj->ivExists('primLineHash', $lineNumber)) {

            return $self->scriptObj->setError(
                'line_number_NUM_not_found',
                $self->_objClass . '->implement',
                'NUM', $lineNumber,
            );

        } else {

            # That's the next line to be executed
            $self->scriptObj->set_nextLine(
                $self->scriptObj->ivShow('primLineHash', $lineNumber),
            );
            $self->scriptObj->set_nextStatement(undef);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::help;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::help::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # HELP
    # HELP expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        if ($self->tokenGroupObj->testStatementEnd()) {

            # HELP

            $self->ivAdd('parseDataHash', 'expression', undef);

        } else {

            # HELP Expression

            # Get the expression and store it for ->implement to use.
            $expression = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $expression) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression ',
                    $self->_objClass . '->parse',
                );

            } else {

                $self->ivAdd('parseDataHash', 'expression', $expression);
            }

            # There should be nothing after the expression
            if (! $self->tokenGroupObj->testStatementEnd()) {

                return $self->scriptObj->setError(
                    'unexpected_keywords,_operators_or_expressions',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression, $topic);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the expression to be displayed
        $expression = $self->ivShow('parseDataHash', 'expression');
        if (! defined $expression) {

            # 'HELP' is the same as the client command ';axbasichelp'
            $self->scriptObj->session->pseudoCmd('axbasichelp', $self->scriptObj->pseudoCmdMode);

        } else {

            # 'HELP Expression' is the same as the client command ';axbasichelp <topic>'
            $topic = $expression->evaluate();
            $self->scriptObj->session->pseudoCmd(
                'axbasichelp <' . $topic . '>',
                $self->scriptObj->pseudoCmdMode,
            );
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::if;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::if::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # IF condition THEN statement [ : statement ...] [ ELSE statement [ : statement ...]]
    # IF condition THEN expression [ ELSE expression ]
    #
    # IF condition THEN
    #    statement
    #    statement
    # ELSE IF condition THEN
    #    statement
    # ELSE
    #    statement
    # END IF

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $condition, $newTokenGroup, $previousStatement, $thenStatement, $elseStatement,
            $otherStatement, $subObj,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Everything up until 'then' is a conditional expression
        $condition = Language::Axbasic::Expression::LogicalOr->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $condition) {

            return $self->scriptObj->setError(
                'missing_or_illegal_conditional_expression',
                $self->_objClass . '->parse',
            );

        } else {

            # Store the condition expression, so $self->implement can retrieve it
            $self->ivAdd('parseDataHash', 'condition', $condition);
        }

        if (! defined $self->tokenGroupObj->shiftMatchingToken('then')) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );
        }

        # Everything up until 'else' or the end of the line is one or more statements to do if the
        #   'if' condition is true
        if (! defined $self->tokenGroupObj->lookAhead()) {

            # This statement is the start of a multi-line IF..END IF code block
            # Add it to the IF code block stack for the current subroutine
            $subObj = $self->scriptObj->returnCurrentSub();
            $subObj->push_ifStackList($self);

            # We don't know where the corresponding END IF statement is yet
            $self->ivAdd('parseDataHash', 'end_if_statement', undef);

        } else {

            # Import all the tokens until the 'else' statement (if there is no 'else', just import
            #   all the tokens)
            $newTokenGroup = Language::Axbasic::TokenGroup->new($self->scriptObj);
            $newTokenGroup->importTokens($self->tokenGroupObj, 'else');

            # Create a new statement to parse the 'then' clause, and parse the statement
            # 'line_num_ok' tells the new statement that it's parsing a 'then/else', so that
            #   'then 20' is parsed like 'then goto 20'
            $thenStatement = Language::Axbasic::Statement->new(
                $self->scriptObj,
                $self->lineObj,
                $newTokenGroup,
                'line_num_ok',
            );

            if (! defined $thenStatement) {

                return $self->scriptObj->setError(
                    'syntax_error',
                    $self->_objClass . '->parse',
                );

            } else {

                $thenStatement->parse();
                $previousStatement = $thenStatement;
            }

            # Deal with [: Statement]
            while (defined ($newTokenGroup->shiftTokenIfCategory('statement_end'))) {

                # A plain line number, like 'then 20', is only allowed in the first 'then/else'
                #   statement
                $otherStatement = Language::Axbasic::Statement->new(
                    $self->scriptObj,
                    $self->lineObj,
                    $newTokenGroup,
                );

                $otherStatement->parse();
                $previousStatement->set_nextStatement($otherStatement);
                $previousStatement = $otherStatement;
            }

            # Make sure we don't do the 'else' after the 'then'!
            $previousStatement->set_nextStatement('nextStatement', undef);

            # If there is anything left in $self->tokenGroup, it's the 'else' clause
            if (defined $self->tokenGroupObj->shiftMatchingToken('else')) {

                # Use up all the remaining tokens
                $elseStatement = Language::Axbasic::Statement->new(
                    $self->scriptObj,
                    $self->lineObj,
                    $self->tokenGroupObj,
                    'line_num_ok',
                );

                if (! defined $elseStatement) {

                    return $self->scriptObj->setError(
                        'syntax_error',
                        $self->_objClass . '->parse',
                    );

                } else {

                    $elseStatement->parse();
                    $previousStatement = $elseStatement;
                }

                while (defined($self->tokenGroupObj->shiftTokenIfCategory('statement_end'))) {

                    $otherStatement = Language::Axbasic::Statement->new(
                        $self->scriptObj,
                        $self->lineObj,
                        $self->tokenGroupObj,
                    );

                    $otherStatement->parse();
                    $previousStatement->set_nextStatement($otherStatement);
                    $previousStatement = $otherStatement;
                }

                $previousStatement->set_nextStatement(undef);

                if (! $self->tokenGroupObj->testStatementEnd()) {

                    return $self->scriptObj->setError(
                        'unexpected_keywords,_operators_or_expressions',
                        $self->_objClass . '->parse',
                    )
                }

            } elsif (! $self->tokenGroupObj->testStatementEnd()) {

                return $self->scriptObj->setError(
                    'unexpected_keywords,_operators_or_expressions',
                    $self->_objClass . '->parse',
                )
            }

            # Save the 'then' and 'else' statements, so ->implement can retrieve them
            $self->ivAdd('parseDataHash', 'then_statement', $thenStatement);
            $self->ivAdd('parseDataHash', 'else_statement', $elseStatement);
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
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
            $subObj, $thenStatement, $elseStatement, $condition, $endIfStatement, $nextStatement,
            @statementList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the stored data
        $thenStatement = $self->ivShow('parseDataHash', 'then_statement');
        $elseStatement = $self->ivShow('parseDataHash', 'else_statement');

        # Single-line IF..THEN..ELSE statement
        if ($thenStatement) {

            $condition = $self->ivShow('parseDataHash', 'condition');

            # Decide which statement should be executed next, depending on whether the $condition is
            #   true, or not
            if ($condition->evaluate()) {

                # Execute the 'then' statement (which always exists)
                $self->ivPoke('nextStatement', $thenStatement);

            } else {

                # Execute the 'else' statement (if it exists), or just continue on to the next
                #   statement in the script (if it doesn't)
                $self->ivPoke('nextStatement', $elseStatement);
            }

        # Multi-line IF..END IF statement
        } else {

            # (Any ELSE IF statements are stored in $self->parseDataList)

            # Find the ELSE statement, if there is one
            $elseStatement = $self->ivShow('parseDataHash', 'else_statement');
            # Find the END IF statement
            $endIfStatement = $self->ivShow('parseDataHash', 'end_if_statement');

            # Compile a list of conditions to evaluate, starting with the one in the
            #   current statement, followed by all the ELSE IF statements
            @statementList = ($self, $self->parseDataList);

            # Evaluate each condition, looking for the first one which evaluates to
            #   'true'
            OUTER: foreach my $statement (@statementList) {

                my $cond = $statement->ivShow('parseDataHash', 'condition');

                if ($cond->evaluate()) {

                    $nextStatement = $statement;
                    last OUTER;
                }
            }

            if (! $nextStatement && $elseStatement) {

                # The conditions in IF and ELSE IF are all false, but there is an
                #   ELSE clause, so use it
                $nextStatement = $elseStatement;
            }

            if (! $nextStatement) {

                # All conditions are false (and there is no ELSE clause), so we need to skip to the
                #   end of the IF..END IF code block
                if (defined $endIfStatement->nextStatement) {

                    $self->scriptObj->set_nextStatement($endIfStatement->nextStatement);

                } else {

                    # The END IF statement was the last (or only) statement on the line: use the
                    #   next line
                    $self->scriptObj->set_nextLine($endIfStatement->lineObj->procLineNum + 1);
                }

            } else {

                # Add this IF..END IF code block to the main code block stack, since we're going
                #   to execute it now. The corresponding END IF statement will remove it.
                $subObj = $self->scriptObj->returnCurrentSub();
                $subObj->push_blockStackList($self);

                # Resume execution after the ELSE IF or ELSE statement
                if (defined $nextStatement->nextStatement) {

                    $self->scriptObj->set_nextStatement($nextStatement->nextStatement);

                } else {

                    # The ELSE IF/ELSE statement was the last (or only) statement on the line: use
                    #   the next line
                    $self->scriptObj->set_nextLine($nextStatement->lineObj->procLineNum + 1);
                }
            }
        }

        return 1;
    }
}

{ package Language::Axbasic::Statement::input;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::input::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # INPUT [ constant ; ] variable-name [ , variable-name ... ]
    # INPUT #channel: variable-name [ , variable-name ... ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $token, $channel, $promptExp,
            @lvalueList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # First token can be a constant, a file channel or the first of the variable names
        $token = $self->tokenGroupObj->lookAhead();
        if (! defined $token) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );

        # Get the file channel, if specified
        } elsif ($token->category eq 'file_channel') {

            $self->tokenGroupObj->shiftToken();

            # For INPUT statements, the file channel must include a colon at the end (e.g. '#5:' )
            if (! ($token->tokenText =~ m/\:$/)) {

                return $self->scriptObj->setError(
                    'syntax_error',
                    $self->_objClass . '->parse',
                );
            }

            # Get the channel number
            $token->tokenText =~ m/([0-9]+)/;
            $channel = $1;

            # True BASIC specifies that the channel must be in the range 1-999; same range used by
            #   Axbasic
            if ($channel < 1 || $channel > 999) {

                return $self->scriptObj->setError(
                    'file_channel_NUM_out_of_range',
                    $self->_objClass . '->parse',
                    'NUM', $channel,
                );

            } else {

                # Store the channel number; this also informs $self->implement that we're reading
                #    from a file, not the user's keyboard
                $self->ivAdd('parseDataHash', 'channel', $channel);
            }

        # Get the optional prompt text, if specified
        } elsif ($token->category eq 'string_constant') {

            # A text prompt was specified - it requires either a following comma or semicolon
            $promptExp = Language::Axbasic::Expression::Constant::String->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $self->tokenGroupObj->shiftMatchingToken(';')) {

                return $self->scriptObj->setError(
                    'missing_separator_after_INPUT_prompt',
                    $self->_objClass . '->parse',
                );
            }
        }

        # The rest of the arguments are variable names, separated by commas
        do {

            my $expression = Language::Axbasic::Expression::Lvalue->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $expression) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_variable',
                    $self->_objClass . '->parse',
                );

            } else {

                push (@lvalueList, $expression);
            }

        } until (! defined $self->tokenGroupObj->shiftMatchingToken(','));

        # Save the components so that $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'prompt_exp', $promptExp);
        $self->ivPush('parseDataList', @lvalueList);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $channel, $channelObj, $fileHandle, $promptExp, $prompt, $taskObj,
            @lvalueList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the components stored by $self->parse
        $channel = $self->ivShow('parseDataHash', 'channel');
        $promptExp = $self->ivShow('parseDataHash', 'prompt_exp');
        @lvalueList = $self->parseDataList;

        # Deal with reading from a file, if a file channel was specified
        if (defined $channel) {

            # Check that the file channel exists
            if (! $self->scriptObj->ivExists('fileChannelHash', $channel)) {

                return $self->scriptObj->setError(
                    'file_channel_NUM_not_open',
                    $self->_objClass . '->implement',
                    'NUM', $channel,
                );

            } else {

                $channelObj = $self->scriptObj->ivShow('fileChannelHash', $channel);
                $fileHandle = $channelObj->fileHandle;
            }

            # Check that reading from the file channel is allowed
            if ($channelObj->accessType eq 'output') {

                return $self->scriptObj->setError(
                    'file_channel_NUM_is_write_only',
                    $self->_objClass . '->implement',
                    'NUM', $channel,
                );
            }

            # Check that the pointer hasn't already reached end-of-file
            if (eof($fileHandle)) {

                return $self->scriptObj->setError(
                    'end_of_file_on_channel_NUM',
                    $self->_objClass . '->implement',
                    'NUM', $channel,
                );
            }

            # Read a file line for each value expected
            for (my $count = 0; $count < scalar @lvalueList; $count++) {

                my ($lvalue, $varObj, $line);

                $lvalue = $lvalueList[$count];
                $varObj = $lvalue->variable;

                # Read a line from the file
                $line = <$fileHandle>;
                chomp $line;

                if (! defined $line) {

                    return $self->scriptObj->setError(
                        'end_of_file_on_channel_NUM',
                        $self->_objClass . '->implement',
                        'NUM', $channel,
                    );

                } else {

                    # Set the variable
                    if ($line) {

                        $varObj->set($line);

                    } else {

                        if (ref($varObj) =~ m/Numeric/) {
                            $varObj->set(0);
                        } else {
                            $varObj->set('');
                        }
                    }
                }
            }

        } else {

            # Otherwise, we're reading from the user's keyboard. Evaluate the prompt expression (if
            #   there is one)
            if ($promptExp) {

                $prompt = $promptExp->evaluate();
            }

            # Import the parent task (if any)
            $taskObj = $self->scriptObj->parentTask;

            # If the task window is open and an entry box is available, use that window to get the
            #   input. Otherwise, open 'dialogue' windows to get the input
            if ($taskObj && $taskObj->taskWinEntryFlag) {

                # Display the prompt text, if it exists; if it doesn't, we must still display a
                #   question mark, because many BASIC scripts use a format like
                #       10 print "tell me";
                #       20 input a$
                # ...which forces Axmud to display unrelated text on the same line as the prompt
                if ($prompt) {
                    $taskObj->insertPrint($prompt . '? ');
                } else {
                    $taskObj->insertPrint('? ');
                }

                # Tell the script object how many lines of input to expect
                $self->scriptObj->set_inputList(@lvalueList);

                # Mark this script as 'waiting for INPUT' - it will be resumed automatically when
                #   the user types in the task window's entry box
                $self->scriptObj->set_scriptStatus('wait_input');

            } else {

                # Display the prompt text, if it exists; if it doesn't, we must still display a
                #   question mark, because many BASIC scripts use a format like
                #       10 print "tell me";
                #       20 input a$
                # ...which forces Axmud to display unrelated text on the same line as the prompt
                # NB The prompt is displayed both in the 'main' window, and in the dialogue box
                if ($prompt) {
                    $self->scriptObj->session->writeText($prompt . '? ', 'echo');
                } else {
                    $self->scriptObj->session->writeText('? ', 'echo');
                }

                # Use dialogue boxes - one for each value expected
                for (my $count = 0; $count < scalar @lvalueList; $count++) {

                    my ($lvalue, $varObj, $msg, $result);

                    $lvalue = $lvalueList[$count];
                    $varObj = $lvalue->variable;

                    if ($prompt) {
                        $msg = $prompt . '?';
                    } else {
                        $msg = 'Value?';
                    }

                    if (scalar @lvalueList > 1) {

                        $msg .= ' (' . ($count + 1) . '/' . scalar @lvalueList . ')';
                    }

                    # Open a 'dialogue' window to allow the user to input a value
                    $result = $self->scriptObj->session->mainWin->showEntryDialogue(
                        'Axbasic INPUT (' . $self->scriptObj->name . ')',
                        $msg,
                    );

                    if (! defined $result) {

                        # User clicked 'cancel' or closed the window
                        $self->scriptObj->session->writeText(' ');  # Cancel the earlier 'echo'

                        return $self->scriptObj->setError(
                            'user_declined_input_error',
                            $self->_objClass . '->implement',
                        );

                    } elsif ($result) {

                        # Set the variable
                        $varObj->set($result);

                        # Also display it in the 'main' window
                        $self->scriptObj->session->writeText($result);

                    } else {

                        # No value entered, so use a null value
                        if (ref($varObj) =~ m/Numeric/) {
                            $varObj->set(0);
                        } else {
                            $varObj->set('');
                        }

                        # Cancel the earlier 'echo' in the 'main' window
                        $self->scriptObj->session->writeText(' ');
                    }
                }
            }
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::let;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::let::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # [LET] variable-name = expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new when the first token
        #   in the statement is the keyword 'let', or when the first token in the statement isn't a
        #   keyword (which is an implied 'let')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($lvalue, $token, $subNameToken, $argListObj, $expression);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the variable name
        $lvalue = Language::Axbasic::Expression::Lvalue->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $lvalue) {

            return $self->scriptObj->setError(
                'missing_or_illegal_variable',
                $self->_objClass . '->parse',
            );
        }

        # Extract the assignment operator
        $token = $self->tokenGroupObj->shiftTokenIfCategory('assignment_operator');
        if (! defined $token) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );
        }

        # The rest of the statement is either an expression, the value of which should be assigned
        #   to the variable, or a subroutine call or PEEK statement, the return value of which
        #   should be assigned to the variable
        $token = $self->tokenGroupObj->lookAhead();
        if (! defined $token) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );
        }

        # If the first token is a recognised Axbasic keyword...
        if ($token->tokenText eq 'call') {

            # Eat the 'call' token
            $token = $self->tokenGroupObj->shiftToken();

            # Process the subroutine call using code from the CALL statement
            Language::Axbasic::Statement::call->parse($self);

            # Save the variable object. LA::Statement::call->implement will use it
            $self->ivAdd('parseDataHash', 'call_var', $lvalue->varObj);

        } else {

            $expression = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $expression) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }

            # Save the variable object and expression object so $self->implement can use them, if it
            #   is called
            $self->ivAdd('parseDataHash', 'lvalue', $lvalue);
            $self->ivAdd('parseDataHash', 'expression', $expression);
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($lvalue, $expression, $value, $variable);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # LET var$ = CALL subname (arglist)
        if ($self->ivExists('parseDataHash', 'call_var')) {

            # Process the subroutine call using code from the CALL statement
            Language::Axbasic::Statement::call->implement($self);

        # LET var$ = <expression>
        } else {

            # Get the values stored by $self->parse
            $lvalue = $self->ivShow('parseDataHash', 'lvalue');
            $expression = $self->ivShow('parseDataHash', 'expression');

            $variable = $lvalue->variable;
            if (! defined $variable) {

                # $variable might be 'undef' if we use a script like
                #   DIM var$ (5)
                #   LET var$ (6) = "hello";
                return undef;
            }

            # Set the variable's value
            $value = $expression->evaluate();
            $variable->set($value);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::local;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::local::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # LOCAL variable-name [ , variable-name ... ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($token, $argListObj, $result);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # The 'local' keyword is not available in primitive numbering mode
        if ($self->scriptObj->executionMode ne 'no_line_num') {

            return $self->scriptObj->setError(
                'statement_not_available_with_line_numbers',
                $self->_objClass . '->parse',
            );
        }

        # Temporarily set the IV that allows undeclared variables to be created
        $self->scriptObj->set_declareMode('local_scalar');

        # Process each array in turn (if several appear on the same line, they are separated by
        #   commas)
        do {

            my $lvalue = Language::Axbasic::Expression::Lvalue->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $lvalue) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_variable',
                    $self->_objClass . '->parse',
                );
            }

        } while (defined $self->tokenGroupObj->shiftMatchingToken(','));

        # Reset the temporary IV
        $self->scriptObj->set_declareMode('default');

        # Check there is nothing else (except for the statement separator, :)
        $result = $self->tokenGroupObj->testStatementEnd();
        if (! defined $result) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Save the arglist so that ->implement can add all these variables to the global variable
        #   hash, when the line is executed
        $self->ivAdd('parseDataHash', 'arg_list_obj', $argListObj);

        # Parsing complete
        return 1;
    }

#   sub implement {}        # No ->implement method - LA::Variable->lookup has already added the
                            #   variable to LA::Subroutine->localScalarHash or ->localArrayHash
}

{ package Language::Axbasic::Statement::login;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::login::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # LOGIN

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)

        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # LOGIN statements always appear on their own
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Tell the GA::Session that the automatic login is complete (if the character is already
        #   marked as 'logged in', nothing happens
        $self->scriptObj->session->doLogin();

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::loop;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::loop::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # LOOP

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($subObj, $whileStatement);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # The 'loop' keyword is not available in primitive numbering mode
        if ($self->scriptObj->executionMode ne 'no_line_num') {

            return $self->scriptObj->setError(
                'statement_not_available_with_line_numbers',
                $self->_objClass . '->parse',
            );
        }

        # LOOP statements always appear on their own
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Find the matching WHILE statement, which should already have been parsed
        $subObj = $self->scriptObj->returnCurrentSub();
        if (! $subObj->whileStackList) {

            return $self->scriptObj->setError(
                'LOOP_statement_without_matching_WHILE',
                $self->_objClass . '->parse',
            );

        } else {

            $whileStatement = $subObj->pop_whileStackList();

            # Tell the WHILE statement's ->implement what its matching LOOP statement (i.e. this
            #   one) is
            $whileStatement->add_parseDataHash('loop_statement', $self);
            # Store the WHILE statement so this statement's ->implement can use it
            $self->ivAdd('parseDataHash', 'while_statement', $whileStatement);
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($whileStatement, $subObj, $topStatement);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the paired WHILE statement
        $whileStatement = $self->ivShow('parseDataHash', 'while_statement');

        # Skip to the beginning of the WHILE..LOOP code block
        $self->scriptObj->set_nextLine($whileStatement->lineObj->procLineNum);
        $self->scriptObj->set_nextStatement(undef);

        # Remove this code block from the standard code block stack. (The WHILE statement puts it
        #   straight back, if the code block is to be executed again.)
        $subObj = $self->scriptObj->returnCurrentSub();
        if (! $subObj->blockStackList) {

            return $self->scriptObj->setError(
                'LOOP_statement_without_matching_WHILE',
                $self->_objClass . '->implement',
            );

        } else {

            $topStatement = $subObj->pop_blockStackList();

            # The statement at the top of the stack must be a WHILE statement, not another kind of
            #   code block
            if ($topStatement->keyword ne 'while') {

                return $self->scriptObj->setError(
                    'LOOP_statement_without_matching_WHILE',
                    $self->_objClass . '->implement',
                );
            }
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::move;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::move::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # MOVE expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the expression and store it for ->implement to use
        $expression = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );

        } else {

            $self->ivAdd('parseDataHash', 'expression', $expression);
        }

        # There should be nothing after the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression, $cmd);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the expression to be played
        $expression = $self->ivShow('parseDataHash', 'expression');
        # Evaluate the expression to get a world command
        $cmd = $expression->evaluate();

        # Send the command to the world
        $self->scriptObj->session->moveCmd($cmd);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::multi;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::multi::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # MULTI expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the expression and store it for ->implement to use
        $expression = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );

        } else {

            $self->ivAdd('parseDataHash', 'expression', $expression);
        }

        # There should be nothing after the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression, $string);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the expression to be written
        $expression = $self->ivShow('parseDataHash', 'expression');
        # Evaluate the expression to get a scalar value
        $string = $expression->evaluate();

        # Execute the expression as a multi command
        $self->scriptObj->session->multiCmd($string);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::next;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::next::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # NEXT variable-name

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $lvalue;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Read the iterator variable name
        $lvalue = Language::Axbasic::Expression::Lvalue->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $lvalue) {

            return $self->scriptObj->setError(
                'missing_or_illegal_iterator',
                $self->_objClass . '->parse',
            );

        } elsif ($lvalue->isa('Language::Axbasic::Expression::String')) {

            return $self->scriptObj->setError(
                'missing_or_illegal_iterator',
                $self->_objClass . '->parse',
            );

        } else {

            # Store the iterator, so $self->implement can retrieve it
            $self->ivAdd('parseDataHash', 'lvalue', $lvalue);
        }

        # Check there's nothing else in the statement after the iterator
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $lvalue, $subObj, $forStatement, $exitFlag, $forLvalue, $forTermExp, $forStepExp, $term,
            $step, $var, $value,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the iterator stored by $self->parse
        $lvalue = $self->ivShow('parseDataHash', 'lvalue');

        # Get the corresponding FOR statement from the current subroutine's code block stack. Keep
        #   removing code blocks from the top of the stack until we get the right one
        $subObj = $self->scriptObj->returnCurrentSub();
        if (! $subObj->blockStackList) {

            return $self->scriptObj->setError(
                'NEXT_statement_without_matching_FOR',
                $self->_objClass . '->implement',
            );
        }

        do {

            $forStatement = $subObj->pop_blockStackList();

            # Check that it's a FOR statement - not the start of another kind of code block - and
            #   that it's the right iterator
            if (
                $forStatement->keyword eq 'for'
                && $forStatement->ivShow('parseDataHash', 'lvalue')->varObj eq $lvalue->varObj
            ) {
                # We've found the statement we're looking for
                $exitFlag = TRUE;
            }

        } until ($exitFlag || ! $subObj->blockStackList);

        if (! $exitFlag) {

            return $self->scriptObj->setError(
                'NEXT_statement_without_matching_FOR',
                $self->_objClass . '->implement',
            );
        }

        # Import the stored data from the matching FOR statement
        $forLvalue = $forStatement->ivShow('parseDataHash', 'lvalue');
        $forTermExp = $forStatement->ivShow('parseDataHash', 'term_exp');
        $forStepExp = $forStatement->ivShow('parseDataHash', 'step_exp');

        # Evaluate the termination and step expressions. Store them so that, during a FOR..NEXT
        #    loop, we only have to evaluate the expressions once
        if (! $self->ivExists('parseDataHash', 'term_value')) {

            $term = $forTermExp->evaluate();
            $step = $forStepExp->evaluate();

            $self->ivAdd('parseDataHash', 'term_value', $term);
            $self->ivAdd('parseDataHash', 'step_value', $step);

        } else {

            $term = $self->ivShow('parseDataHash', 'term_value');
            $step = $self->ivShow('parseDataHash', 'step_value');
        }

        # Increment the iterator variable
        $var = $lvalue->variable;
        $value = $var->value;
        $value += $step;
        $var->set($value);

        # Termination test
        if (! ($step > 0 && $value > $term) || ($step < 0 && $value < $term)) {

            # Perform another iteration of the loop. Go to the statement immediately after the
            #   corresponding FOR statement
            if (defined $forStatement->nextStatement) {

                $self->scriptObj->set_nextStatement($forStatement->nextStatement);

            } else {

                # The FOR statement was the last (or only) statement on the line: use the next line
                $self->scriptObj->set_nextLine($forStatement->lineObj->procLineNum + 1);
            }

            # Put the corresponding 'for' statement back into the current subroutine's code block
            #   stack
            $subObj->push_blockStackList($forStatement);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::nextiface;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::nextiface::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # NEXTIFACE

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($subObj, $whileStatement);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # NEXTIFACE statements always appear on their own
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Do nothing, if the interface notification list is empty
        if (! $self->scriptObj->notificationList) {

            # Implementation complete
            return 1;

        } else {

            # Remove the current interface from the list
            $self->scriptObj->rmv_currentNotification();
            if ($self->scriptObj->notificationList) {

                # The next current notification is the first one in the list
                $self->scriptObj->set_currentNotification(0);

            } else {

                # The list is empty. Mark this with the value -1
                $self->scriptObj->set_currentNotification(-1);
            }
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::on;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::on::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # ON expression GOTO expression [ , expression ... ]
    # ON expression GOSUB expression [ , expression ... ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $expression, $token, $statementType,
            @lineList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # The 'on' keyword is only available in primitive numbering mode
        if ($self->scriptObj->executionMode ne 'line_num') {

            return $self->scriptObj->setError(
                'statement_not_available_without_line_numbers',
                $self->_objClass . '->parse',
            );
        }

        # Everything up to the 'gosub' or 'goto' token is an arithmetic expression
        $expression = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Extract the 'gosub'/'goto' token
        $token = $self->tokenGroupObj->shiftTokenIfCategory('keyword');
        if (! defined $token || ($token->tokenText ne 'gosub' && $token->tokenText ne 'goto')) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );

        } else {

            # Remember if it's a 'gosub' or a 'goto'
            $statementType = $token->tokenText;
        }

        # The remaining tokens should be line numbers, separated by commas
        do {

            my $lineNumber = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $lineNumber) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );

            } else {

                push (@lineList, $lineNumber);
            }

        } while (defined $self->tokenGroupObj->shiftMatchingToken(','));

        # Store the data, so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'expression', $expression);
        $self->ivAdd('parseDataHash', 'statement_type', $statementType);
        $self->ivPush('parseDataList', @lineList);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
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
            $expression, $statementType, $line, $lineNumber, $value,
            @lineList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the data stored by ->parse
        $expression = $self->ivShow('parseDataHash', 'expression');
        $statementType = $self->ivShow('parseDataHash', 'statement_type');
        @lineList = $self->parseDataList;

        # Evaluate the main expression
        $value = $expression->evaluate();
        if (! defined $value || ! ($value =~ /^\d+$/) || $value > @lineList) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->implement',
                'VALUE', $value,
            );
        }

        # If $value == n, the line number to jump to is the [n-1]th value in @lineList
        $line = $lineList[$value - 1];
        $lineNumber = $line->evaluate();
        if (! defined $lineNumber || ! ($lineNumber =~ /^\d+$/)) {

            return $self->scriptObj->setError(
                'illegal_line_number_NUM',
                $self->_objClass . '->implement',
                'NUM', $lineNumber,
            );
        }

        # Check that the primitive line number exists
        if (! $self->scriptObj->ivExists('primLineHash', $lineNumber)) {

            return $self->scriptObj->setError(
                'line_number_NUM_not_found',
                $self->_objClass . '->implement',
                'NUM', $lineNumber,
            );
        }

        if ($statementType eq 'gosub') {

            # Push the current statement onto the subroutine stack
            $self->scriptObj->push_gosubStackList($self);
        }

        # Set the next line/statement to be executed
        $self->scriptObj->set_nextLine($self->scriptObj->ivShow('primLineHash', $lineNumber));
        $self->scriptObj->set_nextStatement(undef);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::open;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::open::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # OPEN #channel: NAME expression
    #   [, ORGANIZATION TEXT ] [, CREATE NEW|OLD|NEWOLD ] [, ACCESS OUTIN|INPUT|OUTPUT ]
    # OPEN #channel: NAME expression
    #   [, ORGANIZATION expression ] [, CREATE expression ] [, ACCESS expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($channelToken, $channel, $nameFlag);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the channel token. For OPEN statements, it must include a colon at the end
        #   (e.g. '#5:' )
        $channelToken = $self->tokenGroupObj->shiftTokenIfCategory('file_channel');
        if (! defined $channelToken || ! ($channelToken->tokenText =~ m/\:$/)) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );

        } else {

            # Store the channel number
            $channelToken->tokenText =~ m/([0-9]+)/;
            $channel = $1;

            # True BASIC specifies that the channel must be in the range 1-999; same range used by
            #   Axbasic
            if ($channel < 1 || $channel > 999) {

                return $self->scriptObj->setError(
                    'file_channel_NUM_out_of_range',
                    $self->_objClass . '->parse',
                    'NUM', $channel,
                );

            } else {

                $self->ivAdd('parseDataHash', 'channel', $channel);
            }
        }

        # The rest of the arguments will be separated by commas
        do {

            my ($token, $expression, $nextToken);

            $token = $self->tokenGroupObj->shiftToken();
            if ($token) {

                if ($token->category ne 'keyword') {

                    return $self->scriptObj->setError(
                        'syntax_error',
                        $self->_objClass . '->parse',
                    );

                } elsif ($token->tokenText eq 'name') {

                    # Next token is an expression for the file name
                    $expression = Language::Axbasic::Expression::Arithmetic->new(
                        $self->scriptObj,
                        $self->tokenGroupObj,
                    );

                    if (! defined $expression) {

                        return $self->scriptObj->setError(
                            'missing_or_illegal_expression',
                            $self->_objClass . '->parse',
                        );

                    } else {

                        # Store the file expression
                        $self->ivAdd('parseDataHash', 'file_exp', $expression);
                        $nameFlag = TRUE;
                    }

                } elsif ($token->tokenText eq 'organization' || $token->tokenText eq 'org') {

                    # Next token must be the keyword TEXT (True BASIC also uses STREAM, RANDOM,
                    #   RECORD and BYTE, but Axbasic does not implement them)
                    # (Can also be an expression evaluating to 'text')
                    $nextToken = $self->tokenGroupObj->shiftMatchingToken('text');
                    if (! $nextToken) {

                        $expression = Language::Axbasic::Expression::Arithmetic->new(
                            $self->scriptObj,
                            $self->tokenGroupObj,
                        );

                        if (! $expression) {

                            return $self->scriptObj->setError(
                                'syntax_error',
                                $self->_objClass . '->parse',
                            );

                        } else {

                            # Store the expression, for $self->implement to evaluate
                            $self->ivAdd('parseDataHash', 'org_exp', $expression);
                        }

                    } else {

                        # Axbasic only reads/writes text files, but we'll store value for
                        #   $self->implemement to retrieve anyway
                        $self->ivAdd('parseDataHash', 'org_type', 'text');
                    }

                } elsif ($token->tokenText eq 'create') {

                    # Next token must be one of the keywords NEW, OLD, NEWOLD (can also be an
                    #   expression evaluating to 'new', 'old' or 'newold')
                    $nextToken = $self->tokenGroupObj->shiftTokenIfCategory('keyword');
                    if (! $nextToken) {

                        $expression = Language::Axbasic::Expression::Arithmetic->new(
                            $self->scriptObj,
                            $self->tokenGroupObj,
                        );

                        if (! $expression) {

                            return $self->scriptObj->setError(
                                'syntax_error',
                                $self->_objClass . '->parse',
                            );

                        } else {

                            # Store the expression, for $self->implement to evaluate
                            $self->ivAdd('parseDataHash', 'create_exp', $expression);
                        }

                    } else {

                        if (
                            $nextToken->tokenText eq 'new'
                            || $nextToken->tokenText eq 'old'
                            || $nextToken->tokenText eq 'newold'
                        ) {
                            # Store the create file mode
                            $self->ivAdd('parseDataHash', 'create_type', $nextToken->tokenText);

                        } else {

                            return $self->scriptObj->setError(
                                'syntax_error',
                                $self->_objClass . '->parse',
                            );
                        }
                    }

                } elsif ($token->tokenText eq 'access') {

                    # Next token must be one of the keywords OUTIN, INPUT, OUTPUT (can also be an
                    #   expression evaluating to 'outin', 'input' or 'output')
                    $nextToken = $self->tokenGroupObj->shiftTokenIfCategory('keyword');
                    if (! $nextToken) {

                        $expression = Language::Axbasic::Expression::Arithmetic->new(
                            $self->scriptObj,
                            $self->tokenGroupObj,
                        );

                        if (! $expression) {

                            return $self->scriptObj->setError(
                                'syntax_error',
                                $self->_objClass . '->parse',
                            );

                        } else {

                            # Store the expression, for $self->implement to evaluate
                            $self->ivAdd('parseDataHash', 'access_exp', $expression);
                        }

                    } else {

                        if (
                            $nextToken->tokenText eq 'outin'
                            || $nextToken->tokenText eq 'input'
                            || $nextToken->tokenText eq 'output'
                        ) {
                            # Store the create file mode
                            $self->ivAdd('parseDataHash', 'access_type', $nextToken->tokenText);

                        } else {

                            return $self->scriptObj->setError(
                                'syntax_error',
                                $self->_objClass . '->parse',
                            );
                        }
                    }

                } else {

                    return $self->scriptObj->setError(
                        'syntax_error',
                        $self->_objClass . '->parse',
                    );
                }
            }

        } until (! defined $self->tokenGroupObj->shiftMatchingToken(','));

        # The NAME keyword, followed by a file expression, are compulsory
        if (! $nameFlag) {

            return $self->scriptObj->setError(
                'missing_file_NAME_in_OPEN_statement',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $channel, $fileExp, $orgType, $orgExp, $createType, $createExp, $accessType, $accessExp,
            $channelCount, $channelObj, $filePath, $file, $directory, $fileMode, $fileHandle,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the variables stored by ->parse
        $channel = $self->ivShow('parseDataHash', 'channel');
        $fileExp = $self->ivShow('parseDataHash', 'file_exp');
        $orgType = $self->ivShow('parseDataHash', 'org_type');          # Recognised, but not used
        $orgExp = $self->ivShow('parseDataHash', 'org_exp');
        $createType = $self->ivShow('parseDataHash', 'create_type');
        $createExp = $self->ivShow('parseDataHash', 'create_exp');
        $accessType = $self->ivShow('parseDataHash', 'access_type');
        $accessExp = $self->ivShow('parseDataHash', 'access_exp');

        # Check that the file channel is not already open
        if ($self->scriptObj->ivExists('fileChannelHash', $channel)) {

            return $self->scriptObj->setError(
                'file_channel_NUM_already_open',
                $self->_objClass . '->implement',
                'NUM', $channel,
            );
        }

        # Check that there aren't already too many channels open. True BASIC specifies a limit of
        #   25 simultaneous channels; same limit used by Axbasic
        $channelCount = $self->scriptObj->ivPairs('fineChannelHash');
        if ($channelCount >= 25) {

            return $self->scriptObj->setError(
                'file_channel_limit_reached',
                $self->_objClass . '->implement',
                'NUM', $channel,
            );
        }

        # OPEN statements can contain TEXT, NEW, OLD, NEWOLD, OUTIN, INPUT, OUTPUT option keywords.
        #   If expressions were used instead, evaluate the expression
        if ($orgExp) {

            $orgType = lc($orgExp->evaluate());
            if (! $orgType || $orgType ne 'text') {

                return $self->scriptObj->setError(
                    'invalid_option_in_OPEN_statement',
                    $self->_objClass . '->implement',
                );
            }
        }

        if ($createExp) {

            $createType = lc($createExp->evaluate());
            if (
                ! $createType
                || ($createType ne 'new' && $createType ne 'old' && $createType ne 'newold')
            ) {
                return $self->scriptObj->setError(
                    'invalid_option_in_OPEN_statement',
                    $self->_objClass . '->implement',
                );
            }
        }

        if ($accessExp) {

            $accessType = lc($accessExp->evaluate());
            if (
                ! $accessType
                || ($accessType ne 'outin' && $accessType ne 'input' && $accessType ne 'output')
            ) {
                return $self->scriptObj->setError(
                    'invalid_option_in_OPEN_statement',
                    $self->_objClass . '->implement',
                );
            }
        }

        # OPEN statements can contain ORGANIZATION, CREATE and ACCESS option keywords but, if not,
        #   set the default values
        if (! defined $orgType) {

            $orgType = 'text';
        }

        if (! defined $createType) {

            $createType = 'old';
        }

        if (! defined $accessType) {

            $accessType = 'outin';
        }

        # Evaluate the filepath expression
        $filePath = $fileExp->evaluate();
        if (! $filePath) {

            return $self->scriptObj->setError(
                'invalid_file_path',
                $self->_objClass . '->implement',
            );

        } else {

            # Assuming that $filePath is relative to the script's directory, convert it to an
            #   absolute filepath
            # LA::Script->filePath is the path to the script's .bas file. Get its directory
            ($file, $directory) = File::Basename::fileparse($self->scriptObj->filePath);
            if ($directory) {

                $filePath = $directory . $filePath;
            }
        }

        # For CREATE NEW, display an error if the file already exists
        if ($createType eq 'new' && -e $filePath) {

            return $self->scriptObj->setError(
                'file_already_exists',
                $self->_objClass . '->implement',
            );
        }

        # For CREATE OLD, check that the file actually exists
        if ($createType eq 'old' && ! -e $filePath) {

            return $self->scriptObj->setError(
                'file_does_not_exist',
                $self->_objClass . '->implement',
            );
        }

        # CREATE NEW can't be used with ACCESS INPUT - can't read a file that doesn't exist
        if ($createType eq 'new' && $accessType eq 'input') {

            return $self->scriptObj->setError(
                'invalid_OPEN_statement_options',
                $self->_objClass . '->implement',
            );
        }

        # Axbasic simplifies things by opening a file in 'read/write' mode; every subsequent INPUT /
        #   PRINT statement that uses this file channel checks the options specified by the CREATE
        #   and ACCESS keywords, to make sure reading/writing is allowed
        if (! open ($fileHandle, "+>>", $filePath)) {       # Read/write, create, don't truncate

            return $self->scriptObj->setError(
                'failed_to_open_file',
                $self->_objClass . '->implement',
            );
        }

        # However, for read-only and read/write modes, need to move the pointer to the beginning of
        #   the file
        if ($accessType ne 'output') {

            seek($fileHandle, 0, Fcntl::SEEK_SET);
        }

        # File channel open. Create a file channel object
        $channelObj = Language::Axbasic::FileChannel->new(
            $self->scriptObj,
            $channel,
            $filePath,
            $fileHandle,
            $orgType,
            $createType,
            $accessType,
        );

        if (! $channelObj) {

            return $self->scriptObj->setError(
                'failed_to_open_channel',
                $self->_objClass . '->implement',
            );

        } else {

            # Update the script's IVs
            $self->scriptObj->add_fileChannel($channelObj);

            # Implementation complete
            return 1;
        }
    }
}

{ package Language::Axbasic::Statement::openentry;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::openentry::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # OPENENTRY

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # OPENENTRY statements always appear on their own
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script is being run from within an Axmud task, open the window (unless one
        #   is already open). Otherwise, do nothing
        if ($self->scriptObj->parentTask && ! $self->scriptObj->parentTask->taskWinFlag) {

            # Open a task window with an entry box (by specifying these arguments, we get either a
            #   'grid' window or a pane object in the session's 'main' window, both using an
            #   entry box)
            $self->scriptObj->parentTask->openWin('entry_fill', 'pane', 'grid');
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::openwin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::openwin::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # OPENWIN

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # OPENWIN statements always appear on their own
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script is being run from within an Axmud task, open the window (unless one
        #   is already open). Otherwise, do nothing
        if ($self->scriptObj->parentTask && ! $self->scriptObj->parentTask->taskWinFlag) {

            # Open a task window with an entry box (by specifying these arguments, we get either a
            #   'grid' window or a pane object in the session's 'main' window, neither using an
            #   entry box)
            $self->scriptObj->parentTask->openWin('basic_fill', 'entry', 'grid');
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::option;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::option::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # OPTION ANGLE DEGREES
    # OPTION ANGLE RADIANS
    # OPTION DIVERT
    # OPTION NEEDTASK
    # OPTION NOLET
    # OPTION PERSIST
    # OPTION PSEUDO expression
    # OPTION REQUIRE expression
    # OPTION TYPO

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($token, $expression, $value);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # OPTION ANGLE DEGREES statement
        # OPTION ANGLE RADIANS statement
        $token = $self->tokenGroupObj->shiftMatchingToken('angle');
        if (defined $token) {

            $token = $self->tokenGroupObj->shiftMatchingToken('degrees');
            if (! defined $token) {

                $token = $self->tokenGroupObj->shiftMatchingToken('radians');
            }

            if (defined $token) {

                if (! $self->tokenGroupObj->testStatementEnd()) {

                    return $self->scriptObj->setError(
                        'unexpected_keywords,_operators_or_expressions',
                        $self->_objClass . '->parse',
                    );

                } elsif ($token->tokenText eq 'degrees') {

                    $self->scriptObj->add_optionStatement('angle', 'degrees');

                } else {

                    $self->scriptObj->add_optionStatement('angle', 'radians');
                }

                return 1;

            } else {

                return $self->scriptObj->setError(
                    'syntax_error',
                    $self->_objClass . '->parse',
                );
            }
        }

        # OPTION DIVERT statement
        $token = $self->tokenGroupObj->shiftMatchingToken('divert');
        if (defined $token) {

            if (! $self->tokenGroupObj->testStatementEnd()) {

                return $self->scriptObj->setError(
                    'unexpected_keywords,_operators_or_expressions',
                    $self->_objClass . '->parse',
                );

            } else {

                $self->scriptObj->add_optionStatement('divert', TRUE);
                return 1;
            }
        }

        # OPTION NEEDTASK statement
        $token = $self->tokenGroupObj->shiftMatchingToken('needtask');
        if (defined $token) {

            if (! $self->tokenGroupObj->testStatementEnd()) {

                return $self->scriptObj->setError(
                    'unexpected_keywords,_operators_or_expressions',
                    $self->_objClass . '->parse',
                );

            } elsif (! $self->scriptObj->parentTask) {

                return $self->scriptObj->setError(
                    'script_cannot_run_without_parent_task',
                    $self->_objClass . '->parse',
                );

            } else {

                $self->scriptObj->add_optionStatement('needtask', TRUE);
                return 1;
            }
        }

        # OPTION NOLET statement
        $token = $self->tokenGroupObj->shiftMatchingToken('nolet');
        if (defined $token) {

            if (! $self->tokenGroupObj->testStatementEnd()) {

                return $self->scriptObj->setError(
                    'unexpected_keywords,_operators_or_expressions',
                    $self->_objClass . '->parse',
                );

            } else {

                $self->scriptObj->add_optionStatement('nolet', TRUE);
                return 1;
            }
        }

        # OPTION PERSIST statement
        $token = $self->tokenGroupObj->shiftMatchingToken('persist');
        if (defined $token) {

            if (! $self->tokenGroupObj->testStatementEnd()) {

                return $self->scriptObj->setError(
                    'unexpected_keywords,_operators_or_expressions',
                    $self->_objClass . '->parse',
                );

            } else {

                $self->scriptObj->add_optionStatement('persist', TRUE);
                return 1;
            }
        }

        # OPTION PSEUDO String-Exp
        $token = $self->tokenGroupObj->shiftMatchingToken('pseudo');
        if (defined $token) {

            # Get the expression
            $expression = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $expression) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }

            # There should be nothing more
            if (! $self->tokenGroupObj->testStatementEnd()) {

                return $self->scriptObj->setError(
                    'unexpected_keywords,_operators_or_expressions',
                    $self->_objClass . '->parse',
                );
            }

            # Check that a valid expression  has been specified
            # Evaluate the expression
            $value = $expression->evaluate();
            if (
                ! defined $value
                || (
                    $value ne 'show_all' && $value ne 'hide_complete' && $value ne 'hide_system'
                    && $value ne 'win_error' && $value ne 'win_only'
                )
            ) {
                return $self->scriptObj->setError(
                    'invalid_expression',
                    $self->_objClass . '->parse',
                )
            }

            # Set the new pseudo-command mode
            $self->scriptObj->add_optionStatement('pseudo', $value);
            $self->scriptObj->set_pseudoCmdMode($value);

            return 1;
        }

        # OPTION REQUIRE Arith-Exp statement
        $token = $self->tokenGroupObj->shiftMatchingToken('require');
        if (defined $token) {

            # Get the expression
            $expression = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $expression) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }

            # There should be nothing more
            if (! $self->tokenGroupObj->testStatementEnd()) {

                return $self->scriptObj->setError(
                    'unexpected_keywords,_operators_or_expressions',
                    $self->_objClass . '->parse',
                );
            }

            # Check that a valid expression (floating point numbers, 1.0 or above) has been
            #   specified
            # Evaluate the expression
            $value = $expression->evaluate();
            if (
                ! defined $value
                || ! ($value =~ /^-?(?:\d+\.?|\.\d)\d*\z/)
            ) {
                return $self->scriptObj->setError(
                    'invalid_version',
                    $self->_objClass . '->parse',
                )

            } elsif ($value < 1) {

                return $self->scriptObj->setError(
                    'version_NUM_out_of_range',
                    $self->_objClass . '->parse',
                    'NUM', $value,
                )

            } elsif ($value > $axmud::BASIC_VERSION) {

                return $self->scriptObj->setError(
                    'script_requires_version_NUM',
                    $self->_objClass . '->parse',
                    'NUM', $value,
                );
            }

            # Set the new minimum version
            $self->scriptObj->add_optionStatement('require', $value);

            return 1;
        }

        # OPTION TYPO statement
        $token = $self->tokenGroupObj->shiftMatchingToken('typo');
        if (defined $token) {

            if (! $self->tokenGroupObj->testStatementEnd()) {

                return $self->scriptObj->setError(
                    'unexpected_keywords,_operators_or_expressions',
                    $self->_objClass . '->parse',
                );

            } else {

                $self->scriptObj->add_optionStatement('typo', TRUE);

                return 1;
            }
        }

        # Default
        return $self->scriptObj->setError(
            'syntax_error',
            $self->_objClass . '->parse',
        );

        # Parsing complete
        return 1;
    }

    # No ->implement function needed
}

{ package Language::Axbasic::Statement::paintwin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::paintwin::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PAINTWIN [ expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $paintExp;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        if (! $self->tokenGroupObj->testStatementEnd()) {

            # Convert the name string into an expression
            $paintExp = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $paintExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Check that nothing more remains
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        if ($paintExp) {

            # Store the expression, so $self->implement can retrieve it
            $self->ivAdd('parseDataHash', 'paint_exp', $paintExp);
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($paintExp, $paint, $mode, $taskObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the argument stored by $self->parse
        $paintExp = $self->ivShow('parseDataHash', 'paint_exp');

        if (defined $paintExp) {

            # Evaluate the expression
            $paint = $paintExp->evaluate();
        }

        # Import the parent task (if any)
        $taskObj = $self->scriptObj->parentTask;

        # If the Axbasic script is being run from within an Axmud task and the window is open, paint
        #   it. Otherwise, do nothing
        if ($taskObj && $taskObj->taskWinFlag) {

            if (defined $paintExp) {

                # Evaluate the expression
                $paint = $paintExp->evaluate();
                # Is it a valid Axmud standard colour tag (not xterm or RGB)?
                ($mode) = $axmud::CLIENT->checkColourTags($paint, 'standard');
                if (! $mode) {

                    return $self->scriptObj->setError(
                        'invalid_colour_tag_TAG',
                        $self->_objClass . '->implement',
                        'TAG',
                        $paint,
                    );
                }
            }

            # Paint the window
            $taskObj->paintWin($paint);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::pause;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::pause::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PAUSE expression
    # SLEEP expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # The rest of the statement is an arithemetic expression which evaluates to a number of
        #   seconds
        $expression = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Check that nothing follows the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the arithmetic expression, so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'expression', $expression);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression, $seconds);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the variable stored by ->parse
        $expression = $self->ivShow('parseDataHash', 'expression');

        # Evaluate the expression to get a number of seconds (which can be fractional, but must be
        #   > 0)
        $seconds = $expression->evaluate();
        if (! ($seconds =~  /^\d+$/)) {

            return $self->scriptObj->setError(
                'invalid_integer',
                $self->_objClass . '->implement',
            );

        } elsif ($seconds < 1) {

            return $self->scriptObj->setError(

                'number_NUM_out_of_range',
                $self->_objClass . '->parse',
                'NUM', $seconds,
            );
        }

        # If the Axbasic script is being run from within an Axmud task, pause execution, otherwise
        #   do nothing
        if ($self->scriptObj->parentTask) {

            # Mark this script as paused
            $self->scriptObj->set_scriptStatus('paused');
            # Reset the number of steps to take, before taking an automatic pause
            $self->scriptObj->set_stepCount(0);

            # Also, tell the parent task to pause...
            $self->scriptObj->parentTask->pauseUntil(
                ($self->scriptObj->session->sessionTime + $seconds),
            );
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::peek;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::peek::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PEEK variable-name = axmud-object-name
    # PEEK variable-name = axmud-object-property
    # PEEK ARRAY variable-name = axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract the standard PEEK... tokens. If the extraction is successful, they are stored in
        #   $self->parseDataHash, ready for $self->implement to access
        if (! $self->parsePeek()) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $parseArrayFlag, $basicVarName, $expression, $expValue, $successFlag, $blessed, $ivName,
            $var, $objFlag, $privFlag, $scalar, $varObj,
            @array,
            # Custom (set after $varObj is set)
            $impScalarFlag, $impArrayFlag,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $parseArrayFlag = $self->ivShow('parseDataHash', 'array_flag');
        $basicVarName = $self->ivShow('parseDataHash', 'var_name');
        $expression = $self->ivShow('parseDataHash', 'expression');

        # Evaluate the expression to get the Axmud internal variable, e.g. "world.current.name"
        $expValue = $expression->evaluate();
        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($expValue);
        if (! $successFlag) {

            return $self->scriptObj->setError(
                'PEEK_operation_failure',
                $self->_objClass . '->implement',
            );
        }

        # Import the Axmud internal variable, setting $scalar if $string refers to a scalar value,
        #   or @array if $string refers to a list or hash value
        if (! $objFlag) {

            if (! defined $var) {

                $scalar = undef;
                $impScalarFlag = TRUE;

            } elsif (ref($var) eq 'ARRAY') {

                @array = @$var;
                $impArrayFlag = TRUE;

            } elsif (ref($var) eq 'HASH') {

                @array = %$var;
                $impArrayFlag = TRUE;  # Perl hash gets converted to an Axbasic array

            } else {

                $scalar = $var;
                $impScalarFlag = TRUE;
            }

            # If this was a PEEK ARRAY statement, but the IV is a scalar, copy it into the first
            #   cell of the Axbasic array (being an array containing 1 element)
            if ($impScalarFlag && $parseArrayFlag) {

                push (@array, $scalar);

            # Don't let the user copy a list/hash IV into an Axbasic scalar variable
            } elsif ($impArrayFlag && ! $parseArrayFlag) {

                return $self->scriptObj->setError(
                    'PEEK_operation_failure',
                    $self->_objClass . '->implement',
                );
            }

        } else {

            # Set $scalar to the Perl object
            if ($parseArrayFlag) {

                # We'll let the user copy an Axmud scalar IV into an Axbasic array, but we won't let
                #   them copy a Perl object into an Axbasic array
                return $self->scriptObj->setError(
                    'PEEK_operation_failure',
                    $self->_objClass . '->implement',
                );

            } else {

                $scalar = $blessed;
                $impScalarFlag = TRUE;
            }
        }

        # Look up the LA::Variable
        $varObj = $self->fetchVar('PEEK', $basicVarName, $parseArrayFlag);
        if (! $varObj) {

            # (self->scriptObj->setError already called)
            return undef;
        }

        # Now we can set the variable to PEEK's return value
        if (! $parseArrayFlag) {

            # Import the scalar into an Axbasic scalar variable, converting Perl 'undef' as
            #   neccesary
            $self->importAsScalar($varObj, $scalar);

        } else {

            # Import the list/hash into an Axbasic array, resizing it as necessary
            $self->importAsArray($varObj, @array);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::peekequals;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::peekequals::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PEEKEQUALS variable-name = axmud-object-property, expression
    # PEEKEQUALS ARRAY variable-name = axmud-object-property, expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract the standard PEEK... tokens. If the extraction is successful, they are stored in
        #   $self->parseDataHash, ready for $self->implement to access
        if (! $self->parsePeek(FALSE, TRUE)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $parseArrayFlag, $basicVarName, $expression, $expValue, $successFlag, $blessed, $ivName,
            $var, $objFlag, $privFlag, $scalar, $varObj,
            @array,
            # Custom (set after $varObj is set)
            $matchExp, $match, $matchIndex,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $parseArrayFlag = $self->ivShow('parseDataHash', 'array_flag');
        $basicVarName = $self->ivShow('parseDataHash', 'var_name');
        $expression = $self->ivShow('parseDataHash', 'expression');
        $matchExp = $self->ivShow('parseDataHash', 'extra_exp');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $expValue = $expression->evaluate();
        # Evaluate the second expression to get a numeric value
        $match = $matchExp->evaluate();
        if (! defined $match || ! ($match =~  /^\d+$/)) {

            return $self->scriptObj->setError(
                'invalid_matching_expression',
                $self->_objClass . '->implement',
            );
        }

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($expValue);
        if (! $successFlag) {

            return $self->scriptObj->setError(
                'PEEKEQUALS_operation_failure',
                $self->_objClass . '->implement',
            );
        }

        # Import the Axmud internal variable, setting $scalar if $string refers to a scalar value,
        #   or @array if $string refers to a list or hash value
        if (! $objFlag) {

            # This statement only accepts Perl scalars
            if (defined $var && ref($var) eq 'ARRAY') {

                @array = @$var;

            } else {

                return $self->scriptObj->setError(
                    'PEEKEQUALS_operation_expects_list',
                    $self->_objClass . '->implement',
                );
            }

        } else {

            return $self->scriptObj->setError(
                'PEEKEQUALS_cannot_import_object',
                $self->_objClass . '->implement',
            );
        }

        # Look up the LA::Variable
        $varObj = $self->fetchVar('PEEKEQUALS', $basicVarName, $parseArrayFlag);
        if (! $varObj) {

            # (self->scriptObj->setError already called)
            return undef;
        }

        # Now we can set the variable to PEEKEQUALS's return value
        # Assuming the array is not empty, walk the array looking for a value which is the same as
        #   $match
        if (@array) {

            OUTER: for (my $count = 0; $count < scalar @array; $count++) {

                my $number;

                if (defined $array[$count]) {

                    $number = $array[$count];
                    if (
                        $number =~ m/([-+]?([0-9]+(\.[0-9]+)?|\.[0-9]+))/
                        && $number == $match
                    ) {

                        # Matching value found at index $count
                        $matchIndex = $count;
                        last OUTER;
                    }
                }
            }
        }

        if (! defined $matchIndex) {

            # List is empty, or a matching value was not found
            $matchIndex = -1;
        }

       if (! $parseArrayFlag) {

            # Import the scalar into an Axbasic scalar variable, converting Perl 'undef' as
            #   necessary
            $self->importAsScalar($varObj, $matchIndex);

        } else {

            # Import the list/hash into an Axbasic array, resizing it as necessary
            $self->importAsArray($varObj, $matchIndex);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::peekexists;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::peekexists::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PEEKEXISTS variable-name = axmud-object-property, expression
    # PEEKEXISTS ARRAY variable-name = axmud-object-property, expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract the standard PEEK... tokens. If the extraction is successful, they are stored in
        #   $self->parseDataHash, ready for $self->implement to access
        if (! $self->parsePeek(FALSE, TRUE)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $parseArrayFlag, $basicVarName, $expression, $expValue, $successFlag, $blessed, $ivName,
            $var, $objFlag, $privFlag, $scalar, $varObj,
            @array,
            # Custom (set after $varObj is set)
            $keyExp, $hashKey, $flagValue,
            %hash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $parseArrayFlag = $self->ivShow('parseDataHash', 'array_flag');
        $basicVarName = $self->ivShow('parseDataHash', 'var_name');
        $expression = $self->ivShow('parseDataHash', 'expression');
        $keyExp = $self->ivShow('parseDataHash', 'extra_exp');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $expValue = $expression->evaluate();
        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($expValue);
        if (! $successFlag) {

            return $self->scriptObj->setError(
                'PEEKEXISTS_operation_failure',
                $self->_objClass . '->implement',
            );
        }

        # Evaluate the second expression to get a hash key, e.g. 'gold'
        $hashKey = $keyExp->evaluate();

        # Import the Axmud internal variable, setting $scalar if $string refers to a scalar value,
        #   or @array if $string refers to a list or hash value
        if (! $objFlag) {

            # This statement only accepts Perl hashes
            if (defined $var && ref($var) eq 'HASH') {

                %hash = %$var;

            } else {

                return $self->scriptObj->setError(
                    'PEEKEXISTS_operation_expects_hash',
                    $self->_objClass . '->implement',
                );
            }

        } else {

            return $self->scriptObj->setError(
                'PEEKEXISTS_cannot_import_object',
                $self->_objClass . '->implement',
            );
        }

        # Look up the LA::Variable
        $varObj = $self->fetchVar('PEEKEXISTS', $basicVarName, $parseArrayFlag);
        if (! $varObj) {

            # (self->scriptObj->setError already called)
            return undef;
        }

        # Now we can set the variable to PEEKEXISTS's return value
        if (! exists $hash{$hashKey}) {

            # $hashKey doesn't exist in the hash
            if (ref($varObj) =~ m/Numeric/) {
                $flagValue = 0;
            } else {
                $flagValue = 'false';
            }

        } else {

            # $hashKey does exist in the hash
            if (ref($varObj) =~ m/Numeric/) {
                $flagValue = 1;
            } else {
                $flagValue = 'true';
            }
        }

        if (! $parseArrayFlag) {

            # Import the scalar into an Axbasic scalar variable, converting Perl 'undef' as
            #   necessary
            $self->importAsScalar($varObj, $flagValue);

        } else {

            # Import the list/hash into an Axbasic array, resizing it as necessary
            $self->importAsArray($varObj, $flagValue);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::peekfind;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::peekfind::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PEEKFIND variable-name = axmud-object-property, expression
    # PEEKFIND ARRAY variable-name = axmud-object-property, expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract the standard PEEK... tokens. If the extraction is successful, they are stored in
        #   $self->parseDataHash, ready for $self->implement to access
        if (! $self->parsePeek(FALSE, TRUE)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $parseArrayFlag, $basicVarName, $expression, $expValue, $successFlag, $blessed, $ivName,
            $var, $objFlag, $privFlag, $scalar, $varObj,
            @array,
            # Custom (set after $varObj is set)
            $matchExp, $match, $matchIndex,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $parseArrayFlag = $self->ivShow('parseDataHash', 'array_flag');
        $basicVarName = $self->ivShow('parseDataHash', 'var_name');
        $expression = $self->ivShow('parseDataHash', 'expression');
        $matchExp = $self->ivShow('parseDataHash', 'extra_exp');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $expValue = $expression->evaluate();
        # Evaluate the second expression to get a numeric/string value (allow 0, but not empty
        #   strings)
        $match = $matchExp->evaluate();
        if (! defined $match || length($match) == 0) {

            return $self->scriptObj->setError(
                'invalid_matching_expression',
                $self->_objClass . '->implement',
            );
        }

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($expValue);
        if (! $successFlag) {

            return $self->scriptObj->setError(
                'PEEKFIND_operation_failure',
                $self->_objClass . '->implement',
            );
        }

        # Import the Axmud internal variable, setting $scalar if $string refers to a scalar value,
        #   or @array if $string refers to a list or hash value
        if (! $objFlag) {

            # This statement only accepts Perl scalars
            if (defined $var && ref($var) eq 'ARRAY') {

                @array = @$var;

            } else {

                return $self->scriptObj->setError(
                    'PEEKFIND_operation_expects_list',
                    $self->_objClass . '->implement',
                );
            }

        } else {

            return $self->scriptObj->setError(
                'PEEKFIND_cannot_import_object',
                $self->_objClass . '->implement',
            );
        }

        # Look up the LA::Variable
        $varObj = $self->fetchVar('PEEKFIND', $basicVarName, $parseArrayFlag);
        if (! $varObj) {

            # (self->scriptObj->setError already called)
            return undef;
        }

        # Now we can set the variable to PEEKFIND's return value
        # Assuming the array is not empty, walk the array looking for a value which is the same as
        #   $match
        if (@array) {

            OUTER: for (my $count = 0; $count < scalar @array; $count++) {

                if (defined $array[$count] && $array[$count] eq $match) {

                    # Matching value found at index $count
                    $matchIndex = $count;
                    last OUTER;
                }
            }
        }

        if (! defined $matchIndex) {

            # List is empty, or a matching value was not found
            $matchIndex = -1;
        }

       if (! $parseArrayFlag) {

            # Import the scalar into an Axbasic scalar variable, converting Perl 'undef' as
            #   necessary
            $self->importAsScalar($varObj, $matchIndex);

        } else {

            # Import the list/hash into an Axbasic array, resizing it as necessary
            $self->importAsArray($varObj, $matchIndex);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::peekfirst;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::peekfirst::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PEEKFIRST variable-name = axmud-object-property
    # PEEKFIRST ARRAY variable-name = axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract the standard PEEK... tokens. If the extraction is successful, they are stored in
        #   $self->parseDataHash, ready for $self->implement to access
        if (! $self->parsePeek()) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $parseArrayFlag, $basicVarName, $expression, $expValue, $successFlag, $blessed, $ivName,
            $var, $objFlag, $privFlag, $scalar, $varObj,
            @array,
            # Custom (set after $varObj is set)
            $elementValue,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $parseArrayFlag = $self->ivShow('parseDataHash', 'array_flag');
        $basicVarName = $self->ivShow('parseDataHash', 'var_name');
        $expression = $self->ivShow('parseDataHash', 'expression');

        # Evaluate the expression to get the Axmud internal variable, e.g. "current.world.name"
        $expValue = $expression->evaluate();
        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($expValue);
        if (! $successFlag) {

            return $self->scriptObj->setError(
                'PEEKFIRST_operation_failure',
                $self->_objClass . '->implement',
            );
        }

        # Import the Axmud internal variable, setting $scalar if $string refers to a scalar value,
        #   or @array if $string refers to a list or hash value
        if (! $objFlag) {

            # This statement only accepts Perl lists
            if (defined $var && ref($var) eq 'ARRAY') {

                @array = @$var;

            } else {

                return $self->scriptObj->setError(
                    'PEEKFIRST_operation_expects_list',
                    $self->_objClass . '->implement',
                );
            }

        } else {

            return $self->scriptObj->setError(
                'PEEKFIRST_cannot_import_object',
                $self->_objClass . '->implement',
            );
        }

        # Look up the LA::Variable
        $varObj = $self->fetchVar('PEEKFIRST', $basicVarName, $parseArrayFlag);
        if (! $varObj) {

            # (self->scriptObj->setError already called)
            return undef;
        }

        # Now we can set the variable to PEEKFIRST's return value
        if (! @array) {

            # If the array is empty, then PEEKFIRST's return value is 0 or an empty string
            if (ref($varObj) =~ m/Numeric/) {
                $elementValue = 0;
            } else {
                $elementValue = '';
            }

        } else {

            $elementValue = $array[0];

            # If the corresponding value is actually 'undef', PEEKFIRST's return value is 0 or the
            #   string "<<undef>>"
            if (! defined $elementValue) {

                if (ref($varObj) =~ m/Numeric/) {
                    $elementValue = 0;
                } else {
                    $elementValue = '<<undef>>';
                }
            }
        }

        if (! $parseArrayFlag) {

            # Import the scalar into an Axbasic scalar variable, converting Perl 'undef' as
            #   necessary
            $self->importAsScalar($varObj, $elementValue);

        } else {

            # Import the list/hash into an Axbasic array, resizing it as necessary
            $self->importAsArray($varObj, $elementValue);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::peekget;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::peekget::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PEEKGET variable-name = axmud-object-property
    # PEEKGET ARRAY variable-name = axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract the standard PEEK... tokens. If the extraction is successful, they are stored in
        #   $self->parseDataHash, ready for $self->implement to access
        if (! $self->parsePeek()) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $parseArrayFlag, $basicVarName, $expression, $expValue, $successFlag, $blessed, $ivName,
            $var, $objFlag, $privFlag, $scalar, $varObj,
            @array,
            # Custom (set after $varObj is set)
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $parseArrayFlag = $self->ivShow('parseDataHash', 'array_flag');
        $basicVarName = $self->ivShow('parseDataHash', 'var_name');
        $expression = $self->ivShow('parseDataHash', 'expression');

        # Evaluate the expression to get the Axmud internal variable, e.g. "current.world.name"
        $expValue = $expression->evaluate();
        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($expValue);
        if (! $successFlag) {

            return $self->scriptObj->setError(
                'PEEKGET_operation_failure',
                $self->_objClass . '->implement',
            );
        }

        # Import the Axmud internal variable, setting $scalar if $string refers to a scalar value,
        #   or @array if $string refers to a list or hash value
        if (! $objFlag) {

            # This statement only accepts Perl scalars
            if (! defined $var || (ref($var) ne 'ARRAY' && ref($var) ne 'HASH')) {

                $scalar = $var;

                # If this was a PEEKGET ARRAY statement, but the IV is a scalar, copy it into the
                #   first cell of the Axbasic array (being an array containing 1 element)
                if ($parseArrayFlag) {

                    push (@array, $scalar);
                }

            } else {

                return $self->scriptObj->setError(
                    'PEEKGET_operation_expects_scalar',
                    $self->_objClass . '->implement',
                );
            }

        } else {

            return $self->scriptObj->setError(
                'PEEKGET_cannot_import_object',
                $self->_objClass . '->implement',
            );
        }

        # Look up the LA::Variable
        $varObj = $self->fetchVar('PEEKGET', $basicVarName, $parseArrayFlag);
        if (! $varObj) {

            # (self->scriptObj->setError already called)
            return undef;
        }

        # Now we can set the variable to PEEKGET's return value
        if (! $parseArrayFlag) {

            # Import the scalar into an Axbasic scalar variable, converting Perl 'undef' as
            #   necessary
            $self->importAsScalar($varObj, $scalar);

        } else {

            # Import the list/hash into an Axbasic array, resizing it as necessary
            $self->importAsArray($varObj, @array);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::peekindex;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::peekindex::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PEEKINDEX variable-name = axmud-object-property, expression
    # PEEKINDEX ARRAY variable-name = axmud-object-property, expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract the standard PEEK... tokens. If the extraction is successful, they are stored in
        #   $self->parseDataHash, ready for $self->implement to access
        if (! $self->parsePeek(FALSE, TRUE)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $parseArrayFlag, $basicVarName, $expression, $expValue, $successFlag, $blessed, $ivName,
            $var, $objFlag, $privFlag, $scalar, $varObj,
            @array,
            # Custom (set after $varObj is set)
            $indexExp, $index, $indexValue,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $parseArrayFlag = $self->ivShow('parseDataHash', 'array_flag');
        $basicVarName = $self->ivShow('parseDataHash', 'var_name');
        $expression = $self->ivShow('parseDataHash', 'expression');
        $indexExp = $self->ivShow('parseDataHash', 'extra_exp');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $expValue = $expression->evaluate();
        # Evaluate the second expression to get an index
        $index = $indexExp->evaluate();
        if (! defined $index || ! ($index =~  /^\d+$/) || $index < 0) {

            return $self->scriptObj->setError(
                'invalid_index_NUM',
                $self->_objClass . '->implement',
                'NUM', $index,
            );
        }

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($expValue);
        if (! $successFlag) {

            return $self->scriptObj->setError(
                'PEEKINDEX_operation_failure',
                $self->_objClass . '->implement',
            );
        }

        # Import the Axmud internal variable, setting $scalar if $string refers to a scalar value,
        #   or @array if $string refers to a list or hash value
        if (! $objFlag) {

            # This statement only accepts Perl scalars
            if (defined $var && ref($var) eq 'ARRAY') {

                @array = @$var;

            } else {

                return $self->scriptObj->setError(
                    'PEEKINDEX_operation_expects_list',
                    $self->_objClass . '->implement',
                );
            }

        } else {

            return $self->scriptObj->setError(
                'PEEKINDEX_cannot_import_object',
                $self->_objClass . '->implement',
            );
        }

        # Look up the LA::Variable
        $varObj = $self->fetchVar('PEEKINDEX', $basicVarName, $parseArrayFlag);
        if (! $varObj) {

            # (self->scriptObj->setError already called)
            return undef;
        }

        # Now we can set the variable to PEEKINDEX's return value.
        if ($index >= scalar @array) {

            # If $index is bigger than the array itself, then PEEKINDEX's return value is 0 or an
            #   empty string
            if (ref($varObj) =~ m/Numeric/) {
                $indexValue = 0;
            } else {
                $indexValue = '';
            }

        } else {

            $indexValue = $array[$index];

            # If the corresponding value is actually 'undef', PEEKINDEX's return value is 0 or the
            #   string "<<undef>>"
            if (! defined $indexValue) {

                if (ref($varObj) =~ m/Numeric/) {
                    $indexValue = 0;
                } else {
                    $indexValue = '<<undef>>';
                }
            }
        }

       if (! $parseArrayFlag) {

            # Import the scalar into an Axbasic scalar variable, converting Perl 'undef' as
            #   necessary
            $self->importAsScalar($varObj, $indexValue);

        } else {

            # Import the list/hash into an Axbasic array, resizing it as necessary
            $self->importAsArray($varObj, $indexValue);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::peekkeys;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::peekkeys::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PEEKKEYS variable-name = axmud-object-property
    # PEEKKEYS ARRAY variable-name = axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract the standard PEEK... tokens. If the extraction is successful, they are stored in
        #   $self->parseDataHash, ready for $self->implement to access
        if (! $self->parsePeek(TRUE, FALSE)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $parseArrayFlag, $basicVarName, $expression, $expValue, $successFlag, $blessed, $ivName,
            $var, $objFlag, $privFlag, $scalar, $varObj,
            @array,
            # Custom (set after $varObj is set)
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $parseArrayFlag = $self->ivShow('parseDataHash', 'array_flag');
        $basicVarName = $self->ivShow('parseDataHash', 'var_name');
        $expression = $self->ivShow('parseDataHash', 'expression');

        # Evaluate the expression to get the Axmud internal variable, e.g. "current.world.name"
        $expValue = $expression->evaluate();
        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($expValue);
        if (! $successFlag) {

            return $self->scriptObj->setError(
                'PEEKKEYS_operation_failure',
                $self->_objClass . '->implement',
            );
        }

        # Import the Axmud internal variable, setting $scalar if $string refers to a scalar value,
        #   or @array if $string refers to a list or hash value
        if (! $objFlag) {

            # This statement only accepts Perl hashes
            if (defined $var && ref($var) eq 'HASH') {

                @array = keys %$var;

            } else {

                return $self->scriptObj->setError(
                    'PEEKKEYS_operation_expects_hash',
                    $self->_objClass . '->implement',
                );
            }

        } else {

            return $self->scriptObj->setError(
                'PEEKKEYS_cannot_import_object',
                $self->_objClass . '->implement',
            );
        }

        # Look up the LA::Variable
        $varObj = $self->fetchVar('PEEKKEYS', $basicVarName, TRUE);
        if (! $varObj) {

            # (self->scriptObj->setError already called)
            return undef;
        }

        # Now we can set the variable to PEEKKEYS's return values ($parseArrayFlag is definitely
        #   TRUE)
        # Import the list/hash into an Axbasic array, resizing it as necessary
        $self->importAsArray($varObj, @array);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::peeklast;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::peeklast::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PEEKLAST variable-name = axmud-object-property
    # PEEKLAST ARRAY variable-name = axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract the standard PEEK... tokens. If the extraction is successful, they are stored in
        #   $self->parseDataHash, ready for $self->implement to access
        if (! $self->parsePeek()) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $parseArrayFlag, $basicVarName, $expression, $expValue, $successFlag, $blessed, $ivName,
            $var, $objFlag, $privFlag, $scalar, $varObj,
            @array,
            # Custom (set after $varObj is set)
            $lastIndex,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $parseArrayFlag = $self->ivShow('parseDataHash', 'array_flag');
        $basicVarName = $self->ivShow('parseDataHash', 'var_name');
        $expression = $self->ivShow('parseDataHash', 'expression');

        # Evaluate the expression to get the Axmud internal variable, e.g. "current.world.name"
        $expValue = $expression->evaluate();
        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($expValue);
        if (! $successFlag) {

            return $self->scriptObj->setError(
                'PEEKLAST_operation_failure',
                $self->_objClass . '->implement',
            );
        }

        # Import the Axmud internal variable, setting $scalar if $string refers to a scalar value,
        #   or @array if $string refers to a list or hash value
        if (! $objFlag) {

            # This statement only accepts Perl lists
            if (defined $var && ref($var) eq 'ARRAY') {

                @array = @$var;

            } else {

                return $self->scriptObj->setError(
                    'PEEKLAST_operation_expects_list',
                    $self->_objClass . '->implement',
                );
            }

        } else {

            return $self->scriptObj->setError(
                'PEEKLAST_cannot_import_object',
                $self->_objClass . '->implement',
            );
        }

        # Look up the LA::Variable
        $varObj = $self->fetchVar('PEEKLAST', $basicVarName, $parseArrayFlag);
        if (! $varObj) {

            # (self->scriptObj->setError already called)
            return undef;
        }

        # Now we can set the variable to PEEKLAST's return value. If the list is empty, we use the
        #   value -1
        if (! @array) {
            $lastIndex = -1;
        } else {
            $lastIndex = (scalar @array) - 1;
        }

        if (! $parseArrayFlag) {

            # Import the scalar into an Axbasic scalar variable, converting Perl 'undef' as
            #   necessary
            $self->importAsScalar($varObj, $lastIndex);

        } else {

            # Import the list/hash into an Axbasic array, resizing it as necessary
            $self->importAsArray($varObj, $lastIndex);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::peekmatch;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::peekmatch::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PEEKMATCH variable-name = axmud-object-property, expression
    # PEEKMATCH ARRAY variable-name = axmud-object-property, expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract the standard PEEK... tokens. If the extraction is successful, they are stored in
        #   $self->parseDataHash, ready for $self->implement to access
        if (! $self->parsePeek(FALSE, TRUE)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $parseArrayFlag, $basicVarName, $expression, $expValue, $successFlag, $blessed, $ivName,
            $var, $objFlag, $privFlag, $scalar, $varObj,
            @array,
            # Custom (set after $varObj is set)
            $regexExp, $regex, $matchIndex,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $parseArrayFlag = $self->ivShow('parseDataHash', 'array_flag');
        $basicVarName = $self->ivShow('parseDataHash', 'var_name');
        $expression = $self->ivShow('parseDataHash', 'expression');
        $regexExp = $self->ivShow('parseDataHash', 'extra_exp');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $expValue = $expression->evaluate();
        # Evaluate the second expression to get a regex
        $regex = $regexExp->evaluate();
        if (! $regex) {

            return $self->scriptObj->setError(
                'invalid_matching_expression',
                $self->_objClass . '->implement',
            );
        }

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($expValue);
        if (! $successFlag) {

            return $self->scriptObj->setError(
                'PEEKMATCH_operation_failure',
                $self->_objClass . '->implement',
            );
        }

        # Import the Axmud internal variable, setting $scalar if $string refers to a scalar value,
        #   or @array if $string refers to a list or hash value
        if (! $objFlag) {

            # This statement only accepts Perl scalars
            if (defined $var && ref($var) eq 'ARRAY') {

                @array = @$var;

            } else {

                return $self->scriptObj->setError(
                    'PEEKMATCH_operation_expects_list',
                    $self->_objClass . '->implement',
                );
            }

        } else {

            return $self->scriptObj->setError(
                'PEEKMATCH_cannot_import_object',
                $self->_objClass . '->implement',
            );
        }

        # Look up the LA::Variable
        $varObj = $self->fetchVar('PEEKMATCH', $basicVarName, $parseArrayFlag);
        if (! $varObj) {

            # (self->scriptObj->setError already called)
            return undef;
        }

        # Now we can set the variable to PEEKMATCH's return value
        # Assuming the array is not empty, walk the array looking for a value which matches the
        #   regex
        if (@array) {

            OUTER: for (my $count = 0; $count < scalar @array; $count++) {

                if (defined $array[$count] && $array[$count] =~ m/$regex/) {

                    # Matching value found at index $count
                    $matchIndex = $count;
                    last OUTER;
                }
            }
        }

        if (! defined $matchIndex) {

            # List is empty, or a matching value was not found
            $matchIndex = -1;
        }

       if (! $parseArrayFlag) {

            # Import the scalar into an Axbasic scalar variable, converting Perl 'undef' as
            #   necessary
            $self->importAsScalar($varObj, $matchIndex);

        } else {

            # Import the list/hash into an Axbasic array, resizing it as necessary
            $self->importAsArray($varObj, $matchIndex);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::peeknumber;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::peeknumber::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PEEKNUMBER variable-name = axmud-object-property
    # PEEKNUMBER ARRAY variable-name = axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract the standard PEEK... tokens. If the extraction is successful, they are stored in
        #   $self->parseDataHash, ready for $self->implement to access
        if (! $self->parsePeek()) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $parseArrayFlag, $basicVarName, $expression, $expValue, $successFlag, $blessed, $ivName,
            $var, $objFlag, $privFlag, $scalar, $varObj,
            @array,
            # Custom (set after $varObj is set)
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $parseArrayFlag = $self->ivShow('parseDataHash', 'array_flag');
        $basicVarName = $self->ivShow('parseDataHash', 'var_name');
        $expression = $self->ivShow('parseDataHash', 'expression');

        # Evaluate the expression to get the Axmud internal variable, e.g. "current.world.name"
        $expValue = $expression->evaluate();
        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($expValue);
        if (! $successFlag) {

            return $self->scriptObj->setError(
                'PEEKNUMBER_operation_failure',
                $self->_objClass . '->implement',
            );
        }

        # Import the Axmud internal variable, setting $scalar if $string refers to a scalar value,
        #   or @array if $string refers to a list or hash value
        if (! $objFlag) {

            # This statement only accepts Perl lists
            if (defined $var && ref($var) eq 'ARRAY') {

                @array = @$var;

            } else {

                return $self->scriptObj->setError(
                    'PEEKNUMBER_operation_expects_list',
                    $self->_objClass . '->implement',
                );
            }

        } else {

            return $self->scriptObj->setError(
                'PEEKNUMBER_cannot_import_object',
                $self->_objClass . '->implement',
            );
        }

        # Look up the LA::Variable
        $varObj = $self->fetchVar('PEEKNUMBER', $basicVarName, $parseArrayFlag);
        if (! $varObj) {

            # (self->scriptObj->setError already called)
            return undef;
        }

        # Now we can set the variable to PEEKNUMBER's return value
        if (! $parseArrayFlag) {

            # Import the scalar into an Axbasic scalar variable, converting Perl 'undef' as
            #   necessary
            $self->importAsScalar($varObj, scalar @array);

        } else {

            # Import the list/hash into an Axbasic array, resizing it as necessary
            $self->importAsArray($varObj, scalar @array);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::peekpairs;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::peekpairs::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PEEKPAIRS variable-name = axmud-object-property
    # PEEKPAIRS ARRAY variable-name = axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract the standard PEEK... tokens. If the extraction is successful, they are stored in
        #   $self->parseDataHash, ready for $self->implement to access
        if (! $self->parsePeek()) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $parseArrayFlag, $basicVarName, $expression, $expValue, $successFlag, $blessed, $ivName,
            $var, $objFlag, $privFlag, $scalar, $varObj,
            @array,
            # Custom (set after $varObj is set)
            %hash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $parseArrayFlag = $self->ivShow('parseDataHash', 'array_flag');
        $basicVarName = $self->ivShow('parseDataHash', 'var_name');
        $expression = $self->ivShow('parseDataHash', 'expression');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $expValue = $expression->evaluate();
        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($expValue);
        if (! $successFlag) {

            return $self->scriptObj->setError(
                'PEEKPAIRS_operation_failure',
                $self->_objClass . '->implement',
            );
        }

        # Import the Axmud internal variable, setting $scalar if $string refers to a scalar value,
        #   or @array if $string refers to a list or hash value
        if (! $objFlag) {

            # This statement only accepts Perl hashes
            if (defined $var && ref($var) eq 'HASH') {

                %hash = %$var;

            } else {

                return $self->scriptObj->setError(
                    'PEEKPAIRS_operation_expects_hash',
                    $self->_objClass . '->implement',
                );
            }

        } else {

            return $self->scriptObj->setError(
                'PEEKPAIRS_cannot_import_object',
                $self->_objClass . '->implement',
            );
        }

        # Look up the LA::Variable
        $varObj = $self->fetchVar('PEEKPAIRS', $basicVarName, $parseArrayFlag);
        if (! $varObj) {

            # (self->scriptObj->setError already called)
            return undef;
        }

        # Now we can set the variable to PEEKPAIRS's return value
        if (! $parseArrayFlag) {

            # Import the scalar into an Axbasic scalar variable, converting Perl 'undef' as
            #   necessary
            $self->importAsScalar($varObj, scalar(keys %hash));

        } else {

            # Import the list/hash into an Axbasic array, resizing it as necessary
            $self->importAsArray($varObj, scalar(keys %hash));
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::peekpop;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::peekpop::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PEEKPOP variable-name = axmud-object-property
    # PEEKPOP ARRAY variable-name = axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract the standard PEEK... tokens. If the extraction is successful, they are stored in
        #   $self->parseDataHash, ready for $self->implement to access
        if (! $self->parsePeek()) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $parseArrayFlag, $basicVarName, $expression, $expValue, $successFlag, $blessed, $ivName,
            $var, $objFlag, $privFlag, $scalar, $varObj,
            @array,
            # Custom (set after $varObj is set)
            $popValue,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $parseArrayFlag = $self->ivShow('parseDataHash', 'array_flag');
        $basicVarName = $self->ivShow('parseDataHash', 'var_name');
        $expression = $self->ivShow('parseDataHash', 'expression');

        # Evaluate the expression to get the Axmud internal variable, e.g. "current.world.name"
        $expValue = $expression->evaluate();
        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($expValue);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'PEEKPOP_operation_failure',
                $self->_objClass . '->implement',
            );
        }

        # Import the Axmud internal variable, setting $scalar if $string refers to a scalar value,
        #   or @array if $string refers to a list or hash value
        if (! $objFlag) {

            # This statement only accepts Perl lists
            if (defined $var && ref($var) eq 'ARRAY') {

                @array = @$var;

            } else {

                return $self->scriptObj->setError(
                    'PEEKPOP_operation_expects_list',
                    $self->_objClass . '->implement',
                );
            }

        } else {

            return $self->scriptObj->setError(
                'PEEKPOP_cannot_import_object',
                $self->_objClass . '->implement',
            );
        }

        # Look up the LA::Variable
        $varObj = $self->fetchVar('PEEKPOP', $basicVarName, $parseArrayFlag);
        if (! $varObj) {

            # (self->scriptObj->setError already called)
            return undef;
        }

        # Now we can set the variable to PEEKPOP's return value. If the list is empty, we use the
        #   value 'undef' (which is converted by the call to ->importAsScalar or ->importAsList)
        $popValue = $blessed->ivPop($ivName);

        if (! $parseArrayFlag) {

            # Import the scalar into an Axbasic scalar variable, converting Perl 'undef' as
            #   necessary
            $self->importAsScalar($varObj, $popValue);

        } else {

            # Import the list/hash into an Axbasic array, resizing it as necessary
            $self->importAsArray($varObj, $popValue);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::peekshift;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::peekshift::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PEEKSHIFT variable-name = axmud-object-property
    # PEEKSHIFT ARRAY variable-name = axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract the standard PEEK... tokens. If the extraction is successful, they are stored in
        #   $self->parseDataHash, ready for $self->implement to access
        if (! $self->parsePeek()) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $parseArrayFlag, $basicVarName, $expression, $expValue, $successFlag, $blessed, $ivName,
            $var, $objFlag, $privFlag, $scalar, $varObj,
            @array,
            # Custom (set after $varObj is set)
            $shiftValue,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $parseArrayFlag = $self->ivShow('parseDataHash', 'array_flag');
        $basicVarName = $self->ivShow('parseDataHash', 'var_name');
        $expression = $self->ivShow('parseDataHash', 'expression');

        # Evaluate the expression to get the Axmud internal variable, e.g. "current.world.name"
        $expValue = $expression->evaluate();
        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($expValue);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'PEEKSHIFT_operation_failure',
                $self->_objClass . '->implement',
            );
        }

        # Import the Axmud internal variable, setting $scalar if $string refers to a scalar value,
        #   or @array if $string refers to a list or hash value
        if (! $objFlag) {

            # This statement only accepts Perl lists
            if (defined $var && ref($var) eq 'ARRAY') {

                @array = @$var;

            } else {

                return $self->scriptObj->setError(
                    'PEEKSHIFT_operation_expects_list',
                    $self->_objClass . '->implement',
                );
            }

        } else {

            return $self->scriptObj->setError(
                'PEEKSHIFT_cannot_import_object',
                $self->_objClass . '->implement',
            );
        }

        # Look up the LA::Variable
        $varObj = $self->fetchVar('PEEKSHIFT', $basicVarName, $parseArrayFlag);
        if (! $varObj) {

            # (self->scriptObj->setError already called)
            return undef;
        }

        # Now we can set the variable to PEEKSHIFT's return value. If the list is empty, we use the
        #   value 'undef' (which is converted by the call to ->importAsScalar or ->importAsList)
        $shiftValue = $blessed->ivShift($ivName);

        if (! $parseArrayFlag) {

            # Import the scalar into an Axbasic scalar variable, converting Perl 'undef' as
            #   necessary
            $self->importAsScalar($varObj, $shiftValue);

        } else {

            # Import the list/hash into an Axbasic array, resizing it as necessary
            $self->importAsArray($varObj, $shiftValue);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::peekshow;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::peekshow::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PEEKSHOW variable-name = axmud-object-property, expression
    # PEEKSHOW ARRAY variable-name = axmud-object-property, expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract the standard PEEK... tokens. If the extraction is successful, they are stored in
        #   $self->parseDataHash, ready for $self->implement to access
        if (! $self->parsePeek(FALSE, TRUE)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $parseArrayFlag, $basicVarName, $expression, $expValue, $successFlag, $blessed, $ivName,
            $var, $objFlag, $privFlag, $scalar, $varObj,
            @array,
            # Custom (set after $varObj is set)
            $keyExp, $hashKey, $hashValue,
            %hash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $parseArrayFlag = $self->ivShow('parseDataHash', 'array_flag');
        $basicVarName = $self->ivShow('parseDataHash', 'var_name');
        $expression = $self->ivShow('parseDataHash', 'expression');
        $keyExp = $self->ivShow('parseDataHash', 'extra_exp');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $expValue = $expression->evaluate();
        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($expValue);
        if (! $successFlag) {

            return $self->scriptObj->setError(
                'PEEKSHOW_operation_failure',
                $self->_objClass . '->implement',
            );
        }

        # Evaluate the second expression to get a hash key, e.g. 'gold'
        $hashKey = $keyExp->evaluate();

        # Import the Axmud internal variable, setting $scalar if $string refers to a scalar value,
        #   or @array if $string refers to a list or hash value
        if (! $objFlag) {

            # This statement only accepts Perl hashes
            if (defined $var && ref($var) eq 'HASH') {

                %hash = %$var;

            } else {

                return $self->scriptObj->setError(
                    'PEEKSHOW_operation_expects_hash',
                    $self->_objClass . '->implement',
                );
            }

        } else {

            return $self->scriptObj->setError(
                'PEEKSHOW_cannot_import_object',
                $self->_objClass . '->implement',
            );
        }

        # Look up the LA::Variable
        $varObj = $self->fetchVar('PEEKSHOW', $basicVarName, $parseArrayFlag);
        if (! $varObj) {

            # (self->scriptObj->setError already called)
            return undef;
        }

        # Now we can set the variable to PEEKSHOW's return values
        if (! exists $hash{$hashKey}) {

            # If $hashKey doesn't exist in the hash, then PEEKSHOW's return value is 0 or an empty
            #   string
            if (ref($varObj) =~ m/Numeric/) {
                $hashValue = 0;
            } else {
                $hashValue = '';
            }

        } else {

            $hashValue = $hash{$hashKey};

            # If the corresponding value is actually 'undef', PEEKSHOW's return value is 0 or the
            #   string "<<undef>>"
            if (! defined $hashValue) {

                # $hashKey's corresponding value might be 'undef', or the key might not exist in the
                #   hash property at all. In both cases, PEEKSHOW's return value is 0 or an empty
                #   string
                if (ref($varObj) =~ m/Numeric/) {
                    $hashValue = 0;
                } else {
                    $hashValue = '<<undef>>';
                }
            }
        }

        if (! $parseArrayFlag) {

            # Import the scalar into an Axbasic scalar variable, converting Perl 'undef' as
            #   necessary
            $self->importAsScalar($varObj, $hashValue);

        } else {

            # Import the list/hash into an Axbasic array, resizing it as necessary
            $self->importAsArray($varObj, $hashValue);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::peekvalues;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::peekvalues::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PEEKVALUES variable-name = axmud-object-property
    # PEEKVALUES ARRAY variable-name = axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract the standard PEEK... tokens. If the extraction is successful, they are stored in
        #   $self->parseDataHash, ready for $self->implement to access
        if (! $self->parsePeek(TRUE, FALSE)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $parseArrayFlag, $basicVarName, $expression, $expValue, $successFlag, $blessed, $ivName,
            $var, $objFlag, $privFlag, $scalar, $varObj,
            @array,
            # Custom (set after $varObj is set)
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $parseArrayFlag = $self->ivShow('parseDataHash', 'array_flag');
        $basicVarName = $self->ivShow('parseDataHash', 'var_name');
        $expression = $self->ivShow('parseDataHash', 'expression');

        # Evaluate the expression to get the Axmud internal variable, e.g. "current.world.name"
        $expValue = $expression->evaluate();
        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($expValue);
        if (! $successFlag) {

            return $self->scriptObj->setError(
                'PEEKVALUES_operation_failure',
                $self->_objClass . '->implement',
            );
        }

        # Import the Axmud internal variable, setting $scalar if $string refers to a scalar value,
        #   or @array if $string refers to a list or hash value
        if (! $objFlag) {

            # This statement only accepts Perl hashes
            if (defined $var && ref($var) eq 'HASH') {

                @array = values %$var;

            } else {

                return $self->scriptObj->setError(
                    'PEEKVALUES_operation_expects_hash',
                    $self->_objClass . '->implement',
                );
            }

        } else {

            return $self->scriptObj->setError(
                'PEEKVALUES_cannot_import_object',
                $self->_objClass . '->implement',
            );
        }

        # Look up the LA::Variable
        $varObj = $self->fetchVar('PEEKVALUES', $basicVarName, TRUE);
        if (! $varObj) {

            # (self->scriptObj->setError already called)
            return undef;
        }

        # Now we can set the variable to PEEKVALUES's return values ($parseArrayFlag is definitely
        #   TRUE)
        # Import the list/hash into an Axbasic array, resizing it as necessary
        $self->importAsArray($varObj, @array);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::perl;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::perl::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PERL expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the expression and store it for ->implement to use
        $expression = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );

        } else {

            $self->ivAdd('parseDataHash', 'expression', $expression);
        }

        # There should be nothing after the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression, $string);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the expression to be written
        $expression = $self->ivShow('parseDataHash', 'expression');
        # Evaluate the expression to get a scalar value
        $string = $expression->evaluate();

        # Run the expression as a Perl programme (using the Safe module)
        $self->scriptObj->session->perlCmd($string);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::play;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::play::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PLAY expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the expression and store it for ->implement to use
        $expression = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );

        } else {

            $self->ivAdd('parseDataHash', 'expression', $expression);
        }

        # There should be nothing after the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression, $effect);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the expression to be played
        $expression = $self->ivShow('parseDataHash', 'expression');
        # Evaluate the expression to get an Axmud sound effect
        $effect = $expression->evaluate();

        # Check that the sound effect exists
        if (
            ! $effect
            || ! $axmud::CLIENT->ivExists('customSoundHash', $effect)
            || ! $axmud::CLIENT->ivShow('customSoundHash', $effect)
        ) {
            return $self->scriptObj->setError(
                'sound_not_available',
                $self->_objClass . '->implement',
            );

        } else {

            # Play the sound effect (if allowed)
            $axmud::CLIENT->playSound($effect);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::poke;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::poke::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKE axmud-object-property, expression
    # POKE axmud-object-property, variable-name
    # POKE ARRAY axmud-object-property, variable-name

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($token, $arrayFlag, $propExp, $varName, $varObj, $arithExp);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract the optional ARRAY keyword
        $token = $self->tokenGroupObj->shiftMatchingToken('array');
        if ($token) {
            $arrayFlag = TRUE;
        } else {
            $arrayFlag = FALSE;
        }

        # The first (compulsory) token is either an expression representing an Axmud internal
        #   variable (a scalar, e.g. "current.world.name"; an array,
        #   e.g. "current.world.displayFormatList"; or a hash, e.g. "current.world.currencyHash")
        $token = $self->tokenGroupObj->lookAhead();
        if (! defined $token) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );

        } else {

            $propExp = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $propExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Extract the comma
        if (! defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            return $self->scriptObj->setError(
                'syntax_error',
                   $self->_objClass . '->parse',
            );
        }

        # The second expression can be either a scalar variable, array or just a normal expression
        # Extract a token comprising a whole variable identifier (e.g. A, a$, array), if present
        $token = $self->tokenGroupObj->shiftTokenIfCategory('identifier');
        if ($token) {

            $varName = $token->tokenText;

            # Look up the LA::Variable. Use the local variable, if it exists. Otherwise use the
            #   global variable, if it exists
            if (! $arrayFlag) {

                $varObj = Language::Axbasic::Variable->lookup($self->scriptObj, $varName);

            } else {

                # If it's an array, ->lookup expects a LA::Expression::Arglist; but we only need to
                #   supply it with a defined value
                $varObj = Language::Axbasic::Variable->lookup(
                    $self->scriptObj,
                    $varName,
                    'fake_arg_list'
                );
            }

            if (! $varObj) {

                # This shouldn't happen...
                return $self->scriptObj->setError(
                    'syntax_error',
                    $self->_objClass . '->parse',
                );
            }

        # Identifier not present, so extract a normal expression instead (but not in POKE ARRAY
        #   statements)
        } elsif (! $arrayFlag) {

            $token = $self->tokenGroupObj->lookAhead();
            if (! defined $token) {

                return $self->scriptObj->setError(
                    'syntax_error',
                    $self->_objClass . '->parse',
                );

            } else {

                $arithExp = Language::Axbasic::Expression::Arithmetic->new(
                    $self->scriptObj,
                    $self->tokenGroupObj,
                );

                if (! defined $arithExp) {

                    return $self->scriptObj->setError(
                        'missing_or_illegal_expression',
                        $self->_objClass . '->parse',
                    );
                }
            }

        } else {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );
        }

        # There are no further expressions to extract
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Save the expressions so $self->implement can use them, if it is called
        $self->ivAdd('parseDataHash', 'array_flag', $arrayFlag);
        $self->ivAdd('parseDataHash', 'prop_exp', $propExp);
        $self->ivAdd('parseDataHash', 'var_name', $varName);
        $self->ivAdd('parseDataHash', 'var_obj', $varObj);
        $self->ivAdd('parseDataHash', 'arith_exp', $arithExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $parseArrayFlag, $propExp, $internalVar, $varName, $varObj, $arithExp, $arithValue,
            $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            @cellList, @valueList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $parseArrayFlag = $self->ivShow('parseDataHash', 'array_flag');
        $propExp = $self->ivShow('parseDataHash', 'prop_exp');
        $varName = $self->ivShow('parseDataHash', 'var_name');
        $varObj = $self->ivShow('parseDataHash', 'var_obj');
        $arithExp = $self->ivShow('parseDataHash', 'arith_exp');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $propExp->evaluate();
        # Evaluate the optional arithmetic expression, if set
        if (defined $arithExp) {

            $arithValue = $arithExp->evaluate();
        }

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKE_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKE_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # POKE ARRAY statements require an Axmud list or hash property
        if (
            $parseArrayFlag
            && (! defined $var || (ref($var) ne 'ARRAY' && ref($var) eq 'HASH'))
        ) {
            return $self->scriptObj->setError(
                'POKE_ARRAY_operation_expects_list_or_hash',        # Yes, POKE_ARRAY not POKE
                   $self->_objClass . '->implement',
            );
        }

        # Perform the POKE operation
        # If the user specified an arithmetic expression, use it
        if (defined $arithExp) {

            $blessed->ivPoke($ivName, $arithValue);

        # Otherwise, use the specified variable
        } else {

            if (! $parseArrayFlag) {

                $blessed->ivPoke($ivName, $varObj->value);

            } else {

                @cellList = $varObj->cellList;
                # Axbasic arrays don't use element 0, so dispense with the unusable $cellList[0]
                shift @cellList;

                foreach my $arrayVar (@cellList) {

                    push (@valueList, $arrayVar->value());
                }

                $blessed->ivPoke($ivName, @valueList);
            }
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::pokeadd;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::pokeadd::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKEADD axmud-object-property, expression, expression
    # POKEADD axmud-object-property, expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract tokens. If the extraction is successful, they are stored in $self->parseDataList,
        #   ready for $self->implement to access
        if (! $self->parsePoke(1, 2)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $varExp, $internalVar, $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            # Custom
            $keyExp, $key, $valueExp, $value,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $varExp = $self->ivShow('parseDataHash', 'var_exp');
        $keyExp = $self->ivShift('parseDataList');
        $valueExp = $self->ivShift('parseDataList');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $varExp->evaluate();
        # Evaluate the other expressions
        $key = $keyExp->evaluate();
        if (defined $valueExp) {

            # $valueExp is optional. If the user didn't specify it, $value remains set to 'undef'
            $value = $valueExp->evaluate();
        }

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKEADD_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKEADD_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # This statement only accepts Perl hashes
        if (! defined $var || ref($var) ne 'HASH') {

            return $self->scriptObj->setError(
                'POKEADD_operation_expects_hash',
                   $self->_objClass . '->implement',
            );
        }

        # Perform the POKEADD operation. If the minimum number of expressions was specified, $value
        #   is 'undef'
        $blessed->ivAdd($ivName, $key, $value);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::pokedec;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::pokedec::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKEDEC axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract tokens. If the extraction is successful, they are stored in $self->parseDataList,
        #   ready for $self->implement to access
        if (! $self->parsePoke(0)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $varExp, $internalVar, $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            # Custom
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $varExp = $self->ivShow('parseDataHash', 'var_exp');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $varExp->evaluate();

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKEDEC_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKEDEC_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # This statement only accepts Perl scalars whose values are integers
        if (defined $var && (ref($var) eq 'ARRAY' || ref($var) eq 'HASH')) {

            return $self->scriptObj->setError(
                'POKEDEC_operation_expects_scalar',
                   $self->_objClass . '->implement',
            );
        }

        if (! defined $blessed->$ivName || $blessed->$ivName =~ m/\D/) {

            return $self->scriptObj->setError(
                'POKEDEC_operation_expects_integer',
                   $self->_objClass . '->implement',
            );
        }

        # Perform the POKEDEC operation
        $blessed->ivDecrement($ivName);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::pokedechash;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::pokedechash::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKEDECHASH axmud-object-property, expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract tokens. If the extraction is successful, they are stored in $self->parseDataList,
        #   ready for $self->implement to access
        if (! $self->parsePoke(1)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $varExp, $internalVar, $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            # Custom
            $keyExp, $key, $keyValue,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $varExp = $self->ivShow('parseDataHash', 'var_exp');
        $keyExp = $self->ivShift('parseDataList');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $varExp->evaluate();
        # Evaluate the other expressions
        $key = $keyExp->evaluate();

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKEDECHASH_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKEDECHASH_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # This statement only accepts Perl hashes
        if (! defined $var || ref($var) ne 'HASH') {

            return $self->scriptObj->setError(
                'POKEDECHASH_operation_expects_hash',
                   $self->_objClass . '->implement',
            );
        }

        # The key must exist in the hash, and its corresponding value must be an integer
        if (! $blessed->ivExists($ivName, $key)) {

            return $self->scriptObj->setError(
                'POKEDECHASH_key_not_found',
                   $self->_objClass . '->implement',
            );
        }

        $keyValue = $blessed->ivShow($ivName, $key);
        if (! defined $keyValue || $keyValue =~ m/\D/) {

            return $self->scriptObj->setError(
                'POKEDECHASH_operation_expects_integer',
                   $self->_objClass . '->implement',
            );
        }

        # Perform the POKEDECHASH operation
        $blessed->ivDecHash($ivName, $key);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::pokedelete;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::pokedelete::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKEDELETE axmud-object-property, expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract tokens. If the extraction is successful, they are stored in $self->parseDataList,
        #   ready for $self->implement to access
        if (! $self->parsePoke(1)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $varExp, $internalVar, $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            # Custom
            $keyExp, $key,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $varExp = $self->ivShow('parseDataHash', 'var_exp');
        $keyExp = $self->ivShift('parseDataList');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $varExp->evaluate();
        # Evaluate the other expressions
        $key = $keyExp->evaluate();

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKEDELETE_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKEDELETE_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # This statement only accepts Perl hashes
        if (! defined $var || ref($var) ne 'HASH') {

            return $self->scriptObj->setError(
                'POKEDELETE_operation_expects_hash',
                   $self->_objClass . '->implement',
            );
        }

        # The key must exist in the hash
        if (! $blessed->ivExists($ivName, $key)) {

            return $self->scriptObj->setError(
                'POKEDELETE_key_not_found',
                   $self->_objClass . '->implement',
            );
        }

        # Perform the POKEDELETE operation
        $blessed->ivDelete($ivName, $key);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::pokedivide;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::pokedivide::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKEDIVIDE axmud-object-property, expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract tokens. If the extraction is successful, they are stored in $self->parseDataList,
        #   ready for $self->implement to access
        if (! $self->parsePoke(1)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $varExp, $internalVar, $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            # Custom
            $valueExp, $value,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $varExp = $self->ivShow('parseDataHash', 'var_exp');
        $valueExp = $self->ivShift('parseDataList');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $varExp->evaluate();
        # Evaluate the other expressions
        $value = $valueExp->evaluate();
        # The value of the expression must be a non-zero number
        if (
            ! ($value =~ m/([-+]?([0-9]+(\.[0-9]+)?|\.[0-9]+))/)
            || $value == 0
        ) {
            return $self->scriptObj->setError(
                'invalid_expression_in_POKEDIVIDE_statement',
                $self->_objClass . '->implement',
            );
        }

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKEDIVIDE_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKEDIVIDE_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # This statement only accepts Perl scalars whose values are numbers
        if (defined $var && (ref($var) eq 'ARRAY' || ref($var) eq 'HASH')) {

            return $self->scriptObj->setError(
                'POKEDIVIDE_operation_expects_scalar',
                   $self->_objClass . '->implement',
            );
        }

        if (
            ! defined $blessed->$ivName
            || ! ($blessed->$ivName =~ m/([-+]?([0-9]+(\.[0-9]+)?|\.[0-9]+))/)
        ) {
            return $self->scriptObj->setError(
                'POKEDIVIDE_operation_expects_numeric',
                   $self->_objClass . '->implement',
            );
        }

        # Perform the POKEDIVIDE operation
        $blessed->ivDivide($ivName, $value);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::pokeempty;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::pokeempty::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKEEMPTY axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract tokens. If the extraction is successful, they are stored in $self->parseDataList,
        #   ready for $self->implement to access
        if (! $self->parsePoke(0)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $varExp, $internalVar, $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            # Custom
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $varExp = $self->ivShow('parseDataHash', 'var_exp');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $varExp->evaluate();

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKEEMPTY_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKEEMPTY_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # (This statement accepts Perl scalars, arrays and hashes)

        # Perform the POKEEMPTY operation
        $blessed->ivEmpty($ivName);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::pokefalse;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::pokefalse::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKEFALSE axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract tokens. If the extraction is successful, they are stored in $self->parseDataList,
        #   ready for $self->implement to access
        if (! $self->parsePoke(0)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $varExp, $internalVar, $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            # Custom
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $varExp = $self->ivShow('parseDataHash', 'var_exp');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $varExp->evaluate();

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKEFALSE_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKEFALSE_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # This statement only accepts Perl scalars
        if (defined $var && (ref($var) eq 'ARRAY' || ref($var) eq 'HASH')) {

            return $self->scriptObj->setError(
                'POKEFALSE_operation_expects_scalar',
                   $self->_objClass . '->implement',
            );
        }

        # Perform the POKEFALSE operation
        $blessed->ivFalse($ivName);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::pokeinc;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::pokeinc::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKEINC axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract tokens. If the extraction is successful, they are stored in $self->parseDataList,
        #   ready for $self->implement to access
        if (! $self->parsePoke(0)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $varExp, $internalVar, $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            # Custom
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $varExp = $self->ivShow('parseDataHash', 'var_exp');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $varExp->evaluate();

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKEINC_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKEINC_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # This statement only accepts Perl scalars whose values are integers
        if (defined $var && (ref($var) eq 'ARRAY' || ref($var) eq 'HASH')) {

            return $self->scriptObj->setError(
                'POKEINC_operation_expects_scalar',
                   $self->_objClass . '->implement',
            );
        }

        if (! defined $blessed->$ivName || $blessed->$ivName =~ m/\D/) {

            return $self->scriptObj->setError(
                'POKEINC_operation_expects_integer',
                   $self->_objClass . '->implement',
            );
        }

        # Perform the POKEINC operation
        $blessed->ivIncrement($ivName);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::pokeinchash;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::pokeinchash::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKEINCHASH axmud-object-property, expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract tokens. If the extraction is successful, they are stored in $self->parseDataList,
        #   ready for $self->implement to access
        if (! $self->parsePoke(1)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $varExp, $internalVar, $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            # Custom
            $keyExp, $key, $keyValue,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $varExp = $self->ivShow('parseDataHash', 'var_exp');
        $keyExp = $self->ivShift('parseDataList');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $varExp->evaluate();
        # Evaluate the other expressions
        $key = $keyExp->evaluate();

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKEINCHASH_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKEINCHASH_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # This statement only accepts Perl hashes
        if (! defined $var || ref($var) ne 'HASH') {

            return $self->scriptObj->setError(
                'POKEINCHASH_operation_expects_hash',
                   $self->_objClass . '->implement',
            );
        }

        # The key must exist in the hash, and its corresponding value must be an integer
        if (! $blessed->ivExists($ivName, $key)) {

            return $self->scriptObj->setError(
                'POKEINCHASH_key_not_found',
                   $self->_objClass . '->implement',
            );
        }

        $keyValue = $blessed->ivShow($ivName, $key);
        if (! defined $keyValue || $keyValue =~ m/\D/) {

            return $self->scriptObj->setError(
                'POKEINCHASH_operation_expects_integer',
                   $self->_objClass . '->implement',
            );
        }

        # Perform the POKEINCHASH operation
        $blessed->ivIncHash($ivName, $key);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::pokeint;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::pokeint::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKEINT axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract tokens. If the extraction is successful, they are stored in $self->parseDataList,
        #   ready for $self->implement to access
        if (! $self->parsePoke(0)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $varExp, $internalVar, $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            # Custom
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $varExp = $self->ivShow('parseDataHash', 'var_exp');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $varExp->evaluate();

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKEINT_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKEINT_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # This statement only accepts Perl scalars whose values are numbers
        if (defined $var && (ref($var) eq 'ARRAY' || ref($var) eq 'HASH')) {

            return $self->scriptObj->setError(
                'POKEINT_operation_expects_scalar',
                   $self->_objClass . '->implement',
            );
        }

        if (
            ! defined $blessed->$ivName
            || ! ($blessed->$ivName =~ m/([-+]?([0-9]+(\.[0-9]+)?|\.[0-9]+))/)
        ) {
            return $self->scriptObj->setError(
                'POKEINT_operation_expects_numeric',
                   $self->_objClass . '->implement',
            );
        }

        # Perform the POKEINT operation
        $blessed->ivInt($ivName);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::pokeminus;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::pokeminus::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKEMINUS axmud-object-property, expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract tokens. If the extraction is successful, they are stored in $self->parseDataList,
        #   ready for $self->implement to access
        if (! $self->parsePoke(1)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $varExp, $internalVar, $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            # Custom
            $valueExp, $value,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $varExp = $self->ivShow('parseDataHash', 'var_exp');
        $valueExp = $self->ivShift('parseDataList');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $varExp->evaluate();
        # Evaluate the other expressions
        $value = $valueExp->evaluate();
        # The value of the expression must be a number
        if (! ($value =~ m/([-+]?([0-9]+(\.[0-9]+)?|\.[0-9]+))/)) {

            return $self->scriptObj->setError(
                'invalid_expression_in_POKEMINUS_statement',
                $self->_objClass . '->implement',
            );
        }

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKEMINUS_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKEMINUS_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # This statement only accepts Perl scalars whose values are numbers
        if (defined $var && (ref($var) eq 'ARRAY' || ref($var) eq 'HASH')) {

            return $self->scriptObj->setError(
                'POKEMINUS_operation_expects_scalar',
                   $self->_objClass . '->implement',
            );
        }

        if (
            ! defined $blessed->$ivName
            || ! ($blessed->$ivName =~ m/([-+]?([0-9]+(\.[0-9]+)?|\.[0-9]+))/)
        ) {
            return $self->scriptObj->setError(
                'POKEMINUS_operation_expects_numeric',
                   $self->_objClass . '->implement',
            );
        }

        # Perform the POKEMINUS operation
        $blessed->ivMinus($ivName, $value);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::pokemultiply;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::pokemultiply::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKEMULTIPLY axmud-object-property, expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract tokens. If the extraction is successful, they are stored in $self->parseDataList,
        #   ready for $self->implement to access
        if (! $self->parsePoke(1)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $varExp, $internalVar, $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            # Custom
            $valueExp, $value,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $varExp = $self->ivShow('parseDataHash', 'var_exp');
        $valueExp = $self->ivShift('parseDataList');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $varExp->evaluate();
        # Evaluate the other expressions
        $value = $valueExp->evaluate();
        # The value of the expression must be a number
        if (! ($value =~ m/([-+]?([0-9]+(\.[0-9]+)?|\.[0-9]+))/)) {

            return $self->scriptObj->setError(
                'invalid_expression_in_POKEMULTIPLY_statement',
                $self->_objClass . '->implement',
            );
        }

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKEMULTIPLY_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKEMULTIPLY_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # This statement only accepts Perl scalars whose values are numbers
        if (defined $var && (ref($var) eq 'ARRAY' || ref($var) eq 'HASH')) {

            return $self->scriptObj->setError(
                'POKEMULTIPLY_operation_expects_scalar',
                   $self->_objClass . '->implement',
            );
        }

        if (
            ! defined $blessed->$ivName
            || ! ($blessed->$ivName =~ m/([-+]?([0-9]+(\.[0-9]+)?|\.[0-9]+))/)
        ) {
            return $self->scriptObj->setError(
                'POKEMULTIPLY_operation_expects_numeric',
                   $self->_objClass . '->implement',
            );
        }

        # Perform the POKEMULTIPLY operation
        $blessed->ivMultiply($ivName, $value);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::pokeplus;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::pokeplus::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKEPLUS axmud-object-property, expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract tokens. If the extraction is successful, they are stored in $self->parseDataList,
        #   ready for $self->implement to access
        if (! $self->parsePoke(1)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $varExp, $internalVar, $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            # Custom
            $valueExp, $value,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $varExp = $self->ivShow('parseDataHash', 'var_exp');
        $valueExp = $self->ivShift('parseDataList');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $varExp->evaluate();
        # Evaluate the other expressions
        $value = $valueExp->evaluate();
        # The value of the expression must be a number
        if (! ($value =~ m/([-+]?([0-9]+(\.[0-9]+)?|\.[0-9]+))/)) {

            return $self->scriptObj->setError(
                'invalid_expression_in_POKEPLUS_statement',
                $self->_objClass . '->implement',
            );
        }

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKEPLUS_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKEPLUS_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # This statement only accepts Perl scalars whose values are numbers
        if (defined $var && (ref($var) eq 'ARRAY' || ref($var) eq 'HASH')) {

            return $self->scriptObj->setError(
                'POKEPLUS_operation_expects_scalar',
                   $self->_objClass . '->implement',
            );
        }

        if (
            ! defined $blessed->$ivName
            || ! ($blessed->$ivName =~ m/([-+]?([0-9]+(\.[0-9]+)?|\.[0-9]+))/)
        ) {
            return $self->scriptObj->setError(
                'POKEPLUS_operation_expects_numeric',
                   $self->_objClass . '->implement',
            );
        }

        # Perform the POKEPLUS operation
        $blessed->ivPlus($ivName, $value);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::pokepush;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::pokepush::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKEPUSH axmud-object-property, expression
    # POKEPUSH axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract tokens. If the extraction is successful, they are stored in $self->parseDataList,
        #   ready for $self->implement to access
        if (! $self->parsePoke(0, 1)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $varExp, $internalVar, $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            # Custom
            $valueExp, $value,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $varExp = $self->ivShow('parseDataHash', 'var_exp');
        $valueExp = $self->ivShift('parseDataList');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $varExp->evaluate();
        # Evaluate the other expressions
        if (defined $valueExp) {

            # $valueExp is optional. If the user didn't specify it, $value remains set to 'undef'
            $value = $valueExp->evaluate();
        }

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKEPUSH_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKEPUSH_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # This statement only accepts Perl lists
        if (! defined $var || ref($var) ne 'ARRAY') {

            return $self->scriptObj->setError(
                'POKEPUSH_operation_expects_list',
                   $self->_objClass . '->implement',
            );
        }

        # Perform the POKEPUSH operation. If the minimum number of expressions was specified, $value
        #   is 'undef'
        $blessed->ivPush($ivName, $value);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::pokereplace;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::pokereplace::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKEREPLACE axmud-object-property, expression, expression
    # POKEREPLACE axmud-object-property, expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract tokens. If the extraction is successful, they are stored in $self->parseDataList,
        #   ready for $self->implement to access
        if (! $self->parsePoke(1, 2)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $varExp, $internalVar, $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            # Custom
            $indexExp, $index, $valueExp, $value,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $varExp = $self->ivShow('parseDataHash', 'var_exp');
        $indexExp = $self->ivShift('parseDataList');
        $valueExp = $self->ivShift('parseDataList');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $varExp->evaluate();
        # Evaluate the other expressions
        $index = $indexExp->evaluate();
        if (defined $valueExp) {

            # $valueExp is optional. If the user didn't specify it, $value remains set to 'undef'
            $value = $valueExp->evaluate();
        }

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKEREPLACE_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKEREPLACE_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # This statement only accepts Perl lists
        if (! defined $var || ref($var) ne 'ARRAY') {

            return $self->scriptObj->setError(
                'POKEREPLACE_operation_expects_list',
                   $self->_objClass . '->implement',
            );
        }

        # $index must be a valid integer, and exist in the list property
        if (
            ! defined $index
            || $index =~ /\D/
            || $index < 0
            || $index >= $blessed->ivNumber($ivName)
        ) {
            return $self->scriptObj->setError(
                'invalid_index_NUM',
                $self->_objClass . '->implement',
                'NUM', $index,
            );
        }

        # Perform the POKEREPLACE operation. If the minimum number of expressions was specified,
        #   $value is 'undef'
        $blessed->ivReplace($ivName, $index, $value);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::pokeset;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::pokeset::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKESET axmud-object-property, expression
    # POKESET axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract tokens. If the extraction is successful, they are stored in $self->parseDataList,
        #   ready for $self->implement to access
        if (! $self->parsePoke(0, 1)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $varExp, $internalVar, $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            # Custom
            $valueExp, $value,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $varExp = $self->ivShow('parseDataHash', 'var_exp');
        $valueExp = $self->ivShift('parseDataList');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $varExp->evaluate();
        # Evaluate the other expressions
        if (defined $valueExp) {

            # $valueExp is optional. If the user didn't specify it, $value remains set to 'undef'
            $value = $valueExp->evaluate();
        }

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKESET_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKESET_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # This statement only accepts Perl scalars
        if (defined $var && (ref($var) eq 'ARRAY' || ref($var) eq 'HASH')) {

            return $self->scriptObj->setError(
                'POKESET_operation_expects_scalar',
                   $self->_objClass . '->implement',
            );
        }

        # Perform the POKESET operation. If the minimum number of expressions was specified, $value
        #   is 'undef'
        $blessed->ivSet($ivName, $value);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::poketrue;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::poketrue::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKETRUE axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract tokens. If the extraction is successful, they are stored in $self->parseDataList,
        #   ready for $self->implement to access
        if (! $self->parsePoke(0)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $varExp, $internalVar, $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            # Custom
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $varExp = $self->ivShow('parseDataHash', 'var_exp');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $varExp->evaluate();

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKETRUE_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKETRUE_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # This statement only accepts Perl scalars
        if (defined $var && (ref($var) eq 'ARRAY' || ref($var) eq 'HASH')) {

            return $self->scriptObj->setError(
                'POKETRUE_operation_expects_scalar',
                   $self->_objClass . '->implement',
            );
        }

        # Perform the POKETRUE operation
        $blessed->ivTrue($ivName);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::pokeundef;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::pokeundef::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKEUNDEF axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract tokens. If the extraction is successful, they are stored in $self->parseDataList,
        #   ready for $self->implement to access
        if (! $self->parsePoke(0)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $varExp, $internalVar, $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            # Custom
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $varExp = $self->ivShow('parseDataHash', 'var_exp');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $varExp->evaluate();

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKEUNDEF_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKEUNDEF_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # This statement only accepts Perl scalars
        if (defined $var && (ref($var) eq 'ARRAY' || ref($var) eq 'HASH')) {

            return $self->scriptObj->setError(
                'POKEUNDEF_operation_expects_scalar',
                   $self->_objClass . '->implement',
            );
        }

        # Perform the POKEUNDEF operation
        $blessed->ivUndef($ivName);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::pokeunshift;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::pokeunshift::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # POKEUNSHIFT axmud-object-property, expression
    # POKEUNSHIFT axmud-object-property

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Extract tokens. If the extraction is successful, they are stored in $self->parseDataList,
        #   ready for $self->implement to access
        if (! $self->parsePoke(0, 1)) {

            # ($self->scriptObj->setError has already been called)
            return undef;
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            # Standard
            $varExp, $internalVar, $successFlag, $blessed, $ivName, $var, $objFlag, $privFlag,
            # Custom
            $valueExp, $value,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the values stored by $self->parse
        $varExp = $self->ivShow('parseDataHash', 'var_exp');
        $valueExp = $self->ivShift('parseDataList');

        # Evaluate the first expression to get the Axmud internal variable, e.g.
        #   "current.world.name"
        $internalVar = $varExp->evaluate();
        # Evaluate the other expressions
        if (defined $valueExp) {

            # $valueExp is optional. If the user didn't specify it, $value remains set to 'undef'
            $value = $valueExp->evaluate();
        }

        # Process the string representing the Axmud internal variable
        ($successFlag, $blessed, $ivName, $var, $objFlag, $privFlag)
            = $self->scriptObj->session->parsePeekPoke($internalVar);
        if (! $successFlag || ! $blessed || ! $ivName || $privFlag) {

            return $self->scriptObj->setError(
                'POKEUNSHIFT_operation_failure',
                $self->_objClass . '->implement',
            );

        } elsif ($objFlag) {

            return $self->scriptObj->setError(
                'POKEUNSHIFT_cannot_export_to_object',
                $self->_objClass . '->implement',
            );
        }

        # This statement only accepts Perl lists
        if (! defined $var || ref($var) ne 'ARRAY') {

            return $self->scriptObj->setError(
                'POKEUNSHIFT_operation_expects_list',
                   $self->_objClass . '->implement',
            );
        }

        # Perform the POKEUNSHIFT operation. If the minimum number of expressions was specified,
        #   $value is 'undef'
        $blessed->ivUnshift($ivName, $value);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::print;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::print::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PRINT [ expression [ separator ] [ expression [ separator ] ... ] ]
    # PRINT #channel: expression [ separator ] [ expression [ separator ] ... ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($tokenGroupObj, $token, $channel, $expression, $endChar);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Which token group to use - start with the existing one
        $tokenGroupObj = $self->tokenGroupObj;

        # If the first token is a file channel, extract it
        $token = $self->tokenGroupObj->lookAhead();
        if ($token && $token->category eq 'file_channel') {

            $self->tokenGroupObj->shiftToken();

            # For PRINT statements, the file channel must include a colon at the end (e.g. '#5:' )
            if (! ($token->tokenText =~ m/\:$/)) {

                return $self->scriptObj->setError(
                    'syntax_error',
                    $self->_objClass . '->parse',
                );
            }

            # Get the channel number
            $token->tokenText =~ m/([0-9]+)/;
            $channel = $1;

            # True BASIC specifies that the channel must be in the range 1-999; same range used by
            #   Axbasic
            if ($channel < 1 || $channel > 999) {

                return $self->scriptObj->setError(
                    'file_channel_NUM_out_of_range',
                    $self->_objClass . '->parse',
                    'NUM', $channel,
                );

            } else {

                # Store the channel number; this also informs $self->implement that we're reading
                #    from a file, not the user's keyboard
                $self->ivAdd('parseDataHash', 'channel', $channel);
            }
        }

        # Deal with an empty print statement, i.e. <print> is taken to be <print "">
        if (defined $tokenGroupObj->testStatementEnd()) {

            # Create a token group to represent the implied null string
            $tokenGroupObj = Language::Axbasic::TokenGroup->new($self->scriptObj, '""');
            if (! defined $tokenGroupObj) {

                return $self->scriptObj->setDebug(
                    'Can\'t create token group',
                    $self->_objClass . '->parse',
                );

            } else {

                if (! $tokenGroupObj->lex()) {

                    return undef;
                }
            }
        }

        do {

            # Convert the <print> argument into an expression
            $expression = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $tokenGroupObj,
            );

            if (! defined $expression) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }

            # Look for a comma or semicolon
            $token = $tokenGroupObj->shiftTokenIfCategory('separator');
            if (defined $token) {

                # It's a comma/semicolon
                $endChar = $token->tokenText;

            } elsif (defined $tokenGroupObj->testStatementEnd()) {

                # No comma or semicolon ending the print statement
                $endChar = '';

            } else {

                # Something else which shouldn't be there
                return $self->scriptObj->setError(
                    'syntax_error',
                    $self->_objClass . '->parse',
                );
            }

            # Save the expression and the end character (comma or semicolon) so that
            #   $self->implement can use it, if it is called
            $self->ivPush('parseDataList', $expression, $endChar);

        } until (defined $tokenGroupObj->testStatementEnd());

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $channel, $session, $taskObj, $channelObj, $fileHandle, $line, $newLineCharFlag,
            @printList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the components stored by $self->parse
        $channel = $self->ivShow('parseDataHash', 'channel');
        @printList = $self->parseDataList;

        # For convenience, import the GA::Session and Script task (if any)
        $session = $self->scriptObj->session;
        $taskObj = $self->scriptObj->parentTask;

        # Deal with writing to a file, if a file channel was specified
        if (defined $channel) {

            # Check that the file channel exists
            if (! $self->scriptObj->ivExists('fileChannelHash', $channel)) {

                return $self->scriptObj->setError(
                    'file_channel_NUM_not_open',
                    $self->_objClass . '->implement',
                    'NUM', $channel,
                );

            } else {

                $channelObj = $self->scriptObj->ivShow('fileChannelHash', $channel);
                $fileHandle = $channelObj->fileHandle;
            }

            # Check that writing to the file channel is allowed
            if ($channelObj->accessType eq 'input') {

                return $self->scriptObj->setError(
                    'file_channel_NUM_is_read_only',
                    $self->_objClass . '->implement',
                    'NUM', $channel,
                );
            }

            # Prepare the line to write to the file channel
            $line = '';
            # End the line with a newline char, unless the expressions end with a ';' or ','
            $newLineCharFlag = TRUE;

            while (@printList) {

                my ($expression, $endChar, $number, $string);

                $expression = shift @printList;
                $endChar = shift @printList;

                # Evaluate the expression. If there's been an error, ->setError should already have
                #   been called to display the error message (and $string) will be 'undef')
                $string = $expression->evaluate();
                if (! defined $string) {

                    # Implementation complete
                    return 1;

                } else {

                    $line .= $string;
                }

                # (No space is added after a number, when writing to a file channel)

                if ($endChar eq ',') {

                    $number = 14 - ((length $line) % 14);
                    $line .= (' ' x $number);
                    $newLineCharFlag = FALSE;

                } elsif ($endChar eq ';') {

                    $newLineCharFlag = FALSE;

                } else {

                    $newLineCharFlag = TRUE;
                }
            }

            # Write the line to the file channel
            if ($newLineCharFlag) {

                $line .= "\n";
            }

            print $fileHandle $line;

        } else {

            # Otherwise, display the expressions
            while (@printList) {

                my ($expression, $endChar, $string, $number);

                $expression = shift @printList;
                $endChar = shift @printList;

                # Evaluate the expression. If there's been an error, ->setError should already have
                #   been called to display the error message (and $string) will be 'undef')
                $string = $expression->evaluate();
                if (! defined $string) {

                    # Implementation complete
                    return 1;
                }

                # In 'forced window' mode, a space is added after the number (just as many BASIC
                #   dialects did). Otherwise, no extra space is added
                if ($self->scriptObj->forcedWinFlag && ref($expression) =~ m/Numeric/) {

                    $string .= ' ';
                }

                # Display the expressions in the 'main' window (unless $self->forcedWinFlag is set,
                #   in which case the output is diverted to the task window)

                # Handle the end character (comma or semicolon)
                if ($endChar eq ',') {

                    $number = 14 - ($self->scriptObj->column % 14);
                    $string .= (' ' x $number);

                    # Display the string without a trailing newline character and adjust the column
                    #   accordingly
                    if ($self->scriptObj->forcedWinFlag) {

                        # (If ->column is not 0, the previous PRINT expression must have used a ','
                        #   or ';' character. When writing to the task window, 'echo' means 'no
                        #   newline character after this text')
                        if ($self->scriptObj->column) {
                            $taskObj->insertPrint($string, 'echo');
                        } else {
                            $taskObj->insertPrint($string);
                        }

                    } else {

                        # (When writing to the 'main' window, 'echo' means 'no newline character
                        #   before this text')
                        $session->writeText($string, 'echo');
                    }

                    $self->scriptObj->set_column($self->scriptObj->column + $number);

                } elsif ($endChar eq ';') {

                    # Display the string without a trailing newline character and adjust the column
                    #   accordingly
                    if ($self->scriptObj->forcedWinFlag) {

                        if ($self->scriptObj->column) {
                            $taskObj->insertPrint($string, 'echo');
                        } else {
                            $taskObj->insertPrint($string);
                        }

                    } else {

                        $session->writeText($string, 'echo');
                    }

                    $self->scriptObj->set_column($self->scriptObj->column + length($string));

                } else {

                    # Display the string with a trailing newline character
                    if ($self->scriptObj->forcedWinFlag) {

                        if ($self->scriptObj->column) {
                            $taskObj->insertPrint($string, 'echo');
                        } else {
                            $taskObj->insertPrint($string);
                        }

                    } else {

                        $session->writeText($string);
                    }

                    $self->scriptObj->set_column(0);
                }
            }
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::profile;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::profile::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # PROFILE [ expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $nameExp;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        if (! $self->tokenGroupObj->testStatementEnd()) {

            # Convert the name string into an expression
            $nameExp = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $nameExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Check that nothing more remains
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        if ($nameExp) {

            # Store the expression, so $self->implement can retrieve it
            $self->ivAdd('parseDataHash', 'name', $nameExp);
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($nameExp, $name);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the argument stored by $self->parse
        $nameExp = $self->ivShow('parseDataHash', 'name');

        if (defined $nameExp) {

            # Evaluate the expression
            $name = $nameExp->evaluate();

            # Check that the profile actually exists
            if (! $self->scriptObj->session->ivExists('profHash', $name)) {

                # It doesn't exist, so resume using the current world
                $self->scriptObj->set_useProfile($self->scriptObj->session->currentWorld->name);

            } else {

                # Use the specified profile
                $self->scriptObj->set_useProfile($name);
            }

        } else {

            # No profile specified, so resume using the current world
            $self->scriptObj->set_useProfile($self->scriptObj->session->currentWorld->name);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::read;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::read::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # READ variable-name [ , variable-name ... ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # The rest of the statement is a list of lvalues
        do {

            my $expression = Language::Axbasic::Expression::Lvalue->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $expression) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_variable',
                    $self->_objClass . '->parse',
                );

            } else {

                $self->ivPush('parseDataList', $expression);
            }

        } while (defined $self->tokenGroupObj->shiftMatchingToken(','));

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my @lvalueList;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the list of lvalues stored by $self->parse
        @lvalueList = $self->parseDataList;
        foreach my $lvalue (@lvalueList) {

            my ($var, $data, $value);

            $var = $lvalue->variable;
            $data = $self->scriptObj->shift_readDataList();

            if (! defined $data) {

                return $self->scriptObj->setError(
                    'reading_past_end_of_data',
                    $self->_objClass . '->implement',
                );
            }

            # $data is a LA::Expression::Constant, but we still have to evaluate it
            $value = $data->evaluate();
            $var->set($value);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::redim;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::redim::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # REDIM variable-name [ arg-list ] [ , variable-name [ arg-list ] ... ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Process each array in turn (if several appear on the same line, they are separated by
        #   commas)
        do {

            my $expression = Language::Axbasic::Expression::Lvalue->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $expression) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );

            } else {

                # Save the expression object so $self->implement can use it, if it is called
                $self->ivPush('parseDataList', $expression);
            }

        } while (defined $self->tokenGroupObj->shiftMatchingToken(','));

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my @expList;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Import the list of expressions saved by $self->parse
        @expList = $self->parseDataList;

        # Redefine each array in turn
        foreach my $expression (@expList) {

            my (
                $varObj,
                @indices,
            );

            # If the $expression appeared in a line like REDIM var, rather than the correct REDIM
            #   var(10), then ->argListObj won't be defined
            if (! defined $expression->argListObj) {

                return $self->scriptObj->setError(
                    'invalid_expression_in_REDIM_statement',
                    $self->_objClass . '->implement',
                );
            }

            $varObj = $expression->varObj;

            # Set up the array
            @indices = $expression->argListObj->evaluate();
            if (! @indices) {

                # DIM var() statements not allowed
                return $self->scriptObj->setError(
                    'invalid_expression_in_REDIM_statement',
                    $self->_objClass . '->implement',
                );

            } elsif (scalar @indices == 1 && $indices[0] == 0) {

                # LA::Variable::Array allows empty one-dimensional arrays, which PEEK and PEEK...
                #   statements need, but we can't create an empty one-dimensional array with REDIM
                #   statements
                return $self->scriptObj->setError(
                    'invalid_array_dimension_size_NUM',
                    $self->_objClass . '->implement',
                    'NUM', $indices[0],
                );

            } else {

                $varObj->dimension(@indices);
            }
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::relay;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::relay::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # RELAY expression [ , expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($cmdExp, $token, $obscureExp);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the expression and store it for ->implement to use
        $cmdExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $cmdExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Get the second expression, if specified
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $token = $self->tokenGroupObj->lookAhead();
            if (defined $token) {

                $obscureExp = Language::Axbasic::Expression::Arithmetic->new(
                    $self->scriptObj,
                    $self->tokenGroupObj,
                );

                if (! defined $obscureExp) {

                    return $self->scriptObj->setError(
                        'missing_or_illegal_expression',
                        $self->_objClass . '->parse',
                    );
                }
            }
        }

        # There should be nothing after the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expressions, so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'cmd_exp', $cmdExp);
        $self->ivAdd('parseDataHash', 'obscure_exp', $obscureExp);  # May be 'undef'

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($cmdExp, $obscureExp, $cmd, $obscure);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the arguments stored by $self->parse
        $cmdExp = $self->ivShow('parseDataHash', 'cmd_exp');
        $obscureExp = $self->ivShow('parseDataHash', 'obscure_exp');

        # Evaluate the expression to get a world command
        $cmd = $cmdExp->evaluate();
        if ($obscureExp) {

            $obscure = $obscureExp->evaluate();
        }

        # Send the command to the world
        if ($obscureExp) {

            # If some part of the command has to be obscured in the 'main' window, we don't have to
            #   worry about classifying it as a non-movement command; the GA::Session doesn't store
            #   it anywhere
            $self->scriptObj->session->worldCmd($cmd, $obscure);

        } else {

            # It's an ordinary relay command
            $self->scriptObj->session->relayCmd($cmd);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::rem;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::rem::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # REM [ ... ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $token;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Every token on a line after a 'rem' statement is part of the remark, and must be ignored
        $self->tokenGroupObj->set_tokenList();

        return 1;
    }

#   sub implement {}        # ->implement method from LA::Statement inherited
}

{ package Language::Axbasic::Statement::reset;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::reset::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # RESET #channel: BEGIN
    # RESET #channel: END

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($channelToken, $channel, $nextToken);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the channel token. For RESET statements, it must include a colon at the end
        #   (e.g. '#5:' )
        $channelToken = $self->tokenGroupObj->shiftTokenIfCategory('file_channel');
        if (! defined $channelToken || ! ($channelToken->tokenText =~ m/\:$/)) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );

        } else {

            # Store the channel number
            $channelToken->tokenText =~ m/([0-9]+)/;
            $channel = $1;

            # True BASIC specifies that the channel must be in the range 1-999; same range used by
            #   Axbasic
            if ($channel < 1 || $channel > 999) {

                return $self->scriptObj->setError(
                    'file_channel_NUM_out_of_range',
                    $self->_objClass . '->parse',
                    'NUM', $channel,
                );

            } else {

                $self->ivAdd('parseDataHash', 'channel', $channel);
            }
        }

        # The next token must be one of the keywords BEGIN or END
        $nextToken = $self->tokenGroupObj->shiftTokenIfCategory('keyword');
        if (
            ! $nextToken
            || ($nextToken->tokenText ne 'begin' && $nextToken->tokenText ne 'end')
        ) {
            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );

        } else {

            $self->ivAdd('parseDataHash', 'type', $nextToken->tokenText);
        }

        # Check that nothing follows the BEGIN/END keywords
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($channel, $type, $channelObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the variables stored by ->parse
        $channel = $self->ivShow('parseDataHash', 'channel');
        $type = $self->ivShow('parseDataHash', 'type');

        # Check that the file channel is open
        if (! $self->scriptObj->ivExists('fileChannelHash', $channel)) {

            return $self->scriptObj->setError(
                'file_channel_NUM_not_open',
                $self->_objClass . '->implement',
                'NUM', $channel,
            );

        } else {

            $channelObj = $self->scriptObj->ivShow('fileChannelHash', $channel);
        }

        # Move the pointer
        if ($type eq 'begin') {
            seek($channelObj->fileHandle, 0, Fcntl::SEEK_SET);
        } elsif ($type eq 'end') {
            seek($channelObj->fileHandle, 0, Fcntl::SEEK_END);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::restore;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::restore::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # RESTORE

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # RESTORE statements always appear on their own
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Reset the global data list
        $self->scriptObj->set_readDataList($self->scriptObj->globalDataList);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::return;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::return::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # RETURN expression
    # RETURN

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # No line numbers
        if ($self->scriptObj->executionMode eq 'no_line_num') {

            # Check that we're inside a subroutine declaration
            if (! $self->scriptObj->currentParseSub) {

                return $self->scriptObj->setError(
                    'RETURN_statement_used_outside_subroutine',
                    $self->_objClass . '->parse',
                );
            }

            # The rest of the statement is an expression to return
            $expression = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $expression) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }

            # Check that nothing follows the expression
            if (! $self->tokenGroupObj->testStatementEnd()) {

                return $self->scriptObj->setError(
                    'unexpected_keywords,_operators_or_expressions',
                    $self->_objClass . '->parse',
                );
            }

            # Store the GOSUB expression, so $self->implement can retrieve it
            $self->ivAdd('parseDataHash', 'expression', $expression);

        # Line numbers
        } else {

            # We only need to check that the 'return' keyword isn't followed by anything
            if (! $self->tokenGroupObj->testStatementEnd()) {

                return $self->scriptObj->setError(
                    'unexpected_keywords,_operators_or_expressions',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($subObj, $statementObj, $callStatement, $expression, $lineNumber);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # No line numbers
        if ($self->scriptObj->executionMode eq 'no_line_num') {

            $subObj = $self->scriptObj->popSubStack();
            if (! defined $subObj) {

                return $self->scriptObj->setDebug(
                    'Sub/func stack seems to be empty',
                    $self->_objClass . '->implement',
                );
            }

            # Execution resumes at the first statement after the one that called the subroutine
            $callStatement = $subObj->callStatement;

            # The next statement to execute is the statement after that
            if (defined $callStatement->nextStatement) {

                $self->scriptObj->set_nextStatement($callStatement->nextStatement);
                $self->scriptObj->set_nextLine($callStatement->lineObj->procLineNum);

            } else {

                $self->scriptObj->set_nextStatement(undef);
                $self->scriptObj->set_nextLine($callStatement->lineObj->procLineNum + 1);
            }

            # If a return variable was specified (because the subroutine was called in a statement
            #   like 'LET a$ = CALL mysub (args)' ), set its value
            if (defined $subObj->returnVar) {

                $expression = $self->ivShow('parseDataHash', 'expression');
                $subObj->returnVar->set($expression->evaluate());
            }

        # Line numbers
        } else {

            # Get the LA::Statement::gosub statement from the script's subroutine/function stack
            $statementObj = $self->scriptObj->pop_gosubStackList();
            if (! defined $statementObj) {

                return $self->scriptObj->setError(
                    'RETURN_statement_without_matching_GOSUB',
                    $self->_objClass . '->implement',
                );
            }

            # The next statement (or line) to be executed is the one after the gosub statement
            if (defined $statementObj->nextStatement) {

                $self->scriptObj->set_nextStatement($statementObj->nextStatement);
                $self->scriptObj->set_nextLine($statementObj->lineObj->procLineNum);

            } else {

                $self->scriptObj->set_nextStatement(undef);
                $self->scriptObj->set_nextLine($statementObj->lineObj->procLineNum + 1);
            }
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::revpath;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::revpath::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # REVPATH variable-name

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $lvalue;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # (Copied from the SORT statement)
        # Abuse the IV that allows undeclared variables to be created by hijacking it to tell
        #   LA::Variable->lookup that we're intentionally referring to an array variable, such as
        #   that created by
        #       DIM path$ (10)
        #   ...by a variable name that looks like a scalar, i.e.
        #       REVPATH path$
        $self->scriptObj->set_declareMode('sort');

        # Get the variable name
        $lvalue = Language::Axbasic::Expression::Lvalue->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $lvalue) {

            return $self->scriptObj->setError(
                'missing_or_illegal_variable',
                $self->_objClass . '->parse',
            );
        }

        # Reset the temporary IV
        $self->scriptObj->set_declareMode('default');

        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the variable for ->implement to use
        $self->ivAdd('parseDataHash', 'lvalue', $lvalue);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $lvalue, $varObj, $count,
            @cellList, @valueList, @reversedList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the array variable whose contents is to be reversed
        $lvalue = $self->ivShow('parseDataHash', 'lvalue');
        $varObj = $lvalue->varObj;

        # Only 1-dimensional arrays (e.g. DIM var (5) ) can be reversed. Multi-dimensional arrays
        #   (e.g. DIM var (5, 5, 2) ) can't be reversed
        if ($varObj->dimCount > 1) {

            return $self->scriptObj->setError(
                'REVPATH_statement_cannot_operate_on_multi-dimensional_array',
                $self->_objClass . '->implement',
            );
        }

        # Import the values stored in the array, reverse them, and store them back in the array
        @cellList = $varObj->cellList;

        # Ignore the cell numbered 0 - REVPATH assumes the first significant cell is #1
        shift @cellList;

        if (@cellList) {

            # Get the values stored in the variables
            foreach my $var (@cellList) {

                push (@valueList, $var->value);
            }

            # The first arg, 0, instructs the function to not abbreviate anything and, for secondary
            #   directions that have more than one possible opposite direction, to use the first one
            @reversedList = $self->scriptObj->session->worldModelObj->reversePath(
                $self->scriptObj->session,
                'no_abbrev',
                @valueList,
            );

            # Use the existing variables stored in the array, and simply change their values to the
            #   reversed list of directions
            $count = -1;
            foreach my $var (@cellList) {

                $count++;
                $var->set($reversedList[$count]);
            }
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::select;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::select::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # SELECT CASE variable-name

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($token, $expression, $subObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # The 'select' keyword is not available in primitive numbering mode
        if ($self->scriptObj->executionMode ne 'no_line_num') {

            return $self->scriptObj->setError(
                'statement_not_available_with_line_numbers',
                $self->_objClass . '->parse',
            );
        }

        # The next token is always the keyword CASE
        $token = $self->tokenGroupObj->shiftMatchingToken('case');
        if (! defined $token) {

            return $self->scriptObj->setError(
                'syntax error',
                $self->_objClass . '->parse',
            );
        }

        # Read the variable name
        $expression = Language::Axbasic::Expression::Lvalue->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_variable',
                $self->_objClass . '->parse',
            );
        }

        # Check there's nothing else in the statement after the variable
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Add this SELECT statement to the SELECT code block stack for the current subroutine
        $subObj = $self->scriptObj->returnCurrentSub();
        $subObj->push_selectStackList($self);

        # Store the iterator
        $self->ivAdd('parseDataHash', 'expression', $expression);
        # We don't know what the corresponding END SELECT (and, optionally, the CASE ELSE)
        #   statements are, yet
        $self->ivAdd('parseDataHash', 'case_else_statement', undef);
        $self->ivAdd('parseDataHash', 'end_select_statement', undef);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $expression, $value, $endStatement, $matchStatement, $caseElseStatement,
            $subObj,
            @caseStatementList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the variable to test and the corresponding CASE and END SELECT statements
        $expression = $self->ivShow('parseDataHash', 'expression');
        $endStatement = $self->ivShow('parseDataHash', 'end_select_statement');
        @caseStatementList = $self->parseDataList;

        # Get the value of the variable
        $value = $expression->evaluate();

        # Each CASE statement contains, in its ->parseDataList, a list of constants.
        # Test each CASE statement's constant list. The CASE statement which contains the constant
        #   matching the variable's value is the one to execute next
        OUTER: foreach my $caseStatement (@caseStatementList) {

            INNER: foreach my $constant ($caseStatement->parseDataList) {

                if ($value eq $constant) {

                    $matchStatement = $caseStatement;
                    last OUTER;
                }
            }
        }

        if (! $matchStatement) {

            # Use the CASE ELSE statement, if it was found during the ->parse stage
            $caseElseStatement = $self->ivShow('parseDataHash', 'case_else_statement');
            if (defined $caseElseStatement) {

                # The next statement to execute is the one after CASE ELSE
                if (defined $caseElseStatement->nextStatement) {

                    $self->scriptObj->set_nextStatement($caseElseStatement->nextStatement);

                } else {

                    # The case statement was the last (or only) statement on the line: use the next
                    #   line
                    $self->scriptObj->set_nextLine($caseElseStatement->lineObj->procLineNum + 1);
                }

            } else {

                return $self->scriptObj->setError(
                    'no_CASE_selected_and_no_CASE_ELSE',
                    $self->_objClass . '->implement',
                );
            }

        } else {

            # The next statement to execute is the one after $matchStatement
            if (defined $matchStatement->nextStatement) {

                $self->scriptObj->ivPoke('nextStatement', $matchStatement->nextStatement);

            } else {

                # The case statement was the last (or only) statement on the line: use the next line
                $self->scriptObj->set_nextStatement($matchStatement->lineObj->procLineNum + 1);
            }
        }

        # Add this SELECT CASE code block to the main code block stack, since we're going to execute
        #   it now. The corresponding CASE/END SELECT statement will remove it.
        # NB The main ->blockStackList is used during ->implement for all kinds of code blocks;
        #   ->selectStackList is used during ->parse for SELECT CASE..CASE..END SELECT blocks
        #   only
        $subObj = $self->scriptObj->returnCurrentSub();
        $subObj->push_blockStackList($self);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::send;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::send::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # SEND expression [ , expression [ , expression ... ] ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $cmdExp, $exitFlag,
            @otherExpList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the command expression
        $cmdExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $cmdExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Get the optional expressions
        do {
            my ($token, $otherExp);

            if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

                $token = $self->tokenGroupObj->lookAhead();
                if (defined $token) {

                    $otherExp = Language::Axbasic::Expression::Arithmetic->new(
                        $self->scriptObj,
                        $self->tokenGroupObj,
                    );

                    if (! defined $otherExp) {

                        return $self->scriptObj->setError(
                            'missing_or_illegal_expression',
                            $self->_objClass . '->parse',
                        );

                    } else {

                        push (@otherExpList, $otherExp);
                    }
                }

            } else {

                $exitFlag = TRUE;
            }

        } until ($exitFlag);

        # Check that nothing follows the expressions
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expressions, so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'cmd_exp', $cmdExp);
        $self->ivPoke('parseDataList', @otherExpList);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $cmdExp, $cmd, $newCmd,
            @otherExpList, @otherList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the arguments stored by $self->parse
        $cmdExp = $self->ivShow('parseDataHash', 'cmd_exp');
        @otherExpList = $self->parseDataList;

        # Evaluate each expression
        $cmd = $cmdExp->evaluate();
        foreach my $exp (@otherExpList) {

            push (@otherList, $exp->evaluate());
        }

        # Interpolate the command using the (optional) arguments in @otherExpList
        $newCmd = $self->scriptObj->session->prepareCmd($cmd, @otherList);
        if (! $newCmd) {

            # The command couldn't be interpolated, so just send $cmd
            $newCmd = $cmd;
        }

        $self->scriptObj->session->worldCmd($newCmd);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::setgauge;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::setgauge::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # SETGAUGE expression , expression , expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($numberExp, $valExp, $maxValExp);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the arguments into expressions
        $numberExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $numberExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        if (! defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );
        }

        $valExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $valExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        if (! defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );
        }

        $maxValExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $maxValExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Check that nothing follows the expressions
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expressions, so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'number', $numberExp);
        $self->ivAdd('parseDataHash', 'val', $valExp);
        $self->ivAdd('parseDataHash', 'max_val', $maxValExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($numberExp, $valExp, $maxValExp, $number, $val, $maxVal);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Retrieve the arguments stored by $self->parse
        $numberExp = $self->ivShow('parseDataHash', 'number');
        $valExp = $self->ivShow('parseDataHash', 'val');
        $maxValExp = $self->ivShow('parseDataHash', 'max_val');

        # Evaluate each expression
        $number = $numberExp->evaluate();
        $val = $valExp->evaluate();
        $maxVal = $maxValExp->evaluate();

        # $num must be an integer, >= 0 (but it doesn't need to be a gauge number which has
        #   actually been created with an ADDGAUGE or ADDCONGAUGE statement)
        if ($number =~ m/\D/ || $number < 0) {

            return $self->scriptObj->setError(
                'invalid_gauge_number',
                $self->_objClass . '->implement',
            );
        }

        # $val and $maxVal must both be decimal numbers, otherwise we'll have to change them to
        #   'undef'
        if (! ($val =~ m/^\-?((\d+(\.\d*)?)|(\.\d+))$/)) {

            $val = undef;
        }

        if (! ($maxVal =~ m/^\-?((\d+(\.\d*)?)|(\.\d+))$/)) {

            $maxVal = undef;
        }

        # Tell the Script task to set the gauge's value
        $self->scriptObj->parentTask->setGauge($number, $val, $maxVal);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::setstatus;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::setstatus::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # SETSTATUS expression , expression , expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($numberExp, $valExp, $maxValExp);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the arguments into expressions
        $numberExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $numberExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        if (! defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );
        }

        $valExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $valExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        if (! defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            return $self->scriptObj->setError(
                'syntax_error',
                $self->_objClass . '->parse',
            );
        }

        $maxValExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $maxValExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Check that nothing follows the expressions
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expressions, so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'number', $numberExp);
        $self->ivAdd('parseDataHash', 'val', $valExp);
        $self->ivAdd('parseDataHash', 'max_val', $maxValExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($numberExp, $valExp, $maxValExp, $number, $val, $maxVal);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Retrieve the arguments stored by $self->parse
        $numberExp = $self->ivShow('parseDataHash', 'number');
        $valExp = $self->ivShow('parseDataHash', 'val');
        $maxValExp = $self->ivShow('parseDataHash', 'max_val');

        # Evaluate each expression
        $number = $numberExp->evaluate();
        $val = $valExp->evaluate();
        $maxVal = $maxValExp->evaluate();

        # $num must be an integer, >= 0 (but it doesn't need to be a status bar number which has
        #   actually been created with an ADDSTATUS or ADDCONSTATUS statement)
        if ($number =~ m/\D/ || $number < 0) {

            return $self->scriptObj->setError(
                'invalid_status_bar_number',
                $self->_objClass . '->implement',
            );
        }

        # $val and $maxVal must both be decimal numbers, otherwise we'll have to change them to
        #   'undef'
        if (! ($val =~ m/^\-?((\d+(\.\d*)?)|(\.\d+))$/)) {

            $val = undef;
        }

        if (! ($maxVal =~ m/^\-?((\d+(\.\d*)?)|(\.\d+))$/)) {

            $maxVal = undef;
        }

        # Tell the Script task to set the status bar's text
        $self->scriptObj->parentTask->setStatusBar($number, $val, $maxVal);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::settrig;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::settrig::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # SETTRIG expression [ , expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #   when the first token in the statement is the keyword 'settrig'
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($stimulusExp, $newScriptExp, $token);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the stimulus string into an expression
        $stimulusExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $stimulusExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Get the new script name, if specified
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $token = $self->tokenGroupObj->lookAhead();
            if (defined $token) {

                $newScriptExp = Language::Axbasic::Expression::Arithmetic->new(
                    $self->scriptObj,
                    $self->tokenGroupObj,
                );

                if (! defined $newScriptExp) {

                    return $self->scriptObj->setError(
                        'missing_or_illegal_expression',
                        $self->_objClass . '->parse',
                    );
                }
            }
        }

        # Check that nothing follows the expression(s)
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression(s), so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'stimulus', $stimulusExp);
        $self->ivAdd('parseDataHash', 'new_script', $newScriptExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($stimulusExp, $stimulus, $newScriptExp, $newScript, $interfaceObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the arguments stored by $self->parse
        $stimulusExp = $self->ivShow('parseDataHash', 'stimulus');
        $newScriptExp = $self->ivShow('parseDataHash', 'new_script');   # May be 'undef'

        # If the Axbasic script isn't being run from within an Axmud task and assuming there isn't a
        #   new script to call, ignore this statement altogether
        if ((! $self->scriptObj->parentTask) && (! $newScriptExp)) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Otherwise, evaluate the expressions
        $stimulus = $stimulusExp->evaluate();
        if (defined $newScriptExp) {

            $newScript = $newScriptExp->evaluate();
        }

        # Create the trigger
        if (! $newScriptExp) {

            $interfaceObj = $self->scriptObj->session->createInterface(
                'trigger',
                $stimulus,
                $self->scriptObj->parentTask,
                'notifyPatternSeen',
            );

        } else {

            $interfaceObj = $self->scriptObj->session->createInterface(
                'trigger',
                $stimulus,
                $self->scriptObj->parentTask,
                'execPatternSeen',
            );
        }

        if (defined $interfaceObj) {

            # Store the name of the new script to execute in the interface object
            $interfaceObj->ivAdd('propertyHash', 'new_script', $newScript);

            # Add this trigger to the list of interfaces created during the execution of the
            #   Axbasic script
            $self->scriptObj->push_depInterfaceList($interfaceObj->name);
            $self->scriptObj->set_depInterfaceName($interfaceObj->name);

        } else {

            # Store the fact that creation of the interface failed
            $self->scriptObj->set_depInterfaceName(undef);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::skipiface;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::skipiface::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # SKIPIFACE

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($subObj, $whileStatement);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # SKIPIFACE statements always appear on their own
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $count;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Get the size of the notification list
        $count = $self->scriptObj->ivNumber('notificationList');

        # Do nothing, if the interface notification list is empty or if it contains only one
        #   notification
        if ($count < 2) {

            # Implementation complete
            return 1;

        } else {

            if ($self->scriptObj->currentNotification == ($count - 1)) {

                # At the end of the list
                $self->scriptObj->set_currentNotification(0);

            } else {

                # Move along one position
                $self->scriptObj->inc_currentNotification();
            }

            # Implementation complete
            return 1;
        }
    }
}

{ package Language::Axbasic::Statement::sort;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::sort::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # SORT variable-name

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Abuse the IV that allows undeclared variables to be created by hijacking it to tell
        #   LA::Variable->lookup that we're intentionally referring to an array variable, such as
        #   that created by
        #       DIM var (10)
        #   ...by a variable name that looks like a scalar, i.e.
        #       SORT var
        $self->scriptObj->set_declareMode('sort');

        # Get the variable name
        $expression = Language::Axbasic::Expression::Lvalue->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_variable',
                $self->_objClass . '->parse',
            );
        }

        # Reset the temporary IV
        $self->scriptObj->set_declareMode('default');

        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the variable for ->implement to use
        $self->ivAdd('parseDataHash', 'expression', $expression);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $expression, $varObj, $elementZero,
            @list, @sortedList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the array variable to sort
        $expression = $self->ivShow('parseDataHash', 'expression');
        $varObj = $expression->varObj;

        # Only 1-dimensional arrays (e.g. DIM var (5) ) can be sorted. Multi-dimensional arrays
        #   (e.g. DIM var (5, 5, 2) ) can't be sorted
        if ($varObj->dimCount > 1) {

            return $self->scriptObj->setError(
                'SORT_statement_cannot_operate_on_multi-dimensional_array',
                $self->_objClass . '->implement',
            );
        }

        # Import the values stored in the array, sort them, and store them back in the  array
        @list = $varObj->cellList;

        # Ignore the cell numbered 0 - SORT assumes the first significant cell is #1
        $elementZero = shift @list;

        if (ref($varObj) =~ m/Numeric/) {

            # It's a numeric array
            @sortedList = sort {$a->value <=> $b->value} (@list);

        } else {

            # It's a string array
            @sortedList = sort {$a->value cmp $b->value} (@list);
        }

        # Restore the 0th element to its previous place
        unshift(@sortedList, $elementZero);
        $varObj->ivPoke('cellList', @sortedList);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::sortcase;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::sortcase::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # SORTCASE variable-name

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Abuse the IV that allows undeclared variables to be created by hijacking it to tell
        #   LA::Variable->lookup that we're intentionally referring to an array variable, such as
        #   that created by
        #       DIM var (10)
        #   ...by a variable name that looks like a scalar, i.e.
        #       SORT var
        $self->scriptObj->set_declareMode('sort');

        # Get the variable name
        $expression = Language::Axbasic::Expression::Lvalue->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_variable',
                $self->_objClass . '->parse',
            );
        }

        # Reset the temporary IV
        $self->scriptObj->set_declareMode('default');

        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the variable for ->implement to use
        $self->ivAdd('parseDataHash', 'expression', $expression);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $expression, $varObj, $elementZero,
            @list, @sortedList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the array variable to sort
        $expression = $self->ivShow('parseDataHash', 'expression');
        $varObj = $expression->varObj;

        # Only 1-dimensional arrays (e.g. DIM var (5) ) can be sorted. Multi-dimensional arrays
        #   (e.g. DIM var (5, 5, 2) ) can't be sorted
        if ($varObj->dimCount > 1) {

            return $self->scriptObj->setError(
                'SORTCASE_statement_cannot_operate_on_multi-dimensional_array',
                $self->_objClass . '->implement',
            );
        }

        # Import the values stored in the array, sort them, and store them back in the  array
        @list = $varObj->cellList;

        # Ignore the cell numbered 0 - SORTCASE assumes the first significant cell is #1
        $elementZero = shift @list;

        if (ref($varObj) =~ m/Numeric/) {

            # It's a numeric array
            @sortedList = sort {$a->value <=> $b->value} (@list);

        } else {

            # It's a string array
            @sortedList = sort {lc($a->value) cmp ($b->value)} (@list);
        }

        # Restore the 0th element to its previous place
        unshift(@sortedList, $elementZero);
        $varObj->ivPoke('cellList', @sortedList);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::sortcaser;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::sortcaser::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # SORTCASER variable-name

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Abuse the IV that allows undeclared variables to be created by hijacking it to tell
        #   LA::Variable->lookup that we're intentionally referring to an array variable, such as
        #   that created by
        #       DIM var (10)
        #   ...by a variable name that looks like a scalar, i.e.
        #       SORT var
        $self->scriptObj->set_declareMode('sort');

        # Get the variable name
        $expression = Language::Axbasic::Expression::Lvalue->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_variable',
                $self->_objClass . '->parse',
            );
        }

        # Reset the temporary IV
        $self->scriptObj->set_declareMode('default');

        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the variable for ->implement to use
        $self->ivAdd('parseDataHash', 'expression', $expression);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $expression, $varObj, $elementZero,
            @list, @sortedList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the array variable to sort
        $expression = $self->ivShow('parseDataHash', 'expression');
        $varObj = $expression->varObj;

        # Only 1-dimensional arrays (e.g. DIM var (5) ) can be sorted. Multi-dimensional arrays
        #   (e.g. DIM var (5, 5, 2) ) can't be sorted
        if ($varObj->dimCount > 1) {

            return $self->scriptObj->setError(
                'SORTCASER_statement_cannot_operate_on_multi-dimensional_array',
                $self->_objClass . '->implement',
            );
        }

        # Import the values stored in the array, sort them, and store them back in the array
        @list = $varObj->cellList;

        # Ignore the cell numbered 0 - SORTCASER assumes the first significant cell is #1
        $elementZero = shift @list;

        if (ref($varObj) =~ m/Numeric/) {

            # It's a numeric array
            @sortedList = sort {$b->value <=> $a->value} (@list);

        } else {

            # It's a string array
            @sortedList = sort {lc($b->value) cmp lc($a->value)} (@list);
        }

        # Restore the 0th element to its previous place
        unshift(@sortedList, $elementZero);
        $varObj->ivPoke('cellList', @sortedList);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::sortr;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::sortr::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # SORTR variable-name

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Abuse the IV that allows undeclared variables to be created by hijacking it to tell
        #   LA::Variable->lookup that we're intentionally referring to an array variable, such as
        #   that created by
        #       DIM var (10)
        #   ...by a variable name that looks like a scalar, i.e.
        #       SORT var
        $self->scriptObj->set_declareMode('sort');

        # Get the variable name
        $expression = Language::Axbasic::Expression::Lvalue->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_variable',
                $self->_objClass . '->parse',
            );
        }

        # Reset the temporary IV
        $self->scriptObj->set_declareMode('default');

        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the variable for ->implement to use
        $self->ivAdd('parseDataHash', 'expression', $expression);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $expression, $varObj, $elementZero,
            @list, @sortedList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the array variable to sort
        $expression = $self->ivShow('parseDataHash', 'expression');
        $varObj = $expression->varObj;

        # Only 1-dimensional arrays (e.g. DIM var (5) ) can be sorted. Multi-dimensional arrays
        #   (e.g. DIM var (5, 5, 2) ) can't be sorted
        if ($varObj->dimCount > 1) {

            return $self->scriptObj->setError(
                'SORTR_statement_cannot_operate_on_multi-dimensional_array',
                $self->_objClass . '->implement',
            );
        }

        # Import the values stored in the array, sort them, and store them back in the array
        @list = $varObj->cellList;

        # Ignore the cell numbered 0 - SORT assumes the first significant cell is #1
        $elementZero = shift @list;

        if (ref($varObj) =~ m/Numeric/) {

            # It's a numeric array
            @sortedList = sort {$b->value <=> $a->value} (@list);

        } else {

            # It's a string array
            @sortedList = sort {$b->value cmp $a->value} (@list);
        }

        # Restore the 0th element to its previous place
        unshift(@sortedList, $elementZero);
        $varObj->ivPoke('cellList', @sortedList);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::speak;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::speak::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # SPEAK expression [ , expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($textExp, $configExp, $token);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the text and configuration strings into expressions
        $textExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $textExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $configExp = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $configExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Check that nothing follows the expressions
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expressions, so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'text', $textExp);
        $self->ivAdd('parseDataHash', 'config', $configExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($textExp, $text, $configExp, $configuration, $cmd);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the arguments stored by $self->parse
        $textExp = $self->ivShow('parseDataHash', 'text');
        $configExp = $self->ivShow('parseDataHash', 'config');

        # Evaluate each expression
        $text = $textExp->evaluate();
        if (defined $configExp) {

            $configuration = $configExp->evaluate();
        }

        # Prepare the client command
        $cmd = 'speak <' . $text . '>';
        if ($configuration) {

            $cmd .= ' -n ' . $configuration;
        }

        # Send the command
        $self->scriptObj->session->pseudoCmd($cmd, $self->scriptObj->pseudoCmdMode);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::speed;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::speed::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # SPEED expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the expression and store it for ->implement to use
        $expression = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );

        } else {

            $self->ivAdd('parseDataHash', 'expression', $expression);
        }

        # There should be nothing after the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression, $string);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the expression to be written
        $expression = $self->ivShow('parseDataHash', 'expression');
        # Evaluate the expression to get a scalar value
        $string = $expression->evaluate();

        # Execute the expression as a speedwalk command
        $self->scriptObj->session->speedWalkCmd($string);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::stop;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::stop::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # STOP

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # STOP statements always appear on their own
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Execution of the Axbasic script can now stop
        if ($self->scriptObj->executionStatus ne 'finished') {

            # 'wait_input' means that parsing/implementation of the script has finished
            $self->scriptObj->set_executionStatus('finished');
            # 'finished' means that parsing/implementation finished without an error
            $self->scriptObj->set_scriptStatus('finished');
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::sub;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::sub::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # SUB STRING subroutine-name ( [ arg-list ] )
    # SUB NUMERIC subroutine-name ( [ arg-list ] )

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($subExpression, $result, $type, $subObj, $expression);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # The SUB keyword is not available in primitive numbering mode
        if ($self->scriptObj->executionMode ne 'no_line_num') {

            return $self->scriptObj->setError(
                'statement_not_available_with_line_numbers',
                $self->_objClass . '->parse',
            );
        }

        # Look for the keywords NUMERIC or STRING, which define what type of return value the
        #   subroutine will produce
        $result = $self->tokenGroupObj->shiftMatchingToken('numeric');
        if (defined $result) {

            $type = 'numeric';

        } else {

            $result = $self->tokenGroupObj->shiftMatchingToken('string');
            if (defined $result) {

                $type = 'string';

            } else {

                return $self->scriptObj->setError(
                    'syntax_error',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Temporarily set the IV that allows undeclared variables to be created
        $self->scriptObj->set_declareMode('local_scalar');

        # The subroutine name, and its arguments, consist of all the tokens up until the close
        #   parenthesis
        if ($type eq 'numeric') {

            $subExpression = Language::Axbasic::Expression::Subroutine::Numeric->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

        } else {

            $subExpression = Language::Axbasic::Expression::Subroutine::String->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );
        }

        # Reset the temporary IV
        $self->scriptObj->set_declareMode('default');

        if (! defined $subExpression) {

            return $self->scriptObj->setError(
                'subroutine_declaration_error',
                $self->_objClass . '->parse',
            );
        }

        # Check that there is nothing after the list of arguments (except for the statement
        #   separator, :)
        $result = $self->tokenGroupObj->testStatementEnd();
        if (! defined $result) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Subroutines cannot be declared inside another one (except for the implied *main
        #   subroutine, in which any number of subroutines can be declared)
        if ($self->scriptObj->currentParseSub) {

            return $self->scriptObj->setError(
                'subroutine_declared_inside_another',
                $self->_objClass . '->parse',
            );
        }

        # We don't actually want the LA::Expression, just the LA::Subroutine object we've declared
        $subObj = $subExpression->subObj;
        # Store it in the script's list of subroutines
        $self->scriptObj->add_subName($subObj->name, $subObj);

        # Save the function object - ->implement needs it
        $self->ivAdd('parseDataHash', 'sub_obj', $subObj);

        # Tell LA::Script->parse that it's parsing statements inside a subroutine declaration now
        $self->scriptObj->set_currentParseSub($subObj);
        # Tell the subroutine in which statement it is declared
        $subObj->set_declareStatement($self);
        # Tell the subroutine what kind of return value it is going to send
        $subObj->set_returnVarType($type);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($subObj, $endStatement);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # SUB statements are ->implemented in the following situation
        #
        #   PRINT "Hello world!"
        #   SUB STRING test (var$)
        #       ...
        #   END SUB
        #   PRINT "Goodbye cruel world!"
        #   END
        #
        # ...namely, when a subroutine declaration occurs before the END statement
        # After executing the PRINT "Hello world!", this function locates the correct
        #   LA::Subroutine, finds the END SUB statement, and marks the next statement
        #   after that - in this case, the PRINT "Goodbye cruel world!" - as the
        #   next statement to execute. Everything between SUB...END SUB is ignored

        $subObj = $self->ivShow('parseDataHash', 'sub_obj');

        # Find the subroutine's END SUB statement
        $endStatement = $subObj->terminateStatement;

        # The next statement to execute is the statement after that
        if (defined $endStatement->nextStatement) {

            $self->scriptObj->set_nextStatement($endStatement->nextStatement);
            $self->scriptObj->set_nextLine($endStatement->lineObj->procLineNum);

        } else {

            $self->scriptObj->set_nextStatement(undef);
            $self->scriptObj->set_nextLine($endStatement->lineObj->procLineNum + 1);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::titlewin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::titlewin::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # TITLEWIN expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the expression and store it for ->implement to use
        $expression = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );

        } else {

            $self->ivAdd('parseDataHash', 'expression', $expression);
        }

        # There should be nothing after the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression, $string);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the expression to be used as a title
        $expression = $self->ivShow('parseDataHash', 'expression');
        # Evaluate the expression to get a string
        $string = $expression->evaluate();

        # If the Axbasic script is being run from within an Axmud task and the task window is open,
        #   set its title. Otherwise, do nothing
        if ($self->scriptObj->parentTask && $self->scriptObj->parentTask->taskWinFlag) {

            # Write to the window. If $string is an empty string, restore the original title
            if ($string) {
                $self->scriptObj->parentTask->resetTaskWinTitle($string);
            } else {
                $self->scriptObj->parentTask->resetTaskWinTitle();
            }
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::unflashwin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::unflashwin::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # UNFLASHWIN

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # UNFLASHWIN statements always appear on their own
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script is being run from within an Axmud task and the task window is open,
        #   reset the window's urgency hint. Otherwise, do nothing
        if ($self->scriptObj->parentTask && $self->scriptObj->parentTask->winObj) {

            # Sets the window urgency hint
            $self->scriptObj->parentTask->winObj->resetUrgent();
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::until;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::until::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # UNTIL condition

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($condition, $subObj, $doStatement);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # The 'until' keyword is not available in primitive numbering mode
        if ($self->scriptObj->executionMode ne 'no_line_num') {

            return $self->scriptObj->setError(
                'statement_not_available_with_line_numbers',
                $self->_objClass . '->parse',
            );
        }

        # Read a conditional expression
        $condition = Language::Axbasic::Expression::LogicalOr->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $condition) {

            return $self->scriptObj->setError(
                'missing_or_illegal_conditional_expression',
                $self->_objClass . '->parse',
            );

        } else {

            # Store the condition expression, so $self->implement can retrieve it
            $self->ivAdd('parseDataHash', 'condition', $condition);
        }

        # Check there's nothing else in the statement after the condition expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Find the matching DO statement, which should already have been parsed
        $subObj = $self->scriptObj->returnCurrentSub();
        if (! $subObj->doStackList) {

            return $self->scriptObj->setError(
                'UNTIL_statement_without_matching_DO',
                $self->_objClass . '->parse',
            );

        } else {

            $doStatement = $subObj->pop_doStackList();

            # Tell the DO statement's ->implement what its matching LOOP statement (i.e. this one)
            #   is
            $doStatement->add_parseDataHash('until_statement', $self);
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($condition, $subObj, $doStatement, $exitFlag);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the condition expression stored by $self->parse
        $condition = $self->ivShow('parseDataHash', 'condition');

        # Get the corresponding DO statement from the current subroutine's code block stack. Keep
        #   removing code blocks from the top of the stack until we get the right one
        $subObj = $self->scriptObj->returnCurrentSub();
        if (! $subObj->blockStackList) {

            return $self->scriptObj->setError(
                'UNTIL_statement_without_matching_DO',
                $self->_objClass . '->implement',
            );
        }

        do {
            $doStatement = $subObj->pop_blockStackList();

            # Check that it's a DO statement - not the start of another kind of code block
            if ($doStatement->keyword eq 'do') {

                # We've found the statement we're looking for
                $exitFlag = TRUE;
            }

        } until ($exitFlag || ! $subObj->blockStackList);

        if (! $exitFlag) {

            return $self->scriptObj->setError(
                'UNTIL_statement_without_matching_DO',
                $self->_objClass . '->implement',
            );
        }

        # Evaluate the condition expression
        if (! $condition->evaluate()) {

            # The condition expression is false, so we need to repeat the loop

            # Perform another iteration of the loop. Go to the statement immediately after the
            #   corresponding DO statement
            if (defined $doStatement->nextStatement) {

                $self->scriptObj->set_nextStatement($doStatement->nextStatement);

            } else {

                # The DO statement was the last (or only) statement on the line: use the next line
                $self->scriptObj->set_nextLine($doStatement->lineObj->procLineNum + 1);
            }

            # Put the corresponding DO statement back into the current subroutine's code block stack
            $subObj->push_blockStackList($doStatement);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::waitactive;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::waitactive::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WAITACTIVE expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $taskNameExp;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the task string into an expression
        $taskNameExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $taskNameExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Check that nothing follows the expression(s)
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression, so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'task_name', $taskNameExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($taskNameExp, $taskName, $taskObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Otherwise, retrieve the argument stored by $self->parse
        $taskNameExp = $self->ivShow('parseDataHash', 'task_name');

        # Evaluate the expression(s)
        $taskName = $taskNameExp->evaluate();

        # Look for a task matching $taskName. GA::Generic::Cmd->findTask recognises task labels
        #   (stored in GA::Client->taskLabelHash), tasks' formal names (stored in
        #   GA::Client->taskPackageHash), or task unique names in the current tasklist (stored in
        #   GA::Session->currentTaskHash)
        ($taskObj) = Games::Axmud::Generic::Cmd->findTask($self->scriptObj->session, $taskName);
        if (! $taskObj) {

            # No matching task in the current tasklist
            return $self->scriptObj->setError(
                'WAITACTIVE_operation_failure',
                $self->_objClass . '->parse',
            );
        }

        # Inform the LA::Script's parent task that it should start waiting
        $self->scriptObj->parentTask->setUpMonitoring('task_active', $taskObj->uniqueName);

        # Halt execution of the Axbasic script to allow control to be passed back to the parent task
        $self->scriptObj->set_scriptStatus('wait_active');

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::waitalive;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::waitalive::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WAITALIVE [ expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $timeoutExp;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the timeout, if specified, and convert it into an expression
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $timeoutExp = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $timeoutExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Check that nothing follows the expression(s)
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression (if specified), so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'timeout', $timeoutExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($timeoutExp, $timeout);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Otherwise, retrieve the argument (if any) stored by $self->parse
        $timeoutExp = $self->ivShow('parseDataHash', 'timeout');

        # Evaluate the expression, if specified
        if (defined $timeoutExp) {

            $timeout = $timeoutExp->evaluate();

            if (! ($timeout =~  /^\d+$/)) {

                return $self->scriptObj->setError(
                    'invalid_integer',
                    $self->_objClass . '->implement',
                );

            } elsif ($timeout < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->implement',
                    'NUM', $timeout,
                );
            }
        }

        # Inform the parent task that it should start waiting
        $self->scriptObj->parentTask->setUpMonitoring(
            'status',
            'alive',
            undef,
            $timeout,
        );

        # Halt execution of the Axbasic script to allow control to be passed back to the parent task
        $self->scriptObj->set_scriptStatus('wait_status');

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::waitarrive;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::waitarrive::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WAITARRIVE [ expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $timeoutExp;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the timeout, if specified, and convert it into an expression
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $timeoutExp = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $timeoutExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Check that nothing follows the expression(s)
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression (if specified), so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'timeout', $timeoutExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($timeoutExp, $timeout);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Otherwise, retrieve the argument (if any) stored by $self->parse
        $timeoutExp = $self->ivShow('parseDataHash', 'timeout');

        # Evaluate the expression, if specified
        if (defined $timeoutExp) {

            $timeout = $timeoutExp->evaluate();

            if (! ($timeout =~  /^\d+$/)) {

                return $self->scriptObj->setError(
                    'invalid_integer',
                    $self->_objClass . '->implement',
                );

            } elsif ($timeout < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->implement',
                    'NUM', $timeout,
                );
            }
        }

        # Inform the parent task that it should start waiting
        $self->scriptObj->parentTask->setUpMonitoring(
            'locator',
            'arrive',
            undef,
            $timeout,
        );

        # Halt execution of the Axbasic script to allow control to be passed back to the parent task
        $self->scriptObj->set_scriptStatus('wait_status');

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::waitdead;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::waitdead::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WAITDEAD [ expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $timeoutExp;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the timeout, if specified, and convert it into an expression
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $timeoutExp = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $timeoutExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Check that nothing follows the expression(s)
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression (if specified), so $self->implement can retrieve it
        if (defined $timeoutExp) {

            $self->ivAdd('parseDataHash', 'timeout', $timeoutExp);
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($timeoutExp, $timeout);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Otherwise, retrieve the argument (if any) stored by $self->parse
        $timeoutExp = $self->ivShow('parseDataHash', 'timeout');

        # Evaluate the expression, if specified
        if (defined $timeoutExp) {

            $timeout = $timeoutExp->evaluate();

            if (! ($timeout =~  /^\d+$/)) {

                return $self->scriptObj->setError(
                    'invalid_integer',
                    $self->_objClass . '->implement',
                );

            } elsif ($timeout < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->implement',
                    'NUM', $timeout,
                );
            }
        }

        # Inform the parent task that it should start waiting
        $self->scriptObj->parentTask->setUpMonitoring(
            'status',
            'dead',
            undef,
            $timeout,
        );

        # Halt execution of the Axbasic script to allow control to be passed back to the parent task
        $self->scriptObj->set_scriptStatus('wait_status');

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::waitep;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::waitep::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WAITEP expression [ , expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($valueExp, $timeoutExp);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the value string into an expression
        $valueExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $valueExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Get the timeout, if specified, and convert it into an expression
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $timeoutExp = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $timeoutExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Check that nothing follows the expression(s)
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression(s), so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'value', $valueExp);
        $self->ivAdd('parseDataHash', 'timeout', $timeoutExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($valueExp, $value, $timeoutExp, $timeout);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Otherwise, retrieve the argument(s) stored by $self->parse
        $valueExp = $self->ivShow('parseDataHash', 'value');
        $timeoutExp = $self->ivShow('parseDataHash', 'timeout');

        # Evaluate the expression(s)
        $value = $valueExp->evaluate();
        if (! ($value =~  /^\d+$/) || $value < 0 || $value > 100) {

            # An illegitimate percentage, use the default value instead
            $value = 100;
        }

        if (defined $timeoutExp) {

            $timeout = $timeoutExp->evaluate();

            if (! ($timeout =~  /^\d+$/)) {

                return $self->scriptObj->setError(
                    'invalid_integer',
                    $self->_objClass . '->implement',
                );

            } elsif ($timeout < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->implement',
                    'NUM', $timeout,
                );
            }
        }

        # Inform the parent task that it should start waiting
        $self->scriptObj->parentTask->setUpMonitoring(
            'status',
            'ep',
            $value,
            $timeout,
        );

        # Halt execution of the Axbasic script to allow control to be passed back to the parent task
        $self->scriptObj->set_scriptStatus('wait_status');

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::waitgp;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::waitgp::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WAITGP expression [ , expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($valueExp, $timeoutExp);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the value string into an expression
        $valueExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $valueExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Get the timeout, if specified, and convert it into an expression
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $timeoutExp = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $timeoutExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Check that nothing follows the expression(s)
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression(s), so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'value', $valueExp);
        $self->ivAdd('parseDataHash', 'timeout', $timeoutExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($valueExp, $value, $timeoutExp, $timeout);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Otherwise, retrieve the argument(s) stored by $self->parse
        $valueExp = $self->ivShow('parseDataHash', 'value');
        $timeoutExp = $self->ivShow('parseDataHash', 'timeout');

        # Evaluate the expression(s)
        $value = $valueExp->evaluate();
        if (! ($value =~  /^\d+$/) || $value < 0 || $value > 100) {

            # An illegitimate percentage, use the default value instead
            $value = 100;
        }

        if (defined $timeoutExp) {

            $timeout = $timeoutExp->evaluate();

            if (! ($timeout =~  /^\d+$/)) {

                return $self->scriptObj->setError(
                    'invalid_integer',
                    $self->_objClass . '->implement',
                );

            } elsif ($timeout < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->implement',
                    'NUM', $timeout,
                );
            }
        }

        # Inform the parent task that it should start waiting
        $self->scriptObj->parentTask->setUpMonitoring(
            'status',
            'gp',
            $value,
            $timeout,
        );

        # Halt execution of the Axbasic script to allow control to be passed back to the parent task
        $self->scriptObj->set_scriptStatus('wait_status');

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::waithp;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::waithp::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WAITHP expression [ , expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($valueExp, $timeoutExp);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the value string into an expression
        $valueExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $valueExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Get the timeout, if specified, and convert it into an expression
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $timeoutExp = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $timeoutExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Check that nothing follows the expression(s)
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression(s), so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'value', $valueExp);
        $self->ivAdd('parseDataHash', 'timeout', $timeoutExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($valueExp, $value, $timeoutExp, $timeout);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Otherwise, retrieve the argument(s) stored by $self->parse
        $valueExp = $self->ivShow('parseDataHash', 'value');
        $timeoutExp = $self->ivShow('parseDataHash', 'timeout');

        # Evaluate the expression(s)
        $value = $valueExp->evaluate();
        if (! ($value =~  /^\d+$/) || $value < 0 || $value > 100) {

            # An illegitimate percentage, use the default value instead
            $value = 100;
        }

        if (defined $timeoutExp) {

            $timeout = $timeoutExp->evaluate();

            if (! ($timeout =~  /^\d+$/)) {

                return $self->scriptObj->setError(
                    'invalid_integer',
                    $self->_objClass . '->implement',
                );

            } elsif ($timeout < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->implement',
                    'NUM', $timeout,
                );
            }
        }

        # Inform the parent task that it should start waiting
        $self->scriptObj->parentTask->setUpMonitoring(
            'status',
            'hp',
            $value,
            $timeout,
        );

        # Halt execution of the Axbasic script to allow control to be passed back to the parent task
        $self->scriptObj->set_scriptStatus('wait_status');

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::waitmp;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::waitmp::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WAITMP expression [ , expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($valueExp, $timeoutExp);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the value string into an expression
        $valueExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $valueExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Get the timeout, if specified, and convert it into an expression
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $timeoutExp = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $timeoutExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Check that nothing follows the expression(s)
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression(s), so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'value', $valueExp);
        $self->ivAdd('parseDataHash', 'timeout', $timeoutExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($valueExp, $value, $timeoutExp, $timeout);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Otherwise, retrieve the argument(s) stored by $self->parse
        $valueExp = $self->ivShow('parseDataHash', 'value');
        $timeoutExp = $self->ivShow('parseDataHash', 'timeout');

        # Evaluate the expression(s)
        $value = $valueExp->evaluate();
        if (! ($value =~  /^\d+$/) || $value < 0 || $value > 100) {

            # An illegitimate percentage, use the default value instead
            $value = 100;
        }

        if (defined $timeoutExp) {

            $timeout = $timeoutExp->evaluate();

            if (! ($timeout =~  /^\d+$/)) {

                return $self->scriptObj->setError(
                    'invalid_integer',
                    $self->_objClass . '->implement',
                );

            } elsif ($timeout < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->implement',
                    'NUM', $timeout,
                );
            }
        }

        # Inform the parent task that it should start waiting
        $self->scriptObj->parentTask->setUpMonitoring(
            'status',
            'mp',
            $value,
            $timeout,
        );

        # Halt execution of the Axbasic script to allow control to be passed back to the parent task
        $self->scriptObj->set_scriptStatus('wait_status');

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::waitnextxp;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::waitnextxp::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WAITNEXTXP expression [ , expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($valueExp, $timeoutExp);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the value string into an expression
        $valueExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $valueExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Get the timeout, if specified, and convert it into an expression
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $timeoutExp = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $timeoutExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Check that nothing follows the expression(s)
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression(s), so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'value', $valueExp);
        $self->ivAdd('parseDataHash', 'timeout', $timeoutExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($valueExp, $value, $timeoutExp, $timeout);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Otherwise, retrieve the argument(s) stored by $self->parse
        $valueExp = $self->ivShow('parseDataHash', 'value');
        $timeoutExp = $self->ivShow('parseDataHash', 'timeout');

        # Evaluate the expression(s)
        $value = $valueExp->evaluate();
        if (! ($value =~  /^\d+$/)) {

            return $self->scriptObj->setError(
                'invalid_integer',
                $self->_objClass . '->parse',
            );
        }

        if (defined $timeoutExp) {

            $timeout = $timeoutExp->evaluate();

            if (! ($timeout =~  /^\d+$/)) {

                return $self->scriptObj->setError(
                    'invalid_integer',
                    $self->_objClass . '->implement',
                );

            } elsif ($timeout < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->implement',
                    'NUM', $timeout,
                );
            }
        }

        # Inform the parent task that it should start waiting
        $self->scriptObj->parentTask->setUpMonitoring(
            'status',
            'xp_next_level',
            $value,
            $timeout,
        );

        # Halt execution of the Axbasic script to allow control to be passed back to the parent task
        $self->scriptObj->set_scriptStatus('wait_status');

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::waitnotactive;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::waitnotactive::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WAITNOTACTIVE expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $taskNameExp;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the task string into an expression
        $taskNameExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $taskNameExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Check that nothing follows the expression(s)
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression, so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'task_name', $taskNameExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($taskNameExp, $taskName, $taskObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Otherwise, retrieve the argument stored by $self->parse
        $taskNameExp = $self->ivShow('parseDataHash', 'task_name');

        # Evaluate the expression(s)
        $taskName = $taskNameExp->evaluate();

        # Look for a task matching $taskName. GA::Generic::Cmd->findTask recognises task labels
        #   (stored in GA::Client->taskLabelHash), tasks' formal names (stored in
        #   GA::Client->taskPackageHash), or task unique names in the current tasklist (stored in
        #   GA::Session->currentTaskHash)
        ($taskObj) = Games::Axmud::Generic::Cmd->findTask($self->scriptObj->session, $taskName);
        if (! $taskObj) {

            # No matching task in the current tasklist
            return $self->scriptObj->setError(
                'WAITACTIVE_operation_failure',
                $self->_objClass . '->parse',
            );
        }

        # Inform the LA::Script's parent task that it should start waiting
        $self->scriptObj->parentTask->setUpMonitoring('task_not_active', $taskObj->uniqueName);

        # Halt execution of the Axbasic script to allow control to be passed back to the parent task
        $self->scriptObj->set_scriptStatus('wait_not_active');

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::waitpassout;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::waitpassout::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WAITPASSOUT [ expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $timeoutExp;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the timeout, if specified, and convert it into an expression
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $timeoutExp = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $timeoutExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Check that nothing follows the expression(s)
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression (if specified), so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'timeout', $timeoutExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($timeoutExp, $timeout);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Otherwise, retrieve the argument (if any) stored by $self->parse
        $timeoutExp = $self->ivShow('parseDataHash', 'timeout');

        # Evaluate the expression, if specified
        if (defined $timeoutExp) {

            $timeout = $timeoutExp->evaluate();

            if (! ($timeout =~  /^\d+$/)) {

                return $self->scriptObj->setError(
                    'invalid_integer',
                    $self->_objClass . '->implement',
                );

            } elsif ($timeout < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->implement',
                    'NUM', $timeout,
                );
            }
        }

        # Inform the parent task that it should start waiting
        $self->scriptObj->parentTask->setUpMonitoring(
            'status',
            'passout',
            undef,
            $timeout,
        );

        # Halt execution of the Axbasic script to allow control to be passed back to the parent task
        $self->scriptObj->set_scriptStatus('wait_status');

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::waitscript;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::waitscript::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WAITSCRIPT expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $scriptNameExp;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the task string into an expression
        $scriptNameExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $scriptNameExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression ',
                $self->_objClass . '->parse',
            );
        }

        # Check that nothing follows the expression(s)
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression, so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'script_exp', $scriptNameExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($scriptNameExp, $scriptName, $packageName, $taskObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If this Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Otherwise, retrieve the argument stored by $self->parse
        $scriptNameExp = $self->ivShow('parseDataHash', 'script_exp');
        # Evaluate the expression(s)
        $scriptName = $scriptNameExp->evaluate();

        # Create the new Script task object
        $taskObj = Games::Axmud::Task::Script->new($self->scriptObj->session, 'current');
        if (!  $taskObj) {

            # If the new task can't be created, it's a fatal error
            return $self->scriptObj->setError(
                'WAITSCRIPT_operation_failure',
                $self->_objClass . '->parse',
            );
        }

        # Tell the new task which Axbasic script to run
        $taskObj->ivPoke('scriptName', $scriptName);

        # Inform the LA::Script's parent task that it should start waiting
        $self->scriptObj->parentTask->setUpMonitoring('task', $taskObj->uniqueName);

        # Halt execution of the Axbasic script to allow control to be passed back to the parent task
        $self->scriptObj->set_scriptStatus('wait_status');

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::waitsleep;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::waitsleep::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WAITSLEEP [ expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $timeoutExp;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the timeout, if specified, and convert it into an expression
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $timeoutExp = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $timeoutExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Check that nothing follows the expression(s)
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression (if specified), so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'timeout', $timeoutExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($timeoutExp, $timeout);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Otherwise, retrieve the argument (if any) stored by $self->parse
        $timeoutExp = $self->ivShow('parseDataHash', 'timeout');

        # Evaluate the expression, if specified
        if (defined $timeoutExp) {

            $timeout = $timeoutExp->evaluate();

            if (! ($timeout =~  /^\d+$/)) {

                return $self->scriptObj->setError(
                    'invalid_integer',
                    $self->_objClass . '->implement',
                );

            } elsif ($timeout < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->implement',
                    'NUM', $timeout,
                );
            }
        }

        # Inform the parent task that it should start waiting
        $self->scriptObj->parentTask->setUpMonitoring(
            'status',
            'sleep',
            undef,
            $timeout,
        );

        # Halt execution of the Axbasic script to allow control to be passed back to the parent task
        $self->scriptObj->set_scriptStatus('wait_status');

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::waitsp;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::waitsp::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WAITSP expression [ , expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($valueExp, $timeoutExp);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the value string into an expression
        $valueExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $valueExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Get the timeout, if specified, and convert it into an expression
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $timeoutExp = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $timeoutExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Check that nothing follows the expression(s)
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression(s), so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'value', $valueExp);
        $self->ivAdd('parseDataHash', 'timeout', $timeoutExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($valueExp, $value, $timeoutExp, $timeout);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Otherwise, retrieve the argument(s) stored by $self->parse
        $valueExp = $self->ivShow('parseDataHash', 'value');
        $timeoutExp = $self->ivShow('parseDataHash', 'timeout');

        # Evaluate the expression(s)
        $value = $valueExp->evaluate();
        if (! ($value =~  /^\d+$/) || $value < 0 || $value > 100) {

            # An illegitimate percentage, use the default value instead
            $value = 100;
        }

        if (defined $timeoutExp) {

            $timeout = $timeoutExp->evaluate();

            if (! ($timeout =~  /^\d+$/)) {

                return $self->scriptObj->setError(
                    'invalid_integer',
                    $self->_objClass . '->implement',
                );

            } elsif ($timeout < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->implement',
                    'NUM', $timeout,
                );
            }
        }

        # Inform the parent task that it should start waiting
        $self->scriptObj->parentTask->setUpMonitoring(
            'status',
            'sp',
            $value,
            $timeout,
        );

        # Halt execution of the Axbasic script to allow control to be passed back to the parent task
        $self->scriptObj->set_scriptStatus('wait_status');

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::waittask;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::waittask::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WAITTASK expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $taskNameExp;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the task string into an expression
        $taskNameExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $taskNameExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Check that nothing follows the expression(s)
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression, so $self->implement can retrieve it
        $self->ivAdd('parseDataHash', 'task_name', $taskNameExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($taskNameExp, $taskName, $packageName, $taskObj, $result);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Otherwise, retrieve the argument stored by $self->parse
        $taskNameExp = $self->ivShow('parseDataHash', 'task_name');

        # Evaluate the expression(s)
        $taskName = $taskNameExp->evaluate();

        # The rest of this code is adapted from GA::Cmd::StartTask
        # GA::Generic::Cmd->findTaskPackageName recognises unique names of currently running tasks
        #   (e.g. 'status_task_57'), so before we consult it, check that a task called $taskName
        #   isn't already running
        if ($self->scriptObj->session->ivExists('currentTaskHash', $taskName)) {

            return $self->scriptObj->setError(
                'WAITTASK_operation_failure',
                $self->_objClass . '->parse',
            );
        }

        # Get the package name corresponding to $taskName (e.g. 'Games::Axmud::Task::Status',
        #   'Games::Axmud::Task::Divert')
        $packageName
            = Games::Axmud::Generic::Cmd->findTaskPackageName($self->scriptObj->session, $taskName);

        if (! defined $packageName) {

            return $self->scriptObj->setError(
                'WAITTASK_operation_failure',
                $self->_objClass . '->parse',
            );
        }

        # Create the new task object
        $taskObj = $packageName->new($self->scriptObj->session, 'current');
        if (! $taskObj) {

            # If the new task can't be created and set up properly, it's a fatal error
            return $self->scriptObj->setError(
                'WAITTASK_operation_failure',
                $self->_objClass . '->parse',
                'STRING', $taskName,
            );
        }

        # Inform the LA::Script's parent task that it should start waiting
        $self->scriptObj->parentTask->setUpMonitoring('task', $taskObj->uniqueName);

        # Halt execution of the Axbasic script to allow control to be passed back to the parent task
        $self->scriptObj->set_scriptStatus('wait_status');

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::waittotalxp;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::waittotalxp::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WAITTOTALXP expression [ , expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($valueExp, $timeoutExp);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the value string into an expression
        $valueExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $valueExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Get the timeout, if specified, and convert it into an expression
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $timeoutExp = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $timeoutExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Check that nothing follows the expression(s)
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression(s), so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'value', $valueExp);
        $self->ivAdd('parseDataHash', 'timeout', $timeoutExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($valueExp, $value, $timeoutExp, $timeout);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Otherwise, retrieve the argument(s) stored by $self->parse
        $valueExp = $self->ivShow('parseDataHash', 'value');
        $timeoutExp = $self->ivShow('parseDataHash', 'timeout');

        # Evaluate the expression(s)
        $value = $valueExp->evaluate();
        if (! ($value =~  /^\d+$/)) {

            return $self->scriptObj->setError(
                'invalid_integer',
                $self->_objClass . '->parse',
            );
        }

        if (defined $timeoutExp) {

            $timeout = $timeoutExp->evaluate();

            if (! ($timeout =~  /^\d+$/)) {

                return $self->scriptObj->setError(
                    'invalid_integer',
                    $self->_objClass . '->implement',
                );

            } elsif ($timeout < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->implement',
                    'NUM', $timeout,
                );
            }
        }

        # Inform the parent task that it should start waiting
        $self->scriptObj->parentTask->setUpMonitoring(
            'status',
            'xp_total',
            $value,
            $timeout,
        );

        # Halt execution of the Axbasic script to allow control to be passed back to the parent task
        $self->scriptObj->set_scriptStatus('wait_status');

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::waittrig;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::waittrig::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WAITTRIG expression [ , expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($stimulusExp, $timeoutExp);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the pattern string into an expression
        $stimulusExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $stimulusExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Get the timeout, if specified, and convert it into an expression
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $timeoutExp = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $timeoutExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Check that nothing follows the expression(s)
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression(s), so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'pattern', $stimulusExp);
        $self->ivAdd('parseDataHash', 'timeout', $timeoutExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($stimulusExp, $stimulus, $timeoutExp, $timeout, $interfaceObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Otherwise, retrieve the argument(s) stored by $self->parse
        $stimulusExp = $self->ivShow('parseDataHash', 'pattern');
        $timeoutExp = $self->ivShow('parseDataHash', 'timeout');

        # Evaluate the expression(s)
        $stimulus = $stimulusExp->evaluate();

        if (defined $timeoutExp) {

            $timeout = $timeoutExp->evaluate();

            if (! ($timeout =~  /^\d+$/)) {

                return $self->scriptObj->setError(
                    'invalid_integer',
                    $self->_objClass . '->implement',
                );

            } elsif ($timeout < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->implement',
                    'NUM', $timeout,
                );
            }
        }

        # Create the trigger, which will call a function in this script's parent task when it fires
        $interfaceObj = $self->scriptObj->session->createInterface(
            'trigger',
            $stimulus,
            $self->scriptObj->parentTask,
            'waitPatternSeen',
            'temporary',
            1,
        );

        if (defined $interfaceObj) {

            # Add this trigger to the list of interfaces created during the execution of the Axbasic
            #   script
            $self->scriptObj->push_depInterfaceList($interfaceObj->name);
            $self->scriptObj->set_depInterfaceName($interfaceObj->name);

            # Mark this script as paused
            $self->scriptObj->set_scriptStatus('paused');
            # Tell the task that it's waiting for a trigger, so that the interface can be deleted,
            #   the first time the trigger fires...
            $self->scriptObj->parentTask->ivPoke('waitForInterface', $interfaceObj->name);
            # ...and then mark the task as paused
            $self->scriptObj->parentTask->pauseUntil(
                ($self->scriptObj->session->sessionTime + $timeout),
            );

        } else {

            # Store the fact that creation of the interface failed
            $self->scriptObj->set_depInterfaceName(undef);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::waitxp;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::waitxp::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WAITXP expression [ , expression ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($valueExp, $timeoutExp);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Convert the value string into an expression
        $valueExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $valueExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Get the timeout, if specified, and convert it into an expression
        if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

            $timeoutExp = Language::Axbasic::Expression::Arithmetic->new(
                $self->scriptObj,
                $self->tokenGroupObj,
            );

            if (! defined $timeoutExp) {

                return $self->scriptObj->setError(
                    'missing_or_illegal_expression',
                    $self->_objClass . '->parse',
                );
            }
        }

        # Check that nothing follows the expression(s)
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expression(s), so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'value', $valueExp);
        $self->ivAdd('parseDataHash', 'timeout', $timeoutExp);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($valueExp, $value, $timeoutExp, $timeout);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # If the Axbasic script isn't being run from within an Axmud task, ignore the statement
        if (! $self->scriptObj->parentTask) {

            # Implementation complete. Execution resumes from the next statement
            return 1;
        }

        # Otherwise, retrieve the argument(s) stored by $self->parse
        $valueExp = $self->ivShow('parseDataHash', 'value');
        $timeoutExp = $self->ivShow('parseDataHash', 'timeout');

        # Evaluate the expression(s)
        $value = $valueExp->evaluate();
        if (! ($value =~  /^\d+$/)) {

            return $self->scriptObj->setError(
                'invalid_integer',
                $self->_objClass . '->parse',
            );
        }

        if (defined $timeoutExp) {

            $timeout = $timeoutExp->evaluate();

            if (! ($timeout =~  /^\d+$/)) {

                return $self->scriptObj->setError(
                    'invalid_integer',
                    $self->_objClass . '->implement',
                );

            } elsif ($timeout < 1) {

                return $self->scriptObj->setError(
                    'number_NUM_out_of_range',
                    $self->_objClass . '->implement',
                    'NUM', $timeout,
                );
            }
        }

        # Inform the parent task that it should start waiting
        $self->scriptObj->parentTask->setUpMonitoring(
            'status',
            'xp_current',
            $value,
            $timeout,
        );

        # Halt execution of the Axbasic script to allow control to be passed back to the parent task
        $self->scriptObj->set_scriptStatus('wait_status');

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::warning;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::warning::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WARNING expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the expression and store it for ->implement to use
        $expression = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );

        } else {

            $self->ivAdd('parseDataHash', 'expression', $expression);
        }

        # There should be nothing after the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression, $string);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the expression to be written
        $expression = $self->ivShow('parseDataHash', 'expression');
        # Evaluate the expression to get a scalar value
        $string = $expression->evaluate();

        # If the last PRINT statement was followed by a semicolon, we need to reset the column so
        #   the error message appears on a new line
        if ($self->scriptObj->column != 0) {

            $self->scriptObj->session->writeText('', 'after');
            $self->scriptObj->set_column(0);
        }

        # Write the error message to the 'main' window
        $self->scriptObj->session->writeWarning($string);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::while;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::while::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WHILE condition

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($condition, $subObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # The 'while' keyword is not available in primitive numbering mode
        if ($self->scriptObj->executionMode ne 'no_line_num') {

            return $self->scriptObj->setError(
                'statement_not_available_with_line_numbers',
                $self->_objClass . '->parse',
            );
        }

        # Read a conditional expression
        $condition = Language::Axbasic::Expression::LogicalOr->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $condition) {

            return $self->scriptObj->setError(
                'missing_or_illegal_conditional_expression',
                $self->_objClass . '->parse',
            );

        } else {

            # Store the condition expression, so $self->implement can retrieve it
            $self->ivAdd('parseDataHash', 'condition', $condition);
        }

        # Check there's nothing else in the statement after the condition expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Add this WHILE statement to the WHILE code block stack for the current subroutine
        $subObj = $self->scriptObj->returnCurrentSub();
        $subObj->push_whileStackList($self);

        # We don't know what the corresponding LOOP statement is, yet
        $self->ivAdd('parseDataHash', 'loop_statement', undef);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse when the
        #   first token in the statement is the keyword 'while'
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($condition, $loopStatement, $subObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the condition expression stored by $self->parse
        $condition = $self->ivShow('parseDataHash', 'condition');

        # Check the corresponding 'loop' statement from the current subroutine's WHILE code block
        #   stack.
        if (! $self->ivShow('parseDataHash', 'loop_statement')) {

            return $self->scriptObj->setError(
                'WHILE_statement_without_matching_LOOP',
                $self->_objClass . '->implement',
            );
        }

        # Evaluate the condition expression
        if (! $condition->evaluate()) {

            # The condition expression is false, so we need to skip to the end of the WHILE..LOOP
            #   code block
            $loopStatement = $self->ivShow('parseDataHash', 'loop_statement');

            if (defined $loopStatement->nextStatement) {

                $self->scriptObj->set_nextStatement($loopStatement->nextStatement);

            } else {

                # The LOOP statement was the last (or only) statement on the line: use the next line
                $self->scriptObj->set_nextLine($loopStatement->lineObj->procLineNum + 1),
            }

        } else {

            # Add this WHILE code block to the main code block stack, since we're going to execute
            #   it now. The corresponding UNTIL statement will remove it.
            # NB The main ->blockStackList is used during ->implement for all kinds of code blocks;
            #   ->whileStackList is used during ->parse for WHILE..LOOP blocks only
            $subObj = $self->scriptObj->returnCurrentSub();
            $subObj->push_blockStackList($self);
        }

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::write;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::write::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WRITE expression

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $expression;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the expression and store it for ->implement to use
        $expression = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $expression) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );

        } else {

            $self->ivAdd('parseDataHash', 'expression', $expression);
        }

        # There should be nothing after the expression
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($expression, $string);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the expression to be written
        $expression = $self->ivShow('parseDataHash', 'expression');
        # Evaluate the expression to get a scalar value
        $string = $expression->evaluate();

        # If the last PRINT statement was followed by a semicolon, we need to reset the column so
        #   the message appears on a new line
        if ($self->scriptObj->column != 0) {

            $self->scriptObj->session->writeText('', 'after');
            $self->scriptObj->set_column(0);
        }

        # Write the message to the 'main' window
        $self->scriptObj->session->writeText('AXBASIC: ' . $string);

        # Implementation complete
        return 1;
    }
}

{ package Language::Axbasic::Statement::writewin;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Statement::writewin::ISA = qw(
        Language::Axbasic
        Language::Axbasic::Statement
    );

    # WRITEWIN expression [ , expression [ , expression ... ] ]

    ##################
    # Methods

    sub parse {

        # Called by LA::Line->parse directly after a call to LA::Statement->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $textExp, $exitFlag,
            @otherExpList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Get the text expression
        $textExp = Language::Axbasic::Expression::Arithmetic->new(
            $self->scriptObj,
            $self->tokenGroupObj,
        );

        if (! defined $textExp) {

            return $self->scriptObj->setError(
                'missing_or_illegal_expression',
                $self->_objClass . '->parse',
            );
        }

        # Get the optional expressions
        do {
            my ($token, $otherExp);

            if (defined $self->tokenGroupObj->shiftMatchingToken(',')) {

                $token = $self->tokenGroupObj->lookAhead();
                if (defined $token) {

                    $otherExp = Language::Axbasic::Expression::Arithmetic->new(
                        $self->scriptObj,
                        $self->tokenGroupObj,
                    );

                    if (! defined $otherExp) {

                        return $self->scriptObj->setError(
                            'missing_or_illegal_expression',
                            $self->_objClass . '->parse',
                        );

                    } else {

                        push (@otherExpList, $otherExp);
                    }
                }

            } else {

                $exitFlag = TRUE;
            }

        } until ($exitFlag);

        # Check that nothing follows the expressions
        if (! $self->tokenGroupObj->testStatementEnd()) {

            return $self->scriptObj->setError(
                'unexpected_keywords,_operators_or_expressions',
                $self->_objClass . '->parse',
            );
        }

        # Store the expressions, so $self->implement can retrieve them
        $self->ivAdd('parseDataHash', 'text_exp', $textExp);
        $self->ivPoke('parseDataList', @otherExpList);

        # Parsing complete
        return 1;
    }

    sub implement {

        # Called by LA::Line->implement directly after a call to $self->parse
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there is an error
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $textExp, $text,
            @otherExpList, @otherList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
        }

        # Retrieve the arguments stored by $self->parse
        $textExp = $self->ivShow('parseDataHash', 'text_exp');
        @otherExpList = $self->parseDataList;

        # Evaluate each expression
        $text = $textExp->evaluate();
        foreach my $exp (@otherExpList) {

            push (@otherList, $exp->evaluate());
        }

        # If the Axbasic script is being run from within an Axmud task and the task window is open,
        #   write to it. If run from within the task, the task window is closed but we're allowed to
        #   write to the 'main' window, write to the 'main' window. Otherwise, do nothing
        if ($self->scriptObj->parentTask) {

            if ($self->scriptObj->parentTask->taskWinFlag) {

                # Write to the task window
                $self->scriptObj->parentTask->insertPrint($text, @otherList);

            } elsif ($self->scriptObj->ivShow('optionStatementHash', 'divert')) {

                # Write to the 'main' window; ignore the contents of @otherList
                $self->scriptObj->session->writeText($text);
            }
        }

        # Implementation complete
        return 1;
    }
}

# Package must return true
1
