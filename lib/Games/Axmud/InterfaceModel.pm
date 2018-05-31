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
# Games::Axmud::InterfaceModel::XXX
# Code that handles default settings for interfaces (triggers, alias, macros, timers and hooks)

{ package Games::Axmud::InterfaceModel::Trigger;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::InterfaceModel Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Creates a new instance of the interface model object for triggers
        #
        # Axmud interfaces are triggers, aliases, macros, timers and hooks. Interface models contain
        #   default value for each type of interface. The GA::Client object stores one model
        #   interface object for every type of interface
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $check) = @_;

        # Check for improper arguments
        if (! defined $class || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'trigger',
            _objClass                   => $class,
            _parentFile                 => undef,           # No parent file object
            _parentWorld                => undef,           # No parent file object
            _privFlag                   => TRUE,            # All IVs are private

            # Interface category
            # ------------------

            category                    => 'trigger',       # Shortcut to $self->_objClass

            # Trigger attributes
            # ------------------

            stimulusName                => 'pattern',
            responseName                => 'instruction',   # Or a pattern/substitution

            # Default values for each trigger attribute
            optionalAttribHash          => {
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
                'style_mode'            => 0,       # 0     - don't apply style
                                                    # -1    - apply style to whole line
                                                    # -2    - apply to matched text
                                                    # 1+    - apply to matched substring
                'style_text'            => '',      # Empty string or standard/xterm/RGB text colour
                                                    #   tag
                'style_underlay'        => '',      # Empty string or standard/xterm/RGB underlay
                                                    #   colour tag
                'style_italics'         => 0,       # 0 (do not change), 1 (yes), 2 (no)
                'style_underline'       => 0,       # 0 (do not change), 1 (yes), 2 (no)
                'style_blink_slow'      => 0,       # 0 (do not change), 1 (yes), 2 (no)
                'style_blink_fast'      => 0,       # 0 (do not change), 1 (yes), 2 (no)
                'style_strike'          => 0,       # 0 (do not change), 1 (yes), 2 (no)
                'style_link'            => 0,       # 0 (do not change), 1 (yes), 2 (no)
            },

            # Acceptable values for all attributes (standard interface and trigger)
            attribTypeHash              => {
                # Standard
                'name'                  => 'string',
                'stimulus'              => 'pattern',
                'response'              => 'instruction',   # Or a substitution
                'enabled'               => 'boolean',
                # Trigger
                'splitter'              => 'boolean',
                'split_after'           => 'boolean',
                'keep_splitting'        => 'boolean',
                'rewriter'              => 'boolean',
                'rewrite_global'        => 'boolean',
                'ignore_case'           => 'boolean',
                'gag'                   => 'boolean',
                'gag_log'               => 'boolean',
                'need_prompt'           => 'boolean',
                'need_login'            => 'boolean',
                'keep_checking'         => 'boolean',
                'default_pane'          => 'boolean',
                'pane_name'             => 'string',
                'temporary'             => 'boolean',
                'style_mode'            => 'mode',
                'style_text'            => 'colour',
                'style_underlay'        => 'underlay',
                'style_italics'         => 'style',
                'style_underline'       => 'style',
                'style_blink_slow'      => 'style',
                'style_blink_fast'      => 'style',
                'style_strike'          => 'style',
                'style_link'            => 'style',
            },

            # Switches used in client commands
            compulsorySwitchHash        => {
                'stimulus'              => 's',
                'response'              => 'p',
            },

            optionalSwitchHash          => {
                'name'                  => 'n',
                'enabled'               => 'e',
                'splitter'              => 'sp',    # Don't like two letters, but run out of letters
                'split_after'           => 'sa',
                'keep_splitting'        => 'ks',
                'rewriter'              => 'rw',
                'rewrite_global'        => 'rg',
                'ignore_case'           => 'o',
                'gag'                   => 'a',
                'gag_log'               => 'l',
                'need_prompt'           => 'pr',
                'need_login'            => 'lg',
                'keep_checking'         => 'k',
                'default_pane'          => 'dp',
                'pane_name'             => 'pn',
                'temporary'             => 't',
                'style_mode'            => 'm',
                'style_text'            => 'h',
                'style_underlay'        => 'j',
                'style_italics'         => 'it',
                'style_underline'       => 'u',
                'style_blink_slow'      => 'bs',
                'style_blink_fast'      => 'bf',
                'style_strike'          => 'q',
                'style_link'            => 'lk',
            },
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::InterfaceModel::Alias;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::InterfaceModel Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Creates a new instance of the interface model object for aliases
        #
        # Axmud interfaces are triggers, aliases, macros, timers and hooks. Interface models contain
        #   default value for each type of interface. The GA::Client object stores one model
        #   interface object for every type of interface
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $check) = @_;

        # Check for improper arguments
        if (! defined $class || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'alias',
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Interface category
            # ------------------

            category                    => 'alias',     # Shortcut to $self->_objClass

            # Alias attributes
            # ----------------

            stimulusName                => 'pattern',
            responseName                => 'substitution',

            # Default values for each alias attribute
            optionalAttribHash          => {
                'ignore_case'           => TRUE,
                'keep_checking'         => FALSE,
                'temporary'             => FALSE,
            },

            # Acceptable values for all attributes (standard interface and alias)
            attribTypeHash              => {
                # Standard
                'name'                  => 'string',
                'stimulus'              => 'pattern',
                'response'              => 'substitution',
                'enabled'               => 'boolean',
                # Alias
                'ignore_case'           => 'boolean',
                'keep_checking'         => 'boolean',
                'temporary'             => 'boolean',
            },

            # Switches used in client commands
            compulsorySwitchHash        => {
                'stimulus'              => 's',
                'response'              => 'p',
            },

            optionalSwitchHash          => {
                'name'                  => 'n',
                'enabled'               => 'e',
                'ignore_case'           => 'o',
                'keep_checking'         => 'k',
                'temporary'             => 't',
            },
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::InterfaceModel::Macro;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::InterfaceModel Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Creates a new instance of the interface model object for macros
        #
        # Axmud interfaces are triggers, aliases, macros, timers and hooks. Interface models contain
        #   default value for each type of interface. The GA::Client object stores one model
        #   interface object for every type of interface
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $check) = @_;

        # Check for improper arguments
        if (! defined $class || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'macro',
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Interface category
            # ------------------

            category                    => 'macro',     # Shortcut to $self->_objClass

            # Macro attributes
            # ----------------

            stimulusName                => 'keycode',
            responseName                => 'instruction',

            # Default values for each macro attribute
            optionalAttribHash          => {
                'temporary'             => FALSE,
            },

            # Acceptable values for all attributes (standard interface and macro)
            attribTypeHash              => {
                # Standard
                'name'                  => 'string',
                'stimulus'              => 'keycode',
                'response'              => 'instruction',
                'enabled'               => 'boolean',
                # Macro
                'temporary'             => 'boolean',
            },

            # Switches used in client commands
            compulsorySwitchHash        => {
                'stimulus'              => 's',
                'response'              => 'p',
            },

            optionalSwitchHash          => {
                'name'                  => 'n',
                'enabled'               => 'e',
                'temporary'             => 't',
            },
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::InterfaceModel::Timer;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::InterfaceModel Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Creates a new instance of the interface model object for timers
        #
        # Axmud interfaces are triggers, aliases, macros, timers and hooks. Interface models contain
        #   default value for each type of interface. The GA::Client object stores one model
        #   interface object for every type of interface
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $check) = @_;

        # Check for improper arguments
        if (! defined $class || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'timer',
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Interface category
            # ------------------

            category                    => 'timer',    # Shortcut to $self->_objClass

            # Timer attributes
            # ------------------

            stimulusName                => 'interval',
            responseName                => 'instruction',

            # Default values for each timer attribute
            optionalAttribHash          => {
                'count'                 => -1,
                'initial_delay'         => 0,
                'random_delay'          => FALSE,
                'random_min'            => 0,
                'wait_login'            => TRUE,
                'temporary'             => FALSE,
            },

            # Acceptable values for all attributes (standard interface and timer)
            attribTypeHash              => {
                # Standard
                'name'                  => 'string',
                'stimulus'              => 'interval',          # Interval
                'response'              => 'instruction',       # Instruction
                'enabled'               => 'boolean',
                # Timer
                'count'                 => 'repeat_count',      # -1 or a positive integer
                'initial_delay'         => 'number',            # 0 or a positive number
                'random_delay'          => 'boolean',
                'random_min'            => 'number',            # 0 or a positive number
                'wait_login'            => 'boolean',
                'temporary'             => 'boolean',
            },

            # Switches used in client commands
            compulsorySwitchHash        => {
                'stimulus'              => 's',
                'response'              => 'p',
            },

            optionalSwitchHash          => {
                'name'                  => 'n',
                'enabled'               => 'e',
                'count'                 => 'o',
                'initial_delay'         => 'i',
                'random_delay'          => 'r',
                'random_min'            => 'm',
                'wait_login'            => 'w',
                'temporary'             => 't',
            },
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::InterfaceModel::Hook;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::InterfaceModel Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Creates a new instance of the interface model object for hooks
        #
        # Axmud interfaces are triggers, aliases, macros, timers and hooks. Interface models contain
        #   default value for each type of interface. The GA::Client object stores one model
        #   interface object for every type of interface
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $check) = @_;

        # Check for improper arguments
        if (! defined $class || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'hook',
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Interface category
            # ------------------

            category                    => 'hook',      # Shortcut to $self->_objClass

            # Hook attributes
            # ---------------

            stimulusName                => 'hook_event',
            responseName                => 'instruction',

            # Default values for each hook attribute
            optionalAttribHash          => {
                'temporary'             => FALSE,
            },

            # Acceptable values for all attributes (standard interface and hook)
            attribTypeHash              => {
                # Standard
                'name'                  => 'string',
                'stimulus'              => 'hook_event',
                'response'              => 'instruction',
                'enabled'               => 'boolean',
                # Hook
                'temporary'             => 'boolean',
            },

            # Switches used in client commands
            compulsorySwitchHash        => {
                'stimulus'              => 's',
                'response'              => 'p',
            },

            optionalSwitchHash          => {
                'name'                  => 'n',
                'enabled'               => 'e',
                'temporary'             => 't',
            },

            # Available hook events. The key is the hook event name, the corresponding value is the
            #   number of hook data items to expect
            hookEventHash               => {
                # Fired by GA::Session->connectionComplete when the first text is received from the
                #   world (meaning we're connected)
                # (Hook data: none)
                'connect'               => 0,
                # Fired by GA::Session->reactDisconnect when we are disconnected from the world
                # (Hook data: none)
                'disconnect'            => 0,
                # Fired by GA::Session->doLogin when the character is marked as 'logged in'
                # (Hook data: none)
                'login'                 => 0,
                # Fired by GA::Session->processPrompt when something that looks like a prompt is
                #   received from the world - after waiting a short time, to confirm that the world
                #   isn't about to send the rest of an incomplete line. If the user types a command
                #   in the mean time, the 'prompt' event doesn't fire
                # (Hook data: the line, stripped of escape sequences)
                'prompt'                => 1,
                # Fired by GA::Session->processLineSegment when any text is received
                # (Hook data: the line, stripped of escape sequences)
                'receive_text'          => 1,
                # Fired by GA::Session->worldCmd or ->teleportCmd when an instruction contains a
                #   world command (an instruction like 'open door;n;kill orc' counts as three world
                #   commands, and causes the hook to fire three times. The hook fires BEFORE the
                #   world command is modified by any aliases, etc)
                # (Hook data: the command being processed)
                'sending_cmd'           => 1,
                # Fired by GA::Session->dispatchCmd when a world command is actually sent to the
                #   world, AFTER any aliases (etc) have acted on it
                # (Hook data: the command to be sent)
                'send_cmd'              => 1,
                # Fired by GA::Session->processMsdpData when MSDP data is received (the hook is
                #   fired once for each variable/value pair received)
                # (Hook data: The variable/value pair received)
                'msdp'                  => 2,
                # Fired by GA::Session->processMsspData when MSSP data is received (the hook is
                #   fired once for each variable/value pair received)
                # (Hook data: The variable/value pair received)
                'mssp'                  => 2,
                # Fired by GA::Session->processAtcpData when ATCP data is received (the hook is
                #   fired once for each ATCP packet received)
                # (Hook data: The name of the ATCP package received)
                'atcp'                  => 1,
                # Fired by GA::Session->processGmcpData when GMCP data is received (the hook is
                #   fired once for each GMCP packet received)
                # (Hook data: The name of the GMCP package received)
                'gmcp'                  => 1,
                # Fired by GA::Client->setCurrentSession when the session becomes the one visible
                #   in the 'main' window that has focus)
                # (Hook data: none)
                'current_session'       => 0,
                # Fired by GA::Client->setCurrentSession when a different session becomes the one
                #   visible in the 'main' window that has focus
                # (Hook data: the new current session's ->number)
                'not_current'           => 1,
                # Fired in every session by GA::Client->setCurrentSession when the visible session
                #   in the 'main' window that has focus changes
                # (Hook data: the new current session's ->number)
                'change_session'        => 1,
                # Fired by GA::Win::Internal->setVisibleSession when the session becomes the one
                #   visible in its 'main' window)
                # (Hook data: none)
                'visible_session'       => 0,
                # Fired by GA::Win::Internal->setVisibleSession when a different session becomes the
                #   one visible in the former's 'main' window
                # (Hook data: the new current session's ->number)
                'not_visible'           => 1,
                # Fired in every session by GA::Win::Internal->setVisibleSession when a 'main'
                #   window's visible session changes
                # (Hook data: the new current session's ->number)
                'change_vivible'        => 1,
                # Fired by GA::Session->spinTimerLoop when the user has been idle for 60 seconds
                #   (and no world commands have been sent)
                # (Hook data: GA::Session->lastCmdTime, the time at which the last command was sent)
                'user_idle'             => 1,
                # Fired by GA::Session->spinTimerLoop when no text has been received from the world
                #   world for 60 seconds
                # (Hook data: GA::Session->lastDisplayTime, the time at which the last text was
                #   received)
                'world_idle'            => 1,
                # Fired by ->signal_connect in GA::Win::Internal->setFocusInEvent when the
                #   'internal' window gets focus
                # (Hook data: none)
                'get_focus'             => 0,
                # Fired by ->signal_connect in GA::Win::Internal->setFocusOutEvent when the
                #   'internal' window gets focus
                # (Hook data: none)
                'lose_focus'            => 0,
                # Fired by GA::Client->stop when the client stops executing
                # (Hook data: none)
                'close_disconnect'      => 0,
            },
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub hookEventHash
        { my $self = shift; return %{$self->{hookEventHash}}; }
}

# Package must return true
1
