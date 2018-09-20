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
# Games::Axmud::Obj::Mission
# Handles missions (very simple scripts)

{ package Games::Axmud::Obj::Mission;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Cmd::AddMission->do
        # Creates a new instance of the mission object
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $name       - A unique string name for this mission (max 16 chars, containing
        #                   A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable.
        #                   Must not exist as a key in the global hash of reserved names,
        #                   $axmud::CLIENT->constReservedHash)
        #
        # Optional arguments
        #   $descrip    - A short description for the mission (max 64 chars) ('undef' if not
        #                   specified)
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $descrip, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $session || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that $name is valid and not already in use by another mission (missions are
        #   stored in the current world profile)
        if (! $axmud::CLIENT->nameCheck($name, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $class . '->new',
            );

        } elsif ($session->currentWorld->ivExists('missionHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: current world profile already has a mission called \''
                . $name . '\'',
                $class . '->new',
            );
        }

        # If a description was specified, check it for length
        if (defined $descrip) {

            if (length($descrip) >  64) {

                return $axmud::CLIENT->writeError(
                    'Mission description is too long (max 64 characters)',
                    $class . '->new',
                );
            }

        } else {

            $descrip = '<no description available>';
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => $session->currentWorld->name,
            _parentWorld                => undef,
            _privFlag                   => TRUE,        # All IVs are private

            # IVs
            # ---

            # A unique name for the mission (max 16 chars)
            name                        => $name,
            # A short description for the mission (max 64 chars)
            descrip                     => $descrip,

            # The contents of the mission
            # Each element in the list is a string beginning with an identifying character,
            #   (optionally followed by any amount of whitespace), followed by a command to process
            #   - so the following elements are equivalent:
            #       >kill orc
            #       > kill orc
            #       >      kill orc
            # The initial character (and any following whitespace) is stripped, before the string is
            #   used. Valid initial characters are:
            #   '>' identifies the string as a world command
            #   ';' identifies the string as a client command
            #   '.' identifies the string as a speedwalk command
            #   '#' identifies the string as a comment to be displayed in the 'main' window
            #   '@' identifies the string as a break (anything following the '@' is ignored)
            # There are three special kinds of break (see the help for ';startmission'):
            #   't' identifies a trigger break; it is followed by a string used as the stimulus
            #       in a trigger. When the trigger fires, the mission continues
            #   'p' identifies a pause break; it is followed by a number, the time (in seconds) to
            #       wait
            #   'l' identifies a Locator break; it waits for the Locator task to decide it's not
            #       expecting any more room descriptions (anything following the 'l' is ignored)
            # There are four initial characters for missions being used as login scripts:
            #   'n' sends the current character profile's name (if set)
            #   'w' sends the corresponding password (if known)
            #   'a' sends the corresponding account name (if known)
            #   'c' sends a combination of the three above; if the command contains '@name@', it is
            #           substituted for the current character profile's name; '@password@' is
            #           substituted for the corresponding password and '@account@' is substituted
            #           for the corresponding account name. The string, probably modified, is then
            #           sent as an ordinary world command. If @name@, @password@ and @account@ are
            #           used, but are not set, the world command isn't sent. If there is no
            #           current character, the world command isn't sent (even if @name@ is not used)
            #
            # Normally, the mission consists of a group of commands followed by a break, followed by
            #   another group of commands, followed by another break, and so on
            # When the mission is initiated, commands are sent continuously to the world until a
            #   break is found. The user needs to re-initiate the mission, at which time the next
            #   group of commands is sent continuously until the next break is found
            # Comments can appear anywhere in the list, but it's best to put them immediately before
            #   a break
            missionList                 => [],

            # (The remaining IVs are only used when a mission, stored in
            #   GA::Session->currentMission, is running)

            # Flag set to TRUE if the mission should not display confirmation messages in the
            #   'main' window, FALSE if it should display them (as normal)
            # NB Comments and error/warning messages are displayed as normal, even when TRUE
            quietFlag                   => FALSE,

            # When a mission is first initiated (or rest), the contents of ->missionList are copied
            #   into this list. This list is gradually emptied as the mission progresses. When the
            #   list is empty, the mission is complete.
            currentList                 => [],
            # Counts how many strings have been used during a current mission. If this IV is set to
            #   n, then $self->currentList[n] is the next string for processing. If set to 0, the
            #   mission isn't current. The first string is #1
            nextString                  => 0,

            # Every time a comment is displayed, it is saved here (so the ';repeatcomment' command
            #   can show it again, if it has scrolled off the screen)
            prevComment                 => undef,
            # Every command sent is added to this list, so the ';repeatmission' command can access
            #   them
            prevCmdList                 => [],

            # Whenever a current mission is not on a break, this variable set to 'undef'. Otherwise,
            #   it is set to a string describing the break we're on: 'break' (for normal breaks),
            #   'trigger', 'pause', 'locator'
            breakType                   => undef,
            # For triggers breaks, the name of the active trigger interface created
            triggerName                 => undef,
            # For pause breaks, the name of the active timer interface created
            timerName                   => undef,
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    sub clone {

        # Called by GA::Cmd::StartMission->do or CloneMission->do
        # Creates a clone of an existing mission
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #
        # Optional arguments
        #   $name       - A unique string name for this mission (max 16 chars, containing
        #                   A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable.
        #                   Must not exist as a key in the global hash of reserved names,
        #                   $axmud::CLIENT->constReservedHash). If not specified (because the cloned
        #                   mission is to be stored in GA::Session->currentMission), the clone has
        #                   the same name as the original
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid (when specified)
        #   Blessed reference to the newly-created object on success

        my ($self, $session, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        if (defined $name) {

            # Check that $name is valid and not already in use by another profile
            if (! $axmud::CLIENT->nameCheck($name, 16)) {

                return $axmud::CLIENT->writeError(
                    'Registry naming error: invalid name \'' . $name . '\'',
                    $self->_objClass . '->clone',
                );

            } elsif ($axmud::CLIENT->ivExists('worldProfHash', $name)) {

              return $axmud::CLIENT->writeError(
                    'Registry naming error: profile \'' . $name . '\' already exists',
                    $self->_objClass . '->clone',
                );
            }

        } else {

            # The cloned mission has the same ->name as the original
            $name = $self->name;
        }

        # Setup
        my $clone = {
            _objName                    => $name,
            _objClass                   => $self->_objClass,
            _parentFile                 => $session->currentWorld->name,
            _parentWorld                => undef,
            _privFlag                   => TRUE,        # All IVs are private

            # IVs
            # ---

            name                        => $name,
            descrip                     => $self->descrip,

            quietFlag                   => FALSE,

            missionList                 => [$self->missionList],

            currentList                 => [],
            nextString                  => 0,

            prevComment                 => undef,
            prevCmdList                 => [],

            breakType                   => undef,
            triggerName                 => undef,
            timerName                   => undef,
        };

        # Bless the cloned object into existence
        bless $clone, $self->_objClass;

        return $clone;
    }

    ##################
    # Methods

    sub startMission {

        # Called by GA::Cmd::StartMission->do
        # Starts the mission stored in this object
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $quietFlag  - Flag set to TRUE if the mission should not display confirmation messages
        #                   in the 'main' window, FALSE (or 'undef') if it should display them
        #                   (as normal)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $quietFlag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->startMission', @_);
        }

        # Make sure that all the IVs used when a GA::Session is running a mission have their
        #   default values
        $self->resetMission();

        # Start the mission
        $self->ivPoke('currentList', $self->missionList);
        if ($quietFlag) {

            $self->ivPoke('quietFlag', TRUE);
        }

        return 1;
    }

    sub resetBreak {

        # Called by GA::Cmd::Mission->do at the end of a break
        # Resets a few IVs
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetBreak', @_);
        }

        # Reset IVs
        $self->ivUndef('breakType');
        $self->ivUndef('triggerName');
        $self->ivUndef('timerName');

        return 1;
    }

    sub continueMission {

        # Called by GA::Cmd::StartMission->do, etc
        # Also called by $self->triggerSeen, etc
        #
        # Proceeds with the next stage in the mission. Starting with the first remainining element
        #   in $self->currentList, processes each element in turn until either a break or the end
        #   of the list is reached
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #
        # Optional arguments
        #   $singleFlag - Set to TRUE if only one string from ->currentList should be processed
        #                   (e.g. when called by GA::Cmd::Mission->do); otherwise 'undef'
        #
        #
        # Return values
        #   'undef' on improper arguments
        #   1 if a break is reached (or the first string is processed, when $singleFlag is TRUE)
        #   2 if $self->currentList has been emptied, signifying the end of the mission

        my ($self, $session, $singleFlag, $check) = @_;

        # Local variables
        my ($count, $name, $pwd, $pwdFlag, $account);

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->continueMission', @_);
        }

        # Process each string in turn
        $count = 0;
        while (1) {

            my ($string, $initChar, $cmd, $triggerObj, $triggerString, $timerObj, $interval);

            # $count is needed to identify the first while loop; $self->nextString identifies which
            #   string in the list $self->currentList is next to be processed (i.e. on the next
            #   'while' loop)
            $count++;
            $self->ivIncrement('nextString');

            if (! $self->currentList) {

                # The mission has finished
                $self->completeMission($session);

                return 2;

            } else {

                # Get the next string to process
                $string = $self->ivShift('currentList');
            }

            # $string starts with an initial char, followed by optional whitespace, followed by a
            #   command to process. Separate $string into its components
            $initChar = substr($string, 0, 1);
            $cmd = substr($string, 1);
            $cmd = $axmud::CLIENT->trimWhitespace($cmd);

            if ($initChar eq '>') {

                # It's a world command
                $session->doInstruct($cmd);

                # Add the command to the misson's previous command list, in case the user wants to
                #   repeat it (keep the '>' to identify it as a world command)
                $self->ivPush('prevCmdList', $string);

                # If the flag has been set, we don't send any more commands for now
                if ($singleFlag) {

                    return 1;
                }

            } elsif ($initChar eq ';') {

                # If $cmd is empty, then simply ignore this string
                if ($cmd) {

                    # It's a client command - so we need to re-attach the initial ';'
                    $session->doInstruct(';' . $cmd);

                    # Add the command to the misson's previous command list, in case the user wants
                    #   to repeat them (keep the '!' to identify it as a client command)
                    $self->ivPush('prevCmdList', $string);

                    # If the flag has been set, we don't send any more commands for now
                    if ($singleFlag) {

                        return 1;
                    }
                }

            } elsif ($initChar eq '.') {

                # If $cmd is empty, then simply ignore this string
                if ($cmd) {

                    # It's a speedwalk command
                    $session->speedWalkCmd('.' . $cmd);

                    # If the flag has been set, we don't send any more commands for now
                    if ($singleFlag) {

                        return 1;
                    }
                }

            } elsif ($initChar eq '#') {

                # If $cmd is empty, then simply ignore this string
                if ($cmd) {

                    # It's a comment. Display it
                    $self->displayComment($session, $cmd);
                    # Save the comment, in case the user wants to repeat it
                    $self->ivPoke('prevComment', $cmd);
                }

            } elsif ($initChar eq '@') {

                # It's a break. However, if this is the first string in the list and this function
                #   was called by ';incrementmission', we're probably at the start of a
                #   break-comment-break sequence. We don't want to do nothing, because that's
                #   disconcerting, so ignore the break. Otherwise, process the break
                if (! $singleFlag || $count != 1) {

                    $self->ivPoke('breakType', 'break');
                    # Return 1 to show a break has been reached
                    return 1;
                }

            } elsif ($initChar eq 't') {

                # It's a trigger break
                if (! $cmd) {

                    $session->writeWarning(
                        'Current mission\'s trigger string is invalid (using normal break instead)',
                        $self->_objClass . '->continueMission',
                    );

                    # Create a normal break instead
                    $self->ivPoke('breakType', 'break');
                    # Return 1 to show a break has been reached
                    return 1;

                } else {

                    # Create a trigger
                    $triggerObj = $session->createInterface(
                        'trigger',
                        $cmd,       # A pattern
                        $self,
                        'triggerSeen',
                    );

                    if (! $triggerObj) {

                        $session->writeWarning(
                            'Current mission failed to create trigger for the pattern \'' . $cmd
                            . '\'  (using normal break instead)',
                            $self->_objClass . '->continueMission',
                        );

                        # Create a normal break instead
                        $self->ivPoke('breakType', 'break');
                        # Return 1 to show a break has been reached
                        return 1;

                    } else {

                        $self->ivPoke('breakType', 'trigger');
                        $self->ivPoke('triggerName', $triggerObj->name);
                        # Return 1 to show a break has been reached
                        return 1;
                    }
                }

            } elsif ($initChar eq 'p') {

                # It's a pause break. Check the supplied value is a valid number
                if (! $axmud::CLIENT->floatCheck($cmd, 0) || $cmd == 0) {

                    $session->writeWarning(
                        'Current mission\'s pause interval \'' . $cmd . '\' is invalid, using'
                        . ' a 10 second interval instead',
                        $self->_objClass . '->continueMission',
                    );

                    # Use 10 seconds as a default value
                    $cmd = 10;
                }

                # Create a timer that counts once, then deletes itself
                $timerObj = $session->createInterface(
                    'timer',
                    $cmd,       # A time interval
                    $self,
                    'timerSeen',
                    # Optional attributes
                    'count',
                    1,
                    'temporary',
                    1,
                );

                if (! $timerObj) {

                    $session->writeWarning(
                        'Current mission failed to create timer for the interval \'' . $cmd . '\''
                        . ' (using normal break instead)',
                        $self->_objClass . '->continueMission',
                    );

                    # Create a normal break instead
                    $self->ivPoke('breakType', 'break');
                    $self->ivPoke('timerName', $timerObj);
                    # Return 1 to show a break has been reached
                    return 1;

                } else {

                    $self->ivPoke('breakType', 'pause');
                    # Return 1 to show a break has been reached
                    return 1;
                }

            } elsif ($initChar eq 'l') {

                # It's a locator break
                if (! $session->locatorTask) {

                    # Don't create an ordinary break instead - it doesn't matter too much if we just
                    #   keep sending commands to the world
                    $session->writeWarning(
                        'Current mission\'s Locator break ignored - no Locator task running',
                        $self->_objClass . '->continueMission',
                    );

                } elsif (! $session->locatorTask->roomObj) {

                    # Likewise for this warning
                    $session->writeWarning(
                        'Current mission\'s Locator break ignored - the Locator task doesn\'t know'
                        . ' what the character\'s current location is',
                        $self->_objClass . '->continueMission',
                    );

                } else {

                    # Create the break
                    $self->ivPoke('breakType', 'locator');
                    # The Locator task's ->main function will call $self->taskReady when the task
                    #   isn't expecting any more room statements
                    # Return 1 to show a break has been reached
                    return 1;
                }

            } elsif ($initChar eq 'n' || $initChar eq 'w' || $initChar eq 'a') {

                # It's an instruction to send the character's name, password or associated account
                #   name (for missions being used as a login script)
                if ($session->loginFlag) {

                    $session->writeWarning(
                        'Current mission ignored a request to send the character\'s login details'
                        . ' to the world - character is already marked as \'logged in\'',
                        $self->_objClass . 'continueMission',
                    );

                    $self->completeMission($session);

                    return 2;

                } elsif ( ! $session->currentChar) {

                    $session->writeWarning(
                        'Current mission ignored a request to send the character\'s login details'
                        . ' to the world - no current character set',
                        $self->_objClass . 'continueMission',
                    );

                    $self->completeMission($session);

                    return 2;

                } else {

                    $pwd = $session->currentWorld->ivShow(
                        'passwordHash',
                        $session->currentChar->name,
                    );

                    $account = $session->currentWorld->ivShow(
                        'accountHash',
                        $session->currentChar->name,
                    );

                    if (! $pwd) {

                        # (If password not set, don't send any of the character's login details -
                        #   not the name, password or the associated account name)
                        $session->writeWarning(
                            'Current mission ignored a request to send the character\'s login'
                            . ' details to the world - no password set',
                            $self->_objClass . '->continueMission',
                        );

                        $self->completeMission($session);

                        return 2;

                    } elsif ($initChar eq 'a' && ! $account) {

                        # (If associated account not set but the mission wants to send it to the
                        #   world, we also have to end the mission here)
                        $session->writeWarning(
                            'Current mission ignored a request to send the character\'s associated'
                            . ' account name - no account name set',
                            $self->_objClass . '->continueMission',
                        );

                        $self->completeMission($session);

                        return 2;
                    }
                }

                if ($initChar eq 'n') {

                    # Send the character's name as a normal world command (and don't add the
                    #   command to the mission's previous command list)
                    $session->doInstruct($session->currentChar->name);

                } elsif ($initChar eq 'w') {

                    # Send the character's password as a normal world command, obfuscated in the
                    #   'main' window (and don't add the command to the mission's previous command
                    #   list)
                    $session->worldCmd($pwd, $pwd);

                } elsif ($initChar eq 'a') {

                    # Send the character's associated account name as a normal world command (and
                    #   don't add the command to the mission's previous command list)
                    $session->doInstruct($account);
                }

                # If the flag has been set, we don't send any more commands for now
                if ($singleFlag) {

                    return 1;
                }

            } elsif ($initChar eq 'c') {

                # It's an instruction which should be modified to substitute @name@, @password@ and
                #   @account@ for the current character's name and corresponding password and
                #   account name; the modified instruction is then sent as an ordinary world
                #   command (for missions being used as a login scrip)
                if ($session->loginFlag) {

                    $session->writeWarning(
                        'Current mission ignored a request to send the character\'s login details'
                        . ' to the world - character is already marked as \'logged in\'',
                        $self->_objClass . 'continueMission',
                    );

                    $self->completeMission($session);

                    return 2;

                } elsif ( ! $session->currentChar) {

                    $session->writeWarning(
                        'Current mission ignored a request to send the character\'s login details'
                        . ' to the world - no current character set',
                        $self->_objClass . 'continueMission',
                    );

                    $self->completeMission($session);

                    return 2;
                }

                # For convenience, import the current character's name and corresponding password
                #   and corresponding account name
                $name = $session->currentChar->name;

                $pwd = $session->currentWorld->ivShow(
                    'passwordHash',
                    $name,
                );

                $account = $session->currentWorld->ivShow(
                    'accountHash',
                    $name,
                );

                # Substitute @name@
                $cmd =~ s/\@name\@/$name/;

                # Substitute @password@
                if ($cmd =~ m/\@password\@/) {

                    if (! defined $pwd) {

                        $session->writeWarning(
                            'Current mission ignored a request to send the character\'s password'
                            . ' to the world - no password set',
                            $self->_objClass . 'continueMission',
                        );

                        $self->completeMission($session);

                        return 2;

                    } else {

                        $cmd =~ s/\@password\@/$pwd/;
                        $pwdFlag = TRUE;
                    }
                }

                # Substitute @account@
                if ($cmd =~ m/\@account\@/) {

                    if (! defined $account) {

                        $session->writeWarning(
                            'Current mission ignored a request to send the character\'s account'
                            . ' name to the world - no account name set',
                            $self->_objClass . 'continueMission',
                        );

                        $self->completeMission($session);

                        return 2;

                    } else {

                        $cmd =~ s/\@account\@/$account/;
                    }
                }

                # Send the world command
                if ($pwdFlag) {

                    # Send the command, which contains a password, as a normal world command,
                    #   obfuscated in the 'main' window (and don't add the command to the mission's
                    #   previous command list)
                    $session->worldCmd($cmd, $cmd);

                } else {

                    # Send the character's login details as a normal world command (and don't add
                    #   the command to the mission's previous command list)
                    $session->doInstruct($cmd);
                }

                # If the flag has been set, we don't send any more commands for now
                if ($singleFlag) {

                    return 1;
                }

            } else {

                # Ignore the invalid command; show a warning, then move on to the next string
                $session->writeWarning(
                    'Current mission ignored an invalid string: \'' . $string . '\'',
                    $self->_objClass . '->continueMission',
                );
            }
        }
    }

    sub completeMission {

        # Called by several stages of $self->continueMission
        # Shows a confirmation messages, resets IVs and updates the GA::Session IV
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->completeMission', @_);
        }

        # Abuse $self->displayComment to show a confirmation message
        if (! $self->quietFlag) {

            $self->displayComment($session, 'Mission complete');
        }

        # Update our own temporary IVs
        $self->resetMission();
        # Update the GA::Session's IV
        $session->reset_currentMission();

        return 1;
    }

    sub resetMission {

        # Called by $self->startMission or ->completeMission
        # Resets all the IVs used when a GA::Session is running a mission
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetMission', @_);
        }

        $self->ivPoke('quietFlag', FALSE);
        $self->ivEmpty('currentList');
        $self->ivPoke('nextString', 0);
        $self->ivUndef('prevComment');
        $self->ivEmpty('prevCmdList');
        $self->ivUndef('breakType');
        $self->ivUndef('triggerName');
        $self->ivUndef('timerName');

        return 1;
    }

    sub displayComment {

        # Called by $self->continueMission and GA::Cmd::RepeatComment
        # Shows a comment in the 'main' window
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $comment    - The comment to show
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $comment, $check) = @_;

        # Check for improper arguments
        if (! defined $session || ! defined $comment || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->displayComment', @_);
        }

        $session->writeText(
            'MISSION: \'' . $self->name . '\' (step ' . $self->nextString . ')',
        );

        $session->writeText($comment);

        return 1;
    }

    sub taskReady {

        # Called by GA::Task::Locator->processLine while the mission is on a Locator break, whenever
        #   the task notices that there are no more room statements expected (i.e. the character has
        #   arrived at their intended destination)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->taskReady', @_);
        }

        # Reset the mission's IVs
        $self->ivUndef('breakType');

        # Send the next group of commands, and return the result ('undef', 1 or 2)
        return ($self->continueMission($session));
    }

    sub statusTaskChange {

        # Called by GA::Task::Status->deadSeen, ->passedOutSeen or ->asleepSeen when the character
        #   dies, passes out or falls asleep
        # Terminates the current mission
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $status         - The Status task's new ->lifeStatus IV: 'sleep', 'passout' or
        #                       'dead' (if it's 'alive', this function does nothing)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $status, $check) = @_;

        # Local variables
        my $comment;

        # Check for improper arguments
        if (
            ! defined $session || ! defined $status
            || (
                $status ne 'alive' && $status ne 'sleep' && $status ne 'passout'
                && $status ne 'dead'
            ) || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->statusTaskChange', @_);
        }

        if ($status eq 'alive') {

            # Do nothing
            return 1;

        } else {

            $comment = 'Mission terminated because character has ';
            if ($status eq 'sleep') {
                $comment .= 'fallen asleep';
            } elsif ($status eq 'passout') {
                $comment .= 'passed out';
            } elsif ($status eq 'dead') {
                $comment .= 'died';
            }

            $self->displayComment($session, $comment);
            $session->reset_currentMission();

            return 1;
        }
    }

    # Response methods

    sub triggerSeen {

        # Called by GA::Session->checkTriggers, while on a trigger break, after the trigger created
        #   by $self->continueMission fires
        #
        # Expected arguments (standard args from GA::Session->checkTriggers)
        #   $session        - The calling function's GA::Session
        #   $interfaceNum   - The number of the active trigger interface that fired
        #   $line           - The line of text received from the world
        #   $stripLine      - $line, with all escape sequences removed
        #   $modLine        - $stripLine, possibly modified by previously-checked triggers
        #   $backRefListRef - Reference to a list of backreferences from the pattern match
        #                       (equivalent of @_)
        #   $matchMinusListRef
        #                   - Reference to a list of matched substring offsets (equivalent of @-)
        #   $matchPlusListRef
        #                   - Reference to a list of matched substring offsets (equivalent of @+)
        #
        # Return values
        #   'undef' on improper arguments, or if $session is the wrong session, or if the interface
        #       object can't be found
        #   Otherwise returns the result of the call to $self->continueMission ('undef', 1 or 2)

        my (
            $self, $session, $interfaceNum, $line, $stripLine, $modLine, $backRefListRef,
            $matchMinusListRef, $matchPlusListRef, $check,
        ) = @_;

        # Local variables
        my $obj;

        # Check for improper arguments
        if (
            ! defined $session || ! defined $interfaceNum || ! defined $line || ! defined $stripLine
            || ! defined $modLine || ! defined $backRefListRef || ! defined $matchMinusListRef
            || ! defined $matchPlusListRef || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->triggerSeen', @_);
        }

        # Get the interface object itself
        $obj = $session->ivShow('interfaceNumHash', $interfaceNum);
        if (! $obj) {

            return undef;
        }

        # Respond to the fired trigger

        # The trigger must only fire once, so mark the trigger to be deleted (it is first disabled,
        #   then deleted at the start of the next task loop)
        $session->deleteInterface($obj->name);

        # Reset the mission's IVs
        $self->ivUndef('triggerName');
        $self->ivUndef('breakType');

        # Send the next group of commands, and return the result ('undef', 1 or 2)
        return $self->continueMission($session);
    }

    sub timerSeen {

        # Called by GA::Session->checkTimers, while on a pause break, after the timer created by
        #   $self->continueMission fires
        #
        # Expected arguments (standard args from GA::Session->checkTimers)
        #   $session        - The calling function's GA::Session
        #   $interfaceNum   - The number of the active timer interface that fired
        #   $dueTime        - The time (matches GA::Session->sessionTime) at which the timer was due
        #                       to fire, in seconds
        #   $actualTime     - The time (matches GA::Session->sessionTime) at which the timer
        #                       actually fired, in seconds
        #
        # Return values
        #   'undef' on improper arguments, or if $session is the wrong session, or if the interface
        #       object can't be found
        #   Otherwise returns the result of the call to $self->continueMission ('undef', 1 or 2)

        my ($self, $session, $interfaceNum, $dueTime, $actualTime, $check) = @_;

        # Local variables
        my $obj;

        # Check for improper arguments
        if (
            ! defined $session || ! defined $interfaceNum || ! defined $dueTime
            || ! defined $actualTime || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->timerSeen', @_);
        }

        # Get the interface object itself
        $obj = $session->ivShow('interfaceNumHash', $interfaceNum);
        if (! $obj) {

            return undef;
        }

        # Respond to the fired timer

        # Reset the mission's IVs (the timer was marked as 'temporary' when it was created, so it
        #   will only fire once)
        $self->ivUndef('timerName');
        $self->ivUndef('breakType');

        # Send the next group of commands, and return the result ('undef', 1 or 2)
        return ($self->continueMission($session));
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }
    sub descrip
        { $_[0]->{descrip} }

    sub missionList
        { my $self = shift; return @{$self->{missionList}}; }

    sub quietFlag
        { $_[0]->{quietFlag} }

    sub currentList
        { my $self = shift; return @{$self->{currentList}}; }
    sub nextString
        { $_[0]->{nextString} }

    sub prevComment
        { $_[0]->{previousComment} }
    sub prevCmdList
        { my $self = shift; return @{$self->{prevCmdList}}; }

    sub breakType
        { $_[0]->{breakType} }
    sub triggerName
        { $_[0]->{triggerName} }
    sub timerName
        { $_[0]->{timerName} }
}

# Package must return true
1
