# Copyright (C) 2011-2019 A S Lewis
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
# Games::Axmud::Cage::XXX
# The code that handles a cage

{ package Games::Axmud::Cage::Cmd;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Cage Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Creates a new instance of the command cage
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session (not stored as an IV)
        #   $profName       - The parent profile's name (e.g. matches the object's ->name)
        #   $profCategory   - The profile's category (e.g. 'world', 'guild', 'faction' etc)
        #
        # Return values
        #   'undef' on improper arguments or if the cage already seems to exist
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $profName, $profCategory, $check) = @_;

        # Local variables
        my $name;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $profName || ! defined $profCategory
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Compose the cage's unique name
        $name = 'cmd_' . $profCategory . '_' . $profName;

        # Check that $name is valid and not already in use by another profile
        if (! $axmud::CLIENT->nameCheck($name, 42)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $class . '->new',
            );

        } elsif ($session->ivExists('cageHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: cage \'' . $name . '\' already exists',
                $class . '->new',
            );
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,           # All IVs are public

            # Standard cage IVs
            # -----------------

            name                        => $name,
            cageType                    => 'cmd',
            standardFlag                => TRUE,            # This is a built-in Axmud cage
            profName                    => $profName,
            profCategory                => $profCategory,

            # Command cage IVs
            # ----------------

            # Hash of standard commands and their replacements for the parent profile, in the form
            #   $commandHash{standard_command} = replacement_command
            #
            # Any word in the replacement_command can be changed (or 'interpolated') by the code
            #   that wants to send a command to the world, but the words 'object', 'direction',
            #   'victim', 'text', 'menu' and 'number' are almost always interpolated
            #       e.g. ->commandHash{'climb'} = 'climb object'
            #       e.g. ->commandHash{'throw_dir'} = 'throw object direction'
            # If a standard command isn't available at this world, the replacement_command should be
            #   set to an empty string.
            #       e.g. ->commandHash{'wake'} = ''
            # If this cage should consult a lower-priority cage to get the replacement command, the
            #   replacement_command should be set to undef.
            cmdHash                     => {},              # Set below
            # Hash of common words (nouns and pronouns) which should be automatically interpolated
            # For example, the standard command 'buy' has a replacement command 'buy object' which
            #   is usually interpolated into something like 'buy torch', but the command 'kill all'
            #   contains a very common object - 'all' - which should be automatically interpolated
            wordHash                    => {},              # Set below

            # A list of the standard commands used for movement (usually, those which include
            #   'direction' in the replacement_command). Used by GA::Buffer::Cmd->interpretCmd to
            #   detect when a movement command has taken place
            moveCmdList                 => [
                'go_dir',
                'run',
                'walk',
                'fly',
                'swim',
                'dive',
                'sail',
                'ride',
                'drive',
                'creep',
                'sneak',
                'squeeze',
                'move',
                'go',
            ],
        };

        # Bless the object into existence
        bless $self, $class;

        # Set the contents of the command cage's IVs
        $self->setup();

        return $self;
    }

    sub clone {

        # Creates a clone of an existing command cage
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session (not stored as an IV)
        #   $profName       - The parent profile's name (e.g. matches the object's ->name)
        #   $profCategory   - The profile's category (e.g. 'world', 'guild', 'faction' etc)
        #
        # Return values
        #   'undef' on improper arguments or if the cage already seems to exist
        #   Blessed reference to the newly-created object on success

        my ($self, $session, $profName, $profCategory, $check) = @_;

        # Local variables
        my $name;

        # Check for improper arguments
        if (
            ! defined $session || ! defined $profName || ! defined $profCategory
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Compose the cage's unique name
        $name = 'cmd_' . $profCategory . '_' . $profName;

        # Check that $name is valid and not already in use by another profile
        if (! $axmud::CLIENT->nameCheck($name, 42)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $self->_objClass . '->clone',
            );

        } elsif ($session->ivExists('cageHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: cage \'' . $name . '\' already exists',
                $self->_objClass . '->clone',
            );
        }

        # Setup
        my $clone = {
            _objName                    => $name,
            _objClass                   => $self->_objClass,
            _parentFile                 => 'otherprof',
            _parentWorld                => undef,
            _privFlag                   => FALSE,               # All IVs are public

            # Standard cage IVs
            # -----------------

            name                        => $name,
            cageType                    => 'cmd',
            standardFlag                => TRUE,                # This is a built-in Axmud cage
            profName                    => $profName,
            profCategory                => $profCategory,

            # Command cage IVs
            # ----------------

            cmdHash                     => {$self->cmdHash},
            wordHash                    => {$self->wordHash},

            moveCmdList                 => [$self->moveCmdList],
        };

        # Bless the cloned object into existence
        bless $clone, $self->_objClass;
        return $clone;
    }

    ##################
    # Methods

    sub setup {

        # Called by $self->new
        # Sets the contents of the command cage's IVs
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
            @list,
            %cmdHash, %wordHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setup', @_);
        }

        # Standard commands and their replacements
        @list = (
            # NB If new standard commands are added, the GA::Buffer::Cmd->interpretCmd function
            #   may need to be modified

            # connect to world
            connect         => 'connect name password',
            # send maximum columns to world
            cols            => 'cols number',
            # send maximum rows to world
            rows            => 'rows number',
            # send termtype (e.g. ansi) to world
            term            => 'term text',

            # Turns on verbose descriptions
            verbose         => 'brief off',
            # Turns on brief descriptions
            brief           => 'brief on',

            # get full room description
            look            => 'look',
            short_look      => 'l',
            # get brief room description
            glance          => 'glance',
            short_glance    => 'gl',
            # get inventory
            inventory       => 'inventory',
            # search room for hidden objects
            search          => 'search',
            # examine object
            examine         => 'examine object',

            # run in a direction
            run             => 'run direction',
            # walk in a direction
            walk            => 'walk direction',
            # fly in a sirection
            fly             => 'fly direction',
            # swim in a direction
            swim            => 'swim direction',
            # dive in a direction
            dive            => 'dive direction',
            # sail in a direction
            sail            => 'sail direction',
            # ride in a direction
            ride            => 'ride direction',
            # drive in a direction
            drive           => 'drive direction',
            # creep into new room, becoming invisible there
            creep           => 'creep direction',
            # sneak from the current room, so that the disappearance isn't seen by other beings
            sneak           => 'sneak direction',
            # squeeze through a small exit
            squeeze         => 'squeeze direction',
            # go in a direction
            go_dir          => 'go direction',
            # move in a direction (general-purpose command for any verb not covered above)
#            move            => 'move direction',
            # (Disabled by default, so 'move box' isn't confused as a movement)
            move            => '',
            # (For any world in which it's possible to type 'north' to move - a direction, without
            #   a verb - this special standard command covers it. The value should either be
            #   'direction' - if it's possible to type 'north' in order to move - or an empty
            #   string, if not)
            go              => 'direction',
            # Special teleportation command, used when the game allows teleportation (reaching a
            #   destination location from many different departure locations). The 'room' word can
            #   be the name used by the world. If the world model has a room with an identical
            #   room tag, that's the assumed target destination; otherwise the target destination
            #   is unknown
            teleport        => 'teleport room',

            # become hidden
            hide            => 'hide',
            # become unhidden
            unhide          => 'unhide',
            # climb
            climb           => 'climb',
            # climb something
            climb_obj       => 'climb object',
            # jump
            jump            => 'jump',
            # jump into something
            jump_obj        => 'jump into object',

            # pick something up
            get             => 'get object',
            # drop something
            drop            => 'drop object',
            # put something in something
            put             => 'put object in target',
            # give something to target
            give_to         => 'give object to target',
            # get something from something
            get_from        => 'get object from target',

            # loot a (single) corpse - get a single object from the corpse
            loot            => 'get object from target',
            # loot a (single) corpse - get everything from the corpse
            loot_corpse     => 'get all from corpse',
            # loot a room (use empty string if it's not possible to do 'loot all corpses' with a
            #   single command at this world)
            loot_room       => 'get all from corpses',
            # rob a (single) corpse - get all cash from the corpse, but leave its possessions intact
            rob_corpse      => 'get coins from corpse',
            # rob a room
            rob_room        => 'get coins from corpses',
            # dispose of a (single) corpse
            dispose_corpse  => 'bury corpse',
            # dispose of every corpses in a room
            dispose_room    => 'bury corpses',

            # throw something
            throw           => 'throw object',
            # throw object in a direction
            throw_dir       => 'throw object direction',
            # wave something
            wave            => 'wave object',
            # wave something at someone
            wave_victim     => 'wave object at victim',
            # read something
            read            => 'read object',
            # write something
            write           => 'write text',
            # write something on something
            write_on        => 'write text on object',

            # run away when health reaches certain level
            wimpy           => 'wimpy number',

            # wield, wear and hold all items
            equip           => 'equip',
            # stop wielding, wearing and holding all items
            unequip         => 'unequip',
            # wield a weapon
            wield           => 'wield object',
            # unwield a weapon
            unwield         => 'lower object',
            # wear something
            wear            => 'wear object',
            # stop wearing something
            unwear          => 'remove object',
            # hold something
            hold            => 'hold object',
            # stop holding something
            unhold          => 'remove object',

            # attacks - kill target
            kill            => 'kill victim',
            # kill target using a guild command
            guild_kill      => 'kill victim',
            # kill target using a race command
            race_kill       => 'kill victim',
            # attacks - interact with a target (e.g. 'mug victim')
            interact        => 'mug victim',
            # interact with target using a guild command
            guild_interact  => 'mug victim',
            # interact with target using a race command
            race_interact   => 'mug victim',

            # say something
            say             => 'say text',
            # say something to someone
            say_to          => 'say to victim text',
            # ask something something
            ask             => 'ask victim text',
            # ask something about something
            ask_about       => 'ask victim about text',
            # tell someone something
            tell            => 'tell victim text',
            # tell someone about something
            tell_about      => 'tell victim text',
            # shout something to all connected characters
            shout           => 'shout text',
            # say something rude
            swear           => 'damn',

            # read help files
            help            => 'help text',
            # verbose score
            score           => 'score',
            # brief score
            sc              => 'sc',
            # get character's stats (e.g. 'dex', 'int', 'con', etc)
            stats           => 'stats',
            # character's current level
            level           => 'level',
            # list of connected characters
            who             => 'who',
            # game time
            time            => 'time',
            # real-world time
            date            => 'date',
            # disconnect
            quit            => 'quit',
            # set world's termtype
            term            => 'term text',

            # eat something
            eat             => 'eat object',
            # drink something
            drink           => 'drink object',
            # go to sleep
            sleep           => 'sleep',
            # wake up
            wake            => 'wake',

            # cost of advancing a skill
            cost            => 'cost text',
            # cost of advancing all skills
            cost_all        => 'cost all',
            # advance a skill
            advance         => 'advance text',

            # tie something
            tie             => 'tie object',
            # tie something to something else
            tie_to          => 'tie object to object',
            # untie something
            untie           => 'untie object',
            # untie something from something else
            untie_from      => 'untie object from object',

            # deposit some money into bank
            deposit         => 'deposit number text coins',
            # deposit all money
            deposit_all     => 'deposit coins',
            # deposit all coins of a certain type
            deposit_type    => 'deposit text coins',
            # withdraw some money from bank
            withdraw        => 'withdraw number text coins',
            # withdraw all money from bank
            withdraw_all    => 'withdraw coins',
            # withdraw all coins of a certain type
            withdraw_type   => 'withdraw text coins',
            # get bank balance
            balance         => 'balance',
            # open account at bank
            open_account    => 'open account',
            # close account at bank
            close_account   => 'close account',

            # open a door
            open            => 'open door',
            # e.g. 'open southwest door'
            open_dir        => 'open direction door',
            close           => 'close door',
            close_dir       => 'close direction door',
            unlock          => 'unlock direction door',
            unlock_with     => 'unlock direction door with keys',
            lock            => 'lock direction door',
            lock_with       => 'lock direction door with keys',
            pick            => 'pick direction door',
            pick_with       => 'pick direction door with lockpick',
            break           => 'break direction door',
            break_with      => 'break direction door with crowbar',

            # follow someone
            follow          => 'follow victim',
            # stop following someone
            unfollow        => 'unfollow victim',
            # allow someone to follow
            consent         => 'consent victim',
            # stop someone from following you
            lose            => 'lose victim',
            # list people following you
            followers       => 'followers',
            # protect someone (tank)
            protect         => 'protect victim',
            # stop protecting someone
            unprotect       => 'unprotect victim',

            # summon guild minions
            summon          => 'summon',
            # summon specific guild minion
            summon_victim   => 'summon victim',
            # fighter guild commands
            resize          => 'resize object',
            repair          => 'repair object',
            # cleric guild commands
            bury            => 'bury object',
            recite          => 'recite text',
            meditate        => 'meditate text',
            # bard guild commands
            sing            => 'sing text',
            # wizard guild commands
            cast            => 'cast text',
            memorise        => 'memorise text',

            # buy something
            buy             => 'buy object',
            # sell something
            sell            => 'sell object',
            # sell everything
            sell_all        => 'sell all',
            # value something
            value           => 'value object',
            # get information about something for sale
            browse          => 'browse object',
            # list things for sale
            list            => 'list',
            # list of things for sale at pub/cafe
            read_menu       => 'read menu',
        );

        do {

            my $standard = shift @list;
            my $replacement = shift @list;

            if ($self->profCategory eq 'world') {

                $cmdHash{$standard} = $replacement;

            } else {

                # Higher-priority cage have 'undef' as replacements so that the cage belonging to
                #   the next profile in the priority list can be consulted
                $cmdHash{$standard} = undef;
            }

        } until (! @list);

        # Other words and their replacement words
        @list = (
            # The word for 'all'
            all             => 'all',
            # The world's word for 'all non-player characters'
            mall            => 'mall',
            # The word for coin
            coin            => 'coin',
            # The word for coins
            coins           => 'coins',
            # The word for your character
            me              => 'me',
            # The word for all characters in your group (not available on most worlds)
            us              => 'us',
            # The word for any object, used in context (not available on most worlds)
            it              => 'it',
            # The word for any group of objects, used in context (not available on most worlds)
            them            => 'them',
        );

        do {

            my $standard = shift @list;
            my $replacement = shift @list;

            if ($self->profCategory eq 'world') {

                $wordHash{$standard} = $replacement;

            } else {

                # Higher-priority cage have 'undef' as replacements so that the cage belonging to
                #   the next profile in the priority list can be consulted
                $wordHash{$standard} = undef;
            }

        } until (! @list);

        # Update IVs
        $self->{cmdHash} = \%cmdHash;
        $self->{wordHash} = \%wordHash;

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    # NB These methods set/return the cage's ACTUAL command hash. To get/set values from this hash
    #   AND/OR its inferiors, use the generic cage's ->ivXXX functions
    sub cmdHash
        { my $self = shift; return %{$self->{cmdHash}}; }
    sub wordHash
        { my $self = shift; return %{$self->{wordHash}}; }

    sub moveCmdList
        { my $self = shift; return @{$self->{moveCmdList}}; }
}

{ package Games::Axmud::Cage::Trigger;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::InterfaceCage Games::Axmud::Generic::Cage
        Games::Axmud
    );

    ##################
    # Constructors

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::Cage::Alias;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::InterfaceCage Games::Axmud::Generic::Cage
        Games::Axmud
    );

    ##################
    # Constructors

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::Cage::Macro;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::InterfaceCage Games::Axmud::Generic::Cage
        Games::Axmud
    );

    ##################
    # Constructors

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::Cage::Timer;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::InterfaceCage Games::Axmud::Generic::Cage
        Games::Axmud
    );

    ##################
    # Constructors

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::Cage::Hook;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::InterfaceCage Games::Axmud::Generic::Cage
        Games::Axmud
    );

    ##################
    # Constructors

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::Cage::Route;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Cage Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Creates a new instance of the route cage
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session (not stored as an IV)
        #   $profName       - The parent profile's name (e.g. matches the object's ->name)
        #   $profCategory   - The profile's category (e.g. 'world', 'guild', 'faction' etc)
        #
        # Return values
        #   'undef' on improper arguments or if the cage already seems to exist
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $profName, $profCategory, $check) = @_;

        # Local variables
        my $name;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $profName || ! defined $profCategory
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Compose the cage's unique name
        $name = 'route_' . $profCategory . '_' . $profName;

        # Check that $name is valid and not already in use by another profile
        if (! $axmud::CLIENT->nameCheck($name, 42)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $class . '->new',
            );

        } elsif ($session->ivExists('cageHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: cage \'' . $name . '\' already exists',
                $class . '->new',
            );
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'otherprof',
            _parentWorld                => $session->currentWorld->name,
            _privFlag                   => FALSE,           # All IVs are public

            # Standard cage IVs
            # -----------------

            name                        => $name,
            cageType                    => 'route',
            standardFlag                => TRUE,            # This is a built-in Axmud cage
            profName                    => $profName,
            profCategory                => $profCategory,

            # Route cage IVs
            # --------------

            # Hash of GA::Obj::Route (stores a fixed route between two rooms, or a fixed circuit
            #   starting and stopping at the same room). Hash in the form
            #
            #   $routeHash{r_start-room-tag@@@stop-room-tag} = blessed_reference_to_route_object
            #       (for road routes, where 'start-room-tag' and 'stop-room-tag' are strings
            #       matching GA::Obj::Route->startRoom and ->stopRoom)
            #   $routeHash{q_start-room-tag@@@stop-room-tag} = blessed_reference_to_route_object
            #       (for quick routes, where 'start-room-tag' and 'stop-room-tag' are strings
            #       matching GA::Obj::Route->startRoom and ->stopRoom)
            #   $routeHash{c_start-room-tag@@@circuit-name} = blessed_reference_to_route_object
            #       (for circuit routes, where 'start-room-tag' matches GA::Obj::Route->startRoom
            #       and 'circuit-name' matches GA::Obj::Route->circuitName)
            routeHash                   => {},
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    sub clone {

        # Creates a clone of an existing route cage
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session (not stored as an IV)
        #   $profName       - The parent profile's name (e.g. matches the object's ->name)
        #   $profCategory   - The profile's category (e.g. 'world', 'guild', 'faction' etc)
        #
        # Return values
        #   'undef' on improper arguments or if the cage already seems to exist
        #   Blessed reference to the newly-created object on success

        my ($self, $session, $profName, $profCategory, $check) = @_;

        # Local variables
        my $name;

        # Check for improper arguments
        if (
            ! defined $session || ! defined $profName || ! defined $profCategory
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Compose the cage's unique name
        $name = 'route_' . $profCategory . '_' . $profName;

        # Check that $name is valid and not already in use by another profile
        if (! $axmud::CLIENT->nameCheck($name, 42)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $self->_objClass . '->clone',
            );

        } elsif ($session->ivExists('cageHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: cage \'' . $name . '\' already exists',
                $self->_objClass . '->clone',
            );
        }

        # Setup
        my $clone = {
            _objName                    => $name,
            _objClass                   => $self->_objClass,
            _parentFile                 => 'otherprof',
            _parentWorld                => undef,
            _privFlag                   => FALSE,               # All IVs are public

            # Standard cage IVs
            # -----------------

            name                        => $name,
            cageType                    => 'route',
            standardFlag                => TRUE,            # This is a built-in Axmud cage
            profName                    => $profName,
            profCategory                => $profCategory,

            # Route cage IVs
            # --------------

            routeHash                   => {$self->routeHash},
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

    # NB These methods set/return the cage's ACTUAL route hash. To get/set values from this hash
    #   AND/OR its inferiors, use the generic cage's ->ivXXX functions
    sub routeHash
        { my $self = shift; return %{$self->{routeHash}}; }
}

# Package must return a true value
1
