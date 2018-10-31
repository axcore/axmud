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
# Games::Axmud::Profile::XXX
# The code that handles a profile

{ package Games::Axmud::Profile::World;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Profile Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by any function
        # Creates a new instance of the world profile
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $name       - A unique string name for this profile (max 16 chars, containing
        #                   A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable.
        #                   Must not exist as a key in the global hash of reserved names,
        #                   $axmud::CLIENT->constReservedHash)
        #
        # Optional arguments
        #   $tempFlag   - If set to TRUE, this is a temporary profile created for use with an 'edit'
        #                   window; $name is not checked for validity. Otherwise set to FALSE (or
        #                   'undef')
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $tempFlag, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $session || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        if (! $tempFlag) {

            # Check that $name is valid and not already in use by another profile
            if (! $axmud::CLIENT->nameCheck($name, 16)) {

                return $axmud::CLIENT->writeError(
                    'Registry naming error: invalid name \'' . $name . '\'',
                    $class . '->new',
                );

            } elsif ($axmud::CLIENT->ivExists('worldProfHash', $name)) {

                return $axmud::CLIENT->writeError(
                    'Registry naming error: profile \'' . $name . '\' already exists',
                    $class . '->new',
                );
            }
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => $name,
            _parentWorld                => undef,
            _privFlag                   => FALSE,       # All IVs are public

            # Standard profile IVs
            # --------------------

            name                        => $name,
            category                    => 'world',
            # The name of associated world profile (world profiles don't have a parent world)
            parentWorld                 => undef,

            # Hash of tasks that start whenever this profile is made a current profile (as soon as
            #   the character is marked as 'logged in') - the profile's initial tasklist. Hash in
            #   the form
            #       $initTaskHash{unique_task_name} = blessed_reference_to_task_object
            initTaskHash                => {},
            # The order in which the tasks are started (not very important for tasks unless they
            #   are Script tasks). List contains all the keys in $self->initTaskHash
            initTaskOrderList           => [],
            # How many initial tasks have been created, in total (used to give each one a unique
            #   name). Reset to 0 when the profile's initial tasklist is emptied
            initTaskTotal               => 0,
            # Hash of scripts that start whenever this definiton is made a current profile (as soon
            #   as the character is marked as 'logged in') - the profile's initial scriptlist. Hash
            #   in the form
            #       $initScriptHash{script_name} = mode
            # ...where 'script_name' matches the file from which the script is loaded, and 'mode' is
            #   set to one of the following value:
            #       'no_task'       - run the script without a task
            #       'run_task'      - run the script from within a task
            #       'run_task_win'  - run the script from within a task, in 'forced window' mode
            initScriptHash              => {},
            # The order in which the scripts are started. List contains all the keys in
            #   $self->initScriptHash
            initScriptOrderList         => [],
            # The name of the mission to start whenever a new session begins with this as a current
            #   profile, as soon as the character is marked as logged in - but NOT when a current
            #   profile is set after the login
            # Profiles are checked in priority order; only the first mission found is run. Set to
            #   the name of the mission, or 'undef'
            initMission                 => undef,
            # A list of commands to execute, as if the user had typed them in the 'main' window's
            #   command entry box, whenever a new session begins with this as a current profile,
            #   as soon as the character is marked as logged in - but NOT when a current profile
            #   is set after the login
            # Profiles are checked in priority order; commands are sent from all profiles, but
            #   duplicate commands are not sent
            # Commands are sent AFTER the commands specified by the current world profile's
            #   ->columns, ->rows and ->sendSizeInfoFlag IVs (so this list doesn't need to include
            #   them)
            initCmdList                 => [],

            # Flag set to TRUE if this profile has EVER been a current profile (in which case, it
            #   will have cages etc); set to FALSE if not (in which case, the parent file object
            #   will set up cages etc when this profile first becomes a current profile)
            # NB The flag will be TRUE for all pre-configured worlds, as the code that creates them
            #   also creates cages for each world
            setupCompleteFlag           => FALSE,
            # List containing notes written by this user for this profile, and available to the
            #   Notepad task when it's running
            notepadList                 => [],
            # A hash to store any data your own plugins/scripts want to store (when a profile is
            #   cloned, this data is not copied to the clone)
            privateHash                 => {},

            # World profile IVs
            # -----------------

            # A flag set to TRUE if this profile's 'worldprof' file, and its associated 'otherprof'
            #   and 'worldmodel' files, should not be saved (set to FALSE otherwise)
            # Used when the Connections window starts a new session for which the user hasn't
            #   specified a world name; setting this flag to TRUE effectively makes the profile
            #   temporary
            noSaveFlag                  => FALSE,
            # A list of GA::Obj::ConnectHistory objects, storing details about every connection to
            #   this world (but only when GA::Client->connectHistoryFlag is TRUE). The first object
            #   in the list is for the earliest connection, the last object, the most recent (or
            #   current) connection
            connectHistoryList          => [],

            # A hash of key-value pairs that can be be set for any world which, for one reason or
            #   another, must not use certain telnet options/protocols
            # The key is a string representing a telnet option or protocol (e.g. 'naws' or 'mxp').
            #   It matches an argument recognised by GA::Client->toggle_telnetOption or
            #   GA::Client->toggle_mudProtocol. The corresponding value is always 'undef'
            # If the key exists in the hash, the session won't use that option/protocol, regardless
            #   of the value of the corresponding GA::Client IVs (->useNawsFlag and ->useMxpFlag, in
            #   the examples above)
            # NB This hash is only consulted by code in GA::Session. All other Axmud code uses the
            #   original GA::Client IVs
            telnetOverrideHash          => {
#               # Telnet options
#               'echo'                  => undef,           # GA::Client->useEchoFlag
#               'sga'                   => undef,           # GA::Client->useSgaFlag
#               'ttype'                 => undef,           # GA::Client->useTTypeFlag
#               'eor'                   => undef,           # GA::Client->useEorFlag
#               'naws'                  => undef,           # GA::Client->useNawsFlag
#               'new_environ'           => undef,           # GA::Client->useNewEnvironFlag
#               'charset'               => undef,           # GA::Client->useCharSetFlag
#               # Telnet protocols
#               'msdp'                  => undef,           # GA::Client->useMsdpFlag
#               'mssp'                  => undef,           # GA::Client->useMsspFlag
#               'mccp'                  => undef,           # GA::Client->useMccpFlag
#               'msp'                   => undef,           # GA::Client->useMspFlag
#               'mxp'                   => undef,           # GA::Client->useMxpFlag
#               'pueblo'                => undef,           # GA::Client->usePuebloFlag
#               'zmp'                   => undef,           # GA::Client->useZmpFlag
#               'aard102'               => undef,           # GA::Client->useAard102Flag
#               'atcp'                  => undef,           # GA::Client->useAtcpFlag
#               'gmcp'                  => undef,           # GA::Client->useGmcpFlag
#               'mtts'                  => undef,           # GA::Client->useMttsFlag
#               'mcp'                   => undef,           # GA::Client->useMcpFlag
            },
            # A hash which overrides the values of certain GA::Client flags related to MXP
            #   permissions
            # The key is a string representing a permission (e.g. 'room'). It matches an
            #   argument recognised by GA::Client->set_allowMxpFlag
            # If the key doesn't exist in the hash, the session uses the value of the GA::Client IV.
            #   If the key exists in the hash, the session uses the key's corresponding value
            #   instead. The corresponding value should be TRUE or FALSE
            # NB This hash is only consulted by code in GA::Session (the 'room' key is consulted by
            #   code in the Locator task). All other Axmud code uses the original GA::Client IVs
            mxpOverrideHash             => {
#               'room'                  => TRUE,            # GA::Client->allowMxpRoomFlag
            },
            # A hash which overrides the values of GA::Client->termTypeMode, ->customClientName,
            #   ->customClientVersion, ->useCtrlSeqFlag, ->useVisibleCursorFlag and
            #   ->useDirectKeysFlag
            # The key has the same name as the GA::Client IV. If the key doesn't exist in the hash,
            #   the session uses the value of the GA::Client IV. If the key exists in the hash, the
            #   session uses the key's corresponding value instead. The corresponding value should
            #   match one of the acceptable values of the GA::Client IV
            # NB This hash is only consulted by code in GA::Session. All other Axmud code uses the
            #   original GA::Client IVs
            termOverrideHash            => {
#               'termTypeMode'          => 'send_client',   # GA::Client->termTypeMode
#               'customClientName'      => '',              # GA::Client->customClientName
#               'customClientVersion'   => '',              # GA::Client->customClientVersion
#               'useCtrlSeqFlag'        => TRUE,            # GA::Client->useCtrlSeqFlag
#               'useVisibleCursorFlag'  => FALSE,           # GA::Client->useVisibleCursorFlag
#               'useDirectKeysFlag'     => FALSE,           # GA::Client->useDirectKeysFlag
            },
            # A hash which overrides the values of GA::Client->echoSigilFlag, ->perlSigilFlag,
            #   ->scriptSigilFlag and ->multiSigilFlag
            # The key is one of the strings 'echo', 'perl', 'script', 'multi' or 'bypass'. If the
            #   key doesn't exist in the hash, the session uses the value of the GA::Client IV. If
            #   the key exists in the hash, the session uses the key's corresponding value instead.
            #   The corresponding value should be TRUE or FALSE
            # NB This hash is only consulted by code in GA::Session. All other Axmud code uses the
            #   original GA::Client IVs
            sigilOverrideHash           => {
#               'echo'                  => TRUE,            # GA::Client->echoSigilFlag
#               'perl'                  => TRUE,            # GA::Client->perlSigilFlag
#               'script'                => TRUE,            # GA::Client->scriptSigilFlag
#               'multi'                 => TRUE,            # GA::Client->multiSigilFlag
#               'speed'                 => TRUE,            # GA::Client->speedSigilFlag
#               'bypass'                => TRUE,            # GA::Client->bypassSigilFlag
            },

            # A hash containing all the profiles associated with this world, in the form
            #   $profHash{profile_name} = profile_category
            # NB Includes an entry for this world profile, i.e.
            #   $profHash{this_profile_name} = 'world'
            profHash                    => {
                $name                   => 'world',
            },
            # A hash containing characters and their passwords (if known), in the form
            #   $passwordHash{char_profile_name} = password
            #   $passwordHash{char_profile_name} = 'undef'      (if password not known)
            passwordHash                => {},
            # The Connections window enables the user to add new characters to the profile, and to
            #   edit the password of existing characters. In both cases, a new entry is made to this
            #   hash; when the profile next becomes a current profile, GA::Session->setupProfiles
            #   creates the characters and/or updates passwords. Hash in the form
            #       $newPasswordHash{char_profile_name} = password
            #       $newPasswordHash{char_profile_name} = 'undef'   (if password not known)
            newPasswordHash             => {},
            # For worlds that have separate account/character names, a hash of matching account and
            #   character names, in the form
            #       $accountHash{char_profile_name} = account_name
            #       $accountHash{char_profile_name} = 'undef'       (if no separate account name)
            accountHash                 => {},
            # Connections window enables user to set the account name in the same way. Hash in the
            #   form
            #       $newAccountHash{char_profile_name} = account_name
            #       $newAccountHash{char_profile_name} = 'undef'    (if no separate account name)
            newAccountHash              => {},

            # The connection protocol to use: 'telnet', 'ssh' or 'ssl'
            protocol                    => 'telnet',

            # Connection details. If specified, ->ipv6 is used. Otherwise if specified, ->ipv4 is
            #   used. Otherwise, ->dns is used. If none are specified, '127.0.0.1' is used
            dns                         => undef,
            ipv4                        => undef,
            ipv6                        => undef,
            port                        => 23,
            # SSH connection details (if the username is not set, the GA::Session prompts the user
            #   for a password on every connection, and if the user doesn't provide one, reverts to
            #   a telnet connection)
            sshUserName                 => undef,
            sshPassword                 => undef,
            # Flag set to TRUE if $self->port should be specified in the SSH connection; FALSE if it
            #   should be omitted
            sshPortFlag                 => FALSE,

            # Previous connection details
            lastConnectDate             => undef,
            lastConnectTime             => undef,
            numberConnects              => 0,
            lastConnectChar             => undef,

            # The world's long name (if any; suggested max length of 32)
            longName                    => undef,
            # Flag set to TRUE if the world contains overt adult (sexual) themes, FALSE if not.
            #   This IV doesn't appear in the profile's edit window, so is usually only TRUE if the
            #   pre-configured world (or basic mudlist) specifies it
            adultFlag                   => FALSE,
            # URL of the world's own website ('undef' if unknown)
            worldURL                    => undef,
            # URL of the world's entry on a referrer website (can be any, but www.mudstats.com is
            #   used by default; 'undef' if unknown)
            referURL                    => undef,
            # Short description of the world (use newline characters, if required; 'undef' if no
            #   description known)
            worldDescrip                => undef,
            # Short hint message for this world, shown on first connection and again if the user
            #   types the ';hint' command. Typically used to warn users about which world commands
            #   must be sent, before the automapper can work, etc etc. Newline characters are not
            #   required. Set to 'undef' if no hint is needed
            worldHint                   => undef,
            # Which character set to use with this world. If set, should be one of the characters
            #   sets provided by Perl's Encode module (and stored in GA::Client->charSetList); if
            #   set to 'undef', GA::Client->charSet is used as the character set
            worldCharSet                => undef,

            # The terminal type to use for this world. If set, it is sent to the world when the
            #   server requests a terminal type. If an empty string (or 'undef'), Axmud decides
            #   which terminal type to send, based on the GA::Client->termTypeMode,
            #   ->customClientName and ->customClientVersion
            termType                    => undef,
            # The terminal size to use for this world ('undef' if not set)
            columns                     => 0,           # e.g. 100
            rows                        => 0,           # e.g. 50
            # If the flag is TRUE, ->termType, ->columns and ->rows are sent to the world manually
            #   (and NAWS is not used in this session) after logging in. If set to FALSE, they
            #   aren't sent, and NAWS can be used (if the GA::Client flag allows it)
            sendSizeInfoFlag            => FALSE,

            # MSSP data collected from this world (if any, containing only generic variables). Hash
            #   in the form
            #       $msspGenericValueHash{variable} = value
            msspGenericValueHash        => {},
            # MSSP data collected from this world (if any, containing only custom variables)
            msspCustomValueHash         => {},

            # Automatic login mode. Axmud needs to know when the character has logged in; the
            #   GA::Session->loginFlag is set to TRUE at this point
            # Axmud can perform an automatic login, if allowed. The following IV specifies which
            #   kind of login to perform when this world profile is the current world profile. The
            #   mode can be any of the following values:
            #       'none' - No automatic login (user must use the ;lgn command)
            #       'immediate' - Immediate login (character marked as 'logged in' immediately - not
            #           recommended, as tasks like the Locator task will start looking for room
            #           statements in the world's introductory text)
            #       'lp' - LP/Diku/AberMUD login (consecutive prompts for character/password)
            #       'tiny' - TinyMUD login (send 'connect char pass' after a line of text containing
            #           the word 'connect' is received. Actually, the current command cage's
            #           'connect' command is used, so the actual command sent might be different)
            #       'world_cmd' - Send a sequence of world commands at the first prompt. Any command
            #           which contains '@name@' is substituted for the character's name, any command
            #           which contains '@account@' is substituted for the account name, and any
            #           command which contains '@password@' is substituted for the character's
            #           password (if not set, removed altogether). Any of them that are not set are
            #           substituted for an empty string. NB If $self->loginConnectPatternList is
            #           set, we wait for one of those patterns, rather than waiting for the first
            #           prompt
            #       'telnet' - Basic telnet login (e.g. 'login:' 'password:')
            #       'task' - Run a task (character is logged if the task calls GA::Session->doLogin)
            #       'script_task' - Run an Axbasic script from within a task (character is logged in
            #           if the script executes a LOGIN statement)
            #       'script' - Run an Axbasic script (character is logged in if the script executes
            #           a LOGIN statement)
            #       'mission' - Start a mission (character is logged in if the mission uses the
            #           ';login' client command)
            loginMode                   => 'none',
            # For login mode 'world_cmd', the sequence of world commands to send. Commands
            #   containing '@name@', '@account@' and '@password@' are substituted
            loginCmdList                => [],
            # For login modes 'task', 'script_task', 'script', 'mission', the name of the task
            #   (formal name or task label), script or mission to start
            loginObjName                => undef,
            # For login mode 'tiny', a list of patterns matching the line which mean we should send
            #   the connect command
            # For login mode 'world_cmd', a list of patterns matching the line which mean we should
            #   send the list of (substituted) world commands. If this list is empty, we wait for
            #   the first prompt before sending them, instead
            loginConnectPatternList     => [
                'connect',
            ],
            # Login success pattern list - used in login modes 'lp', 'tiny', 'world_cmd', 'telnet'
            #   and 'mission'
            # In modes  'lp', 'tiny', 'world_cmd' and 'telnet', if the list is empty, the automatic
            #   login is completed as soon as a response to the world's prompt(s) has been sent
            # In mode 'mission', the automatic login is normally completed when the mission
            #   finishes, but is completed early if a line matching one of these patterns is
            #   received
            loginSuccessPatternList     => [],
            # Login account mode - whether an account name is needed to login to this world, as well
            #   as the usual character name/password. The setting of this IV affects text displayed
            #   in the Connections window, so its value doesn't really matter. Specifically, it does
            #   not affect the automatic login process (using the IVs just above) at all
            # 'unknown' - not known if user must login with an account name, 'not_required' -
            #   account name not required, 'required' - account name required
            loginAccountMode            => 'unknown',
            # Some worlds force the user to type a character from a list; often the user must type
            #   1 for the first listed character, 2 for the second one, and so on
            # A collection of patterns to take care of this situation. A list in groups of three;
            #   the first item is a pattern which should match the line containing the character's
            #   name and usually uses one or more group substrings. The second item is the number of
            #   the group substring containing the character name (can be set if multiple character
            #   names appear on the same line; set to 0 if only one character name appears per
            #   matching line). The third item is the command to send to the world, and should
            #   usually contain a group substring variable like $1
            #
            #       e.g.     Choose a character
            #                1. Gandalf
            #                2. Bilbo
            #
            #       In this case, the pattern to use would be '(\d)\.\s(.*)'
            #       Characters appear on their own line, so we can use the group substring number 0
            #       The corresponding world command to use would be simply '$1' - above, the
            #           number 1 or 2
            #
            #       e.g.    1. Gandalf 2. Bilbo
            #
            #       In this case, the pattern to use might be '(\d)\.\s(.*)\s(\d)\.\s(.*)',
            #           the group substring number would be 1, and the world command would be '$1'
            #       We'd then add a second identical pattern to the list, together with the
            #           group substring number 2 and the world command '$2'
            #
            # If this list is empty, it is ignored. If $self->loginMode is not 'mission', it is
            #   ignored
            # If this list is set, GA::Session checks ever incoming line of text (complete, or not)
            #   for patterns that match the current character's name (case-insensitively). If there
            #   are any lines that match the name and also match one of the patterns in the list
            #   (case-insensitively), the corresponding world command is sent, and the GA::Session
            #   stops checking incoming lines. If a login takes place for any reason (via a call to
            #   GA::Session->doLogin), the GA::Session stops checking incoming lines
            # This IV is used with a login mission ($self->loginMode is 'mission', and
            #   $self->loginObjName is set to the name of the GA::Obj::Mission). Typically, the
            #   contents of the mission should look like this:
            #       't Your account',               (Wait for this prompt)
            #       'a',                            (Send account name)
            #       't Password',                   (Wait for this prompt)
            #       'w',                            (Send password)
            #           ... we now wait for GA::Session to choose a character...
            #       't Welcome back to DeathMud',   (This line seen after the character is chosen)
            #       ';login',                       (Mark the character as logged in)
            # List (groups of 3)
            #   0 - the pattern matching a line containing the character's name (because a
            #           perl substitution will be performed, it must match the whole line - begin
            #           and/or end the pattern with '.*' if necessary
            #   1-  the number of the group substring that contains the character's name; can be set
            #           to 0 if only one character name appears per line
            #   2 - the world command to send, usually including a group substring variable, e.g. $1
            loginSpecialList            => [],

            # Automatic quit mode. Users can disconnect from many worlds by sending some kind of
            #   'quit' world command, but at other worlds, it's not so simple. These IVs are used
            #   only when the user types ';quit', ';qquit' or ';quitall'. They are ignored if the
            #   user simply types some kind of 'quit' world command, or if a connection to a world
            #   is terminated remotely.
            #       'normal' - Send the standard 'quit' world command, as defined by the current
            #           highest-priority command cage
            #       'world_cmd' - Send a sequence of world commands
            #       'task' - Run a task (the task is responsible for sending a 'quit' world command)
            #       'task_script' - Run an Axbasic script from within a task (the script is
            #           responsible for sending a 'quit' world command)
            #       'script' - Run an Axbasic script (the script is responsible for sending a 'quit'
            #           world command)
            #       'mission' - Start a mission (the mission is responsible for sending a 'quit'
            #           world command)
            autoQuitMode                => 'normal',
            # For quit mode 'world_cmd', the sequence of commands to send. (Unlike
            #   $self->loginCmdList, no substitutions take place.) If the list is empty, Axmud
            #   reverts to quit mode 'normal'
            autoQuitCmdList             => [],
            # For quit modes 'task', 'task_script', 'script' and 'mission', the name of the task
            #   (formal name or task label), script or mission to start. If an empty string or
            #   'undef', Axmud reverts to quit mode 'normal'
            autoQuitObjName             => undef,

            # If set to FALSE, the world can be sent a string containing multiple commands
            #   (separated by command separators, e.g. 'n;n;w')
            # If set to TRUE, Axmud must send each command separately
            autoSeparateCmdFlag         => TRUE,
            # Slowwalking IVs (implemented by GA::Session as 'excess commands')
            # Some worlds enforce a maximum number of commands per second (or maximum number of
            #   commands per fraction of a second)
            # If this variable is set, commands are counted as they are sent. When the maximum is
            #   reached, further commands are stored temporarily. If this value is set to 0, no
            #   maximum is used; all commands are sent immediately
            excessCmdLimit              => 0,
            # The time period (in seconds) to wait before sending stored commands. The value 1
            #   means 'wait 1 seconds before sending the next batch of commands). The minimum value
            #   (in case this IV is set to 0) is the same as GA::Session->sessionLoopDelay
            excessCmdDelay              => 1,
            # Some worlds don't explicitly state when a dead character is resurrected. If this flag
            #   is set to TRUE, the Status task will change the character's ->lifeStatus to 'alive'
            #   whenever one of the triggers which detect the current health points (etc) fires, if
            #   the character is dead, asleep or passed out. Otherwise, the Status task will wait
            #   for an explicit regenerated, come around or woken up trigger to fire.
            lifeStatusOverrideFlag      => FALSE,

            # Command prompt patterns - a list of patterns which match the world's command prompts.
            #   Any received packet of text (comprising one or more lines, split by newline
            #   characters) is tested against these patterns, before anything else is done. If any
            #   of the patterns match, a newline character is inserted immediately after the match -
            #   UNLESS the matching text is already followed by a newline character, or occurs at
            #   the end of the packet
            # The text is tested BEFORE being matched against triggers
            # NB The Session code assumes that each pattern matches the WHOLE of the prompt, so it
            #   should definitely contain an initial ^ character, but not a final $ character
            cmdPromptPatternList        => [],
            # 'Strict prompts' mode, for worlds that don't use EOR or IAC GA to show a prompt. When
            #   a line is received in two or more pieces - perhaps separated by some fractions of a
            #   second - trigger patterns that are supposed to match the whole line are tested
            #   against each piece, and therefore don't match
            # When this flag is TRUE, 'Strict prompts' mode is in force. The Session only
            #   recognises prompts which match (the whole of) one of the patterns in
            #   $self->cmdPromptPatternList; everything else is assumed to be part of a line which
            #   hasn't been fully received yet (the text is not processed until the rest of the
            #   line is received). If TRUE, ->cmdPromptPatternList should contain the initial
            #   'Enter your name' and 'Enter your password' prompts, as well as the usual '> '
            #   prompt
            # When this flag is FALSE, a line that doesn't end in a with a newline character (or
            #   is terminated with EOR or IAC GA) is processed (and displayed) immediately; it can
            #   be marked as a prompt some fractions of a second later, if no text is received
            # Strict prompts mode is not applied when $self->specialEchoMode is 'enabled' (because
            #   if world commands are sent to the world, one character at a time, and then echoed
            #   back to us, the patterns in $self->cmdPromptPatternList won't recognise them as
            #   valid prompts)
            strictPromptsMode           => FALSE,
            # Empty line suppression. If set to 0, no empty lines are suppressed. If set to 1, all
            #   empty lines are suppressed. If set to n (where n > 1), all consecutive lines from
            #   n onwards are suppressed (e.g. n = 3, 2 consecutive empty lines are preserved, all
            #   further consecutive empty lines are suppressed)
            suppressEmptyLineCount      => 0,
            # Flag set to TRUE if empty line suppression should only be applied after the character
            #   is marked as logged in (preserving the world's initial ASCII art, if present); set
            #   to FALSE if empty line suppression should be applied immediately
            suppressBeforeLoginFlag     => FALSE,

            # The name of the dictionary used by this world (the dictionary often has the same name
            #   as the world). Set to 'undef' until a dictionary is created for it
            dict                        => undef,
            # If this flag is TRUE, the Locator task will collect unknown words (words which appear
            #   in room statements, but which aren't in our dictionary), in order to provide a
            #   convenient list of words that could be added to the dictionary
            collectUnknownWordFlag      => FALSE,
            # If this flag is TRUE, the Locator task will collect all contents lines, without
            #   splitting the line into objects, and store them in the dictionary (this flag isn't
            #   affected by the setting of $self->collectUnknownWordFlag; both that flag and this
            #   one can be set to TRUE)
            collectContentsFlag         => FALSE,
            # Flag set to TRUE if objects in the same room and with the same name (e.g. two orcs)
            #   can be identified as 'orc 1' and 'orc 2' in commands sent to the world
            numberedObjFlag             => TRUE,    # 'orc 1' and 'orc 2' possible on DS
            # In worlds which specify multiples in contents lines like this:
            #   (2) A big axe
            # ...a pattern which matches the portion '(2)'
            # The pattern must contain a group substring. The first group substring is used as the
            #   multiple (other group substrings are ignored). In the example above, we would use
            #   the pattern '\((\d+)\)'
            # Ignored if set to 'undef' (or an empty string). A matching pattern is NOT used as the
            #   multiple if the group substring does not contain a positive integer (1 is
            #   acceptable, but 0 is not)
            multiplePattern             => undef,

            # Logging preferences for this world. The default settings are stored in
            #   GA::Client->constSessionLogPrefHash; the current settings are stored here. Hash in
            #   the form
            #       $logPrefHash{log_file_type} = TRUE or FALSE
            logPrefHash                 => {},      # Set below

            # The unit for counting the character's age. It matches one of the keys in the current
            #   dictionary's ->timeHash and ->timePluralHash IVs, which are the same in every
            #   language; so the value of this IV *must* be one of the English words 'second',
            #   'minute', 'hour', 'day', 'week', 'month', 'year', 'decade', 'century' or
            #   'millennium' (or 'undef' if the age unit isn't known, or not used)
            charAgeUnit                 => 'day',
            # The unit in which the world weighs things (can be set to any word, of 'undef' if the
            #   unit is unknown, or not used)
            weightUnit                  => undef,
            # Strings representing the weight unit e.g. ('kilogram', 'kilo', 'kg', 'kilograms',
            #   'kilos', 'kg')
            # This list should contain abbreviations and plurals of the unit represented by
            #   ->weightUnit (If ->weightUnit is 'undef', should be an empty list)
            weightUnitStringList        => [],

            # Dark room pattern groups (take the place of a room statement) (groups of 1)
            #   [0]     - the pattern to match
            darkRoomPatternList         => [],
            # Failed exit pattern groups (groups of 1)
            #   [0]     - the pattern to match
            failExitPatternList         => [],
            # Closed door pattern groups (groups of 1)
            #   [0]     - the pattern (regex) to match
            doorPatternList             => [],
            # Locked door pattern groups (groups of 1)
            #   [0]     - the pattern to match
            lockedPatternList           => [],
            # Involuntary exit patterns (groups of 1)
            #   [0]     - the pattern to match
            involuntaryExitPatternList  => [],
            # Unspecified room pattern groups (tell us that the character has arrived in a new room,
            #   but the room statement won't be displayed) (groups of 1)
            #   [0]     - the pattern to match
            unspecifiedRoomPatternList  => [],
            # Follow exit patterns, used when 'You follow Gandalf north' moves the character to a
            #   new room, and when the world sends a new room statement (groups of 2)
            #   [0]     - the pattern to match
            #   [1]     - the number of the group substring containing the direction
            followPatternList           => [],
            # Follow anchor patterns, used when 'You follow Gandalf north' moves the character to a
            #   new room, but when the world doesn't send a new room statement (so the line
            #   matching the pattern must act as an anchor line) (groups of 2)
            #   [0]     - the pattern to match
            #   [1]     - the number of the group substring containing the direction
            followAnchorPatternList     => [],
            # Transient exit pattern groups, matching any exits which are temporary and usually in
            #   random locations (such as the entrance to a wagon, which is moving from room to
            #   room) (groups of 2)
            #   [0]     - the pattern to match
            #   [1]     - the number of the destination room, or 'undef'/an empty string/zero if no
            #               destination room is set
            transientExitPatternList    => [],

            # Status task format list - how the Status task should display its variables in its
            #   task window (if it's open)
            # Status task variables are in the form @variable_name@; any items in the list matching
            #   that format are substituted for a value provided by the Status task, every time its
            #   task window is updated
            statusFormatList            => [
                # Not reasonable to expect the user to create this for themselves, so use a default
                #   list
                'HP: @health_points@ (@health_points_max@) MP: @magic_points@ (@magic_points_max@)'
                . ' EP: @energy_points@ (@energy_points_max@) GP: @guild_points@'
                . ' (@guild_points_max@) SP: @social_points@ (@social_points_max@)',
                'XP: @xp_current@ Total: @xp_total@ Level: @level@',
                'Bank: @bank_balance@ Purse: @purse_contents@',
                'Local Wimpy: @local_wimpy@ (@local_wimpy_max@) Remote Wimpy: @remote_wimpy@'
                . ' (@remote_wimpy_max@)',
                '@fight_count@ @coward_string@',
                '@interact_string@',
                'Temp: XP: @temp_xp_count@ (Av: @temp_xp_average@) QP: @temp_quest_count@'
                . ' Money: @temp_money_count@ Time: @temp_timer@',
                ' @temp_fight_count@ @temp_coward_count@',
                ' @temp_interact_count@',
                'Tasks: @task@ @task_active@',
            ],
            # Gauge format list - how the Status task should display data in the 'main' window's
            #   gauge box (groups of 7)
            #   [0] - the variable to display in the gauge; can be any of the Status task's
            #           character, fixed or custom variables
            #   [1] - the variable to display in the gauge as the 'maximum'; can be any of the
            #           Status task's character, fixed or custom variables
            #       - NB It's possible to use the same scalar in [0] and [1], e.g. 'bank_balance',
            #           in order to display a gauge that's always full (assuming that the Status
            #           task's ->gaugeValueFlag is TRUE, so the numerical value is also displayed)
            #   [2] - if TRUE, the total size of the gauge is ($value + $maxValue). If FALSE (or
            #           'undef'), the total size is $maxValue
            #   [3] - the label to use, e.g. 'HP'
            #   [4] - the colour of the 'full' portion of the gauge (if 'undef', the default gauge
            #           colour is used)
            #   [5] - the colour of the 'empty' portion of the gauge (if 'undef', the default gauge
            #           colour is used)
            #   [6] - the colour of the label (if 'undef', the default label colour is used)
            # A default list using the most common variables
            gaugeFormatList             => [
                'health_points', 'health_points_max', FALSE, 'HP',
                    'RED', 'red', 'WHITE',
                'magic_points', 'magic_points_max', FALSE, 'MP',
                    'YELLOW', 'yellow', 'black',
                'energy_points', 'energy_points_max', FALSE, 'EP',
                    'GREEN', 'green', 'black',
                'guild_points', 'guild_points_max', FALSE, 'GP',
                    'BLUE', 'blue', 'WHITE',
                'social_points', 'social_points_max', FALSE, 'SP',
                    'MAGENTA', 'magenta', 'WHITE',
            ],
            # Hash of Status task variables, whose values can be set when MSDP variables are
            #   received. Hash in the form
            #       $msdpStatusVarHash{MSDP_VARIABLE} = status_task_variable
            # Normally, the Status task only accepts a subset of MSDP variables for the categories
            #   'Character', 'Combat' and 'World'. Adding key-value pairs to this hash allow the
            #   Status task to accept other MSDP variables too
            msdpStatusVarHash           => {},
            # Bar string pattern groups (groups of 6)
            #   [0] - the pattern to match
            #   [1] - the number of the group substring that contains the data we need
            #   [2] - 'health', 'magic', 'energy', 'guild', 'social', 'xp_current', 'xp_next_level',
            #           'qp_current', 'qp_next_level', 'op_current', 'op_next_level' (note that
            #           other values, including all other Status task variables, are invalid here)
            #   [3] - 'hide' to use a gag trigger, 'show' to use a non-gag trigger, 'choose' to let
            #           the Status task choose
            #   [4] - the string which represents 1 unit, e.g. '=' or '*'
            #   [5] - how many units equal the maximum
            barPatternList              => [],
            # Pattern groups containing one or more group substrings, only one of which is used
            #   (groups of 4)
            #   [0] - the pattern to match
            #   [1] - the number of the group substring that contains the data we need
            #   [2] - any Status task character, local or custom variable
            #   [3] - 'hide' to use a gag trigger, 'show' to use a non-gag trigger, 'choose' to let
            #           the Status task choose
            groupPatternList            => [],
            # Affect string pattern groups (groups of 3)
            #   [0] - the pattern to match
            #   [1] - the number of the group substring that contains the data we need (probably a
            #           string like 'Curse Invisibility', with each word corresponding to a key in
            #           the current character's ->affectHash. If the string means that the
            #           character is not affected by any spells (etc), use the number 0
            #   [2] - 'hide' to use a gag trigger, 'show' to use a non-gag trigger, 'choose' to let
            #           the Status task choose
            affectPatternList           => [],
            # Stat string pattern groups (groups of 4)
            #   [0] - the pattern to match
            #   [1] - the number of the group substring that contains the data we need
            #   [2] - a key in the stat hash (e.g. 'int', 'con', 'dex')
            #   [3] - 'hide' to use a gag trigger, 'show' to use a non-gag trigger, 'choose' to let
            #           the Status task choose
            statPatternList             => [],
            # Age string pattern groups (groups of 1)
            #   [0] - the pattern to match (all group substrings are used)
            agePatternList              => [],
            # Time string pattern groups (groups of 1)
            #   [0] - the pattern to match (only the first group substring is used)
            timePatternList             => [],
            # Status ignore pattern groups (groups of 1)
            #   [0] - the pattern to match when strings should be ignored
            statusIgnorePatternList     => [],

            # Life status pattern groups (groups of 1)
            #   [0] - the pattern to match
            deathPatternList            => [],
            resurrectPatternList        => [],
            passedOutPatternList        => [],
            comeAroundPatternList       => [],
            fallAsleepPatternList       => [],
            wakeUpPatternList           => [],
            questCompletePatternList    => [],

            # Inventory string pattern groups (groups of 5)
            #   [0] - the pattern to match
            #   [1] - the number of the group substring that contains object(s) in the inventory
            #           (might be 0 if the line doesn't contain any objects)
            #   [2] - what kind of possession this is. Standard strings are:
            #           'wield', 'hold', 'wear', 'carry' for objects;
            #           'sack' for anything being carried in something else (which usually doesn't
            #               appear in the inventory list);
            #           'purse', 'deposit', 'deposit_only', 'withdraw', 'withdraw_only', 'balance'
            #               which update the character's purse and bank balances;
            #           'empty_purse' for an empty purse, 'empty_bank' for an empty bank account
            #           'misc' for any other type of possession
            #           'ignore' for a line in the inventory which should be ignored
            #   [3] - 'hide' to use a gag trigger, 'show' to use a non-gag trigger (all the
            #           triggers are disabled when the task is disactivated, so we don't need a
            #           'choose')
            #   [4] - 'start' if this line is always at the beginning of an inventory list; 'stop'
            #           if it is always the end of an inventory list; 'optional' for any other line
            inventoryPatternList        => [],
            # Inventory ignore pattern groups (groups of 2)
            #   [0] - the pattern to match when strings should be ignored
            #   [1] - 'hide' to use a gag trigger, 'show' to use a non-gag trigger (all the
            #           triggers are disabled when the task is disactivated, so we don't need a
            #           'choose')
            inventoryIgnorePatternList  => [],
            # Inventory discard pattern groups (groups of 1)
            #   [0] - the pattern which matches a portion of a line
            # All patterns in the list are matched against all lines. For any matching lines, the
            #   matching portion(s) are removed from the line (using the pattern(s) in Perl
            #   substitutions), and the rest of the line is parsed as an object.
            # These patterns are matched against lines after patterns in
            #   ->inventoryIgnorePatternList are checked
            inventoryDiscardPatternList => [],
            # Inventory split pattern groups (groups of 1)
            #   [0] - the pattern which matches a portion of a line
            # All patterns in the list are matched against all lines. For any matching lines, the
            #   line is split into multiple pieces, in a standard Perl split operation using the
            #   pattern. If multiple discard patterns are specified, they are all applied, one after
            #   another, potentially splitting existing line pieces into smaller pieces. Each piece
            #   is then parsed as a (separate) object. The portion of the line matching the split
            #   pattern is discarded
            # NB The split occurs before the object(s) are passed to GA::Obj::WorldModel->parseObj.
            #   That function uses the current dictonary to parse a string like 'Two orcs, a sword
            #   and three shields' into a list of objects. This IV doesn't need to include commas
            #   and words like 'and' because ->parseObj already takes care of that
            # These patterns are matched against lines after patterns in
            #   ->inventoryIgnorePatternList and ->inventoryDiscardPatternList are checked
            inventorySplitPatternList   => [],
            # The way in which the Inventory task (if running) interprets the character's inventory
            # In inventory mode 'match_all', only lines matching one of the patterns in
            #   ->inventoryPatternList (and not matching ->inventoryIgnorePatternList) are used. The
            #   lines are processed as soon as they are received. There should be at least one
            #   'start' or 'stop' line; when a 'start' line is received, the previously-gathered
            #   inventory is emptied; when a 'stop' line is received, the previously-gathered
            #   inventory is marked to be emptied as soon as the next matching line is found
            # In inventory mode 'start_stop', all lines between a 'start' and 'stop' pattern are
            #   used. Lines which match one of the patterns in ->inventoryPatternList (and which
            #   don't match one of the patterns in ->inventoryIgnorePatternList) are processed as
            #   soon as they are received; other lines between 'start' and 'stop' are processed when
            #   the Inventory task is next called (default: once a second)
            # In inventory mode 'start_empty', all lines between a 'start' line and the first empty
            #   line are used.  Lines which match one of the patterns in ->inventoryPatternList (and
            #   which don't match one of the patterns in ->inventoryIgnorePatternList) are processed
            #   as soon as they are received; other lines between 'start' and the first empty line
            #   are processed when the Inventory task is next called (default: once a second)
            # NB 'optional' patterns must contain group substrings; only the group substrings are
            #   processed as an object. 'start' and 'stop' patterns can contain group substrings, or
            #   not; the group substrings are processed as objects, if found
            # NB In modes 'start_stop' and 'start_empty', lines which don't match an 'optional'
            #   pattern are processed whole
            inventoryMode               => 'match_all',

            # Object condition pattern groups (groups of 4)
            #   [0] - the pattern to match
            #   [1] - the number of the group substring that contains the object (set to 0 if no
            #           part of the string is guaranteed to contain the object)
            #   [2] - 'hide' to use a gag trigger, 'show' to use a non-gag trigger (all the
            #           triggers are disabled when the task is disactivated, so we don't need a
            #           'choose')
            #   [3] - the corresponding condition in the range 0-100
            conditionPatternList        => [],
            # Condition ignore string arguments (groups of 1)
            conditionIgnorePatternList  => [],

            # Fight pattern groups applying to all characters in the world (groups of 2)
            #   [0] - the pattern to match
            #   [1] - the number of the group substring that contains the target (if 0, string
            #           doesn't contain the target)
            fightStartedPatternList     => [],
            cannotFindTargetPatternList => [],
            targetAlreadyDeadPatternList
                                        => [],
            targetKilledPatternList     => [],
            fightDefeatPatternList      => [],
            wimpyEngagedPatternList     => [],
            # Exceptions to these pattern groups [groups of 1]
            #   [0] - the pattern to match
            noFightStartedPatternList   => [],
            noCannotFindTargetPatternList
                                        => [],
            noTargetAlreadyDeadPatternList
                                        => [],
            noTargetKilledPatternList   => [],
            noFightDefeatPatternList    => [],
            noWimpyEngagedPatternList   => [],

            # Interaction pattern groups applying to all characters in the world (groups of 2)
            #   [0] - the pattern to match
            #   [1] - the number of the group substring that contains the target (if 0, string
            #           doesn't contain the target)
            interactionStartedPatternList
                                        => [],
            cannotInteractPatternList
                                        => [],
            interactionSuccessPatternList
                                        => [],
            interactionFailPatternList
                                        => [],
            interactionFightPatternList
                                        => [],      # Converts the interaction into a fight
            interactionDisasterPatternList
                                        => [],      # Engages wimpy mode
            # Exceptions to these pattern groups [groups of 1]
            #   [0] - the pattern to match
            noInteractionStartedPatternList
                                        => [],
            noCannotInteractPatternList
                                        => [],
            noInteractionSuccessPatternList
                                        => [],
            noInteractionFailPatternList
                                        => [],
            noInteractionFightPatternList
                                        => [],
            noInteractionDisasterPatternList
                                        => [],

            # Fight/interaction pattern groups (groups of 3)
            #   [0] - the pattern to match
            #   [1] - the number of the group substring that contains the target
            #   [2] - the number of the group substring that contains the direction (0 if not
            #           supplied by the world, e.g. 'The orc runs away.')
            targetLeavesPatternList     => [],
            targetArrivesPatternList    => [],
            # Exceptions to these pattern groups (groups of 1)
            #   [0]     - the pattern to match
            noTargetLeavesPatternList   => [],
            noTargetArrivesPatternList  => [],

            # Fight/interaction pattern groups (groups of 1)
            #   [0]     - the pattern to match
            noFightsRoomPatternList     => [],
            noInteractionsRoomPatternList
                                        => [],

            # Get success strings (what the world sends after the 'get axe' command) (groups of 1)
            #   [0]     - the pattern to match
            getSuccessPatternList       => [],
            # Get too heavy pattern groups (what the world sends after the 'get axe' command, if
            #   it's too heavy to pick up, but when the axe actually exists) (groups of 1)
            #   [0]     - the pattern to match
            getHeavyPatternList         => [],
            # Get fail pattern groups (what the world sends after the 'get axe' command, when the
            #   axe doesn't exist) (groups of 1)
            #   [0]     - the pattern to match
            getFailPatternList          => [],
            # Drop success pattern groups (what the world sends after the 'drop axe' command)
            #   (groups of 1)
            #   [0]     - the pattern to match
            dropSuccessPatternList      => [],
            # Drop forbidden pattern groups (what the world sends after the 'drop axe' command, if
            #   the action is forbidden - perhaps because the character has to stop wielding the axe
            #   first) (groups of 1)
            #   [0]     - the pattern to match
            dropForbidPatternList       => [],
            # Drop fail pattern groups (what the world sends after the 'drop axe' command, when the
            #   axe doesn't exist) (groups of 1)
            #   [0]     - the pattern to match
            dropFailPatternList         => [],

            # Buy success strings (what the world sends after the 'buy axe' command) (groups of 1)
            #   [0]     - the pattern to match
            buySuccessPatternList       => [],
            # Buy partial success strings (can be used in situations like 'buy x y and z' if the
            #   world send 'The shopkeeper can't cope with that many items') (groups of 1)
            #   [0]     - the pattern to match
            buyPartialPatternList       => [],
            # Buy fail strings (what the world sends after the 'buy axe' command, if it's not
            #   possible for any reason) (groups of 1)
            #   [0]     - the pattern to match
            buyFailPatternList          => [],
            # Sell success strings (what the world sends after the 'sell axe' command) (groups of 1)
            #   [0]     - the pattern to match
            sellSuccessPatternList      => [],
            # Sell partial success strings (can be used in situations like 'sell all' if the world
            #   sends 'The shopkeeper can't cope with that many items') (groups of 1)
            #   [0]     - the pattern to match
            sellPartialPatternList      => [],
            # Sell fail strings (what the world sends after the 'sell axe' command, if it's not
            #   possible for any reason) (groups of 1)
            sellFailPatternList         => [],

            # Advance success strings (what the world sends after you successfully advance a skill)
            #   (groups of 1)
            #   [0]     - the pattern to match
            advanceSuccessPatternList   => [],
            # Advance fail strings (what the world sends after you fail to advance a skill) (groups
            #   of 1)
            #   [0]     - the pattern to match
            advanceFailPatternList      => [],

            # List of patterns for use in the Channels and Divert task (groups of 3)
            #   [0] - the pattern to match
            #   [1] - a channel name
            #   [2] - a flag set to FALSE if the matching line must also be displayed in the 'main'
            #           window, TRUE if it must be gagged in the 'main' window
            # When text matching a pattern is received, the Channels task displays it in a tab with
            #   the name of the channel. The Divert task uses assigned colours for the channels
            #   'tell', 'social', 'custom' and 'warning', and a separate assigned colour for every
            #   other channel
            # Channel names must be 1-16 characters. There is no need to add channels anywhere; the
            #   channel exists if it's defined in this list
            channelList                 => [],
            # A list of exceptions. If text matches a pattern in $self->channelList, but also
            #   matches any of the patterns in this list, it is not diverted to the Channels or
            #   Divert task (groups of 1)
            #   [0] - the pattern to match
            noChannelList               => [],

            # Hash of currency units mapping each unit onto a standard unit (usually the largest
            #   one)
            #   e.g. ->currencyHash{'gold'} = 1;
            # The keys in this hash can represent either an adjective (e.g. 'gold' as in 'gold
            #   coin'), or a noun ('dollar')
            # NB One of keys with a value of 1 - here, 'gold' - must also be specified in
            #   $self->standardCurrencyUnit (if there is more than one key with the value 1, choose
            #   one of the keys as the standard unit)
            currencyHash                => {
                'gold'  => 1,
            },
            standardCurrencyUnit        => 'gold',
            # The number of decimal places to which any cash value should be rounded, when
            #   intercepted by the Inventory task (the Status task does the actual rounding). Use
            #    a value of 0 to round cash values to the nearest integer or -1 to prevent
            #   rounding altogether. Maximum value 9.
            # If you use a value of 1 or more, it should match the lowest value in ->currencyHash
            #   (e.g. if you use bronze => 0.01, then ->currencyRounding should be 2 for 2dp)
            currencyRounding            => -1,

            # Hash of missions (each one stored in a GA::Obj::Mission object)
            #   ->missionHash{unique_name} = blessed_reference_to_mission_object
            missionHash                 => {},

            # Variables which are also used by the character profile characters - if these values
            #   are unknown, or they vary too much, leave them empty/set to 0
            # Hash of quests (list of quest names in this world)
            #   ->questHash{unique_name} = blessed_reference_to_quest_object
            questHash                   => {},
            # Number of quests stored in ->questHash
            questCount                  => 0,
            # Total quest points, XP and cash earned by the quests stored in ->questHash
            questPointCount             => 0,
            questXPCount                => 0,
            questCashCount              => 0,

            # Hash of character stats
            #   $statHash{stat_name} = default_value
            #   (N.B. 'default_value' is usually 0)
            statHash                    => {},
            # Ordered list of character stats. If set, the Status task (or anything else) can
            #   use this list to display a list of character stats, in the order in which they occur
            #   in the list. If this list is empty, the task uses the keys in $self->statHash in
            #   alphabetical order
            statOrderList               => [],

            # Hash of commands sent by the Status task when it is in 'active' mode (e.g. 'score',
            #   'sc' sent every ten seconds)
            # This hash is inherited by the character profile, and from there it is copied by the
            #   Status task
            #   e.g. $statusCmdHash{'score'} = 30
            #       (sends the command 'score' every 30 seconds)
            statusCmdHash               => {},
            # Hash of commands the Inventory task should send to the world periodically
            # This hash is inherited by the character profile, and from there it is copied by the
            #   Status task
            #   e.g. $inventoryCommandHash{'i'} = 30
            #       (sends the command 'i' every 30 seconds)
            inventoryCmdHash            => {},

            # A section of text which describes a room is called a 'room statement'. Axmud's Locator
            #   task uses room statements to track the character's current location in the world
            # Many worlds use room statements in one of two forms, 'verbose' and 'brief'. Axmud
            #   divides these into three distinct forms, some of which are not available in every
            #   world:
            #
            #   'Verbose', e.g.
            #
            #       Village Road Intersection
            #       You are in the main intersection of the village. Saquivor road extends north and
            #         south, intersected east to west by a road that leads west toward a wilderness,
            #         and east toward shore.
            #       Obvious exits: south, north, east, west
            #       A damp towel is here.
            #
            #   'Short verbose'
            #       (Exactly the same as 'verbose', but the verbose description part is usually
            #           omitted)
            #
            #   'Brief', e.g.
            #
            #       Village Road Intersection [s, n, e, w]
            #
            # When the task loop spins, the Locator task checks incoming text to see whether it
            #   looks like a verbose, short verbose or brief room statement.
            # Normally, the Locator task looks out for text matching all three forms of statement.
            #   However, if a particular world omits one or more form, the task can be told to
            #   ignore those forms
            #
            # Room statements consist of an ordered list of components. Each component is a
            #   GA::Obj::Component object. Axmud recognises the following component types
            #   (available as a list in GA::Client->constComponentTypeList):
            #       'anchor'        - See below (1 line only)
            #       'verb_title'    - The room title in a verbose/short verbose statement
            #       'verb_descrip'  - The description in a verbose/short verbose statement
            #       'verb_exit'     - The exit list in a verbose/short verbose statement
            #       'verb_content'  - The contents list in a verbose/short verbose statement
            #       'verb_special'  - Lines adjacent to the verbose description, which are actually
            #                           a contents list
            #       'brief_title'   - The room title in a brief statement
            #       'brief_exit'    - The exit list in a brief statement
            #       'brief_title_exit'
            #                       - The room title and exit list (1 line only)
            #       'brief_exit_title'
            #                       - The exit list and room title (1 line only)
            #       'brief_content' - The contents list in a brief statement
            #       'room_cmd'      - List of commands available in the room
            #       'mudlib_path'   - Path to the room's source code, relative to
            #                           GA::Obj::WorldModel->mudlibPath
            #       'weather'       - Lines describing the weather. They are not stored in the world
            #                           model but are displayed in the Locator task's window (if
            #                           open. The component's name is displayed too, so this
            #                           component can used for the weather, the time of day, or
            #                           anything else that we want displayed in the window
            #       'ignore_line'   - Lines inside the statement, which should be ignored (here,
            #                           'inside' can mean the first or last lines of the statement)
            #       'custom'        - Available for any other code that wants to create their own
            #                           GA::Obj:Components, and to store them here
            # The 'anchor' is a special component, which is always one line long and matches a
            #   specific pattern. The Locator task finds a room statement by looking for a line
            #   matching the anchor line.
            # For most worlds, the anchor line is the list of exits, matching a pattern like
            #   'Obvious exits: '. On most worlds, the 'anchor' component and either the 'verb_exit'
            #   or 'brief_exit' components share a line.
            #
            # An Axmud room statement consists of an ordered list of components, which must include
            #   at least the anchor line (all other components are, in theory, optional.)
            # Any component can be used with any form of statement - for example, in worlds which
            #   use identical contents lists in their verbose and brief statements, you can use the
            #   'verb_content' component in both)
            # Every component can have a fixed number of lines or a dynamic number, can stop at a
            #   line matching a pattern (or not matching a pattern), or stop at the first empty line
            #   (or the first line not containing alphanumeric characters). (Exceptions: the
            #   'anchor' and 'mudlib_path' components are only ever one line long)
            # In addition, the anchor line can be marked as appearing on its own line, as sharing
            #   a line with the component before it, or as sharing a line with the component after
            #   it
            #
            # Hash of GA::Obj::Component objects that exist (not all of them may be in use). Each
            #   has a unique name (max 16 chars). Hash in the form
            #       $componentHash{unique_name} = blessed_reference_to_component_object
            componentHash               => {},
            # The component lists for verbose room statements (set below). If not empty, consists of
            #   GA::Obj::Component object names (keys in $self->componentHash) and/or the string
            #   'anchor'. If empty, this form of statement is not used in the world
            verboseComponentList        => [],
            # The component lists for short verbose room statements (set below)
            shortComponentList          => [],
            # The component lists for brief room statements (set below)
            briefComponentList          => [],

            # Some worlds (e.g. MUD1, LamdbaMOO) don't use room statements with any matchable text
            #   at all; in both those cases, neither have an exit list. Because we can't use
            #   regular expressions to detect a room statement, we have to assume a move was
            #   successful, unless a recognisable fail exit string is encountered straight after the
            #   move
            # In basic mapping mode, GA::Obj::Component objects can still be specified, typically
            #   in order to process room titles, verbose descriptions, contents lists and so on.
            #   However, if no components are specified, the move is still considered successful
            # In basic mapping mode, the Locator task won't use a line matching a recognisable
            #   prompt ($self->cmdPromptPatternList) or an empty line as the start of a room
            #   statement; so make sure ->cmdPromptPatternList has been set, if you use basic
            #   mapping mode
            # If the Automapper window is open, basic mapping mode normally causes a one-way exit
            #   to be drawn from the departure room to the newly-created destination room. If the
            #   user wants to create 2-way exits by default, they can toggle
            #   GA::Obj::WorldModel->autocompleteExitsFlag
            # Those components are specified in $self->verboseAnchorPatternList,
            #   ->shortAnchorPatternList and ->briefAnchorPatternList. If specified, the first item
            #   in the list(s) must be 'anchor', followed by one or more other components
            # Basic mapping mode. FALSE - don't use basic mapping (because this world's room
            #   statements contain some matchable text, like a list of exits). TRUE - use basic
            #   mapping (assume a move was successful, unless a recognisable fail exit string is
            #   seen straight after the move)
            basicMappingFlag            => FALSE,
            # The world MUD1 (British Legends) echos back movement commands. This leaves the Locator
            #   unable to detect fail exit strings, and so on (in basic mapping mode)
            # A list of patterns which match a line which should NOT be checked as potential anchor
            #   lines (ignored, when extracting room statement components).
            # NB The Locator uses this list regardless of whether basic mapping mode is on, or not;
            #   but it's probably only useful in basic mapping mode
            notAnchorPatternList        => [],

            # Settings for 'anchor' component
            # A list of patterns which mark a line as a verbose anchor line
            verboseAnchorPatternList    => [],
            # The anchor line's relationship with other components in the component list: -1 if the
            #   anchor line shares a line with the component before it; +1 if the anchor line
            #   shares a line with the component after it; 0 if the anchor line does not share its
            #   line with any component
            verboseAnchorOffset         => 1,   # By default, anchor line is the list of exits
            # A list of patterns adjacent to the anchor line, used to check that we've got the
            #   right one. List in groups of 2, in the form
            #       (offset, pattern, offset, pattern)
            #   ...where 'offset' is an integer in the range -16 to +16 describing a line above
            #       (negative) or below (positive) the anchor line (if 0, the anchor line itself is
            #       checked against the pattern), and 'pattern' is the regex that line must match.
            #       If any of the 'pattern's in the list don't match, the line matching
            #       ->verboseAnchorPatternList is not used as an anchor line. If the line
            #       specified by 'offset' doesn't exist (hasn't been received yet), the anchor line
            #       is not used (so if you specify any check patterns, it's better to use an anchor
            #       line near the start of a room statement, not one near the end of it)
            verboseAnchorCheckList      => [],
            # A list of patterns which mark a line as a short verbose anchor line
            shortAnchorPatternList      => [],
            # The anchor line's relationship with other components in the component list:
            shortAnchorOffset           => 1,
            # A list of patterns adjacent to the anchor line, in groups of 2
            shortAnchorCheckList        => [],
            # A list of patterns which mark a line as a brief anchor line
            briefAnchorPatternList      => [],
            # The anchor line's relationship with other components in the component list:
            briefAnchorOffset           => 1,
            # A list of patterns adjacent to the anchor line, in groups of 2
            briefAnchorCheckList        => [],

            # Settings for 'verb_exit' component
            # If the exits in the 'verb_exit' component are separated by characters or strings, the
            #   delimiters used. Must include whitespace, as appropriate (e.g. ' and ' / ', ' / '.')
            # Items in the list should ideally be in order of length, longest first (but the
            #   Locator task sorts them before using them, anyway)
            verboseExitDelimiterList    => [],      # String, not a regex
            # A non-delimiter is a string which the exit list should NOT contain. This helps the
            #   Locator task to work out what is a list of exits, and what is not (e.g. 'is here',
            #   'are here')
            # Items in the list can be in any order (and are not sorted by the Locator task)
            verboseExitNonDelimiterList => [],      # String, not a regex
            # Alternatively, if the exits are single letters in a continuous string (e.g. NSEW),
            #   set this flag to TRUE to split the string into 1-letter exits
            # NB If both delimiters and the flag are set, they are both used - delimiters are used
            #   first to split the string into a list; then each item in the list is split into
            #   characters
            verboseExitSplitCharFlag    => FALSE,
            # If the exit list is surrounded by markers, these lists contain those markers. Every
            #   marker is a regex
            # If no markers are available on this world, set them both as empty lists. The markers
            #   are checked in order, so longer markers should be listed before shorter ones. Left
            #   markers are checked before right ones
            # Left marker regexes should start with '^', and right marker regexes should end with
            #   '$'; if they don't, the markers will be removed from the middle of a list of exits
            #   (which is probably not what you want)
            # For lines like 'There are no obvious exits', create a left marker like
            #   '^There are no obvious exits\.*$'
            verboseExitLeftMarkerList   => [],
            verboseExitRightMarkerList  => [],

            # Settings for 'brief_exit', 'brief_title_exit' and 'brief_exit_title' components
            # If the exits in these components are separated by characters or strings, the
            #   delimiters used. Must include whitespace, as appropriate (e.g. ' and ' / ', ' / '.')
            # Items in the list should ideally be in order of length, longest first (but the
            #   Locator task sorts them before using them, anyway)
            briefExitDelimiterList      => [],      # String, not a regex
            # A non-delimiter is a string which the exit list should NOT contain. This helps the
            #   Locator task to work out what is a list of exits, and what is not (e.g. 'is here',
            #   'are here')
            # Items in the list can be in any order (and are not sorted by the Locator task)
            briefExitNonDelimiterList   => [],      # String, not a regex
            # Alternatively, if the exits are single letters in a continuous string (e.g. NSEW),
            #   set this flag to TRUE to split the string into 1-letter exits
            # NB If both delimiters and the flag are set, they are both used - delimiters are used
            #   first to split the string into a list; then each item in the list is split into
            #   characters
            briefExitSplitCharFlag      => FALSE,
            # If the exit list is surrounded by markers, these lists contain those markers. Every
            #   marker is a regex
            # If no markers are available on this world, set them both as empty lists. The markers
            #   are checked in order, so longer markers should be listed before shorter ones. Left
            #   markers are checked before right ones
            # Left marker regexes should start with '^', and right marker regexes should end with
            #   '$'; if they don't, the markers will be removed from the middle of a list of exits
            #   (which is probably not what you want)
            # For lines like 'Exits: none', create a left marker like
            #   '^Exits: none\.*$'
            briefExitLeftMarkerList     => [],
            briefExitRightMarkerList    => [],

            # Some worlds (especially MOOs) use an exit list like 'west (to Main Street), east (to
            #   hotel), etc. The portions in brackets are not required by the Locator, so we need
            #   to be able to extract them
            # An unlimited list of patterns; any matching portions of the exit are removed. In
            #   addition, the first group substring (if any) is used to set GA::Obj::Exit->exitInfo
            #   (otherwise, ->exitInfo remains set to 'undef')
            exitInfoPatternList         => [],
            # An unlimited list of patterns; any matching portions of the exit are removed (in a
            #   s/$pattern//gi operation) - case insensitive, because a 'North' exit will already
            #   have become a 'north' exit, when the pattern match is done
            exitRemovePatternList       => [],
            # On some worlds, the verbose list of exits indicates exit states by surrounding an exit
            #   with symbols, e.g. 'Obvious exits : north, (east), west'
            # Some of these list IVs contain strings (not regexes) found at the beginning, middle
            #   and/or end of a verbose exit which is open, closed, locked or impassable.
            # Other IVs contain strings (not regexes) that indicate the destination room is dark,
            #   dangerous, or in some other state.
            # The final kind of exit state which is simple ignored; the colons (or whatever) are
            #   removed, but GA::Obj::Exit->exitState is not modified
            # List of exit state strings (groups of 4)
            #   [0] - The exit state represented, one of 'normal', 'open', 'closed', 'locked',
            #           'secret', 'secret_open', 'secret_closed', 'secret_locked', 'impass', 'dark',
            #           'danger', 'other', 'ignore'
            #         Exits which lack exit state strings (e.g. 'west') have the exit state 'normal'
            #           by default, but in case some world uses exit state strings on ALL exits,
            #           it's possible to specify 'normal' exit state strings here, too
            #   [1] - String appearing at the beginning of the exit (or an empty string), e.g. '('
            #   [2] - String appearing in the middle (or end) of the exit (or an empty string)
            #   [3] - String appearing at the end of the exit (or an empty string), e.g. ')'
            # NB Axmud treats exits as case insensitive, so '(NORTH)' and '(north)' would both be
            #   treated as an exit called 'north', with an exit state 'dark'
            # NB If items [2] and [3] are both non-empty strings, Axmud assumes that [2] occurs in
            #   middle, and only [3] occurs at the end. If [2] is a non-empty string and [3] is an
            #   empty string, Axmud assumes that [2] occurs either in the middle, or at the end
            # NB If items [1], [2] and [3] are all empty strings, Axmud will assume the exit state
            #   can't be detected, and will class the exit as 'normal'. The default exit state is
            #   already 'normal', so there's no need to add a group like this
            # NB The first matching set of exit state strings determine an exit's state, so a
            #   duplicate set of exit state strings would never be checked
            exitStateStringList         => [],
            # If exit state strings themselves contain exit delimiters (one of the strings in
            #   $self->verboseExitDelimiterList and/or ->briefExitDelimiterList), exit parsing will
            #   fail
            # For example, the exit delimiter appears in the exit state string meaning 'closed':
            #   > Exits: north south [ west ] east
            # In that case, pattern(s) matching the whole exit, including its surrounding exit state
            #   strings, can be added to this list (in the example above, we'd add the pattern
            #   '\[\s\w+\s\]', and the exit delimiter list should contain the strings '  ' and ' '
            #   (two spaces, as well as one)
            # When splitting an exit list into separated exits, any portion of the text matching
            #   one of these patterns is removed and treated as a single exit, before the text is
            #   split into individual exits using exit delimiters
            exitStatePatternList        => [],
            # Some worlds use exit lists, with two or more exits represented as a single word;
            #   for example, Lost Souls uses 'compass' to mean 'n w s e nw ne sw se'
            # Hash of exit aliases. The key is a pattern found in the world's exit list; the
            #   corresponding value is a replacement string. The Locator task substitutes the
            #   exit alias for the replacement string (in a normal regex substitution)
            # e.g. $exitAliasHash{compass} = 'n w s e nw ne sw se'
            exitAliasHash               => {},

            # List of patterns used in contents list which shouldn't be parsed (i.e. are not a part
            #   of the object itself)
            contentPatternList          => [],
            # Hash of special contents patterns, which matches any line in the 'verb_special', which
            #   is normally adjacent to the 'verb_descrip' component, and which represents a part
            #   of the room's contents, not part of its description. The corresponding value is
            #   something that can be parsed by GA::Obj::WorldModel->parseObj. Hash in the form
            #       $specialPatternHash{'There is a sign here you can read'} = 'A sign is here'
            # NB The 'verb_special' component uses the keys of this list in place of
            #   the component's usual ->stopBeforeNoPatternList
            specialPatternHash          => {},

            # Settings for 'room_cmd' component
            # If the commands in the 'room_cmd' component are separated by characters or strings,
            #   the delimiters used. Must include whitespace, as appropriate (e.g. ' and ' / ', '
            #   / '.')
            # Items in the list should ideally be in order of length, longest first (but the
            #   Locator task sorts them before using them, anyway)
            roomCmdDelimiterList        => [],      # String, not a regex
            # A non-delimiter is a string which the room command list should NOT contain. This helps
            #   the Locator task to work out what is a list of room commands, and what is not
            # Items in the list can be in any order (and are not sorted by the Locator task)
            roomCmdNonDelimiterList     => [],      # String, not a regex
            # Alternatively, if the room commands are single letters in a continuous string (e.g.
            #   HGP representing commands for harvesting, gathering and picking), set this flag to
            #   TRUE to split the string into 1-letter room commands
            # NB If both delimiters and the flag are set, they are both used - delimiters are used
            #   first to split the string into a list; then each item in the list is split into
            #   characters
            roomCmdSplitCharFlag        => FALSE,
            # If the room command list is surrounded by markers, these lists contain those markers.
            #   Every marker is a regex
            # If no markers are available on this world, set them both as empty lists. The markers
            #   are checked in order, so longer markers should be listed before shorter ones. Left
            #   markers are checked before right ones
            # Left marker regexes should start with '^', and right marker regexes should end with
            #   '$'; if they don't, the markers will be removed from the middle of a list of exits
            #   (which is probably not what you want)
            # For lines like 'There are no commands in this room', create a left marker like
            #   '^There are no commands in this room\.*$'
            roomCmdLeftMarkerList       => [],
            roomCmdRightMarkerList      => [],
            # A list of room commands for this world which should be ignored by ';roomcommand'
            roomCmdIgnoreList           => [],

            # For worlds with long(ish) room statements - especially those whose verbose
            #   descriptions come after the anchor line - it's possible to define a pattern which
            #   occurs after the anchor line, and whose absence means the whole room statement
            #   hasn't been received yet (in which case, the Locator task waits a while)
            verboseFinalPattern         => undef,
            shortFinalPattern           => undef,
            briefFinalPattern           => undef,
        };

        # Bless the object into existence
        bless $self, $class;

        # Import the standard hash of log preferences from the client
        $self->{logPrefHash} = {$axmud::CLIENT->constSessionLogPrefHash};

        return $self;
    }

    sub clone {

        # Creates a clone of an existing world profile
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $name       - A unique string name for this profile (max 16 chars, containing
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

        # Setup
        my $clone = {
            _objName                    => $name,
            _objClass                   => $self->_objClass,
            _parentFile                 => $name,
            _parentWorld                => undef,
            _privFlag                   => FALSE,           # All IVs are public

            # Standard profile IVs
            # --------------------

            name                        => $name,
            category                    => $self->category,
            parentWorld                 => undef,

            initTaskHash                => {},              # Set below
            initTaskOrderList           => [],              # Set below
            initTaskTotal               => $self->initTaskTotal,
            initScriptHash              => {$self->initScriptHash},
            initScriptOrderList         => [$self->initScriptOrderList],
            initMission                 => $self->initMission,
            initCmdList                 => [$self->initCmdList],

            setupCompleteFlag           => FALSE,           # Clone never been a current profile
            notepadList                 => [$self->notepadList],
            privateHash                 => {},

            # World profile IVs
            # -----------------

            noSaveFlag                  => FALSE,           # Temp world profile can't be cloned
            connectHistoryList          => [],

            telnetOverrideHash          => {},
            mxpOverrideHash             => {},
            termOverrideHash            => {},
            sigilOverrideHash           => {},

            profHash                    => {},
            passwordHash                => {},              # Passwords are not cloned
            newPasswordHash             => {},
            accountHash                 => {},              # Account names are not cloned
            newAccountHash              => {},

            protocol                    => $self->protocol,

            dns                         => $self->dns,
            ipv4                        => $self->ipv4,
            ipv6                        => $self->ipv6,
            port                        => $self->port,
            sshUserName                 => undef,           # SSH user/password not cloned
            sshPassword                 => undef,
            sshPortFlag                 => $self->sshPortFlag,

            lastConnectDate             => undef,
            lastConnectTime             => undef,
            numberConnects              => 0,
            lastConnectChar             => undef,

            longName                    => $self->longName,
            adultFlag                   => $self->adultFlag,
            worldURL                    => $self->worldURL,
            referURL                    => $self->referURL,
            worldDescrip                => $self->worldDescrip,
            worldHint                       => $self->worldHint,
            worldCharSet                => $self->worldCharSet,

            termType                    => $self->termType,
            columns                     => $self->columns,
            rows                        => $self->rows,
            sendSizeInfoFlag            => $self->sendSizeInfoFlag,

            msspGenericValueHash        => {},              # MSSP data not cloned
            msspCustomValueHash         => {},              # MSSP data not cloned

            loginMode                   => $self->loginMode,
            loginCmdList                => [$self->loginCmdList],
            loginObjName                => $self->loginObjName,
            loginConnectPatternList     => [$self->loginConnectPatternList],
            loginSuccessPatternList     => [$self->loginSuccessPatternList],
            loginAccountMode            => $self->loginAccountMode,
            loginSpecialList            => [$self->loginSpecialList],

            autoQuitMode                => $self->autoQuitMode,
            autoQuitCmdList             => [$self->autoQuitCmdList],
            autoQuitObjName             => $self->autoQuitObjName,

            autoSeparateCmdFlag         => $self->autoSeparateCmdFlag,
            excessCmdLimit              => $self->excessCmdLimit,
            excessCmdDelay              => $self->excessCmdDelay,
            lifeStatusOverrideFlag      => $self->lifeStatusOverrideFlag,

            cmdPromptPatternList        => [$self->cmdPromptPatternList],
            strictPromptsMode           => $self->strictPromptsMode,
            suppressEmptyLineCount      => $self->suppressEmptyLineCount,
            suppressBeforeLoginFlag     => $self->suppressBeforeLoginFlag,

            dict                        => undef,           # Set by ';cloneworld'
            collectUnknownWordFlag      => $self->collectUnknownWordFlag,
            collectContentsFlag         => $self->collectContentsFlag,
            numberedObjFlag             => $self->numberedObjFlag,
            multiplePattern             => $self->multiplePattern,

            logPrefHash                 => {$self->logPrefHash},

            charAgeUnit                 => $self->charAgeUnit,
            weightUnit                  => $self->weightUnit,
            weightUnitStringList        => [$self->weightUnitStringList],

            darkRoomPatternList         => [$self->darkRoomPatternList],
            failExitPatternList         => [$self->failExitPatternList],
            doorPatternList             => [$self->doorPatternList],
            lockedPatternList           => [$self->lockedPatternList],
            involuntaryExitPatternList  => [$self->involuntaryExitPatternList],
            unspecifiedRoomPatternList  => [$self->unspecifiedRoomPatternList],
            followPatternList           => [$self->followPatternList],
            followAnchorPatternList     => [$self->followAnchorPatternList],
            transientExitPatternList    => [$self->transientExitPatternList],

            statusFormatList            => [$self->statusFormatList],
            gaugeFormatList             => [$self->gaugeFormatList],
            msdpStatusVarHash           => {$self->msdpStatusVarHash},
            barPatternList              => [$self->barPatternList],
            groupPatternList            => [$self->groupPatternList],
            affectPatternList           => [$self->affectPatternList],
            statPatternList             => [$self->statPatternList],
            agePatternList              => [$self->agePatternList],
            timePatternList             => [$self->timePatternList],
            statusIgnorePatternList     => [$self->statusIgnorePatternList],

            deathPatternList            => [$self->deathPatternList],
            resurrectPatternList        => [$self->resurrectPatternList],
            passedOutPatternList        => [$self->passedOutPatternList],
            comeAroundPatternList       => [$self->comeAroundPatternList],
            fallAsleepPatternList       => [$self->fallAsleepPatternList],
            wakeUpPatternList           => [$self->wakeUpPatternList],
            questCompletePatternList    => [$self->questCompletePatternList],

            inventoryPatternList        => [$self->inventoryPatternList],
            inventoryIgnorePatternList  => [$self->inventoryIgnorePatternList],
            inventoryDiscardPatternList => [$self->inventoryDiscardPatternList],
            inventorySplitPatternList   => [$self->inventorySplitPatternList],
            inventoryMode               => $self->inventoryMode,

            conditionPatternList        => [$self->conditionPatternList],
            conditionIgnorePatternList  => [$self->conditionIgnorePatternList],

            fightStartedPatternList     => [$self->fightStartedPatternList],
            cannotFindTargetPatternList => [$self->cannotFindTargetPatternList],
            targetAlreadyDeadPatternList
                                        => [$self->targetAlreadyDeadPatternList],
            targetKilledPatternList     => [$self->targetKilledPatternList],
            fightDefeatPatternList      => [$self->fightDefeatPatternList],
            wimpyEngagedPatternList     => [$self->wimpyEngagedPatternList],
            noFightStartedPatternList   => [$self->noFightStartedPatternList],
            noCannotFindTargetPatternList
                                        => [$self->noCannotFindTargetPatternList],
            noTargetAlreadyDeadPatternList
                                        => [$self->noTargetAlreadyDeadPatternList],
            noTargetKilledPatternList   => [$self->noTargetKilledPatternList],
            noFightDefeatPatternList    => [$self->noFightDefeatPatternList],
            noWimpyEngagedPatternList   => [$self->noWimpyEngagedPatternList],

            interactionStartedPatternList
                                        => [$self->interactionStartedPatternList],
            cannotInteractPatternList   => [$self->cannotInteractPatternList],
            interactionSuccessPatternList
                                        => [$self->interactionSuccessPatternList],
            interactionFailPatternList  => [$self->interactionFailPatternList],
            interactionFightPatternList => [$self->interactionFightPatternList],
            interactionDisasterPatternList
                                        => [$self->interactionDisasterPatternList],
            noInteractionStartedPatternList
                                        => [$self->noInteractionStartedPatternList],
            noCannotInteractPatternList => [$self->noCannotInteractPatternList],
            noInteractionSuccessPatternList
                                        => [$self->noInteractionSuccessPatternList],
            noInteractionFailPatternList
                                        => [$self->noInteractionFailPatternList],
            noInteractionFightPatternList
                                        => [$self->noInteractionFightPatternList],
            noInteractionDisasterPatternList
                                        => [$self->noInteractionDisasterPatternList],

            targetLeavesPatternList     => [$self->targetLeavesPatternList],
            targetArrivesPatternList    => [$self->targetArrivesPatternList],
            noTargetLeavesPatternList   => [$self->noTargetLeavesPatternList],
            noTargetArrivesPatternList  => [$self->noTargetArrivesPatternList],

            noFightsRoomPatternList     => [$self->noFightsRoomPatternList],
            noInteractionsRoomPatternList
                                        => [$self->noInteractionsRoomPatternList],

            getSuccessPatternList       => [$self->getSuccessPatternList],
            getHeavyPatternList         => [$self->getHeavyPatternList],
            getFailPatternList          => [$self->getFailPatternList],
            dropSuccessPatternList      => [$self->dropSuccessPatternList],
            dropForbidPatternList       => [$self->dropForbidPatternList],
            dropFailPatternList         => [$self->dropFailPatternList],

            buySuccessPatternList       => [$self->buySuccessPatternList],
            buyPartialPatternList       => [$self->buyPartialPatternList],
            buyFailPatternList          => [$self->buyFailPatternList],
            sellSuccessPatternList      => [$self->sellSuccessPatternList],
            sellPartialPatternList      => [$self->sellPartialPatternList],
            sellFailPatternList         => [$self->sellFailPatternList],

            advanceSuccessPatternList   => [$self->advanceSuccessPatternList],
            advanceFailPatternList      => [$self->advanceFailPatternList],

            channelList                 => [$self->channelList],
            noChannelList               => [$self->noChannelList],

            currencyHash                => {$self->currencyHash},
            standardCurrencyUnit        => $self->standardCurrencyUnit,
            currencyRounding            => $self->currencyRounding,

            missionHash                 => {$self->missionHash},

            questHash                   => {$self->questHash},
            questCount                  => $self->questCount,
            questPointCount             => $self->questPointCount,
            questXPCount                => $self->questXPCount,
            questCashCount              => $self->questCashCount,

            statHash                    => {$self->statHash},
            statOrderList               => [$self->statOrderList],

            statusCmdHash               => {$self->statusCmdHash},
            inventoryCmdHash            => {$self->inventoryCmdHash},

            componentHash               => {},              # Set below
            verboseComponentList        => [$self->verboseComponentList],
            shortComponentList          => [$self->shortComponentList],
            briefComponentList          => [$self->briefComponentList],

            basicMappingFlag            => $self->basicMappingFlag,
            notAnchorPatternList        => [$self->notAnchorPatternList],

            verboseAnchorPatternList    => [$self->verboseAnchorPatternList],
            verboseAnchorOffset         => $self->verboseAnchorOffset,
            verboseAnchorCheckList      => [$self->verboseAnchorCheckList],
            shortAnchorPatternList      => [$self->shortAnchorPatternList],
            shortAnchorOffset           => $self->shortAnchorOffset,
            shortAnchorCheckList        => [$self->shortAnchorCheckList],
            briefAnchorPatternList      => [$self->briefAnchorPatternList],
            briefAnchorOffset           => $self->briefAnchorOffset,
            briefAnchorCheckList        => [$self->briefAnchorCheckList],

            verboseExitDelimiterList    => [$self->verboseExitDelimiterList],
            verboseExitNonDelimiterList => [$self->verboseExitNonDelimiterList],
            verboseExitSplitCharFlag    => $self->verboseExitSplitCharFlag,
            verboseExitLeftMarkerList   => [$self->verboseExitLeftMarkerList],
            verboseExitRightMarkerList  => [$self->verboseExitRightMarkerList],

            briefExitDelimiterList      => [$self->briefExitDelimiterList],
            briefExitNonDelimiterList   => [$self->briefExitNonDelimiterList],
            briefExitSplitCharFlag      => $self->briefExitSplitCharFlag,
            briefExitLeftMarkerList     => [$self->briefExitLeftMarkerList],
            briefExitRightMarkerList    => [$self->briefExitRightMarkerList],

            exitInfoPatternList         => [$self->exitInfoPatternList],
            exitRemovePatternList       => [$self->exitRemovePatternList],
            exitStateStringList         => [$self->exitStateStringList],
            exitStatePatternList        => [$self->exitStatePatternList],
            exitAliasHash               => {$self->exitAliasHash},

            contentPatternList          => [$self->contentPatternList],
            specialPatternHash          => {$self->specialPatternHash},

            roomCmdDelimiterList        => [$self->roomCmdDelimiterList],
            roomCmdNonDelimiterList     => [$self->roomCmdNonDelimiterList],
            roomCmdSplitCharFlag        => $self->roomCmdSplitCharFlag,
            roomCmdLeftMarkerList       => [$self->roomCmdLeftMarkerList],
            roomCmdRightMarkerList      => [$self->roomCmdRightMarkerList],
            roomCmdIgnoreList           => [$self->roomCmdIgnoreList],

            verboseFinalPattern         => $self->verboseFinalPattern,
            shortFinalPattern           => $self->shortFinalPattern,
            briefFinalPattern           => $self->briefFinalPattern,
        };

        # Bless the cloned object into existence
        bless $clone, $self->_objClass;

        # Also need to clone everything in the initial tasklist...
        $clone->cloneInitTaskList($self);
        # ...and the room statement component list
        $clone->cloneComponentList($session, $self);

        return $clone;
    }

    ##################
    # Methods

    sub cloneComponentList {

        # Called by $self->clone immediately after cloning this profile from another
        # Clones room statement component objects in the original profile's ->componentHash
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $original   - The original profile object, from which this object was cloned
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $original, $check) = @_;

        # Local variables
        my (%hash, %newHash);

        # Check for improper arguments
        if (! defined $session || ! defined $original || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->new', @_);
        }

        # Import the hash of component objects
        %hash = $original->componentHash;
        foreach my $name (keys %hash) {

            my ($oldObj, $newObj);

            $oldObj = $hash{$name};
            $newObj = $oldObj->clone($session, $self, $oldObj->name, $oldObj->type);
            if ($newObj) {

                $newHash{$newObj->name} = $newObj;
            }
        }

        # Update IVs (the cloned profile has no corresponding file object yet, so we can't use
        #   ->ivPoke);
        $self->{componentHash} = \%newHash;

        return 1;
    }

    sub findProfiles {

        # Called by GA::Cmd::ListProfile->do, or by any other code
        # $self->profHash contains a list of profiles associated with this world profile
        # Returns a list of associated profile names matching a specified category (which can be
        #   'world', 'guild', 'race', 'char' or any custom profile category)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $category   - A category of profile (one of the elements of
        #                   GA::Client->profPriorityList). If 'undef', returns a list of names of
        #                   profiles whose ->category isn't 'world', 'guild', 'race' or 'char'
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a list of names of the profiles whose ->category IV matches
        #       $category (may be an empty list)

        my ($self, $category, $check) = @_;

        # Local variables
        my (
            @emptyList, @list,
            %hash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->findProfiles', @_);
        }

        if ($category) {

            # Find profiles matching the category
            foreach my $profName ($self->ivKeys('profHash')) {

                my $thisCategory = $self->ivShow('profHash', $profName);

                if ($thisCategory eq $category) {

                    push (@list, $profName);
                }
            }

        } else {

            # Find profiles using a custom category (i.e. profiles whose category isn't one of the
            #   keys in the following hash)
            %hash = (
                'world' => undef,
                'guild' => undef,
                'race'  => undef,
                'char'  => undef,
            );

            foreach my $profName ($self->ivKeys('profHash')) {

                my $thisCategory = $self->ivShow('profHash', $profName);

                if (! exists $hash{$thisCategory}) {

                    push (@list, $profName);
                }
            }
        }

        return @list;
    }

    sub getConnectDetails {

        # Called by GA::Client->start, GA::Cmd::Connect->do, Reconnect->do, etc or by any other
        #   function
        # Fetches the connection details specified by this world profile, just before a call to
        #   GA::Session->new
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $char       - The name of the character profile being used (set to 'undef' if unknown)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a list in the form:
        #       (host_address, host_port, char_name, char_password, char_account)
        #   If 'host_address' and 'host_port' are not specified by this profile, emergency default
        #       values are returned (better to return an invalid string than to return 'undef')
        #   If $char is not specified, 'char_name' will be 'undef'
        #   If $char is not specified or no password for the character can be found,
        #       'char_password' will be undef
        #   If $char is not specified or no associated account for the character can be found,
        #       'char_account' will be undef

        my ($self, $char, $check) = @_;

        # Local variables
        my (
            $host, $port, $pass, $account,
            @emptyList,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getConnectDetails', @_);
            return @emptyList,
        }

        # Prefer IPV6, if specified. Otherwise, prefer 'deathmud.com' over '101.111.121.131'
        if ($self->ipv6) {
            $host = $self->ipv6;
        } elsif ($self->dns) {
            $host = $self->dns;
        } elsif ($self->ipv4) {
            $host = $self->ipv4;
        } else {
            $host = '127.0.0.1';        # Emergency default value
        }

        if ($self->port) {
            $port = $self->port;
        } else {
            $port = 23;                 # Emergency default value
        }

        if ($char) {

            if ($self->ivExists('passwordHash', $char)) {

                $pass = $self->ivShow('passwordHash', $char);

            } elsif ($self->ivExists('newPasswordHash', $char)) {

                # Character profile not created yet, but we know the password
                $pass = $self->ivShow('newPasswordHash', $char);
            }

            if ($self->ivExists('accountHash', $char)) {

                $account = $self->ivShow('accountHash', $char);

            } elsif ($self->ivExists('newAccountHash', $char)) {

                # Character profile not created yet, but we know the password
                $account = $self->ivShow('newAccountHash', $char);
            }
        }

        return ($host, $port, $char, $pass, $account);
    }

    sub updateQuestStats {

        # Called by anything, any time a quest stored by this profile changes
        # Re-calculates this profile's running totals
        #
        # Expected arguements
        #   $session    - The calling function's GA::Session
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Local variables
        my ($questCount, $pointCount, $xpCount, $cashCount);

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateQuestStats', @_);
        }

        # Go through each quest registered in $self->questHash, updating the
        #   running totals wherever possible
        $questCount = 0;
        $pointCount = 0;
        $xpCount = 0;
        $cashCount = 0;
        foreach my $questObj ($self->ivValues('questHash')) {

            $questCount++;

            if (defined $questObj->questPoints) {

                $pointCount += $questObj->questPoints;
            }

            if (defined $questObj->questXP) {

                $xpCount += $questObj->questXP;
            }

            if (defined $questObj->questCash) {

                $cashCount += $questObj->questCash;
            }
        }

        # Save the totals
        $self->ivPoke('questCount', $questCount);
        $self->ivPoke('questPointCount', $pointCount);
        $self->ivPoke('questXPCount', $xpCount);
        $self->ivPoke('questCashCount', $cashCount);

        # Now go through each character profile, and update its quest stats, too
        foreach my $profObj ($session->ivValues('profHash')) {

            if ($profObj->category eq 'char') {

                $profObj->updateQuestStats($session);
            }
        }

        return 1;
    }

    sub mergeData {

        # Called by GA::Cmd::UpdateWorld->do
        # Merges data from an importable world profile (which hasn't been added to the list of
        #   profiles in memory, or in any saved files) into this profile, as a way of updating this
        #   profile
        #
        # Expected arguments
        #   $otherObj   - A GA::Profile::World which has been read from an importable file
        #   $version    - The Axmud version that saved the importable file
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $otherObj, $version, $check) = @_;

        # Local variables
        my $fileObj;

        # Check for improper arguments
        if (! defined $otherObj || ! defined $version || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->mergeData', @_);
        }

        # (Don't merge ->name, ->category or ->parentWorld)

        # (Don't merge any initial tasks, scripts, missions or commands)

        # (Don't merge ->setupCompleteFlag, ->notepadList or ->privateHash)

        # (Don't merge ->noSaveFlag, ->connectHistoryList, ->telnetOverrideHash, ->mxpOverrideHash,
        #   ->termOverrideHash, ->sigilOverrideHash, ->profHash, ->passwordHash, ->newPasswordHash,
        #   ->accountHash or ->newAccountHash)

        # (Don't merge ->protocol)

        # Merge connection details, but don't merge SSH details
        $self->mergeScalar('dns', $otherObj);
        $self->mergeScalar('ipv4', $otherObj);
        $self->mergeScalar('ipv6', $otherObj);
        $self->mergeScalar('port', $otherObj);

        # (Don't merge previous connection details)

        # Don't merge the long name/description, but do merge URLs
        $self->mergeScalar('worldURL', $otherObj);
        $self->mergeScalar('referURL', $otherObj);

        # (Don't merge termtype or terminal size)

        # Don't merge login details, but do add any login success patterns
        $self->mergeList('loginConnectPatternList', $otherObj);
        $self->mergeList('loginSuccessPatternList', $otherObj);
        $self->ivPoke('loginAccountMode', $otherObj->loginAccountMode);
        $self->mergeList('loginSpecialList', $otherObj);

        # (Don't merge auto-quit details)

        # Merge the command and life status IVs
        $self->ivPoke('autoSeparateCmdFlag', $otherObj->autoSeparateCmdFlag);
        $self->mergeScalar('excessCmdLimit', $otherObj);
        $self->mergeScalar('excessCmdDelay', $otherObj);
        $self->ivPoke('lifeStatusOverrideFlag', $otherObj->lifeStatusOverrideFlag);

        # Merge command prompt patterns but don't merge empty line suppression IVs
        $self->mergeList('cmdPromptPatternList', $otherObj);

        # Don't merge the dictionary IVs but do merge the numbered objects flag
        $self->ivPoke('numberedObjFlag', $otherObj->numberedObjFlag);
        $self->ivPoke('multiplePattern', $otherObj->multiplePattern);

        # (Don't merge logging preferences)

        # Merge age/weight IVs
        $self->mergeScalar('charAgeUnit', $otherObj);
        $self->mergeScalar('weightUnit', $otherObj);
        $self->mergeList('weightUnitStringList', $otherObj);

        # Merge room patterns
        $self->mergeList('darkRoomPatternList', $otherObj);
        $self->mergeList('failExitPatternList', $otherObj);
        $self->mergeList('doorPatternList', $otherObj);
        $self->mergeList('lockedPatternList', $otherObj);
        $self->mergeList('involuntaryExitPatternList', $otherObj);
        $self->mergeList('unspecifiedRoomPatternList', $otherObj);
        $self->mergeList('followPatternList', $otherObj);
        $self->mergeList('followAnchorPatternList', $otherObj);
        $self->mergeList('transientExitPatternList', $otherObj);

        # (Don't merge the Status task's display format list - let the user keep their changes)

        # Merge Status task patterns
        $self->mergeHash('msdpStatusVarHash', $otherObj);
        $self->mergeGroupList('barPatternList', $otherObj, 6);
        $self->mergeGroupList('groupPatternList', $otherObj, 4);
        $self->mergeGroupList('affectPatternList', $otherObj, 3);
        $self->mergeGroupList('statPatternList', $otherObj, 4);
        $self->mergeList('agePatternList', $otherObj);
        $self->mergeList('timePatternList', $otherObj);
        $self->mergeList('statusIgnorePatternList', $otherObj);

        $self->mergeList('deathPatternList', $otherObj);
        $self->mergeList('resurrectPatternList', $otherObj);
        $self->mergeList('passedOutPatternList', $otherObj);
        $self->mergeList('comeAroundPatternList', $otherObj);
        $self->mergeList('fallAsleepPatternList', $otherObj);
        $self->mergeList('wakeUpPatternList', $otherObj);
        $self->mergeList('questCompletePatternList', $otherObj);

        # Merge inventory/condition patterns
        $self->mergeGroupList('inventoryPatternList', $otherObj, 5);
        $self->mergeGroupList('inventoryIgnorePatternList', $otherObj, 2);
        $self->mergeList('inventoryDiscardPatternList', $otherObj);
        $self->mergeList('inventorySplitPatternList', $otherObj);
        $self->ivPoke('inventoryMode', $otherObj->inventoryMode);
        $self->mergeGroupList('conditionPatternList', $otherObj, 4);
        $self->mergeList('conditionIgnorePatternList', $otherObj);

        # Merge fight/interaction patterns
        $self->mergeGroupList('fightStartedPatternList', $otherObj, 2);
        $self->mergeGroupList('cannotFindTargetPatternList', $otherObj, 2);
        $self->mergeGroupList('targetAlreadyDeadPatternList', $otherObj, 2);
        $self->mergeGroupList('targetKilledPatternList', $otherObj, 2);
        $self->mergeGroupList('fightDefeatPatternList', $otherObj, 2);
        $self->mergeGroupList('wimpyEngagedPatternList', $otherObj, 2);
        $self->mergeList('noFightStartedPatternList', $otherObj);
        $self->mergeList('noCannotFindTargetPatternList', $otherObj);
        $self->mergeList('noTargetAlreadyDeadPatternList', $otherObj);
        $self->mergeList('noTargetKilledPatternList', $otherObj);
        $self->mergeList('noFightDefeatPatternList', $otherObj);
        $self->mergeList('noWimpyEngagedPatternList', $otherObj);

        $self->mergeGroupList('interactionStartedPatternList', $otherObj, 2);
        $self->mergeGroupList('cannotInteractPatternList', $otherObj, 2);
        $self->mergeGroupList('interactionSuccessPatternList', $otherObj, 2);
        $self->mergeGroupList('interactionFailPatternList', $otherObj, 2);
        $self->mergeGroupList('interactionFightPatternList', $otherObj, 2);
        $self->mergeGroupList('interactionDisasterPatternList', $otherObj, 2);
        $self->mergeList('noInteractionStartedPatternList', $otherObj);
        $self->mergeList('noCannotInteractPatternList', $otherObj);
        $self->mergeList('noInteractionSuccessPatternList', $otherObj);
        $self->mergeList('noInteractionFailPatternList', $otherObj);
        $self->mergeList('noInteractionFightPatternList', $otherObj);
        $self->mergeList('noInteractionDisasterPatternList', $otherObj);

        $self->mergeGroupList('targetLeavesPatternList', $otherObj, 3);
        $self->mergeGroupList('targetArrivesPatternList', $otherObj, 3);
        $self->mergeList('noTargetLeavesPatternList', $otherObj);
        $self->mergeList('noTargetArrivesPatternList', $otherObj);

        $self->mergeList('noFightsRoomPatternList', $otherObj);
        $self->mergeList('noInteractionsRoomPatternList', $otherObj);

        # Merge get/drop patterns
        $self->mergeList('getSuccessPatternList', $otherObj);
        $self->mergeList('getHeavyPatternList', $otherObj);
        $self->mergeList('getFailPatternList', $otherObj);
        $self->mergeList('dropSuccessPatternList', $otherObj);
        $self->mergeList('dropForbidPatternList', $otherObj);
        $self->mergeList('dropFailPatternList', $otherObj);

        # Merge buy/sell patterns
        $self->mergeList('buySuccessPatternList', $otherObj);
        $self->mergeList('buyPartialPatternList', $otherObj);
        $self->mergeList('buyFailPatternList', $otherObj);
        $self->mergeList('sellSuccessPatternList', $otherObj);
        $self->mergeList('sellPartialPatternList', $otherObj);
        $self->mergeList('sellFailPatternList', $otherObj);

        # Merge Advance task patterns
        $self->mergeList('advanceSuccessPatternList', $otherObj);
        $self->mergeList('advanceFailPatternList', $otherObj);

        # Merge Channels/Divert task patterns
        $self->mergeGroupList('channelList', $otherObj, 3);
        $self->mergeList('noChannelList', $otherObj);

        # Merge currency IVs
        if ($otherObj->currencyHash) {

            # (Replace the whole hash)
            $self->ivPoke('currencyHash', $otherObj->currencyHash);
        }

        $self->ivPoke('standardCurrencyUnit', $otherObj->standardCurrencyUnit);
        $self->ivPoke('currencyRounding', $otherObj->currencyRounding);

        # (Don't merge missions or quests)

        # Merge stats
        if ($otherObj->statHash) {

            # (Replace the whole hash)
            $self->ivPoke('statHash', $otherObj->statHash);
        }

        if ($otherObj->statOrderList) {

            # (Replace the whole list)
            $self->ivPoke('statOrderList', $otherObj->statOrderList);
        }

        # (Don't merge status/inventory command hashes - let the user retain their own preferred
        #   values)

        # Merge room statement components, replacing the entire lists
        $self->mergeHash('componentHash', $otherObj);
        if ($otherObj->verboseComponentList) {

            $self->ivPoke('verboseComponentList', $otherObj->verboseComponentList);
        }

        if ($otherObj->shortComponentList) {

            $self->ivPoke('shortComponentList', $otherObj->shortComponentList);
        }

        if ($otherObj->briefComponentList) {

            $self->ivPoke('briefComponentList', $otherObj->briefComponentList);
        }

        # Merge basic mapping mode
        $self->ivPoke('basicMappingFlag', $otherObj->basicMappingFlag);
        $self->mergeList('notAnchorPatternList', $otherObj);

        # Merge room statement patterns
        $self->mergeList('verboseAnchorPatternList', $otherObj);
        $self->ivPoke('verboseAnchorOffset', $otherObj->verboseAnchorOffset);
        $self->mergeList('verboseAnchorCheckList', $otherObj);
        $self->mergeList('shortAnchorPatternList', $otherObj);
        $self->ivPoke('shortAnchorOffset', $otherObj->shortAnchorOffset);
        $self->mergeList('shortAnchorCheckList', $otherObj);
        $self->mergeList('briefAnchorPatternList', $otherObj);
        $self->ivPoke('briefAnchorOffset', $otherObj->briefAnchorOffset);
        $self->mergeList('briefAnchorCheckList', $otherObj);

        $self->mergeList('verboseExitDelimiterList', $otherObj);
        $self->mergeList('verboseExitNonDelimiterList', $otherObj);
        $self->ivPoke('verboseExitSplitCharFlag', $otherObj->verboseExitSplitCharFlag);
        $self->mergeList('verboseExitLeftMarkerList', $otherObj);
        $self->mergeList('verboseExitRightMarkerList', $otherObj);

        $self->mergeList('briefExitDelimiterList', $otherObj);
        $self->mergeList('briefExitNonDelimiterList', $otherObj);
        $self->ivPoke('briefExitSplitCharFlag', $otherObj->briefExitSplitCharFlag);
        $self->mergeList('briefExitLeftMarkerList', $otherObj);
        $self->mergeList('briefExitRightMarkerList', $otherObj);

        $self->mergeList('exitInfoPatternList', $otherObj);
        $self->mergeList('exitRemovePatternList', $otherObj);
        $self->mergeGroupList('exitStateStringList', $otherObj, 4);
        $self->mergeList('exitStatePatternList', $otherObj);
        $self->mergeHash('exitAliasHash', $otherObj);

        $self->mergeList('contentPatternList', $otherObj);
        $self->mergeHash('specialPatternHash', $otherObj);

        $self->mergeList('roomCmdDelimiterList', $otherObj);
        $self->mergeList('roomCmdNonDelimiterList', $otherObj);
        $self->ivPoke('roomCmdSplitCharFlag', $otherObj->roomCmdSplitCharFlag);
        $self->mergeList('roomCmdLeftMarkerList', $otherObj);
        $self->mergeList('roomCmdRightMarkerList', $otherObj);
        $self->mergeList('roomCmdIgnoreList', $otherObj);

        $self->ivPoke('verboseFinalPattern', $otherObj->verboseFinalPattern);
        $self->ivPoke('shortFinalPattern', $otherObj->shortFinalPattern);
        $self->ivPoke('briefFinalPattern', $otherObj->briefFinalPattern);

        # If the importable world profile was saved by a previous version of Axmud, we may need to
        #   modify some of the data imported into this profile to work with the current version of
        #   Axmud
        $fileObj = $axmud::CLIENT->ivShow('fileObjHash', $self->name);
        $fileObj->updateExtractedData($axmud::CLIENT->convertVersion($version));

        # Merge complete
        return 1;
    }

    sub mergeScalar {

        # Called by $self->mergeData during an ';updateworld' operation
        # Merges a single scalar IV. If the value stored in the importable world profile is defined,
        #   copy it to the current world profile; otherwise, do nothing
        #
        # Expected arguments
        #   $iv         - The IV to merge
        #   $otherObj   - A GA::Profile::World which has been read from an importable file
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $iv, $otherObj, $check) = @_;

        # Check for improper arguments
        if (! defined $iv || ! defined $otherObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->mergeScalar', @_);
        }

        if (defined $otherObj->$iv) {

            $self->ivPoke($iv, $otherObj->$iv);
        }

        return 1;
    }

    sub mergeList {

        # Called by $self->mergeData during an ';updateworld' operation
        # Merges a single list IV. Copies values stored in the importable world profile's list into
        #   into the current world profile's list, unless they already exist there. (Duplicates in
        #   the importable world profile's list are eliminated)
        #
        # Expected arguments
        #   $iv         - The IV to merge
        #   $otherObj   - A GA::Profile::World which has been read from an importable file
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $iv, $otherObj, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (! defined $iv || ! defined $otherObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->mergeList', @_);
        }

        # Get the contents of the importable world profile's list IV
        @list = $otherObj->$iv;

        foreach my $item (@list) {

            # If the item doesn't already exist in the current world profile's IV...
            if (! defined $self->ivFind($iv, $item)) {

                $self->ivPush($iv, $item);
            }
        }

        return 1;
    }

    sub mergeGroupList {

        # Called by $self->mergeData during an ';updateworld' operation
        # Merges a single list IV whose items are in groups, e.g. $self->fightStartedPatternList
        #   whose items are in groups of two, in the form
        #       (pattern, group_substring_number, pattern, group_substring_number...)
        # Copies groups of values stored in the importable world profile's list into the current
        #   world profile's list, unless the FIRST value in the importable group already exists as a
        #   FIRST value in the current group. (Groups in the importable world profile's list with a
        #   duplicate FIRST value are eliminated)
        #
        # Expected arguments
        #   $iv         - The IV to merge
        #   $otherObj   - A GA::Profile::World which has been read from an importable file
        #   $size       - The number of items in each group
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $iv, $otherObj, $size, $check) = @_;

        # Local variables
        my (@currentList, @otherList);

        # Check for improper arguments
        if (! defined $iv || ! defined $otherObj || ! defined $size || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->mergeGroupList', @_);
        }

        # Get the contents of both list IVs
        @currentList = $self->$iv;
        @otherList = $otherObj->$iv;

        if (! @currentList) {

            # Don't have to check that the first item in every group already exists
            $self->ivPoke($iv, @otherList);

        } elsif (@otherList) {

            do {

                my (
                    $matchFlag,
                    @groupList,
                );

                # Get a group of $size items from @otherList
                for (my $count = 0; $count < $size; $count++) {

                    push (@groupList, shift @otherList);
                }

                # Does the first item in @groupList match the first item of any group in
                #   @currentList?
                OUTER: for (my $index = 0; $index < scalar @currentList; $index += $size) {

                    if ($groupList[0] eq $currentList[$index]) {

                        $matchFlag = TRUE;
                        last OUTER;
                    }
                }

                if (! $matchFlag) {

                    # The first tiem in @groupList doesn't already exist in the current world
                    #   profile's list IV, so copy the whole group into it
                    push (@currentList, @groupList);
                }

            } until (! @otherList);


            # Update the IV
            $self->ivPoke($iv, @currentList);
        }

        return 1;
    }

    sub mergeHash {

        # Called by $self->mergeData during an ';updateworld' operation
        # Merges a single hash IV. Copies key-value pairs stored in the importable world profile's
        #   hash into the current world profile's hash, replacing any identical keys which are
        #   already there
        # (It's just a standard Perl %hash = (%hash2, %hash3) operation)
        #
        # Expected arguments
        #   $iv         - The IV to merge
        #   $otherObj   - A GA::Profile::World which has been read from an importable file
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $iv, $otherObj, $check) = @_;

        # Local variables
        my (%currentHash, %otherHash, %newHash);

        # Check for improper arguments
        if (! defined $iv || ! defined $otherObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->mergeHash', @_);
        }

        # Get the contents of both hash IVs
        %currentHash = $self->$iv;
        %otherHash = $otherObj->$iv;

        # Merge the hashes
        %newHash = (%currentHash, %otherHash);
        # Update the IV
        $self->ivPoke($iv, %newHash);

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub noSaveFlag
        { $_[0]->{noSaveFlag} }
    sub connectHistoryList
        { my $self = shift; return @{$self->{connectHistoryList}}; }

    sub telnetOverrideHash
        { my $self = shift; return %{$self->{telnetOverrideHash}}; }
    sub mxpOverrideHash
        { my $self = shift; return %{$self->{mxpOverrideHash}}; }
    sub termOverrideHash
        { my $self = shift; return %{$self->{termOverrideHash}}; }
    sub sigilOverrideHash
        { my $self = shift; return %{$self->{sigilOverrideHash}}; }

    sub profHash
        { my $self = shift; return %{$self->{profHash}}; }
    sub passwordHash
        { my $self = shift; return %{$self->{passwordHash}}; }
    sub newPasswordHash
        { my $self = shift; return %{$self->{newPasswordHash}}; }
    sub accountHash
        { my $self = shift; return %{$self->{accountHash}}; }
    sub newAccountHash
        { my $self = shift; return %{$self->{newAccountHash}}; }

    sub protocol
        { $_[0]->{protocol} }

    sub dns
        { $_[0]->{dns} }
    sub ipv4
        { $_[0]->{ipv4} }
    sub ipv6
        { $_[0]->{ipv6} }
    sub port
        { $_[0]->{port} }
    sub sshUserName
        { $_[0]->{sshUserName} }
    sub sshPassword
        { $_[0]->{sshPassword} }
    sub sshPortFlag
        { $_[0]->{sshPortFlag} }

    sub lastConnectDate
        { $_[0]->{lastConnectDate} }
    sub lastConnectTime
        { $_[0]->{lastConnectTime} }
    sub numberConnects
        { $_[0]->{numberConnects} }
    sub lastConnectChar
        { $_[0]->{lastConnectChar} }

    sub longName
        { $_[0]->{longName} }
    sub adultFlag
        { $_[0]->{adultFlag} }
    sub worldURL
        { $_[0]->{worldURL} }
    sub referURL
        { $_[0]->{referURL} }
    sub worldDescrip
        { $_[0]->{worldDescrip} }
    sub worldHint
        { $_[0]->{worldHint} }
    sub worldCharSet
        { $_[0]->{worldCharSet} }

    sub termType
        { $_[0]->{termType} }
    sub columns
        { $_[0]->{columns} }
    sub rows
        { $_[0]->{rows} }
    sub sendSizeInfoFlag
        { $_[0]->{sendSizeInfoFlag} }

    sub msspGenericValueHash
        { my $self = shift; return %{$self->{msspGenericValueHash}}; }
    sub msspCustomValueHash
        { my $self = shift; return %{$self->{msspCustomValueHash}}; }

    sub loginMode
        { $_[0]->{loginMode} }
    sub loginCmdList
        { my $self = shift; return @{$self->{loginCmdList}}; }
    sub loginObjName
        { $_[0]->{loginObjName} }
    sub loginConnectPatternList
        { my $self = shift; return @{$self->{loginConnectPatternList}}; }
    sub loginSuccessPatternList
        { my $self = shift; return @{$self->{loginSuccessPatternList}}; }
    sub loginAccountMode
        { $_[0]->{loginAccountMode} }
    sub loginSpecialList
        { my $self = shift; return @{$self->{loginSpecialList}}; }

    sub autoQuitMode
        { $_[0]->{autoQuitMode} }
    sub autoQuitCmdList
        { my $self = shift; return @{$self->{autoQuitCmdList}}; }
    sub autoQuitObjName
        { $_[0]->{autoQuitObjName} }

    sub autoSeparateCmdFlag
        { $_[0]->{autoSeparateCmdFlag} }
    sub excessCmdLimit
        { $_[0]->{excessCmdLimit} }
    sub excessCmdDelay
        { $_[0]->{excessCmdDelay} }
    sub lifeStatusOverrideFlag
        { $_[0]->{lifeStatusOverrideFlag} }

    sub cmdPromptPatternList
        { my $self = shift; return @{$self->{cmdPromptPatternList}}; }
    sub strictPromptsMode
        { $_[0]->{strictPromptsMode} }
    sub suppressEmptyLineCount
        { $_[0]->{suppressEmptyLineCount} }
    sub suppressBeforeLoginFlag
        { $_[0]->{suppressBeforeLoginFlag} }

    sub dict
        { $_[0]->{dict} }
    sub collectUnknownWordFlag
        { $_[0]->{collectUnknownWordFlag} }
    sub collectContentsFlag
        { $_[0]->{collectContentsFlag} }
    sub numberedObjFlag
        { $_[0]->{numberedObjFlag} }
    sub multiplePattern
        { $_[0]->{multiplePattern} }

    sub logPrefHash
        { my $self = shift; return %{$self->{logPrefHash}}; }

    sub charAgeUnit
        { $_[0]->{charAgeUnit} }
    sub weightUnit
        { $_[0]->{weightUnit} }
    sub weightUnitStringList
        { $_[0]->{weightUnitStringList} }

    sub darkRoomPatternList
        { my $self = shift; return @{$self->{darkRoomPatternList}}; }
    sub failExitPatternList
        { my $self = shift; return @{$self->{failExitPatternList}}; }
    sub doorPatternList
        { my $self = shift; return @{$self->{doorPatternList}}; }
    sub lockedPatternList
        { my $self = shift; return @{$self->{lockedPatternList}}; }
    sub involuntaryExitPatternList
        { my $self = shift; return @{$self->{involuntaryExitPatternList}}; }
    sub unspecifiedRoomPatternList
        { my $self = shift; return @{$self->{unspecifiedRoomPatternList}}; }
    sub followPatternList
        { my $self = shift; return @{$self->{followPatternList}}; }
    sub followAnchorPatternList
        { my $self = shift; return @{$self->{followAnchorPatternList}}; }
    sub transientExitPatternList
        { my $self = shift; return @{$self->{transientExitPatternList}}; }

    sub statusFormatList
        { my $self = shift; return @{$self->{statusFormatList}}; }
    sub gaugeFormatList
        { my $self = shift; return @{$self->{gaugeFormatList}}; }
    sub msdpStatusVarHash
        { my $self = shift; return %{$self->{msdpStatusVarHash}}; }
    sub barPatternList
        { my $self = shift; return @{$self->{barPatternList}}; }
    sub groupPatternList
        { my $self = shift; return @{$self->{groupPatternList}}; }
    sub affectPatternList
        { my $self = shift; return @{$self->{affectPatternList}} }
    sub statPatternList
        { my $self = shift; return @{$self->{statPatternList}} }
    sub agePatternList
        { my $self = shift; return @{$self->{agePatternList}}; }
    sub timePatternList
        { my $self = shift; return @{$self->{timePatternList}}; }
    sub statusIgnorePatternList
        { my $self = shift; return @{$self->{statusIgnorePatternList}}; }

    sub deathPatternList
        { my $self = shift; return @{$self->{deathPatternList}}; }
    sub resurrectPatternList
        { my $self = shift; return @{$self->{resurrectPatternList}}; }
    sub passedOutPatternList
        { my $self = shift; return @{$self->{passedOutPatternList}}; }
    sub comeAroundPatternList
        { my $self = shift; return @{$self->{comeAroundPatternList}}; }
    sub fallAsleepPatternList
        { my $self = shift; return @{$self->{fallAsleepPatternList}}; }
    sub wakeUpPatternList
        { my $self = shift; return @{$self->{wakeUpPatternList}}; }
    sub questCompletePatternList
        { my $self = shift; return @{$self->{questCompletePatternList}}; }

    sub inventoryPatternList
        { my $self = shift; return @{$self->{inventoryPatternList}}; }
    sub inventoryIgnorePatternList
        { my $self = shift; return @{$self->{inventoryIgnorePatternList}}; }
    sub inventoryDiscardPatternList
        { my $self = shift; return @{$self->{inventoryDiscardPatternList}}; }
    sub inventorySplitPatternList
        { my $self = shift; return @{$self->{inventorySplitPatternList}}; }
    sub inventoryMode
        { $_[0]->{inventoryMode} }

    sub conditionPatternList
        { my $self = shift; return @{$self->{conditionPatternList}}; }
    sub conditionIgnorePatternList
        { my $self = shift; return @{$self->{conditionIgnorePatternList}}; }

    sub fightStartedPatternList
        { my $self = shift; return @{$self->{fightStartedPatternList}}; }
    sub cannotFindTargetPatternList
        { my $self = shift; return @{$self->{cannotFindTargetPatternList}}; }
    sub targetAlreadyDeadPatternList
        { my $self = shift; return @{$self->{targetAlreadyDeadPatternList}}; }
    sub targetKilledPatternList
        { my $self = shift; return @{$self->{targetKilledPatternList}}; }
    sub fightDefeatPatternList
        { my $self = shift; return @{$self->{fightDefeatPatternList}}; }
    sub wimpyEngagedPatternList
        { my $self = shift; return @{$self->{wimpyEngagedPatternList}}; }
    sub noFightStartedPatternList
        { my $self = shift; return @{$self->{noFightStartedPatternList}}; }
    sub noCannotFindTargetPatternList
        { my $self = shift; return @{$self->{noCannotFindTargetPatternList}}; }
    sub noTargetAlreadyDeadPatternList
        { my $self = shift; return @{$self->{noTargetAlreadyDeadPatternList}}; }
    sub noTargetKilledPatternList
        { my $self = shift; return @{$self->{noTargetKilledPatternList}}; }
    sub noFightDefeatPatternList
        { my $self = shift; return @{$self->{noFightDefeatPatternList}}; }
    sub noWimpyEngagedPatternList
        { my $self = shift; return @{$self->{noWimpyEngagedPatternList}}; }

    sub interactionStartedPatternList
        { my $self = shift; return @{$self->{interactionStartedPatternList}}; }
    sub cannotInteractPatternList
        { my $self = shift; return @{$self->{cannotInteractPatternList}}; }
    sub interactionSuccessPatternList
        { my $self = shift; return @{$self->{interactionSuccessPatternList}}; }
    sub interactionFailPatternList
        { my $self = shift; return @{$self->{interactionFailPatternList}}; }
    sub interactionFightPatternList
        { my $self = shift; return @{$self->{interactionFightPatternList}}; }
    sub interactionDisasterPatternList
        { my $self = shift; return @{$self->{interactionDisasterPatternList}}; }
    sub noInteractionStartedPatternList
        { my $self = shift; return @{$self->{noInteractionStartedPatternList}}; }
    sub noCannotInteractPatternList
        { my $self = shift; return @{$self->{noCannotInteractPatternList}}; }
    sub noInteractionSuccessPatternList
        { my $self = shift; return @{$self->{noInteractionSuccessPatternList}}; }
    sub noInteractionFailPatternList
        { my $self = shift; return @{$self->{noInteractionFailPatternList}}; }
    sub noInteractionFightPatternList
        { my $self = shift; return @{$self->{noInteractionFightPatternList}}; }
    sub noInteractionDisasterPatternList
        { my $self = shift; return @{$self->{noInteractionDisasterPatternList}}; }

    sub targetLeavesPatternList
        { my $self = shift; return @{$self->{targetLeavesPatternList}}; }
    sub targetArrivesPatternList
        { my $self = shift; return @{$self->{targetArrivesPatternList}}; }
    sub noTargetLeavesPatternList
        { my $self = shift; return @{$self->{noTargetLeavesPatternList}}; }
    sub noTargetArrivesPatternList
        { my $self = shift; return @{$self->{noTargetArrivesPatternList}}; }

    sub noFightsRoomPatternList
        { my $self = shift; return @{$self->{noFightsRoomPatternList}}; }
    sub noInteractionsRoomPatternList
        { my $self = shift; return @{$self->{noInteractionsRoomPatternList}}; }

    sub getSuccessPatternList
        { my $self = shift; return @{$self->{getSuccessPatternList}}; }
    sub getHeavyPatternList
        { my $self = shift; return @{$self->{getHeavyPatternList}}; }
    sub getFailPatternList
        { my $self = shift; return @{$self->{getFailPatternList}}; }
    sub dropSuccessPatternList
        { my $self = shift; return @{$self->{dropSuccessPatternList}}; }
    sub dropForbidPatternList
        { my $self = shift; return @{$self->{dropForbidPatternList}}; }
    sub dropFailPatternList
        { my $self = shift; return @{$self->{dropFailPatternList}}; }

    sub buySuccessPatternList
        { my $self = shift; return @{$self->{buySuccessPatternList}}; }
    sub buyPartialPatternList
        { my $self = shift; return @{$self->{buyPartialPatternList}}; }
    sub buyFailPatternList
        { my $self = shift; return @{$self->{buyFailPatternList}}; }
    sub sellSuccessPatternList
        { my $self = shift; return @{$self->{sellSuccessPatternList}}; }
    sub sellPartialPatternList
        { my $self = shift; return @{$self->{sellPartialPatternList}}; }
    sub sellFailPatternList
        { my $self = shift; return @{$self->{sellFailPatternList}}; }

    sub advanceSuccessPatternList
        { my $self = shift; return @{$self->{advanceSuccessPatternList}}; }
    sub advanceFailPatternList
        { my $self = shift; return @{$self->{advanceFailPatternList}}; }

    sub channelList
        { my $self = shift; return @{$self->{channelList}}; }
    sub noChannelList
        { my $self = shift; return @{$self->{noChannelList}}; }

    sub currencyHash
        { my $self = shift; return %{$self->{currencyHash}}; }
    sub standardCurrencyUnit
        { $_[0]->{standardCurrencyUnit} }
    sub currencyRounding
        { $_[0]->{currencyRounding} }

    sub missionHash
        { my $self = shift; return %{$self->{missionHash}}; }

    sub questHash
        { my $self = shift; return %{$self->{questHash}}; }
    sub questCount
        { $_[0]->{questCount} }
    sub questPointCount
        { $_[0]->{questPointCount} }
    sub questXPCount
        { $_[0]->{questXPCount} }
    sub questCashCount
        { $_[0]->{questCashCount} }

    sub statHash
        { my $self = shift; return %{$self->{statHash}}; }
    sub statOrderList
        { my $self = shift; return @{$self->{statOrderList}}; }

    sub statusCmdHash
        { my $self = shift; return %{$self->{statusCmdHash}}; }
    sub inventoryCmdHash
        { my $self = shift; return %{$self->{inventoryCmdHash}}; }

    sub componentHash
        { my $self = shift; return %{$self->{componentHash}}; }
    sub verboseComponentList
        { my $self = shift; return @{$self->{verboseComponentList}}; }
    sub shortComponentList
        { my $self = shift; return @{$self->{shortComponentList}}; }
    sub briefComponentList
        { my $self = shift; return @{$self->{briefComponentList}}; }

    sub basicMappingFlag
        { $_[0]->{basicMappingFlag} }
    sub notAnchorPatternList
        { my $self = shift; return @{$self->{notAnchorPatternList}}; }

    sub verboseAnchorPatternList
        { my $self = shift; return @{$self->{verboseAnchorPatternList}}; }
    sub verboseAnchorOffset
        { $_[0]->{verboseAnchorOffset} }
    sub verboseAnchorCheckList
        { my $self = shift; return @{$self->{verboseAnchorCheckList}}; }
    sub shortAnchorPatternList
        { my $self = shift; return @{$self->{shortAnchorPatternList}}; }
    sub shortAnchorOffset
        { $_[0]->{shortAnchorOffset} }
    sub shortAnchorCheckList
        { my $self = shift; return @{$self->{shortAnchorCheckList}}; }
    sub briefAnchorPatternList
        { my $self = shift; return @{$self->{briefAnchorPatternList}}; }
    sub briefAnchorOffset
        { $_[0]->{briefAnchorOffset} }
    sub briefAnchorCheckList
        { my $self = shift; return @{$self->{briefAnchorCheckList}}; }

    sub verboseExitDelimiterList
        { my $self = shift; return @{$self->{verboseExitDelimiterList}}; }
    sub verboseExitNonDelimiterList
        { my $self = shift; return @{$self->{verboseExitNonDelimiterList}}; }
    sub verboseExitSplitCharFlag
        { $_[0]->{verboseExitSplitCharFlag} }
    sub verboseExitLeftMarkerList
        { my $self = shift; return @{$self->{verboseExitLeftMarkerList}}; }
    sub verboseExitRightMarkerList
        { my $self = shift; return @{$self->{verboseExitRightMarkerList}}; }

    sub briefExitDelimiterList
        { my $self = shift; return @{$self->{briefExitDelimiterList}}; }
    sub briefExitNonDelimiterList
        { my $self = shift; return @{$self->{briefExitNonDelimiterList}}; }
    sub briefExitSplitCharFlag
        { $_[0]->{briefExitSplitCharFlag} }
    sub briefExitLeftMarkerList
        { my $self = shift; return @{$self->{briefExitLeftMarkerList}}; }
    sub briefExitRightMarkerList
        { my $self = shift; return @{$self->{briefExitRightMarkerList}}; }

    sub exitInfoPatternList
        { my $self = shift; return @{$self->{exitInfoPatternList}}; }
    sub exitRemovePatternList
        { my $self = shift; return @{$self->{exitRemovePatternList}}; }
    sub exitStateStringList
        { my $self = shift; return @{$self->{exitStateStringList}}; }
    sub exitStatePatternList
        { my $self = shift; return @{$self->{exitStatePatternList}}; }
    sub exitAliasHash
        { my $self = shift; return %{$self->{exitAliasHash}}; }

    sub contentPatternList
        { my $self = shift; return @{$self->{contentPatternList}}; }
    sub specialPatternHash
        { my $self = shift; return %{$self->{specialPatternHash}}; }

    sub roomCmdDelimiterList
        { my $self = shift; return @{$self->{roomCmdDelimiterList}}; }
    sub roomCmdNonDelimiterList
        { my $self = shift; return @{$self->{roomCmdNonDelimiterList}}; }
    sub roomCmdSplitCharFlag
        { $_[0]->{roomCmdSplitCharFlag} }
    sub roomCmdLeftMarkerList
        { my $self = shift; return @{$self->{roomCmdLeftMarkerList}}; }
    sub roomCmdRightMarkerList
        { my $self = shift; return @{$self->{roomCmdRightMarkerList}}; }
    sub roomCmdIgnoreList
        { my $self = shift; return @{$self->{roomCmdIgnoreList}}; }

    sub verboseFinalPattern
        { $_[0]->{verboseFinalPattern} }
    sub shortFinalPattern
        { $_[0]->{shortFinalPattern} }
    sub briefFinalPattern
        { $_[0]->{briefFinalPattern} }
}

{ package Games::Axmud::Profile::Guild;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Profile Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by any function
        # Creates a new instance of the guild profile
        #
        # Expected arguments
        #   $session     - The GA::Session which called this function (not stored as an IV)
        #   $name        - A unique string name for this profile (max 16 chars, containing
        #                    A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable.
        #                    Must not exist as a key in the global hash of reserved names,
        #                    $axmud::CLIENT->constReservedHash)
        #   $parentWorld - The name of the parent world profile, with which this profile is
        #                    associated
        #
        # Optional arguments
        #   $tempFlag   - If set to TRUE, this is a temporary profile created for use with an 'edit'
        #                   window; $name is not checked for validity. Otherwise set to FALSE (or
        #                   'undef')
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $parentWorld, $tempFlag, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $parentWorld
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        if (! $tempFlag) {

            # Check that $name is valid and not already in use by another profile
            if (! $axmud::CLIENT->nameCheck($name, 16)) {

                return $axmud::CLIENT->writeError(
                    'Registry naming error: invalid name \'' . $name . '\'',
                    $class . '->new',
                );

            } elsif ($session->ivExists('profHash', $name)) {

                return $axmud::CLIENT->writeError(
                    'Registry naming error: profile \'' . $name . '\' already exists',
                    $class . '->new',
                );
            }
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,       # All IVs are public

            # Standard profile IVs
            # --------------------

            name                        => $name,
            category                    => 'guild',
            # The name of parent world profile, with which this profile is associated
            parentWorld                 => $parentWorld,

            # Hash of tasks that start whenever this profile is made a current profile (as soon as
            #   the character is marked as 'logged in') - the profile's initial tasklist. Hash in
            #   the form
            #       $initTaskHash{unique_task_name} = blessed_reference_to_task_object
            initTaskHash                => {},
            # The order in which the tasks are started (not very important for tasks unless they
            #   are Script tasks). List contains all the keys in $self->initTaskHash
            initTaskOrderList           => [],
            # How many initial tasks have been created, in total (used to give each one a unique
            #   name). Reset to 0 when the profile's initial tasklist is emptied
            initTaskTotal               => 0,
            # Hash of scripts that start whenever this definiton is made a current profile (as soon
            #   as the character is marked as 'logged in') - the profile's initial scriptlist. Hash
            #   in the form
            #       $initScriptHash{script_name} = mode
            # ...where 'script_name' matches the file from which the script is loaded, and 'mode' is
            #   set to one of the following value:
            #       'no_task'       - run the script without a task
            #       'run_task'      - run the script from within a task
            #       'run_task_win'  - run the script from within a task, in 'forced window' mode
            initScriptHash              => {},
            # The order in which the scripts are started. List contains all the keys in
            #   $self->initScriptHash
            initScriptOrderList         => [],
            # The name of the mission to start whenever a new session begins with this as a current
            #   profile, as soon as the character is marked as logged in - but NOT when a current
            #   profile is set after the login
            # Profiles are checked in priority order; only the first mission found is run. Set to
            #   the name of the mission, or 'undef'
            initMission                 => undef,
            # A list of commands to send the the world whenever a new session begins with this as a
            #   current profile, as soon as the character is marked as logged in - but NOT when a
            #   current profile is set after the login
            # Profiles are checked in priority order; commands are sent from all profiles, but
            #   duplicate commands are not sent
            # Commands are sent AFTER the commands specified by the current world profile's
            #   ->columns, ->rows and ->sendSizeInfoFlag IVs (so this list doesn't need to include
            #   them)
            initCmdList                 => [],

            # Flag set to TRUE if this profile has EVER been a current profile (in which case, it
            #   will have cages etc); set to FALSE if not (in which case, the parent file object
            #   will set up cages etc when this profile first becomes a current profile)
            setupCompleteFlag           => FALSE,
            # List containing notes written by this user for this profile, and available to the
            #   Notepad task when it's running
            notepadList                 => [],
            # A hash to store any data your own plugins/scripts want to store (when a profile is
            #   cloned, this data is not copied to the clone)
            privateHash                 => {},

            # Guild profile IVs
            # -----------------

            # Complete list of guild-specific commands for this guild (character-independent)
            cmdList                     => [],
            # List of fight patterns (e.g. 'You hit (.*) with your spear') used with this guild
            #   (groups of 2)
            #   [0] - the pattern to match
            #   [1] - the number of the group substring that contains the assailant (set to 0 if it
            #           doesn't)
            fightMsgList                => [],
            # List of interaction patterns (e.g. 'You curse (.*) with your magic wand') used with
            #   this guild (groups of 2)
            #   [0] - the pattern to match
            #   [1] - the number of the group substring that contains the victim (set to 0 if it
            #           doesn't)
            interactionMsgList          => [],

            # The progression of skills. These variables store the default progression for the
            #   guild; this is copied to the character profile (whenever 'factory settings' need
            #   to be restored), where the character's own skill progression is stored
            # Complete list of skills for this guild
            skillList                   => [],
            # maximum possible level, e.g. 'fighting' => 100
            skillMaxLevelHash           => {},
            # What method is used to advance skills
            # 'order' - advance skills in a pre-determined order
            # 'cycle' - advance skills on a repeating cycle
            # 'combo' - advance skills in the pre-determined order then, when that list is
            #   exhausted, start advancing skills in the repeating cycle
            advanceMethod               => 'order',
            # The pre-determined list of skills (an empty list if not used)
            advanceOrderList            => [],
            # The pre-determined cycle of skills (an empty list if not used)
            advanceCycleList            => [],
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    sub clone {

        # Creates a clone of an existing guild profile
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $name       - A unique string name for this profile (max 16 chars, containing
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

        # Check that $name is valid and not already in use by another profile
        if (! $axmud::CLIENT->nameCheck($name, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $self->_objClass . '->clone',
            );

        } elsif ($session->ivExists('profHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: profile \'' . $name . '\' already exists',
                $self->_objClass . '->clone',
            );
        }

        # Setup
        my $clone = {
            _objName                    => $name,
            _objClass                   => $self->_objClass,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,           # All IVs are public

            # Standard profile IVs
            # --------------------

            name                        => $name,
            category                    => $self->category,
            parentWorld                 => undef,

            initTaskHash                => {},              # Set below
            initTaskOrderList           => [],              # Set below
            initTaskTotal               => $self->initTaskTotal,
            initScriptHash              => {},              # Set below
            initScriptOrderList         => [],              # Set below
            initMission                 => $self->initMission,
            initCmdList                 => [$self->initCmdList],

            setupCompleteFlag           => FALSE,           # Clone never been a current profile
            notepadList                 => [$self->notepadList],
            privateHash                 => {},

            # Guild profile IVs
            # -----------------

            cmdList                     => [$self->cmdList],
            fightMsgList                => [$self->fightMsgList],
            interactionMsgList          => [$self->interactionMsgList],

            skillList                   => [$self->skillList],
            skillMaxLevelHash           => {$self->skillMaxLevelHash},
            advanceMethod               => $self->advanceMethod,
            advanceOrderList            => [$self->advanceOrderList],
            advanceCycleList            => [$self->advanceCycleList],
        };

        # Bless the cloned object into existence
        bless $clone, $self->_objClass;

        # Also need to clone everything in the initial tasklist
        $clone->cloneInitTaskList($self);

        return $clone;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub cmdList
        { my $self = shift; return @{$self->{cmdList}}; }
    sub fightMsgList
        { my $self = shift; return @{$self->{fightMsgList}}; }
    sub interactionMsgList
        { my $self = shift; return @{$self->{interactionMsgList}}; }

    sub skillList
        { my $self = shift; return @{$self->{skillList}}; }
    sub skillMaxLevelHash
        { my $self = shift; return %{$self->{skillMaxLevelHash}}; }
    sub advanceMethod
        { $_[0]->{advanceMethod} }
    sub advanceOrderList
        { my $self = shift; return @{$self->{advanceOrderList}}; }
    sub advanceCycleList
        { my $self = shift; return @{$self->{advanceCycleList}}; }
}

{ package Games::Axmud::Profile::Race;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Profile Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by any function
        # Creates a new instance of the race profile
        #
        # Expected arguments
        #   $session     - The GA::Session which called this function (not stored as an IV)
        #   $name        - A unique string name for this profile (max 16 chars, containing
        #                    A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable.
        #                    Must not exist as a key in the global hash of reserved names,
        #                    $axmud::CLIENT->constReservedHash)
        #   $parentWorld - The name of the parent world profile, with which this profile is
        #                    associated
        #
        # Optional arguments
        #   $tempFlag   - If set to TRUE, this is a temporary profile created for use with an 'edit'
        #                   window; $name is not checked for validity. Otherwise set to FALSE (or
        #                   'undef')
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $parentWorld, $tempFlag, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $parentWorld
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        if (! $tempFlag) {

            # Check that $name is valid and not already in use by another profile
            if (! $axmud::CLIENT->nameCheck($name, 16)) {

                return $axmud::CLIENT->writeError(
                    'Registry naming error: invalid name \'' . $name . '\'',
                    $class . '->new',
                );

            } elsif ($session->ivExists('profHash', $name)) {

                return $axmud::CLIENT->writeError(
                    'Registry naming error: profile \'' . $name . '\' already exists',
                    $class . '->new',
                );
            }
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,       # All IVs are public

            # Standard profile IVs
            # --------------------

            name                        => $name,
            category                    => 'race',
            # The name of parent world profile, with which this profile is associated
            parentWorld                 => $parentWorld,

            # Hash of tasks that start whenever this profile is made a current profile (as soon as
            #   the character is marked as 'logged in') - the profile's initial tasklist. Hash in
            #   the form
            #       $initTaskHash{unique_task_name} = blessed_reference_to_task_object
            initTaskHash                => {},
            # The order in which the tasks are started (not very important for tasks unless they
            #   are Script tasks). List contains all the keys in $self->initTaskHash
            initTaskOrderList           => [],
            # How many initial tasks have been created, in total (used to give each one a unique
            #   name). Reset to 0 when the profile's initial tasklist is emptied
            initTaskTotal               => 0,
            # Hash of scripts that start whenever this definiton is made a current profile (as soon
            #   as the character is marked as 'logged in') - the profile's initial scriptlist. Hash
            #   in the form
            #       $initScriptHash{script_name} = mode
            # ...where 'script_name' matches the file from which the script is loaded, and 'mode' is
            #   set to one of the following value:
            #       'no_task'       - run the script without a task
            #       'run_task'      - run the script from within a task
            #       'run_task_win'  - run the script from within a task, in 'forced window' mode
            initScriptHash              => {},
            # The order in which the scripts are started. List contains all the keys in
            #   $self->initScriptHash
            initScriptOrderList         => [],
            # The name of the mission to start whenever a new session begins with this as a current
            #   profile, as soon as the character is marked as logged in - but NOT when a current
            #   profile is set after the login
            # Profiles are checked in priority order; only the first mission found is run. Set to
            #   the name of the mission, or 'undef'
            initMission                 => undef,
            # A list of commands to send the the world whenever a new session begins with this as a
            #   current profile, as soon as the character is marked as logged in - but NOT when a
            #   current profile is set after the login
            # Profiles are checked in priority order; commands are sent from all profiles, but
            #   duplicate commands are not sent
            # Commands are sent AFTER the commands specified by the current world profile's
            #   ->columns, ->rows and ->sendSizeInfoFlag IVs (so this list doesn't need to include
            #   them)
            initCmdList                 => [],

            # Flag set to TRUE if this profile has EVER been a current profile (in which case, it
            #   will have cages etc); set to FALSE if not (in which case, the parent file object
            #   will set up cages etc when this profile first becomes a current profile)
            setupCompleteFlag           => FALSE,
            # List containing notes written by this user for this profile, and available to the
            #   Notepad task when it's running
            notepadList                 => [],
            # A hash to store any data your own plugins/scripts want to store (when a profile is
            #   cloned, this data is not copied to the clone)
            privateHash                 => {},

            # Race profile IVs
            # ----------------

            # Complete list of race-specific commands for this race (character-independent)
            cmdList                     => [],
            # List of fight patterns (e.g. 'You hit (.*) with your spear') used with this race
            #   (groups of 2)
            #   [0] - the pattern to match
            #   [1] - the number of the group substring that contains the assailant (set to 0 if it
            #           doesn't)
            fightMsgList                => [],
            # List of interaction patterns (e.g. 'You curse (.*) with your magic wand') used with
            #   this race (groups of 2)
            #   [0] - the pattern to match
            #   [1] - the number of the group substring that contains the victim (set to 0 if it
            #           doesn't)
            interactionMsgList          => [],
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    sub clone {

        # Creates a clone of an existing race profile
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $name       - A unique string name for this profile (max 16 chars, containing
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

        # Check that $name is valid and not already in use by another profile
        if (! $axmud::CLIENT->nameCheck($name, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $self->_objClass . '->clone',
            );

        } elsif ($session->ivExists('profHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: profile \'' . $name . '\' already exists',
                $self->_objClass . '->clone',
            );
        }

        # Setup
        my $clone = {
            _objName                    => $name,
            _objClass                   => $self->_objClass,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,           # All IVs are public

            # Standard profile IVs
            # --------------------

            name                        => $name,
            category                    => $self->category,
            parentWorld                 => undef,

            initTaskHash                => {},              # Set below
            initTaskOrderList           => [],              # Set below
            initTaskTotal               => $self->initTaskTotal,
            initScriptHash              => {},              # Set below
            initScriptOrderList         => [],              # Set below
            initMission                 => $self->initMission,
            initCmdList                 => [$self->initCmdList],

            setupCompleteFlag           => FALSE,           # Clone never been a current profile
            notepadList                 => [$self->notepadList],
            privateHash                 => {},

            # Race profile IVs
            # ----------------

            cmdList                     => [$self->cmdList],
            fightMsgList                => [$self->fightMsgList],
            interactionMsgList          => [$self->interactionMsgList],
        };

        # Bless the cloned object into existence
        bless $clone, $self->_objClass;

        # Also need to clone everything in the initial tasklist
        $clone->cloneInitTaskList($self);

        return $clone;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub cmdList
        { my $self = shift; return @{$self->{cmdList}}; }
    sub fightMsgList
        { my $self = shift; return @{$self->{fightMsgList}}; }
    sub interactionMsgList
        { my $self = shift; return @{$self->{interactionMsgList}}; }
}

{ package Games::Axmud::Profile::Char;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Profile Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by any function
        # Creates a new instance of the character profile
        #
        # Expected arguments
        #   $session     - The GA::Session which called this function (not stored as an IV)
        #   $name        - A unique string name for this profile (max 16 chars, containing
        #                    A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable.
        #                    Must not exist as a key in the global hash of reserved names,
        #                    $axmud::CLIENT->constReservedHash)
        #   $parentWorld - The name of the parent world profile, with which this profile is
        #                    associated
        #
        # Optional arguments
        #   $tempFlag   - If set to TRUE, this is a temporary profile created for use with an 'edit'
        #                   window; $name is not checked for validity. Otherwise set to FALSE (or
        #                   'undef')
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $parentWorld, $tempFlag, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $parentWorld
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        if (! $tempFlag) {

            # Check that $name is valid and not already in use by another profile
            if (! $axmud::CLIENT->nameCheck($name, 16)) {

                return $axmud::CLIENT->writeError(
                    'Registry naming error: invalid name \'' . $name . '\'',
                    $class . '->new',
                );

            } elsif ($session->ivExists('profHash', $name)) {

                return $axmud::CLIENT->writeError(
                    'Registry naming error: profile \'' . $name . '\' already exists',
                    $class . '->new',
                );
            }
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,       # All IVs are public

            # Standard profile IVs
            # --------------------

            name                        => $name,
            category                    => 'char',
            # The name of parent world profile, with which this profile is associated
            parentWorld                 => $parentWorld,

            # Hash of tasks that start whenever this profile is made a current profile (as soon as
            #   the character is marked as 'logged in') - the profile's initial tasklist. Hash in
            #   the form
            #       $initTaskHash{unique_task_name} = blessed_reference_to_task_object
            initTaskHash                => {},
            # The order in which the tasks are started (not very important for tasks unless they
            #   are Script tasks). List contains all the keys in $self->initTaskHash
            initTaskOrderList           => [],
            # How many initial tasks have been created, in total (used to give each one a unique
            #   name). Reset to 0 when the profile's initial tasklist is emptied
            initTaskTotal               => 0,
            # Hash of scripts that start whenever this definiton is made a current profile (as soon
            #   as the character is marked as 'logged in') - the profile's initial scriptlist. Hash
            #   in the form
            #       $initScriptHash{script_name} = mode
            # ...where 'script_name' matches the file from which the script is loaded, and 'mode' is
            #   set to one of the following value:
            #       'no_task'       - run the script without a task
            #       'run_task'      - run the script from within a task
            #       'run_task_win'  - run the script from within a task, in 'forced window' mode
            initScriptHash              => {},
            # The order in which the scripts are started. List contains all the keys in
            #   $self->initScriptHash
            initScriptOrderList         => [],
            # The name of the mission to start whenever a new session begins with this as a current
            #   profile, as soon as the character is marked as logged in - but NOT when a current
            #   profile is set after the login
            # Profiles are checked in priority order; only the first mission found is run. Set to
            #   the name of the mission, or 'undef'
            initMission                 => undef,
            # A list of commands to send the the world whenever a new session begins with this as a
            #   current profile, as soon as the character is marked as logged in - but NOT when a
            #   current profile is set after the login
            # Profiles are checked in priority order; commands are sent from all profiles, but
            #   duplicate commands are not sent
            # Commands are sent AFTER the commands specified by the current world profile's
            #   ->columns, ->rows and ->sendSizeInfoFlag IVs (so this list doesn't need to include
            #   them)
            initCmdList                 => [],

            # Flag set to TRUE if this profile has EVER been a current profile (in which case, it
            #   will have cages etc); set to FALSE if not (in which case, the parent file
            #   object will set up cages etc when this profile first becomes a current profile)
            setupCompleteFlag           => FALSE,
            # List containing notes written by this user for this profile, and available to the
            #   Notepad task when it's running
            notepadList                 => [],
            # A hash to store any data your own plugins/scripts want to store (when a profile is
            #   cloned, this data is not copied to the clone)
            privateHash                 => {},

            # Character profile IVs
            # ---------------------

            # Which guild this character is (matches a guild profile name, or 'undef' if no guild)
            guild                       => undef,
            # Which race this character is (matches a race profile name, or 'undef' if no race)
            race                        => undef,
            # A hash of current custom profiles that correspond to this character, in the form
            #   $customProfHash{profile_name} = profile_category
            customProfHash              => {},

            # Health, magic, energy, guild and social points (corresponding to those collected by
            #   the Status task)
            healthPoints                => 0,
            healthPointsMax             => 0,
            magicPoints                 => 0,
            magicPointsMax              => 0,
            energyPoints                => 0,
            energyPointsMax             => 0,
            guildPoints                 => 0,
            guildPointsMax              => 0,
            socialPoints                => 0,
            socialPointsMax             => 0,

            # Current XP, that hasn't already been used for advancing skills
            xpCurrent                   => 0,
            # XP to the next level
            xpNextLevel                 => 0,
            # Total XP earned by character (if known)
            xpTotal                     => 0,

            # Current QP (Quest Points)
            qpCurrent                   => 0,
            # QP required for the next level
            qpNextLevel                 => 0,
            # Total QP earned by character (if known)
            qpTotal                     => 0,

            # Spare set of IVs, used in parallel with XP and QP counts, in case the world
            #   implements a similar system using a different measure. We'll call them OP (Other
            #   Points)
            opCurrent                   => 0,
            opNextLevel                 => 0,
            opTotal                     => 0,

            # The QP values above are designed to be updated by the Status task. This set of IVs
            #   exists in parallel with the IVs with the same names in the world profile, and are
            #   designed to be updated manually by the user
            # Hash of quests which have been solved by this character. Hash in the form
            #   $questHash{quest_name} = undef
            questHash                   => {},
            # How many quests solved by this character
            questCount                  => 0,
            # Number of quest points earned
            questPointCount             => 0,
            # Total quest points available
            questXPCount                => 0,
            # Number of quests completed
            questCashCount              => 0,

            # Character's current level (if known), e.g. 100
            level                       => 0,
            # Character's current alignment (if known), usually a string
            alignment                   => undef,
            # Hash of spells (etc) that currently affect the character, in the form
            #   $affectHash{spell} = undef
            affectHash                  => {},

            # The progression of skills. These variables store the default progression for the
            #   guild; this is copied to the character profile (whenever 'factory settings' need to
            #   be restored), where the character's own skill progression is stored
            # This flag is set to TRUE if a reset has been done at least once (needs to be done, in
            #   order for the Advance task to work)
            resetSkillsFlag             => FALSE,
            # What method is used to advance skills
            # 'order' - advance skills in a pre-determined order
            # 'cycle' - advance skills on a repeating cycle
            # 'combo' - advance skills in the pre-determined order then, when that list is
            #   exhausted, start advancing skills in the repeating cycle
            advanceMethod               => 'order',
            # When ->advanceMethod = 'combo', whether we are on the 'order' or 'cycle' stage (undef
            #   if ->advanceMethod = 'order' or 'cycle' )
            advanceMethodStatus         => undef,
            # The pre-determined list of skills (an empty list if not used)
            advanceOrderList            => [],
            # The current list of skills, emptied as it is used (refreshed from
            #   $self->advanceOrderList as necessary)
            currentAdvanceOrderList     => [],
            # The pre-determined cycle of skills (an empty list if not used)
            advanceCycleList            => [],
            # The current cycle of skills (refreshed from ->advanceCycleList as necessary)
            currentAdvanceCycleList     => [],

            # The character's own skill progression variables. The basic list is imported from the
            #   current guild with $self->resetSkills (and can be reset at any time)
            # e.g. skill and current level, e.g. 'fighting' => 10
            skillLevelHash              => {},
            # no. times the skill has been advanced, e.g. 'fighting' => 15
            skillAdvanceCountHash       => {},
            # Total XP spent advancing this skill (0 if unknown)
            skillTotalXPHash            => {},
            # XP required to advance this skill once more (undef if unknown)
            skillNextXPHash             => {},
            # Total cash spent advancing this skill (0 if unknown)
            skillTotalCashHash          => {},
            # Cash required to advance this skill once more (undef if unknown)
            skillNextCashHash           => {},

            # The character's skill advance history - a list of GA::Obj::SkillHistory objects, each
            #   representing an advance, in the order they were advanced
            skillHistoryList            => [],

            # Number of lives left
            lifeCount                   => 0,
            # Number of times killed
            deathCount                  => 0,
            # Total number of lives, including already used up
            lifeMax                     => 0,
            # 'alive', 'sleep', 'passout', 'dead'
            lifeStatus                  => 'alive',

            # Many worlds have a 'wimpy' setting, allowing the char to automatically run away before
            #   death
            remoteWimpy                 => 0,
            remoteWimpyMax              => 100,
            # Axmud's local wimpy fulfills the same purpose, however the maximum value is always
            #   100
            localWimpy                  => 0,
            constLocalWimpyMax          => 100,

            # The character's age (in the world's standard age unit, defined by
            #   GA::Profile::World->charAgeUnit)
            age                         => 0,

            # Axmud stores cash as a single currency, even if the world uses multiple coins; e.g.
            #   two gold and two silver coins will be stored as 2.5 units - a unit representing gold
            #   coins
            # The character's bank balance (if known)
            bankBalance                 => 0,
            # How much money the character has in their pockets (if known)
            purseContents               => 0,

            # Number of fights involving the character (two simultaneous opponents = 2 fights)
            fightCount                  => 0,
            # Total number of kills achieved by the character
            killCount                   => 0,
            # Number of fights that ended with the character running away when wimpy mode was
            #   activated
            wimpyCount                  => 0,
            # Number of fights that ended in other kinds of defeat, e.g. death or loss of
            #   consciousness for the character
            fightDefeatCount            => 0,

            # Some guilds don't use fights, e.g. bards might perform songs which can be successes
            #   or failures. These are called 'interactions'.
            interactCount               => 0,
            # How many successful interactions
            interactSuccessCount        => 0,
            # How many failed interactions
            interactFailCount           => 0,
            # How many failed interactions led to a fight
            interactFightCount          => 0,
            # How many failed interactions that, generally, cause the character to need to run away
            #   quickly
            interactDisasterCount       => 0,

            # How many fights/interactions caused a target to flee, when the character is able to
            #   pursue
            fleeCount                   => 0,
            # How many fights/interactions ended when a target escaped, meaning the character isn't
            #   able to pursue
            escapeCount                 => 0,

            # A record of all the things killed, updated by the Attack task. Two hashes, one
            #   containing the main noun of the victim (e.g. 'orc'), the other, the base string
            #   (e.g. 'big hairy orc'). Hash in the form
            #       $fightVictimHash{main_noun} = number_of_times_killed
            fightVictimHash             => {},
            # Hash in the form
            #   $fightVictimStringHash{base_string} = number_of_times_killed
            fightVictimStringHash       => {},
            # A record of successful interactions, updated by the Attack task. Two hashes, one
            #   containing the main noun of the victim (e.g. 'orc'), the other, the base string
            #   (e.g. 'big hairy orc', in all-lower case)
            # Hash in the form
            #   $interactionVictimHash{main_noun} = number_of_times_interacted_with_successfully
            interactionVictimHash       => {},
            # Hash in the form
            #   $interactionVictimStringHash{base_string} = num_times_interacted_with_successfully
            interactionVictimStringHash => {},

            # Character's permanent stats (not including bonuses/penalties), initially inherited
            #   from the world profile
            #   e.g. statHash{con} = 10, statHash{dex} = 15, etc
            statHash                    => {},      # Set below

            # Hash of commands the Status task should send to the world periodically (initially
            #   inherited from the world profile. The Status task gets its list from the character
            #   profile, not the world profile)
            statusCmdHash               => {},      # Set below
            # Flag set to TRUE when the Status task should start sending these commands as soon as
            #   it is initialised; FALSE if not (or 'undef' when the Status task has never run)
            statusCmdFlag               => undef,
            # Hash of commands the Inventory task should send to the world periodically, initially
            #   inherited from the world profile
            inventoryCmdHash            => {},      # Set below,

            # A list of GA::Obj::Protect objects which define which things enjoy semi-protection
            #   from being dropped or sold, if they happen to be in the character's inventory
            protectObjList              => [],
            # A list of GA::Obj::Monitor objects which define which things should not be checked
            #   by the Condition task, if they happen to be in the character's inventory
            monitorObjList              => [],
        };

        # Allow this character profile to inherit a few values from the current world profile (if
        #   there is one)
        if ($session->currentWorld) {

            $self->{statHash} = $session->currentWorld->{statHash};
            $self->{statusCmdHash} = $session->currentWorld->{statusCmdHash};
            $self->{inventoryCmdHash} = $session->currentWorld->{inventoryCmdHash};
        }

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    sub clone {

        # Creates a clone of an existing character profile
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $name       - A unique string name for this profile (max 16 chars, containing
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

        # Check that $name is valid and not already in use by another profile
        if (! $axmud::CLIENT->nameCheck($name, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $self->_objClass . '->clone',
            );

        } elsif ($session->ivExists('profHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: profile \'' . $name . '\' already exists',
                $self->_objClass . '->clone',
            );
        }

        # Setup
        my $clone = {
            _objName                    => $name,
            _objClass                   => $self->_objClass,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,           # All IVs are public

            # Standard profile IVs
            # --------------------

            name                        => $name,
            category                    => $self->category,
            parentWorld                 => undef,

            initTaskHash                => {},              # Set below
            initTaskOrderList           => [],              # Set below
            initTaskTotal               => $self->initTaskTotal,
            initScriptHash              => {},              # Set below
            initScriptOrderList         => [],              # Set below
            initMission                 => $self->initMission,
            initCmdList                 => [$self->initCmdList],

            setupCompleteFlag           => FALSE,           # Clone never been a current profile
            notepadList                 => [$self->notepadList],
            privateHash                 => {},

            # Character profile IVs
            # ---------------------

            guild                       => $self->guild,
            race                        => $self->race,
            customProfHash              => {$self->customProfHash},

            healthPoints                => $self->healthPoints,
            healthPointsMax             => $self->healthPointsMax,
            magicPoints                 => $self->magicPoints,
            magicPointsMax              => $self->magicPointsMax,
            energyPoints                => $self->energyPoints,
            energyPointsMax             => $self->energyPointsMax,
            guildPoints                 => $self->guildPoints,
            guildPointsMax              => $self->guildPointsMax,
            socialPoints                => $self->socialPoints,
            socialPointsMax             => $self->socialPointsMax,

            xpCurrent                   => $self->xpCurrent,
            xpNextLevel                 => $self->xpNextLevel,
            xpTotal                     => $self->xpTotal,

            qpCurrent                   => $self->qpCurrent,
            qpNextLevel                 => $self->qpNextLevel,
            qpTotal                     => $self->qpTotal,

            opCurrent                   => $self->opCurrent,
            opNextLevel                 => $self->opNextLevel,
            opTotal                     => $self->opTotal,

            questHash                   => {$self->questHash},
            questCount                  => $self->questCount,
            questPointCount             => $self->questPointCount,
            questXPCount                => $self->questXPCount,
            questCashCount              => $self->questCashCount,

            level                       => $self->level,
            alignment                   => $self->alignment,
            affectHash                  => {$self->affectHash},

            resetSkillsFlag             => $self->resetSkillsFlag,
            advanceMethod               => $self->advanceMethod,
            advanceMethodStatus         => $self->advanceMethodStatus,
            advanceOrderList            => [$self->advanceOrderList],
            currentAdvanceOrderList     => [$self->currentAdvanceOrderList],
            advanceCycleList            => [$self->advanceCycleList],
            currentAdvanceCycleList     => [$self->currentAdvanceCycleList],

            skillLevelHash              => {$self->skillLevelHash},
            skillAdvanceCountHash       => {$self->skillAdvanceCountHash},
            skillTotalXPHash            => {$self->skillTotalXPHash},
            skillNextXPHash             => {$self->skillNextXPHash},
            skillTotalCashHash          => {$self->skillTotalCashHash},
            skillNextCashHash           => {$self->skillNextCashHash},

            skillHistoryList            => [$self->skillHistoryList],

            lifeCount                   => $self->lifeCount,
            deathCount                  => $self->deathCount,
            lifeMax                     => $self->lifeMax,
            lifeStatus                  => $self->lifeStatus,

            remoteWimpy                 => $self->remoteWimpy,
            remoteWimpyMax              => $self->remoteWimpyMax,
            localWimpy                  => $self->localWimpy,
            constLocalWimpyMax          => $self->constLocalWimpyMax,

            age                         => $self->age,

            bankBalance                 => $self->bankBalance,
            purseContents               => $self->purseContents,

            fightCount                  => $self->fightCount,
            killCount                   => $self->killCount,
            wimpyCount                  => $self->wimpyCount,
            fightDefeatCount            => $self->fightDefeatCount,

            interactCount               => $self->interactCount,
            interactSuccessCount        => $self->interactSuccessCount,
            interactFailCount           => $self->interactFailCount,
            interactFightCount          => $self->interactFightCount,
            interactDisasterCount       => $self->interactDisasterCount,

            fleeCount                   => $self->fleeCount,
            escapeCount                 => $self->escapeCount,

            fightVictimHash             => {$self->fightVictimHash},
            fightVictimStringHash       => {$self->fightVictimStringHash},
            interactionVictimHash       => {$self->interactionVictimHash},
            interactionVictimStringHash
                                        => {$self->interactionVictimStringHash},

            statHash                    => {$self->statHash},

            statusCmdHash               => {$self->statusCmdHash},
            statusCmdFlag               => $self->statusCmdFlag,
            inventoryCmdHash            => {$self->inventoryCmdHash},

            protectObjList              => [$self->protectObjList],
            monitorObjList              => [$self->monitorObjList],
        };

        # Bless the cloned object into existence
        bless $clone, $self->_objClass;

        # Also need to clone everything in the initial tasklist
        $clone->cloneInitTaskList($self);

        return $clone;
    }

    ##################
    # Methods

    sub updateQuestStats {

        # Called by anything, any time a quest stored by this profile changes
        # Re-calculates this profile's running totals
        #
        # Expected arguements
        #   $session    - The calling function's GA::Session
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Local variables
        my ($questCount, $pointCount, $xpCount, $cashCount);

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateQuestStats', @_);
        }

        # Go through each quest registered in $self->questHash, updating the
        #   running totals wherever possible
        $questCount = 0;
        $pointCount = 0;
        $xpCount = 0;
        $cashCount = 0;
        foreach my $questName ($self->ivKeys('questHash')) {

            my $questObj = $session->currentWorld->ivShow('questHash', $questName);
            if ($questObj) {

                $questCount++;

                if (defined $questObj->questPoints) {

                    $pointCount += $questObj->questPoints;
                }

                if (defined $questObj->questXP) {

                    $xpCount += $questObj->questXP;
                }

                if (defined $questObj->questCash) {

                    $cashCount += $questObj->questCash;
                }
            }
        }

        # Save the totals
        $self->ivPoke('questCount', $questCount);
        $self->ivPoke('questPointCount', $pointCount);
        $self->ivPoke('questXPCount', $xpCount);
        $self->ivPoke('questCashCount', $cashCount);

        return 1;
    }

    sub resetSkills {

        # Can be called by anything (e.g. GA::Cmd::ResetGuildSkills->do)
        # Restores the skill IVs stored for this character to their defaults, importing some values
        #   from the current guild profile
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #
        # Return values
        #   'undef' on improper arguments or if there isn't a current guild from which to import
        #       values
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Local variables
        my (
            $guild,
            @list,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetSkills', @_);
        }

        # Check there is a current guild profile
        $guild = $session->currentGuild;
        if (! $guild) {

            # Can't import values from non-existent profile
            return undef;

        } else {

            # Import values from the current guild profile
            $self->ivPoke('advanceMethod', $guild->advanceMethod);
            $self->ivPoke('advanceOrderList', $guild->advanceOrderList);
            $self->ivPoke('advanceCycleList', $guild->advanceCycleList);

            # Set default values in this character profile
            if ($self->advanceMethod eq 'combo') {

                # In 'combo' mode, the 'order' list is used up before the 'cycle' list
                $self->ivPoke('advanceMethodStatus', 'order');
            }

            $self->ivPoke('currentAdvanceOrderList', $self->advanceOrderList);
            $self->ivPoke('currentAdvanceCycleList', $self->advanceCycleList);

            foreach my $skill ($guild->skillList) {

                # Every skill starts at 0
                $self->ivAdd('skillLevelHash', $skill, 0);
                # Skill never advanced
                $self->ivAdd('skillAdvanceCountHash', $skill, 0);
                # No XP used in advancing
                $self->ivAdd('skillTotalXPHash', $skill, 0);
                # XP needed to advance again unknown
                $self->ivAdd('skillNextXPHash', $skill, 0);
                # No cash used in advancing
                $self->ivAdd('skillTotalCashHash', $skill, 0);
                # Cash needed to advance again unknown
                $self->ivAdd('skillNextCashHash', $skill, 0);
            }

            # Empty the skill history list
            $self->ivEmpty('skillHistoryList');

            # Mark the values as having been reset at least once
            $self->ivPoke('skillsResetFlag', TRUE);

            # Reset complete
            return 1;
        }
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub guild
        { $_[0]->{guild} }
    sub race
        { $_[0]->{race} }
    sub customProfHash
        { my $self = shift; return %{$self->{customProfHash}}; }

    sub healthPoints
        { $_[0]->{healthPoints} }
    sub healthPointsMax
        { $_[0]->{healthPointsMax} }
    sub magicPoints
        { $_[0]->{magicPoints} }
    sub magicPointsMax
        { $_[0]->{magicPointsMax} }
    sub energyPoints
        { $_[0]->{energyPoints} }
    sub energyPointsMax
        { $_[0]->{energyPointsMax} }
    sub guildPoints
        { $_[0]->{guildPoints} }
    sub guildPointsMax
        { $_[0]->{guildPointsMax} }
    sub socialPoints
        { $_[0]->{socialPoints} }
    sub socialPointsMax
        { $_[0]->{socialPointsMax} }

    sub xpCurrent
        { $_[0]->{xpCurrent} }
    sub xpNextLevel
        { $_[0]->{xpNextLevel} }
    sub xpTotal
        { $_[0]->{xpTotal} }

    sub qpCurrent
        { $_[0]->{qpCurrent} }
    sub qpNextLevel
        { $_[0]->{qpNextLevel} }
    sub qpTotal
        { $_[0]->{qpTotal} }

    sub opCurrent
        { $_[0]->{opCurrent} }
    sub opNextLevel
        { $_[0]->{opNextLevel} }
    sub opTotal
        { $_[0]->{opTotal} }

    sub questHash
        { my $self = shift; return %{$self->{questHash}}; }
    sub questCount
        { $_[0]->{questCount} }
    sub questPointCount
        { $_[0]->{questPointCount} }
    sub questXPCount
        { $_[0]->{questXPCount} }
    sub questCashCount
        { $_[0]->{questCashCount} }

    sub level
        { $_[0]->{level} }
    sub alignment
        { $_[0]->{alignment} }
    sub affectHash
        { my $self = shift; return %{$self->{affectHash}}; }

    sub resetSkillsFlag
        { $_[0]->{resetSkillsFlag} }
    sub advanceMethod
        { $_[0]->{advanceMethod} }
    sub advanceMethodStatus
        { $_[0]->{advanceMethodStatus} }
    sub advanceOrderList
        { my $self = shift; return @{$self->{advanceOrderList}}; }
    sub currentAdvanceOrderList
        { my $self = shift; return @{$self->{currentAdvanceOrderList}}; }
    sub advanceCycleList
        { my $self = shift; return @{$self->{advanceCycleList}}; }
    sub currentAdvanceCycleList
        { my $self = shift; return @{$self->{currentAdvanceCycleList}}; }

    sub skillLevelHash
        { my $self = shift; return %{$self->{skillLevelHash}}; }
    sub skillAdvanceCountHash
        { my $self = shift; return %{$self->{skillAdvanceCountHash}}; }
    sub skillTotalXPHash
        { my $self = shift; return %{$self->{skillTotalXPHash}}; }
    sub skillNextXPHash
        { my $self = shift; return %{$self->{skillNextXPHash}}; }
    sub skillTotalCashHash
        { my $self = shift; return %{$self->{skillTotalCashHash}}; }
    sub skillNextCashHash
        { my $self = shift; return %{$self->{skillNextCashHash}}; }

    sub skillHistoryList
        { my $self = shift; return @{$self->{skillHistoryList}}; }

    sub lifeCount
        { $_[0]->{lifeCount} }
    sub deathCount
        { $_[0]->{deathCount} }
    sub lifeMax
        { $_[0]->{lifeMax} }
    sub lifeStatus
        { $_[0]->{lifeStatus} }

    sub remoteWimpy
        { $_[0]->{remoteWimpy} }
    sub remoteWimpyMax
        { $_[0]->{remoteWimpyMax} }
    sub localWimpy
        { $_[0]->{localWimpy} }
    sub constLocalWimpyMax
        { $_[0]->{constLocalWimpyMax} }

    sub age
        { $_[0]->{age} }

    sub bankBalance
        { $_[0]->{bankBalance} }
    sub purseContents
        { $_[0]->{purseContents} }

    sub fightCount
        { $_[0]->{fightCount} }
    sub killCount
        { $_[0]->{killCount} }
    sub wimpyCount
        { $_[0]->{wimpyCount} }
    sub fightDefeatCount
        { $_[0]->{fightDefeatCount} }

    sub interactCount
        { $_[0]->{interactCount} }
    sub interactSuccessCount
        { $_[0]->{interactSuccessCount} }
    sub interactFailCount
        { $_[0]->{interactFailCount} }
    sub interactFightCount
        { $_[0]->{interactFightCount} }
    sub interactDisasterCount
        { $_[0]->{interactDisasterCount} }

    sub fleeCount
        { $_[0]->{fleeCount} }
    sub escapeCount
        { $_[0]->{escapeCount} }

    sub fightVictimHash
        { my $self = shift; return %{$self->{fightVictimHash}}; }
    sub fightVictimStringHash
        { my $self = shift; return %{$self->{fightVictimStringHash}}; }
    sub interactionVictimHash
        { my $self = shift; return %{$self->{interactionVictimHash}}; }
    sub interactionVictimStringHash
        { my $self = shift; return %{$self->{interactionVictimStringHash}}; }

    sub statHash
        { my $self = shift; return %{$self->{statHash}}; }

    sub statusCmdHash
        { my $self = shift; return %{$self->{statusCmdHash}}; }
    sub statusCmdFlag
        { $_[0]->{statusCmdFlag} }
    sub inventoryCmdHash
        { my $self = shift; return %{$self->{inventoryCmdHash}}; }

    sub protectObjList
        { my $self = shift; return @{$self->{protectObjList}}; }
    sub monitorObjList
        { my $self = shift; return @{$self->{monitorObjList}}; }
}

{ package Games::Axmud::Profile::Template;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Profile Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Cmd::AddTemplate->do, ListProperty->do or by the object viewer window
        # Creates a new kind of custom profile, called a 'profile template'
        #   Call ->new to create the bare bones of a custom profile - the instance variables that
        #       all custom profile must have
        #   Use the ->createScalarProperty, ->createListProperty and ->createHashProperty methods to
        #       give it instance variables that make this kind of custom profile unique
        #       ('favourite_colour', 'size', 'bank_balance' etc)
        #   Use ->removeProperty to remove one, if necessary
        #   Then call ->spawn to create an instance of the GA::Profile::Custom object, using all of
        #       these instance variables
        #   Once call->spawn is used for the first time, the instance variables are fixed and cannot
        #       be changed (but call ->clone to create a clone of the template can be created, which
        #       is still able to spawn)
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $category   - What kind of profile this is (must not be one of the four standard
        #                   categories, 'world', 'guild', 'race' and 'char', nor the category for
        #                   any existing profile template) (max 16 chars, containing A-Za-z0-9_ -
        #                   1st char can't be number, non-Latin alphabets acceptable. Must not exist
        #                   as a key in the global hash of reserved names,
        #                   $axmud::CLIENT->constReservedHash)
        #
        # Optional arguments
        #   $tempFlag   - If set to TRUE, this is a temporary profile template created for use with
        #                   an 'edit' window; $category is not checked for validity. Otherwise set
        #                   to FALSE (or 'undef')
        #
        # Return values
        #   'undef' on improper arguments or if $category is invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $category, $tempFlag, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $session || ! defined $category || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        if (! $tempFlag) {

            # Check that $category is valid and not already in use by another profile template
            if (! $axmud::CLIENT->nameCheck($category, 16)) {

                return $axmud::CLIENT->writeError(
                    'Registry naming error: invalid category \'' . $category . '\'',
                    $class . '->new',
                );

            } elsif ($session->ivExists('templateHash', $category)) {

                return $axmud::CLIENT->writeError(
                    'Registry naming error: profile template for the category \'' . $category
                    . '\' already exists',
                    $class . '->new',
                );

            # Check it's not a standard category ('world', 'guild', 'race', 'char')
            } elsif (defined $axmud::CLIENT->ivFind('constProfPriorityList', $category)) {

                return $axmud::CLIENT->writeError(
                    'Registry naming error: the category \'' . $category . '\' is a standard'
                    . ' category, so profile templates can\'t be created for it',
                    $class . '->new',
                );
            }
        }

        # Setup
        my $self = {
            _objName                    => $category,
            _objClass                   => $class,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,       # All IVs are public

            # Template IVs
            # ------------

            # The category of profile created from this template
            category                    => $category,
            # Flag set to TRUE the first time ->spawn is called, after which no more IVs can be
            #   added or deleted (the initial underline prevents anything from modifying its
            #   contents via the usual ->ivPoke (etc) methods)
            constFixedFlag              => FALSE,
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    sub clone {

        # Creates a clone of this template, but with its ->constFixedFlag reset back to FALSE, so
        #   that the copy can be given new IVs
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $category   - What kind of profile the copy will be (must not be one of the four
        #                   standard categories, 'world', 'guild', 'race' and 'char', nor the
        #                   category for any existing profile template) (max 16 chars, containing
        #                   A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable.
        #                   Must not exist as a key in the global hash of reserved names,
        #                   $axmud::CLIENT->constReservedHash)
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($self, $session, $category, $check) = @_;

        # Check for improper arguments
        if (! defined $session || ! defined $category || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Check that $category is valid and not already in use by another profile template
        if (! $axmud::CLIENT->nameCheck($category, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid category \'' . $category . '\'',
                $self->_objClass . '->clone',
            );

        } elsif ($session->ivExists('templateHash', $category)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: profile template for the category \'' . $category
                . '\' already exists',
                $self->_objClass . '->clone',
            );

        # Check it's not a standard category ('world', 'guild', 'race', 'char')
        } elsif (defined $axmud::CLIENT->ivFind('constProfPriorityList', $category)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: the category \'' . $category . '\' is a standard category,'
                . ' so profile templates can\'t be created for it',
                $self->_objClass . '->clone',
            );
        }

        # Setup
        my $clone = {
            _objName                    => $category,
            _objClass                   => $self->_objClass,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,       # All IVs are public

            # Template IVs
            # ------------

            # The category of profile created from this template
            category                    => $category,
            # Flag set to TRUE the first time ->spawn is called, after which no more IVs can be
            #   added or deleted (the initial underline prevents anything from modifying its
            #   contents via the usual ->ivPoke (etc) methods)
            constFixedFlag              => FALSE,
        };

        # Bless the cloned object into existence
        bless $clone, $self->_objClass;

        # Clone the instance variables for this profile template
        OUTER: foreach my $iv ($self->ivList) {

            # Don't clone any IVs specified by the GA::Client registry hash
            if (! $axmud::CLIENT->ivExists('constProfStandardHash', $iv)) {

                $clone->{$iv} = $self->{$iv};
            }
        }

        return $clone;
    }

    ##################
    # Methods

    sub spawn {

        # Called by any function
        # Creates an instance of the GA::Profile::Custom object using this object's properties (IVs)
        # If successful, sets $self->constFixedFlag to TRUE, so that no more changes can be made to
        #   the template's properties
        #
        # Expected arguments
        #   $session     - The GA::Session which called this function
        #   $name        - A unique string name for this profile (max 16 chars, containing
        #                    A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable.
        #                    Must not exist as a key in the global hash of reserved names,
        #                    $axmud::CLIENT->constReservedHash)
        #   $parentWorld - The name of the parent world profile, with which this profile is
        #                    associated
        #
        # Optional arguments
        #   $tempFlag   - If set to TRUE, the new profile is a temporary profile created for use
        #                   with an 'edit' window; this object's $self->constFixedFlag is not set to
        #                   TRUE. Otherwise set to FALSE (or 'undef')
        #
        # Return values
        #   'undef' on improper arguments or if the spawned custom profile can't be created
        #   Blessed reference to the newly-created object on success

        my ($self, $session, $name, $parentWorld, $tempFlag, $check) = @_;

        # Local variables
        my ($spawnObj, $templObj);

        # Check for improper arguments
        if (! defined $session || ! defined $name || ! defined $parentWorld || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->spawn', @_);
        }

        # Create the spawned custom profile
        $spawnObj = Games::Axmud::Profile::Custom->new(
            $session,
            $name,
            $parentWorld,
            $self->category,
            $tempFlag,
        );

        if (! $spawnObj) {

            # (Error message already displayed)
            return undef;
        }

        # Export all the IVs for this category of custom profile
        OUTER: foreach my $iv ($self->ivList) {

            # Don't export any IVs specified by the GA::Client registry hash
            if (! $axmud::CLIENT->ivExists('constProfStandardHash', $iv)) {

                $spawnObj->{$iv} = $self->{$iv};
            }
        }

        if (! $tempFlag) {

            # This template object should now be marked as 'fixed' (no more changes can be made to
            #   its properties)
            # We need to use the $self->{...} form, because IVs beginning 'const...' can't be
            #   modified with ->ivPoke...
            $self->{constFixedFlag} = TRUE;
            # ...but the parent file still needs to have its ->modifyFlag set...
            $session->setModifyFlag($self->_parentFile, TRUE, $self->_objClass . '->spawn');
        }

        # Spawning complete
        return $spawnObj;
    }

    sub createScalarProperty {

        # Gives the template a new scalar property (IV)
        #
        # Expected arguments
        #   $name       - The property name
        #
        # Optional arguments
        #   $scalar     - The property is set to this value (otherwise it is set to 'undef')
        #
        # Return values
        #   'undef' on improper arguments, or if the property $name already exists, or if the
        #       template has been 'fixed' (no new properties are allowed)
        #   1 on success

        my ($self, $name, $scalar, $check) = @_;

        # Check for improper arguments
        if (! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createScalarProperty', @_);
        }

        if (
            # Check the property doesn't already exist
            exists $self->{$name}
            # Check the template hasn't already been 'fixed'
            || $self->constFixedFlag
            # Check that the property isn't one of those specified by the GA::Client registry hash
            || $axmud::CLIENT->ivExists('constProfStandardHash', $name)
        ) {
            return undef;

        } else {

            # Add the property as a new instance variable
            $self->ivCreate($name, 'scalar');
            $self->ivPoke($name, $scalar);
        }

        return 1;
    }

    sub createListProperty {

        # Gives the template a new array property (IV)
        #
        # Expected arguments
        #   $name       - The property name
        #
        # Optional arguments
        #   @list       - The property is set to this list (otherwise it is set to an empty list)
        #
        # Return values
        #   'undef' on improper arguments, or if the property $name already exists, or if the
        #       template has been 'fixed' (no new properties are allowed)
        #   1 on success

        my ($self, $name, @list) = @_;

        # Check for improper arguments
        if (! defined $name) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createListProperty', @_);
        }

        if (
            # Check the property doesn't already exist
            exists $self->{$name}
            # Check the template hasn't already been 'fixed'
            || $self->constFixedFlag
            # Check that the property isn't one of those specified by the GA::Client registry hash
            || $axmud::CLIENT->ivExists('constProfStandardHash', $name)
        ) {
            return undef;

        } else {

            # Add the property as a new instance variable
            $self->ivCreate($name, 'list');
            $self->ivPoke($name, @list);
        }

        return 1;
    }

    sub createHashProperty {

        # Gives the template a new hash property (IV)
        #
        # Expected arguments
        #   $name       - The property name
        #
        # Optional arguments
        #   %hash       - The property is set to this hash (otherwise it is set to an empty hash)
        #
        # Return values
        #   'undef' on improper arguments, or if the property $name already exists, or if the
        #       template has been 'fixed' (no new properties are allowed)
        #   1 on success

        my ($self, $name, %hash) = @_;

        # Check for improper arguments
        if (! defined $name) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createHashProperty', @_);
        }

        if (
            # Check the property doesn't already exist
            exists $self->{$name}
            # Check the template hasn't already been 'fixed'
            || $self->constFixedFlag
            # Check that the property isn't one of those specified by the GA::Client registry hash
            || $axmud::CLIENT->ivExists('constProfStandardHash', $name)
        ) {
            return undef;

        } else {

            # Add the property as a new instance variable
            $self->ivCreate($name, 'hash');
            $self->ivPoke($name, %hash);
        }

        return 1;
    }

    sub removeProperty {

        # Removes one of the properties (IVs) that were created with $self->createScalarProperty,
        #   ->createArrayProperty or ->createHashProperty
        # (You can't use this function to remove any of the properties which exist as keys in
        #   the GA::Client registry hash, or any property whose name begins with an underline)
        #
        # Expected arguments
        #   $name   - The name of the property to remove
        #
        # Return values
        #   'undef' if the property doesn't exist, if the property couldn't be removed, or on
        #       improper arguments
        #   1 on success

        my ($self, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeProperty', @_);
        }

        if (
            # Check the property already exists
            ! exists $self->{$name}
            # Check the template hasn't already been 'fixed'
            || $self->constFixedFlag
            # Check that the property isn't one of the standard ones (which can't therefore be
            #   destroyed)
            || $axmud::CLIENT->ivExists('constProfStandardHash', $name)
            || substr($name, 0, 1) eq '_'
        ) {
            return undef;

        } else {

            # Destroy the property by destroying its instance variable
            return $self->ivDestroy($name);
        }
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub category
        { $_[0]->{category} }
    sub constFixedFlag
        { $_[0]->{constFixedFlag} }
}

{ package Games::Axmud::Profile::Custom;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Profile Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Profile::Template->spawn
        # Creates a new instance of a custom profile
        # THIS METHOD SHOULD NOT BE CALLED DIRECTLY. Instead, call GA::Profile::Template->spawn
        #
        # Expected arguments
        #   $session     - The GA::Session which called this function (not stored as an IV)
        #   $name        - A unique string name for this profile (max 16 chars, containing
        #                    A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable.
        #                    Must not exist as a key in the global hash of reserved names,
        #                    $axmud::CLIENT->constReservedHash)
        #   $parentWorld - The name of the parent world profile, with which this profile is
        #                    associated
        #   $category    - What kind of profile this is. Matches the ->category of a
        #                    GA::Profile::Template (equivalent to 'world', 'race', 'guild', 'char')
        #
        # Optional arguments
        #   $tempFlag   - If set to TRUE, this is a temporary profile created for use with an 'edit'
        #                   window; $name is not checked for validity. Otherwise set to FALSE (or
        #                   'undef')
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $parentWorld, $category, $tempFlag, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $name || ! defined $parentWorld
            || ! defined $category || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        if (! $tempFlag) {

            # Check that $name is valid and not already in use by another profile
            if (! $axmud::CLIENT->nameCheck($name, 16)) {

                return $axmud::CLIENT->writeError(
                    'Registry naming error: invalid name \'' . $name . '\'',
                    $class . '->new',
                );

            } elsif ($session->ivExists('profHash', $name)) {

                return $axmud::CLIENT->writeError(
                    'Registry naming error: profile \'' . $name . '\' already exists',
                    $class . '->new',
                );
            }

            # Check that a matching template profile exists
            if (! $session->ivExists('templateHash', $category)) {

                return $axmud::CLIENT->writeError(
                    'Registry naming error: no profile template of the category \'' . $category
                    . '\' exists',
                    $class . '->new',
                );
            }
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,       # All IVs are public

            # Standard profile IVs
            # --------------------

            name                        => $name,
            category                    => $category,
            # The name of parent world profile, with which this profile is associated
            parentWorld                 => $parentWorld,

            # Hash of tasks that start whenever this profile is made a current profile (as soon as
            #   the character is marked as 'logged in') - the profile's initial tasklist. Hash in
            #   the form
            #       $initTaskHash{unique_task_name} = blessed_reference_to_task_object
            initTaskHash                => {},
            # The order in which the tasks are started (not very important for tasks unless they
            #   are Script tasks). List contains all the keys in $self->initTaskHash
            initTaskOrderList           => [],
            # How many initial tasks have been created, in total (used to give each one a unique
            #   name). Reset to 0 when the profile's initial tasklist is emptied
            initTaskTotal               => 0,
            # Hash of scripts that start whenever this definiton is made a current profile (as soon
            #   as the character is marked as 'logged in') - the profile's initial scriptlist. Hash
            #   in the form
            #       $initScriptHash{script_name} = mode
            # ...where 'script_name' matches the file from which the script is loaded, and 'mode' is
            #   set to one of the following value:
            #       'no_task'       - run the script without a task
            #       'run_task'      - run the script from within a task
            #       'run_task_win'  - run the script from within a task, in 'forced window' mode
            initScriptHash              => {},
            # The order in which the scripts are started. List contains all the keys in
            #   $self->initScriptHash
            initScriptOrderList         => [],
            # The name of the mission to start whenever a new session begins with this as a current
            #   profile, as soon as the character is marked as logged in - but NOT when a current
            #   profile is set after the login
            # Profiles are checked in priority order; only the first mission found is run. Set to
            #   the name of the mission, or 'undef'
            initMission                 => undef,
            # A list of commands to send the the world whenever a new session begins with this as a
            #   current profile, as soon as the character is marked as logged in - but NOT when a
            #   current profile is set after the login
            # Profiles are checked in priority order; commands are sent from all profiles, but
            #   duplicate commands are not sent
            # Commands are sent AFTER the commands specified by the current world profile's
            #   ->columns, ->rows and ->sendSizeInfoFlag IVs (so this list doesn't need to include
            #   them)
            initCmdList                 => [],

            # Flag set to TRUE if this profile has EVER been a current profile (in which case, it
            #   will have cages etc); set to FALSE if not (in which case, the parent file object
            #   will set up cages etc when this profile first becomes a current profile)
            setupCompleteFlag           => FALSE,
            # List containing notes written by this user for this profile, and available to the
            #   Notepad task when it's running
            notepadList                 => [],
            # A hash to store any data your own plugins/scripts want to store (when a profile is
            #   cloned, this data is not copied to the clone)
            privateHash                 => {},

            # The remaining instance variables - those which are unique to every category of custom
            #   profile - are set by the calling function, GA::Profile::Template->spawn
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    sub clone {

        # Creates a clone of an existing custom profile
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $name       - A unique string name for this profile (max 16 chars, containing
        #                   A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable.
        #                   Must not exist as a key in the global hash of reserved names,
        #                   $axmud::CLIENT->constReservedHash)
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($self, $session, $name, $check) = @_;

        # Local variables
        my $templObj;

        # Check for improper arguments
        if (! defined $session || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Check that $name is valid and not already in use by another profile
        if (! $axmud::CLIENT->nameCheck($name, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $self->_objClass . '->clone',
            );

        } elsif ($session->ivExists('profHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: profile \'' . $name . '\' already exists',
                $self->_objClass . '->clone',
            );
        }

        # Setup
        my $clone = {
            _objName                    => $name,
            _objClass                   => $self->_objClass,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,           # All IVs are public

            # Standard profile IVs
            # --------------------

            name                        => $name,
            category                    => $self->category,
            parentWorld                 => undef,

            initTaskHash                => {},              # Set below
            initTaskOrderList           => [],              # Set below
            initTaskTotal               => $self->initTaskTotal,
            initScriptHash              => {},              # Set below
            initScriptOrderList         => [],              # Set below
            initMission                 => $self->initMission,
            initCmdList                 => [$self->initCmdList],

            setupCompleteFlag           => FALSE,           # Clone never been a current profile
            notepadList                 => [$self->notepadList],
            privateHash                 => {},
        };

        # Bless the cloned object into existence
        bless $clone, $self->_objClass;

        # Get the parent template object
        $templObj = $session->ivShow('templateHash', $self->category);

        # Clone the instance variables for this category of custom profile
        OUTER: foreach my $iv ($self->ivList) {

            # Don't use standard profile IVs specified by the GA::Client registry hash
            if (! $axmud::CLIENT->ivExists('constProfStandardHash', $iv)) {

                $clone->{$iv} = $self->{$iv};
            }
        }

        # Also need to clone everything in the initial tasklist
        $clone->cloneInitTaskList($self);

        return $clone;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

# Package must return a true value
1
