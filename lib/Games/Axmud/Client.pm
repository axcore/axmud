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
# Games::Axmud::Client
# The main body of code for the Axmud client

{ package Games::Axmud::Client;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);
    # Include module here, as well as in axmud.pl, so that .../t/00-compile.t won't fail
    use Archive::Tar;

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by axmud.pl on startup
        #
        # Expected arguments
        #   (none besides $class)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success. The calling function sets the
        #       $CLIENT global variable

        my ($class, $check) = @_;

        # Local variables
        my (
            $urlRegex, $shortRegex, $emailRegex,
            @cmdList,
            %soundHash, %msspHash,
        );

        # Check for improper arguments
        if (! defined $class || defined $check) {

            # Global variable $axmud::CLIENT not set yet, so we'll just have to print the
            #   improper arguments message
            print "IMPROPER ARGUMENTS: Games::Axmud::Client->new " . join(' ', @_) . "\n";
            return undef;
        }

        # Set regexes to recognise URLs
        $urlRegex = 'http(s?)\:\/\/[0-9a-zA-Z]([-.\w]*[0-9a-zA-Z])*(:(0-9)*)*(\/?)'
                        . '([a-zA-Z0-9\-?\.\?\,\'\/\\\+&amp;%\$#_\=\~]*)?';
        $shortRegex = '[0-9a-zA-Z]([-.\w]*[0-9a-zA-Z])*\.(com|org|net|int|edu|gov|mil|io|uk)';
        # Set a regex to recognise email addresses
        $emailRegex = '\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b';

        # Setup
        my $self = {
            _objName                    => 'client',
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Perl object components
            # ----------------------

            # The main desktop object (GA::Obj::Desktop), which arranges windows on the desktop
            #   across one or more workspaces
            desktopObj                  => undef,

            # An IV which stores a 'main' window. First set when Axmud starts, and a spare 'main'
            #   window, not belonging to any session, opens before the Connections window opens
            # Briefly set back to 'undef' when the spare 'main' window is destroyed, just before a
            #   new 'main' window for a new session is created to replace it
            # Then set whenever $self->currentSession is set
            mainWin                     => undef,

            # The About window (only one can be open at a time)
            aboutWin                    => undef,       # Set by $self->set_aboutWin
            # A 'dialogue' window created by a call to GA::Generic::Win->showBusyWin, e.g. the
            #   'Loading...' window created by $self->start
            busyWin                     => undef,       # Set by $self->set_busyWin
            # The Connections window (only one can be open at a time)
            connectWin                  => undef,       # Set by $self->set_connectWin
            # The Client Console window (only one can be open at a time)
            consoleWin                  => undef,       # Set by $self->set_consoleWin

            # Instance variable constants
            # ---------------------------

            # All of Axmud's Perl objects have instance variables (IVs); the vast majority of them
            #   are either scalar IVs (including references stored in scalar variables), list IVs or
            #   hash IVs. There are a few more complex structures (e.g. arrays of arrays, hashes of
            #   arrays, etc), but besides that, there no other data structures (globs, etc)
            #
            # All objects have five standard 'constant' IVs which should not be modified, namely
            #   ->_objName, ->_objClass, ->_parentFile, ->_parentWorld and ->privFlag.
            # ->_objName gives a name to an object, even if it doesn't have a ->name IV.
            #   ->_objName is not necessarily unique
            # ->_objectClass is the same as the package name for the object (e.g. GA::Client)
            # ->_parentFile matches a key in the file object registry, $self->fileObjHash (see
            #   further below). It tells us which data file is used to save this object. (A few
            #   objects don't have a parent file; in these casees, ->_parentFile is set to 'undef')
            # ->_parentWorld is the name of the current world profile, in the GA::Session to which
            #   the object belongs. (Some objects don't belong to a particular GA::Session; in these
            #   cases, ->_parentWorld is set to 'undef')
            # ->_privFlag is set to TRUE if the object's IVs are private; FALSE if they are public.
            #   (See the comments at the top of generic_obj.pm)
            #
            # In addition, any IV whose name begins with 'const' is treated as a constant value
            #   which should not be modified
            #
            # The generic object, Games::Axmud, from which all Axmud objects inherit, provides
            #   several useful functions for accessing and storing values for all IVs, such as
            #   ->ivPush, ->ivSplice and ->ivPeek
            # The most important one is ->ivPoke. When an IV's value (or values) are set, it should
            #   not be done with a call to
            #       $self->{iv_name} = $value
            #   but with a call to
            #       $self->ivPoke('iv_name', $value)
            # ->ivPoke (like all the generic object's IV functions) tells the equivalent
            #   GA::Obj::File that its data has been modified, and that it needs to be saved
            # ->ivPoke, etc, can't be used to modify constant IVs (the five mentioned above, and any
            #   IV whose names starts 'const'
            #
            # Constant registry hash of constant instance variables (IVs) required by every Perl
            #   object. A hash in the form
            #   $constIVHash{iv_name} = undef
            constIVHash                 => {
                '_objName'              => undef,
                '_objClass'             => undef,
                '_parentFile'           => undef,
                '_parentWorld'          => undef,
                '_privFlag'             => undef,
            },
            # Constant registry hash of reserved names that can't be used by profiles and other
            #   Perl objects which have unique names (case-insensitive; these values never change)
            # Hash in the form
            #   $constReservedHash{string} = undef
            # NB Plurals have been added only when necessary, specifically because there's a file
            #   object with a name in the plural
            constReservedHash           => {
                'about'                 => undef,
                'alias'                 => undef,
                'amud'                  => undef,
                'axmud'                 => undef,
                'automap'               => undef,
                'automapper'            => undef,
                'buffer'                => undef,
                'cage'                  => undef,
                'client'                => undef,
                'cmd'                   => undef,
                'colour'                => undef,
                'color'                 => undef,   # American too
                'component'             => undef,
                'config'                => undef,
                'connect'               => undef,
                'console'               => undef,
                'contact'               => undef,
                'contacts'              => undef,
                'current'               => undef,
                'custom'                => undef,
                'default'               => undef,
                'defn'                  => undef,
                'definition'            => undef,
                'delete'                => undef,
                'desktop'               => undef,
                'dict'                  => undef,
                'dictionary'            => undef,
                'dicts'                 => undef,
                'edit'                  => undef,
                'exit'                  => undef,
                'external'              => undef,
                'favourite'             => undef,
                'favorite'              => undef,   # American too
                'file'                  => undef,
                'fixed'                 => undef,
                'flag'                  => undef,
                'free'                  => undef,
                'gauge'                 => undef,
                'generic'               => undef,
                'grid'                  => undef,
                'gui'                   => undef,
                'hash'                  => undef,
                'help'                  => undef,
                'hook'                  => undef,
                'icon'                  => undef,
                'init'                  => undef,
                'interface'             => undef,
                'internal'              => undef,
                'jmud'                  => undef,   # Old JMud plugin for KildClient
                'keycode'               => undef,
                'keycodes'              => undef,
                'label'                 => undef,
                'link'                  => undef,
                'list'                  => undef,
                'load'                  => undef,
                'localhost'             => undef,
                'login'                 => undef,
                'loop'                  => undef,
                'macro'                 => undef,
                'main'                  => undef,
                'map'                   => undef,
                'misc'                  => undef,
                'mission'               => undef,
                'model'                 => undef,
                'name'                  => undef,
                'node'                  => undef,
                'not_applicable'        => undef,   # Used in data files to represent assoc'd world
                'obj'                   => undef,
                'other'                 => undef,
                'otherdefn'             => undef,
                'otherprof'             => undef,
                'package'               => undef,
                'phrasebook'            => undef,
                'plugin'                => undef,
                'pref'                  => undef,
                'preference'            => undef,
                'profile'               => undef,
                'pseudo'                => undef,
                'quest'                 => undef,
                'region'                => undef,
                'regionmap'             => undef,
                'regionpath'            => undef,
                'room'                  => undef,
                'save'                  => undef,
                'scalar'                => undef,
                'scheme'                => undef,
                'separator'             => undef,
                'session'               => undef,
                'sigil'                 => undef,
                'sound'                 => undef,
                'ssh'                   => undef,
                'ssl'                   => undef,
                'standard'              => undef,
                'strip'                 => undef,
                'sub'                   => undef,
                'tab'                   => undef,
                'table'                 => undef,
                'tablezone'             => undef,
                'task'                  => undef,
                'tasks'                 => undef,
                'telnet'                => undef,
                'template'              => undef,
                'text'                  => undef,
                'textview'              => undef,
                'timer'                 => undef,
                'toolbar'               => undef,
                'tooltip'               => undef,
                'trigger'               => undef,
                'tts'                   => undef,
                'usercomm'              => undef,
                'viewer'                => undef,
                'window'                => undef,
                'winmap'                => undef,
                'winmaps'               => undef,
                'winzone'               => undef,
                'workspace'             => undef,
                'worlddefn'             => undef,
                'worldprof'             => undef,
                'worldmodel'            => undef,
                'zone'                  => undef,
                'zonemap'               => undef,
                'zonemaps'              => undef,
                # Telnet options and MUD protocols
                'echo'                  => undef,
                'sga'                   => undef,
                'ttype'                 => undef,
                'eor'                   => undef,
                'naws'                  => undef,
                'newenviron'            => undef,
                'charset'               => undef,
                'mccp'                  => undef,
                'msdp'                  => undef,
                'mssp'                  => undef,
                'mccp'                  => undef,
                'msp'                   => undef,
                'mxp'                   => undef,
                'pueblo'                => undef,
                'zmp'                   => undef,
                'aard102'               => undef,
                'atcp'                  => undef,
                'gmcp'                  => undef,
                'mtts'                  => undef,
                'mcp'                   => undef,
            },

            # File objects
            # ------------

            # Flags to allow/forbid loading/saving of data
            # Should loading/saving of the 'config' file for the client be allowed?
            loadConfigFlag              => TRUE,        # Saved in file [config]
            saveConfigFlag              => TRUE,        # [config]
            # Should loading/saving of other data files be allowed?
            loadDataFlag                => TRUE,        # [config]
            saveDataFlag                => TRUE,        # [config]
            # Flag set to TRUE if, when the script starts, the existing 'config' file and the
            #   entire contents of the /log and /data directories should be deleted; FALSE if they
            #   should not be deleted
            # (The flag can be set to TRUE while developing Axmud code; should be set to FALSE for
            #   any public releases)
            deleteFilesAtStartFlag      => FALSE,
            # Flag set to TRUE whenever any file operation (launched from the client commands
            #   ';load', ';save', ';importfiles', ';exportfiles', ';importdata', ';exportdata')
            #   fails, wholly or partially. Any code can set this flag to FALSE (with a call to
            #   $self->set_fileFailFlag) before initiating the file operation, in order to test its
            #   success
            fileFailFlag                => FALSE,
            #
            # Emergency saves - when a file save operation fails and this flag is TRUE, user can be
            #   prompted to save a copy of all data files in a new location (a USB drive, perhaps),
            #   so that data in memory is not lost permanently. If this flag is FALSE, the user is
            #   not prompted
            # NB Even if this flag is FALSE, the user can still do an emergency save using the
            #   ';emergencysave' client command
            # NB The only reason to set this flag to FALSE is for testing and development, when you
            #   don't want to be prompted all the time. For that reason, there are no client
            #   command and no preference window options for setting the flag
            emergencySaveFlag           => TRUE,
            #
            # Auto-save. Flag set to TRUE if auto-save is turned on, FALSE if not
            autoSaveFlag                => TRUE,       # [config]
            # When auto-save is turned on, the number of minutes between saves. (Each GA::Session
            #   has an ->autoSaveCheckTime IV, the time at which to do the next auto-save). Min
            #   value 1 minute; values must be integers
            autoSaveWaitTime            => 5,           # [config]
            # When a file is saved, a temporary copy of an existing file with the same name is
            #   created. If this flag is set to TRUE, the temporary file is not deleted as soon as
            #   the 'save' operation is completed; in that case, if the saved file is corrupted, the
            #   user can manually restore the previous version. If this flag is set to FALSE, the
            #   backup is destroyed as soon as the save process is complete.
            autoRetainFileFlag          => TRUE,        # [config]
            #
            # Auto-backup (a process which creates a .tgz or .zip of the entire Axmud data
            #   directory)
            # Auto-backup mode: 'no_backup' (don't do auto-backups'), 'all_start' (do an auto-backup
            #   whenever Axmud starts), 'all_stop' (do an auto-backup whenever Axmud stops),
            #   'interval_start' (do an auto-backup at regular intervals, performed when Axmud
            #   first starts after the interval has passed), 'interval_stop' (do an auto backup at
            #   regular intervals, when Axmud stops)
            autoBackupMode              => 'no_backup', # [config]
            # The directory in which the backup is saved. If 'undef' or an empty string, the user
            #   is prompted for a directory each time
            autoBackupDir               => undef,       # [config]
            # For auto-backup mode 'interval_start' and 'interval_stop', the number of days between
            #   successive backups. 1 means do daily backups, 8 means do weekly backups, 366 means
            #   backup once a year. 0 means stop doing backups temporarily (but remember when the
            #   last backup occured, so when the interval is change back to a positive integer, that
            #   interval is applied to the time since the last backup). Range 0-366
            autoBackupInterval          => 8,           # [config]
            # The time of the last successful auto-backup, set a string returned by $self->localDate
            #   (in the form 'Thu Dec 18, 2010'). 'undef' or an empty string if no auto-backup has
            #   ever been performed, or if auto-backup mode is currently 'no_backup', 'all_start' or
            #   'all_stop'. The value is not modified if the user performs a manual backup using the
            #   ';backupdata' command
            autoBackupDate              => undef,           # [config]
            # Auto-backup file type: 'tar' to use a .tgz file, 'zip' to use a .zip file, 'default'
            #   to use a convenient file type for the system (.tgz for Linux/*BSD, .zip for MS
            #   Windows)
            autoBackupFileType          => 'default',   # [config]
            # Flag set to TRUE if the time should be appended to auto-backups and to manual backups
            #   using the ';backupdata' command
            autoBackupAppendFlag        => FALSE,       # [config]
            #
            # Axmud retains information about the config and data files it has loaded/saved since
            #   the script started. Each file that can be loaded or saved is handled by a
            #   GA::Obj::File
            # There are eleven types of file object. Each file object has a name that is the same as
            #   its type (except for 'worldprof' file objects, whose name is the same as the world
            #   profile to which it corresponds)
            # The types of data files Axmud uses are:
            #   File type    Standard directory                              Unique name     Stored
            #   'config'     <SCRIPT_DIR>/axmud.conf                         config          Client
            #   'worldprof'  <SCRIPT_DIR>/data/worlds/<WORLD>/worldprof.axm  WORLD           Both
            #   'otherprof'  <SCRIPT_DIR>/data/worlds/<WORLD>/otherprof.axm  otherprof       Session
            #   'worldmodel' <SCRIPT_DIR>/data/worlds/<WORLD>/worldmodel.axm worldmodel      Session
            #   'tasks'      <SCRIPT_DIR>/data/tasks.axm                     tasks           Client
            #   'scripts'    <SCRIPT_DIR>/data/scripts.axm                   scripts         Client
            #   'contacts'   <SCRIPT_DIR>/data/contacts.axm                  contacts        Client
            #   'dicts'      <SCRIPT_DIR>/data/dicts.axm                     dicts           Client
            #   'toolbar'    <SCRIPT_DIR>/data/toolbar.axm                   toolbar         Client
            #   'usercmds'   <SCRIPT_DIR>/data/usercmds.axm                  usercmds        Client
            #   'zonemaps'   <SCRIPT_DIR>/data/zonemaps.axm                  zonemaps        Client
            #   'winmaps'    <SCRIPT_DIR>/data/winmaps.axm                   winmaps         Client
            #   'tts'        <SCRIPT_DIR>/data/tts.axm                       tts             Client
            # (WORLD is replaced by the name of the associated world profile)
            #
            # This GA::Client has a registry of file objects; each GA::Session also has its own one
            # The only overlap is for 'worldprof' files. The GA::Client stores all 'worldprof' file
            #   objects; the GA::Session stores only the 'worldprof' file object for its current
            #   world profile (if any)
            # In GA::Client's registry, there are any number of 'worldprof' file objects, but only
            #   one instance of the other types of file object. In GA::Session's registry, there is
            #   one 'worldprof' file object, any number of 'otherprof' file objects, and one
            #   'worldmodel file object
            #
            # NB Every file object has a ->modifyFlag which is set to TRUE whenever its data in
            #   memory has changed, which means the file needs to be saved. The flag is set back to
            #   FALSE when the file is saved (or loaded, overwritng the data in memory)
            # It's possible to call the GA::Obj::File->set_modifyFlag method directly, but the
            #   easier way to do it, is to call GA::Client->setModifyFlag() - for file objects
            #   stored here - or GA::Session->setModifyFlag() - for file objects stored in the
            #   session's file object registry
            #
            # Registry hash of file objects, in the form
            #   $fileObjHash{unique_name} = blessed_reference_to_file_object
            fileObjHash                 => {},
            # A shortcut to the blessed reference of the 'config' file object (very useful for all
            #   the parts of the code that need to set the file object's ->modifyFlag)
            configFileObj               => undef,
            # Every time the 'config' file is loaded, the list of world profiles it contains is
            #   copied into this list (empty if the 'config' file doesn't list any world
            #   profile). This list will become obsolete as soon as profiles are created/destroyed/
            #   loaded, so it shouldn't be used for any other purpose
            configWorldProfList         => [],

            # GA::Session->setupProfiles can optionally create a 'Loading...' popup window by
            #   calling GA::Generic::Win->showBusyWin, if the file(s) it's loading are above a
            #   certain size. It's up to the calling function to close the popup window when all
            #   load operations are complete
            # The standard file size above which a 'Loading...' popup can be shown, if some part of
            #   the Axmud code wants it
            constLargeFileSize          => 5_000_000,   # (roughly 5MB)

            # Large world models can cause 'out of memory' errors on low-spec machines. The
            #   problem is not that the world model takes up too much memory, but that the Perl
            #   Storable module struggles to load very large files into memory
            # Since v1.1.529, the world model is saved either as a monolithic file (as previously),
            #   or as multiple files, all of which are handled by a single file object
            # Flag set to TRUE if we should allow large world models to be saved as multiple files,
            #   FALSE if world models should always be saved as a single monolithic file
            allowModelSplitFlag         => TRUE,        # [config]
            # If multiple files are allowed, this value sets the maximum size of the world model
            #   for which a monolithic file is still used. It also sets the size of multiple files,
            #   when they are used. The value corresponds to a number of model objects (regions,
            #   rooms etc) or exit model objects
            # The constant (default) value
            constModelSplitSize         => 5000,
            # The value actually used (must be an integer, minimum value is 1000)
            modelSplitSize              => 5000,

            # Plugins
            # -------

            # Registry list of plugins (.pm files) that should be loaded as plugins at startup. Each
            #   item in the list is the full file path
            initPluginList              => [],          # [config]
            # Registry hash of plugins (.pm files) that have been loaded, in the form
            #   $pluginHash{plugin_name} = blessed_reference_to_plugin_object
            pluginHash                  => {},
            # Registry hash of client commands that are created when a plugin is loaded, in the form
            #   $pluginCmdHash{command_name} = plugin_name
            # ...where 'command_name' matches a key in $self->clientCmdHash (e.g. 'about') and
            #   'plugin_name' matches a key in $self->pluginHash
            # NB If a (built-in) client command of the same name already exists, it is replaced. If
            #   the plugin is later disabled, the original command is restored. If the plugin is
            #   then re-enabled, the original command is again replaced, and so on. This works very
            #   well as long as the plugins you load don't themselves have client commands of the
            #   same name, so try to avoid that
            pluginCmdHash               => {},
            # Registry hash of tasks that are added when a plugin is loaded, in the form
            #   $pluginTaskHash{task_name} = plugin_name
            # ...where 'task_name' matches the task's standard name (a key in
            #   $self->taskPackageHash) and 'plugin_name' matches a key in $self->pluginHash
            # NB Tasks with the same name as existing tasks (built-in, or from a plugin that's
            #   already been loaded) will not be added
            pluginTaskHash              => {},
            # Registry hash of 'grid' windows added by the plugin. If the plugin is disabled, the
            #   windows are closed (and, for 'main' windows, all sessions in the 'main' windows are
            #   terminated). Hash in the form
            #   $pluginGridWinHash{package_name} = plugin_name
            pluginGridWinHash           => {},
            # Registry hash of 'free' windows added by the plugin (not including 'dialogue'
            #   windows). If the plugin is disabled, the windows are closed. Hash in the form
            #   $pluginFreeWinHash{package_name} = plugin_name
            pluginFreeWinHash           => {},
            # Registry hash of strip objects added by the plugin. Strip objects are always
            #   available, even if their parent plugin is disabled. Hash in the form
            #   $pluginStripObjHash{package_name} = plugin_name
            pluginStripObjHash          => {},
            # Registry hash of table objects added by the plugin. Table objects are always
            #   available, even if their parent plugin is disabled. Hash in the form
            #   $pluginTableObjHash{package_name} = plugin_name
            pluginTableObjHash          => {},
            # Registry hash of cages that are added when a plugin is loaded, in the form
            #   $pluginCageHash{cage_name} = plugin_name
            # ...where 'cage_name' matches the cage's name (an item in $self->cageTypeList) and
            #   'plugin_name' matches a key in $self->pluginHash
            pluginCageHash              => {},
            # For cages that have been added by a plugin, a registry hash of package names in the
            #   form
            #   $pluginCagePackageHash{cage_name} = cage_package
            # ...where 'cage_name' is an item in $self->cageTypeList, and 'cage_package' is the
            #   package name of the Perl object
            pluginCagePackageHash       => {},
            # For cages that have been added by a plugin, a registry hash of 'edit' windows added by
            #   the plugin (where available)
            # Hash in the form
            #   $pluginCageEditWinHash{cage_name} = config_window_package_name
            # NB If no 'edit' window exists for a particular cage, 'edit_window_package_name' will
            #   be 'undef'
            pluginCageEditWinHash       => {},
            # Registry hash of functions to call every time a menu strip object (GA::Strip::MenuBar)
            #   creates a menu in an 'internal' window, in order to add menu menu items for the
            #   plugin. Hash in the form
            #   $pluginMenuFuncHash{plugin_name} = func_ref
            #   ...where 'func_ref' is a reference to a function within a plugin that creates menu
            #   items, when passed an existing Gtk3::Menu widget
            pluginMenuFuncHash          => {},
            # For MXP file filters that must be passed to a plugin, a registry hash of the plugin
            #   functions to call when the filter is applied to a file. Hash in the form
            #   $pluginMxpFilterHash{package_name} = reference_to_function
            pluginMxpFilterHash         => {},

            # System loops
            # ------------

            # The client time (used by various parts of the code that need a time that stays
            #   consistent for some measured period, but which is updated frequently). Set by
            #   $self->spinClientLoop, whenever the client loop spins, to the same value stored as
            #   $self->clientLoopObj->spinTime
            # (See also the corresponding session IV, GA::Session->sessionTime)
            clientTime                  => 0,
            # Each session has a session loop, also called by a Glib timer. If a Perl error is
            #   generated, the code in axmud.pl this flag to TRUE, which suspends the client loop
            #   and
            #   all session loops until the user lifts the suspension with the ';restart' command
            suspendSessionLoopFlag      => FALSE,

            # Client loop
            # -----------

            # The GA::Obj::Loop which handles the client loop
            clientLoopObj               => undef,
            # Flag set to TRUE (by GA::Obj::Loop->spinLoop) when the client loop spins, set back to
            #   FALSE when the spin is complete. The TRUE setting prevents one client loop spin from
            #   taking place if another is still being processed
            clientLoopSpinFlag          => FALSE,
            # The client loop default delay, in seconds (never changes once set; absolute minimum
            #   value is 0.01)
            clientLoopDelay             => 0.1,

            # File objects
            # When there are no file objects in GA::Client->fileObjHash whose ->modifyFlag is set to
            #   TRUE (meaning that none of them need to be saved), this flag is set to FALSE
            # When the first file object has its ->modifyFlag set to TRUE, this flag is set to TRUE
            # When the flag changes, $self->checkMainWinTitles changes the title of all 'main'
            #   windows together, with an asterisk if the flag is TRUE, and no asterisk if the flag
            #   is FALSE
            showModFlag                 => FALSE,

            # 'internal' window blinkers (not to be confused with blinking text in textviews)
            # Blinkers in GA::Strip::ConnectInfo objects (in 'internal' windows) are handled by the
            #   client loop. Each session has its own ->blinkerStateHash, which specifies the
            #   current state of each blinker when that session is the window's visible session
            #   ('off' or 'on' for some specified time)
            # This IV specifies the blinker delay - how many seconds until the blinker, having been
            #   turned on, should be turned off
            blinkerDelay                => 0.25,

            # Blinking text in textviews (not to be confused with 'internal' window blinkers)
            # The time per blink for 'blink_slow' text, in seconds
            blinkSlowTime               => 1,       # 60 blinks per minute
            # The time (matches $self->clientTime) at which the 'blink_slow' text should next appear
            #   or disappear (one blink = one appearance and disappearance)
            blinkSlowCheckTime          => undef,
            # Flag set to TRUE when 'blink_slow' text is visible, FALSE when 'blink_slow' text is
            #   invisible
            blinkSlowFlag               => undef,
            # The time per blink for 'blink_fast' text, in seconds
            blinkFastTime               => 0.4,     # 150 blinks per minute
            # The time (matches $self->clientTime) at which the 'blink_slow' text should next appear
            #   or disappear (one blink = one appearance and disappearance)
            blinkFastCheckTime          => undef,
            # Flag set to TRUE when 'blink_fast' text is visible, FALSE when 'blink_fast' text is
            #   invisible
            blinkFastFlag               => undef,

            # In 'internal' windows, the strip object GA::Strip::Entry includes a switcher button to
            #   switch between pane objects (GA::Table::Pane); the scroll lock/split screen buttons
            #   then apply to the selected pane object
            # When a pane object is selected, its border size is briefly increased by a call to
            #   $self->modifyPane, then restored to normal by a call to $self->restorePane after a
            #   short period
            # The period to wait (in seconds) before restoring a border to its normal size
            paneDelay                   => 0.5,
            # Pane object numbers are not unique to the client, so in this hash we take the unusual
            #   step of using a system time as a key, matching the time at which the border size
            #   should be restored. Hash in the form
            #   $paneRestoreHash{system_time} = pane_object
            paneRestoreHash             => {},

            # When system messages are written but there's no session open in which they can be
            #   displayed, they are written to the terminal, and also stored here. Then, the next
            #   time the Client Console window is open, they are displayed there
            # (If the Client Console window is already open, the system message is displayed there
            #   immediately and is not added to this list)
            # List in groups of 2, in the form (type, message), where 'type' is the type of system
            #   message: 'system', 'error', 'warning', 'debug' or 'improper'
            systemMsgList               => [],

            # Sessions
            # --------

            # Registry hash of GA::Session objects
            # Each connection to a world has its own session. Sessions can also be created for
            #   simulated connections in 'connect offline' mode
            # If $self->shareMainWinFlag TRUE, each session corresponds to a tab in a single 'main'
            #   window. If $self->shareMainWinFlag is FALSE, each session has its own 'main' window
            # Hash in the form
            #   $sessionHash{unique_number} = blessed_reference_to_session_object
            sessionHash                 => {},
            # Number of session objects ever created (used to give each session object a unique
            #   number)
            sessionCount                => 0,
            # The absolute maximum number of sessions allowed - to prevent a possible infinite loop
            #   of new sessions
            constSessionMax             => 1024,
            # The current number of sessions allowed (ignored when $axmud::BLIND_MODE_FLAG is TRUE,
            #   when only one session is allowed)
            sessionMax                  => 16,          # [config]
            # The current session is set whenever a session's default tab becomes the visible tab in
            #   a 'main' window, and is set back to 'undef' when there are no sessions running
            # Set/reset by $self->setCurrentSession
            currentSession              => undef,
            # Flag set to TRUE when Axmud should be shut down. The END() function in axmud.pl checks
            #   this flag and, if it's still set to FALSE, calls GA::Client->stop() before
            #   terminating the script. If it's set to TRUE, GA::Client->stop() has already been
            #   called, and we don't need to call it again
            shutdownFlag                => FALSE,
            # Flag set to TRUE when $self->stop is first called, to prevent multiple concurrent
            #   calls to that function
            terminatingFlag             => FALSE,
            # Flag that determines how a session deals with a disconnection from a world (i.e. when
            #   its ->status is 'connected'). FALSE if it should switch to 'disconnected' mode, TRUE
            #   if it should switch to 'offline' mode (as if the user had clicked the 'Connect
            #   offline' button in the Connections window)
            offlineOnDisconnectFlag     => FALSE,       # [config]

            # The way in which text on each session's tab label (if it's visible) is displayed:
            #   'bracket'   - displayed as 'deathmud (Gandalf)'
            #   'hyphen'    - 'deathmud - Gandalf'
            #   'world'     - 'deathmud'
            #   'char'      - 'gandalf'
            # NB If $self->xTermTitleFlag is TRUE and an xterm title is received, that title is
            #   displayed instead
            # NB If $self->longTitleFlag is TRUE, the world's long name (rather than the world's
            #   profile name) is used
            sessionTabMode              => 'bracket',   # [config]
            # Flag set to TRUE if xterm titles (in the form ESC]0;stringBEL ) should be displayed
            #   in a 'main' window tab's title (if the tab is visible) when they are received from
            #   the world; set to FALSE if the normal text (specified by
            #   GA::Session->checkTabLabels) should be displayed there (if the tab is visible)
            # NB If set to TRUE, the normal text is displayed until the first xterm title is
            #   received
            xTermTitleFlag              => TRUE,        # [config]
            # Flag set to TRUE if the tab label (if it's visible) should use the world's long name,
            #   FALSE if the tab label should use the profile name
            longTabLabelFlag            => TRUE,        # [config]
            # Flag set to TRUE if a so-called 'simple tab' (a standalone Gtk3::TextView, rather than
            #   a tab in a Gtk3::Notebook) should be displayed when only a single session is open
            #   in a 'main' window (it's replaced with a Gtk3::Notebook when a second session is
            #   opened in the same 'main' window)
            # Flag set to FALSE if a Gtk3::Notebook should always be used
            # NB This IV only applies to pane objects used for sessions' default tabs
            simpleTabFlag               => FALSE,       # [config]
            # Flag set to TRUE if the user should be prompted for a confirmation if they try to
            #   close a 'main' window by clicking on its 'X' widget, and any of the sessions using
            #   the window are connected to a world
            confirmCloseMainWinFlag     => TRUE,        # [config]
            # Flag set to TRUE if the user should be prompted for a confirmation if they try to
            #   close a tab by clicking on its 'X' widget, and the session is connected to a world
            confirmCloseTabFlag         => TRUE,        # [config]

            # The default character set to use. Must be one of the character sets available with the
            #   Perl Encode module
            constCharSet                => 'iso-8859-1',
            # The current character set. For each individual session, if the current world's
            #   ->worldCharSet IV is set, that character set is used instead
            charSet                     => undef,       # [config] Set below
            # Ordered list of available character sets (from the Perl 'encode' module)
            charSetList                 => [],          # Set below

            # Flag set to TRUE if details about every connection to a world should be stored in the
            #   world profile, FALSE if not
            connectHistoryFlag          => TRUE,        # [config]

            # Client commands
            # ---------------

            # All client command objects are stored in the following hash. Each command object
            #   inherits from GA::Generic::Cmd
            # (Actually, there are two types of client command: 'built-in' commands which exist in
            #   every copy of Axmud, and commands loaded from plugins which Axmud treats in almost
            #   exactly the same way. If plugin client commands have the same name as built-in
            #   client commands, then the built-in command is not available for as long as the
            #   plugin is enabled)
            #
            # Registry hash of client command objects, in the form
            #   $clientCmdHash{command_name} = blessed_reference_to_command_object
            #       e.g. $clientCmdHash{'about'} = blessed_reference_to_command_object
            clientCmdHash               => {},
            # When a plugin adds a command with same 'command_name' as an existing client
            #   command, the existing command is moved out of ->clientCmdHash and into this hash.
            #   Later, if the plugin is disabled, the original command is moved back into
            #   ->clientCmdHash, and the plugin command is moved into this hash - and so on,
            #   ad infinitum
            replaceClientCmdHash        => {},
            # A constant list of built-in client commands, grouped thematically and in a pre-defined
            #   order. Elements beginning with the @ character are group headings; everything else
            #   is a built-in client command
            constClientCmdPrettyList    => [
                '@Debug commands',
                    'Test', 'HelpTest', 'DumpAscii', 'TestColour', 'TestXTerm', 'TestFile',
                        'TestModel', 'TestPattern',
                    'QuickInput',
                    'SimulateWorld', 'SimulatePrompt', 'SimulateCommand', 'SimulateHook',
                    'DebugToggle', 'DebugConnection', 'Restart', 'Peek', 'Poke', 'PeekHelp',
                '@Client commands',
                    'Help', 'Hint', 'QuickHelp', 'SearchHelp', 'ListReserved',
                    'About', 'OpenAboutWindow', 'CloseAboutWindow',
                    'EditQuick', 'EditClient', 'EditSession',
                    'SwitchSession', 'MaxSession', 'ListSession', 'SetSession',
                    'Connect', 'Reconnect', 'XConnect', 'Telnet', 'SSH', 'SSL',
                    'Login',
                    'Quit', 'Qquit', 'QuitAll', 'Exit', 'Xxit', 'ExitAll',
                        'AbortSelfDestruct', 'StopSession', 'StopClient', 'Panic',
                    'AwayFromKeys', 'SetReminder', 'SetCountdown', 'SetCountup',
                    'SetCharSet',
                    'SetCustomMonth', 'SetCustomWeek', 'SetCommifyMode',
                    'SetApplication', 'ResetApplication', 'SetPromptDelay',
                    'Repeat', 'IntervalRepeat', 'StopCommand',
                    'RedirectMode', 'SetRedirectMode',
                    'ToggleInstruction', 'ToggleSigil', 'CommandSeparator',
                    'Echo', 'Perl', 'Multi', 'SpeedWalk', 'SlowWalk', 'Crawl', 'Bypass',
                    'AddUserCommand', 'DeleteUserCommand', 'ListUserCommand', 'ResetUserCommand',
                    'DisplayBuffer', 'SetDisplayBuffer', 'EditDisplayBuffer', 'DumpDisplayBuffer',
                    'InstructionBuffer', 'SetInstructionBuffer', 'EditInstructionBuffer',
                        'DumpInstructionBuffer',
                    'CommandBuffer', 'SetCommandBuffer', 'EditCommandBuffer', 'DumpCommandBuffer',
                    'SaveBuffer', 'LoadBuffer', 'ReplayBuffer', 'HaltReplay', 'SetAutoComplete',
                        'ToggleWindowKey', 'ToggleMainWindow', 'ToggleLabel', 'ToggleIrreversible',
                        'TogglePopup', 'ToggleShortLink',
                    'ShowFile', 'DisableSaveLoad', 'DisableSaveWorld', 'Save', 'Load',
                        'AutoSave', 'EmergencySave',
                    'ExportFiles', 'ImportFiles', 'ExportData', 'ImportData',
                    'RetainFileCopy',
                    'ListDataDirectory', 'SetDataDirectory', 'BackupData', 'RestoreData',
                        'AutoBackup',
                    'ImportPlugin', 'LoadPlugin', 'EnablePlugin', 'DisablePlugin', 'TestPlugin',
                        'ListPlugin',
                    'AddInitialPlugin', 'DeleteInitialPlugin', 'ListInitialPlugin',
                    'SetTelnetOption', 'SetMUDProtocol', 'SetTermType', 'ConfigureTerminal',
                    'MSDP', 'MSSP', 'MXP', 'MSP', 'ZMP', 'SendZMP', 'InputZMP', 'Aardwolf', 'ATCP',
                        'SendATCP', 'GMCP', 'SendGMCP', 'MCP',
                    'Log',
                '@Sound and text-to-speech',
                    'Sound', 'ASCIIBell',
                    'AddSoundEffect', 'PlaySoundEffect', 'QuickSoundEffect', 'Beep',
                        'DeleteSoundEffect', 'ResetSoundEffect', 'ListSoundEffect',
                    'Speech', 'Speak', 'Read', 'PermRead', 'Switch', 'PermSwitch', 'Alert',
                        'PermAlert', 'ListAttribute', 'AddConfig', 'CloneConfig', 'EditConfig',
                        'ModifyConfig', 'DeleteConfig', 'ListConfig',
                '@Other windows',
                    'OpenObjectViewer', 'CloseObjectViewer',
                    'OpenAutomapper', 'CloseAutomapper', 'ToggleAutomapper',
                    'LocatorWizard',
                '@Dictionaries',
                    'AddDictionary', 'SetDictionary', 'CloneDictionary', 'EditDictionary',
                        'DeleteDictionary', 'ListDictionary', 'SetLanguage', 'SwitchLanguage',
                    'AddWord', 'QuickAddWord', 'DeleteWord', 'ListWord',
                    'ModifyPrimary', 'AddSecondary', 'ModifySecondary', 'DeleteSecondary',
                        'AddRelative', 'DeleteRelative', 'ListDirection',
                    'SetAutoSecondary', 'ListAutoSecondary',
                    'AddSpeedWalk', 'DeleteSpeedWalk', 'ListSpeedWalk',
                    'AddModifierChar', 'DeleteModifierChar', 'ListModifierChar',
                '@Profiles - general',
                    'ListProfile',
                    'SetProfilePriority', 'ListProfilePriority',
                    'AddTemplate', 'CloneTemplate', 'EditTemplate', 'DeleteTemplate',
                        'ListTemplate', 'AddScalarProperty', 'AddListProperty', 'AddHashProperty',
                        'DeleteProperty', 'ListProperty',
                '@Profiles - world profiles',
                    'AddWorld', 'SetWorld', 'CloneWorld', 'EditWorld', 'DeleteWorld', 'ListWorld',
                        'SetFavouriteWorld', 'ListFavouriteWorld', 'SetAutoWorld', 'ListAutoWorld',
                        'RestoreWorld', 'ListRestoreWorld', 'UpdateWorld', 'ListBasicWorld',
                    'ToggleHistory', 'ClearHistory', 'ShowHistory',
                '@Profiles - other profiles',
                    'AddGuild', 'SetGuild', 'UnsetGuild', 'CloneGuild', 'EditGuild', 'DeleteGuild',
                        'ListGuild',
                    'AddRace', 'SetRace', 'UnsetRace', 'CloneRace', 'EditRace', 'DeleteRace',
                        'ListRace',
                    'AddChar', 'SetChar', 'UnsetChar', 'CloneChar', 'EditChar', 'DeleteChar',
                        'ListChar',
                '@Profiles - custom profiles',
                    'AddCustomProfile', 'SetCustomProfile', 'UnsetCustomProfile',
                        'CloneCustomProfile', 'EditCustomProfile', 'DeleteCustomProfile',
                        'ListCustomProfile',
                '@Cages',
                    'EditCage', 'DeleteCage', 'ListCage', 'SetCageMask', 'EditCageMask',
                '@Interfaces',
                    'EnableActiveInterface', 'DisableActiveInterface', 'MoveActiveInterface',
                        'EditActiveInterface', 'ListActiveInterface',
                    'EditInterfaceModel', 'ListInterfaceModel',
                    'AddTrigger', 'ModifyTrigger', 'DeleteTrigger', 'ListTrigger',
                    'AddAlias', 'ModifyAlias', 'DeleteAlias', 'ListAlias',
                    'AddMacro', 'ModifyMacro', 'DeleteMacro', 'ListMacro',
                    'AddTimer', 'ModifyTimer', 'DeleteTimer', 'ListTimer',
                    'AddHook', 'ModifyHook', 'DeleteHook', 'ListHook',
                '@Keycodes',
                    'ListKeycode', 'ListKeycodeAlternative',
                '@Task package names',
                    'AddTaskPackage', 'DeleteTaskPackage', 'ResetTaskPackage', 'ListTaskPackage',
                '@Task labels',
                    'AddTaskLabel', 'DeleteTaskLabel', 'ResetTaskLabel', 'ListTaskLabel',
                '@Current tasks',
                    'TaskHelp', 'StartTask', 'HaltTask', 'KillTask', 'PauseTask', 'ResumeTask',
                        'ResetTask', 'FreezeTask', 'EditTask', 'ListTask', 'SetRunList',
                '@Initial tasks',
                    'AddInitialTask', 'EditInitialTask', 'DeleteInitialTask', 'ListInitialTask',
                '@Custom tasks',
                    'AddCustomTask', 'EditCustomTask', 'DeleteCustomTask', 'ListCustomTask',
                        'StartCustomTask',
                '@Initial scripts',
                    'AddInitialScript', 'DeleteInitialScript', 'ListInitialScript',
                '@Axbasic commands',
                    'EditScript', 'CheckScript', 'RunScript', 'RunScriptTask', 'AxbasicHelp',
                    'AddDirectory', 'DeleteDirectory', 'ListDirectory',
                '@Workspaces',
                    'UseWorkspace', 'EditWorkspace', 'RemoveWorkspace', 'ListWorkspace',
                        'SetWorkspaceDirection',
                    'AddInitialWorkspace', 'ModifyInitialWorkspace', 'DeleteInitialWorkspace',
                        'ListInitialWorkspace',
                    'SetWindowSize',
                    'TestWindowControls', 'SetWindowControls', 'ListWindowControls',
                        'TestPanel', 'SetPanel', 'ListPanel',
                '@Workspace grids',
                    'ActivateGrid', 'DisactivateGrid', 'SetGrid', 'ResetGrid', 'EditGrid',
                        'ListGrid',
                    'SetLayer', 'LayerUp', 'LayerDown',
                    'ToggleWindowStorage', 'ApplyWindowStorage', 'ClearWindowStorage',
                        'DumpWindowStorage',
                '@Winmaps and winzones',
                    'AddWinmap', 'CloneWinmap', 'EditWinmap', 'ModifyWinmap', 'DeleteWinmap',
                        'ResetWinmap', 'SetDefaultWinmap', 'ListWinmap',
                    'AddWinzone', 'EditWinzone', 'ModifyWinzone', 'DeleteWinzone', 'ListWinzone',
                '@Zonemaps and zone models',
                    'AddZonemap', 'CloneZonemap', 'EditZonemap', 'DeleteZonemap', 'ResetZonemap',
                        'ListZonemap',
                    'AddZoneModel', 'EditZoneModel', 'ModifyZoneModel', 'DeleteZoneModel',
                        'ListZoneModel',
                '@\'Grid\' windows',
                    'ToggleShare', 'SwapWindow', 'MoveWindow', 'RestoreWindow', 'GrabWindow',
                        'BanishWindow', 'FixWindow', 'FlashWindow', 'UnflashWindow', 'CloseWindow',
                        'EditWindow', 'ListWindow',
                '@\'Internal\' windows',
                    'EditWindowStrip', 'ListWindowStrip', 'EditWindowTable', 'ListWindowTable',
                    'OpenTaskWindow', 'CloseTaskWindow',
                    'EditToolbar', 'ListToolbar',
                '@\'Free\' windows',
                    'EditFreeWindow', 'CloseFreeWindow', 'ListFreeWindow',
                '@Textviews',
                    'ScrollLock', 'SplitScreen', 'ClearTextView', 'SetTextView', 'ListTextView',
                        'FindText', 'FindReset', 'ConvertText',
                    'SetColour', 'ListColour',
                    'SetSystemColour', 'ListSystemColour',
                    'SetXTerm', 'TogglePalette',
                    'AddColourScheme', 'EditColourScheme', 'ModifyColourScheme',
                        'UpdateColourScheme', 'ApplyColourScheme', 'DeleteColourScheme',
                        'ListColourScheme',
                '@Recordings, missions, quests and routes',
                    'Record', 'PauseRecording', 'WorldCommand', 'ClientCommand', 'SpeedWalkCommand',
                        'Comment', 'Break',
                    'InsertRecording', 'DeleteRecording', 'ListRecording', 'CopyRecording',
                    'StartMission', 'Mission', 'NudgeMission', 'HaltMission',
                    'RepeatComment', 'RepeatMission',
                    'AddMission', 'CloneMission', 'EditMission', 'DeleteMission', 'ListMission',
                        'PresentMission',
                    'AddQuest', 'CloneQuest', 'EditQuest', 'ModifyQuest', 'FinishQuest',
                        'DeleteQuest', 'ListQuest',
                    'AddRoute', 'EditRoute', 'DeleteRoute', 'ListRoute',
                    'Go', 'Drive', 'Road', 'Quick', 'Circuit',
                '@Advance task',
                    'ResetGuildSkills', 'ListGuildSkills', 'Advance', 'SkipAdvance', 'ListAdvance',
                        'ListAdvanceHistory',
                '@Attack task',
                    'Kill', 'KKill', 'KillAll', 'KillMall', 'Interact', 'IInteract', 'InteractAll',
                        'InteractMall',
                '@Channels and Divert tasks',
                    'AddChannelPattern', 'DeleteChannelPattern', 'ListChannelPattern',
                        'EmptyChannelsWindow', 'EmptyDivertWindow',
                '@Chat task',
                    'GetIP', 'ChatListen', 'ChatIgnore', 'AddContact', 'EditContact',
                        'DeleteContact', 'ListContact',
                    'ChatCall', 'ChatMCall', 'ChatZCall', 'Chat', 'Emote', 'ChatGroup',
                        'EmoteGroup', 'ChatAll', 'EmoteAll', 'ChatPing', 'ChatDND',  'ChatSubmit',
                        'ChatEscape', 'ChatCommand', 'ChatSendFile', 'ChatStopFile', 'ChatSnoop',
                        'ChatHangUp', 'ChatPeek', 'ChatRequest', 'ChatInfo', 'ChatSet',
                        'ChatSetName', 'ChatSetGroup', 'ChatSetEmail', 'ChatSetSmiley',
                        'ChatSetIcon',
                    'AddSmiley', 'DeleteSmiley', 'ListSmiley', 'ResetSmiley',
                '@Compass task',
                    'Compass', 'PermCompass', 'WorldCompass',
                '@Inventory / Condition tasks',
                    'ActivateInventory', 'DisactivateInventory',
                    'ProtectObject', 'UnprotectObject', 'ListProtectObject',
                    'MonitorObject', 'UnmonitorObject', 'ListMonitorObject',
                    'SellAll', 'DropAll', 'UseAll',
                '@Locator task',
                    'MoveDirection', 'RelayDirection', 'Teleport', 'AddTeleport', 'DeleteTeleport',
                        'ListTeleport', 'InsertLook', 'InsertFailedExit', 'ResetLocatorTask',
                        'SetFacing',
                    'AddExitPattern', 'DeleteExitPattern', 'ListExitPattern',
                    'CollectUnknownWords', 'EmptyUnknownWords', 'ListUnknownWords',
                    'CollectContentsLines', 'EmptyContentsLines', 'ListContentsLines',
                '@Status task',
                    'ActivateStatusTask', 'DisactivateStatusTask', 'ResetCounter',
                        'AddStatusCommand', 'DeleteStatusCommand', 'ListStatusCommand', 'SetWimpy',
                        'SetLife', 'SetStatusEvent', 'ShowStatusGauge',
                '@System task',
                    'SetSystemMode',
                '@Watch task',
                    'EmptyWatchWindow',
                '@World model commands',
                    'AddRegion', 'AddRoom', 'AddModelObject', 'SetModelParent', 'EditModelObject',
                        'EditRegionmap', 'EmptyRegion', 'DeleteRegion', 'DeleteTemporaryRegion',
                        'DeleteRoom', 'DeleteModelObject', 'ListModel', 'ListOrphan', 'DumpModel',
                        'SplitModel', 'EditModel', 'MergeModel', 'UpdateModel', 'CompressModel',
                        'ModelReport', 'ListSourceCode',
                    'AddLabelStyle', 'EditLabelStyle', 'RenameLabelStyle', 'DeleteLabelStyle',
                        'ListLabelStyle',
                    'QuickLabelDelete',
                    'AddPlayerCharacter', 'DeletePlayerCharacter', 'ListPlayerCharacter',
                    'AddMinionString', 'DeleteMinionString', 'ListMinionString',
                    'SetLightList', 'ResetLightList', 'SetLightStatus',
                    'SetRoom', 'ResetRoom', 'SetOfflineRoom', 'LocateRoom',
                    'EditRoomComponent', 'ListRoomComponent',
                    'EditPainter',
                    'SetAssistedMoves', 'SetProtectedMoves',
                    'RoomCommand', 'IgnoreRoomCommand', 'NoticeRoomCommand', 'ListRoomCommand',
                '@Exit model commands',
                    'AddExit', 'EditExit', 'DeleteExit', 'ListExitModel', 'DumpExitModel',
                    'AllocateExit', 'AlternativeExit',
            ],
            # An ordered list of commands, initially set to $self->constClientCmdPrettyList, and
            #   modified when plugins are loaded, enabled or disabled in order to show (or remove)
            #   any plugin client commands
            clientCmdPrettyList         => [],      # set below
            # An ordered list of commands - initially set to $self->constClientCmdPrettyList but
            #   with the headings removed, and all in lower-case (e.g. 'AddChar' becomes 'addchar')
            clientCmdList               => [],
            # When plugins are loaded, anything to be added to ->clientCmdPrettyList is also added
            #   to this hash. Then, when the plugin is disabled and/or re-enabled,
            #   ->clientCmdPrettyList can be updated
            # Hash in the form
            #   $clientCmdReplacePrettyHash{plugin_name}
            #       = reference_to_list_of_group_headings_and_client_commands
            clientCmdReplacePrettyHash  => {},
            #
            # Each client command has one or more corresponding 'user commands'. Most user commands
            #   are abbreviations; for example, the client command 'addchar' has the user commands
            #   'ach' and 'addchar'
            # When the user types a client command in the 'main' window, what they're actually
            #   typing is a user command. Axmud translates the user command into the corresponding
            #   client command before executing it
            # Both client and user commands have a maximum length of 32 characters
            #
            # The constant hash of user commands (these values never change). A hash in the form
            #  $constUserCmdHash{user_command} = standard_command
            #       e.g. $constUserCmdHash{'ab'} = 'about'
            # The hash is set up by a call to $self->setupCmds
            constUserCmdHash            => {},
            # The customisable hash of user commands, in the form
            #   $userCmdHash{user_command} = standard_command
            userCmdHash                 => {},      # [usercmds]
            #       e.g. ->constUserCmdHash{'my_custom_about'} = 'about'

            # Instructions
            # ------------

            # Axmud offers several different kinds of instructions. Instructions are usually typed
            #   in the 'main' window's command entry box, but any part of the Axmud code can
            #   generate its own instructions
            # For example, most interfaces (triggers, aliases, macros, timers and hooks) generate an
            #   instruction as their response to a stimulus, and that instruction is executed as if
            #   it had been typed in the 'main' window's command entry box
            # Instructions can beging with one of Axmud's instruction sigils. The sigil specifies
            #   what kind of instruction it is
            # Some sigils are invariable (cannot be disabled, but others can be enabled or disabled
            #   according to the user's requirements
            # If an instruction doesn't begin with a recognised instruction sigil, or if it begins
            #   with an instruction sigil that's currently disabled, it is executed as an ordinary
            #   world command (sent to the current world)
            #
            # The following sigils can be enabled/disabled (but are disabled by default):
            #
            # The " (double quote) character indicates an 'echo command'. Echo commands are
            #   displayed in the current session's 'main' window in the same colour used by Axmud
            #   system messages
            #
            #   e.g. "hello world
            #       - Displays a 'hello world' message in the session's 'main' window
            #
            # The / (forward slash) character indicates a 'Perl command'. Perl commands are run as
            #   a mini-Perl programme. The programme's return value is then executed as an
            #   instruction. For security, the programme has limited functionality (for example,
            #   it's not possible to accidentally run 'rm *' )
            #
            #   e.g. /$a = 5; $b = 2; $a * $b;
            #       - Evaluates the programme, which returns a value of 10, which is executed as a
            #           world command
            #
            # The & (ampersand) character indicates a 'script command'. Script commands cause an
            #   Axbasic script to run. Note that, unlike Perl programmes, Axbasic scripts don't have
            #   a return value, so no instruction is executed when the script terminates
            #
            #   e.g. &wumpus
            #       - Runs the wumpus.bas script; it's the equivalent of ';runscript wumpus'
            #
            # The : (colon) character indicates a 'multi command'. Multi commands are executed in
            #   multiple sessions - either in sessions connected to the same world as the session
            #   executing the command, or in all sessions (depending on the value of
            #   $self->maxMultiCmdFlag) - as a forced world command
            #
            #   e.g. :shout I'm going for lunch
            #       - Executes the forced world command in multiple sessions
            #
            # The . (full stop) character indicates a 'speedwalk command'. Speedwalk commands are
            #   strings like '3nw2e' which resolved to a series of world commands. For special
            #   features of speedwalk commands, see the comments in GA::Session->speedWalkCmd
            #
            #   e.g. .3nw2s
            #       - The equivalent of 'north;north;north;west;south;south'
            #
            # The > (greater than) character indicates a 'bypass command'. Bypass commands are
            #   ordinary world commands that are executed immediately, ahead of any stored excess
            #   commands (if the world profile's slowwalking settings specify a command limit, or if
            #   the session is in crawl mode)
            #
            #   e.g. >drink water
            #       - Executes the world command immediately, perhaps to drink in order to increase
            #           the character's energy points before they run out, and while still moving
            #           along a path (specifically, bypasses a queue of unsent world commands
            #           created in slowwalking or crawl mode)
            #
            # The following sigils are always enabled:
            #
            # The ; (semicolon) character indicates a 'client command'. Axmud provides several
            #   hundred client commands so that its internal data can be accessed and modified
            #   from the command line
            #
            #   e.g. ;help
            #       - Displays Axmud help
            #
            # The ,, (two commas) sequence indicates a 'forced world command'. Everything following
            #   the commas is executed as a world command, even if the rest of the command starts
            #   with a different instruction sigil
            #
            #   e.g. ,,/connect
            #       - Executes '/connect/ as a world command, rather than as a Perl command
            #
            # If an instruction doesn't begin with a recognised instruction sigil (or if it does,
            #   but the sigil is disabled), the instruction is executed as an ordinary world command
            #   (not a forced world command)
            #
            # World commands can be modified in some circumstances
            #   - They can be intercepted by aliases, and either modified or diverted to some part
            #       of the Axmud code
            #   - Primary directions like 'north' can be modified if 'redirect' mode is on, or if
            #       the automapper's assisted moves are on
            #   - The instruction might be split into two or more world commands, if the command
            #       separator (a semicolon by default) occurs in the command
            #   - commands typed in upper-case letters (only) can be converted to lower-case letters
            #       if $self->convertWorldCmdFlag is set
            # However, none of these apply to forced world commands, which are never modified before
            #   being sent to the world
            #
            # The instruction sigils. Modifying the values of these IVs is strongly discouraged
            # If you do modify them, do not use empty strings or strings containing whitespace. Make
            #   sure each sigil starts with a different character (i.e. don't set the client command
            #   sigil to '@1' and the echo command sigil to '@2', or something like that)
            # Axmud system messages do not consult these IVs; they generally assume that the sigils
            #   have not been modified. Changing these sigils will not affect the way missions or
            #   the Chat task operate
            constClientSigil            => ';',
            constForcedSigil            => ',,',
            constEchoSigil              => '"',
            constPerlSigil              => '/',
            constScriptSigil            => '&',
            constMultiSigil             => ':',
            constSpeedSigil             => '.',
            constBypassSigil            => '>',
            # Flags to enable (TRUE) or disable (FALSE) some instruction sigils
            echoSigilFlag               => FALSE,
            perlSigilFlag               => FALSE,
            scriptSigilFlag             => FALSE,
            multiSigilFlag              => FALSE,
            speedSigilFlag              => FALSE,
            bypassSigilFlag             => FALSE,
            #
            # The default character (or string) used to separate commands in a string (maximum 4
            #   characters)
            constCmdSep                 => ';',
            # The current character (or string) used
            cmdSep                      => undef,      # [config] Set below

            # Constant default sizes for display, instruction and world command buffers (any
            #   registry which stores GA::Buffer::Display, GA::Buffer::Instruct or
            #   GA::Buffer::Cmd objects)
            constDisplayBufferSize      => 10000,
            constInstructBufferSize     => 1000,
            constCmdBufferSize          => 1000,
            # Constant minimum/maximum buffer sizes
            constMinBufferSize          => 10,
            constMaxBufferSize          => 1000000,
            # Custom sizes for display, instruction and world command buffers. Minimum 10,
            #   maximum 1000000
            customDisplayBufferSize     => undef,           # [config] set below
            customInstructBufferSize    => undef,           # [config]
            customCmdBufferSize         => undef,           # [config]

            # Flag set to TRUE if world commands should be confirmed (also displayed) in the
            #   session's default textview object, after being sent to the world; set to FALSE
            #   otherwise
            confirmWorldCmdFlag         => TRUE,            # [config]
            # Flag set to TRUE if single-word world commands that are in ALL CAPITAL LETTERS
            #   (usually after typing all-caps elsewhere, perhaps the text for a label in the
            #   automapper window) should be converted to lower-case letters, before being processed
            convertWorldCmdFlag         => TRUE,            # [config]
            # Flag set to TRUE if the last world command typed in the 'main' window's command entry
            #   box should be preserved after the user types RETURN; set to FALSE otherwise (also
            #   applies to multi commands, speedwalk commands and bypass commands)
            preserveWorldCmdFlag        => TRUE,            # [config]
            # Flag set to TRUE if the last instruction (besides world, multi, speedwalk and bypass
            #   commands commands) typed in the 'main' window's command entry box should be
            #   preserved after the user types RETURN, set to FALSE otherwise
            preserveOtherCmdFlag        => FALSE,           # [config]
            # Flag set to TRUE if multi commands (those beginning with the instruction sigil ':')
            #   should be executed as world commands in all sessions, FALSE if they should be
            #   executed as world commands only in sessions with the same current world
            maxMultiCmdFlag             => TRUE,            # [config]

            # Auto-complete mode - what to do when an 'internal' window's command entry box is in
            #   focus, and the user presses the up/down arrow keys
            #       'none'      - Do nothing
            #       'auto'      - Auto-complete the command using the 'tab' key, or navigate through
            #                       instructions/world commands using the 'up'/'down' keys
            autoCompleteMode            => 'auto',          # [config]
            # Auto-complete type - navigate through an instruction buffer ('instruct') or through a
            #   world command buffer ('cmd')
            autoCompleteType            => 'cmd',           # [config]
            # Auto-complete registry location. Registries to store display, instruction and world
            #   command buffers exist in GA::Client and GA::Session. Which registry to use:
            #   'combined' or 'session'
            autoCompleteParent          => 'session',       # [config]

            # Flag set to TRUE if the page up/page down/home/end keys should cause the a textview in
            #   the active 'internal' window to scroll up and down; set to FALSE otherwise
            useScrollKeysFlag           => TRUE,            # [config]
            # Flag set to FALSE if the page up/page down keys should scroll the size of a page (so
            #   that no text from the previous page is visible), TRUE if the keys should scroll the
            #   size of a page increment (which is a little smaller, so that text from the top or
            #   bottom is still visible)
            smoothScrollKeysFlag        => TRUE,            # [config]
            # Flag set to TRUE if the page up/home keys should cause a textview object to engage
            #   split screen mode (if it's not engaged already), and the page down/end keys should
            #   cause a textview object to disengage split screen mode
            autoSplitKeysFlag           => TRUE,            # [config]
            # Flag set to TRUE if the tab/cursor up/cursor down should autocomplete text in the
            #   active 'internal' window's command entry box; set to FALSE otherwise
            # (NB GA::Client->autoCompleteMode must also be set to 'auto')
            useCompleteKeysFlag         => TRUE,            # [config]
            # Flag set to TRUE if the TAB key should switch between tabs in a pane object
            #   (GA::Table::Pane) in the active 'internal' window; set to FALSE otherwise
            # If the window contains an entry strip object (GA::Strip::Entry), the TAB key is used
            #   in auto-completion, so CTRL+TAB is required to switch tabs. If there's no entry
            #   strip object, TAB will do the job
            useSwitchKeysFlag           => TRUE,            # [config]

            # The instruction buffer for the client. Every instruction processed by any session is
            #   assigned its own GA::Buffer::Instruct object in that session's registry, as well as
            #   a separate GA::Buffer:Instruct object in this registry
            # Instructions includes client commands like ';setworld deathmud', Perl commands, echo
            #   commands as well as world commands
            # In addition, if the user types 'north;kill troll;eat corpse', that chain of world
            #   commands is stored as a single GA::Buffer::Instruct (and also as three separate
            #   GA::Buffer::Cmd objects in the world command buffer)
            # When the buffer is full, adding an instruction to the buffer also deletes the oldest
            #   existing one
            # Hash in the form
            #   $instructBufferHash{number} = blessed_reference_to_buffer_object
            instructBufferHash          => {},
            # How many instructions have been processed altogether (used to give every
            #   GA::Buffer::Instruct object a unique number)
            instructBufferCount         => 0,
            # The ->number of the earliest surviving GA::Buffer::Instruct object in the buffer,
            #   deleted when the buffer is full and a new object is added
            instructBufferFirst         => undef,
            # The ->number of the most recently-created GA::Buffer::Instruct object in the buffer
            #   (when set, always one less than $self->instructBufferCount)
            instructBufferLast          => undef,
            # When the user navigates through instructions in an 'internal' window's command entry
            #   box by pressing the up/down arrow keys, the number of the buffer object whose
            #   instruction is currently used (matches a key in ->instructBufferHash)
            # Set on the first such key press in the window. Reset back to 'undef' when the current
            #   session changes or an instruction is processed by the visible session (even if it's
            #   a GA::Session->pseudoCmd call)
            instructBufferPosn          => undef,

            # The world command buffer for the client. Every world command processed by any session
            #   is assigned its own GA::Buffer::Cmd object in that session's registry, as well as a
            #   separate GA::Buffer:Cmd object in this registry
            # If the user types 'north;kill troll;eat corpse', three world commands are processed
            #   and three GA::Buffer:Cmd objects are added
            # When the buffer is full, adding an instruction to the buffer also deletes the oldest
            #   existing one
            # Hash in the form
            #   $cmdBufferHash{number} = blessed_reference_to_buffer_object
            cmdBufferHash               => {},
            # How many world commands have been processed altogether (used to give every
            #   GA::Buffer::Cmd object a unique number)
            cmdBufferCount              => 0,
            # The ->number of the earliest surviving GA::Buffer::Cmd object in the buffer,
            #   deleted when the buffer is full and a new object is added
            cmdBufferFirst              => undef,
            # The ->number of the most recently-created GA::Buffer::Cmd object in the buffer
            #   (when set, always one less than $self->cmdBufferCount)
            cmdBufferLast               => undef,
            # When the user navigates through world commands in an 'internal' window's command entry
            #   box by pressing the up/down arrow keys, the number of the buffer object whose
            #   world command is currently used (matches a key in ->cmdBufferHash)
            # Set on the first such key press in the window. Reset back to 'undef' when the current
            #   session changes or an instruction is processed by the visible session (even if it's
            #   a GA::Session->pseudoCmd call)
            cmdBufferPosn               => undef,

            # Profiles
            # --------

            # 'Profiles' are Perl objects describing the properties of things like worlds, guilds,
            #   races and characters. All profiles are associated with a particular world. For every
            #   single world profile, there can be any number of associated guild, race and
            #   character profiles. The profiles for each world have a unique name, so you can't
            #   have a character and a race profile both called 'wolf' (but you can have two
            #   character profiles, both called 'Gandalf', associated with different worlds)
            # Other data can be represented by profiles - for example, it's possible for the user to
            #   create 'faction', 'gang' or 'house' profiles
            # At the start of the session, Axmud loads from file (or creates) all the profiles
            #   associated with that world. One profile of each category can be marked as 'current'.
            #   There doesn't have to be a current profile from each category, but there is always a
            #   current 'world' profile (and usually a current 'character' profile)
            # A 'profile template' is a blueprint for a new category of profile. The template can
            #   spawn copies of itself which are profiles in their own right
            #
            # Profiles serve two purposes. Firstly, they allow us to store data about the world,
            #   secondly, they allow us to attach Axmud interfaces to a subset of characters on the
            #   world. (Interfaces are triggers, aliases, macros, timers and hooks)
            # In short, when a player logs in to Deathmud with the character Gandalf, Axmud is able
            #   to activate only the relevant interfaces, disactivating all the others. For example,
            #   if we have three aliases called 'shopping' (one for wizards, one for warriors and
            #   one for thieves), only the 'shopping' alias for wizards will be activated
            #
            # Profiles categories have a priority order, with the highest priority on the left of
            #   the list. The default priority order is character > race > guild > world
            # The priority order can be changed, but with a few restrictions: it must contain at
            #   least 'world' and 'char', and 'world' always has the lowest priority (is the last
            #   item on the list)
            # If we have two aliases called 'shopping', one for Gandalf only and one for wizards in
            #   general, the Gandalf alias is the active one because characters take priority over
            #   guilds (by default)
            #
            # Constant registry list of profile priorities (these values never change)
            constProfPriorityList       => ['char', 'race', 'guild', 'world'],
            # Constant registry hash of profile IVs that are used with every category of profile,
            #   and which therefore can't be changed or removed in profile templates or custom
            #   profiles
            constProfStandardHash       => {
                name                    => undef,
                category                => undef,
                parentWorld             => undef,
                initTaskHash            => undef,
                initTaskOrderList       => undef,
                initTaskTotal           => undef,
                initScriptHash          => undef,
                initScriptOrderList     => undef,
                initMission             => undef,
                initCmdList             => undef,
                setupCompleteFlag       => undef,
                notepadList             => undef,
                privateHash             => undef,
                # Also, the IVs used by profile templates, but not built-in profiles
                constFixedFlag          => undef,
                # Also, constant IVs specified by $self->constIVHash
                _objName                => undef,
                _objClass               => undef,
                _parentFile             => undef,
                _parentWorld            => undef,
                _privFlag               => undef,
            },
            #
            # Registry hash of all world profile objects, in the form
            #   $worldProfHash{unique_string_name} = blessed_reference_to_profile_object
            worldProfHash               => {},      # [config] [worldprof]
            #
            # Axmud comes with some pre-configured world profiles. A constant registry hash of those
            #   world profiles, and the Axmud version in which they were introduced
            # If the user is using a newer version of Axmud, this IV is consulted and any new
            #   pre-configured worlds are imported into Axmud's data directories
            constWorldHash              => {
                'aardwolf'          => '1.0.140', # Aardwolf MUD / aardmud.org 40000
                'achaea'            => '1.0.050', # Achaea / achaea.com 23
                'advun'             => '1.1.138', # Adventures Unlimited / tharel.net 5005
                'aetolia'           => '1.0.376', # Aetolia / aetolia.com 23
                'alteraeon'         => '1.0.140', # Alter Aeon / alteraeon.com 3000
                'anguish'           => '1.0.050', # Ancient Anguish / ancient.anguish.org 2222
                'aochaos'           => '1.1.050', # Age of Chaos / aoc.pandapub.com 4000
                'archipelago'       => '1.0.140', # Archipelago MUD / the-firebird.net 8000
                'arctic'            => '1.1.0',   # ArcticMud / mud.arctic.org 2700
                'ateraan'           => '1.1.0',   # New Worlds: Ateraan / www.ateraan.com 4002
                'avalonmud'         => '1.1.050', # Avalon (Germany) / avalon.mud.de 7777
                'avalonrpg'         => '1.1.0',   # Avalon; The Legend Lives / avalon-rpg.com 23
                'avatarmud'         => '1.1.0',   # Avatar MUD / avatar.outland.org 3000
                'batmud'            => '1.0.140', # BatMUD / batmud.bat.org 23
                'bedlam'            => '1.0.140', # Bedlam / mud.playbedlam.com 9000
                'burningmud'        => '1.1.0',   # Burning MUD / burningmud.com 4000
                'bylins'            => '1.1.138', # Bylins MUD / bylins.su 4000
                'carrion'           => '1.1.050', # Carrion Fields / carrionfields.net 4449
                'clessidra'         => '1.1.138', # Clessidra MUD / mud.clessidra.it 4000
                'clok'              => '1.0.275', # CLOK / clok.contrarium.net 4000
                'coffeemud'         => '1.1.0',   # CoffeeMud / coffeemud.net 23
                'cryosphere'        => '1.0.376', # Cryosphere / cryosphere.org 6666
                'cyberassault'      => '1.1.050', # CyberASSAULT / cyberassault.org 11111
                'darkrealms'        => '1.1.0',   # Dark Realms: City of Syne / 173.244.70.250 1138
                'dartmud'           => '1.1.0',   # DartMUD / dartmud.com 2525
                'dawn'              => '1.1.0',   # Dawn / 23.241.198.57 3000
                'discworld'         => '1.0.140', # Discworld MUD / discworld.starturtle.net 23
                'dragonstone'       => '1.1.138', # DragonStone / dragonstone.mudmagic.com 2345
                'dsdev'             => '1.0.0',   # Dead Souls development mud / dead-souls.net 8000
                'dslands'           => '1.0.0',   # Dark and Shattered Lands / dsl-mud.org 4000
                'dslocal'           => '1.0.0',   # Local installation of Dead Souls mudlib
                                                  #     / localhost 6666
                'dsprime'           => '1.0.0',   # Dead Souls game mud / dead-souls.net 6666
                'dswords'           => '1.1.270', # Dragon Swords / dragonswordsmud.com 1234
                'dunemud'           => '1.1.0',   # DuneMUD / dunemud.net 6789
                'duris'             => '1.0.0',   # Duris: Land of BloodLust / mud.durismud.com 7777
                'edmud'             => '1.1.138', # Eternal Darkness / edmud.net 9700
                'elephantmud'       => '1.1.0',   # Elephant MUD / elephant.org 23
                'elysium'           => '1.1.050', # Elysium RPG / elysium-rpg.com 7777
                'empire'            => '1.1.0',   # EmpireMUD 2.0 / empiremud.net 4000
                'eotl'              => '1.1.0',   # End of the Line / eotl.org 2010
                'fkingdoms'         => '1.1.270', # Forgotten Kingdoms / forgottenkingdoms.org 23
                'fourdims'          => '1.0.050', # 4Dimensions / 4dimensions.org 6000
                'forestsedge'       => '1.1.270', # Forest's Edge / theforestsedge.com 23
                'genesis'           => '1.0.0',   # Genesis / mud.genesismud.org 3011
                'greatermud'        => '1.1.270', # GreaterMUD / greatermud.com 23
                'hellmoo'           => '1.1.050', # HellMOO / hellmoo.org 7777
                'hexonyx'           => '1.1.138', # HexOnyx / mud.hexonyx.com 7777
                'holyquest'         => '1.1.0',   # HolyQuest / holyquest.org 8080
                'iberia'            => '1.0.0',   # Iberia MUD / iberiamud.com 5900
                'icesus'            => '1.1.0',   # Icesus / icesus.org 23
                'ifmud'             => '1.0.275', # ifMUD / ifmud.port4000.com 4000
                'imperian'          => '1.0.376', # Imperian: Sundered Heavens / imperian.com 23
                'islands'           => '1.1.0',   # Islands / play.islands-game.live 3000
                'kallisti'          => '1.1.0',   # Legends of Kallisti / legendsofkallisti.com 4000
                'lambda'            => '1.1.0',   # LambdaMOO / lambda.moo.mud.org 8888
                'legendmud'         => '1.0.275', # LegendMUD / mud.legendmud.org 9999
                'lostsouls'         => '1.1.0',   # Lost Souls / lostsouls.org 23
                'luminari'          => '1.1.0',   # Luminari MUD / luminarimud.com 4100
                'lusternia'         => '1.0.0',   # Lusternia / lusternia.com 23
                'magica'            => '1.0.140', # Materia Magica / materiamagica.com 4000
                'medievia'          => '1.1.0',   # Medievia / medievia.com 4000
                'merentha'          => '1.0.050', # Merentha / mud.merentha.com 10000
                'midnightsun'       => '1.1.270', # Midnight Sun / midnightsun2.org 3000
                'miriani'           => '1.1.050', # Miriani / toastsoft.net 1234
                'morgengrauen'      => '1.1.0',   # MorgenGrauen / mg.mud.de 23
                'mud1'              => '1.1.0',   # MUD1 (British Legends)
                                                  #     / british-legends.com 27750
                'mud2'              => '1.1.0',   # MUD2 (Canadian server) / mud2.com 23
                'mudii'             => '1.1.0',   # MUD2 (UK server) / mud2.com 23
                'mume'              => '1.1.050', # MUME / mume.org 23
                'nannymud'          => '1.1.270', # NannyMUD / mud.lysator.liu.se 2000
                'nanvaent'          => '1.0.0',   # Nanvaent / nanvaent.org 23
                'nodeka'            => '1.0.275', # Nodeka / nodeka.com 23
                'nuclearwar'        => '1.0.140', # Nuclear War / nuclearwarmudusa.com 4000
                'penultimate'       => '1.1.0',   # Penultimate Destination
                                                  #     / penultimatemush.com 9500
                'pict'              => '1.0.140', # Pict MUD / 136.62.89.155 4200
                'ravenmud'          => '1.1.138', # RavenMUD / ravenmud.com 6060
                'realmsmud'         => '1.1.138', # RealmsMUD / realmsmud.org 1501
                'reinos'            => '1.1.0',   # Reinos de Leyenda / rlmud.org 5001
                'retromud'          => '1.1.0',   # RetroMUD / retromud.org 3000
                'rodespair'         => '1.1.0',   # Realms of Despair / realmsofdespair.com 23
                'roninmud'          => '1.1.050', # RoninMUD / game.roninmud.org 5000
                'rupert'            => '1.0.275', # Rupert / rupert.twyst.org 9040
                'slothmud'          => '1.0.140', # SlothMUD III / slothmud.org 6101
                'stickmud'          => '1.1.270', # StickMUD / stickmud.com 7680
                'stonia'            => '1.0.376', # Stonia / stonia.ttu.ee 4000
                'swmud'             => '1.1.0',   # Star Wars Mud / swmud.org 6666
                'tempora'           => '1.0.0',   # Tempora Heroica / login1.ibiblio.org 2895
                'theland'           => '1.1.270', # The Land / theland.notroot.com 5000
                'threekingdoms'     => '1.1.0',   # 3Kingdoms / 3k.org 3000
                'threescapes'       => '1.1.0',   # 3Scapes / 3scapes.org 3200
                'tilegacy'          => '1.1.270', # The Inquisition: Legacy / ti-legacy.org 5050
                'torilmud'          => '1.1.0',   # TorilMUD / torilmud.org 9999
                'tsunami'           => '1.1.050', # Tsunami / tsunami.thebigwave.net 23
                'twotowers'         => '1.1.138', # Two Towers / t2tmud.org 9999
                'uossmud'           => '1.1.270', # Unofficial SquareSoft MUD
                                                  #     / uossmud.sandwich.net 9000
                'valhalla'          => '1.0.0',   # Valhalla MUD / valhalla.com 4242
                'vikingmud'         => '1.0.050', # Viking MUD / connect.vikingmud.org 2001
                'waterdeep'         => '1.1.138', # Waterdeep / waterdeep.org 4200
                'wotmud'            => '1.1.0',   # The Wheel of Time MUD / game.wotmud.org 2224
                'zombiemud'         => '1.1.0',   # ZombieMUD / zombiemud.org 23
                # Pre-configured worlds from earlier releases => '1.1.0', now defunct
#               'midkemia'          => '1.0.376', # Midkemia Online / closed 2016
                # Worlds ready for the next Axmud release
                #   ...
            },
            # Constant registry hash of pre-configured world profiles that must be patched (because
            #   of serious problems, or because the IP/DNS/port has changed), and the most recent
            #   Axmud version whose saved data requires the patch
            constWorldPatchHash         => {
                'achaea'            => '1.2.041',
                'aetolia'           => '1.2.041',
                'alteraeon'         => '1.1.270',
                'avalonrpg'         => '1.1.012',
                'discworld'         => '1.1.343',
                'dsdev'             => '1.1.270',
                'dslocal'           => '1.1.270',
                'dsprime'           => '1.1.270',
                'dunemud'           => '1.2.0',
                'imperian'          => '1.2.041',
                'islands'           => '1.2.0',
                'kallisti'          => '1.2.041',
                'luminari'          => '1.1.270',
                'lusternia'         => '1.2.041',
                'mud1'              => '1.1.270',
                'mud2'              => '1.1.270',
                'mudii'             => '1.1.270',
                'nanvaent'          => '1.1.405',
                'pict'              => '1.1.174',
                'swmud'             => '1.1.012',
                'threekingdoms'     => '1.1.270',
                'threescapes'       => '1.1.270',
                'twotowers'         => '1.2.0',
            },
            # Constant registry list of pre-configured world profiles; all the keys in
            #   $self->constWorldList, sorted alphabetically
            constWorldList              => [],      # Set below
            # The Axmud version found the last time the user ran Axmud. If the user is now using a
            #   newer version of Axmud, the code uses this IV to decide which new pre-configured
            #   worlds to insert into Axmud's data directory
            # The literal value stored below is the version number of Axmud's first public release.
            #   This IV was introduced in v1.1.021
            prevClientVersion           => '1.0.0', # [config]
            # List of the user's 'favourite' worlds, which appear at the top of the Connections
            #   window's list (in the same order they appear here)
            favouriteWorldList          => [],      # [config]
            # List of worlds to which Axmud should auto-connect when it starts (unless @ARGV is set,
            #   meaning the user started Axmud by typing something like 'axmud.pl deathmud 5555'
            # Each item in the list should be a string containing one or more words, separated by
            #   any amount of whitespace. The first (compulsory) word is the world profile name;
            #   any subsequent words are character profile names. If multiple character profiles are
            #   specified, Axmud opens a session for all of them. If none are specified, Axmud opens
            #   a connection without setting a current character
            # The list is processed in order. A world can appear multiple times in the list. When
            #   Axmud starts, if the world profile or a character profile doesn't exist, no
            #   attemption is connected. Axmud will connect to the same world several times, where
            #   no character profile exists, but it won't try to connect using the same profile
            #   twice
            # Note that, in Axmud blind mode ($BLIND_MODE_FLAG = TRUE), only one session can be
            #   opened. Any further items in this list after the first connection are ignored
            # Examples items in the list:
            #       'deathmud'
            #       'deathmud gandalf'
            #       'deathmud    gandalf    bilbo'
            autoConnectList             => [],      # [config]
            # As well as the pre-configured worlds, Axmud uses a much larger list of worlds from
            #   which the user can choose in the Connections window. Basic details for each world
            #   are stored in a GA::Obj::BasicWorld object
            # Registry hash in the form
            #       $constBasicWorldHash{'name'} = blessed_reference_to_basic_world_object
            # ...where 'name' is the string used as the world profile name, if the user connects
            #   to this world
            constBasicWorldHash         => {},      # Set by $self->loadBasicWorlds

            # World models
            # ------------

            # Constant registry list of room filters in a standard order
            constRoomFilterList         => [
                'markers',
                'custom',
                'navigation',
                'commercial',
                'buildings',
                'structures',
                'terrain',
                'objects',
                'light',
                'guilds',
                'quests',
                'attacks',
            ],
            # Parallel list of room filters with keyboard shortcuts, for use in the automapper
            #   window menu ('R' is not available, and items must be in the same order as the list
            #   above)
            constRoomFilterKeyList         => [
                '_markers',
                '_custom',
                '_navigation',
                'c_ommercial',
                '_buildings',
                '_structures',
                '_terrain',
                'ob_jects',
                'l_ight',
                '_guilds',
                '_quests',
                '_attacks',
            ],
            # Constant registry list of values used to initialise room flags in world models
            constRoomFlagList           => [
                # Markers
                # -------
                # blocked_room - Set if this room shouldn't be available to pathfinding functions
                #   (or similar code)
                'blocked_room' , 'Bl', 'markers',
                    '#A6483C',  # Dark red
                    'Room is blocked',
                # interesting - Set if this room is marked as interesting
                'interesting', 'In', 'markers',
                    '#EC7171',  # Pink
                    'Room is interesting',
                # investigate - Set if this room is marked as worth coming back later to investigate
                'investigate', 'Iv', 'markers',
                    '#F37E1B',  # Orange
                    'Room worth investigating',
                # unexplored - Set if this room hasn't been visited yet
                'unexplored', 'Ux', 'markers',
                    '#AE5463',  # Dull dark red
                    'Room not visited yet',
                #   unspecified - Set if this room has an 'unspecified' room statement
                'unspecified', 'Un', 'markers',
                    '#84885C',  # Very pale green
                    'Unspecified room statement',
                # avoid_room - Set if this room is marked as worth avoiding
                'avoid_room' , 'Av', 'markers',
                    '#E15835',  # Orange-red
                    'Room worth avoiding',
                # mortal_danger - Set if entering this room will probably get the character killed
                'mortal_danger', 'Md', 'markers',
                    '#FF0000',  # Default red
                    'Room is extremely dangerous',
                # danger - Set if entering this room is dangerous
                'danger', 'Dg', 'markers',
                    '#A12C1C',  # Dark red
                    'Room is dangerous',
                # dummy_room - Set if this room is not actually accessible
                'dummy_room', 'Dr', 'markers',
                    '#A4A4A4',  # Grey
                    'Inaccessible (dummy) room',
                # rent_room - Set if this room is where the character can rent (store stuff)
                'rent_room', 'Rt', 'markers',
                    '#CACA84',  # Pale brown/yellow
                    'Room for renting',
                # camp_room - Set if this room is where the character can camp
                'camp_room', 'Cm', 'markers',
                    '#909044',  # Darker brown/yellow
                    'Room for camping',
                # stash_room - Set if this room is where you like to leave things temporarily
                'stash_room', 'St', 'markers',
                    '#C1722B',  # Dirty orange
                    'Room for stashing things',
                # hide_room - Set if this room is where you like to hide
                'hide_room', 'Hd', 'markers',
                    '#AE8B6A',  # Grey-brown
                    'Room for hiding',
                # random_room - Set if this room was randomly generated (by the world)
                'random_room', 'Rn', 'markers',
                    '#A7B455',  # Yellow-green
                    'Randomly-generated room',
                # immortal_room - Set if this room is only accessible to admin users
                'immortal_room', 'Im', 'markers',
                    '#FF2161',  # Red-purple
                    'Room not accessible to mortals',

                # Custom
                # ------
                # (all room flags added by the user are in this filter)

                # Navigation
                # ----------
                # world_centre - Set if this room has been designated the centre of the world
                'world_centre', 'Mc', 'navigation',
                    '#FB922C',  # Orange
                     'Room is centre of world',
                # world_start - Set if this room is the room where new players start
                'world_start', 'Ms', 'navigation',
                    '#57FF6A',  # Lilac green
                     'Start room for new players',
                # meet_point - Set if this room has been designated as a meeting point (usually a
                #   room in the world at the centre of a town, near shops)
                'meet_point', 'Mp', 'navigation',
                    '#D77EC7',  # Light purple
                    'Room is a meetpoint',
                # main_route - Set if this is a main route
                'main_route', 'Mr', 'navigation',
                    '#A0959F',  # Dark grey
                    'Room is on a main route',
                # minor_route - Set if this is a minor route
                'minor_route', 'mr', 'navigation',
                    '#CDC4CD',  # Light grey
                    'Room is on a minor route',
                # cross_route - Set if this is where two or more routes meet
                'cross_route', 'Cr', 'navigation',
                    '#F0B68F',  # Light orange
                    'Room is at an intersection',
                # arrow_route - Set if this room leads in the right direction
                'arrow_route', 'Aw', 'navigation',
                    '#ECD24E',  # Gold
                    'Room leads in right direction',
                # wrong_route - Set if this room leads in the wrong direction
                'wrong_route', 'Br', 'navigation',
                    '#A55B2A',  # Brown
                    'Room leads in wrong direction',
                # portal - Set if this room contains some kind of portal
                'portal', 'Pl', 'navigation',
                    '#88FFE7',  # Bright cyan
                    'Room contains some kind of portal',
                # sign_post - Set if this room contains a signpost
                'sign_post', 'Sp', 'navigation',
                    '#B58870',  # Pale brown
                    'Room contains a signpost',
                # bus_stop - Set if this room is a stop along a moving vehicle's route
                'bus_stop', 'Bs', 'navigation',
                    '#6F6F6F',  # Darker grey
                    'Room has a bus stop',
                # moving_boat - Set if this room is on a (moving) boat
                'moving_boat', 'Bt', 'navigation',
                    '#3CD1C8',  # Cyan
                    'Room is a (moving) boat',
                # vehicle - Set if this room is on a (moving) vehicle
                'vehicle', 'Vh', 'navigation',
                    '#869D9B',  # Grey-cyan
                    'Room is a (moving) vehicle',
                # fixed_boat - Set if this room is on a (stationary) boat
                'fixed_boat', 'Fb', 'navigation',
                    '#237974',  # Darkish blue
                    'Room is on a (stationary) boat',
                # swim_room - Set if this room is in water, so the character needs to swim
                'swim_room', 'Sw', 'navigation',
                    '#2656C6',  # Blue
                    'Character needs to swim here',
                # fly_room - Set if this room is in the air, so the character needs to fly
                'fly_room', 'Fl', 'navigation',
                    '3A79F7',   # Sky blue
                    'Character needs to fly here',

                # Commercial
                # ----------
                # shop_general - Set if this room is a general store
                'shop_general', 'Sh', 'commercial',
                    '#F7FF65',  # Light yellow
                    'Room is a general store',
                # shop_weapon - Set if this room is a weapon shop
                'shop_weapon', 'Ws', 'commercial',
                    '#F97F20',  # Orange
                    'Room is a weapon shop',
                # shop_armour - Set if this room is an armour shop
                'shop_armour', 'Wa', 'commercial',
                    '#DA440C',  # Slightly darker orange
                    'Room is an armour shop',
                # shop_clothes - Set if this room is a clothes shop
                'shop_clothes', 'Wc', 'commercial',
                    '#DAA10C',  # Yellow-gold
                    'Room is a clothes shop',
                # shop_player - Set if this room is a player-controlled shop
                'shop_player', 'Sy', 'commercial',
                    '#FFA966',   # Light orange
                    'Room is a player-controlled shop',
                # shop_special - Set if this room is some other kind of shop
                'shop_special', 'Ss', 'commercial',
                    '#3AFF34',  # Green
                    'Room is another kind of shop',
                # shop_empty - Set if this room is an empty shop
                'shop_empty', 'Se', 'commercial',
                    '#8DFF89',  # Pale greeen
                    'Room is an empty shop',
                # smithy - Set if this room is a smithy
                'smithy', 'Sm', 'commercial',
                    '#D58111',  # Light brown
                    'Room is a smithy',
                # bank - Set if this room is a bank
                'bank', 'Bn', 'commercial',
                    '#8E0E3F',  # Purple
                    'Room is a bank',
                # pub - Set if this room is some kind of pub
                'pub', 'Pb', 'commercial',
                    '#1730F5',  # Blue
                    'Room is a pub',
                # cafe - Set if this room is some kind of cafeteria (like a pub, but with non-
                #   alcoholic drinks)
                'cafe', 'Cf', 'commercial',
                    '#3196CA',  # Dark cyan
                    'Room is a cafeteria',
                # restaurant - Set if this room is some kind of restaurant (where the character can
                #   eat)
                'restaurant', 'Re', 'commercial',
                    '#487F9B',  # Murky blue
                    'Room is a restaurant',
                # takeaway - Set if this room is some kind of takeaway (where the character can
                #   buy food to carry)
                'takeaway', 'Ta', 'commercial',
                    '#A9C1F4',  # Very light blue
                    'Room is a takeaway',
                # auction - Set if this room is an auction house
                'auction', 'Au', 'commercial',
                    '#CA1E4D',  # Red
                    'Room is an auction house',
                # post_office - Set if this room is a post office
                'post_office', 'Po', 'commercial',
                    '#8CB583',  # Dull green
                    'Room is a post office',

                # Buildings
                # ---------
                # library - Set if this room is where books, parchments, signs, notice boards and so
                #   on are available
                'library', 'Lb', 'buildings',
                    '#DEF3CC',  # Very pale green
                    'Room is a library',
                # theatre - Set if this room is a theatre or performance venue
                'theatre', 'Th', 'buildings',
                    '#2DD06C',  # Turquoise
                    'Room is a theatre',
                # temple - Set if this room is some kind of temple or shrine
                'temple', 'Te', 'buildings',
                    '#7C6365',  # Very dull red
                    'Room is a temple',
                # church - Set if this room is a church or cathedral
                'church', 'Ch', 'buildings',
                    '#C17D80',  # Pale red
                    'Room is a church/cathedral',
                # hotel - Set if this room is a hotel
                'hotel', 'Hl', 'buildings',
                    '#B0B167',  # Dull yellow
                    'Room is a hotel',
                # storage - Set if this room is somewhere you can store things
                'storage', 'St', 'buildings',
                    '#996712',  # Green-brown
                    'Room is a storage facility',
                # office - Set if this room is an office
                'office', 'Of', 'buildings',
                    '#A36C6C',  # Dull red
                    'Room is an office',
                # jail - Set if this room is a jail or dungeon
                'jail', 'Jl', 'buildings',
                    '#C46F47',  # Pale brown
                    'Room is a jail or dungeon',
                # hospital - Set if this room is some kind of hospital
                'hospital', 'Ho', 'buildings',
                    '#ED0C60',  # Red-purple
                    'Room is a hospital',
                # stable - Set if this room is a room where animals are stored
                'stable', 'St', 'buildings',
                    '#DF9F4B',  # Straw orange
                    'Room is a stable for animals',
                # tent - Set if this room is inside a tent
                'tent', 'Tt', 'buildings',
                    '#D2B380',  # Canvas
                    'Room is a tent',
                # house - Set if this room is an ordinary house or home
                'house', 'Hs', 'buildings',
                    '#3B7E55',  # Dark green
                    'Room is a house or home',
                # ord_building - Set if this room is an ordinary building
                'ord_building', 'Ob', 'buildings',
                    '#82E1CA',  # Light cyan
                    'Room is an ordinary building',
                # bulletin_board - Set if this room contains some kind of bulletin board
                'bulletin_board', 'Bb', 'buildings',
                    '#A47AB8',  # Light purple
                    'Room contains a bulletin board',

                # Structures
                # ----------
                # building - Set if this is any kind of building
                'building', 'Bu', 'structures',
                    '#B7764F',  # Pale brown
                    'Room is any kind of building',
                # gate - Set if this is at (or outside) a city gate
                'gate', 'Ga', 'structures',
                    '#87BDC6',  # Pale blue
                    'Room is at a city gate',
                # wall - Set if this is on (or alongside) a city wall
                'wall', 'Wl', 'structures',
                    '#C9D3D5',  # Blue-grey
                    'Room is on/outside a city wall',
                # tower - Set if this is on (or inside) a tower
                'tower', 'Tw', 'structures',
                    '#B1A27F',  # Dull yellow
                    'Room is on/inside a tower',
                # staircase - Set if this is on a staircase
                'staircase', 'Sc', 'structures',
                    '#FFB47C',  # Sandy yellow
                    'Room is on a staircase',
                # tunnel - Set if this is in a tunnel
                'tunnel', 'Tu', 'structures',
                    '#C4897D',  # Dull pink
                    'Room is in a tunnel',
                # bridge - Set if this is a on a bridge
                'bridge', 'Br', 'structures',
                    '#A9631F',  # Brown
                    'Room is on a bridge',
                # fountain - Set if this room has a fountain
                'fountain', 'Fn', 'structures',
                    '#35BDD8',  # Bright blue
                    'Room contains a fountain',
                # well - Set if this is a well or water source
                'well', 'We', 'structures',
                    '#76A1D3',  # Light blue
                    'Room is a well',
                # farm - Set if this is a farm
                'farm', 'Fa', 'structures',
                    '#A84100',  # Brown
                    'Room is on a farm',
                # field - Set if this is a field
                'field', 'Fi', 'structures',
                    '#75B256',  # Paler green
                    'Room is in a field',
                # park - Set if this is a park/garden
                'park', 'Pa', 'structures',
                    '#00FF00',  # (Pure) green
                    'Room is in a garden/park',
                # graveyard - Set if this is a graveyard
                'graveyard', 'Gy', 'structures',
                    '#CBA5AE',  # Dull pink
                    'Room is in a graveyard',
                # port - Set if this is a port/harbour/jetty
                'port', 'Pt', 'structures',
                    '#117311',  # Bottle green
                    'Room is in a port/harbour/jetty',
                # maze - Set if this is a maze
                'maze', 'Mz', 'structures',
                    '#D30027',  # Headache red
                    'Room is in a maze',

                # Terrain
                # -------
                # forest - Set if this is a forest/wood
                'forest', 'Fo', 'terrain',
                    '#227122',  # Dark green
                     'Room is in a forest/wood',
                # clearing - Set if this is a clearing
                'clearing', 'Cl', 'terrain',
                    '#68E568',  # Pale green
                     'Room is a clearing',
                # grassland - Set if this is a grassland/plain
                'grassland', 'Gl', 'terrain',
                    '#BFED57',  # Yellow-green
                    'Room is in a grassland/plain',
                # swamp - Set if this is a swamp/marsh
                'swamp', 'Sw', 'terrain',
                    '#6F9956',  # Dirty green
                    'Room is in a swamp/marsh',
                # desert - Set if this is a desert
                'desert', 'De', 'terrain',
                    '#F5F72B',  # Yellow
                    'Room is in a desert',
                # beach - Set if this is a beach/coast
                'beach', 'Be', 'terrain',
                    '#F7922B',  # Red-orange
                    'Room is on a beach/coastline',
                # river - Set if this is a river/stream
                'river', 'Rv', 'terrain',
                    '#61C3EB',  # Light blue
                    'Room is in a river/stream',
                # lake - Set if this is a lake
                'lake', 'Lk', 'terrain',
                    '#A9E6FF',  # Very light blue
                    'Room is in a lake',
                # sea - Set if this is a sea/ocean
                'sea', 'Se', 'terrain',
                    '#216D8C',  # Darker blue
                    'Room is in a sea/ocean',
                # cave - Set if this is a cave
                'cave', 'Cv', 'terrain',
                    '#849DAD',  # Grey-blue
                     'Room is in a cave',
                # mountain - Set if this is a mountainous area
                'mountain', 'Mn', 'terrain',
                    '#CDDDE7',  # Blue-white
                    'Room is in a mountainous area',
                # rocky - Set if this is rocky landscape
                'rocky', 'Rc', 'terrain',
                    '#C5AC95',  # Brown-grey
                    'Room is in a rocky landscape',
                # icy - Set if this is icy landscape
                'icy', 'Ic', 'terrain',
                    '#96BFC3',  # Very pale blue
                    'Room is in an icy landscape',
                # hill - Set if this is a hill
                'hill', 'Hi', 'terrain',
                    '#7ADA97',  # Light green
                    'Room is on a hill',
                # pit - Set if this is next to (or inside) a pit or hole
                'pit', 'Pi', 'terrain',
                    '#A7B179',  # Dull yellow-green
                    'Room is in a pit or contains one',

                # Objects
                # -------
                # weapon - Set if the room contains a weapon
                'weapon', 'Wp', 'objects',
                    '#A87389',  # Pale purple
                    'Room contains a weapon',
                # armour - Set if the room contains an armour
                'armour', 'Ar', 'objects',
                    '#82405C',  # Dark pale purple
                    'Room contains an armour',
                # garment - Set if the room contains a garment
                'garment', 'Gr', 'objects',
                    '#FF74AE',  # Purple-pink
                    'Room contains a garment',
                # major_npc - Set if the room contains an important NPC
                'major_npc', 'Np', 'objects',
                    '#3BCC2F',  # Green
                    'Room contains an important NPC',
                # talk_npc - Set if the room contains a talking NPC
                'talk_npc', 'Tn', 'objects',
                    '#086800',  # Dark green
                    'Room contains a talking NPC',
                # npc - Set if the room contains any NPC
                'npc', 'Np', 'objects',
                    '#7FEE75',  # Light green
                    'Room contains an NPC',
                # portable - Set if the room contains a portable object
                'portable', 'Pr', 'objects',
                    '#262FD8',  # Dark blue
                    'Room contains a portable object',
                # decoration - Set if the room contains a decoration object
                'decoration', 'Dc', 'objects',
                    '#10EBA1',  # Light cyan
                    'Room contains a decoration object',
                # money - Set if the room contains money
                'money', 'My', 'objects',
                    '#FFE63B',  # Gold
                    'Room contains money',
                # treasure - Set if the room contains a valuable object
                'treasure', 'Tr', 'objects',
                    '#FF673B',  # Red-orange
                    'Room treasure or valuable objects',
                # collectable - Set if the room contains a collectable object
                'collectable', 'Cl', 'objects',
                    '#FF9900',  # Orange
                    'Room contains collectable objects',

                # Light
                # -----
                # outside - Set if this room is outside
                'outside', 'Ou', 'light',
                    '#77C4E4',  # Sky blue
                    'Room is outside',
                # inside - Set if this room is inside
                'inside', 'In', 'light',
                    '#D38D36',  # Light brown
                    'Room is inside',
                # overground - Set if this room is above ground
                'overground', 'Ov', 'light',
                    '#36D355',  # Green
                    'Room is above ground',
                # underground - Set if this room is underground
                'underground', 'Un', 'light',
                    '#CDCDCD',  # Grey
                    'Room is underground',
                # torch - Set if average player needs a torch in this room
                'torch', 'To', 'light',
                    '#E1D139',  # Yellow
                    'Room usually needs a torch',
                # always_dark - Set if this room is always dark
                'always_dark', 'Ad', 'light',
                    '#977E6A',  # Pale brown
                    'Room is always dark',

                # Guilds
                # ------
                # guild_entrance - Set if this room is an entrance to a guild (possibly guarded)
                'guild_entrance', 'Ge', 'guilds',
                    '#8F2AF9',  # Purple-blue
                    'Entrance to a guild',
                # guild_main - Set if this is a room inside the guild where a character can advance
                #   skills and/or join the guild
                'guild_main', 'Gm', 'guilds',
                    '#DAA0FB',  # Light purple
                    'Guild room for advancing skills',
                # guild_practice - Set if this room is where a character can practice guild skills
                'guild_practice', 'Gp', 'guilds',
                    '#DB0C89',  # Red-purple
                    'Guild room for practicing skills',
                # guild_shop - Set if this is a room inside the guild where a character can buy
                #   guild-specific items
                'guild_shop', 'Gs', 'guilds',
                    '#CE4DF7',  # Purple
                    'Guild room for shopping',
                # guild_other - Set if this is a room inside the guild where a character can't
                #   advance skills or buy guild-specific items
                'guild_other', 'Go', 'guilds',
                    '#89679C',  # Grey-purple
                    'Other kind of guild room',

                # Quests
                # ------
                # quest_room - Set if this room is important in a quest
                'quest_room' , 'Qr', 'quests',
                    '#F4E637',  # Yellow
                    'Room used in quest',
                # quest_begin - Set if this room is the start of a quest
                'quest_begin', 'Qb', 'quests',
                    '#58FF57',  # Green
                    'Quest begins in room',
                # quest_end - Set if this room is the end of a quest
                'quest_end', 'Qe', 'quests',
                    '#FF6957',  # Red
                    'Quest ends in room',

                # Attacks
                # -------
                # peaceful - Set if the world doesn't allow fights in this room
                'peaceful', 'Pf', 'attacks',
                    '#9CE3DD',  # Light cyan
                    'World forbids attacks in room',
                # recovery - Set if this room lets the character recover from fights more quickly
                'recovery', 'Ry', 'attacks',
                    '#E9DC3D',  # Yellow
                    'Character recovers quickly in room',
                # char_dead - Set if any character has ever died in this room
                'char_dead', 'Cd', 'attacks',
                    '#FF361E',  # Red
                    'Any character has died in room',
                # char_pass_out - Set if any character has ever been knocked out in this room
                'char_pass_out', 'Cp', 'attacks',
                    '#ED22BE',  # Purple
                    'Any character has passed out in room',
            ],
            # Constant registry hash of room flags which mark the room as hazardous; the pathfinding
            #   functions (or any other code) can avoid these rooms when finding the shortest path
            #   between two rooms
            constRoomHazardHash         => {
                'blocked_room'          => undef,
                'avoid_room'            => undef,
                'danger',               => undef,
                'mortal_danger'         => undef,
                'dummy_room'            => undef,
            },

            # Cages
            # -----

            # 'Cages' are associated with a 'profile'
            # For example, the command cage lists common commands at a particular world (the verbs
            #   for 'kill', 'look', 'inventory', and so on)
            # If the cage is associated with the current world profile, those commands are
            #   considered to be available to all characters. However, if the cage is associated
            #   with (for example) a guild profile, those commands are considered to be available
            #   only to members of that guild
            # Parts of Axmud code - most usually, tasks and Axbasic scripts - can choose to have
            #   their commands modified, or 'interpolated', before being sent to the world. For
            #   example, if a task wants to send the command 'kill', it looks through the command
            #   cages for each current profile - starting with the highest-priority profile - and
            #   uses the first 'kill' command it finds
            # Besides the command cage, there are standard cage which store each kind of interface
            #   (triggers, aliases, macros, timers and hooks). It's also possible for the user to
            #   design their own cages
            #
            # Constant registry list of cage types (these values never change)
            constCageTypeList           => [
                'cmd',
                'trigger',
                'alias',
                'macro',
                'timer',
                'hook',
                'route',
            ],
            # Customisable registry list of cage types (max 8 chars)
            cageTypeList                => [],      # Set below

            # Dictionaries
            # ------------

            # Axmud Dictionaries contain lists of words so that Axmud can tell apart directions,
            #   NPCs, weapons, torches, and so on
            # If the dictionary object has the same name as a world, it's automatically associated
            #   with that world. (Dictionaries don't have to be associated with a particular world,
            #   but they often are)
            # Dictionaries are associated with a particular language. The default language is
            #   English
            #
            # Registry hash of dictionary objects that have been loaded since the script started,
            #   in the form
            #   $dictHash{unique_dictionary_name} = blessed_reference_to_dictionary_object
            dictHash                    => {},      # [dicts]
            # As well as dictionaries, Axmud uses a much smaller collection of data, a phrasebook
            #   object, containing a list of primary directions, articles, conjunctions and basic
            #   number words in a target language. The data is stored in a GA::Obj::Phrasebook
            #   object
            # Registry hash in the form
            #       $constPhrasebookHash{'name'} = blessed_reference_to_phrasebook_object
            # ...where 'name' is the the language name, rendered in lower-case English
            #   (e.g. 'french')
            constPhrasebookHash         => {},

            # Interfaces
            # ----------

            # Interfaces are triggers, aliases, macros, timers and hooks
            # Interface model objects store default values for each of these interfaces
            # Registry hash of interface model objects, in the form
            #   $interfaceModelHash{interface_type} = blessed_reference_to_interface_model_object
            interfaceModelHash          => {},

            # Macros use keycodes - ways of naming keys on the keyboard (F1, Escape, grave etc)
            # Axmud uses a standard set of keycodes that don't vary from system to system. For
            #   example, on Linux the ALT-GR key produces the keycode 'ISO_Level3_Shift', but on
            #   MS Windows, it produces the keycode 'Alt_R'. Axmud's standard keycode is 'alt_gr'
            # Note that there are no Axmud standard keycodes for ordinary letters/numbers; Axmud
            #   assumes that these are needed for typing, so they're not available to macros
            #
            # Constant registry hash of Axmud standard keycode values, and their Linux equivalents.
            #   Hash in the form
            #       $constKeycodeHash{standard_value} = linux_value_string
            # ...where 'standard_value' is a value used by Axmud to uniquely identify a key or
            #   key combination, and 'linux_value_string' is the corresponding keycode returned by
            #   Linux (when there is more than one corresponding keycode, they are in a single
            #   string, separated by a space)
            constKeycodeHash            => {
                shift                   => 'Shift_L Shift_R',
                alt                     => 'Alt_L',
                alt_gr                  => 'ISO_Level3_Shift',
                ctrl                    => 'Control_L Control_R',
                num_lock                => 'Num_Lock',

                escape                  => 'Escape',
                pause                   => 'Pause',
                break                   => 'Break',
                insert                  => 'Insert KP_Insert',
                delete                  => 'Delete KP_Delete',
                return                  => 'Return',
                backspace               => 'BackSpace',
                space                   => 'space',
                tab                     => 'Tab',

                home                    => 'Home KP_Home',
                page_up                 => 'Page_Up KP_Page_Up',
                page_down               => 'Page_Down KP_Page_Down',
                end                     => 'End KP_End',

                up                      => 'Up KP_Up',
                down                    => 'Down KP_Down',
                left                    => 'Left KP_Left',
                right                   => 'Right KP_Right',

                f1                      => 'F1',
                f2                      => 'F2',
                f3                      => 'F3',
                f4                      => 'F4',
                f5                      => 'F5',
                f6                      => 'F6',
                f7                      => 'F7',
                f8                      => 'F8',
                f9                      => 'F9',
                f10                     => 'F10',
                f11                     => 'F11',
                f12                     => 'F12',

                grave                   => 'grave',         # `
                tilde                   => 'asciitilde',    # ~
                exclam                  => 'exclam',        # !
                at                      => 'at',            # @
                number_sign             => 'numbersign',    # #
                dollar                  => 'dollar',        # $
                percent                 => 'percent',       # %
                ascii_circum            => 'asciicircum',   # ^
                ampersand               => 'ampersand',     # &
                asterisk                => 'asterisk',      # *
                paren_left              => 'parenleft',     # (
                paren_right             => 'parenright',    # )

                plus                    => 'plus',          # +
                minus                   => 'minus',         # -
                equal                   => 'equal',         # =
                underline               => 'underscore',    # _

                bracket_left            => 'bracketleft',   # [
                bracket_right           => 'bracketright',  # ]
                brace_left              => 'braceleft',     # {
                brace_right             => 'braceright',    # }
                colon                   => 'colon',         # :
                semicolon               => 'semicolon',     # ;
                apostrophe              => 'apostrophe',    # '
                quote                   => 'quotedbl',      # "
                slash                   => 'slash',         # /
                backslash               => 'backslash',     # \
                pipe                    => 'bar',           # |
                comma                   => 'comma',         # ,
                full_stop               => 'period',        # .
                less_than               => 'less',          # <
                greater_than            => 'greater',       # >
                question_mark           => 'question',      # ?

                # Keypad - NUM LOCK on
                kp_0                    => 'KP_0',
                kp_1                    => 'KP_1',
                kp_2                    => 'KP_2',
                kp_3                    => 'KP_3',
                kp_4                    => 'KP_4',
                kp_5                    => 'KP_5',
                kp_6                    => 'KP_6',
                kp_7                    => 'KP_7',
                kp_8                    => 'KP_8',
                kp_9                    => 'KP_9',
                kp_add                  => 'KP_Add',
                kp_subtract             => 'KP_Subtract',
                kp_multiply             => 'KP_Multiply',
                kp_divide               => 'KP_Divide',
                kp_enter                => 'KP_Enter',
                kp_full_stop            => 'KP_Decimal',
            },
            # We also use a constant registry hash of Axmud standard keycode values and their
            #   equivalents in MS Windows and in *BSD. Only keycodes which are different to those
            #   above are listed
            constMSWinKeycodeHash       => {
                alt_gr                  => 'Alt_R',
                ctrl                    => 'Control_L',
                num_lock                => '',
            },
            constBSDKeycodeHash         => {
                ctrl                    => 'Control_L',
                num_lock                => '',
            },
            # Custom hash of Axmud standard keycodes and their equivalents on the current system
            keycodeHash                 => {},              # Set by $self->setupKeycodes
            # The reverse hash of $self->keycodeHash, which therefore contains more keys, e.g.
            #   $keycodeHash{'up'} = 'Up KP_Up'
            #   $revKeycodeHash{'Up'} = 'up'
            #   $revKeycodeHash{'KP_Up'} = 'up'
            revKeycodeHash              => {},              # Set by $self->setupKeycodes
            # Constant registry hash of alternatives to Axmud standard keycode values. Includes
            #   variants without capitals (e.g. transforms 'backspace' into 'backSpace') and
            #   American English variants (e.g. transforms 'period' into 'full_stop')
            # Hash in the form
            #   $constAltKeycodeHash{variant_value} = standard_value
            # ...where 'standard_value' matches a key in $self->constKeycodeHash
            constAltKeycodeHash         => {
                altgr                   => 'alt_gr',
                pageup                  => 'page_up',
                pagedown                => 'page_down',
                numbersign              => 'number_sign',
                asciicircum             => 'ascii_circum',
                parenleft               => 'paren_left',
                parenright              => 'paren_right',
                bracketleft             => 'bracket_left',
                bracketright            => 'bracket_right',
                braceleft               => 'brace_left',
                braceright              => 'brace_right',
                bar                     => 'pipe',
                fullstop                => 'full_stop',
                period                  => 'full_stop',
                lessthan                => 'less_than',
                less                    => 'less_than',
                greaterthan             => 'greater_than',
                greater                 => 'greater_than',
                questionmark            => 'question_mark',
                underscore              => 'underline',
            },
            # Constant list of Axmud standard keycode values in a fixed order, each item a key in
            #   $self->constKeycodeHash
            constKeycodeList            => [
                'shift', 'alt', 'alt_gr', 'ctrl', 'num_lock',
                'escape', 'pause', 'break', 'insert', 'delete', 'return', 'backspace', 'space',
                    'tab',
                'home', 'page_up', 'page_down', 'end',
                'up', 'down', 'left', 'right',
                'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8', 'f9', 'f10', 'f11', 'f12',
                'grave', 'tilde', 'exclam', 'at', 'number_sign', 'dollar', 'percent',
                    'ascii_circum', 'ampersand', 'asterisk', 'paren_left', 'paren_right',
                'plus', 'minus', 'equal', 'underline',
                'bracket_left', 'bracket_right', 'brace_left', 'brace_right', 'colon', 'semicolon',
                    'apostrophe', 'quote', 'slash', 'backslash', 'pipe', 'comma', 'full_stop',
                    'less_than', 'greater_than', 'question_mark',
                'kp_0', 'kp_1', 'kp_2', 'kp_3', 'kp_4', 'kp_5', 'kp_6', 'kp_7', 'kp_8', 'kp_9',
                'kp_add', 'kp_subtract', 'kp_multiply', 'kp_divide', 'kp_enter',
                'kp_full_stop',
            ],
            # Registry hash of keycodes that are used by any active macro interface in any session
            #   (used in addition to the session's own registries, because every time a key is
            #   pressed, we want to know - as quickly as possible - whether we should check it
            #   against all interactive macros in all sessions). Hash in the form
            #   $activeKeycodeHash{standard_keycode} = undef
            activeKeycodeHash           => {},
            # When an active macro interface is deleted, $self->activeKeycodeHash needs to be
            #   reset. If several hundred interfaces are deleted in one go, it would be a bad idea
            #   to reset the registry several hundred times. Instead, this flag is set to TRUE.
            # Whichever GA::Session is the first to have its timer loop spin, is the one to call
            #   $self->reset_activeKeycodes, which re-compiles the registry
            resetKeycodesFlag           => FALSE,

            # Tasks
            # -----

            # Axmud keeps two lists of the package names for tasks - one for Axmud's built-in tasks,
            #   and another for all tasks (built-in tasks and those added via a plugin)
            #
            # The constant registry hash of package names (these values never change). A hash in the
            #   form
            #   $constTaskPackageHash{task_standard_name} = package_name
            #       e.g. task_standard_name = StatusTask->name,
            #           package_name = 'Games::Axmud::Task::Status'
            constTaskPackageHash        => {
                'advance_task'          => 'Games::Axmud::Task::Advance',
                'attack_task'           => 'Games::Axmud::Task::Attack',
                'channels_task'         => 'Games::Axmud::Task::Channels',
                'chat_task'             => 'Games::Axmud::Task::Chat',
                'compass_task'          => 'Games::Axmud::Task::Compass',
                'condition_task'        => 'Games::Axmud::Task::Condition',
                'connections_task'      => 'Games::Axmud::Task::Connections',
                'countdown_task'        => 'Games::Axmud::Task::Countdown',
                'divert_task'           => 'Games::Axmud::Task::Divert',
                'frame_task'            => 'Games::Axmud::Task::Frame',
                'inventory_task'        => 'Games::Axmud::Task::Inventory',
                'launch_task'           => 'Games::Axmud::Task::Launch',
                'locator_task'          => 'Games::Axmud::Task::Locator',
                'map_check_task'        => 'Games::Axmud::Task::MapCheck',
                'notepad_task'          => 'Games::Axmud::Task::Notepad',
                'raw_text_task'         => 'Games::Axmud::Task::RawText',
                'raw_token_task'        => 'Games::Axmud::Task::RawToken',
                'script_task'           => 'Games::Axmud::Task::Script',
                'status_task'           => 'Games::Axmud::Task::Status',
                'system_task'           => 'Games::Axmud::Task::System',
                'tasklist_task'         => 'Games::Axmud::Task::TaskList',
                'watch_task'            => 'Games::Axmud::Task::Watch',
            },
            # The customisable registry hash of package names, in the form
            #   $taskPackageHash{task_standard_name} = package_name
            #       e.g. task_standard_name = $myTask->name,
            #           package_name = 'Games::Axmud::Task::MyTask',
            taskPackageHash             => {},      # Set below
            #
            # Axmud keeps some shorthand forms ('labels') of the standard/external tasks for the
            #   user to type - one for standard tasks (e.g. 'tasklist', 'stat') and another for all
            #   tasks (max length 32 characters)
            #
            # Constant registry hash of task labels (these values never change). A hash in the form
            #   $constTaskLabelHash{label} = task_standard_name
            constTaskLabelHash          => {
                'adv'                   => 'advance_task',
                'advance'               => 'advance_task',
                'att'                   => 'attack_task',
                'attack'                => 'attack_task',
                'chan'                  => 'channels_task',
                'channel'               => 'channels_task',
                'channels'              => 'channels_task',
                'chat'                  => 'chat_task',
                'comp'                  => 'compass_task',
                'compass'               => 'compass_task',
                'cond'                  => 'condition_task',
                'condition'             => 'condition_task',
                'conn'                  => 'connections_task',
                'connect'               => 'connections_task',
                'connections'           => 'connections_task',
                'cd'                    => 'countdown_task',
                'count'                 => 'countdown_task',
                'countdown'             => 'countdown_task',
                'div'                   => 'divert_task',
                'divert'                => 'divert_task',
                'frame'                 => 'frame_task',
                'inv'                   => 'inventory_task',
                'invent'                => 'inventory_task',
                'inventory'             => 'inventory_task',
                'launch'                => 'launch_task',
                'launcher'              => 'launch_task',
                'loc'                   => 'locator_task',
                'locator'               => 'locator_task',
                'mc'                    => 'map_check_task',
                'map'                   => 'map_check_task',
                'mapcheck'              => 'map_check_task',
                'note'                  => 'notepad_task',
                'notes'                 => 'notepad_task',
                'notepad'               => 'notepad_task',
                'raw'                   => 'raw_text_task',
                'rawtext'               => 'raw_text_task',
                'token'                 => 'raw_token_task',
                'rawtoken'              => 'raw_token_task',
                'scr'                   => 'script_task',
                'script'                => 'script_task',
                'stat'                  => 'status_task',
                'status'                => 'status_task',
                'sys'                   => 'system_task',
                'system'                => 'system_task',
                'task'                  => 'tasklist_task',
                'tasks'                 => 'tasklist_task',
                'tasklist'              => 'tasklist_task',
                'watch'                 => 'watch_task',
            },
            # Customisable registry hash of task labels, in the form
            #   $taskLabelHash{label} = task_standard_name
            taskLabelHash               => {},      # [tasks] Set below
            #
            # Sometimes one type of task needs to run before, or after, other types of task
            # This list of tasks is run before any others. If there are two or more copies of a
            #   task type running and they appear on the list, they will run together, one after the
            #   other, before others types of task
            # There are two runlists - a list of tasks to run FIRST, and a list of tasks to be
            #   run LAST. Every item on the runlist must be the task's formal name, ->name
            #
            # The constant task runlists (these values never change)
            constTaskRunFirstList       => [
                'status_task',      # First task on list is the first to be run
                'locator_task'
            ],
            constTaskRunLastList        => [
                'tasklist_task',    # First task on list the last to be run
            ],
            # User-customisable task runlists
            taskRunFirstList            => [],      # [tasks] Set below
            taskRunLastList             => [],      # [tasks] Set below
            #
            # Counts used for giving unique names to tasks (not used for custom tasks)
            # How many tasks have been started in total, across all sessions. Reset to 0 whenever
            #   Axmud starts
            taskTotal                   => 0,

            # Registry hash of tasks that start in every session (when the character has logged in)
            #   - the 'global initial tasklist' (each profile also has its own initial tasklist).
            #   Hash in the form
            #   $initTaskHash{unique_task_name} = blessed_reference_to_task_object
            initTaskHash                => {},      # [tasks]
            # The order in which the tasks are started (not very important for tasks unless they
            #   are Script tasks). List contains all the keys in $self->initTaskHash
            initTaskOrderList           => [],      # [tasks]
            # How many (global) initial tasks have been created in total. Reset to 0 only if a
            #   config file is being created (or if the global initial tasklist becomes empty)
            initTaskTotal               => 0,       # [tasks]

            # Registry hash of customised tasks - the 'custom tasklist'. Each has a unique name
            #   (max 16 chars, no reserved names) which the user can choose freely
            #   ->customTaskHash{custom_task_name} = blessed_reference_to_task_object
            customTaskHash              => {},      # [tasks]

            # Tasks have two types of IV - task settings (standard IVs for all tasks), and task
            #   parameters (different IVs for all types of task)
            # Constant hash of task IVs that are task settings, not task parameters
            constTaskSettingsHash       => {
                'session'               => undef,
                'name'                  => undef,
                'prettyName'            => undef,
                'uniqueName'            => undef,
                'shortName'             => undef,
                'customName'            => undef,
                'category'              => undef,
                'descrip'               => undef,
                'taskType'              => undef,
                'profName'              => undef,
                'profCategory'          => undef,
                'shortCutIV'            => undef,
                'jealousyFlag'          => undef,
                'requireLocatorFlag'    => undef,
                'profSensitivityFlag'   => undef,
                'storableFlag'          => undef,
                'startTime'             => undef,
                'checkTime'             => undef,
                'endStatus'             => undef,
                'endTime'               => undef,
                'waitForTask'           => undef,
                'delayTime'             => undef,
                'shutdownFlag'          => undef,
                'status'                => undef,
                'resumeStatus'          => undef,
                'activeFlag'            => undef,
                'stage'                 => undef,
                'allowWinFlag'          => undef,
                'requireWinFlag'        => undef,
                'startWithWinFlag'      => undef,
                'winPreferList'         => undef,
                'winObj'                => undef,
                'tableObj'              => undef,
                'taskWinFlag'           => undef,
                'taskWinEntryFlag'      => undef,
                'winmap'                => undef,
                'winUpdateFunc'         => undef,
                'defaultTabObj'         => undef,
                'monochromeFlag'        => undef,
                'noScrollFlag'          => undef,
                'ttsFlag'               => undef,
                'ttsConfig'             => undef,
                'ttsAttribHash'         => undef,
                'ttsFlagAttribHash'     => undef,
                'ttsAlertAttribHash'    => undef,
            },
            # Constant hash of permissible values for a task's ->status IV
            constTaskStatusHash         => {
                'no_exist'              => undef,
                'wait_init'             => undef,
                'wait_task_exist'       => undef,
                'wait_task_no_exist'    => undef,
                'wait_task_start_stop'  => undef,
                'running'               => undef,
                'paused'                => undef,
                'finished'              => undef,
                'reset'                 => undef,
            },

            # Scripts
            # -------

            # Registry hash of directories inside which Axbasic scripts are stored. When an Axbasic
            #   script needs to be loaded, the '/data/scripts' directory is first checked; then
            #   every directory in this list is checked, in order. The first directory which
            #   contains an Axbasic script with the right name is loaded
            scriptDirList               => [],      # [scripts]
            # Registry hash of scripts that start in every session (when the character has logged
            #   in) - the 'global initial scriptlist' (each profile also has its own initial
            #   scriptlist) Hash in the form
            #       $initScriptHash{script_name} = mode
            # ...where 'script_name' matches the file from which the script is loaded, and 'mode' is
            #   set to one of the following values:
            #       'no_task'       - run the script without a task
            #       'run_task'      - run the script from within a task
            #       'run_task_win'  - run the script from within a task, in 'forced window' mode
            initScriptHash              => {},      # [scripts]
            # The order in which the scripts are started. List contains all the keys in
            #   $self->initScriptHash
            initScriptOrderList         => [],      # [scripts]

            # World model
            # -----------

            # Constant hash of valid model object types (all of which inherit from
            #   GA::Generic::ModelObj; the type matches the object's ->category IV). Hash in the
            #   form
            #   $constModelTypeHash{type} = undef;
            constModelTypeHash          => {
                'region'                => undef,
                'room'                  => undef,
                'weapon'                => undef,
                'armour'                => undef,
                'garment'               => undef,
                'char'                  => undef,
                'minion'                => undef,
                'sentient'              => undef,
                'creature'              => undef,
                'portable'              => undef,
                'decoration'            => undef,
                'custom'                => undef,
            },
            # Constant list of standard primary directions, in a fixed order
            constPrimaryDirList         => [
                'north',
                'northnortheast',
                'northeast',
                'eastnortheast',
                'east',
                'eastsoutheast',
                'southeast',
                'southsoutheast',
                'south',
                'southsouthwest',
                'southwest',
                'westsouthwest',
                'west',
                'westnorthwest',
                'northwest',
                'northnorthwest',
                'up',
                'down',
            ],
            # Constant list of standard primary directions, but with the secondary-intercardinal
            #   directions removed
            constShortPrimaryDirList    => [
                'north',
                'northeast',
                'east',
                'southeast',
                'south',
                'southwest',
                'west',
                'northwest',
                'up',
                'down',
            ],
            # Constant hash of standard primary directions, but with the secondary-intercardinal
            #   directions removed
            constShortPrimaryDirHash    => {
                'north'                 => undef,
                'northeast'             => undef,
                'east'                  => undef,
                'southeast'             => undef,
                'south'                 => undef,
                'southwest'             => undef,
                'west'                  => undef,
                'northwest'             => undef,
                'up'                    => undef,
                'down'                  => undef,
            },
            # Constant hash of standard primary directions and their opposites (used mostly by the
            #   automapper functions). Hash in the form
            #   $constOppDirHash{standard_direction} = opposite_standard_direction
            constOppDirHash             => {
                'north'                 => 'south',
                'northnortheast'        => 'southsouthwest',
                'northeast'             => 'southwest',
                'eastnortheast'         => 'westsouthwest',
                'east'                  => 'west',
                'eastsoutheast'         => 'westnorthwest',
                'southeast'             => 'northwest',
                'southsoutheast'        => 'northnorthwest',
                'south'                 => 'north',
                'southsouthwest'        => 'northnortheast',
                'southwest'             => 'northeast',
                'westsouthwest'         => 'eastnortheast',
                'west'                  => 'east',
                'westnorthwest'         => 'eastsoutheast',
                'northwest'             => 'southeast',
                'northnorthwest'        => 'southsoutheast',
                'up'                    => 'down',
                'down'                  => 'up',
            },
            # Constant registry list of room statement component types (matching
            #   GA::Obj::Component->type)
            constComponentTypeList      => [
                'anchor',
                'verb_title', 'verb_descrip', 'verb_exit', 'verb_content', 'verb_special',
                'brief_title', 'brief_exit', 'brief_title_exit', 'brief_exit_title',
                'brief_content',
                'room_cmd',
                'mudlib_path',
                'weather',
                'ignore_line',
                'custom',
            ],
            # Constant hash of exit states (acceptable values for GA::Obj::Exit->exitState)
            # NB This hash doesn't include 'ignore', or any custom strings specified by
            #   GA::Profile::World->exitStateTagHash
            # NB For an explanation of what each value means, see the comments in GA::Obj::Exit->new
            constExitStateHash          => {
                'normal'                => undef,
                'open'                  => undef,
                'closed'                => undef,
                'locked'                => undef,
                'secret'                => undef,
                'secret_open'           => undef,
                'secret_closed'         => undef,
                'secret_locked'         => undef,
                'impass'                => undef,
                'dark'                  => undef,
                'danger'                => undef,
                'emphasis'              => undef,
                'other'                 => undef,
#               'ignore'                => undef,
            },
            # Object parsing sanity check (in case someone creates a room containing a billion
            #   hobbits) - maximum number of world model objects created in response by
            #   GA::Obj::WorldModel->parseObj()
            # (The 999 value communicates to the user that the number has been reduced)
            constParseObjMax            => 999,

            # Logging
            # -------

            # Axmud can log to several different logfiles, all of which are in the /logs
            #   directory and its sub-directories (in the Axmud data directory, $DATA_DIR)
            #
            # Two logfiles are stored in the /logs directory itself:
            #   'main'      - Logs everything displayed in the 'main' window, across all sessions
            #   'errors'    - Logs all kinds of system error message (including debug, warning and
            #                   improper argument messages) across all sessions
            # Several logfiles are stored in /logs/standard:
            #   'system'    - Logs every system message (from GA::Obj::TextView->showSystemText)
            #                   across all sessions
            #   'error'     - Logs every system error message (from GA::Obj::TextView->showError)
            #                   across all sessions
            #   'warning'   - Logs every system warning message (from
            #                   GA::Obj::TextView->showWarning) across all sessions
            #   'debug'     - Logs every system debug message (from GA::Obj::TextView->showDebug)
            #                   across all sessions
            #   'improper'  - Logs every system 'improper arguments' message (from
            #                   GA::Obj::TextView->showImproper) across all sessions
            # Several logfiles are stored in /logs/<current_world> by a GA::Session:
            #   'receive'   - Logs all text received from the world in .../receive. Unlike other
            #                   logfiles, lines of text are not split by splitter triggers or
            #                   recognised command prompts. If $self->logImageFlag is TRUE, the
            #                   text also records processed images
            #   'display'   - Logs all text received from the world after it's been modified by any
            #                   matching rewriter triggers (if any) in .../display
            #   'rooms'     - Logs all room statements processed by the Locator task in .../rooms
            #   'descrips'  - Logs all room descriptions processed by the Locator task in
            #                   .../descrips
            #   'contents'  - Logs all room contents strings processed by the Locator task in
            #                   .../contents
            #   'attack'    - Logs all attacks processed by the Attack task in .../attacks
            #   'divert'    - Logs all text processed by the Divert task in .../divert
            #   'chat'      - Logs all conversations with chat contacts in ../chat
            # Several logfiles are written to /logs/<current_world> by the Status task, when it
            #   detects certain events:
            #   'sleep'     - Logs lines leading up to the character falling asleep
            #   'passout'   - Logs lines leading up to the character passing out
            #   'dead'      - Logs lines leading up to the character's death
            #
            # Constant registry hash of the logfiles written by GA::Client, and whether they should
            #   be written, in the form
            #   $constLogPrefHash{log_file_type} = TRUE or FALSE
            constLogPrefHash            => {
                'main'                  => FALSE,
                'errors'                => TRUE,
                'system'                => FALSE,
                'error'                 => TRUE,
                'warning'               => TRUE,
                'debug'                 => TRUE,
                'improper'              => TRUE,
            },
            # Registry hash of current log-writing preferences, in the form
            #   $logPrefHash{type} = TRUE or FALSE
            logPrefHash                 => {},          # [config] Set below
            # Constant registry hash of the logfiles written by individual GA::Session objects, and
            #   whether they should be written, in the form
            #   $constLogSessionPrefHash{log_file_type} = TRUE or FALSE
            # Used to initialise ->logPrefHash in GA::Profile::World
            constSessionLogPrefHash     => {
                'receive'               => FALSE,
                'display'               => TRUE,
                'rooms'                 => TRUE,
                'descrips'              => TRUE,
                'contents'              => TRUE,
                'attack'                => FALSE,
                'channels'              => TRUE,
                'chat'                  => TRUE,
                'divert'                => TRUE,
                'sleep'                 => TRUE,
                'passout'               => TRUE,
                'dead'                  => TRUE,
            },
            # A list of GA::Session logfiles in a standard order, for use in the world profile's
            #   'edit' window
            constSessionLogOrderList    => [
                'receive', 'display', 'rooms', 'descrips','contents', 'attack', 'channels', 'chat',
                'divert', 'sleep', 'passout', 'dead',
            ],

            # Parallel hash of short descriptions for each type of logfile, for use in the
            #   client's 'pref' window and the world profile's 'edit' window
            constLogDescripHash         => {
                # GA::Client
                'main'
                    => 'Logs everything displayed in the \'main\' window, across all sessions',
                'errors'
                    => 'Logs all kinds of system error message (including debug/warning, etc)',
                'system'
                    => 'Logs every system message shown in the \'main\' window',
                'error'
                    => 'Logs every system error message shown in the \'main\' window',
                'warning'
                    => 'Logs every system warning message shown in the \'main\' window',
                'debug'
                    => 'Logs every system debug message shown in the \'main\' window',
                'improper'
                    => 'Logs every system \'improper arguments\' message shown in the \'main\''
                            . ' window',
                # GA::Session and its tasks
                'receive'
                    => 'Logs all text received from the world',
                'display'
                    => 'Logs all text received after any modifications from matching triggers',
                'rooms'
                    => 'Logs all room statements processed by the Locator task',
                'descrips'
                    => 'Logs all room descriptions processed by the Locator task',
                'contents'
                    => 'Logs all room contents strings processed by the Locator task',
                'attack'
                    => 'Logs all attacks processed by the Attack task',
                'channels'
                    => 'Logs all text processed by the Channels task',
                'chat'
                    => 'Logs all conversations with chat contacts',
                'divert'
                    => 'Logs all text processed by the Divert task',
                'sleep'
                    => 'Logs lines leading up to the character falling asleep',
                'passout'
                    => 'Logs lines leading up to the character passing out',
                'dead'
                    => 'Logs lines leading up to the character\'s death',
            },
            # A list of logfiles in a standard order, for use in the client's 'pref' window
            constLogOrderList           => [
                'main', 'errors', 'system', 'error', 'warning', 'debug', 'improper',
            ],
            # Constant registry hash of paths for each logfile, relative to the Axmud data
            #   directory, in the form
            #   $constLogPathHash{type} = path_relative_to_data_directory
            constLogPathHash            => {
                'main'                  => '/logs/main',
                'errors'                => '/logs/errors',
                'system'                => '/logs/standard/system',
                'error'                 => '/logs/standard/error',
                'warning'               => '/logs/standard/warning',
                'debug'                 => '/logs/standard/debug',
                'improper'              => '/logs/standard/improper',
            },
            # Flag set to TRUE if logging is enabled, FALSE if logging is disabled
            allowLogsFlag               => FALSE,       # [config]
            # Flag set to TRUE if the logfiles listed above should be deleted whenever the Axmud
            #   client starts, FALSE if not
            deleteStandardLogsFlag      => FALSE,       # [config]
            # Flag set to TRUE if the logfiles relating to a particular world (listed in
            #   GA::Session) should be deleted whenever the world is a current world
            deleteWorldLogsFlag         => FALSE,       # [config]
            #
            # The following flags apply to the logfiles listed above, and those specified in
            #   GA::Session
            # Flag set to TRUE if a new logfile should be started on every distinct date, FALSE if
            #   not
            logDayFlag                  => TRUE,        # [config]
            # Flag set to TRUE if a new logfile should be started when the Axmud client starts
            logClientFlag               => TRUE,        # [config]
            # Flag set to TRUE if every line in a log should be prefixed by the date, FALSE if not
            logPrefixDateFlag           => TRUE,        # [config]
            # Flag set to TRUE if every line in a log should be prefixed by the time, FALSE if not
            logPrefixTimeFlag           => TRUE,        # [config]
            # Flag set to TRUE if images should be included in 'receive' logfile (only), FALSE if
            #   not
            logImageFlag                => FALSE,       # [config]
            #
            # String to add a the beginning of every logfile (for example, to add a copyright
            #   message, or to identify the user). Can contain one or more strings, as well as empty
            #   strings (for spacing). If an empty list, a preamble isn't used
            logPreambleList             => [],          # [config]

            # The 'sleep', 'passout' and 'dead' logfiles are written by the Status task, which
            #   attempts to write lines of text received from the world before and after the event.
            #   If the value is 0, no lines are written before/after the event. Otherwise, write
            #   the number of lines specified by the IV (max: 999)
            statusEventBeforeCount      => 200,         # [config]
            statusEventAfterCount       => 50,          # [config]

            # Chat
            # ----

            # The Chat task is an instant messenger using the zChat/MudMaster chat protocols. The
            #   Client stores some IVs used by all chat sessions
            #
            # The user's chat name. If 'undef', the current character's name is used in chat
            #   sessions
            chatName                    => undef,       # [contacts]
            # Chat email, broadcast during sessions using the zChat protocol. If 'undef', not
            #   broadcast
            chatEmail                   => undef,       # [contacts]
            # The default port for incoming chat connections (should not be modified)
            constChatPort               => 4050,
            # Should incoming calls be auto-accepted? ('prompt' - no, prompt the user first,
            #   'accept_contact' - auto-accept calls from people in your chat contact list,
            #   'accept_all' - auto-accept calls from everyone)
            chatAcceptMode              => 'prompt',    # [contacts]
            # Registry hash of GA::Obj::ChatContact objects in the form
            #   $chatContactHash{unique_name} = blessed_reference_to_chat_contact_object
            chatContactHash             => {},          # [contacts]
            #
            # Path to the default icon broadcast to chat contacts during chat sessions (relative to
            #   the Axmud base directory)
            constChatIcon               => 'icons/system/default_chat.bmp',
            # Path to the icon currently broadcast to chat contacts during chat sessions (absolute
            #   path)
            chatIcon                    => $axmud::SHARE_DIR . '/icons/system/default_chat.bmp',
                                                        # [contacts]
            # Path to the default icon used if the chat contact does not broadcast their own during
            #   chat sessions (relative to the Axmud base directory)
            constChatContactIcon        => 'icons/system/default_contact.bmp',
            # Constant registry hash of paths to smiley icons (these values never changes). The
            #   smileys themselves are strings, not regexes. Hash in the form
            #       $constChatSmileyHash{smiley} = path_to_file
            # NB Maximum smiley size is 8 characters
            constChatSmileyHash         => {
                # Happy
                ':)'                    => $axmud::SHARE_DIR . '/icons/smileys/emotion_smile.bmp',
                ':-)'                   => $axmud::SHARE_DIR . '/icons/smileys/emotion_smile.bmp',
                # Laughing
                ':D'                    => $axmud::SHARE_DIR . '/icons/smileys/emotion_haha.bmp',
                ':-D'                   => $axmud::SHARE_DIR . '/icons/smileys/emotion_haha.bmp',
                # Sad
                ':('                    => $axmud::SHARE_DIR . '/icons/smileys/emotion_sad.bmp',
                ':-('                   => $axmud::SHARE_DIR . '/icons/smileys/emotion_sad.bmp',
                # Winky frowny
                ';('                    => $axmud::SHARE_DIR
                                                . '/icons/smileys/emotion_misdoubt.bmp',
                # Angry
                ':@'                    => $axmud::SHARE_DIR . '/icons/smileys/emotion_mad.bmp',
                '>:('                   => $axmud::SHARE_DIR . '/icons/smileys/emotion_mad.bmp',
                # Crying
                ":'("                   => $axmud::SHARE_DIR . '/icons/smileys/emotion_too_sad.bmp',
                ":'-("                  => $axmud::SHARE_DIR . '/icons/smileys/emotion_too_sad.bmp',
                # Horror
                'D:'                    => $axmud::SHARE_DIR . '/icons/smileys/emotion_horror.bmp',
                'D:<'                   => $axmud::SHARE_DIR . '/icons/smileys/emotion_horror.bmp',
                # Shock
                ':O'                    => $axmud::SHARE_DIR . '/icons/smileys/emotion_shocked.bmp',
                ':-O'                   => $axmud::SHARE_DIR . '/icons/smileys/emotion_shocked.bmp',
                # Kiss
                ':*'                    => $axmud::SHARE_DIR . '/icons/smileys/emotion_kiss.bmp',
                # Wink
                ';)'                    => $axmud::SHARE_DIR . '/icons/smileys/emotion_wink.bmp',
                ';-)'                   => $axmud::SHARE_DIR . '/icons/smileys/emotion_wink.bmp',
                # Tongue sticking out
                ':P'                    => $axmud::SHARE_DIR . '/icons/smileys/emotion_tongue.bmp',
                ':-P'                   => $axmud::SHARE_DIR . '/icons/smileys/emotion_tongue.bmp',
                # Straight face
                ':|'                    => $axmud::SHARE_DIR . '/icons/smileys/emotion_what.bmp',
                ':-|'                   => $axmud::SHARE_DIR . '/icons/smileys/emotion_what.bmp',
                # Embarrassed
                ':$'                    => $axmud::SHARE_DIR . '/icons/smileys/emotion_red.bmp',
                # Angel
                'O:-)'                  => $axmud::SHARE_DIR . '/icons/smileys/emotion_angel.bmp',
                # Evil
                '>:)'                   => $axmud::SHARE_DIR
                                                . '/icons/smileys/emotion_evilgrin.bmp',
                # Devilish
                '}:)'                   => $axmud::SHARE_DIR . '/icons/smileys/emotion_devil.bmp',
                '}:-)'                  => $axmud::SHARE_DIR . '/icons/smileys/emotion_devil.bmp',
                # Heart
                '<3'                    => $axmud::SHARE_DIR . '/icons/smileys/emotion_love.bmp',
            },
            # Registry hash of paths to smiley icons
            chatSmileyHash              => {},          # [contacts] Set below

            # Colour tags
            # -----------

            # Axmud Colour tags - a standard colour scheme which allows Axmud's textvies to use the
            #   same colour set as other telnet clients
            #
            # Axmud uses three sets of colour tags:
            #   - (Standard) colour tags used to show ANSI colours (e.g. 'red', 'BLUE'). To specify
            #       an underlay colour, precede the string with 'ul_' or 'UL_'
            #   - Xterm colour tags used to show xterm-256 colours (e.g. 'x0', 'x255'). To specify
            #       an underlay colour, use a string in the range 'ux0' to 'ux255'. Xterm colour
            #       tags are case-insensitive, so it's safe to specify 'X0' or 'UX255'
            #   - RGB colour tags used to show RGB colours (e.g. '#000000', '#FFFFFF'). To specify
            #       an underlay colour, use a string in the range 'u#000000' to 'u#FFFFFF'. RGB
            #       colour tags are case-insensitive, so it's safe to specify 'U#00000' or
            #       'U#AbCdEf'
            # Standard and xterm colour tags are converted into RGB colour tags, before being used
            #
            # Standard colour tags have all-upper case or all-lower case names. Upper-case names are
            #   used for bold colours. In addition, each standard tag can be preceded by 'ul_' (or
            #   'UL_' for bold colours) to show that the tag is an underlay colour, not a text
            #   colour.
            # e.g. 'BLUE' - bold blue text, 'UL_BLUE' - bold blue underlay text
            #
            # A constant list of standard (normal) colour tags, in a standard order
            # (These values never change, max length: 7 characters; corresponding underlay
            #   characters have a max length of 10)
            constColourTagList          => [
                'black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white',
            ],
            # A list of standard (bold) colour tags, in a standard order
            # (These values never change, max length: 7 characters; corresponding underlay
            #   characters have a max length of 10)
            constBoldColourTagList      => [
                'BLACK', 'RED', 'GREEN', 'YELLOW', 'BLUE', 'MAGENTA', 'CYAN', 'WHITE',
            ],
            #
            # A constant hash of standard (normal) colour tags (these values never change). Hash in
            #   the form
            #   $constColourTag{standard_colour_tag} = rgb_colour_tag
            constColourTagHash          => {
                'black'                 => '#000000',
                'red'                   => '#8B0000',
                'green'                 => '#007300',
                'yellow'                => '#8B6914',
                'blue'                  => '#0000C0',
                'magenta'               => '#8B008B',
                'cyan'                  => '#008B8B',
                'white'                 => '#BEBEBE',
            },
            # A constant hash of standard (bold) colour tags (these values never changes). Hash in
            #   the form
            #   $constBoldColourTagHash{STANDARD_BOLD_COLOUR_TAG} = rgb_colour_tag
            constBoldColourTagHash      => {
                'BLACK'                 => '#5F5F5F',
                'RED'                   => '#FF0000',
                'GREEN'                 => '#00FF00',
                'YELLOW'                => '#FFFF00',
                'BLUE'                  => '#0000FF',
                'MAGENTA'               => '#FF00FF',
                'CYAN'                  => '#00FFFF',
                'WHITE'                 => '#FFFFFF',
            },
            # Customisable hash of standard (normal) colour tags, in the form
            #   $colourTagHash{standard_colour_tag} = rgb_colour_tag
            colourTagHash               => {},     # [config] Set below
            # Customisable hash of standard (bold) colour tags, in the form
            #   $boldColourTagHash{STANDARD_BOLD_COLOUR_TAG} = rgb_colour_tag
            boldColourTagHash           => {},     # [config] Set below
            #
            # A constant hash of background colour tags and suitable text colour tags to use with
            #   them (for the benefit of tasks, or any other code). Hash in the form
            #   $constMonochromeHash{background_colour_tag} = text_colour_tag
            constMonochromeHash         => {
                'black'                 => 'white',
                'red'                   => 'WHITE',
                'green'                 => 'WHITE',
                'yellow'                => 'white',
                'blue'                  => 'WHITE',
                'magenta'               => 'WHITE',
                'cyan'                  => 'WHITE',
                'white'                 => 'black',
                'BLACK'                 => 'WHITE',
                'RED'                   => 'black',
                'GREEN'                 => 'black',
                'YELLOW'                => 'black',
                'BLUE'                  => 'WHITE',
                'MAGENTA'               => 'black',
                'CYAN'                  => 'black',
                'WHITE'                 => 'black',
            },

            # A constant list of 32 rgb colour tags, roughly in rainbow order, for use with the
            #   winmap/zonemap 'edit' windows (these values never change)
            constRainbowColourList      => [
                '#FF0000',  # reds
                '#FF7F00',  # oranges
                '#FFFF00',  # yellows
                '#00CD00',  # greens
                '#0000FF',  # blues
                '#00CDCD',  # cyans
                '#8B008B',  # purples
                '#CDCDBA',  # greys
                '#8B0000',  # cycle repeats...
                '#8B4500',
                '#FFFF7F',
                '#008B00',
                '#00008B',
                '#008B8B',
                '#CD00CD',
                '#8B8B7E',
                '#CD0000',
                '#CD6600',
                '#D8EE21',
                '#00FF00',
                '#7F7FFF',
                '#3FFFFF',
                '#FF00FF',
                '#FF7A7A',
                '#FFBF7F',
                '#EED877',
                '#7FFF7F',
                '#BFFFFF',
                '#C8FFFF',
                '#FF7FFF',
                '#BACDCD',
                '#FFFFFF',  # black
            ],
            # A constant hash of official HTML 4 colour names (in lower-case only), used to
            #   implement MXP colours, in the form
            #       $constHtmlColourHash{html_colour_name} = rgb_colour_tag
            constHtmlColourHash         => {
                # Standard HTML colours
                'white'                 => '#FFFFFF',
                'silver'                => '#C0C0C0',
                'gray'                  => '#808080',
                'black'                 => '#000000',
                'red'                   => '#FF0000',
                'maroon'                => '#800000',
                'yellow'                => '#FFFF00',
                'olive'                 => '#808000',
                'lime'                  => '#00FF00',
                'green'                 => '#008000',
                'aqua'                  => '#00FFFF',
                'teal'                  => '#008080',
                'blue'                  => '#0000FF',
                'navy'                  => '#000080',
                'fuchsia'               => '#FF00FF',
                'purple'                => '#800080',
                # New colours from http://www.gammon.com.au/mushclient/mxpcolours.htm
                #    (replacing any existing keys from above)
                'aliceblue'             => '#f0f8ff',
                'antiquewhite'          => '#FAEBD7',
                'aqua'                  => '#00FFFF',
                'aquamarine'            => '#7FFFD4',
                'azure'                 => '#F0FFFF',
                'beige'                 => '#F5F5DC',
                'bisque'                => '#FFE4C4',
                'black'                 => '#000000',
                'blanchedalmond'        => '#FFEBCD',
                'blue'                  => '#0000FF',
                'blueviolet'            => '#8A2BE2',
                'brown'                 => '#A52A2A',
                'burlywood'             => '#DEB887',
                'cadetblue'             => '#5F9EA0',
                'chartreuse'            => '#7FFF00',
                'chocolate'             => '#D2691E',
                'coral'                 => '#FF7F50',
                'cornflowerblue'        => '#6495ED',
                'cornsilk'              => '#FFF8DC',
                'crimson'               => '#DC143C',
                'cyan'                  => '#00FFFF',
                'darkblue'              => '#00008B',
                'darkcyan'              => '#008B8B',
                'darkgoldenrod'         => '#B8860B',
                'darkgray'              => '#A9A9A9',
                'darkgreen'             => '#006400',
                'darkkhaki'             => '#BDB76B',
                'darkmagenta'           => '#8B008B',
                'darkolivegreen'        => '#556B2F',
                'darkorange'            => '#FF8C00',
                'darkorchid'            => '#9932CC',
                'darkred'               => '#8B0000',
                'darksalmon'            => '#E9967A',
                'darkseagreen'          => '#8DBC8F',
                'darkslateblue'         => '#483D8B',
                'darkslategray'         => '#2F4F4F',
                'darkturquoise'         => '#00DED1',
                'darkviolet'            => '#9400D3',
                'deeppink'              => '#FF1493',
                'deepskyblue'           => '#00BFFF',
                'dimgray'               => '#696969',
                'dodgerblue'            => '#1E90FF',
                'firebrick'             => '#B22222',
                'floralwhite'           => '#FFFAF0',
                'forestgreen'           => '#228B22',
                'fuchsia'               => '#FF00FF',
                'gainsboro'             => '#DCDCDC',
                'ghostwhite'            => '#F8F8FF',
                'gold'                  => '#FFD700',
                'goldenrod'             => '#DAA520',
                'gray'                  => '#808080',
                'green'                 => '#008000',
                'greenyellow'           => '#ADFF2F',
                'honeydew'              => '#F0FFF0',
                'hotpink'               => '#FF69B4',
                'indianred'             => '#CD5C5C',
                'indigo'                => '#4B0082',
                'ivory'                 => '#FFFFF0',
                'khaki'                 => '#F0E68C',
                'lavender'              => '#E6E6FA',
                'lavenderblush'         => '#FFF0F5',
                'lawngreen'             => '#7CFC00',
                'lemonchiffon'          => '#FFFACD',
                'lightblue'             => '#ADD8E6',
                'lightcoral'            => '#F08080',
                'lightcyan'             => '#E0FFFF',
                'lightgoldenrodyellow'  => '#FAFAD2',
                'lightgray'             => '#D3D3D3',
                'lightgreen'            => '#90EE90',
                'lightgrey'             => '#D3D3D3',
                'lightpink'             => '#FFB6C1',
                'lightsalmon'           => '#FFA07A',
                'lightseagreen'         => '#20B2AA',
                'lightskyblue'          => '#87CEFA',
                'lightslategray'        => '#778899',
                'lightsteelblue'        => '#B0C4DE',
                'lightyellow'           => '#FFFFE0',
                'lime'                  => '#00FF00',
                'limegreen'             => '#32CD32',
                'linen'                 => '#FAF0E6',
                'magenta'               => '#FF00FF',
                'maroon'                => '#800000',
                'mediumaquamarine'      => '#66CDAA',
                'mediumblue'            => '#0000CD',
                'mediumorchid'          => '#BA55D3',
                'mediumpurple'          => '#9370DB',
                'mediumseagreen'        => '#3CB371',
                'mediumslateblue'       => '#7B68EE',
                'mediumspringgreen'     => '#00FA9A',
                'mediumturquoise'       => '#48D1CC',
                'mediumvioletred'       => '#C71585',
                'midnightblue'          => '#191970',
                'mintcream'             => '#F5FFFA',
                'mistyrose'             => '#FFE4E1',
                'moccasin'              => '#FFE4B5',
                'navajowhite'           => '#FFDEAD',
                'navy'                  => '#000080',
                'oldlace'               => '#FDF5E6',
                'olive'                 => '#808000',
                'olivedrab'             => '#6B8E23',
                'orange'                => '#FFA500',
                'orangered'             => '#FF4500',
                'orchid'                => '#DA70D6',
                'palegoldenrod'         => '#EEE8AA',
                'palegreen'             => '#98FB98',
                'paleturquoise'         => '#AFEEEE',
                'palevioletred'         => '#DB7093',
                'papayawhip'            => '#FFEFD5',
                'peachpuff'             => '#FFDAB9',
                'peru'                  => '#CD853F',
                'pink'                  => '#FFC8CB',
                'plum'                  => '#DDA0DD',
                'powderblue'            => '#B0E0E6',
                'purple'                => '#800080',
                'red'                   => '#FF0000',
                'rosybrown'             => '#BC8F8F',
                'royalblue'             => '#4169E1',
                'saddlebrown'           => '#8B4513',
                'salmon'                => '#FA8072',
                'sandybrown'            => '#F4A460',
                'seagreen'              => '#2E8B57',
                'seashell'              => '#FFF5EE',
                'sienna'                => '#A0522D',
                'silver'                => '#C0C0C0',
                'skyblue'               => '#87CEEB',
                'slateblue'             => '#6A5ACD',
                'slategray'             => '#708090',
                'snow'                  => '#FFFAFA',
                'springgreen'           => '#00FF7F',
                'steelblue'             => '#4682B4',
                'tan'                   => '#D2B48C',
                'teal'                  => '#008080',
                'thistle'               => '#D8BFD8',
                'tomato'                => '#FF6347',
                'turquoise'             => '#40E0D0',
                'violet'                => '#EE82EE',
                'wheat'                 => '#F5DEB3',
                'white'                 => '#FFFFFF',
                'whitesmoke'            => '#F5F5F5',
                'yellow'                => '#FFFF00',
                'yellowgreen'           => '#9ACD32',
            },
            # For the benefit of MXP gauges (which require three colours - the specified one,
            #   black for the empty portion of the gauge, and a third colour for the label), a
            #   partial hash HTML 4 colours, containing only the standard colours as keys, and
            #   suitable label colours as corresponding values
            constHtmlContrastHash       => {
                # Standard HTML colours
                'white'                 => '#FF0000',
                'silver'                => '#FF0000',
                'gray'                  => '#FF0000',
                'black'                 => '#FFFFFF',
                'red'                   => '#FFFFFF',
                'maroon'                => '#FFFFFF',
                'yellow'                => '#FF0000',
                'olive'                 => '#FFFFFF',
                'lime'                  => '#FFFFFF',
                'green'                 => '#FFFFFF',
                'aqua'                  => '#FFFFFF',
                'teal'                  => '#FFFFFF',
                'blue'                  => '#FFFFFF',
                'navy'                  => '#FFFFFF',
                'fuchsia'               => '#FFFFFF',
                'purple'                => '#FFFFFF',
            },

            # http://www.gammon.com.au/forum/bbshowpost.php?id=7761&page=4
            # To show xterm-256 colours, Axmud supports two colour cubes detailed in the page above:
            #   the xterm colour cube (the default one) and the netscape colour cube
            # Constant hash for the xterm colour cube, converting xterm colour tags (strings in the
            #   range 'x0' - 'x255') into RGB colour tags (strings in range '#000000' - '#FFFFFFF').
            #   Hash in the form
            #       $constXTermColourHash{xterm_colour_tag} = rgb_colour_tag
            # NB This hash doesn't include underlay colours represented by strings in the range
            #   'ux0' - 'ux255'
            constXTermColourHash        => {},                  # Set below
            # Constant hash for the netscape colour cube (in the same form)
            constNetscapeColourHash     => {},
            # Which colour cube is in use at the moment - 'xterm' or 'netscape'
            currentColourCube           => 'xterm',             # [config]
            # The hash currently in use (copied from one of the constant hashes above)
            xTermColourHash             => {},

            # http://www.mudpedia.org/mediawiki/index.php/OSC_color_palette
            # A constant hash of colours used in the OSC colour palette, translating a single
            #   hex character in the range 0-9, A-F into a standard colour tag
            constOscPaletteHash         => {
                '0'                     => 'black',
                '1'                     => 'red',
                '2'                     => 'green',
                '3'                     => 'yellow',
                '4'                     => 'blue',
                '5'                     => 'magenta',
                '6'                     => 'cyan',
                '7'                     => 'white',
                '8'                     => 'BLACK',
                '9'                     => 'RED',
                'A'                     => 'GREEN',
                'B'                     => 'YELLOW',
                'C'                     => 'BLUE',
                'D'                     => 'MAGENTA',
                'E'                     => 'CYAN',
                'F'                     => 'WHITE',
            },
            # Flag set to TRUE if using the OSC colour palette is allowed; set to FALSE if OSC
            #   colour palette escape sequences should be ignored
            oscPaletteFlag              => TRUE,                # [config]

            # Style tags
            # ----------

            # A constant list of style tags, in a standard order
            # (These values never change, max length: 16 characters)
            constStyleTagList           => [
                'italics', 'italics_off', 'underline', 'underline_off', 'blink_slow', 'blink_fast',
                'blink_off', 'strike', 'strike_off',  'link', 'link_off', 'justify_left',
                'justify_centre', 'justify_right', 'justify_default',
            ],
            # A constant list of 'dummy' style tags, in a standard order. 'Dummy' style tags affect
            #   the text colour and background colour, so they are converted into colour tags
            #   before the text is displayed on the screen.
            # In practice, an 'mxpf_font' tag is always used in a modified form, where 'font' is
            #   substituted for the actual font that MXP requires, e.g. 'mxpf_monospace_bold_12_p5'.
            # However, the 'mxpf_off' tag never changes.
            # The modified string typically contains one or more of the following, separated by
            #   underlines: the font name (e.g. 'monospace'), a font name modifier (e.g. 'bold'),
            #   the font size (e.g. '12') and the pixel spacing above and below the text (used for
            #   MXP HTML headings, e.g. 'p5'; when not specified, a spacing of 0 is used)
            # Also, an 'mxpm_mode' tag is always used in a modified form, where 'mode' is
            #   substituted for a value in the range 10-12, 19, 20-99. Since these MXP modes apply
            #   to a whole single line, there is no 'mxpm_off' tag
            # (These values never change, max length: 16 characters)
            constDummyTagList           => [
                'bold', 'bold_off', 'reverse', 'reverse_off', 'conceal', 'conceal_off',
                    'mxpf_font', 'mxpf_off', 'mxpm_mode', 'attribs_off',
            ],

            # A constant hash of style tags (these values never change). Hash in the form
            #   $constStyleTagHash{tag_name} = undef
            constStyleTagHash           => {
                'italics'               => undef,
                'italics_off'           => undef,
                'underline'             => undef,
                'underline_off'         => undef,
                'blink_slow'            => undef,
                'blink_fast'            => undef,
                'blink_off'             => undef,
                'strike'                => undef,
                'strike_off'            => undef,
                'link'                  => undef,
                'link_off'              => undef,
                'justify_left'          => undef,
                'justify_centre'        => undef,
                'justify_right'         => undef,
                'justify_default'       => undef,
            },
            # Constant hash of justification style tags for quick lookup
            constJustifyTagHash         => {
                'justify_left'          => undef,
                'justify_centre'        => undef,
                'justify_right'         => undef,
                'justify_default'       => undef,
            },
            # Constant hash of 'dummy' style tags for quick lookup
            constDummyTagHash           => {
                'bold'                  => undef,
                'bold_off'              => undef,
                'reverse'               => undef,
                'reverse_off'           => undef,
                'conceal'               => undef,
                'conceal_off'           => undef,
                'mxpf_font'             => undef,
                'mxpf_off'              => undef,
                'mxpm_mode'             => undef,
                'attribs_off'           => undef,
            },

            # ANSI escape sequences
            # ---------------------

            # Constant hashes which help Axmud interpret ANSI escape sequences in text received from
            #   the world

            # A constant hash of colours, mapping the value in an 'Esc[Value;...;Valuem' escape
            #   sequence into a standard colour tag
            constANSIColourHash         => {
                30                      => 'black',
                31                      => 'red',
                32                      => 'green',
                33                      => 'yellow',
                34                      => 'blue',
                35                      => 'magenta',
                36                      => 'cyan',
                37                      => 'white',
                40                      => 'ul_black',
                41                      => 'ul_red',
                42                      => 'ul_green',
                43                      => 'ul_yellow',
                44                      => 'ul_blue',
                45                      => 'ul_magenta',
                46                      => 'ul_cyan',
                47                      => 'ul_white',
            },
            # A constant hash of styles, mapping the value in an 'Esc[Value;...;Valuem' escape
            #   sequence onto a style tag
            # NB 1 (bold) and 22 (bold off) are implemented without using (real) style tags, but
            #   instead with the 'dummy' style tags 'bold' and 'bold_off'
            # NB 7 (reverse video on) and 27 (reverse video off) are implemented using the 'dummy'
            #   style tags 'reverse' and 'reverse_off'
            # NB 8 (conceal on) and 28 (conceal off) are implemented using the 'dummy' style tags
            #   'conceal' and 'conceal_off'
            # NB The style tags 'link_on' and 'link_off' are implemented solely within Axmud and do
            #   not correspond to an ANSI escape sequence
            # NB 39 (default text colour) and 49 (default underlay colour) are implemented by
            #   converting them into an Axmud colour tag
            constANSIStyleHash          => {
                3                       => 'italics',
                4                       => 'underline',
                5                       => 'blink_slow',
                6                       => 'blink_fast',
                9                       => 'strike',        # Actually 'Crossed out'
                23                      => 'italics_off',
                24                      => 'underline_off',
                25                      => 'blink_off',
                29                      => 'strike_off',    # Actually 'Not crossed out'
            },

            # A constant list of standard colour/style tags stored in the GA::Buffer::Display
            #   object for each received line, in a standard order (compiled by
            #   GA::Session->convertANSISequences)
            constColourStyleList        => [
                'black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white',
                'ul_black', 'ul_red', 'ul_green', 'ul_yellow', 'ul_blue', 'ul_magenta', 'ul_cyan',
                    'ul_white',
                'italics', 'italics_off', 'underline', 'underline_off', 'blink_slow', 'blink_fast',
                    'blink_off', 'strike', 'strike_off', 'link', 'link_off', 'justify_left',
                    'justify_centre', 'justify_right', 'justify_default',
                # 'Dummy' style tags
                'bold', 'bold_off', 'reverse', 'reverse_off', 'conceal', 'conceal_off',
                    'mxpf_font', 'mxpf_off', 'mxpm_mode', 'attribs_off',
            ],
            # A constant hash of nicer names for standard colour/style tags. The keys are all the
            #   values in $self->constColourStyleList; the values are more descriptive names for
            #   them
            constPrettyTagHash          => {
                # Colour tags
                'black'                 => 'Black text',
                'red'                   => 'Red text',
                'green'                 => 'Green text',
                'yellow'                => 'Yellow text',
                'blue'                  => 'Blue text',
                'magenta'               => 'Magenta text',
                'cyan'                  => 'Cyan text',
                'white'                 => 'White text',
                'ul_black'              => 'Black underlay',
                'ul_red'                => 'Red underlay',
                'ul_green'              => 'Green underlay',
                'ul_yellow'             => 'Yellow underlay',
                'ul_blue'               => 'Blue underlay',
                'ul_magenta'            => 'Magenta underlay',
                'ul_cyan'               => 'Cyan underlay',
                'ul_white'              => 'White underlay',
                # Style tags
                'italics'               => 'Turn on italics',
                'italics_off'           => 'Turn off italics',
                'underline'             => 'Turn on underline',
                'underline_off'         => 'Turn off underline',
                'blink_slow'            => 'Turn on slow blink',
                'blink_fast'            => 'Turn on fast blink',
                'blink_off'             => 'Turn off slow/fast blink',
                'strike'                => 'Turn on strike-through',
                'strike_off'            => 'Turn off strike-through',
                'link'                  => 'Clickable link',
                'link_off'              => 'End of clickable link',
                'justify_left'          => 'Left justification for text',
                'justify_centre'        => 'Centre justification for text',
                'justify_right'         => 'Right justification for text',
                'justify_default'       => 'Default justification for text',
                # Dummy style tags
                'bold'                  => 'Turn on bold colours',
                'bold_off'              => 'Turn off bold colours',
                'reverse'               => 'Turn on reverse video',
                'reverse_off'           => 'Turn off reverse video',
                'conceal'               => 'Turn on conceal',
                'conceal_off'           => 'Turn off conceal',
                'mxpf_font'             => 'Turn on MXP font attributes',
                'mxpf_off'              => 'Turn off MXP font attributes',
                'mxpm_mode'             => 'Apply an MXP line mode',
                'attribs_off'           => 'Turn off all attributes',
            },
            # 'Set Graphics Mode' ANSI escape sequences in text received from the world apply
            #   until the next occurence of that sequence. Each GA::Session needs to keep track of
            #   which graphic modes apply right now in the session's current textview object
            # Constant hash of graphics modes (these values never change, and are used to initialise
            #   comparable hashes in GA::Session and GA::Obj::TextView)
            constColourStyleHash        => {
                # Colour tags - when set to 'undef', the default colours are used. Standard or xterm
                #   colour tags, but not RGB colour tags
                text                    => undef,       # Axmud colour tag, e.g. 'red' or 'x230'
                underlay                => undef,       # Axmud underlay colour tag, e.g. 'ul_white'
                # Style tags
                italics                 => FALSE,
                underline               => FALSE,
                blink_slow              => FALSE,
                blink_fast              => FALSE,
                strike                  => FALSE,
                link                    => FALSE,
                # MXP font tags (which are dummy style tags)
                mxp_font                => undef,       # e.g. 'mxpf_monospace_bold_12', or 'undef'
                # Justification
                justify                 => undef,       # 'left', 'right', 'centre' or 'undef' to
                                                        #   represent style tag 'justify_default'
            },

            # Telnet options and mud protocols
            # --------------------------------

            # Constant hash of telnet negotiation descriptors
            constTelnetHash             => {
                # TELNET_
                'TELNET_IS'             => 0,
                'TELNET_SEND'           => 1,
                'TELNET_SE'             => 240,
                'TELNET_GA'             => 249,
                'TELNET_SB'             => 250,
                'TELNET_WILL'           => 251,
                'TELNET_WONT'           => 252,
                'TELNET_DO'             => 253,
                'TELNET_DONT'           => 254,
                'TELNET_IAC'            => 255,
                # TELOPT_
                'TELOPT_ECHO'           => 1,
                'TELOPT_SGA'            => 3,       # Implemented directly by GA::Obj::Telnet
                'TELOPT_TTYPE'          => 24,
                'TELOPT_EOR'            => 25,
                'TELOPT_NAWS'           => 31,
                'TELOPT_NEW_ENVIRON'    => 39,
                'TELOPT_CHARSET'        => 42,
                'TELOPT_MSDP'           => 69,
                'TELOPT_MSSP'           => 70,
                'TELOPT_MCCP1'          => 85,
                'TELOPT_MCCP2'          => 86,
                'TELOPT_MSP'            => 90,
                'TELOPT_MXP'            => 91,
                'TELOPT_ZMP'            => 93,
                'TELOPT_AARD102'        => 102,
                'TELOPT_ATCP'           => 200,
                'TELOPT_GMCP'           => 201,
                # MSDP
                'MSDP_VAR'              => 1,
                'MSDP_VAL'              => 2,
                'MSDP_TABLE_OPEN'       => 3,
                'MSDP_TABLE_CLOSE'      => 4,
                'MSDP_ARRAY_OPEN'       => 5,
                'MSDP_ARRAY_CLOSE'      => 6,
                # MSSP
                'MSSP_VAR'              => 1,
                'MSSP_VAL'              => 2,
            },
            # Constant hash of telopts
            constTeloptHash             => {
                1                       => 'TELOPT_ECHO',
                3                       => 'TELOPT_SGA',
                24                      => 'TELOPT_TTYPE',
                25                      => 'TELOPT_EOR',
                31                      => 'TELOPT_NAWS',
                39                      => 'TELOPT_NEW_ENVIRON',
                42                      => 'TELOPT_CHARSET',
                69                      => 'TELOPT_MSDP',
                70                      => 'TELOPT_MSSP',
                85                      => 'TELOPT_MCCP1',
                86                      => 'TELOPT_MCCP2',
                90                      => 'TELOPT_MSP',
                91                      => 'TELOPT_MXP',
                93                      => 'TELOPT_ZMP',
                102                     => 'TELOPT_AARD102',
                200                     => 'TELOPT_ATCP',
                201                     => 'TELOPT_GMCP',
            },

            # Hashes of HTML heading sizes and spacings, relative to $self->constFontSize,
            #   corresponding to the HTML tags <H1>...<H6>. Used with both MXP and Pueblo
            constHeadingSizeHash        => {
                1                       => 2,       # <H1>
                2                       => 1.5,     # <H2>, etc
                3                       => 1.17,
                4                       => 1,
                5                       => 0.83,
                6                       => 0.67,
            },
            constHeadingSpacingHash     => {
                1                       => 0.67,
                2                       => 0.83,
                3                       => 1,
                4                       => 1.33,
                5                       => 1.67,
                6                       => 2,
            },

            # Telnet option negotiations
            # Use ECHO (http://www.ietf.org/rfc/rfc857.txt)
            useEchoFlag                 => TRUE,        # [config]
            # Use SGA (Suppress Go Ahead - http://www.ietf.org/rfc/rfc858.txt)
            useSgaFlag                  => TRUE,        # [config]
            # Use TTYPE (Terminal type - http://www.ietf.org/rfc/rfc1091.txt)
            useTTypeFlag                => TRUE,        # [config]
            # Use EOR (End Of Record - RFC 885, http://www.ietf.org/rfc/rfc885.txt)
            useEorFlag                  => TRUE,        # [config]
            # Use NAWS (Negotiate About Window Size - RFC 1073, http://www.ietf.org/rfc/rfc1073.txt)
            useNawsFlag                 => TRUE,        # [config]
            # Use NEW-ENVIRON (New Environment option - RFC 1572,
            #   http://www.ietf.org/rfc/rfc1572.txt)
            useNewEnvironFlag           => TRUE,        # [config]
            # Use CHARSET (Character Set and translation - RFC 1073,
            #   http://www.ietf.org/rfc/rfc2066.txt)
            useCharSetFlag              => TRUE,        # [config]

            # MUD protocols
            # Use MSDP (Mud Server Data Protocol - http://tintin.sourceforge.io/msdp/)
            useMsdpFlag                 => TRUE,        # [config]
            # Use MSSP (Mud Server Status Protocol - http://tintin.sourceforge.io/mssp/)
            useMsspFlag                 => TRUE,        # [config]
            # Use MCCP (Mud Client Compression Protocol - http://tintin.sourceforge.io/mccp/). Both
            #   MCCP1 and MCCP2 are supported
            useMccpFlag                 => TRUE,        # [config]
            # Use MSP (Mud Sound Protocol - http://www.zuggsoft.com/zmud/msp.htm)
            useMspFlag                  => TRUE,        # [config]
            # Use MXP (Mud Xtension Protocol - http://www.zuggsoft.com/zmud/mxp.htm)
            useMxpFlag                  => TRUE,        # [config]
            # Use Pueblo - http://pueblo.sourceforge.io/doc/manual/html_standard_elements.html
            # (NB In line with other major MUD clients, Axmud offers only partial Pueblo support)
            usePuebloFlag               => TRUE,        # [config]
            # Use ZMP (Zenith Mud Protocol
            #   - http://discworld.starturtle.net/external/protocols/zmp.html)
            useZmpFlag                  => TRUE,        # [config]
            # Use AARD102 (Aardwolf 102 channel)
            #   - http://www.aardwolf.com/blog/2008/07/10/
            #       telnet-negotiation-control-mud-client-interaction/
            useAard102Flag              => TRUE,        # [config]
            # Use ATCP (Achaea Telnet Client Protocol)
            #   - https://www.ironrealms.com/rapture/manual/files/FeatATCP-txt.html
            useAtcpFlag                 => TRUE,        # [config]
            # Use GMCP (Generic MUD Communication Protocol) - https://www.gammon.com.au/gmcp
            useGmcpFlag                 => TRUE,        # [config]
            # Use MTTS (Mud Terminal Type Standard - http://tintin.sourceforge.io/mtts/)
            useMttsFlag                 => TRUE,        # [config]
            # Use MCP (Mud Client Protocol - http://www.moo.mud.org/mcp/). Only MCP version 2.1 is
            #   supported. Axmud provides the MCP packages 'mcp-negotiate', 'mcp-cord' and
            #   'dns-org-mud-moo-simpleedit'
            useMcpFlag                  => TRUE,        # [config]

            # Constant hash of official MSSP variables
            constMsspVarHash            => {},          # Set below
            # Constant list of official MSSP variables, in a fixed order; items that begin with
            #   a # character are not official variables, but subject headings
            constMsspVarList            => [
                '#Required',
                'NAME',
                'PLAYERS',
                'UPTIME',
                '#Generic',
                'CRAWL DELAY',
                'HOSTNAME',
                'PORT',
                'CODEBASE',
                'CONTACT',
                'CREATED',
                'ICON',
                'IP',
                'LANGUAGE',
                'LOCATION',
                'MINIMUM AGE',
                'WEBSITE',
                '#Categorisation',
                'FAMILY',
                'GENRE',
                'GAMEPLAY',
                'STATUS',
                'GAMESYSTEM',
                'INTERMUD',
                'SUBGENRE',
                '#World',
                'AREAS',
                'HELPFILES',
                'MOBILES',
                'OBJECTS',
                'ROOMS',
                'CLASSES',
                'LEVELS',
                'RACES',
                'SKILLS',
                '#Protocols',
                'ANSI',
                'GMCP',
                'MCCP',
                'MCP',
                'MSDP',
                'MSP',
                'MXP',
                'PUEBLO',
                'UTF-8',
                'VT100',
                'XTERM 256 COLORS',
                '#Commercial',
                'PAY TO PLAY',
                'PAY FOR PERKS',
                '#Hiring',
                'HIRING BUILDERS',
                'HIRING CODERS',
            ],

            # The version of MSP supported by this cleint
            constMspVersion             => '0.3',
            # Flag set to TRUE if Axmud should play several sound triggers at once, FALSE if it
            #   should stop playing the previous sound trigger, if a new sound trigger arrives
            allowMspMultipleFlag        => TRUE,        # [config]
            # Flag set to TRUE if Axmud should allow MSP to download sound files it doesn't already
            #   have, FALSE if not
            allowMspLoadSoundFlag       => TRUE,        # [config]
            # Flag set to TRUE if Axmud should recognise MSP tags in the middle of a line; FALSE if
            #   it should only recognise MSP tags at the beginning of a line
            allowMspFlexibleFlag        => FALSE,       # [config]

            # The version of MXP supported by this client
            constMxpVersion             => '1.0',
            # Hash of all official MXP tags (i.e. tags which cannot be user-defined)
            constMxpOfficialHash        => {
                'ELEMENT'               => undef,
                    'EL'                => undef,
                'ATTLIST'               => undef,
                    'AT'                => undef,
                    'ATT'               => undef,       # The MXP spec uses both <!AT> and <!ATT>
                'ENTITY'                => undef,
                    'EN'                => undef,
                'VAR'                   => undef,
                    'V'                 => undef,
                'TAG'                   => undef,
                'BOLD'                  => undef,
                    'B'                 => undef,
                    'STRONG'            => undef,
                'ITALIC'                => undef,
                    'I'                 => undef,
                    'EM'                => undef,
                'UNDERLINE'             => undef,
                    'U'                 => undef,
                'STRIKEOUT'             => undef,
                    'S'                 => undef,
                'HIGH'                  => undef,
                    'H'                 => undef,
                'COLOR'                 => undef,
                    'C'                 => undef,       # Is in MXP spec
                'FONT'                  => undef,
                    'F'                 => undef,       # Not in MXP spec, but implemented anyway
                'NOBR'                  => undef,
                'P'                     => undef,
                'BR'                    => undef,
                'SBR'                   => undef,
#               '&nbsp'                 => undef,
                'A'                     => undef,
                'SEND'                  => undef,
                'EXPIRE'                => undef,
                'VERSION'               => undef,
                'SUPPORT'               => undef,
                'H1'                    => undef,
                'H2'                    => undef,
                'H3'                    => undef,
                'H4'                    => undef,
                'H5'                    => undef,
                'H6'                    => undef,
                'HR'                    => undef,
                'SMALL'                 => undef,
                'TT'                    => undef,
                'SOUND'                 => undef,
                'MUSIC'                 => undef,
                'GAUGE'                 => undef,
                'STAT'                  => undef,
                'FRAME'                 => undef,
                'DESTINATION'           => undef,
                    'DEST'              => undef,
                'RELOCATE'              => undef,
                'QUIET'                 => undef,
                'USER'                  => undef,
                'PASSWORD'              => undef,
                'IMAGE'                 => undef,
                'FILTER'                => undef,
#               'SCRIPT                 => undef,       # Deprecated since MXP v0.4
            },
            # Hash of MXP tags and their attributes (a subset of ->constMxpOfficialHash, omitting
            #   tags that appear as keys in $self->constMxpConvertHash); used to respond to
            #   <SUPPORT> requests, so both the element and its list of attributes are in lower-case
            constMxpAttribHash          => {
#               'element'               => undef,
                'el'                    => ['att', 'tag', 'flag', 'open', 'delete', 'empty'],
#               'attlist'               => undef,
                'at'                    => undef,
#               'att'                   => undef,
#               'entity'                => undef,
                'en'                    => [
                                                'desc', 'private', 'publish', 'delete', 'add',
                                                'remove',
                                           ],
#               'var'                   => undef,
                'v'                     => [
                                                'desc', 'private', 'publish', 'delete', 'add',
                                                'remove',
                                           ],
                'tag'                   => [
                                                'windowname', 'fore', 'back', 'gag', 'enable',
                                                'disable',
                                           ],
#               'bold'                  => undef,
                'b'                     => undef,
#               'italic'                => undef,
                'i'                     => undef,
#               'em'                    => undef,
#               'underline'             => undef,
                'u'                     => undef,
#               'strikeout'             => undef,
                's'                     => undef,
#               'high'                  => undef,
                'h'                     => undef,
#               'color'                 => undef,
                'c'                     => ['fore', 'back'],
#               'font'                  => undef,
                'f'                     => ['face', 'size', 'color', 'back'],
                'nobr'                  => undef,
                'p'                     => undef,
                'br'                    => undef,
                'sbr'                   => undef,
#               '&nbsp'                 => undef,
                'a'                     => ['href', 'hint', 'expire'],
                'send'                  => ['href', 'hint', 'prompt', 'expire'],
                'expire'                => undef,
                'version'               => undef,
                'support'               => undef,
                'h1'                    => undef,
                'h2'                    => undef,
                'h3'                    => undef,
                'h4'                    => undef,
                'h5'                    => undef,
                'h6'                    => undef,
                'small'                 => undef,
                'tt'                    => undef,
                'sound'                 => ['v', 'l', 'p', 'c', 't', 'u'],
                'music'                 => ['v', 'l', 'p', 'c', 't', 'u'],
                'gauge'                 => ['max', 'caption', 'color'],
                'stat'                  => ['max', 'caption'],
                'frame'                 => [
                                                'name', 'action', 'open', 'close', 'redirect',
                                                'title', 'internal', 'align', 'left', 'top',
                                                'width', 'height', 'scrolling', 'floating',
                                           ],
#               'destination'           => undef,
                'dest'                  => ['x', 'y', 'eol', 'eof'],
                'relocate'              => undef,
                'quiet'                 => undef,
                'user'                  => undef,
                'password'              => undef,
                'image'                 => [
                                                'fname', 'url', 't', 'h', 'w', 'hspace', 'vspace',
                                                'align', 'ismap',
                                           ],
                'filter'                => ['src', 'dest', 'name'],
#               'SCRIPT                 => undef,       # Deprecated since MXP v0.4
            },
            # Hash of MXP tags which are synonyms of other tags, e.g. <B>, <BOLD> and <STRONG>
            #   are all equivalent
            constMxpConvertHash         => {
                'BOLD'                  => 'B',
                'STRONG'                => 'B',
                'ITALIC'                => 'I',
                'EM'                    => 'I',
                'UNDERLINE'             => 'U',
                'STRIKEOUT'             => 'S',
                'HIGH'                  => 'H',
                'COLOR'                 => 'C',     # Is in MXP spec
                'FONT'                  => 'F',     # Is not in MXP spec, but implemented anyway
                'ELEMENT'               => 'EL',
                'ATTLIST'               => 'AT',
                'ATT'                   => 'AT',    # The MXP spec uses both <!AT> and <!ATT>
                'ENTITY'                => 'EN',
                'VAR'                   => 'V',
                'DESTINATION'           => 'DEST',
            },
            # Hash of MXP tags that are line-spacing tags that are routed to
            #   $self->processMxpSpacingTag, not $self->processMxpElement
            constMxpLineSpacingHash     => {
                '<NOBR>'                => undef,
                '</NOBR>'               => undef,   # Invalid MXP tag, but still routed to
                                                    #   ->processMxpSpacingTag
                '<P>'                   => undef,
                '</P>'                  => undef,   # Valid MXP tag
                '<BR>'                  => undef,
                '</BR>'                 => undef,   # Invalid MXP tag
                '<SBR>'                 => undef,
                '</SBR>'                => undef,   # Invalid MXP tag
                '<HR>'                  => undef,   # (Actually an MXP HTML element)
                '</HR>'                 => undef,   # Invalid MXP tag
            },
            # Hash of MXP modal tags, such as <B> and </I>, that can be 'on' or 'off'. These are
            #   also the only MXP tags that are allowed in open line mode ($self->mxpLineMode = 0)
            constMxpModalHash           => {
                'B'                     => undef,
                'C'                     => undef,
                'F'                     => undef,
                'H'                     => undef,
                'I'                     => undef,
                'S'                     => undef,
                'U'                     => undef,
            },
            # Hash for converting some MXP modal tags into keys in
            #   GA::Obj::TextView->mxpModalStackHash (for quick lookup, when processing an opening
            #   tag like <B>, but not required when processing a closing tag like </B>)
            constMxpStackConvertHash    => {
                'B'                     => 'bold_flag',     # i.e. <B>
                'I'                     => 'italics_flag',
                'U'                     => 'underline_flag',
                'S'                     => 'strike_flag',
                'H'                     => 'bold_flag',     # 'bold' and 'high' implemented same way
            },
            # Hashes for converting some MXP modal tags into Axmud style tags
            constMxpModalOnHash         => {
#               'B'                     => 'bold',
                'I'                     => 'italics',       # i.e. <I>
                'U'                     => 'underline',
                'S'                     => 'strike',
                'H'                     => 'bold',          # 'bold' and 'high' implemented same way
            },
            # Image file formats permitted by this implementation of MXP
            constMxpFormatHash          => {
                # Supported in MXP spec
                'bmp'                   => undef,
                'gif'                   => undef,
                 # Not supported in MXP spec, but supported by Axmud
                'jpg'                   => undef,
                'jpeg'                  => undef,
                'png'                   => undef,
            },
            # Constant hash of MXP entity names
            #   (from http://www.gammon.com.au/mushclient/mxpentities.htm)
            # NB Does not include entities in the form '&#nnn;' - these are implemented directly by
            #   GA::Session->extractMxpPuebloEntity and ->processMxpEntity
            constMxpEntityHash          => {
                'Aacute'                => chr(193),
                'aacute'                => chr(225),
                'Acirc'                 => chr(194),
                'acirc'                 => chr(226),
                'acute'                 => chr(180),
                'AElig'                 => chr(198),
                'aelig'                 => chr(230),
                'Agrave'                => chr(192),
                'agrave'                => chr(224),
                'amp'                   => chr(38),
                'apos'                  => chr(39),
                'Aring'                 => chr(197),
                'aring'                 => chr(229),
                'Atilde'                => chr(195),
                'atilde'                => chr(227),
                'Auml'                  => chr(196),
                'auml'                  => chr(228),
                'brvbar'                => chr(166),
                'Ccedil'                => chr(199),
                'ccedil'                => chr(231),
                'cedil'                 => chr(184),
                'cent'                  => chr(162),
                'copy'                  => chr(169),
                'curren'                => chr(164),
                'deg'                   => chr(176),
                'divide'                => chr(247),
                'Eacute'                => chr(201),
                'eacute'                => chr(233),
                'Ecirc'                 => chr(202),
                'ecirc'                 => chr(234),
                'Egrave'                => chr(200),
                'egrave'                => chr(232),
                'ETH'                   => chr(208),
                'eth'                   => chr(240),
                'Euml'                  => chr(203),
                'euml'                  => chr(235),
                'frac12'                => chr(189),
                'frac14'                => chr(188),
                'frac34'                => chr(190),
                'gt'                    => chr(62),
                'Iacute'                => chr(205),
                'iacute'                => chr(237),
                'Icirc'                 => chr(206),
                'icirc'                 => chr(238),
                'iexcl'                 => chr(161),
                'Igrave'                => chr(204),
                'igrave'                => chr(236),
                'iquest'                => chr(191),
                'Iuml'                  => chr(207),
                'iuml'                  => chr(239),
                'laquo'                 => chr(171),
                'lt'                    => chr(60),
                'macr'                  => chr(175),
                'micro'                 => chr(181),
                'middot'                => chr(183),
                'nbsp'                  => chr(160),
                'not'                   => chr(172),
                'Ntilde'                => chr(209),
                'ntilde'                => chr(241),
                'Oacute'                => chr(211),
                'oacute'                => chr(243),
                'Ocirc'                 => chr(212),
                'ocirc'                 => chr(244),
                'Ograve'                => chr(210),
                'ograve'                => chr(242),
                'ordf'                  => chr(170),
                'ordm'                  => chr(186),
                'Oslash'                => chr(216),
                'oslash'                => chr(248),
                'Otilde'                => chr(213),
                'otilde'                => chr(245),
                'Ouml'                  => chr(214),
                'ouml'                  => chr(246),
                'para'                  => chr(182),
                'plusmn'                => chr(177),
                'pound'                 => chr(163),
                'quot'                  => chr(34),
                'raquo'                 => chr(187),
                'reg'                   => chr(174),
                'sect'                  => chr(167),
                'shy'                   => chr(173),
                'sup1'                  => chr(185),
                'sup2'                  => chr(178),
                'sup3'                  => chr(179),
                'szlig'                 => chr(223),
                'THORN'                 => chr(222),
                'thorn'                 => chr(254),
                'times'                 => chr(215),
                'Uacute'                => chr(218),
                'uacute'                => chr(250),
                'Ucirc'                 => chr(219),
                'ucirc'                 => chr(251),
                'Ugrave'                => chr(217),
                'ugrave'                => chr(249),
                'uml'                   => chr(168),
                'Uuml'                  => chr(220),
                'uuml'                  => chr(252),
                'Yacute'                => chr(221),
                'yacute'                => chr(253),
                'yen'                   => chr(165),
            },
            # Flag set to TRUE if MXP should be allowed to change the font used, set to FALSE
            #   otherwise
            allowMxpFontFlag            => TRUE,        # [config]
            # Flag set to TRUE if MXP should be allowed to display images in textviews, FALSE if
            #   not
            allowMxpImageFlag           => TRUE,        # [config]
            # Flag set to TRUE if MXP should be allowed to download image files it doesn't already
            #   have, FALSE if not
            allowMxpLoadImageFlag       => TRUE,        # [config]
            # Flag set to TRUE if MXP should be allowed to use image files in the world's own
            #   graphics format (using the <FILTER> tag, FALSE if not
            allowMxpFilterImageFlag     => TRUE,        # [config]
            # Flag set to TRUE if MXP should be allowed to play sound/music (if sound is enabled
            #   generally), set to FALSE otherwise
            allowMxpSoundFlag           => TRUE,        # [config]
            # Flag set to TRUE if MXP should be allowed to download sound files it doesn't already
            #   have, FALSE if not
            allowMxpLoadSoundFlag       => TRUE,        # [config]
            # Flag set to TRUE if MXP should be allowed to display gauges/status bars, FALSE if not
            allowMxpGaugeFlag           => TRUE,        # [config]
            # Flag set to TRUE if MXP should be allowed to use frames (exterior and interior),
            #   FALSE if not
            allowMxpFrameFlag           => TRUE,        # [config]
            # Flag set to TRUE if MXP should be allowed to use interior frames (when available),
            #   set to FALSE if only exterior frames should be used (ignored if
            #   $self->allowMxpFrameFlag is FALSE)
            allowMxpInteriorFlag        => TRUE,        # [config]
            # Flag set to TRUE if MXP should be allowed to perform crosslinking operations
            #   (connect to a new server), FALSE if not
            allowMxpCrosslinkFlag       => TRUE,        # [config]
            # Flag set to TRUE if the Locator task should stop looking for room statement anchors
            #   when it encounters the first MXP 'RoomName', 'RoomDesc', 'RoomExit' or 'RoomNum',
            #   and to use those exclusively from then on; set to FALSE if the Locator task should
            #   ignore those MXP tag flags and look for anchor lines as normal
            allowMxpRoomFlag            => TRUE,        # [config]
            # Flag set to TRUE if Axmud should recognise some illegal MXP keywords (for example,
            #   those using hyphens instead of underlines); FALSE if it should only allow legal
            #   MXP keywords
            allowMxpFlexibleFlag        => FALSE,       # [config]
            # Flag set to TRUE if GA::Session should assume that MXP has been negotiated with the
            #   server (by artificially changing the value of GA::Session->mxpMode from 'no_invite'
            #   to 'client_agree' once automatic logic is complete); FALSE if Axmud should rely on
            #   telnet option negoatiation, as normal
            # (Can be set to TRUE for IRE MUDs that provide MXP by default, but don't negotiate it
            #   with the client)
            allowMxpPermFlag            => FALSE,       # [config]
            # Flag temporarily set to TRUE when modifying the flags above, if
            #   $self->set_allowMxpFlag should not issue a new MXP <SUPPORTS> tag, as it normally
            #   would; usually set to FALSE
            mxpPreventSupportFlag       => FALSE,

            # Hash of all official Pueblo tags (including those not implemented by Axmud)
            constPuebloOfficialHash     => {
                # http://pueblo.sourceforge.io/doc/manual/html_standard_elements.html
                # Document Structure Elements
                'BODY'                  => undef,       # partially implemented
                'HEAD'                  => undef,       # NOT implemented
                'HTML'                  => undef,       # NOT implemented
                'TITLE'                 => undef,       # NOT implemented
                # Anchor Element
                'A'                     => undef,       # partially implemented
                # Embed Element
                'EMBED'                 => undef,       # NOT implemented
                # Image Element
                'IMG'                   => undef,       # partially implemented
                # Block Formatting Elements
                'ADDRESS'               => undef,       # NOT implemented
                'BASEFONT'              => undef,       # implemented
                'BLOCKQUOTE'            => undef,       # NOT implemented
                'BR'                    => undef,       # partially implemented
                'CENTER'                => undef,       # implemented
                'H1'                    => undef,       # partially implemented
                'H2'                    => undef,       # partially implemented
                'H3'                    => undef,       # partially implemented
                'H4'                    => undef,       # partially implemented
                'H5'                    => undef,       # partially implemented
                'H6'                    => undef,       # partially implemented
                'HR'                    => undef,       # partially implemented
                'LISTING'               => undef,       # NOT implemented
                'P'                     => undef,       # partially implemented
                'PLAINTEXT'             => undef,       # NOT implemented
                'PRE'                   => undef,       # partially implemented
                'SAMP'                  => undef,       # implemented
                'XMP'                   => undef,       # NOT implemented
                # Character Formatting Elements
                'B'                     => undef,       # implemented
                'CITE'                  => undef,       # implemented
                'CODE'                  => undef,       # implemented
                'EM'                    => undef,       # implemented
                'FONT'                  => undef,       # implemented
                'I'                     => undef,       # implemented
                'STRIKE'                => undef,       # implemented
                'STRONG'                => undef,       # implemented
                'TT'                    => undef,       # implemented
                'U'                     => undef,       # implemented
                # List Elements
                'DL'                    => undef,       # NOT implemented
                'DIR'                   => undef,       # NOT implemented
                'LI'                    => undef,       # implemented
                'MENU'                  => undef,       # NOT implemented
                'OL'                    => undef,       # implemented
                'UL'                    => undef,       # implemented
                # Form Elements
                'FORM'                  => undef,       # NOT implemented
                'INPUT'                 => undef,       # NOT implemented
                'OPTION'                => undef,       # NOT implemented
                'SELECT'                => undef,       # NOT implemented
                'TEXTAREA'              => undef,       # NOT implemented
                # Unsupported HTML elements
                'ISINDEX'               => undef,       # NOT implemented
                'KBD'                   => undef,       # NOT implemented
                'LINK'                  => undef,       # NOT implemented
                'META'                  => undef,       # NOT implemented
                'NEXTID'                => undef,       # NOT implemented
                'TABLE'                 => undef,       # NOT implemented
                'VAR'                   => undef,       # NOT implemented
                # http://pueblo.sourceforge.io/doc/manual/html_pueblo_extensions.html
                # Basic extensions to HTML
#                'EVENT'                => undef,       # an <IMG> attribute, NOT implemented
#               'XCH_HINT'              => undef,       # an <A> attribute, implemented
                'XCH_PAGE'              => undef,       # partially implemented
                'XCH_PANE'              => undef,       # partially implemented
                'XCH_PREFETCH'          => undef,       # NOT implemented
#               'XCH_PROB'              => undef,       # <XCH_PREFETCH> attribute, NOT implemented
                # Extensions for interactivity
                'XCH_CMD'               => undef,       # an <A> attribute, implemented
#               'XCH_MODE'              => undef,       # an <IMG> attribute, implemented
                'XCH_MUDTEXT'           => undef,       # implemented
                # Extensions for graphics
                'XCH_GRAPH'             => undef,       # NOT implemented
                # Extensions for sound
                'XCH_SOUND'             => undef,       # an <IMG> attribute, partially implemented
                'XCH_SPEECH'            => undef,       # NOT implemented
                'XCH_VOLUME'            => undef,       # NOT implemented
                'XCH_ALERT'             => undef,       # implemented
                'XCH_DEVICE'            => undef,       # NOT implemented
                # http://pueblo.sourceforge.io/doc/manual/vrml_pueblo_extensions.html
                'XCH_CMD_INFO'          => undef,       # NOT implemented
                # http://www.gammon.com.au/forum/?id=281
                'COLOR'                 => undef,       # implemented, but not in Pueblo 2.50 spec
                'SEND'                  => undef,       # implemented, but not in Pueblo 2.50 spec
            },
            # Hash of all implemented Pueblo tags (a subset of $self->constPuebloOfficialHash)
            constPuebloImplementHash    => {
                'A'                     => undef,       # partially implemented
                'B'                     => undef,
                'BASEFONT'              => undef,
                'BODY'                  => undef,       # partially implemented
                'BR'                    => undef,       # partially implemented
                'CENTER'                => undef,
                'CODE'                  => undef,
                'COLOR'                 => undef,       # implemented, but not in Pueblo 2.50 spec
                'EM'                    => undef,
                'FONT'                  => undef,
                'H1'                    => undef,       # partially implemented
                'H2'                    => undef,       # partially implemented
                'H3'                    => undef,       # partially implemented
                'H4'                    => undef,       # partially implemented
                'H5'                    => undef,       # partially implemented
                'H6'                    => undef,       # partially implemented
                'HR'                    => undef,       # partially implemented
                'I'                     => undef,
                'IMG'                   => undef,       # partially implemented
                'LI'                    => undef,
                'OL'                    => undef,
                'P'                     => undef,       # partially implemented
                'PRE'                   => undef,       # partially implemented
                'SAMP'                  => undef,       # implemented
                'SEND'                  => undef,       # implemented, but not in Pueblo 2.50 spec
                'STRIKE'                => undef,
                'STRONG'                => undef,
                'TT'                    => undef,
                'U'                     => undef,
                'UL'                    => undef,
                'XCH_ALERT'             => undef,
                'XCH_MUDTEXT'           => undef,
                'XCH_PAGE'              => undef,       # partially implemented
                'XCH_PANE'              => undef,       # partially implemented
            },
            # Hash of Pueblo tags which are synonyms of other tags, e.g. <B>, <EM> and <STRONG> are
            #   all equivalent
            constPuebloConvertHash      => {
                'CITE'                  => 'I',
                'EM'                    => 'B',
                'STRONG'                => 'B',
            },
            # Hash of Pueblo modal tags, such as <B> and </I>, that can be 'on' or 'off'
            constPuebloModalHash        => {
                'B'                     => undef,
                'I'                     => undef,
                'STRIKE'                => undef,
                'U'                     => undef,
            },

            # Hash of ZMP package objects (GA::Obj::Zmp), in the form
            #   $zmpPackageHash{object_name} = blessed_reference_to_package_object
            # ...where 'object_name' is in the form 'PackageName@WorldName' for a ZMP package that
            #   should be available for any session connected to the world name 'WorldName', or
            #   'PackageName@' for a ZMP package that should be available for all sessions
            # ZMP package objects should be created by plugins. Creating the object by calling
            #   GA::Obj::Zmp->new automatically updates this hash
            # The hash is not saved in any data file. Package objects cannot be modified once
            #   created, and must not be removed from this hash once created - you must edit the
            #   plugin that created and then restart Axmud, instead
            zmpPackageHash              => {},

            # Constant list of MCP packages supported by Axmud by default, and the package versions
            #   that are supported. List in groups of 4, in the form
            #       (mcp_package_name, perl_package_name, minimum_version, maximum_version, ...)
            #   ...where 'minimum_version' and 'maximum_version' refer to the version of the
            #   package itself, not the version of MCP that Axmud uses (2.1)
            constMcpPackageList         => [
                # Official packages
                'mcp-negotiate',
                    'Games::Axmud::Mcp::NegotiateCan',
                        '1.0',
                        '2.0',
                'mcp-cord',
                    'Games::Axmud::Mcp::Cord',
                        '1.0',
                        '1.0',
                # Non-official packages
                'dns-org-mud-moo-simpleedit',
                    'Games::Axmud::Mcp::SimpleEdit',
                        '1.0',
                        '1.0',
            ],
            # Hash of MCP package objects, inheriting from GA::Generic::MCP. The hash includes
            #   the packages specified in $self->constMcpPackageList, as well as any MCP package
            #   pbjects added by plugins (via a call to $self->addPluginMcpPackages)
            # When a GA::Session wants to use a plugin, it clones the MCP package object, placing
            #   the clone into its own ->mcpPackageHash IV
            # Hash in the form
            #   $mcpPackageHash{package_name} = blessed_reference_to_package_object
            mcpPackageHash              => {},

            # Constant list of terminal types currently supported by Axmud. The first item in the
            #   list also serves as the 'default' terminal type, if it is needed. The last item in
            #   the list must be 'unknown', and is sent to the server during telnet option
            #   negotiations, if the server doesn't recognise anything else
            # NB Axmud does not do full xterm-emulation; it merely recognises xterm-256 colours
            #   used by some MUDs (as well as OSC colour palette support)
            constTermTypeList           => [
                'ansi', 'vt100', 'xterm', 'dumb', 'unknown',
            ],
            # Which information is sent to the server during TTYPE option negotiations (when
            #   $self->useMttsFlag is FALSE):
            #   'send_nothing'  - (Nothing sent - should be set to 0 if ->useTTypeFlag is FALSE)
            #   'send_client'   - Send the client name, followed by everything in
            #                       ->constTermTypeList (one at a time)
            #   'send_client_version'
            #                   - Send the client name and version (as a single string), followed by
            #                       everything in ->constTermTypeList (one at a time)
            #   'send_custom_client'
            #                   - Send a customised client name and customised client version,
            #                       followed by everything in ->constTermTypeList (one at a time)
            #   'send_default'  - Send everything in ->constTermTypeList (one at a time)
            #   'send_unknown'  - Send 'unknown'
            #
            # NB For modes 'send_client', 'send_client_version', 'send_custom_client',
            #   'send_default', if the current world profile's ->termType is set, that is sent
            #   first, before everything else
            # NB When $self->useMttsFlag is TRUE, ->termTypeMode is ignored. We send the client
            #   name, followed by either the world profile's ->termType (if set) or 'xterm'
            #   (if not set), followed by the MTTS message
            # NB This IV, as well as ->customClientName and ->customClientVersion, are also used by
            #   MXP and ZMP
            termTypeMode                => 'send_client',   # [config]
            # In mode 'send_custom_client' (or when $self->useMttsFlag is TRUE), the customised
            #   client name to send (if 'undef' or an empty string, it is not sent, instead the
            #   first item in ->constTermTypeList is sent)
            customClientName            => '',          # [config]
            # In mode 'send_custom_client' (or when $self->useMttsFlag is TRUE), the customised
            #   client version to send (if 'undef', or an empty string, or if ->customClientName is
            #   'undef' or an empty string, it is not sent at all)
            customClientVersion         => '',          # [config]

            # Flag set to TRUE if VT100 control sequences should be accepted. If FALSE, they are
            #   ignored (and 'vt100' is not used in terminal type negotations)
            # (Even when FALSE, escape sequences in the form 'ESC [ value ; value m' are still
            #   accepted
            useCtrlSeqFlag              => TRUE,        # [config]
            # Flag set to TRUE if a visible cursor should be displayed in each session's default
            #   textview (only really useful for VT100 emulation, but available all the time)
            useVisibleCursorFlag        => FALSE,       # [config]
            # Flag set to TRUE if a visible cursor should blink quickly; FALSE if it should blink at
            #   a normal rate. Ignored if ->useVisibleCursorFlag is FALSE
            useFastCursorFlag           => FALSE,       # [config]
            # Flag set to TRUE if certain keycodes should be sent directly to the world, FALSE
            #   otherwise
            # In addition, when TRUE and a session's special echo mode is enabled, world commands
            #   are sent to the world immediately, each character sent as soon as it's typed
            useDirectKeysFlag           => FALSE,       # [config]
            # Keycodes available in numeric keypad alternate mode (GA::Session->ctrlKeypadMode is
            #   'alternate') and cursor key application mode (GA::Session->ctrlCursorMode is
            #   'application') (assuming that $self->useDirectKeysFlag is TRUE)
            constDirectAppKeysHash      => {
                'up'                    => chr(27) . 'OA',
                'down'                  => chr(27) . 'OB',
                'right'                 => chr(27) . 'OC',
                'left'                  => chr(27) . 'OD',
            },
            # Constant hashes of Axmud keycodes and their corresponding VT100 escape sequences
            # Keycodes available in numeric keypad alternate mode (GA::Session->ctrlKeypadMode is
            #   'alternate') (assuming that $self->useDirectKeysFlag is TRUE)
            constDirectAltKeysHash      => {
                'kp_enter'              => chr(27) . 'OM',
#               'kp_comma'              => chr(27) . 'Ol',      # This Axmud keycode doesn't exist
                'kp_subtract'           => chr(27) . 'Om',
                'kp_0'                  => chr(27) . 'Op',
                'kp_1'                  => chr(27) . 'Oq',
                'kp_2'                  => chr(27) . 'Or',
                'kp_3'                  => chr(27) . 'Os',
                'kp_4'                  => chr(27) . 'Ot',
                'kp_5'                  => chr(27) . 'Ou',
                'kp_6'                  => chr(27) . 'Ov',
                'kp_7'                  => chr(27) . 'Ow',
                'kp_8'                  => chr(27) . 'Ox',
                'kp_9'                  => chr(27) . 'Oy',
            },
            # Keycodes available at all times (assuming that $self->useDirectKeysFlag is TRUE, and
            #   the previous two hashes take precedence)
            constDirectKeysHash         => {
                'up'                    => chr(27) . '[A',
                'down'                  => chr(27) . '[B',
                'right'                 => chr(27) . '[C',
                'left'                  => chr(27) . '[D',
                'num_lock'              => chr(27) . 'OP',      # PF1 / not available on MSWin/*BSD
                'kp_divide'             => chr(27) . 'OQ',      # PF2
                'kp_multiply'           => chr(27) . 'OR',      # PF3
                'kp_subtract'           => chr(27) . 'OS',      # PF4
            },
            # Constant hash of Axmud keycodes which must be intercepted by a ->signal_connect in
            #   GA::Win::Internal->setKeyPressEvent and sent to the world, whenever a session's
            #   special echo mode is enabled
            constDirectSpecialKeysHash  => {
                'escape'                => chr(27),
                'tab'                   => chr(11),
                'backspace'             => chr(8),
                'delete'                => chr(127),
            },

            # Debugging flag set to TRUE if invalid escape sequences should be displayed as 'debug'
            #   messages, FALSE otherwise
            debugEscSequenceFlag        => FALSE,       # [config]
            # Debugging flag set to TRUE if incoming option negotiations should be displayed as
            #   'debug' messages, FALSE otherwise
            debugTelnetFlag             => FALSE,       # [config]
            # Parallel debugging flag set to TRUE if a very short 'debug' message should be
            #   displayed for incoming option negotiations (ignored if ->debugTelnetFlag is TRUE)
            debugTelnetMiniFlag         => FALSE,       # [config]
            # Debugging flag set to TRUE if GA::Obj::Telnet should write its own logfile for
            #   option negotiations, telopt.log (store in Axmud's base directory)
            debugTelnetLogFlag          => FALSE,       # [config]
            # Debugging flag set to TRUE if MSDP data sent to Status/Locator tasks should be
            #   displayed as 'debug' messages, FALSE otherwise
            debugMsdpFlag               => FALSE,       # [config]
            # Debugging flag set to TRUE if MXP errors should be displayed as 'debug' messages,
            #   FALSE otherwise
            debugMxpFlag                => FALSE,       # [config]
            # Debugging flag set to TRUE if MXP comment elements should be displayed as 'debug'
            #   messages, FALSE otherwise
            debugMxpCommentFlag         => FALSE,       # [config]
            # Debugging flag set to TRUE if Pueblo errors should be displayed as 'debug' messages,
            #   FALSE otherwise
            debugPuebloFlag             => FALSE,       # [config]
            # Debugging flag set to TRUE if Pueblo comment elements should be displayed as 'debug'
            #   messages, FALSE otherwise
            debugPuebloCommentFlag      => FALSE,       # [config]
            # Debugging flag set to TRUE if ZMP data should be displayed as 'debug' messages, FALSE
            #   otherwise
            debugZmpFlag                => FALSE,       # [config]
            # Debugging flag set to TRUE if incoming ATCP data should be displayed as 'debug'
            #   messages, FALSE otherwise
            debugAtcpFlag               => FALSE,       # [config]
            # Debugging flag set to TRUE if incoming GMCP data should be displayed as 'debug'
            #   messages, FALSE otherwise
            debugGmcpFlag               => FALSE,       # [config]
            # Debugging flag set to TRUE if MCP errors should be displayed as 'debug' messages,
            #   FALSE otherwise
            debugMcpFlag                => FALSE,       # [config]

            # Desktop and display settings
            # ----------------------------

            # Display variables
            # Axmud makes use of a number of windows, both those it creates and 'external' windows
            #   it doesn't create
            # 'grid' windows are permanent (or semi-permanent). Axmud tries to arrange these windows
            #   so they don't overlap or, if there isn't enough room on the workspace, to make them
            #   overlap in sensible ways. Axmud tries to take account of the different desktop
            #   environments in getting the positioning of its windows right. 'grid' windows can
            #   include 'external' windows, such as media players, so that they don't overlap
            #   Axmud's own windows (if required)
            # 'free' windows are temporary, and are displayed in the middle of the workspace without
            #   regard for the positioning of any 'grid' windows
            # If your system has multiple workspaces available, 'grid' windows can be arranged on
            #   each one of them. Each workspace can have one or more 'workspace grids' on which
            #   'grid' windows for that workspace are arranged
            #
            # NB Recent Axmud versions can draw task windows and the Automapper window inside the
            #   'main' window, as well as in separate 'grid' windows, as before. These are called
            #   'pseudo-windows'. Their ->number IV is always -1, and they don't appear in registry
            #   hashes of windows. This feature is experimental, so in general comments don't
            #   mention them
            #
            # There are two modes for handling windows in multiple sessions, according to the
            #   setting of this flag:
            #       TRUE (traditional) : All sessions share a single 'main' window. The 'main'
            #           window's Gtk3::Grid contains one table object, a pane object
            #           (GA::Table::Pane) which displays text received from each session's world
            #           in a separate tab. No other widgets are allowed on the table. Other
            #           'internal' windows may be visible; on each workspace, they are arranged on
            #           workspace grids belonging to their session (on every workspace, one
            #           workspace grid for every session). The current session is the one whose tab
            #           is visible; only its 'internal' windows are visible; 'internal' windows
            #           controlled by other sessions are not visible (usually minimised)
            #       FALSE: All sessions have their own 'main' window. The 'main' window's
            #           Gtk3::Grid contains at least one pane object, but can also contain other
            #           table widgets (including other pane objects). Other 'internal' windows are
            #           arranged on a workspace grid shared by all sessions (one workspace grid for
            #           every workspace in use). When the current session changes, no windows are
            #           made visible or invisible (usually minimised or un-minimised)
            shareMainWinFlag            => TRUE,            # [config]
            # When the user wants to change the setting of ->shareMainWinFlag, the change can't be
            #   applied immediately.
            # Instead, this IV is set to 'on' or 'off'. When Axmud next starts, if this IV is not
            #   set to 'default', ->shareMainWinFlag is set to TRUE (for 'on') or FALSE (for 'off');
            #   ->restartShareMainWinMode is then set back to 'default'
            restartShareMainWinMode     => 'default',       # [config]
            # Workspace grids can be available, or not. GA::Obj::Desktop->gridPermitFlag is set to
            #   FALSE if workspace grids are not available at all (because the desktop is too small,
            #   because Axmud is running on MS Windows or running in blind mode, etc)
            # Independent of that flag is this one, which the user can set with
            #   ';activategrid' and ';disactivategrid'. When Axmud starts, it tries to create
            #   workspace grids if this flag and GA::Obj::Desktop->gridPermitFlag are both TRUE
            activateGridFlag            => TRUE,            # [config]
            # When workspace grids are not available, Axmud can try to remember the size and
            #   position of its 'grid' windows. Users can adjust the size/positions manually, and
            #   have those settings applied in future sessions
            # Flag set to TRUE if Axmud should try to remember the size and position of 'grid'
            #   windows, FALSE if not (can be TRUE even if workspace grids are available)
            storeGridPosnFlag           => FALSE,           # [config]
            # When ->storeGridPosnFlag is TRUE, Axmud uses this hash to store the size/position of
            #   each 'grid' window with a unique ->winName (e.g. 'main', 'status_task', 'map').
            #   When it's FALSE, this hash is not updated at all
            # A key-value pair is created when a 'grid' window is created, if there's not already a
            #   matching entry in the hash
            # If a 'grid' window is created when workspace grids are not available, and if there's
            #   an entry in this hash with the same ->winName, that entry is used for the size and
            #   position of the new 'grid' window. If, on the other hand, workspace grids are
            #   available, then the new window's size and position is set by the workspace grid code
            # If a 'grid' window is resized (by code or manually by the user) and it's either the
            #   only window with the same ->winName open, or the first one of that ->winName that
            #   was opened, then the entry in this hash is updated
            # 'External' windows are never added to this hash
            # Hash in the form
            #   ->storeGridPosnHash{window_name} = list_reference
            # ...where 'list_reference' is a reference to a list in the form (x y width height). At
            #   least one of the four values must be defined. When a 'grid' window is created and
            #   workspace grids aren't available, the posn is only used if both 'x' and 'y' are
            #   defined, and the size is only used if both 'width' and 'height' are defined. Those
            #   are the minimum requirements; in actual use, Axmud's code almost certainly delivers
            #   an entry with all four values defined
            storeGridPosnHash           => {},              # [config]
            #
            # Constant hash of standard 'grid' window types (any type of window that can be put onto
            #   a workspace grid; includes 'external' windows, but doesn't include the object viewer
            #   window, 'edit' windows, 'pref' windows, 'dialogue' windows etc)
            # NB 'Internal' windows are a sub-class of 'grid' window handled by GA::Win::Internal,
            #   consisting of the window types 'main', 'protocol' and 'custom'
            # Hash in the form
            #   $constWinTypeHash{window_type} = 'undef'
            # ...where 'window_type' matches GA::Generic::GridWin->winType
            constGridWinTypeHash        => {
                # Any 'grid' window used as a 'main' window by any session (can be created only by
                #   GA::Client or GA::Session)
                'main'                  => undef,
                # Any 'grid' window used as an Automapper window (can be created by any code)
                'map'                   => undef,
                # Any 'grid' window created by a MUD protocol such as MXP (can be created only by
                #   GA::Session)
                'protocol'              => undef,
                # Any 'grid' window NOT used as a 'main' window by any session (besides 'map' and
                #   'protocol' windows), whose widgets can't be customised (can be created by any
                #   code)
                'fixed'                 => undef,
                # Any 'grid' window NOT used as a 'main' window by any session (besides 'map' and
                #   'protocol' windows), whose widgets can be customised (e.g. windows controlled
                #    by individual tasks; can be created by any code)
                'custom'                => undef,
                # Any 'external' window (not created by Axmud, but which has been placed on a
                #   workspace grid, such as media players (can be created only by GA::Session)
                'external'              => undef,
            },
            # Constant hash of standard 'free' window types (temporary windows that can't be put
            #   onto a workspace grid)
            # Hash in the form
            #   $constFreeWinTypeHash{window_type} = 'undef'
            # ...where 'window_type' matches GA::Generic::FreeWin->winType
            constFreeWinTypeHash        => {
                # The object viewer window
                'viewer'                => undef,
                # All 'edit' windows
                'edit'                  => undef,
                # All preference windows (collectively, 'edit' and 'pref' windows are called
                #   'config' windows)
                'pref'                  => undef,
                # All wizard windows
                'wiz'                   => undef,
                # All 'dialogue' windows
                'dialogue'              => undef,
                # Any other kind of temporary window can use this window type
                'other'                 => undef,
            },
            #
            # The layout of 'internal' windows can be customised. The 'plan' for arranging widgets
            #   in an 'internal' window is called a winmap, and is handled by a GA::Obj::Winmap
            #   object
            # The winmap divides the window's client area into horizontal (by default) or vertical
            #   strips (conceptually, not using a specific Gtk3 widget)
            # The winmap only affects the window when it is first created (or when it is reset).
            #   The Axmud code is then free to add/remove strips, or add/remove/resizes widgets
            #   within the Gtk3::Grid, whenever it pleases
            # Axmud has several standard winmaps, which can't be modified by the user (but which
            #   can be cloned, and the clones are modifiable)
            #   'main_wait' - The winmap used in the spare 'main' window visible when Axmud starts,
            #       before the first session is created. From top to bottom, the window will contain
            #       a menu bar, toolbar, Gtk3::Grid and an entry box. The Gtk3::Grid contains no
            #       table objects
            #   'internal_wait' - The equivalent of 'main_wait' for 'internal' windows other than
            #       'main' windows. It's probably not required by anything, but is available
            #       nonetheless. The window contains only one strip object, the compulsory
            #       GA::Strip::Table; it contains no table objects
            #   'main_fill' - The default winmap for 'main' windows. From top to bottom, the window
            #       will contain a menu bar, toolbar, Gtk3::Grid, a gauge box, an entry box and an
            #       info box. The Gtk3::Grid contains a single pane object (GA::Table::Pane, which
            #       consists of one or two Gtk3::TextViews sharing a single Gtk3::TextBuffer)
            #       filling the whole table
            #   'main_part' - The same as 'main_fill', but the single pane object fills two-thirds
            #       of the left-hand side of the table, leaving the remaining third empty for other
            #       widgets
            #   'main_empty' - The same as 'main_fill', but the Gtk3::Grid is empty
            #   'basic_fill' - The default winmap for 'internal' windows besides 'main' windows.
            #       Contains only a Gtk3::Grid. The Gtk3::Grid contains a single pane object
            #       filling the whole table
            #   'basic_part' - The same as 'basic_fill', but the single pane object fills only the
            #       lower quarter of the table, leaving plenty of room for other widgets
            #   'basic_empty' - The same as 'basic_fill', but the Gtk3::Grid is empty
            #   'entry_fill' - From top to bottom, contains a Gtk3::Grid and an entry box. The
            #       Gtk3::Grid contains a single pane object filling the whole table
            #   'entry_part' - The same as 'entry_fill', but the single pane object fills only the
            #       lower quarter of the table, leaving plenty of room for other widgets
            #   'entry_empty' - The same as 'entry_fill', but the Gtk3::Grid is empty
            # Constant registry hash of standard winmap names, in the form
            #   $constWinmapNameHash->{name} = undef
            constWinmapNameHash         => {
                'main_wait'             => undef,
                'main_fill'             => undef,
                'main_part'             => undef,
                'main_empty'            => undef,
                'basic_fill'            => undef,
                'basic_part'            => undef,
                'basic_empty'           => undef,
                'entry_fill'            => undef,
                'entry_part'            => undef,
                'entry_empty'           => undef,
            },
            # Registry hash of blessed references to all winmap objects. Names have max of 16 chars.
            #   Hash in the form
            #       $winmapHash{name} = blessed_reference_to_winmap_object
            winmapHash                  => {},              # [winmaps]
            # A hash containing only the 'standard' winmap objects, a subset of
            #   $self->winmapHash (filled by GA::Obj::Winmap->setupStandardWinmap)
            standardWinmapHash          => {},              # [winmaps]
            # The name of the default winmaps to use when a 'main' window or other 'internal'
            #   window object is created
            # Constant default values for the winmaps (these values never change)
            # Default winmap for 'main' windows when workspace grids are enabled
            #   ($self->activateGridFlag = TRUE)
            constDefaultEnabledWinmap   => 'main_fill',
            # Default winmap for 'main' windows when workspace grids are disabled
            #   ($self->activateGridFlag = FALSE)
            constDefaultDisabledWinmap  => 'main_part',
            # Default winmap for other 'internal' windows besides 'main' windows
            constDefaultInternalWinmap  => 'basic_fill',
            # Customisable default values for the winmaps
            defaultEnabledWinmap        => undef,           # [winmaps] Set below
            defaultDisabledWinmap       => undef,           # [winmaps] Set below
            defaultInternalWinmap       => undef,           # [winmaps] Set below
            #
            # A workspace grid is divided into 'gridblocks'. The size of a gridblock can be changed,
            #   but the default size is 10x10 pixels (min 1, max 100)
            # 'Grid' windows are moved and resized to fit on a workspace grid, leaving no partially-
            #   filled gridblocks, and no gridblocks with more than one window occupying them
            # In fact, a workspace grid exists in three dimensions, allowing Axmud to stack windows
            #   on top of each other when the workspace grid is full. The default number of layers
            #   is 16 and the layer at the bottom is the default one. (Both of these values can be
            #   changed.)
            # 'Grid' windows are usually placed in the default layer. If there's no room for them
            #   there, they're placed in the first available layer below; if there are no available
            #   layers below (which will be the case, if the default layer is at the bottom),
            #   they're placed in the first available layer above
            # Constant default value for a workspace griblock
            # (This value never changes; min - 1 pixel, max - 100)
            constGridBlockSize          => 10,
            # Customisable default size for a workspace gridblock
            gridBlockSize               => undef,           # [config] Set below
            #
            # The 'plan' for a workspace grid is called a zonemap. Zonemaps are 60x60 grids,
            #   regardless of the size of the workspace.
            # A zonemap is filled with zone models. Zone models are a 'plan' for an individual zone
            #   on a workspace grid
            #
            #   PLAN            ACTUAL
            #   zonemap     ->  workspace grid
            #   zone model  ->  zone
            #
            # Axmud will try to make the zonemap fit onto the workspace grid as closely as possible,
            #   but because of the irregular size of some workspaces, zones in the zonemap might not
            #   be in exactly the same proportions as zones in the gridmap.
            # Axmud has several standard zonemaps, which can't be modified by the user (but which
            #   can be cloned, and the clones are modifiable)
            #   'single' - The entire workspace is covered by a single zone. Windows (even 'main'
            #       windows) use their default sizes. Windows cannot be stacked above each other
            #   'single2' - A modified version of 'single', in which windows can be stacked above
            #       each other
            #   'basic' - Intended for use when $self->shareMainWinFlag = TRUE. There are two zones.
            #       The first zone covers the left-hand 2/3 of the workspace and is reserved for a
            #       single 'main' window. The other zone covers the right-hand 1/3 of the workspace
            #       and is available for all 'grid' windows (and only those windows can be stacked
            #       above each other). The first 'main' window expands to fill the whole of its
            #       zone. Other windows use their default sizes
            #   'extended' - Intended for use when $self->shareMainWinFlag = TRUE. The left-hand 2/3
            #       of the workspace is reserved for a single 'main' window and the Status and
            #       Locator task windows. The task windows go above the first 'main' window; the
            #       Status window is to the left of the Locator window.  The right-hand 1/3 of the
            #       workspace is reserved for a single 'map' window at the top half and any other
            #       'grid' windows at the bottom half (and only those windows can be stacked above
            #       each other)
            #   'widescreen' - A modified version of 'extended' for widescreen monitors, with the
            #       the workspace divided into halves, rather than a 2/3 - 1/3 split
            #   'horizontal' - Intended for use when $self->shareMainWinFlag = FALSE. The workspace
            #       is divided into two halves, left and right, with each half occupied by a single
            #       session's windows. Inside the half, the 'main' window is at the bottom, and
            #       other windows are at the top. Windows cannot be stacked above each other
            #   'horizontal2' - A modified version of 'horizontal', in which windows can be stacked
            #       above each other
            #   'vertical' - Intended for use when $self->shareMainWinFlag = FALSE. The workspace is
            #       divided into two halves, top and bottom, with each half occupied by a single
            #       session's windows. Inside the half, the 'main' window is on the left, and other
            #       windows are on the right. Windows cannot be stacked above each other
            #   'vertical2' - A modified version of 'vertical', in which windows can be stacked
            #       above each other
            # Constant registry hash of standard zonemap names, in the form
            #   $constZonemapHash->{name} = undef
            #   $constZonemapHash->{name} = clone_from_standard_zonemap_called_this
            constZonemapHash            => {
                'single'                => undef,
                'single2'               => 'single',
                'basic'                 => undef,
                'extended'              => undef,
                'widescreen'            => undef,
                'horizontal'            => undef,
                'horizontal2'           => 'horizontal',
                'vertical'              => undef,
                'vertical2'             => 'vertical',
            },
            # Registry hash of blessed references to all zonemap objects. Names have max of 16
            #   chars. Hash in the form
            #       $zonemapHash{unique_zonemap_name} = blessed_reference_to_zonemap_object
            zonemapHash                 => {},              # [zonemaps]
            # A hash containing only the 'standard' zonemap objects, a subset of
            #   $self->zonemapHash (filled by GA::Obj::Zonemap->setupStandardZonemap)
            standardZonemapHash         => {},              # [zonemaps]
            # Constant registry hash which specifies how many workspaces to use on startup, and the
            #   default zonemaps for each one. Hash in the form
            #       $constInitWorkspaceHash{unique_number} = default_zonemap_name
            constInitWorkspaceHash      => {
                0                       => 'basic',
            },
            # Customisable registry hash of workspaces to use on startup. The default workspace has
            #   the 'unique_number' 0, and corresponds to the workspace in which Axmud starts. Any
            #   further workspaces should be numbered consecutively (1, 2, 3...). If a key-value
            #   pair is removed, subsequent key-value pairs must be renumbered
            # This hash is only used on startup; the workspaces currently in use are stored in
            #   GA::Obj::Desktop->workspaceHash
            # Hash in the form
            #   $initWorkspaceHash{unique_number} = default_zonemap_name
            #   $initWorkspaceHash{unique_number} = 'undef'
            # NB If 'undef' is specified, GA::Obj::Desktop->useWorkspace chooses a zonemap based on
            #   the current value of $self->shareMainWinFlag
            initWorkspaceHash           => {},              # [config] Set below
            # Constant direction of workspace use. If $self->initWorkspaceHash specifies we should
            #   use two or more workspaces at startup, this IV specifies in which direction we
            #   should move, after finding the default workspace:
            #       'move_left'     - move left from the default workspace until we reach the
            #                           left-most workspace (and then stop)
            #       'move_right'    - move right from the default workspace until we reach the
            #                           right-most workspace (and then stop)
            #       'start_left'    - after finding the default workspace, the next workspace
            #                           should be the left-most one, after that move right until we
            #                           reach the right-most workspace (and then stop)
            #       'start_right'   - after finding the default workspace, the next workspace
            #                           should be the right-most one, after that move left until we
            #                           reach the left-most workspace (and then stop)
            constInitWorkspaceDir       => 'move_right',
            # Customisable direction of workspace use
            initWorkspaceDir            => undef,           # [config] Set below
            #
            # Sometimes a window almost fills a zone, leaving gaps of just a few gridblocks here and
            #   there. When a new window is created, GA::Obj::Zone->adjustSingleWin can remedy this
            #   situation by expanding the window to remove the small gap between it and the edge of
            #   its zone
            # If the zone has a maximum number of windows, then the biggest gap (measured in
            #   gridblocks) that GA::Obj::Zone->adjustSingleWin can fix is the maximum number of
            #   windows, minus 1. (A gap that's the same size as the maximum windows shouldn't
            #   exist)
            # Otherwise, the size of the maximum gap is stored in this IV. This IV holds the maximum
            #   size of the gap between a window and an edge of the grid, in gridblocks, that can be
            #   removed by the function.
            # When gridblocks are their default size (10 pixels), a good value for this IV is 1 or
            #   2. 3 would be ok, but 4 is probably too much. When set to 0, gaps will not be
            #   removed at all.
            # Constant default size for the grid gap (this value never changes; min: 0, max: 100)
            constGridGapMaxSize         => 2,
            # Customisable default value for the grid gap
            gridGapMaxSize              => 2,               # [config]
            # When there are a larger gaps in a zone, and if the windows in the zone are all the
            #   same width (or all the same height), GA::Obj::Zone->adjustMultipleWin can adjust
            #   the size of all of the windows at the same time to either remove the gap (if it is
            #   small), or to increase the gap to make room for another window (if it is big).
            # This flag is set to TRUE if adjustments are allowed, FALSE if not
            gridAdjustmentFlag          => TRUE,            # [config]
            # When the available workspace is an arkward size (i.e. not exactly divisible by
            #   $self->gridBlockSize) there may be a small gap on the right and bottom edges of the
            #   workspace grid. GA::Obj::WorkspaceGrid->fineTuneWinSize can close the gap, if this
            #   flag is set to TRUE
            gridEdgeCorrectionFlag      => TRUE,            # [config]
            # When a window is deleted in the middle of the zone, the resulting empty space
            #   doesn't look very attractive. If this flag is TRUE, when a window is deleted, other
            #   windows are re-shuffled to move them closer to the zone's starting corner, moving
            #   the gap to the opposite end
            gridReshuffleFlag           => TRUE,            # [config]
            # When a GA::Session is no longer a current session, its workspace 'grid' windows must
            #   be hidden. When it becomes a current session again, those windows must be un-hidden
            #   (this doesn't apply to the 'main' window, which is always visible)
            # If this flag is set to TRUE, the windows become invisible; if the flag is set to
            #   FALSE, they are merely minimised
            gridInvisWinFlag            => FALSE,           # [config]
            #
            # The maximum and minimum sizes of workspace that Axmud allows. If the workspace is
            #   bigger than the maximum, Axmud will use less than the whole workspace. If the
            #   workspace is smaller than the minimum, Axmud will only allow a single 'grid' window
            #   (as well as any number of 'free' windows) to open, workspace grids will be disabled
            constWorkspaceMaxWidth      => 3200,
            constWorkspaceMaxHeight     => 3200,
            constWorkspaceMinWidth      => 800,
            constWorkspaceMinHeight     => 600,
            #
            # Default window sizes
            # Constant default size for windows of the type 'main'. (Any window is allowed to use
            #   these values. The constant values never change. Min: 100, max:
            #   ->constWorkspaceMaxWidth / ->constWorkspaceMaxHeight)
            constMainWinWidth           => 800,
            constMainWinHeight          => 600,
            # Customisable default size for windows of the type 'main'
            customMainWinWidth          => undef,           # [config] Set below
            customMainWinHeight         => undef,           # [config] Set below
            # Constant default spacing values for 'main' windows (in pixels)
            constMainBorderPixels       => 5,
            constMainSpacingPixels      => 5,
            #
            # Constant default size for other 'grid' windows besides those of the type 'main'. (Not
            #   used very often, because GA::Obj::Zone defines its own default window size. Any
            #   window is allowed to use these values. The constant values never change. Min: 100,
            #   max: ->constWorkspaceMaxWidth / ->constWorkspaceMaxHeight)
            constGridWinWidth           => 400,
            constGridWinHeight          => 300,
            # Customisable default size for task windows
            customGridWinWidth          => undef,           # [config] Set below
            customGridWinHeight         => undef,           # [config] Set below
            # Constant default spacing values for other 'grid' windows (in pixels)
            constGridBorderPixels       => 5,
            constGridSpacingPixels      => 5,
            #
            # Constant default size for 'free' windows. (Any window is allowed to use these values,
            #   but 'dialogue' windows usually specify their own size. The constant values never
            #   change. Min: 100, max: ->constWorkspaceMaxWidth / ->constWorkspaceMaxHeight)
            constFreeWinWidth           => 700,
            constFreeWinHeight          => 500,
            # Customisable default size for 'free' windows
            customFreeWinWidth          => undef,           # [config] Set below
            customFreeWinHeight         => undef,           # [config] Set below
            # Constant default spacing values for 'free' windows (in pixels)
            constFreeBorderPixels       => 5,
            constFreeSpacingPixels      => 5,
            # Unfortunately, when we display labels in Axmud 'dialogue' windows, we usually have to
            #   break up the text into separate lines (as Gtk+ no longer handles that)
            # The maximum number of characters per line, when that is done
            constDialogueLabelSize      => 50,
            #
            # The edges of the workspace may not be available to windows because of panels (called
            #   'taskbars' in MS Windows). These IVs hold the sizes, in pixels, of the area
            #   unavailable on each edge of the workspace. If 0, Axmud assumes windows can be placed
            #   at the edges (min: 0, max left+right: ->constWorkspaceMaxWidth, max top+bottom:
            #   ->constWorkspaceMaxHeight)
            # Constant size of a workspace panel (this value never changes)
            constPanelSize              => 0,
            # Constant default sizes for panels, used when no panels can be detected at all. We'll
            #   assume that it's most likely that people have a single panel at the bottom of the
            #   workspace; let's also assume that it's quite big
            constPanelLeftSize          => 0,
            constPanelRightSize         => 0,
            constPanelTopSize           => 0,
            constPanelBottomSize        => 50,
            # Customisable sizes for panel sizes. Axmud assumes any sizes that are defined here are
            #   valid for all workspaces. For any sizes that are not defined, Axmud tries to detect
            #   the sizes for each workspace it uses. If detection fails, Axmud uses the constant
            #   values just above
            customPanelLeftSize         => undef,            # [config]
            customPanelRightSize        => undef,            # [config]
            customPanelTopSize          => undef,            # [config]
            customPanelBottomSize       => undef,            # [config]
            #
            # Window controls are the edges of any windows, typically including a border on all
            #   four sides, and a window name at the top. The sizes of window controls are
            #   required when moving windows around the workspace, so Axmud tests window controls on
            #   each workspace it uses. (It's rather unlikely that different workspaces will use
            #   different window controls, but Axmud checks for that possibility anyway)
            # Constant default size for window controls (this value never changes; min: 0 pixels,
            #   max: 100)
            constControlsSize           => 0,
            # Constant default sizes for window controls, used when the window controls test fails.
            #   (These values never change; based on Linux Mint 18 using Cinnamon)
            constControlsLeftSize       => 1,
            constControlsRightSize      => 1,
            constControlsTopSize        => 25,
            constControlsBottomSize     => 1,
            # Customisable sizes for window controls. If all four sizes here are defined, Axmud
            #   uses them for all workspaces. If even one size is not defined, Axmud tries to detect
            #   window controls sizes in every workspace it uses. If detection fails, Axmud uses the
            #   constant values just above
            customControlsLeftSize      => undef,           # [config]
            customControlsRightSize     => undef,           # [config]
            customControlsTopSize       => undef,           # [config]
            customControlsBottomSize    => undef,           # [config]
            #
            # Constant default colour scheme for the pane objects (GA::Table::Pane), each of which
            #   displays a Gtk3::TextView in an 'internal' windows
            # (These values never change; each value MUST be a standard colour tag, not an Xterm or
            #   RGB colour tag)
            constTextColour             => 'white',
            constUnderlayColour         => 'ul_black',
            constBackgroundColour       => 'black',
            constFont                   => 'monospace',
            constFontSize               => 10,
            # In Pueblo mode, the default colour for clickable links (not used otherwise)
            constPuebloLinkColour       => 'CYAN',
            # Registry hash of colour scheme objects, each of which defines a colour scheme that can
            #   be used in a Gtk3::TextView
            # Colour schemes with the same name as a type of window are used as the default colour
            #   scheme for that type of window. Those colour scheme objects can be modified, but not
            #   deleted from the hash. Other colour scheme objects can be added, deleted and
            #   modified as required
            # Hash in the form
            #   $colourSchemeHash{unique_name} = blessed_reference_to_colour_scheme_object
            colourSchemeHash            => {},              # [winmaps]
            #
            # Constant default colours used for particular types of system message
            # (These values never changes; each value is a standard colour tag)
            constInsertCmdColour        => 'green',         # [config]
            constShowSystemTextColour   => 'YELLOW',        # [config]
            constShowErrorColour        => 'cyan',          # [config]
            constShowWarningColour      => 'cyan',          # [config]
            constShowDebugColour        => 'GREEN',         # [config]
            constShowImproperColour     => 'MAGENTA',       # [config]
            # Customisable default colours used for particular types of system message
            customInsertCmdColour       => undef,           # [config] Set below
            customShowSystemTextColour  => undef,           # [config] Set below
            customShowErrorColour       => undef,           # [config] Set below
            customShowWarningColour     => undef,           # [config] Set below
            customShowDebugColour       => undef,           # [config] Set below
            customShowImproperColour    => undef,           # [config] Set below
            #
            # When 'black' text is shown on a 'black' background, it is invisible. If this flag is
            #   set, text that's the same colour as the background is converted to/from bold (i.e.
            #   'black' becomes 'BLACK', and 'BLACK' becomes 'black'
            convertInvisibleFlag        => FALSE,           # [config]
            # Constant default size for the textviews, corresponding to the number of lines that can
            #   be stored in any textview object's Gtk3::TextBuffer (when it's full, the earliest
            #   line is removed to make way for a new line)
            # NB If required, text buffers can be set to be of unlimited size; these IVs only apply
            #   if a maximum size is needed
            # NB The absolute minimum/maximum size (when a size is used at all) is taken from the
            #   IVs for Axmud's display, instruction and world command buffers, ->constMaxBufferSize
            #   and ->constMinBufferSize
            constTextBufferSize         => 10000,
            # Default maximum number of lines that can be shown in a Gtk3::TextView
            customTextBufferSize        => undef,           # [config] Set below

            # A set of Gtk3::Gdk::Cursors, one for when the mouse is hovering over a normal part of
            #   a textview, and others when it is hovering over various kinds of clickable link
            constNormalCursor           => Gtk3::Gdk::Cursor->new('xterm'),
            constWWWCursor              => Gtk3::Gdk::Cursor->new('hand1'),
            constPromptCursor           => Gtk3::Gdk::Cursor->new('sb_down_arrow'),
            constPopupCursor            => Gtk3::Gdk::Cursor->new('target'),
            constCmdCursor              => Gtk3::Gdk::Cursor->new('mouse'),
            constMailCursor             => Gtk3::Gdk::Cursor->new('pencil'),
            constTelnetCursor           => Gtk3::Gdk::Cursor->new('trek'),
            # Another set of Gtk3::Gdk::Cursors for the automapper window's free click mode
            constMapCursor              => Gtk3::Gdk::Cursor->new('arrow'),
            constMapAddCursor           => Gtk3::Gdk::Cursor->new('plus'),
            constMapConnectCursor       => Gtk3::Gdk::Cursor->new('crosshair'),
            constMapMergeCursor         => Gtk3::Gdk::Cursor->new('target'),

            # Icon file paths (relative to the main directory) for the 'internal' window strip
            #   object, GA::Strip::SearchBox
            constUpIconPath             => '/icons/search/arrow_up.png',
            constDownIconPath           => '/icons/search/arrow_down.png',
            constResetIconPath          => '/icons/search/broom.png',
            constCaseIconPath           => '/icons/search/capitalization.png',
            constRegexIconPath          => '/icons/search/token_shortland_character.png',
            constDivideIconPath         => '/icons/search/application_tile_vertical.png',
            # Icon file paths (relative to the main directory) for the 'internal' window strip
            #   object, GA::Strip::Entry
            constWipeIconPath           => '/icons/button/broom.png',
            constAddIconPath            => '/icons/button/textfield_add.png',
            constEmptyIconPath          => '/icons/button/console.png',
            constSystemIconPath         => '/icons/button/console_system.png',
            constDebugIconPath          => '/icons/button/console_debug.png',
            constErrorIconPath          => '/icons/button/console_error.png',
            constMultiIconPath          => '/icons/button/toggle_expand.png',
            constSearchIconPath         => '/icons/button/search.png',
            constCancelIconPath         => '/icons/button/wall.png',
            constSwitchIconPath         => '/icons/button/switch_windows.png',
            constSplitIconPath          => '/icons/button/application_tile_vertical.png',
            constRestoreIconPath        => '/icons/button/application.png',
            constScrollIconPath         => '/icons/button/lock_open.png',
            constLockIconPath           => '/icons/button/lock.png',

            # The sizes of icon provided for Axmud (icon files are in /icons/win/
            # Constant list of icon sizes (these values never change; in pixels)
            constIconSizeList           => [16, 32, 48, 64, 128],

            # If you want to extend the object viewer window for this session with your own 'edit'
            #   window - using code you've written in your own plugin - this flag gets set to TRUE;
            #   the custom 'edit' window defined by the plugin can then be called by the object
            #   viewer window's menu
            guiPrivateFlag              => FALSE,
            # If you want, in addition, the GUI menu to have its 'Private' column for code you've
            #   written yourself, set this flag to TRUE
            guiPrivateMenuFlag          => FALSE,

            # 'Internal' windows
            # ------------------

            # Axmud keeps two lists of strip objects - one for Axmud's built-in strip objects, and
            #   another for all strip objects (built-in objects and custom objects added via a
            #   plugin, which should inherit from GA::Strip::Custom)
            #
            # The constant registry of strip objects (these values never change). A hash in the form
            #   $constStripHash{package_name} = pretty_name
            # NB Both 'package_name' and 'pretty_name' should be unique. To avoid problems, use the
            #   plugin name in 'pretty_name', e.g. 'Myplugin toolbar'
            constStripHash              => {
                'Games::Axmud::Strip::MenuBar'
                                        => $axmud::SCRIPT . ' menu bar',
                'Games::Axmud::Strip::Toolbar'
                                        => $axmud::SCRIPT . ' toolbar',
                'Games::Axmud::Strip::Table'
                                        => $axmud::SCRIPT . ' table',
                'Games::Axmud::Strip::GaugeBox'
                                        => $axmud::SCRIPT . ' gauge box',
                'Games::Axmud::Strip::SearchBox'
                                        => $axmud::SCRIPT . ' search box',
                'Games::Axmud::Strip::Entry'
                                        => $axmud::SCRIPT . ' command entry box',
                'Games::Axmud::Strip::ConnectInfo'
                                        => $axmud::SCRIPT . ' connection info box',
            },
            # The customisable registry hash of strip objects, in the form
            #   $customStripHash{package_name} = description
            customStripHash             => {},      # Set below

            # Likewise, Axmud keeps two lists of table objects - one for Axmud's built-in table
            #   objects, and another for all table objects (built-in objects and custom objects
            #   added via a plugin, which should inherit from GA::Table::Custom)
            #
            # The constant registry of table objects (these values never change). A hash in the form
            #   $constTableHash{package_name} = pretty-name
            # NB Both 'package_name' and 'pretty_name' should be unique. To avoid problems, use the
            #   plugin name in 'pretty_name', e.g. 'Myplugin button'
            constTableHash              => {
                'Games::Axmud::Table::Holder'
                                        => $axmud::SCRIPT . ' holder',
                'Games::Axmud::Table::Container'
                                        => $axmud::SCRIPT . ' generic container',
                'Games::Axmud::Table::MiniTable'
                                        => $axmud::SCRIPT . ' mini-table',
                'Games::Axmud::Table::Label'
                                        => $axmud::SCRIPT . ' label',
                'Games::Axmud::Table::Button'
                                        => $axmud::SCRIPT . ' button',
                'Games::Axmud::Table::CheckButton'
                                        => $axmud::SCRIPT . ' check button',
                'Games::Axmud::Table::RadioButton'
                                        => $axmud::SCRIPT . ' radio button',
                'Games::Axmud::Table::Entry'
                                        => $axmud::SCRIPT . ' entry box',
                'Games::Axmud::Table::ComboBox'
                                        => $axmud::SCRIPT . ' combobox',
                'Games::Axmud::Table::SimpleList'
                                        => $axmud::SCRIPT . ' simple list',
                'Games::Axmud::Table::TextView'
                                        => $axmud::SCRIPT . ' simple textview',
                'Games::Axmud::Table::Pane'
                                        => $axmud::SCRIPT . ' window pane',
                'Games::Axmud::Table::PseudoWin'
                                        => $axmud::SCRIPT . ' pseudo-window',
            },
            # The customisable registry hash of table objects, in the form
            #   $customTableHash{package_name} = description
            customTableHash             => {},      # Set below

            # Constant registry list used to initialise the default set of toolbar buttons used in
            #   'internal' windows (usually only 'main' windows), when required. List in groups of
            #   6, in the form
            #       name            - Unique object name
            #       descrip         - Short description
            #       iconPath        - File path to the icon
            #       instruct        - Instruction to execute
            #       session_flag    - Icon only sensitised when there is a current session
            #       connect_flag    - Icon only sensitised when current session connected to a world
            # Separators are in groups of 1
            constToolbarList            => [
                'connect_me',
                    'Connect to a world',
                    'phone_vintage.png',
                    ';connect',
                    FALSE,                      # Always available
                    FALSE,                      # Doesn't require connection to world
                'login_me',
                    'Mark the character as logged in',
                    'user_go.png',
                    ';login',
                    TRUE,                       # Requires current session
                    TRUE,                       # Requires connection to world
                'save_me',
                    'Save data',
                    'drive_disk.png',
                    ';save',
                    TRUE,                       # Requires current session
                    TRUE,                       # Requires connection to world
                # separator
                'separator',
                'open_map',
                    'Open Automapper window',
                    'compass.png',
                    ';openautomapper',
                    TRUE,                       # Requires current session
                    TRUE,                       # Requires connection to world
                'reset_loc',
                    'Reset the Locator task',
                    'roadworks.png',
                    ';resetlocator',
                    TRUE,                       # Requires current session
                    TRUE,                       # Requires connection to world
                # separator
                'separator',
                'active_int',
                    'View active interfaces',
                    'gear_in.png',
                    ';editactiveinterface',
                    TRUE,                       # Requires current session
                    TRUE,                       # Requires connection to world
                'edit_trigger',
                    'Edit world trigger cage',
                    'gun.png',
                    ';editcage -t',
                    TRUE,                       # Requires current session
                    TRUE,                       # Requires connection to world
                'edit_alias',
                    'Edit world alias cage',
                    'user_detective.png',
                    ';editcage -a',
                    TRUE,                       # Requires current session
                    TRUE,                       # Requires connection to world
                'edit_macro',
                    'Edit world macro cage',
                    'keyboard.png',
                    ';editcage -m',
                    TRUE,                       # Requires current session
                    TRUE,                       # Requires connection to world
                'edit_timer',
                    'Edit world timer cage',
                    'clock_red.png',
                    ';editcage -i',
                    TRUE,                       # Requires current session
                    TRUE,                       # Requires connection to world
                'edit_hook',
                    'Edit world hook cage',
                    'candy_cane.png',
                    ';editcage -h',
                    TRUE,                       # Requires current session
                    TRUE,                       # Requires connection to world
                'route',
                    'Edit route cage',
                    'routing_go_straight_left.png',
                    ';editcage -r',
                    TRUE,                       # Requires current session
                    TRUE,                       # Requires connection to world
                # separator
                'separator',
                'edit_quick',
                    'Set quick preferences',
                    'book_edit.png',
                    ';editquick',
                    TRUE,                       # Requires current session
                    TRUE,                       # Requires connection to world
                'edit_client',
                    'Set Axmud client preferences',
                    'application_edit.png',
                    ';editclient',
                    TRUE,                       # Requires current session
                    TRUE,                       # Requires connection to world
                'edit_world',
                    'Edit current world profile',
                    'world_edit.png',
                    ';editworld',
                    TRUE,                       # Requires current session
                    TRUE,                       # Requires connection to world
                'open_viewer',
                    'Open object viewer window',
                    'watermark_table.png',
                    ';openobjectviewer',
                    TRUE,                       # Requires current session
                    TRUE,                       # Requires connection to world
                # separator
                'separator',
                'speech',
                    'Turn on text-to-speech',
                    'ear_listen.png',
                    ';speech toggle',
                    FALSE,                      # Doesn't current session
                    FALSE,                      # Doesn't connection to world
                'freeze_task',
                    'Freeze/unfreeze tasks',
                    'cold.png',
                    ';freezetask',
                    TRUE,                       # Requires current session
                    TRUE,                       # Requires connection to world
                'disable_int',
                    'Disable all active interfaces',
                    'prohibition_button.png',
                    ';disableactiveinterface',
                    TRUE,                       # Requires current session
                    FALSE,                      # Doesn't connection to world
                # separator
                'separator',
                'layer_up',
                    'Move workspace grid up a layer',
                    'hand_point_090.png',
                    ';layerup',
                    TRUE,                       # Requires current session
                    TRUE,                       # Requires connection to world
                'layer_down',
                    'Move workspace grid down a layer',
                    'hand_point_270.png',
                    ';layerdown',
                    TRUE,                       # Requires current session
                    TRUE,                       # Requires connection to world
                'help_me',
                    'Show quick help',
                    'help.png',
                    ';openaboutwindow -h',
                    FALSE,                      # Always available
                    FALSE,                      # Doesn't require connection to world
            ],
            # Registry hash of toolbar button objects which exist, in the form
            #   $toolbarHash{unique_name} = blessed_reference_to_toolbar_button_object
            toolbarHash                 => {},              # [toolbar]
            # Registry list of toolbar button object names, in the order in which they appear in the
            #   toolbar (and any number of occurences of the word 'separator', which is not a
            #   toolbar button, but a separator)
            toolbarList                 => [],              # [toolbar]

            # External applications
            # ---------------------

            # Constant registry list of external application commands for Linux
            # NB Any audio package can be used to play MSP sound triggers, but Axmud is only able to
            #   apply the volume parameter to packages it actively supports. Currently, only the SoX
            #   package is actively supported
            constLinuxCmdList           => [
                'firefox "%s" &',                           # Firefox
                'thunderbird -compose "to=\'%s\'" &',       # Thunderbird
                'play -q "%s" &',                           # play from SoX package
                'xed "%s" &',                               # xed
            ],
            # Constant registry list of external application commands for MS Windows
            constMSWinCmdList           => [
                'start iexplore.exe %s',                    # Internet Explorer
                'start outlook.exe /c ipm.note /m %s',      # Outlook Express
                'start wmplayer.exe /play %s',              # Windows Media Player
                'start notepad.exe /A %s',                  # Notepad
            ],
            # Constant registry list of external application commands for *BSD
            constBSDCmdList             => [
                'firefox "%s" &',                           # Firefox
                'thunderbird -compose "to=\'%s\'" &',       # Thunderbird
                'play -q "%s" &',                           # play from SoX package
                'pluma "%s" &',                             # Pluma
            ],
            # The command to run a web browser. %s is substituted for a URL
            browserCmd                  => undef,           # [config] set below
            # The command to open an email application. %s is subsituted for the email address
            #   of the person to email
            emailCmd                    => undef,           # [config] set below
            # The command to run an audio player. %s is substituted for the full file path
            #   (default value opens sox package on Linux)
            audioCmd                    => undef,           # [config] set below
            # The command to open a text editor. %s is subsituted for the file to open
            textEditCmd                 => undef,           # [config] set below

            # Sound and sound effects
            # -----------------------

            # Audio file formats supported by various parts of Axmud (principally by the MSP code)
            constSoundFormatHash          => {
                # Supported in MSP spec
                'mid'                   => undef,
                'midi'                  => undef,
                'wav'                   => undef,
                # Not supported in MSP spec, but supported by Axmud
                'aac'                   => undef,
                'aiff'                  => undef,
                'alac'                  => undef,
                'flac'                  => undef,
                'mp3'                   => undef,
                'ogg'                   => undef,
                'wma'                   => undef,
            },
            # Flag set to TRUE if sound effects are allowed at all, FALSE if not
            allowSoundFlag              => FALSE,                   # [config]
            # Flag set to TRUE if Axmud should play a 'bell' when GA::Obj::TextView->insertText
            #   (etc) tries to display an ASCII 7 character (bell), FALSE if not
            # Set to TRUE by default so that turning on sound will automatically allow remote beeps
            allowAsciiBellFlag          => TRUE,                    # [config]
            # Axmud provides two groups of sound effects by default. The first group are used by
            #   various parts of the Axmud code, and are named for the purpose for which they're
            #   mostly used
            # Constant registry hash of standard sound effects, in the form
            #   $constStandardSoundHash{effect_name} = file_name
            # ...where 'file_name' is the file in /items/sounds
            constStandardSoundHash      => {
                # Text received after going AFK
                'afk'                   => 'afk.mp3',
                # Timed alerts
                'alert'                 => 'alert.mp3',
                # General alarm
                'alarm'                 => 'alarm.mp3',
                # General attack started
                'attack'                => 'attack.mp3',
                # Old-fashioned beep
                'beep'                  => 'beep.mp3',
                # Desk bell
                'bell'                  => 'bell.mp3',
                # Incoming chat message
                'call'                  => 'call.mp3',
                # Character dies
                'death'                 => 'death.mp3',
                # Character deposits money into bank
                'deposit'               => 'deposit.mp3',
                # System error/warning/debug/improper arguments messages
                'error'                 => 'error.mp3',
                # General arrival
                'greeting'              => 'greeting.mp3',
                # General kill
                'kill'                  => 'kill.mp3',
                # Automapper gets lost
                'lost'                  => 'lost.mp3',
                # General notification
                'notify'                => 'notify.mp3',
                # Something is ready
                'ready'                 => 'ready.mp3',
                # Torch has burnt out
                'torch'                 => 'torch.mp3',
                # Character withdraws money from bank
                'withdraw'              => 'withdraw.mp3',
            },
            # The second group are named after the sounds that the sound effects contain, and can be
            #   used for any purpose
            # The following registry hash is in the same format as ->constStandardSoundHash, and
            #   contains both groups of sound effects, representing all the sound files in
            #   /items/sounds (refreshed every time Axmud runs)
            constExtendedSoundHash      => {},
            # Customisable registry hash of sound effects (the 'sound effects bank') in the form
            #   $customSoundHash{effect} = full_file_path
            # This hash is initially filled with all the sound effects in /items/sounds, and from
            #   then on can be customised by the user
            # If full_file_path is an empty string (or 'undef'), no sound is played
            customSoundHash             => {},                      # [config] Set below

            # Text-to-speech (TTS)
            # --------------------

            # NB Perl modules for handling TTS don't work for us, so we haven't used them at all;
            #   instead, we are using direct system calls to one of three commonly-used TTS engines.
            #   The call will only work if that engine has been installed correctly on the user's
            #   system

            # There are two flags that turn TTS on and off
            # The user can toggle the first one on or off at any time (using the ;speech command),
            #   and is saved in the config file
            # Flag set to TRUE if TTS is allowed at all, FALSE if not
            customAllowTTSFlag          => FALSE,                   # [config]
            # The second flag is not saved in any file. It is set to TRUE when
            #   $self->customAllowTTSFlag is TRUE or when the global variable
            #   $axmud::BLIND_MODE_FLAG is TRUE
            # In this way if the user starts Axmud in blind mode, TTS is definitely turned on; if
            #   the user then restarts Axmud not in blind mode, TTS will be on or off, depending on
            #   the value of ->customAllowTTSFlag
            # (Thus, a single installation of Axmud can be used by two users, one with a visual
            #   impairment and one without)
            systemAllowTTSFlag          => FALSE,                   # [config]
            # If the user specifies a TTS engine from the command line (e.g. by running
            #   './axmud.pl festival'  or './baxmud.pl deathmud.com 5000 festival'), that engine
            #   is used exclusively while Axmud is running. This IV stores the engine, if specified
            forceTTSEngine              => undef,
            # Constant list of TTS engines that Axmud currently supports - eSpeak, espeak-ng, Flite,
            #   Festival, Swift (using Cepstral) and a dummy engine, 'none', which produces no
            #   speech when specified
            constTTSList                => [
                'espeak', 'esng', 'flite', 'festival', 'swift', 'none',
            ],
            # Constant list of TTS engines that Axmud supports on this operating system
            constTTSCompatList          => [],                      # Set below
            # On MS Windows, the path to the eSpeak engine (if installed) depends on the age of the
            #   system. This IV is set by $self->start to the correct path for the user's system, or
            #   left as 'undef' if eSpeak is not installed on it
            eSpeakPath                  => undef,
            # Allow TTS smoothing, which inserts an artificial full stop at the end of lines which
            #   don't end with one, if the next line begins with a capital letter (makes the voice
            #   sound more natural)
            ttsSmoothFlag               => TRUE,                    # [config]

            # Constant lists of default TTS settings, used for initialising TTS configuration
            #   objects, in the form
            #       (tts_engine, tts_voice, tts_speed, tts_rate, tts_pitch, tts_volume...)
            constTtsDefaultList         => [
                'espeak',
                    'english_rp',       # Male voice
                    80,
                    undef,
                    50,
                    undef,
                'esng',
                    'en',               # Male voice
                    80,
                    undef,
                    50,
                    80,
                'flite',
                    'slt',              # Female voice
                    undef,
                    undef,
                    undef,
                    undef,
                'festival',             # Male voice
                    'voice_kal_diphone',
                    undef,
                    33,
                    undef,
                    20,
                'swift',
                    'David',
                    30,                 # Used on MSWin
                    50,                 # Used on Linux/*BSD
                    50,
                    80,
                'none',                 # Doesn't actually read anything
                    undef,
                    undef,
                    undef,
                    undef,
                    undef,
            ],
            # Constant hash of TTS configuration objects to be created at startup, in the form
            #   $constTtsObjHash{unique_name} = which_tts_engine_to_use_by_default
            # ...where 'unique_name' is max 16 chars, no reserved names
            constTtsObjHash             => {
                # Default TTS settings
                'espeak'                => 'espeak',    # Default for each TTS engine
                'esng'                  => 'esng',
                'flite'                 => 'flite',
                'festival'              => 'festival',
                'swift'                 => 'swift',
                'none'                  => 'espeak',    # The 'void' engine - doesn't read anything
                'task'                  => 'espeak',    # Default for tasks
                'script'                => 'espeak',    # Default for Axbasic scripts
                'default'               => 'espeak',    # Default for everything else
                # Default TTS settings for various parts of Axmud
                'receive'               => 'espeak',    # Text received from world
                'system'                => 'espeak',    # System messages, i.e. ->writeText
                'error'                 => 'espeak',    # System error/warning/debug/improper msgs
                'command'               => 'espeak',    # World commands
                'dialogue'              => 'espeak',    # 'Dialogue' windows
                # Default TTS settings for various built-in tasks
                'attack'                => 'espeak',
                'chat'                  => 'espeak',
                'channels'              => 'espeak',
                'divert'                => 'espeak',
                'locator'               => 'espeak',
                'status'                => 'espeak',
                'watch'                 => 'espeak',
            },
            # Constant hash of TTS configuration objects which cannot be removed
            constTtsPermObjHash         => {
                'espeak'                => undef,
                'esng'                  => undef,
                'flite'                 => undef,
                'festival'              => undef,
                'swift'                 => undef,
                'none'                  => undef,
                'task'                  => undef,
                'script'                => undef,
                'default'               => undef,
            },
            # Constant hash of TTS configuration objects which cannot be modified, as their IVs are
            #   used as default values for other configuration object IVs
            constTtsFixedObjHash        => {
                'espeak'                => undef,
                'esng'                  => undef,
                'flite'                 => undef,
                'festival'              => undef,
                'swift'                 => undef,
                'none'                  => undef,
            },
            # Registry hash of TTS configuration objects (GA::Obj::Tts) in the form
            #   $ttsObjHash{unique_name} = blessed_reference_to_tts_object
            # ...where 'unique_name' is max 16 chars, no reserved names
            # When Axmud runs for the first time, TTS configuration objects are created for each of
            #   the keys in $self->constTtsObjHash
            # The configuration objects in $self->constTtsPermObjHash cannot be removed from this
            #   hash. The configuration objects in ->constTtsFixedObjHash cannot be modified.
            #   Otherwise, the user and/or code can freely add and remove configuration objects from
            #   this hash
            ttsObjHash                  => {},

            # Constant hash of TTS (normal) attributes, which allows the ';read' command to interact
            #   with specific tasks
            # Hash in the form
            #   $constTtsAttribHash{attribute} = name_of_task_which_uses_it
            # ...where 'attribute' is a string unique to this hash, preferably a single word in all
            #   lower-case letters
            constTtsAttribHash          => {
                # Locator task
                'title'                 => 'locator_task',      # Reads current room title
                'descrip'               => 'locator_task',      # ...description
                'description'           => 'locator_task',      # ...description
                'exit'                  => 'locator_task',      # ...exit list
                'exits'                 => 'locator_task',      # ...exit list
                'content'               => 'locator_task',      # ...contents
                'contents'              => 'locator_task',      # ...contents
                'command'               => 'locator_task',      # ...room commands
                'cmd'                   => 'locator_task',      # ...room commands
                # Status task
                'status'                => 'status_task',       # Read current char's life status
                'life'                  => 'status_task',       # ...life and death counts
                'lives'                 => 'status_task',       # ...life and death counts
                'health'                => 'status_task',       # ...health points/max health points
                'magic'                 => 'status_task',       # ...magic points
                'energy'                => 'status_task',       # ...energy points
                'guild'                 => 'status_task',       # ...guild points
                'social'                => 'status_task',       # ...social points
                'xp'                    => 'status_task',       # ...xp
                'experience'            => 'status_task',       # ...xp
                'level'                 => 'status_task',       # ...level
                'align'                 => 'status_task',       # ...alignment
                'alignment'             => 'status_task',       # ...alignment
                'age'                   => 'status_task',       # ...age
                'time'                  => 'status_task',       # ...game time
                'bank'                  => 'status_task',       # ...bank balance
                'purse'                 => 'status_task',       # ...purse contents
            },
            # Hash of TTS (normal) attributes, initially set identical to ->constTtsAttribHash,
            #   and then modified as plugins add new plugin tasks
            # Each GA::Session contains a customisable hash, initially given the same key-value
            #   pairs as this one, which contains all the TTS attributes used by built-in tasks. If
            #   the new tasks add attributes already used by built-in tasks, then the key-value
            #   pairs are overwritten, and the attributes point to the new task, not the built-in
            #   task
            ttsAttribHash               => {},          # Set below
            # Constant hash of TTS flag attributes, which allows the ';switch' command to
            #   interact with specific tasks
            # Hash in the form
            #   $constTtsFlagAttribHash{flag_attribute} = name_of_task_which_uses_it
            # ...where 'flag_attribute' is a string unique to this hash (not a TRUE or FALSE value),
            #   preferably a single word in all lower-case letters
            # NB Each GA::Session contains a customisable hash, as for $self->constTtsAttribHash
            constTtsFlagAttribHash      => {
                # Attack task
                'fight'                 => 'attack_task',       # Turn on/off automatic kill reading
                'interact'              => 'attack_task',       # ...interaction reading
                'interaction'           => 'attack_task',       # ...interaction reading
                # Channels task
                'channels'              => 'channels_task',     # Turn on/off reading diverted msgs
                # Chat task
                'chat'                  => 'chat_task',         # Turns on/off reading all messages
                'chatout'               => 'chat_task',         # ...only sent messages
                'chatin'                => 'chat_task',         # ...only received messages
                'chatecho'              => 'chat_task',         # ...only echoed (group) messages
                'chatsystem'            => 'chat_task',         # ...only local system messages
                'chatremote'            => 'chat_task',         # ...only remote system messages
                'chatsnoop'             => 'chat_task',         # ...only snooping messages
                # Divert task
                'divert'                => 'divert_task',       # Turn on/off reading diverted msgs
                'tell'                  => 'divert_task',       # ...only tells
                'social'                => 'divert_task',       # ...only socials
                'custom'                => 'divert_task',       # ...only customs
                'warning'               => 'divert_task',       # ...only warnings
                # Locator task
                'title'                 => 'locator_task',      # Turn on/off room title reading
                'descrip'               => 'locator_task',      # ...description reading
                'description'           => 'locator_task',      # ...description reading
                'exit'                  => 'locator_task',      # ...exit list reading
                'exits'                 => 'locator_task',      # ...exit list reading
                'content'               => 'locator_task',      # ...contents reading
                'contents'              => 'locator_task',      # ...contents reading
                'command'               => 'locator_task',      # ...room commands
                'cmd'                   => 'locator_task',      # ...room commands
                # Status task
                'life'                  => 'status_task',       # Turn on/off life status reading
                # Watch task
                'watch'                 => 'watch_task',        # Turn on/off reading watched msgs
            },
            # Hash of TTS flag attributes, initially set identical to ->constTtsFlagAttribHash,
            #   and then modified as plugins add new plugin tasks
            ttsFlagAttribHash           => {},          # Set below
            # Constant hash of TTS alert attributes, which allows the ';alert' command to
            #   interact with specific tasks
            # Hash in the form
            #   $constTtsAlertAttribHash{alert_attribute} = name_of_task_which_uses_it
            # ...where 'alert_attribute' is a string unique to this hash, preferably a single word
            #   in all lower-case letters
            # NB Each GA::Session contains a customisable hash, as for $self->constTtsAttribHash
            constTtsAlertAttribHash     => {
                # Status task
                'healthup'              => 'status_task',       # HP recovers to minimum level
                'healthdown'            => 'status_task',       # ...falls to maximum level
                'magicup'               => 'status_task',       # Magic points recover to min level
                'magicdown'             => 'status_task',       # ...falls to maximum level
                'energyup'              => 'status_task',       # Energy points recover to min level
                'energydown'            => 'status_task',       # ...falls to maximum level
                'guildup'               => 'status_task',       # Guild points recover to min level
                'guilddown'             => 'status_task',       # ...falls to maximum level
                'socialup'              => 'status_task',       # Social points recover to min level
                'socialdown'            => 'status_task',       # ...falls to maximum level
                # ...
            },
            # Hash of TTS alert attributes, initially set identical to ->constTtsAlertAttribHash,
            #   and then modified as plugins add new plugin tasks
            ttsAlertAttribHash          => {},          # set below

            # IVs that govern what text is converted to speech
            # Convert text received from the world (after modification by triggers, etc)
            ttsReceiveFlag              => TRUE,                    # [config]
            # Don't convert text received from the world before a login is processed (except for
            #   prompts)
            ttsLoginFlag                => TRUE,                    # [config]
            # Convert system messages
            ttsSystemFlag               => TRUE,                    # [config]
            # Convert system error messages (including warning and debug messages)
            ttsSystemErrorFlag          => TRUE,                    # [config]
            # Convert world commands
            ttsWorldCmdFlag             => TRUE,                    # [config]
            # Convert 'dialogue' windows (as far as possible)
            ttsDialogueFlag             => TRUE,                    # [config]
            # Convert (some) text displayed in (some) task windows
            ttsTaskFlag                 => FALSE,                   # [config]

            # Special IVs for interacting with the Festival server. The first time some part of the
            #   code calls $self->tts to read out some text with the Festival engine, Axmud attempts
            #   to contact the Festival server using this port
            # The Festival server default port, in case the user wants to reset it
            constTtsFestivalServerPort  => 1314,
            # The port the server is using, in case the user has changed it. If changed to 0, an
            #   empty string or 'undef', Axmud won't try to connect to the Festival server
            ttsFestivalServerPort       => undef,                   # [config] # set below
            # If the server is running, the IO::Socket::INET object is stored here
            ttsFestivalServer           => undef,
            # If this flag is set to TRUE, Axmud should attempt to start the server, before
            #   connecting to it
            ttsStartServerFlag          => TRUE,                    # [config]
            # When Axmud starts the Festival server, the value of this IV is set to 1. Whenever it
            #   is time to do some TTS with the Festival engine, $self->tts will try connecting to
            #   the server (which does not start instantaneously). If the connection fails, TTS is
            #   done using the command-line Festival engine. Eventually, the connection succeeds,
            #   this IV is set to 2, and TTS is done with the Festival server
            # On the other hand, if $self->ttsStartServerFlag is FALSE, Axmud attempts to connect
            #   to the server just once. If the connection fails, TTS is done using the command-line
            #   Festival engine. If the connection succeeds, TTS is done using the Festival server.
            #   In either case, this IV is set to 2 immediately.
            ttsFestivalServerMode       => 'waiting',

            # Other IVs
            # ---------

            # Lists of short names for months and days of the week (mainly used with functions like
            #   ->localTime, ->localClock and ->localDate)
            # Registry list of short months (these values never change)
            constMonthList              => [
                'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
            ],
            # Customisable list of short months (can be changed for other languages)
            customMonthList             => [],          # [config] Set below
            # Registry list of short days (these values never change)
            constDayList                => [
                'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat',
            ],
            # Customisable list of short days (can be changed for other languages)
            customDayList               => [],          # [config] Set below
            # Hash used by $self->convertRoman to convert integer numbers to Roman numerals, based
            #   on Text::Roman by Stanislaw Pusep
            constRomanHash              => {
                'I'     => 1,
                'V'     => 5,
                'X'     => 10,
                'L'     => 50,
                'C'     => 100,
                'D'     => 500,
                'M'     => 1000,
                'IV'    => 4,
                'IX'    => 9,
                'XL'    => 40,
                'XC'    => 90,
                'CD'    => 400,
                'CM'    => 900,
            },

            # List of websites that provide the user's IP address
            constIPLookupList           => [
                'https://canihazip.com/s',
                'http://icanhazip.com/',
                'http://myip.dnsomatic.com/',
                'http://ifconfig.me/ip',
            ],

            # Lines in help files should be longer than 80 characters long
            constHelpCharLimit          => 80,          # [config]

            # The system time, in seconds, at which the client started
            startTime                   => undef,
            # The date/time at which the client started
            startClock                  => undef,
            startDate                   => undef,
            startClockString            => undef,
            startDateString             => undef,

            # When text is received from the world that doesn't end in a newline character, we wait
            #   a short time before treating it as a prompt. If nothing else is received in that
            #   time, it's a prompt.
            # Constant default time to wait
            constPromptWaitTime         => 0.5,
            # The time to wait (in seconds, minimum value 0.1, maximum value 5)
            promptWaitTime              => undef,       # [config] Set below
            # At the start of a session, how long to wait for the character to login before showing
            #   a reminder message
            # Constant default time to wait
            constLoginWarningTime       => 60,
            # The time to wait (in seconds, minimum value 0 for 'immediately')
            loginWarningTime            => undef,       # [config] Set below

            # Toolbar buttons in the 'main' and automapper windows are created with labels. On most
            #   Linux systems, the labels are only visible in a drop-down menu if there are too
            #   many buttons in the toolbar, but on other systems (including MS Windows), the
            #   labels are displayed beneath the buttons (which we don't want). Users can toggle
            #   this flag to suit their own system
            # Flag set to TRUE if toolbar buttons should have labels, FALSE otherwise
            toolbarLabelFlag            => undef,       # [config] Set below
            # Some 'edit'/'pref' windows use the irreversible icon (stored as the file
            #   /icons/system/irreversible.png) on buttons to show that stored data will be
            #   modified immediately. However, on some (Linux) systems the icon isn't currently
            #   visible. Flag set to TRUE if an icon should be drawn, FALSE if an asterisk should be
            #   drawn instead
            irreversibleIconFlag        => FALSE,       # [config]
            # Flag set to TRUE if the popup window created by GA::Generic::Win->showBusyWin should
            #   not be shown at all; FALSE if it can be shown (when required)
            allowBusyWinFlag            => TRUE,        # [config]
            # Flag set to FALSE if system messages should never be displayed in a session's 'main'
            #   window, but redirected to the Session Console window; TRUE if the session should
            #   decide for itself which of those to do
            mainWinSystemMsgFlag        => TRUE,       # [config]
            # Flag set to TRUE if a session's 'main' window urgency hint should be set, when text
            #   is received from the world
            mainWinUrgencyFlag          => FALSE,       # [config]
            # Flag set to TRUE if tooltips should be shown in session's default tab
            mainWinTooltipFlag          => TRUE,        # [config]

            # Calls to $self->commify can modify a long number like 1000000 into something more
            #   readable, like 1,000,000 (currently, only used by the Status task, but it's
            #   available to any code)
            # The default mode to use when converting numbers with a call to $self->commify
            #   'none' - don't use commas (1000000)
            #   'comma' - use commas (1,000,000)
            #   'europe' - use European-style full stops/periods (1.000.000)
            #   'brit' - use British-style spaces (1 000 000)
            #   'underline' - use underlines (1_000_000)
            commifyMode                 => 'none',      # [config]

            # Flag set to TRUE if the session's 'main' window urgency hint should be set once, when
            #   the next text is received from the world; as soon as text is received, the flag is
            #   set back to FALSE.
            tempUrgencyFlag             => FALSE,
            # Flag set to TRUE if a sound effect should be played, when the next text is received
            #   from the world; as soon as text is received, the flag is set back to FALSE
            tempSoundFlag               => FALSE,

            # Regexes used to recognise valid web links
            constUrlRegex               => $urlRegex,
            constShortUrlRegex          => $shortRegex,
            # Flag set to TRUE if GA::Session->extractClickLinks should use both
            #   $self->constUrlRegex and ->constShortUrlRegex, set to FALSE if it should only use
            #   ->constUrlRegex
            shortUrlFlag                => TRUE,
            # Regex used to recognise valid email addresses
            constEmailRegex             => $emailRegex,

            # IV set briefly by private code (not included in the public release) which creates a
            #   set of pre-configured worlds in the /items/worlds directory. When set,
            #   ';exportfiles' and ';exportdata' save a file to a specific sub-directory, not to a
            #   directory specified by the user. Set to 'undef' at all other times
            privConfigAllWorld          => undef,

            # Benchmarking IVs
            # ----------------

            # Provides on-the-fly benchmarking of Axmud processes
            # Call $self->benchMark to set a start time, and $self->stopBenchMark to set a stop
            #   time. The difference between the two is used to set the list IVs
            # The start time (matches the system time); set by $self->benchMark and reset by
            #   ->stopBenchMark
            benchMarkTime               => undef,
            # The last 10 and 100 benchmark times, used to provide an average (in microseconds),
            #   which is written to the terminal
            benchMarkShortList          => [],
            benchMarkLongList           => [],

            # Debug flags
            # -----------

            # Flag set to TRUE if the text received from the world should be displayed in the 'main'
            #   window with explicit text buffer line numbers (set to FALSE if text should be
            #   displayed normally)
            debugLineNumsFlag           => FALSE,       # [config]
            # Flag set to TRUE if the text received from the world should be displayed in the 'main'
            #   window with explicit Axmud colour/style tags (set to FALSE if text should be
            #   displayed normally)
            debugLineTagsFlag           => FALSE,       # [config]
            # Flag set to TRUE if the Locator task should display standard debug messages as it
            #   tries to interpret room statements (set to FALSE if the Locator should behave
            #   normally)
            # Locator task debug messages uses an error code in the range 100-999
            debugLocatorFlag            => FALSE,       # [config]
            # Flag set to TRUE if the Locator task should display extensive standard debug messages
            #   as it tries to interpret room statements (set to FALSE if the Locator should behave
            #   normally)
            debugMaxLocatorFlag         => FALSE,       # [config]
            # Flag set to TRUE if GA::Obj::Exit should display debug messages for an illegal
            #   exit direction (typically one that's over 64 characters long), FALSE if no debug
            #   message should be shown
            debugExitFlag               => FALSE,       # [config]
            # Flag set to TRUE if the Locator task should display a summary of the contents of its
            #   ->moveList IV (which contains a list of look/glance and movement commands for which
            #   it is expecting to receive room statements) in its task window (set to FALSE if the
            #   Locator's task window should behave normally)
            debugMoveListFlag           => FALSE,       # [config]
            # Flag set to TRUE if GA::Obj::WorldModel->parseObj (which converts a string like 'Two
            #   big guards, a troll and three small torches are here' into a string of non-model
            #   objects) should display standard debug messages as it parses lines (set to FALSE if
            #   the function should behave normally)
            debugParseObjFlag           => FALSE,       # [config]
            # Flag set to TRUE if GA::Obj::WorldModel->objCompare (which compares a target model
            #   object against a list of other model objects, to see if any of them seem to match
            #   the target) should display standard debug messages as it makes comparisons (set to
            #   FALSE if the function should behave normally)
            # (Also used by GA::Obj::WorldModel->objMatch)
            debugCompareObjFlag         => FALSE,       # [config]
            # Flag set to TRUE if GA::Client->loadPlugin should display debug messages, when a
            #   plugin can't be loaded, specifying exactly why (set to FALSE otherwise)
            debugExplainPluginFlag      => FALSE,       # [config]
            # Flag set to TRUE if functions in the generic object, Games::Axmud (inherited by all
            #   other objects) should show a debug message every time some part of the Axmud code
            #   tries to use an IV which doesn't exist
            debugCheckIVFlag            => TRUE,        # [config]
            # Flag set to TRUE if Axmud should show error messages if a table object (inheriting
            #   from GA::Generic::Table) can't be added or resized within its table strip object
            #   (GA::Strip::Table)
            debugTableFitFlag           => FALSE,       # [config]
            # Flag set to TRUE if Perl errors/warnings should be displayed in the 'main' window
            #   (set to FALSE if they should be sent to the terminal)
            debugTrapErrorFlag          => TRUE,        # [config]

            # Misc flags
            # ----------

            # When Axmud first runs (specifically, when GA::Obj::File->setupConfigFile is called),
            #   the Setup 'wiz' window (GA::WizWin::Setup) invites the new user to initialise a few
            #   settings. If required for testing purposes, the window can be blocked by setting
            #   this flag to FALSE
            allowSetupWizWinFlag        => TRUE,
            # If the flag above is TRUE, GA::Obj::File->setupConfigFile sets this flag to TRUE,
            #   which is the signal to GA::Client->start to open the Setup 'wiz' window
            showSetupWizWinFlag         => FALSE,
            # Flag that can be set to TRUE by any code (by calling $self->set_blockWorldHintFlag)
            #   to stop the GA::Session displaying a 'dialogue' window with the world profile's
            #   ->worldHint, when the session starts
            blockWorldHintFlag          => FALSE,
        };

        # Bless the object into existence
        bless $self, $class;

        # Set remaining IVs

        $self->{charSet}                = $self->constCharSet;
        # Sets ->charSetList
        $self->compileCharSets();

        $self->{clientCmdPrettyList}    = [$self->constClientCmdPrettyList];

        $self->{cmdSep}                 = $self->constCmdSep;

        $self->{constWorldList}         = [
                                            sort {lc($a) cmp lc($b)}
                                                ($self->ivKeys('constWorldHash'))
                                          ];

        $self->{cageTypeList}           = [$self->constCageTypeList];

        $self->{taskPackageHash}        = {$self->constTaskPackageHash};
        $self->{taskLabelHash}          = {$self->constTaskLabelHash};
        $self->{taskRunFirstList}       = [$self->constTaskRunFirstList];
        $self->{taskRunLastList}        = [$self->constTaskRunLastList];

        $self->{logPrefHash}            = {$self->constLogPrefHash};

        $self->{chatSmileyHash}         = {$self->constChatSmileyHash};

        $self->{colourTagHash}          = {$self->constColourTagHash};
        $self->{boldColourTagHash}      = {$self->constBoldColourTagHash};

        # Sets ->constXTermColourHash, ->constNetscapeColourHash
        $self->setXTermColours();
        if ($self->currentColourCube eq 'netscape') {

            $self->{xTermColourHash}    = {$self->constNetscapeColourHash};

        } else {

            # Default
            $self->{xTermColourHash}    = {$self->constXTermColourHash};
        }

        foreach my $item ($self->constMsspVarList) {

            if (substr($item, 0, 1) ne '#') {

                $msspHash{$item} = undef;
            }
        }

        $self->{constMsspVarHash}       = \%msspHash;

        $self->{defaultEnabledWinmap}   = $self->constDefaultEnabledWinmap;
        $self->{defaultDisabledWinmap}  = $self->constDefaultDisabledWinmap;
        $self->{defaultInternalWinmap}  = $self->constDefaultInternalWinmap;

        $self->{gridBlockSize}          = $self->constGridBlockSize;

        $self->{initWorkspaceHash}      = {$self->constInitWorkspaceHash};
        $self->{initWorkspaceDir}       = $self->constInitWorkspaceDir;

        $self->{customMainWinWidth}     = $self->constMainWinWidth;
        $self->{customMainWinHeight}    = $self->constMainWinHeight;
        $self->{customGridWinWidth}     = $self->constGridWinWidth;
        $self->{customGridWinHeight}    = $self->constGridWinHeight;
        $self->{customFreeWinWidth}     = $self->constFreeWinWidth;
        $self->{customFreeWinHeight}    = $self->constFreeWinHeight;

        $self->{customInsertCmdColour}  = $self->constInsertCmdColour;
        $self->{customShowSystemTextColour}
                                        = $self->constShowSystemTextColour;
        $self->{customShowErrorColour}  = $self->constShowErrorColour;
        $self->{customShowWarningColour}
                                        = $self->constShowWarningColour;
        $self->{customShowDebugColour}  = $self->constShowDebugColour;
        $self->{customShowImproperColour}
                                        = $self->constShowImproperColour;

        $self->{customTextBufferSize}   = $self->constTextBufferSize;

        $self->{customStripHash}        = {$self->constStripHash};
        $self->{customTableHash}        = {$self->constTableHash};

        if ($^O eq 'linux') {
            @cmdList = $self->constLinuxCmdList;
        } elsif ($^O eq 'MSWin32') {
            @cmdList = $self->constMSWinCmdList;
        } elsif ($^O =~ m/bsd/i) {                          # 'freebsd', 'openbsd'
            @cmdList = $self->constBSDCmdList;
        }

        $self->{customDisplayBufferSize}
                                        = $self->constDisplayBufferSize;
        $self->{customInstructBufferSize}
                                        = $self->constInstructBufferSize;
        $self->{customCmdBufferSize}    = $self->constCmdBufferSize;

        $self->{browserCmd}             = shift @cmdList;
        $self->{emailCmd}               = shift @cmdList;
        $self->{audioCmd}               = shift @cmdList;
        $self->{textEditCmd}            = shift @cmdList;

        $self->compileSoundEffects();
        foreach my $effect ($self->ivKeys('constExtendedSoundHash')) {

            # Values in ->constExtendedSoundHash are file names relative to /items/sounds; values in
            #   ->customSoundHash should be full file paths
            $soundHash{$effect}
                = $axmud::DATA_DIR . '/sounds/' . $self->ivShow('constExtendedSoundHash', $effect);
        }

        $self->{customSoundHash}        = {%soundHash};

        if ($^O eq 'MSWin32') {

            $self->{constTTSCompatList} = ['espeak', 'esng', 'swift', 'none'];

        } else {

            # Not sure what TTS engines are available on (all) BSDs, if any, so just use the Linux
            #   list
            $self->{constTTSCompatList} = [$self->constTTSList];
        }

        $self->{ttsAttribHash}          = {$self->constTtsAttribHash};
        $self->{ttsFlagAttribHash}      = {$self->constTtsFlagAttribHash};
        $self->{ttsAlertAttribHash}     = {$self->constTtsAlertAttribHash};
        $self->{ttsFestivalServerPort}  = $self->constTtsFestivalServerPort;

        $self->{customMonthList}        = [$self->constMonthList];
        $self->{customDayList}          = [$self->constDayList];

        $self->{promptWaitTime}         = $self->constPromptWaitTime;
        $self->{loginWarningTime}       = $self->constLoginWarningTime;

        if ($^O eq 'MSWin32') {
            $self->{toolbarLabelFlag} = FALSE;
        } else {
            $self->{toolbarLabelFlag} = TRUE;
        }

        return $self;
    }

    ##################
    # Methods

    # Support functions for ->new

    sub compileCharSets {

        # Called by $self->new to set the contents of $self->charSetList
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
            $latinFlag, $unicodeFlag, $strictFlag, $extendFlag,
            @allList, @modList,
        );

        # Check for improper arguments
        if (defined $check) {

            # Global variable $axmud::CLIENT not set yet, so we'll just have to print the
            #   improper arguments message
            print "IMPROPER ARGUMENTS: Games::Axmud::Client->compileCharSets "
                . join(' ', @_) . "\n";
            return undef;
        }

        # Get the Perl module's list of all charsets
        @allList = Encode->encodings(":all");

        # Some encodings are more important for Axmud than others. If the list contains them, move
        #   them to the top of the list
        # (We'll sort the list first, although it should already be sorted)
        foreach my $item (sort {lc($a) cmp lc($b)} (@allList)) {

            if ($item eq 'iso-8859-1') {
                $latinFlag = TRUE;
            } elsif ($item eq 'utf8') {
                $unicodeFlag = TRUE;
            } elsif ($item eq 'utf-8-strict') {
                $strictFlag = TRUE;
            } elsif ($item eq 'cp437') {
                $extendFlag = TRUE;
            } else {
                push (@modList, $item);
            }
        }

        if ($extendFlag) {

            unshift (@modList, 'cp437');
        }

        if ($strictFlag) {

            unshift (@modList, 'utf-8-strict');
        }

        if ($unicodeFlag) {

            unshift (@modList, 'utf8');
        }

        if ($latinFlag) {

            unshift (@modList, 'iso-8859-1');
        }

        # Set the IV
        $self->{charSetList} = \@modList;

        return 1;
    }

    sub setXTermColours {

        # Called by $self->new to set the contents of $self->constXTermColourHash and
        #   ->constNetscapeColourHash, based on a fixed algorithm borrowed from
        #   http://www.gammon.com.au/forum/bbshowpost.php?id=7761&page=4
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (%xTermHash, %netscapeHash);

        # Check for improper arguments
        if (defined $check) {

            # Global variable $axmud::CLIENT not set yet, so we'll just have to print the
            #   improper arguments message
            print "IMPROPER ARGUMENTS: Games::Axmud::Client->setXTermColours "
                . join(' ', @_) . "\n";
            return undef;
        }

        # Generate the xterm colour cube
        %xTermHash = $self->generateColourCube(
            0,
            95,
            135,
            175,
            215,
            255,
        );

        $self->{constXTermColourHash} = \%xTermHash;

        # Generate the netscape colour cube
        %netscapeHash = $self->generateColourCube(
            0,
            51,
            102,
            153,
            204,
            255,
        );

        $self->{constNetscapeColourHash} = \%netscapeHash;

        return 1;
    }

    sub generateColourCube {

        # Called by $self->setXTermColours to generate one of the two colour cubes used by Axmud:
        #   either the xterm colour cube or the netscape colour cube
        #
        # Expected arguments
        #   @valueList
        #       - Set of values that differentiate the two colour cubes
        #           - Set to (0, 95, 135, 175, 205, 255) for the xterm colour cube
        #           - Set to (0, 51, 102, 153, 204, 255) for the netscape colour cube
        #
        # Return values
        #   An empty hash on improper arguments
        #   Otherwise returns a hash converting an xterm colour tag (a string in the range 'x0' to
        #       'x255') into an RGB colour tag (a string in the range '#000000' to '#FFFFFF')

        my ($self, @valueList) = @_;

        # Local variables
        my (
            @colourList,
            %emptyHash, %returnHash,
        );

        # Check for improper arguments
        if (! @valueList) {

            # Global variable $axmud::CLIENT not set yet, so we'll just have to print the
            #   improper arguments message
            print "IMPROPER ARGUMENTS: Games::Axmud::Client->generateColourCube "
                . join(' ', @_) . "\n";
            return %emptyHash;
        }

        # Add basic xterm colour tags x0 - x15
        push (@colourList,
            $self->convertRGB(0, 0, 0),         # black
            $self->convertRGB(128, 0, 0),       # maroon
            $self->convertRGB(0, 128, 0),       # green
            $self->convertRGB(128, 128, 0),     # olive
            $self->convertRGB(0, 0, 128),       # navy
            $self->convertRGB(128, 0, 128),     # purple
            $self->convertRGB(0, 128, 128),     # teal
            $self->convertRGB(192, 192, 192),   # silver

            $self->convertRGB(128, 128, 128),   # grey
            $self->convertRGB(255, 0, 0),       # red
            $self->convertRGB(0, 255, 0),       # lime
            $self->convertRGB(255, 255, 0),     # yellow
            $self->convertRGB(0, 0, 255),       # blue
            $self->convertRGB(255, 0, 255),     # magenta
            $self->convertRGB(0, 255, 255),     # cyan
            $self->convertRGB(255, 255, 255),   # white
        );

        # Add extended xterm colour tags x16 - x230
        for (my $red = 0; $red < 6; $red++) {

            for (my $green = 0; $green < 6; $green++) {

                for (my $blue = 0; $blue < 6; $blue++) {

                    $colourList[(16 + ($red * 36) + ($green * 6) + $blue)]
                        = $self->convertRGB(
                            $valueList[$red],
                            $valueList[$green],
                            $valueList[$blue],
                        );
                }
            }
        }

        # Add greyscale xterm colour tags x231-x255
        for (my $grey = 0; $grey < 24; $grey++) {

            my $value = 8 + ($grey * 10);

            $colourList[($grey + 232)] = $self->convertRGB($value, $value, $value);
        }

        # Prepare the return hash
        for (my $index = 0; $index < 256; $index++) {

            $returnHash{'x' . $index} = $colourList[$index];
        }

        return %returnHash;
    }

    sub convertRGB {

        # Called by $self->generateColourCube, which was in turn called by $self->setXTermColours
        #   and $self->new
        # Converts an xterm-256 colour (using a 6x6x6 colour cube) into an RGB colour tag
        #
        # Expected arguments
        #   $red    - An integer in the range 0-255
        #   $green  - An integer in the range 0-255
        #   $blue   - An integer in the range 0-255
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns an RGB colour tag like '#000000'

        my ($self, $red, $green, $blue, $check) = @_;

        # Check for improper arguments
        if (! defined $red || ! defined $green || ! defined $blue || defined $check) {

            # Global variable $axmud::CLIENT not set yet, so we'll just have to print the
            #   improper arguments message
            print "IMPROPER ARGUMENTS: Games::Axmud::Client->convertRGB " . join(' ', @_) . "\n";
            return undef;
        }

        return ('#' . sprintf('%02X%02X%02X', $red, $green, $blue));
    }

    sub compileSoundEffects {

        # Called by $self->new to set the contents of $self->constExtendedSoundHash; one key-value
        #   pair for every sound file in /items/sounds
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the /items/sounds directory doesn't exist
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $dir, $dirHandle, $regex,
            @fileList,
            %hash,
        );

        # Check for improper arguments
        if (defined $check) {

            # Global variable $axmud::CLIENT not set yet, so we'll just have to print the
            #   improper arguments message
            print "IMPROPER ARGUMENTS: Games::Axmud::Client->compileSoundEffects "
                . join(' ', @_) . "\n";
            return undef;
        }

        $dir = $axmud::SHARE_DIR . '/items/sounds/';
        if (! -e $dir) {

            return undef;
        }

        # Get a list of text files in this directory
        if (! opendir ($dirHandle, $dir)) {

            return undef;

        } else {

            @fileList = readdir ($dirHandle);
            closedir $dirHandle;
        }

        # Filter out non-sound files
        $regex = '\.(' . join('|', $self->ivKeys('constSoundFormatHash')) . ')$';
        foreach my $file (@fileList) {

            my $name;

            if ($file =~ m/$regex/) {

                $name = $file;
                $name =~ s/$regex//;

                $hash{$name} = $file;
            }
        }

        # Set the IV
        $self->{constExtendedSoundHash} = \%hash;

        return 1;
    }

    # Start / stop

    sub start {

        # Called by axmud.pl on startup, immediately after the call to GA::Client->new
        # Starts the client. Opens the first 'main' window, and prompts the user to connect to a
        #   world
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if setup fails
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $warningFlag, $roomObj, $exitObj, $desktopObj, $host, $engine, $port, $world, $profObj,
            $taskObj, $offlineFlag,
            @list,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->start', @_);
        }

        # Set the date/time at which the client started
        $self->ivPoke('startTime', $self->localTime());
        $self->ivPoke('startClock', $self->localClock());
        $self->ivPoke('startDate', $self->localDate());
        $self->ivPoke('startClockString', $self->localClockString());
        $self->ivPoke('startDateString', $self->localDateString());

        # In Axmud blind mode, TTS is always enabled
        if ($axmud::BLIND_MODE_FLAG) {

            $self->ivPoke('systemAllowTTSFlag', TRUE);
        }

        # On MS Windows, see if an eSpeak engine is installed, and set the IV
        if ($^O eq 'MSWin32') {

            if (-e "C:\\Program Files\\espeak\\command_line\\espeak.exe") {

                $self->ivPoke('eSpeakPath', "C:\\Program Files\\espeak\\command_line\\espeak");

            } elsif (-e "C:\\Program Files (x86)\\espeak\\command_line\\espeak.exe") {

                $self->ivPoke(
                    'eSpeakPath',
                    "C:\\Program Files (x86)\\espeak\\command_line\\espeak",
                );
            }
        }

        # Load the basic mudlist, and store the data in GA::Obj::BasicWorld objects. The data
        #   isn't important, so don't disable loading/saving of data files if the operation fails
        if (! $self->loadBasicWorlds()) {

            $warningFlag = TRUE;
            $self->writeWarning(
                'Could not load basic mudlist (files possible corrupted)',
                $self->_objClass . '->start',
            );
        }

        # Load phrasebooks, and store the data in GA::Obj::PhraseBook objects. The data isn't
        #   important, so don't disable loading/saving of data files if the operation fails
        if (! $self->loadPhrasebooks()) {

            $warningFlag = TRUE;
            $self->writeWarning(
                'Could not load phrasebooks (files possible corrupted)',
                $self->_objClass . '->start',
            );
        }

        # Create the file objects stored by this GA::Client object
        if (! $self->createFileObjs()) {

            $warningFlag = TRUE;
            $self->writeWarning(
                'Could not create file objects for the client - loading/saving disabled',
                $self->_objClass . '->start',
            );

            # Disable all loading/saving of data files (the TRUE argument means 'don't prompt the
            #   user to do an emergency save')
            $self->disableAllFileAccess(TRUE);
        }

        # Make sure all standard directories exist
        if (! $self->createDataDirs()) {

            $warningFlag = TRUE;
            $self->writeWarning(
                'Could not create standard directories - loading/saving disabled',
                $self->_objClass . '->start',
            );

            # Disable all loading/saving of data files (the TRUE argument means 'don't prompt the
            #   user to do an emergency save')
            $self->disableAllFileAccess(TRUE);
        }

        # Delete everything in the temporary directories
        # (The former is for plugins; the latter is for Axmud code)
        foreach my $tempDir ($axmud::DATA_DIR . '/tmp/', $axmud::DATA_DIR . '/data/temp/') {

            # Simplest way to empty the directory and all its sub-directories seems to be to
            #   destroy the directory and make a new one
            File::Path::remove_tree($tempDir);
            mkdir ($tempDir, 0755);
        }

        # Create interface model objects (which store default values for interfaces - triggers,
        #   aliases, macros, timers and hooks)
        @list = ('trigger', 'alias', 'macro', 'timer', 'hook');
        foreach my $type (@list) {

            my ($package, $obj);

            $package = 'Games::Axmud::InterfaceModel::' . ucfirst($type);
            $obj = $package->new();
            if (! $obj) {

                # (Allow writing to something other than GA::Session - there are no sessions yet)
                return $self->writeError(
                    'Could not create interface model objects',
                    $self->_objClass . '->start',
                );

            } else {

                $self->ivAdd('interfaceModelHash', $type, $obj);
            }
        }

        # Create standard zonemaps
        $self->createStandardZonemaps();
        # Create standard winmaps
        $self->createStandardWinmaps();
        # Create standard colour schemes
        $self->createStandardColourSchemes();
        # Set up supported MCP packages
        $self->createSupportedMcpPackages();
        # Set up keycodes for the current system
        $self->setupKeycodes();
        # Create default TTS objects
        $self->ttsCreateStandard();

        # Create a room object and an exit object with default values for their IVs, used to supply
        #   default values for all other room/exit objects
        $roomObj = Games::Axmud::ModelObj::Room->new($self, 'default', 'global');
        $exitObj = Games::Axmud::Obj::Exit->new($self, 'default', 'global');
        if (! $roomObj || ! $exitObj) {

            return $self->writeError(
                'Could not initialise the default room and exit objects',
                $self->_objClass . '->start',
            );

        } else {

            $axmud::DEFAULT_ROOM = $roomObj;
            $axmud::DEFAULT_EXIT = $exitObj;
        }

        # Load (or create) the config file (if allowed)
        if (! $self->configFileObj->setupConfigFile()) {

            $warningFlag = TRUE;
            $self->writeWarning(
                'Error reading (or creating) the ' . $axmud::SCRIPT . ' config file - loading'
                . '/saving disabled',
                $self->_objClass . '->start',
            );

            # Disable all loading/saving of data files (the TRUE argument means 'don't prompt the
            #   user to do an emergency save')
            $self->disableAllFileAccess(TRUE);
        }

        # Any changes to IV values which could not be applied immediately, the last time Axmud was
        #   running, should be applied now
        # (->restartShareMainWinMode is 'default' if no change is required, or 'off' / 'on' if a
        #   change is required)
        if ($self->restartShareMainWinMode ne 'default') {

            if ($self->restartShareMainWinMode eq 'off') {
                $self->ivPoke('shareMainWinFlag', FALSE);
            } else {
                $self->ivPoke('shareMainWinFlag', TRUE);
            }

            $self->ivPoke('restartShareMainWinMode', 'default');
        }

        # Initialise the default set of toolbar button objects
        if (! $self->initialiseToolbar()) {

            return $self->writeError(
                'Could not initialise toolbar button objects',
                $self->_objClass . '->start',
            );
        }

        # Create the main desktop object. Set up the default workspace, set up window icons, prepare
        #   rc-file styles for each kind of window, create the first 'main' window
        $desktopObj = Games::Axmud::Obj::Desktop->new();
        if (! $desktopObj) {

            return $self->writeError(
                'Could not set up the desktop',
                $self->_objClass . '->start',
            );

        } else {

            $self->ivPoke('desktopObj', $desktopObj);
            if (! $desktopObj->start()) {

                return $self->writeError(
                    'Could not set up the desktop',
                    $self->_objClass . '->start',
                );

            } else {

                # Loading of data files and plugins could take some seconds; make the whole 'main'
                #   window visible in the meantime
                $desktopObj->updateWidgets($self->_objClass . '->start');
            }
        }

        # Perform an auto-backup of Axmud's data directory, if required
        if (
            $self->autoBackupMode eq 'all_start'
            || (
                $self->autoBackupMode eq 'interval_start' && $self->checkBackupInterval()
            )
        ) {
            $self->doAutoBackup();
        }

        # Display a 'dialogue' window while loading data files/plugins
        if (! $axmud::TEST_MODE_FLAG && ! $axmud::BLIND_MODE_FLAG) {

            $self->mainWin->showBusyWin();
        }

        # If the user is using a new version of Axmud, check if there are any new pre-configured
        #   worlds in this version. If so, insert them into Axmud's data directory
        if (
            $self->convertVersion($axmud::VERSION) > $self->convertVersion($self->prevClientVersion)
        ) {
            $self->insertPreConfigWorlds();
            # Don't perform this operation again until the next Axmud release
            $self->ivPoke('prevClientVersion', $axmud::VERSION);
        }

        # Load world profiles, creating a file object for each (if allowed, and if there are any to
        #   load)
        if ($self->loadDataFlag && $self->configWorldProfList && ! $axmud::TEST_PRE_CONFIG_FLAG) {

            if (! $self->loadWorldProfs() ) {

                $warningFlag = TRUE;
                $self->writeWarning(
                    'Error loading the world profiles expected after reading the \'config\''
                    . ' file',
                    $self->_objClass . '->start',
                );
            }
        }

        # Load data for the remaining file objects ('tasks', 'scripts', 'contacts', 'dicts',
        #   'toolbar', 'usercmds', 'zonemaps', 'winmaps', 'tts')
        if ($self->loadDataFlag && ! $self->loadOtherFiles()) {

            $warningFlag = TRUE;
            $self->writeWarning(
                'Error reading (or creating) data files - loading/saving disabled',
                $self->_objClass . '->start',
            );

            # Disable all loading/saving of data files (the TRUE argument means 'don't prompt the
            #   user to do an emergency save')
            $self->disableAllFileAccess(TRUE);
        }

        # Add remaining workspaces, if any are specified
        $desktopObj->setupWorkspaces();

        # Set up client commands
        if (! $self->setupCmds()) {

            # (Allow writing to something other than GA::Session - there are no sessions yet)
            return $self->writeError(
                'Could not initialise ' . $axmud::SCRIPT . ' client commands',
                $self->_objClass . '->start',
            );
        }

        # Delete the contents of log directories (leaving files inside worlds' own log directories
        #   intact), if the flag is set (but don't delete directories if this function has produced
        #   any warning messages - so that the messages aren't lost
        if ($self->deleteStandardLogsFlag && ! $warningFlag) {

            $self->deleteStandardLogs();
        }

        # Load plugins in the /private directory, if it exists (will not exist in any public release
        #   of Axmud)
        if (-e $axmud::SHARE_DIR . '/private') {

            $self->loadPrivatePlugins();
        }

        # Load initial plugins
        if ($self->initPluginList) {

            foreach my $pluginPath ($self->initPluginList) {

                if (! $self->loadPlugin($pluginPath)) {

                    $self->writeWarning(
                        'Error loading the plugin \'' . $pluginPath . '\'',
                        $self->_objClass . '->start',
                    );
                }
            }
        }

        # Close the 'dialogue' window and reset the Client IV that stores it
        if ($self->busyWin) {

            $self->mainWin->closeDialogueWin($self->busyWin);
        }

        # Start the client loop
        if (! $self->startClientLoop()) {

            return $self->writeError(
                'Could not start the client loop',
                $self->_objClass . '->start',
            );
        }

        # Prepare to initialise connections
        if ($self->showSetupWizWinFlag) {

            # When Axmud runs for the first time (specifically, when there is no Axmud config file)
            #   this flag will be set to TRUE, instructing us to open the Setup 'wiz' window so the
            #   new user can initialise a few settings
            if ($axmud::TEST_MODE_FLAG) {

                # In Axmud test mode, don't show the Setup window at all; just insert a couple of
                #   tasks into the global initial tasklist
                $self->addGlobalInitTask('status_task');
                $self->addGlobalInitTask('locator_task');

                # Don't show the setup window twice
                $self->set_showSetupWizWinFlag(FALSE);

            } elsif ($axmud::BLIND_MODE_FLAG) {

                # In Axmud blind mode, don't show the Setup window at all; instead, insert a few
                #   tasks into the global initial tasklist, and modify a few of their settings
                #   (specifically, none of them open a task window)
                $taskObj = $self->addGlobalInitTask('status_task');
                if ($taskObj) {

                    $taskObj->set_startWithWinFlag(FALSE);
                }

                $taskObj = $self->addGlobalInitTask('locator_task');
                if ($taskObj) {

                    $taskObj->set_startWithWinFlag(FALSE);
                }

                $taskObj = $self->addGlobalInitTask('compass_task');
                if ($taskObj) {

                    $taskObj->set_startWithWinFlag(FALSE);
                }

                $taskObj = $self->addGlobalInitTask('divert_task');
                if ($taskObj) {

                    $taskObj->set_requireWinFlag(FALSE);
                    $taskObj->set_startWithWinFlag(FALSE);
                    # Turn off sound effects, since TTS is used instead
                    $taskObj->ivUndef('tellAlertSound');
                    $taskObj->ivUndef('socialAlertSound');
                    $taskObj->ivUndef('customAlertSound');
                    $taskObj->ivUndef('warningAlertSound');
                    $taskObj->ivUndef('otherAlertSound');
                }

                # Don't show the setup window twice
                $self->set_showSetupWizWinFlag(FALSE);

            } else {

                # Open the setup window. When it closes, it will open the Connections window for us
                $self->mainWin->quickFreeWin('Games::Axmud::WizWin::Setup');

                # Don't show the setup window twice
                $self->set_showSetupWizWinFlag(FALSE);

                return 1;
            }
        }

        if (@ARGV) {

            # The user started Axmud with arguments, e.g. from a Linux terminal:
            #   ./axmud.pl deathmud.com 5000
            # If the port is not specified, the generic port is used:
            #   ./axmud.pl deathmud.com          (use port 23)
            # The user can also specify a world profile name:
            #   ./axmud.pl deathmud
            #
            # Any of those formats can use baxmud.pl rather than axmud.pl
            # Any of those formats can specify one of Axmud's supported text-to-speech engines,
            #   after all the other arguments (any of the items in $self->constTTSList, e.g.
            #   'festival'). If a recognised speech engine is specified, that engine is used for
            #   all text-to-speech while Axmud is running
            $engine = $ARGV[-1];
            if (defined $engine && defined $self->ivFind('constTTSList', $engine)) {

                pop @ARGV;
                $self->ivPoke('forceTTSEngine', $engine);
            }
        }

        if (@ARGV) {

            $host = shift @ARGV;
            $port = shift @ARGV;
            if (@ARGV) {

                # (Allow writing to something other than GA::Session - there are no sessions yet)
                return $self->writeError(
                    'Invalid command line arguments (try \'<host> <port>\', \'<host>\' or'
                    . ' \'<world_name>\')',
                    $self->_objClass . '->start',
                );
            }

            if (! $port && $self->ivExists('worldProfHash', $host)) {

                # $host is a world profile name
                $world = $host;
                $profObj = $self->ivShow('worldProfHash', $world);
                ($host, $port) = $profObj->getConnectDetails();

                if (! $self->startSession($world, $host, $port)) {

                    # (Allow writing to something other than GA::Session - there are no sessions
                    #   yet)
                    return $self->writeError(
                        'Could not open a session connecting to \'' . $host . '\'',
                        $self->_objClass . '->start',
                    );
                }

            } else {

                # $host is a host address. Get a temporary world name
                $world = $self->getTempProfName();
                if (
                    ! $world
                    || ! $self->startSession(
                        $world,
                        $host,
                        $port,
                        undef,      # No character
                        undef,      # No password
                        undef,      # No account
                        undef,      # Default protocol
                        undef,      # No login mode
                        FALSE,      # Not offline mode
                        TRUE,       # Temporary world profile
                    )
                ) {
                    # (Allow writing to something other than GA::Session - there are no sessions
                    #   yet)
                    return $self->writeError(
                        'Could not open a session connecting to \'' . $host . '\'',
                        $self->_objClass . '->start',
                    );
                }
            }

        } elsif ($axmud::BLIND_MODE_FLAG && ! $self->autoConnectList) {

            # In Axmud blind mode, open a series of standard 'dialogue' windows, allowing the
            #   visually-impaired user to select/create a world and/or character
            $self->connectBlind();

        } elsif ($axmud::TEST_MODE_FLAG) {

            # In Axmud test mode, connect to a world which is assumed to be running on the local
            #   machine
            if (! $axmud::TEST_MODE_LOGIN_LIST[5]) {
                $offlineFlag = TRUE;
            } else {
                $offlineFlag = undef;
            }

            if (
                ! $self->startSession(
                    $axmud::TEST_MODE_LOGIN_LIST[0],        # World
                    $axmud::TEST_MODE_LOGIN_LIST[1],        # Host
                    $axmud::TEST_MODE_LOGIN_LIST[2],        # Post
                    $axmud::TEST_MODE_LOGIN_LIST[3],        # Character
                    $axmud::TEST_MODE_LOGIN_LIST[4],        # Password
                    undef,                                  # Account
                    undef,                                  # Default protocol
                    undef,                                  # No login mode
                    $offlineFlag,
                )
            ) {
                return undef;
            }

        } elsif ($self->autoConnectList) {

            # Connect to all the worlds specified by the auto-connection list
            OUTER: foreach my $line ($self->autoConnectList) {

                my (
                    $worldName, $worldObj, $host, $port, $char, $password, $account,
                    @list,
                );

                # Each line is in the form <world> <optional_char> <optional_char>...
                @list = split(/\s+/, $line);
                $worldName = shift @list;

                # Check the world exists and, if not, ignore this line
                $worldObj = $self->ivShow('worldProfHash', $worldName);
                if (! $worldObj) {

                    next OUTER;
                }

                if (! @list) {

                    # Get connection details for this world
                    ($host, $port) = $worldObj->getConnectDetails();

                    # Connect without a character
                    if (
                        $self->startSession($worldName, $host, $port)
                        && $axmud::BLIND_MODE_FLAG
                    ) {
                        # In blind mode, stop after the first successful connection
                        last OUTER;
                    }

                } else {

                    INNER: foreach my $thisChar (@list) {

                        # Check that the character profile exists
                        my $profType = $worldObj->ivShow('profHash', $thisChar);
                        if (! defined $profType || $profType ne 'char') {

                            next INNER;
                        }

                        # Check that a connection has already been initiated for this world/
                        #   character combination
                        foreach my $session ($self->ivValues('sessionHash')) {

                            if (
                                $session->initWorld eq $worldName
                                && $session->initChar
                                && $session->initChar eq $thisChar
                            ) {
                                next INNER;
                            }
                        }

                        # Get connection details for this world
                        ($host, $port, $char, $password, $account)
                            = $worldObj->getConnectDetails($thisChar);

                        # Connect with a character
                        if (
                            $self->startSession(
                                $worldName,
                                $host,
                                $port,
                                $char,
                                $password,
                                $account
                            )
                            && $axmud::BLIND_MODE_FLAG
                        ) {
                            # In blind mode, stop after the first successful connection
                            last OUTER;
                        }
                    }
                }
            }

            # During this process, if no connections were actually initialised, open the Connections
            #   window as normal (except in Axmud blind mode)
            if (! $self->sessionHash) {

                if ($axmud::BLIND_MODE_FLAG) {
                    $self->connectBlind();
                } else {
                    $self->mainWin->quickFreeWin('Games::Axmud::OtherWin::Connect');
                }
            }

        } else {

            # Open the Connections window. If the user wants to connect to a world, it calls
            #   GA::Client->startSession
            $self->mainWin->quickFreeWin('Games::Axmud::OtherWin::Connect');
        }

        return 1;
    }

    sub stop {

        # Called by axmud.pl on shutdown
        # Also called by $self->stopSession, GA::Cmd::StopClient->do, GA::Cmd::Panic->do,
        #   GA::Cmd::RestoreWorld->do, GA::Win::Internal->setDeleteEvent and
        #   GA::Strip::MenuBar->drawWorldColumn
        # Stops the client
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $tempDir;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->stop', @_);
        }

        # The END() function will call this function again, before terminating the script, unless
        #   we set this flag
        # (The TRUE value also gives GA::Obj::WorkspaceGrid->stop to destroy a shared 'main'
        #   window, rather than just disengaging it)
        $self->ivPoke('shutdownFlag', TRUE);

        # This flag prevents multiple concurrent calls to this function if, for example, the user
        #   is repeatedly clicking the 'main' window's close button
        if ($self->terminatingFlag) {

            return undef;

        } else {

            $self->ivPoke('terminatingFlag', TRUE);
        }

        # Perform an auto-backup of Axmud's data directory, if required
        if (
            $self->autoBackupMode eq 'all_stop'
            || (
                $self->autoBackupMode eq 'interval_stop' && $self->checkBackupInterval()
            )
        ) {
            $self->doAutoBackup();
        }

        # Fire any hooks in any session that are using the 'close_disconnect' hook event
        foreach my $sessionObj ($self->listSessions()) {

            $sessionObj->checkHooks('close_disconnect');
        }

        # Stop every current session
        if ($self->sessionHash && ! $self->stopAllSessions()) {

            return $self->writeError(
                'Could not stop all sessions',
                $self->_objClass . '->stop',
            );
        }

        # Stop the client loop (if running)
        if ($self->clientLoopObj && ! $self->stopClientLoop()) {

            return $self->writeError(
                'Could not stop the client loop',
                $self->_objClass . '->stop',
            );
        }

        # Close any remaining 'internal' windows, restore 'external' windows to their original size/
        #   position, close any remaining 'free' windows
        if (! $self->desktopObj->stop()) {

            return $self->writeError(
                'Could not stop the desktop object',
                $self->_objClass . '->stop',
            );
        }

        # Delete everything in the temporary directories
        # (The former is for plugins; the latter is for Axmud code)
        foreach my $tempDir ($axmud::DATA_DIR . '/tmp/', $axmud::DATA_DIR . '/data/temp/') {

            # Simplest way to empty the directory and all its sub-directories seems to be to
            #   destroy the directory and make a new one
            File::Path::remove_tree($tempDir);
            mkdir ($tempDir, 0755);
        }

        # Halt Gtk3, which halts Axmud
        Gtk3->main_quit();

        return 1;
    }

    # Setup

    sub loadBasicWorlds {

        # Called by $self->start
        # Loads data from the basic mudlist and stores it in GA::Obj::BasicWorld objects, ready for
        #   the Connections window to display
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if the file can't be read or if it appears to be
        #       corrupted
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my (
            $path, $fileHandle, $exitFlag,
            @list,
            %hash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->loadBasicWorlds', @_);
        }

        $path = $axmud::SHARE_DIR . '/items/mudlist/mudlist.txt';
        if (! -e $path) {

            return undef;
        }

        # Open the file for reading
        if (! open ($fileHandle, "<$path")) {

            return undef;
        }

        # Read the file
        do {

            my $line = <$fileHandle>;

            # Without this line, Cyrillic text is read as gibberish
            $line = Encode::decode('utf8', $line);

            if (! defined $line) {

                $exitFlag = TRUE;

            # Ignore empty lines and comments
            } elsif ($line =~ m/\S/ && ! ($line =~ m/^\s*\#/)) {

                chomp $line;
                push (@list, $self->trimWhitespace($line));
            }

        } until ($exitFlag);

        close $fileHandle;

        if (! @list) {

            # File is empty
            return undef;
        }

        # Store the data
        do {

            my ($longName, $name, $host, $port, $adultFlag, $language, $obj);

            $longName = shift @list;
            $name = shift @list;
            $host = shift @list;
            $port = shift @list;
            $adultFlag = shift @list;
            $language = shift @list;

            # Check that a line isn't missing (and that an extra line hasn't been inserted) by
            #   checking the value of the flag, which can only be 0 or 1, and also by checking that
            #   $language is defined (which also means missing or additional lines)
            if (
                (! defined $adultFlag || ($adultFlag ne '1' && $adultFlag ne '0'))
                || ! defined $language
            ) {
                # File corrupted
                return undef;
            }

            # $adultFlag must be TRUE or FALSE
            if (! $adultFlag) {
                $adultFlag = FALSE;
            } else {
                $adultFlag = TRUE;
            }

            # Create an object to store basic details for this world
            $obj = Games::Axmud::Obj::BasicWorld->new(
                $name,
                $longName,
                $host,
                $port,
                $adultFlag,
                $language,
            );

            if (! $obj) {

                # Improper args or $name is invalid
                return undef;

            } else {

                $hash{$name} = $obj;
            }

        } until (! @list);

        # Data loaded successfully; store it
        $self->{constBasicWorldHash} = \%hash;

        # Operation complete
        return 1;
    }

    sub loadPhrasebooks {

        # Called by $self->start
        # Loads data from the phrasebook files and stores it in GA::Obj::Phrasebook objects
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if the file can't be read or if it appears to be
        #       corrupted
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my (
            $dirHandle, $dir,
            @fileList, @modList,
            %hash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->loadPhrasebooks', @_);
        }

        $dir = $axmud::SHARE_DIR . '/items/phrasebooks/';
        if (! -e $dir) {

            return undef;
        }

        # Get a list of text files in this directory
        if (! opendir ($dirHandle, $dir)) {

            return undef;

        } else {

            @fileList = readdir ($dirHandle);
            closedir $dirHandle;
        }

        # Filter out the file template (beginning with an underline) and anything that's not a .txt
        #   file
        foreach my $file (@fileList) {

            if ($file =~ m/^[A-Za-z].*\.txt$/) {

                push (@modList, $file);
            }
        }

        if (! @modList) {

            return undef;
        }

        # Read each file in turn, creating a new phrasebook object for each
        foreach my $file (@modList) {

            my (
                $path, $fileHandle, $pbObj, $exitFlag, $name, $targetName, $nounPosn, $number,
                @lineList, @primaryDirList, @primaryAbbrevDirList, @definiteList, @indefiniteList,
                @andList, @orList, @numberList,
            );

            # Open the file for reading
            $path = $dir . $file;
            if (! open ($fileHandle, "<$path")) {

                return undef;
            }

            # Read the file
            do {

                my $line = <$fileHandle>;

                # Without this line, the Russian phrasebook is gibberish
                $line = Encode::decode('utf8', $line);

                if (! defined $line) {

                    $exitFlag = TRUE;

                } elsif ($line =~ m/^\s*[[:alnum:]]/) {

                    # Ignore empty lines and lines starting with a #
                    chomp $line;
                    push (@lineList, $self->trimWhitespace($line));
                }

            } until ($exitFlag);

            close $fileHandle;

            # Interpret the data
            $name = shift @lineList;
            $targetName = shift @lineList;
            $nounPosn = shift @lineList;

            for (my $count = 0; $count < 18; $count++) {

                push (@primaryDirList, shift @lineList);
            }

            for (my $count = 0; $count < 18; $count++) {

                push (@primaryAbbrevDirList, shift @lineList);
            }

            $number = shift @lineList;
            if (! $self->intCheck($number, 0)) {

                return undef;

            } elsif ($number > 0) {

                for (my $count = 0; $count < $number; $count++) {

                    push (@definiteList, shift @lineList);
                }
            }

            $number = shift @lineList;
            if (! $self->intCheck($number, 0)) {

                return undef;

            } elsif ($number > 0) {

                for (my $count = 0; $count < $number; $count++) {

                    push (@indefiniteList, shift @lineList);
                }
            }

            $number = shift @lineList;
            if (! $self->intCheck($number, 0)) {

                return undef;

            } elsif ($number > 0) {

                for (my $count = 0; $count < $number; $count++) {

                    push (@andList, shift @lineList);
                }
            }

            $number = shift @lineList;
            if (! $self->intCheck($number, 0)) {

                return undef;

            } elsif ($number > 0) {

                for (my $count = 0; $count < $number; $count++) {

                    push (@orList, shift @lineList);
                }
            }

            for (my $count = 0; $count < 10; $count++) {

                push (@numberList, shift @lineList);
            }

            # There shouldn't be anything left
            if (@lineList) {

               return undef;
            }

            # Store the data in a phrasebook object
            $pbObj = Games::Axmud::Obj::Phrasebook->new($name, $targetName);
            if (! $pbObj) {

                return undef;

            } else {

                if (substr($nounPosn, 0, 1) eq 'n') {
                    $pbObj->ivPoke('nounPosn', 'noun_adj');
                } else {
                    $pbObj->ivPoke('nounPosn', 'adj_noun');
                }

                $pbObj->ivPoke('primaryDirList', @primaryDirList);
                $pbObj->ivPoke('primaryAbbrevDirList', @primaryAbbrevDirList);
                $pbObj->ivPoke('definiteList', @definiteList);
                $pbObj->ivPoke('indefiniteList', @indefiniteList);
                $pbObj->ivPoke('andList', @andList);
                $pbObj->ivPoke('orList', @orList);
                $pbObj->ivPoke('numberList', @numberList);

                $hash{$name} = $pbObj;
            }
        }

        $self->{constPhrasebookHash} = \%hash;

        # Operation complete
        return 1;
    }

    sub createFileObjs {

        # Called by $self->start
        # Creates the file objects (GA::Obj::File) that are stored in this GA::Client's registry
        #   (omitting those which are stored in GA::Session's registry)
        # NB Does not create any 'worldprof' file objects yet
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if any of the file objects can't be created
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createFileObjs', @_);
        }

        # The list of file object types to create
        @list = (
            'config', 'tasks', 'scripts', 'contacts', 'dicts', 'toolbar', 'usercmds', 'zonemaps',
            'winmaps', 'tts',
        );

        # Create the FileObjs
        foreach my $type (@list) {

            my $obj = Games::Axmud::Obj::File->new($type);

            if (! $obj) {

                return undef;

            } else {

                # FileObj created
                $self->ivAdd('fileObjHash', $type, $obj);
                if ($type eq 'config') {

                    $self->ivPoke('configFileObj', $obj);
                }
            }
        }

        # All file objects created
        return 1;
    }

    sub setModifyFlag {

        # Called by anything
        # Sets a file object's ->modifyFlag, first checking that the file object actually exists
        #   (and displaying a warning, if not)
        # NB 'otherprof' and 'worldmodel' file objects can't be accessed from here. Use
        #   GA::Session->setModifyFlag instead
        # NB The GA::Session->setModifyFlag can be called for any file object stored in the client's
        #   registry; it passes requests directly to this function
        #
        # Expected arguments
        #   $objName    - The unique name of the file object, matching a key in $self->fileObjHash
        #                   ('config', 'tasks', 'scripts', 'contacts', 'dicts', 'toolbar',
        #                   'usercmds', 'zonemaps', 'winmaps', 'tts' or the name of a world profile)
        #   $flag       - The setting for the flag (TRUE of FALSE)
        #
        # Optional arguments
        #   $func       - The calling function. Ignored for now, if specified
        #
        # Return values
        #   'undef' on improper arguments
        #   $flag on success

        my ($self, $objName, $flag, $func, $check) = @_;

        # Check for improper arguments
        if (! defined $objName || ! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setModifyFlag', @_);
        }

        # Check the file object exists
        if (! $self->ivExists('fileObjHash', $objName)) {

            return $self->writeWarning(
                'Missing file object \'' . $objName . '\' - can\'t set its modified data flag',
                $self->_objClass . '->setModifyFlag',
            );

        } else {

            return $self->ivShow('fileObjHash', $objName)->set_modifyFlag($flag);
        }
    }

    sub createDataDirs {

        # Called by $self->start and by GA::Obj::File->setupConfigFile
        # Creates any standard Axmud data directories that don't already exist
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createDataDirs', @_);
        }

        # Check for data directories created by previous versions of Axmud (which will have
        #   different names)
        if (! -e $axmud::DATA_DIR) {

            OUTER: foreach my $nameShort (@axmud::COMPAT_DIR_LIST) {

                my ($dataDir, $config);

                # (Ignore the directory we already know doesn't exist)
                if ($nameShort ne $axmud::NAME_SHORT) {

                    $dataDir = File::HomeDir->my_home . '/' . $nameShort . '-data';
                    if (-e $dataDir) {

                        # Data directory exists; rename it and its config file
                        if (File::Copy::Recursive::dirmove($dataDir, $axmud::DATA_DIR)) {

                            # MSWin uses .ini, everything else uses .conf
                            $config = $axmud::DATA_DIR . '/' . $nameShort . '.';
                            if (-e $config . 'ini') {

                                File::Copy::move(
                                    $config . 'ini',
                                    $axmud::DATA_DIR . '/' . $axmud::NAME_SHORT . '.ini',
                                );

                            } elsif (-e $config . 'conf') {

                                File::Copy::move(
                                    $config . 'conf',
                                    $axmud::DATA_DIR . '/' . $axmud::NAME_SHORT . '.conf',
                                );
                            }
                        }

                        last OUTER;
                    }
                }
            }
        }

        # Create directories
        mkdir ($axmud::DATA_DIR, 0755);
        mkdir ($axmud::DATA_DIR . '/buffers', 0755);
        mkdir ($axmud::DATA_DIR . '/custom', 0755);
        mkdir ($axmud::DATA_DIR . '/data', 0755);
        mkdir ($axmud::DATA_DIR . '/data/worlds', 0755);
        # (Temp directory for use by Axmud code only)
        mkdir ($axmud::DATA_DIR . '/data/temp', 0755);
        mkdir ($axmud::DATA_DIR . '/logos', 0755);
        mkdir ($axmud::DATA_DIR . '/logs', 0755);
        mkdir ($axmud::DATA_DIR . '/logs/standard', 0755);
        mkdir ($axmud::DATA_DIR . '/msp', 0755);
        mkdir ($axmud::DATA_DIR . '/mxp', 0755);
        mkdir ($axmud::DATA_DIR . '/plugins', 0755);
        mkdir ($axmud::DATA_DIR . '/plugins/help', 0755);
        mkdir ($axmud::DATA_DIR . '/plugins/help/cmd', 0755);
        mkdir ($axmud::DATA_DIR . '/plugins/help/task', 0755);
        mkdir ($axmud::DATA_DIR . '/screenshots', 0755);
        mkdir ($axmud::DATA_DIR . '/scripts', 0755);
        mkdir ($axmud::DATA_DIR . '/sounds', 0755);
        mkdir ($axmud::DATA_DIR . '/store', 0755);
        # (Temp directory for use by plugins)
        mkdir ($axmud::DATA_DIR . '/tmp', 0755);

        # Make sure the data directory's README file is in place
        File::Copy::copy($axmud::SHARE_DIR . '/items/readme/README', $axmud::DATA_DIR);

        return 1;
    }

    sub fillDataDirs {

        # Called by GA::Obj::File->setupConfigFile when a new 'config' file is created
        # Copies data from Axmud's base sub-directories (default sound effects, icons, etc) into its
        #   data directories; when the user wants to mess with files, they can modify the files in
        #   the data directories - not the default copies in Axmud's base directory
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $type           - The type of files to copy - 'scripts' or 'sounds'. If 'undef', both
        #                       of these files are copied
        #   $replaceFlag    - If set to TRUE, a default file in Axmud's base sub-directories
        #                       replaces the corresponding one in the data directories. If FALSE (or
        #                       'undef'), only files that are missing in the data directories are
        #                       copied
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $type, $replaceFlag, $check) = @_;

        # Local variables
        my (
            $dir, $dirHandle,
            @fileList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->fillDataDirs', @_);
        }

        # Copy scripts
        if (! defined $type || $type eq 'scripts') {

            $dir = $axmud::SHARE_DIR . '/items/scripts';
            if (-e $dir) {

                # Open the directory for reading
                opendir($dirHandle, $dir);

                # Get a list of files in the directory
                @fileList = ();
                while (my $file = readdir($dirHandle)) {

                    push (@fileList, $file);
                }

                # Close the directory handle
                closedir($dirHandle);

                # Copy each file into the equivalent data directory
                foreach my $file (@fileList) {

                    my ($originalPath, $copyPath);

                    $originalPath = $dir . '/' . $file;
                    $copyPath = $axmud::DATA_DIR . '/scripts/' . $file;

                    # Copy the file if $replaceFlag forces us to, or if a file with the same path as
                    #   $newPath doesn't already exist
                    if ($replaceFlag || ! (-e $copyPath)) {

                        File::Copy::copy($originalPath, $copyPath);
                    }
                }
            }
        }

        # Copy sounds
        if (! defined $type || $type eq 'sounds') {

            $dir = $axmud::SHARE_DIR . '/items/sounds';
            if (-e $dir) {

                # Open the directory for reading
                opendir($dirHandle, $dir);

                # Get a list of files in the directory
                @fileList = ();
                while (my $file = readdir($dirHandle)) {

                    push (@fileList, $file);
                }

                # Close the directory handle
                closedir($dirHandle);

                # Copy each file into the equivalent data directory
                foreach my $file (@fileList) {

                    my ($originalPath, $copyPath);

                    $originalPath = $dir . '/' . $file;
                    $copyPath = $axmud::DATA_DIR . '/sounds/' . $file;

                    # Copy the file if $replaceFlag forces us to, or if a file with the same path as
                    #   $newPath doesn't already exist
                    if ($replaceFlag || ! (-e $copyPath)) {

                        File::Copy::copy($originalPath, $copyPath);
                    }
                }
            }
        }

        return 1;
    }

    sub createStandardZonemaps {

        # Called by $self->start
        # Makes sure the standard GA::Obj::Zonemap objects specified by $self->constZonemapHash
        #   (e.g. 'basic', 'widescreen') exist and, if not, create them
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if one of the standard zonemaps doesn't exist and
        #       can't be created
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $modFlag,
            %constHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createStandardZonemaps', @_);
        }

        # Import the hash of standard zonemaps (for convenience)
        %constHash = $self->constZonemapHash;

        # First create zonemaps that aren't clones
        foreach my $zonemapName (keys %constHash) {

            my $zonemapObj;

            # If this standard zonemap hasn't already been created, and doesn't need to be cloned...
            if (
                ! $self->ivExists('zonemapHash', $zonemapName)
                && ! $constHash{$zonemapName}
            ) {
                # ...then create it
                $zonemapObj = Games::Axmud::Obj::Zonemap->new($zonemapName);
                if (! $zonemapObj) {

                    return $self->writeError(
                        'Cannot set up the standard \'' . $zonemapName . '\' zonemap',
                        $self->_objClass . '->createStandardZonemaps',
                    );

                } else {

                    # Add the zonemap to the client's registries
                    $self->ivAdd('zonemapHash', $zonemapObj->name, $zonemapObj);
                    $self->ivAdd('standardZonemapHash', $zonemapObj->name, $zonemapObj);

                    $modFlag = TRUE;
                }
            }
        }

        # Now create zonemaps that are clones (of zonemap objects we've already created)
        foreach my $cloneName (keys %constHash) {

            my ($originalName, $originalObj, $cloneObj);

            $originalName = $constHash{$cloneName};
            if ($originalName) {

                $originalObj = $self->ivShow('zonemapHash', $originalName);
            }

            # If this standard zonemap hasn't already been created, and does need to be cloned, and
            #   the original now exists...
            if (
                $originalObj
                && ! $self->ivExists('zonemapHash', $cloneName)
            ) {
                # ...then create it
                $cloneObj = $originalObj->clone($cloneName);
                if (! $cloneObj) {

                    return $self->writeError(
                        'Cannot set up the standard \'' . $cloneName . '\' zonemap',
                        $self->_objClass . '->createStandardZonemaps',
                    );

                } else {

                    # Add the zonemap to the client's registries
                    $self->ivAdd('zonemapHash', $cloneObj->name, $cloneObj);
                    $self->ivAdd('standardZonemapHash', $cloneObj->name, $cloneObj);
                    $modFlag = TRUE;

                    # The clone differs from the original in that its zone models should allow
                    #   multiple layers, except for models reserved for 'main' windows
                    # Apply that change now
                    $cloneObj->modifyStandardZonemap();
                }
            }
        }

        if ($modFlag) {

            # The data stored in these IVs are saved in the 'zonemaps' file
            $self->setModifyFlag('zonemaps', TRUE, $self->_objClass . '->createStandardZonemaps');
        }

        return 1;
    }

    sub createTempZonemap {

        # Called by GA::Session->processMxpFrameElement
        # Creates a 'temporary' zonemap (one that is never saved, and which is destroyed when the
        #   calling session closes, and which can only be used with the calling session)
        #
        # Expected arguments
        #   $session    - The calling GA::Session
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   Otherwise returns the new GA::Obj::Zonemap object

        my ($self, $session, $check) = @_;

        # Local variables
        my ($count, $name, $zonemapObj, $modelObj);

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createTempZonemap', @_);
        }

        # Create a zonemap called 'temp_n', where 'n' is the first available integer number
        $count = 0;
        do {

            $count++;
            if (! $self->ivExists('zonemapHash', 'temp_' . $count)) {

                $name = 'temp_' . $count;
            }

        } until ($name);

        # Unlikely in the extreme that we'll ever use a trillion zonemaps, but let's check anyway
        if (! $self->nameCheck($name, 16)) {

            return undef;
        }

        # Create the temporary zonemap
        $zonemapObj = Games::Axmud::Obj::Zonemap->new($name, TRUE, $session);
        if (! $zonemapObj) {

            return undef;
        }

        # Add the zonemap to the client's registries
        $self->ivAdd('zonemapHash', $zonemapObj->name, $zonemapObj);

        # Add a single zone model, covering the whole of the zonemap's internal grid
        $modelObj = Games::Axmud::Obj::ZoneModel->new($zonemapObj);
        $modelObj->{left} = 0;
        $modelObj->{right} = 59;
        $modelObj->{top} = 0;
        $modelObj->{bottom} = 59;
        $modelObj->{width} = 60;
        $modelObj->{height} = 60;
        $zonemapObj->addZoneModel($modelObj);

        return $zonemapObj;
    }

    sub checkCurrentZonemap {

        # Called by GA::EditWin::ZoneModel and GA::Cmd::ModifyZoneModel->do
        # Checks whether the specified zonemap is being used by any workspace grid (a
        #   GA::Obj::WorkspaceGrid object), because a zonemap in use cannot be modified
        #
        # Expected arguments
        #   $zonemap    - The name of the zonemap to check
        #
        # Return values
        #   'undef' in improper arguments or if $zonemap isn't in use by any workspace grid
        #   1 if $zonemap is in use by any workspace grid

        my ($self, $zonemap, $check) = @_;

        # Check for improper arguments
        if (! defined $zonemap || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkCurrentZonemap', @_);
        }

        foreach my $workspaceGridObj ($self->desktopObj->ivValues('gridHash')) {

            if ($workspaceGridObj->zonemap && $workspaceGridObj->zonemap eq $zonemap) {

                return 1;
            }
        }

        # $zonemap isn't in use by any workspace grid
        return undef;
    }

    sub createStandardWinmaps {

        # Called by $self->start
        # Makes sure the standard GA::Obj::Winmap objects specified by
        #   $self->constWinmapNameHash (e.g. 'main_fill', 'entry_empty') exist and, if not, create
        #   them
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if one of the standard winmaps doesn't exist and can't
        #       be created
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $modFlag;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createStandardWinmaps', @_);
        }

        foreach my $winmapName ($self->ivKeys('constWinmapNameHash')) {

            my $winmapObj;

            # If this standard winmap hasn't already been created...
            if (! $self->ivExists('winmapHash', $winmapName)) {

                # ...then create it
                $winmapObj = Games::Axmud::Obj::Winmap->new($winmapName);
                if (! $winmapObj) {

                    return $self->writeError(
                        'Cannot set up the standard \'' . $winmapName . '\' winmap',
                        $self->_objClass . '->createStandardWinmaps',
                    );

                } else {

                    # Add the winmap to the client's registries
                    $self->ivAdd('winmapHash', $winmapObj->name, $winmapObj);
                    $self->ivAdd('standardWinmapHash', $winmapObj->name, $winmapObj);

                    $modFlag = TRUE;
                }
            }
        }

        if ($modFlag) {

            # The data stored in these IVs are saved in the 'winmaps' file
            $self->setModifyFlag('winmaps', TRUE, $self->_objClass . '->createStandardWinmaps');
        }

        return 1;
    }

    sub createStandardColourSchemes {

        # Called by $self->start
        # Makes sure the standard GA::Obj::ColourScheme objects (whose names matches a type of
        #   'grid' or 'free' window) exist and, if not, create them
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if one of the standard zonemaps doesn't exist and
        #       can't be created
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $modFlag,
            @list,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->createStandardColourSchemes',
                @_,
            );
        }

        push (@list, $self->ivKeys('constGridWinTypeHash'), $self->ivKeys('constFreeWinTypeHash'));

        foreach my $winType (@list) {

            if (! $self->ivExists('colourSchemeHash', $winType)) {

                # Doesn't exist, so create it
                my $obj = Games::Axmud::Obj::ColourScheme->new($winType);
                if (! $obj) {

                    return $self->writeError(
                        'Cannot set up the standard \'' . $winType . '\' colour scheme',
                        $self->_objClass . '->createStandardColourSchemes',
                    );

                } else {

                    # Add the colour scheme to the client's registry
                    $self->ivAdd('colourSchemeHash', $obj->name, $obj);
                    $modFlag = TRUE;
                }
            }
        }

        if ($modFlag) {

            # The data stored in these IVs are saved in the 'winmaps' file
            $self->setModifyFlag(
                'winmaps',
                TRUE,
                $self->_objClass . '->createStandardColourSchemes',
            );
        }

        return 1;
    }

    sub createSupportedMcpPackages {

        # Called by $self->start
        # Creates MCP package objects (inheriting from Games::Axmud::Generic::Mcp) for all
        #   MCP packages supported by Axmud (before any initial plugins have defined new ones)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if one of the supported MCP package objects can't be
        #       created
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->createSupportedMcpPackages',
                @_,
            );
        }

        @list = $self->constMcpPackageList;
        if (! @list) {

            # No supported packages to add
            return 1;
        }

        # Create an MCP package object for each supported package
        do {

            my ($name, $perlPackage, $min, $max, $obj);

            $name = shift @list;
            $perlPackage = shift @list;
            $min = shift @list;
            $max = shift @list;

            # Obviously we, the authors, aren't going to create duplicate packages, but there's no
            #   harm in checking
            if ($self->ivExists('mcpPackageHash', $name)) {

                return $self->writeError(
                    'Duplicate supported MCP package \'' . $name . '\'',
                    $self->_objClass . '->createSupportedMcpPackages',
                );
            }

            # Create the MCP package object
            $obj = $perlPackage->new($name, $min, $max);
            if (! $obj) {

                return $self->writeError(
                    'Cannot set up supported MCP package \'' . $name . '\'',
                    $self->_objClass . '->createSupportedMcpPackages',
                );

            } else {

                $self->ivAdd('mcpPackageHash', $name, $obj);
            }

        } until (! @list);

        return 1;
    }

    sub setupKeycodes {

        # Called by $self->start
        # Sets up keycodes for the current system by populating $self->keycodeHash and
        #   $self->revKeycodeHash
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setupKeycodes', @_);
        }

        $self->ivPoke('keycodeHash', $self->constKeycodeHash);
        if ($^O eq 'MSWin32') {

            foreach my $key ($self->ivKeys('constMSWinKeycodeHash')) {

                $self->ivAdd('keycodeHash', $key, $self->ivShow('constMSWinKeycodeHash', $key));
            }

        } elsif ($^O =~ m/bsd/i) {

            foreach my $key ($self->ivKeys('constBSDKeycodeHash')) {

                $self->ivAdd('keycodeHash', $key, $self->ivShow('constBSDKeycodeHash', $key));
            }
        }

        foreach my $standard ($self->ivKeys('keycodeHash')) {

            my (
                $string,
                @list,
            );

            $string = $self->ivShow('keycodeHash', $standard);

            # $string is a single standard keycode, e.g. 'kp_0', or a set of standard keycodes
            #   separated by whitespace, e.g. 'up kp_up'
            @list = split(/\s+/, $string);

            foreach my $item (@list) {

                $self->ivAdd('revKeycodeHash', $item, $standard);
            }
        }

        return 1;
    }

    sub copyPreConfigWorld {

        # Called by GA::Obj::File->setupConfigFile when a new 'config' file is created
        # Also called by $self->insertPreConfigWorlds when the user is using a newer version of
        #   Axmud
        #
        # Copies a pre-configured world profile from Axmud's base sub-directories into its data
        #   directories
        # If called by ->setupConfigFile, creates a dummy entry in $self->worldProfHash, ready for
        #   the file object to create a 'config' file that includes the pre-configured worlds
        # If called by ->insertPreConfigWorlds, doesn't create a dummy entry, but otherwise the
        #   operation is identical
        #
        # If, by any chance, Axmud's data directories already contain a world profile with the same
        #   name, don't replace them (but still update $self->worldProfHash)
        #
        # Expected arguments
        #   $world      - The name of the pre-configured world profile
        #
        # Optional arguments
        #   $setupFlag  - TRUE if called by GA::Obj::File->setupConfigFile; FALSE (or 'undef') if
        #                   called by anything else
        #
        # Return values
        #   'undef' on improper arguments or if there's a serious error (meaning that no further
        #       pre-configured worlds can be copied)
        #   Otherwise returns a string: 'success' if the pre-configured world is succesfully
        #       copied, 'fail' if the world can't be copied (but it's safe to continue copying
        #       other worlds)

        my ($self, $world, $setupFlag, $check) = @_;

        # Local variables
        my (
            $importPath, $extractObj, $tempDir, $newDir, $origLogo, $newLogo, $hashRef, $fileObj,
            @fileList,
            %fileHash, %loadHash, %dictHash,
        );

        # Check for improper arguments
        if (! defined $world || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->copyPreConfigWorld', @_);
        }

        # Pre-configured world test mode: When preparing for a release, the authors set this flag to
        #   TRUE to stop Axmud complaining about missing pre-configured worlds
        if ($axmud::TEST_PRE_CONFIG_FLAG) {

            return 'success';
        }

        # If a directory for the pre-configured world exists and a data directory for a world with
        #   the same name doesn't exist...
        if (
            -e $axmud::SHARE_DIR . '/items/worlds/' . $world
            && ! (-e $axmud::DATA_DIR . '/data/worlds/' . $world)
        ) {
            # Copy the pre-configured worlds into the data directories (code adapted from
            #   GA::Cmd::ImportFiles->do)
            $importPath = $axmud::SHARE_DIR . '/items/worlds/' . $world . '/' . $world . '.tgz';
            if (! -e $importPath) {

                $self->writeWarning(
                    'General error importing pre-configured worlds (archive missing for \''
                    . $world . '\' world)',
                    $self->_objClass . '->copyPreConfigWorld',
                );

                return 'fail';
            }

            # Build an Archive::Extract object
            $extractObj = Archive::Extract->new(archive => $importPath);
            if (! $extractObj) {

                return $self->writeError(
                    'General error importing pre-configured worlds (archive error)',
                       $self->_objClass . '->copyPreConfigWorld',
                );
            }

            # Extract the object to a temporary directory (if it doesn't already exist, create it)
            $tempDir = $axmud::DATA_DIR . '/data/temp/import';
            if (! $extractObj->extract(to => $tempDir)) {

                return $self->writeError(
                    'General error importing pre-configured worlds (extraction error)',
                    $self->_objClass . '->copyPreConfigWorld',
                );
            }

            # All the files are now in /data/temp/import. Get a list of paths, relative to $tempDir,
            #   of all the extracted files
            @fileList = @{$extractObj->files};  # e.g. export/tasks.axm
            # Convert all the paths into absolute paths. Check they are real Axmud files and, if so,
            #   store them in a hash
            foreach my $file (@fileList) {

                my (
                    $fileType, $filePath,
                    %headerHash,
                );

                $filePath = $tempDir . '/' . $file;

                %headerHash = Games::Axmud::Obj::File->examineDataFile($filePath, 'return_header');
                if (! %headerHash) {

                    $self->writeWarning(
                        'General error importing pre-configured worlds (archive contains invalid'
                        . ' file)',
                        $self->_objClass . '->copyPreConfigWorld',
                    );

                    return 'fail';

                } else {

                    $fileType = $headerHash{'file_type'};
                    $fileHash{$fileType} = $filePath;
                }
            }

            # Now we can check that we have the right three files ('worldprof', 'otherprof' and
            #   'worldmodel')
            if (
                ! exists $fileHash{'worldprof'}
                || ! exists $fileHash{'otherprof'}
                || ! exists $fileHash{'worldmodel'}
                || scalar (keys %fileHash) != 3
            ) {
                $self->writeWarning(
                    'General error importing pre-configured worlds (incorrect archive for \''
                    . $world . '\' world)',
                    $self->_objClass . '->copyPreConfigWorld',
                );

                return 'fail';
            }

            # Create the data sub-directory
            $newDir = $axmud::DATA_DIR . '/data/worlds/' . $world . '/';
            if (! mkdir ($newDir, 0755)) {

                $self->writeWarning(
                    'General error importing pre-configured worlds (could not copy files)',
                    $self->_objClass . '->copyPreConfigWorld',
                );

                return 'fail';
            }

            # Copy the files into the sub-directory
            foreach my $file (keys %fileHash) {

                my $filePath = $fileHash{$file};

                if (! File::Copy::copy($filePath, $newDir . $file . '.axm')) {

                    # Give up importing this pre-configured world; destroy its data sub-directory
                    File::Path::remove_tree($newDir);

                    $self->writeWarning(
                        'General error importing pre-configured worlds (could not copy files)',
                        $self->_objClass . '->copyPreConfigWorld',
                    );

                    return 'fail';
                }
            }

            # When this function was called by GA::Obj::File->setupConfigFile, add a dummy entry to
            #   the this object's profile registry so the calling function,
            #   GA::Obj::File->setupConfigFile, can add the world to the 'config' file it's about to
            #   create (the dummy entry will be removed by that function)
            if ($setupFlag) {

                $self->ivAdd('worldProfHash', $world, undef);
            }

            # If a logo for this world exists, and if the equivalent logo doesn't exist in the data
            #   directory, copy it
            $origLogo = $axmud::SHARE_DIR . '/items/worlds/' . $world . '/' . $world . '.png';
            $newLogo = $axmud::DATA_DIR . '/logos/' . $world . '.png';

            if (-e $origLogo && ! (-e $newLogo)) {

                File::Copy::copy($origLogo, $newLogo);
            }

            # Now, try to import the corresponding file containing the world's dictionary
            $importPath = $axmud::SHARE_DIR . '/items/worlds/' . $world . '/' . $world . '.amx';
            if (! -e $importPath) {

                # Pre-configured dictionary archive missing; so move on to the next world
                $self->writeWarning(
                    'General error importing pre-configured worlds (dictionary archive not found)',
                    $self->_objClass . '->copyPreConfigWorld',
                );

                return 'fail';
            }

            # We can't call GA::Obj::File->importDataFile because it expects a GA::Session as an
            #   argument
            # Instead, we'll use a modified version of ->importDataFile and ->extractData

            # Load all the data into an anonymous hash
            eval { $hashRef = Storable::lock_retrieve($importPath); };
            if (! $hashRef) {

                return $self->writeError(
                    'General error importing pre-configured worlds (lockfile error)',
                    $self->_objClass . '->copyPreConfigWorld',
                );
            }

            # Convert the anonymous hash referenced by $hashRef into a named hash
            %loadHash = %{$hashRef};

            # Before v1.0.868, Axmud had a different name. Update all header data
            if (
                defined $loadHash{'script_version'}
                && $self->convertVersion($loadHash{'script_version'}) < 1_000_868
            ) {
                %loadHash = Games::Axmud::Obj::File->updateHeaderAfterRename(%loadHash);
            }

            if (
                # Check the header is valid
                ! defined $loadHash{'file_type'} || ! defined $loadHash{'script_name'}
                || ! defined $loadHash{'script_version'} || ! defined $loadHash{'save_date'}
                || ! defined $loadHash{'save_time'} || ! exists $loadHash{'assoc_world_prof'}
                # Check it's the right kind of file
                || $loadHash{'file_type'} ne 'dicts'
                # Check the file was created by a compatible programme
                || ! Games::Axmud::Obj::File->checkCompatibility($loadHash{'script_name'})
            ) {
                $self->writeWarning(
                    'General error importing pre-configured worlds (dictionary archive invalid)',
                    $self->_objClass . '->copyPreConfigWorld',
                );

                return 'fail';
            }

            # Import the dictionary objects stored in the file
            %dictHash = %{$loadHash{'dict_hash'}};
            if (%dictHash) {

                foreach my $dictObj (values %dictHash) {

                    # Before v1.0.868, Axmud had a different name. Update the dictionary object
                    $dictObj = Games::Axmud::Obj::File->update_obj_dict($dictObj);

                    $self->ivAdd('dictHash', $dictObj->name, $dictObj);
                }

                # The data stored in this IV is saved in the 'dicts' file
                $self->setModifyFlag('dicts', TRUE, $self->_objClass . '->copyPreConfigWorld');
                # Because dictionary objects may contain new IVs (or other changes), we need to call
                #   the file object's ->updateExtractedData (this happens elsewhere, for the
                #   'worldprof', 'otherprof' and 'worldmodel' files, but for the 'dicts' file, we
                #   must do it now)
                $fileObj = $self->ivShow('fileObjHash', 'dicts');
                $fileObj->updateExtractedData(
                    $self->convertVersion($loadHash{'script_version'}),
                );
            }
        }

        # Operation complete
        return 'success';
    }

    sub cleanPreConfigWorlds {

        # Called by GA::Obj::File->setupConfigFile after a call to $self->copyPreConfigWorlds, which
        #   added a number of dummy entries to $self->worldProfHash
        # Removes the dummy entries, adding new entries in $self->configWorldProfList (as if the
        #   config file had been read, not created)
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->cleanPreConfigWorlds', @_);
        }

        foreach my $world ($self->ivKeys('worldProfHash')) {

            my $worldObj = $self->ivShow('worldProfHash', $world);

            if (! defined $worldObj) {

                $self->ivDelete('worldProfHash', $world);
                $self->ivPush('configWorldProfList', $world);
            }
        }

        return 1;
    }

    sub insertPreConfigWorlds {

        # Called by $self->start when the user is using a new version of Axmud
        # Checks whether any pre-configured worlds have been added since the version of Axmud last
        #   used by the user (i.e. the version that created the Axmud data directory we're using)
        # If any are found, inserts them into Axmud's data directory
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there's a serious error (after which, this function
        #       gives up inserting pre-configured worlds)
        #   1 on success or if there are only minor errors (this function continued trying to
        #       insert pre-configured worlds after the minor error)

        my ($self, $check) = @_;

        # Local variables
        my (
            $prevVersion,
            %alreadyHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->insertPreConfigWorlds', @_);
        }

        # Convert version, e.g. '1.1.0' to '1_001_000'
        $prevVersion = $self->convertVersion($self->prevClientVersion);
        # Compile a hash of world profiles which (should) already exist (none of which have been
        #   loaded by $self->start yet)
        foreach my $world ($self->configWorldProfList) {

            $alreadyHash{$world} = undef;
        }

        # Only insert pre-configured worlds that are newer than the version of Axmud the user was
        #   using last time
        # Also don't import a pre-configured world if a world profile with the same name (created by
        #   the user) already exists
        foreach my $world ($self->constWorldList) {

            my ($worldVersion, $result);

            if (! exists $alreadyHash{$world} && $self->ivExists('constWorldHash', $world)) {

                $worldVersion = $self->convertVersion($self->ivShow('constWorldHash', $world));

                if ($worldVersion > $prevVersion) {

                    $result = $self->copyPreConfigWorld($world);
                    if (! defined $result) {

                        # Serious error. Give up inserting pre-configured worlds
                        return undef;

                    } elsif ($result = 'success') {

                        # No minor error reported, so tell the calling function to load this world
                        #   profile
                        $self->ivPush('configWorldProfList', $world);
                    }
                }
            }
        }

        return 1;
    }

    sub loadWorldProfs {

        # Called by $self->start
        # $self->configWorldProfList contains a list of world profile names stored in the 'config'
        #   file. This function loads each of those profiles into memory
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if any of the expected world profiles can't be loaded
        #       (when that happens, this function continues trying to load world profiles before
        #       returning 'undef')
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my ($worldDir, $failFlag);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->loadWorldProfs', @_);
        }

        # Set the directory in which world profile-related data is stored
        $worldDir = $axmud::DATA_DIR . '/data/worlds';

        # Load each profile in turn
        foreach my $world ($self->configWorldProfList) {

            my ($old, $new, $fileObj, $dir, $path, $file);

            # Before v1.0.868, worldprof.axm was called worlddefn.amd, and otherprof.axm was called
            #   otherdefn.amd. If the old files are present, rename them
            $old = $worldDir . '/' . $world . '/worlddefn.amd';
            if (-e $old) {

                $new = $worldDir . '/' . $world . '/worldprof.axm';
                File::Copy::move($old, $new);
            }

            $old = $worldDir . '/' . $world . '/otherdefn.amd';
            if (-e $old) {

                $new = $worldDir . '/' . $world . '/otherprof.axm';
                File::Copy::move($old, $new);
            }

            # Create a file object to store the header information, once loaded.
            $fileObj = Games::Axmud::Obj::File->new('worldprof', $world);
            if (! $fileObj) {

                return $self->writeError(
                    'Failed to create a file object for the world profile \'' . $world . '\'',
                    $self->_objClass . '->loadWorldProfs',
                );

            } else {

                # Add the file object to its registry
                $self->ivAdd('fileObjHash', $fileObj->assocWorldProf, $fileObj);

                # Load the profile file (in overwrite mode - only the world profile itself is
                #   overwritten)
                $dir = $worldDir . '/' . $world;
                $file = $fileObj->standardFileName;
                $path = $dir . '/' . $fileObj->standardFileName;

                if (! $fileObj->loadDataFile($file, $path, $dir)) {

                    # Try loading the automatic backup, i.e. 'worldprof.axm.bu'
                    if (! $fileObj->loadDataFile($file, $path, $dir, TRUE)) {

                        # Continue loading world profiles, but this function will return 'undef'
                        $failFlag = TRUE;

                    } else {

                        # The contents of the backup, now loaded into memory, must be saved at some
                        #   point
                        $fileObj->set_modifyFlag(TRUE);
                        # Don't overwrite the existing backup file with the faulty one
                        $fileObj->set_preserveBackupFlag(TRUE);
                    }
                }
            }
        }

        if ($failFlag) {
            return undef;
        } else {
            return 1;
        }
    }

    sub getTempProfName {

        # Called by $self->start, GA::Cmd::Telnet->do, GA::Cmd::SSH->do, GA::Cmd::SSL->do or
        #   GA::OtherWin::Connect->connectWorldCallback
        # All sessions require a current world profile with a defined name. For situations in which
        #   we want to create a temporary world profile that won't be saved - such as when the
        #   Connections window starts a new connection, but the user hasn't specified a world name -
        #   this function returns an available world profile name to use
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there are no available world profile names (an
        #       exceedingly unlikely situation)
        #   Otherwise, returns an available world profile name

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getTempProfName', @_);
        }

        for (my $count = 1; $count <= 9999; $count++) {

            if (! $self->ivExists('worldProfHash', 'temp_world_' . $count)) {

                return 'temp_world_' . $count;
            }
        }

        # No temporary profile names available
        return undef;
    }

    sub loadOtherFiles {

        # Called by $self->start
        # Loads data from the files 'tasks', 'scripts', 'contacts', 'dicts', 'toolbar', 'usercmds',
        #   'zonemaps', 'winmaps', 'tts')
        # Any of the files which don't yet exist are created
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if any of the file objects can't be loaded (or created)
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->loadOtherFiles', @_);
        }

        # The list of file types to load
        @list = (
            'tasks', 'scripts', 'contacts', 'dicts', 'toolbar', 'usercmds', 'zonemaps', 'winmaps',
            'tts',
        );

        # Create the FileObjs
        foreach my $type (@list) {

            my $obj;

            if (! $self->ivExists('fileObjHash', $type)) {

                # The corresponding file object is missing. This should never happen
                return undef;

            } else {

                $obj = $self->ivShow('fileObjHash', $type);
                # Load the file
                if (! $obj->setupDataFile()) {

                    # File not loaded (or created)
                    return undef;
                }
            }
        }

        # All files loaded
        return 1;
    }

    sub disableAllFileAccess {

        # Called by $self->start, $self->createFileObjs or by any other code
        # Disables loading and saving of files across all sessions
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments flag
        #   $noPromptFlag   - If set to TRUE, there's no need to prompt the user for an emergency
        #                       save. If set to FALSE (or 'undef'), prompt the user in the normal
        #                       way, if allowed
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $noPromptFlag, $check) = @_;

        # Local variables
        my $choice;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createFileObjs', @_);
        }

        # Disable loading/saving of the 'config' file for the client
        $self->ivPoke('loadConfigFlag', FALSE);
        $self->ivPoke('saveConfigFlag', FALSE);
        # Disable loading/saving of all other data files by all sessions
        $self->ivPoke('loadDataFlag', FALSE);
        $self->ivPoke('saveDataFlag', FALSE);

        # The data stored in these IVs is saved in the 'config' file (set the modify flag, even
        #   though the 'config' file can't be saved)
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->disableAllFileAccess');

        # Do an emergency save, if allowed
        if ($self->emergencySaveFlag && ! $noPromptFlag) {

            if ($self->mainWin) {

                # Ask the user for permission to do an emergency save
                $choice = $self->mainWin->showMsgDialogue(
                    'Emergency save',
                    'warning',
                    'File access is about to be disabled. Would you like to do an emergency save?',
                    'yes-no',
                );

                if ($choice eq 'yes') {

                    $self->doEmergencySave();
                }

            } else {

                # No 'main' window from which to do open 'dialogue' windows, so go ahead and do the
                #   emergency save
                $self->doEmergencySave();
            }
        }

        return 1;
    }

    sub doEmergencySave {

        # Called by $self->disableAllFileAccess, GA::Cmd::EmergencySave->do or by any other code
        # Performs an emergency save, saving all file objects to a location specified by the user
        #   (which is almost always not the usual Axmud data directory)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the user cancels the operation
        #   Otherwise, returns the directory in which the files were saved

        my ($self, $check) = @_;

        # Local variables
        my ($dir, $msg, $errorCount);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->doEmergencySave', @_);
        }

        # Prompt the user for a directory in which to save
        if ($self->mainWin) {

            $dir = $self->mainWin->showFileChooser(
                'Emergency save location',
                'select-folder',
            );

            if (! $dir) {

                return undef;
            }

            # Create a sub-directory in that directory
            #    e.g. .../axmud_101218_09_17_12
            $dir .= '/' . $axmud::NAME_SHORT . '_' . $self->localDateString() . '_'
                            . $self->localClockString;

        } else {

            # If there is no 'main' window, save into Axmud's base directory as a fallback
            $dir = $axmud::SHARE_DIR . '/EMERGENCY_SAVE/' . $axmud::NAME_SHORT . '_'
                        . $self->localDateString() . '_' . $self->localClockString;
        }

        if (! mkdir ($dir, 0755)) {

            $msg = 'Could not create an emergency save directory (folder); you can try again using'
                        . ' the \';emergencysave\' command';

            if ($self->mainWin) {

                $self->mainWin->showMsgDialogue(
                    'Emergency save',
                    'error',
                    $msg,
                    'ok',
                );

            } else {

                $self->writeError($msg, $self->_objClass . '->doEmergencySave');
            }

            return 1;
        }

        # Create a further sub-directory for world-specific files
        if (! mkdir ($dir . '/worlds', 0755)) {

            $msg = 'Could not create an emergency save directory (folder); you can try again using'
                        . ' the \';emergencysave\' command.';

            if ($self->mainWin) {

                $self->mainWin->showMsgDialogue(
                    'Emergency save',
                    'error',
                    $msg,
                    'ok',
                );

            } else {

                $self->writeError($msg, $self->_objClass . '->doEmergencySave');
            }

            return 1;
        }

        # Save file objects stored in this GA::Client
        # (NB 'otherprof' or 'worldmodel' files should only be stored in the GA::Session)
        $errorCount = 0;

        foreach my $fileObjName ($self->ivKeys('fileObjHash')) {

            my ($fileObj, $thisDir);

            $fileObj = $self->ivShow('fileObjHash', $fileObjName);

            if ($fileObj->fileType eq 'config') {

                if (
                    ! $fileObj->saveConfigFile(
                        $fileObj->actualFileName,
                        $dir . '/' . $fileObj->actualFileName,
                        $dir,
                        # The TRUE flag tells the function that an emergency save is in progress
                        TRUE,
                    )
                ) {
                    $errorCount++;
                }

            } elsif ($fileObj->fileType eq 'worldprof') {

                # ('worldprof' files are stored in their own directory)
                $thisDir = $dir . '/worlds/' . $fileObj->assocWorldProf;

                if (
                    ! $fileObj->saveDataFile(
                        $fileObj->actualFileName,
                        $thisDir . '/' . $fileObj->actualFileName,
                        $thisDir,
                        # The TRUE flag tells the function that an emergency save is in progress
                        TRUE,
                    )
                ) {
                    $errorCount++;
                }

            } else {

                if (
                    ! $fileObj->saveDataFile(
                        $fileObj->actualFileName,
                        $dir . '/' . $fileObj->actualFileName,
                        $dir,
                        # The TRUE flag tells the function that an emergency save is in
                        #   progress
                        TRUE,
                    )
                ) {
                    $errorCount++;
                }
            }
        }

        # Instruct each session to do an emergency save in their own directory
        foreach my $thisSession ($self->listSessions()) {

            if (! $thisSession->sessionEmergencySave($dir)) {

                $errorCount++;
            }
        }

        # Show a confirmation
        if ($errorCount) {

            $msg = 'Emergency save complete (sessions saved: '
                        . $self->ivPairs('sessionHash') . ', errors: ' . $errorCount
                        . '; you can try again using the' . ' \';emergencysave\' command)';

            if ($self->mainWin) {

                $self->mainWin->showMsgDialogue(
                    'Emergency save',
                    'warning',
                    $msg,
                    'ok',
                );

            } else {

                $self->writeWarning($msg, $self->_objClass . '->doEmergencySave');
            }

        } else {

            $msg = 'Emergency save complete (sessions saved: '
                       . $self->ivPairs('sessionHash') . ')';

            if ($self->mainWin) {

                $self->mainWin->showMsgDialogue(
                    'Emergency save',
                    'info',
                    $msg,
                    'ok',
                );

            } else {

                $self->writeText($msg);
            }
        }

        # Operation complete
        return $dir;
    }

    sub setupCmds {

        # Called by $self->start
        # Creates a Perl object for each client command, storing them in the registry
        #   $self->clientCmdHash. (See also the code in $self->addPluginCmds)
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setupCmds', @_);
        }

        foreach my $string ($self->clientCmdPrettyList) {

            my ($package, $obj);

            # $self->clientCmdPrettyList contains a list of client commands, grouped under headings.
            #   The headings begin with a '@' character
            if (substr ($string, 0, 1) ne '@') {

                # Not a heading. Create a Perl object
                $package = 'Games::Axmud::Cmd::' . $string;
                $obj = $package->new();
                if (! $obj) {

                    # (Allow writing to something other than GA::Session - there are no sessions
                    #   yet)
                    return $self->writeError(
                        'Could not create client command \'' . $self->cmdSep . lc($string) . '\'',
                        $self->_objClass . '->setupCmds',
                    );
                }

                # Update IVs
                $self->ivAdd('clientCmdHash', lc($string), $obj);
                $self->ivPush('clientCmdList', lc($string));

                # Set up user commands corresponding to this client command
                foreach my $userCmd ($obj->defaultUserCmdList) {

                    # Check the user command isn't already in use by another client command
                    if ($self->ivExists('constUserCmdHash', lc($userCmd))) {

                        # (Allow writing to something other than GA::Session - there are no
                        #   sessions yet)
                        return $self->writeError(
                            'Duplicate user command \'' . $userCmd . '\' pointing at client'
                            . ' command \'' . lc($string) . '\'',
                            $self->_objClass . '->setupCmds',
                        );

                    } else {

                        # Add the user command to GA::Client's hash. It's a constant variable (once
                        #   set by this function), so we can't use ->ivAdd
                        $self->{'constUserCmdHash'}{lc($userCmd)} = lc($string);
                    }
                }

                # The customisable hash of user commands is, for the time being, identical
                $self->ivPoke('userCmdHash', $self->constUserCmdHash);
            }
        }

        # Setup complete
        return 1;
    }

    sub initialiseToolbar {

        # Called by $self->start and GA::PrefWin::Client->toolbarTab
        # Creates a default set of toolbar button objects and updates the IVs $self->toolbarHash
        #   and ->toolbarList
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there's an error creating a toolbar button object
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my @defaultList;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->initialiseToolbar', @_);
        }

        # Empty the existing IVs
        $self->ivEmpty('toolbarHash');
        $self->ivEmpty('toolbarList');

        # The items are in groups of 6, one group for each GA::Obj::Toolbar object to be created.
        #   However, separators are in groups of 1
        @defaultList = $self->constToolbarList;
        if (@defaultList) {

            do {

                my ($name, $descrip, $iconPath, $instruct, $sessionFlag, $connectFlag);

                if ($defaultList[0] eq 'separator') {

                    shift @defaultList,
                    $self->ivPush('toolbarList', 'separator');

                } else {

                    $name = shift @defaultList;
                    $descrip = shift @defaultList;
                    $iconPath = shift @defaultList;
                    $instruct = shift @defaultList;
                    $sessionFlag = shift @defaultList;
                    $connectFlag = shift @defaultList;

                    # Check that $name and $descrip are valid
                    if (! $self->nameCheck($name, 16)) {

                        $self->writeWarning(
                            'Invalid default toolbar button name \'' . $name . '\'',
                            $self->_objClass . '->initialiseToolbar',
                        );

                    } elsif (length ($descrip) > 32) {

                        $self->writeWarning(
                            'Invalid default toolbar button description (button \'' . $name . '\')',
                            $self->_objClass . '->initialiseToolbar',
                        );

                    } else {

                        # Create a new toolbar button object
                        my $obj = Games::Axmud::Obj::Toolbar->new(
                            $name,
                            $descrip,
                            FALSE,          # Default, not custom, toolbar button
                            $iconPath,
                            $instruct,
                            $sessionFlag,
                            $connectFlag,
                        );

                        if (! $obj) {

                            return undef;

                        } else {

                            $self->ivAdd('toolbarHash', $obj->name, $obj);
                            $self->ivPush('toolbarList', $obj->name);
                        }
                    }
                }

            } until (! @defaultList);
        }

        return 1;
    }

    sub connectBlind {

        # Called by $self->start in Axmud blind mode
        # Open a series of standard 'dialogue' windows, allowing the visually-impaired user to
        #   select a world and/or character
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my (
            $newWorldString, $newCharString, $title, $choice, $connectWorld, $connectWorldObj,
            $connectHost, $connectPort, $loginMode, $connectChar, $connectPwd, $connectAccount,
            $startFlag,
            @faveList, @visitedList, @otherList, @comboList, @comboList2, @comboList3,
            %worldHash, %nameHash, %checkHash, %loginHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->connectBlind', @_);
        }

        # Make sure the test window for finding desktop panels has been removed
        $self->desktopObj->updateWidgets($self->_objClass . '->connectBlind');

        # Get a list of worlds, favourite worlds first, then all visited worlds sorted by number
        #   of visits, finally unvisited worlds sorted alphabetically
        # (Code borrowed from GA::OtherWin::Connect->resetTreeView)

        $newWorldString = 'Create new world';
        $newCharString = 'Create new character';

        # For each world, decide which name to use. Create a hash in the form
        #   $nameHash{profile_name} = displayed_name
        #   (where 'displayed_name' is the long name, if available, or the profile name, if not
        # At the same time, create a parallel hash to check for duplicate long names, in the form
        #   $checkHash{long_name} = profile_name
        # If duplicate long names are found, 'displayed_name' should include both the long name and
        #   the profile name
        %worldHash = $self->worldProfHash;
        foreach my $worldObj (values %worldHash) {

            my ($otherWorld, $otherWorldObj);

            if ($worldObj->longName) {

                if ($worldObj->longName eq $newWorldString) {

                    $nameHash{$worldObj->name} = $worldObj->longName . ' (' . $worldObj->name . ')';
                    $checkHash{$worldObj->longName} = $worldObj->name;

                } elsif (exists $checkHash{$worldObj->longName}) {

                    # Amend both entries to include the long name and the profile name
                    $otherWorld = $checkHash{$worldObj->longName};
                    $otherWorldObj = $worldHash{$otherWorld};

                    $nameHash{$worldObj->name} = $worldObj->longName . ' (' . $worldObj->name . ')';
                    # (There's already an entry in $checkHash matching ->longName)
                    $nameHash{$otherWorld}
                        = $otherWorldObj->longName . ' (' . $otherWorldObj->name . ')';

                } else {

                    # Not a duplicate, so just display the long name
                    $nameHash{$worldObj->name} = $worldObj->longName;
                    $checkHash{$worldObj->longName} = $worldObj->name;
                }

            } else {

                # Just display the profile name
                $nameHash{$worldObj->name} = $worldObj->name;
            }
        }

        # Remove all favourite worlds from %worldHash, so they can be displayed first
        foreach my $name ($self->favouriteWorldList) {

            if (exists $worldHash{$name}) {

                push (@faveList, $worldHash{$name});
                delete $worldHash{$name};
            }
        }

        # Remove all visited worlds from %worldHash, so they can be displayed next
        foreach my $name (keys %worldHash) {

            my $worldObj = $worldHash{$name};

            if ($worldObj->numberConnects) {

                push (@visitedList, $worldObj);
                delete $worldHash{$name};
            }
        }

        # ...and sort that list so the most-visited worlds appear at the top
        @visitedList = sort {$a->numberConnects <=> $b->numberConnects} (@visitedList);

        # Now sort the remaining world profiles alphabetically
        @otherList = sort {lc($nameHash{$a->name}) cmp lc($nameHash{$b->name})} (values %worldHash);

        # Combine the three lists, replacing the GA::Profile::World objects with a name
        foreach my $worldObj (@faveList, @visitedList) {

            push (@comboList, $nameHash{$worldObj->name});
        }

        # The 'create new world' goes at the top
        push (@comboList, $newWorldString);

        foreach my $worldObj (@otherList) {

            push (@comboList, $nameHash{$worldObj->name});
        }

        # Open the 'dialogue' window. Don't use the welcome message more than once
        if (! $self->sessionCount) {
            $title = 'Welcome to ' . $axmud::SCRIPT;
        } else {
            $title = 'Connect to a world';
        }

        $choice = $self->mainWin->showComboDialogue(
            $title,
            'Please use your cursor keys to select a world, and your tab and enter keys to click'
            . ' OK',
            \@comboList,
            TRUE,                       # Show only a single OK button
        );

        if (! $choice) {

            return $self->stop();

        } elsif ($choice ne $newWorldString) {

            $connectWorld = $checkHash{$choice};
            $connectWorldObj = $self->ivShow('worldProfHash', $connectWorld);
        }

        # Branch 1 - new world profile
        # ----------------------------

        if ($choice eq $newWorldString) {

            $connectWorld = $self->mainWin->showEntryDialogue(
                'New world',
                'Enter a name for the new world and press RETURN (maximum 16 characters and no'
                . ' spaces)',
                16,
                undef, undef, undef,
                TRUE,                   # Show only a single OK button
            );

            if (! $connectWorld) {

                return $self->stop();

            } elsif ($self->ivExists('worldProfHash', $connectWorld)) {

                $connectWorldObj = $self->ivShow('worldProfHash', $connectWorld);

            } else {

                $connectHost = $self->mainWin->showEntryDialogue(
                    'Host',
                    'Enter the DNS or IP address for the world and press RETURN',
                    256,
                    undef, undef, undef,
                    TRUE,                   # Show only a single OK button
                );

                if (! $connectHost) {

                    return $self->stop();
                }

                $connectPort = $self->mainWin->showEntryDialogue(
                    'Port',
                    'Enter the port and press RETURN',
                    256,
                    undef, undef, undef,
                    TRUE,                   # Show only a single OK button
                );

                if (! $connectPort) {

                    return $self->stop();
                }

                # (A subset of login modes in GA::Profile::World->loginMode)
                %loginHash = (
                    'No automatic login'                => 'none',
                    'LP / Diku / AberMUD style logins'  => 'lp',
                    'TinyMUD style logins'              => 'tiny',
                    'Basic telnet logins'               => 'telnet',
                );

                @comboList3 = (
                    'No automatic login',
                    'LP / Diku / AberMUD style logins',
                    'TinyMUD style logins',
                    'Basic telnet logins',
                );

                $choice = $self->mainWin->showComboDialogue(
                    'Automatic login mode',
                    'What kind of login does this world use? (If you\'re not sure, select \'no'
                    . ' automatic login\')',
                    \@comboList3,
                    TRUE,                       # Show only a single OK button
                );

                if (! $choice) {
                    $loginMode = 'none';
                } else {
                    $loginMode = $loginHash{$choice};
                }

                # (Characters are optional)
                $connectChar = $self->mainWin->showEntryDialogue(
                    'Character',
                    'Enter a character name and press RETURN',
                    16,
                    undef, undef, undef,
                    TRUE,                   # Show only a single OK button
                );

                if ($connectChar) {

                    # (Passwords are optional)
                    $connectPwd = $self->mainWin->showEntryDialogue(
                        'Password',
                        'Enter a password and press RETURN',
                        16,
                        undef, undef, undef,
                        TRUE,                   # Show only a single OK button
                    );
                }

                # Ready to start the session
                $startFlag = TRUE;
            }
        }

        # Branch 2 - existing world profile
        # ---------------------------------

        if (! $startFlag) {

            # Get a sorted list of player profiles, with the most recently-connected player at the
            #   top
            foreach my $char ($connectWorldObj->ivKeys('passwordHash')) {

                if (
                    ! $connectWorldObj->lastConnectChar
                    || $char eq $connectWorldObj->lastConnectChar
                ) {
                    push (@comboList2, $char);
                }
            }

            # (If there are no characters in the list, skip the next dialogue)
            if (@comboList2) {

                push (@comboList2, $newCharString);

                $choice = $self->mainWin->showComboDialogue(
                    'Select character',
                    'Use your cursor keys to select a character, and your tab and enter keys to'
                    . ' click OK',
                    \@comboList2,
                    TRUE,                       # Show only a single OK button
                );

                if (! $choice) {

                    return $self->stop();

                } elsif ($choice ne $newCharString) {

                    $connectChar = $choice;

                    ($connectHost, $connectPort, $connectChar, $connectPwd, $connectAccount)
                        = $connectWorldObj->getConnectDetails($connectChar);
                }
            }

            if (! $connectChar) {

                # (Characters are optional)
                $connectChar = $self->mainWin->showEntryDialogue(
                    'Character',
                    'Enter a character name and press RETURN',
                    16,
                    undef, undef, undef,
                    TRUE,                   # Show only a single OK button
                );

                if ($connectChar) {

                    # (Passwords are optional)
                    $connectPwd = $self->mainWin->showEntryDialogue(
                        'Password',
                        'Enter a password and press RETURN',
                        16,
                        undef, undef, undef,
                        TRUE,                   # Show only a single OK button
                    );
                }

                ($connectHost, $connectPort) = $connectWorldObj->getConnectDetails();
            }
        }

        # Start the session
        if (
            ! $self->startSession(
                $connectWorld,
                $connectHost,
                $connectPort,
                $connectChar,
                $connectPwd,
                $connectAccount,
                undef,                  # Default protocol
                $loginMode,             # May be 'undef'
            )
        ) {
            # Display a confirmation
            $self->mainWin->showMsgDialogue(
                'Failed connection',
                'error',
                'General error while connecting to \'' . $connectWorld . '\'',
                'ok',
            );

            return $self->stop();

        } else {

            # Operation complete
            return 1;
        }
    }

    sub addGlobalInitTask {

        # Called by $self->start (when no sessions are running) to add a task to the global initial
        #   tasklist
        # (Also called by functions in GA::WizWin::Setup)
        #
        # Expected arguments
        #   $taskName   - The task's formal name (e.g. 'status_task')
        #
        # Return values
        #   'undef' on improper arguments or if the initial task can't be added
        #   Otherwise returns the new initial task

        my ($self, $taskName, $check) = @_;

        # Local variables
        my ($packageName, $taskObj);

        # Check for improper arguments
        if (! defined $taskName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addGlobalInitTask', @_);
        }

        # Get the package name corresponding to $taskName (e.g. 'Games::Axmud::Task::Status',
        #   'Games::Axmud::Task::Divert')
        $packageName = $self->ivShow('constTaskPackageHash', $taskName);
        if (! $packageName) {

            return undef;
        }

        # Create the task object. We have to cheat a bit and name this GA::Client as the parent
        #   GA::Session (it's not stored as an IV)
        $taskObj = $packageName->new($self);
        if (! $taskObj) {

            return undef;
        }

        # (No need to check plugins, normally done by a call to GA::Generic::Task->checkPlugins -
        #   only built-in tasks exist in ->constTaskPackageHash)

        # Set the standard IV (normally done by GA::Generic::Task->setParentFileObj)
        $taskObj->{_parentFile} = 'tasks';
        # Set the task type (normally done in the call to $taskObj->new)
        $taskObj->{taskType} = 'initial';

        # Update the global initial tasklist (normally done by GA::Generic::Task->updateTaskLists)
        # Give task a unique name within the global initial tasklist
        $taskObj->{uniqueName} = $taskObj->{name} . '_' . $self->inc_initTaskTotal();
        # Create an entry in the global initial tasklist (this call marks the parent file objects as
        #   having had its data modified)
        $self->add_initTask($taskObj);

        return $taskObj;
    }

    # Client and session loop

    sub startClientLoop {

        # Called by $self->start
        # Starts the client loop, which calls $self->spinClientLoop whenever the loop spins
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the loop can't be started
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $loopObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->startClientLoop', @_);
        }

        # Create the object that handles the loop
        $loopObj = Games::Axmud::Obj::Loop->new(
            $self,
            'spinClientLoop',
            'client',
        );

        if (! $loopObj) {

            return undef;

        } else {

            $self->ivPoke('clientLoopObj', $loopObj);
        }

        # Start the loop
        if (! $loopObj->startLoop($self->clientLoopDelay)) {

            return undef;

        } else {

            # Initialise blinking text in textviews, with text initially visible
            $self->ivPoke('blinkSlowCheckTime', $self->clientTime + ($self->blinkSlowTime / 2));
            $self->ivPoke('blinkSlowFlag', TRUE);
            $self->ivPoke('blinkFastCheckTime', $self->clientTime + ($self->blinkFastTime / 2));
            $self->ivPoke('blinkFastFlag', TRUE);

            return 1;
        }
    }

    sub stopClientLoop {

        # Called by $self->stop
        # Stops the client loop
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if the loop isn't running or if it can't be stopped
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $result;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->stopClientLoop', @_);
        }

        if (! $self->clientLoopObj) {

            return undef;
        }

        # Stop the loop
        $result = $self->clientLoopObj->stopLoop();

        # Update IVs
        $self->ivUndef('clientLoopObj');

        return $result;
    }

    sub spinClientLoop {

        # Called by $self->clientLoopObj->spinLoop when the client loop spins
        # Updates 'internal' windows and some of their strip objects. Makes blinking text in
        #   Gtk3::Textviews blink on or off. Checks file objects and, if any need to be saved,
        #   updates the title of 'main' windows
        #
        # Expected arguments
        #   $loopObj    - The GA::Obj::Loop object handling the client loop
        #
        # Return values
        #   'undef' on improper arguments, if the client loop isn't running or if $loopObj is the
        #       wrong loop object
        #   1 otherwise

        my ($self, $loopObj, $check) = @_;

        # Local variables
        my (
            $connectInfoFlag, $result,
            @bufferList,
        );

        # Check for improper arguments
        if (! defined $loopObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->spinClientLoop', @_);
        }

        if (
            ! $self->clientLoopObj
            || $self->clientLoopObj ne $loopObj
            || $self->suspendSessionLoopFlag
        ) {
            return undef;
        }

        # Update IVs
        $self->ivPoke('clientTime', $loopObj->spinTime);

        # Update blinkers states for each session
        foreach my $session ($self->listSessions()) {

            $session->updateBlinkers();
        }

        # Update 'internal' windows
        foreach my $winObj ($self->desktopObj->listGridWins()) {

            my (
                $stripObj,
                %hash,
            );

            if (
                $winObj->winType eq 'main'
                || $winObj->winType eq 'protocol'
                || $winObj->winType eq 'custom'
            ) {
                # If the GA::Strip::GaugeBox strip object's gauge box has been empty for too long,
                #   remove it
                $stripObj = $winObj->ivShow('firstStripHash', 'Games::Axmud::Strip::GaugeBox');
                if (
                    $stripObj
                    && defined $stripObj->gaugeCheckTime
                    && $stripObj->gaugeCheckTime < $self->clientTime
                ) {
                    $stripObj->removeGaugeBox();
                }

                # If the GA::Strip::Entry strip object's console button is in flashing mode, make
                #   it flash once
                if ($winObj->visibleSession && $winObj->visibleSession->systemMsgCheckTime) {

                    $stripObj = $winObj->ivShow('firstStripHash', 'Games::Axmud::Strip::Entry');
                    if ($stripObj) {

                        $stripObj->set_consoleIconFlash();
                    }
                }

                # Update the GA::Strip::ConnectInfo strip object in every 'internal' window
                #   approximately every second
                # (GA::Strip::ConnectInfo are allowed in 'internal' windows besides 'main' windows,
                #   but they don't display connection data)
                if ($winObj->visibleSession) {

                    if (
                        ! $winObj->visibleSession->connectInfoCheckTime
                        || $winObj->visibleSession->connectInfoCheckTime
                                < int($winObj->visibleSession->sessionTime)
                    ) {
                        $winObj->setTimeLabel($winObj->visibleSession->getTimeLabelText());
                    }

                } else {

                    $winObj->setTimeLabel('');
                }

                # Re-draw blinkers in any 'internal' window which uses them, as appropriate
                # (GA::Strip::ConnectInfo are allowed in 'internal' windows besides 'main' windows,
                #   but blinkers are only updated in the session's 'main' window)
                if ($winObj->visibleSession) {

                    $stripObj
                        = $winObj->ivShow('firstStripHash', 'Games::Axmud::Strip::ConnectInfo');

                    if ($stripObj) {

                        # Import the visible session's blinker state hash (for convenience)
                        %hash = $winObj->visibleSession->blinkerStateHash;

                        # Redraw each blinker that is off, but should be on (and vice-versa)
                        foreach my $blinkerNum (keys %hash) {

                            my ($blinkerState, $blinkerObj);

                            $blinkerState = $hash{$blinkerNum};
                            $blinkerObj = $stripObj->ivShow('blinkerHash', $blinkerNum);

                            if (
                                $blinkerObj
                                && (
                                    (defined $blinkerState && ! $blinkerObj->onFlag)
                                    || (! defined $blinkerState && $blinkerObj->onFlag)
                                )
                            ) {
                                # Redraw this blinker
                                $stripObj->drawBlinker($blinkerNum, ! ($blinkerObj->onFlag));
                            }
                        }
                    }
                }
            }
        }

        # Get a list of textview buffers which might contain blinking text
        foreach my $textViewObj ($self->desktopObj->ivValues('textViewHash')) {

            push (@bufferList, $textViewObj->buffer);
        }

        # Update the buffers' text tags (if it's time to do so), making the text appear or disappear
        #   on cue
        if ($self->clientTime > $self->blinkSlowCheckTime) {

            foreach my $buffer (@bufferList) {

                my ($blinkTag, $cursorTag);

                $blinkTag = $buffer->get_tag_table->lookup('blink_slow');
                $cursorTag = $buffer->get_tag_table->lookup('cursor');

                if ($blinkTag) {

                    $blinkTag->set_property('foreground-set', $self->blinkSlowFlag);
                    $blinkTag->set_property('background-set', $self->blinkSlowFlag);
                }

                # The textview object's cursor is updated at the same time
                if ($cursorTag && ! $self->useFastCursorFlag) {

                    if ($self->blinkSlowFlag) {
                        $cursorTag->set_property('underline', 'single');
                    } else {
                        $cursorTag->set_property('underline', 'none');
                    }
                }
            }

            if ($self->blinkSlowFlag) {
                $self->ivPoke('blinkSlowFlag', FALSE);
            } else {
                $self->ivPoke('blinkSlowFlag', TRUE);
            }

            $self->ivPoke('blinkSlowCheckTime', $self->clientTime + ($self->blinkSlowTime / 2));
        }

        if ($self->clientTime > $self->blinkFastCheckTime) {

            foreach my $buffer (@bufferList) {

                my ($blinkTag, $cursorTag);

                $blinkTag = $buffer->get_tag_table->lookup('blink_fast');
                $cursorTag = $buffer->get_tag_table->lookup('cursor');

                if ($blinkTag) {

                    $blinkTag->set_property('foreground-set', $self->blinkFastFlag);
                    $blinkTag->set_property('background-set', $self->blinkFastFlag);
                }

                # The textview object's cursor is updated at the same time
                if ($cursorTag && $self->useFastCursorFlag) {

                    if ($self->blinkFastFlag) {
                        $cursorTag->set_property('underline', 'single');
                    } else {
                        $cursorTag->set_property('underline', 'none');
                    }
                }
            }

            if ($self->blinkFastFlag) {
                $self->ivPoke('blinkFastFlag', FALSE);
            } else {
                $self->ivPoke('blinkFastFlag', TRUE);
            }

            $self->ivPoke('blinkFastCheckTime', $self->clientTime + ($self->blinkFastTime / 2));
        }

        # Checks all the file objects stored in $self->fileObjHash and change the title of all
        #   'main' windows, if necessary (using an asterisk to show that at least one file needs to
        #   be saved, and no asterisk to show that none of them need to be saved)
        $self->checkMainWinTitles();

        # Restore the border size of any pane objects whose border size has been briefly increased
        $self->paneRestoreBorder();

        return 1;
    }

    sub haltSessionLoops {

        # Called by $SIG{__DIE__} in axmud.pl
        # We don't know which GA::Session caused the Perl error, but we can leave Axmud in a (more
        #   or less) functional state by halting all client loops and session loops; the user can
        #   restart them, when ready, with the ';restart' command
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->haltSessionLoops', @_);
        }

        $self->ivPoke('suspendSessionLoopFlag', TRUE);

        # The Glib::Timeout might have stopped, or not (depending on what caused the error), so we
        #   need to formally stop it
        foreach my $session ($self->ivValues('sessionHash')) {

            $session->stopSessionLoop();
        }

        @list = (
            ' ',
            'Because of a Perl error, ' . $axmud::SCRIPT . ' internal processes have been'
            . ' suspended across all sessions. (This will prevent you from seeing the same'
            . ' error message again and again, and will perhaps protect your stored data'
            . ' from getting corrupted. If there are several sessions open, the error is'
            . ' sometimes visible only in one session.)',
            ' ',
            'Most errors of this kind are caused by invalid patterns (regular expressions)'
            . ' in your interfaces (triggers, aliases, macros, timers and hooks). You can'
            . ' often correct them by opening an \'edit\' window and by replacing the'
            . ' invalid pattern with a valid one or by deleting it altogether.',
            ' ',
            'If the error was caused by a faulty plugin, the plugin can be disabled with'
            . ' the \';disableplugin\' command. Errors with the ' . $axmud::SCRIPT . ' code'
            . ' itself should be reported to the authors.',
            ' ',
            'When you are ready, you can use the \';restart\' command to return '
            . $axmud::SCRIPT . ' to a more-or-less functional state.',
            ' ',
            '---',
            ' ',
            'Too long, didn\'t read? Just type:   ;restart',
            ' ',
        );

        foreach my $session ($self->ivValues('sessionHash')) {

            foreach my $line (@list) {

                $session->writeText($line);
            }
        }

        return 1;
    }

    sub restoreSessionLoops {

        # Called by GA::Cmd::Restart->do
        # Restarts client/session loops stopped by a call to $self->haltSessionLoops
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->restoreSessionLoops', @_);
        }

        $self->ivPoke('suspendSessionLoopFlag', FALSE);

        # The Glib::Timeout might have stopped, or not (depending on what caused the error), so we
        #   need to formally stop it
        foreach my $session ($self->ivValues('sessionHash')) {

            $session->startSessionLoop();
        }

        return 1;
    }

    sub checkMainWinTitles {

        # Called by $self->spinClientLoop
        # This titles of all 'main' windows need to be changed from time to time (all 'main' windows
        #   have the same title, and any changes are performed on all 'main' windows at the same
        #   time)
        # This function checks whether it's necessary to change them and performs the operation, if
        #   so
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
            $exitFlag,
            @winObjList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkMainWinTitles', @_);
        }

        # Get an ordered list of all 'main' windows
        @winObjList = $self->desktopObj->listGridWins('main');

        # Check file objects for the client
        if ($self->showModFlag) {

            # 'main' window titles contain an asterisk, meaning that some files need to be saved. If
            #   they have all been saved, we change the titles
            OUTER: foreach my $fileObj ($self->ivValues('fileObjHash')) {

                if ($fileObj->modifyFlag) {

                    $exitFlag = TRUE;
                    last OUTER;
                }
            }

            if (! $exitFlag) {

                # All files already saved; change 'main' windows titles
                foreach my $winObj (@winObjList) {

                    $winObj->setMainWinTitle(FALSE);
                }

                # Update IVs
                $self->ivPoke('showModFlag', FALSE);
            }

        } else {

            # 'main' window titles don't contain an asterisk, meaning that no files need to be
            #   saved. If any of them now need to be saved, we change the titles
            OUTER: foreach my $fileObj ($self->ivValues('fileObjHash')) {

                if ($fileObj->modifyFlag) {

                    $exitFlag = TRUE;
                    last OUTER;
                }
            }

            if ($exitFlag) {

                # At least one file needs to be saved; change the label (the window's ->showModFlag
                #   is automatically updated)
                # All files already saved; change 'main' window titles
                foreach my $winObj (@winObjList) {

                    $winObj->setMainWinTitle(TRUE);
                }

                # Update IVs
                $self->ivPoke('showModFlag', TRUE);
            }
        }

        return 1;
    }

    sub paneModifyBorder {

        # Called by GA::Strip::Entry->setSwitchSignals
        # In 'internal' windows, that strip object includes a switcher button to switch between pane
        #   objects (GA::Table::Pane); the scroll lock/split screen buttons then apply to the
        #   selected pane object
        # When a pane object is selected, this function is called to briefly increase the pane's
        #   border size; any other panes in the same window are immediately restored
        # The size of this pane is restored to normal by a call to $self->paneRestoreBorder from
        #   $self->spinClientLoop
        #
        # Expected arguments
        #   $paneObj    - The selected pane object
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $paneObj, $check) = @_;

        # Check for improper arguments
        if (! defined $paneObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->paneModifyBorder', @_);
        }

        # Immediately restore the border size of any other pane object in this window
        foreach my $time ($self->ivKeys('paneRestoreHash')) {

            my $otherPaneObj = $self->ivShow('paneRestoreHash', $time);

            if ($otherPaneObj->winObj && $otherPaneObj->winObj eq $paneObj->winObj) {

                # Restore this pane object's border size immediately
                $otherPaneObj->set_borderWidth(FALSE);
                $self->ivDelete('paneRestoreHash', $time);
            }
        }

        # Modify the pane's border size
        $paneObj->set_borderWidth(TRUE);
        # Add an entry for this pane object, setting the time at which its border will be restored
        # Pane object numbers are not unique to the client, so in this hash we take the unusual
        #   step of using a system time as a key, matching the time at which the border size
        #   should be restored
        $self->ivAdd('paneRestoreHash', ($self->clientTime + $self->paneDelay), $paneObj);

        return 1;
    }

    sub paneRestoreBorder {

        # Called by $self->spinClientLoop
        # In 'internal' windows, the strip object GA::Strip::Entry includes a switcher button to
        #   switch between pane objects (GA::Table::Pane); the scroll lock/split screen buttons
        #   then apply to the selected pane object
        # When a pane object is selected, $self->paneModifyBorder is called to briefly increase the
        #   pane's border size; the client loop calls this function to check whether it's time to
        #   restore any border sizes, and to restore them if so
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->paneRestoreBorder', @_);
        }

        foreach my $time ($self->ivKeys('paneRestoreHash')) {

            my $paneObj;

            if ($time < $self->clientTime) {

                $paneObj = $self->ivShow('paneRestoreHash', $time);
                # Check the pane object and its window still exist (just in case)
                if (
                    $paneObj->winObj
                    && $self->desktopObj->ivExists('gridWinHash', $paneObj->winObj->number)
                ) {
                    # Restore this pane object's border size immediately
                    $paneObj->set_borderWidth(FALSE);
                    $self->ivDelete('paneRestoreHash', $time);
                }
            }
        }

        return 1;
    }

    # Session methods

    sub startSession {

        # Called initially by GA::OtherWin::Connect->connectWorldCallback or $self->connectBlind,
        #   thereafter by GA::Cmd::Connect->do, Reconnect->do, XConnect->do, Telnet->do, SSH->do and
        #   SSL->do
        # Starts a session (managing a single connection to a world)
        #
        # Expected arguments
        #   $world          - The world's name (matches a world profile name)
        #
        # Optional arguments
        #   $host           - The world's host address (if 'undef', default host address used)
        #   $port           - The world's port (if 'undef', default host port used)
        #   $char           - A character name (matches a character profile name (if 'undef', no
        #                       character profile used)
        #   $pass           - The corresponding password (if 'undef', the world profile is consulted
        #                       to provide the password, if possible)
        #   $account        - The character's associated account name, for worlds that use both
        #                       (if 'undef', no account name used)
        #   $protocol       - If set to 'telnet', 'ssh' or 'ssl', that protocol is used; if 'undef'
        #                       or an unrecognised value, the world profile's ->protocol is used
        #   $loginMode      - Set when called by $self->connectBlind, when a new world profile is to
        #                       be created, and the user has specified what type of ->loginMode this
        #                       world uses; otherwise set to 'undef'
        #   $offlineFlag    - If TRUE, the session doesn't actually connect to the world, but still
        #                       loads all data and makes some client commands available. If FALSE
        #                       (or 'undef'), the session tries to connect to the world
        #   $tempFlag       - If set to TRUE, the world profile is a temporary world profile,
        #                       created because the user didn't specify a world name. File saving
        #                       in the session will be disabled. Otherwise set to FALSE (or
        #                       'undef')
        #
        # Return values
        #   'undef' on improper arguments or if the GA::Session object can't be created or started
        #   The new GA::Session object on success

        my (
            $self, $world, $host, $port, $char, $pass, $account, $protocol, $loginMode,
            $offlineFlag, $tempFlag, $check,
        ) = @_;

        # Local variables
        my ($actualCount, $tempName, $successFlag, $worldObj, $newSession, $index);

        # Check for improper arguments
        if (! defined $world || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->startSession', @_);
        }

        # In blind mode, only one session is allowed. To allow the user to use ';reconnect', and
        #   so on, terminate the existing session which is not connected to a world before
        #   creating a new one
        if ($axmud::BLIND_MODE_FLAG) {

            foreach my $session ($self->listSessions()) {

                if (
                    $session->status eq 'waiting'
                    || $session->status eq 'offline'
                    || $session->status eq 'disconnected'
                ) {
                    $self->stopSession($session);
                }
            }
        }

        # Count the number of active sessions
        $actualCount = $self->ivPairs('sessionHash');

        # Check that we don't already have too many sessions
        if ($actualCount >= $self->sessionMax) {

            $self->mainWin->showMsgDialogue(
                'Session limit reached',
                'error',
                'Can\'t open a new session (' . $axmud::SCRIPT . ' has reached its limit of '
                . $self->sessionMax . ' sessions - see the help for \';maxsession\')',
                'ok',
            );

            return undef;

        } elsif ($axmud::BLIND_MODE_FLAG && $actualCount >= 1) {

            $self->mainWin->showMsgDialogue(
                'Session limit reached',
                'error',
                'Can\'t open multiple sessions when ' . $axmud::SCRIPT . ' is running in \'blind\''
                . ' mode',
                'ok',
            );

            return undef;
        }

        # Two sessions can have the same current world, but they can't have the same current
        #   character (unless one of them has their ->status set to 'disconnected')
        if ($char && $self->testSessions($world, $char, TRUE)) {

            $self->mainWin->showMsgDialogue(
                'Duplicate character',
                'error',
                'You are already connected to \'' . $world . '\' using the character \'' . $char
                . '\'',
                'ok',
            );

            return undef;
        }

        # For temporary profiles, check a world profile with the same name doesn't already exist
        #   and, if so, rename the temporary profile
        if ($tempFlag && $self->ivExists('worldProfHash', $world)) {

            # (Give up after too many renaming attempts)
            OUTER: for (my $count = 2; $count < 999; $count++) {

                $tempName = $world . $count;        # e.g. 'deathmud2'

                # Max length of a profile is 16 chars
                if (length ($tempName) <= 16 && ! $self->ivExists('worldProfHash', $tempName)) {

                    $world = $tempName;
                    $successFlag = TRUE;
                    last OUTER;
                }
            }

            if (! $successFlag) {

                $self->mainWin->showMsgDialogue(
                    'Bad temporary world',
                    'error',
                    'Attempted to create a temporary world profile, but a world profile called \''
                    . $world . '\' already exists, and ' . $axmud::SCRIPT . ' could not find an'
                    . ' alternative name',
                    'ok',
                );

                return undef;
            }
        }

        # If $host and/or $port were not specified, use generic values
        if (! defined $host) {

            $host = '127.0.0.1';
        }

        if (! defined $port) {

            $port = 23;
        }

        # If $protocol is not recognised, use a default value
        if (
            defined $protocol && $protocol ne 'telnet' && $protocol ne 'ssh' && $protocol ne 'ssl'
        ) {
            # Default is 'telnet'
            $protocol = undef;
        }

        # Create the GA::Session
        $newSession = Games::Axmud::Session->new(
            $self->sessionCount,
            $world,
            $host,
            $port,
            $char,
            $pass,
            $account,
            $protocol,
            $loginMode,
            $offlineFlag,
            $tempFlag,
        );

        if (! $newSession) {

            return undef;
        }

        # Session object created. Update IVs
        $self->ivIncrement('sessionCount');
        $self->ivAdd('sessionHash', $newSession->number, $newSession);

        # Start the session
        if (! $newSession->start()) {
            return undef;
        } else {
            return $newSession;
        }
    }

    sub stopSession {

        # Called by GA::Cmd::StopSession->do, $self->disablePlugin and GA::Session->del_winObj
        # Also called by $self->startSession in blind mode, to remove the existing disconnected
        #   session
        #
        # Stops a GA::Session
        #
        # Expected arguments
        #   $session        - The GA::Session object to stop
        #
        # Return values
        #   'undef' on improper arguments, if the session is missing from the registry or if it
        #       can't be stopped (no error msgs)
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Local variables
        my $nextSession;

        # Check for improper arguments
        if (! defined $session || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->stopSession', @_);
        }

        if (! $self->ivExists('sessionHash', $session->number)) {

            # $session seems to be missing from the registry
            return $self->writeError(
               'Session #' . $session->number . ' missing from session registry',
                $self->_objClass . '->stopSession',
            );

        } else {

            # Update IVs
            $self->ivDelete('sessionHash', $session->number);

            # Terminate the session
            $session->stop();
            if ($self->currentSession eq $session) {

               if (! $self->sessionHash) {

                    # There are no more sessions left
                    $self->setCurrentSession();
                    if (! $self->shareMainWinFlag) {

                        # When sessions don't share a 'main' window, close the client when the last
                        #   session terminates
                        # (If sessions do share a 'main' window, GA::Session->stop has already
                        #   created a spare 'main' window, and the client doesn't stop)
                        $self->stop();
                    }

                } else {

                    # Decide which session is the new current one. It's the one which was created
                    #   after $session but, if $session was the most recently-created one, it's
                    #   the one created last
                    # (The TRUE argument means use the last one, rather than the first one, if
                    #   necessary)
                    $nextSession = $self->getNextSession($session, TRUE);
                    if ($nextSession) {

                        # Make the session's default tab the new visible tab in its pane object
                        if ($nextSession->defaultTabObj) {

                            $nextSession->defaultTabObj->paneObj->setVisibleTab(
                                $nextSession->defaultTabObj,
                            );
                        }

                        # If all sessions have their own 'main' window, make sure the new current
                        #   session's 'main' window is visible
                        if (! $self->shareMainWinFlag) {

                            $nextSession->mainWin->restoreFocus();
                        }
                    }
                }
            }

            return 1;
        }
    }

    sub stopAllSessions {

        # Called by $self->stop
        # Stops every GA::Session
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if no sessions exist or if a session can't be closed (no
        #       error msgs)
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->stopAllSessions', @_);
        }

        if (! $self->sessionHash) {

            # There are no sessions to stop
            return undef;
        }

        # Close every session
        foreach my $session ($self->listSessions()) {

            # Terminate the session
            if (! $session->stop()) {

                # Failed to terminate the session
                return undef;
            }
        }

        # The call we're about to make to ->setCurrentSession requires an empty ->sessionHash
        $self->ivEmpty('sessionHash');

        # All sessions terminated
        $self->setCurrentSession();

        return 1;
    }

    sub setCurrentSession {

        # Called by GA::Win::Internal->setVisibleSession whenever a 'main' window that has focus
        #   changes its visible session. Also called by $self->stopSession and ->stopAllSessions
        # Updates IVs and fires some hooks
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $session    - The GA::Session that is the new current session. Unless the registry
        #                   $self->sessionHash is empty, there must be a current session at all
        #                   times. If not specified, there is no current session
        #
        # Return values
        #   'undef' on improper arguments or if no new current session is specified when the
        #       registry is not empty
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setCurrentSession', @_);
        }

        # No current session
        if (! defined $session) {

           if ($self->sessionHash) {

                # The registry is not empty, but should be
                return $self->writeError(
                    'Could not set a null session - registry not empty',
                    $self->_objClass . '->setCurrentSession',
                );

            } else {

                $self->ivUndef('currentSession');
               $self->ivEmpty('sessionHash');
            }

        # New current session
        } else {

            if (
                $self->currentSession
                && $self->currentSession ne $session
                && $self->shareMainWinFlag
            ) {
                # Fire any hooks that are using the 'not_current' hook event
                $self->currentSession->checkHooks('not_current', $session->number);
            }

            $self->ivPoke('currentSession', $session);
            $self->ivPoke('mainWin', $session->mainWin);

            # Fire any hooks that are using the 'current_session' hook event
            $session->checkHooks('current_session', undef);
            # Fire any hooks that are using the 'change_current' hook event
            foreach my $otherSession ($self->listSessions()) {

                if ($otherSession ne $session) {

                    $otherSession->checkHooks('change_current', $session->number);
                }
            }
        }

        return 1;
    }

    sub getNextSession {

        # Called by $self->stopSession or any other code
        # Given a session, find the session which was created after that one. If the specified
        #   session was the most recently-created one, return either the first or last remaining
        #   session
        #
        # Expected arguments
        #   $session    - A GA::Session
        #
        # Optional arguments
        #   $lastFlag   - If there are no sessions that were created after the specified
        #                   $session, then this function returns the most recently-created other
        #                   session (if $lastFlag is TRUE), or the earliest-created other session
        #                   if ($lastFlag is FALSE or 'undef')
        #
        # Return values
        #   'undef' on improper arguments or if $self->sessionHash is empty
        #   Otherwise, returns the session described above

        my ($self, $session, $lastFlag, $check) = @_;

        # Local variables
        my ($first, $last, $match);

        # Check for improper arguments
        if (! defined $session || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->getNextSession', @_);
        }

        OUTER: foreach my $otherSession ($self->listSessions()) {

            if ($otherSession ne $session) {

                $last = $otherSession;
                if (! defined $first) {

                    $first = $otherSession;
                }

                if ($otherSession->number > $session->number) {

                    $match = $otherSession;
                    last OUTER;
                }
            }
        }

        if (! $match) {

            if ($lastFlag) {
                return $last;
            } else {
                return $first;
            }

        } else {

            return $match;
        }
    }

    sub listSessions {

        # Convenience function. Returns a list of existing GA::Session objects in the order in
        #   which they were created
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $ignoreSession  - If specified, ignore this session
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns the ordered list of sessions (may be an empty list)

        my ($self, $ignoreSession, $check) = @_;

        # Local variables
        my (@sessionList, @returnList, @emptyList);

        # Check for improper arguments
        if (defined $check) {

             $axmud::CLIENT->writeImproper($self->_objClass . '->listSessions', @_);
             return @emptyList;
        }

        if (! $ignoreSession) {

            return (sort {$a->number <=> $b->number} ($self->ivValues('sessionHash')));

        } else {

            @sessionList = sort {$a->number <=> $b->number} ($self->ivValues('sessionHash'));
            foreach my $session (@sessionList) {

                if ($session ne $ignoreSession) {

                    push (@returnList, $session);
                }
            }

            return @returnList;
        }
    }

    sub testSessions {

        # Called by $self->startSession or GA::Generic::Cmd->setProfile
        # Given specified world and character profiles, tests other sessions to see if any of them
        #   are using the same current world and character and returns the number of matching
        #   sessions
        #
        # Expected arguments
        #   $world          - Name of a world profile
        #   $char           - Name of a character profile associated with that world
        #
        # Optional arguments
        #   $ignoreFlag     - Flag set to TRUE when called by $self->startSession; ignores sessions
        #                       whose ->status is 'disconnected'. Otherwise set to FALSE (or
        #                       'undef'), and all matching session are returned
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the number of matching sessions (may be 0)

        my ($self, $world, $char, $ignoreFlag, $check) = @_;

        # Local variables
        my $count;

        # Check for improper arguments
        if (! defined $world || ! defined $char || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->testSessions', @_);
        }

        $count = 0;
        foreach my $session ($self->listSessions()) {

            if (
                $session->currentWorld->name eq $world
                && $session->currentChar && $session->currentChar->name eq $char
                && (
                    ! $ignoreFlag
                    || ($ignoreFlag && $session->status ne 'disconnected')
                )
            ) {
                $count++;
            }
        }

        return $count;
    }

    sub findSessions {

        # Called by GA::Session->setupProfiles
        # Compiles a list of sessions whose current world matches a specified world, and returns
        #   the list (in the order in which the sessions were created)
        #
        # Expected arguments
        #   $worldName      - The name of a world profile
        #
        # Optional arguments
        #   $ignoreSession  - If specified, ignore this session
        #
        # Return values
        #   An empty list on improper arguments or if no session is using $name as its current world
        #   Otherwise, returns the list of matching sessions

        my ($self, $worldName, $ignoreSession, $check) = @_;

        # Local variables
        my (@emptyList, @returnArray);

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->findSessions', @_);
            return @emptyList;
        }

        foreach my $session ($self->listSessions()) {

            if (
                (! $ignoreSession || $ignoreSession ne $session)
                && $session->currentWorld
                && $session->currentWorld->name eq $worldName
            ) {
                # This is a matching GA::Session
                push (@returnArray, $session);
            }
        }

        # Return the list of matching sessions (may be empty)
        return @returnArray;
    }

    sub checkSessions {

        # Called by GA::Strip::MenuBar->drawWorldColumn just before doing the ';stopsession' or
        #   ';stopclient' commands
        # Checks every session to see whether any of them are connected, and whether there are any
        #   unsaved files at all (if not, the 'main' window doesn't have to prompt the user for
        #   confirmation, before stopping the session/client).
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $session    - If specified, ignore other GA::Session objects (but still check the
        #                   client's file objects)
        #
        # Return values
        #   'undef' on improper arguments or if there are any connected sessions or unsaved files
        #   1 if there are absolutely no connected sessions or unsaved files

        my ($self, $session, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkSessions', @_);
        }

        # Check GA::Client file objects
        foreach my $fileObj ($self->ivValues('fileObjHash')) {

            if ($fileObj->modifyFlag) {

                return undef;
            }
        }

        # Check each session in turn
        foreach my $otherSession ($self->listSessions()) {

            if ($session && $session ne $otherSession) {

                # Ignore this session
                next OUTER;
            }

            # Check the session's connection status
            if ($otherSession->status ne 'disconnected' && $otherSession->status ne 'offline') {

                return undef;
            }

            # Check GA::Session file objects
            foreach my $fileObj ($otherSession->ivValues('sessionFileObjHash')) {

                if ($fileObj->modifyFlag) {

                    return undef;
                }
            }
        }

        # There are no connected sessions or unsaved files
        return 1;
    }

    sub broadcastInstruct {

        # Can be called by anything (with great caution!)
        # Executes an instruction in every session (optionally, with the exception of a specified
        #   session)
        #
        # Expected arguments
        #   $instruct           - The instruction to execute, e.g. 'north', ';about'
        #
        # Optional arguments
        #   $excludeSession    - The GA::Session to which the instruction should NOT be executed.
        #                           If 'undef', the instruction is executed in every session
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $instruct, $excludeSession, $check) = @_;

        # Check for improper arguments
        if (! defined $instruct || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->broadcastInstruct', @_);
        }

        foreach my $session ($self->listSessions()) {

            if (! $excludeSession || ($excludeSession ne $session)) {

                $session->doInstruct($instruct);
            }
        }

        return 1;
    }

    # Buffers

    sub updateInstructBuffer {

        # Called by GA::Session->updateInstructBuffer when an instruction is added to the session's
        #   buffer registry
        # Updates this client's own instruction buffer, creating a separate buffer object (with a
        #   different ->number than the one created by the calling function)
        #
        # Expected arguments
        #   $session    - The calling GA::Session
        #   $instruct   - The instruction itself (e.g. ';setworld deathmud' or 'north;kill orc')
        #   $type       - The type of instruction: 'client' for a client command, 'world' for a
        #                   world command, 'perl' for a Perl command and 'echo' for an echo command
        #
        # Return values
        #   'undef' on improper arguments or if the buffer is not updated
        #   Otherwise returns the buffer object created

        my ($self, $session, $instruct, $type, $check) = @_;

        # Local variables
        my $obj;

        # Check for improper arguments
        if (! defined $session || ! defined $instruct || ! defined $type || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateInstructBuffer', @_);
        }

        if (! defined $self->instructBufferFirst) {

            # This the first instruction ever processed
            $self->ivPoke('instructBufferFirst', 0);
        }

        # Create a new buffer object for this instruction
        $obj = Games::Axmud::Buffer::Instruct->new(
            $session,
            'client',
            $self->instructBufferCount,
            $instruct,
            $type,
            $self->clientTime,
        );

        if (! $obj) {

            return undef;

        } else {

            # Update the instruction buffer
            $self->ivAdd('instructBufferHash', $obj->number, $obj);
            $self->ivIncrement('instructBufferCount');
            $self->ivPoke('instructBufferLast', ($self->instructBufferCount - 1));

            # If the buffer is full, remove the oldest line
            if ($self->instructBufferCount > $self->customInstructBufferSize) {

                $self->ivDelete('instructBufferHash', $self->instructBufferFirst);
                $self->ivIncrement('instructBufferFirst');
            }

            return $obj;
        }
    }

    sub updateCmdBuffer {

        # Called by GA::Session->updateCmdBuffer when a world command is added to the session's
        #   buffer registry
        # Updates this client's own world command buffer, creating a separate buffer object (with a
        #   different ->number than the one created by the calling function)
        #
        # Expected arguments
        #   $session    - The calling GA::Session
        #   $cmd        - The world command itself (e.g. 'north', 'kill orc')
        #
        # Return values
        #   'undef' on improper arguments or if the buffer can't be updated
        #   Otherwise returns the buffer object created

        my ($self, $session, $cmd, $check) = @_;

        # Local variables
        my $obj;

        # Check for improper arguments
        if (! defined $session || ! defined $cmd || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateCmdBuffer', @_);
        }

        if (! defined $self->cmdBufferFirst) {

            # This the first world command ever processed
            $self->ivPoke('cmdBufferFirst', 0);
        }

        # Create a new buffer object for this world command
        $obj = Games::Axmud::Buffer::Cmd->new(
            $session,
            'client',
            $self->cmdBufferCount,
            $cmd,
            $self->clientTime,
        );

        if (! $obj) {

            return undef;

        } else {

            # Update the world command buffer
            $self->ivAdd('cmdBufferHash', $obj->number, $obj);
            $self->ivIncrement('cmdBufferCount');
            $self->ivPoke('cmdBufferLast', ($self->cmdBufferCount - 1));

            # If the buffer is full, remove the oldest line
            if ($self->cmdBufferCount > $self->customCmdBufferSize) {

                $self->ivDelete('cmdBufferHash', $self->cmdBufferFirst);
                $self->ivIncrement('cmdBufferFirst');
            }

            return $obj;
        }
    }

    # Plugins

    sub loadPlugin {

        # Called by GA::Session->start, $self->loadPrivatePlugins, GA::Cmd::LoadPlugin->do and
        #   ->TestPlugin->do
        # Attemps to load a Perl module as a plugin. Checks the file exists, that it is a Perl file,
        #   that it has the right Axmud plugin header and that there are no compile errors, then
        #   loads the plugin
        #
        # Axmud plugin headers have a fixed format. If the header is not in this format, the plugin
        #   is not loaded
        # There can be any number of empty lines, or lines containing only comments, after the first
        #   line. Lines after the package line can appear in any order; duplicate lines replace the
        #   earlier one (so '#: Author: JRR Tolkien' replaces and earlier '#: Author: JK Rowling')
        # The format is case sensitive, except for the lines mentioned just below (so
        #   '#: author: jk rowling' will not be recognised)
        #
        # The header is in the format:
        #   #!/usr/bin/perl
        #   package NAME;
        #   #: Version: VERSION
        #   #: Description: ONE LINE DESCRIPTION
        #   #: Author: AUTHOR'S NAME                (optional)
        #   #: Copyright: COPYRIGHT MESSAGE         (optional)
        #   #: Require: AXMUD VERSION               (optional)
        #   #: Init: STRING                         (optional)
        #
        # NB NAME can't be the name of an existing plugin, or the client name (matching
        #   $axmud::SCRIPT, case-insensitive)
        # NB AXMUD VERSION can be in the form 'v1.0.0' / 'V1.0.0' / '1.0.0'. If it's not a valid
        #   version number, the plugin is not loaded
        # NB STRING is case-insensitive, and should be one of the strings 'enable', 'disable',
        #   'enabled' or 'disabled'. If it's not one of those strings, the default behaviour
        #   (equivalent to 'enable') is used
        #
        # Expected arguments
        #   $path       - The full file path to the Perl module
        #
        # Optional arguments
        #   $testFlag   - If set to TRUE, the plugin isn't loaded, just tested. Set to FALSE (or
        #                   'undef') otherwise
        #
        # Return values
        #   'undef' on improper arguments, if the plugin can't be loaded or if it has already been
        #       loaded
        #   Otherwise returns the name of the plugin loaded

        my ($self, $path, $testFlag, $check) = @_;

        # Local variables
        my (
            $string, $fileHandle, $line, $packageName, $exitFlag, $version, $descrip, $author,
            $copyright, $require, $init, $enabledFlag, $result, $obj, $null,
        );

        # Check for improper arguments
        if (! defined $path || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->loadPlugin', @_);
        }

        if (! $testFlag) {
            $string = 'load failure';
        } else {
            $string = 'test failure';
        }

        # Check the file exists
        if (! -e $path) {

            if ($self->debugExplainPluginFlag) {

                $self->writeDebug('Plugin \'' . $path . '\' ' . $string . ': file doesn\'t exist');
            }

            return undef;
        }

        # Check the file is a Perl file by reading the first line, which should contain a Perl
        #   shebang
        if (! open ($fileHandle, "<", $path)) {

            if ($self->debugExplainPluginFlag) {

                $self->writeDebug(
                    'Plugin \'' . $path . '\' ' . $string . ': could not open file',
                );
            }

            return undef;
        }

        # Check the first line contains a Perl shebang
        $line = <$fileHandle>;
        if (! $line =~ /^#!\s*(.*perl\S*)/) {

            if ($self->debugExplainPluginFlag) {

                $self->writeDebug(
                    'Plugin \'' . $path . '\' ' . $string . ':  line is not Perl shebang',
                );
            }

            close $fileHandle;

            return undef;
        }

        # Read the next non-empty line to get the package name
        $line = $self->readPluginLine($fileHandle);
        if (! $line || ! ($line =~ m/^package\s+(.+)\;/)) {

            if ($self->debugExplainPluginFlag) {

                $self->writeDebug(
                    'Plugin \'' . $path . '\' ' . $string . ': missing package name in plugin'
                    . ' header',
                );
            }

            close $fileHandle;

            return undef;

        } else {

            $packageName = $1;
        }

        # The remaining header lines can occur in any order
        do {

            # Read the next non-empty line to get the version
            $line = $self->readPluginLine($fileHandle);

            if (! $line) {

                # Header has finished
                $exitFlag = TRUE;

            } else {

                if ($line =~ m/^\#\:\s+Version\:\s+/) {

                    $line =~ s/^\#\:\s+Version\:\s+//;
                    $version = $self->trimWhitespace($line);

                } elsif ($line =~ m/^\#\:\s+Description\:\s+/) {

                    $line =~ s/^\#\:\s+Description\:\s+//;
                    $descrip = $self->trimWhitespace($line);

                } elsif ($line =~ m/^\#\:\s+Author\:\s+/) {

                    $line =~ s/^\#\:\s+Author\:\s+//;
                    $author = $self->trimWhitespace($line);

                } elsif ($line =~ m/^\#\:\s+Copyright\:\s+/) {

                    $line =~ s/^\#\:\s+Copyright\:\s+//;
                    $copyright = $self->trimWhitespace($line);

                } elsif ($line =~ m/^\#\:\s+Require\:\s+[vV]?/) {

                    $line =~ s/^\#\:\s+Require\:\s+[vV]?//;
                    $require = $self->trimWhitespace($line);

                } elsif ($line =~ m/^\#\:\s+Init\:\s+/) {

                    $line =~ s/^\#\:\s+Init\:\s+//;
                    $init = lc($self->trimWhitespace($line));

                } else {

                    # Header has finished
                    $exitFlag = TRUE;
                }
            }

        } until ($exitFlag);

        # (Don't need to read the file any further)
        close $fileHandle;

        # Check that the package name is allowed
        if (lc($packageName) eq $axmud::NAME_SHORT) {

            if ($self->debugExplainPluginFlag) {

                $self->writeDebug(
                    'Plugin \'' . $path . '\' ' . $string . ': package name \'' . $packageName
                    . '\' is not allowed',
                );
            }

            return undef;
        }

        # Check that the compulsory version and description were specified
        if (! defined $version) {

            if ($self->debugExplainPluginFlag) {

                $self->writeDebug(
                    'Plugin \'' . $path . '\' ' . $string . ': missing version in plugin header',
                );
            }

            return undef;

        } elsif (! defined $descrip) {

            if ($self->debugExplainPluginFlag) {

                $self->writeDebug(
                    'Plugin \'' . $path . '\' ' . $string . ': missing description in plugin'
                    . ' header',
                );
            }

            return undef;
        }

        # Check that the minimum Axmud version, if specified, is high enough
        if (
            defined $require
            && $self->convertVersion($require) > $self->convertVersion($axmud::VERSION)
        ) {
            if ($self->debugExplainPluginFlag) {

                $self->writeDebug(
                    'Plugin \'' . $path . '\' ' . $string . ': minimum version \'' . $require
                    . '\' is higher than current ' . $axmud::SCRIPT . ' version \''
                    . $axmud::VERSION . '\'',
                );
            }

            return undef;
        }

        # Check that the init status, if specified, is a recognised string (and ignore it, if not)
        if (
            defined $init && $init ne 'enable' && $init ne 'disable' && $init ne 'enabled'
            && $init ne 'disabled'
        ) {
            $init = undef;
        }

        # Set whether the plugin starts enabled (default) or disabled
        if (! defined $init || $init eq 'enable' || $init eq 'enabled') {
            $enabledFlag = TRUE;
        } else {
            $enabledFlag = FALSE;
        }

        # Check that the plugin hasn't already been loaded (but don't bother if we're just testing
        #   the file)
        if (! $testFlag && $self->ivExists('pluginHash', $packageName)) {

            # Plugin called $packageName already loaded
            if ($self->debugExplainPluginFlag) {

                $self->writeDebug(
                    'Plugin \'' . $path . '\' ' . $string . ': plugin called \'' . $packageName
                    . '\' has already been loaded',
                );
            }

            return undef;
        }

        # Check the file's syntax. System returns 0 on success, something else on failure
        if ($^O eq 'MSWin32') {
            $null = 'nul';
        } else {
            $null = '/dev/null';
        }

        $result = system("perl -c $path 2>$null >$null");
        if ($result ne '0') {

            if ($self->debugExplainPluginFlag) {

                $self->writeDebug(
                    'Plugin \'' . $path . '\' ' . $string . ': Perl syntax check failed',
                );
            }

            return undef;
        }

        # If $testFlag is set, we don't need to actually load the plugin
        if ($testFlag) {

            # Operation complete
            return $packageName;
        }

        # Create a plugin object to handle the file
        $obj =  Games::Axmud::Obj::Plugin->new(
            $packageName,
            $path,
            $version,
            $descrip,
            $enabledFlag,
            $author,        # May be 'undef'
            $copyright,     # May be 'undef'
            $require,       # May be 'undef'
            $init,          # May be 'undef'
        );

        if (! $obj) {

            # (Couldn't create object, error message already displayed)
            if ($self->debugExplainPluginFlag) {

                $self->writeDebug(
                    'Plugin \'' . $path . '\' ' . $string . ': couldn\'t create plugin object',
                );
            }

            return undef;
        }

        # Update IVs
        $self->ivAdd('pluginHash', $packageName, $obj);

        # Attempt to load the plugin
        eval { Module::Load::load($path); };
        if ($@) {

            if ($self->debugExplainPluginFlag) {

                $self->writeDebug(
                    'Plugin \'' . $path . '\' ' . $string . ': could not load plugin',
                );
            }

            $self->ivDelete('pluginHash', $packageName);

            return undef;
        }

        # Plugin loaded. If it should start disabled, disable it now
        if (! $enabledFlag) {

            $self->disablePlugin($packageName);
        }

        return $packageName;
    }

    sub loadPrivatePlugins {

        # Called by $self->start
        # Loads private plugins stored in the /private directory (which doesn't exist in public
        #   releases of Axmud)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (@pathList, @modList);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->loadPrivatePlugins', @_);
        }

        if ($^O eq 'MSWin32') {
            @pathList = glob($axmud::SHARE_DIR . '\\private\\*.pm');
        } else {
            @pathList = glob($axmud::SHARE_DIR . '/private/*.pm');
        }

        foreach my $path (@pathList) {

            # Private plugins begin with an alpha-numeric character and end .pm; all other .pm files
            #   in the directory must begin with an underline character
            # Remove all non-plugin files from the list
            if ($path =~ m/private[\\\/][[:alnum:]][[:word:]\s]*\.pm$/) {

                push (@modList, $path);
            }
        }

        # Load each plugin
        foreach my $path (@modList) {

            my $plugin = $self->loadPlugin($path);
            if (! $plugin) {

                $self->writeWarning(
                    'Error loading the private plugin \'' . $path . '\'',
                    $self->_objClass . '->loadPrivatePlugins',
                );
            }
        }

        return 1;
    }

    sub readPluginLine {

        # Called by $self->loadPlugin
        # Reads lines from an already opened plugin file, looking for the first line which isn't
        #   empty (or contains only a comment that's not part of the header)
        # Returns the first matching line found
        #
        # Expected arguments
        #   $fileHandle     - The plugin file's filehandle
        #
        # Return values
        #   'undef' on improper arguments or if end-of-file is reached before the line is found
        #   The first matching line found otherwise

        my ($self, $fileHandle, $check) = @_;

        # Check for improper arguments
        if (! defined $fileHandle || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->readPluginLine', @_);
        }

        while (<$fileHandle>) {

            my $line = $_;

            chomp $line;

            if (
                $line
                && ! (
                    $line =~ m/^\s+$/
                    || $line =~ m/\s*\#[^\:]/
                )
            ) {
                # This is the line we're looking for
                return $line;
            }
        }

        # No matching line found
        return undef;
    }

    sub enablePlugin {

        # Called by GA::Cmd::EnablePlugin->do
        # Enables a loaded plugin, after an earlier call to $self->disablePlugin disabled it
        #
        # Expected arguments
        #   $plugin     - The name of the plugin to enable
        #
        # Return values
        #   'undef' on improper arguments or if a plugin called $plugin has not been loaded
        #   1 otherwise

        my ($self, $plugin, $check) = @_;

        # Local variables
        my ($pluginObj, $listRef);

        # Check for improper arguments
        if (! defined $plugin || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->enablePlugin', @_);
        }

        # Find the plugin object
        $pluginObj = $self->ivShow('pluginHash', $plugin);
        if (! $pluginObj) {

            # Plugin not found
            return undef;
        }

        # Enable the plugin
        $pluginObj->set_enabledFlag(TRUE);

        # If any of this plugin's tasks defined text-to-speech attributes (TTS), update the
        #   our customisable attribute hashes, re-assigning existing attributes to these tasks, if
        #   necessary
        foreach my $taskName ($self->ivKeys('pluginTaskHash')) {

            if ($plugin eq $self->ivShow('pluginTaskHash', $taskName)) {

                $self->ttsAssignAttribs($taskName);
            }
        }

        # Restore the plugin's client commands. If there are any (built-in) client commands of the
        #   same name, move them somewhere else, in case this plugin is disabled again at some point
        #   in the future
        foreach my $pluginCmd ($self->ivKeys('pluginCmdHash')) {

            my ($otherPlugin, $pluginCmdObj, $originalCmdObj);

            $otherPlugin = $self->ivShow('pluginCmdHash', $pluginCmd);
            if ($otherPlugin eq $plugin) {

                if ($self->ivExists('clientCmdHash', $pluginCmd)) {

                    # Restore the plugin command, and move the original to a special IV, so that it
                    #   too can be restored if the plugin is re-disabled at some point
                    $pluginCmdObj = $self->ivShow('replaceClientCmdHash', $pluginCmd);
                    $originalCmdObj = $self->ivShow('clientCmdHash', $pluginCmd);
                    $self->ivAdd('replaceClientCmdHash', $pluginCmd, $originalCmdObj);
                    $self->ivAdd('clientCmdHash', $pluginCmd, $pluginCmdObj);

                } else {

                    # Just restore the plugin command
                    $pluginCmdObj = $self->ivShow('replaceClientCmdHash', $pluginCmd);
                    $self->ivAdd('clientCmdHash', $pluginCmd, $pluginCmdObj);
                    $self->ivDelete('replaceClientCmdHash', $pluginCmd);
                }
            }
        }

        # Also restore the plugin's client commands (along with any group headings) to
        #   $self->clientCmdPrettyList
        if ($self->ivExists('clientCmdReplacePrettyHash', $plugin)) {

            $listRef = $self->ivShow('clientCmdReplacePrettyHash', $plugin);
            if (defined $listRef && @$listRef) {

                $self->ivPush('clientCmdPrettyList', @$listRef);
            }
        }

        # Sensitise/desensitise menu bar/toolbar items, depending on current conditions
        $self->desktopObj->restrictWidgets();

        # Operation complete
        return 1;
    }

    sub disablePlugin {

        # Called by GA::Cmd::DisablePlugin->do
        # Disables a loaded plugin. Halts all of the plugin's tasks (new tasks from the plugin
        #   can't start). Closes any windows of the types added by the plugin. Disables any client
        #   commands added by the plugin
        #
        # Expected arguments
        #   $plugin     - The name of the plugin to disable
        #
        # Return values
        #   'undef' on improper arguments or if a plugin called $plugin has not been loaded
        #   1 otherwise

        my ($self, $plugin, $check) = @_;

        # Local variables
        my ($pluginObj, $listRef, $index, $matchFlag);

        # Check for improper arguments
        if (! defined $plugin || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->disablePlugin', @_);
        }

        # Find the plugin object
        $pluginObj = $self->ivShow('pluginHash', $plugin);
        if (! $pluginObj) {

            # Plugin not found
            return undef;
        }

        # Disable the plugin
        $pluginObj->set_enabledFlag(FALSE);

        # If any of this plugin's tasks are running, in any session, halt them
        foreach my $session ($self->listSessions()) {

            foreach my $taskObj ($session->ivValues('currentTaskHash')) {

                my $thisPlugin = $self->ivShow('pluginTaskHash', $taskObj->name);

                if (defined $thisPlugin && $thisPlugin eq $plugin) {

                    # Halt the task
                    $session->pseudoCmd('halttask ' . $taskObj->uniqueName);
                }
            }
        }

        # If any of our customisable text-to-speech (TTS) hashes have assigned an attribute to
        #   this plugin's tasks, re-assign the attributes to a built-in task, if possible, or
        #   otherwise remove the attributes completely
        foreach my $taskName ($self->ivKeys('pluginTaskHash')) {

            if ($plugin eq $self->ivShow('pluginTaskHash', $taskName)) {

                $self->ttsResetAttribs($taskName);
            }
        }

        # Close any 'free' windows added by the plugin
        foreach my $winObj
            (sort {$a->number <=> $b->number} ($self->desktopObj->ivValues('freeWinHash')))
        {
            my $thisPlugin = $self->ivShow('pluginFreeWinHash', $winObj->_objClass);
            if (defined $thisPlugin && $thisPlugin eq $plugin) {

                # Close the window
                $winObj->winDestroy();
            }
        }

        # Close any 'grid' windows added by the plugin
        foreach my $winObj
            (sort {$a->number <=> $b->number} ($self->desktopObj->ivValues('freeWinHash')))
        {
            my $thisPlugin = $self->ivShow('pluginGridWinHash', $winObj->_objClass);
            if (defined $thisPlugin && $thisPlugin eq $plugin) {

                # For 'main' windows, terminate any session using the window
                if ($winObj->winType eq 'main') {

                    foreach my $session
                        (sort {$a->number <=> $b->number} ($self->ivValues('sessionHash')))
                    {
                        if ($session->mainWin && $session->mainWin eq $winObj) {

                            $self->stopSession($session);
                        }
                    }
                }

                # Close the window
                $winObj->winDestroy();
            }
        }

        # If the plugin loaded any client commands that replaced an existing client command of the
        #   same name, restore the original. Otherwise, remove the command completely
        foreach my $pluginCmd ($self->ivKeys('pluginCmdHash')) {

            my ($otherPlugin, $pluginCmdObj, $originalCmdObj);

            $otherPlugin = $self->ivShow('pluginCmdHash', $pluginCmd);
            if ($otherPlugin eq $plugin) {

                if ($self->ivExists('replaceClientCmdHash', $pluginCmd)) {

                    # Restore the original, and move the plugin command to a special IV, so that it
                    #   too can be restored if the plugin is re-enabled at some point
                    $originalCmdObj = $self->ivShow('replaceClientCmdHash', $pluginCmd);
                    $pluginCmdObj = $self->ivShow('clientCmdHash', $pluginCmd);
                    $self->ivAdd('replaceClientCmdHash', $pluginCmd, $pluginCmdObj);
                    $self->ivAdd('clientCmdHash', $pluginCmd, $originalCmdObj);

                } else {

                    # Just move the plugin command to a special IV, so that it can be restored if
                    #   the plugin is re-enabled
                    $pluginCmdObj = $self->ivShow('clientCmdHash', $pluginCmd);
                    $self->ivAdd('replaceClientCmdHash', $pluginCmd, $pluginCmdObj);
                    $self->ivDelete('clientCmdHash', $pluginCmd);
                }
            }
        }

        # Any plugin client commands should also have been added to $self->clientCmdPrettyList.
        #   Attempt to remove them
        if ($self->ivExists('clientCmdReplacePrettyHash', $plugin)) {

            $listRef = $self->ivShow('clientCmdReplacePrettyHash', $plugin);
            if (defined $listRef && @$listRef) {

                # Search through $self->clientCmdPrettyList, looking for an exact match for the
                #   contents of the list in $listRef
                $index = -1;
                do {

                    my $failFlag;

                    $index++;

                    if ($self->ivIndex('clientCmdPrettyList', $index) eq $$listRef[0]) {

                        # Found the first item in $listRef; do the rest of the items match?
                        OUTER: for (my $count = $index; $count < scalar @$listRef; $count++) {

                            if (
                                $self->ivIndex('clientCmdPrettyList', $count) ne $$listRef[$count]
                            ) {
                                # Nope! Try again on the next iteration of the do loop
                                $failFlag = TRUE;
                                last OUTER;
                            }
                        }

                        if (! $failFlag) {

                            # Found a complete match
                            $matchFlag = TRUE;
                        }
                    }

                } until ($matchFlag || $index == ((scalar $self->clientCmdPrettyList) - 1));

                if ($matchFlag) {

                    # Remove the group headings and client commands from this plugin
                    $self->ivSplice('clientCmdPrettyList', $index, scalar @$listRef);
                }
            }
        }

        # Sensitise/desensitise menu bar/toolbar items, depending on current conditions
        $self->desktopObj->restrictWidgets();

        # Operation complete
        return 1;
    }

    sub addPluginCmds {

        # Called by any Axmud plugin
        # Adds client commands defined in the plugin
        #
        # Expected arguments
        #   $plugin   - The plugin's main package (declared in the file header)
        #
        # Optional arguments
        #   @list     - A list of client commands, grouped thematically (using the same format as
        #                   $self->clientCmdPrettyList uses). If the list is empty, no commands are
        #                   added
        #
        # Return values
        #   'undef' on improper arguments or if a client command object can't be created
        #   Otherwise returns the number of client command objects created (may be 0)

        my ($self, $plugin, @list) = @_;

        # Local variables
        my (
            $pluginObj, $count,
            @clientCmdList, @clientCmdPrettyList,
            %clientCmdHash, %replaceClientCmdHash, %userCmdHash, %pluginCmdHash,
        );

        # Check for improper arguments
        if (! defined $plugin) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->addPluginCmds', @_);
        }

        # Find the plugin object
        $pluginObj = $self->ivShow('pluginHash', $plugin);
        if (! $pluginObj) {

            # Plugin not found - a very unlikely occurrence for this function, but it's worth
            #   checking anyway
            return undef;
        }

        # If no commands specified, nothing to add
        if (! @list) {

            return 0;
        }

        # Import GA::Client IVs; they are only updated if all commands are sucessfully added
        %clientCmdHash = $self->clientCmdHash;
        %replaceClientCmdHash = $self->replaceClientCmdHash;
        @clientCmdList = $self->clientCmdList;
        %userCmdHash = $self->userCmdHash;
        @clientCmdPrettyList = $self->clientCmdPrettyList;
        %pluginCmdHash = $self->pluginCmdHash;

        # (Code adapted from $self->setupCmds)
        $count = 0;
        foreach my $string (@list) {

            my ($replaceFlag, $package, $obj);

            # @list contains a list of commands, grouped under headings. The headings begin with a
            #   '@' character
            if (substr ($string, 0, 1) ne '@') {

                # Not a heading. If there's an existing command of the same name, remove it
                if (exists $clientCmdHash{lc($string)}) {

                    # Remove the existing client command, but don't change any user commands; they
                    #   stay the same when the plugin command is loaded
                    $replaceFlag = TRUE;
                    $replaceClientCmdHash{lc($string)} = $clientCmdHash{lc($string)};
                    delete $clientCmdHash{lc($string)};
                }

                # Create a Perl object
                $package = 'Games::Axmud::Cmd::Plugin::' . $string;
                $obj = $package->new();
                if (! $obj) {

                    return $self->writeError(
                        'Could not create client command \'' . $self->cmdSep . lc($string) . '\'',
                        $self->_objClass . '->addPluginCmds',
                    );
                }

                # Set up user commands corresponding to this client command (but not if it's
                #   replacing an existing command of the same name)
                if (! $replaceFlag) {

                    foreach my $userCmd ($obj->defaultUserCmdList) {

                        # Check the user command isn't already in use by another client command
                        if (exists $userCmdHash{lc($userCmd)}) {

                            # (Allow writing to something other than GA::Session - there are no
                            #   sessions yet)
                            return $self->writeError(
                                'Duplicate user command \'' . $userCmd . '\' pointing at client'
                                . ' command \'' . lc($string) . '\'',
                                $self->_objClass . '->setupCmds',
                            );

                        } else {

                            # Add the user command to the GA::Client's hash
                            $userCmdHash{lc($userCmd)} = lc($string);
                        }
                    }
                }

                # Update IVs
                $count++;

                $clientCmdHash{lc($string)} = $obj;
                push (@clientCmdList, lc($string));
                $pluginCmdHash{lc($string)} = $plugin;
            }

            # Both headings and command names are added to ->clientCmdPrettyList
            push (@clientCmdPrettyList, $string);
        }

        # No errors, so we can now update the GA::Client IVs (if any command objects were actually
        #   added)
        if ($count) {

            $self->ivPoke('clientCmdHash', %clientCmdHash);
            $self->ivPoke('replaceClientCmdHash', %replaceClientCmdHash);
            $self->ivPoke('clientCmdList', @clientCmdList);
            $self->ivPoke('userCmdHash', %userCmdHash);
            $self->ivPoke('clientCmdPrettyList', @clientCmdPrettyList);
            $self->ivPoke('pluginCmdHash', %pluginCmdHash);

            $self->ivAdd('clientCmdReplacePrettyHash', $plugin, \@list);
        }

        # Operation complete
        return $count;
    }

    sub addPluginTasks {

        # Called by any Axmud plugin
        # Adds tasks defined in the plugin
        #
        # Expected arguments
        #   $plugin     - The plugin's main package (declared in the file header)
        #
        # Optional arguments
        #   @list       - A list containing groups of 3 elements, in the form
        #                   (task_package, task_formal_name, reference_to_task_label_list)
        #               - ...where 'task_package' is the package name of the Perl object for the
        #                       task (e.g. 'Games::Axmud::Task::MyCoolTask'), 'task_package_name' is
        #                       the task's formal name, stored in ->task (e.g. 'my_cool_task'), and
        #                       'reference_to_task_label_list' is a list of task labels (e.g.
        #                       'mct', 'mycool', 'mycooltask'. If the list is empty, no tasks are
        #                       added
        #
        # Return values
        #   'undef' on improper arguments or if a task can't be added
        #   Otherwise returns the number of tasks added (may be 0)

        my ($self, $plugin, @list) = @_;

        # Local variables
        my (
            $pluginObj, $count,
            @newTaskList,
            %taskPackageHash, %taskLabelHash, %pluginTaskHash,
        );

        # Check for improper arguments
        if (! defined $plugin) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->addPluginTasks', @_);
        }

        # Find the plugin object
        $pluginObj = $self->ivShow('pluginHash', $plugin);
        if (! $pluginObj) {

            # Plugin not found - a very unlikely occurrence for this function, but it's worth
            #   checking anyway
            return undef;
        }

        # Import GA::Client IVs; they are only updated if all tasks are sucessfully added
        %taskPackageHash = $self->taskPackageHash;
        %taskLabelHash = $self->taskLabelHash;
        %pluginTaskHash = $self->pluginTaskHash;

        # (Code adapted from $self->setupCmds)
        $count = 0;
        if (@list) {

            do {

                my ($packageName, $taskName, $listRef);

                $packageName = shift @list;
                $taskName = shift @list;
                $listRef = shift @list;

                if (! $packageName) {

                    return $self->writeError(
                        'Could not add task (no package name specified)',
                        $self->_objClass . '->addPluginTasks',
                    );

                } elsif (! $taskName || ! defined $listRef) {

                    return $self->writeError(
                        'Could not add task (invalid formal name or undefined label list)',
                        $self->_objClass . '->addPluginTasks',
                    );
                }

                # (Code adapted from GA::Cmd::AddTaskPackage->do)

                # Check that no tasks of this type are running in any session
                foreach my $session ($self->listSessions()) {

                    if ($session->ivExists('currentTaskNameHash', $taskName)) {

                        return $self->writeError(
                            'Can\'t change the package name for the task \'' . $taskName
                            . '\' because the task is running in at least one session (try halting'
                            . ' the task first)',
                            $self->_objClass . '->addPluginTasks',
                        );
                    }
                }

                # Check that $taskName is not too long
                if (length $taskName > 16) {

                    return $self->writeError(
                        'Task name \'' . $taskName . '\' is too long (max 16 characters)',
                        $self->_objClass . '->addPluginTasks',
                    );
                }

                # (Code adapted from GA::Cmd::AddTaskLabel->do)

                # Check that all the labels in $listRef don't already exist, and that the labels are
                #   allowed
                foreach my $label (@$listRef) {

                    if (exists $taskLabelHash{$label} && $taskLabelHash{$label} ne $taskName) {

                        return $self->writeError(
                            'The label \'' . $label . '\' already exists (and points to the \''
                            . $taskLabelHash{$label} . '\' task)',
                            $self->_objClass . '->addPluginTasks',
                        );
                    }

                    if (! $self->nameCheck($label, 32)) {

                        return $self->writeError(
                            'Illegal task label name \'' . $label . '\'',
                            $self->_objClass . '->addPluginTasks',
                        );
                    }
                }

                # Add the task package name and labels (overwrite identical entries, if they
                #   already exist)
                $count++;
                $taskPackageHash{$taskName} = $packageName;
                foreach my $label (@$listRef) {

                    $taskLabelHash{$label} = $taskName;
                }

                # Mark the task as having been added by the plugin
                $pluginTaskHash{$taskName} = $plugin;

                # Preserve the new taskname temporarily
                push (@newTaskList, $taskName);

            } until (! @list);
        }

        # No errors, so we can now update the GA::Client IVs (if any tasks were actually added)
        if ($count) {

            $self->ivPoke('taskPackageHash', %taskPackageHash);
            $self->ivPoke('taskLabelHash', %taskLabelHash);
            $self->ivPoke('pluginTaskHash', %pluginTaskHash);
        }

        # We can also update our customisable text-to-speech (TTS) hashes, so that if the same
        #   TTS attributes are used by multiple tasks, this plugin's tasks take priority
        foreach my $taskName (@newTaskList) {

            $self->ttsAssignAttribs($taskName);
        }

        # Operation complete
        return $count;
    }

    sub addPluginGridWins {

        # Called by any Axmud plugin
        # Adds 'grid' windows defined in the plugin
        #
        # Expected arguments
        #   $plugin     - The plugin's main package (declared in the file header)
        #
        # Optional arguments
        #   @list       - A list of 'grid' window package names (in groups of 1 element). If the
        #                   list is empty, no 'grid' windows are added. Duplicates are not added
        #
        # Return values
        #   'undef' on improper arguments or if a 'grid' window package can't be added
        #   Otherwise returns the number of 'grid' window packages added (may be 0)

        my ($self, $plugin, @list) = @_;

        # Local variables
        my ($pluginObj, $count);

        # Check for improper arguments
        if (! defined $plugin) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->addPluginGridWins', @_);
        }

        # Find the plugin object
        $pluginObj = $self->ivShow('pluginHash', $plugin);
        if (! $pluginObj) {

            # Plugin not found - a very unlikely occurrence for this function, but it's worth
            #   checking anyway
            return undef;
        }

        # Don't add duplicates
        $count = 0;
        foreach my $package (@list) {

            if (! $self->ivExists('pluginGridWinHash', $package)) {

                $self->ivAdd('pluginGridWinHash', $package, $plugin);
                $count++;
            }
        }

        # Operation complete
        return $count;
    }

    sub addPluginFreeWins {

        # Called by any Axmud plugin
        # Adds 'free' windows defined in the plugin
        #
        # Expected arguments
        #   $plugin     - The plugin's main package (declared in the file header)
        #
        # Optional arguments
        #   @list       - A list of 'free' window package names (in groups of 1 element); should
        #                   not include any 'dialogue' windows. If the list is empty, no 'free'
        #                   windows are added. Duplicates are not added
        #
        # Return values
        #   'undef' on improper arguments or if a 'free' window package can't be added
        #   Otherwise returns the number of 'free' window packages added (may be 0)

        my ($self, $plugin, @list) = @_;

        # Local variables
        my ($pluginObj, $count);

        # Find the plugin object
        $pluginObj = $self->ivShow('pluginHash', $plugin);
        if (! $pluginObj) {

            # Plugin not found - a very unlikely occurrence for this function, but it's worth
            #   checking anyway
            return undef;
        }

        # Check for improper arguments
        if (! defined $plugin) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->addPluginFreeWins', @_);
        }

        # Don't add duplicates
        $count = 0;
        foreach my $package (@list) {

            if (! $self->ivExists('pluginFreeWinHash', $package)) {

                $self->ivAdd('pluginFreeWinHash', $package, $plugin);
                $count++;
            }
        }

        # Operation complete
        return $count;
    }

    sub addPluginStripObjs {

        # Called by any Axmud plugin
        # Adds strip objects defined in the plugin. Note that if an existing strip object with the
        #   same package name already exists in $self->customStripHash, it is not replaced, and this
        #   plugin's strip object does not become available for use
        #
        # Expected arguments
        #   $plugin         - The plugin's main package (declared in the file header)
        #   $stripPackage   - The package name for the strip object, e.g.
        #                       'Games::Axmud::Strip::MyObj'
        #   $descrip        - A short description, e.g. 'Test strip object'
        #
        # Return values
        #   'undef' on improper arguments or if the plugin's strip object can't be added
        #   1 on success

        my ($self, $plugin, $stripPackage, $descrip, $check) = @_;

        # Local variables
        my $pluginObj;

        # Check for improper arguments
        if (! defined $plugin || ! defined $stripPackage || ! defined $descrip || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->addPluginStripObjs', @_);
        }

        # Find the plugin object
        $pluginObj = $self->ivShow('pluginHash', $plugin);
        if (! $pluginObj) {

            # Plugin not found - a very unlikely occurrence for this function, but it's worth
            #   checking anyway
            return undef;
        }

        # Check that a strip object with the same package name doesn't already exist
        if ($self->ivShow('customStripHash', $stripPackage)) {

            return undef;
        }

        # Update IVs
        $self->ivAdd('customStripHash', $stripPackage, $descrip);
        $self->ivAdd('pluginStripObjHash', $stripPackage, $plugin);

        # Operation complete
        return 1;
    }

    sub addPluginTableObjs {

        # Called by any Axmud plugin
        # Adds table objects defined in the plugin. Note that if an existing table object with the
        #   same package name already exists in $self->customTableHash, it is not replaced, and this
        #   plugin's table object does not become available for use
        #
        # Expected arguments
        #   $plugin         - The plugin's main package (declared in the file header)
        #   $tablePackage   - The package name for the table object, e.g.
        #                       'Games::Axmud::Table::MyObj'
        #   $descrip        - A short description, e.g. 'Test table object'
        #
        # Return values
        #   'undef' on improper arguments or if the plugin's table object can't be added
        #   1 on success

        my ($self, $plugin, $tablePackage, $descrip, $check) = @_;

        # Local variables
        my $pluginObj;

        # Check for improper arguments
        if (! defined $plugin || ! defined $tablePackage || ! defined $descrip || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->addPluginTableObjs', @_);
        }

        # Find the plugin object
        $pluginObj = $self->ivShow('pluginHash', $plugin);
        if (! $pluginObj) {

            # Plugin not found - a very unlikely occurrence for this function, but it's worth
            #   checking anyway
            return undef;
        }

        # Check that a table object with the same package name doesn't already exist
        if ($self->ivShow('customTableHash', $tablePackage)) {

            return undef;
        }

        # Update IVs
        $self->ivAdd('customTableHash', $tablePackage, $descrip);
        $self->ivAdd('pluginTableObjHash', $tablePackage, $plugin);

        # Operation complete
        return 1;
    }

    sub addPluginCages {

        # Called by any Axmud plugin
        # Adds cages defined in the plugin
        #
        # Expected arguments
        #   $plugin     - The plugin's main package (declared in the file header)
        #
        # Optional arguments
        #   @list       - A list containing groups of 3 elements, in the form
        #                   (cage_package, cage_type, edit_win_package)
        #               - ...where 'cage_package' is the package name of the Perl object for the
        #                   cage (e.g. 'Games::Axmud::Cage::MyCage'), 'cage_type' is the cage's
        #                   type, e.g. 'mycage' (max 8 characters) and 'edit_win_package' is the
        #                   package name of the cage's 'edit' window (or 'undef', if the cage
        #                   doesn't have an 'edit' window). If the list is empty, no cages are added
        #               - NB Cage 'edit' windows must also be added to this client via a call to
        #                   $self->addPluginFreeWins
        #
        # Return values
        #   'undef' on improper arguments or if a task can't be added
        #   Otherwise returns the number of cages added (may be 0)

        my ($self, $plugin, @list) = @_;

        # Local variables
        my (
            $pluginObj, $count,
            @cageTypeList,
            %pluginCageHash, %pluginCagePackageHash, %pluginCageEditWinHash,
        );

        # Check for improper arguments
        if (! defined $plugin) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->addPluginCages', @_);
        }

        # Find the plugin object
        $pluginObj = $self->ivShow('pluginHash', $plugin);
        if (! $pluginObj) {

            # Plugin not found - a very unlikely occurrence for this function, but it's worth
            #   checking anyway
            return undef;
        }

        # Import GA::Client IVs; they are only updated if all cages are sucessfully added
        @cageTypeList = $self->cageTypeList;
        %pluginCageHash = $self->pluginCageHash;
        %pluginCagePackageHash = $self->pluginCagePackageHash;
        %pluginCageEditWinHash = $self->pluginCageEditWinHash;

        # (Code adapted from $self->setupCmds)
        $count = 0;
        if (@list) {

            do {

                my ($packageName, $cageType, $editWinPackage);

                $packageName = shift @list;
                $cageType = shift @list;
                $editWinPackage = shift @list;      # Can be 'undef'

                if (! $packageName) {

                    return $self->writeError(
                        'Could not add cage (no package name specified)',
                        $self->_objClass . '->addPluginCages',
                    );

                } elsif (! $cageType) {

                    return $self->writeError(
                        'Could not add cage (no cage type specified)',
                        $self->_objClass . '->addPluginCages',
                    );
                }

                # Check that $cageType is not too long
                if (length $cageType > 8) {

                    return $self->writeError(
                        'Cage type \'' . $cageType . '\' is too long (max 8 characters)',
                        $self->_objClass . '->addPluginCages',
                    );
                }

                # Check that the cage type doesn't already exist
                foreach my $item (@cageTypeList) {

                    if ($item eq $cageType) {

                        return $self->writeError(
                            'The cage type \'' . $cageType . '\' already exists',
                            $self->_objClass . '->addPluginCages',
                        );
                    }
                }

                # Add the cage
                $count++;
                push (@cageTypeList, $cageType);
                $pluginCageHash{$cageType} = $plugin;
                $pluginCagePackageHash{$cageType} = $packageName;
                $pluginCageEditWinHash{$cageType} = $editWinPackage;

            } until (! @list);
        }

        # No errors, so we can now update the GA::Client IVs (if any cages were actually added)
        if ($count) {

            $self->ivPoke('cageTypeList', @cageTypeList);
            $self->ivPoke('pluginCageHash', %pluginCageHash);
            $self->ivPoke('pluginCagePackageHash', %pluginCagePackageHash);
            $self->ivPoke('pluginCageEditWinHash', %pluginCageEditWinHash);

            # Update existing profiles
            foreach my $session ($self->listSessions()) {

                # The TRUE argument means 'don't display a message for each cage created/destroyed'
                $session->updateCages(TRUE);
            }
        }

        # Operation complete
        return $count;
    }

    sub addPluginMenus {

        # Called by any Axmud plugin
        # Adds menu items defined in the plugin to any menu strip object (GA::Strip::MenuBar)
        #   displayed in any 'internal' window while the client is running (and the plugin is
        #   enabled)
        #
        # Expected arguments
        #   $plugin     - The plugin's main package (declared in the file header)
        #
        # Optional arguments
        #   $funcRef    - Reference to a function which contain the code to add menu items to a
        #                   Gtk3::Menu widget, pre-existing or created by this function. The
        #                   referenced function must accept the strip object and Gtk3::Menu as
        #                   arguments, and return 'undef' on failure or 1 on success
        #
        # Return values
        #   'undef' on improper arguments or if the menu items can't be added
        #   1 otherwise

        my ($self, $plugin, $funcRef, $check) = @_;

        # Local variables
        my ($pluginObj, $subMenu);

        # Check for improper arguments
        if (! defined $plugin || ! defined $funcRef || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->addPluginWidgets', @_);
        }

        # Find the plugin object
        $pluginObj = $self->ivShow('pluginHash', $plugin);
        if (! $pluginObj) {

            # Plugin not found - a very unlikely occurrence for this function, but it's worth
            #   checking anyway
            return undef;
        }

        # Each plugin can only call this function once
        if ($self->ivExists('pluginMenuFuncHash', $plugin)) {

            return undef;

        } else {

            $self->ivAdd('pluginMenuFuncHash', $plugin, $funcRef);
        }

        # Any 'internal' windows which already exist and which have a menu strip object should add a
        #   sub-menu for this plugin now; any new 'internal' windows created from now will
        #   automatically call the referenced function to add their own sub-menus
        foreach my $winObj ($self->desktopObj->ivValues('gridWinHash')) {

            my ($stripObj, $subMenu);

            if (
                $winObj->winType eq 'main'
                || $winObj->winType eq 'protocol'
                || $winObj->winType eq 'custom'
            ) {
                $stripObj = $winObj->ivShow('firstStripHash', 'Games::Axmud::Strip::MenuBar');
                if ($stripObj) {

                    $subMenu = $stripObj->addPluginWidgets($plugin);
                    if (! $subMenu) {

                        return undef;
                    }

                    # Call the referenced function to add menu items to this sub-menu
                    if (! &$funcRef($stripObj, $subMenu)) {

                        return undef;
                    }

                    # Update the window to show the new menu items
                    $winObj->winShowAll($self->_objClass . '->addPluginMenus');
                }
            }
        }

        return 1;
    }

    sub addPluginMxpFilters {

        # Called by any Axmud plugin
        # Adds the plugin function that's used to apply MXP file filters
        #
        # Expected arguments
        #   $plugin     - The plugin's main package (declared in the file header)
        #   $funcRef    - Reference to the function that does the conversion
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $plugin, $funcRef, $check) = @_;

        # Local variables
        my $pluginObj;

        # Check for improper arguments
        if (! defined $plugin || ! defined $funcRef || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->addPluginMxpFilters', @_);
        }

        # Find the plugin object
        $pluginObj = $self->ivShow('pluginHash', $plugin);
        if (! $pluginObj) {

            # Plugin not found - a very unlikely occurrence for this function, but it's worth
            #   checking anyway
            return undef;
        }

        # Update IVs
        $self->ivAdd('pluginMxpFilterHash', $plugin, $funcRef);

        # Operation complete
        return 1;
    }

    sub addPluginMcpPackages {

        # Called by any Axmud plugin
        # Adds the MCP package object (inheriting from GA::Generic::Mcp) defined by the plugin
        #
        # Expected arguments
        #   $plugin         - The plugin's main package (declared in the file header)
        #   $name           - The name of the MCP package, e.g. 'mcp-negotiate-can'. Must conform to
        #                       MCP's package name rules (see the MCP spec for more information);
        #                       this function won't allow you to add 'official' MCP packages whose
        #                       name starts 'mcp-'
        #   $perlPackage    - The Perl package for the object, e.g. Games::Axmud::Mcp::MyPackage
        #   $minVersion     - The minimum package version supported (e.g. '1.0', '2.0' etc). Should
        #                       ideally be a string (i.e. '1.0' not 1). If not a valid number (any
        #                       decimal number greater than 0), 1.0 is used
        #   $maxVersion     - The maximum package version supported (e.g. '1.0', '2.0' etc). Should
        #                       ideally be a string (i.e. '1.0' not 1). If not a valid number (any
        #                       decimal number greater than 0), 1.0 is used
        #
        # Optional arguments
        #   @supplantList   - An optional list of MCP package names for which Axmud should prefer to
        #                       use this MCP package, if the world supports both. Standard MCP
        #                       packages like 'mcp-negotiate' cannot be supplanted (specifically,
        #                       any package whose name begins 'mcp-' cannot be supplanted; the name
        #                       is ignored if present in this list)
        #
        # Return values
        #   'undef' on improper arguments or if the MCP package object can't be added
        #   1 otherwise

        my ($self, $plugin, $name, $perlPackage, $minVersion, $maxVersion, @supplantList) = @_;

        # Local variables
        my ($pluginObj, $mcpObj);

        # Check for improper arguments
        if (
            ! defined $plugin || ! defined $name || ! defined $perlPackage || ! defined $minVersion
            || ! defined $maxVersion
        ) {
             return $axmud::CLIENT->writeImproper($self->_objClass . '->addPluginMcpPackages', @_);
        }

        # Find the plugin object
        $pluginObj = $self->ivShow('pluginHash', $plugin);
        if (! $pluginObj) {

            # Plugin not found - a very unlikely occurrence for this function, but it's worth
            #   checking anyway
            return undef;
        }

        # Check that an MCP package object with the same name doesn't already exist
        if ($self->ivExists('mcpPackageHash', $name)) {

            return $self->writeError(
                'Could not create MCP package \'' . $name . '\' - duplicate package name',
                $self->_objClass . '->addPluginMcpPackages',
            );
        }

        # Don't add 'official' MCP packages (those whose names start 'mcp-')
        if (substr($name, 0, 4) eq 'mcp-') {

            return $self->writeError(
                'Cannot create \'official\' MCP package \'' . $name . '\'',
                $self->_objClass . '->addPluginMcpPackages',
            );
        }

        # Create the MCP package object
        $mcpObj = $perlPackage->new($name, $minVersion, $maxVersion, $plugin, @supplantList);
        if (! $mcpObj) {

            return $self->writeError(
                'Could not create MCP package \'' . $name . '\' - internal error',
                $self->_objClass . '->createSupportedMcpPackages',
            );
        }

        # Update IVs
        $self->ivAdd('mcpPackageHash', $name, $mcpObj);

        # Operation complete
        return 1;
    }

    # Logging

    sub deleteStandardLogs {

        # Called by $self->start, if the ->deleteStandardLogsFlag is set
        # Makes sure the /logs and /logs/standard directories are empty (but doesn't interfere with
        #   each world's own log directory)
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteStandardLogs', @_);
        }

        foreach my $path ($self->ivValues('logPrefHash')) {

            if (-e $axmud::DATA_DIR . $path) {

                unlink ($axmud::DATA_DIR . $path);
            }
        }

        return 1;
    }

    sub deleteWorldLogDir {

        # Called by GA::Session->setupProfiles, if the ->deleteWorldLogsFlag is set
        # Deletes the logfile directory for the specified world
        #
        # Expected arguments
        #   $world    - The name of a world profile
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $world, $check) = @_;

        # Check for improper arguments
        if (! defined $world || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteWorldLogDir', @_);
        }

        # Delete the dictory...
        File::Path::remove_tree($axmud::DATA_DIR . '/logs/' . $world);

        return 1;
    }

    sub createWorldLogDir {

        # Called by GA::Session->setupProfiles
        # Creates the logfile directory for the specified world
        #
        # Expected arguments
        #   $world    - The name of a world profile
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $world, $check) = @_;

        # Local variables
        my $dir;

        # Check for improper arguments
        if (! defined $world || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createWorldLogDir', @_);
        }

        # Create the dictory (unless it already exists)
        $dir = $axmud::DATA_DIR . '/logs/' . $world;
        if (! -e $dir) {

            mkdir ($dir, 0755);
        }

        return 1;
    }

    sub writeLog {

        # Can be called by any function, but mostly called by:
        #   GA::Obj::TextView->showSystemText, ->showError, ->showWarning, ->showDebug,
        #   ->showImproper, GA::Session->writeIncomingDataLogs, ->dispatchCmd, ->dispatchPassword
        #
        # Writes some text to one or more logfiles (if allowed)
        #
        # Expected arguments
        #   $session        - The GA::Session that generated the message
        #   $standardflag   - Set to TRUE for standard logfiles, so that the session number is
        #                       written to the logfile (so we can tell which session generated the
        #                       text); FALSE otherwise
        #   $text           - The text to be written
        #   $beforeFlag     - TRUE if $text should be preceded by a newline character, FALSE if not
        #   $afterFlag      - TRUE if $text should be followed by a newline character, FALSE if not
        #
        # Optional arguments
        #   @fileTypeList   - A list of logfile types to which $text must be written. For standard
        #                       logfiles, the types are keys in GA::Client->logPrefHash; otherwise,
        #                       keys in GA::Session->currentWorld->logPrefHash. If an empty list,
        #                       $text is not written to any logfile. If any of the log file types
        #                       are unrecognised, they are simply ignored (no error message is
        #                       generated)
        #
        # Return values
        #   'undef' on improper arguments or if logging is disabled for all sessions
        #   1 otherwise

        my ($self, $session, $standardflag, $text, $beforeFlag, $afterFlag, @fileTypeList) = @_;

        # Local variables
        my ($prefix, $preamble);

        # Check for improper arguments
        if (
            ! defined $session || ! defined $standardflag || ! defined $text
            || ! defined $beforeFlag || ! defined $afterFlag
        ) {
            # Can't call $self->showImproper, or we'll get an infinite loop, so write something to
            #   the terminal
            print "IMPROPER ARGUMENTSS: " . $self->_objClass . "->writeLog() " . join (" ", @_)
                        . "\n";
            return undef;
        }

        # If logging is disabled for all sessions, don't write anything
        if (! $self->allowLogsFlag) {

            return undef;
        }

        # Prefix the date and/or time to the line to be written, if allowed
        if ($self->logPrefixDateFlag) {

            $prefix = $self->localDateString();
        }

        if ($self->logPrefixTimeFlag) {

            if ($prefix) {
                $prefix .= ' ' . $self->localClock();
            } else {
                $prefix = $self->localClock();
            }
        }

        # For standard logfiles, add the session number
        if ($standardflag) {

            if ($prefix) {
                $prefix .= ' [' . $session->number . ']';
            } else {
                $prefix = '[' . $session->number . ']';
            }
        }

        # Create the logfile preamble as a single string, if one is set
        if (! $self->logPreambleList) {
            $preamble = '';
        } else {
            $preamble = join("\n", $self->logPreambleList) . "\n";
        }

        OUTER: foreach my $type (@fileTypeList) {

            my ($path, $fileHandle, $newFileFlag, $thisText, $lastChar);

            # Check that the log $fileType is recognised, and that logging is turned on for it
            # If so, set the file's path
            if ($standardflag) {

                # Standard logfiles
                if (
                    ! $self->ivExists('logPrefHash', $type)
                    || ! $self->ivShow('logPrefHash', $type)
                ) {
                    next OUTER;

                } else {

                    $path = $axmud::DATA_DIR . $self->ivShow('constLogPathHash', $type)
                }

            } else {

                # World-specific logfiles
                if (
                    ! $session->currentWorld->ivExists('logPrefHash', $type)
                    || ! $session->currentWorld->ivShow('logPrefHash', $type)
                ) {
                    next OUTER;

                } else {

                    $path = $axmud::DATA_DIR . '/logs/'
                        . $session->currentWorld->name . '/' . $type;
                }
            }

            # If the file name must be unique for every session, or for every distinct date, modify
            #   its path
            if ($self->logClientFlag) {
                $path .= '_' . $self->startDateString . '_' . $self->startClockString;
            } elsif ($self->logDayFlag) {
                $path .= '_' . $self->startDateString;
            }

            # Logfiles end with .txt on MS Windows
            if ($^O eq 'MSWin32') {

                $path .= '.txt';
            }

            # Check whether the file already exists
            if (! -e $path) {

                $newFileFlag = TRUE;

                # Add the prefix (if one was set)
                if ($prefix) {

                    $thisText = $prefix . ' ' . $text;
                }

                # For new logfiles, ignore $beforeFlag, but apply $afterFlag
                if ($afterFlag) {

                    $thisText .= "\n";
                }

            } else {

                if (! $beforeFlag) {

                    # Test whether the file ends with a newline character, or not
                    if (! open ($fileHandle, "<$path")) {

                        # Could not open file
                        next OUTER;
                    }

                    # Read the last character
                    seek $fileHandle, -1, 2;        # SEEK_END
                    $lastChar = getc($fileHandle);
                    close $fileHandle;
                }

                # Apply $beforeFlag and $afterFlag, and if we're writing on a new line, add $prefix
                #   at the right position
                if ($beforeFlag) {
                    $thisText = "\n";
                } else {
                    $thisText = "";
                }

                if ($beforeFlag || $lastChar eq "\n") {

                    $thisText .= $prefix;
                }

                if ($thisText) {
                    $thisText .= ' ' . $text;
                } else {
                    $thisText = $text;
                }

                if ($afterFlag) {

                    $thisText .= "\n";
                }
            }

            # Open the file for writing, appending $text to anything already there
            if (! open ($fileHandle, ">>$path")) {

                # Could not open file
                next OUTER;
            }

            # This line prevents any nasty 'Wide character in print' errors when (for example)
            #   receiving UTF8 characters from the world
            binmode $fileHandle, ':utf8';

            # If the file didn't already exist, write a header
            if ($newFileFlag) {

                print
                    $fileHandle
                    $axmud::SCRIPT . ' v' . $axmud::VERSION . ' logfile \'' . $type
                    . '\' started at ' . $self->localTime() . "\n$preamble";
            }

            # Write the line and close the file
            print $fileHandle $thisText;
            close $fileHandle;
        }

        # Logging complete
        return 1;
    }

    # Colour/style tags

    sub checkColourTags {

        # Can be called by anything
        # Checks whether a specified colour tag is standard colour tag, an xterm colour tag or an
        #   RGB colour tag
        #
        # Expected arguments
        #   $tag        - The colour tag to check. Standard colour tags are case-sensitive (i.e.
        #                   'red' and 'RED' are different colours), but xterm and RGB colour tags
        #                   are case-insensitive (i.e. '#ffffff' and '#FFFFFF' are the same colour)
        #
        # Optional arguments
        #   $mode       - Specifies which tags to check
        #                   'all' (or 'undef') - check standard, xterm and RGB colour tags
        #                   'standard' - check only standard colour tags
        #                   'xterm' - check only xterm colour tags
        #                   'rgb' - check only RGB colour tags
        #
        # Return values
        #   An empty list on improper arguments it it's not a recognised colour tag, or if $mode is
        #       set to 'standard', 'xterm' or 'rgb' and $tag isn't one of those colour tags, or if
        #       $mode is an unrecognised value
        #   Otherwise returns a list identifying $tag, in the form
        #       (tag_type, underlay_flag)
        #   ...where 'tag_type' is one of the strings 'standard', 'xterm' or 'rgb', and
        #       'underlay_flag' is TRUE if it's an underlay tag, FALSE if not

        my ($self, $tag, $mode, $check) = @_;

        # Local variables
        my (
            $underlayFlag,
            @emptyList,
        );

        # Check for improper arguments
        if (! defined $tag || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->checkColourTags', @_);
            return @emptyList;
        }

        if (! defined $mode) {

            $mode = 'all';
        }

        # Standard colour tags
        if ($mode eq 'all' || $mode eq 'standard') {

            # GA::Client->colourTagHash and ->boldColourTagHash both contain 'red', 'BLUE' etc, but
            #   they don't contain the corresponding underlay tags 'ul_red', 'UL_BLUE', etc
            # Since 'red' is the same colour as 'ul_red', we can simply remove the 'ul_' or 'UL_'
            #   portions
            if (substr($tag, 0, 3) eq 'ul_') {

                substr($tag, 0, 3) = '';
                if ($self->ivExists('colourTagHash', $tag)) {

                    # Valid standard underlay colour tag
                    return ('standard', TRUE);

                } else {

                    # Invalid standard underlay colour tag
                    return @emptyList;
                }

            } elsif (substr($tag, 0, 3) eq 'UL_') {

                substr($tag, 0, 3) = '';
                if ($self->ivExists('boldColourTagHash', $tag)) {

                    # Valid standard underlay colour tag
                    return ('standard', TRUE);

                } else {

                    # Invalid standard underlay colour tag
                    return @emptyList;
                }

            } elsif (
                $self->ivExists('colourTagHash', $tag)
                || $self->ivExists('boldColourTagHash', $tag)
            ) {
                # Valid standard colour tag
                return ('standard', FALSE);
            }
        }

        # xterm and RGB colour tags are case-insensitive (unlike standard colour tags)
        $tag = lc($tag);
        # Remove the initial 'u' that represents an underlay colour (as opposed to a text colour)
        if (substr($tag, 0, 1) eq 'u') {

            substr($tag, 0, 1) = '';
            $underlayFlag = TRUE;
        }

        # xterm colour tags
        if ($mode eq 'all' || $mode eq 'xterm') {

            if ($self->ivExists('xTermColourHash', $tag)) {

                if (! $underlayFlag) {

                    # Valid xterm text colour tag
                    return ('xterm', FALSE);

                } else {

                    # Valid xterm underlay colour tag
                    return ('xterm', TRUE);
                }
            }
        }

        # RGB colour tags
        if ($mode eq 'all' || $mode eq 'rgb') {

            if ($tag =~ m/^\#[a-f0-9]{6}$/) {

                if (! $underlayFlag) {

                    # Valid RGB text colour tag
                    return ('rgb', FALSE);

                } else {

                    # Valid RGB underlay colour tag
                    return ('rgb', TRUE);
                }
            }
        }

        # Otherwise it's an invalid colour tag
        return @emptyList;
    }

    sub checkTextTags {

        # Can be called by anything
        # A modified copy of $self->checkColourTags; checks only standard, xterm and RGB text
        #   colour tags (ignores underlay colour tags)
        #
        # Expected arguments
        #   $tag        - The colour tag to check. Standard colour tags are case-sensitive (i.e.
        #                   'red' and 'RED' are different colours), but xterm and RGB colour tags
        #                   are case-insensitive (i.e. '#ffffff' and '#FFFFFF' are the same colour)
        #
        # Optional arguments
        #   $mode       - Specifies which tags to check
        #                   'all' (or 'undef') - check standard, xterm and RGB colour tags
        #                   'standard' - check only standard colour tags
        #                   'xterm' - check only xterm colour tags
        #                   'rgb' - check only RGB colour tags
        #
        # Return values
        #   'undef' on improper arguments it it's not a recognised text colour tag (including any
        #       underlay colour tag), or if $mode is set to 'standard', 'xterm' or 'rgb' and $tag
        #       isn't one of those colour tags, or if $mode is an unrecognised value
        #   Otherwise returns a string identifying $tag: 'standard', 'xterm' or 'rgb'

        my ($self, $tag, $mode, $check) = @_;

        # Check for improper arguments
        if (! defined $tag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkTextTags', @_);
        }

        if (! defined $mode) {

            $mode = 'all';
        }

        # Standard text colour tags
        if ($mode eq 'all' || $mode eq 'standard') {

            if (
                $self->ivExists('colourTagHash', $tag)
                || $self->ivExists('boldColourTagHash', $tag)
            ) {
                # Valid standard colour tag
                return 'standard';
            }
        }

        # xterm and RGB colour tags are case-insensitive (unlike standard colour tags)
        $tag = lc($tag);

        # xterm colour tags
        if ($mode eq 'all' || $mode eq 'xterm') {

            if ($self->ivExists('xTermColourHash', $tag)) {

                # Valid xterm text colour tag
                return 'xterm';
            }
        }

        # RGB colour tags
        if ($mode eq 'all' || $mode eq 'rgb') {

            if ($tag =~ m/^\#[a-f0-9]{6}$/) {

                # Valid RGB text colour tag
                return 'rgb';
            }
        }

        # Otherwise it's either a valid underlay colour tag, or an invalid colour tag
        return undef;
    }

    sub checkUnderlayTags {

        # Can be called by anything
        # A modified copy of $self->checkColourTags; checks only standard, xterm and RGB underlay
        #   colour tags (ignores text colour tags)
        #
        # Expected arguments
        #   $tag        - The colour tag to check. Standard colour tags are case-sensitive (i.e.
        #                   'ul_red' and 'UL_RED' are different colours), but xterm and RGB colour
        #                   tags are case-insensitive (i.e. 'u#ffffff' and 'U#FFFFFF' are the same
        #                   colour)
        #
        # Optional arguments
        #   $mode       - Specifies which tags to check
        #                   'all' (or 'undef') - check standard, xterm and RGB colour tags
        #                   'standard' - check only standard colour tags
        #                   'xterm' - check only xterm colour tags
        #                   'rgb' - check only RGB colour tags
        #
        # Return values
        #   'undef' on improper arguments it it's not a recognised underlay colour tag (including
        #       any text colour tag), or if $mode is set to 'standard', 'xterm' or 'rgb' and $tag
        #       isn't one of those colour tags, or if $mode is an unrecognised value
        #   Otherwise returns a string identifying $tag: 'standard', 'xterm' or 'rgb'

        my ($self, $tag, $mode, $check) = @_;

        # Check for improper arguments
        if (! defined $tag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkUnderlayTags', @_);
        }

        if (! defined $mode) {

            $mode = 'all';
        }

        # Standard colour tags
        if ($mode eq 'all' || $mode eq 'standard') {

            # GA::Client->colourTagHash and ->boldColourTagHash both contain 'red', 'BLUE' etc, but
            #   they don't contain the corresponding underlay tags 'ul_red', 'UL_BLUE', etc
            # Since 'red' is the same colour as 'ul_red', we can simply remove the 'ul_' or 'UL_'
            #   portions
            if (substr($tag, 0, 3) eq 'ul_') {

                substr($tag, 0, 3) = '';
                if ($self->ivExists('colourTagHash', $tag)) {

                    # Valid standard underlay colour tag
                    return 'standard';

                } else {

                    # Invalid standard underlay colour tag
                    return undef;
                }

            } elsif (substr($tag, 0, 3) eq 'UL_') {

                substr($tag, 0, 3) = '';
                if ($self->ivExists('boldColourTagHash', $tag)) {

                    # Valid standard underlay colour tag
                    return 'standard'

                } else {

                    # Invalid standard underlay colour tag
                    return undef;
                }
            }
        }

        # xterm and RGB colour tags are case-insensitive (unlike standard colour tags)
        $tag = lc($tag);
        # Remove the initial 'u' that represents an underlay colour (as opposed to a text colour)
        if (substr($tag, 0, 1) eq 'u') {

            substr($tag, 0, 1) = '';

        } else {

            # Not a valid xterm or RGB underlay colour flag
            return undef;
        }

        # xterm colour tags
        if ($mode eq 'all' || $mode eq 'xterm') {

            if ($self->ivExists('xTermColourHash', $tag)) {

                # Valid xterm underlay colour tag
                return 'xterm';
            }
        }

        # RGB colour tags
        if ($mode eq 'all' || $mode eq 'rgb') {

            if ($tag =~ m/^\#[a-f0-9]{6}$/) {

                # Valid RGB underlay colour tag
                return 'rgb';
            }
        }

        # Otherwise it's either a valid text colour tag, or an invalid colour tag
        return undef;
    }

    sub checkBoldTags {

        # Can be called by anything
        # Checks whether a specified colour tag is bold standard colour tag - either a text tag
        #   like 'BLUE' or an underlay tag like 'UL_BLUE'
        #
        # Expected arguments
        #   $tag        - the colour tag to check
        #
        # Return values
        #   'undef' on improper arguments it it's not a bold standard colour tag
        #   'text' if it's a bold standard text colour tag (e.g. 'BLUE')
        #   'underlay' if it's an bold standard underlay tag (e.g. 'UL_BLUE')

        my ($self, $tag, $check) = @_;

        # Check for improper arguments
        if (! defined $tag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkBoldTags', @_);
        }

        # ->boldColourTagHash contains 'BLUE' etc, but it doesn't contain the corresponding underlay
        #   tags 'UL_BLUE', etc
        # Since 'BLUE' is the same colour as 'UL_BLUE', we can simply remove 'UL_' portion
        if (substr($tag, 0, 3) eq 'UL_') {

            substr($tag, 0, 3) = '';
            if ($self->ivExists('boldColourTagHash', $tag)) {

                # Valid bold standard underlay colour tag
                return 'underlay';
            }

        } elsif ($self->ivExists('boldColourTagHash', $tag)) {

            # Valid bold standard text colour tag
            return 'text';
        }

        # Not a valid bold standard colour tag
        return undef;
    }

    sub returnRGBColour {

        # Can be called by anything
        # Translate one of the standard colour tags used by Axmud (e.g. 'white') or an xterm colour
        #   tag (e.g. 'x255') into an RGB colour tag (e.g. '#FFFFFF')
        # If an RGB colour tag is supplied, returns it unmodified
        # If the standard/xterm colour tag isn't recognised, returns a failsafe RGB tag based on
        #   either $self->constTextColour or $self->constBackgroundColour
        #
        # Expected arguments
        #   $tag    - the Axmud colour tag to translate
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns an RGB colour in the form #xxxxxx

        my ($self, $tag, $check) = @_;

        # Local variables
        my ($defaultText, $defaultBackground);

        # Check for improper arguments
        if (! defined $tag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->returnRGBColour', @_);
        }

        # Get some failsafe RGB tags to use in case $tag isn't recognised
        $defaultText = $self->ivShow('colourTagHash', $self->constTextColour);
        $defaultBackground = $self->ivShow('colourTagHash', $self->constBackgroundColour);

        # If we have been supplied with an RGB colour tag, we must return it unmodified
        if ($tag =~ m/^[Uu]?\#[A-Fa-f0-9]{6}$/) {

            return $tag;

        # The tag 'red' should return the same RGB colour as 'ul_red', and the tag 'BLUE' should
        #   return the same RGB colour as 'UL_BLUE'
        } elsif (substr($tag, 0, 3) eq 'ul_') {

            substr($tag, 0, 3) = '';
            if ($self->ivExists('colourTagHash', $tag)) {

                # Valid (normal) underlay colour tag
                return $self->ivShow('colourTagHash', $tag);

            } else {

                # Invalid (normal) underlay colour tag. Use the default background colour instead
                return $defaultBackground;
            }

        } elsif (substr($tag, 0, 3) eq 'UL_') {

            substr($tag, 0, 3) = '';
            if ($self->ivExists('boldColourTagHash', $tag)) {

                # Valid (bold) underlay colour tag
                return $self->ivShow('boldColourTagHash', $tag);

            } else {

                # Invalid (bold) underlay colour tag. Use the default background colour instead
                return $defaultBackground;
            }

        } elsif ($self->ivExists('colourTagHash', $tag)) {

            # Valid (normal) text colour tag
            return $self->ivShow('colourTagHash', $tag);

        } elsif ($self->ivExists('boldColourTagHash', $tag)) {

            # Valid (bold) text colour tag
            return $self->ivShow('boldColourTagHash', $tag);

        } elsif ($self->ivExists('xTermColourHash', $tag)) {

            # Valid xterm text colour tag
            return $self->ivShow('xTermColourHash', $tag);

        } elsif (
            substr($tag, 0, 1) eq 'u'
            && $self->ivExists('xTermColourHash', substr($tag, 1))
        ) {
            # Valid xterm underlay colour tag
            return $self->ivShow('xTermColourHash', substr($tag, 1));

        } else {

            # Invalid colour tag. Use the (global) default text colour instead
            return $defaultText;
        }
    }

    sub returnCairoColour {

        # Can be called by anything (but is not currently called by anything)
        # Translates any Axmud colour tag (including standard, xterm and RGB tags) into a format
        #   used for Cairo drawing - a reference to a list containing three values in the range 0-1,
        #   corresponding to the RGB values Cairo is expecting
        #
        # Expected arguments
        #   $tag    - the Axmud colour tag to translate
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the list reference described above

        my ($self, $tag, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (! defined $tag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->returnCairoColour', @_);
        }

        # Convert the colour tag to an RGB tag, in the form '#ABCDEF'
        $tag = $self->returnRGBColour($tag);
        if (! $tag) {

            return undef;
        }

        # Convert the 'AB', 'CD' and 'EF' portions to values in the range 0-1, and return them
        @list = (
            (hex (substr($tag, -6, 2)) / 255),
            (hex (substr($tag, -4, 2)) / 255),
            (hex (substr($tag, -2, 2)) / 255),
        );

        return \@list;
    }

    sub swapColours {

        # Can be called by anything
        # Converts a text colour tag into an underlay colour tag, or an underlay colour tag into a
        #   text colour tag
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $tag        - A standard colour tag, e.g 'red' or 'UL_BLUE', an xterm colour tag,
        #                   e.g. 'x255' or 'ux255', or an RGB colour tag, e.g. '#FF0000' or
        #                   'u#FF0000'. If 'undef', then 'undef' is returned
        #
        # Return values
        #   'undef' on improper arguments or if $tag is 'undef'
        #   Otherwise returns the converted tag

        my ($self, $tag, $check) = @_;

        # Local variables
        my ($type, $underlayFlag);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->swapColours', @_);
        }

        if (! defined $tag) {

            return undef;
        }

        ($type, $underlayFlag) = $self->checkColourTags($tag);
        if ($type) {

            if ($type eq 'standard') {

                # Standard text colour tags
                if (! $underlayFlag) {

                    if ($self->ivExists('constColourTagHash', $tag)) {
                        $tag = 'ul_' . $tag;
                    } else {
                        $tag = 'UL_' . $tag;
                    }

                # Standard underlay colour tags
                } else {

                    # Remove the initial 'ul_' or 'UL_'
                    $tag = substr($tag, 3);
                }

            # xterm text colour tags
            # RGB text colour tags
            } elsif (! $underlayFlag) {

                $tag = 'u' . $tag;

            # xterm underlay colour tags
            # RGB underlay colour tags
            } else {

                # Remove the initial 'u'
                $tag = substr($tag, 1);
            }
        }

        return $tag;
    }

    # Text-to-speech (TTS)

    sub tts {

        # Can be called by anything
        # Converts a string to audible speech, using one of the supported TTS engines. Never tries
        #   to convert a string if it contains no alphanumeric characters (because if we send
        #   unreadable text to the engine, there will be a delay)
        #
        # Expected arguments
        #   (none besides self)
        #
        # Optional arguments
        #   $text   - The text to convert to audible speech (if an empty string or 'undef', nothing
        #               happens)
        #   $type   - The type of message to be converted: 'receive' for text received from the
        #               world, 'system', 'error' for system messages, 'command' (or 'cmd') for a
        #               world command, 'dialogue' for a 'dialogue' window or 'task' for a task
        #               message or 'other' for something else (if an empty string or 'undef', the
        #               type 'other' is used)
        #   $configuration
        #           - Name of the TTS configuration object to use, which specifies the engine,
        #               voice, word speed and word pitch to use (a key in GA::Client->ttsObjHash; if
        #               set to an empty string or 'undef', or if no TTS configuration object called
        #               $name exists, the 'default' configuration object is used)
        #           - If set to the dummy configuration 'none', nothing is read out
        #           - If $self->forceTTSEngine, that is used as the configuration, overriding any
        #               setting of $configuration besides 'none'
        #   $session
        #           - The calling GA::Session (can be set to 'undef' if there is no calling
        #               session)
        #   $engine, $voice, $speed, $rate, $pitch, $volume
        #           - Set when called by GA::Cmd::Speak->do, in order to override the engine,
        #               voice, speed and/or pitch of the specified $configuration (any that are set
        #               to 'undef' are ignored). For $speed, $rate, $pitch and $volume, the values
        #               (if defined) are in the range 0-100
        #   $exclFlag
        #           - Set to TRUE when called by GA::Cmd::Speak->do (or by anything else), meaning
        #               that the TTS configuration's exclusive/excluded patterns should not be
        #               checked. Set to FALSE (or 'undef') if they should be checked as normal
        #   $overrideFlag
        #           - Set to TRUE when called by GA::Cmd::Speak->do (or by anything else), meaning
        #               that the text should be converted even if GA::Client->systemAllowTTSFlag
        #               is set to FALSE (subject to other checks)
        #
        # Return values
        #   'undef' on improper arguments, if $text is an empty string (or 'undef'), if TTS is
        #       disabled generally or if the text-to-speech conversion can't be done for any other
        #       reason
        #   1 otherwise

        my (
            $self, $text, $type, $configuration, $session, $engine, $voice, $speed, $rate, $pitch,
            $volume, $exclFlag, $overrideFlag, $check,
        ) = @_;

        # Local variables
        my (
            $cmd, $begin, $end, $rateFlag, $pitchFlag, $volumeFlag, $ttsObj, $param,
            @lineList, @modList, @finalList, @msWinList,
        );

        # Check for improper arguments
        if (! defined $type || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->tts', @_);
        }

        # If no $text was specified or if TTS is disabled generally, there's nothing to convert
        if (
            ! $text
            || (! $self->systemAllowTTSFlag && ! $overrideFlag)
        ) {
            return undef;
        }

        # If the user specified a TTS engine from the command line, it overrides all other TTS
        #   engines
        if (
            $self->forceTTSEngine
            && (! defined $configuration || $configuration ne 'none')
        ) {
            if (defined $configuration && $self->forceTTSEngine ne $configuration) {

                # Ignore the voice/speed/rate/pitch/volume specified by the calling function
                #   GA::Cmd::Speak->do
                $voice = $speed = $rate = $pitch = $volume = undef;
            }

            $configuration = $self->forceTTSEngine;
        }

        # The system commands use " to contain the text portion, so if $text contains any double
        #   quotes, replace them with single quotes
        $text =~ s/\"/\'/g;

        # Set the TTS configuration object (GA::Obj::Tts) to use, which specifies the TTS engine,
        #   voice, word speed, word rate, word pitch and volume. If no TTS configuration object was
        #   specified, use the default one
        if (
            ! $configuration
            || ! $self->ivExists('ttsObjHash', $configuration)
        ) {
            $configuration = 'default';
        }

        $ttsObj = $self->ivShow('ttsObjHash', $configuration);

        # Set the type of message, if none was specified (or if an invalid type was specified)
        if (
            ! $type
            || (
                $type ne 'receive' && $type ne 'system' && $type ne 'error' && $type ne 'command'
                && $type ne 'cmd' && $type ne 'dialogue' && $type ne 'task' && $type ne 'other'

            )
        ) {
            $type = 'other';

        } elsif ($type eq 'cmd') {

            $type = 'command';
        }

        # Set the engine, voice, speed, rate, pitch and volume to use (overriding the TTS
        #   configuration object, if necessary)
        if (! $engine) {

            $engine = $ttsObj->engine;
        }

        if (! $voice) {

            $voice = $ttsObj->voice;        # May still be 'undef'
        }

        if (! $speed) {

            $speed = $ttsObj->speed;        # May still be 'undef'
        }

        if (! $rate) {

            $rate = $ttsObj->rate;          # May still be 'undef'
        }

        if (! $pitch) {

            $pitch = $ttsObj->pitch;        # May still be 'undef'
        }

        if (! $volume) {

            $volume = $ttsObj->volume;      # May still be 'undef'
        }

        # Split $text into separate lines, so we can check each line before re-combining them for
        #   TTS operations
        @lineList = split("\n", $text);

        # Don't attempt to convert any lines which contain no alphanumeric characters
        foreach my $line (@lineList) {

            if ($line =~ m/\w/) {

                push (@modList, $line);
            }
        }

        # Check each line of $text against exclusive/excluded patterns  (unless the flag is set)
        if (! $exclFlag) {

            foreach my $line (@modList) {

                my $matchFlag;

                if ($ttsObj->exclusiveList) {

                    OUTER: foreach my $pattern ($ttsObj->exclusiveList) {

                        if ($line =~ m/$pattern/i) {

                            $matchFlag = TRUE;
                            last OUTER;
                        }
                    }

                    if ($matchFlag) {

                        # $line matches an exclusive pattern, so we do convert it to speech
                        push (@finalList, $line);
                    }

                } elsif ($ttsObj->excludedList) {

                    OUTER: foreach my $pattern ($ttsObj->excludedList) {

                        if ($line =~ m/$pattern/i) {

                            $matchFlag = TRUE;
                            last OUTER;
                        }
                    }

                    if (! $matchFlag) {

                        # $line does not match an excluded pattern, so we do convert it to speech
                        push (@finalList, $line);
                    }

                } else {

                    # No exclusive/excluded patterns to check
                    push (@finalList, $line);
                }
            }

            if (! @finalList) {

                # No readable lines found, so don't convert anything
                return undef;

            } else {

                # Recombine the lines into a single string, so that the TTS engine reads them more
                #   naturally
                $text = join(' ', @finalList);
            }
        }

        # Prepare the system command to use. If $engine is set to the dummy engine 'none', then we
        #   don't prepare a system command at all

        # Prepare a system command on MS Windows
        if ($^O eq 'MSWin32') {

            if ($engine eq 'espeak') {

                # With eSpeak, we can set the voice, speed and pitch, but not rate or volume
                if (! $self->eSpeakPath) {

                    # No eSpeak engine found in the system
                    return undef;

                } else {

                    push (@msWinList,
                        $self->eSpeakPath,
                        $text,
                       );
                }

                if (defined $voice) {

                    push (@msWinList, '-v', $voice);
                }

                # Speed in the range 10-200
                if ($self->floatCheck($speed, 0, 100)) {

                    $speed = int($speed * 1.9) + 10;

                    push (@msWinList, '-s', $speed);
                }

                # Pitch in the range 0-99
                if ($self->floatCheck($pitch, 0, 100)) {

                    if ($pitch > 99) {

                        $pitch = 99;
                    }

                    push (@msWinList, '-p', $pitch);
                }

            } elsif ($engine eq 'esng') {

                # With espeak-ng, we can set the voice, speed, pitch and volume, but not rate
                push (@msWinList,
                    "C:\\Program Files\\eSpeak NG\\espeak-ng",
                    $text,
                );

                if (defined $voice) {

                    push (@msWinList, '-v', $voice);
                }

                # Speed in the range 10-200
                if ($self->floatCheck($speed, 0, 100)) {

                    $speed = int($speed * 1.9) + 10;

                    push (@msWinList, '-s', $speed);
                }

                # Pitch in the range 0-99
                if ($self->floatCheck($pitch, 0, 100)) {

                    if ($pitch > 99) {

                        $pitch = 99;
                    }

                    push (@msWinList, '-p', $pitch);
                }

                # Volume in the range 0-200
                if ($self->floatCheck($volume, 0, 100)) {

                    $volume *= 2;

                    push (@msWinList, '-a', $volume);
                }

            } elsif ($engine eq 'flite' || $engine eq 'festival') {

                # Flite not available on MS Windows
                # Festival has been ported to MS Windows, but with little or no documentation
                return undef;

            } elsif ($engine eq 'swift') {

                # With Swift on MS Windows (using Cepstral), we can set the voice, speed, pitch and
                #   volume, but not rate
                push (@msWinList, "C:\\Program Files\\Cepstral\\bin\\swift");

                if ($voice) {

                    push (@msWinList, '-n', $voice);
                }

                # Speed in the range 100-400
                if ($self->floatCheck($speed, 0, 100)) {

                    $speed = ($speed * 3) + 100;

                    $param = 'speech/rate=' . $speed
                }

                # Pitch in the range 0.1-5
                if ($self->floatCheck($pitch, 0, 100)) {

                    $pitch = int($pitch/20);
                    if ($pitch < 0.1) {

                        $pitch = 0.1;
                    }

                    if (! $param) {
                        $param = 'speech/pitch/shift=' . $pitch;
                    } else {
                        $param .= ',speech/pitch/shift=' . $pitch;
                    }
                }

                # Volume in the range 0-100
                if ($self->floatCheck($volume, 0, 100)) {

                    if (! $param) {
                        $param = 'audio/volume=' . $volume;
                    } else {
                        $param .= ',audio/volume=' . $volume;
                    }
                }

                if ($param) {

                    push (@msWinList, '-p', $param);
                }

                push (@msWinList, $text);
            }

            # Convert the text to speech
            if ($engine eq 'festival' && $self->ttsFestivalServer) {

                # (If using Festival server, we contact it directly; otherwise use the standard
                #   Perl system command)
                $self->ttsFestivalServer->print($cmd);

            } elsif ($configuration ne 'none') {

                system (@msWinList);
            }

            # Inform the calling session (if any) which type of message was most recently converted
            #   to speech
            if ($session) {

                $session->set_ttsLastType($type);
            }

        # Prepare a system command on Linux/*BSD
        } else {

            if ($engine eq 'espeak') {

                # With eSpeak, we can set the voice, speed and pitch, but not rate or volume
                $cmd = 'espeak "' . $text . '"';

                if (defined $voice) {

                    $cmd .= ' -v ' . $voice;
                }

                # Speed in the range 10-200
                if ($self->floatCheck($speed, 0, 100)) {

                    $speed = int($speed * 1.9) + 10;

                    $cmd .= ' -s ' . $speed;
                }

                # Pitch in the range 0-99
                if ($self->floatCheck($pitch, 0, 100)) {

                    if ($pitch > 99) {

                        $pitch = 99;
                    }

                    $cmd .= ' -p ' . $pitch;
                }

            } elsif ($engine eq 'esng') {

                # With espeak-ng, we can set the voice, speed, pitch and volume, but not rate
                $cmd = 'espeak-ng "' . $text . '"';

                if (defined $voice) {

                    $cmd .= ' -v ' . $voice;
                }

                # Speed in the range 10-200
                if ($self->floatCheck($speed, 0, 100)) {

                    $speed = int($speed * 1.9) + 10;

                    $cmd .= ' -s ' . $speed;
                }

                # Pitch in the range 0-99
                if ($self->floatCheck($pitch, 0, 100)) {

                    if ($pitch > 99) {

                        $pitch = 99;
                    }

                    $cmd .= ' -p ' . $pitch;
                }

                # Volume in the range 0-200
                if ($self->floatCheck($volume, 0, 100)) {

                    $volume *= 2;

                    $cmd .= ' -a ' . $volume;
                }

            } elsif ($engine eq 'flite') {

                # With Flite, we can set the voice, but not speed, rate, pitch or volume
                $cmd = 'flite -t "' . $text . '"';

                if (defined $voice) {

                    $cmd .= ' -voice ' . $voice;
                }

            } elsif ($engine eq 'festival') {

                # When the specified engine is Festival, we try using the Festival server if
                #   possible; otherwise, we default to using the Festival engine from the command
                #   line
                # With Festival server, we can set the voice, rate, pitch and volume, but not speed
                # With Festival command line, we can't set the voice, speed, rate pitch of volume

                # Start the Festival server (if required)
                if ($self->ttsFestivalServerMode eq 'waiting' && $self->ttsStartServerFlag) {

                    # Attempt to start the Festival server
                    $self->ttsStartServer();

                    # We're now waiting for the first successful connection
                    $self->set_ttsFestivalServerMode('connecting');
                }

                # Connect to the Festival server (if required)
                if ($self->ttsFestivalServerMode eq 'connecting') {

                    $self->ttsConnectServer();
                }

                # Prepare the system command, depending on whether we're using the Festival server,
                #   or not
                if ($self->ttsFestivalServer) {

                    # Use Festival server
                    $cmd = "(let ((utt (Utterance Text \"$text\")))";
                    if ($voice) {

                        $cmd .= " (begin ($voice)";

                        # Rate in the range 0.5-2
                        if ($self->floatCheck($rate, 0, 100)) {

                            $rate = ($rate * 0.015) + 0.5;

                            $cmd .= " (Parameter.set 'Duration_Stretch $rate)";
                        }

                        # Volume in the range 0.33-6
                        if ($self->floatCheck($volume, 0, 100)) {

                            $volume = ($volume * 0.0567) + 0.33;

                            $cmd .= " (utt.synth utt) (utt.wave.resample utt 8000)"
                                        . " (utt.wave.rescale utt $volume) (utt.play utt)";
                        }

                        $cmd .= ")";
                    }

                    $cmd .= ")\n";

                } else {

                    # Don't use Festival server
                    $cmd = 'echo ' . $text . ' | festival --tts';
                }

            } elsif ($engine eq 'swift') {

                # With Swift on Linux (using Cepstral), we can set the voice, rate, pitch and
                #   volume, but not speed
                $begin = '';
                $end = '';
                if ($voice) {

                    $begin .= "swift <voice name=\"$voice\">";
                    $end = "</voice>" . $end;
                }

                # (rate, pitch and volume all share an element; only create the element if at least
                #   one valid value is being used)

                # Rate in the range 0.5-2
                if ($self->floatCheck($rate, 0, 100)) {

                    $rateFlag = TRUE;
                    $rate = ($rate * 0.015) + 0.5;
                }

                # Pitch in the range 0.1-5
                if ($self->floatCheck($pitch, 0, 100)) {

                    $pitch = $pitch / 20;
                    if ($pitch < 0.1) {

                        $pitch = 0.1;
                    }

                    $pitchFlag = TRUE;
                }

                # Volume in the range 0.33-6
                if ($self->floatCheck($volume, 0, 100)) {

                    $volumeFlag = TRUE;
                    $volume = ($volume * 0.0567) + 0.33;
                }

                if ($rateFlag || $pitchFlag || $volumeFlag) {

                    $begin .= "<prosody";
                    if ($rateFlag) {

                        $begin .= " rate='$rate'";
                    }

                    if ($pitchFlag) {

                        $begin .= " pitch='$pitch'";
                    }

                    if ($volumeFlag) {

                        $begin .= " volume='$volume'";
                    }

                    $begin .= ">";
                    $end = "</prosody>" . $end;
                }

                $cmd = $begin . $text . $end;
            }

            # Convert the text to speech
            if ($engine eq 'festival' && $self->ttsFestivalServer) {

                # (If using Festival server, we contact it directly; otherwise use the standard
                #   Perl system command)
                $self->ttsFestivalServer->print($cmd);

            } elsif ($configuration ne 'none') {

                system $cmd;
            }

            # Inform the calling session (if any) which type of message was most recently converted
            #   to speech
            if ($session) {

                $session->set_ttsLastType($type);
            }
        }

        # Operation complete
        return 1;
    }

    sub ttsStartServer {

        # Called by GA::Cmd::Speech->do and $self->tts
        # Attempts to start the Festival server on the local system
        #
        # Expected arguments
        #   (none besides self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ttsStartServer', @_);
        }

        system "festival --server &";

        return 1;
    }

    sub ttsConnectServer {

        # Called by $self->tts
        # When $self->ttsFestivalServerMode is 'connecting', actually connects to the Festival
        #   server, changing the mode to 'connected' if successful
        #
        # Expected arguments
        #   (none besides self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $server;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ttsConnectServer', @_);
        }

        if (! $self->ttsFestivalServerPort) {

            # Cannot connect to the server without a port
            $self->set_ttsFestivalServerMode('connected');

        } else {

            # Attempt to connect to the Festival server
            $server = IO::Socket::INET->new(
                Proto     => 'tcp',
                PeerAddr  => '127.0.0.1',
                PeerPort  => $self->ttsFestivalServerPort,
            );

            if ($server) {

                # Connected; store it as an IV
                $self->set_ttsFestivalServer($server);
                $self->set_ttsFestivalServerMode('connected');

            } elsif (! $self->ttsStartServerFlag) {

                # We didn't start the server. If the connection failed, give up after
                #   the first attempt (if we did start the server, keep trying)
                $self->set_ttsFestivalServerMode('connected');
            }
        }

        return 1;
    }

    sub ttsReconnectServer {

        # Called by GA::Cmd::Speech->do and GA::Client->set_ttsFestivalServerPort
        # Disconnects from the Festival server (if connected) and reset GA::Client IVs, so that the
        #   next call to $self->tts will initiate a reconnection
        #
        # Expected arguments
        #   (none besides self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ttsReconnectServer', @_);
        }

        if ($self->ttsFestivalServer) {

            shutdown($self->ttsFestivalServer, 2);
            $self->set_ttsFestivalServer();
        }

        # Setting the mode to 0 will cause the next call to $self->tts to initiate the
        #   reconnection
        $self->set_ttsFestivalServerMode('waiting');

        return 1;
    }

    sub ttsCreateStandard {

        # Called by $self->start
        # Creates standard TTS configuration objects and stores them in the client registry
        #
        # Expected arguments
        #   (none besides $self)s
        #
        # Return values
        #   'undef' on improper arguments, or if one of the standard zonemaps doesn't exist and
        #       can't be created
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createStandardTTS', @_);
        }

        # First create standard TTS configuration objects for each supported TTS engine ('espeak',
        #   'flite', 'festival', 'swift' and the dummy engine 'none')
        @list = $self->constTtsDefaultList;

        do {

            my ($engine, $voice, $speed, $rate, $pitch, $volume, $obj);

            $engine = shift @list;
            $voice = shift @list;
            $speed = shift @list;
            $rate = shift @list;
            $pitch = shift @list;
            $volume = shift @list;

            $obj = Games::Axmud::Obj::Tts->new(
                $engine,    # This TTS configuration object has the same name as its engine
                $engine,
                $voice,
                $speed,
                $rate,
                $pitch,
                $volume,
            );

            if (! $obj) {

                return $self->writeError(
                    'Cannot create the standard TTS configuration object \'' . $engine . '\'',
                    $self->_objClass . '->createStandardTTS',
                );

            } else {

                $self->ivAdd('ttsObjHash', $engine, $obj);
            }

        } until (! @list);

        # Next create the remaining standard TTS configuration objects, copying settings from one of
        #   the objects we created above
        foreach my $name ($self->ivKeys('constTtsObjHash')) {

            my ($copyName, $copyObj, $obj);

            # If this TTS configuration object wasn't created above...
            if (! $self->ivExists('ttsObjHash', $name)) {

                # Copy settings from this already-created TTS configuration object
                $copyName = $self->ivShow('constTtsObjHash', $name);
                $copyObj = $self->ivShow('ttsObjHash', $copyName);

                # Create a new object, using the settings from $copyObj
                $obj = Games::Axmud::Obj::Tts->new(
                    $name,
                    $copyObj->engine,
                    $copyObj->voice,
                    $copyObj->speed,
                    $copyObj->rate,
                    $copyObj->pitch,
                    $copyObj->volume,
                );

                if (! $obj) {

                    return $self->writeError(
                        'Cannot create the standard TTS configuration object \'' . $name . '\'',
                        $self->_objClass . '->createStandardTTS',
                    );

                } else {

                    $self->ivAdd('ttsObjHash', $name, $obj);
                }
            }
        }

        # Operation complete
        return 1;
    }

    sub ttsAssignAttribs {

        # Called by $self->loadPlugin and ->enablePlugin
        # Updates the customisabletext-to-speech (TTS) attribute hashes, to take account of a task
        #   loaded from a plugin
        #
        # Expected arguments
        #   $taskName   - The newly-loaded task's standard name
        #
        # Return values
        #   'undef' on improper arguments or if the hashes can't be updated
        #   1 otherwise

        my ($self, $taskName, $check) = @_;

        # Local variables
        my ($packageName, $taskObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ttsAssignAttribs', @_);
        }

        # Get the package name corresponding to $taskName (e.g. 'Games::Axmud::Task::Status',
        #   'Games::Axmud::Task::Divert')
        $packageName = Games::Axmud::Generic::Cmd->findTaskPackageName($self, $taskName);
        if (! defined $packageName) {

            return undef;
        }

        # Create a dummy task, so we can access its IVs
        $taskObj = $packageName->new($self);
        if (! $taskObj) {

            return undef;
        }

        # Update TTS attributes
#       # v1.2.036. For unknown reasons, calling Games::Axmud::ivKeys() while loading a plugin from
#       #   ../share/private causes a stream of Perl errors. Workaround is to fetch the keys from
#       #   the IV directly
#       foreach my $attrib ($taskObj->ivKeys('ttsAttribHash')) {
        foreach my $attrib (keys %{$taskObj->{'ttsAttribHash'}}) {

            # In $self->ttsAttribHash, any existing (probably built-in tasks) using the same
            #   attribute are replaced with the task loaded from the plugin
            $self->ivAdd('ttsAttribHash', $attrib, $taskObj->name);
        }

#       foreach my $flagAttrib ($taskObj->ivKeys('ttsFlagAttribHash')) {
        foreach my $flagAttrib (keys %{$taskObj->{'ttsFlagAttribHash'}}) {

            $self->ivAdd('ttsFlagAttribHash', $flagAttrib, $taskObj->name);
        }

#       foreach my $alertAttrib ($taskObj->ivKeys('ttsAlertAttribHash')) {
        foreach my $alertAttrib (keys %{$taskObj->{'ttsAlertAttribHash'}}) {

            $self->ivAdd('ttsAlertAttribHash', $alertAttrib, $taskObj->name);
        }

        # Operation complete
        return 1;
    }

    sub ttsResetAttribs {

        # Called by $self->disablePlugin
        # Updates the customisable text-to-speech (TTS) attribute hashes, to remove any attributes
        #   assigned to a task from the disabled plugin
        # If those attributes are assigned to one of Axmud's built-in tasks, those attributes are
        #   re-assigned to the built-in task. Otherwise, they are removed from the attribute hashes
        #   entirely
        # (This doesn't take account of a situation, in which an attribute is used by a built-in
        #   task and two tasks from two different plugins. If one of the plugins is disabled, the
        #   attribute is re-assigned to the built-in task, not the other plugin task. Not a perfect
        #   system, but a practical one.)
        #
        # Expected arguments
        #   $taskName   - The task's standard name
        #
        # Return values
        #   'undef' on improper arguments or if the hashes can't be updated
        #   1 otherwise

        my ($self, $taskName, $check) = @_;

        # Local variables
        my ($packageName, $taskObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ttsResetAttribs', @_);
        }

        # Get the package name corresponding to $taskName (e.g. 'Games::Axmud::Task::Status',
        #   'Games::Axmud::Task::Divert')
        $packageName = Games::Axmud::Generic::Cmd->findTaskPackageName($self, $taskName);
        if (! defined $packageName) {

            return undef;
        }

        # Create a dummy task, so we can access its IVs
        $taskObj = $packageName->new($self);
        if (! $taskObj) {

            return undef;
        }

        # Update TTS attributes
        foreach my $attrib ($taskObj->ivKeys('ttsAttribHash')) {

            if ($self->ivExists('constTtsAttribHash', $attrib)) {

                # Re-assign the attribute to a built-in task
                $self->ivAdd(
                    'ttsAttribHash',
                    $attrib,
                    $self->ivShow('constTtsAttribHash', $attrib),
                );

            } else {

                # Delete the attribute
                $self->ivDelete('ttsAttribHash', $attrib);
            }
        }

        foreach my $flagAttrib ($taskObj->ivKeys('ttsFlagAttribHash')) {

            if ($self->ivExists('constTtsFlagAttribHash', $flagAttrib)) {

                # Re-assign the flag attribute to a built-in task
                $self->ivAdd(
                    'ttsFlagAttribHash',
                    $flagAttrib,
                    $self->ivShow('constTtsFlagAttribHash', $flagAttrib),
                );

            } else {

                # Delete the flag attribute
                $self->ivDelete('ttsFlagAttribHash', $flagAttrib);
            }
        }

        foreach my $alertAttrib ($taskObj->ivKeys('ttsAlertAttribHash')) {

            if ($self->ivExists('constTtsAlertAttribHash', $alertAttrib)) {

                # Re-assign the alert attribute to a built-in task
                $self->ivAdd(
                    'ttsAlertAttribHash',
                    $alertAttrib,
                    $self->ivShow('constTtsAlertAttribHash', $alertAttrib),
                );

            } else {

                # Delete the alert attribute
                $self->ivDelete('ttsAlertAttribHash', $alertAttrib);
            }
        }

        # Operation complete
        return 1;
    }

    # External applications

    sub openURL {

        # Called by GA::Strip::MenuBar->drawHelpColumn, GA::Obj::TextView->setButtonPressEvent,
        #   GA::OtherWin::Connect->createTableWidgets or any other function
        # Opens a URL link in an external web browser (if allowed)
        #
        # Expected arguments
        #   $link   - The URL to open
        #
        # Return values
        #   'undef' on improper arguments or if the link can't be opened
        #   1 otherwise

        my ($self, $link, $check) = @_;

        # Local variables
        my $cmd;

        # Check for improper arguments
        if (! defined $link || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->openURL', @_);
        }

        if (! $self->browserCmd || ! ($self->browserCmd =~ m/%s/)) {

            # No browser command set, or it doesn't contain a %s (which is substituted for the link)
            return undef;

        } else {

            $cmd = $self->browserCmd;
            $cmd =~ s/%s/$link/;

            system $cmd;

            return 1;
        }
    }

    sub openEmail {

        # Called by GA::Obj::TextView->setButtonPressEvent or by any other function
        # Opens an email link in an external email application (if allowed)
        #
        # Expected arguments
        #   $link   - The email address to open
        #
        # Return values
        #   'undef' on improper arguments or if the link can't be opened
        #   1 otherwise

        my ($self, $link, $check) = @_;

        # Local variables
        my $cmd;

        # Check for improper arguments
        if (! defined $link || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->openEmail', @_);
        }

        if (! $self->emailCmd || ! ($self->emailCmd =~ m/%s/)) {

            # No email command set, or it doesn't contain a %s (which is substituted for the link)
            return undef;

        } else {

            $cmd = $self->emailCmd;
            $cmd =~ s/%s/$link/;

            system $cmd;

            return 1;
        }
    }

    # Sound and sound effects

    sub playSound {

        # Can be called by anything
        # Plays a specified sound effect (if allowed, and if the sound effect exists)
        #
        # Expected arguments
        #   $sound  - The name of the sound effect to play; should match a key in
        #               $self->customSoundHash
        #
        # Return values
        #   'undef' on improper arguments or if the sound effect can't be played
        #   1 otherwise

        my ($self, $sound, $check) = @_;

        # Local variables
        my ($file, $cmd);

        # Check for improper arguments
        if (! defined $sound || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->playSound', @_);
        }

        $file = $self->ivShow('customSoundHash', $sound);

        if (
            # Sound not allowed
            ! $self->allowSoundFlag
            # No external audio player set, or the command to start the audio player doesn't contain
            #   a %s substitution
            || ! $self->audioCmd
            || ! ($self->audioCmd =~ m/%s/)
            # Sound effect doesn't exist, or no file specified for this sound effect
            || ! $file
            # File doesn't exist
            || ! (-e $file)
        ) {
            return undef;

        } else {

            # Play the file associated with $sound. GA::Client->audioCmd is a value in the form
            #   'play %s &', where %s is substituted for the name of the file to play
            $cmd = $self->audioCmd;
            $cmd =~ s/%s/$file/;

            system $cmd;

            return 1;
        }
    }

    sub playSoundFile {

        # Can be called by anything
        # Plays a sound file using the specified filepath. Unlike $self->playSound, which plays one
        #   of Axmud's sound effects, this function can be called to play any sound file on the
        #   local system
        # The optional arguments are designed for playing MSP sound triggers (called by
        #   GA::Session->processMspSoundTrigger). Other code can specify these arguments too, if
        #   required
        # The $v (volume) argument is only applied when using one of Axmud's supported audio
        #   packages. At the moment, the only package supported is SoX
        #
        # Expected arguments
        #   $session    - The calling GA::Session
        #   $path       - The full file path of the sound to play
        #
        # Optional arguments
        #   $delFlag    - Set to TRUE if the file $path should be deleted, when it has finished
        #                   playing, set to FALSE (or 'undef') otherwise. (Used for MXP sound files
        #                   which are converted from a world-specific file format, and which should
        #                   be deleted after being played)
        #   $type       - The MSP sound trigger type, 'sound' or 'music'. Should be 'undef' (or
        #                   'other') for non-MSP sounds
        #   $v          - The sound volume. Value in the range 0-100 (if 'undef', no volume applied)
        #   $l          - Number of repeats. Value in the range 1+, or -1 to repeat indefinitely (if
        #                   'undef', sound played only once)
        #   $p          - Sound priority. Value in the range 0-100. If $p is higher than the
        #                   priority of the sound already playing, the old sound is stopped and this
        #                   sound is played instead; otherwise, this sound is not played at all (if
        #                   'undef', default priority of 50 is applied by this function)
        #               - (NB Axmud sound effects played by $self->playSound are independent, and
        #                   not affected by this function)
        #   $c          - Continue flag. Values 0 or 1. If 1, the file should simply continue
        #                   playing if requested again. If 0, the file should restart, if requested
        #                   again.
        #               - (NB Axmud sound effects played by $self->playSound are independent, and
        #                   not affected by this function)
        #
        # Return values
        #   'undef' on improper arguments or if the sound file can't be played
        #   1 otherwise

        my ($self, $session, $path, $delFlag, $type, $v, $l, $p, $c, $check) = @_;

        # Local variables
        my (
            $cmd, $harness, $soundObj, $num,
            @args,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $path || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->playSoundFile', @_);
        }

        if (
            # Sound not allowed
            ! $self->allowSoundFlag
            # No external audio player set, or the command to start the audio player doesn't contain
            #   a %s substitution
            || ! $self->audioCmd
            || ! ($self->audioCmd =~ m/%s/)
            # File doesn't exist
            || ! (-e $path)
        ) {
            return undef;
        }

        # For non-MSP sounds, the $type stored in the GA::Obj::Sound object should be 'other'
        if (! defined $type) {

            $type = 'other';
        }

        # Use default values for $delFlag, $v, $l, $p and $c, if they were not specified
        if (! defined $delFlag) {

            $delFlag = FALSE;
        }

        if (! defined $v) {

            $v = 100;
        }

        if (! defined $l) {

            $l = 1;
        }

        if (! defined $p) {

            $p = 50;
        }

        if (! defined $c) {

            $c = 1;
        }

        # Prepare the argument list
        $cmd = $self->audioCmd;
        if (
            $^O ne 'MSWin32'
            && (substr($cmd, 0, 4) eq 'sox ' || substr($cmd, 0, 5) eq 'play ')
        ) {
            # Supported audio package, SoX ('-q' for quiet)
            @args = ('play', '-q');

            if (defined $v) {

                # $v is in the range 0-100; SoX expects a value in the range 0-1
                if ($v) {
                    push (@args, '-v ' . ($v / 100));
                } else {
                    push (@args, '-v 0');
                }
            }

            push (@args, $path);

        } else {

            # Unsupported audio package
            $cmd =~ s/%s//;
            @args = ($cmd, $path);
        }

        # Play the sound
        $harness = IPC::Run::start(\@args);
        # Create a GA::Obj::Sound object to store the harness details, so we can monitor its
        #   progress
        $session->add_soundHarness(
            $path,
            $harness,
            $delFlag,
            $type,
            $v,
            $l,
            $p,
            $c,
        );

        return 1;
    }

    sub repeatSoundFile {

        # Called by GA::Session->spinMaintainLoop (only)
        # Repeat the playing of a sound file, using details stored in a GA::Obj::Sound object
        # (This function complements $self->playSoundFile)
        #
        # Expected arguments
        #   $soundObj   - The GA::Obj::Sound object
        #
        # Return values
        #   'undef' on improper arguments or if the sound file can't be played
        #   1 otherwise

        my ($self, $soundObj, $check) = @_;

        # Local variables
        my (
            $cmd, $harness,
            @args,
        );

        # Check for improper arguments
        if (! defined $soundObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->repeatSoundFile', @_);
        }

        if (
            # Sound not allowed
            ! $self->allowSoundFlag
            # No external audio player set, or the command to start the audio player doesn't contain
            #   a %s substitution
            || ! $self->audioCmd
            || ! ($self->audioCmd =~ m/%s/)
            # File path no longer exists
            || ! (-e $soundObj->path)
        ) {
            return undef;
        }

        # Prepare the argument list
        $cmd = $self->audioCmd;
        if (
            $^O ne 'MSWin32'
            && (substr($cmd, 0, 4) eq 'sox ' || substr($cmd, 0, 5) eq 'play ')
        ) {
            # Supported audio package, SoX ('-q' for quiet)
            @args = ('play', '-q');

            # $v is in the range 0-100; SoX expects a value in the range 0-1
            if ($soundObj->volume) {
                push (@args, '-v ' . ($soundObj->volume / 100));
            } else {
                push (@args, '-v 0');
            }

            push (@args, $soundObj->path);

        } else {

            # Unsupported audio package
            $cmd =~ s/%s//;
            @args = ($cmd, $soundObj->path);
        }

        # Play the sound
        $harness = IPC::Run::start(\@args);
        # Update the GA::Obj::Sound object with the harness for the new sound (the calling function
        #   should update $soundObj->repeat, if necessary)
        $soundObj->ivPoke('harness', $harness);

        return 1;
    }

    # Seasonally appropriate logos/icons

    sub getClientLogo {

        # Returns the seasonally-appropriate file path for the client logo, mainly used in the
        #   Connections window
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $adultFlag  - If TRUE, show the client logo with an '18' in one corner. If FALSE (or
        #                   'undef'), show the usual logo
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the file path

        my ($self, $adultFlag, $check) = @_;

        # Local variables
        my ($second, $minute, $hour, $dayOfMonth, $month);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getClientLogo', @_);
        }

        ($second, $minute, $hour, $dayOfMonth, $month) = localtime();

        # NB $month is in the range 0-11
        if (($month == 11 && $dayOfMonth >= 24) || ($month == 0 && $dayOfMonth <= 5)) {

            if (! $adultFlag) {
                return $axmud::SHARE_DIR . '/icons/system/client_logo_xmas.png';
            } else {
                return $axmud::SHARE_DIR . '/icons/system/client_logo_xmas_18.png';
            }

        } else {

            if (! $adultFlag) {
                return $axmud::SHARE_DIR . '/icons/system/client_logo.png';
            } else {
                return $axmud::SHARE_DIR . '/icons/system/client_logo_18.png';
            }
        }
    }

    sub getDialogueIcon {

        # Returns the seasonally-appropriate file path for the standard 'dialogue' window icon
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $mode   - If specified and set to 'large' or 'medium', then the large/medium-size icon
        #               is used. For any other value (including 'undef'), the standard small icon is
        #               used
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the file path

        my ($self, $mode, $check) = @_;

        # Local variables
        my ($second, $minute, $hour, $dayOfMonth, $month);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getDialogueIcon', @_);
        }

        ($second, $minute, $hour, $dayOfMonth, $month) = localtime();

        # NB $month is in the range 0-11
        if (($month == 11 && $dayOfMonth >= 24) || ($month == 0 && $dayOfMonth <= 5)) {

            if (defined $mode && $mode eq 'large') {
                return $axmud::SHARE_DIR . '/icons/system/dialogue_icon_xmas_large.png';
            } elsif (defined $mode && $mode eq 'medium') {
                return $axmud::SHARE_DIR . '/icons/system/dialogue_icon_xmas_medium.png';
            } else {
                return $axmud::SHARE_DIR . '/icons/system/dialogue_icon_xmas.png';
            }

        } else {

           if (defined $mode && $mode eq 'large') {
                return $axmud::SHARE_DIR . '/icons/system/dialogue_icon_large.png';
            } elsif (defined $mode && $mode eq 'medium') {
                return $axmud::SHARE_DIR . '/icons/system/dialogue_icon_medium.png';
            } else {
                return $axmud::SHARE_DIR . '/icons/system/dialogue_icon.png';
            }
        }
    }

    # Auto-backup

    sub checkBackupInterval {

        # Called by $self->start when $self->autoBackupMode is 'interval_start', and by $self->stop
        #   when $self->autoBackupMode is 'interval_stop'
        # Checks whether it is time to perform an auto-backup
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if it's not yet time to perform an auto-backup
        #   1 if it is time to perform at auto-backup

        my ($self, $check) = @_;

        # Local variables
        my ($format, $time, $oldTime, $diff);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkBackupInterval', @_);
        }

        if (! $self->autoBackupInterval) {

            # Don't do auto-backups for the time being
            return undef;

        } elsif (! $self->autoBackupDate) {

            # No auto-backup time recorded, so perform an auto-backup now
            return 1;

        } else {

            # Otherwise, do the calculation
            $format = '%a %b %d, %Y';           # e.g. 'Thu Dec 18, 2010'
            $time = Time::Piece->strptime($self->localDate(), $format);
            $oldTime = Time::Piece->strptime($self->autoBackupDate, $format);

            $diff = $time->julian_day() - $oldTime->julian_day();

            if ($diff < $self->autoBackupInterval) {
                return undef;
            } else {
                return 1;
            }
        }
    }

    sub doAutoBackup {

        # Called by $self->start or $self->stop when it's time to do an auto-backup
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the auto-backup fails
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my (
            $dataDir, $ext, $fileName, $backupPath, $zipObj, $tarObj,
            @fileList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->doAutoBackup', @_);
        }

        # (Code borrowed from GA::Cmd::BackupData, as we don't want client command error messages)

        # Import the Axmud data directory for use in regexes
        $dataDir = $axmud::DATA_DIR;

        # In 'default' mode, archive to .zip on MS Windows, and to .tgz on Linux
        if ($self->autoBackupFileType eq 'default') {

            if ($^O eq 'MSWin32') {
                $ext = 'zip';
            } else {
                $ext = 'tgz';
            }

        } elsif ($self->autoBackupFileType eq 'zip') {
            $ext = 'zip';
        } else {
            $ext = 'tgz';
        }

        # Set the filename, appending the time if required
        if (! $axmud::CLIENT->autoBackupAppendFlag) {

            $fileName = $axmud::NAME_FILE . '_backup_' . $axmud::CLIENT->localDateString() . '.'
                            . $ext;

        } else {

            $fileName = $axmud::NAME_FILE . '_backup_' . $axmud::CLIENT->localDateString() . '_'
                            . $axmud::CLIENT->localClockString() . '.' . $ext;
        }

        # If necessary, open a file chooser dialog to decide where to save the exported file
        if ($self->autoBackupDir && -e $self->autoBackupDir) {

            $backupPath = $self->autoBackupDir;

        } else {

            $backupPath = $self->mainWin->showFileChooser(
                'Backup ' . $axmud::SCRIPT . ' data',
                'save',
                $fileName,
            );
        }

        if (! $backupPath) {

            return undef;
        }

        # Display a 'dialogue' window while backing up data. The 'undef' argument means 'show the
        #   standard icon'
        if (! $axmud::BLIND_MODE_FLAG) {

            $self->mainWin->showBusyWin(undef, 'Backing up...');
        }

        # Get a list of files in the data directory, recursively searching sub-directories
        File::Find::find(
            sub { push (@fileList, $File::Find::name); },
            $dataDir . '/',
        );

        # Perform the backup
        if ($ext eq 'zip') {

            # Create a zip object
            $zipObj = Archive::Zip->new();

            foreach my $file (@fileList) {

                my $modFile;

                if ($file ne $dataDir) {

                    $modFile = $file;
                    $modFile =~ s/$dataDir//;

                    # 6 is the default compression level
                    $zipObj->addFile($file, $modFile, 6);
                }
            }

            # Save the .zip file. Successful operation returns 0
            if ($zipObj->writeToFileNamed($backupPath)) {

                # Close the 'dialogue' window and reset the Client IV that stores it
                if ($self->busyWin) {

                    $self->mainWin->closeDialogueWin($self->busyWin);
                }

                return undef;
            }

        } else {

            # Create a tar object
            $tarObj = Archive::Tar->new();

            foreach my $file (@fileList) {

                if ($file ne $dataDir) {

                    $tarObj->add_files($file);
                    # Rename each file in the archive to remove the directory structure
                    $tarObj->rename(substr($file, 1), substr($file, length($dataDir)));
                }
            }

            # Save the .tgz file
            if (
                ! $tarObj->write(
                    $backupPath,
                    Archive::Tar::COMPRESS_GZIP,
                    $axmud::NAME_SHORT . '-data',
                )
            ) {
                # Close the 'dialogue' window and reset the Client IV that stores it
                if ($self->busyWin) {

                    $self->mainWin->closeDialogueWin($self->busyWin);
                }

                return undef;
            }
        }

        # Operation successful. Update IVs so the next scheduled auto-backup occurs on time
        if ($self->autoBackupMode eq 'all_start' || $self->autoBackupMode eq 'all_stop') {

            # No scheduled auto-backups; auto-backups occur when Axmud starts/stops
            $self->ivUndef('autoBackupDate');

        } else {

            # Scheduled auto-backups
            $self->ivPoke('autoBackupDate', $self->localDate());
        }

        # Close the 'dialogue' window and reset the Client IV that stores it
        if ($self->busyWin) {

            $self->mainWin->closeDialogueWin($self->busyWin);
        }

        return 1;
    }

    # General-purpose methods

    sub nameCheck {

        # Checks whether a name for a Perl object matches Axmud's naming rules (namely, must be
        #   between 1 to $maxLength characters, containing letters, numbers and underlines -
        #   first character can't be a number. International characters, e.g. those in Cyrillic,
        #   are accepted)
        # Also checks that the name doesn't clash with one of Axmud's reserved words
        #
        # Expected arguments
        #   $name       - the name (string) to be tested
        #   $maxLength  - the maximum string length allowed
        #
        # Return values
        #   'undef' on improper arguments or if $name is not valid, according to Axmud's naming
        #       rules
        #   1 if $name is acceptable

        my ($self, $name, $maxLength, $check) = @_;

        # Check for improper arguments
        if (! defined $name || ! defined $maxLength || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->nameCheck', @_);
        }

        # Check reserved words
        if ($self->ivExists('constReservedHash', lc($name))) {

            return undef;
        }

        # Perform the check
        $maxLength--;

        if (! ($name =~  m/^[[:alpha:]\_]{1}[[:word:]]{0,$maxLength}$/)) {
            return undef;
        } else {
            return 1;
        }
    }

    sub intCheck {

        # Checks whether a value is an integer, or not
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $num        - A value to test. If 'undef' or an empty string, no value is tested (and
        #                   no error message is produced)
        #   $min        - If defined, a minimum value. Can be zero or any floating-point number,
        #                   positive or negative (but will usually be another integer)
        #   $max        - If defined, a maximum value. Can be zero or any floating-point number,
        #                   positive or negative (but will usually be another integer)
        #
        # Return values
        #   'undef' on improper arguments, if $num is not a valid integer, if $min is defined and
        #       $num is not that value or higher, or if $max is defined and $num is not that value
        #       or lower
        #   1 otherwise

        my ($self, $num, $min, $max, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->intCheck', @_);
        }

        if (
            ! defined $num
            || $num eq ""
            || ! ($num =~ m/^[-]?\d+$/)
            || (defined $min && $num < $min)
            || (defined $max && $num > $max)
        ) {
            return undef;
        } else {
            return 1;
        }
    }

    sub floatCheck {

        # Checks whether a value is a floating-point (decimal) number, or not
        #
        # NB To check for a floating-point number that is any value above a minimum, do this:
        #   if (! $axmud::CLIENT->floatCheck($value, $min) || $value == $min) {
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $num        - A value to test. If 'undef' or an empty string, no value is tested (and
        #                   no error message is produced)
        #   $min        - If defined, a minimum value. Can be zero or any floating-point number,
        #                   positive or negative
        #   $max        - If defined, a maximum value. Can be zero or any floating-point number,
        #                   positive or negative
        #
        # Return values
        #   'undef' on improper arguments, if $num is not a valid floating-point number, if $min is
        #       defined and $num is not that value or higher, or if $max is defined and $num is not
        #       that value or lower
        #   1 otherwise

        my ($self, $num, $min, $max, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->floatCheck', @_);
        }

        if (
            ! defined $num
            || $num eq ""
            || ! ($num =~ m/^[-]?\d+(\.\d*)?$/)
            || (defined $min && $num < $min)
            || (defined $max && $num > $max)
        ) {
            return undef;
        } else {
            return 1;
        }
    }

    sub ipv4Check {

        # Checks whether a specified string is a valid IPv4 address (using Regexp::IPv4)
        #
        # Expected arguments
        #   $string     - the string to check
        #
        # Return values
        #   'undef' on improper arguments or if $string is not a valid IPv4 address
        #   1 if $string is a valid IPv4 address

        my ($self, $string, $check) = @_;

        # Local variables
        my ($digRegex, $regex);

        # Check for improper arguments
        if (! defined $string || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ipv4Check', @_);
        }

        # Regexp::IPv4 is not available in Debian, but since it's only three lines of code, we'll
        #   just import them directly
        $digRegex = '(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})';
        $regex = "(?:$digRegex(?:\\.$digRegex){3})";
        $regex = qr/$regex/;

        if ($string =~ /^$regex$/) {
            return 1;
        } else {
            return undef;
        }
    }

    sub ipv6Check {

        # Checks whether a specified string is a valid IPv6 address (using Regexp::IPv6)
        #
        # Expected arguments
        #   $string     - the string to check
        #
        # Return values
        #   'undef' on improper arguments or if $string is not a valid IPv6 address
        #   1 if $string is a valid IPv6 address

        my ($self, $string, $check) = @_;

        # Local variables
        my $regex;

        # Check for improper arguments
        if (! defined $string || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ipv6Check', @_);
        }

        $regex = $Regexp::IPv6::IPv6_re;

        if ($string =~ /^$regex$/) {
            return 1;
        } else {
            return undef;
        }
    }

    sub ipv4Get {

        # Contact remote servers to fetch the user's IP address
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the IP address can't be fetched
        #   Otherwise, the user's IP (in the form '101.102.103.104')

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->ipv4Get', @_);
        }

        # $self->constIPLookupList lists several servers, in case one of them isn't available
        foreach my $url ($self->constIPLookupList) {

            my ($obj, $response);

            $obj = HTTP::Tiny->new();
            if ($obj) {

                $response = $obj->get('http://canihazip.com/s/');
                if ($response->{success} && $response->{content} =~ m/^\d+\.\d+\.\d+\.\d+$/) {

                    return $response->{content};
                }
            }
        }

        # No IP address found
        return undef;
    }

    sub regexCheck {

        # Test that a regex is valid without generating a Perl error/warning message
        #
        # Expected arguments
        #   $regex  - The regex to test
        #
        # Return values
        #   'undef' on improper arguments or if $regex is a valid regular expression
        #   Otherwise, returns the error message generated by the invalid regular expression

        my ($self, $regex, $check) = @_;

        # Local variables
        my $result;

        # Check for improper arguments
        if (! defined $regex || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->regexCheck', @_);
        }

        # Set global variables to intercept the Perl error/warning message
        $axmud::TEST_REGEX_FLAG = TRUE;
        $axmud::TEST_REGEX_ERROR = undef;
        # Test the regex
        eval { qr/$regex/ };
        # The global variable is already set to 'undef' for a valid regex, or the error message
        #   generated by an invalid regex
        $result = $axmud::TEST_REGEX_ERROR;
        $axmud::TEST_REGEX_FLAG = FALSE;

        if (! defined $result) {

            return undef;

        } else {

            # Remove the 'at lib/Games/Axmud/Client.pm line xxxxx' portion, which the user
            #   definitely doesn't want
            $result =~ s/at lib.*Client\.pm line \d+.*//;
            # Also remove the final newline character
            chomp $result;

            return $result;
        }
    }

    sub commify {

        # Can be called by anything
        # Adds commas, full stops/periods, spaces or underlines/underscores to long numbers (e.g.
        #   converts 1000000 to 1,000,000 / 1.000.000 / 1 000 000 / 1_000_000)
        # Returns the modified string
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $number - An integer or floating point value, e.g. 1.124. If not defined, then 'undef'
        #                is returned
        #   $mode   - 'none' to add nothing, 'comma' to add commas, 'europe' to add European-style
        #               full stops/periods, 'brit' to add British-style spaces, 'underline' to use
        #               underlines/underscores. If 'undef', $self->commifyMode is used. If an
        #               unrecognised value is specified, adds nothing
        #
        # Return values
        #   'undef' if no arguments specified
        #   Otherwise returns the modified string

        my ($self, $number, $mode, $check) = @_;

        # (No check for improper arguments)

        if (! defined $mode) {

            $mode = $self->commifyMode;
        }

        if (! defined $number) {

            return undef;

        } elsif ($mode eq 'comma') {

            # (add commas)
            1 while $number =~ s/^([-+]?\d+)(\d{3})/$1,$2/;

        } elsif ($mode eq 'europe') {

            # (add European-style full stops/periods)
            1 while $number =~ s/^([-+]?\d+)(\d{3})/$1.$2/;

        } elsif ($mode eq 'brit') {

            # (add British-style spaces)
            1 while $number =~ s/^([-+]?\d+)(\d{3})/$1 $2/;

        } elsif ($mode eq 'underline') {

            # (add underlines/underscores)
            1 while $number =~ s/^([-+]?\d+)(\d{3})/$1_$2/;
        }

        return $number;
    }

    sub getKeycode {

        # Called by anything
        # Given an Axmud standard keycode, or one of the recognised alternative versions of a
        #   standard keycode, returns the corresponding keycode string (a string containing one or
        #   more keycodes, separated by spaces)
        #
        # Expected arguments
        #   $standard   - The standard Axmud keycode type (a key in $self->constKeycodeHash) or the
        #                   alternative version of this type (a key in $self->constAltKeycodeHash)
        #
        # Return values
        #   'undef' on improper arguments or if $standard is an invalid standard/alternative keycode
        #   1 otherwise

        my ($self, $standard, $check) = @_;

        # Check for improper arguments
        if (! defined $standard  || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getKeycode', @_);
        }

        # If $standard is an alternative keycode type, translate it into the standard keycode type
        if ($axmud::CLIENT->ivExists('constAltKeycodeHash', $standard)) {

            $standard = $axmud::CLIENT->ivShow('constAltKeycodeHash', $standard);

        # Otherwise, check that $type is a valid standard keycode type
        } elsif (! $self->ivExists('constKeycodeHash', $standard)) {

            # (No error message displayed - just return 'undef')
            return undef;
        }

        # Return the keycode string
        return $self->ivShow('keycodeHash', $standard);
    }

    sub reverseKeycode {

        # Called by anything
        # Converts one of the current system's keycodes (e.g. 'ISO_Level3_Shift' on Linux/*BSD,
        #   'Alt_R' on MS Windows) into an Axmud standard keycode
        #
        # Expected arguments
        #   $sysKeycode - The system keycode, e.g. 'ISO_Level3_Shift', 'Alt_R'
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the Axmud standard keycode. $self->constKeycodeHash doesn't include
        #       the keycodes for ordinary letters and numbers, so if $sysKeycode isn't in that
        #       hash, return $sysKeycode unmodified

        my ($self, $sysKeycode, $check) = @_;

        # Local variables
        my $standard;

        # Check for improper arguments
        if (! defined $sysKeycode  || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reverseKeycode', @_);
        }

        $standard = $axmud::CLIENT->ivShow('revKeycodeHash', $sysKeycode);
        if (! $standard) {
            return $sysKeycode;
        } else {
            return $standard;
        }
    }

    sub convertKeycodeString {

        # Called by GA::Generic::Cmd->addInterface and ->modifyInterface while adding or modifying
        #   a macro
        # The macro's stimulus is one of Axmud's standard keycodes (like 'f5') or a keycode string
        #   (like 'shift f5' or 'ctrl a')
        # Standard keycodes in a keycode string must be in a given order (i.e. 'ctrl shift f5', not
        #   'shift ctrl f5' or even 'f5 shift ctrl')
        # This function changes the order of words in the keycode string, if necessary, and returns
        #   the modified string
        #
        # Expected arguments
        #   $string     - A string containing one or more Axmud standard keycodes
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the modified (or original) keycode string

        my ($self, $string, $check) = @_;

        # Local variables
        my (
            $ctrlFlag, $shiftFlag, $altFlag, $altGrFlag, $newString,
            @list, @modList,
        );

        # Check for improper arguments
        if (! defined $string || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->convertKeycodeString', @_);
        }

        # Split the string into a list of words
        @list = split(m/\s+/, $string);

        # Go through @list, removing the 'ctrl', 'shift', 'alt', 'alt_gr' (which we'll put back
        #   later)
        foreach my $keycode (@list) {

            if ($keycode eq 'ctrl') {
                $ctrlFlag = TRUE;
            } elsif ($keycode eq 'shift') {
                $shiftFlag = TRUE;
            } elsif ($keycode eq 'alt') {
                $altFlag = TRUE;
            } elsif ($keycode eq 'alt_gr') {
                $altGrFlag = TRUE;
            } else {
                push (@modList, $keycode);
            }
        }

        # Now compile a new keycode string
        $newString = '';

        if ($ctrlFlag) {

            $newString .= 'ctrl';
        }

        if ($shiftFlag) {

            if ($newString) {
                $newString .= ' shift';
            } else {
                $newString .= 'shift';
            }
        }

        if ($altFlag) {

            if ($newString) {
                $newString .= ' alt';
            } else {
                $newString .= 'alt';
            }
        }

        if ($altGrFlag) {

            if ($newString) {
                $newString .= ' alt_gr';
            } else {
                $newString .= 'alt_gr';
            }
        }

        foreach my $keycode (@modList) {

            # Preserve the order of keycodes other than 'ctrl', 'shift', 'alt' or 'alt_gr'
            if ($newString) {
                $newString .= ' ' . $keycode;
            } else {
                $newString .= $keycode;
            }
        }

        return $newString;
    }

    sub getTime {

        # Called by several functions which handle the task and incoming data loops
        # Returns the system's current time (expressed in seconds since the system epoch, to three
        #   decimal places), using a call to Time::HiRes->gettimeofday()
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   The system time on success

        my ($self, $check) = @_;

        # Local variables
        my ($secs, $micros);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getTime', @_);
        }

        # Get the system time in seconds and microseconds
        ($secs, $micros) = Time::HiRes::gettimeofday();
        # Convert to seconds (to three decimal places)
        return ($secs + (int($micros / 1000)) / 1000);
    }

    sub getCounter {

        # Called by anything, but mostly by GA::Session->getTimeLabelText
        # Converts a time in seconds into a string like '35:07' or '4:35:07' (ignores milliseconds,
        #   so 5.741 seconds is returned as the string '0:05'
        #
        # Expected arguments
        #   $time   - A time in seconds
        #
        # Return values
        #   'undef' on improper arguments
        #   If $time is not a valid number (0 or positive), returns 0
        #   Otherwise, returns a string like '35:07' or '4:35:07'

        my ($self, $time, $check) = @_;

        # Local variables
        my ($hours, $mins, $secs);

        # Check for improper arguments
        if (! defined $time || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getCounter', @_);
        }

        # Check $time is a valid number
        if (! $self->floatCheck($time, 0)) {

            return 0;
        }

        # Convert $time
        $mins = int ($time / 60);
        $secs = $time % 60;

        $hours = int ($mins / 60);
        $mins = $mins % 60;

        if (! $hours) {
            return $mins . sprintf(':%02d', $secs);
        } else {
            return $hours . sprintf(':%02d:%02d', $mins, $secs);
        }
    }

    sub localTime {

        # Converts the output from Perl's localtime() function into the following format:
        #   e.g. 09:17:12, Thu Dec 18, 2010
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise the string described above

        my ($self, $check) = @_;

        # Local variables
        my (
            $second, $minute, $hour, $dayOfMonth, $month, $year, $yearOffset, $dayOfWeek,
            $dayOfYear, $daylightSavings,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->localTime', @_);
        }

        (
            $second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear,
            $daylightSavings,
        ) = localtime();

        $year = 1900 + $yearOffset;

        return (
            sprintf('%02d:%02d:%02d, ', $hour, $minute, $second)
            . $self->ivIndex('customDayList', $dayOfWeek)
            . ' ' . $self->ivIndex('customMonthList', $month)
            . " $dayOfMonth, $year"
        );
    }

    sub localClock {

        # Converts the output from Perl's localtime() function into the following format:
        #   e.g. 09:17:12
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise the string described above

        my ($self, $check) = @_;

        # Local variables
        my ($second, $minute, $hour);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->localClock', @_);
        }

        ($second, $minute, $hour) = localtime();

        return (sprintf('%02d:%02d:%02d', $hour, $minute, $second));
    }

    sub localClockString {

        # Converts the output from Perl's localtime() function into the following format:
        #   e.g. 09_17_12
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise the string described above

        my ($self, $check) = @_;

        # Local variables
        my ($second, $minute, $hour);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->localClock', @_);
        }

        ($second, $minute, $hour) = localtime();

        return (sprintf('%.2d_%.2d_%.2d', $hour, $minute, $second));
    }

    sub localDate {

        # Converts the output from Perl's localtime() function into the following format:
        #   e.g. Thu Dec 18, 2010
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise the string described above

        my ($self, $check) = @_;

        # Local variables
        my (
            $second, $minute, $hour, $dayOfMonth, $month, $year, $yearOffset, $dayOfWeek,
            $dayOfYear, $daylightSavings,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->localDate', @_);
        }

        (
            $second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear,
            $daylightSavings
        ) = localtime();

        $year = 1900 + $yearOffset;

        return $self->ivIndex('customDayList', $dayOfWeek)
            . ' ' . $self->ivIndex('customMonthList', $month)
            . " $dayOfMonth, $year";
    }

    sub localDateString {

        # Converts the output from Perl's localtime() function into the following format:
        #   e.g. 101218 (in format YYMMDD)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise the string described above

        my ($self, $check) = @_;

        # Local variables
        my (
            $second, $minute, $hour, $dayOfMonth, $month, $year, $yearOffset, $dayOfWeek,
            $dayOfYear, $daylightSavings,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->localDateString', @_);
        }

        (
            $second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear,
            $daylightSavings,
        ) = localtime();

        # $month is in the range 0-11
        $month++;
        $year = 1900 + $yearOffset;

        return (sprintf('%.2d%.2d%.2d', substr($year, 2), $month, $dayOfMonth));
    }

    sub convertTime {

        # Alternative to $self->localTime, that converts a specified system time rather than the
        #   current system time into a string in the following format:
        #   e.g. 09:17:12, Thu Dec 18, 2010
        #
        # Expected arguments
        #   $otherTime  - A system time (past, present or future) in seconds
        #
        # Optional arguments
        #   $mode       - If 'clock', only the clock component (e.g. 09:17:12) is returned. If
        #                   'date', only the date component (e.g. Thu Dec 18, 2010). If 'undef',
        #                   FALSE or any other value, the full string is returned
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise the string described above

        my ($self, $otherTime, $mode, $check) = @_;

        # Local variables
        my (
            $second, $minute, $hour, $dayOfMonth, $month, $year, $yearOffset, $dayOfWeek,
            $dayOfYear, $daylightSavings,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->convertTime', @_);
        }

        (
            $second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear,
            $daylightSavings,
        ) = localtime($otherTime);

        $year = 1900 + $yearOffset;

        if (defined $mode) {

            if ($mode eq 'clock') {

                return sprintf('%02d:%02d:%02d', $hour, $minute, $second);

            } elsif ($mode eq 'date') {

                return $self->ivIndex('customDayList', $dayOfWeek) . ' '
                        . $self->ivIndex('customMonthList', $month)
                        . " $dayOfMonth, $year";
            }
        }

        # Default - return full string
        return (
            sprintf('%02d:%02d:%02d, ', $hour, $minute, $second)
            . $self->ivIndex('customDayList', $dayOfWeek)
            . ' ' . $self->ivIndex('customMonthList', $month)
            . " $dayOfMonth, $year"
        );
    }

    sub trimWhitespace {

        # Can be called anything
        # Removes all whitespace at the beginning and end of a string
        #    e.g. '    You are here. He is there   <tab>'
        #    >>   'You are here. He is there.'
        # Optionally replaces space in the middle of the string with a single space character
        #   e.g. '   You are     here.   He          is there  <tab>'
        #   >>  'You are here. He is there.'
        #
        # Expected arguments
        #   $string - The string to trim
        #
        # Optional arguments
        #   $flag   - If set to TRUE, replaces space in the middle of the string; 'undef' otherwise
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the trimmed string

        my ($self, $string, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $string || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->trimWhitespace', @_);
        }

        # Trim whitespace from the beginning of the string
        $string =~ s/^\s+//;
        # Trim whitespace from the end of the string
        $string =~ s/\s+$//;

        if ($flag) {

            # Shorten whitespace in the middle of the string
            $string =~ s/\s+/ /g;
        }

        return $string;
    }

    sub convertVersion {

        # Converts an Axmud version (in the form 1.2.11) into a single integer number (in this case,
        #   1,002,011) so that version numbers can be compared
        # The string '1.2.11' is made up of three components. The first is converted into a number
        #   measured in millions, the second a number measured in thousands, the third is not
        #   converted
        # In this case, we have 1,000,000 + 2000 + 11 = 1002011
        # We assume that the 2nd and 3rd components aren't larger than 999
        #
        # Expected arguments
        #   $string    - An Axmud version string in the form 1.2.11 (possibly the value stored in
        #                   $axmud::VERSION)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, the converted string in the form of an integer number

        my ($self, $string, $check) = @_;

        # Local variables
        my (
            $number,
            @list,
        );

        # Check for improper arguments
        if (! defined $string || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->convertVersion', @_);
        }

        # Convert the string into its three components
        @list = split(/\./, $string);

        # Convert the components into a single number
        $number = ($list[0] * 1_000_000) + ($list[1] * 1_000) + $list[2];

        return $number;
    }

    sub convertRoman {

        # Converts an integer into Roman numerals (based on code from Text::Roman version by
        #   Stanislaw Pusep)
        #
        # Expected arguments
        #   $value      - Integer value between 1 and 3999
        #
        # Return values
        #   'undef' on improper arguments
        #   An empty string if $value is not an integer between 1 and 3999
        #   Otherwise returns the equivalent Roman numeral in upper-case letters, e.g. 'XII'

        my ($self, $value, $check) = @_;

        # Local variables
        my (
            $string,
            %reverseHash,
        );

        # Check for improper arguments
        if (! defined $value || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->convertRoman', @_);
        }

        # Check that $value is valid
        if (! $self->intCheck($value, 1, 3999)) {

            return '';
        }

        # Do the conversion
        %reverseHash = reverse $self->constRomanHash;
        for (reverse sort { $a <=> $b } $self->ivValues('constRomanHash')) {

            $string .= $reverseHash{$_} x int($value / $_);
            $value %= $_;
        }

        return $string;
    }

    sub splitText {

        # Splits a line of text into a specified number of rows separated by line break characters
        # Each line will be no longer than a specified number of characters, but words are not
        #   split (unless they're longer than the line)
        # Discards any extra text and optionally appends an ellipsis if doing so
        #
        # Expected arguments
        #   $line           - The line of text to split
        #   $rows           - The maximum number of rows. If 0, there is no maximum (and no text is
        #                       discarded)
        #   $columns        - The maximum number of columns per line (minimum 10)
        #
        # Optional arguments
        #   $ellipsisFlag   - If set to TRUE, an ellipsis is appended if any text is discarded.
        #                       If set to FALSE (or 'undef'), no ellipsis is appended
        #   $noHyphenFlag   - If set to TRUE, no hyphen is added at the end of a word which has
        #                       been split. If FALSE (or 'undef'), no hyphens are ever added
        #
        # Return values
        #   The unmodified value of $text on improper arguments, or if $rows and/or $columns are
        #       invalid values
        #   Otherwise, returns the modified string

        my ($self, $line, $rows, $columns, $ellipsisFlag, $hyphenFlag, $check) = @_;

        # Local variables
        my (
            $hyphen, $keep, $newLine,
            @array,
        );

        # Check for improper arguments
        if (! defined $line || ! defined $rows || ! defined $columns || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->splitText', @_);
            return $line;
        }

        # Check for valid values of $rows and $columns
        if (! $self->intCheck($rows, 0) || ! $self->intCheck($columns, 10)) {

            return $line;
        }

        # Use a hyphen, or not
        if (! $hyphenFlag) {
            $hyphen = '';
        } else {
            $hyphen = '-';
        }

        # Replace any existing newline characters with spaces
        $line =~ s/\n+/ /g;

        # Split the text into distinct lines
        do {

            my ($i, $gap);

            $i = 0;         # Search the text, character by character
            $keep = 0;      # If splitting on a forward slash, preserve it

            if (length($line) <= $columns) {

                # No need to split anything (and this is the final iteration)
                push(@array, $line);
                $line = '';

            } else {

                # The line is going to be split near character number $columns. Find the space (or
                #   tab, or forward slash) nearest to the end of the line
                OUTER: for ($i = $columns; $i > 0; $i--) {

                    my $char = substr($line, $i, 1);

                    if ($char eq " " || $char eq "\t") {

                        last OUTER;

                    } elsif ($char eq "/") {

                        $keep = 1;
                        last OUTER;
                    }
                }

                # A space (or tab or forward slash) was found. Split the line there
                if ($i > 1) {

                    push (@array, substr($line, 0, ($i + $keep)));
                    $line = substr($line, ($i + 1));

                # There is no space at which the line can be split. Split a word (using a hyphen, if
                #   allowed)
                } else {

                    push (@array, substr($line, 0, ($columns)) . $hyphen);
                    $line = substr($line, $columns);
                }
            }

        } until ($line eq '' || ($rows && (scalar @array) >= $rows));

        # Join the distinct lines together as a single string, with the lines separated by newline
        #   characters
        $newLine = join("\n", @array);
        # If we're discarding extra text, append an ellipsis (if allowed)
        if ($line && $ellipsisFlag) {

            $newLine .= '...';
        }

        return $newLine;
    }

    sub encodeJson {

        # Uses the JSON module to convert a Perl data structure to a UTF-8 encoded binary string
        #
        # Expected arguments
        #   $data       - The Perl data structure to encode
        #
        # Return values
        #   'undef' on improper arguments or if the conversion fails
        #   Otherwise returns the binary string

        my ($self, $data, $check) = @_;

        # Local variables
        my $obj;

        # Check for improper arguments
        if (! defined $data || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->encodeJson', @_);
        }

        $obj = JSON->new();
        $obj->allow_nonref();
        $obj->allow_unknown();
        $obj->space_before();
        $obj->space_after();

        return $obj->utf8->encode($data);
    }

    sub decodeJson {

        # Uses the JSON module to convert a UTF-8 encoded binary string to a Perl data structure
        #
        # Expected arguments
        #   $data     - The string to decode
        #
        # Return values
        #   'undef' on improper arguments, if $data is an empty string (or contains just space
        #       characters), or if the conversion fails
        #   Otherwise returns the Perl data structure

        my ($self, $data, $check) = @_;

        # Local variables
        my $obj;

        # Check for improper arguments
        if (! defined $data || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->decodeJson', @_);
        }

        # (Materia magica presents an ATCP/GMCP packet which produces a $data consisting of a single
        #   space character, so we need to check for that)
        if ($data eq '' || $data =~ m/^\s*$/) {

            return undef;
        }

        $obj = JSON->new();
        $obj->allow_nonref();
        $obj->allow_unknown();

        return $obj->utf8->decode($data);
    }

    sub benchMark {

        # Can be called by anything
        # Stores the current system time in $self->benchMarkTime
        # The subsequent call to $self->stopBenchMark calculates the time that has elapsed between
        #   the two function calls
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   1

        my ($self) = @_;

        # Local variables
        my ($secs, $micros);

        # (No improper arguments check for speed)

        # Store the system time to 3dp
        ($secs, $micros) = Time::HiRes::gettimeofday();
        $self->{benchMarkTime} = ($secs * 1000000) + $micros;

        return 1;
    }

    sub stopBenchMark {

        # Can be called by anything
        # Works out the time (in microseconds) that has elapsed since the previous call to
        #   $self->benchMark, and writes it to the terminal, updating averaging IVs at the same time
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   1

        my ($self) = @_;

        # Local variable
        my ($secs, $micros, $time, $count, $total, $average, $count2, $total2, $average2);

        # (No improper arguments check for speed)

        if (! $self->{benchMarkTime}) {

            # Bad call
            return 1;
        }

        # Get the system time to 3dp
        ($secs, $micros) = Time::HiRes::gettimeofday();
        $time = ($secs * 1000000) + $micros - $self->{benchMarkTime};

        # Calculate average of the short list
        $self->ivPush('benchMarkShortList', $time);
        $count = $self->ivNumber('benchMarkShortList');
        if ($count >= 10) {

            $self->ivShift('benchMarkShortList');
            $count--;
        }

        $total = 0;
        foreach my $time ($self->benchMarkShortList) {

            $total += $time;
        }

        $average = int($total / $count);

        # Calculate average of the long list
        $self->ivPush('benchMarkLongList', $time);
        $count2 = $self->ivNumber('benchMarkLongList');
        if ($count2 >= 100) {

            $self->ivShift('benchMarkLongList');
            $count2--;
        }

        $total2 = 0;
        foreach my $time ($self->benchMarkLongList) {

            $total2 += $time;
        }

        $average2 = int($total2 / $count2);

        print "BENCHMARK: time $time, recent $average, average $average2\n";

        return 1;
    }

    ##################
    # Accessors - set

    sub set_aboutWin {

        my ($self, $winObj, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_aboutWin', @_);
        }

        # Update IVs
        $self->ivPoke('aboutWin', $winObj);

        return 1;
    }

    sub set_activateGridFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_activateGridFlag',
                @_,
            );
        }

        if ($flag) {
            $self->ivPoke('activateGridFlag', TRUE);
        } else {
            $self->ivPoke('activateGridFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_activateGridFlag');

        return 1;
    }

    sub add_activeKeycode {

        my ($self, $keycode, $check) = @_;

        # Check for improper arguments
        if (! defined $keycode || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_activeKeycode', @_);
        }

        $self->ivAdd('activeKeycodeHash', $keycode, undef);

        return 1;
    }

    sub reset_activeKeycodes {

        my ($self, $check) = @_;

        # Local variables
        my %hash;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_activeKeycodes', @_);
        }

        OUTER: foreach my $session ($self->listSessions()) {

            INNER: foreach my $keycode ($session->ivValues('macroHash')) {

                $hash{$keycode} = undef;
            }
        }

        $self->ivPoke('activeKeycodeHash', %hash);
        $self->ivPoke('resetKeycodesFlag', FALSE);

        return 1;
    }

    sub set_allowAsciiBellFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_allowAsciiBellFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('allowAsciiBellFlag', TRUE);
        } else {
            $self->ivPoke('allowAsciiBellFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_allowAsciiBellFlag');

        return 1;
    }

    sub set_allowBusyWinFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_allowBusyWinFlag',
                @_,
            );
        }

        if ($flag) {
            $self->ivPoke('allowBusyWinFlag', TRUE);
        } else {
            $self->ivPoke('allowBusyWinFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_allowBusyWinFlag');

        return 1;
    }

    sub set_allowModelSplitFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_allowModelSplitFlag',
                @_,
            );
        }

        if ($flag) {
            $self->ivPoke('allowModelSplitFlag', TRUE);
        } else {
            $self->ivPoke('allowModelSplitFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_allowModelSplitFlag');

        return 1;
    }

    sub set_allowMxpFlag {

        my ($self, $type, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_allowMxpFlag', @_);
        }

        if (! $flag) {
            $flag = FALSE;
        } else {
            $flag = TRUE;
        }

        if ($type eq 'font') {
            $self->ivPoke('allowMxpFontFlag', $flag);
        } elsif ($type eq 'image') {
            $self->ivPoke('allowMxpImageFlag', $flag);
        } elsif ($type eq 'load_image') {
            $self->ivPoke('allowMxpLoadImageFlag', $flag);
        } elsif ($type eq 'filter_image') {
            $self->ivPoke('allowMxpFilterImageFlag', $flag);
        } elsif ($type eq 'sound') {
            $self->ivPoke('allowMxpSoundFlag', $flag);
        } elsif ($type eq 'load_sound') {
            $self->ivPoke('allowMxpLoadSoundFlag', $flag);
        } elsif ($type eq 'gauge') {
            $self->ivPoke('allowMxpGaugeFlag', $flag);
        } elsif ($type eq 'frame') {
            $self->ivPoke('allowMxpFrameFlag', $flag);
        } elsif ($type eq 'interior') {
            $self->ivPoke('allowMxpInteriorFlag', $flag);
        } elsif ($type eq 'crosslink') {
            $self->ivPoke('allowMxpCrosslinkFlag', $flag);
        } elsif ($type eq 'room') {
            $self->ivPoke('allowMxpRoomFlag', $flag);
        } elsif ($type eq 'flexible') {
            $self->ivPoke('allowMxpFlexibleFlag', $flag);
        } elsif ($type eq 'perm') {
            $self->ivPoke('allowMxpPermFlag', $flag);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_allowMxpFlag');

        # Any sessions which are connected to a world, and which are using MXP, should re-issue
        #   their <SUPPORTS> tag (this isn't part of the MXP spec, but it can't do any damage; the
        #   world will either implement an unsolicited <SUPPORTS> tag, or it won't)
        if (! $self->mxpPreventSupportFlag && $type ne 'room') {

            foreach my $session ($self->ivValues('sessionHash')) {

                if ($session->status eq 'connected' && $session->mxpMode eq 'client_agree') {

                    # Process a fake <SUPPORT> tag, as if the world had sent one
                    $session->processMxpSupportElement('<SUPPORT>', 0, 'SUPPORT');
                }
            }
        }

        return 1;
    }

    sub set_allowSoundFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_allowSoundFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('allowSoundFlag', TRUE);
        } else {
            $self->ivPoke('allowSoundFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_allowSoundFlag');

        # Any sessions which are connected to a world, and which are using MXP, should re-issue
        #   their <SUPPORTS> tag (this isn't part of the MXP spec, but it can't do any damage; the
        #   world will either implement an unsolicited <SUPPORTS> tag, or it won't)
        foreach my $session ($self->ivValues('sessionHash')) {

            if ($session->status eq 'connected' && $session->mxpMode eq 'client_agree') {

                # Process a fake <SUPPORT> tag, as if the world had sent one
                $session->processMxpSupportElement('<SUPPORT>', 0, 'SUPPORT');
            }
        }

        return 1;
    }

    sub set_audioCmd {

        my ($self, $cmd, $check) = @_;

        # Check for improper arguments
        if (! defined $cmd || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_audioCmd', @_);
        }

        $self->ivPoke('audioCmd', $cmd);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_audioCmd');

        return 1;
    }

    sub set_autoCompleteMode {

        my ($self, $mode, $check) = @_;

        # Check for improper arguments
        if (! defined $mode || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_autoCompleteMode', @_);
        }

        # Update IVs
        $self->ivPoke('autoCompleteMode', $mode);
        $self->ivUndef('instructBufferPosn');
        $self->ivUndef('cmdBufferPosn');

        foreach my $session ($self->listSessions()) {

            $session->set_instructBufferPosn();
            $session->set_cmdBufferPosn();
        }

        foreach my $winObj ($self->desktopObj->ivValues('gridWinHash')) {

            $winObj->resetEntry();
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_autoCompleteMode');

        return 1;
    }

    sub set_autoCompleteParent {

        my ($self, $parent, $check) = @_;

        # Check for improper arguments
        if (! defined $parent || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_autoCompleteParent', @_);
        }

        # Update IVs
        if ($parent eq 'client') {
            $self->ivPoke('autoCompleteParent', 'combined');
        } else {
            $self->ivPoke('autoCompleteParent', 'session');       # Initial value
        }

        $self->ivUndef('instructBufferPosn');
        $self->ivUndef('cmdBufferPosn');

        foreach my $session ($self->listSessions()) {

            $session->set_instructBufferPosn();
            $session->set_cmdBufferPosn();
        }

        foreach my $winObj ($self->desktopObj->ivValues('gridWinHash')) {

            $winObj->resetEntry();
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_autoCompleteParent');

        return 1;
    }

    sub set_autoCompleteType {

        my ($self, $type, $check) = @_;

        # Check for improper arguments
        if (! defined $type || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_autoCompleteType', @_);
        }

        # Update IVs
        if ($type eq 'instruct') {
            $self->ivPoke('autoCompleteType', 'instruct');
        } else {
            $self->ivPoke('autoCompleteType', 'cmd');           # Initial value
        }

        $self->ivUndef('instructBufferPosn');
        $self->ivUndef('cmdBufferPosn');

        foreach my $session ($self->listSessions()) {

            $session->set_instructBufferPosn();
            $session->set_cmdBufferPosn();
        }

        foreach my $winObj ($self->desktopObj->ivValues('gridWinHash')) {

            $winObj->resetEntry();
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_autoCompleteType');

        return 1;
    }

    sub set_autoConnectList {

        my ($self, @args) = @_;

        # (No improper arguments to check; @args can be an empty list)

        $self->ivPoke('autoConnectList', @args);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_autoConnectList');

        return 1;
    }

    sub set_autoRetainFileFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_autoRetainFileFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('autoRetainFileFlag', TRUE);
        } else {
            $self->ivPoke('autoRetainFileFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_autoRetainFileFlag');

        return 1;
    }

    sub set_autoSaveFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_autoSaveFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('autoSaveFlag', TRUE);
        } else {
            $self->ivPoke('autoSaveFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_autoSaveFlag');

        return 1;
    }

    sub set_autoSaveWaitTime {

        my ($self, $time, $check) = @_;

        # Check for improper arguments
        if (! defined $time || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_autoSaveWaitTime', @_);
        }

        $self->ivPoke('autoSaveWaitTime', $time);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_autoSaveWaitTime');

        return 1;
    }

    sub set_autoBackupAppendFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_autoBackupAppendFlag',
                @_,
            );
        }

        if ($flag) {
            $self->ivPoke('autoBackupAppendFlag', TRUE);
        } else {
            $self->ivPoke('autoBackupAppendFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_autoBackupAppendFlag');

        return 1;
    }

    sub set_autoBackupDir {

        my ($self, $dir, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_autoBackupDir', @_);
        }

        $self->ivPoke('autoBackupDir', $dir);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_autoBackupDir');

        return 1;
    }

    sub set_autoBackupFileType {

        my ($self, $type, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $type
            || ($type ne 'default' && $type ne 'tar' && $type ne 'zip')
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_autoBackupFileType', @_);
        }

        $self->ivPoke('autoBackupFileType', $type);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_autoBackupFileType');

        return 1;
    }

    sub set_autoBackupInterval {

        my ($self, $number, $check) = @_;

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_autoBackupInterval', @_);
        }

        $self->ivPoke('autoBackupInterval', $number);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_autoBackupInterval');

        return 1;
    }

    sub set_autoBackupMode {

        my ($self, $mode, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $mode
            || (
                $mode ne 'no_backup' && $mode ne 'all_start' && $mode ne 'all_stop'
                && $mode ne 'interval_start' && $mode ne 'interval_stop'
            ) || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_autoBackupMode', @_);
        }

        $self->ivPoke('autoBackupMode', $mode);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_autoBackupMode');

        return 1;
    }

    sub set_blockWorldHintFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_blockWorldHintFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('blockWorldHintFlag', TRUE);
        } else {
            $self->ivPoke('blockWorldHintFlag', FALSE);
        }

        return 1;
    }

    sub set_browserCmd {

        my ($self, $cmd, $check) = @_;

        # Check for improper arguments
        if (! defined $cmd || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_browserCmd', @_);
        }

        $self->ivPoke('browserCmd', $cmd);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_browserCmd');

        return 1;
    }

    sub set_busyWin {

        my ($self, $winObj, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_busyWin', @_);
        }

        # Update IVs
        $self->ivPoke('busyWin', $winObj);

        return 1;
    }

    sub set_chatAcceptMode {

        my ($self, $mode, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $mode
            || ($mode ne 'prompt' && $mode ne 'accept_contact' && $mode ne 'accept_all')
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_chatAcceptMode', @_);
        }

        $self->ivPoke('chatAcceptMode', $mode);

        # The data stored in this IV is saved in the 'contacts' file
        $self->setModifyFlag('contacts', TRUE, $self->_objClass . '->set_chatAcceptMode');

        return 1;
    }

    sub add_chatContact {

        my ($self, $name, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $name || ! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_chatContact', @_);
        }

        $self->ivAdd('chatContactHash', $name, $obj);

        # The data stored in this IV is saved in the 'contacts' file
        $self->setModifyFlag('contacts', TRUE, $self->_objClass . '->add_chatContact');

        return 1;
    }

    sub del_chatContact {

        my ($self, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_chatContact', @_);
        }

        $self->ivDelete('chatContactHash', $name);

        # The data stored in this IV is saved in the 'contacts' file
        $self->setModifyFlag('contacts', TRUE, $self->_objClass . '->del_chatContact');

        return 1;
    }

    sub set_charSet {

        # This function should only be called by GA::Cmd::SetCharSet->do

        my ($self, $charSet, $check) = @_;

        # Check for improper arguments
        if (! defined $charSet || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_charSet', @_);
        }

        $self->ivPoke('charSet', $charSet);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_charSet');

        return 1;
    }

    sub set_chatEmail {

        my ($self, $email, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_chatEmail', @_);
        }

        $self->ivPoke('chatEmail', $email);       # Can be 'undef'

        # The data stored in this IV is saved in the 'contacts' file
        $self->setModifyFlag('contacts', TRUE, $self->_objClass . '->set_chatEmail');

        return 1;
    }

    sub set_chatIcon {

        my ($self, $path, $check) = @_;

        # Check for improper arguments
        if (! defined $path || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_chatIcon', @_);
        }

        $self->ivPoke('chatIcon', $path);       # Can't be 'undef'

        # The data stored in this IV is saved in the 'contacts' file
        $self->setModifyFlag('contacts', TRUE, $self->_objClass . '->set_chatIcon');

        return 1;
    }

    sub set_chatName {

        my ($self, $name, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_chatName', @_);
        }

        $self->ivPoke('chatName', $name);       # Can be 'undef'

        # The data stored in this IV is saved in the 'contacts' file
        $self->setModifyFlag('contacts', TRUE, $self->_objClass . '->set_chatName');

        return 1;
    }

    sub add_chatSmiley {

        my ($self, $smiley, $path, $check) = @_;

        # Check for improper arguments
        if (! defined $smiley || ! defined $path || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_chatSmiley', @_);
        }

        $self->ivAdd('chatSmileyHash', $smiley, $path);

        # The data stored in this IV is saved in the 'contacts' file
        $self->setModifyFlag('contacts', TRUE, $self->_objClass . '->add_chatSmiley');

        return 1;
    }

    sub del_chatSmiley {

        my ($self, $smiley, $check) = @_;

        # Check for improper arguments
        if (! defined $smiley || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_chatSmiley', @_);
        }

        $self->ivDelete('chatSmileyHash', $smiley);

        # The data stored in this IV is saved in the 'contacts' file
        $self->setModifyFlag('contacts', TRUE, $self->_objClass . '->del_chatSmiley');

        return 1;
    }

    sub set_chatSmileyHash {

        my ($self, %hash) = @_;

        # (Don't check for improper arguments - %hash can be empty)

        $self->ivPoke('chatSmileyHash', %hash);

        # The data stored in these IVs is saved in the 'contacts' file
        $self->setModifyFlag('contacts', TRUE, $self->_objClass . '->set_chatSmileyHash');

        return 1;
    }

    sub set_cmdBufferPosn {

        my ($self, $posn, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_cmdBufferPosn', @_);
        }

        # Update IVs
        $self->ivPoke('cmdBufferPosn', $posn);

        return 1;
    }

    sub set_cmdSep {

        my ($self, $string, $check) = @_;

        # Check for improper arguments
        if (! defined $string || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_cmdSep', @_);
        }

        $self->ivPoke('cmdSep', $string);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_cmdSep');

        return 1;
    }

    sub add_colourScheme {

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_colourScheme', @_);
        }

        # Update IVs
        $self->ivAdd('colourSchemeHash', $obj->name, $obj);

        # The data stored in this IV is saved in the 'winmaps' file
        $self->setModifyFlag('winmaps', TRUE, $self->_objClass . '->add_colourScheme');

        return 1;
    }

    sub del_colourScheme {

        my ($self, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_colourScheme', @_);
        }

        # Update IVs
        $self->ivDelete('colourSchemeHash', $name);

        # The data stored in this IV is saved in the 'winmaps' file
        $self->setModifyFlag('winmaps', TRUE, $self->_objClass . '->del_colourScheme');

        return 1;
    }

    sub set_commifyMode {

        my ($self, $mode, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $mode
            || (
                $mode ne 'comma' && $mode ne 'europe' && $mode ne 'brit' && $mode ne 'underline'
                && $mode ne 'none'
            )
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_commifyMode', @_);
        }

        $self->ivPoke('commifyMode', $mode);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_commifyMode');

        return 1;
    }

    sub set_configWorldProfList {

        my ($self, @list) = @_;

        # (No improper arguments to check)

        $self->ivPoke('configWorldProfList', @list);

        return 1;
    }

    sub set_connectHistoryFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_connectHistoryFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('connectHistoryFlag', TRUE);
        } else {
            $self->ivPoke('connectHistoryFlag', FALSE);
        }

        return 1;
    }

    sub set_connectWin {

        my ($self, $winObj, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_connectWin', @_);
        }

        # Update IVs
        $self->ivPoke('connectWin', $winObj);

        return 1;
    }

    sub set_consoleWin {

        my ($self, $winObj, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_consoleWin', @_);
        }

        # Update IVs
        $self->ivPoke('consoleWin', $winObj);

        return 1;
    }

    sub set_currentColourCube {

        my ($self, $cube, $check) = @_;

        # Check for improper arguments
        if (! defined $cube || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_currentColourCube', @_);
        }

        $self->ivPoke('currentColourCube', $cube);
        if ($cube eq 'netscape') {

            $self->ivPoke('xTermColourHash', $self->constNetscapeColourHash);

        } else {

            # Default
            $self->ivPoke('xTermColourHash', $self->constXTermColourHash);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_currentColourCube');

        return 1;
    }

    sub set_customAllowTTSFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_customAllowTTSFlag', @_);
        }

        if ($flag) {

            $self->ivPoke('customAllowTTSFlag', TRUE);
            $self->ivPoke('systemAllowTTSFlag', TRUE);

        } else {

            $self->ivPoke('customAllowTTSFlag', FALSE);
            if (! $axmud::BLIND_MODE_FLAG) {
                $self->ivPoke('systemAllowTTSFlag', FALSE);
            } else {
                $self->ivPoke('systemAllowTTSFlag', TRUE);
            }
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_customAllowTTSFlag');

        return 1;
    }

    sub set_customClientName {

        my ($self, $name, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_customClientName', @_);
        }

        if ($name) {
            $self->ivPoke('customClientName', $name);
        } else {
            $self->ivPoke('customClientName', '');
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_customClientName');

        return 1;
    }

    sub set_customClientVersion {

        my ($self, $version, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_customClientVersion',
                @_,
            );
        }

        if ($version) {
            $self->ivPoke('customClientVersion', $version);
        } else {
            $self->ivPoke('customClientVersion', '');
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_customClientVersion');

        return 1;
    }

    sub set_customInsertCmdColour {

        my ($self, $value, $check) = @_;

        # Check for improper arguments
        if (! defined $value || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_customInsertCmdColour',
                @_,
            );
        }

        $self->ivPoke('customInsertCmdColour', $value);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_customInsertCmdColour');

        return 1;
    }

    sub set_convertInvisibleFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_convertInvisibleFlag',
                @_,
            );
        }

        if ($flag) {
            $self->ivPoke('convertInvisibleFlag', TRUE);
        } else {
            $self->ivPoke('convertInvisibleFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_convertInvisibleFlag');

        return 1;
    }

    sub set_customCmdBufferSize {

        my ($self, $size, $check) = @_;

        # Check for improper arguments
        if (! defined $size || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_customCmdBufferSize',
                @_,
            );
        }

        $self->ivPoke('customCmdBufferSize', $size);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_customCmdBufferSize');

        return 1;
    }

    sub set_customControlsSize {

        my ($self, $type, $value, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $type
            || ($type ne 'left' && $type ne 'right' && $type ne 'top' && $type ne 'bottom')
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_customControlsSize',
                @_,
            );
        }

        # $value can be 'undef'
        $self->ivPoke('customControls' . ucfirst($type) . 'Size', $value);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_customControlsSize');

        return 1;
    }

    sub set_customDayList {

        my ($self, @list) = @_;

        # Check for improper arguments
        if (! @list || (scalar @list) < 7) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_customDayList', @_);
        }

        $self->ivPoke('customDayList', @list);

        # The data stored in these IVs are saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_customDayList');

        return 1;
    }

    sub reset_customDayList {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_customDayList', @_);
        }

        $self->ivPoke('customDayList', $self->constDayList);

        # The data stored in these IVs are saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->reset_customDayList');

        return 1;
    }

    sub set_customDisplayBufferSize {

        my ($self, $size, $check) = @_;

        # Check for improper arguments
        if (! defined $size || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_customDisplayBufferSize',
                @_,
            );
        }

        $self->ivPoke('customDisplayBufferSize', $size);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_customDisplayBufferSize');

        return 1;
    }

    sub set_customFreeWinSize {

        my ($self, $width, $height, $check) = @_;

        # Check for improper arguments
        if (! defined $width || ! defined $height || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_customFreeWinSize', @_);
        }

        $self->ivPoke('customFreeWinWidth', $width);
        $self->ivPoke('customFreeWinHeight', $height);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_customFreeWinSize');

        return 1;
    }

    sub set_customGridWinSize {

        my ($self, $width, $height, $check) = @_;

        # Check for improper arguments
        if (! defined $width || ! defined $height || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_customGridWinSize', @_);
        }

        $self->ivPoke('customGridWinWidth', $width);
        $self->ivPoke('customGridWinHeight', $height);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_customGridWinSize');

        return 1;
    }

    sub set_customInstructBufferSize {

        my ($self, $size, $check) = @_;

        # Check for improper arguments
        if (! defined $size || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_customInstructBufferSize',
                @_,
            );
        }

        $self->ivPoke('customInstructBufferSize', $size);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_customInstructBufferSize');

        return 1;
    }

    sub set_customMainWinSize {

        my ($self, $width, $height, $check) = @_;

        # Check for improper arguments
        if (! defined $width || ! defined $height || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_customMainWinSize', @_);
        }

        $self->ivPoke('customMainWinWidth', $width);
        $self->ivPoke('customMainWinHeight', $height);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_customMainWinSize');

        return 1;
    }

    sub set_customMonthList {

        my ($self, @list) = @_;

        # Check for improper arguments
        if (! @list || (scalar @list) < 12) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_customMonthList', @_);
        }

        $self->ivPoke('customMonthList', @list);

        # The data stored in these IVs are saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_customMonthList');

        return 1;
    }

    sub reset_customMonthList {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_customMonthList', @_);
        }

        $self->ivPoke('customMonthList', $self->constMonthList);

        # The data stored in these IVs are saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->reset_customMonthList');

        return 1;
    }

    sub set_customPanelSize {

        my ($self, $type, $value, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $type
            || ($type ne 'left' && $type ne 'right' && $type ne 'top' && $type ne 'bottom')
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_customPanelSize',
                @_,
            );
        }

        # $value can be 'undef'
        $self->ivPoke('customPanel' . ucfirst($type) . 'Size', $value);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_customPanelSize');

        return 1;
    }

    sub set_customShowDebugColour {

        my ($self, $value, $check) = @_;

        # Check for improper arguments
        if (! defined $value || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_customShowDebugColour',
                @_,
            );
        }

        $self->ivPoke('customShowDebugColour', $value);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->customShowDebugColour');

        return 1;
    }

    sub set_customShowErrorColour {

        my ($self, $value, $check) = @_;

        # Check for improper arguments
        if (! defined $value || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_customShowErrorColour',
                @_,
            );
        }

        $self->ivPoke('customShowErrorColour', $value);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_customShowErrorColour');

        return 1;
    }

    sub set_customShowImproperColour {

        my ($self, $value, $check) = @_;

        # Check for improper arguments
        if (! defined $value || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_customShowImproperColour',
                @_,
            );
        }

        $self->ivPoke('customShowImproperColour', $value);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_customShowImproperColour');

        return 1;
    }

    sub set_customShowSystemTextColour {

        my ($self, $value, $check) = @_;

        # Check for improper arguments
        if (! defined $value || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_customShowSystemTextColour',
                @_,
            );
        }

        $self->ivPoke('customShowSystemTextColour', $value);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_customShowSystemTextColour');

        return 1;
    }

    sub set_customShowWarningColour {

        my ($self, $value, $check) = @_;

        # Check for improper arguments
        if (! defined $value || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_customShowWarningColour',
                @_,
            );
        }

        $self->ivPoke('customShowWarningColour', $value);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_customShowWarningColour');

        return 1;
    }

    sub reset_customSoundHash {

        my ($self, $check) = @_;

        # Local variables
        my %soundHash;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_customSoundHash', @_);
        }

        foreach my $effect ($self->ivKeys('constExtendedSoundHash')) {

            # Values in ->constExtendedSoundHash are file names; values in ->customSoundHash should
            #   be full file paths
            $soundHash{$effect}
                = $axmud::DATA_DIR . '/sounds/' . $self->ivShow('constExtendedSoundHash', $effect);
        }

        $self->ivPoke('customSoundHash', %soundHash);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->reset_customSoundHash');

        return 1;
    }

    sub add_customTask {

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_customTask', @_);
        }

        # Update IVs
        $self->ivAdd('customTaskHash', $obj->customName, $obj);

        # The data stored in this IV is saved in the 'tasks' file
        $self->setModifyFlag('tasks', TRUE, $self->_objClass . '->add_customTask');

        return 1;
    }

    sub del_customTask {

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_customTask', @_);
        }

        # Update IVs
        $self->ivDelete('customTaskHash', $obj->customName);

        # The data stored in this IV is saved in the 'tasks' file
        $self->setModifyFlag('tasks', TRUE, $self->_objClass . '->del_customTask');

        return 1;
    }

    sub reset_customTaskHash {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_customTaskHash', @_);
        }

        $self->ivEmpty('customTaskHash');

        # The data stored in these IVs is saved in the 'tasks' file
        $self->setModifyFlag('tasks', TRUE, $self->_objClass . '->reset_customTaskHash');

        return 1;
    }

    sub set_customTextBufferSize {

        my ($self, $size, $check) = @_;

        # Check for improper arguments
        if (! defined $size || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_customTextBufferSize',
                @_,
            );
        }

        $self->ivPoke('customTextBufferSize', $size);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_customTextBufferSize');

        return 1;
    }

    sub set_debugFlag {

        my ($self, $iv, $flag, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $iv
            || (
                # Main debug flags
                $iv ne 'debugLineNumsFlag'
                && $iv ne 'debugLineTagsFlag'
                && $iv ne 'debugLocatorFlag'
                && $iv ne 'debugMaxLocatorFlag'
                && $iv ne 'debugExitFlag'
                && $iv ne 'debugMoveListFlag'
                && $iv ne 'debugParseObjFlag'
                && $iv ne 'debugCompareObjFlag'
                && $iv ne 'debugExplainPluginFlag'
                && $iv ne 'debugCheckIVFlag'
                && $iv ne 'debugTableFitFlag'
                && $iv ne 'debugTrapErrorFlag'
                # Telnet negotiation debug flags
                && $iv ne 'debugEscSequenceFlag'
                && $iv ne 'debugTelnetFlag'
                && $iv ne 'debugTelnetMiniFlag'
                && $iv ne 'debugTelnetLogFlag'
                && $iv ne 'debugMsdpFlag'
                && $iv ne 'debugMxpFlag'
                && $iv ne 'debugMxpCommentFlag'
                && $iv ne 'debugPuebloFlag'
                && $iv ne 'debugPuebloCommentFlag'
                && $iv ne 'debugZmpFlag'
                && $iv ne 'debugAtcpFlag'
                && $iv ne 'debugGmcpFlag'
                && $iv ne 'debugMcpFlag'
            )
            || ! defined $flag
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_debugFlag', @_);
        }

        if ($flag) {
            $self->ivPoke($iv, TRUE);
        } else {
            $self->ivPoke($iv, FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_debugFlag');

        return 1;
    }

    sub toggle_debugFlag {

        my ($self, $iv, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $iv
            || (
                # Main debug flags
                $iv ne 'debugLineNumsFlag'
                && $iv ne 'debugLineTagsFlag'
                && $iv ne 'debugLocatorFlag'
                && $iv ne 'debugMaxLocatorFlag'
                && $iv ne 'debugExitFlag'
                && $iv ne 'debugMoveListFlag'
                && $iv ne 'debugParseObjFlag'
                && $iv ne 'debugCompareObjFlag'
                && $iv ne 'debugExplainPluginFlag'
                && $iv ne 'debugCheckIVFlag'
                && $iv ne 'debugTableFitFlag'
                && $iv ne 'debugTrapErrorFlag'
                # Telnet negotiation debug flags
                && $iv ne 'debugEscSequenceFlag'
                && $iv ne 'debugTelnetFlag'
                && $iv ne 'debugTelnetMiniFlag'
                && $iv ne 'debugTelnetLogFlag'
                && $iv ne 'debugMsdpFlag'
                && $iv ne 'debugMxpFlag'
                && $iv ne 'debugMxpCommentFlag'
                && $iv ne 'debugPuebloFlag'
                && $iv ne 'debugPuebloCommentFlag'
                && $iv ne 'debugZmpFlag'
                && $iv ne 'debugAtcpFlag'
                && $iv ne 'debugGmcpFlag'
                && $iv ne 'debugMcpFlag'
            ) || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggle_debugFlag', @_);
        }

        # Special case - disabling ->debugLocatorFlag also disables ->debugMaxLocatorFlag
        if (
            $iv eq 'debugLocatorFlag'
            && $self->debugLocatorFlag
        ) {
            $self->ivPoke($iv, FALSE);
            $self->ivPoke('debugMaxLocatorFlag', FALSE);

        } else {

            if (! $self->$iv) {
                $self->ivPoke($iv, TRUE);
            } else {
                $self->ivPoke($iv, FALSE);
            }
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->toggle_debugFlag');

        return 1;
    }

    sub set_defaultDisabledWinmap {

        my ($self, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_defaultDisabledWinmap',
                @_,
            );
        }

        $self->ivPoke('defaultDisabledWinmap', $name);

        # The data stored in this IV is saved in the 'winmaps' file
        $self->setModifyFlag('winmaps', TRUE, $self->_objClass . '->set_defaultDisabledWinmap');

        return 1;
    }

    sub set_defaultEnabledWinmap {

        my ($self, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_defaultEnabledWinmap',
                @_,
            );
        }

        $self->ivPoke('defaultEnabledWinmap', $name);

        # The data stored in this IV is saved in the 'winmaps' file
        $self->setModifyFlag('winmaps', TRUE, $self->_objClass . '->set_defaultEnabledWinmap');

        return 1;
    }

    sub set_defaultInternalWinmap {

        my ($self, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_defaultInternalWinmap',
                @_,
            );
        }

        $self->ivPoke('defaultInternalWinmap', $name);

        # The data stored in this IV is saved in the 'winmaps' file
        $self->setModifyFlag('winmaps', TRUE, $self->_objClass . '->set_defaultInternalWinmap');

        return 1;
    }

    sub add_dict {

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_dict', @_);
        }

        $self->ivAdd('dictHash', $obj->name, $obj);

        # The data stored in this IV is saved in the 'dicts' file
        $self->setModifyFlag('dicts', TRUE, $self->_objClass . '->add_dict');

        return 1;
    }

    sub del_dict {

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_dict', @_);
        }

        $self->ivDelete('dictHash', $obj->name);

        # The data stored in this IV is saved in the 'dicts' file
        $self->setModifyFlag('dicts', TRUE, $self->_objClass . '->del_dict');

        return 1;
    }

    sub set_dictHash {

        my ($self, %hash) = @_;

        # (No improper arguments to check - %hash can be empty)

        $self->ivPoke('dictHash', %hash);

        # The data stored in this IV is saved in the 'dicts' file
        $self->setModifyFlag('dicts', TRUE, $self->_objClass . '->set_dictHash');

        return 1;
    }

    sub set_emailCmd {

        my ($self, $cmd, $check) = @_;

        # Check for improper arguments
        if (! defined $cmd || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_emailCmd', @_);
        }

        $self->ivPoke('emailCmd', $cmd);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_emailCmd');

        return 1;
    }

    sub set_favouriteWorldList {

        my ($self, @args) = @_;

        # (No improper arguments to check; @args can be an empty list)

        $self->ivPoke('favouriteWorldList', @args);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_favouriteWorldList');

        return 1;
    }

    sub set_fileFailFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_fileFailFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('fileFailFlag', TRUE);
        } else {
            $self->ivPoke('fileFailFlag', FALSE);
        }

        return 1;
    }

    sub add_fileObj {

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_fileObj', @_);
        }

        $self->ivAdd('fileObjHash', $obj->name, $obj);

        return 1;
    }

    sub del_fileObj {

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_fileObj', @_);
        }

        $self->ivDelete('fileObjHash', $obj->name);

        return 1;
    }

    sub set_gridAdjustmentFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_gridAdjustmentFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('gridAdjustmentFlag', TRUE);
        } else {
            $self->ivPoke('gridAdjustmentFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_gridAdjustmentFlag');

        return 1;
    }

    sub set_gridBlockSize {

        my ($self, $size, $check) = @_;

        # Check for improper arguments
        if (! defined $size || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_gridBlockSize', @_);
        }

        $self->ivPoke('gridBlockSize', $size);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_gridBlockSize');

        return 1;
    }

    sub set_gridEdgeCorrectionFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_gridEdgeCorrectionFlag',
                @_,
            );
        }

        if ($flag) {
            $self->ivPoke('gridEdgeCorrectionFlag', TRUE);
        } else {
            $self->ivPoke('gridEdgeCorrectionFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_gridEdgeCorrectionFlag');

        return 1;
    }

    sub set_gridGapMaxSize {

        my ($self, $size, $check) = @_;

        # Check for improper arguments
        if (! defined $size || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_gridGapMaxSize', @_);
        }

        $self->ivPoke('gridGapMaxSize', $size);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_gridGapMaxSize');

        return 1;
    }

    sub set_gridInvisWinFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_gridInvisWinFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('gridInvisWinFlag', TRUE);
        } else {
            $self->ivPoke('gridInvisWinFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_gridInvisWinFlag');

        return 1;
    }

    sub set_gridReshuffleFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_gridReshuffleFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('gridReshuffleFlag', TRUE);
        } else {
            $self->ivPoke('gridReshuffleFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_gridReshuffleFlag');

        return 1;
    }

    sub add_initPlugin {

        my ($self, $pluginPath, $check) = @_;

        # Check for improper arguments
        if (! defined $pluginPath || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_initPlugin', @_);
        }

        $self->ivPush('initPluginList', $pluginPath);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->add_initPlugin');

        return 1;
    }

    sub del_initPlugin {

        my ($self, $index, $check) = @_;

        # Check for improper arguments
        if (! defined $index || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_initPlugin', @_);
        }

        if ($self->initPluginList && $index < (scalar $self->initPluginList)) {

            $self->ivSplice('initPluginList', $index, 1);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->del_initPlugin');

        return 1;
    }

    sub add_initScript {

        my ($self, $scriptName, $mode, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $scriptName
            || ! defined $mode
            || ($mode ne 'no_task' && $mode ne 'run_task' && $mode ne 'run_task_win')
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_initScript', @_);
        }

        # See if the script already exists in the initial scriptlist
        if (! defined $self->ivFind('initScriptOrderList', $scriptName)) {

            # Not there, so add it
            $self->ivPush('initScriptOrderList', $scriptName);
        }

        # In either case, update the hash (replacing any previous entry)
        $self->ivAdd('initScriptHash', $scriptName, $mode);

        # The data stored in this IV is saved in the 'scripts' file
        $self->setModifyFlag('scripts', TRUE, $self->_objClass . '->add_initScript');

        return 1;
    }

    sub del_initScript {

        my ($self, $scriptName, $check) = @_;

        # Local variables
        my $index;

        # Check for improper arguments
        if (! defined $scriptName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_initScript', @_);
        }

        # Update IVs
        $self->ivDelete('initScriptHash', $scriptName);
        $index = $self->ivFind('initScriptOrderList', $scriptName);
        if (defined $index) {

            $self->ivSplice('initScriptOrderList', $index, 1);
        }

        # The data stored in this IV is saved in the 'scripts' file
        $self->setModifyFlag('scripts', TRUE, $self->_objClass . '->del_initScript');

        return 1;
    }

    sub set_initScriptOrderList {

        my ($self, @args) = @_;

        # (No improper arguments to check; @args can be an empty list)

        $self->ivPoke('initScriptOrderList', @args);

        # The data stored in this IV is saved in the 'scripts' file
        $self->setModifyFlag('scripts', TRUE, $self->_objClass . '->set_initScriptOrderList');

        return 1;
    }

    sub add_initTask {

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_initTask', @_);
        }

        # Update IVs
        $self->ivAdd('initTaskHash', $obj->uniqueName, $obj);
        $self->ivPush('initTaskOrderList', $obj->uniqueName);

        # The data stored in these IVs is saved in the 'tasks' file
        $self->setModifyFlag('tasks', TRUE, $self->_objClass . '->add_initTask');

        return 1;
    }

    sub del_initTask {

        my ($self, $obj, $check) = @_;

        # Local variables
        my $index;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_initTask', @_);
        }

        # Update IVs
        $self->ivDelete('initTaskHash', $obj->uniqueName);
        $index = $self->ivFind('initTaskOrderList', $obj->uniqueName);
        if (defined $index) {

            $self->ivSplice('initTaskOrderList', $index, 1);
        }

        # The data stored in these IVs is saved in the 'tasks' file
        $self->setModifyFlag('tasks', TRUE, $self->_objClass . '->add_initTask');

        return 1;
    }

    sub reset_initTaskHash {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_initTaskHash', @_);
        }

        $self->ivEmpty('initTaskHash');
        $self->ivEmpty('initTaskOrderList');
        $self->ivPoke('initTaskTotal', 0);

        # The data stored in these IVs is saved in the 'tasks' file
        $self->setModifyFlag('tasks', TRUE, $self->_objClass . '->reset_initTaskHash');

        return 1;
    }

    sub set_initTaskOrderList {

        my ($self, @args) = @_;

        # (No improper arguments to check; @args can be an empty list)

        $self->ivPoke('initTaskOrderList', @args);

        # The data stored in this IV is saved in the 'tasks' file
        $self->setModifyFlag('tasks', TRUE, $self->_objClass . '->set_initTaskOrderList');

        return 1;
    }

    sub inc_initTaskTotal {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->inc_initTaskTotal', @_);
        }

        # The data stored in this IV is saved in the 'tasks' file
        $self->setModifyFlag('tasks', TRUE, $self->_objClass . '->inc_initTaskTotal');

        return $self->ivIncrement('initTaskTotal');
    }

    sub reset_initTaskTotal {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_initTaskTotal', @_);
        }

        $self->ivPoke('initTaskTotal', 0);

        # The data stored in this IV is saved in the 'tasks' file
        $self->setModifyFlag('tasks', TRUE, $self->_objClass . '->reset_initTaskTotal');

        return 1;
    }

    sub add_initWorkspace {

        my ($self, $number, $zonemap, $check) = @_;

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_initWorkspace', @_);
        }

        $self->ivAdd('initWorkspaceHash', $number, $zonemap);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->add_initWorkspace');

        return 1;
    }

    sub del_initWorkspace {

        my ($self, $number, $check) = @_;

        # Local variables
        my (
            $count,
            %modHash,
        );

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_initWorkspace', @_);
        }

        # Default initial workspace can't be deleted under any circumstances
        if ($number eq '0') {

            return undef;

        } else {

            $self->ivDelete('initWorkspaceHash', $number);

            # Remaining initial workspaces must be renumbered
            $count = 0;
            foreach my $key ($self->ivKeys('initWorkspaceHash')) {

                $modHash{$count} = $self->ivShow('initWorkspaceHash', $key);
                $count++;
            }

            $self->ivPoke('initWorkspaceHash', %modHash);

            # The data stored in this IV is saved in the 'config' file
            $self->setModifyFlag('config', TRUE, $self->_objClass . '->add_initWorkspace');

            return 1;
        }
    }

    sub set_initWorkspaceDir {

        my ($self, $string, $check) = @_;

        # Check for improper arguments
        if (! defined $string || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_initWorkspaceDir', @_);
        }

        $self->ivPoke('initWorkspaceDir', $string);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_initWorkspaceDir');

        return 1;
    }

    sub set_instructBufferPosn {

        my ($self, $posn, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_instructBufferPosn', @_);
        }

        # Update IVs
        $self->ivPoke('instructBufferPosn', $posn);

        return 1;
    }

    sub toggle_instructFlag {

        my ($self, $type, $check) = @_;

        # Local variables
        my $iv;

        # Check for improper arguments
        if (
            ! defined $type
            || (
                $type ne 'confirm' && $type ne 'convert' && $type ne 'world' && $type ne 'other'
                && $type ne 'max'
            )
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggle_instructFlag', @_);
        }

        if ($type eq 'confirm') {
            $iv = 'confirmWorldCmdFlag';
        } elsif ($type eq 'convert') {
            $iv = 'convertWorldCmdFlag';
        } elsif ($type eq 'world') {
            $iv = 'preserveWorldCmdFlag';
        } elsif ($type eq 'other') {
            $iv = 'preserveOtherCmdFlag';
        } elsif ($type eq 'max') {
            $iv = 'maxMultiCmdFlag';
        }
        if ($self->$iv) {
            $self->ivPoke($iv, FALSE);
        } else {
            $self->ivPoke($iv, TRUE);
        }

        # The data stored in these IVs are saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->toggle_instructFlag');

        return 1;
    }

    sub set_irreversibleIconFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_irreversibleIconFlag',
                @_,
            );
        }

        if ($flag) {
            $self->ivPoke('irreversibleIconFlag', TRUE);
        } else {
            $self->ivPoke('irreversibleIconFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_irreversibleIconFlag');

        return 1;
    }

    sub toggle_keysFlag {

        my ($self, $type, $check) = @_;

        # Local variables
        my $iv;

        # Check for improper arguments
        if (
            ! defined $type
            || (
                $type ne 'scroll' && $type ne 'smooth_scroll' && $type ne 'auto_split'
                && $type ne 'auto_complete' && $type ne 'switch_tab'
            )
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggle_keysFlag', @_);
        }

        if ($type eq 'scroll') {
            $iv = 'useScrollKeysFlag';
        } elsif ($type eq 'smooth_scroll') {
            $iv = 'smoothScrollKeysFlag';
        } elsif ($type eq 'auto_split') {
            $iv = 'autoSplitKeysFlag';
        } elsif ($type eq 'auto_complete') {
            $iv = 'useCompleteKeysFlag';
        } elsif ($type eq 'switch_tab') {
            $iv = 'useSwitchKeysFlag';
        }
        if ($self->$iv) {
            $self->ivPoke($iv, FALSE);
        } else {
            $self->ivPoke($iv, TRUE);
        }

        # The data stored in these IVs are saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->toggle_keysFlag');

        return 1;
    }

    sub set_loadConfigFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_loadConfigFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('loadConfigFlag', TRUE);
        } else {
            $self->ivPoke('loadConfigFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_loadConfigFlag');

        return 1;
    }

    sub set_loadDataFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_loadDataFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('loadDataFlag', TRUE);
        } else {
            $self->ivPoke('loadDataFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_loadDataFlag');

        return 1;
    }

    sub toggle_logFlag {

        my ($self, $type, $check) = @_;

        # Local variables
        my $iv;

        # Check for improper arguments
        if (
            ! defined $type
            || (
                $type ne 'allow' && $type ne 'del_standard' && $type ne 'del_world'
                && $type ne 'new_client' && $type ne 'new_day' && $type ne 'prefix_date'
                && $type ne 'prefix_time' && $type ne 'image'
            )
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggle_logFlag', @_);
        }

        if ($type eq 'allow') {
            $iv = 'allowLogsFlag';
        } elsif ($type eq 'del_standard') {
            $iv = 'deleteStandardLogsFlag';
        } elsif ($type eq 'del_world') {
            $iv = 'deleteWorldLogsFlag';
        } elsif ($type eq 'new_client') {
            $iv = 'logClientFlag';
        } elsif ($type eq 'new_day') {
            $iv = 'logDayFlag';
        } elsif ($type eq 'prefix_date') {
            $iv = 'logPrefixDateFlag';
        } elsif ($type eq 'prefix_time') {
            $iv = 'logPrefixTimeFlag';
        } elsif ($type eq 'image') {
            $iv = 'logImageFlag';
        }

        if ($self->$iv) {
            $self->ivPoke($iv, FALSE);
        } else {
            $self->ivPoke($iv, TRUE);
        }

        # The data stored in these IVs are saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->toggle_logFlag');

        return 1;
    }

    sub set_loginWarningTime {

        my ($self, $interval, $check) = @_;

        # Check for improper arguments
        if (! defined $interval || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_loginWarningTime', @_);
        }

        # Update IVs
        $self->ivPoke('loginWarningTime', $interval);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_loginWarningTime');

        return 1;
    }

    sub set_logPreamble {

        my ($self, @list) = @_;

        # (No improper arguments to check)

        $self->ivPoke('logPreambleList', @list);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_logPreamble');

        return 1;
    }

    sub set_logPref {

        my ($self, $logFile, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $logFile || ! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_logPref', @_);
        }

        if (! $self->ivExists('logPrefHash', $logFile)) {

            return undef;

        } else {

            if ($flag) {
                $self->ivAdd('logPrefHash', $logFile, TRUE);
            } else {
                $self->ivAdd('logPrefHash', $logFile, FALSE);
            }

            # The data stored in this IV is saved in the 'config' file
            $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_logPref');

            return 1;
        }
    }

    sub set_loopSpinFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_loopSpinFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('clientLoopSpinFlag', TRUE);
        } else {
            $self->ivPoke('clientLoopSpinFlag', FALSE);
        }

        return 1;
    }

    sub set_mainWin {

        # Called by GA::Obj::Desktop->start and GA::Session->setMainWin

        my ($self, $winObj, $check) = @_;

        # Check for improper arguments
        if (! defined $winObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_mainWin', @_);
        }

        # Update IVs
        $self->ivPoke('mainWin', $winObj);

        return 1;
    }

    sub reset_mainWin {

        # Called by GA::Obj::Desktop->start and GA::Session->setMainWin

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_mainWin', @_);
        }

        # Update IVs
        $self->ivPoke('mainWin', undef);

        return 1;
    }

    sub set_mainWinSystemMsgFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_mainWinSystemMsgFlag',
                @_,
            );
        }

        if ($flag) {
            $self->ivPoke('mainWinSystemMsgFlag', TRUE);
        } else {
            $self->ivPoke('mainWinSystemMsgFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_mainWinSystemMsgFlag');

        return 1;
    }

    sub set_mainWinTooltipFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_mainWinTooltipFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('mainWinTooltipFlag', TRUE);
        } else {
            $self->ivPoke('mainWinTooltipFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_mainWinTooltipFlag');

        return 1;
    }

    sub set_mainWinUrgencyFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_mainWinUrgencyFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('mainWinUrgencyFlag', TRUE);
        } else {
            $self->ivPoke('mainWinUrgencyFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_mainWinUrgencyFlag');

        return 1;
    }

    sub set_modelSplitSize {

        my ($self, $size, $check) = @_;

        # Check for improper arguments
        if (! defined $size || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_modelSplitSize', @_);
        }

        # Update IVs
        $self->ivPoke('modelSplitSize', $size);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_modelSplitSize');

        return 1;
    }

    sub toggle_mspFlag {

        # $flag is not specified when called by ;msp, but is specified when called by
        #   GA::PrefWin::Client

        my ($self, $type, $flag, $check) = @_;

        # Local variables
        my $iv;

        # Check for improper arguments
        if (
            ! defined $type
            || ($type ne 'multiple' && $type ne 'load' && $type ne 'flexible')
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggle_mspFlag', @_);
        }

        if ($type eq 'multiple') {
            $iv = 'allowMspMultipleFlag';
        } elsif ($type eq 'load') {
            $iv = 'allowMspLoadSoundFlag';
        } elsif ($type eq 'flexible') {
            $iv = 'allowMspFlexibleFlag';
        }

        if (defined $flag) {

            if ($flag) {
                $self->ivPoke($iv, TRUE);
            } else {
                $self->ivPoke($iv, FALSE);
            }

        } elsif ($self->$iv) {

            $self->ivPoke($iv, FALSE);

        } else {

            $self->ivPoke($iv, TRUE);
        }

        # The data stored in these IVs are saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->toggle_mspFlag');

        return 1;
    }

    sub toggle_mudProtocol {

        # $flag is not specified when called by ;setmudprotocol, but is specified when called by
        #   GA::PrefWin::Client

        my ($self, $protocol, $flag, $check) = @_;

        # Local variables
        my $iv;

        # Check for improper arguments
        if (
            ! defined $protocol
            || (
                $protocol ne 'msdp' && $protocol ne 'mssp' && $protocol ne 'mccp'
                && $protocol ne 'msp' && $protocol ne 'mxp' && $protocol ne 'pueblo'
                && $protocol ne 'zmp' && $protocol ne 'aard102' && $protocol ne 'atcp'
                && $protocol ne 'gmcp' && $protocol ne 'mtts' && $protocol ne 'mcp'
            )
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggle_mudProtocol', @_);
        }

        if ($protocol eq 'msdp') {
            $iv = 'useMsdpFlag';
        } elsif ($protocol eq 'mssp') {
            $iv = 'useMsspFlag';
        } elsif ($protocol eq 'mccp') {
            $iv = 'useMccpFlag';
        } elsif ($protocol eq 'msp') {
            $iv = 'useMspFlag';
        } elsif ($protocol eq 'mxp') {
            $iv = 'useMxpFlag';
        } elsif ($protocol eq 'pueblo') {
            $iv = 'usePuebloFlag';
        } elsif ($protocol eq 'zmp') {
            $iv = 'useZmpFlag';
        } elsif ($protocol eq 'aard102') {
            $iv = 'useAard102Flag';
        } elsif ($protocol eq 'atcp') {
            $iv = 'useAtcpFlag';
        } elsif ($protocol eq 'gmcp') {
            $iv = 'useGmcpFlag';
        } elsif ($protocol eq 'mtts') {
            $iv = 'useMttsFlag';
        } elsif ($protocol eq 'mcp') {
            $iv = 'useMcpFlag';
        }

        if (defined $flag) {

            if ($flag) {
                $self->ivPoke($iv, TRUE);
            } else {
                $self->ivPoke($iv, FALSE);
            }

        } elsif ($self->$iv) {

            $self->ivPoke($iv, FALSE);

        } else {

            $self->ivPoke($iv, TRUE);
        }

        # If disabling an option, update every session (except for Pueblo and ZMP, which can't be
        #   turned off mid-session)
        if (! $self->$iv && $iv ne 'pueblo' && $iv ne 'zmp') {

            foreach my $session ($self->listSessions()) {

                $session->disableMudProtocol($protocol);
            }
        }

        # The data stored in these IVs are saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->toggle_mudProtocol');

        return 1;
    }

    sub set_mxpPreventSupportFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_mxpPreventSupportFlag',
                @_,
            );
        }

        if ($flag) {
            $self->ivPoke('mxpPreventSupportFlag', TRUE);
        } else {
            $self->ivPoke('mxpPreventSupportFlag', FALSE);
        }

        return 1;
    }

    sub set_oscPaletteFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_oscPaletteFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('oscPaletteFlag', TRUE);
        } else {
            $self->ivPoke('oscPaletteFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_oscPaletteFlag');

        return 1;
    }

    sub set_promptWaitTime {

        my ($self, $interval, $check) = @_;

        # Check for improper arguments
        if (! defined $interval || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_promptWaitTime', @_);
        }

        # Update IVs
        $self->ivPoke('promptWaitTime', $interval);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_promptWaitTime');

        return 1;
    }

    sub set_resetKeycodesFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_resetKeycodesFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('resetKeycodesFlag', TRUE);
        } else {
            $self->ivPoke('resetKeycodesFlag', FALSE);
        }

        return 1;
    }

    sub set_restartShareMainWinMode {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_restartShareMainWinMode',
                @_,
            );
        }

        if ($flag) {
            $self->ivPoke('restartShareMainWinMode', 'on');
        } else {
            $self->ivPoke('restartShareMainWinMode', 'off');
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_restartShareMainWinMode');

        return 1;
    }

    sub reset_runLists {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_runLists', @_);
        }

        $self->ivPoke('taskRunFirstList', $self->constTaskRunFirstList);
        $self->ivPoke('taskRunLastList', $self->constTaskRunLastList);

        # The data stored in these IVs is saved in the 'tasks' file
        $self->setModifyFlag('tasks', TRUE, $self->_objClass . '->reset_runLists');

        return 1;
    }

    sub set_saveConfigFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_saveConfigFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('saveConfigFlag', TRUE);
        } else {
            $self->ivPoke('saveConfigFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_saveConfigFlag');

        return 1;
    }

    sub set_saveDataFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_saveDataFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('saveDataFlag', TRUE);
        } else {
            $self->ivPoke('saveDataFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_saveDataFlag');

        return 1;
    }

    sub add_scriptDir {

        my ($self, $dir, $check) = @_;

        # Check for improper arguments
        if (! defined $dir || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_scriptDir', @_);
        }

        $self->ivPush('scriptDirList', $dir);

        # The data stored in this IV is saved in the 'scripts' file
        $self->setModifyFlag('scripts', TRUE, $self->_objClass . '->add_scriptDir');

        return 1;
    }

    sub del_scriptDir {

        my ($self, $index, $check) = @_;

        # Check for improper arguments
        if (! defined $index || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_soundEffect', @_);
        }

        $self->ivSplice('scriptDirList', $index, 1);

        # The data stored in this IV is saved in the 'scripts' file
        $self->setModifyFlag('scripts', TRUE, $self->_objClass . '->del_soundEffect');

        return 1;
    }

    sub inc_sessionCount {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->inc_sessionCount', @_);
        }

        return $self->ivIncrement('sessionCount');
    }

    sub set_sessionMax {

        my ($self, $num, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $num
            || $num > $self->constSessionMax
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_sessionMax', @_);
        }

        $self->ivPoke('sessionMax', $num);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_sessionMax');

        return 1;
    }

    sub toggle_sessionFlag {

        my ($self, $type, $check) = @_;

        # Local variables
        my $iv;

        # Check for improper arguments
        if (
            ! defined $type
            || (
                $type ne 'xterm' && $type ne 'long' && $type ne 'simple' && $type ne 'close_main'
                && $type ne 'close_tab' && $type ne 'switch_offline'
            )
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggle_sessionFlag', @_);
        }

        if ($type eq 'xterm') {
            $iv = 'xTermTitleFlag';
        } elsif ($type eq 'long') {
            $iv = 'longTabLabelFlag';
        } elsif ($type eq 'simple') {
            $iv = 'simpleTabFlag';
        } elsif ($type eq 'close_main') {
            $iv = 'confirmCloseMainWinFlag';
        } elsif ($type eq 'close_tab') {
            $iv = 'confirmCloseTabFlag';
        } elsif ($type eq 'switch_offline') {
            $iv = 'offlineOnDisconnectFlag';
        }

        if ($self->$iv) {
            $self->ivPoke($iv, FALSE);
        } else {
            $self->ivPoke($iv, TRUE);
        }

        # Redraw the tab title in every session
        if ($type ne 'switch_offline') {

            foreach my $session ($self->listSessions()) {

                # The TRUE argument means 'definitely update'
                $session->checkTabLabels(TRUE);
            }
        }

        # The data stored in these IVs are saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->toggle_sessionFlag');

        return 1;
    }

    sub set_sessionTabMode {

        my ($self, $mode, $check) = @_;

        # Check for improper arguments
        if (
            defined $check
            || ($mode ne 'bracket' && $mode ne 'hyphen' && $mode ne 'world' && $mode ne 'char')
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_sessionTabMode', @_);
        }

        # Update IVs
        $self->ivPoke('sessionTabMode', $mode);

        # Redraw the tab title in every session
        foreach my $session ($self->listSessions()) {

            # The TRUE argument means 'definitely update'
            $session->checkTabLabels(TRUE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_sessionTabMode');

        return 1;
    }

    sub set_shareMainWinFlag {

        # Should only be called by GA::WizWin::Setup->saveChanges. Everything else should call
        #   $self->set_restartShareMainWinMode

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_shareMainWinFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('shareMainWinFlag', TRUE);
        } else {
            $self->ivPoke('shareMainWinFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_shareMainWinFlag');

        return 1;
    }

    sub set_shortUrlFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_shortUrlFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('shortUrlFlag', TRUE);
        } else {
            $self->ivPoke('shortUrlFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_shortUrlFlag');

        return 1;
    }

    sub set_showSetupWizWinFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_showSetupWizWinFlag',
                @_,
            );
        }

        if ($flag) {
            $self->ivPoke('showSetupWizWinFlag', TRUE);
        } else {
            $self->ivPoke('showSetupWizWinFlag', FALSE);
        }

        return 1;
    }

    sub toggle_sigilFlag {

        my ($self, $sigil, $check) = @_;

        # Local variables
        my $iv;

        # Check for improper arguments
        if (
            ! defined $sigil
            || (
                $sigil ne 'echo' && $sigil ne 'perl' && $sigil ne 'script' && $sigil ne 'multi'
                && $sigil ne 'speed' && $sigil ne 'bypass'
            )
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggle_sigilFlag', @_);
        }

        $iv = $sigil . 'SigilFlag';     # e.g. ->echoSigilFlag
        if ($self->$iv) {
            $self->ivPoke($iv, FALSE);
        } else {
            $self->ivPoke($iv, TRUE);
        }

        # The data stored in these IVs are saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->toggle_sigilFlag');

        return 1;
    }

    sub add_soundEffect {

        my ($self, $sound, $path, $check) = @_;

        # Check for improper arguments
        if (! defined $sound || ! defined $path || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_soundEffect', @_);
        }

        $self->ivAdd('customSoundHash', $sound, $path);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->add_soundEffect');

        return 1;
    }

    sub del_soundEffect {

        my ($self, $sound, $check) = @_;

        # Check for improper arguments
        if (! defined $sound || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_soundEffect', @_);
        }

        $self->ivDelete('customSoundHash', $sound);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->del_soundEffect');

        return 1;
    }

    sub set_standardColourTag {

        my ($self, $tag, $rgb, $boldFlag, $check) = @_;

        # Check for improper arguments
        if (! defined $tag || ! defined $rgb || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_standardColourTag', @_);
        }

        # Update IVs
        if (! $boldFlag) {
            $self->ivAdd('colourTagHash', $tag, $rgb);
        } else {
            $self->ivAdd('boldColourTagHash', $tag, $rgb);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_standardColourTag');

        return 1;
    }

    sub add_standardZonemap {

        my ($self, $zonemap, $check) = @_;

        # Check for improper arguments
        if (! defined $zonemap || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_standardZonemap', @_);
        }

        # Update IVs
        $self->ivAdd('standardZonemapHash', $zonemap->name, $zonemap);

        # The data stored in this IV is saved in the 'zonemaps' file
        $self->setModifyFlag('zonemaps', TRUE, $self->_objClass . '->add_standardZonemap');

        return 1;
    }

    sub set_statusEvent {

        my ($self, $type, $number, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $type || ($type ne 'before' && $type ne 'after') || ! defined $number
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_statusEvent', @_);
        }

        if ($type eq 'before') {
            $self->ivPoke('statusEventBeforeCount', $number);
        } else {
            $self->ivPoke('statusEventAfterCount', $number);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_statusEvent');

        return 1;
    }

    sub set_storeGridPosnFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_storeGridPosnFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('storeGridPosnFlag', TRUE);
        } else {
            $self->ivPoke('storeGridPosnFlag', FALSE);
        }

        return 1;
    }

    sub add_storeGridPosn {

        # Called by GA::Win::Internal->setConfigureEvent and GA::Win::Map->setConfigureEvent
        # Also called by GA::Obj::Workspace->createGridWin and ->createSimpleGridWin

        my ($self, $winObj, $xPos, $yPos, $width, $height, $ignoreFlag, $check) = @_;

        # Check for improper arguments
        if (! defined $winObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_storeGridPosn', @_);
        }

        # Do nothing if the storage flag isn't set, if it's not a 'grid' window or if it's an
        #   'external' window
        # Allow storing of position but not size, or size but not position, but not both
        if (
            (! $self->storeGridPosnFlag && ! $ignoreFlag)
            || $winObj->winCategory ne 'grid'
            || $winObj->winType eq 'external'
            || (! defined $xPos && ! defined $yPos && ! defined $width && ! defined $height)
        ) {
            return undef;
        }

        # An entry is added/replaced in $self->storeGridPosnHash for any 'grid' window, but if there
        #   are several windows with the same ->winName open, only the one which was opened first is
        #   used
        foreach my $otherWinObj ($self->desktopObj->ivValues('gridWinHash')) {

            if (
                $otherWinObj ne $winObj
                && $otherWinObj->winName eq $winObj->winName
                && $otherWinObj->number < $winObj->number
            ) {
                return undef;
            }
        }

        # Update the hash IV
        $self->ivAdd(
            'storeGridPosnHash',
            $winObj->winName,
            [$xPos, $yPos, $width, $height],
        );

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->add_storeGridPosn');

        return 1;
    }

    sub del_storeGridPosn {

        my ($self, $winName, $check) = @_;

        # Check for improper arguments
        if (! defined $winName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_storeGridPosn', @_);
        }

        $self->ivDelete('storeGridPosnHash', $winName);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->del_storeGridPosn');

        return 1;
    }

    sub reset_storeGridPosn {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_storeGridPosn', @_);
        }

        $self->ivEmpty('storeGridPosnHash');

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->reset_storeGridPosn');

        return 1;
    }

    sub add_systemMsg {

        my ($self, $type, $msg, $check) = @_;

        # Check for improper arguments
        if (! defined $type || ! defined $msg || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_systemMsg', @_);
        }

        # If the Client Console window is actually open, display it there immediately
        if ($self->consoleWin) {

            $self->consoleWin->update($type, $msg);

        } else {

            $self->ivPush('systemMsgList', $type, $msg);
            # If the Connections window is open, tell it to change the icon on its button, so the
            #   user can see that a system message has arrived
            if ($self->connectWin) {

                $self->connectWin->set_consoleButton(TRUE);
            }
        }

        return 1;
    }

    sub reset_systemMsg {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_systemMsg', @_);
        }

        $self->ivEmpty('systemMsgList');

        # If the Connections window is open, tell it to change the icon on its button
        if ($self->connectWin) {

            $self->connectWin->set_consoleButton(FALSE);
        }

        return 1;
    }

    sub add_taskLabel {

        my ($self, $label, $taskName, $check) = @_;

        # Check for improper arguments
        if (! defined $label || ! defined $taskName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_taskLabel', @_);
        }

        $self->ivAdd('taskLabelHash', $label, $taskName);

        # The data stored in this IV is saved in the 'tasks' file
        $self->setModifyFlag('tasks', TRUE, $self->_objClass . '->add_taskLabel');

        return 1;
    }

    sub del_taskLabel {

        my ($self, $label, $check) = @_;

        # Check for improper arguments
        if (! defined $label || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_taskLabel', @_);
        }

        $self->ivDelete('taskLabelHash', $label);

        # The data stored in this IV is saved in the 'tasks' file
        $self->setModifyFlag('tasks', TRUE, $self->_objClass . '->del_taskLabel');

        return 1;
    }

    sub reset_taskLabels {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_taskLabels', @_);
        }

        $self->ivPoke('taskLabelHash', $self->constTaskLabelHash);

        # The data stored in this IV is saved in the 'tasks' file
        $self->setModifyFlag('tasks', TRUE, $self->_objClass . '->reset_taskLabels');

        return 1;
    }

    sub add_taskPackageName {

        my ($self, $taskName, $packageName, $check) = @_;

        # Check for improper arguments
        if (! defined $taskName || ! defined $packageName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_taskPackageName', @_);
        }

        $self->ivAdd('taskPackageHash', $taskName, $packageName);

        return 1;
    }

    sub del_taskPackageName {

        my ($self, $taskName, $check) = @_;

        # Check for improper arguments
        if (! defined $taskName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_taskPackageName', @_);
        }

        $self->ivDelete('taskPackageHash', $taskName);

        return 1;
    }

    sub reset_taskPackageNames {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_taskPackageNames', @_);
        }

        $self->ivPoke('taskPackageHash', $self->constTaskPackageHash);

        return 1;
    }

    sub set_taskRunFirstList {

        my ($self, @args) = @_;

        # (No improper arguments to check; @args can be an empty list)

        $self->ivPoke('taskRunFirstList', @args);

        # The data stored in this IV is saved in the 'tasks' file
        $self->setModifyFlag('tasks', TRUE, $self->_objClass . '->set_taskRunFirstList');

        return 1;
    }

    sub set_taskRunLastList {

        my ($self, @args) = @_;

        # (No improper arguments to check; @args can be an empty list)

        $self->ivPoke('taskRunLastList', @args);

        # The data stored in this IV is saved in the 'tasks' file
        $self->setModifyFlag('tasks', TRUE, $self->_objClass . '->set_taskRunLastList');

        return 1;
    }

    sub inc_taskTotal {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->inc_taskTotal', @_);
        }

        return $self->ivIncrement('taskTotal');
    }

    sub toggle_telnetOption {

        # $flag is not specified when called by ;settelnetoption, but is specified when called by
        #   GA::PrefWin::Client

        my ($self, $option, $flag, $check) = @_;

        # Local variables
        my $iv;

        # Check for improper arguments
        if (
            ! defined $option
            || (
                $option ne 'echo' && $option ne 'sga' && $option ne 'ttype' && $option ne 'eor'
                && $option ne 'naws' && $option ne 'new_environ' && $option ne 'charset'
            )
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggle_telnetOption', @_);
        }

        if ($option eq 'echo') {
            $iv = 'useEchoFlag';
        } elsif ($option eq 'sga') {
            $iv = 'useSgaFlag';
        } elsif ($option eq 'ttype') {
            $iv = 'useTTypeFlag';
        } elsif ($option eq 'eor') {
            $iv = 'useEorFlag';
        } elsif ($option eq 'naws') {
            $iv = 'useNawsFlag';
        } elsif ($option eq 'new_environ') {
            $iv = 'useNewEnvironFlag';
        } elsif ($option eq 'charset') {
            $iv = 'useCharSetFlag';
        }

        if (defined $flag) {

            if ($flag) {
                $self->ivPoke($iv, TRUE);
            } else {
                $self->ivPoke($iv, FALSE);
            }

        } elsif ($self->$iv) {

            $self->ivPoke($iv, FALSE);

        } else {

            $self->ivPoke($iv, TRUE);
        }

        # If disabling an option, update every session
        if (! $self->$iv) {

            foreach my $session ($self->listSessions()) {

                $session->disableTelnetOption($option);
            }
        }

        # The data stored in these IVs are saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->toggle_telnetOption');

        return 1;
    }

    sub set_tempSoundFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_tempSoundFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('tempSoundFlag', TRUE);
        } else {
            $self->ivPoke('tempSoundFlag', FALSE);
        }

        return 1;
    }

    sub set_tempUrgencyFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_tempUrgencyFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('tempUrgencyFlag', TRUE);
        } else {
            $self->ivPoke('tempUrgencyFlag', FALSE);
        }

        return 1;
    }

    sub toggle_termSetting {

        # $flag is not specified when called by ;configureterminal, but is specified when called by
        #   GA::PrefWin::Client

        my ($self, $type, $flag, $check) = @_;

        # Local variables
        my $iv;

        # Check for improper arguments
        if (
            ! defined $type
            || (
                $type ne 'use_ctrl_seq' && $type ne 'show_cursor' && $type ne 'fast_cursor'
                && $type ne 'direct_keys'
            )
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggle_termSetting', @_);
        }

        if ($type eq 'use_ctrl_seq') {
            $iv = 'useCtrlSeqFlag';
        } elsif ($type eq 'show_cursor') {
            $iv = 'useVisibleCursorFlag';
        } elsif ($type eq 'fast_cursor') {
            $iv = 'useFastCursorFlag';
        } elsif ($type eq 'direct_keys') {
            $iv = 'useDirectKeysFlag';
        }

        if (defined $flag) {

            if ($flag) {
                $self->ivPoke($iv, TRUE);
            } else {
                $self->ivPoke($iv, FALSE);
            }

        } elsif ($self->$iv) {

            $self->ivPoke($iv, FALSE);

        } else {

            $self->ivPoke($iv, TRUE);
        }

        # Inform every session that $self->useVisibleCursorFlag or ->useDirectKeysFlag have changed
        if ($type eq 'show_cursor') {

            foreach my $session ($self->listSessions()) {

                $session->textViewCursorUpdate();
            }

        } elsif ($type eq 'direct_keys') {

            foreach my $session ($self->listSessions()) {

                $session->textViewKeysUpdate();
            }
        }

        # The data stored in these IVs are saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->toggle_termSetting');

        return 1;
    }

    sub set_termTypeMode {

        my ($self, $mode, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $mode
            || (
                $mode ne 'send_nothing' && $mode ne 'send_client' && $mode ne 'send_client_version'
                && $mode ne 'send_custom_client' && $mode ne 'send_default'
                && $mode ne 'send_unknown'
            )
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_termTypeMode', @_);
        }

        # Update IVs
        $self->ivPoke('termTypeMode', $mode);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_termTypeMode');

        return 1;
    }

    sub set_textEditCmd {

        my ($self, $cmd, $check) = @_;

        # Check for improper arguments
        if (! defined $cmd || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_textEditCmd', @_);
        }

        $self->ivPoke('textEditCmd', $cmd);

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_textEditCmd');

        return 1;
    }

    sub set_toolbarLabelFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_toolbarLabelFlag',
                @_,
            );
        }

        if ($flag) {
            $self->ivPoke('toolbarLabelFlag', TRUE);
        } else {
            $self->ivPoke('toolbarLabelFlag', FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_toolbarLabelFlag');

        return 1;
    }

    sub set_toolbarHash {

        my ($self, %hash) = @_;

        # (No improper arguments to check - %hash can be empty)

        $self->ivPoke('toolbarHash', %hash);

        # The data stored in this IV is saved in the 'toolbar' file
        $self->setModifyFlag('toolbar', TRUE, $self->_objClass . '->set_toolbarHash');

        return 1;
    }

    sub set_toolbarList {

        my ($self, @list) = @_;

        # (No improper arguments to check - @list can be empty)

        $self->ivPoke('toolbarList', @list);

        # The data stored in this IV is saved in the 'toolbar' file
        $self->setModifyFlag('toolbar', TRUE, $self->_objClass . '->set_toolbarList');

        return 1;
    }

    sub add_ttsObj {

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_ttsObj', @_);
        }

        $self->ivAdd('ttsObjHash', $obj->name, $obj);

        # The data stored in this IV is saved in the 'tts' file
        $self->setModifyFlag('tts', TRUE, $self->_objClass . '->add_ttsObj');

        return 1;
    }

    sub del_ttsObj {

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_ttsObj', @_);
        }

        # Cannot delete certain standard objects
        if ($self->ivExists('constTtsPermObjHash', $obj->name)) {

            return undef;

        } else {

            $self->ivDelete('ttsObjHash', $obj->name);
        }

        # The data stored in this IV is saved in the 'tts' file
        $self->setModifyFlag('tts', TRUE, $self->_objClass . '->del_ttsObj');

        return 1;
    }

    sub set_ttsFestivalServer {

        my ($self, $server, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_ttsFestivalServer', @_);
        }

        $self->ivPoke('ttsFestivalServer', $server);        # Can be 'undef'

        return 1;
    }

    sub set_ttsFestivalServerMode {

        my ($self, $mode, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $mode
            || ($mode ne 'waiting' && $mode ne 'connecting' && $mode ne 'connected')
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_ttsFestivalServerMode',
                @_,
            );
        }

        $self->ivPoke('ttsFestivalServerMode', $mode);

        return 1;
    }

    sub set_ttsFestivalServerPort {

        my ($self, $port, $check) = @_;

        # Check for improper arguments
        if (
            defined $check
            || (
                defined $port && ($port < 0 || $port > 65535)
            )
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_ttsFestivalServerPort',
                @_,
            );
        }

        $self->ivPoke('ttsFestivalServerPort', $port);      # May be 'undef'

        # Modifying the port means we must disconnect from the Festival server (if connected) and
        #   reconnect to the Festival server (when required)
        $self->ttsReconnectServer();

        return 1;
    }

    sub set_ttsFlag {

        my ($self, $type, $flag, $check) = @_;

        # Local variables
        my $iv;

        # Check for improper arguments
        if (
            ! defined $flag
            || (
                $type ne 'receive' && $type ne 'login' && $type ne 'system'
                && $type ne 'error' && $type ne 'command' && $type ne 'cmd' && $type ne 'dialogue'
                && $type ne 'task' && $type ne 'smooth' && $type ne 'auto'
            ) || defined $check
        ) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_ttsFlag', @_);
        }

        if ($type eq 'receive') {
            $iv = 'ttsReceiveFlag';
        } elsif ($type eq 'login') {
            $iv = 'ttsLoginFlag';
        } elsif ($type eq 'system') {
            $iv = 'ttsSystemFlag';
        } elsif ($type eq 'error') {
            $iv = 'ttsSystemErrorFlag';
        } elsif ($type eq 'command' || $type eq 'cmd') {
            $iv = 'ttsWorldCmdFlag';
        } elsif ($type eq 'dialogue') {
            $iv = 'ttsDialogueFlag';
        } elsif ($type eq 'task') {
            $iv = 'ttsTaskFlag';
        } elsif ($type eq 'smooth') {
            $iv = 'ttsSmoothFlag';
        } elsif ($type eq 'auto') {
            $iv = 'ttsStartServerFlag';
        }

        if ($flag) {
            $self->ivPoke($iv, TRUE);
        } else {
            $self->ivPoke($iv, FALSE);
        }

        # The data stored in this IV is saved in the 'config' file
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->set_ttsFlag');

        return 1;
    }

    sub add_userCmd {

        my ($self, $userCmd, $standardCmd, $check) = @_;

        # Check for improper arguments
        if (! defined $userCmd || ! defined $standardCmd || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_userCmd', @_);
        }

        $self->ivAdd('userCmdHash', $userCmd, $standardCmd);

        # The data stored in these IVs is saved in the 'usercmds' file
        $self->setModifyFlag('usercmds', TRUE, $self->_objClass . '->add_userCmd');

        return 1;
    }

    sub del_userCmd {

        my ($self, $userCmd, $check) = @_;

        # Check for improper arguments
        if (! defined $userCmd || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_userCmd', @_);
        }

        $self->ivDelete('userCmdHash', $userCmd);

        # The data stored in these IVs is saved in the 'usercmds' file
        $self->setModifyFlag('usercmds', TRUE, $self->_objClass . '->del_userCmd');

        return 1;
    }

    sub reset_userCmd {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_userCmd', @_);
        }

        $self->ivPoke('userCmdHash', $self->constUserCmdHash);

        # The data stored in these IVs is saved in the 'usercmds' file
        $self->setModifyFlag('usercmds', TRUE, $self->_objClass . '->reset_userCmd');

        return 1;
    }

    sub del_winObj {

        # Called by GA::Win::Generic->winDestroy

        my ($self, $winObj, $check) = @_;

        # Local variables
        my $stripObj;

        # Check for improper arguments
        if (! defined $winObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_winObj', @_);
        }

        # For pseudo-windows, if the parent table object is still open, close it
        if ($winObj->pseudoWinTableObj) {

            $stripObj = $winObj->pseudoWinTableObj->stripObj;
            if ($stripObj->ivExists('tableObjHash', $winObj->pseudoWinTableObj->number)) {

                $stripObj->removeTableObj($winObj->pseudoWinTableObj);
            }
        }

        return 1;
    }

    sub add_worldProf {

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_worldProf', @_);
        }

        $self->ivAdd('worldProfHash', $obj->name, $obj);

        # The data stored in this IV is saved in the 'config' and 'worldprof' files
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->add_worldProf');
        $self->setModifyFlag($obj->name, TRUE, $self->_objClass . '->add_worldProf');

        return 1;
    }

    sub del_worldProf {

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_worldProf', @_);
        }

        $self->ivDelete('worldProfHash', $obj->name);

        # The data stored in this IV is saved in the 'config' and 'worldprof' files
        $self->setModifyFlag('config', TRUE, $self->_objClass . '->del_worldProf');
        $self->setModifyFlag($obj->name, TRUE, $self->_objClass . '->del_worldProf');

        return 1;
    }

    sub add_winmap {

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_winmap', @_);
        }

        # Update IVs
        $self->ivAdd('winmapHash', $obj->name, $obj);

        # The data stored in this IV is saved in the 'winmaps' file
        $self->setModifyFlag('winmaps', TRUE, $self->_objClass . '->add_winmap');

        return 1;
    }

    sub del_winmap {

        my ($self, $winmapName, $check) = @_;

        # Check for improper arguments
        if (! defined $winmapName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_winmap', @_);
        }

        # Update IVs
        $self->ivDelete('winmapHash', $winmapName);

        # The data stored in this IV is saved in the 'winmaps' file
        $self->setModifyFlag('winmaps', TRUE, $self->_objClass . '->del_winmap');

        return 1;
    }

    sub add_zmpPackage {

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_zmpPackage', @_);
        }

        # Can't replace an existing package object using one with the same name
        if ($self->ivExists('zmpPackageHash', $obj->name)) {

            return undef;

        } else {

            $self->ivAdd('zmpPackageHash', $obj->name, $obj);

            return $obj;
        }
    }

    sub add_zonemap {

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_zonemap', @_);
        }

        # Update IVs
        $self->ivAdd('zonemapHash', $obj->name, $obj);

        # The data stored in this IV is saved in the 'zonemaps' file
        $self->setModifyFlag('zonemaps', TRUE, $self->_objClass . '->add_zonemap');

        return 1;
    }

    sub del_zonemap {

        # Called by GA::Cmd::DeleteZonemap->do and, for temporary zonemaps, GA::Session->stop
        #   (only; if a zonemap in use by a workspace grid is deleted, bad things can happen)

        my ($self, $zonemapName, $check) = @_;

        # Check for improper arguments
        if (! defined $zonemapName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_zonemap', @_);
        }

        # Update IVs
        $self->ivDelete('zonemapHash', $zonemapName);

        # The data stored in this IV is saved in the 'zonemaps' file
        $self->setModifyFlag('zonemaps', TRUE, $self->_objClass . '->del_zonemap');

        return 1;
    }

    ##################
    # Accessors - get

    sub desktopObj
        { $_[0]->{desktopObj} }

    sub mainWin
        { $_[0]->{mainWin} }

    sub aboutWin
        { $_[0]->{aboutWin} }
    sub busyWin
        { $_[0]->{busyWin} }
    sub connectWin
        { $_[0]->{connectWin} }
    sub consoleWin
        { $_[0]->{consoleWin} }

    sub constIVHash
        { my $self = shift; return %{$self->{constIVHash}}; }
    sub constReservedHash
        { my $self = shift; return %{$self->{constReservedHash}}; }

    sub loadConfigFlag
        { $_[0]->{loadConfigFlag} }
    sub saveConfigFlag
        { $_[0]->{saveConfigFlag} }
    sub loadDataFlag
        { $_[0]->{loadDataFlag} }
    sub saveDataFlag
        { $_[0]->{saveDataFlag} }
    sub deleteFilesAtStartFlag
        { $_[0]->{deleteFilesAtStartFlag} }
    sub fileFailFlag
        { $_[0]->{fileFailFlag} }

    sub emergencySaveFlag
        { $_[0]->{emergencySaveFlag} }

    sub autoSaveFlag
        { $_[0]->{autoSaveFlag} }
    sub autoSaveWaitTime
        { $_[0]->{autoSaveWaitTime} }
    sub autoRetainFileFlag
        { $_[0]->{autoRetainFileFlag} }

    sub autoBackupMode
        { $_[0]->{autoBackupMode} }
    sub autoBackupDir
        { $_[0]->{autoBackupDir} }
    sub autoBackupInterval
        { $_[0]->{autoBackupInterval} }
    sub autoBackupDate
        { $_[0]->{autoBackupDate} }
    sub autoBackupFileType
        { $_[0]->{autoBackupFileType} }
    sub autoBackupAppendFlag
        { $_[0]->{autoBackupAppendFlag} }

    sub fileObjHash
        { my $self = shift; return %{$self->{fileObjHash}}; }
    sub configFileObj
        { $_[0]->{configFileObj} }
    sub configWorldProfList
        { my $self = shift; return @{$self->{configWorldProfList}}; }

    sub constLargeFileSize
        { $_[0]->{constLargeFileSize} }

    sub allowModelSplitFlag
        { $_[0]->{allowModelSplitFlag} }
    sub constModelSplitSize
        { $_[0]->{constModelSplitSize} }
    sub modelSplitSize
        { $_[0]->{modelSplitSize} }

    sub initPluginList
        { my $self = shift; return @{$self->{initPluginList}}; }
    sub pluginHash
        { my $self = shift; return %{$self->{pluginHash}}; }
    sub pluginCmdHash
        { my $self = shift; return %{$self->{pluginCmdHash}}; }
    sub pluginTaskHash
        { my $self = shift; return %{$self->{pluginTaskHash}}; }
    sub pluginGridWinHash
        { my $self = shift; return %{$self->{pluginGridWinHash}}; }
    sub pluginFreeWinHash
        { my $self = shift; return %{$self->{pluginFreeWinHash}}; }
    sub pluginStripObjHash
        { my $self = shift; return %{$self->{pluginStripObjHash}}; }
    sub pluginTableObjHash
        { my $self = shift; return %{$self->{pluginTableObjHash}}; }
    sub pluginCageHash
        { my $self = shift; return %{$self->{pluginCageHash}}; }
    sub pluginCagePackageHash
        { my $self = shift; return %{$self->{pluginCagePackageHash}}; }
    sub pluginCageEditWinHash
        { my $self = shift; return %{$self->{pluginCageEditWinHash}}; }
    sub pluginMenuFuncHash
        { my $self = shift; return %{$self->{pluginMenuFuncHash}}; }
    sub pluginMxpFilterHash
        { my $self = shift; return %{$self->{pluginMxpFilterHash}}; }

    sub clientTime
        { $_[0]->{clientTime} }
    sub suspendSessionLoopFlag
        { $_[0]->{suspendSessionLoopFlag} }

    sub clientLoopObj
        { $_[0]->{clientLoopObj} }
    sub clientLoopSpinFlag
        { $_[0]->{clientLoopSpinFlag} }
    sub clientLoopDelay
        { $_[0]->{clientLoopDelay} }

    sub showModFlag
        { $_[0]->{showModFlag} }

    sub blinkerDelay
        { $_[0]->{blinkerDelay} }

    sub blinkSlowTime
        { $_[0]->{blinkSlowTime} }
    sub blinkSlowCheckTime
        { $_[0]->{blinkSlowCheckTime} }
    sub blinkSlowFlag
        { $_[0]->{blinkSlowFlag} }
    sub blinkFastTime
        { $_[0]->{blinkFastTime} }
    sub blinkFastCheckTime
        { $_[0]->{blinkFastCheckTime} }
    sub blinkFastFlag
        { $_[0]->{blinkFastFlag} }

    sub paneDelay
        { $_[0]->{paneDelay} }
    sub paneRestoreHash
        { my $self = shift; return %{$self->{paneRestoreHash}}; }

    sub systemMsgList
        { my $self = shift; return @{$self->{systemMsgList}}; }

    sub sessionHash
        { my $self = shift; return %{$self->{sessionHash}}; }
    sub sessionCount
        { $_[0]->{sessionCount} }
    sub constSessionMax
        { $_[0]->{constSessionMax} }
    sub sessionMax
        { $_[0]->{sessionMax} }
    sub currentSession
        { $_[0]->{currentSession} }
    sub shutdownFlag
        { $_[0]->{shutdownFlag} }
    sub terminatingFlag
        { $_[0]->{terminatingFlag} }

    sub sessionTabMode
        { $_[0]->{sessionTabMode} }
    sub xTermTitleFlag
        { $_[0]->{xTermTitleFlag} }
    sub longTabLabelFlag
        { $_[0]->{longTabLabelFlag} }
    sub simpleTabFlag
        { $_[0]->{simpleTabFlag} }
    sub confirmCloseMainWinFlag
        { $_[0]->{confirmCloseMainWinFlag} }
    sub confirmCloseTabFlag
        { $_[0]->{confirmCloseTabFlag} }
    sub offlineOnDisconnectFlag
        { $_[0]->{offlineOnDisconnectFlag} }

    sub constCharSet
        { $_[0]->{constCharSet} }
    sub charSet
        { $_[0]->{charSet} }
    sub charSetList
        { my $self = shift; return @{$self->{charSetList}}; }

    sub connectHistoryFlag
        { $_[0]->{connectHistoryFlag} }

    sub clientCmdHash
        { my $self = shift; return %{$self->{clientCmdHash}}; }
    sub replaceClientCmdHash
        { my $self = shift; return %{$self->{replaceClientCmdHash}}; }
    sub constClientCmdPrettyList
        { my $self = shift; return @{$self->{constClientCmdPrettyList}}; }
    sub clientCmdPrettyList
        { my $self = shift; return @{$self->{clientCmdPrettyList}}; }
    sub clientCmdList
        { my $self = shift; return @{$self->{clientCmdList}}; }
    sub clientCmdReplacePrettyHash
        { my $self = shift; return %{$self->{clientCmdReplacePrettyHash}}; }

    sub constUserCmdHash
        { my $self = shift; return %{$self->{constUserCmdHash}}; }
    sub userCmdHash
        { my $self = shift; return %{$self->{userCmdHash}}; }

    sub constClientSigil
        { $_[0]->{constClientSigil} }
    sub constForcedSigil
        { $_[0]->{constForcedSigil} }
    sub constEchoSigil
        { $_[0]->{constEchoSigil} }
    sub constPerlSigil
        { $_[0]->{constPerlSigil} }
    sub constScriptSigil
        { $_[0]->{constScriptSigil} }
    sub constMultiSigil
        { $_[0]->{constMultiSigil} }
    sub constSpeedSigil
        { $_[0]->{constSpeedSigil} }
    sub constBypassSigil
        { $_[0]->{constBypassSigil} }

    sub echoSigilFlag
        { $_[0]->{echoSigilFlag} }
    sub perlSigilFlag
        { $_[0]->{perlSigilFlag} }
    sub scriptSigilFlag
        { $_[0]->{scriptSigilFlag} }
    sub multiSigilFlag
        { $_[0]->{multiSigilFlag} }
    sub speedSigilFlag
        { $_[0]->{speedSigilFlag} }
    sub bypassSigilFlag
        { $_[0]->{bypassSigilFlag} }

    sub constCmdSep
        { $_[0]->{constCmdSep} }
    sub cmdSep
        { $_[0]->{cmdSep} }

    sub constDisplayBufferSize
        { $_[0]->{constDisplayBufferSize} }
    sub constInstructBufferSize
        { $_[0]->{constInstructBufferSize} }
    sub constCmdBufferSize
        { $_[0]->{constCmdBufferSize} }
    sub constMinBufferSize
        { $_[0]->{constMinBufferSize} }
    sub constMaxBufferSize
        { $_[0]->{constMaxBufferSize} }
    sub customDisplayBufferSize
        { $_[0]->{customDisplayBufferSize} }
    sub customInstructBufferSize
        { $_[0]->{customInstructBufferSize} }
    sub customCmdBufferSize
        { $_[0]->{customCmdBufferSize} }

    sub confirmWorldCmdFlag
        { $_[0]->{confirmWorldCmdFlag} }
    sub convertWorldCmdFlag
        { $_[0]->{convertWorldCmdFlag} }
    sub preserveWorldCmdFlag
        { $_[0]->{preserveWorldCmdFlag} }
    sub preserveOtherCmdFlag
        { $_[0]->{preserveOtherCmdFlag} }
    sub maxMultiCmdFlag
        { $_[0]->{maxMultiCmdFlag} }

    sub autoCompleteMode
        { $_[0]->{autoCompleteMode} }
    sub autoCompleteType
        { $_[0]->{autoCompleteType} }
    sub autoCompleteParent
        { $_[0]->{autoCompleteParent} }

    sub useScrollKeysFlag
        { $_[0]->{useScrollKeysFlag} }
    sub smoothScrollKeysFlag
        { $_[0]->{smoothScrollKeysFlag} }
    sub autoSplitKeysFlag
        { $_[0]->{autoSplitKeysFlag} }
    sub useCompleteKeysFlag
        { $_[0]->{useCompleteKeysFlag} }
    sub useSwitchKeysFlag
        { $_[0]->{useSwitchKeysFlag} }

    sub instructBufferHash
        { my $self = shift; return %{$self->{instructBufferHash}}; }
    sub instructBufferCount
        { $_[0]->{instructBufferCount} }
    sub instructBufferFirst
        { $_[0]->{instructBufferFirst} }
    sub instructBufferLast
        { $_[0]->{instructBufferLast} }
    sub instructBufferPosn
        { $_[0]->{instructBufferPosn} }

    sub cmdBufferHash
        { my $self = shift; return %{$self->{cmdBufferHash}}; }
    sub cmdBufferCount
        { $_[0]->{cmdBufferCount} }
    sub cmdBufferFirst
        { $_[0]->{cmdBufferFirst} }
    sub cmdBufferLast
        { $_[0]->{cmdBufferLast} }
    sub cmdBufferPosn
        { $_[0]->{cmdBufferPosn} }

    sub constProfPriorityList
        { my $self = shift; return @{$self->{constProfPriorityList}}; }
    sub constProfStandardHash
        { my $self = shift; return %{$self->{constProfStandardHash}}; }

    sub worldProfHash
        { my $self = shift; return %{$self->{worldProfHash}}; }

    sub constWorldHash
        { my $self = shift; return %{$self->{constWorldHash}}; }
    sub constWorldPatchHash
        { my $self = shift; return %{$self->{constWorldPatchHash}}; }
    sub constWorldList
        { my $self = shift; return @{$self->{constWorldList}}; }
    sub prevClientVersion
        { $_[0]->{prevClientVersion} }
    sub favouriteWorldList
        { my $self = shift; return @{$self->{favouriteWorldList}}; }
    sub autoConnectList
        { my $self = shift; return @{$self->{autoConnectList}}; }
    sub constBasicWorldHash
        { my $self = shift; return %{$self->{constBasicWorldHash}}; }

    sub constRoomFilterList
        { my $self = shift; return @{$self->{constRoomFilterList}}; }
    sub constRoomFilterKeyList
        { my $self = shift; return @{$self->{constRoomFilterKeyList}}; }
    sub constRoomFlagList
        { my $self = shift; return @{$self->{constRoomFlagList}}; }
    sub constRoomHazardHash
        { my $self = shift; return %{$self->{constRoomHazardHash}}; }

    sub constCageTypeList
        { my $self = shift; return @{$self->{constCageTypeList}}; }
    sub cageTypeList
        { my $self = shift; return @{$self->{cageTypeList}}; }

    sub dictHash
        { my $self = shift; return %{$self->{dictHash}}; }
    sub phrasebookHash
        { my $self = shift; return %{$self->{phrasebookHash}}; }

    sub interfaceModelHash
        { my $self = shift; return %{$self->{interfaceModelHash}}; }

    sub constKeycodeHash
        { my $self = shift; return %{$self->{constKeycodeHash}}; }
    sub constMSWinKeycodeHash
        { my $self = shift; return %{$self->{constMSWinKeycodeHash}}; }
    sub constBSDKeycodeHash
        { my $self = shift; return %{$self->{constBSDKeycodeHash}}; }
    sub keycodeHash
        { my $self = shift; return %{$self->{keycodeHash}}; }
    sub revKeycodeHash
        { my $self = shift; return %{$self->{revKeycodeHash}}; }
    sub constAltKeycodeHash
        { my $self = shift; return %{$self->{constAltKeycodeHash}}; }
    sub constKeycodeList
        { my $self = shift; return @{$self->{constKeycodeList}}; }
    sub activeKeycodeHash
        { my $self = shift; return %{$self->{activeKeycodeHash}}; }
    sub resetKeycodesFlag
        { $_[0]->{resetKeycodesFlag} }

    sub constTaskPackageHash
        { my $self = shift; return %{$self->{constTaskPackageHash}}; }
    sub taskPackageHash
        { my $self = shift; return %{$self->{taskPackageHash}}; }
    sub constTaskLabelHash
        { my $self = shift; return %{$self->{constTaskLabelHash}}; }
    sub taskLabelHash
        { my $self = shift; return %{$self->{taskLabelHash}}; }

    sub constTaskRunFirstList
        { my $self = shift; return @{$self->{constTaskRunFirstList}}; }
    sub constTaskRunLastList
        { my $self = shift; return @{$self->{constTaskRunLastList}}; }
    sub taskRunFirstList
        { my $self = shift; return @{$self->{taskRunFirstList}}; }
    sub taskRunLastList
        { my $self = shift; return @{$self->{taskRunLastList}}; }

    sub taskTotal
        { $_[0]->{taskTotal} }

    sub initTaskHash
        { my $self = shift; return %{$self->{initTaskHash}}; }
    sub initTaskOrderList
        { my $self = shift; return @{$self->{initTaskOrderList}}; }
    sub initTaskTotal
        { $_[0]->{initTaskTotal} }

    sub customTaskHash
        { my $self = shift; return %{$self->{customTaskHash}}; }

    sub constTaskSettingsHash
        { my $self = shift; return %{$self->{constTaskSettingsHash}}; }
    sub constTaskStatusHash
        { my $self = shift; return %{$self->{constTaskStatusHash}}; }

    sub scriptDirList
        { my $self = shift; return @{$self->{scriptDirList}}; }
    sub initScriptHash
        { my $self = shift; return %{$self->{initScriptHash}}; }
    sub initScriptOrderList
        { my $self = shift; return @{$self->{initScriptOrderList}}; }

    sub constModelTypeHash
        { my $self = shift; return %{$self->{constModelTypeHash}}; }
    sub constPrimaryDirList
        { my $self = shift; return @{$self->{constPrimaryDirList}}; }
    sub constShortPrimaryDirList
        { my $self = shift; return @{$self->{constShortPrimaryDirList}}; }
    sub constShortPrimaryDirHash
        { my $self = shift; return %{$self->{constShortPrimaryDirHash}}; }
    sub constOppDirHash
        { my $self = shift; return %{$self->{constOppDirHash}}; }
    sub constComponentTypeList
        { my $self = shift; return @{$self->{constComponentTypeList}}; }
    sub constExitStateHash
        { my $self = shift; return %{$self->{constExitStateHash}}; }
    sub constParseObjMax
        { $_[0]->{constParseObjMax} }

    sub constLogPrefHash
        { my $self = shift; return %{$self->{constLogPrefHash}}; }
    sub logPrefHash
        { my $self = shift; return %{$self->{logPrefHash}}; }
    sub constSessionLogPrefHash
        { my $self = shift; return %{$self->{constSessionLogPrefHash}}; }
    sub constSessionLogOrderList
        { my $self = shift; return @{$self->{constSessionLogOrderList}}; }

    sub constLogDescripHash
        { my $self = shift; return %{$self->{constLogDescripHash}}; }
    sub constLogOrderList
        { my $self = shift; return @{$self->{constLogOrderList}}; }
    sub constLogPathHash
        { my $self = shift; return %{$self->{constLogPathHash}}; }
    sub allowLogsFlag
        { $_[0]->{allowLogsFlag} }
    sub deleteStandardLogsFlag
        { $_[0]->{deleteStandardLogsFlag} }
    sub deleteWorldLogsFlag
        { $_[0]->{deleteWorldLogsFlag} }

    sub logDayFlag
        { $_[0]->{logDayFlag} }
    sub logClientFlag
        { $_[0]->{logClientFlag} }
    sub logPrefixDateFlag
        { $_[0]->{logPrefixDateFlag} }
    sub logPrefixTimeFlag
        { $_[0]->{logPrefixTimeFlag} }
    sub logImageFlag
        { $_[0]->{logImageFlag} }
    sub logPreambleList
        { my $self = shift; return @{$self->{logPreambleList}}; }

    sub statusEventBeforeCount
        { $_[0]->{statusEventBeforeCount} }
    sub statusEventAfterCount
        { $_[0]->{statusEventAfterCount} }

    sub chatName
        { $_[0]->{chatName} }
    sub chatEmail
        { $_[0]->{chatEmail} }
    sub constChatPort
        { $_[0]->{constChatPort} }
    sub chatAcceptMode
        { $_[0]->{chatAcceptMode} }
    sub chatContactHash
        { my $self = shift; return %{$self->{chatContactHash}}; }

    sub constChatIcon
        { $_[0]->{constChatIcon} }
    sub chatIcon
        { $_[0]->{chatIcon} }

    sub constChatContactIcon
        { $_[0]->{constChatContactIcon} }
    sub constChatSmileyHash
        { my $self = shift; return %{$self->{constChatSmileyHash}}; }
    sub chatSmileyHash
        { my $self = shift; return %{$self->{chatSmileyHash}}; }

    sub constColourTagList
        { my $self = shift; return @{$self->{constColourTagList}}; }
    sub constBoldColourTagList
        { my $self = shift; return @{$self->{constBoldColourTagList}}; }
    sub constColourTagHash
        { my $self = shift; return %{$self->{constColourTagHash}}; }
    sub constBoldColourTagHash
        { my $self = shift; return %{$self->{constBoldColourTagHash}}; }
    sub colourTagHash
        { my $self = shift; return %{$self->{colourTagHash}}; }
    sub boldColourTagHash
        { my $self = shift; return %{$self->{boldColourTagHash}}; }
    sub constMonochromeHash
        { my $self = shift; return %{$self->{constMonochromeHash}}; }

    sub constRainbowColourList
        { my $self = shift; return @{$self->{constRainbowColourList}}; }
    sub constHtmlColourHash
        { my $self = shift; return %{$self->{constHtmlColourHash}}; }
    sub constHtmlContrastHash
        { my $self = shift; return %{$self->{constHtmlContrastHash}}; }

    sub constXTermColourHash
        { my $self = shift; return %{$self->{constXTermColourHash}}; }
    sub constNetscapeColourHash
        { my $self = shift; return %{$self->{constNetscapeColourHash}}; }
    sub currentColourCube
        { $_[0]->{currentColourCube} }
    sub xTermColourHash
        { my $self = shift; return %{$self->{xTermColourHash}}; }

    sub constOscPaletteHash
        { my $self = shift; return %{$self->{constOscPaletteHash}}; }
    sub oscPaletteFlag
        { $_[0]->{oscPaletteFlag} }

    sub constStyleTagList
        { my $self = shift; return @{$self->{constStyleTagList}}; }
    sub constDummyTagList
        { my $self = shift; return @{$self->{constDummyTagList}}; }
    sub constStyleTagHash
        { my $self = shift; return %{$self->{constStyleTagHash}}; }
    sub constJustifyTagHash
        { my $self = shift; return %{$self->{constJustifyTagHash}}; }
    sub constDummyTagHash
        { my $self = shift; return %{$self->{constDummyTagHash}}; }

    sub constANSIColourHash
        { my $self = shift; return %{$self->{constANSIColourHash}}; }
    sub constANSIStyleHash
        { my $self = shift; return %{$self->{constANSIStyleHash}}; }
    sub constColourStyleList
        { my $self = shift; return @{$self->{constColourStyleList}}; }
    sub constPrettyTagHash
        { my $self = shift; return %{$self->{constPrettyTagHash}}; }
    sub constColourStyleHash
        { my $self = shift; return %{$self->{constColourStyleHash}}; }

    sub constTelnetHash
        { my $self = shift; return %{$self->{constTelnetHash}}; }
    sub constTeloptHash
        { my $self = shift; return %{$self->{constTeloptHash}}; }

    sub constHeadingSizeHash
        { my $self = shift; return %{$self->{constHeadingSizeHash}}; }
    sub constHeadingSpacingHash
        { my $self = shift; return %{$self->{constHeadingSpacingHash}}; }

    sub useEchoFlag
        { $_[0]->{useEchoFlag} }
    sub useSgaFlag
        { $_[0]->{useSgaFlag} }
    sub useTTypeFlag
        { $_[0]->{useTTypeFlag} }
    sub useEorFlag
        { $_[0]->{useEorFlag} }
    sub useNawsFlag
        { $_[0]->{useNawsFlag} }
    sub useNewEnvironFlag
        { $_[0]->{useNewEnvironFlag} }
    sub useCharSetFlag
        { $_[0]->{useCharSetFlag} }

    sub useMsdpFlag
        { $_[0]->{useMsdpFlag} }
    sub useMsspFlag
        { $_[0]->{useMsspFlag} }
    sub useMccpFlag
        { $_[0]->{useMccpFlag} }
    sub useMspFlag
        { $_[0]->{useMspFlag} }
    sub useMxpFlag
        { $_[0]->{useMxpFlag} }
    sub usePuebloFlag
        { $_[0]->{usePuebloFlag} }
    sub useZmpFlag
        { $_[0]->{useZmpFlag} }
    sub useAard102Flag
        { $_[0]->{useAard102Flag} }
    sub useAtcpFlag
        { $_[0]->{useAtcpFlag} }
    sub useGmcpFlag
        { $_[0]->{useGmcpFlag} }
    sub useMttsFlag
        { $_[0]->{useMttsFlag} }
    sub useMcpFlag
        { $_[0]->{useMcpFlag} }

    sub constMsspVarHash
        { my $self = shift; return %{$self->{constMsspVarHash}}; }
    sub constMsspVarList
        { my $self = shift; return @{$self->{constMsspVarList}}; }

    sub constMspVersion
        { $_[0]->{constMspVersion} }
    sub allowMspMultipleFlag
        { $_[0]->{allowMspMultipleFlag} }
    sub allowMspLoadSoundFlag
        { $_[0]->{allowMspLoadSoundFlag} }
    sub allowMspFlexibleFlag
        { $_[0]->{allowMspFlexibleFlag} }

    sub constMxpVersion
        { $_[0]->{constMxpVersion} }
    sub constMxpOfficialHash
        { my $self = shift; return %{$self->{constMxpOfficialHash}}; }
    sub constMxpAttribHash
        { my $self = shift; return %{$self->{constMxpAttribHash}}; }
    sub constMxpConvertHash
        { my $self = shift; return %{$self->{constMxpConvertHash}}; }
    sub constMxpLineSpacingHash
        { my $self = shift; return %{$self->{constMxpLineSpacingHash}}; }
    sub constMxpModalHash
        { my $self = shift; return %{$self->{constMxpModalHash}}; }
    sub constMxpStackConvertHash
        { my $self = shift; return %{$self->{constMxpStackConvertHash}}; }
    sub constMxpModalOnHash
        { my $self = shift; return %{$self->{constMxpModalOnHash}}; }
    sub constMxpFormatHash
        { my $self = shift; return %{$self->{constMxpFormatHash}}; }
    sub constMxpEntityHash
        { my $self = shift; return %{$self->{constMxpEntityHash}}; }
    sub allowMxpFontFlag
        { $_[0]->{allowMxpFontFlag} }
    sub allowMxpImageFlag
        { $_[0]->{allowMxpImageFlag} }
    sub allowMxpLoadImageFlag
        { $_[0]->{allowMxpLoadImageFlag} }
    sub allowMxpFilterImageFlag
        { $_[0]->{allowMxpFilterImageFlag} }
    sub allowMxpSoundFlag
        { $_[0]->{allowMxpSoundFlag} }
    sub allowMxpLoadSoundFlag
        { $_[0]->{allowMxpLoadSoundFlag} }
    sub allowMxpGaugeFlag
        { $_[0]->{allowMxpGaugeFlag} }
    sub allowMxpFrameFlag
        { $_[0]->{allowMxpFrameFlag} }
    sub allowMxpInteriorFlag
        { $_[0]->{allowMxpInteriorFlag} }
    sub allowMxpCrosslinkFlag
        { $_[0]->{allowMxpCrosslinkFlag} }
    sub allowMxpRoomFlag
        { $_[0]->{allowMxpRoomFlag} }
    sub allowMxpFlexibleFlag
        { $_[0]->{allowMxpFlexibleFlag} }
    sub allowMxpPermFlag
        { $_[0]->{allowMxpPermFlag} }
    sub mxpPreventSupportFlag
        { $_[0]->{mxpPreventSupportFlag} }

    sub constPuebloOfficialHash
        { my $self = shift; return %{$self->{constPuebloOfficialHash}}; }
    sub constPuebloImplementHash
        { my $self = shift; return %{$self->{constPuebloImplementHash}}; }
    sub constPuebloConvertHash
        { my $self = shift; return %{$self->{constPuebloConvertHash}}; }
    sub constPuebloModalHash
        { my $self = shift; return %{$self->{constPuebloModalHash}}; }

    sub zmpPackageHash
        { my $self = shift; return %{$self->{zmpPackageHash}}; }

    sub constMcpPackageList
        { my $self = shift; return @{$self->{constMcpPackageList}}; }
    sub mcpPackageHash
        { my $self = shift; return %{$self->{mcpPackageHash}}; }

    sub constTermTypeList
        { my $self = shift; return @{$self->{constTermTypeList}}; }
    sub termTypeMode
        { $_[0]->{termTypeMode} }
    sub customClientName
        { $_[0]->{customClientName} }
    sub customClientVersion
        { $_[0]->{customClientVersion} }

    sub useCtrlSeqFlag
        { $_[0]->{useCtrlSeqFlag} }
    sub useVisibleCursorFlag
        { $_[0]->{useVisibleCursorFlag} }
    sub useFastCursorFlag
        { $_[0]->{useFastCursorFlag} }
    sub useDirectKeysFlag
        { $_[0]->{useDirectKeysFlag} }
    sub constDirectAppKeysHash
        { my $self = shift; return %{$self->{constDirectAppKeysHash}}; }
    sub constDirectAltKeysHash
        { my $self = shift; return %{$self->{constDirectAltKeysHash}}; }
    sub constDirectKeysHash
        { my $self = shift; return %{$self->{constDirectKeysHash}}; }
    sub constDirectSpecialKeysHash
        { my $self = shift; return %{$self->{constDirectSpecialKeysHash}}; }

    sub debugEscSequenceFlag
        { $_[0]->{debugEscSequenceFlag} }
    sub debugTelnetFlag
        { $_[0]->{debugTelnetFlag} }
    sub debugTelnetMiniFlag
        { $_[0]->{debugTelnetMiniFlag} }
    sub debugTelnetLogFlag
        { $_[0]->{debugTelnetLogFlag} }
    sub debugMsdpFlag
        { $_[0]->{debugMsdpFlag} }
    sub debugMxpFlag
        { $_[0]->{debugMxpFlag} }
    sub debugMxpCommentFlag
        { $_[0]->{debugMxpCommentFlag} }
    sub debugPuebloFlag
        { $_[0]->{debugPuebloFlag} }
    sub debugPuebloCommentFlag
        { $_[0]->{debugPuebloCommentFlag} }
    sub debugZmpFlag
        { $_[0]->{debugZmpFlag} }
    sub debugAtcpFlag
        { $_[0]->{debugAtcpFlag} }
    sub debugGmcpFlag
        { $_[0]->{debugGmcpFlag} }
    sub debugMcpFlag
        { $_[0]->{debugMcpFlag} }

    sub shareMainWinFlag
        { $_[0]->{shareMainWinFlag} }
    sub restartShareMainWinMode
        { $_[0]->{restartShareMainWinMode} }
    sub activateGridFlag
        { $_[0]->{activateGridFlag} }
    sub storeGridPosnFlag
        { $_[0]->{storeGridPosnFlag} }
    sub storeGridPosnHash
        { my $self = shift; return %{$self->{storeGridPosnHash}}; }

    sub constGridWinTypeHash
        { my $self = shift; return %{$self->{constGridWinTypeHash}}; }
    sub constFreeWinTypeHash
        { my $self = shift; return %{$self->{constFreeWinTypeHash}}; }

    sub constWinmapNameHash
        { my $self = shift; return %{$self->{constWinmapNameHash}}; }
    sub winmapHash
        { my $self = shift; return %{$self->{winmapHash}}; }
    sub standardWinmapHash
        { my $self = shift; return %{$self->{standardWinmapHash}}; }
    sub constDefaultEnabledWinmap
        { $_[0]->{constDefaultEnabledWinmap} }
    sub constDefaultDisabledWinmap
        { $_[0]->{constDefaultDisabledWinmap} }
    sub constDefaultInternalWinmap
        { $_[0]->{constDefaultInternalWinmap} }
    sub defaultEnabledWinmap
        { $_[0]->{defaultEnabledWinmap} }
    sub defaultDisabledWinmap
        { $_[0]->{defaultDisabledWinmap} }
    sub defaultInternalWinmap
        { $_[0]->{defaultInternalWinmap} }

    sub constGridBlockSize
        { $_[0]->{constGridBlockSize} }
    sub gridBlockSize
        { $_[0]->{gridBlockSize} }

    sub constZonemapHash
        { my $self = shift; return %{$self->{constZonemapHash}}; }
    sub zonemapHash
        { my $self = shift; return %{$self->{zonemapHash}}; }
    sub standardZonemapHash
        { my $self = shift; return %{$self->{standardZonemapHash}}; }
    sub constInitWorkspaceHash
        { my $self = shift; return %{$self->{constInitWorkspaceHash}}; }
    sub initWorkspaceHash
        { my $self = shift; return %{$self->{initWorkspaceHash}}; }
    sub constInitWorkspaceDir
        { $_[0]->{constInitWorkspaceDir} }
    sub initWorkspaceDir
        { $_[0]->{initWorkspaceDir} }

    sub constGridGapMaxSize
        { $_[0]->{constGridGapMaxSize} }
    sub gridGapMaxSize
        { $_[0]->{gridGapMaxSize} }
    sub gridAdjustmentFlag
        { $_[0]->{gridAdjustmentFlag} }
    sub gridEdgeCorrectionFlag
        { $_[0]->{gridEdgeCorrectionFlag} }
    sub gridReshuffleFlag
        { $_[0]->{gridReshuffleFlag} }
    sub gridInvisWinFlag
        { $_[0]->{gridInvisWinFlag} }

    sub constWorkspaceMaxWidth
        { $_[0]->{constWorkspaceMaxWidth} }
    sub constWorkspaceMaxHeight
        { $_[0]->{constWorkspaceMaxHeight} }
    sub constWorkspaceMinWidth
        { $_[0]->{constWorkspaceMinWidth} }
    sub constWorkspaceMinHeight
        { $_[0]->{constWorkspaceMinHeight} }

    sub constMainWinWidth
        { $_[0]->{constMainWinWidth} }
    sub constMainWinHeight
        { $_[0]->{constMainWinHeight} }
    sub customMainWinWidth
        { $_[0]->{customMainWinWidth} }
    sub customMainWinHeight
        { $_[0]->{customMainWinHeight} }
    sub constMainBorderPixels
        { $_[0]->{constMainBorderPixels} }
    sub constMainSpacingPixels
        { $_[0]->{constMainSpacingPixels} }

    sub constGridWinWidth
        { $_[0]->{constGridWinWidth} }
    sub constGridWinHeight
        { $_[0]->{constGridWinHeight} }
    sub customGridWinWidth
        { $_[0]->{customGridWinWidth} }
    sub customGridWinHeight
        { $_[0]->{customGridWinHeight} }
    sub constGridBorderPixels
        { $_[0]->{constGridBorderPixels} }
    sub constGridSpacingPixels
        { $_[0]->{constGridSpacingPixels} }

    sub constFreeWinWidth
        { $_[0]->{constFreeWinWidth} }
    sub constFreeWinHeight
        { $_[0]->{constFreeWinHeight} }
    sub customFreeWinWidth
        { $_[0]->{customFreeWinWidth} }
    sub customFreeWinHeight
        { $_[0]->{customFreeWinHeight} }
    sub constFreeBorderPixels
        { $_[0]->{constFreeBorderPixels} }
    sub constFreeSpacingPixels
        { $_[0]->{constFreeSpacingPixels} }
    sub constDialogueLabelSize
        { $_[0]->{constDialogueLabelSize} }

    sub constPanelSize
        { $_[0]->{constPanelSize} }
    sub constPanelLeftSize
        { $_[0]->{constPanelLeftSize} }
    sub constPanelRightSize
        { $_[0]->{constPanelRightSize} }
    sub constPanelTopSize
        { $_[0]->{constPanelTopSize} }
    sub constPanelBottomSize
        { $_[0]->{constPanelBottomSize} }
    sub customPanelLeftSize
        { $_[0]->{customPanelLeftSize} }
    sub customPanelRightSize
        { $_[0]->{customPanelRightSize} }
    sub customPanelTopSize
        { $_[0]->{customPanelTopSize} }
    sub customPanelBottomSize
        { $_[0]->{customPanelBottomSize} }

    sub constControlsSize
        { $_[0]->{constControlsSize} }
    sub constControlsLeftSize
        { $_[0]->{constControlsLeftSize} }
    sub constControlsRightSize
        { $_[0]->{constControlsRightSize} }
    sub constControlsTopSize
        { $_[0]->{constControlsTopSize} }
    sub constControlsBottomSize
        { $_[0]->{constControlsBottomSize} }
    sub customControlsLeftSize
        { $_[0]->{customControlsLeftSize} }
    sub customControlsRightSize
        { $_[0]->{customControlsRightSize} }
    sub customControlsTopSize
        { $_[0]->{customControlsTopSize} }
    sub customControlsBottomSize
        { $_[0]->{customControlsBottomSize} }

    sub constTextColour
        { $_[0]->{constTextColour} }
    sub constUnderlayColour
        { $_[0]->{constUnderlayColour} }
    sub constBackgroundColour
        { $_[0]->{constBackgroundColour} }
    sub constFont
        { $_[0]->{constFont} }
    sub constFontSize
        { $_[0]->{constFontSize} }
    sub constPuebloLinkColour
        { $_[0]->{constPuebloLinkColour} }
    sub colourSchemeHash
        { my $self = shift; return %{$self->{colourSchemeHash}}; }

    sub constInsertCmdColour
        { $_[0]->{constInsertCmdColour} }
    sub constShowSystemTextColour
        { $_[0]->{constShowSystemTextColour} }
    sub constShowErrorColour
        { $_[0]->{constShowErrorColour} }
    sub constShowWarningColour
        { $_[0]->{constShowWarningColour} }
    sub constShowDebugColour
        { $_[0]->{constShowDebugColour} }
    sub constShowImproperColour
        { $_[0]->{constShowImproperColour} }
    sub customInsertCmdColour
        { $_[0]->{customInsertCmdColour} }
    sub customShowSystemTextColour
        { $_[0]->{customShowSystemTextColour} }
    sub customShowErrorColour
        { $_[0]->{customShowErrorColour} }
    sub customShowWarningColour
        { $_[0]->{customShowWarningColour} }
    sub customShowDebugColour
        { $_[0]->{customShowDebugColour} }
    sub customShowImproperColour
        { $_[0]->{customShowImproperColour} }

    sub convertInvisibleFlag
        { $_[0]->{convertInvisibleFlag} }
    sub constTextBufferSize
        { $_[0]->{constTextBufferSize} }
    sub customTextBufferSize
        { $_[0]->{customTextBufferSize} }

    sub constNormalCursor
        { $_[0]->{constNormalCursor} }
    sub constWWWCursor
        { $_[0]->{constWWWCursor} }
    sub constPromptCursor
        { $_[0]->{constPromptCursor} }
    sub constPopupCursor
        { $_[0]->{constPopupCursor} }
    sub constCmdCursor
        { $_[0]->{constCmdCursor} }
    sub constMailCursor
        { $_[0]->{constMailCursor} }
    sub constTelnetCursor
        { $_[0]->{constTelnetCursor} }
    sub constMapCursor
        { $_[0]->{constMapCursor} }
    sub constMapAddCursor
        { $_[0]->{constMapAddCursor} }
    sub constMapConnectCursor
        { $_[0]->{constMapConnectCursor} }
    sub constMapMergeCursor
        { $_[0]->{constMapMergeCursor} }

    sub constUpIconPath
        { $_[0]->{constUpIconPath} }
    sub constDownIconPath
        { $_[0]->{constDownIconPath} }
    sub constResetIconPath
        { $_[0]->{constResetIconPath} }
    sub constCaseIconPath
        { $_[0]->{constCaseIconPath} }
    sub constRegexIconPath
        { $_[0]->{constRegexIconPath} }
    sub constDivideIconPath
        { $_[0]->{constDivideIconPath} }
    sub constWipeIconPath
        { $_[0]->{constWipeIconPath} }
    sub constAddIconPath
        { $_[0]->{constAddIconPath} }
    sub constEmptyIconPath
        { $_[0]->{constEmptyIconPath} }
    sub constSystemIconPath
        { $_[0]->{constSystemIconPath} }
    sub constDebugIconPath
        { $_[0]->{constDebugIconPath} }
    sub constErrorIconPath
        { $_[0]->{constErrorIconPath} }
    sub constMultiIconPath
        { $_[0]->{constMultiIconPath} }
    sub constSearchIconPath
        { $_[0]->{constSearchIconPath} }
    sub constCancelIconPath
        { $_[0]->{constCancelIconPath} }
    sub constSwitchIconPath
        { $_[0]->{constSwitchIconPath} }
    sub constSplitIconPath
        { $_[0]->{constSplitIconPath} }
    sub constRestoreIconPath
        { $_[0]->{constRestoreIconPath} }
    sub constScrollIconPath
        { $_[0]->{constScrollIconPath} }
    sub constLockIconPath
        { $_[0]->{constLockIconPath} }

    sub constIconSizeList
        { my $self = shift; return @{$self->{constIconSizeList}}; }

    sub guiPrivateFlag
        { $_[0]->{guiPrivateFlag} }
    sub guiPrivateMenuFlag
        { $_[0]->{guiPrivateMenuFlag} }

    sub constStripHash
        { my $self = shift; return %{$self->{constStripHash}}; }
    sub customStripHash
        { my $self = shift; return %{$self->{customStripHash}}; }
    sub constTableHash
        { my $self = shift; return %{$self->{constTableHash}}; }
    sub customTableHash
        { my $self = shift; return %{$self->{customTableHash}}; }

    sub constToolbarList
        { my $self = shift; return @{$self->{constToolbarList}}; }
    sub toolbarHash
        { my $self = shift; return %{$self->{toolbarHash}}; }
    sub toolbarList
        { my $self = shift; return @{$self->{toolbarList}}; }

    sub constLinuxCmdList
        { my $self = shift; return @{$self->{constLinuxCmdList}}; }
    sub constMSWinCmdList
        { my $self = shift; return @{$self->{constMSWinCmdList}}; }
    sub constBSDCmdList
        { my $self = shift; return @{$self->{constBSDCmdList}}; }
    sub browserCmd
        { $_[0]->{browserCmd} }
    sub emailCmd
        { $_[0]->{emailCmd} }
    sub audioCmd
        { $_[0]->{audioCmd} }
    sub textEditCmd
        { $_[0]->{textEditCmd} }

    sub constSoundFormatHash
        { my $self = shift; return %{$self->{constSoundFormatHash}}; }
    sub allowSoundFlag
        { $_[0]->{allowSoundFlag} }
    sub allowAsciiBellFlag
        { $_[0]->{allowAsciiBellFlag} }
    sub constStandardSoundHash
        { my $self = shift; return %{$self->{constStandardSoundHash}}; }
    sub constExtendedSoundHash
        { my $self = shift; return %{$self->{constExtendedSoundHash}}; }
    sub customSoundHash
        { my $self = shift; return %{$self->{customSoundHash}}; }

    sub customAllowTTSFlag
        { $_[0]->{customAllowTTSFlag} }
    sub systemAllowTTSFlag
        { $_[0]->{systemAllowTTSFlag} }
    sub forceTTSEngine
        { $_[0]->{forceTTSEngine} }
    sub constTTSList
        { my $self = shift; return @{$self->{constTTSList}}; }
    sub constTTSCompatList
        { my $self = shift; return @{$self->{constTTSCompatList}}; }
    sub eSpeakPath
        { $_[0]->{eSpeakPath} }
    sub ttsSmoothFlag
        { $_[0]->{ttsSmoothFlag} }

    sub constTtsDefaultList
        { my $self = shift; return @{$self->{constTtsDefaultList}}; }
    sub constTtsObjHash
        { my $self = shift; return %{$self->{constTtsObjHash}}; }
    sub constTtsPermObjHash
        { my $self = shift; return %{$self->{constTtsPermObjHash}}; }
    sub constTtsFixedObjHash
        { my $self = shift; return %{$self->{constTtsFixedObjHash}}; }
    sub ttsObjHash
        { my $self = shift; return %{$self->{ttsObjHash}}; }

    sub constTtsAttribHash
        { my $self = shift; return %{$self->{constTtsAttribHash}}; }
    sub ttsAttribHash
        { my $self = shift; return %{$self->{ttsAttribHash}}; }
    sub constTtsFlagAttribHash
        { my $self = shift; return %{$self->{constTtsFlagAttribHash}}; }
    sub ttsFlagAttribHash
        { my $self = shift; return %{$self->{ttsFlagAttribHash}}; }
    sub constTtsAlertAttribHash
        { my $self = shift; return %{$self->{constTtsAlertAttribHash}}; }
    sub ttsAlertAttribHash
        { my $self = shift; return %{$self->{ttsAlertAttribHash}}; }

    sub ttsReceiveFlag
        { $_[0]->{ttsReceiveFlag} }
    sub ttsLoginFlag
        { $_[0]->{ttsLoginFlag} }
    sub ttsSystemFlag
        { $_[0]->{ttsSystemFlag} }
    sub ttsSystemErrorFlag
        { $_[0]->{ttsSystemErrorFlag} }
    sub ttsWorldCmdFlag
        { $_[0]->{ttsWorldCmdFlag} }
    sub ttsDialogueFlag
        { $_[0]->{ttsDialogueFlag} }
    sub ttsTaskFlag
        { $_[0]->{ttsTaskFlag} }

    sub constTtsFestivalServerPort
        { $_[0]->{constTtsFestivalServerPort} }
    sub ttsFestivalServerPort
        { $_[0]->{ttsFestivalServerPort} }
    sub ttsFestivalServer
        { $_[0]->{ttsFestivalServer} }
    sub ttsStartServerFlag
        { $_[0]->{ttsStartServerFlag} }
    sub ttsFestivalServerMode
        { $_[0]->{ttsFestivalServerMode} }

    sub constMonthList
        { my $self = shift; return @{$self->{constMonthList}}; }
    sub customMonthList
        { my $self = shift; return @{$self->{customMonthList}}; }
    sub constDayList
        { my $self = shift; return @{$self->{constDayList}}; }
    sub customDayList
        { my $self = shift; return @{$self->{customDayList}}; }
    sub constRomanHash
        { my $self = shift; return %{$self->{constRomanHash}}; }

    sub constIPLookupList
        { my $self = shift; return @{$self->{constIPLookupList}}; }

    sub constHelpCharLimit
        { $_[0]->{constHelpCharLimit} }

    sub startTime
        { $_[0]->{startTime} }
    sub startClock
        { $_[0]->{startClock} }
    sub startDate
        { $_[0]->{startDate} }
    sub startClockString
        { $_[0]->{startClockString} }
    sub startDateString
        { $_[0]->{startDateString} }

    sub constPromptWaitTime
        { $_[0]->{constPromptWaitTime} }
    sub promptWaitTime
        { $_[0]->{promptWaitTime} }
    sub constLoginWarningTime
        { $_[0]->{constLoginWarningTime} }
    sub loginWarningTime
        { $_[0]->{loginWarningTime} }

    sub toolbarLabelFlag
        { $_[0]->{toolbarLabelFlag} }
    sub irreversibleIconFlag
        { $_[0]->{irreversibleIconFlag} }
    sub allowBusyWinFlag
        { $_[0]->{allowBusyWinFlag} }
    sub mainWinSystemMsgFlag
        { $_[0]->{mainWinSystemMsgFlag} }
    sub mainWinUrgencyFlag
        { $_[0]->{mainWinUrgencyFlag} }
    sub mainWinTooltipFlag
        { $_[0]->{mainWinTooltipFlag} }

    sub commifyMode
        { $_[0]->{commifyMode} }

    sub tempUrgencyFlag
        { $_[0]->{tempUrgencyFlag} }
    sub tempSoundFlag
        { $_[0]->{tempSoundFlag} }

    sub constUrlRegex
        { $_[0]->{constUrlRegex} }
    sub constShortUrlRegex
        { $_[0]->{constShortUrlRegex} }
    sub shortUrlFlag
        { $_[0]->{shortUrlFlag} }
    sub constEmailRegex
        { $_[0]->{constEmailRegex} }

    sub privConfigAllWorld
        { $_[0]->{privConfigAllWorld} }

    sub benchMarkTime
        { $_[0]->{benchMarkTime} }
    sub benchMarkShortList
        { my $self = shift; return @{$self->{benchMarkShortList}}; }
    sub benchMarkLongList
        { my $self = shift; return @{$self->{benchMarkLongList}}; }

    sub debugLineNumsFlag
        { $_[0]->{debugLineNumsFlag} }
    sub debugLineTagsFlag
        { $_[0]->{debugLineTagsFlag} }
    sub debugLocatorFlag
        { $_[0]->{debugLocatorFlag} }
    sub debugExitFlag
        { $_[0]->{debugExitFlag} }
    sub debugMaxLocatorFlag
        { $_[0]->{debugMaxLocatorFlag} }
    sub debugMoveListFlag
        { $_[0]->{debugMoveListFlag} }
    sub debugParseObjFlag
        { $_[0]->{debugParseObjFlag} }
    sub debugCompareObjFlag
        { $_[0]->{debugCompareObjFlag} }
    sub debugExplainPluginFlag
        { $_[0]->{debugExplainPluginFlag} }
    sub debugCheckIVFlag
        { $_[0]->{debugCheckIVFlag} }
    sub debugTableFitFlag
        { $_[0]->{debugTableFitFlag} }
    sub debugTrapErrorFlag
        { $_[0]->{debugTrapErrorFlag} }

    sub allowSetupWizWinFlag
        { $_[0]->{allowSetupWizWinFlag} }
    sub showSetupWizWinFlag
        { $_[0]->{showSetupWizWinFlag} }
    sub blockWorldHintFlag
        { $_[0]->{blockWorldHintFlag} }
}

# Package must return a true value
1
