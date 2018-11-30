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
# Games::Axmud
# All Perl objects used in Axmud should inherit this generic object, which serves as a base class
#   for all Axmud objects and provides convenience functions for accessing scalar/array/hash
#   instance variables (IVs) and for writing system messages
#
# Some Perl objects treat all of their IVs as 'public' - any of the methods inherited from this
#   (base class) object can be called by other objects, in order to set IVs
# Other Perl objects treat all of their IVs as 'private' - other objects must call one of the
#   specially-written accessor methods, in order to set its IVs
# All Perl objects have five special constant IVs: _objName, ->_objClass, _parentFile, _parentWorld
#   and _privFlag. If _privFlag is set to TRUE, then an object's IVs are private. If set to FALSE,
#   the object's IVs are public
#
# Some of the methods inherited from this object store value(s) in an IV, and some of them retrieve
#   value(s) from an IV. Methods that retrieve values can be used all the time; methods that store
#   values should only be used when an object's IVs are public, or when the object is modifying its
#   own values
#
# Except in vary rare circumstances, you should not set an IV with a line of code like
#   $obj->{some_iv} = $value
# ...because the code inherited from this object tells Axmud when its data has been modified, and
#   needs to be saved
#
# The functions marked with an * are those which modify the value(s) of an instance variable (and so
#   these are the ones which cause a file object's ->modifyFlag to be set to 1)
#
#   ->checkModify($instVar)     - Checks whether modifying an instance variable is allowed
#
# Functions for scalar IVs:
#
#   ->ivSet($instVar, $value)   * Set a scalar instance variable (IV)
#   ->ivUndef($instVar)         * Sets a scalar instance variable (IV) to 'undef'
#   ->ivTrue($instVar)          * Sets a scalar instance variable (IV) to TRUE
#   ->ivFalse($instVar)         * Sets a scalar instance variable (IV) to FALSE
#   ->ivGet($instVar)           - Get a scalar IV
#   ->ivIncrement($instVar)     * Incremements a scalar IV (i.e. $instVar++)
#   ->ivDecrement($instVar)     * Decrements a scalar IV (i.e. $instVar--)
#   ->ivPlus($instVar, $value)  * Performs addition on scalar IV (i.e. $instVar + $value)
#   ->ivMinus($instVar, $value) * Performs subtraction on scalar IV (i.e. $instVar - $value)
#   ->ivMultiply($instVar, $value)
#                               * Performs multiplication on scalar IV (i.e. $instVar * $value)
#   ->ivDivide($instVar, $value)
#                               * Performs division on scalar IV (i.e. $instVar / $value)
#   ->ivInt($instVar)           * Remove the fractional part of an instance variable (IV)
#
# Functions for array IVs:
#
#   ->ivPush($instVar, @list)   * Push to an array IV
#   ->ivPop($instVar)           * Pop from an array IV
#   ->ivUnshift($instVar, @list)
#                               * Unshift to an array IV
#   ->ivShift($instVar)         * Shift from an array IV
#   ->ivNumber($instVar)        - Number of elements in an array IV
#   ->ivSplice($instVar, $offset, [$length, [@list]])
#                               * Splice an array IV
#   ->ivIndex($instVar, $index) - Returns the element at the index in an array IV
#   ->ivFirst($instVar)         - Returns the element at index 0 in an array IV
#   ->ivLast($instVar)          - Returns the Last index (not the element) in an array IV
#   ->ivReplace($instVar, $index, [$scalar])
#                               * Replaces the element at the index in an array IV
#   ->ivFind($instVar, $scalar) - Finds the element in an array IV matching $scalar (string)
#   ->ivMatch(instVar, $regEx, [$global, [$ignore]])
#                               - Finds the element in an array IV matching a Perl regex
#   ->ivEquals($instVar, $number)
#                               - Finds the element in an array IV which equals $number
#
# Functions for hash IVs:
#
#   ->ivAdd($instVar, $key, $value)
#                               * Adds a key-value pair to a hash IV
#   ->ivIncHash($instVar, $key) * Increments the value of the key in a hash IV
#   ->ivDecHash($instVar, $key) * Decrements the value of the key in a hash IV
#   ->ivShow($instVar, $key)    - Retrieves the value matching $key in a hash IV
#   ->ivDelete($instVar, $key)  * Deletes a key in a hash IV
#   ->ivExists($instVar, $key)  - Show if key exists in a hash IV
#   ->ivKeys($instVar)          - Gets list of all keys in a hash IV
#   ->ivValues($instVar)        - Gets list of all values in a hash IV
#   ->ivPairs($instVar)         - Returns number of key-value pairs in the hash IV
#
# Functions for scalar, array and hash IVs:
#
#   ->ivList()                  - Retrieves list of all instance variables
#   ->ivEmpty($instVar)         * Empties an array or hash IV, sets a scalar IV to undef'
#   ->ivType($instVar)          - Returns the type of IV - 'scalar', 'list' or 'hash'
#   ->ivPeek($instVar)          - Returns the contents of an IV scalar, array or hash AS A LIST
#   ->ivPoke($instVar, @list)   * Sets the value of an IV scalar (identical to ->ivSet) to the first
#                                   value in @list
#                               * Sets the contents of an IV list to @list, deleting any values
#                                   already stored in the IV
#                               * Sets the contents of an IV hash to @list, deleting any key-value
#                                   pairs already stored in the IV
#   ->ivMember($instVar)        - See if the IV exists in the object, or not
#   ->ivCreate($instVar, $type) - Creates a new IV of $type 'scalar', 'list' or 'hash'
#   ->ivDestroy($instVar)       - Destroys an existing IV
#
# Other functions:
#
#   ->writeText($text, @args)   - Writes text to the a session's default textview object
#   ->writeError($text, $func)  - Writes an error message to a session's default textview object
#   ->writeWarning($text, $func)
#                               - Writes a warning message to a session's default textview object
#   ->writeDebug($text, $func)  - Writes a debug message to a session's default textview object
#   ->wd($text, $func)          - Writes a debug message to a session's default textview object
#   ->writeImproper($func, @args)
#                               - Writes an 'improper arguments' message to a session's default
#                                   textview object
#   ->debugBreak($title, $msg)  - Show a 'dialogue' window, which pauses the script until the
#                                   window is closed
#   ->showList($lineNum, @list) - Debugging function, displays a list
#   ->showHash($lineNum, %hash) - Debugging function, displays a hash
#   ->getMethodRef($funcName)   - Gets a reference to a function that's an OOP method

{ package Games::Axmud;

    use strict;
    use warnings;
    use diagnostics;

    # (This variable exists for the benefit of Kwalitee, and is never referenced by the code)
    our $VERSION = '1.1.343';

    use Glib qw(TRUE FALSE);

#   our @ISA = qw();

    use Games::Axmud::Buffer;
    use Games::Axmud::Cage;
    use Games::Axmud::Client;
    use Games::Axmud::Cmd;
    use Games::Axmud::EditWin;
    use Games::Axmud::FixedWin;
    use Games::Axmud::Generic;
    use Games::Axmud::Interface;
    use Games::Axmud::InterfaceModel;
    use Games::Axmud::Mcp;
    use Games::Axmud::ModelObj;
    use Games::Axmud::Mxp;
    use Games::Axmud::Node;
    use Games::Axmud::OtherWin;
    use Games::Axmud::PrefWin;
    use Games::Axmud::Profile;
    use Games::Axmud::Pueblo;
    use Games::Axmud::Session;
    use Games::Axmud::Strip;
    use Games::Axmud::Table;
    use Games::Axmud::Task;
    use Games::Axmud::Widget;
    use Games::Axmud::WizWin;

    use Games::Axmud::Obj::Area;
    use Games::Axmud::Obj::Atcp;
    use Games::Axmud::Obj::BasicWorld;
    use Games::Axmud::Obj::Heap;
    use Games::Axmud::Obj::Blinker;
    use Games::Axmud::Obj::ChatContact;
    use Games::Axmud::Obj::ColourScheme;
    use Games::Axmud::Obj::Component;
    use Games::Axmud::Obj::ConnectHistory;
    use Games::Axmud::Obj::Desktop;
    use Games::Axmud::Obj::Dict;
    use Games::Axmud::Obj::DrawingArea;
    use Games::Axmud::Obj::Exit;
    use Games::Axmud::Obj::File;
    use Games::Axmud::Obj::Gauge;
    use Games::Axmud::Obj::GaugeLevel;
    use Games::Axmud::Obj::Gmcp;
    use Games::Axmud::Obj::GridColour;
    use Games::Axmud::Obj::Link;
    use Games::Axmud::Obj::Loop;
    use Games::Axmud::Obj::Map;
    use Games::Axmud::Obj::MapLabel;
    use Games::Axmud::Obj::MiniWorld;
    use Games::Axmud::Obj::Mission;
    use Games::Axmud::Obj::Monitor;
    use Games::Axmud::Obj::Phrasebook;
    use Games::Axmud::Obj::Plugin;
    use Games::Axmud::Obj::Protect;
    use Games::Axmud::Obj::Quest;
    use Games::Axmud::Obj::Regionmap;
    use Games::Axmud::Obj::RegionPath;
    use Games::Axmud::Obj::Repeat;
    use Games::Axmud::Obj::RoomFlag;
    use Games::Axmud::Obj::Route;
    use Games::Axmud::Obj::Simple;
    use Games::Axmud::Obj::SkillHistory;
    use Games::Axmud::Obj::Sound;
    use Games::Axmud::Obj::Tab;
    use Games::Axmud::Obj::Tablezone;
    use Games::Axmud::Obj::Telnet;
    use Games::Axmud::Obj::TextView;
    use Games::Axmud::Obj::Toolbar;
    use Games::Axmud::Obj::Tts;
    use Games::Axmud::Obj::Winmap;
    use Games::Axmud::Obj::Winzone;
    use Games::Axmud::Obj::Workspace;
    use Games::Axmud::Obj::WorkspaceGrid;
    use Games::Axmud::Obj::WorldModel;
    use Games::Axmud::Obj::Zmp;
    use Games::Axmud::Obj::Zone;
    use Games::Axmud::Obj::Zonemap;
    use Games::Axmud::Obj::ZoneModel;

    use Games::Axmud::Win::External;
    use Games::Axmud::Win::Internal;
    use Games::Axmud::Win::Map;

    ##################
    # Constructors

    # (All inheriting objects must provide their own ->new function)

    ##################
    # Methods

    # General methods

    sub checkModify {

        # Can be called by any of the ->ivXXX methods in this object which modify the value(s)
        #   stored in the object's IVs
        # Given the instance variable to be modified, checks whether modifying this variable is
        #   allowed. (It's up to the Axmud code to refrain from modifying IVs in other Perl objects,
        #   when those objects have their ->_privFlag set to TRUE)
        #
        # Expected arguments
        #   $iv   - The instance variable to be modified
        #
        # Return values
        #   'undef' on improper arguments, or if modifying the IV is not allowed
        #   1 on success

        my ($self, $iv, $check) = @_;

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkModify', @_);
        }

        # Check whether modifying this instance variable is allowed

        if ($axmud::CLIENT->ivExists('constIVHash', $iv)) {

            # This is a constant instance variable (i.e. '_objName', '_objClass', '_parentFile',
            #   '_parentWorld',  or '_privFlag') required by the system
            return $axmud::CLIENT->writeError(
                '\'' . $iv . '\' is a system constant IV which must not be modified',
                $self->_objClass . '->checkModify',
            );

        } elsif (substr ($iv, 0, 5) eq 'const') {

            # This is a constant Axmud instance variable. ->iv functions can't be used to modify it
            return $axmud::CLIENT->writeError(
                '\'' . $iv . '\' is a constant IV which cannot be modified',
                $self->_objClass . '->checkModify',
            );

        } else {

            # Modification of this IV is allowed
            return 1;
        }
    }

    sub doModify {

        # Can be called by any of the ->ivXXX methods in this object after a call to
        #   $self->checkModify
        # If there is a parent file object stored in $self->_parentFile, sets its ->modifyFlag to
        #   TRUE
        #
        # Expected arguments
        #   $func   - The calling function (e.g. 'ivPoke')
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $func, $check) = @_;

        # Check for improper arguments
        if (! defined $func || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->doModify', @_);
        }

        # Set the parent file's 'data modified' flag
        if (defined $self->_parentFile) {

            # (For some task objects, $self->session is defined, for others, it is not)
            if (exists $self->{session} && defined $self->{session}) {

                # The parent file object is stored either in GA::Client or in this GA::Session.
                #   Call the GA::Session; if it doesn't store the file object, it passes on the call
                #   to the GA::Client
                $self->session->setModifyFlag(
                    $self->_parentFile,
                    TRUE,
                    $self->_objClass . '->' . $func,
                );

            } elsif (defined $self->_parentWorld) {

                # The parent file object is not stored in GA::Client, but in a GA::Session, but we
                #   don't know which session (because there is no ->session IV)
                # Check each session in turn, looking for the right file object. As soon as it is
                #   found, set the flag
                OUTER: foreach my $session ($axmud::CLIENT->listSessions()) {

                    if (
                        $session->currentWorld
                        && $session->currentWorld->name eq $self->_parentWorld
                    ) {
                        # This is the right sesion
                        $session->setModifyFlag(
                            $self->_parentFile,
                            TRUE,
                            $self->_objClass . '->' . $func,
                        );

                        last OUTER;
                    }
                }

            } else {

                # Most file objects are stored in the GA::Client
                $axmud::CLIENT->setModifyFlag(
                    $self->_parentFile,
                    TRUE,
                    $self->_objClass . '->' . $func,
                );
            }
        }

        return 1;
    }

    # IV methods

    sub ivSet {

        # Set variable function for scalar instance variables
        #
        # Expected arguments
        #   $iv     - Which scalar instance variable to modify
        #   $value  - What the instance variable is set to
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a scalar, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->regConst) or
        #       or if it begins with _, meaning modification not allowed using this function
        #   1 on success

        my ($self, $iv, $value, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || ! defined $value || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivSet', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivSet'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        # According to Axmud's coding conventions, if ref() doesn't return 'ARRAY' or 'HASH', it's
        #   a scalar instance variable; so treat it as a scalar
        $refType = ref $self->{$iv};
        if ($refType ne 'ARRAY' && $refType ne 'HASH') {

            # This is a scalar. Set the parent file object's 'data modified' flag
            $self->doModify('ivSet');

            # Set the scalar
            $self->{$iv} = $value;

            return 1;

        } else {

            # Not a scalar
            return undef;
        }
    }

    sub ivUndef {

        # Set variable to 'undef' function for scalar instance variables
        #
        # Expected arguments
        #   $iv   - Which scalar instance variable to modify
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a scalar, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   1 on success

        my ($self, $iv, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivUndef', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivUndef'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        # According to Axmud's coding conventions, if ref() doesn't return 'ARRAY' or 'HASH', it's
        #   a scalar instance variable; so treat it as a scalar
        $refType = ref $self->{$iv};
        if ($refType ne 'ARRAY' && $refType ne 'HASH') {

            # This is a scalar. Set the parent file object's 'data modified' flag
            $self->doModify('ivUndef');

            # Set the scalar
            $self->{$iv} = undef;

            return 1;

        } else {

            # Not a scalar
            return undef;
        }
    }

    sub ivTrue {

        # Set variable to TRUE function for scalar instance variables
        #
        # Expected arguments
        #   $iv   - Which scalar instance variable to modify
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a scalar, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   1 on success

        my ($self, $iv, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivTrue', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivTrue'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        # According to Axmud's coding conventions, if ref() doesn't return 'ARRAY' or 'HASH', it's
        #   a scalar instance variable; so treat it as a scalar
        $refType = ref $self->{$iv};
        if ($refType ne 'ARRAY' && $refType ne 'HASH') {

            # This is a scalar. Set the parent file object's 'data modified' flag
            $self->doModify('ivTrue');

            # Set the scalar
            $self->{$iv} = TRUE;

            return 1;

        } else {

            # Not a scalar
            return undef;
        }
    }

    sub ivFalse {

        # Set variable to FALSE function for scalar instance variables
        #
        # Expected arguments
        #   $iv   - Which scalar instance variable to modify
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a scalar, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   1 on success

        my ($self, $iv, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivFalse', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivFalse'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        # According to Axmud's coding conventions, if ref() doesn't return 'ARRAY' or 'HASH', it's
        #   a scalar instance variable; so treat it as a scalar
        $refType = ref $self->{$iv};
        if ($refType ne 'ARRAY' && $refType ne 'HASH') {

            # This is a scalar. Set the parent file object's 'data modified' flag
            $self->doModify('ivFalse');

            # Set the scalar
            $self->{$iv} = FALSE;

            return 1;

        } else {

            # Not a scalar
            return undef;
        }
    }

    sub ivGet {

        # Retrieve variable function for scalar instance variables
        #
        # Expected arguments
        #   $iv   - Which scalar instance variable to get
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a scalar, or improper arguments
        #        supplied)
        #   The instance variable's value on success

        my ($self, $iv, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivGet', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivGet'
                );
            }

            return undef;
        }

        # According to Axmud's coding conventions, if ref() doesn't return 'ARRAY' or 'HASH', it's
        #   a scalar instance variable; so treat it as a scalar
        $refType = ref $self->{$iv};
        if ($refType ne 'ARRAY' && $refType ne 'HASH') {

            # This is a scalar. Retrieve its value
            return $self->{$iv};

        } else {

            # Not a scalar
            return undef;
        }
    }

    sub ivIncrement {

        # Increments a scalar instance variable by 1
        #
        # Expected arguments
        #   $iv   - Which scalar instance variable to modify
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a scalar, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   The instance variable's value on success

        my ($self, $iv, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivIncrement', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivIncrement'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        # According to Axmud's coding conventions, if ref() doesn't return 'ARRAY' or 'HASH', it's
        #   a scalar instance variable; so treat it as a scalar
        $refType = ref $self->{$iv};
        if ($refType ne 'ARRAY' && $refType ne 'HASH') {

            # This is a scalar. Set the parent file object's 'data modified' flag
            $self->doModify('ivIncrement');

            # Increment the scalar and return it
            return ++($self->{$iv});

        } else {

            # Not a scalar
            return undef;
        }
    }

    sub ivDecrement {

        # Decrements a scalar instance variable by 1
        #
        # Expected arguments
        #   $iv   - Which scalar instance variable to modify
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a scalar, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   The instance variable's value on success

        my ($self, $iv, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivDecrement', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivDecrement'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        # According to Axmud's coding conventions, if ref() doesn't return 'ARRAY' or 'HASH', it's
        #   a scalar instance variable; so treat it as a scalar
        $refType = ref $self->{$iv};
        if ($refType ne 'ARRAY' && $refType ne 'HASH') {

            # This is a scalar. Set the parent file object's 'data modified' flag
            $self->doModify('ivDecrement');

            # Decrement the scalar and return it
            return --($self->{$iv});

        } else {

            # Not a scalar
            return undef;
        }
    }

    sub ivPlus {

        # Performs an addition operation on a scalar instance variable
        #
        # Expected arguments
        #   $iv     - Which scalar instance variable to modify
        #   $value  - Which value to add
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a scalar, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   The instance variable's value on success ($self->instanceVariable + $value)

        my ($self, $iv, $value, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || ! defined $value || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivPlus', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivPlus'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        # According to Axmud's coding conventions, if ref() doesn't return 'ARRAY' or 'HASH', it's
        #   a scalar instance variable; so treat it as a scalar
        $refType = ref $self->{$iv};
        if ($refType ne 'ARRAY' && $refType ne 'HASH') {

            # This is a scalar. Set the parent file object's 'data modified' flag
            $self->doModify('ivPlus');

            # Perform the addition
            $self->{$iv} += $value;
            return $self->{$iv};

        } else {

            # Not a scalar
            return undef;
        }
    }

    sub ivMinus {

        # Performs a subtraction operation on a scalar instance variable
        #
        # Expected arguments
        #   $iv     - Which scalar instance variable to modify
        #   $value  - Which value to subtract
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a scalar, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   The instance variable's value on success ($self->instanceVariable - $value)

        my ($self, $iv, $value, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || ! defined $value || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivMinus', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivMinus'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        # According to Axmud's coding conventions, if ref() doesn't return 'ARRAY' or 'HASH', it's
        #   a scalar instance variable; so treat it as a scalar
        $refType = ref $self->{$iv};
        if ($refType ne 'ARRAY' && $refType ne 'HASH') {

            # This is a scalar. Set the parent file object's 'data modified' flag
            $self->doModify('ivMinus');

            # Perform the subtraction
            $self->{$iv} -= $value;

            return $self->{$iv};

        } else {

            # Not a scalar
            return undef;
        }
    }

    sub ivMultiply {

        # Performs a multiplication operation on a scalar instance variable
        #
        # Expected arguments
        #   $iv     - Which scalar instance variable to modify
        #   $value  - Which value to multiply with
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a scalar, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   The instance variable's value on success ($self->instanceVariable * $value)

        my ($self, $iv, $value, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || ! defined $value || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivMultiply', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivMultiply'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        # According to Axmud's coding conventions, if ref() doesn't return 'ARRAY' or 'HASH', it's
        #   a scalar instance variable; so treat it as a scalar
        $refType = ref $self->{$iv};
        if ($refType ne 'ARRAY' && $refType ne 'HASH') {

            # This is a scalar. Set the parent file object's 'data modified' flag
            $self->doModify('ivMultiply');

            # Perform the multiplication
            $self->{$iv} *= $value;

            return $self->{$iv};

        } else {

            # Not a scalar
            return undef;
        }
    }

    sub ivDivide {

        # Performs a division operation on a scalar instance variable
        #
        # Expected arguments
        #   $iv     - Which scalar instance variable to modify
        #   $value  - Which value to divide by
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a scalar, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   The instance variable's value on success ($self->instanceVariable / $value)

        my ($self, $iv, $value, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || ! defined $value || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivDivide', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivDivide'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        # According to Axmud's coding conventions, if ref() doesn't return 'ARRAY' or 'HASH', it's
        #   a scalar instance variable; so treat it as a scalar
        $refType = ref $self->{$iv};
        if ($refType ne 'ARRAY' && $refType ne 'HASH') {

            # This is a scalar. Set the parent file object's 'data modified' flag
            $self->doModify('ivDivide');

            # Perform the division
            $self->{$iv} /= $value;

            return $self->{$iv};

        } else {

            # Not a scalar
            return undef;
        }
    }

    sub ivInt {

        # Removes the fractional part of an instance variable
        #
        # Expected arguments
        #   $iv   - Which scalar instance variable to modify
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a scalar, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   The instance variable's value on success

        my ($self, $iv, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivInt', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivInt'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        # According to Axmud's coding conventions, if ref() doesn't return 'ARRAY' or 'HASH', it's
        #   a scalar instance variable; so treat it as a scalar
        $refType = ref $self->{$iv};
        if ($refType ne 'ARRAY' && $refType ne 'HASH') {

            # This is a scalar. Set the parent file object's 'data modified' flag
            $self->doModify('ivInt');

            # Increment the scalar and return it
            return $self->{$iv} = int($self->{$iv});

        } else {

            # Not a scalar
            return undef;
        }
    }

    sub ivPush {

        # Push function for array instance variables
        #
        # Expected arguments
        #   $iv     - Which array instance variable to modify
        #
        # Optional arguments
        #   @list   - List of values to push into the array (can be an empty list)
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't an array, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   1 on success

        my ($self, $iv, @list) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivPush', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivPush'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'ARRAY') {

            # This is a list. Set the parent file object's 'data modified' flag
            $self->doModify('ivPush');

            # Perform the push operation
            push( @{$self->{$iv}}, @list );

            return 1;

        } else {

            # Not a list
            return undef;
        }
    }

    sub ivPop {

        # Pop function for array instance variables
        #
        # Expected arguments
        #   $iv   - Which array instance variable to modify
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't an arry, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   A scalar value on success

        my ($self, $iv, $check) = @_;

        # Local variables
        my ($refType, $returnValue);

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivPop', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivPop'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'ARRAY') {

            # This is a list. Set the parent file object's 'data modified' flag
            $self->doModify('ivPop');

            # Perform the pop operation
            return ( pop @{$self->{$iv}} );

        } else {

            # Not a list
            return undef;
        }
    }

    sub ivUnshift {

        # Unshift function for array instance variables
        #
        # Expected arguments
        #   $iv     - Which array instance variable to modify
        #
        # Optional arguments
        #   @list   - List of values to unshift into the array (can be an empty list)
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't an array, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   Number of elements in new array, on success

        my ($self, $iv, @list) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivUnshift', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivUnshift'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'ARRAY') {

            # This is a list. Set the parent file object's 'data modified' flag
            $self->doModify('ivUnshift');

            # Perform the unshift operation
            return ( unshift(@{$self->{$iv}}, @list) );

        } else {

            # Not a list
            return undef;
        }
    }

    sub ivShift {

        # Shift function for array instance variables
        #
        # Expected arguments
        #   $iv   - Which array instance variable to modify
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't an array, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   A scalar value on success

        my ($self, $iv, $check) = @_;

        # Local variables
        my ($refType, $returnValue);

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivSet', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivUnshift'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'ARRAY') {

            # This is a list. Set the parent file object's 'data modified' flag
            $self->doModify('ivShift');

            # Perform the shift operation
            return ( shift @{$self->{$iv}} );

        } else {

            # Not a list
            return undef;
        }
    }

    sub ivNumber {

        # Function to retrieve the number of elements in an array instance variable
        #
        # Expected arguments
        #   $iv   - Which array instance variable to check
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't an array, or improper arguments
        #        supplied)
        #   An integer upon success (which might be 0 if the array is empty)

        my ($self, $iv, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivNumber', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivNumber'
                );
            }

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'ARRAY') {

            # This is a list. Return the number of elements
            return (scalar @{$self->{$iv}});

        } else {

            # Not a list
            return undef;
        }
    }

    sub ivSplice {

        # Function to splice an array instance variable. Returns the spliced elements (obeys the
        #   same rules as the Perl splice() function)
        #
        # Expected arguments
        #   $iv         - Which array instance variable to splice
        #   $offset     - Which index at which to start removing elements
        #
        # Optional arguments
        #   $length     - How many elements to remove (default is all elements from $offset onwards)
        #   @list       - List of scalars to insert at the splice
        #
        # Return values
        #   An empty list on failure (because $iv doesn't exist, or isn't an array, or improper
        #       arguments supplied)
        #   An empty list if $iv is a system constant (specified by the keys in
        #       GA::Client->constIVHash) or or if it begins with _, meaning modification not allowed
        #       using this function
        #   Returns @returnArray, the list of elements removed from the array, on success

        my ($self, $iv, $offset, $length, @list) = @_;

        # Local variables
        my (
            $refType,
            @emptyList, @returnArray,
        );

        # Check for improper arguments
        if (! defined $iv || ! defined $offset) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->ivSplice', @_);
            return @emptyList;
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivSplice'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return @emptyList;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'ARRAY') {

            # This is a list. Set the parent file object's 'data modified' flag
            $self->doModify('ivSplice');

            if (scalar @list) {
                @returnArray = splice ( @{$self->{$iv}}, $offset, $length, @list );
            } elsif (defined $length) {
                @returnArray = splice ( @{$self->{$iv}}, $offset, $length );
            } else {
                @returnArray = splice ( @{$self->{$iv}}, $offset );
            }

            # Return the spliced value(s)
            return @returnArray;

        } else {

            # Not a list
            return @emptyList;
        }
    }

    sub ivIndex {

        # Returns an element at the specified index of an array instance variable
        #
        # Expected arguments
        #   $iv     - Which array instance variable to check
        #   $index  - Which element to return
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't an array, or the index is
        #       outside the array, or improper arguments supplied)
        #   Returns a scalar value on success

        my ($self, $iv, $index, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || ! defined $index || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivIndex', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivIndex'
                );
            }

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'ARRAY') {

            # This is a list. Perform the retrieval operation
            return ($self->{$iv}[$index]);

        } else {

            # Not a list
            return undef;
        }
    }

    sub ivFirst {

        # Returns an element at index 0 of an array instance variable
        # Note that ->ivFirst returns the value of the first element of an array, but ->ivLast
        #   returns the index of the last element of an array
        #
        # Expected arguments
        #   $iv     - Which array instance variable to check
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't an array, or the array is empty,
        #       or improper arguments supplied)
        #   Returns a scalar value on success

        my ($self, $iv, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivFirst', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivFirst'
                );
            }

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'ARRAY') {

            # This is a list. Perform the retrieval operation
            return $self->{$iv}[0];

        } else {

            # Not a list
            return undef;
        }
    }

    sub ivLast {

        # Function to retrieve the the last index in an array instance variable
        # Note that ->ivFirst returns the value of the first element of an array, but ->ivLast
        #   returns the index of the last element of an array
        #
        # Expected arguments
        #   $iv   - Which array instance variable to check
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't an array, or improper arguments
        #        supplied)
        #   An integer upon success (which will be -1 if the array is empty)

        my ($self, $iv, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivLast', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivLast'
                );
            }

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'ARRAY') {

            # This is a list. Return the last index (-1 if the list is empty)
            return $#{$self->{$iv}};

        } else {

            # Not a list
            return undef;
        }
    }

    sub ivReplace {

        # Replaces an element at the specified index of an array instance variable
        #
        # Expected arguments
        #   $iv         - Which array instance variable to check
        #   $index      - Which element to replace
        #
        # Optional arguments
        #   $scalar     - The scalar to insert at the index (default is 'undef')
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't an array, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   1 on success

        my ($self, $iv, $index, $scalar, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || ! defined $index || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivReplace', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivReplace'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'ARRAY') {

            # This is a list. Set the parent file object's 'data modified' flag
            $self->doModify('ivReplace');

            # Perform the replacement operation
            $self->{$iv}[$index] = $scalar;

            return 1;

        } else {

            # Not a list
            return undef;
        }
    }

    sub ivFind {

        # Checks all the elements of an array instance variable to see if one of them matches the
        #   supplied scalar (exactly - $scalar and each element in the array are treated as strings)
        #
        # Expected arguments
        #   $iv         - Which array instance variable to check
        #   $scalar     - The scalar value to match
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't an array, or no matching
        #       element found, or improper arguments supplied)
        #   The index of the first element in the array that matches $scalar, on success

        my ($self, $iv, $scalar, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || ! defined $scalar || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivFind', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivFind'
                );
            }

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'ARRAY') {

            # This is a list. Perform the search operation
            if (! @{$self->{$iv}}) {

                # List is empty
                return undef;
            }

            for (my $count = 0; $count < (scalar @{$self->{$iv}}); $count++) {

                if ($self->{$iv}[$count] eq $scalar) {

                    return $count;
                }
            }

            # No matching element found
            return undef;

        } else {

            # Not a list
            return undef;
        }
    }

    sub ivMatch {

        # Performs a pattern match against all the elements of an array instance variable, looking
        #   for the first one that returns 'true' in a Perl regex
        #
        # Expected arguments
        #   $iv             - Which array instance variable to check
        #   $regEx          - The regular expression to match (the portion between m/.../ )
        #
        # Optional arguments
        #   $globalFlag     - If 1, the match done is m/.../g
        #   $ignoreCaseFlag - If 1, the match done is m/.../i
        #
        # Notes
        #   If $globalFlag and $ignoreCaseFlag are both 1, the match done is m/.../gi
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't an array, or no matching
        #       element found, or improper arguments supplied)
        #   The index of the first element in the array that matches the regular expression, on
        #       success

        my ($self, $iv, $regEx, $globalFlag, $ignoreCaseFlag, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || ! defined $regEx || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivMatch', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivMatch'
                );
            }

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'ARRAY') {

            # This is a list. Perform the match operation
            if (! @{$self->{$iv}}) {

                # List is empty
                return undef;
            }

            for (my $count = 0; $count < (scalar @{$self->{$iv}}); $count++) {

                if ($globalFlag && $ignoreCaseFlag) {

                    if ($self->{$iv}[$count] =~ m/$regEx/gi) {

                        # Match found
                        return $count;
                    }

                } elsif ($globalFlag) {

                    if ($self->{$iv}[$count] =~ m/$regEx/g) {

                        # Match found
                        return $count;
                    }

                } elsif ($ignoreCaseFlag) {

                    if ($self->{$iv}[$count] =~ m/$regEx/i) {

                        # Match found
                        return $count;
                    }

                } else {

                    if ($self->{$iv}[$count] =~ m/$regEx/) {

                        # Match found
                        return $count;
                    }
                }
            }

            # No matching element found
            return undef;

        } else {

            # Not a list
            return undef;
        }
    }

    sub ivEquals {

        # Checks all the elements of an array instance variable to see if one of them matches the
        #   supplied scalar (treats $number and each element in the array as numbers)
        #
        # Expected arguments
        #   $iv         - Which array instance variable to check
        #   $number     - The scalar value to match
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't an array, or improper arguments
        #        supplied)
        #   The index of the first element in the array that equals $number, on success

        my ($self, $iv, $number, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || ! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivEquals', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivEquals'
                );
            }

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'ARRAY') {

            # This is a list. Perform the search operation
            if (! @{$self->{$iv}}) {

                # List is empty
                return undef;
            }

            for (my $count = 0; $count < (scalar @{$self->{$iv}}); $count++) {

                if (
                    ! ($self->{$iv}[$count] =~ /\D/)
                    && $self->{$iv}[$count] == $number
                ) {
                    return $count;
                }
            }

            # No matching element found
            return undef;

        } else {

            # Not a list
            return undef;
        }
    }

    sub ivAdd {

        # Set key-value pair function for hash instance variables
        #
        # Expected arguments
        #   $iv     - Which hash instance variable to modify
        #   $key    - Which key to add
        #   $value  - What value to pair with the key
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a hash, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   1 on success

        my ($self, $iv, $key, $value, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || ! defined $key || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivAdd', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivAdd'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'HASH') {

            # This is a hash. Set the parent file object's 'data modified' flag
            $self->doModify('ivAdd');

            # Add the key-value pair
            $self->{$iv}{$key} = $value;
            return 1;

        } else {

            # Not a hash
            return undef;
        }
    }

    sub ivIncHash {

        # Increments the value of a key in a hash instance variable
        #
        # Expected arguments
        #   $iv     - Which hash instance variable to modify
        #   $key    - Which key to increment
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a hash, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   'undef' if the value matching $key isn't a number or if the specified $key doesn't exist
        #       in the hash
        #   1 on success

        my ($self, $iv, $key, $check) = @_;

        # Local variables
        my ($refType, $value);

        # Check for improper arguments
        if (! defined $iv || ! defined $key || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivIncHash', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivIncHash'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'HASH') {

            # Check the specified key exists
            if (! exists $self->{$iv}{$key}) {

                return undef;

            # Check that the value is a number
            } elsif ($self->{$iv}{$key} =~ m/\D/) {

                return undef;
            }

            # This is a hash. Set the parent file object's 'data modified' flag
            $self->doModify('ivIncHash');

            # Increment the value
            ($self->{$iv}{$key})++;
            return 1;

        } else {

            # Not a hash
            return undef;
        }
    }

    sub ivDecHash {

        # Decrements the value of a key in a hash instance variable
        #
        # Expected arguments
        #   $iv     - Which hash instance variable to modify
        #   $key    - Which key to decrement
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a hash, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   'undef' if the value matching $key isn't a number or if the specified $key doesn't exist
        #       in the hash
        #   1 on success

        my ($self, $iv, $key, $check) = @_;

        # Local variables
        my ($refType, $value);

        # Check for improper arguments
        if (! defined $iv || ! defined $key || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivDecHash', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivDecHash'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'HASH') {

            # Check the specified key exists
            if (! exists $self->{$iv}{$key}) {

                return undef;

            # Check that the value is a number
            } elsif ($self->{$iv}{$key} =~ m/\D/) {

                return undef;
            }

            # This is a hash. Set the parent file object's 'data modified' flag
            $self->doModify('ivDecHash');

            # Decrement the value
            ($self->{$iv}{$key})--;
            return 1;

        } else {

            # Not a hash
            return undef;
        }
    }

    sub ivShow {

        # Function to retrieve the value of a key-value pair in hash instance variables
        #
        # Expected arguments
        #   $iv     - Which hash instance variable to test
        #   $key    - Which key-value pair to retrieve
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a hash, or improper arguments
        #        supplied)
        #   The key's value on success

        my ($self, $iv, $key, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || ! defined $key || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivShow', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivShow'
                );
            }

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'HASH') {

            # This is a hash. Show the value from the key-value pair
            return $self->{$iv}{$key};

        } else {

            # Not a hash
            return undef;
        }
    }

    sub ivDelete {

        # Function to delete a key-value pair in hash instance variables
        #
        # Expected arguments
        #   $iv     - Which hash instance variable to modify
        #   $key    - Which key-value pair to delete
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a hash, or improper arguments
        #        supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   1 on success

        my ($self, $iv, $key, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || ! defined $key || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivDelete', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivDelete'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'HASH') {

            # This is a hash. Check the key-value pair exists
            if (! exists $self->{$iv}{$key}) {

                return undef;
            }

            # Set the parent file object's 'data modified' flag
            $self->doModify('ivDelete');

            # Delete the key-value pair
            delete $self->{$iv}{$key};
            return 1;

        } else {

            # Not a hash
            return undef;
        }
    }

    sub ivExists {

        # Exists function for hash instance variables
        #
        # Expected arguments
        #   $iv     - Which hash instance variable to test
        #   $key    - Which key-value pair to test
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a hash, or improper arguments
        #        supplied)
        #   1 on success

        my ($self, $iv, $key, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || ! defined $key || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivExists', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivExists'
                );
            }

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'HASH') {

            # This is a hash. Check the key-value pair exists
            if (exists $self->{$iv}{$key}) {
                return 1;
            } else {
                return undef;
            }

        } else {

            # Not a hash
            return undef;
        }
    }

    sub ivKeys {

        # Function to retrieve list of keys from hash instance variables
        #
        # Expected arguments
        #   $iv   - Which hash instance variable to test
        #
        # Return values
        #   An empty list on failure (because $iv doesn't exist, or isn't a hash, or improper
        #       arguments supplied)
        #   The list of keys on success (which might be empty)

        my ($self, $iv, $check) = @_;

        # Local variables
        my (
            $refType,
            @emptyList,
        );

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->ivSet', @_);
            return @emptyList;
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivKeys'
                );
            }

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'HASH') {

            # This is a hash. Return a list of keys
            return (keys %{$self->{$iv}} );

        } else {

            # Not a hash
            return @emptyList;
        }
    }

    sub ivValues {

        # Function to retrieve list of values from hash instance variables
        #
        # Expected arguments
        #   $iv   - Which hash instance variable to test
        #
        # Return values
        #   An empty list on failure (because $iv doesn't exist, or isn't a hash, or improper
        #       arguments supplied)
        #   The list of values on success

        my ($self, $iv, $check) = @_;

        # Local variables
        my (
            $refType,
            @emptyList,
        );

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->ivValues', @_);
            return @emptyList;
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivValues'
                );
            }

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'HASH') {

            # This is a hash. Return a list of values
            return ( values %{$self->{$iv}} );

        } else {

            # Not a hash
            return @emptyList;
        }
    }

    sub ivPairs {

        # Function to retrieve the number of key-value pairs in a hash instance variables
        #
        # Expected arguments
        #   $iv   - Which hash instance variable to test
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a hash, or improper arguments
        #        supplied)
        #   The number of key-value pairs on success (may be 0)

        my ($self, $iv, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivPairs', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivPairs'
                );
            }

            return undef;
        }

        $refType = ref $self->{$iv};
        if ($refType eq 'HASH') {

            # This is a hash. Return the number of key-value pairs
            return scalar (keys %{$self->{$iv}} );

        } else {

            # Not a hash
            return undef;
        }
    }

    sub ivList {

        # Function to list all the instance variables in this object package
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   A list of instance variable names on success

        my ($self, $check) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->ivList', @_);
            return @emptyList;
        }

        return keys (%{$self});
    }

    sub ivEmpty {

        # Function to empty an instance variable. If it's a scalar, it's set to 'undef'. If it's a
        #   list or a hash, the list or hash is emptied
        #
        # Expected arguments
        #   $iv   - Which instance variable to modify
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or isn't a scalar / list / hash, or
        #       improper arguments supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   1 on success

        my ($self, $iv, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivEmpty', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivEmpty'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        # According to Axmud's coding conventions, if ref() doesn't return 'ARRAY' or 'HASH', it's
        #   a scalar instance variable; so treat it as a scalar
        $refType = ref $self->{$iv};
        if ($refType eq '' || $refType eq 'ARRAY' || $refType eq 'HASH') {

            # This is a scalar, array or hash. Set the parent file object's 'data modified' flag
            $self->doModify('ivEmpty');

            if ($refType eq '') {

                # A scalar. Set it to 'undef'
                $self->{$iv} = undef;
                return 1;

            } elsif ($refType eq 'ARRAY') {

                # A list. Empty the list
                $self->{$iv} = [];
                return 1;

            } elsif ($refType eq 'HASH') {

                # A hash. Empty the hash
                $self->{$iv} = {};
                return 1;
            }

        } else {

            # Something else. Return 'undef'
            return undef;
        }
    }

    sub ivType {

        # Returns the type of the instance variable - 'scalar', 'list', 'hash'
        # According to Axmud conventions, instance variables should be one of these three. If you
        #   use some other reference (to a block of code, for example), ->ivType will just return
        #   'undef'
        #
        # Expected arguments
        #   $iv   - Which instance variable to check
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, or improper arguments supplied)
        #   One of the values 'scalar', 'list' or 'hash' on success

        my ($self, $iv, $check) = @_;

        # Local variables
        my $refType;

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivType', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivType'
                );
            }

            return undef;
        }

        # According to Axmud's coding conventions, if ref() doesn't return 'ARRAY' or 'HASH', it's
        #   a scalar instance variable; so treat it as a scalar
        $refType = ref $self->{$iv};
        if ($refType eq 'ARRAY') {

            return 'list';

        } elsif ($refType eq 'HASH') {

            return 'hash';

        } else {

            # Assume it's a scalar
            return 'scalar';
        }
    }

    sub ivPeek {

        # Returns the contents of a scalar, array or hash instance variable as a list
        #
        # Expected arguments
        #   $iv   - Which instance variable to check
        #
        # Return values
        #   An empty list on failure (because $iv doesn't exist, isn't a scalar / list / hash or
        #       improper arguments supplied)
        #   Otherwise returns @returnArray, the list of contents (may be an empty list)

        my ($self, $iv, $check) = @_;

        # Local variables
        my (
            $refType,
            @emptyList, @returnArray,
        );

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->ivSet', @_);
            return @emptyList;
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivPeek'
                );
            }

            return undef;
        }

        # According to Axmud's coding conventions, if ref() doesn't return 'ARRAY' or 'HASH', it's
        #   a scalar instance variable; so treat it as a scalar
        $refType = ref $self->{$iv};
        if ($refType eq '') {

            # It's a scalar (presumably). Return the scalar as a 1-element list. Need to check that
            #   the value stored in the IV is defined, otherwise we get an error
            if (defined ${$self->{$iv}}) {

                @returnArray = ( ${$self->{$iv}} );
            }

            return @returnArray;

        } elsif ($refType eq 'ARRAY') {

            # It's a list. Simply return the list
            return @{$self->{$iv}};

        } elsif ($refType eq 'HASH') {

            # It's a hash. Unwind the array into a flat list and return the list
            @returnArray = %{$self->{$iv}};
            return @returnArray;

        } else {

            # Something else
            return @emptyList;
        }
    }

    sub ivPoke {

        # Sets the contents of a scalar, array or hash instance variable
        #
        # Expected arguments
        #   $iv     - Which instance variable to check
        #   @list   - List of values to set
        #
        # Notes
        #   If this IV is a scalar, the IV is set to the first value in @list (if @list is empty,
        #       the IV is set to 'undef')
        #   If this IV is a list, the IV is set to the whole of @list (if @list is empty, the IV is
        #       set to an empty list)
        #   If this IV is a hash, the IV is set to the whole of @list, so @list is expected to be a
        #       (key, value, key, value...) sequence. If the last value is missing, the value in
        #       that key-value pair is set to 'undef'. If @list is empty, the hash is emptied.
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist or improper arguments supplied)
        #   'undef' if $iv is a system constant (specified by the keys in GA::Client->constIVHash)
        #       or if it begins with _, meaning modification not allowed using this function
        #   1 on success

        my ($self, $iv, @list) = @_;

        # Local variables
        my (
            $refType, $debugFlag,
            %hash,
        );

        # Check for improper arguments
        if (! defined $iv) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivPoke', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            if ($axmud::CLIENT->debugCheckIVFlag) {

                $self->writeDebug(
                    'Code accessed non-existent IV \'' . $iv . '\'',
                    $self->_objClass . '->ivPoke'
                );
            }

            return undef;
        }

        # Check that modifying the instance variable is allowed
        if (! $self->checkModify($iv)) {

            return undef;
        }

        # Set the parent file's 'data modified' flag
        $self->doModify('ivPoke');

        # According to Axmud's coding conventions, if ref() doesn't return 'ARRAY' or 'HASH', it's
        #   saved in one of the scalar IVs (might be a scalar value or a blessed reference)
        $refType = ref $self->{$iv};
        if ($refType eq 'ARRAY') {

            # It's a list. Set the list
            $self->{$iv} = \@list;

            return 1;

        } elsif ($refType eq 'HASH') {

            # It's a hash. Convert @list into a hash, and set the hash
            %hash = @list;
            $self->{$iv} = \%hash;

            return 1;

        } else {

            if (! @list) {
                $self->{$iv} = undef;
            } else {
                $self->{$iv} = $list[0];
            }

            return 1;
        }
    }

    sub ivMember {

        # See if the instance variable exists, or not
        #
        # Expected arguments
        #   $iv   - Which instance variable to check
        #
        # Return values
        #   'undef' on improper arguments or if the instance variable doesn't exist
        #   1 if the instance variable exists

        my ($self, $iv, $check) = @_;

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivMember', @_);
        }

        # Check the instance variable exists at all
        if (! exists $self->{$iv}) {

            return undef;

        } else {

            return 1;
        }
    }

    sub ivCreate {

        # Creates a new IV of a specified type. If it's a scalar, its initial value is 'undef'.
        #   If it's a list or hash, its initial value is an empty list of hash
        # The reason to call this function - rather than to use a statement like
        #       $self->{...} = ...
        #   ...is, of course, to make sure that parent file object's ->modifyFlag (if any) is set
        # This function is provided for profile templates (and probably isn't useful for anything
        #   else)
        #
        # Expected arguments
        #   $iv     - The name of the new instance variable
        #   $type   - 'scalar', 'list' (or 'array'), or 'hash'
        #
        # Return values
        #   'undef' on failure (because $iv already exists or improper arguments supplied)
        #   1 on success

        my ($self, $iv, $type, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $iv || ! defined $type
            || ($type ne 'scalar' && $type ne 'list' && $type ne 'array' && $type ne 'hash')
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivCreate', @_);
        }

        # Check the variable doesn't already exist
        if (exists $self->{$iv}) {

            return undef;
        }

        # Create the variable
        if ($type eq 'list' || $type eq 'array') {
            $self->{$iv} = [];
        } elsif ($type eq 'hash') {
            $self->{$iv} = {};
        } else {
            $self->{$iv} = undef;
        }

        # Set the parent file object's 'data modified' flag
        $self->doModify('ivCreate');

        return 1;
    }

    sub ivDestroy {

        # Destroys an existing IV
        # The reason to call this function - rather than to use a statement like
        #       delete $self->{...}
        #   ...is, of course, to make sure that parent file object's ->modifyFlag (if any) is set
        # This function is provided for profile templates (and probably isn't useful for anything
        #   else)
        # IVs which being with an underline can't be destroyed (we definitely don't want to
        #   destory one of the four standard IVs, used by all Perl objects, by mistake)
        #
        # Expected arguments
        #   $iv     - The name of the doomed instance variable
        #
        # Return values
        #   'undef' on failure (because $iv doesn't exist, the property begins with an underline
        #       or improper arguments supplied)
        #   1 on success

        my ($self, $iv, $check) = @_;

        # Check for improper arguments
        if (! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ivCreate', @_);
        }

        # Check the variable exists
        if (! exists $self->{$iv}) {

            return undef;

        # Check it doesn't begin with an underline
        } elsif (substr($iv, 0, 1) eq '_') {

            return undef;
        }

        # Destroy the variable
        delete $self->{$iv};

        # Set the parent file object's 'data modified' flag
        $self->doModify('ivDestroy');

        return 1;
    }

    # Text-writing methods

    sub writeText {

        # Can be called by anything
        # Passes a set of arguments to GA::Obj::TextView->showSystemText. If it's not possible to
        #   display a message in a 'main' window, writes to the terminal (and the Client Console
        #   window, the next time it's opened)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   @args   - A list of arguments to pass on. The first one is the system message itself
        #
        # Return values
        #   Returns the return value of the call to GA::Obj::TextView->showSystemText, or 'undef' if
        #       forced to write to the terminal

        my ($self, @args) = @_;

        # Local variables
        my $msg;

        # (No improper arguments to check)

        # If this object has a ->session IV, then we can find its default tab
        if (exists $self->{'session'} && $self->session && $self->session->defaultTabObj) {

            return $self->session->defaultTabObj->textViewObj->showSystemText(@args);

        # Otherwise, try the GA::Client's current session (the visible session in the last 'main'
        #   window to receive focus)
        } elsif ($axmud::CLIENT->currentSession && $axmud::CLIENT->currentSession->defaultTabObj) {

            return
                $axmud::CLIENT->currentSession->defaultTabObj->textViewObj->showSystemText(@args);

        } else {

            # Otherwise, we're forced to write to the terminal. The message is also stored in
            #   GA::Client->systemMsgList, so it can be viewed in the Client Console window, if and
            #   when the user opens it
            $msg = $args[0];
            if (! defined $msg) {

                $msg = '<<undef>>';
            }

            $msg = 'SYSTEM: ' . $msg;

            $axmud::CLIENT->add_systemMsg('system', $msg);
            print $msg . "\n";

            return undef;
        }
    }

    sub writeError {

        # Can be called by anything
        # Passes a set of arguments to GA::Obj::TextView->showError. If it's not possible to display
        #   a message in a 'main' window, writes to the terminal (and the Client Console window, the
        #   next time it's opened)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $text   - The error message to write. If undefined, the text <<undef>> is written
        #   $func   - The function that produced the error (e.g. 'Games::Axmud::Session->start'). If
        #               undefined, the function is not displayed
        #
        # Return values
        #   'undef'

        my ($self, $text, $func, $check) = @_;

        # Local variables
        my $msg;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->writeError', @_);
        }

        # If this object has a ->session IV, then we can find its default tab
        if (exists $self->{'session'} && $self->session && $self->session->defaultTabObj) {

            return $self->session->defaultTabObj->textViewObj->showError($text, $func);

        # Otherwise, try the GA::Client's current session (the visible session in the last 'main'
        #   window to receive focus)
        } elsif ($axmud::CLIENT->currentSession && $axmud::CLIENT->currentSession->defaultTabObj) {

            return $axmud::CLIENT->currentSession->defaultTabObj->textViewObj->showError(
                $text,
                $func,
            );

        } else {

            # Write to the terminal and the Client Console window, if possible
            if (! defined $text) {

                $text = "<<undef>>\n";
            }

            if ($func) {
                $msg = "ERROR: $func: $text";
            } else {
                $msg = "ERROR: $text";
            }

            $axmud::CLIENT->add_systemMsg('error', $msg);
            print $msg . "\n";

            return undef;
        }
    }

    sub writeWarning {

        # Can be called by anything
        # Passes a set of arguments to GA::Obj::TextView->showWarning. If it's not possible to
        #   display a message in a 'main' window, writes to the terminal (and the Client Console
        #   window, the next time it's opened)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $text   - The warning message to write. If undefined, the text <<undef>> is written
        #   $func   - The function that produced the warning (e.g. 'Games::Axmud::Session->start').
        #               If undefined, the function is not displayed
        #
        # Return values
        #   'undef'

        my ($self, $text, $func, $check) = @_;

        # Local variables
        my $msg;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->writeWarning', @_);
        }

        # If this object has a ->session IV, then we can find its default tab
        if (exists $self->{'session'} && $self->session && $self->session->defaultTabObj) {

            return $self->session->defaultTabObj->textViewObj->showWarning($text, $func);

        # Otherwise, try the GA::Client's current session (the visible session in the last 'main'
        #   window to receive focus)
        } elsif ($axmud::CLIENT->currentSession && $axmud::CLIENT->currentSession->defaultTabObj) {

            return $axmud::CLIENT->currentSession->defaultTabObj->textViewObj->showWarning(
                $text,
                $func,
            );

        } else {

            # Write to the terminal and the Client Console window, if possible
            if (! defined $text) {

                $text = "<<undef>>\n";
            }

            if ($func) {
                $msg = "WARNING: $func: $text";
            } else {
                $msg = "WARNING: $text";
            }

            $axmud::CLIENT->add_systemMsg('warning', $msg);
            print $msg . "\n";

            return undef;
        }
    }

    sub writeDebug {

        # Can be called by anything
        # Passes a set of arguments to GA::Obj::TextView->showDebug. If it's not possible to
        #   display a message in a 'main' window, writes to the terminal (and the Client Console
        #   window, the next time it's opened)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $text   - The debug message to write. If undefined, the text <<undef>> is written
        #   $func   - The function that produced the message (e.g. 'Games::Axmud::Session->start').
        #               If undefined, the function is not displayed
        #
        # Return values
        #   'undef'

        my ($self, $text, $func, $check) = @_;

        # Local variables
        my $msg;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->writeDebug', @_);
        }

        # If this object has a ->session IV, then we can find its default tab
        if (exists $self->{'session'} && $self->session && $self->session->defaultTabObj) {

            return $self->session->defaultTabObj->textViewObj->showDebug($text, $func);

        # Otherwise, try the GA::Client's current session (the visible session in the last 'main'
        #   window to receive focus)
        } elsif ($axmud::CLIENT->currentSession && $axmud::CLIENT->currentSession->defaultTabObj) {

            return $axmud::CLIENT->currentSession->defaultTabObj->textViewObj->showDebug(
                $text,
                $func,
            );

        } else {

            # Write to the terminal and the Client Console window, if possible
            if (! defined $text) {

                $text = "<<undef>>\n";
            }

            if ($func) {
                $msg = "DEBUG: $func: $text";
            } else {
                $msg = "DEBUG: $text";
            }

            $axmud::CLIENT->add_systemMsg('debug', $msg);
            print $msg . "\n";

            return undef;
        }
    }

    sub wd {

        # Convenience function; all arguments are passed directly to $self->writeDebug
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $text   - The debug message to write. If undefined, the text <<undef>> is written
        #   $func   - The function that produced the message (e.g. 'Games::Axmud::Session->start').
        #               If undefined, the function is not displayed
        #
        # Return values
        #   'undef'

        my ($self, @args) = @_;

        return $self->writeDebug(@args);
    }

    sub writeImproper {

        # Can be called by anything
        # Passes a set of arguments to GA::Obj::TextView->showImproper. If it's not possible to
        #   display a message there, writes to the terminal (and the Client Console window, the next
        #   time it's opened)
        #
        # Expected arguments
        #   $func   - The function that produced the message (e.g. 'Games::Axmud::Session->start')
        #
        # Optional arguments
        #   @args   - A list of arguments passed to the calling function. If no arguments were
        #               passed, an empty list
        #
        # Return values
        #   'undef'

        my ($self, $func, @args) = @_;

        # Local variables
        my $msg;

        # Check for improper arguments
        if (! defined $func) {

            # This function mustn't call itself, so write something to the terminal and the Client
            #   Console window, if possible
            $msg = "ERROR: Recursive improper arguments call from $func";

            $axmud::CLIENT->add_systemMsg('improper', $msg);
            print $msg . "\n";

            return undef;
        }

        # Always display improper arguments error messages in the current session's default tab
        if ($axmud::CLIENT->currentSession && $axmud::CLIENT->currentSession->defaultTabObj) {

            return $axmud::CLIENT->currentSession->defaultTabObj->textViewObj->showImproper(
                $func,
                @args,
            );

        } else {

            # Some of the values in @args might be 'undef'; these need to be replaced by some text
            #   that can actually be displayed
            foreach my $arg (@args) {

                if (! defined $arg) {

                    $arg = "<<undef>>\n";
                }
            }

            # Write to the terminal and the Client Console window, if possible
            $msg = "IMPROPER ARGUMENTS: $func() " . join (" ", @args);

            $axmud::CLIENT->add_systemMsg('improper', $msg);
            print $msg . "\n";

            return undef;
        }
    }

    sub debugBreak {

        # Can be called by anything
        # Opens a 'dialogue' window, which effectively halts execution until the window is closed
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $title  - The window title. If undefined, a generic title is set
        #   $msg    - The message to show. If undefined, a generic message is shown
        #
        # Return values
        #   'undef' on improper arguments or if the 'dialogue' window can't be opened
        #   1 otherwise

        my ($self, $title, $msg, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->debugBreak', @_);
        }

        if (! $title) {

            $title = $axmud::SCRIPT . ' debug';
        }

        if (! $msg) {

            $msg = 'This is a debug message';
        }

        # Open the 'dialogue' window, using the current session's 'main' window as the parent window
        #   (if there is one)
        if ($axmud::CLIENT->mainWin) {

            $axmud::CLIENT->mainWin->showMsgDialogue(
                $title,
                'info',
                $msg,
                'ok',
            );

            return 1;

        } else {

            return $self->writeError(
                'Can\'t open debug \'dialogue\' window when no \'main\' windows are open',
                $self->_objClass . '->debugBreak',
            );
        }
    }

    sub writePerlError {

        # Called by code in axmud.pl
        # After trapping a Perl error, display the error in a 'main' window. If it's not possible to
        #   display a message there, write to the terminal (and the Client Console window, the next
        #   time it's opened)
        #
        # Expected arguments
        #   @list   - One or more lines of text that comprise the Perl error message
        #
        # Return values
        #   'undef'

        my ($self, @list) = @_;

        # Local variables
        my $msg;

        # (No improper arguments to check)

        # We don't know which session generated the error, so display the error message in the
        #   current session's tab
        if (
            $axmud::CLIENT->debugTrapErrorFlag
            && $axmud::CLIENT->currentSession
            && $axmud::CLIENT->currentSession->defaultTabObj
        ) {
            foreach my $string (@list) {

                # GA::Obj::TextView->showError is not expecting any newline characters, so remove
                #   them
                foreach my $line (split(/\n/, $string)) {

                    $axmud::CLIENT->currentSession->defaultTabObj->textViewObj->showError($line);
                }
            }

        } else {

            # Write to the terminal and the Client Console window, if possible
            $msg = "PERL ERROR: " . join("\n", @list);

            $axmud::CLIENT->add_systemMsg('error', $msg);
            print $msg . "\n";

            return undef;
        }

        return undef;
    }

    sub writePerlWarning {

        # Called by code in axmud.pl
        # After trapping a Perl warning, display the warning in a 'main' window. If it's not
        #   possible to display a message there, write to the terminal (and the Client Console
        #   window, the next time it's opened)
        #
        # Expected arguments
        #   @list   - One or more lines of text that comprise the Perl warning message
        #
        # Return values
        #   'undef'

        my ($self, @list) = @_;

        # Local variables
        my $msg;

        # (No improper arguments to check)

        # We don't know which session generated the warning, so display the warning message in the
        #   current session's tab
        if (
            $axmud::CLIENT->debugTrapErrorFlag
            && $axmud::CLIENT->currentSession
            && $axmud::CLIENT->currentSession->defaultTabObj
        ) {
            foreach my $string (@list) {

                # GA::Obj::TextView->showWarning is not expecting any newline character, so remove
                #   them
                foreach my $line (split(/\n/, $string)) {

                    $axmud::CLIENT->currentSession->defaultTabObj->textViewObj->showWarning($line);
                }
            }

        } else {

            # Write to the terminal and the Client Console window, if possible
            $msg = "PERL WARNING: " . join("\n", @list);

            $axmud::CLIENT->add_systemMsg('warning', $msg);
            print $msg . "\n";

            return undef;
        }

        return undef;
    }

    sub showList {

        # Debugging function
        # Displays the contents of a list, numbered
        #
        # Expected arguments
        #   $num     - A Perl line number to display
        #   @list    - The list to display
        #
        # Return values
        #   1

        my ($self, $num, @list) = @_;

        # Local variables
        my $count;

        # (This is a debugging function, so no need to check for improper arguments)

        # Display header
        if (! $num) {

            # Forgot to specify it...
            $num = '?';
        }

        $self->writeDebug('START of list (line ' . $num . ', size: ' . @list . ')');

        # Display list
        $count = -1;
        foreach my $item (@list) {

            $count++;

            if (defined $item) {
                $self->writeDebug('  ' . $count . ': ' . $item);
            } else {
                $self->writeDebug('  ' . $count . ': <undef>');
            }
        }

        # Display footer
        $self->writeDebug('END of list');

        return 1;
    }

    sub showHash {

        # Debugging function
        # Displays contents of a hash
        #
        # Expected arguments
        #   $num     - A line number to display
        #   %hash    - The hash to display
        #
        # Return values
        #   1

        my ($self, $num, %hash) = @_;

        # (This is a debugging function, so no need to check for improper arguments)

        # Display header
        if (! $num) {

            # Forgot to specify it...
            $num = '?';
        }

        $self->writeDebug('START of hash (line ' . $num . ')');

        # Display hash
        foreach my $key (keys %hash) {

            if (defined $hash{$key}) {
                $self->writeDebug('  key: ' . $key . ' value: ' . $hash{$key});
            } else {
                $self->writeDebug('  key: ' . $key . ' value: <<UNDEF>>');
            }
        }

        # Display footer
        $self->writeDebug('END of hash');

        return 1;
    }

    sub getMethodRef {

        # Convenience function for obtaining a function reference to a method (i.e. a function
        #   within an OOP object). The Perl code is a bit tricky, so this function can be used to
        #   simplify things a bit
        #
        # Example call:
        #   $self->getMethodRef('entryCallback')
        #
        # Expected arguments
        #   $funcName   - The name of a function, which must be a function in $self
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns a function reference

        my ($self, $funcName, $check) = @_;

        # Local variables
        my $funcRef;

        # Check for improper arguments
        if (! defined $funcName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getMethodRef', @_);
        }

        $funcRef = sub { $self->$funcName(@_) };

        return $funcRef;
    }

    ##################
    # Accessors - get

    # There are five standard IVs for every Axmud Perl object

    # A name for the object (might store the same value as the ->name IV, if there is one). Not
    #   used for anything important
    sub _objName
        { $_[0]->{_objName} }

    # The class into which the object has been blessed (usually the same as ref($self) )
    sub _objClass
        { $_[0]->{_objClass} }

    # The parent GA::Obj::File. Value matches one of the standard file object types (currently
    #   'config', 'otherprof', 'worldmodel', 'tasks', 'scripts', 'contacts', 'dicts', 'toolbar',
    #   'usercmds', 'zonemaps', 'winmaps', 'tts' or, for 'worldprof' file objects, the name of the
    #   world profile). Very important; used to set parent file object's ->modifyFlag
    sub _parentFile
        { $_[0]->{_parentFile} }

    # The 'otherprof' and 'worldmodel' file objects aren't stored in the GA::Client - where anything
    #   can look them up - but in GA::Session objects for which they have been loaded. In order to
    #   set the ->modifyFlag for these file objects, this value matches the name of the current
    #   world profile for the session(s). Set to 'undef' for other types of file object
    sub _parentWorld
        { $_[0]->{_parentWorld} }

    # A flag set to TRUE if this object's IVs are 'private' - which means that other objects can
    #   read the IVs, but cannot set them directly; instead they have to call a 'get' accessor. Set
    #   to FALSE if IVs can be set directly with calls like $obj->ivPoke(iv_name, new_value)
    sub _privFlag
        { $_[0]->{_privFlag} }

    ##################
    # Accessors - set
}

=pod

=head1 NAME

Games::Axmud - Axmud, a modern Multi-User Dungeon (MUD) client written in Perl5
/ GTK2

=head1 SYNOPSIS

Axmud is known to work on MS Windows, Linux and *BSD. It might be possible to
install it on other systems such as MacOS, but the authors have not been able to
confirm this yet.

After installation (see the INSTALL file), visually-impaired users can run this
script

    baxmud.pl

Other users can run this script

    axmud.pl

Using either script, you can specify a world to which Axmud connects immediately

    axmud.pl empiremud.net 4000

If you omit the port number, Axmud connects using the generic port 23

    axmud.pl elephant.org

If a world profile already exists, you can specify its name instead

    axmud.pl cryosphere

Note that window tiling and multiple desktop support has not been implemented on
MS Windows yet.

=head1 DESCRIPTION

Axmud is a modern Multi-User Dungeon (MUD) client written in Perl 5 / GTK 2.
Its features include:

Telnet, SSH and SSL connections - ANSI/xterm/OSC/RGB colour - Full support for
all major MUD protocols, including MXP and GMCP (with partial Pueblo support) -
VT100 emulation - Class-based triggers, aliases, macros, timers and hooks
- Graphical automapper - 100 pre-configured worlds - Multiple approaches to
scripting - Fully customisable from top to bottom, using the command line or the
extensive GUI interface - Native support for visually-impaired users

=head1 AUTHOR

A S Lewis <aslewis@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2011-2018 A S Lewis

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <http://www.gnu.org/licenses/>.

=cut

# Package must return a true value
1
