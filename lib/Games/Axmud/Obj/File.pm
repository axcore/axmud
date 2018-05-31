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
# Games::Axmud::Obj::File
# The code that handles a single data file

{ package Games::Axmud::Obj::File;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Client->createFileObjs and ->loadWorldProfs
        # Also called by GA::Session->createFileObj and GA::Cmd::Save->do
        #
        # Expected arguments
        #   $fileType      - one of the types listed below
        #       TYPE        PATH
        #       config      <DATA_DIR>/axmud.conf
        #       worldprof   <DATA_DIR>/data/worlds/<WORLD>/worldprof.axm
        #       otherprof   <DATA_DIR>/data/worlds/<WORLD>/otherprof.axm
        #       worldmodel  <DATA_DIR>/data/worlds/<WORLD>/worldmodel.axm
        #       tasks       <DATA_DIR>/data/tasks.axm
        #       scripts     <DATA_DIR>/data/scripts.axm
        #       contacts    <DATA_DIR>/data/contacts.axm
        #       keycodes    <DATA_DIR>/data/keycodes.axm
        #       dicts       <DATA_DIR>/data/dicts.axm
        #       toolbar     <DATA_DIR>/data/toolbar.axm
        #       usercmds    <DATA_DIR>/data/usercmds.axm
        #       zonemaps    <DATA_DIR>/data/zonemaps.axm
        #       winmaps     <DATA_DIR>/data/winmaps.axm
        #       tts         <DATA_DIR>/data/tts.axm
        #
        # Optional arguments
        #   $assocWorldProf - For the file types 'worldprof', 'otherprof' and 'worldmodel', the name
        #                       of the associated world profile - needed so we can set the path and
        #                       directory ('undef' for other file types)
        #   $session        - For the file types 'otherprof' and 'worldmodel', the name of the
        #                       calling GA::Session ('undef' for other files types)
        #
        # Return values
        #   'undef' on improper arguments or if $fileType isn't recognised
        #   Blessed reference to the newly-created object on success

        my ($class, $fileType, $assocWorldProf, $session, $check) = @_;

        # Local variables
        my (
            $name, $standardFileName, $standardPath, $standardDir, $altFileName,
            $altPath,
        );

        # Check for improper arguments
        if (
            ! defined $class
            || ! defined $fileType
            || (
                defined $assocWorldProf && $fileType ne 'worldprof' && $fileType ne 'otherprof'
                && $fileType ne 'worldmodel'
            ) || (
                ! defined $assocWorldProf && (
                    $fileType eq 'worldprof' || $fileType eq 'otherprof'
                    || $fileType eq 'worldmodel'
                )
            ) || (defined $session && $fileType ne 'otherprof' && $fileType ne 'worldmodel')
            || (! defined $session && ($fileType eq 'otherprof' || $fileType eq 'worldmodel'))
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Prepare variables this file type
        if ($fileType eq 'config') {

            if ($^O eq 'MSWin32') {

                $standardFileName = $axmud::NAME_SHORT . '.ini';
                $standardPath = '/' . $axmud::NAME_SHORT . '.ini';
                $altFileName = $axmud::NAME_SHORT . '.conf';
                $altPath = '/' . $axmud::NAME_SHORT . '.conf';

            } else {

                $standardFileName = $axmud::NAME_SHORT . '.conf';
                $standardPath = '/' . $axmud::NAME_SHORT . '.conf';
                $altFileName = $axmud::NAME_SHORT . '.ini';
                $altPath = '/' . $axmud::NAME_SHORT . '.ini';
            }

            $standardDir = '';

        } elsif ($fileType eq 'worldprof') {

            $standardFileName = 'worldprof.axm';
            $standardPath = '/data/worlds/' . $assocWorldProf . '/' . $standardFileName;
            $standardDir = '/data/worlds/' . $assocWorldProf;

        } elsif ($fileType eq 'otherprof') {

            $standardFileName = 'otherprof.axm';
            $standardPath = '/data/worlds/' . $assocWorldProf . '/' . $standardFileName;
            $standardDir = '/data/worlds/' . $assocWorldProf;

        } elsif ($fileType eq 'worldmodel') {

            $standardFileName = 'worldmodel.axm';
            $standardPath = '/data/worlds/' . $assocWorldProf . '/' . $standardFileName;
            $standardDir = '/data/worlds/' . $assocWorldProf;

        } elsif ($fileType eq 'tasks') {

            $standardFileName = 'tasks.axm';
            $standardPath = '/data/tasks.axm';
            $standardDir = '/data';

        } elsif ($fileType eq 'scripts') {

            $standardFileName = 'scripts.axm';
            $standardPath = '/data/scripts.axm';
            $standardDir = '/data';

        } elsif ($fileType eq 'contacts') {

            $standardFileName = 'contacts.axm';
            $standardPath = '/data/contacts.axm';
            $standardDir = '/data';

        } elsif ($fileType eq 'keycodes') {

            $standardFileName = 'keycodes.axm';
            $standardPath = '/data/keycodes.axm';
            $standardDir = '/data';

        } elsif ($fileType eq 'dicts') {

            $standardFileName = 'dicts.axm';
            $standardPath = '/data/dicts.axm';
            $standardDir = '/data';

        } elsif ($fileType eq 'toolbar') {

            $standardFileName = 'toolbar.axm';
            $standardPath = '/data/toolbar.axm';
            $standardDir = '/data';

        } elsif ($fileType eq 'usercmds') {

            $standardFileName = 'usercmds.axm';
            $standardPath = '/data/usercmds.axm';
            $standardDir = '/data';

        } elsif ($fileType eq 'zonemaps') {

            $standardFileName = 'zonemaps.axm';
            $standardPath = '/data/zonemaps.axm';
            $standardDir = '/data';

        } elsif ($fileType eq 'winmaps') {

            $standardFileName = 'winmaps.axm';
            $standardPath = '/data/winmaps.axm';
            $standardDir = '/data';

        } elsif ($fileType eq 'tts') {

            $standardFileName = 'tts.axm';
            $standardPath = '/data/tts.axm';
            $standardDir = '/data';

        } else {

            # Unrecognised file type
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        if ($fileType eq 'worldprof') {
            $name = $assocWorldProf;
        } else {
            $name = $fileType;
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _parentFile                 => undef,       # File objects don't have parent file object
            _parentWorld                => undef,       # See above
            _objClass                   => $class,
            _privFlag                   => TRUE,        # All IVs are private

            # Perl object components
            # ----------------------

            # The parent GA::Session object (only set for 'otherprof' and 'worldmodel' file types)
            session                     => $session,

            # Other IVs
            # ---------

            # Unique name for the FileObj
            name                        => $name,

            # The information included in a file's header (i.e. the meta-data)
            fileType                    => $fileType,
            scriptName                  => undef,
            scriptVersion               => undef,    # e.g. '1.0.5'
            scriptConvertVersion        => undef,    # Set by call to GA::Client->convertVersion
            saveDate                    => undef,
            saveTime                    => undef,
            # For file types 'worldprof', 'otherprof' and 'worldmodel', the name of the associated
            #   world profile (e.g. 'myworld') (default: 'undef')
            assocWorldProf              => $assocWorldProf,

            # File name, e.g. 'tasks.axm'
            actualFileName              => undef,
            # Full path of the file, e.g. '/home/me/axmud/data/tasks.axm'
            actualPath                  => undef,
            # Directory
            actualDir                   => undef,

            # The standard paths for this file type
            standardFileName            => $standardFileName,
            # (Relative to script's directory)
            standardPath                => $standardPath,
            # (Relative to script's directory)
            standardDir                 => $standardDir,

            # For file type 'config', ->standardFileName ends .ini on MS Windows, .conf on Linux.
            #   For portability, these variables contains the standard filename on the operating
            #   system currently NOT in use
            altFileName                 => $altFileName,
            altPath                     => $altPath,

            # This flag should be set to TRUE (by the accessor functions inherited from the generic
            #   object Games::Axmud) whenever some of the data it contains is modified
            modifyFlag                  => FALSE,
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub setupConfigFile {

        # Called by GA::Client->start for the file types:
        #   'config'
        # Loads the config file. If the file doesn't exist, creates it
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or if there any errors reading/writing the file, or if
        #       file loading/saving isn't allowed (because of global flags)
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setupConfigFile', @_);
        }

        # Check it's the right file type for this function
        if ($self->fileType ne 'config') {

            return $self->writeError(
                'Wrong file type \'' . $self->fileType . '\'',
                $self->_objClass . '->setupConfigFile',
            );
        }

        # Delete all data and logfiles, if the flag is set
        if ($axmud::CLIENT->deleteFilesAtStartFlag) {

            # Need to delete the config file, so that a brand new one can be written (as if none had
            #   existed before)
            if (-e $axmud::DATA_DIR . $self->standardPath) {

                # Config file on this operating system
                unlink ($axmud::DATA_DIR . $self->standardPath);
            }

            if (-e $axmud::DATA_DIR . $self->altPath) {

                # Config file on the other operating system
                unlink ($axmud::DATA_DIR . $self->altPath);
            }

            # Also delete the /data directory
            if (-e $axmud::DATA_DIR . '/data' ) {

                File::Path::remove_tree($axmud::DATA_DIR . '/data');
            }

            # Also delete /logs directory
            if (-e $axmud::DATA_DIR . '/logs') {

                File::Path::remove_tree($axmud::DATA_DIR . '/logs');
            }

            # Re-create all standard directories
            $axmud::CLIENT->createDataDirs();
        }

        # Check whether the config file already exists, and if we're allowed to load it
        if (
            $axmud::CLIENT->loadConfigFlag
            && (
                -e $axmud::DATA_DIR . $self->standardPath
                || -e $axmud::DATA_DIR . $self->altPath
            )
        ) {
            # The file exists and we are allowed to load it, so try to load it
            if (! $self->loadConfigFile()) {

                return $self->writeError(
                    'Error reading \'' . $self->fileType . '\' data file',
                    $self->_objClass . '->setupConfigFile',
                );

            } else {

                return 1;
            }

        } elsif (
            $axmud::CLIENT->saveConfigFlag
            && ! (
                -e $axmud::DATA_DIR . $self->standardPath
                || -e $axmud::DATA_DIR . $self->altPath
            )
        ) {
            # The file doesn't exist, but we are allowed to create it

            # Move files from Axmud's base sub-directories (default sound effects, default icons,
            #   etc) into its data directories
            $axmud::CLIENT->fillDataDirs();

            # Copy pre-configured worlds into the data directory, and add entries for each of them
            #   in the GA::Client's directories
            $axmud::CLIENT->copyPreConfigWorlds();

            # Try to create a config file
            if (! $self->saveConfigFile()) {

                return $self->writeError(
                    'Error creating \'' . $self->fileType . '\' data file',
                    $self->_objClass . '->setupConfigFile',
                );
            }

            # The call to ->copyPreConfigWorlds will have added some dummy entries to the client's
            #   world registry; remove them (but create new entries in
            #   GA::Client->configWorldProfList, as if we had just read the config file, rather
            #   than delete it)
            $axmud::CLIENT->cleanPreConfigWorlds();

            # Set a flag to show the 'dialogue' window which invites the user to add tasks to the
            #   global initial tasklist, the first time the script is run
            if ($axmud::CLIENT->allowSetupWizWinFlag) {

                $axmud::CLIENT->set_showSetupWizWinFlag(TRUE);
            }

            return 1;

        } else {

            # Cannot load or save the config file
            return undef;
        }
    }

    sub saveConfigFile {

        # Called by $self->setupConfigFile for the file types:
        #   'config'
        # Saves the config file
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $fileName   - The file name, e.g. 'axmud.conf'
        #   $path       - The full path, e.g. '/home/me/axmud-data/axmud.conf'
        #   $dir        - The directory, e.g. '/home/me/axmud-data/'
        #   $emergFlag  - If set to TRUE, an emergency save is in progress.
        #                   GA::Client->saveConfigFlag is ignored, $self->disableAllFileAccess is
        #                   not called on failure, and $self->modifyFlag is not set. Set to FALSE
        #                   (or 'undef') if an emergency save is not in progress
        #
        # Notes:
        #   If $fileName is specified, $path and $dir must also be specified
        #   If $fileName is not specified, the default filename, path and directory for this file
        #       type are used
        #
        # Return values
        #   'undef' on improper arguments, or if there any errors writing the file or in taking out
        #       a lock on the semaphore file
        #   1 otherwise

        my ($self, $fileName, $path, $dir, $emergFlag, $check) = @_;

        # Local variables
        my (
            $backupFile, $semaphoreFile, $semaphoreHandle, $saveDate, $saveTime, $fileHandle,
            $client, $result,
            @list, @workspaceList, @itemList, @modList,
            %workspaceHash, %itemHash, %worldHash,
        );

        # Check for improper arguments
        if (
            defined $check
            || (defined $fileName && (! defined $path || ! defined $dir))
            || (defined $path && (! defined $fileName || ! defined $dir))
            || (defined $dir && (! defined $fileName || ! defined $path))
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->saveConfigFile', @_);
        }

        # Check it's the right file type for this function
        if ($self->fileType ne 'config') {

            return $self->writeError(
                'Wrong file type \'' . $self->fileType . '\'',
                $self->_objClass . '->saveConfigFile',
            );
        }

        # Set the filename, path and directory, if not specified
        if (! defined $fileName) {

            $fileName = $self->standardFileName;
            $path = $axmud::DATA_DIR . $self->standardPath;
            $dir = $axmud::DATA_DIR . $self->standardDir;
        }

        # Checks made when an emergency save is NOT in progress...
        if (! $emergFlag) {

            # Don't save anything if the global flags forbid it
            if (! $axmud::CLIENT->saveConfigFlag) {

                return $self->disableSaveLoad(TRUE);
            }

            # Check that the data directory exists
            if (! (-d $dir)) {

                return $self->disableSaveLoad(TRUE);
            }
        }

        # Precautions taken when an emergency save is NOT in progress...
        if (! $emergFlag) {

            # If the config file already exists, make a backup copy in the /temp directory (it's not
            #   really necessary for the config file, which is so small, but for larger data files
            #   which take a long time to save, it's necessary to have a backup before overwriting
            #   an existing file)
            if (-e $path) {

                if ($axmud::CLIENT->autoRetainFileFlag) {

                    # Retain this 'temporary' file where the user can easily find it
                    $backupFile = $path . '.bu';

                } else {

                    # This really is a temporary file, so store it in the temporary files directory
                    $backupFile = $axmud::DATA_DIR . '/data/temp/config.bu';
                }

                File::Copy::copy($path, $backupFile);
            }

            # Get an exclusive lock on the twinned semaphore file
            $semaphoreFile = $axmud::DATA_DIR . '/data/temp/config.sem';
            $semaphoreHandle = $self->getFileLock($semaphoreFile, TRUE, $semaphoreFile);
            # Don't try to write the config file if no lock could be taken out on the semaphore file
            if (! $semaphoreHandle) {

                return $self->disableSaveLoad(FALSE);
            }

            # Open the file for writing, overwriting previous contents
            if (! open ($fileHandle, ">$path")) {

                # Could not open file
                return $self->disableSaveLoad(FALSE);
            }

        # (No precautions taken when an emergency save IS in progress)
        } else {

            # Open the file for writing, overwriting previous contents
            if (! open ($fileHandle, ">$path")) {

                return undef;
            }
        }

        # Need to add some values both to the file, and also to its header
        $saveDate = $axmud::CLIENT->localDate();
        $saveTime = $axmud::CLIENT->localTime();

        # Prepare header
        push (@list,
            '@@@ file_type config',
            '@@@ script_name ' . $axmud::NAME_FILE,
            '@@@ script_version ' . $axmud::VERSION,
            '@@@ save_date ' . $saveDate,
            '@@@ save_time ' . $saveTime,
            '@@@ assoc_world_prof not_applicable',
            '@@@ eos',
        );

        # Script data (for information - not used, when the config file is loaded)
        push (@list,
            '# SCRIPT DATA',
            '# Script name',
                $axmud::NAME_FILE,
            '# Script version',
                $axmud::VERSION,
            '# Script date',
                $axmud::DATE,
            '@@@ eos',
        );

        # For convenience, import the GA::Client
        $client = $axmud::CLIENT;

        # File object data
        push (@list,
            '# FILE OBJECTS',
            '# Allow config file load',
                $self->convert($client->loadConfigFlag),
            '# Allow config file save',
                $self->convert($client->saveConfigFlag),
            '# Allow data file load',
                $self->convert($client->loadDataFlag),
            '# Allow data file load',
                $self->convert($client->saveDataFlag),
            '# Delete data directory at startup',
                $self->convert($client->deleteFilesAtStartFlag),
            '# Prompt user to do emergency saves',
                $self->convert($client->emergencySaveFlag),
            '# Auto-saves turned on',
                $self->convert($client->autoSaveFlag),
            '# Auto-save wait time (minutes)',
                $client->autoSaveWaitTime,
            '# Auto-retain most recent temporary backup file',
                $client->autoRetainFileFlag,
            '@@@ eos',
        );

        # Plugin data
        push (@list,
            '# PLUGINS',
            '# Number of initial plugin files',
                scalar $client->initPluginList,
            '# List of initial plugin files',
                $client->initPluginList,
            '@@@ eos',
        );

        # Instruction data
        push (@list,
            '# INSTRUCTIONS',
            '# Enable echo commands',
                $self->convert($client->echoSigilFlag),
            '# Enable Perl commands',
                $self->convert($client->perlSigilFlag),
            '# Enable script commands',
                $self->convert($client->scriptSigilFlag),
            '# Enable multi commands',
                $self->convert($client->multiSigilFlag),
            '# Enable speedwalk commands',
                $self->convert($client->speedSigilFlag),
            '# Enable bypass commands',
                $self->convert($client->bypassSigilFlag),
            '# Command separator',
                $client->cmdSep,
            '@@@ eos',
        );

        # World profile data. Extract a list of world profile names and sort it alphabetically
        %worldHash = $axmud::CLIENT->worldProfHash;
        @itemList = sort {lc($a) cmp lc($b)} (keys %worldHash);
        # Filter out any unsaveable worlds, but use worlds (keys in %worldHash) with no
        #   corresponding profile objects (values in %worldHash), because those entries were
        #   probably created by GA::Client->copyPreConfigWorlds - and they must be saved in the
        #   config file
        foreach my $world (@itemList) {

            my $worldObj = $worldHash{$world};
            if (! $worldObj || ! $worldObj->noSaveFlag) {

                push (@modList, $world);
            }
        }

        push (@list,
            '# WORLD PROFILES',
            '# Number of world profiles',
                scalar @modList,
            '# World profile list',
                @modList,
            '# Number of favourite worlds',
                scalar $client->favouriteWorldList,
            '# Favourite world list',
                $client->favouriteWorldList,
            '@@@ eos',
        );

        # Logging preferences
        push (@list,
            '# LOGGING PREFERENCES',
            '# Allow logging',
                $self->convert($client->allowLogsFlag),
            '# Delete standard logs on startup',
                $self->convert($client->deleteStandardLogsFlag),
            '# Delete world logs on startup',
                $self->convert($client->deleteWorldLogsFlag),
            '# Prefix lines with date',
                $self->convert($client->logPrefixDateFlag),
            '# Prefix lines with time',
                $self->convert($client->logPrefixTimeFlag),
            '# Start new logfiles each day',
                $self->convert($client->logDayFlag),
            '# Start new logfiles on startup',
                $self->convert($client->logClientFlag),
            '# Display image names in logfiles',
                $self->convert($client->logImageFlag),
            '# Status task event number of lines recorded',
                $client->statusEventBeforeCount,
                $client->statusEventAfterCount,
        );

        %itemHash = $client->logPrefHash;
        @itemList = sort {lc($a) cmp lc($b)} (keys %itemHash);

        push (@list,
            '# Number of log preferences',
                scalar @itemList,
            '# Log preferences',
        );

        foreach my $item (@itemList) {

            my $flag = $itemHash{$item};

            push (@list, $item, $self->convert($flag));
        }

        push (@list, '@@@ eos');

        # Colour tags
        %itemHash = $client->colourTagHash;
        @itemList = sort {$a cmp $b} (keys %itemHash);      # Don't use lc()

        push (@list,
            '# COLOUR TAGS',
            '# Current xterm colour cube',
                $client->currentColourCube,
            '# Allow OSC colour palette',
                $self->convert($client->oscPaletteFlag),
            '# Number of standard (normal) colour tags',
                scalar @itemList,
            '# Standard (normal) colour tags',
        );

        foreach my $item (@itemList) {

            my $rgb = $itemHash{$item};

            push (@list, $item, $rgb);
        }

        %itemHash = $client->boldColourTagHash;
        @itemList = sort {$a cmp $b} (keys %itemHash);      # Don't use lc()

        push (@list,
            '# Number of standard (bold) colour tags',
                scalar @itemList,
            '# Standard (bold) colour tags',
        );

        foreach my $item (@itemList) {

            my $rgb = $itemHash{$item};

            push (@list, $item, $rgb);
        }

        push (@list, '@@@ eos');

        # Desktop and display settings
        push (@list,
            '# DESKTOP AND DISPLAY SETTINGS',
            '# \'Main\' window default size',
                $client->customMainWinWidth,
                $client->customMainWinHeight,
            '# \'Grid\' window default size',
                $client->customGridWinWidth,
                $client->customGridWinHeight,
            '# World command colour',
                $client->customInsertCmdColour,
            '# System message colour',
                $client->customShowTextColour,
            '# System error message colour',
                $client->customShowErrorColour,
            '# System warning message colour',
                $client->customShowWarningColour,
            '# System debug message colour',
                $client->customShowDebugColour,
            '# System improper message colour',
                $client->customShowImproperColour,
            '# Convert invisible text flag',
                $self->convert($client->convertInvisibleFlag),
            '# Custom text buffer size',
                $client->customTextBufferSize,
            '# Custom panel left size',
                $client->customPanelLeftSize,
            '# Custom panel right size',
                $client->customPanelRightSize,
            '# Custom panel top size',
                $client->customPanelTopSize,
            '# Custom panel bottom size',
                $client->customPanelBottomSize,
            '# Custom window controls left size',
                $client->customControlsLeftSize,
            '# Custom window controls right size',
                $client->customControlsRightSize,
            '# Custom window controls top size',
                $client->customControlsTopSize,
            '# Custom window controls bottom size',
                $client->customControlsBottomSize,
            '# Sessions share a \'main\' window',
                $client->shareMainWinFlag,
            '# (The setting to use when ' . $axmud::SCRIPT . ' next starts)',
                $client->restartShareMainWinFlag,
            '# Workspace grids are activated',
                $client->activateGridFlag,
            '# Direction of workspace adding',
                $client->initWorkspaceDir,
        );

        %workspaceHash = $client->initWorkspaceHash;
        @workspaceList = sort {lc($a) cmp lc($b)} (keys %workspaceHash);

        push (@list,
            '# Number of initial workspaces',
                scalar @workspaceList,
            '# Initial workspaces',
        );

        foreach my $number (@workspaceList) {

            my $zonemap = $workspaceHash{$number};

            push (@list, $number, $zonemap);
        }

        push (@list,
            '# Gridblock size',
                $client->gridBlockSize,
            '# Grid gap max size',
                $client->gridGapMaxSize,
            '# Grid adjustment flag',
                $self->convert($client->gridAdjustmentFlag),
            '# Grid edge correction flag',
                $self->convert($client->gridEdgeCorrectionFlag),
            '# Grid reshuffle flag',
                $self->convert($client->gridReshuffleFlag),
            '# Grid invisible windows flag',
                $self->convert($client->gridInvisWinFlag),
            '@@@ eos',
        );

        # Instructions
        push (@list,
            '# INSTRUCTIONS',
            '# Display buffer size',
                $client->customDisplayBufferSize,
            '# Command buffer size',
                $client->customCmdBufferSize,
            '# Instruction buffer size',
                $client->customInstructBufferSize,
            '# Confirm world commands in \'main\' window',
                $self->convert($client->confirmWorldCmdFlag),
            '# Convert single-word world commands to lower case',
                $self->convert($client->convertWorldCmdFlag),
            '# Preserve world commands in command entry box',
                $self->convert($client->preserveWorldCmdFlag),
            '# Preserve other instructions in command entry box',
                $self->convert($client->preserveOtherCmdFlag),
            '# Multi commands apply to all sessions',
                $self->convert($client->maxMultiCmdFlag),
            '# Auto-complete mode',
                $client->autoCompleteMode,
            '# Auto-complete type',
                $client->autoCompleteType,
            '# Auto-complete location',
                $client->autoCompleteParent,
            '@@@ eos',
        );

        # External applications
        push (@list,
            '# EXTERNAL APPLICATIONS',
            '# Web browser command',
                $client->browserCmd,
            '# Audio player command',
                $client->audioCmd,
            '# Text editor command',
                $client->textEditCmd,
            '@@@ eos',
        );

        # Sound effects
        push (@list,
            '# SOUND EFFECTS',
            '# Sound allowed',
                $self->convert($client->allowSoundFlag),
            '# ASCII beeps allowed',
                $self->convert($client->allowAsciiBellFlag),
        );

        %itemHash = $client->customSoundHash;
        @itemList = sort {lc($a) cmp lc($b)} (keys %itemHash);

        push (@list,
            '# Number of sound effects',
                scalar @itemList,
            '# Sound effects',
        );

        foreach my $item (@itemList) {

            my $path = $itemHash{$item};

            push (@list, $item, $path);
        }

        push (@list, '@@@ eos');

        # Text-to-speech
        push (@list,
            '# TEXT-TO-SPEECH (TTS)',
            '# TTS allowed for all users',
                $self->convert($client->customAllowTTSFlag),
            '# Apply TTS smoothing',
                $self->convert($client->ttsSmoothFlag),
            '# Use TTS for received text',
                $self->convert($client->ttsReceiveFlag),
            '# Don\'t use TTS for received text before login (except prompts)',
                $self->convert($client->ttsLoginFlag),
            '# Use TTS for system messages',
                $self->convert($client->ttsSystemFlag),
            '# Use TTS for system error messages',
                $self->convert($client->ttsSystemErrorFlag),
            '# Use TTS for world commands',
                $self->convert($client->ttsWorldCmdFlag),
            '# Use TTS for \'dialogue\' windows',
                $self->convert($client->ttsDialogueFlag),
            '# Use TTS for task windows',
                $self->convert($client->ttsTaskFlag),
            '# Port for Festival server',
                $client->ttsFestivalServerPort,
            '# Start Festival server when required',
                $self->convert($client->ttsStartServerFlag),
            '@@@ eos',
        );

        # Telnet options/mud protocols
        push (@list,
            '# TELNET OPTION NEGOTIATION',
            '# Use ECHO',
                $self->convert($client->useEchoFlag),
            '# Use TTYPE',
                $self->convert($client->useTTypeFlag),
            '# Use NAWS',
                $self->convert($client->useNawsFlag),
            '# Use CHARSET',
                $self->convert($client->useCharSetFlag),
            '# Use EOR',
                $self->convert($client->useEorFlag),
            '# Use SGa',
                $self->convert($client->useSgaFlag),
            '# Use NEW-ENVIRON',
                $self->convert($client->useNewEnvironFlag),
            '# MUD PROTOCOLS',
            '# Use MCCP',
                $self->convert($client->useMccpFlag),
            '# Use MSDP',
                $self->convert($client->useMsdpFlag),
            '# Use MSSP',
                $self->convert($client->useMsspFlag),
            '# Use MTTS',
                $self->convert($client->useMttsFlag),
            '# Use MXP',
                $self->convert($client->useMxpFlag),
            '# Use MSP',
                $self->convert($client->useMspFlag),
            '# Use Pueblo',
                $self->convert($client->usePuebloFlag),
            '# Use ATCP',
                $self->convert($client->useAtcpFlag),
            '# Use GMCP',
                $self->convert($client->useGmcpFlag),
            '# Use ZMP',
                $self->convert($client->useZmpFlag),
            '# Use AARD102',
                $self->convert($client->useAard102Flag),
            '# Use MCP',
                $self->convert($client->useMcpFlag),
            '# MUD PROTOCOL CUSTOMISATION',
            '# Allow MXP to change font',
                $self->convert($client->allowMxpFontFlag),
            '# Allow MXP to display images',
                $self->convert($client->allowMxpImageFlag),
            '# Allow MXP to download images',
                $self->convert($client->allowMxpLoadImageFlag),
            '# Allow MXP to use images in world\'s own graphics format',
                $self->convert($client->allowMxpFilterImageFlag),
            '# Allow MXP to play sound files',
                $self->convert($client->allowMxpSoundFlag),
            '# Allow MXP to download sound files',
                $self->convert($client->allowMxpLoadSoundFlag),
            '# Allow MXP to display gauges/status bars',
                $self->convert($client->allowMxpGaugeFlag),
            '# Allow MXP to use frames',
                $self->convert($client->allowMxpFrameFlag),
            '# Allow MXP to use internal frames',
                $self->convert($client->allowMxpInteriorFlag),
            '# Allow MXP to perform crosslinking operations',
                $self->convert($client->allowMxpCrosslinkFlag),
            '# Allow Locator task to use MXP room data',
                $self->convert($client->allowMxpRoomFlag),
            '# Allow MSP to play concurrent sound triggers',
                $self->convert($client->allowMspMultipleFlag),
            '# Allow MSP to download sound files',
                $self->convert($client->allowMspLoadSoundFlag),
            '# Allow fleximble MSP tag placement (not recommended)',
                $self->convert($client->allowMspFlexibleFlag),
            '# TELNET OPTION NEGOTIATION CUSTOMISATION',
            '# Sending termtype mode',
                $client->termTypeMode,
            '# Customised client name',
                $client->customClientName,
            '# Customised client version',
                $client->customClientVersion,
            '# TELNET OPTION DEBUG FLAGS',
            '# Show option negotiation debug messages',
                $client->debugTelnetFlag,
            '# Show option negotiation short debug messages',
                $client->debugTelnetMiniFlag,
            '# Ask GA::Net::Telnet to write negotiation logfile',
                $client->debugTelnetLogFlag,
            '# Show MSDP debug messages for Status/Locator',
                $client->debugMsdpFlag,
            '# Show debug messages for MXP problems',
                $client->debugMxpFlag,
            '# Show debug messages for MXP comments',
                $client->debugMxpCommentFlag,
            '# Show debug messages for Pueblo problems',
                $client->debugPuebloFlag,
            '# Show debug messages for Pueblo comments',
                $client->debugPuebloCommentFlag,
            '# Show debug messages for incoming ATCP data',
                $client->debugAtcpFlag,
            '# Show debug messages for incoming GMCP data',
                $client->debugGmcpFlag,
            '@@@ eos',
        );

        # Misc data
        push (@list,
            '# MISC DATA',
            '# Month list',
                12,                     # Don't bother stating the number of months in a year...
                $client->customMonthList,
            '# Day list',
                7,                      # ...or the number of days in a week
                $client->customDayList,
            '# Prompt wait time (seconds)',
                $client->promptWaitTime,
            '# Login warning time (seconds)',
                $client->loginWarningTime,
            '# Show explicit line numbers in \'main\' window',
                $self->convert($client->debugLineNumsFlag),
            '# Show explicit tags in \'main\' window',
                $self->convert($client->debugLineTagsFlag),
            '# Show Locator task debug messages',
                $self->convert($client->debugLocatorFlag),
            '# Show extensive Locator task debug messages',
                $self->convert($client->debugMaxLocatorFlag),
            '# Show Locator task expected room statements',
                $self->convert($client->debugMoveListFlag),
            '# Show object parsing debug messages',
                $self->convert($client->debugParseObjFlag),
            '# Show object comparison debug messages',
                $self->convert($client->debugCompareObjFlag),
            '# Show plugin failure debug messages',
                $self->convert($client->debugExplainPluginFlag),
            '# Show non-existent IV debug messages',
                $self->convert($client->debugCheckIVFlag),
            '# Show errors when table objects can\'t be added/resized',
                $self->convert($client->debugTableFitFlag),
            '# Show Perl errors/warnings in \'main\' window',
                $self->convert($client->debugTrapErrorFlag),
            '# Show toolbar button labels',
                $self->convert($client->toolbarLabelFlag),
            '# Show irreversible icon in \'edit\' windows',
                $self->convert($client->irreversibleIconFlag),
            '# Set \'main\' window\'s urgency hint when text received',
                $self->convert($client->mainWinUrgencyFlag),
            '# Show tooltips in a session\'s default tab',
                $self->convert($client->mainWinTooltipFlag),
            '# Session tab mode',
                $client->sessionTabMode,
            '# Use xterm titles',
                $self->convert($client->xTermTitleFlag),
            '# Use long world names in tab labels',
                $self->convert($client->longTabLabelFlag),
            '# Don\'t use tab labels when only one session open',
                $self->convert($client->simpleTabFlag),
            '# Prompt user before closing \'main\' window',
                $self->convert($client->confirmCloseMainWinFlag),
            '# Prompt user before closing \'main\' window tabs',
                $self->convert($client->confirmCloseTabFlag),
            '# Character set',
                $client->charSet,
            '# Maximum concurrent sessions',
                $client->sessionMax,
            '# Store connection history',
                $client->connectHistoryFlag,
            '# Use page up (etc) to scroll in textviews',
                $self->convert($client->useScrollKeysFlag),
            '# Page up (etc) doesn\'t scroll the entire page length',
                $self->convert($client->smoothScrollKeysFlag),
            '# Page up (etc) auto-engages split mode',
                $self->convert($client->autoSplitKeysFlag),
            '# Use tab/cursor keys to auto-complete commands',
                $self->convert($client->useCompleteKeysFlag),
            '# Use tab to switch between sessions',
                $self->convert($client->useSwitchKeysFlag),
            '@@@ eos',
        );

        # Prepare footer
        push @list, ('@@@ eof');

        # Add newline characters to every entry in @list before writing the whole list to the file
        foreach my $item (@list) {

            $item .= "\n";
        }

        print $fileHandle @list;

        # Writing complete
        $result = close $fileHandle;

        # Precautions taken when an emergency save is NOT in progress...
        if (! $emergFlag) {

            # Release the lock on the semaphore file
            $self->releaseFileLock($semaphoreHandle);

            if (! $result) {

                # Restore the config file from backup
                File::Copy::copy($backupFile, $path);

                # Set global flags and display an error message
                return $self->disableSaveLoad(FALSE);

            } elsif (! $axmud::CLIENT->autoRetainFileFlag) {

                # Delete the backup file, unless the user has opted to retain it
                unlink ($backupFile);
            }

            # Save the file's header (metadata) in this object's variables
            $self->ivPoke('scriptName', $axmud::NAME_FILE);
            $self->ivPoke('scriptVersion', $axmud::VERSION);
            $self->ivPoke(
                'scriptConvertVersion',
                $axmud::CLIENT->convertVersion($axmud::VERSION),
            );
            $self->ivPoke('saveDate', $saveDate);
            $self->ivPoke('saveTime', $saveTime);
            $self->ivUndef('assocWorldProf');

            $self->ivPoke('actualFileName', $fileName);
            $self->ivPoke('actualPath', $path);
            $self->ivPoke('actualDir', $dir);

            # If Axmud has been ported from MS Windows to Linux (or vice versa), the old config file
            #   will have been read, and there will now be two. Delete the old one (which we no
            #   longer need)
            if (-e $self->altFileName) {

                unlink $self->altFileName;
            }

            # Mark the file object's data as not needing to be saved
            $self->set_modifyFlag(FALSE, $self->_objClass . '->saveConfigFile');
        }

        return 1;
    }

    sub loadConfigFile {

        # Called by $self->setupConfigFile for the file types:
        #   'config'
        # Loads the config file
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $fileName   - The file name, e.g. 'axmud.conf'
        #   $path       - The full path, e.g. '/home/me/axmud-data/axmud.conf'
        #   $dir        - The directory, e.g. '/home/me/axmud-data/'
        #
        # Notes:
        #   If one optional argument is specified, they must all be specified
        #   If no optional arguments are specified (or are all set to 'undef'), the default
        #       filename, path and directory for this file type are used
        #
        # Return values
        #   'undef' on improper arguments, or if there are any errors reading the file or in taking
        #       out a lock on the semaphore file
        #   1 otherwise

        my ($self, $fileName, $path, $dir, $check) = @_;

        # Local variables
        my (
            $semaphoreFile, $semaphoreHandle, $fileHandle, $word, $fileType, $headerScriptName,
            $headerScriptVersion, $headerSaveDate, $headerSaveTime, $headerAssocWorldProf, $line,
            $failFlag, $warningCount, $result, $client, $notCompatFlag,
            %dataHash,
        );

        # Check for improper arguments
        if (
            defined $check
            || (defined $fileName && (! defined $path || ! defined $dir))
            || (defined $path && (! defined $fileName || ! defined $dir))
            || (defined $dir && (! defined $fileName || ! defined $path))
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->loadConfigFile', @_);
        }

        # Check it's the right file type for this function
        if ($self->fileType ne 'config') {

            return $self->writeError(
                'Wrong file type \'' . $self->fileType . '\'',
                $self->_objClass . '->loadConfigFile',
            );
        }

        # Set the filename, path and directory, if not specified
        if (! defined $fileName) {

            $fileName = $self->standardFileName;
            $path = $axmud::DATA_DIR . $self->standardPath;
            $dir = $axmud::DATA_DIR . $self->standardDir;
        }

        # Don't load anything if the global flags forbid it
        if (! $axmud::CLIENT->loadConfigFlag) {

            return $self->disableSaveLoad(TRUE);
        }

        # Check that the data directory exists
        if (! (-d $dir)) {

            return $self->disableSaveLoad(TRUE);
        }

        # Check that the specified file exists
        if (! (-e $path)) {

            # If the alternative file name exists (because an MS Windows config file has been ported
            #   to Linux, or vice-versa), use that instead
            if (-e $self->altFileName) {

                $fileName = $self->altFileName;
                $path = $axmud::DATA_DIR . $self->altPath;

            } else {

                # Config file doesn't exist at all
                return $self->disableSaveLoad(TRUE);
            }
        }

        # Get a shared lock on the twinned semaphore file
        $semaphoreFile = $axmud::DATA_DIR . '/data/temp/config.sem';
        $semaphoreHandle = $self->getFileLock($semaphoreFile, FALSE, $semaphoreFile);
        # Don't try to read the config file if no lock could be taken out on the semaphore file
        if (! $semaphoreHandle) {

            return $self->disableSaveLoad(FALSE);
        }

        # Open the file for reading
        if (! open ($fileHandle, "<$path")) {

            # Could not open file
            return $self->disableSaveLoad(FALSE);
        }

        #################
        # Read the header

        $failFlag = FALSE;

        ($word, $fileType) = $self->readMarker($fileHandle);
        if (! defined $word || $word ne 'file_type' || ! $fileType) {$failFlag = TRUE}

        ($word, $headerScriptName) = $self->readMarker($fileHandle);
        if (! defined $word || $word ne 'script_name' || ! $headerScriptName) {$failFlag = TRUE}

        ($word, $headerScriptVersion) = $self->readMarker($fileHandle);
        if (! defined $word || $word ne 'script_version' || ! $headerScriptVersion) {

            $failFlag = TRUE;
        }

        ($word, $headerSaveDate) = $self->readMarker($fileHandle);
        if (! defined $word || $word ne 'save_date' || ! $headerSaveDate) {$failFlag = TRUE}

        ($word, $headerSaveTime) = $self->readMarker($fileHandle);
        if (! defined $word || $word ne 'save_time' || ! $headerSaveTime) {$failFlag = TRUE}

        # Before v1.0.868, Axmud used 'assoc_world_defn' rather than 'assoc_world_prof'
        ($word, $headerAssocWorldProf) = $self->readMarker($fileHandle);
        if (
            ! defined $word
            || ($word ne 'assoc_world_prof' && $word ne 'assoc_world_defn')
            || ! $headerAssocWorldProf
        ) {
            $failFlag = TRUE;
        }

        # Read end-of-section
        ($line) = $self->readMarker($fileHandle);
        if (! defined $line || $line ne 'eos') {$failFlag = TRUE}

        # Do basic checks on the header file information - that the file was created by Axmud, by
        #   the current version of it or an earlier version of it
        if (
            ! $self->checkCompatibility($headerScriptName)
            || $axmud::CLIENT->convertVersion($headerScriptVersion)
                > $axmud::CLIENT->convertVersion($axmud::VERSION)
        ) {
            $failFlag = TRUE;
        }

        # If header information is incorrect, don't bother reading the rest of the file
        if ($fileType ne $self->fileType || $failFlag) {

            # Close the file and release the lock on the semaphore file
            $result = close $fileHandle;
            $self->releaseFileLock($semaphoreHandle);

            if (! $result) {
                return $self->disableSaveLoad(FALSE);
            } elsif ($failFlag) {
                return $self->disableSaveLoad(TRUE);
            }

        # Otherwise, save the header information in this object
        } else {

            $self->ivPoke('scriptName', $headerScriptName);
            $self->ivPoke('scriptVersion', $headerScriptVersion);
            $self->ivPoke(
                'scriptConvertVersion',
                $axmud::CLIENT->convertVersion($headerScriptVersion),
            );
            $self->ivPoke('saveDate', $headerSaveDate);
            $self->ivPoke('saveTime', $headerSaveTime);
            $self->ivUndef('assocWorldProf');

            $self->ivPoke('actualFileName', $fileName);
            $self->ivPoke('actualPath', $path);
            $self->ivPoke('actualDir', $dir);
        }

        ###############
        # Read the data

        # Read data from the file, and store it temporarily in a single hash, %dataHash.
        # The temporary hash should contain the filehandle, so that $self->readValue (etc) can use
        #   it
        $dataHash{'file_handle'} = $fileHandle;

        # Read script data (read, but not used)
        $failFlag = $self->readValue($failFlag, \%dataHash, 'script_name');
        $failFlag = $self->readValue($failFlag, \%dataHash, 'script_version');
        $failFlag = $self->readValue($failFlag, \%dataHash, 'script_date');
        $failFlag = $self->readEndOfSection($failFlag, $fileHandle);

        # Read file object data
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'load_config_flag');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'save_config_flag');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'load_data_flag');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'save_data_flag');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'delete_files_start_flag');
        if ($self->scriptConvertVersion >= 1_000_489) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'emergency_save_flag');
        }
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'auto_save_flag');
        $failFlag = $self->readValue($failFlag, \%dataHash, 'auto_save_wait_time');
        if ($self->scriptConvertVersion >= 1_000_118) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'auto_retain_file_flag');
        }
        $failFlag = $self->readEndOfSection($failFlag, $fileHandle);

        # Read plugin data
        $failFlag = $self->readList($failFlag, \%dataHash, 'init_plugin_list');
        $failFlag = $self->readEndOfSection($failFlag, $fileHandle);

        # Read instruction data
        if ($self->scriptConvertVersion >= 1_000_880) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'echo_sigil_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'perl_sigil_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'script_sigil_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'multi_sigil_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_912) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'speed_sigil_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'bypass_sigil_flag');
        }
        $failFlag = $self->readValue($failFlag, \%dataHash, 'cmd_sep');
        $failFlag = $self->readEndOfSection($failFlag, $fileHandle);

        # Read world profile data
        $failFlag = $self->readList($failFlag, \%dataHash, 'world_prof_list');
        $failFlag = $self->readList($failFlag, \%dataHash, 'favourite_world_list');
        $failFlag = $self->readEndOfSection($failFlag, $fileHandle);

        # Read logging preferences
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_logs_flag');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'delete_standard_logs_flag');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'delete_world_logs_flag');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'log_prefix_date_flag');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'log_prefix_time_flag');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'log_day_flag');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'log_client_flag');
        if ($self->scriptConvertVersion >= 1_000_917) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'log_image_flag');
        }
        $failFlag = $self->readValue($failFlag, \%dataHash, 'status_before_count');
        $failFlag = $self->readValue($failFlag, \%dataHash, 'status_after_count');
        $failFlag = $self->readHash($failFlag, \%dataHash, 'log_pref_hash');
        $failFlag = $self->readEndOfSection($failFlag, $fileHandle);

        # Read colour tags
        if ($self->scriptConvertVersion >= 1_000_165) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'current_xterm_cube');
        }
        if ($self->scriptConvertVersion >= 1_000_203) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'osc_palette_flag');
        }
        $failFlag = $self->readHash($failFlag, \%dataHash, 'colour_tag_hash');
        $failFlag = $self->readHash($failFlag, \%dataHash, 'bold_colour_tag_hash');
        $failFlag = $self->readEndOfSection($failFlag, $fileHandle);

        # Read desktop and display settings
        $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_main_win_width');
        $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_main_win_height');
        if ($self->scriptConvertVersion < 1_000_800) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'discard_me');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'discard_me');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'discard_me');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'discard_me');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'discard_me');
        }
        $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_grid_win_width');
        $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_grid_win_height');
        if ($self->scriptConvertVersion < 1_000_800) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'discard_me');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'discard_me');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'discard_me');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'discard_me');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'discard_me');
        }
        if ($self->scriptConvertVersion < 1_000_800) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'discard_me');
        }
        $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_insert_cmd_colour');
        $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_show_text_colour');
        $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_show_error_colour');
        $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_show_warning_colour');
        $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_show_debug_colour');
        $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_show_improper_colour');
        if ($self->scriptConvertVersion >= 1_000_079) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'convert_invisible_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_800) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_text_buffer_size');
        }
        $failFlag = $self->readValueOrUndef($failFlag, \%dataHash, 'custom_panel_left_size');
        $failFlag = $self->readValueOrUndef($failFlag, \%dataHash, 'custom_panel_right_size');
        $failFlag = $self->readValueOrUndef($failFlag, \%dataHash, 'custom_panel_top_size');
        $failFlag = $self->readValueOrUndef($failFlag, \%dataHash, 'custom_panel_bottom_size');
        if ($self->scriptConvertVersion < 1_000_800) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'discard_me');
            $failFlag = $self->readHash($failFlag, \%dataHash, 'discard_me');
        }
        $failFlag = $self->readValueOrUndef($failFlag, \%dataHash, 'custom_controls_left_size');
        $failFlag = $self->readValueOrUndef($failFlag, \%dataHash, 'custom_controls_right_size');
        $failFlag = $self->readValueOrUndef($failFlag, \%dataHash, 'custom_controls_top_size');
        $failFlag = $self->readValueOrUndef($failFlag, \%dataHash, 'custom_controls_bottom_size');
        if ($self->scriptConvertVersion < 1_000_800) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'discard_me');
        }
        if ($self->scriptConvertVersion >= 1_000_800) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'share_main_win_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'restart_share_main_win_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'activate_grid_flag');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'init_workspace_dir');
            $failFlag = $self->readHash($failFlag, \%dataHash, 'init_workspace_hash');
        }
        $failFlag = $self->readValue($failFlag, \%dataHash, 'grid_block_size');
        $failFlag = $self->readValue($failFlag, \%dataHash, 'grid_gap_max_size');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'grid_adjustment_flag');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'grid_edge_correction_flag');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'grid_reshuffle_flag');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'grid_invis_win_flag');
        $failFlag = $self->readEndOfSection($failFlag, $fileHandle);

        if ($self->scriptConvertVersion < 1_000_800) {

            # Read 'main' window widget flags
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'discard_me');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'discard_me');
            if ($self->scriptConvertVersion >= 1_000_674) {

                $failFlag = $self->readFlag($failFlag, \%dataHash, 'discard_me');
            }
            if ($self->scriptConvertVersion >= 1_000_549) {

                $failFlag = $self->readFlag($failFlag, \%dataHash, 'discard_me');
            }
            $failFlag = $self->readEndOfSection($failFlag, $fileHandle);
        }

        # Read instructions
        $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_display_buffer_size');
        $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_cmd_buffer_size');
        $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_instruct_buffer_size');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'confirm_world_cmd_flag');
        if ($self->scriptConvertVersion >= 1_000_331) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'convert_world_cmd_flag');
        }
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'preserve_world_cmd_flag');
        if ($self->scriptConvertVersion >= 1_000_880) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'preserve_other_cmd_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'max_multi_cmd_flag');
        }
        $failFlag = $self->readValue($failFlag, \%dataHash, 'auto_complete_mode');
        if ($self->scriptConvertVersion < 1_000_800 && ! $failFlag) {

            if ($dataHash{'auto_complete_mode'} eq '0') {
                $dataHash{'auto_complete_mode'} = 'none';
            } elsif (
                $dataHash{'auto_complete_mode'} eq '1'
                || $dataHash{'auto_complete_mode'} eq '2'
            ) {
                $dataHash{'auto_complete_mode'} = 'auto';
            }
        }
        if ($self->scriptConvertVersion >= 1_000_800) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'auto_complete_type');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'auto_complete_parent');
        }
        $failFlag = $self->readEndOfSection($failFlag, $fileHandle);

        # Read external applications
        $failFlag = $self->readValue($failFlag, \%dataHash, 'browser_cmd');
        $failFlag = $self->readValue($failFlag, \%dataHash, 'audio_cmd');
        $failFlag = $self->readValue($failFlag, \%dataHash, 'text_edit_cmd');
        $failFlag = $self->readEndOfSection($failFlag, $fileHandle);

        # Read sound effects
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_sound_flag');
        if ($self->scriptConvertVersion >= 1_000_087) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_ascii_bell_flag');
        }
        $failFlag = $self->readHash($failFlag, \%dataHash, 'custom_sound_hash');
        $failFlag = $self->readEndOfSection($failFlag, $fileHandle);

        # Read text-to-speech (TTS)
        if ($self->scriptConvertVersion >= 1_000_618) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_tts_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'tts_smooth_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'tts_receive_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'tts_login_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'tts_system_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'tts_system_error_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'tts_world_cmd_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'tts_dialogue_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'tts_task_flag');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'tts_festival_server_port');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'tts_start_server_flag');
            $failFlag = $self->readEndOfSection($failFlag, $fileHandle);
        }

        # Read telnet option negotiation flags
        if ($self->scriptConvertVersion >= 1_000_156) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_echo_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_ttype_flag');
        }
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_naws_flag');
        if ($self->scriptConvertVersion >= 1_000_156) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_charset_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_163) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_eor_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_879) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_sga_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_new_environ_flag');
        }
        # Read MUD protocol flags
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_mccp_flag');
        if ($self->scriptConvertVersion >= 1_000_156) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_msdp_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_mssp_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_mtts_flag');
        }
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_mxp_flag');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_msp_flag');
        if ($self->scriptConvertVersion >= 1_000_844) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_pueblo_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_850) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_atcp_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_gmcp_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_879) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_zmp_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_aard_102_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_mcp_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_832) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_mxp_font_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_mxp_image_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_mxp_load_image_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_mxp_filter_image_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_mxp_sound_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_mxp_load_sound_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_mxp_gauge_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_mxp_frame_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_mxp_interior_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_mxp_crosslink_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_887) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_mxp_room_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_678) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_msp_multiple_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_msp_load_sound_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_886) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_msp_flexible_flag');
        }
        # Read telnet option negotiation customisation IVs
        if ($self->scriptConvertVersion >= 1_000_160) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'term_type_mode');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_client_name');
        }
        if ($self->scriptConvertVersion >= 1_000_666) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_client_version');
        }
        # Set telnet negotiation debug flags
        if ($self->scriptConvertVersion >= 1_000_378) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_telnet_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_telnet_mini_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_895) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_telnet_log_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_378) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_msdp_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_405) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_mxp_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_mxp_comment_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_849) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_pueblo_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_pueblo_comment_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_926) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_atcp_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_gmcp_flag');
        }

        $failFlag = $self->readEndOfSection($failFlag, $fileHandle);

        # Read misc data
        $failFlag = $self->readList($failFlag, \%dataHash, 'custom_month_list');
        $failFlag = $self->readList($failFlag, \%dataHash, 'custom_day_list');
        if ($self->scriptConvertVersion <= 1_000_922) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'discard_me');
        }
        $failFlag = $self->readValue($failFlag, \%dataHash, 'prompt_wait_time');
        $failFlag = $self->readValue($failFlag, \%dataHash, 'login_warning_time');
        if ($self->scriptConvertVersion >= 1_000_331) {

            if ($self->scriptConvertVersion <= 1_000_535) {

                $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_world_flag');

            } else {

                $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_line_nums_flag');
                $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_line_tags_flag');
            }
        }
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_locator_flag');
        if ($self->scriptConvertVersion >= 1_000_482) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_max_locator_flag');
        }
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_move_list_flag');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_parse_obj_flag');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_compare_obj_flag');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_explain_plugin_flag');
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_check_iv_flag');
        if ($self->scriptConvertVersion >= 1_000_800) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_table_fit_flag');
        }
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_trap_error_flag');
        if ($self->scriptConvertVersion >= 1_000_949) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'toolbar_label_flag');
        }
        $failFlag = $self->readFlag($failFlag, \%dataHash, 'irreversible_icon_flag');
        if ($self->scriptConvertVersion >= 1_000_344) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'main_win_urgency_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_883) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'main_win_tooltip_flag');
        }
        $failFlag = $self->readValue($failFlag, \%dataHash, 'session_tab_mode');
        if ($self->scriptConvertVersion >= 1_000_184) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'xterm_title_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_365) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'long_tab_label_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'simple_tab_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_917) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'confirm_close_main_win_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'confirm_close_tab_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_185) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'char_set');
        }
        if ($self->scriptConvertVersion >= 1_000_616) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'session_max');
        }
        if ($self->scriptConvertVersion >= 1_000_884) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'connect_history_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_338 && $self->scriptConvertVersion <= 1_000_884) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'discard_me');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'discard_me');
        }
        if ($self->scriptConvertVersion >= 1_000_338) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'use_scroll_keys_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_884) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'smooth_scroll_keys_flag');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'auto_split_keys_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_338) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'use_complete_keys_flag');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'use_switch_keys_flag');
        }

        $failFlag = $self->readEndOfSection($failFlag, $fileHandle);

        #################
        # Read the footer

        ($line) = $self->readMarker($fileHandle);
        if (! defined $line || $line ne 'eof') {

            $failFlag = TRUE;
        }

        # Reading complete
        $result = close $fileHandle;
        # Release the lock on the semaphore file
        $self->releaseFileLock($semaphoreHandle);

        if (! $result) {

            # Set global flags and display an error message
            return $self->disableSaveLoad(FALSE);

        } elsif ($failFlag) {

            # Error messages displayed by $self->setupConfigFile
            return $self->disableSaveLoad(TRUE);
        }

        ##############
        # Basic checks

        $warningCount = 0;

        # Check header data

        # For config files created before the first public release, display a warning that the file
        #   might not be compatible with the current version of Axmud (this prevents difficult-to-
        #   diagnose errors which are actually the result of old data)
        if (
            $axmud::CLIENT->convertVersion($axmud::VERSION) < 1
            && (
                $axmud::CLIENT->convertVersion($headerScriptVersion)
                    != $axmud::CLIENT->convertVersion($axmud::VERSION)
            )
        ) {
            $warningCount++;

            $self->writeWarning(
                'Config file may be incompatible with this version of ' . $axmud::CLIENT
                . ' (file v' . $headerScriptVersion . ', client v' . $axmud::VERSION . ')',
                $self->_objClass . '->loadConfigFile',
            );
        }

        # Respond to any warnings
        if ($warningCount == 1) {

            $self->writeWarning(
                'Config file: 1 warning issued and data not loaded',
                $self->_objClass . '->loadConfigFile',
            );

            return $self->disableSaveLoad(TRUE);

        } elsif ($warningCount > 1) {

            $self->writeWarning(
                'Config file: ' . $warningCount . ' warnings issued and data not loaded',
                $self->_objClass . '->loadConfigFile',
            );

            return $self->disableSaveLoad(TRUE);
        }

        #############
        # Mode update

        # v1.0.908 converts some numerical mode values to string mode values
        if ($self->scriptConvertVersion < 1_000_909) {

            # GA::Client->sessionTabMode
            if ($dataHash{'session_tab_mode'} eq '0') {
                $dataHash{'session_tab_mode'} = 'bracket';
            } elsif ($dataHash{'session_tab_mode'} eq '1') {
                $dataHash{'session_tab_mode'} = 'hyphen';
            } elsif ($dataHash{'session_tab_mode'} eq '2') {
                $dataHash{'session_tab_mode'} = 'world';
            } elsif ($dataHash{'session_tab_mode'} eq '3') {
                $dataHash{'session_tab_mode'} = 'char';
            }

            # GA::Client->termTypeMode
            if ($dataHash{'term_type_mode'} eq '0') {
                $dataHash{'term_type_mode'} = 'send_nothing';
            } elsif ($dataHash{'term_type_mode'} eq '1') {
                $dataHash{'term_type_mode'} = 'send_client';
            } elsif ($dataHash{'term_type_mode'} eq '2') {
                $dataHash{'term_type_mode'} = 'send_client_version';
            } elsif ($dataHash{'term_type_mode'} eq '3') {
                $dataHash{'term_type_mode'} = 'send_custom_client';
            } elsif ($dataHash{'term_type_mode'} eq '4') {
                $dataHash{'term_type_mode'} = 'send_default';
            } elsif ($dataHash{'term_type_mode'} eq '5') {
                $dataHash{'term_type_mode'} = 'send_unknown';
            }
        }

        ######################
        # Set GA::Client IVs

        # For convenience, import the GA::Client
        $client = $axmud::CLIENT;

        # Set IVs directly, rather than using GA::Client's 'set' accessors (otherwise the file
        #   object's ->modifyFlag will get set to TRUE again, which we obviously don't want)

        # Set file object data
        $client->ivPoke('loadConfigFlag', $dataHash{'load_config_flag'});
        $client->ivPoke('saveConfigFlag', $dataHash{'save_config_flag'});
        $client->ivPoke('loadDataFlag', $dataHash{'load_data_flag'});
        $client->ivPoke('saveDataFlag', $dataHash{'save_data_flag'});
        $client->ivPoke('deleteFilesAtStartFlag', $dataHash{'delete_files_start_flag'});
        if ($self->scriptConvertVersion >= 1_000_489) {

            $client->ivPoke('emergencySaveFlag', $dataHash{'emergency_save_flag'});
        }
        $client->ivPoke('autoSaveFlag', $dataHash{'auto_save_flag'});
        if ($self->scriptConvertVersion < 1_000_148) {

            # ->autoSaveWaitTime is now expressed in minutes, not seconds
            $client->ivPoke(
                'autoSaveWaitTime',
                POSIX::ceil( ($dataHash{'auto_save_wait_time'}) / 60),
            );

        } else {

            $client->ivPoke('autoSaveWaitTime', $dataHash{'auto_save_wait_time'});
        }
        if ($self->scriptConvertVersion >= 1_000_118) {

            $client->ivPoke('autoRetainFileFlag', $dataHash{'auto_retain_file_flag'});
        }

        # Set plugin data
        $client->ivPoke('initPluginList', @{$dataHash{'init_plugin_list'}});

        # Set instruction data
        if ($self->scriptConvertVersion >= 1_000_880) {

            $client->ivPoke('echoSigilFlag', $dataHash{'echo_sigil_flag'});
            $client->ivPoke('perlSigilFlag', $dataHash{'perl_sigil_flag'});
            $client->ivPoke('scriptSigilFlag', $dataHash{'script_sigil_flag'});
            $client->ivPoke('multiSigilFlag', $dataHash{'multi_sigil_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_912) {

            $client->ivPoke('speedSigilFlag', $dataHash{'speed_sigil_flag'});
            $client->ivPoke('bypassSigilFlag', $dataHash{'bypass_sigil_flag'});
        }
        $client->ivPoke('cmdSep', $dataHash{'cmd_sep'});

        # Set world profile data
        $client->ivPoke('configWorldProfList', @{$dataHash{'world_prof_list'}});
        $client->ivPoke('favouriteWorldList', @{$dataHash{'favourite_world_list'}});

        # Set logging preferences
        $client->ivPoke('allowLogsFlag', $dataHash{'allow_logs_flag'});
        $client->ivPoke('deleteStandardLogsFlag', $dataHash{'delete_standard_logs_flag'});
        $client->ivPoke('deleteWorldLogsFlag', $dataHash{'delete_world_logs_flag'});
        $client->ivPoke('logPrefixDateFlag', $dataHash{'log_prefix_date_flag'});
        $client->ivPoke('logPrefixTimeFlag', $dataHash{'log_prefix_time_flag'});
        $client->ivPoke('logDayFlag', $dataHash{'log_day_flag'});
        $client->ivPoke('logClientFlag', $dataHash{'log_client_flag'});
        if ($self->scriptConvertVersion >= 1_000_917) {

            $client->ivPoke('logImageFlag', $dataHash{'log_image_flag'});
        }
        $client->ivPoke('statusEventBeforeCount', $dataHash{'status_before_count'});
        $client->ivPoke('statusEventAfterCount', $dataHash{'status_after_count'});
        $client->ivPoke('logPrefHash', %{$dataHash{'log_pref_hash'}});

        # Set colour tags
        if ($self->scriptConvertVersion >= 1_000_165) {

            $client->ivPoke('currentColourCube', $dataHash{'current_xterm_cube'});
        }
        if ($self->scriptConvertVersion >= 1_000_203) {

            $client->ivPoke('oscPaletteFlag', $dataHash{'osc_palette_flag'});
        }
        $client->ivPoke('colourTagHash', %{$dataHash{'colour_tag_hash'}});
        $client->ivPoke('boldColourTagHash', %{$dataHash{'bold_colour_tag_hash'}});

        # Read desktop and display settings
        $client->ivPoke('customGridWinWidth', $dataHash{'custom_grid_win_width'});
        $client->ivPoke('customGridWinHeight', $dataHash{'custom_grid_win_height'});

        $client->ivPoke('customInsertCmdColour', $dataHash{'custom_insert_cmd_colour'});
        $client->ivPoke('customShowTextColour', $dataHash{'custom_show_text_colour'});
        $client->ivPoke('customShowErrorColour', $dataHash{'custom_show_error_colour'});
        $client->ivPoke('customShowWarningColour', $dataHash{'custom_show_warning_colour'});
        $client->ivPoke('customShowDebugColour', $dataHash{'custom_show_debug_colour'});
        $client->ivPoke('customShowImproperColour', $dataHash{'custom_show_improper_colour'});
        if ($self->scriptConvertVersion >= 1_000_079) {

            $client->ivPoke('convertInvisibleFlag', $dataHash{'convert_invisible_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_800) {

            $client->ivPoke('customTextBufferSize', $dataHash{'custom_text_buffer_size'});
        }
        $client->ivPoke('customPanelLeftSize', $dataHash{'custom_panel_left_size'});
        $client->ivPoke('customPanelRightSize', $dataHash{'custom_panel_right_size'});
        $client->ivPoke('customPanelTopSize', $dataHash{'custom_panel_top_size'});
        $client->ivPoke('customPanelBottomSize', $dataHash{'custom_panel_bottom_size'});
        $client->ivPoke('customControlsLeftSize', $dataHash{'custom_controls_left_size'});
        $client->ivPoke('customControlsRightSize', $dataHash{'custom_controls_right_size'});
        $client->ivPoke('customControlsTopSize', $dataHash{'custom_controls_top_size'});
        $client->ivPoke('customControlsBottomSize', $dataHash{'custom_controls_bottom_size'});
        if ($self->scriptConvertVersion >= 1_000_800) {

            $client->ivPoke('shareMainWinFlag', $dataHash{'share_main_win_flag'});
            $client->ivPoke('restartShareMainWinFlag', $dataHash{'restart_share_main_win_flag'});
            $client->ivPoke('activateGridFlag', $dataHash{'activate_grid_flag'});
            $client->ivPoke('initWorkspaceDir', $dataHash{'init_workspace_dir'});
            $client->ivPoke('initWorkspaceHash', %{$dataHash{'init_workspace_hash'}});
        }
        $client->ivPoke('gridBlockSize', $dataHash{'grid_block_size'});
        $client->ivPoke('gridGapMaxSize', $dataHash{'grid_gap_max_size'});
        $client->ivPoke('gridAdjustmentFlag', $dataHash{'grid_adjustment_flag'});
        $client->ivPoke('gridEdgeCorrectionFlag', $dataHash{'grid_edge_correction_flag'});
        $client->ivPoke('gridReshuffleFlag', $dataHash{'grid_reshuffle_flag'});
        $client->ivPoke('gridInvisWinFlag', $dataHash{'grid_invis_win_flag'});

        # Instructions
        $client->ivPoke('customDisplayBufferSize', $dataHash{'custom_display_buffer_size'});
        $client->ivPoke('customCmdBufferSize', $dataHash{'custom_cmd_buffer_size'});
        $client->ivPoke('customInstructBufferSize', $dataHash{'custom_instruct_buffer_size'});
        $client->ivPoke('confirmWorldCmdFlag', $dataHash{'confirm_world_cmd_flag'});
        if ($self->scriptConvertVersion >= 1_000_331) {

            $client->ivPoke('convertWorldCmdFlag', $dataHash{'convert_world_cmd_flag'});
        }
        $client->ivPoke('preserveWorldCmdFlag', $dataHash{'preserve_world_cmd_flag'});
        if ($self->scriptConvertVersion >= 1_000_880) {

            $client->ivPoke('preserveOtherCmdFlag', $dataHash{'preserve_other_cmd_flag'});
            $client->ivPoke('maxMultiCmdFlag', $dataHash{'max_multi_cmd_flag'});
        }
        $client->ivPoke('autoCompleteMode', $dataHash{'auto_complete_mode'});
        if ($self->scriptConvertVersion >= 1_000_800) {

            $client->ivPoke('autoCompleteType', $dataHash{'auto_complete_type'});
            $client->ivPoke('autoCompleteParent', $dataHash{'auto_complete_parent'});
        }

        # Set external applications
        $client->ivPoke('browserCmd', $dataHash{'browser_cmd'});
        $client->ivPoke('audioCmd', $dataHash{'audio_cmd'});
        $client->ivPoke('textEditCmd', $dataHash{'text_edit_cmd'});

        # Set sound effects
        $client->ivPoke('allowSoundFlag', $dataHash{'allow_sound_flag'});
        if ($self->scriptConvertVersion >= 1_000_087) {

            $client->ivPoke('allowAsciiBellFlag', $dataHash{'allow_ascii_bell_flag'});
        }
        $client->ivPoke('customSoundHash', %{$dataHash{'custom_sound_hash'}});

        # Set text-to-speech (TTS)
        if ($self->scriptConvertVersion >= 1_000_618) {

            $client->ivPoke('customAllowTTSFlag', $dataHash{'allow_tts_flag'});
            if ($client->customAllowTTSFlag) {

                $client->ivPoke('systemAllowTTSFlag', TRUE);
            }

            $client->ivPoke('ttsSmoothFlag', $dataHash{'tts_smooth_flag'});
            $client->ivPoke('ttsReceiveFlag', $dataHash{'tts_receive_flag'});
            $client->ivPoke('ttsLoginFlag', $dataHash{'tts_login_flag'});
            $client->ivPoke('ttsSystemFlag', $dataHash{'tts_system_flag'});
            $client->ivPoke('ttsSystemErrorFlag', $dataHash{'tts_system_error_flag'});
            $client->ivPoke('ttsWorldCmdFlag', $dataHash{'tts_world_cmd_flag'});
            $client->ivPoke('ttsDialogueFlag', $dataHash{'tts_dialogue_flag'});
            $client->ivPoke('ttsTaskFlag', $dataHash{'tts_task_flag'});
            $client->ivPoke('ttsFestivalServerPort', $dataHash{'tts_festival_server_port'});
            $client->ivPoke('ttsStartServerFlag', $dataHash{'tts_start_server_flag'});
        }

        # Set telnet option negotiation flags
        if ($self->scriptConvertVersion >= 1_000_156) {

            $client->ivPoke('useEchoFlag', $dataHash{'use_echo_flag'});
            $client->ivPoke('useTTypeFlag', $dataHash{'use_ttype_flag'});
        }
        $client->ivPoke('useNawsFlag', $dataHash{'use_naws_flag'});
        if ($self->scriptConvertVersion >= 1_000_156) {

            $client->ivPoke('useCharSetFlag', $dataHash{'use_charset_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_163) {

            $client->ivPoke('useEorFlag', $dataHash{'use_eor_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_879) {

            $client->ivPoke('useSgaFlag', $dataHash{'use_sga_flag'});
            $client->ivPoke('useNewEnvironFlag', $dataHash{'use_new_environ_flag'});
        }

        # Set MUD protocol flags
        $client->ivPoke('useMccpFlag', $dataHash{'use_mccp_flag'});
        if ($self->scriptConvertVersion >= 1_000_156) {

            $client->ivPoke('useMsdpFlag', $dataHash{'use_msdp_flag'});
            $client->ivPoke('useMsspFlag', $dataHash{'use_mssp_flag'});
            $client->ivPoke('useMttsFlag', $dataHash{'use_mtts_flag'});
        }
        $client->ivPoke('useMxpFlag', $dataHash{'use_mxp_flag'});
        $client->ivPoke('useMspFlag', $dataHash{'use_msp_flag'});
        if ($self->scriptConvertVersion >= 1_000_844) {

            $client->ivPoke('usePuebloFlag', $dataHash{'use_pueblo_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_850) {

            $client->ivPoke('useAtcpFlag', $dataHash{'use_atcp_flag'});
            $client->ivPoke('useGmcpFlag', $dataHash{'use_gmcp_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_879) {

            $client->ivPoke('useZmpFlag', $dataHash{'use_zmp_flag'});
            $client->ivPoke('useAard102Flag', $dataHash{'use_aard_102_flag'});
            $client->ivPoke('useMcpFlag', $dataHash{'use_mcp_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_832) {

            $client->ivPoke('allowMxpFontFlag', $dataHash{'allow_mxp_font_flag'});
            $client->ivPoke('allowMxpImageFlag', $dataHash{'allow_mxp_image_flag'});
            $client->ivPoke('allowMxpLoadImageFlag', $dataHash{'allow_mxp_load_image_flag'});
            $client->ivPoke('allowMxpFilterImageFlag', $dataHash{'allow_mxp_filter_image_flag'});
            $client->ivPoke('allowMxpSoundFlag', $dataHash{'allow_mxp_sound_flag'});
            $client->ivPoke('allowMxpLoadSoundFlag', $dataHash{'allow_mxp_load_sound_flag'});
            $client->ivPoke('allowMxpGaugeFlag', $dataHash{'allow_mxp_gauge_flag'});
            $client->ivPoke('allowMxpFrameFlag', $dataHash{'allow_mxp_frame_flag'});
            $client->ivPoke('allowMxpInteriorFlag', $dataHash{'allow_mxp_interior_flag'});
            $client->ivPoke('allowMxpCrosslinkFlag', $dataHash{'allow_mxp_crosslink_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_887) {

            $client->ivPoke('allowMxpRoomFlag', $dataHash{'allow_mxp_room_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_678) {

            $client->ivPoke('allowMspMultipleFlag', $dataHash{'allow_msp_multiple_flag'});
            $client->ivPoke('allowMspLoadSoundFlag', $dataHash{'allow_msp_load_sound_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_886) {

            $client->ivPoke('allowMspFlexibleFlag', $dataHash{'allow_msp_flexible_flag'});
        }
        # Set telnet option negotiation customisation IVs
        if ($self->scriptConvertVersion >= 1_000_160) {

            $client->ivPoke('termTypeMode', $dataHash{'term_type_mode'});
            $client->ivPoke('customClientName', $dataHash{'custom_client_name'});
        }
        if ($self->scriptConvertVersion >= 1_000_666) {

            $client->ivPoke('customClientVersion', $dataHash{'custom_client_version'});
        }
        # Set telnet negotiation debug flags
        if ($self->scriptConvertVersion >= 1_000_378) {

            $client->ivPoke('debugTelnetFlag', $dataHash{'debug_telnet_flag'});
            $client->ivPoke('debugTelnetMiniFlag', $dataHash{'debug_telnet_mini_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_895) {

            $client->ivPoke('debugTelnetLogFlag', $dataHash{'debug_telnet_log_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_378) {

            $client->ivPoke('debugMsdpFlag', $dataHash{'debug_msdp_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_405) {

            $client->ivPoke('debugMxpFlag', $dataHash{'debug_mxp_flag'});
            $client->ivPoke('debugMxpCommentFlag', $dataHash{'debug_mxp_comment_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_849) {

            $client->ivPoke('debugPuebloFlag', $dataHash{'debug_pueblo_flag'});
            $client->ivPoke('debugPuebloCommentFlag', $dataHash{'debug_pueblo_comment_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_926) {

            $client->ivPoke('debugAtcpFlag', $dataHash{'debug_atcp_flag'});
            $client->ivPoke('debugGmcpFlag', $dataHash{'debug_gmcp_flag'});
        }

        # Set misc data
        $client->ivPoke('customMonthList', @{$dataHash{'custom_month_list'}});
        $client->ivPoke('customDayList', @{$dataHash{'custom_day_list'}});
        $client->ivPoke('promptWaitTime', $dataHash{'prompt_wait_time'});
        $client->ivPoke('loginWarningTime', $dataHash{'login_warning_time'});
        if ($self->scriptConvertVersion >= 1_000_331) {

            if ($self->scriptConvertVersion <= 1_000_535) {

                $client->ivPoke('debugLineNumsFlag', $dataHash{'debug_world_flag'});
                $client->ivPoke('debugLineTagsFlag', $dataHash{'debug_world_flag'});

            } else {

                $client->ivPoke('debugLineNumsFlag', $dataHash{'debug_line_nums_flag'});
                $client->ivPoke('debugLineTagsFlag', $dataHash{'debug_line_tags_flag'});
            }
        }
        $client->ivPoke('debugLocatorFlag', $dataHash{'debug_locator_flag'});
        if ($self->scriptConvertVersion >= 1_000_482) {

            $client->ivPoke('debugMaxLocatorFlag', $dataHash{'debug_max_locator_flag'});
        }
        $client->ivPoke('debugMoveListFlag', $dataHash{'debug_move_list_flag'});
        $client->ivPoke('debugParseObjFlag', $dataHash{'debug_parse_obj_flag'});
        $client->ivPoke('debugCompareObjFlag', $dataHash{'debug_compare_obj_flag'});
        $client->ivPoke('debugExplainPluginFlag', $dataHash{'debug_explain_plugin_flag'});
        $client->ivPoke('debugCheckIVFlag', $dataHash{'debug_check_iv_flag'});
        if ($self->scriptConvertVersion >= 1_000_800) {

            $client->ivPoke('debugTableFitFlag', $dataHash{'debug_table_fit_flag'});
        }
        $client->ivPoke('debugTrapErrorFlag', $dataHash{'debug_trap_error_flag'});
        if ($self->scriptConvertVersion >= 1_000_949) {

            $client->ivPoke('toolbarLabelFlag', $dataHash{'toolbar_label_flag'});
        }
        $client->ivPoke('irreversibleIconFlag', $dataHash{'irreversible_icon_flag'});
        if ($self->scriptConvertVersion >= 1_000_344) {

            $client->ivPoke('mainWinUrgencyFlag', $dataHash{'main_win_urgency_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_883) {

            $client->ivPoke('mainWinTooltipFlag', $dataHash{'main_win_tooltip_flag'});
        }
        $client->ivPoke('sessionTabMode', $dataHash{'session_tab_mode'});
        if ($self->scriptConvertVersion >= 1_000_184) {

            $client->ivPoke('xTermTitleFlag', $dataHash{'xterm_title_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_365) {

            $client->ivPoke('longTabLabelFlag', $dataHash{'long_tab_label_flag'});
            $client->ivPoke('simpleTabFlag', $dataHash{'simple_tab_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_917) {

            $client->ivPoke('confirmCloseMainWinFlag', $dataHash{'confirm_close_main_win_flag'});
            $client->ivPoke('confirmCloseTabFlag', $dataHash{'confirm_close_tab_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_185) {

            $client->ivPoke('charSet', $dataHash{'char_set'});
        }
        if ($self->scriptConvertVersion >= 1_000_616) {

            $client->ivPoke('sessionMax', $dataHash{'session_max'});
        }
        if ($self->scriptConvertVersion >= 1_000_884) {

            $client->ivPoke('connectHistoryFlag', $dataHash{'connect_history_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_338) {

            $client->ivPoke('useScrollKeysFlag', $dataHash{'use_scroll_keys_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_884) {

            $client->ivPoke('smoothScrollKeysFlag', $dataHash{'smooth_scroll_keys_flag'});
            $client->ivPoke('autoSplitKeysFlag', $dataHash{'auto_split_keys_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_338) {

            $client->ivPoke('useCompleteKeysFlag', $dataHash{'use_complete_keys_flag'});
            $client->ivPoke('useSwitchKeysFlag', $dataHash{'use_switch_keys_flag'});
        }

        ######################
        # Load complete

        # If the loaded config file was saved by an earlier version of Axmud than the one we're
        #   using now, the file object's data must be marked as needing to be saved (in case the
        #   config file uses new IVs)
        if ($self->scriptConvertVersion < $axmud::CLIENT->convertVersion($axmud::VERSION)) {

            $self->set_modifyFlag(TRUE, $self->_objClass . '->loadConfigFile');

        } else {

            # Otherwise, mark the file object's data as not needing to be saved
            $self->set_modifyFlag(FALSE, $self->_objClass . '->loadConfigFile');
        }

        return 1;
    }

    sub setupDataFile {

        # Called by GA::Client->loadOtherFiles for the file types:
        #   'tasks', 'scripts', 'contacts', 'keycodes', 'dicts', 'toolbar', 'usercmds', 'zonemaps',
        #   'winmaps', 'tts'
        # Loads a data file. If the file doesn't exist, creates it
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or if there any errors reading/writing the file, or if
        #       file loading/saving isn't allowed (because of global flags)
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $obj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setupDataFile', @_);
        }

        # Check it's the right file type for this function
        if (
            $self->fileType ne 'tasks' && $self->fileType ne 'scripts'
            && $self->fileType ne 'contacts' && $self->fileType ne 'keycodes'
            && $self->fileType ne 'dicts' && $self->fileType ne 'toolbar'
            && $self->fileType ne 'usercmds' && $self->fileType ne 'zonemaps'
            && $self->fileType ne 'winmaps' && $self->fileType ne 'tts'
        ) {
            return $self->writeError(
                'Wrong file type \'' . $self->fileType . '\'',
                $self->_objClass . '->setupDataFile',
            );
        }

        # Check whether the data file already exists, and if we're allowed to load it
        if ($axmud::CLIENT->loadDataFlag && -e $axmud::DATA_DIR . $self->standardPath) {

            # The file exists and we are allowed to load it, so try to load it (in overwrite mode)
            if (! $self->loadDataFile()) {

                return $self->writeError(
                    'Error reading \'' . $self->fileType . '\' data file',
                    $self->_objClass . '->setupDataFile',
                );

            } else {

                # File loaded
                return 1;
            }

        } elsif ($axmud::CLIENT->saveDataFlag && ! (-e $axmud::DATA_DIR . $self->standardPath)) {

            # The file doesn't exist, but we are allowed to create it
            if (! $self->saveDataFile()) {

                return $self->writeError(
                    'Error creating \'' . $self->fileType . '\' data file',
                    $self->_objClass . '->setupDataFile',
                );

            } else {

                # File created
                return 1;
            }

        } else {

            # Cannot load or save the data file
            return undef;
        }
    }

    sub saveDataFile {

        # Called by $self->setupDataFile (or by any other function) for the file types:
        #   'tasks', 'scripts', 'contacts', 'keycodes', 'dicts', 'toolbar', 'usercmds', 'zonemaps',
        #   'winmaps', 'tts'
        # Called by any function for the file types:
        #   'worldprof', 'otherprof', 'worldmodel'
        #
        # Saves a data file of the type specified by $self->fileType
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $fileName   - The file name, e.g. 'tasks.axm'
        #   $path       - The full path, e.g. '/home/me/axmud-data/data/tasks.axm'
        #   $dir        - The directory, e.g. '/home/me/axmud-data/data/'
        #   $emergFlag  - If set to TRUE, an emergency save is in progress.
        #                   GA::Client->saveDataFlag is ignored, $self->disableAllFileAccess is not
        #                   called on failure, and $self->modifyFlag is not set. Set to FALSE (or
        #                   'undef') if an emergency save is not in progress
        #
        # Notes:
        #   If $fileName is specified, $path and $dir must also be specified
        #   If $fileName is not specified, the default filename, path and directory for this file
        #       type are used
        #
        # Return values
        #   'undef' on improper arguments, if saving of data files isn't allowed (because of global
        #       flags) or if there is an error saving the data file itself
        #   1 otherwise

        my ($self, $fileName, $path, $dir, $emergFlag, $check) = @_;

        # Local variables
        my (
            $buPath, $checkWorldObj,
            %saveHash, %reverseHash, %importHash, %usrCmdHash,
        );

        # Check for improper arguments
        if (
            defined $check
            || (defined $fileName && (! defined $path || ! defined $dir))
            || (defined $path && (! defined $fileName || ! defined $dir))
            || (defined $dir && (! defined $fileName || ! defined $path))
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->saveDataFile', @_);
        }

        # Check it's the right file type for this function
        if ($self->fileType eq 'config') {

            return $self->writeError(
                'Wrong file type \'' . $self->fileType . '\'',
                $self->_objClass . '->saveDataFile',
            );
        }

        # Set the filename, path and directory, if not specified
        if (! defined $fileName) {

            $fileName = $self->standardFileName;
            $path = $axmud::DATA_DIR . $self->standardPath;
            $dir = $axmud::DATA_DIR . $self->standardDir;
        }

        # Checks made when an emergency save is NOT in progress...
        if (! $emergFlag) {

            # Don't save anything if the global flag forbids it
            if (! $axmud::CLIENT->saveDataFlag) {

                return undef;
            }

            # Don't save 'worldprof', 'otherprof' and 'worldmodel' files associated with a world
            #   profile whose ->noSaveFlag is set
            if (
                $self->fileType eq 'worldprof' || $self->fileType eq 'otherprof'
                || $self->fileType eq 'worldmodel'
            ) {
                $checkWorldObj = $axmud::CLIENT->ivShow('worldProfHash', $self->assocWorldProf);

                # (During a ';cloneworld' operation, the cloned world profile won't have been added
                #   to ->worldProfHash; but ;cloneworld can't be used on (original) profiles whose
                #   ->noSaveFlag is set, so if $checkWorldObj is 'undef', we don't need to check its
                #   ->noSaveFlag)
                if ($checkWorldObj && $checkWorldObj->noSaveFlag) {

                    return undef;
                }
            }
        }

        # Check that the data directory exists and, if it doesn't, try to create it
        if (! (-d $dir)) {

            if (! mkdir ($dir, 0755)) {

                return undef;
            }
        }

        # Compile a special hash, %saveHash, that references all the data we want to save

        # First compile the header information (ie metadata)...
        $saveHash{'file_type'} = $self->fileType;
        $saveHash{'script_name'} = $axmud::NAME_FILE;
        $saveHash{'script_version'} = $axmud::VERSION;
        $saveHash{'save_date'} = $axmud::CLIENT->localDate();
        $saveHash{'save_time'} = $axmud::CLIENT->localTime();
        $saveHash{'assoc_world_prof'} = $self->assocWorldProf;

        # ...then compile the data for this file type
        if ($self->fileType eq 'worldprof') {

            $saveHash{'world_prof'}
                = $axmud::CLIENT->ivShow('worldProfHash', $self->assocWorldProf);

        } elsif ($self->fileType eq 'otherprof') {

            my %profHash;

            # From GA::Session->profHash, remove the current world profile, leaving all non-world
            #   profiles
            foreach my $profObj ($self->session->ivValues('profHash')) {

                if ($profObj->category ne 'world') {

                    $profHash{$profObj->name} = $self->session->ivShow('profHash', $profObj->name);
                }
            }

            $saveHash{'prof_priority_list'} = [$self->session->profPriorityList];
            $saveHash{'template_hash'} = {$self->session->templateHash};
            $saveHash{'prof_hash'} = \%profHash;
            $saveHash{'cage_hash'} = {$self->session->cageHash};

        } elsif ($self->fileType eq 'worldmodel') {

            $saveHash{'world_model_obj'} = $self->session->worldModelObj;

        } elsif ($self->fileType eq 'tasks') {

            $saveHash{'task_label_hash'} = {$axmud::CLIENT->taskLabelHash};
            $saveHash{'task_run_first_list'} = [$axmud::CLIENT->taskRunFirstList];
            $saveHash{'task_run_last_list'} = [$axmud::CLIENT->taskRunLastList];
            $saveHash{'init_task_hash'} = {$axmud::CLIENT->initTaskHash};
            $saveHash{'init_task_order_list'} = [$axmud::CLIENT->initTaskOrderList];
            $saveHash{'init_task_total'} = $axmud::CLIENT->initTaskTotal;
            $saveHash{'custom_task_hash'} = {$axmud::CLIENT->customTaskHash};

        } elsif ($self->fileType eq 'scripts') {

            $saveHash{'script_dir_list'} = [$axmud::CLIENT->scriptDirList];
            $saveHash{'init_script_hash'} = {$axmud::CLIENT->initScriptHash};
            $saveHash{'init_script_order_list'} = [$axmud::CLIENT->initScriptOrderList];

        } elsif ($self->fileType eq 'contacts') {

            $saveHash{'chat_name'} = $axmud::CLIENT->chatName;
            $saveHash{'chat_email'} = $axmud::CLIENT->chatEmail;
            $saveHash{'chat_accept_mode'} = $axmud::CLIENT->chatAcceptMode;
            $saveHash{'chat_contact_hash'} = {$axmud::CLIENT->chatContactHash};
            $saveHash{'chat_icon'} = $axmud::CLIENT->chatIcon;
            $saveHash{'chat_smiley_hash'} = {$axmud::CLIENT->chatSmileyHash};

        } elsif ($self->fileType eq 'keycodes') {

            $saveHash{'keycode_obj_hash'} = {$axmud::CLIENT->keycodeObjHash};
            $saveHash{'current_keycode_obj'} = $axmud::CLIENT->currentKeycodeObj;

        } elsif ($self->fileType eq 'dicts') {

            $saveHash{'dict_hash'} = {$axmud::CLIENT->dictHash};

        } elsif ($self->fileType eq 'toolbar') {

            $saveHash{'toolbar_hash'} = {$axmud::CLIENT->toolbarHash};
            $saveHash{'toolbar_list'} = [$axmud::CLIENT->toolbarList];

        } elsif ($self->fileType eq 'usercmds') {

            # We don't store user commands for client commands supplied by plugins. If we do, the
            #   user will get a lot of nasty errors when they try to use Axmud without loading those
            #   plugins
            # However, we do still store all user commands that the user has created for standard
            #   client commands like ';help' and ';about'
            %reverseHash = $axmud::CLIENT->constUserCmdHash;
            %importHash = $axmud::CLIENT->userCmdHash;
            foreach my $userCmd (keys %importHash) {

                my $standardCmd = $importHash{$userCmd};

                if (exists $reverseHash{$standardCmd}) {

                    $usrCmdHash{$userCmd} = $standardCmd;
                }
            }

            $saveHash{'user_cmd_hash'} = \%usrCmdHash;

        } elsif ($self->fileType eq 'zonemaps') {

            my %zonemapHash;

            # (Temporary zonemaps can't be saved, so we must remove them before saving)
            foreach my $zonemapObj ($axmud::CLIENT->ivValues('zonemapHash')) {

                if (! $zonemapObj->tempFlag) {

                    $zonemapHash{$zonemapObj->name} = $zonemapObj;
                }
            }

            $saveHash{'zonemap_hash'} = \%zonemapHash;

            # Standard zonemaps can't be temporary, so we can save that IV directly...
            $saveHash{'standard_zonemap_hash'} = {$axmud::CLIENT->standardZonemapHash};

        } elsif ($self->fileType eq 'winmaps') {

            $saveHash{'winmap_hash'} = {$axmud::CLIENT->winmapHash};
            $saveHash{'standard_winmap_hash'} = {$axmud::CLIENT->standardWinmapHash};
            $saveHash{'default_enabled_winmap'} = $axmud::CLIENT->defaultEnabledWinmap;
            $saveHash{'default_disabled_winmap'} = $axmud::CLIENT->defaultDisabledWinmap;
            $saveHash{'default_internal_winmap'} = $axmud::CLIENT->defaultInternalWinmap;
            $saveHash{'colour_scheme_hash'} = {$axmud::CLIENT->colourSchemeHash};

        } elsif ($self->fileType eq 'tts') {

            $saveHash{'tts_obj_hash'} = {$axmud::CLIENT->ttsObjHash};
        }

        # Glob test mode: In earlier Axmud versions, saving of data files failed (and Axmud crashed)
        #   because of infinite recursions with two Perl objects referencing each other. If TRUE,
        #   every save file operation (not including the config file) tests data for this problem,
        #   before saving it, writing the output to the terminal
        if ($axmud::TEST_GLOB_MODE_FLAG && ! $self->globTest(%saveHash)) {

            return undef;
        }

        # Precautions taken when an emergency save is NOT in progress...
        if (! $emergFlag) {

            # If the call to ->lock_nstore fails, an existing file called $path will be destroyed
            #   (this could be disastrous, if it contains a world profile, or something)
            # Create a temporary backup of the file, if it already exists, using File::Copy
            if (-e $path) {

                $buPath = $path . '.bu';
                File::Copy::copy($path, $buPath);
            }

            # Save the special hash as a single object
            eval { Storable::lock_nstore(\%saveHash, $path) };
            if ($@) {

                if ($buPath) {

                    # Restore the backup file
                    File::Copy::copy($buPath, $path);
                    # Delete the backup file, unless the user has opted to retain them
                    if (! $axmud::CLIENT->autoRetainFileFlag) {

                        unlink ($buPath);
                    }
                }

                # Disable loading/saving in all sessions
                $axmud::CLIENT->disableAllFileAccess();

                if ($buPath) {

                    return $self->writeError(
                        'Save data failure: \'' . $path . '\' (existing file restored from backup,'
                        . ' file loading/saving disabled)',
                        $self->_objClass . '->saveDataFile',
                    );

                } else {

                    return $self->writeError(
                        'Save data failure: \'' . $path . '\' (file loading/saving disabled)',
                        $self->_objClass . '->saveDataFile',
                    );
                }

            } else {

                # Save operation successful
                if ($buPath) {

                    # Delete the backup file, unless the user has opted to retain them
                    if (! $axmud::CLIENT->autoRetainFileFlag) {

                        unlink ($buPath);
                    }
                }

                # Set this file object's metadata variables
                $self->ivPoke('scriptName', $saveHash{'script_name'});
                $self->ivPoke('scriptVersion', $saveHash{'script_version'});
                $self->ivPoke(
                    'scriptConvertVersion',
                    $axmud::CLIENT->convertVersion($saveHash{'script_version'}),
                );
                $self->ivPoke('saveDate', $saveHash{'save_date'});
                $self->ivPoke('saveTime', $saveHash{'save_time'});
                $self->ivPoke('assocWorldProf', $saveHash{'assoc_world_prof'});

                $self->ivPoke('actualFileName', $fileName);
                $self->ivPoke('actualPath', $path);
                $self->ivPoke('actualDir', $dir);

                # Mark the file object's data as not modified
                $self->set_modifyFlag(FALSE, $self->_objClass . '->saveDataFile');

                return 1;
            }

        # (No precautions taken when an emergency save IS in progress)
        } else {

            # Save the special hash as a single object
            eval { Storable::lock_nstore(\%saveHash, $path) };
            if ($@) {

                return undef;

            } else {

                # (Don't update the file object's metadata variables for an emergency save)
                return 1;
            }
        }
    }

    sub loadDataFile {

        # Called by $self->setupDataFile (or by any other function) for the file types:
        #   'tasks', 'scripts', 'contacts', 'keycodes', 'dicts', 'toolbar', 'usercmds', 'zonemaps',
        #   'winmaps', 'tts'
        # Called by any function for the file types:
        #   'worldprof'
        # Called by any function for the file types:
        #   'otherprof', 'worldmodel'
        #
        # Loads a data file of the type specified by $self->fileType, replacing data in memory
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $fileName   - The file name, e.g. 'tasks.axm'
        #   $path       - The full path, e.g. '/home/me/axmud-data/data/tasks.axm'
        #   $dir        - The directory, e.g. '/home/me/axmud-data/data/'
        #
        # Notes:
        #   If one optional argument is specified, they must all be specified
        #   If no optional arguments are specified (or are all set to 'undef'), the default
        #       filename, path and directory for this file type are used
        #
        # Return values
        #   'undef' on improper arguments, if loading of data files isn't allowed (because of global
        #       flags) or if there is an error loading the data file itself
        #   1 otherwise

        my ($self, $fileName, $path, $dir, $check) = @_;

        # Local variables
        my (
            $matchFlag, $fileType, $scriptName, $scriptVersion, $saveDate, $saveTime,
            $assocWorldProf, $hashRef, $notCompatFlag,
            %loadHash,
        );

        # Check for improper arguments
        if (
            defined $check
            || (defined $fileName && (! defined $path || ! defined $dir))
            || (defined $path && (! defined $fileName || ! defined $dir))
            || (defined $dir && (! defined $fileName || ! defined $path))
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->loadDataFile', @_);
        }

        # Check it's the right file type for this function
        if ($self->fileType eq 'config') {

            return $self->writeError(
                'Wrong file type \'' . $self->fileType . '\'',
                $self->_objClass . '->loadDataFile',
            );
        }

        # Set the filename, path and directory, if not specified
        if (! defined $fileName) {

            $fileName = $self->standardFileName;
            $path = $axmud::DATA_DIR . $self->standardPath;
            $dir = $axmud::DATA_DIR . $self->standardDir;
        }

        # Don't load anything if the global flag forbids it
        if (! $axmud::CLIENT->loadDataFlag) {

            return undef;
        }

        # Check that the data directory exists
        if (! (-d $dir)) {

            return undef;
        }

        # Check that the specified file exists
        if (! (-e $path)) {

            # Before v1.0.868, Axmud used different file extensions; check them all
            OUTER: foreach my $ext (@axmud::COMPAT_EXT_LIST) {

                my $altPath = $path;
                $altPath =~ s/\.axm/.$ext/;

                if (-e $altPath) {

                    $matchFlag = TRUE;
                    $path = $altPath;
                    last OUTER;
                }
            }

            if (! $matchFlag) {

                return undef;
            }
        }

        # Load all the data into a hash
        eval { $hashRef = Storable::lock_retrieve($path); };
        if (! $hashRef) {

            # ->lock_retrieve() failed
            return undef;

        } else {

            # Convert the hash referenced by $hashRef into a named hash
            %loadHash = %{$hashRef};

            # Before v1.0.868, Axmud had a different name. Update all header data
            if (
                defined $loadHash{'script_version'}
                && $axmud::CLIENT->convertVersion($loadHash{'script_version'}) < 1_000_868
            ) {
                %loadHash = $self->updateHeaderAfterRename(%loadHash);
            }

            # Extract the header information (ie metadata) from the hash
            $fileType = $loadHash{'file_type'};
            $scriptName = $loadHash{'script_name'};
            $scriptVersion = $loadHash{'script_version'};
            $saveDate = $loadHash{'save_date'};
            $saveTime = $loadHash{'save_time'};
            $assocWorldProf = $loadHash{'assoc_world_prof'};

            # Do checks on the header information
            if (! defined $fileType || $fileType ne $self->fileType) {

                # Wrong kind of file
               return undef;

            } elsif (
                ! defined $scriptName || ! defined $scriptVersion || ! defined $saveDate
                || ! defined $saveTime
            ) {
                # Missing or possibly corrupted header (NB $assocWorldProf can be 'undef')
                return undef;

            } elsif (
                ! $self->checkCompatibility($scriptName)
                || $axmud::CLIENT->convertVersion($scriptVersion)
                    > $axmud::CLIENT->convertVersion($axmud::VERSION)
            ) {
                # Data file not created by a current or previous version of Axmud
                return undef;
            }

            # Header information checks out. Store the values in this object
            $self->ivPoke('scriptName', $scriptName);
            $self->ivPoke('scriptVersion', $scriptVersion);
            $self->ivPoke('scriptConvertVersion', $axmud::CLIENT->convertVersion($scriptVersion));
            $self->ivPoke('saveDate', $saveDate);
            $self->ivPoke('saveTime', $saveTime);
            $self->ivPoke('assocWorldProf', $assocWorldProf);

            $self->ivPoke('actualFileName', $fileName);
            $self->ivPoke('actualPath', $path);
            $self->ivPoke('actualDir', $dir);

            # Extract the rest of the data from %loadHash, replacing data in memory with data from
            #   the loaded file
            if (! $self->extractData(TRUE, %loadHash)) {

                # Load failed
                return undef;

            } else {

                # Load complete
                return 1;
            }
        }
    }

    sub exportDataFile {

        # Called by GA::Cmd::ExportData->do for the file types:
        #   'config'
        # Exports a partial data file, often containing a single Perl object. The exported partial
        #   data file can be read by GA::Cmd::ImportData->do's call to $self->importDataFile
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $switch     - Switch used in the ';exportdata' command - tells us which kind of
        #                   object(s) to export (e.g. '-s' for profile templates)
        #   $name       - A name corresponding to the object(s) to export (e.g. the name of the
        #                   profile template)
        #
        # Notes:
        #   If one optional argument is specified, they must all be specified
        #   If no optional arguments are specified (or are all set to 'undef'), the default
        #       filename, path and directory for this file type are used
        #
        # Return values
        #   'undef' on improper arguments, if saving of data files isn't allowed (because of global
        #       flags), if the user cancels the export or if there is an error saving the data file
        #       itself
        #   Otherwise returns the path to the exported file

        my ($self, $session, $switch, $name, $check) = @_;

        # Local variables
        my (
            $suggestFile, $exportPath,
            %saveHash,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $switch || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->exportDataFile', @_);
        }

        # Check it's the right file type for this function
        if ($self->fileType ne 'config') {

            return $self->writeError(
                'Wrong file type \'' . $self->fileType . '\'',
                $self->_objClass . '->exportDataFile',
            );
        }

        # Don't save anything if the global flags forbid it
        if (! $axmud::CLIENT->saveDataFlag) {

            return undef;
        }

        # Compile a special hash, %saveHash, that references all the data we want to save

        # First compile the header information (ie metadata)...
#        $saveHash{'file_type'} = $self->fileType;                  # Set below
        $saveHash{'script_name'} = $axmud::NAME_FILE;
        $saveHash{'script_version'} = $axmud::VERSION;
        $saveHash{'save_date'} = $axmud::CLIENT->localDate();
        $saveHash{'save_time'} = $axmud::CLIENT->localTime();
#        $saveHash{'assoc_world_prof'} = $self->assocWorldProf;     # Set below

        # ...then compile the data for this file type
        if ($switch eq '-d') {

            # ;exd -d <profile>
            #   Exports the non-world profile <profile>. If it's a custom profile, the profile
            #       template is also exported. All of the profile's cages are also exported. (World
            #       profiles can't be exported using this command - use ';exportfile' instead.)

            my (
                $profObj,
                %profHash, %cageHash, %templateHash,
            );

            # Prepare the data for a partial 'otherprof' file
            $profObj = $session->ivShow('profHash', $name);
            $profHash{$name} = $profObj;

            foreach my $cageType ($axmud::CLIENT->cageTypeList) {

                $cageHash{$name} = $session->findCage($cageType, $name);
            }

            if ($session->ivExists('templateHash', $profObj->category)) {

                # This is a custom profile, so we also need to export its parent profile template
                $templateHash{$profObj->category}
                    = $session->ivShow('templateHash', $profObj->category);
            }

            # Transfer everything into %saveHash
            $saveHash{'file_type'} = 'otherprof';
            $saveHash{'assoc_world_prof'} = $session->currentWorld->name;
            $saveHash{'prof_priority_list'} = [];
            $saveHash{'template_hash'} = \%templateHash;     # Possibly an empty hash
            $saveHash{'prof_hash'} = \%profHash;
            $saveHash{'cage_hash'} = \%cageHash;

        } elsif ($switch eq '-t') {

            # ;exd -t <cage>
            #   Exports the single cage named <cage>

            my %cageHash;

            # Prepare the data for a partial 'otherprof' file
            $cageHash{$name} = $session->ivShow('cageHash', $name);

            # Transfer everything into %saveHash
            $saveHash{'file_type'} = 'otherprof';
            $saveHash{'assoc_world_prof'} = $session->currentWorld->name;
            $saveHash{'prof_priority_list'} = [];
            $saveHash{'template_hash'} = {};
            $saveHash{'prof_hash'} = {};
            $saveHash{'cage_hash'} = \%cageHash;

        } elsif ($switch eq '-e') {

            # ;exd -e <profile>
            #   Exports all the cages belonging to the profile <profile>, but not the profile itself

            my %cageHash;

            # Prepare the data for a partial 'otherprof' file
            foreach my $cageType ($axmud::CLIENT->cageTypeList) {

                $cageHash{$name} = $session->findCage($cageType, $name);
            }

            # Transfer everything into %saveHash
            $saveHash{'file_type'} = 'otherprof';
            $saveHash{'assoc_world_prof'} = $session->currentWorld->name;
            $saveHash{'prof_priority_list'} = [];
            $saveHash{'template_hash'} = {};
            $saveHash{'prof_hash'} = {};
            $saveHash{'cage_hash'} = \%cageHash;

        } elsif ($switch eq '-s') {

            # ;exd -s <skel>
            #   Exports the template profile named <skel>

            my %templateHash;

            # Prepare the data for a partial 'otherprof' file
            $templateHash{$name} = $session->ivShow('templateHash', $name);

            # Transfer everything into %saveHash
            $saveHash{'file_type'} = 'otherprof';
            $saveHash{'assoc_world_prof'} = $session->currentWorld->name;
            $saveHash{'prof_priority_list'} = [];
            $saveHash{'template_hash'} = \%templateHash;
            $saveHash{'prof_hash'} = {};
            $saveHash{'cage_hash'} = {};

        } elsif ($switch eq '-i') {

            # ;exd -i <task>
            #   Exports the (global) initial task named <task>. (Initial tasks belonging to a
            #       profile can't be exported - you must export the whole profile)

            my %initTaskHash;

            # Prepare the data for a partial 'tasks' file
            $initTaskHash{$name} = $axmud::CLIENT->ivShow('initTaskHash', $name);

            # Transfer everything into %saveHash
            $saveHash{'file_type'} = 'tasks';
            $saveHash{'assoc_world_prof'} = undef;
            $saveHash{'task_label_hash'} = {};
            $saveHash{'task_run_first_list'} = [];
            $saveHash{'task_run_last_list'} = [];
            $saveHash{'init_task_hash'} = \%initTaskHash;
            $saveHash{'init_task_order_list'} = [];
            $saveHash{'init_task_total'} = undef;
            $saveHash{'custom_task_hash'} = {};
            $saveHash{'init_script_hash'} = {};
            $saveHash{'init_script_order_list'} = [];

        } elsif ($switch eq '-c') {

            # ;exd -c <task>
            #   Exports the custom task named <task>

            my %customTaskHash;

            # Prepare the data for a partial 'tasks' file
            $customTaskHash{$name} = $axmud::CLIENT->ivShow('customTaskHash', $name);

            # Transfer everything into %saveHash
            $saveHash{'file_type'} = 'tasks';
            $saveHash{'assoc_world_prof'} = undef;
            $saveHash{'task_label_hash'} = {};
            $saveHash{'task_run_first_list'} = [];
            $saveHash{'task_run_last_list'} = [];
            $saveHash{'init_task_hash'} = {};
            $saveHash{'init_task_order_list'} = [];
            $saveHash{'init_task_total'} = undef;
            $saveHash{'custom_task_hash'} = \%customTaskHash;
            $saveHash{'init_script_hash'} = {};
            $saveHash{'init_script_order_list'} = [];

        } elsif ($switch eq '-k') {

            # ;exd -k <obj>
            #   Exports the keycode object named <obj>

            my %keycodeHash;

            # Prepare the data for a partial 'keycodes' file
            $keycodeHash{$name} = $axmud::CLIENT->ivShow('keycodeObjHash', $name);

            # Transfer everything into %saveHash
            $saveHash{'file_type'} = 'keycodes';
            $saveHash{'assoc_world_prof'} = undef;
            $saveHash{'keycode_obj_hash'} = \%keycodeHash;
            $saveHash{'current_keycode_obj'} = undef;

        } elsif ($switch eq '-y') {

            # ;exd -y <dict>
            #   Exports the dictionary named <dict>

            my %dictHash;

            # Prepare the data for a partial 'dicts' file
            $dictHash{$name} = $axmud::CLIENT->ivShow('dictHash', $name);

            # Transfer everything into %saveHash
            $saveHash{'file_type'} = 'dicts';
            $saveHash{'assoc_world_prof'} = undef;
            $saveHash{'dict_hash'} = \%dictHash;

        } elsif ($switch eq '-z') {

            # ;exd -z <map>
            #   Exports the zonemap named <map>, including all of its zone models

            my %zonemapHash;

            # Prepare the data for a partial 'zonemaps' file
            $zonemapHash{$name} = $axmud::CLIENT->ivShow('zonemapHash', $name);

            # Transfer everything into %saveHash
            $saveHash{'file_type'} = 'zonemaps';
            $saveHash{'assoc_world_prof'} = undef;
            $saveHash{'zonemap_hash'} = \%zonemapHash;
            $saveHash{'standard_zonemap_hash'} = {};

        } elsif ($switch eq '-p') {

            # ;exd -p <map>
            #   Exports the winmap named <map>, including all of its winzone objects

            my %winmapHash;

            # Prepare the data for a partial 'winmaps' file
            $winmapHash{$name} = $axmud::CLIENT->ivShow('winmapHash', $name);

            # Transfer everything into %saveHash
            $saveHash{'file_type'} = 'winmaps';
            $saveHash{'assoc_world_prof'} = undef;
            $saveHash{'winmap_hash'} = \%winmapHash;
            $saveHash{'standard_winmap_hash'} = {};
            $saveHash{'default_main_winmap'} = undef;
            $saveHash{'default_internal_winmap'} = undef;
            $saveHash{'colour_scheme_hash'} = {};

        } elsif ($switch eq '-o') {

            # ;exd -o <col>
            #   Exports the colour scheme named <col>

            my %colourSchemeHash;

            # Prepare the data for a partial 'winmaps' file
            $colourSchemeHash{$name} = $axmud::CLIENT->ivShow('colourSchemeHash', $name);

            # Transfer everything into %saveHash
            $saveHash{'file_type'} = 'winmaps';
            $saveHash{'assoc_world_prof'} = undef;
            $saveHash{'winmap_hash'} = {};
            $saveHash{'standard_winmap_hash'} = {};
            $saveHash{'default_main_winmap'} = undef;
            $saveHash{'default_internal_winmap'} = undef;
            $saveHash{'colour_scheme_hash'} = \%colourSchemeHash;

        } elsif ($switch eq '-x') {

            # ;exd -x <obj>
            #   Exports the text-to-speech object name <obj>

            my %ttsHash;

            # Prepare the data for a partial 'tts' file
            $ttsHash{$name} = $axmud::CLIENT->iShow('ttsObjHash', $name);

            # Transfer everything into %saveHash
            $saveHash{'file_type'} = 'tts';
            $saveHash{'assoc_world_prof'} = undef;
            $saveHash{'tts_obj_hash'} = \%ttsHash;
        }

        # Set the suggested name for the data file
        $suggestFile = $name . '.amx';

        # Open a file chooser dialog to decide where to save the exported file
        # NB Private code, not included in the public release, sets the IV
        #   GA::Client->privConfigAllWorld, in which case we use a certain file path, rather than
        #   prompting the user for one
        if (! $axmud::CLIENT->privConfigAllWorld) {

            $exportPath = $session->mainWin->showFileChooser(
                'Export object',
                'save',
                $suggestFile,
            );

            if (! $exportPath) {

                # User canceleld
                return undef;
            }

        } else {

            $exportPath = $axmud::SHARE_DIR . '/items/worlds/' . $axmud::CLIENT->privConfigAllWorld
                            . '/' . $axmud::CLIENT->privConfigAllWorld . '.amx';
        }

        # Save the special hash as a single object
        if (! Storable::lock_nstore(\%saveHash, $exportPath)) {

            # Export failed
            return undef;

        } else {

            # Export complete
            return $exportPath;
        }
    }

    sub importDataFile {

        # Called by GA::Cmd::ImportData->do for the file types:
        #   'config'
        #
        # Loads an exported data file into memory, replacing existing data in memory only when
        #   objects with the same name exist
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $importPath     - The full path of the file to import
        #
        # Return values
        #   'undef' on improper arguments, if loading of data files isn't allowed (because of global
        #       flags), if the user cancels the load or if there is an error loading the data file
        #       itself
        #   Otherwise returns the filetype (e.g. 'worldprof' or 'tasks')

        my ($self, $session, $importPath, $check) = @_;

        # Local variables
        my (
            $matchFlag, $hashRef, $fileType, $scriptName, $scriptVersion, $saveDate, $saveTime,
            $assocWorldProf, $fileObj, $result, $notCompatFlag,
            %loadHash,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $importPath || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->importDataFile', @_);
        }

        # Check it's the right file type for this function
        if ($self->fileType ne 'config') {

            return $self->writeError(
                'Wrong file type \'' . $self->fileType . '\'',
                $self->_objClass . '->importDataFile',
            );
        }

        # Don't load anything if the global flags forbid it
        if (! $axmud::CLIENT->loadDataFlag) {

            return undef;
        }

        # Check that the specified file exists
        if (! (-e $importPath)) {

            # Before v1.0.868, Axmud used different file extensions; check them all
            OUTER: foreach my $ext (@axmud::COMPAT_EXT_LIST) {

                my $altPath = $importPath;
                $altPath =~ s/\.axm/.$ext/;

                if (-e $altPath) {

                    $matchFlag = TRUE;
                    $importPath = $altPath;
                    last OUTER;
                }
            }

            if (! $matchFlag) {

                return undef;
            }
        }

        # Load all the data into an anonymous hash
        eval { $hashRef = Storable::lock_retrieve($importPath); };
        if (! $hashRef) {

            # ->lock_retrieve() failed
            return undef;

        } else {

            # Convert the anonymous hash referenced by $hashRef into a named hash
            %loadHash = %{$hashRef};

            # Before v1.0.868, Axmud had a different name. Update all header data
            if (
                defined $loadHash{'script_version'}
                && $axmud::CLIENT->convertVersion($loadHash{'script_version'}) < 1_000_868
            ) {
                %loadHash = $self->updateHeaderAfterRename(%loadHash);
            }

            # Extract the header information (ie metadata) from the hash
            $fileType = $loadHash{'file_type'};
            $scriptName = $loadHash{'script_name'};
            $scriptVersion = $loadHash{'script_version'};
            $saveDate = $loadHash{'save_date'};
            $saveTime = $loadHash{'save_time'};
            $assocWorldProf = $loadHash{'assoc_world_prof'};

            # Do checks on the header information
            if (
                ! defined $fileType || ! defined $scriptName || ! defined $scriptVersion
                || ! defined $saveDate || ! defined $saveTime
            ) {
                # Missing or possibly corrupted header (NB $assocWorldProf can be 'undef')
                return undef;

            } elsif (
                ! $self->checkCompatibility($scriptName)
                || $axmud::CLIENT->convertVersion($scriptVersion)
                    > $axmud::CLIENT->convertVersion($axmud::VERSION)
            ) {
                # Data file not created by a current or previous version of Axmud
                return undef;
            }

            # Extract the rest of the data from %loadHash, incorporating data from the loaded file
            #   into memory
            if ($fileType eq 'worldprof') {

                # Call ->extractData on the file object belonging to the current world profile
                $fileObj = $session->ivShow(
                    'sessionFileObjHash',
                    $session->currentWorld->name,
                );

            } elsif ($axmud::CLIENT->ivExists('fileObjHash', $fileType)) {

                # Call ->extractData on the corresponding file object
                $fileObj = $axmud::CLIENT->ivShow('fileObjHash', $fileType);

            } elsif ($session->ivExists('sessionFileObjHash', $fileType)) {

                # Call ->extractData on the corresponding file object
                $fileObj = $session->ivShow('sessionFileObjHash', $fileType);

            } else {

                # No file object into which to incorporate the imported data
                return undef;
            }

            # If the existing file object needs to be saved, asked permission before importing data
            #   into it
            $result = $session->mainWin->showMsgDialogue(
                'Overwrite unsaved data',
                'question',
                'The file you have specified may overwrite unsaved data in memory. Import the'
                . ' file anyway?',
                'yes-no',
            );

            if ($result eq 'no') {

                return undef;
            }

            # Extract the imported data
            $result = $fileObj->extractData(FALSE, %loadHash);
            if (! $result) {

                # Import failed
                return undef;

            } else {

                # Return the file type of the imported file
                return $result;
            }
        }
    }

    sub extractData {

        # Called by $self->loadDataFile or $self->importDataFile
        # Processes an anonymous hash, referenced by %hashRef, containing data loaded from a file
        # Overwrites data in memory, then calls $self->updateExtractedData to update data from
        #       previous versions of Axmud to make it work with the code in this version
        #
        # Expected arguments
        #   $overWriteFlag  - Set to TRUE when called by $self->loadDataFile. Overwites (most)
        #                       existing data in memory
        #                   - Set to FALSE when called by $self->importDataFile. Incorporates (most)
        #                       of the loaded data into memory, replacing identically named
        #                       objects, but retaining other existing objects in memory
        #   %loadHash       - A hash containing all the loaded data (including header data)
        #
        # Notes
        #   $overWriteFlag works on the following general principle:
        #
        #   If $overWriteFlag = TRUE, when tasks.axm contains the custom tasks 'task3' and 'task4',
        #       and when the custom tasks 'task1' and 'task2' are in memory, after loading only
        #       'task3' and 'task4' are in memory.
        #   If $overWriteFlag = FALSE, when tasks.axm contains the custom task 'task3', and when the
        #       custom tasks 'task1' and 'task2' are in memory, all three tasks will be in memory
        #       at the end of the operation. However, if tasks.amx contains 'task2', the 'task2' in
        #       memory will be overwritten
        #
        #   The precise behaviour for each file type is as follows:
        #       'worldprof'
        #           (T) The loaded world profile replaces one in memory with the same name
        #           (F) (This function should not be called)
        #       'otherprof'
        #           (T) All existing non-world profiles, cages and templates are destroyed and
        #               replaced with any loaded ones. The existing world profile is not replaced
        #           (F) We are importing a single non-world profile, or a single template; this
        #               replaces one in memory with the same name. For profiles, the cages are
        #               updated
        #       'worldmodel'
        #           The entire world model in memory is replaced by the loaded one, regardless of
        #               the flag
        #       'tasks', 'scripts', 'contacts', 'keycodes', 'tts'
        #           Behaviour as described above
        #       'dicts'
        #           (T) Any current dictionaries in use by a session are retained, if a dictionary
        #                   with the same name doesn't exist in the loaded file, but dictionaries
        #                   not in use are replaced. Otherwise, all dictionaries are replaced
        #           (F) If one of the loaded dictionaries has the same name as a current dictionary
        #                   in use by any session, that current dictionary is replaced. Otherwise,
        #                   all dictionaries are incorporated
        #       'toolbar'
        #           The entire list of toolbar buttons in memory is replaced by the loaded one,
        #               regardless of the flag
        #       'usercmds'
        #           (T) It's quite common for new commands to be added in between versions of Axmud.
        #               Any user commands corresponding to standard commands that didn't exist
        #               before are retained, but all other user commands are replaced
        #           (F) (This function should not be called)
        #       'zonemaps'
        #           (T) All zonemaps in memory are replaced. The workspace grids used by all
        #                   sessions are reset (when they exist). Any workspaces using a default
        #                   zonemap which no longer exists are given a new default zonemap. Any
        #                   workspace grids using a zonemap which no longer exists are reset to use
        #                   the workspace's default zonemap
        #           (F) Loaded data incorporated into memory. Any workspace grids using a loaded
        #                   zonemap are reset
        #       'winmaps'
        #           (T) All winmaps/colour schemes in memory are replaced; no existing windows are
        #                   affected, since winmaps are only applied when a window is created, and
        #                   colour schemes are only applied periodically
        #           (F) Loaded data incorporated into memory
        #       'tts'
        #           (T) All existing data in memory replaced by loaded data
        #           (F) Loaded data incorporated into memory
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the filetype (e.g. 'worldprof' or 'tasks')

        my ($self, $overWriteFlag, %loadHash) = @_;

        # Local variables
        my (
            $client, $session,
            %hash,
        );

        # Check for improper arguments
        if (! defined $overWriteFlag) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->extractData', @_);
        }

        # Import shortcuts for the GA::Client and GA::Session
        $client = $axmud::CLIENT;
        $session = $self->session;

        # Before v1.0.868, Axmud had a different name. Update all file data
        if ($axmud::CLIENT->convertVersion($self->scriptVersion) < 1_000_868) {

            %loadHash = $self->updateDataAfterRename(%loadHash);
        }

        # Extract the data
        if ($self->fileType eq 'worldprof') {

            # 'worldprof'
            #   (T) The loaded world profile replaces one in memory with the same name
            #   (F) (This function should not be called)

            if ($overWriteFlag) {

                # (When overwriting, set IVs directly, rather than using 'set' accessors)

                # Replace a profile in memory with the same name
                $client->ivAdd(
                    'worldProfHash',
                    $self->assocWorldProf,
                    $loadHash{'world_prof'},
                );

                # Every session using this world must also have its profile registry updated
                foreach my $session ($axmud::CLIENT->listSessions()) {

                    if ($session->currentWorld->name eq $self->assocWorldProf) {

                        $session->ivAdd('profHash', $self->assocWorldProf, $loadHash{'world_prof'});
                    }
                }

                # The data in memory matches the one in saved data files
                $self->set_modifyFlag(FALSE, $self->_objClass . '->extractData');

            } else {

                # (When not overwriting, use 'set' accessors, since the data in memory no longer
                #   matches the saved file)

                # (Should not be able to import a partial 'worldprof' file, since
                #   $self->exportDataFile doesn't create one)
                return undef;
            }

        } elsif ($self->fileType eq 'otherprof') {

            # 'otherprof'
            #   (T) All existing non-world profiles, cages and templates are destroyed and replaced
            #       with any loaded ones. The existing world profile is not replaced
            #   (F) We are importing a single non-world profile, or a single template; this replaces
            #       one in memory with the same name. For profiles, the cages are updated

            my ($worldProfObj, $modFlag);

            if ($overWriteFlag) {

                # We are loading all the non-world profiles associated with a world profile, and all
                #   the cages/templates associated with them
                # If GA::Session->profHash contains a world profile, it is not replaced (but
                #   everything else is)

                # Find the world profile already in memory
                OUTER: foreach my $profObj ($session->ivValues('profHash')) {

                    if ($profObj->category eq 'world') {

                        $worldProfObj = $profObj;
                        last OUTER;
                    }
                }

                # Replace the contents of the profile registry
                $session->ivPoke('profHash', %{$loadHash{'prof_hash'}});
                if ($worldProfObj) {

                    $session->ivAdd('profHash', $worldProfObj->name, $worldProfObj);
                }

                # Replace the contents of other IVs
                $session->ivPoke('profPriorityList', @{$loadHash{'prof_priority_list'}});
                $session->ivPoke('templateHash', %{$loadHash{'template_hash'}});
                $session->ivPoke('cageHash', %{$loadHash{'cage_hash'}});

                # The data in memory matches saved data files
                $self->set_modifyFlag(FALSE, $self->_objClass . '->extractData');
                # Cages for the world profile have been loaded (probably), so its file object must
                #   be marked as having had its data changed
                $client->setModifyFlag(
                    $loadHash{'assoc_world_prof'},
                    TRUE,
                    $self->_objClass . '->extractData',
                );

            } else {

                # We are loading one or more non-world profiles, templates or cages that have been
                #   exported and must be re-incorporated into memory

                # Incorporate non-world profiles and their corresponding cages
                %hash = %{$loadHash{'prof_hash'}};
                if (%hash) {

                    foreach my $profObj (values %hash) {

                        $session->add_prof($profObj);
                    }
                }

                %hash = %{$loadHash{'cage_hash'}};
                if (%hash) {

                    foreach my $cageObj (values %hash) {

                        $session->add_cage($cageObj);
                    }
                }

                %hash = %{$loadHash{'template_hash'}};
                if (%hash) {

                    foreach my $templateObj (values %hash) {

                        $session->add_template($templateObj);
                    }
                }

                # (Calls to accessors will have set the right ->modifyFlag values)
            }

        } elsif ($self->fileType eq 'worldmodel') {

            # 'worldmodel'
            #   The entire world model in memory is replaced by the loaded one, regardless of
            #       the value of $overWriteFlag

            my $swapFlag;

            $session->ivPoke('worldModelObj', $loadHash{'world_model_obj'});

            if ($overWriteFlag) {

                # The data in memory matches saved data files
                $self->set_modifyFlag(FALSE, $self->_objClass . '->extractData');

            } else {

                # The data in memory doesn't match saved data files
                $self->set_modifyFlag(TRUE, $self->_objClass . '->extractData');
            }

            # Delete any temporary regions from the world model
            # $self->updateExtractedData hasn't been called yet, so before v1.0.871,
            #   ->regionModelHash will still be ->regionModel
            if (
                $self->scriptConvertVersion < 1_000_871
                && ! exists $session->worldModelObj->{regionModelHash}
            ) {
                # Swap the IV name temporarily, so ->deleteTempRegions doesn't get confused
                $session->worldModelObj->{regionModelHash} = $session->worldModelObj->{regionModel};
                delete $session->worldModelObj->{regionModel};
                $swapFlag = TRUE;
            }

            $session->worldModelObj->deleteTempRegions(
                $session,
                TRUE,           # Update any Automapper windows that are already open
            );

            if ($swapFlag) {

                # Restore the IV names, so $self->updateExtractedData doesn't get confused
                $session->worldModelObj->{regionModel} = $session->worldModelObj->{regionModelHash};
                delete $session->worldModelObj->{regionModelHash};
            }

        } elsif ($self->fileType eq 'tasks') {

            # 'tasks'
            #   (T) All existing data in memory replaced by loaded data
            #   (F) Loaded data incorporated into memory

            if ($overWriteFlag) {

                # Replace the data in memory
                $client->ivPoke('taskLabelHash', %{$loadHash{'task_label_hash'}});
                $client->ivPoke('taskRunFirstList', @{$loadHash{'task_run_first_list'}});
                $client->ivPoke('taskRunLastList', @{$loadHash{'task_run_last_list'}});
                $client->ivPoke('initTaskHash', %{$loadHash{'init_task_hash'}});
                $client->ivPoke('initTaskOrderList', @{$loadHash{'init_task_order_list'}});
                $client->ivPoke('initTaskTotal', $loadHash{'init_task_total'});
                $client->ivPoke('customTaskHash', %{$loadHash{'custom_task_hash'}});

                # The data in memory matches saved data files
                $self->set_modifyFlag(FALSE, $self->_objClass . '->extractData');

            } else {

                # We are loading one or more global initial task or custom task that have been
                #   exported and must be re-incorporated into memory

                # Incorporate tasks
                %hash = %{$loadHash{'init_task_hash'}};
                foreach my $taskObj (values %hash) {

                    # Give the task a new unique name, before adding it to the client's registries
                    $taskObj->updateTaskLists();
                }

                %hash = %{$loadHash{'custom_task_hash'}};
                foreach my $taskObj (values %hash) {

                    # Give the task a new unique name, before adding it to the client's registries
                    $taskObj->updateTaskLists();
                }

                # (Calls to accessors will have set the right ->modifyFlag values)
            }

        } elsif ($self->fileType eq 'scripts') {

            # 'scripts'
            #   (T) All existing data in memory replaced by loaded data
            #   (F) Loaded data incorporated into memory

            if ($overWriteFlag) {

                # Replace the data in memory
                $client->ivPoke('scriptDirList', @{$loadHash{'script_dir_list'}});
                $client->ivPoke('initScriptHash', %{$loadHash{'init_script_hash'}});
                $client->ivPoke('initScriptOrderList', @{$loadHash{'init_script_order_list'}});

                # The data in memory matches saved data files
                $self->set_modifyFlag(FALSE, $self->_objClass . '->extractData');

            } else {

                # Incorporate script directories into memory
                foreach my $dir (@{$loadHash{'script_dir_list'}}) {

                    # Only add directories which aren't already in the script directory list
                    if (! defined $client->ivFind('scriptDirList', $dir)) {

                        $client->ivPush('scriptDirList', $dir);
                    }
                }

                # Incorporate initial scripts into memory
                %hash = %{$loadHash{'init_script_hash'}};
                foreach my $script (keys %hash) {

                    if ($client->ivExists('initScriptHash', $script)) {

                        # Replace the entry (the script's position in ->initScriptOrderList remains
                        #   unchanged)
                        $client->ivAdd('initScriptHash', $script, $hash{$script});

                    } else {

                        # Add a new entry
                        $client->ivAdd('initScriptHash', $script, $hash{$script});
                        $client->ivPush('initScriptOrderList', $script);
                    }
                }

                # The data in memory doesn't match saved data files
                $self->set_modifyFlag(TRUE, $self->_objClass . '->extractData');
            }

        } elsif ($self->fileType eq 'contacts') {

            # 'contacts'
            #   (T) All existing data in memory replaced by loaded data
            #   (F) Loaded data incorporated into memory

            if ($overWriteFlag) {

                # Replace the data in memory
                $client->ivPoke('chatName', $loadHash{'chat_name'});
                $client->ivPoke('chatEmail', $loadHash{'chat_email'});
                $client->ivPoke('chatAcceptMode', $loadHash{'chat_accept_mode'});
                $client->ivPoke('chatContactHash', %{$loadHash{'chat_contact_hash'}});
                $client->ivPoke('chatIcon', $loadHash{'chat_icon'});
                $client->ivPoke('chatSmileyHash', %{$loadHash{'chat_smiley_hash'}});

                # The data in memory matches saved data files
                $self->set_modifyFlag(FALSE, $self->_objClass . '->extractData');

            } else {

                # (Should not be able to import a partial 'contacts' file, since
                #   $self->exportDataFile doesn't create one)
                return undef;
            }

        } elsif ($self->fileType eq 'keycodes') {

            # 'keycodes'
            #   (T) All existing data in memory replaced by loaded data
            #   (F) Loaded data incorporated into memory

            if ($overWriteFlag) {

                # Replace the data in memory
                $client->ivPoke('keycodeObjHash', %{$loadHash{'keycode_obj_hash'}});
                $client->ivPoke('currentKeycodeObj', $loadHash{'current_keycode_obj'});

                # The data in memory matches saved data files
                $self->set_modifyFlag(FALSE, $self->_objClass . '->extractData');

            } else {

                # We are loading one or more global keycodes objects that have been exported and
                #   must be re-incorporated into memory

                # Incorporate keycode objects
                %hash = %{$loadHash{'keycode_obj_hash'}};
                if (%hash) {

                    foreach my $keycodeObj (values %hash) {

                        $client->add_keycodeObj($keycodeObj);
                    }
                }

                # (Calls to accessors will have set the right ->modifyFlag values)
            }

        } elsif ($self->fileType eq 'dicts') {

            # (T) Any current dictionaries in use by a session are retained, if a dictionary with
            #       the same name doesn't exist in the loaded file, but dictionaries not in use are
            #       replaced. Otherwise, all dictionaries are replaced
            # (F) If one of the loaded dictionaries has the same name as a current dictionary in use
            #       by any session, that current dictionary is replaced. Otherwise, all dictionaries
            #       are incorporated

            my %dictHash;

            if ($overWriteFlag) {

                # Get a hash of dictionaries in use by all sessions
                foreach my $otherSession ($axmud::CLIENT->listSessions()) {

                    my $dictObj = $otherSession->currentDict;

                    $dictHash{$dictObj->name} = $dictObj;
                }

                # Replace the dictionary registry...
                $client->ivPoke('dictHash', %{$loadHash{'dict_hash'}});
                # (So far, the data in memory matches saved data files)
                $self->set_modifyFlag(FALSE, $self->_objClass . '->extractData');
                # ...but retain any current dictionaries which don't appear in it
                foreach my $dictObj (values %dictHash) {

                    if (! $client->ivExists('dictHash', $dictObj->name)) {

                        $client->add_dict($dictObj);    # Updates ->modifyFlag
                    }
                }

                # Update the current dictionary object stored by every session
                foreach my $otherSession ($client->listSessions()) {

                    my ($currentObj, $loadObj);

                    $currentObj = $otherSession->currentDict;
                    $loadObj = $client->ivShow('dictHash', $currentObj->name);

                    if ($currentObj ne $loadObj) {

                        $otherSession->set_currentDict($loadObj);
                    }
                }

            } else {

                # Incorporate dictionaries
                %dictHash = %{$loadHash{'dict_hash'}};
                if (%dictHash) {

                    foreach my $dictObj (values %dictHash) {

                        $client->add_dict($dictObj);
                    }
                }

                # Update the current dictionary object stored by every session
                foreach my $otherSession ($client->listSessions()) {

                    my ($currentObj, $loadObj);

                    $currentObj = $otherSession->currentDict;
                    $loadObj = $client->ivShow('dictHash', $currentObj->name);

                    if ($currentObj ne $loadObj) {

                        $otherSession->set_currentDict($loadObj);
                    }
                }

                # (Calls to accessors will have set the right ->modifyFlag values)
            }

        } elsif ($self->fileType eq 'toolbar') {

            # 'toolbar'
            #   The entire list of toolbar buttons in memory is replaced by the loaded one,
            #       regardless of the flag

            $axmud::CLIENT->ivPoke('toolbarHash', %{$loadHash{'toolbar_hash'}});
            $axmud::CLIENT->ivPoke('toolbarList', @{$loadHash{'toolbar_list'}});

            if ($overWriteFlag) {

                # The data in memory matches saved data files
                $self->set_modifyFlag(FALSE, $self->_objClass . '->extractData');

            } else {

                # The data in memory doesn't match saved data files
                $self->set_modifyFlag(TRUE, $self->_objClass . '->extractData');
            }

            # Redraw toolbar buttons in all 'internal' windows
            foreach my $winObj ($axmud::CLIENT->desktopObj->ivValues('gridWinHash')) {

                my $stripObj;

                if (
                    $winObj->winType eq 'main'
                    || $winObj->winType eq 'protocol'
                    || $winObj->winType eq 'custom'
                ) {
                    $stripObj = $winObj->ivShow('firstStripHash', 'Games::Axmud::Strip::Toolbar');
                    if ($stripObj) {

                        $stripObj->resetToolbar();
                    }
                }
            }

        } elsif ($self->fileType eq 'usercmds') {

            # 'usercmds'
            #   (T) It's quite common for new commands to be added in newer versions of Axmud.
            #       Any user commands corresponding to client commands that didn't exist before
            #       are retained, but all other user commands are replaced
            #   (F) (This function should not be called)

            my (
                $modFlag,
                %standardHash, %currentHash, %newLoadHash, %loadStandardHash,
            );

            if ($overWriteFlag) {

                %hash = %{$loadHash{'user_cmd_hash'}};

                # Import this Axmud version's client command and user command hashes for quick
                #   lookup
                %standardHash = $client->clientCmdHash;
                %currentHash = $client->userCmdHash;

                # From the loaded hash of user commands, filter out any which relate to (standard)
                #   client commands which aren't being used by this version of Axmud
                foreach my $userCmd (keys %hash) {

                    my $standardCmd = $hash{$userCmd};

                    if (exists $standardHash{$userCmd}) {

                        $newLoadHash{$userCmd} = $standardCmd;
                        # Also build a hash of all the standard commands used in the loaded file
                        $loadStandardHash{$standardCmd} = undef;

                    } else {

                        # At least one command filtered out, so the data in memory won't match the
                        #   data file
                        $modFlag = TRUE;
                    }
                }

                # From the current hash of user commands, retain any user commands which correspond
                #   to (standard) client commands not used in the loaded file
                foreach my $userCmd (keys %currentHash) {

                    my $standardCmd = $currentHash{$userCmd};

                    if (! exists $loadStandardHash{$standardCmd}) {

                        # Retain this command
                        $newLoadHash{$userCmd} = $standardCmd;
                        # At least one command retained, so the data in memory won't match the data
                        #   file
                        $modFlag = TRUE;
                    }
                }

                # Replace the client's current list of user commands
                $client->ivPoke('userCmdHash', %newLoadHash);

                if ($modFlag) {
                    $self->set_modifyFlag(TRUE, $self->_objClass . '->extractData');
                } else {
                    $self->set_modifyFlag(FALSE, $self->_objClass . '->extractData');
                }

            } else {

                # (Should not be able to import a partial 'usercmds' file, since
                #   $self->exportDataFile doesn't create one)
                return undef;
            }

        } elsif ($self->fileType eq 'zonemaps') {

            # (T) All zonemaps in memory are replaced. The workspace grids used by all sessions are
            #   reset (when they exist). Any workspaces using a default zonemap which no longer
            #   exists are given a new default zonemap. Any workspace grids using a zonemap which no
            #   longer exists are reset to use the workspace's default zonemap
            # (F) Loaded data incorporated into memory. Any workspace grids using a loaded zonemap
            #   are reset

            if ($overWriteFlag) {

                # Replace the data in memory
                $client->ivPoke('zonemapHash', %{$loadHash{'zonemap_hash'}});
                $client->ivPoke('standardZonemapHash', %{$loadHash{'standard_zonemap_hash'}});

                # Check that the default zonemap for all workspaces still exists and, if not,
                #   replace it with a standard one
                foreach my $workspaceObj ($axmud::CLIENT->desktopObj->ivValues('workspaceHash')) {

                    if (
                        $workspaceObj->defaultZonemap
                        && ! $axmud::CLIENT->ivExists('zonemapHash', $workspaceObj->defaultZonemap)
                    ) {
                        if ($axmud::CLIENT->shareMainWinFlag) {
                            $workspaceObj->set_defaultZonemap('basic');
                        } else {
                            $workspaceObj->set_defaultZonemap('single');
                        }
                    }

                    # Reset all workspace grids, changing the zonemap used by any workspace grid
                    #   when that zonemap no longer exists
                    foreach my $gridObj ($workspaceObj->ivValues('gridHash')) {

                        my ($obj, $defaultObj);

                        $obj = $axmud::CLIENT->ivShow('zonemapHash', $gridObj->zonemap);
                        if (! $obj) {

                            $defaultObj = $axmud::CLIENT->ivShow(
                                'zonemapHash',
                                $workspaceObj->defaultZonemap,
                            );


                            $gridObj->applyZonemap($defaultObj);
                        }
                    }
                }

                # The data in memory matches saved data files
                $self->set_modifyFlag(FALSE, $self->_objClass . '->extractData');

            } else {

                # We are loading one or more global zonemap objects that have been exported and
                #   must be re-incorporated into memory

                # Incorporate zonemap objects
                %hash = %{$loadHash{'zonemap_hash'}};
                if (%hash) {

                    foreach my $zonemapObj (values %hash) {

                        $client->add_zonemap($zonemapObj);
                    }
                }

                # Any workspace grids using one of the incorporated zonemaps must be reset
                foreach my $gridObj ($axmud::CLIENT->desktopObj->ivValues('gridHash')) {

                    if ($gridObj->zonemap && exists $hash{$gridObj->zonemap}) {

                        $gridObj->applyZonemap(
                            $axmud::CLIENT->ivShow('zonemapHash', $gridObj->zonemap),
                        );
                    }
                }

                # (Calls to accessors will have set the right ->modifyFlag values)
            }

        } elsif ($self->fileType eq 'winmaps') {

                # (T) All winmaps/colour schemes in memory are replaced; no existing windows are
                #       affected, since winmaps are only applied when a window is created, and
                #       colour schemes are only applied periodically
                # (F) Loaded data incorporated into memory

            if ($overWriteFlag) {

                # Replace the data in memory
                $client->ivPoke('winmapHash', %{$loadHash{'winmap_hash'}});
                $client->ivPoke('standardWinmapHash', %{$loadHash{'standard_winmap_hash'}});
                $client->ivPoke('defaultEnabledWinmap', $loadHash{'default_enabled_winmap'});
                $client->ivPoke('defaultDisabledWinmap', $loadHash{'default_disabled_winmap'});
                $client->ivPoke('defaultInternalWinmap', $loadHash{'default_internal_winmap'});
                $client->ivPoke('colourSchemeHash', %{$loadHash{'colour_scheme_hash'}});

                # The data in memory matches saved data files
                $self->set_modifyFlag(FALSE, $self->_objClass . '->extractData');

            } else {

                # We are loading one or more global winmap objects that have been exported and
                #   must be re-incorporated into memory

                # Incorporate winmap objects
                %hash = %{$loadHash{'winmap_hash'}};
                if (%hash) {

                    foreach my $winmapObj (values %hash) {

                        $client->add_winmap($winmapObj);
                    }
                }

                # Incorporate colour schemes
                %hash = %{$loadHash{'colour_scheme_hash'}};
                if (%hash) {

                    foreach my $obj (values %hash) {

                        $client->add_colourScheme($obj);
                    }
                }

                # (Calls to accessors will have set the right ->modifyFlag values)
            }

        } elsif ($self->fileType eq 'tts') {

            # 'tts'
            #   (T) All existing data in memory replaced by loaded data
            #   (F) Loaded data incorporated into memory

            if ($overWriteFlag) {

                # Replace the data in memory
                $client->ivPoke('ttsObjHash', %{$loadHash{'tts_obj_hash'}});

                # The data in memory matches saved data files
                $self->set_modifyFlag(FALSE, $self->_objClass . '->extractData');

            } else {

                # We are loading one or more global TTS objects that have been exported and
                #   must be re-incorporated into memory

                # Incorporate TTS objects
                %hash = %{$loadHash{'tts_obj_hash'}};
                if (%hash) {

                    foreach my $ttsObj (values %hash) {

                        $client->add_ttsObj($ttsObj);
                    }
                }

                # (Calls to accessors will have set the right ->modifyFlag values)
            }
        }

        # Update the loaded data from previous versions of Axmud to conform to the current version
        #   of Axmud
        $self->updateExtractedData();

        # Return the file type
        return $loadHash{'file_type'};
    }

    sub updateExtractedData {

        # Called by $self->extractData (also called by GA::Profile::World->mergeData at the end of
        #   an ';updateworld' operation)
        # Data loaded from previous versions of Axmud may be incompatible with the present version.
        #   Update the loaded data, as and where necessary
        # NB Some data is also updated by $self->updateDataAfterRename
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $version    - When called by $self->extractData, the extracted data belongs to the Axmud
        #                   version stored in $self->scriptConvertVersion, and this argument is
        #                   'undef'. When called by GA::Profile::World->mergeData, this argument is
        #                   set to the Axmud version of the imported data's file (in the same
        #                   format)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $version, $check) = @_;

        # Local variables
        my $wmObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateExtractedData', @_);
        }

        if (! defined $version) {

            # This function called by $self->extractData
            $version = $self->scriptConvertVersion;
        }

        ### worldprof / otherprof #################################################################

        if ($self->fileType eq 'worldprof' || $self->fileType eq 'otherprof') {

            if ($version < 1_000_029 && $self->session) {

                # Update every command cage with new standard commands
                foreach my $cage ($self->session->ivValues('cageHash')) {

                    if ($cage->{cageType} eq 'cmd') {

                        if (! $cage->ivExists('cmdHash', 'short_look')) {

                            $cage->ivAdd('cmdHash', 'short_look', 'l');
                        }

                        if (! $cage->ivExists('cmdHash', 'short_glance')) {

                            $cage->ivAdd('cmdHash', 'short_glance', 'gl');
                        }
                    }
                }
            }

            if ($version < 1_000_039) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{excessCmdDelay}) {

                        # Create the IV...
                        $profObj->{excessCmdDelay} = undef;
                        # By setting its default value using ->ivPoke, we make sure the correct
                        #   GA::Obj::File object's ->modifyFlag is set automatically
                        $profObj->ivPoke('excessCmdDelay', 1);
                    }
                }
            }

            if ($version < 1_000_044) {

                # Update room statement components with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    foreach my $compObj ($profObj->ivValues('componentHash')) {

                        if (! exists $compObj->{useTextColour}) {

                            $compObj->{useTextColour} = undef;
                            $compObj->ivUndef('useTextColour');
                            $compObj->{ignoreChars} = undef;
                            $compObj->ivPoke('ignoreChars', 0);
                        }
                    }
                }
            }

            if ($version < 1_000_066 && $self->session) {

                # This version fixes a problem in GA::Profile::Char->fightVictimStringHash and
                #   ->interactionVictimStringHash
                foreach my $profObj ($self->session->ivValues('profHash')) {

                    my $hashRef;

                    if ($profObj->{category} eq 'char') {

                        $hashRef = $profObj->{fightVictimStringHash};
                        if (%$hashRef) {

                            my (%oldHash, %newHash);

                            %oldHash = %$hashRef;
                            foreach my $key (keys %oldHash) {

                                my $value = $oldHash{$key};

                                # All keys must now be lower-case
                                $key = lc($key);
                                if (exists $newHash{$key}) {
                                    $newHash{$key} = $newHash{$key} + $value;
                                } else {
                                    $newHash{$key} = $value;
                                }
                            }

                            $profObj->ivPoke('fightVictimStringHash', %newHash);
                        }

                        $hashRef = $profObj->{interactionVictimStringHash};
                        if (%$hashRef) {

                            my (%oldHash, %newHash);

                            %oldHash = %$hashRef;
                            foreach my $key (keys %oldHash) {

                                my $value = $oldHash{$key};

                                # All keys must now be lower-case
                                $key = lc($key);
                                if (exists $newHash{$key}) {
                                    $newHash{$key} = $newHash{$key} + $value;
                                } else {
                                    $newHash{$key} = $value;
                                }
                            }

                            $profObj->ivPoke('interactionVictimStringHash', %newHash);
                        }
                    }
                }
            }

            if ($version < 1_000_076) {

                # Update room statement components with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    foreach my $compObj ($profObj->ivValues('componentHash')) {

                        # Rename ->ignoreChars as ->ignoreFirstChars. For some reason, ->ignoreChars
                        #   seems to be set to 'undef' in components created in previous Axmud
                        #   versions; not sure why, but this code fixes it
                        if (! exists $compObj->{ignoreFirstChars}) {

                            $compObj->{ignoreFirstChars} = undef;

                            if (exists $compObj->{ignoreChars}) {
                                $compObj->ivPoke('ignoreFirstChars', $compObj->{ignoreChars});
                            } else {
                                $compObj->ivPoke('ignoreFirstChars', 0);
                            }
                        }

                        if (! defined $compObj->{ignoreFirstChars}) {

                            $compObj->ivPoke('ignoreFirstChars', $compObj->{ignoreChars});
                        }

                        delete $compObj->{ignoreChars};

                        $compObj->{useFirstChars} = undef;
                        $compObj->ivPoke('useFirstChars', 0);
                        $compObj->{usePatternBackRefs} = undef;
                        $compObj->ivUndef('usePatternBackRefs');
                    }
                }
            }

            if ($version < 1_000_077) {

                # Update world profiles with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{verboseFinalPattern}) {

                        $profObj->{verboseFinalPattern} = undef;
                        $profObj->ivUndef('verboseFinalPattern');
                        $profObj->{shortFinalPattern} = undef;
                        $profObj->ivUndef('shortFinalPattern');
                        $profObj->{briefFinalPattern} = undef;
                        $profObj->ivUndef('briefFinalPattern');
                    }
                }
            }

            if ($version < 1_000_090) {

                # This version updates the Status task, using a single string (e.g.
                #   'health_points_max') rather than two strings to represent the same thing (e.g.
                #   'health_max', 'health_points_max'. The Status task is updated below; here we
                #   updated a parallel IV in the world profile
                my %updateHash = (
                    '@health_max@'  => '@health_points_max@',
                    '@magic_max@'   => '@magic_points_max@',
                    '@energy_max@'  => '@energy_points_max@',
                    '@guild_max@'   => '@guild_points_max@',
                    '@social_max@'  => '@social_points_max@',
                );

                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    my $listRef = $profObj->{displayFormatList};
                    foreach my $line (@$listRef) {

                        foreach my $key (keys %updateHash) {

                            my $value = $updateHash{$key};

                            $line =~ s/$key/$value/g;
                        }
                    }
                }
            }

            if ($version < 1_000_150) {

                # Update world profiles with new stuff
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    my $listRef;

                    # New IV
                    if (! exists $profObj->{currencyRounding}) {

                        $profObj->{currencyRounding} = undef;
                        $profObj->ivPoke('currencyRounding', 3);
                    }

                    # In ->inventoryPatternList, the type 'empty' has been replaced by
                    #   'empty_purse', so update the list [in groups of 5)
                    $listRef = $profObj->{inventoryPatternList};
                    if (@$listRef) {

                        my (
                            $changeFlag,
                            @modList,
                        );

                        do {

                            my ($pattern, $backRef, $type, $gag, $posn);

                            $pattern = shift @$listRef;
                            $backRef = shift @$listRef;
                            $type = shift @$listRef;
                            $gag = shift @$listRef;
                            $posn = shift @$listRef;

                            if ($type eq 'empty') {

                                $type = 'empty_purse';
                                $changeFlag = TRUE;
                            }

                            push (@modList, $pattern, $backRef, $type, $gag, $posn);

                        } until (! @$listRef);

                        if ($changeFlag) {

                            $profObj->ivPoke('inventoryPatternList', @modList);
                        }
                    }
                }
            }

            if ($version < 1_000_159) {

                # This version changes the way a world profile's ->termType operates; it must now be
                #   one of the values in GA::Client->constTermTypeList (or 'undef')
                # Check every world profile; if its ->termType is set to a value that's not in
                #   ->constTermTypeList replace it with the first item ->constTermTypeList
                OUTER: foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    my ($listRef, $matchFlag);

                    if (defined $profObj->{termType}) {

                        $listRef = $axmud::CLIENT->{constTermTypeList};
                        INNER: foreach my $termType (@$listRef) {

                            if ($termType eq $profObj->{termType}) {

                                $matchFlag = TRUE;
                                last INNER;
                            }
                        }

                        if (! $matchFlag) {

                            # User has set an unrecognised termtype; replace it with 'ansi'
                            $profObj->ivPoke(
                                'termType',
                                $axmud::CLIENT->ivFirst('constTermTypeList'),
                            );
                        }
                    }

                    # Also rename an existing IV
                    if (exists $profObj->{sendTermInfoFlag}) {

                        $profObj->{sendSizeInfoFlag} = undef;
                        $profObj->ivPoke('sendSizeInfoFlag', $profObj->{sendTermInfoFlag});
                        delete $profObj->{sendTermInfoFlag};
                    }
                }
            }

            if ($version < 1_000_163) {

                # This version changes the default values of two IVs from 'undef' to 0
                OUTER: foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! defined $profObj->{columns}) {

                        $profObj->ivPoke('columns', 0);
                    }

                    if (! defined $profObj->{rows}) {

                        $profObj->ivPoke('rows', 0);
                    }
                }
            }

            if ($version < 1_000_165) {

                # Update world profiles with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{msspGenericValueHash}) {

                        $profObj->{msspGenericValueHash} = {};
                        $profObj->ivEmpty('msspGenericValueHash');
                        $profObj->{msspCustomValueHash} = {};
                        $profObj->ivEmpty('msspCustomValueHash');
                    }
                }
            }

            if ($version < 1_000_181 && $self->session) {

                # This version changes the name of two trigger attributes, and adds new ones. Update
                #   every trigger cage
                foreach my $cage ($self->session->ivValues('cageHash')) {

                    if ($cage->{cageType} eq 'trigger') {

                        foreach my $trigObj ($cage->ivValues('interfaceHash')) {

                            $trigObj->ivAdd(
                                'attribHash',
                                'style_text',
                                $trigObj->ivShow('attribHash', 'style_fg'),
                            );

                            $trigObj->ivDelete('attribHash', 'style_fg');

                            $trigObj->ivAdd(
                                'attribHash',
                                'style_underlay',
                                $trigObj->ivShow('attribHash', 'style_bg'),
                            );

                            $trigObj->ivDelete('attribHash', 'style_bg');

                            $trigObj->ivAdd('attribHash', 'style_blink_slow', 0);
                            $trigObj->ivAdd('attribHash', 'style_blink_fast', 0);
                        }
                    }
                }
            }

            if ($version < 1_000_186) {

                # Update world profiles with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{worldCharSet}) {

                        $profObj->{worldCharSet} = undef;
                        $profObj->ivUndef('worldCharSet');
                    }
                }
            }

            if ($version < 1_000_188) {

                # Update world profiles with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{exitRemovePatternList}) {

                        $profObj->{exitRemovePatternList} = [];
                        $profObj->ivEmpty('exitRemovePatternList');
                    }
                }
            }

            if ($version < 1_000_189) {

                # Update world profiles with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{exitStateIgnoreList}) {

                        $profObj->{exitStateIgnoreList} = [];
                        $profObj->ivEmpty('exitStateIgnoreList');
                    }
                }
            }

            if ($version < 1_000_198) {

                # Update world profiles with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    my $listRef;

                    if (! exists $profObj->{affectPatternList}) {

                        $profObj->{affectPatternList} = [];
                        $profObj->ivEmpty('affectPatternList');
                    }

                    # In ->barPatternList, the type 'xp' has been replaced by 'xp_current', so
                    #   update the list [in groups of 6)
                    $listRef = $profObj->{barPatternList};
                    if (@$listRef) {

                        my (
                            $changeFlag,
                            @modList,
                        );

                        do {

                            my ($pattern, $backRef, $type, $gag, $string, $posn);

                            $pattern = shift @$listRef;
                            $backRef = shift @$listRef;
                            $type = shift @$listRef;
                            $gag = shift @$listRef;
                            $string = shift @$listRef;
                            $posn = shift @$listRef;

                            if ($type eq 'xp') {

                                $type = 'xp_current';
                                $changeFlag = TRUE;
                            }

                            push (@modList, $pattern, $backRef, $type, $gag, $string, $posn);

                        } until (! @$listRef);

                        if ($changeFlag) {

                            $profObj->ivPoke('barPatternList', @modList);
                        }
                    }
                }

                if ($self->session) {

                    # Update character profiles with new IVs
                    foreach my $profObj ($self->session->ivValues('profHash')) {

                        if ($profObj->{category} eq 'char' && ! exists $profObj->{xpNextLevel}) {

                            $profObj->{xpNextLevel} = undef;
                            $profObj->ivUndef('xpNextLevel');
                            $profObj->{alignment} = undef;
                            $profObj->ivUndef('alignment');
                            $profObj->{affectHash} = {};
                            $profObj->ivEmpty('affectHash');
                        }
                    }
                }
            }

            if ($version < 1_000_206) {

                # Update room statement components with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    foreach my $compObj ($profObj->ivValues('componentHash')) {

                        if (! exists $compObj->{analyseMode}) {

                            $compObj->{analyseMode} = undef;
                            $compObj->ivPoke('analyseMode', 0);
                        }
                    }
                }
            }

            if ($version < 1_000_210 && $self->session) {

                # Update every command cage with a new standard command
                foreach my $cage ($self->session->ivValues('cageHash')) {

                    if ($cage->{cageType} eq 'cmd') {

                        if (! $cage->ivExists('cmdHash', 'connect')) {

                            $cage->ivAdd('cmdHash', 'connect', 'connect name password');
                        }
                    }
                }
            }

            if ($version < 1_000_210) {

                # Update world profiles with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    my $listRef;

                    if (! exists $profObj->{loginConnectPatternList}) {

                        # One new IV
                        $profObj->{loginConnectPatternList} = [];
                        $profObj->ivEmpty('loginConnectPatternList');
                    }

                    if (exists $profObj->{loginPatternList}) {

                        # One renamed IV
                        $profObj->{loginSuccessPatternList} = [];
                        $listRef = $profObj->{loginPatternList};
                        $profObj->ivPoke('loginSuccessPatternList', @$listRef);
                        delete $profObj->{loginPatternList};
                    }
                }
            }

            if ($version < 1_000_212) {

                # Update world profiles with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{customStatusVarHash}) {

                        $profObj->{customStatusVarHash} = {};
                        $profObj->ivEmpty('customStatusVarHash');
                    }
                }
            }

            if ($version < 1_000_213) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{exitInfoPatternList}) {

                        $profObj->{exitInfoPatternList} = [];
                        $profObj->ivEmpty('exitInfoPatternList');
                    }
                }
            }

            if ($version < 1_000_220) {

                # Update world profiles with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{fightDefeatPatternList}) {

                        $profObj->{fightDefeatPatternList} = [];
                        $profObj->ivEmpty('fightDefeatPatternList');
                        $profObj->{wimpyEngagedPatternList} = [];
                        $profObj->ivEmpty('wimpyEngagedPatternList');
                        $profObj->{noFightDefeatPatternList} = [];
                        $profObj->ivEmpty('noFightDefeatPatternList');
                        $profObj->{noWimpyEngagedPatternList} = [];
                        $profObj->ivEmpty('noWimpyEngagedPatternList');
                    }
                }
            }

            if ($version < 1_000_228 && $self->session) {

                # This version adds a new trigger attribute. Update every trigger cage
                foreach my $cage ($self->session->ivValues('cageHash')) {

                    if ($cage->{cageType} eq 'trigger') {

                        foreach my $trigObj ($cage->ivValues('interfaceHash')) {

                            $trigObj->ivAdd('attribHash', 'rewrite_global', 0);
                        }
                    }
                }
            }

            if ($version < 1_000_239 && $self->session) {

                # This version adds a new trigger attribute. Update every trigger cage
                foreach my $cage ($self->session->ivValues('cageHash')) {

                    if ($cage->{cageType} eq 'trigger') {

                        foreach my $trigObj ($cage->ivValues('interfaceHash')) {

                            $trigObj->ivAdd('attribHash', 'need_login', 0);
                        }
                    }
                }
            }

            if ($version < 1_000_252) {

                # Update world profiles with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{strictPromptsMode}) {

                        $profObj->{strictPromptsMode} = undef;
                        $profObj->ivPoke('strictPromptsMode', FALSE);
                    }
                }
            }

            if ($version < 1_000_297 && $self->session) {

                # Update every command cage with new standard commands
                foreach my $cage ($self->session->ivValues('cageHash')) {

                    if ($cage->{cageType} eq 'cmd') {

                        if (! $cage->ivExists('cmdHash', 'squeeze')) {

                            $cage->ivAdd('cmdHash', 'squeeze', 'squeeze direction');
                        }
                    }
                }
            }

            if ($version < 1_000_300) {

                # Update world profiles with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{exitStateDarkList}) {

                        $profObj->{exitStateDarkList} = [];
                        $profObj->ivEmpty('exitStateDarkList');
                        $profObj->{exitStateDangerList} = [];
                        $profObj->ivEmpty('exitStateDangerList');
                    }
                }
            }

            if ($version < 1_000_301) {

                # Update world profiles with a new hash IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{accountHash}) {

                        # Create the IV
                        $profObj->{accountHash} = {};
                        $profObj->ivEmpty('accountHash');

                        # The IV should have the same keys as the existing ->passwordHash IV, but
                        #   the matching values should all be 'undef'
                        foreach my $key ($profObj->ivKeys('passwordHash')) {

                            $profObj->ivAdd('accountHash', $key, undef);
                        }
                    }
                }
            }

            if ($version < 1_000_302) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{newAccountHash}) {

                        # Create the IV
                        $profObj->{newAccountHash} = {};
                        $profObj->ivEmpty('newAccountHash');
                    }
                }
            }

            if ($version < 1_000_306) {

                # Update room statement components with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    foreach my $compObj ($profObj->ivValues('componentHash')) {

                        if (! exists $compObj->{startTagMode}) {

                            $compObj->{startTagMode} = undef;
                            $compObj->ivPoke('startTagMode', 0);
                            $compObj->{stopTagMode} = undef;
                            $compObj->ivPoke('stopTagMode', 0);
                            $compObj->{skipTagMode} = undef;
                            $compObj->ivPoke('skipTagMode', 0);
                            $compObj->{stopBeforeNoTagMode} = undef;
                            $compObj->ivPoke('stopBeforeNoTagMode', 0);
                            $compObj->{stopBeforeTagMode} = undef;
                            $compObj->ivPoke('stopBeforeTagMode', 0);
                            $compObj->{stopAtNoTagMode} = undef;
                            $compObj->ivPoke('stopAtNoTagMode', 0);
                            $compObj->{stopAtTagMode} = undef;
                            $compObj->ivPoke('stopAtTagMode', 0);
                        }
                    }
                }
            }

            if ($version < 1_000_315 && $self->session) {

                # This version adds new trigger attributes. Update every trigger cage
                foreach my $cage ($self->session->ivValues('cageHash')) {

                    if ($cage->{cageType} eq 'trigger') {

                        foreach my $trigObj ($cage->ivValues('interfaceHash')) {

                            $trigObj->ivAdd('attribHash', 'splitter', 0);
                            $trigObj->ivAdd('attribHash', 'split_after', 0);
                            $trigObj->ivAdd('attribHash', 'keep_splitting', 0);
                        }
                    }
                }
            }

            if ($version < 1_000_318) {

                # Update room statement components, adding some new IVs and removing some other
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    foreach my $compObj ($profObj->ivValues('componentHash')) {

                        my ($patternListRef, $tagListRef);

                        if (! exists $compObj->{startNoPatternList}) {

                            $compObj->{startNoPatternList} = [];
                            $compObj->ivEmpty('startNoPatternList');
                            $compObj->{startNoTagList} = [];
                            $compObj->ivEmpty('startNoTagList');
                            $compObj->{startNoAllFlag} = undef;
                            $compObj->ivPoke('startNoAllFlag', FALSE);
                            $compObj->{startNoTagMode} = undef;
                            $compObj->ivPoke('startNoTagMode', 0);

                            # The existing contents of ->stopPatternList (etc) must be transferred
                            #   to ->stopAtPatternList, without duplicating anything
                            $patternListRef = $compObj->{stopPatternList};
                            OUTER: foreach my $item (@$patternListRef) {

                                my ($stopListRef, $matchFlag);

                                $stopListRef = $compObj->{stopAtPatternList};
                                INNER: foreach my $other (@$stopListRef) {

                                    if ($other eq $item) {

                                        $matchFlag = TRUE;
                                        last INNER;
                                    }
                                }

                                if (! $matchFlag) {

                                    $compObj->ivPush('stopAtPatternList', $item);
                                }
                            }

                            $tagListRef = $compObj->{stopTagList};
                            OUTER: foreach my $item (@$tagListRef) {

                                my ($stopListRef, $matchFlag);

                                $stopListRef = $compObj->{stopAtTagList};
                                INNER: foreach my $other (@$stopListRef) {

                                    if ($other eq $item) {

                                        $matchFlag = TRUE;
                                        last INNER;
                                    }
                                }

                                if (! $matchFlag) {

                                    $compObj->ivPush('stopAtTagList', $item);
                                }
                            }

                            # (We'll assume that ->stopAllFlag and ->stopTagMode should override
                            #   the existing settings of ->stopAtAllFlag and ->stopAtTagMode,
                            #   since ->stop... was formerly more important thatn ->stopAt...)
                            if ($compObj->{stopAllFlag}) {

                                $compObj->ivPoke('stopAtAllFlag', TRUE);
                            }

                            if ($compObj->{stopTagMode}) {

                                $compObj->ivPoke('stopAtTagMode', $compObj->{stopTagMode});
                            }

                            # We can now remove the old IVs
                            delete $compObj->{stopPatternList};
                            delete $compObj->{stopTagList};
                            delete $compObj->{stopAllFlag};
                            delete $compObj->{stopTagMode};
                        }
                    }
                }
            }

            if ($version < 1_000_320) {

                # Update room statement components with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    foreach my $compObj ($profObj->ivValues('componentHash')) {

                        if (! exists $compObj->{useAppliedTagsFlag}) {

                            $compObj->{useAppliedTagsFlag} = undef;
                            $compObj->ivPoke('useAppliedTagsFlag', FALSE);
                        }
                    }
                }
            }

            if ($version < 1_000_324) {

                # Update room statement components with a new IV, which replaces an old one, but
                #   reverses its setting
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    foreach my $compObj ($profObj->ivValues('componentHash')) {

                        if (exists $compObj->{boldInsensitiveFlag}) {

                            $compObj->{boldSensitiveFlag} = undef;
                            if ($compObj->{boldInsensitiveFlag}) {
                                $compObj->ivPoke('boldSensitiveFlag', FALSE);
                            } else {
                                $compObj->ivPoke('boldSensitiveFlag', TRUE);
                            }

                            delete $compObj->{boldInsensitiveFlag};
                        }
                    }
                }
            }

            if ($version < 1_000_330) {

                # This version replaces several IVs (->exitStateOpenList, ->exitStateClosedList,
                #   etc) with a single list IV, in groups of 4

                my %stateHash = (
                    'exitStateOpenList'     => 'open',
                    'exitStateClosedList'   => 'closed',
                    'exitStateLockedList'   => 'locked',
                    'exitStateImpassList'   => 'impass',
                    'exitStateDarkList'     => 'dark',
                    'exitStateDangerList'   => 'danger',
                    'exitStateOtherList'    => 'other',
                    'exitStateIgnoreList'   => 'ignore',
                );

                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    my @newList;

                    if (! exists $profObj->{exitStateStringList}) {

                        foreach my $iv (keys %stateHash) {

                            my ($state, $listRef, $start, $middle, $end, $flag);

                            $state = $stateHash{$iv};
                            $listRef = $profObj->{$iv};

                            if (@$listRef) {

                                ($start, $end, $flag) = @$listRef;
                                # ()       - There are no strings for this exit state
                                # ('')     - There are no strings for this exit state
                                # ('', '') - There are no strings for this exit state
                                if ($start || $end) {

                                    # (string1) - String(s) appear at the beginning of the exit
                                    if ($start && ! $end) {

                                        push (@newList, $state, $start, '', '');

                                    # ('', string2) - String(s) appear at the end of the exit
                                    } elsif (! $start && $end) {

                                        if ($flag) {
                                            push (@newList, $state, '', $end, '');
                                        } else {
                                            push (@newList, $state, '', '', $end);
                                        }

                                    # (string1, string2)
                                    #   - String(s) appear at the beginning and end
                                    # (string1, string2, TRUE)
                                    #   - String(s) appear at the beginning and middle
                                    } else {

                                        if ($flag) {
                                            push (@newList, $state, $start, $end, '');
                                        } else {
                                            push (@newList, $state, $start, '', $end);
                                        }
                                    }
                                }
                            }
                        }

                        # Create the new combined list IV
                        $profObj->{exitStateStringList} = [];
                        $profObj->ivPoke('exitStateStringList', @newList);
                        # And delete the old ones
                        delete $profObj->{exitStateOpenList};
                        delete $profObj->{exitStateClosedList};
                        delete $profObj->{exitStateLockedList};
                        delete $profObj->{exitStateImpassList};
                        delete $profObj->{exitStateDarkList};
                        delete $profObj->{exitStateDangerList};
                        delete $profObj->{exitStateOtherList};
                        delete $profObj->{exitStateIgnoreList};
                    }
                }
            }

            if ($version < 1_000_467 && $self->session) {

                # Update every command cage with new standard commands
                foreach my $cage ($self->session->ivValues('cageHash')) {

                    if ($cage->{cageType} eq 'cmd') {

                        if (! $cage->ivExists('cmdHash', 'teleport')) {

                            $cage->ivAdd('cmdHash', 'teleport', 'teleport room');
                        }
                    }
                }
            }

            if ($version < 1_000_482 && $self->session) {

                # Update world profiles for new character life statuses
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if ($profObj->ivExists('logPrefHash', 'asleep')) {

                        $profObj->ivAdd(
                            'logPrefHash',
                            'sleep',
                            $profObj->ivShow('logPrefHash', 'asleep'),
                        );

                        $profObj->ivDelete('logPrefHash', 'asleep');
                    }

                    if ($profObj->ivExists('logPrefHash', 'passed_out')) {

                        $profObj->ivAdd(
                            'logPrefHash',
                            'passout',
                            $profObj->ivShow('logPrefHash', 'passed_out'),
                        );

                        $profObj->ivDelete('logPrefHash', 'passed_out');
                    }
                }

                # Update character profiles in the same way
                if ($self->session) {

                    # Update character profiles with new IVs
                    foreach my $profObj ($self->session->ivValues('profHash')) {

                        if ($profObj->{category} eq 'char') {

                            if ($profObj->{lifeStatus} eq 'asleep') {
                                $profObj->ivPoke('lifeStatus', 'sleep');
                            } elsif ($profObj->{lifeStatus} eq 'passed_out') {
                                $profObj->ivPoke('lifeStatus', 'passout');
                            }
                        }
                    }
                }
            }


            if ($version < 1_000_512) {

                # Update room statement components with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    foreach my $compObj ($profObj->ivValues('componentHash')) {

                        if (! exists $compObj->{noExtractList}) {

                            $compObj->{noExtractList} = [];
                            $compObj->ivEmpty('noExtractList');
                        }
                    }
                }
            }

            if ($version < 1_000_515) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{exitAliasHash}) {

                        $profObj->{exitAliasHash} = {};
                        $profObj->ivEmpty('exitAliasHash');
                    }
                }
            }

            if ($version < 1_000_517) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{basicMappingMode}) {

                        $profObj->{basicMappingMode} = undef;
                        $profObj->ivPoke('basicMappingMode', 0);
                    }
                }
            }

            if ($version < 1_000_524) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{notAnchorPatternList}) {

                        $profObj->{notAnchorPatternList} = [];
                        $profObj->ivEmpty('notAnchorPatternList');
                    }
                }
            }

            if ($version < 1_000_526) {

                # Update world profiles with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{verboseExitSplitCharFlag}) {

                        $profObj->{verboseExitSplitCharFlag} = undef;
                        $profObj->ivPoke('verboseExitSplitCharFlag', FALSE);
                        $profObj->{briefExitSplitCharFlag} = undef;
                        $profObj->ivPoke('briefExitSplitCharFlag', FALSE);
                    }
                }
            }

            if ($version < 1_000_530) {

                # Update room statement components with an IV whose name has been changed, and a
                #   new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    foreach my $compObj ($profObj->ivValues('componentHash')) {

                        if (! exists $compObj->{useInitialTagsFlag}) {

                            $compObj->{useInitialTagsFlag} = undef;
                            $compObj->ivPoke('useInitialTagsFlag', $compObj->{useAppliedTagsFlag});
                            delete $compObj->{useAppliedTagsFlag};
                        }

                        if (! exists $compObj->{useExplicitTagsFlag}) {

                            $compObj->{useExplicitTagsFlag} = undef;
                            $compObj->ivPoke('useExplicitTagsFlag', FALSE);
                        }
                    }
                }
            }

            if ($version < 1_000_537) {

                # Update world profiles with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{loginAccountMode}) {

                        $profObj->{loginAccountMode} = undef;
                        $profObj->ivPoke('loginAccountMode', 0);
                    }
                }
            }

            if ($version < 1_000_538) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{loginSpecialList}) {

                        $profObj->{loginSpecialList} = [];
                        $profObj->ivEmpty('loginSpecialList');
                    }
                }
            }

            if ($version < 1_000_541) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{worldWarning}) {

                        $profObj->{worldWarning} = undef;
                        $profObj->ivUndef('worldWarning');
                    }
                }
            }

            if ($version < 1_000_542) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{statOrderList}) {

                        $profObj->{statOrderList} = [];
                        $profObj->ivEmpty('statOrderList');
                    }
                }
            }

            if ($version < 1_000_544) {

                # Update world profiles with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{autoQuitMode}) {

                        $profObj->{autoQuitMode} = undef;
                        $profObj->ivUndef('autoQuitMode');
                        $profObj->{autoQuitCmdList} = [];
                        $profObj->ivEmpty('autoQuitCmdList');
                        $profObj->{autoQuitObjName} = undef;
                        $profObj->ivUndef('autoQuitObjName');
                    }
                }
            }

            if ($version < 1_000_576) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{collectContentsFlag}) {

                        $profObj->{collectContentsFlag} = undef;
                        $profObj->ivPoke('collectContentsFlag', TRUE);
                    }
                }
            }

            if ($version < 1_000_577) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{multiplePattern}) {

                        $profObj->{multiplePattern} = undef;
                        $profObj->ivUndef('multiplePattern');
                    }
                }
            }

            if ($version < 1_000_578) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{followPatternList}) {

                        $profObj->{followPatternList} = [];
                        $profObj->ivEmpty('followPatternList');
                    }
                }
            }

            if ($version < 1_000_622) {

                # Update all profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{notepadList}) {

                        $profObj->{notepadList} = [];
                        $profObj->ivEmpty('notepadList');
                    }
                }

                if ($self->session) {

                    foreach my $profObj ($self->session->ivValues('profHash')) {

                        if ($profObj->{category} ne 'world' && ! exists $profObj->{notepadList}) {

                            $profObj->{notepadList} = [];
                            $profObj->ivEmpty('notepadList');
                        }
                    }

                    foreach my $templateObj ($self->session->ivValues('templateHash')) {

                        if (! $templateObj->ivExists('_standardHash', 'notepadList')) {

                            # (Because this IV starts with an underline, have to set it directly)
                            $templateObj->{'_standardHash'}{'notepadList'} = undef;
                        }
                    }
                }
            }

            if ($version < 1_000_688) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{gaugeFormatList}) {

                        $profObj->{gaugeFormatList} = [];
                        $profObj->ivPoke(
                            'gaugeFormatList',
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
                        );
                    }
                }
            }

            if ($version < 1_000_800 && $self->session) {

                # This version adds some trigger attributes. Update every trigger cage
                foreach my $cage ($self->session->ivValues('cageHash')) {

                    if ($cage->{cageType} eq 'trigger') {

                        foreach my $trigObj ($cage->ivValues('interfaceHash')) {

                            $trigObj->ivAdd('attribHash', 'default_pane', TRUE);
                            $trigObj->ivAdd('attribHash', 'pane_name', '');
                        }
                    }
                }
            }

            if ($version < 1_000_808) {

                # Update world profiles' stored mission objects
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    foreach my $missionObj ($profObj->ivValues('missionHash')) {

                        if (! exists $missionObj->{quietFlag}) {

                            $missionObj->{quietFlag} = undef;
                            $missionObj->ivPoke('quietFlag', FALSE);

                            # IVs used to store temporary values while a mission was running have
                            #   not, until now, been reset properly
                            $missionObj->resetMission();
                        }
                     }
                }
            }

            if ($version < 1_000_851) {

                my $regex = $axmud::SCRIPT . '\:\:';

                # Update world profiles' stored mission objects, whose ->triggerName and
                #   ->timerName IVs were set wrong, which caused save file operations to fail
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    foreach my $missionObj ($profObj->ivValues('missionHash')) {

                        if (ref($missionObj->{triggerName}) =~ m/$regex/) {

                            $missionObj->ivPoke('triggerName', $missionObj->{triggerName}->{name});
                        }

                        if (ref($missionObj->{timerName}) =~ m/$regex/) {

                            $missionObj->ivPoke('timerName', $missionObj->{timerName}->{name});
                        }
                     }
                }
            }

            if ($version < 1_000_852) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{adultFlag}) {

                        $profObj->{adultFlag} = undef;
                        $profObj->ivPoke('adultFlag', TRUE);
                    }
                }
            }

            if ($version < 1_000_877) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{inventoryDiscardPatternList}) {

                        $profObj->{inventoryDiscardPatternList} = [];
                        $profObj->ivEmpty('inventoryDiscardPatternList');
                    }
                }
            }

            if ($version < 1_000_879) {

                # Update world profiles with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{telnetOverrideHash}) {

                        $profObj->{telnetOverrideHash} = {};
                        $profObj->ivEmpty('telnetOverrideHash');
                        $profObj->{termOverrideHash} = {};
                        $profObj->ivEmpty('termOverrideHash');

                        # One or two worlds must forbid certain protocols by default
                        if ($profObj->name eq 'kallisti') {

                            $profObj->ivAdd('telnetOverrideHash', 'msdp', undef);
                        }
                    }
                }
            }

            if ($version < 1_000_880) {

                # Rename a world profile IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{worldHint}) {

                        $profObj->{worldHint} = undef;
                        $profObj->ivPoke('worldHint', $profObj->{worldWarning});
                        delete $profObj->{worldWarning};
                    }
                }
            }

            if ($version < 1_000_881) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{sigilOverrideHash}) {

                        $profObj->{sigilOverrideHash} = {};
                        $profObj->ivEmpty('sigilOverrideHash');
                    }
                }
            }

            if ($version < 1_000_885) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{connectHistoryList}) {

                        $profObj->{connectHistoryList} = [];
                        $profObj->ivEmpty('connectHistoryList');
                    }
                }
            }

            if ($version < 1_000_888) {

                # Update world profiles with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{mxpOverrideHash}) {

                        $profObj->{mxpOverrideHash} = {};
                        $profObj->ivEmpty('mxpOverrideHash');

                        # One or two worlds must turn off certain options by default
                        if ($profObj->name eq 'coffeemud') {

                            $profObj->ivAdd('mxpOverrideHash', 'room', FALSE);
                        }
                    }
                }
            }

            if ($version < 1_000_896) {

                # Update world profiles with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{verboseAnchorCheckList}) {

                        $profObj->{verboseAnchorCheckList} = [];
                        $profObj->ivEmpty('verboseAnchorCheckList');
                        $profObj->{shortAnchorCheckList} = [];
                        $profObj->ivEmpty('shortAnchorCheckList');
                        $profObj->{briefAnchorCheckList} = [];
                        $profObj->ivEmpty('briefAnchorCheckList');
                    }

                    if (! exists $profObj->{roomCmdDelimiterList}) {

                        $profObj->{roomCmdDelimiterList} = [];
                        $profObj->ivEmpty('roomCmdDelimiterList');
                        $profObj->{roomCmdNonDelimiterList} = [];
                        $profObj->ivEmpty('roomCmdNonDelimiterList');
                        $profObj->{roomCmdSplitCharFlag} = undef;
                        $profObj->ivPoke('roomCmdSplitCharFlag', FALSE);
                        $profObj->{roomCmdLeftMarkerList} = [];
                        $profObj->ivEmpty('roomCmdLeftMarkerList');
                        $profObj->{roomCmdRightMarkerList} = [];
                        $profObj->ivEmpty('roomCmdRightMarkerList');
                    }

                    # Also remove an IV, which has moved to GA::Client->constComponentTypeList
                    if (exists ($profObj->{_constComponentList})) {

                        delete $profObj->{_constComponentList};
                    }
                }
            }

            if ($version < 1_000_909) {

                my @profList;

                # This version converts some numerical mode values to string mode values

                push (@profList, $axmud::CLIENT->ivValues('worldProfHash'));
                if ($self->session) {

                    push (@profList, $self->session->ivValues('profHash'));
                }

                foreach my $profObj (@profList) {

                    my %initScriptHash = $profObj->initScriptHash;

                    foreach my $key (keys %initScriptHash) {

                        my $value = $initScriptHash{$key};

                        if ($value eq '0') {
                            $initScriptHash{$key} = 'no_task';
                        } elsif ($value eq '1') {
                            $initScriptHash{$key} = 'run_task';
                        } elsif ($value eq '2') {
                            $initScriptHash{$key} = 'run_task_win';
                        }
                    }

                    $profObj->ivPoke('initScriptHash', %initScriptHash);

                    if ($profObj->category eq 'world') {

                        if ($profObj->loginMode eq '0') {
                            $profObj->ivPoke('loginMode', 'none');
                        } elsif ($profObj->loginMode eq '1') {
                            $profObj->ivPoke('loginMode', 'immediate');
                        } elsif ($profObj->loginMode eq '2') {
                            $profObj->ivPoke('loginMode', 'lp');
                        } elsif ($profObj->loginMode eq '3') {
                            $profObj->ivPoke('loginMode', 'tiny');
                        } elsif ($profObj->loginMode eq '4') {
                            $profObj->ivPoke('loginMode', 'world_cmd');
                        } elsif ($profObj->loginMode eq '5') {
                            $profObj->ivPoke('loginMode', 'telnet');
                        } elsif ($profObj->loginMode eq '6') {
                            $profObj->ivPoke('loginMode', 'task');
                        } elsif ($profObj->loginMode eq '7') {
                            $profObj->ivPoke('loginMode', 'script_task');
                        } elsif ($profObj->loginMode eq '8') {
                            $profObj->ivPoke('loginMode', 'script');
                        } elsif ($profObj->loginMode eq '9') {
                            $profObj->ivPoke('loginMode', 'mission');
                        }

                        if ($profObj->loginAccountMode eq '0') {
                            $profObj->ivPoke('loginAccountMode', 'unknown');
                        } elsif ($profObj->loginAccountMode eq '1') {
                            $profObj->ivPoke('loginAccountMode', 'not_required');
                        } elsif ($profObj->loginAccountMode eq '2') {
                            $profObj->ivPoke('loginAccountMode', 'required');
                        }

                        if ($profObj->autoQuitMode eq '0') {
                            $profObj->ivPoke('autoQuitMode', 'normal');
                        } elsif ($profObj->autoQuitMode eq '1') {
                            $profObj->ivPoke('autoQuitMode', 'world_cmd');
                        } elsif ($profObj->autoQuitMode eq '2') {
                            $profObj->ivPoke('autoQuitMode', 'task');
                        } elsif ($profObj->autoQuitMode eq '3') {
                            $profObj->ivPoke('autoQuitMode', 'task_script');
                        } elsif ($profObj->autoQuitMode eq '4') {
                            $profObj->ivPoke('autoQuitMode', 'script');
                        } elsif ($profObj->autoQuitMode eq '5') {
                            $profObj->ivPoke('autoQuitMode', 'mission');
                        }

                        if ($profObj->inventoryMode eq '0') {
                            $profObj->ivPoke('inventoryMode', 'match_all');
                        } elsif ($profObj->inventoryMode eq '1') {
                            $profObj->ivPoke('inventoryMode', 'start_stop');
                        } elsif ($profObj->inventoryMode eq '2') {
                            $profObj->ivPoke('inventoryMode', 'start_empty');
                        }

                        if (! $profObj->basicMappingMode) {
                            $profObj->ivPoke('basicMappingMode', FALSE);
                        } else {
                            $profObj->ivPoke('basicMappingMode', TRUE);
                        }

                        foreach my $componentObj ($profObj->ivValues('componentHash')) {

                            foreach my $iv (
                                'startTagMode', 'startNoTagMode', 'skipTagMode',
                                'stopBeforeTagMode', 'stopBeforeNoTagMode', 'stopAtTagMode',
                                'stopAtNoTagMode',
                            ) {
                                if ($componentObj->$iv eq '0') {
                                    $componentObj->ivPoke($iv, 'default');
                                } elsif ($componentObj->$iv eq '1') {
                                    $componentObj->ivPoke($iv, 'no_colour');
                                } elsif ($componentObj->$iv eq '2') {
                                    $componentObj->ivPoke($iv, 'no_style');
                                } elsif ($componentObj->$iv eq '3') {
                                    $componentObj->ivPoke($iv, 'no_colour_style');
                                }
                            }

                            foreach my $iv ('stopBeforeMode', 'stopAtMode') {

                                if ($componentObj->$iv eq '0') {
                                    $componentObj->ivPoke($iv, 'default');
                                } elsif ($componentObj->$iv eq '1') {
                                    $componentObj->ivPoke($iv, 'no_char');
                                } elsif ($componentObj->$iv eq '2') {
                                    $componentObj->ivPoke($iv, 'no_letter_num');
                                } elsif ($componentObj->$iv eq '3') {
                                    $componentObj->ivPoke($iv, 'no_start_letter_num');
                                } elsif ($componentObj->$iv eq '4') {
                                    $componentObj->ivPoke($iv, 'no_tag');
                                } elsif ($componentObj->$iv eq '5') {
                                    $componentObj->ivPoke($iv, 'has_letter_num');
                                } elsif ($componentObj->$iv eq '6') {
                                    $componentObj->ivPoke($iv, 'has_start_letter_num');
                                } elsif ($componentObj->$iv eq '7') {
                                    $componentObj->ivPoke($iv, 'has_tag');
                                }
                            }
                        }
                    }
                }
            }

            if ($version < 1_000_915) {

                # Update world profiles with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{followAnchorPatternList}) {

                        $profObj->{followAnchorPatternList} = [];
                        $profObj->ivEmpty('followAnchorPatternList');
                    }
                }
            }

            if ($version < 1_000_921) {

                if ($self->session) {

                    # Remove IVs from profile templates and custom profiles
                    foreach my $templObj ($self->session->ivValues('templateHash')) {

                        if (exists $templObj->{_standardHash}) {

                            delete $templObj->{_standardHash};
                        }

                        if (exists $templObj->{_fixedFlag}) {

                            $templObj->{constFixedFlag} = $templObj->{_fixedFlag};
                            delete $templObj->{_fixedFlag};
                        }

                        # (This line makes sure the correct file object's ->modifyFlag is set)
                        $templObj->ivPoke('category', $templObj->category);
                    }

                    foreach my $profObj ($self->session->ivValues('profHash')) {

                        if (exists $profObj->{_standardHash}) {

                            delete $profObj->{_standardHash};

                            # (This line makes sure the correct file object's ->modifyFlag is set)
                            $profObj->ivPoke('category', $profObj->category);
                        }
                    }
                }
            }

            if ($version < 1_000_922) {

                # This version renames a world profile IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (exists $profObj->{_localWimpyMax}) {

                        $profObj->{constLocalWimpyMax} = $profObj->{_localWimpyMax};
                        delete $profObj->{_localWimpyMax};

                        # (This line makes sure the correct file object's ->modifyFlag is set)
                        $profObj->ivPoke('category', $profObj->category);
                    }
                }
            }

        ### worldmodel ###########################################################################

        } elsif ($self->fileType eq 'worldmodel') {

            # (Import the world model, for convenience)
            $wmObj = $self->session->worldModelObj;

            if ($version < 1_000_871) {

                # This version renames a number of IVs. This section comes first so that functions
                #   like $wmObj->updateRegionPaths can be called by this function
                if (! exists $wmObj->{modelHash}) {

                    $wmObj->{modelHash} = $wmObj->{model};
                    $wmObj->{regionModelHash} = $wmObj->{regionModel};
                    $wmObj->{roomModelHash} = $wmObj->{roomModel};
                    $wmObj->{weaponModelHash} = $wmObj->{weaponModel};
                    $wmObj->{armourModelHash} = $wmObj->{armourModel};
                    $wmObj->{garmentModelHash} = $wmObj->{garmentModel};
                    $wmObj->{charModelHash} = $wmObj->{charModel};
                    $wmObj->{minionModelHash} = $wmObj->{minionModel};
                    $wmObj->{sentientModelHash} = $wmObj->{sentientModel};
                    $wmObj->{creatureModelHash} = $wmObj->{creatureModel};
                    $wmObj->{portableModelHash} = $wmObj->{portableModel};
                    $wmObj->{decorationModelHash} = $wmObj->{decorationModel};
                    $wmObj->{customModelHash} = $wmObj->{customModel};
                    $wmObj->{exitModelHash} = $wmObj->{exitModel};

                    delete $wmObj->{model};
                    delete $wmObj->{regionModel};
                    delete $wmObj->{roomModel};
                    delete $wmObj->{weaponModel};
                    delete $wmObj->{armourModel};
                    delete $wmObj->{garmentModel};
                    delete $wmObj->{charModel};
                    delete $wmObj->{minionModel};
                    delete $wmObj->{sentientModel};
                    delete $wmObj->{creatureModel};
                    delete $wmObj->{portableModel};
                    delete $wmObj->{decorationModel};
                    delete $wmObj->{customModel};
                    delete $wmObj->{exitModel};
                }
            }

            if ($version < 1_000_006) {

#                # Update the room flag list
#                $wmObj->updateRoomFlags($self->session);

                # Add the new border colour IV
                $wmObj->{defaultGhostSelectBorderColour} = undef;
                $wmObj->ivPoke('defaultGhostSelectBorderColour', '#BB6E57');
                $wmObj->{ghostSelectBorderColour} = undef;
                $wmObj->ivPoke('ghostSelectBorderColour', '#BB6E57');

                # Add the modified border colours (unless the user has already modified them)
                $wmObj->ivPoke('defaultLostBorderColour', '#21D221');
                if ($wmObj->{lostBorderColour} eq '#00FF00') {

                    $wmObj->ivPoke('lostBorderColour', '#00FF00');
                }
            }

            if ($version < 1_000_009) {

                # This version introduces exit tags for exits drawn as up/down. Any exits in these
                #   directions, whose exit tags have not been modified by the user, should have
                #   their tags updated to include the words 'up' and 'down')
                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    my ($destRoomObj, $destRegionObj, $oldTag, $newTag);

                    if ($exitObj->{exitTag} && $exitObj->{mapDir}) {

                        $destRoomObj = $wmObj->ivShow('modelHash', $exitObj->{destRoom});
                        $destRegionObj = $wmObj->ivShow('modelHash', $destRoomObj->{parent});
                        $oldTag = 'to ' . $destRegionObj->{name};

                        if ($exitObj->{exitTag} eq $oldTag) {

                            # Tag hasn't been modified by the user, so we can update it
                            if ($exitObj->{mapDir} eq 'up' || $exitObj->{mapDir} eq 'down') {
                                $newTag = $exitObj->{mapDir} . ' to ' . $destRegionObj->{name};
                            } else {
                                $newTag = $oldTag;
                            }

                            if ($exitObj->{oneWayFlag}) {

                                $newTag .= ' (>)';
                            }

                            $exitObj->ivPoke('exitTag', $newTag);
                        }
                    }
                }
            }

            if ($version < 1_000_016) {

                if (! exists $wmObj->{pathFindStepLimit}) {

                    # Add the new IV
                    $wmObj->{pathFindStepLimit} = undef;
                    $wmObj->ivPoke('pathFindStepLimit', 200);
                }
            }

            if ($version < 1_000_018) {

#                # Update the room flag list
#                $wmObj->updateRoomFlags($self->session);
            }

            if ($version < 1_000_041) {

                # This version fixes an error in GA::Obj::WorldModel->connectRegionBrokenExit, in
                #   which exits that are connected to rooms in different regions as uncertain or
                #   one-way exits are not added to the parent regionmap's list of region exits
                # First, check every region exit. If it can't be found in the parent regionmap's
                #   list of region exits, add it

                # (Only display a warning, if the model contains exits)
                if ($wmObj->{exitModelHash}) {

                    $self->writeText('Applying essential world model update. Please be patient...');
                    $axmud::CLIENT->desktopObj->updateWidgets(
                        $self->_objClass . '->updateExtractedData',
                    );
                }

                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    my ($roomObj, $regionObj, $regionmapObj);

                    if ($exitObj->{regionFlag}) {

                        $roomObj = $wmObj->ivShow('modelHash', $exitObj->{parent});
                        $regionObj = $wmObj->ivShow('modelHash', $roomObj->{parent});
                        $regionmapObj = $wmObj->ivShow('regionmapHash', $regionObj->{name});

                        if (! $regionmapObj->ivExists('regionExitHash', $exitObj->{number})) {

                            $wmObj->ivAdd(
                                'updateBoundaryHash',
                                $exitObj->{number},
                                $regionObj->{name},
                            );
                        }
                    }
                }

                # Second, tell the world model to update its boundaries (which calls
                #   $regionmapObj->storeRegionExit for each new region exit)
                $wmObj->updateRegionPaths($self->session);

                # Third, recalculate all region paths
                foreach my $regionmapObj (
                    sort {lc($a->{name}) cmp lc($b->{name})} ($wmObj->ivValues('regionmapHash'))
                ) {
                    $wmObj->recalculateRegionPaths(
                        $self->session,
                        $regionmapObj,
                    );
                }
            }

            if ($version < 1_000_053) {

                # Add the new IV to all exit objects
                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    if (! exists $exitObj->{notSuperFlag}) {

                        $exitObj->{notSuperFlag} = undef;
                        $exitObj->ivPoke('notSuperFlag', FALSE);
                    }
                }
            }

            if ($version < 1_000_094) {

                # Add the new IV to all model objects
                foreach my $obj ($wmObj->ivValues('modelHash')) {

                    if (! exists $obj->{targetRoomNum}) {

                        $obj->{targetRoomNum} = undef;
                        $obj->ivUndef('targetRoomNum');
                    }
                }
            }

            if ($version < 1_000_108) {

                # This version changes the initial position of room tag/room guild text on the
                #   Automapper window
                # Check existing world model rooms; if any of them have room tags/room guilds, ask
                #   the user if they should be updated
                my ($tagAdjust, $guildAdjust, $matchFlag, $response);

                $tagAdjust = int (          # Default value - 5
                                    (
                                        $wmObj->{defaultBlockHeightPixels}
                                        - $wmObj->{defaultRoomHeightPixels}
                                    ) / 4
                             );

                $guildAdjust = int (        # Default value - 3
                                    (
                                        $wmObj->{defaultBlockHeightPixels}
                                        - $wmObj->{defaultRoomHeightPixels}
                                    ) / 6
                               );

                OUTER: foreach my $obj ($wmObj->ivValues('modelHash')) {

                    if ($obj->{category} eq 'room' && ($obj->{roomTag} || $obj->{roomGuild})) {

                        $matchFlag = TRUE;
                        last OUTER;
                    }
                }

                if ($matchFlag && ($tagAdjust || $guildAdjust)) {

                    $response = $self->session->mainWin->showMsgDialogue(
                        'Adjust text position',
                        'question',
                        "Room tags and room guilds are now drawn in the\nAutomapper window at a"
                        . " slightly different position.\n\nDo you want to adjust your existing"
                        . " room tags/guilds,\nso that they appear in the same position as before?",
                        'yes-no',
                    );

                    if (defined $response && $response eq 'yes') {

                        OUTER: foreach my $obj ($wmObj->ivValues('modelHash')) {

                            if ($obj->{category} eq 'room') {

                                if ($obj->{roomTag}) {

                                    $obj->ivPlus('roomTagYOffset', $tagAdjust);
                                }

                                if ($obj->{roomGuild}) {

                                    $obj->ivMinus('roomGuildYOffset', $tagAdjust);
                                }
                            }
                        }
                    }
                }
            }

            if ($version < 1_000_110) {

                # This version corrects an error which messed up exits with bends which had been
                #   dragged by the user. To correct the problem, all bends must be removed; it's up
                #   to the user to reposition them, now that it's possible
                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    my $listRef = $exitObj->{bendOffsetList};
                    if (@$listRef) {

                        $exitObj->ivEmpty('bendOffsetList');
                    }
                }
            }

            if ($version < 1_000_114) {

                # This version corrects an error in which an exit is sometimes twinned with an exit
                #   that is attached to a shadow exit, rather than being twinned to the shadow exit
                #   itself
                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    my ($twinExitObj, $shadowExitObj, $roomObj, $otherRoomObj);

                    if ($exitObj->{twinExit} && $exitObj->{shadowExit}) {

                        $twinExitObj = $wmObj->ivShow('exitModelHash', $exitObj->{twinExit});
                        $shadowExitObj = $wmObj->ivShow('exitModelHash', $exitObj->{shadowExit});
                        $roomObj = $wmObj->ivShow('modelHash', $exitObj->{parent});
                        $otherRoomObj = $wmObj->ivShow('modelHash', $twinExitObj->{parent});

                        $wmObj->abandonTwinExit(FALSE, $exitObj, $twinExitObj);

                        # If both the exits had shadow exits, we are now dealing with a set of four
                        #   exits, and the call to ->abandonTwinExit above will leave one of the
                        #   four unabandoned
                        if ($shadowExitObj->{twinExit}) {

                            $wmObj->abandonTwinExit(FALSE, $shadowExitObj);
                        }

                        # Now we can reconnect the rooms, avoiding twinning exits with shadow exits
                        $wmObj->connectRooms(
                            $self->session,
                            FALSE,
                            $roomObj,
                            $otherRoomObj,
                            $shadowExitObj->{dir},
                        );
                    }
                }
            }

            if ($version < 1_000_127) {

                # This version corrects an error in which the destination room is not informed when
                #   1-way and uncertain exits are converted to incomplete exits
                # Need to check every room's hash of incoming 1-way/uncertain exits, to make sure
                #   the exits still lead to their supposed destinations
                foreach my $roomObj ($wmObj->ivValues('roomModelHash')) {

                    my $hashRef = $roomObj->{uncertainExitHash};
                    if (%$hashRef) {

                        my %uncertainExitHash = %$hashRef;

                        foreach my $exitNum (keys %uncertainExitHash) {

                            my $exitObj = $wmObj->ivShow('exitModelHash', $exitNum);

                            if (
                                # Exit doesn't exit
                                ! $exitObj
                                # Exit doesn't lead to $roomObj
                                || ! $exitObj->{destRoom}
                                || $exitObj->{destRoom} != $roomObj->{number}
                                # Exit is no longer an uncertain exit
                                || (
                                    $exitObj->{twinExit}
                                    || $exitObj->{retraceFlag}
                                    || $exitObj->{oneWayFlag}
                                    || $exitObj->{randomType}
                                )
                            ) {
                                delete $uncertainExitHash{$exitNum};
                            }
                        }

                        $roomObj->ivPoke('uncertainExitHash', %uncertainExitHash);
                    }

                    $hashRef = $roomObj->{oneWayExitHash};
                    if (%$hashRef) {

                        my %oneWayExitHash = %$hashRef;

                        foreach my $exitNum (keys %oneWayExitHash) {

                            my $exitObj = $wmObj->ivShow('exitModelHash', $exitNum);

                            if (
                                # Exit doesn't exit
                                ! $exitObj
                                # Exit doesn't lead to $roomObj
                                || ! $exitObj->{destRoom}
                                || $exitObj->{destRoom} != $roomObj->{number}
                                # Exit is no longer a one -way exit
                                || ! $exitObj->{oneWayFlag}
                            ) {
                                delete $oneWayExitHash{$exitNum};
                            }
                        }

                        $roomObj->ivPoke('oneWayExitHash', %oneWayExitHash);
                    }
                }
            }

            if ($version < 1_000_128) {

                # This version adds a new IV to the world model
                if (! exists $wmObj->{protectedMovesFlag}) {

                    $wmObj->{protectedMovesFlag} = undef;
                    $wmObj->ivPoke('protectedMovesFlag', FALSE);
                }
            }

            if ($version < 1_000_213) {

                # Add the new IV to all exit objects
                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    if (! exists $exitObj->{info}) {

                        $exitObj->{info} = undef;
                        $exitObj->ivPoke('info', FALSE);
                    }
                }
            }

            if ($version < 1_000_222) {

                # This version fixes an issue with random exits. Make repairs to the world model

                # Exit still has a ->randomDestList, even though its ->randomType is no longer 3
                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    my $listRef = $exitObj->{randomDestList};
                    if ($exitObj->{randomType} == 3 && @$listRef) {

                        foreach my $destRoomNum (@$listRef) {

                            my $roomObj = $wmObj->ivShow('modelHash', $destRoomNum);
                            if ($roomObj && $roomObj->{category} eq 'room') {

                                $roomObj->ivDelete('randomExitHash', $exitObj->{number});
                            }
                        }

                        $exitObj->ivEmpty('randomDestList');
                    }
                }

                # Room has an incoming random exit of the wrong type
                foreach my $roomObj ($wmObj->ivValues('roomModelHash')) {

                    my $hashRef = $roomObj->{randomExitHash};
                    if (%$hashRef) {

                        my %modHash;

                        foreach my $exitNum ($roomObj->ivKeys('randomExitHash')) {

                            my $exitObj = $wmObj->ivShow('exitModelHash', $exitNum);
                            if ($exitObj && $exitObj->{randomType} == 3) {

                                $modHash{$exitNum} = undef;
                            }
                        }

                        $roomObj->ivPoke('randomExitHash', %modHash);
                    }
                }
            }

            if ($version < 1_000_224) {

                # Add a new IV to the world model, the date and Axmud version when the model was
                #   created. Since we don't know the creation date, use the date of the v1.0.0
                #   release
                if (! exists $wmObj->{modelCreationDate}) {

                    $wmObj->{modelCreationDate} = undef;
                    $wmObj->ivPoke('modelCreationDate', 'Thu Jul 31, 2014');
                    $wmObj->{modelCreationVersion} = undef;
                    $wmObj->ivPoke('modelCreationVersion', '1.0.0');
                }
            }

            if ($version < 1_000_260) {

                my ($regionmapObj, $regionObj);

                # ->firstRegion could have been set to a region which has a parent; in which case
                #   the specified region can't be shown at the top of the Automapper window's list.
                # Check the region specified by ->firstRegion and reset it, if it has a parent
                #   region
                if ($wmObj->{firstRegion}) {

                    my $regionmapObj = $wmObj->ivShow('regionmapHash', $wmObj->{firstRegion});
                    if ($regionmapObj) {

                        $regionObj = $wmObj->ivShow('regionModelHash', $regionmapObj->{number});
                    }

                    if ($regionObj && $regionObj->{parent}) {

                        $wmObj->ivUndef('firstRegion');
                    }
                }
            }

            if ($version < 1_000_272) {

                # This version adds a new IV to the world model
                if (! exists $wmObj->{showAllPrimaryFlag}) {

                    $wmObj->{showAllPrimaryFlag} = undef;
                    $wmObj->ivPoke('showAllPrimaryFlag', FALSE);
                }
            }

            if ($version < 1_000_290) {

                # Add the new IV to all exit objects
                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    if (! exists $exitObj->{oneWayDir}) {

                        $exitObj->{oneWayDir} = undef;
                        # The default direction at which the exit touches its destination room is
                        #   the opposite of the exit's existing ->mapDir
                        # NB If the exit is unallocatable, ->mapDir won't be set, so we'll use
                        #   'north' as an emergency default value for ->mapDir. (This same approach
                        #   is used elsewhere in the Axmud code)
                        if ($exitObj->{mapDir}) {

                            $exitObj->ivPoke(
                                'oneWayDir',
                                $axmud::CLIENT->ivShow('constOppDirHash', $exitObj->{mapDir}),
                            );

                        } else {

                            # Emergency default
                            $exitObj->ivPoke('oneWayDir', 'north');
                        }
                    }
                }
            }

            if ($version < 1_000_300) {

                # The possible values of $exitObj->state have changed. Values 0-3 are unchanged, but
                #   the value 4 (other) must be converted to 6
                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    if ($exitObj->{state} == 4) {

                        $exitObj->ivPoke('state', 6);
                    }
                }
            }

            if ($version < 1_000_309) {

                # v1.0.308 fixes a problem, in which labels on a map disappeared when the region
                #   was renamed. Check all labels, and repair any GA::Obj::MapLabel objects that
                #   are broken
                # Actually, first count the problems, then ask the user to repair them, or to
                #   delete the label altogether
                my ($count, $response, $string);

                $count = 0;

                foreach my $regionmapObj ($wmObj->ivValues('regionmapHash')) {

                    foreach my $labelObj ($regionmapObj->ivValues('gridLabelHash')) {

                        if ($labelObj->{region} ne $regionmapObj->{name}) {

                            $count++;
                        }
                    }
                }

                if ($count) {

                    if ($count == 1) {
                        $string = '1 label';
                    } else {
                        $string = $count . ' labels';
                    }

                    $response = $self->session->mainWin->showMsgDialogue(
                        'Recover missing labels',
                        'question',
                        "Due to an earlier problem, $string had become invisible when region(s)"
                        . " were renamed. Do you want to recover these labels? (Click \'No\' to"
                        . " delete them altogether)",
                        'yes-no',
                    );

                    foreach my $regionmapObj ($wmObj->ivValues('regionmapHash')) {

                        foreach my $labelObj ($regionmapObj->ivValues('gridLabelHash')) {

                            if ($labelObj->{region} ne $regionmapObj->{name}) {

                                # Recover the missing label, even if we're about to delete it
                                $labelObj->ivPoke('region', $regionmapObj->{name});

                                if (! $response || $response eq 'no') {

                                    # Delete this label
                                    $wmObj->deleteLabels(
                                        FALSE,      # No Automapper windows to update
                                        $labelObj,
                                    );
                                }
                            }
                        }
                    }
                }
            }

            if ($version < 1_000_327) {

                # In all exit objects, replace ->state with ->exitState, and modify its value,
                #   increasing all non-zero values by one
                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    if (exists $exitObj->{state}) {

                        $exitObj->{exitState} = undef;
                        if ($exitObj->{state}) {
                            $exitObj->ivPoke('exitState', $exitObj->{state} + 1);
                        } else {
                            $exitObj->ivPoke('exitState', 0);
                        }

                        delete $exitObj->{state};
                    }
                }
            }

            if ($version < 1_000_328) {

                # This version adds a new IV to the world model
                if (! exists $wmObj->{updateOrnamentsFlag}) {

                    $wmObj->{updateOrnamentsFlag} = undef;
                    $wmObj->ivPoke('updateOrnamentsFlag', FALSE);
                }
            }

            if ($version < 1_000_329) {

                my %stateHash = (
                    0   => 'normal',
                    1   => 'open',
                    2   => 'closed',
                    3   => 'locked',
                    4   => 'impass',
                    5   => 'dark',
                    6   => 'danger',
                    7   => 'other',
                );

                # In all exit objects, now swapping values of ->exitState from numbers to strings
                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    if (exists $stateHash{$exitObj->{exitState}}) {

                        # e.g. convert 2 to 'closed'
                        $exitObj->ivPoke('exitState', $stateHash{$exitObj->{exitState}});

                    } else {

                        # Emergency default
                        $exitObj->ivPoke('exitState', 'normal');
                    }
                }
            }

            if ($version < 1_000_341) {

                # Add the new IV to all map label objects
                foreach my $regionmapObj ($wmObj->ivValues('regionmapHash')) {

                    foreach my $mapLabelObj ($regionmapObj->ivValues('gridLabelHash')) {

                        if (! exists $mapLabelObj->{relSize}) {

                            $mapLabelObj->{relSize} = undef;
                            $mapLabelObj->ivPoke('relSize', 1);
                        }
                    }
                }
            }

            if ($version < 1_000_429) {

                # This version adds a new IV to the world model
                if (! exists $wmObj->{superProtectedMovesFlag}) {

                    $wmObj->{superProtectedMovesFlag} = undef;
                    $wmObj->ivPoke('superProtectedMovesFlag', FALSE);
                }
            }

            if ($version < 1_000_467) {

                # This version adds a new IV to the world model
                if (! exists $wmObj->{teleportHash}) {

                    $wmObj->{teleportHash} = {};
                }
            }

            if ($version < 1_000_545) {

                # This version splits an existing world model IV into two new ones
                if (! exists $wmObj->{allowModelScriptFlag}) {

                    $wmObj->{allowModelScriptFlag} = undef;
                    $wmObj->ivPoke('allowModelScriptFlag', $wmObj->{allowScriptFlag});
                    $wmObj->{allowRoomScriptFlag} = undef;
                    $wmObj->ivPoke('allowRoomScriptFlag', $wmObj->{allowScriptFlag});
                    delete $wmObj->{allowScriptFlag};
                }

                # Also creates two new world model IVs
                if (! exists $wmObj->{newRoomScriptList}) {

                    $wmObj->{newRoomScriptList} = [];
                    $wmObj->ivEmpty('newRoomScriptList');
                    $wmObj->{arriveScriptList} = [];
                    $wmObj->ivEmpty('arriveScriptList');
                }

                # This version also renames a room model object IV
                foreach my $obj ($wmObj->ivValues('roomModelHash')) {

                    my $listRef;

                    if (! exists $obj->{arriveScriptList}) {

                        $obj->{arriveScriptList} = [];
                        $listRef = $obj->{scriptList};
                        $obj->ivPush('arriveScriptList', @$listRef);
                        delete $obj->{scriptList};
                    }
                }
            }

            if ($version < 1_000_572) {

#                # Update the room flag list
#                $wmObj->updateRoomFlags($self->session);
            }

            if ($version < 1_000_573) {

                # This version fixes an error, in which one of a pair of region exits is made a
                #   super-region exit, but not the other
                # Check all super-region exits; if their twins are not super-region exits (and the
                #   user hasn't deliberately marked them as not being super-region exits), update
                #   them

                my ($count, $hashRef);

                # Only display a warning, if the model contains objects
                $count = 0;
                $hashRef = $wmObj->{modelHash};
                if (%$hashRef) {

                    $self->writeText('Applying essential world model update. Please be patient...');
                    $axmud::CLIENT->desktopObj->updateWidgets(
                        $self->_objClass . '->updateExtractedData',
                    );
                }

                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    if ($exitObj->{superFlag} && $exitObj->{twinExit}) {

                        my $twinExitObj = $wmObj->ivShow('exitModelHash', $exitObj->{twinExit});

                        if (
                            $twinExitObj->{regionFlag}
                            && ! $twinExitObj->{superFlag}
                            && ! $twinExitObj->{notSuperFlag}
                        ) {
                            $count++;
                            $twinExitObj->ivPoke('superFlag', TRUE);

                            # The regionmap must also be updated (in some cases)
                            my $twinRoomObj = $wmObj->ivShow('modelHash', $twinExitObj->{parent});
                            my $twinRegionObj = $wmObj->ivShow('modelHash', $twinRoomObj->{parent});
                            my $twinRegionmapObj
                                = $wmObj->ivShow('regionmapHash', $twinRegionObj->{name});

                            $twinRegionmapObj->storeRegionExit($self->session, $twinExitObj);
                        }
                    }
                }

                if ($count) {

                    # Recalculate all region pahts
                    foreach my $regionmapObj ($wmObj->ivValues('regionmapHash')) {

                        my $number = $wmObj->recalculateRegionPaths(
                            $self->session,
                            $regionmapObj,
                        );
                    }
                }
            }

            if ($version < 1_000_579) {

                # This version corrects some errors with exit bends. Redrawing the bends exactly
                #   as the user intended them to be is impossible, so in some cases we must
                #   remove the bends altogether

                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    my ($listRef, $twinExitObj, $listRef2);

                    $listRef = $exitObj->{bendOffsetList};

                    # In some cases, a one-way exit or uncertain exit is left with bend(s); so
                    #   remove them
                    if (
                        $exitObj->{oneWayFlag}
                        || (
                            $exitObj->{destRoom}
                            && (
                                ! $exitObj->{twinExit}
                                && ! $exitObj->{retraceFlag}
                                && ! $exitObj->{randomType}
                            )
                        )
                    ) {
                        if (@$listRef) {

                            $exitObj->ivEmpty('bendOffsetList');
                        }
                    }

                    if ($exitObj->{twinExit}) {

                        $twinExitObj = $wmObj->ivShow('exitModelHash', $exitObj->{twinExit});
                        $listRef2 = $twinExitObj->{bendOffsetList};
                    }

                    # In some cases, one of a pair of two-way exits has a bend, but the other
                    #   doesn't. Remove the bend, in this case
                    if (
                        $twinExitObj
                        && (
                            (! @$listRef && @$listRef2)
                            || (@$listRef && ! @$listRef2)
                        )
                    ) {
                        $exitObj->ivEmpty('bendOffsetList');
                        $twinExitObj->ivEmpty('bendOffsetList');
                    }
                }
            }

            if ($version < 1_000_624) {

                # Update the room flag list
                $wmObj->updateRoomFlags($self->session);
            }

            if ($version < 1_000_824) {

                # This version adds a new IV to the world model
                if (! exists $wmObj->{pseudoWinFlag}) {

                    $wmObj->{pseudoWinFlag} = undef;
                    $wmObj->ivPoke('pseudoWinFlag', TRUE);
                }
            }

            if ($version < 1_000_840) {

                # This version adds a new IV to all room model objects
                foreach my $obj ($wmObj->ivValues('roomModelHash')) {

                    if (! exists $obj->{protocolRoomHash}) {

                        $obj->{protocolRoomHash} = {};
                        $obj->ivEmpty('protocolRoomHash');
                        $obj->{protocolExitHash} = {};
                        $obj->ivEmpty('protocolExitHash');
                    }
                }
            }

            if ($version < 1_000_842) {

                # This version adds new IVs to the world model
                if (! exists $wmObj->{matchVNumFlag}) {

                    $wmObj->{matchVNumFlag} = undef;
                    $wmObj->ivPoke('matchVNumFlag', TRUE);
                    $wmObj->{updateVNumFlag} = undef;
                    $wmObj->ivPoke('updateVNumFlag', TRUE);

                    $wmObj->{roomTerrainInitHash} = {};
                    $wmObj->ivEmpty('roomTerrainInitHash');
                    $wmObj->{roomTerrainHash} = {};
                    $wmObj->ivEmpty('roomTerrainHash');
                }
            }

            if ($version < 1_000_859) {

                # This version simplifies an IV in regionmap objects
                foreach my $regionmapObj ($wmObj->ivValues('regionmapHash')) {

                    my (
                        $hashRef,
                        %newHash,
                    );

                    $hashRef = $regionmapObj->{gridExitTagHash};
                    foreach my $key (keys %$hashRef) {

                        $newHash{$key} = undef;
                    }

                    $regionmapObj->ivPoke('gridExitTagHash', %newHash);
                }

                # This version also changed an IV name
                foreach my $obj ($wmObj->ivValues('modelHash')) {

                    if (! exists $obj->{container}) {

                        $obj->{container} = undef;
                        $obj->ivPoke('container', $obj->{containerObj});

                        delete $obj->{container};
                    }
                }
            }

            if ($version < 1_000_896) {

                # This version adds a new IV to all room model objects
                foreach my $obj ($wmObj->ivValues('roomModelHash')) {

                    if (! exists $obj->{roomCmdList}) {

                        $obj->{roomCmdList} = [];
                        $obj->ivEmpty('roomCmdList');
                    }
                }
            }

            if ($version < 1_000_896) {

                # This version adds a new IV to the world model, and renames some existing ones
                if (! exists $wmObj->{updateRoomCmdFlag}) {

                    $wmObj->{updateRoomCmdFlag} = undef;
                    $wmObj->ivPoke('updateRoomCmdFlag', FALSE);
                }

                $wmObj->{matchExitFlag} = $wmObj->{matchExitsFlag};
                delete $wmObj->{matchExitsFlag};
                $wmObj->{updateExitFlag} = $wmObj->{updateExitsFlag};
                delete $wmObj->{updateExitsFlag};
                $wmObj->{updateOrnamentFlag} = $wmObj->{updateOrnamentsFlag};
                delete $wmObj->{updateOrnamentsFlag};
            }

            if ($version < 1_000_909) {

                # This version converts some numerical mode values to string mode values
                if ($wmObj->currentRoomMode eq '0') {
                    $wmObj->ivPoke('currentRoomMode', 'single');
                } elsif ($wmObj->currentRoomMode eq '1') {
                    $wmObj->ivPoke('currentRoomMode', 'double');
                } elsif ($wmObj->currentRoomMode eq '2') {
                    $wmObj->ivPoke('currentRoomMode', 'interior');
                }

                if ($wmObj->roomInteriorMode eq '0') {
                    $wmObj->ivPoke('roomInteriorMode', 'none');
                } elsif ($wmObj->roomInteriorMode eq '1') {
                    $wmObj->ivPoke('roomInteriorMode', 'shadow_count');
                } elsif ($wmObj->roomInteriorMode eq '2') {
                    $wmObj->ivPoke('roomInteriorMode', 'region_count');
                } elsif ($wmObj->roomInteriorMode eq '3') {
                    $wmObj->ivPoke('roomInteriorMode', 'room_content');
                } elsif ($wmObj->roomInteriorMode eq '4') {
                    $wmObj->ivPoke('roomInteriorMode', 'hidden_count');
                } elsif ($wmObj->roomInteriorMode eq '5') {
                    $wmObj->ivPoke('roomInteriorMode', 'temp_count');
                } elsif ($wmObj->roomInteriorMode eq '6') {
                    $wmObj->ivPoke('roomInteriorMode', 'word_count');
                } elsif ($wmObj->roomInteriorMode eq '7') {
                    $wmObj->ivPoke('roomInteriorMode', 'room_flag');
                } elsif ($wmObj->roomInteriorMode eq '8') {
                    $wmObj->ivPoke('roomInteriorMode', 'visit_count');
                } elsif ($wmObj->roomInteriorMode eq '9') {
                    $wmObj->ivPoke('roomInteriorMode', 'profile_count');
                } elsif ($wmObj->roomInteriorMode eq '10') {
                    $wmObj->ivPoke('roomInteriorMode', 'title_descrip');
                } elsif ($wmObj->roomInteriorMode eq '11') {
                    $wmObj->ivPoke('roomInteriorMode', 'exit_pattern');
                } elsif ($wmObj->roomInteriorMode eq '12') {
                    $wmObj->ivPoke('roomInteriorMode', 'source_code');
                } elsif ($wmObj->roomInteriorMode eq '13') {
                    $wmObj->ivPoke('roomInteriorMode', 'vnum');
                }

                if ($wmObj->drawExitMode eq '0') {
                    $wmObj->ivPoke('drawExitMode', 'ask_regionmap');
                } elsif ($wmObj->drawExitMode eq '1') {
                    $wmObj->ivPoke('drawExitMode', 'no_exit');
                } elsif ($wmObj->drawExitMode eq '2') {
                    $wmObj->ivPoke('drawExitMode', 'simple_exit');
                } elsif ($wmObj->drawExitMode eq '3') {
                    $wmObj->ivPoke('drawExitMode', 'complex_exit');
                }

                foreach my $regionmapObj ($wmObj->ivValues('regionmapHash')) {

                    if ($regionmapObj->drawExitMode eq '1') {
                        $regionmapObj->ivPoke('drawExitMode', 'no_exit');
                    } elsif ($regionmapObj->drawExitMode eq '2') {
                        $regionmapObj->ivPoke('drawExitMode', 'simple_exit');
                    } elsif ($regionmapObj->drawExitMode eq '3') {
                        $regionmapObj->ivPoke('drawExitMode', 'complex_exit');
                    }
                }

                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    if ($exitObj->drawMode eq '0') {
                        $exitObj->ivPoke('drawMode', 'primary');
                    } elsif ($exitObj->drawMode eq '1') {
                        $exitObj->ivPoke('drawMode', 'temp_alloc');
                    } elsif ($exitObj->drawMode eq '2') {
                        $exitObj->ivPoke('drawMode', 'temp_unalloc');
                    } elsif ($exitObj->drawMode eq '3') {
                        $exitObj->ivPoke('drawMode', 'perm_alloc');
                    }

                    if ($exitObj->randomType eq '0') {
                        $exitObj->ivPoke('randomType', 'none');
                    } elsif ($exitObj->randomType eq '1') {
                        $exitObj->ivPoke('randomType', 'same_region');
                    } elsif ($exitObj->randomType eq '2') {
                        $exitObj->ivPoke('randomType', 'any_region');
                    } elsif ($exitObj->randomType eq '3') {
                        $exitObj->ivPoke('randomType', 'room_list');
                    }
                }
            }

            if ($version < 1_000_913) {

                # This version removes two IVs which have been moved to GA::Client
                if (exists $wmObj->{roomFilterStartList}) {

                    delete $wmObj->{roomFilterStartList};
                    delete $wmObj->{roomFlagStartList};
                    delete $wmObj->{roomFlagHazardHash};
                }

                # This version also tweaks the value of an IV in several kinds of model objects
                foreach my $obj ($wmObj->ivValues('modelHash')) {

                    if (exists $obj->{sellableFlag}) {

                        if (! $obj->{sellableFlag}) {
                            $obj->ivPoke('sellableFlag', FALSE);
                        } else {
                            $obj->ivPoke('sellableFlag', TRUE);
                        }
                    }
                }
            }

            if ($version < 1_000_915) {

                # This version adds a new IV to the world model
                if (! exists $wmObj->{followAnchorFlag}) {

                    $wmObj->{followAnchorFlag} = undef;
                    $wmObj->ivPoke('followAnchorFlag', FALSE);
                }
            }

            if ($version < 1_000_933) {

                # This version renames an IV in the world model
                if (exists $wmObj->{showToolBarFlag}) {

                    $wmObj->{showToolbarFlag} = undef;
                    $wmObj->ivPoke('showToolbarFlag', $wmObj->{showToolBarFlag});
                    delete $wmObj->{showToolBarFlag};
                }
            }
        }

        ### new built-in tasks (IVs updated below) ################################################

        if ($self->fileType eq 'tasks') {

            if ($version < 1_000_342) {

                # This version adds a new built-in task. GA::Client->taskLabelHash must be updated,
                #   but don't overwrite existing entries
                if (! $axmud::CLIENT->ivExists('taskLabelHash', 'debug')) {

                    $axmud::CLIENT->ivAdd('taskLabelHash', 'debug', 'debugger_task');
                }

                if (! $axmud::CLIENT->ivExists('taskLabelHash', 'debugger')) {

                    $axmud::CLIENT->ivAdd('taskLabelHash', 'debugger', 'debugger_task');
                }
            }

            if ($version < 1_000_424) {

                # This version adds two new built-in tasks
                if (! $axmud::CLIENT->ivExists('taskLabelHash', 'raw')) {

                    $axmud::CLIENT->ivAdd('taskLabelHash', 'raw', 'raw_text_task');
                }

                if (! $axmud::CLIENT->ivExists('taskLabelHash', 'rawtext')) {

                    $axmud::CLIENT->ivAdd('taskLabelHash', 'rawtext', 'raw_text_task');
                }

                if (! $axmud::CLIENT->ivExists('taskLabelHash', 'token')) {

                    $axmud::CLIENT->ivAdd('taskLabelHash', 'token', 'raw_token_task');
                }

                if (! $axmud::CLIENT->ivExists('taskLabelHash', 'rawtoken')) {

                    $axmud::CLIENT->ivAdd('taskLabelHash', 'rawtoken', 'raw_token_task');
                }
            }

            if ($version < 1_000_622) {

                # This version adds a new built-in task
                if (! $axmud::CLIENT->ivExists('taskLabelHash', 'note')) {

                    $axmud::CLIENT->ivAdd('taskLabelHash', 'note', 'notepad_task');
                }

                if (! $axmud::CLIENT->ivExists('taskLabelHash', 'notes')) {

                    $axmud::CLIENT->ivAdd('taskLabelHash', 'notes', 'notepad_task');
                }

                if (! $axmud::CLIENT->ivExists('taskLabelHash', 'notepad')) {

                    $axmud::CLIENT->ivAdd('taskLabelHash', 'notepad', 'notepad_task');
                }
            }

            if ($version < 1_000_827) {

                # This version adds a new built-in task
                if (! $axmud::CLIENT->ivExists('taskLabelHash', 'frame')) {

                    $axmud::CLIENT->ivAdd('taskLabelHash', 'frame', 'frame_task');
                }
            }

            if ($version < 1_000_881) {

                # This version adds a new built-in task
                if (! $axmud::CLIENT->ivExists('taskLabelHash', 'launch')) {

                    $axmud::CLIENT->ivAdd('taskLabelHash', 'launch', 'launch_task');
                    $axmud::CLIENT->ivAdd('taskLabelHash', 'launcher', 'launch_task');
                }
            }
        }

        ### worldprof / otherprof / tasks #########################################################

        if (
            $self->fileType eq 'worldprof'
            || $self->fileType eq 'otherprof'
            || $self->fileType eq 'tasks'
        ) {
            if ($version < 1_000_037 && $self->session) {

                # This version updated the Locator task with a new IV. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('locator_task')) {

                    if (! exists $taskObj->{lastStatementEndLine}) {

                        $taskObj->{lastStatementEndLine} = undef;
                        $taskObj->ivUndef('lastStatementEndLine');
                    }
                }
            }

            if ($version < 1_000_066 && $self->session) {

                # This version updated the Attack task with a new IV. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('attack_task')) {

                    if (! exists $taskObj->{announceFlag}) {

                        $taskObj->{announceFlag} = undef;
                        $taskObj->ivPoke('announceFlag', TRUE);
                    }
                }
            }

            if ($version < 1_000_078 && $self->session) {

                # This version updated the Locator task with a new IV. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('locator_task')) {

                    if (! exists $taskObj->{restartBufferLine}) {

                        $taskObj->{restartBufferLine} = undef;
                        $taskObj->ivUndef('restartBufferLine');
                    }
                }
            }

            if ($version < 1_000_081 && $self->session) {

                # This version updated the Inventory task with a new IV. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('inventory_task')) {

                    if (! exists $taskObj->{resetInventoryFlag}) {

                        $taskObj->{resetInventoryFlag} = undef;
                        $taskObj->ivPoke('resetInventoryFlag', FALSE);
                    }
                }
            }

            if ($version < 1_000_090 && $self->session) {

                # This version updates the Status task, using a single string (e.g.
                #   'health_points_max') rather than two strings to represent the same thing (e.g.
                #   'health_max', 'health_points_max'
                my %updateHash = (
                    '@health_max@'  => '@health_points_max@',
                    '@magic_max@'   => '@magic_points_max@',
                    '@energy_max@'  => '@energy_points_max@',
                    '@guild_max@'   => '@guild_points_max@',
                    '@social_max@'  => '@social_points_max@',
                );

                # Update all initial/custom tasks
                # (NB The world profile themselves were updated above)
                foreach my $taskObj ($self->compileTasks('status_task')) {

                    my $listRef;

                    $listRef = $taskObj->{defaultFormatList};
                    foreach my $line (@$listRef) {

                        foreach my $key (keys %updateHash) {

                            my $value = $updateHash{$key};

                            $line =~ s/$key/$value/g;
                        }
                    }

                    $listRef = $taskObj->{displayVarList};
                    foreach my $line (@$listRef) {

                        foreach my $key (keys %updateHash) {

                            my $value = $updateHash{$key};

                            $line =~ s/$key/$value/g;
                        }
                    }
                }
            }

            if ($version < 1_000_119 && $self->session) {

                # This version updates all tasks with a new flag IV. Its value is set to TRUE for
                #   the Inventory, Locator, Status and TaskList tasks, FALSE for everything else
                my %trueHash = (
                    'inventory_task'    => undef,
                    'locator_task'      => undef,
                    'status_task'       => undef,
                    'tasklist_task'     => undef,
                );

                foreach my $taskObj ($self->compileTasks()) {

                    if (! exists $taskObj->{noScrollFlag}) {

                        $taskObj->{noScrollFlag} = undef;

                        if (exists $trueHash{$taskObj->{name}}) {
                            $taskObj->{noScrollFlag} = TRUE;
                        } else {
                            $taskObj->{noScrollFlag} = FALSE;
                        }
                    }
                }
            }

            if ($version < 1_000_155 && $self->session) {

                # This version updated the Locator task with a new IV. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('locator_task')) {

                    if (! exists $taskObj->{lastStatementStartLine}) {

                        $taskObj->{lastStatementStartLine} = undef;
                        $taskObj->ivUndef('lastStatementStartLine');
                    }
                }
            }

            if ($version < 1_000_198 && $self->session) {

                # This version updated the Status task with a new IV. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('status_task')) {

                    if (! exists $taskObj->{xpNextLevel}) {

                        $taskObj->{xpNextLevel} = undef;
                        $taskObj->ivUndef('xpNextLevel');
                        $taskObj->{alignment} = undef;
                        $taskObj->ivUndef('alignment');
                        $taskObj->{affectHash} = {};
                        $taskObj->ivEmpty('affectHash');

                        $taskObj->{oppName} = undef;
                        $taskObj->ivUndef('oppName');
                        $taskObj->{oppHealth} = undef;
                        $taskObj->ivUndef('oppHealth');
                        $taskObj->{oppHealthMax} = undef;
                        $taskObj->ivUndef('oppHealthMax');
                        $taskObj->{oppLevel} = undef;
                        $taskObj->ivUndef('oppLevel');
                        $taskObj->{oppStrength} = undef;
                        $taskObj->ivUndef('oppStrength');
                    }
                }
            }

            if ($version < 1_000_200 && $self->session) {

                # This version updated the Locator task with a new IV. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('locator_task')) {

                    if (! exists $taskObj->{msdpRoomHash}) {

                        $taskObj->{msdpRoomHash} = {};
                        $taskObj->ivEmpty('msdpRoomHash');
                        $taskObj->{msdpExitHash} = {};
                        $taskObj->ivEmpty('msdpExitHash');
                    }
                }
            }

            if ($version < 1_000_212 && $self->session) {

                # This version updated the Status task with a new IV. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('status_task')) {

                    if (! exists $taskObj->{customVarHash}) {

                        $taskObj->{customVarHash} = {};
                        $taskObj->ivEmpty('customVarHash');
                    }
                }
            }

            if ($version < 1_000_344 && $self->session) {

                # This version updated the Divert task with new IVs. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('divert_task')) {

                    if (! exists $taskObj->{tellRoomFlag}) {

                        $taskObj->{tellRoomFlag} = undef;
                        $taskObj->ivPoke('tellRoomFlag', FALSE);
                        $taskObj->{socialRoomFlag} = undef;
                        $taskObj->ivPoke('socialRoomFlag', FALSE);
                        $taskObj->{customRoomFlag} = undef;
                        $taskObj->ivPoke('customRoomFlag', FALSE);
                        $taskObj->{warningRoomFlag} = undef;
                        $taskObj->ivPoke('warningRoomFlag', FALSE);

                        $taskObj->{tellUrgencyFlag} = undef;
                        $taskObj->ivPoke('tellUrgencyFlag', TRUE);
                        $taskObj->{socialUrgencyFlag} = undef;
                        $taskObj->ivPoke('socialUrgencyFlag', TRUE);
                        $taskObj->{customUrgencyFlag} = undef;
                        $taskObj->ivPoke('customUrgencyFlag', TRUE);
                        $taskObj->{warningUrgencyFlag} = undef;
                        $taskObj->ivPoke('warningUrgencyFlag', TRUE);
                    }
                }
            }

            if ($version < 1_000_424 && $self->session) {

                # This version updated the Debugger task by changing its window type from 'entry'
                #   to 'text'. Update all initial/custom tasks
                foreach my $taskObj ($self->compileTasks('debugger_task')) {

                    $taskObj->{winType} = 'text';
                }
            }

            if ($version < 1_000_482 && $self->session) {

                # This version changes character life status. Update all initial/custom tasks
                foreach my $taskObj ($self->compileTasks('status_task')) {

                    if ($taskObj->{lifeStatus} eq 'asleep') {
                        $taskObj->ivPoke('lifeStatus', 'sleep');
                    } elsif ($taskObj->{lifeStatus} eq 'passed_out') {
                        $taskObj->ivPoke('lifeStatus', 'passout');
                    }
                }
            }

            if ($version < 1_000_509 && $self->session) {

                # This version updated the Status task with a new IV. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('status_task')) {

                    if (! exists $taskObj->{commifyMode}) {

                        $taskObj->{commifyMode} = undef;
                        $taskObj->ivPoke('commifyMode', 0);
                    }
                }
            }

            if ($version < 1_000_572 && $self->session) {

                # This version updated the Locator task with a new IV. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('locator_task')) {

                    if (! exists $taskObj->{autoLookMode}) {

                        $taskObj->{autoLookMode} = undef;
                        $taskObj->ivPoke('autoLookMode', 1);
                    }
                }
            }

            if ($version < 1_000_577 && $self->session) {

                # This version updated the Divert task with new IVs. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('divert_task')) {

                    if (! exists $taskObj->{lastLine}) {

                        $taskObj->{lastLine} = undef;
                        $taskObj->ivPoke('lastLine', 0);
                        $taskObj->{gagFlag} = undef;
                        $taskObj->ivPoke('gagFlag', TRUE);
                    }
                }
            }

            if ($version < 1_000_580 && $self->session) {

                # This version updated the Inventory task with a new IV. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('inventory_task')) {

                    if (! exists $taskObj->{lastLine}) {

                        $taskObj->{lastLine} = undef;
                        $taskObj->ivPoke('lastLine', 0);
                    }
                }
            }

            if ($version < 1_000_599 && $self->session) {

                # This version updated the Locator and Status tasks with new IVs. Update all
                #   initial/custom tasks
                foreach my $taskObj ($self->compileTasks('locator_task')) {

                    if (! exists $taskObj->{ttsToReadHash}) {

                        $taskObj->{ttsToReadHash} = {};
                        $taskObj->ivEmpty('ttsToReadHash');
                    }
                }

                foreach my $taskObj ($self->compileTasks('status_task')) {

                    if (! exists $taskObj->{ttsPointsAlertHash}) {

                        $taskObj->{ttsPointsAlertHash} = {};
                        $taskObj->ivEmpty('ttsPointsAlertHash');
                        $taskObj->{ttsPointsAlertMsgHash} = {};
                        $taskObj->ivEmpty('ttsPointsAlertMsgHash');
                    }
                }
            }

            if ($version < 1_000_606 && $self->session) {

                # This version updated the Compass task with a new IV. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('compass_task')) {

                    if (! exists $taskObj->{enabledFlag}) {

                        # (Existing users expect the task to start disabled, but new users will
                        #   see the task start enabled)
                        $taskObj->{enabledFlag} = undef;
                        $taskObj->ivPoke('enabledFlag', FALSE);

                        $taskObj->{radioButton2} = undef;
                        $taskObj->ivUndef('radioButton2');
                    }
                }
            }

            if ($version < 1_000_607 && $self->session) {

                # This version updates all tasks with a new IV, and removes another IV
                foreach my $taskObj ($self->compileTasks()) {

                    if (! exists $taskObj->{winUpdateFunc}) {

                        $taskObj->{winUpdateFunc} = undef;

                        if ($taskObj->{name} eq 'compass_task') {
                            $taskObj->ivPoke('winUpdateFunc', 'createWidgets');
                        } elsif ($taskObj->{name} eq 'divert_task') {
                            $taskObj->ivPoke('winUpdateFunc', 'restoreWin');
                        } elsif ($taskObj->{name} eq 'locator_task') {
                            $taskObj->ivPoke('winUpdateFunc', 'updateWin');
                        } elsif ($taskObj->{name} eq 'status_task') {
                            $taskObj->ivPoke('winUpdateFunc', 'updateWin');
                        } else {
                            $taskObj->ivUndef('winUpdateFunc');
                        }

                        delete $taskObj->{winOpenFlag};
                    }
                }
            }

            if ($version < 1_000_608 && $self->session) {

                # This version updated the Divert task with a new IV. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('divert_task')) {

                    if (! exists $taskObj->{lineList}) {

                        $taskObj->{lineList} = [];
                        $taskObj->ivEmpty('lineList');
                    }
                }
            }

            if ($version < 1_000_618 && $self->session) {

                # This version updates all tasks with new IVs
                foreach my $taskObj ($self->compileTasks()) {

                    if (! exists $taskObj->{ttsFlag}) {

                        $taskObj->{ttsFlag} = undef;

                        if (
                            $taskObj->{name} eq 'attack_task'
                            || $taskObj->{name} eq 'chat_task'
                            || $taskObj->{name} eq 'divert_task'
                            || $taskObj->{name} eq 'locator_task'
                            || $taskObj->{name} eq 'status_task'
                            || $taskObj->{name} eq 'watch_task'
                        ) {
                            $taskObj->ivPoke('ttsFlag', TRUE);
                        } else {
                            $taskObj->ivPoke('ttsFlag', FALSE);
                        }

                        $taskObj->{ttsProfile} = undef;
                        $taskObj->ivUndef('ttsProfile');

                        $taskObj->{ttsAttribHash} = {};
                        $taskObj->{ttsFlagAttribHash} = {};
                        $taskObj->{ttsAlertAttribHash} = {};

                        if ($taskObj->{name} eq 'attack_task') {

                            $taskObj->ivEmpty('ttsAttribHash');

                            $taskObj->ivPoke(
                                'ttsFlagAttribHash',
                                    'fight', FALSE,
                                    'interact', FALSE,
                                    'interaction', FALSE,
                            );

                            $taskObj->ivEmpty('ttsAlertAttribHash');

                        } elsif ($taskObj->{name} eq 'chat_task') {

                            $taskObj->ivEmpty('ttsAttribHash');

                            $taskObj->ivPoke(
                                'ttsFlagAttribHash',
                                    'chat', FALSE,
                                    'chatout', FALSE,
                                    'chatin', FALSE,
                                    'chatecho', FALSE,
                                    'chatsystem', FALSE,
                                    'chatremote', FALSE,
                                    'chatsnoop', FALSE,
                            );

                            $taskObj->ivEmpty('ttsAlertAttribHash');

                        } elsif ($taskObj->{name} eq 'divert_task') {

                            $taskObj->ivEmpty('ttsAttribHash');

                            $taskObj->ivPoke(
                                'ttsFlagAttribHash',
                                    'divert', FALSE,
                                    'tell', FALSE,
                                    'social', FALSE,
                                    'custom', FALSE,
                                    'warning', FALSE,
                            );

                            $taskObj->ivEmpty('ttsAlertAttribHash');

                        } elsif ($taskObj->{name} eq 'locator_task') {

                            $taskObj->ivPoke(
                                'ttsAttribHash',
                                    'title', undef,
                                    'descrip', undef,
                                    'description', undef,
                                    'exit', undef,
                                    'exits', undef,
                                    'content', undef,
                                    'contents', undef,
                            );

                            $taskObj->ivPoke(
                                'ttsFlagAttribHash',
                                    'title', FALSE,
                                    'descrip', FALSE,
                                    'description', FALSE,
                                    'exit', FALSE,
                                    'exits', FALSE,
                                    'content', FALSE,
                                    'contents', FALSE,
                            );

                            $taskObj->ivEmpty('ttsAlertAttribHash');

                        } elsif ($taskObj->{name} eq 'status_task') {

                            $taskObj->ivPoke(
                                'ttsAttribHash',
                                    'status' => undef,
                                    'life' => undef,
                                    'lives' => undef,
                                    'health' => undef,
                                    'magic' => undef,
                                    'energy' => undef,
                                    'guild' => undef,
                                    'social' => undef,
                                    'xp' => undef,
                                    'experience' => undef,
                                    'level' => undef,
                                    'align' => undef,
                                    'alignment' => undef,
                                    'age' => undef,
                                    'time' => undef,
                                    'bank' => undef,
                                    'purse' => undef,
                            );

                            $taskObj->ivPoke(
                                'ttsFlagAttribHash',
                                    'life' => FALSE,
                            );

                            $taskObj->ivPoke(
                                'ttsAlertAttribHash',
                                    'healthup', undef,
                                    'healthdown', undef,
                                    'magicup', undef,
                                    'magicdown', undef,
                                    'energyup', undef,
                                    'energydown', undef,
                                    'guildup', undef,
                                    'guilddown', undef,
                                    'socialup', undef,
                                    'socialdown', undef,
                            );

                        } elsif ($taskObj->{name} eq 'watch_task') {

                            $taskObj->ivEmpty('ttsAttribHash');

                            $taskObj->ivPoke(
                                'ttsFlagAttribHash',
                                    'watch', FALSE,
                            );

                            $taskObj->ivEmpty('ttsAlertAttribHash');

                        } else {

                            $taskObj->ivEmpty('ttsAttribHash');
                            $taskObj->ivEmpty('ttsFlagAttribHash');
                            $taskObj->ivEmpty('ttsAlertAttribHash');
                        }
                    }
                }
            }

            if ($version < 1_000_619 && $self->session) {

                # This version updates all tasks with a new flag IV. Its value is set to TRUE for
                #   the Divert, Script and Watch tasks, FALSE for everything else
                my %trueHash = (
                    'divert_task'       => undef,
                    'script_task'       => undef,
                    'watch_task'        => undef,
                );

                foreach my $taskObj ($self->compileTasks()) {

                    if (! exists $taskObj->{allowLinkFlag}) {

                        $taskObj->{allowLinkFlag} = undef;

                        if (exists $trueHash{$taskObj->{name}}) {
                            $taskObj->{allowLinkFlag} = TRUE;
                        } else {
                            $taskObj->{allowLinkFlag} = FALSE;
                        }
                    }
                }
            }

            if ($version < 1_000_684 && $self->session) {

                # This version updated the Status task with new IVs. Update all initial/custom
                #   tasks
                my %varHash = (
                    'health_points'         => 'healthPoints',
                    'health_points_max'     => 'healthPointsMax',
                    'magic_points'          => 'magicPoints',
                    'magic_points_max'      => 'magicPointsMax',
                    'energy_points'         => 'energyPoints',
                    'energy_points_max'     => 'energyPointsMax',
                    'guild_points'          => 'guildPoints',
                    'guild_points_max'      => 'guildPointsMax',
                    'social_points'         => 'socialPoints',
                    'social_points_max'     => 'socialPointsMax',
                    'xp_current'            => 'xpCurrent',
                    'xp_next_level'         => 'xpNextLevel',
                    'xp_total'              => 'xpTotal',
                    'quest_points'          => 'questPointCount',
                    'quest_points_max'      => 'worldQuestPointCount',
                    'quest_count'           => 'questCount',
                    'quest_count_max'       => 'worldQuestCount',
                    'level'                 => 'level',
                    'life_count'            => 'lifeCount',
                    'death_count'           => 'deathCount',
                    'life_max'              => 'lifeMax',
                    'local_wimpy'           => 'localWimpy',
                    'remote_wimpy'          => 'remoteWimpy',
                    'remote_wimpy_max'      => 'remoteWimpyMax',
                    'local_wimpy_max'       => '_localWimpyMax',
                    'bank_balance'          => 'bankBalance',
                    'purse_contents'        => 'purseContents',
                    'opp_health'            => 'oppHealth',
                    'opp_health_max'        => 'oppHealthMax',
                    'opp_level'             => 'oppLevel',
                    'opp_strength'          => 'oppStrength',
                );

                my @varList = (
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
                );

                foreach my $taskObj ($self->compileTasks('status_task')) {

                    if (! exists $taskObj->{singleBackRefVarHash}) {

                        $taskObj->{singleBackRefVarHash} = {};
                        $taskObj->ivPoke('singleBackRefVarHash', %varHash);

                        $taskObj->{gaugeFlag} = undef;
                        $taskObj->ivPoke('gaugeFlag', FALSE);
                        $taskObj->{gaugeValueFlag} = undef;
                        $taskObj->ivPoke('gaugeValueFlag', TRUE);

                        $taskObj->{defaultGaugeFormatList} = [];
                        $taskObj->ivPoke('defaultGaugeFormatList', @varList);
                        $taskObj->{gaugeObjList} = [];
                        $taskObj->ivEmpty('gaugeObjList');
                    }
                }
            }

            if ($version < 1_000_689 && $self->session) {

                # This version updated the Status task with a new IV. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('status_task')) {

                    if (! exists $taskObj->{gaugeResetFlag}) {

                        $taskObj->{gaugeResetFlag} = undef;
                        $taskObj->ivPoke('gaugeResetFlag', FALSE);
                    }
                }
            }

            if ($version < 1_000_691 && $self->session) {

                # This version switched the order of some IVs in the Status. Update all initial/
                #   custom tasks
                foreach my $taskObj ($self->compileTasks('status_task')) {

                    my $string;

                    $string = $taskObj->ivIndex('defaultFormatList', 1);

                    # (No reason why any of these conditions should fail; these IVs aren't
                    #   supposed to be altered)
                    if ($string =~ m/^HP\: \@health_points\@.*\(\@social_points_max\@\)$/) {

                        $taskObj->ivReplace(
                            'defaultFormatList',
                            1,
                            'HP: @health_points@ (@health_points_max@) MP: @magic_points@'
                            . ' (@magic_points_max@) EP: @energy_points@ (@energy_points_max@)'
                            . ' GP: @guild_points@ (@guild_points_max@) SP: @social_points@'
                            . ' (@social_points_max@)',
                        );
                    }

                    if (
                        $taskObj->ivIndex('displayVarList', 4) eq 'health_points'
                        && $taskObj->ivIndex('displayVarList', 6) eq 'energy_points'
                    ) {
                        $taskObj->ivReplace('displayVarList', 6, 'magic_points');
                        $taskObj->ivReplace('displayVarList', 7, 'magic_points_max');
                        $taskObj->ivReplace('displayVarList', 8, 'energy_points');
                        $taskObj->ivReplace('displayVarList', 9, 'energy_points_max');
                    }

                    if (
                        $taskObj->ivIndex('singleBackRefVarList', 2) eq 'energy_points'
                        && $taskObj->ivIndex('singleBackRefVarList', 4) eq 'magic_points'
                    ) {
                        $taskObj->ivReplace('singleBackRefVarList', 2, 'magic_points');
                        $taskObj->ivReplace('singleBackRefVarList', 3, 'magic_points_max');
                        $taskObj->ivReplace('singleBackRefVarList', 4, 'energy_points');
                        $taskObj->ivReplace('singleBackRefVarList', 5, 'energy_points_max');
                    }
                }
            }

            if ($version < 1_000_692 && $self->session) {

                # This version updated the Status task with a new IV. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('status_task')) {

                    if (! exists $taskObj->{gaugeLevel}) {

                        $taskObj->{gaugeLevel} = undef;
                        $taskObj->ivUndef('gaugeLevel');
                    }
                }
            }

            if ($version < 1_000_693 && $self->session) {

                # This version updated the Script task with new IVs. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('script_task')) {

                    if (! exists $taskObj->{gaugeLevel}) {

                        $taskObj->{gaugeLevel} = undef;
                        $taskObj->ivUndef('gaugeLevel');
                        $taskObj->{gaugeHash} = {};
                        $taskObj->ivEmpty('gaugeHash');
                    }
                }
            }

            if ($version < 1_000_700 && $self->session) {

                # This version updated the Script task with a new IV. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('script_task')) {

                    if (! exists $taskObj->{statusBarHash}) {

                        $taskObj->{statusBarHash} = {};
                        $taskObj->ivEmpty('statusBarHash');
                    }
                }
            }

            if ($version < 1_000_800 && $self->session) {

                # This version updates all tasks, modifying some IVs and adding/removing others.
                #   Update all initial/custom tasks
                foreach my $taskObj ($self->compileTasks()) {

                    if (exists $taskObj->{allowLinkFlag}) {

                        $taskObj->{defaultTabObj} = undef;
                        $taskObj->{tableObj} = undef;
                        $taskObj->{taskWinFlag} = FALSE;
                        $taskObj->{taskWinEntryFlag} = FALSE;

                        $taskObj->{winPreferList} = [];
                        if (
                            $taskObj->{name} eq 'compass_task' || $taskObj->{name} eq 'notepad_task'
                            || $taskObj->{name} eq 'script_task'
                        ) {
                            $taskObj->{winPreferList} = ['pseudo', 'grid'];
                        } elsif (
                            $taskObj->{name} eq 'debugger_task'
                            || $taskObj->{name} eq 'inventory_task'
                            || $taskObj->{name} eq 'locator'
                            || $taskObj->{name} eq 'raw_text_task'
                            || $taskObj->{name} eq 'raw_token_task'
                            || $taskObj->{name} eq 'status_task'
                            || $taskObj->{name} eq 'tasklist_task'
                            || $taskObj->{name} eq 'watch_task'
                        ) {
                            $taskObj->{winPreferList} = ['pane', 'grid'];
                        } elsif (
                            $taskObj->{name} eq 'divert_task' || $taskObj->{name} eq 'chat_task'
                        ) {
                            $taskObj->{winPreferList} = ['entry', 'grid'];
                        }

                        delete $taskObj->{allowLinkFlag};
                        delete $taskObj->{settingsHash};

                        $taskObj->{monochromeFlag} = $taskObj->{ownColourSchemeFlag};
                        delete $taskObj->{ownColourSchemeFlag};

                        if ($taskObj->{winType} eq 'text') {
                            $taskObj->{winmap} = 'basic_fill';
                        } elsif ($taskObj->{winType} eq 'entry') {
                            $taskObj->{winmap} = 'entry_fill';
                        } elsif ($taskObj->{winType} eq 'graphics') {
                            $taskObj->{winmap} = 'basic_empty';
                        }

                        delete $taskObj->{winType};
                    }
                }

                # This version renames IVs in the Compass task
                foreach my $taskObj ($self->compileTasks('compass_task')) {

                    my $hashRef;

                    if (exists $taskObj->{radioButton}) {

                        $taskObj->{radioTableObj} = undef;
                        $taskObj->{radioTableObj2} = undef;
                        $taskObj->{comboTableObj} = undef;

                        delete $taskObj->{radioButton};
                        delete $taskObj->{radioButton2};
                        delete $taskObj->{comboBox};

                        # Also modify the contents of one of the constant hashes, so it doesn't
                        #   cause a pango error
                        $hashRef = $taskObj->{keypadHintHash};
                        $$hashRef{'kp_enter'} = 'ENTER key';
                        $taskObj->{radioTableObj} = $hashRef;
                    }
                }

                # This version updates IVs in the Debugger task
                foreach my $taskObj ($self->compileTasks('debugger_task')) {

                    if ($taskObj->{errorMode} == 0) {
                        $taskObj->{errorMode} = 'original';
                    } elsif ($taskObj->{errorMode} == 1) {
                        $taskObj->{errorMode} = 'both';
                    } elsif ($taskObj->{errorMode} == 2) {
                        $taskObj->{errorMode} = 'task';
                    }

                    if ($taskObj->{warningMode} == 0) {
                        $taskObj->{warningMode} = 'original';
                    } elsif ($taskObj->{warningMode} == 1) {
                        $taskObj->{warningMode} = 'both';
                    } elsif ($taskObj->{warningMode} == 2) {
                        $taskObj->{warningMode} = 'task';
                    }

                    if ($taskObj->{debugMode} == 0) {
                        $taskObj->{debugMode} = 'original';
                    } elsif ($taskObj->{debugMode} == 1) {
                        $taskObj->{debugMode} = 'both';
                    } elsif ($taskObj->{debugMode} == 2) {
                        $taskObj->{debugMode} = 'task';
                    }

                    if ($taskObj->{improperMode} == 0) {
                        $taskObj->{improperMode} = 'original';
                    } elsif ($taskObj->{improperMode} == 1) {
                        $taskObj->{improperMode} = 'both';
                    } elsif ($taskObj->{improperMode} == 2) {
                        $taskObj->{improperMode} = 'task';
                    }
                }

                # This version renames an IV in the Inventory task
                foreach my $taskObj ($self->compileTasks('inventory_task')) {

                    if (exists $taskObj->{updateWinflag}) {

                        $taskObj->{refreshWinFlag} = $taskObj->{updateWinFlag};
                        delete $taskObj->{updateWinFlag};
                    }
                }

                # This version renames IVs in the Notepad task (and removes one, too)
                foreach my $taskObj ($self->compileTasks('notepad_task')) {

                    if (exists $taskObj->{textView}) {

                        $taskObj->{textTableObj} = undef;
                        $taskObj->{comboTableObj} = undef;

                        delete $taskObj->{textView};
                        delete $taskObj->{buffer};
                        delete $taskObj->{comboBox};
                    }
                }

                # This function updates IVs in the Locator and Status tasks
                foreach my $taskObj ($self->compileTasks('locator_task')) {

                    $taskObj->{winUpdateFunc} = 'refreshWin';
                }

                foreach my $taskObj ($self->compileTasks('status_task')) {

                    $taskObj->{winUpdateFunc} = 'refreshWin';
                    $taskObj->{gaugeStripObj} = undef;
                }
            }

            if ($version < 1_000_813 && $self->session) {

                # This version removes an IV from all tasks. Update all initial/custom tasks
                foreach my $taskObj ($self->compileTasks()) {

                    if (exists $taskObj->{statusTypeHash}) {

                        delete $taskObj->{statusTypeHash};
                    }
                }
            }

            if ($version < 1_000_840 && $self->session) {

                # This version removes some IVs from the Locator task. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('locator_task')) {

                    if (exists $taskObj->{useMxpFlag}) {

                        $taskObj->{useMxpFlag} = undef;
                        $taskObj->ivFalse('useMxpFlag');

                        $taskObj->{mxpPropHash} = {};
                        $taskObj->ivPoke(
                            'mxpPropHash',
                                'RoomName'      => undef,
                                'RoomDesc'      => undef,
                                'RoomExit'      => undef,
                                'RoomNum'       => undef,
                        );
                    }
                }
            }

            if ($version < 1_000_841 && $self->session) {

                # This version removes an IV from all tasks
                foreach my $taskObj ($self->compileTasks()) {

                    if (exists $taskObj->{msdpRoomHash}) {

                        delete $taskObj->{msdpRoomHash};
                        delete $taskObj->{msdpExitHash};
                    }
                }
            }

            if ($version < 1_000_879 && $self->session) {

                # This version removes an IV from the Status task
                foreach my $taskObj ($self->compileTasks('status_task')) {

                    if (! exists $taskObj->{defaultGaugeFormatList}) {

                        delete $taskObj->{defaultGaugeFormatList};
                    }
                }
            }

            if ($version < 1_000_904 && $self->session) {

                # This version adds an IV to all tasks. Update all initial/custom tasks
                foreach my $taskObj ($self->compileTasks()) {

                    if (! exists $taskObj->{hasResetFlag}) {

                        $taskObj->{hasResetFlag} = undef;
                        $taskObj->ivUndef('hasResetFlag');
                    }
                }
            }

            if ($version < 1_000_909) {

                # This version converts some numerical mode values to string mode values
                foreach my $taskObj ($self->compileTasks('advance_task')) {

                    if ($taskObj->advanceMode eq '0') {
                        $taskObj->ivPoke('advanceMode', 'named_skill');
                    } elsif ($taskObj->advanceMode eq '1') {
                        $taskObj->ivPoke('advanceMode', 'order_list');
                    } elsif ($taskObj->advanceMode eq '2') {
                        $taskObj->ivPoke('advanceMode', 'cycle_list');
                    }
                }

                foreach my $taskObj ($self->compileTasks('chat_task')) {

                    if ($taskObj->entryMode eq '0') {
                        $taskObj->ivPoke('entryMode', 'chat');
                    } elsif ($taskObj->entryMode eq '1') {
                        $taskObj->ivPoke('entryMode', 'emote');
                    } elsif ($taskObj->entryMode eq '2') {
                        $taskObj->ivPoke('entryMode', 'cmd');
                    }
                }

                foreach my $taskObj ($self->compileTasks('locator_task')) {

                    if ($taskObj->autoLookMode eq '0') {
                        $taskObj->ivPoke('autoLookMode', 'do_nothing');
                    } elsif ($taskObj->autoLookMode eq '1') {
                        $taskObj->ivPoke('autoLookMode', 'search_back');
                    } elsif ($taskObj->autoLookMode eq '2') {
                        $taskObj->ivPoke('autoLookMode', 'send_look');
                    }
                }

                foreach my $taskObj ($self->compileTasks('status_task')) {

                    if ($taskObj->commifyMode eq '0') {
                        $taskObj->ivPoke('commifyMode', 'none');
                    } elsif ($taskObj->commifyMode eq '1') {
                        $taskObj->ivPoke('commifyMode', 'use_comma');
                    } elsif ($taskObj->commifyMode eq '2') {
                        $taskObj->ivPoke('commifyMode', 'use_europe');
                    } elsif ($taskObj->commifyMode eq '3') {
                        $taskObj->ivPoke('commifyMode', 'use_brit');
                    } elsif ($taskObj->commifyMode eq '4') {
                        $taskObj->ivPoke('commifyMode', 'use_underline');
                    }
                }
            }

            if ($version < 1_000_922 && $self->session) {

                # This version renames an IV in the Status task
                foreach my $taskObj ($self->compileTasks('status_task')) {

                    if (exists $taskObj->{_localWimpyMax}) {

                        $taskObj->{constLocalWimpyMax} = $taskObj->{_localWimpyMax};
                        delete $taskObj->{_localWimpyMax};

                        # (This line makes sure the correct file object's ->modifyFlag is set)
                        $taskObj->ivPoke('category', $taskObj->category);
                    }
                }
            }

            if ($version < 1_000_923 && $self->session) {

                # This version renames an IV in the Chat task
                foreach my $taskObj ($self->compileTasks('chat_task')) {

                    if (exists $taskObj->{constantHash}) {

                        $taskObj->{constOptHash} = $taskObj->{constantHash};
                        delete $taskObj->{constantHash};

                        # (This line makes sure the correct file object's ->modifyFlag is set)
                        $taskObj->ivPoke('category', $taskObj->category);
                    }
                }
            }

            if ($version < 1_000_924 && $self->session) {

                # This version renames an IV in the Locator task
                foreach my $taskObj ($self->compileTasks('locator_task')) {

                    if (exists $taskObj->{oldRoomObj}) {

                        $taskObj->{prevRoomObj} = undef;
                        $taskObj->ivPoke('prevRoomObj', $taskObj->{oldRoomObj});

                        delete $taskObj->{oldRoomObj};
                    }
                }
            }

            if ($version < 1_000_928 && $self->session) {

                # This version replaces an IV in the Launch task
                foreach my $taskObj ($self->compileTasks('launch_task')) {

                    if (exists $taskObj->{simpleList}) {

                        $taskObj->{slTableObj} = undef;
                        $taskObj->ivPoke('slTableObj', undef);

                        delete $taskObj->{simpleList};
                    }
                }
            }
        }

        ### scripts ###############################################################################

        if ($self->fileType eq 'scripts') {

            if ($version < 1_000_909) {

                # This version converts some numerical mode values to string mode values

                my %initScriptHash = $axmud::CLIENT->initScriptHash;

                foreach my $key (keys %initScriptHash) {

                    my $value = $initScriptHash{$key};

                    if ($value eq '0') {
                        $initScriptHash{$key} = 'no_task';
                    } elsif ($value eq '1') {
                        $initScriptHash{$key} = 'run_task';
                    } elsif ($value eq '2') {
                        $initScriptHash{$key} = 'run_task_win';
                    }
                }

                $axmud::CLIENT->ivPoke('initScriptHash', %initScriptHash);
            }

        ### contacts ##############################################################################

        } elsif ($self->fileType eq 'contacts') {

            if ($version < 1_000_909) {

                # This version converts some numerical mode values to string mode values
                if ($axmud::CLIENT->chatAcceptMode eq '0') {
                    $axmud::CLIENT->ivPoke('chatAcceptMode', 'prompt');
                } elsif ($axmud::CLIENT->chatAcceptMode eq '1') {
                    $axmud::CLIENT->ivPoke('chatAcceptMode', 'accept_contact');
                } elsif ($axmud::CLIENT->chatAcceptMode eq '2') {
                    $axmud::CLIENT->ivPoke('chatAcceptMode', 'accept_all');
                }
            }

        ### keycodes #############################################################################

        } elsif ($self->fileType eq 'keycodes') {

            if ($version < 1_000_337) {

                # This version adds an Axmud keycode for the tab key
                foreach my $keycodeObj ($axmud::CLIENT->ivValues('keycodeObjHash')) {

                    if (! $axmud::CLIENT->ivExists('constKeycodeHash', 'tab')) {

                        $keycodeObj->ivAdd('keycodeHash', 'tab', 'Tab');
                        $keycodeObj->setReverseHash();
                    }
                }
            }

            if ($version < 1_000_815) {

                # This version removes several IVs (moved to GA::Client)
                foreach my $keycodeObj ($axmud::CLIENT->ivValues('keycodeObjHash')) {

                    if (exists $keycodeObj->{constKeycodeHash}) {

                        delete $keycodeObj->{constKeycodeHash};
                        delete $keycodeObj->{altKeycodeHash};
                        delete $keycodeObj->{keycodeList};

                        # (This line makes sure the correct file object's ->modifyFlag is set)
                        $keycodeObj->ivPoke('name', $keycodeObj->name);
                    }
                }
            }
        ### dicts #################################################################################

        } elsif ($self->fileType eq 'dicts') {

            if ($version < 1_000_037) {

                foreach my $dictObj ($axmud::CLIENT->ivValues('dictHash')) {

                    # Add 'portal' as a new type of decoration, if it's not already there
                    if (! defined $dictObj->ivMatch('constDecorationTypeList', 'portal')) {

                        $dictObj->ivPush('constDecorationTypeList', 'portal');
                    }

                    if (! defined $dictObj->ivMatch('decorationTypeList', 'portal')) {

                        $dictObj->ivPush('decorationTypeList', 'portal');
                    }

                    # Add 'portal' to the decoration lists
                    if (! $dictObj->ivExists('decorationHash', 'portal')) {

                        $dictObj->ivAdd('decorationHash', 'portal', 'decoration');
                        $dictObj->ivAdd('decorationTypeHash', 'portal', 'portal');
                    }
                }
            }

            if ($version < 1_000_271) {

                # This version adds eight new primary directions. $self->session is not necessarily
                #   set, so we can't create a temporary dictionary and copy IVs to existing
                #   dictionaries; need to update IVs the hard way
                # (Unfortunately, non-English dictionaries will be updated with English words;
                #   hopefully only a tiny number of users will be affected)

                my (
                    @primaryDirList, @shortPrimaryDirList,
                    %shortPrimaryDirHash, %primaryAbbrevHash, %primaryOppHash,
                    %primaryOppAbbrevHash,
                );

                @primaryDirList = (
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
                );

                @shortPrimaryDirList = (
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
                );

                %shortPrimaryDirHash = (
                    'north'             => undef,
                    'northeast'         => undef,
                    'east'              => undef,
                    'southeast'         => undef,
                    'south'             => undef,
                    'southwest'         => undef,
                    'west'              => undef,
                    'northwest'         => undef,
                    'up'                => undef,
                    'down'              => undef,
                );

                %primaryAbbrevHash = (
                    northnortheast      => 'nne',               # Only new key-value pairs
                    eastnortheast       => 'ene',
                    eastsoutheast       => 'ese',
                    southsoutheast      => 'sse',
                    southsouthwest      => 'ssw',
                    westsouthwest       => 'wsw',
                    westnorthwest       => 'wnw',
                    northnorthwest      => 'nnw',
                );

                %primaryOppHash = (
                    northnortheast      => 'southsouthwest',    # Only new key-value pairs
                    eastnortheast       => 'westsouthwest',
                    eastsoutheast       => 'westnorthwest',
                    southsoutheast      => 'northnorthwest',
                    southsouthwest      => 'northnortheast',
                    westsouthwest       => 'eastnortheast',
                    westnorthwest       => 'eastsoutheast',
                    northnorthwest      => 'southsoutheast',
                );

                %primaryOppAbbrevHash = (
                    northnortheast      => 'ssw',
                    eastnortheast       => 'wsw',
                    eastsoutheast       => 'wnw',
                    southsoutheast      => 'nnw',
                    southsouthwest      => 'nne',
                    westsouthwest       => 'ene',
                    westnorthwest       => 'ese',
                    northnorthwest      => 'sse',
                );

                foreach my $dictObj ($axmud::CLIENT->ivValues('dictHash')) {

                    if (! $dictObj->ivExists('primaryDirHash', 'northnortheast')) {

                        # Update this dictionary's IVs
                        $dictObj->ivPoke('primaryDirList', @primaryDirList);
                        $dictObj->{shortPrimaryDirList} = [];
                        $dictObj->ivPoke('shortPrimaryDirList', @shortPrimaryDirList);
                        $dictObj->{shortPrimaryDirHash} = {};
                        $dictObj->ivPoke('shortPrimaryDirHash', %shortPrimaryDirHash);

                        foreach my $dir (@primaryDirList) {

                            if (! exists $shortPrimaryDirHash{$dir}) {

                                $dictObj->ivAdd(
                                    'primaryDirHash',
                                    $dir,   # Standard and custom dirs are initially the same
                                    $dir,
                                );
                            }
                        }

                        foreach my $key (keys %primaryAbbrevHash) {

                            $dictObj->ivAdd('primaryAbbrevHash', $key, $primaryAbbrevHash{$key});
                        }

                        foreach my $key (keys %primaryOppHash) {

                            $dictObj->ivAdd('primaryOppHash', $key, $primaryOppHash{$key});
                        }

                        foreach my $key (keys %primaryOppAbbrevHash) {

                            $dictObj->ivAdd(
                                'primaryOppAbbrevHash',
                                $key,
                                $primaryOppAbbrevHash{$key},
                            );
                        }

                        # We also have to update the combined hashes the hard way
                        foreach my $key (keys %primaryAbbrevHash) {

                            # Standard and custom dirs are initially the same
                            $dictObj->ivAdd('combDirHash', $key, 'primaryDir');
                        }

                        foreach my $value (values %primaryAbbrevHash) {

                            # Standard and custom dirs are initially the same
                            $dictObj->ivAdd('combDirHash', $value, 'primaryAbbrev');
                        }

                        foreach my $key (keys %primaryOppHash) {

                            # Standard and custom dirs are initially the same
                            $dictObj->ivAdd('combOppDirHash', $key, $primaryOppHash{$key});
                        }

                        foreach my $key (keys %primaryAbbrevHash) {

                            # Standard and custom dirs are initially the same
                            $dictObj->ivAdd('combRevDirHash', $key, $key);
                        }
                    }
                }
            }

            if ($version < 1_000_275) {

                foreach my $dictObj ($axmud::CLIENT->ivValues('dictHash')) {

                    # Update this dictionary's IVs
                    $dictObj->{secondaryAutoHash} = {};
                    # Create a key-value pair for every existing secondary direction
                    foreach my $dir ($dictObj->ivKeys('secondaryDirHash')) {

                        $dictObj->ivAdd('secondaryAutoHash', $dir, undef);
                    }
                }
            }

            if ($version < 1_000_278) {

                foreach my $dictObj ($axmud::CLIENT->ivValues('dictHash')) {

                    # Update this dictionary's IVs
                    $dictObj->{secondaryAbbrevHash} = {};
                    $dictObj->{secondaryOppAbbrevHash} = {};
                    # Create a key-value pair for every existing secondary direction
                    foreach my $dir ($dictObj->ivKeys('secondaryDirHash')) {

                        $dictObj->ivAdd('secondaryAbbrevHash', $dir, undef);
                        $dictObj->ivAdd('secondaryOppAbbrevHash', $dir, '');
                    }
                }
            }

            if ($version < 1_000_582) {

                # Update dictionary with a new IV
                foreach my $dictObj ($axmud::CLIENT->ivValues('dictHash')) {

                    if (! exists $dictObj->{contentsLinesHash}) {

                        $dictObj->{contentsLinesHash} = {};
                        $dictObj->ivEmpty('contentsLinesHash');
                    }
                }

                # An error in ';addword' added key-value pairs with the wrong value. Here's the fix
                foreach my $dictObj ($axmud::CLIENT->ivValues('dictHash')) {

                    foreach my $key ($dictObj->ivKeys('adjHash')) {

                        my $value = $dictObj->ivShow('adjHash', $key);

                        if ($value ne 'adj') {

                            $dictObj->ivAdd('adjHash', $key, 'adj');
                        }
                    }
                }
            }

            if ($version < 1_000_897) {

                # Update dictionary by removing some IVs, which have moved to GA::Client
                foreach my $dictObj ($axmud::CLIENT->ivValues('dictHash')) {

                    if (exists $dictObj->{primaryDirList}) {

                        delete $dictObj->{primaryDirList};
                        delete $dictObj->{shortPrimaryDirList};
                        delete $dictObj->{shortPrimaryDirHash};

                        # (This line makes sure the correct file object's ->modifyFlag is set)
                        $dictObj->ivPoke('name', $dictObj->name);
                    }
                }
            }

            if ($version < 1_000_909) {

                # This version converts some numerical mode values to string mode values
                foreach my $dictObj ($axmud::CLIENT->ivValues('dictHash')) {

                    if ($dictObj->nounPosn eq '0') {
                        $dictObj->ivPoke('nounPosn', 'noun_adj');
                    } elsif ($dictObj->nounPosn eq '1') {
                        $dictObj->ivPoke('nounPosn', 'adj_noun');
                    }
                }
            }

            if ($version < 1_000_911) {

                # Update dictionary with some new IVs
                foreach my $dictObj ($axmud::CLIENT->ivValues('dictHash')) {

                    if (! exists $dictObj->{speedDirHash}) {

                        $dictObj->{speedDirHash} = {};
                        $dictObj->ivPoke(
                            'speedDirHash',
                                'n' => 'north',
                                's' => 'south',
                                'e' => 'east',
                                'w' => 'west',
                                'u' => 'up',
                                'd' => 'down',
                                'l' => 'look',
                                't' => 'northwest',
                                'y' => 'northeast',
                                'g' => 'southwest',
                                'h' => 'southeast',
                        );

                        $dictObj->{speedModifierHash} = {};
                        $dictObj->ivPoke(
                            'speedModifierHash',
                                # Movement commands
                                'G' => 'go_dir',
                                'N' => 'run',
                                'A' => 'walk',
                                'F' => 'fly',
                                'W' => 'swim',
                                'V' => 'dive',
                                'S' => 'sail',
                                'I' => 'ride',
                                'D' => 'drive',
                                'R' => 'creep',
                                'E' => 'sneak',
                                'Q' => 'squeeze',
                                # Non-movement commands
                                'O' => 'open_dir',
                                'C' => 'close_dir',
                                'K' => 'unlock',
                                'L' => 'lock',
                                'P' => 'pick',
                                'B' => 'break',
                        );
                    }
                }
            }

        ### toolbar ###############################################################################

        } elsif ($self->fileType eq 'toolbar') {

            if ($version < 1_000_927) {

                my (
                    @buttonList,
                    %buttonHash,
                );

                # This version renames one of the toolbar buttons, because of clashes with
                #   GA::Client->constReservedHash
                foreach my $buttonObj ($axmud::CLIENT->ivValues('toolbarHash')) {

                    if ($buttonObj->name eq 'connect') {
                        $buttonObj->ivPoke('name', 'connect_me');
                    } elsif ($buttonObj->name eq 'help') {
                        $buttonObj->ivPoke('name', 'help_me');
                    } elsif ($buttonObj->name eq 'login') {
                        $buttonObj->ivPoke('name', 'login_me');
                    } elsif ($buttonObj->name eq 'save') {
                        $buttonObj->ivPoke('name', 'save_me');
                    }

                    $buttonHash{$buttonObj->name} = $buttonObj;
                }

                foreach my $name ($axmud::CLIENT->toolbarList) {

                    if ($name eq 'connect') {
                        push (@buttonList, 'connect_me');
                    } elsif ($name eq 'help') {
                        push (@buttonList, 'help_me');
                    } elsif ($name eq 'login') {
                        push (@buttonList, 'login_me');
                    } elsif ($name eq 'save') {
                        push (@buttonList, 'save_me');
                    } else {
                        push (@buttonList, $name);
                    }
                }

                $axmud::CLIENT->ivPoke('toolbarHash', %buttonHash);
                $axmud::CLIENT->ivPoke('toolbarList', @buttonList);
            }

        ## zonemap ################################################################################

        } elsif ($self->fileType eq 'zonemaps') {

            if ($version < 1_000_653) {

                # This version adds new IVs to zonemaps
                foreach my $zonemapObj ($axmud::CLIENT->ivValues('zonemapHash')) {

                    if (! exists $zonemapObj->{tempFlag}) {

                        $zonemapObj->{tempFlag} = undef;
                        $zonemapObj->ivFalse('tempFlag');
                        $zonemapObj->{tempSession} = undef;
                        $zonemapObj->ivUndef('tempSession');
                    }
                }
            }

            if ($version < 1_000_800) {

                # This version modifies several zonemap and zone model IVs
                foreach my $zonemapObj ($axmud::CLIENT->ivValues('zonemapHash')) {

                    my (%oldReservedHash, %newReservedHash, %newModelHash);

                    if (exists $zonemapObj->{_zonemap}) {

                        delete $zonemapObj->{_zonemap};

                        $zonemapObj->{modelCount} = $zonemapObj->{zoneModelCount};
                        delete $zonemapObj->{zoneModelCount};

                        $zonemapObj->{gridSize} = 60;

                        foreach my $modelObj ($zonemapObj->ivValues('zoneModelHash')) {

                            $modelObj->{left} = $modelObj->{zonemapLeft};
                            delete $modelObj->{zonemapLeft};

                            $modelObj->{top} = $modelObj->{zonemapTop};
                            delete $modelObj->{zonemapTop};

                            $modelObj->{right} = $modelObj->{zonemapRight};
                            delete $modelObj->{zonemapRight};

                            $modelObj->{bottom} = $modelObj->{zonemapBottom};
                            delete $modelObj->{zonemapBottom};

                            $modelObj->{width} = $modelObj->{zonemapWidth};
                            delete $modelObj->{zonemapWidth};

                            $modelObj->{height} = $modelObj->{zonemapHeight};
                            delete $modelObj->{zonemapHeight};

                            $modelObj->{zonemapObj} = $modelObj->{parentZonemap};
                            delete $modelObj->{parentZonemap};

                            $modelObj->{areaMax} = $modelObj->{winMax};
                            delete $modelObj->{winMax};

                            $modelObj->{visibleAreaMax} = $modelObj->{winVisibleMax};
                            delete $modelObj->{winVisibleMax};

                            $modelObj->{defaultAreaWidth} = $modelObj->{defaultWinWidth};
                            delete $modelObj->{defaultWinWidth};

                            $modelObj->{defaultAreaHeight} = $modelObj->{defaultWinHeight};
                            delete $modelObj->{defaultWinHeight};

                            $modelObj->{reservedFlag} = $modelObj->{reservedZoneFlag};
                            delete $modelObj->{reservedZoneFlag};

                            # Values stored in ->reservedHash have changed
                            %oldReservedHash = $modelObj->reservedHash;
                            foreach my $name (keys %oldReservedHash) {

                                my $type = $oldReservedHash{$name};

                                if ($type eq 'main' || $type eq 'map' || $type eq 'external') {

                                    $newReservedHash{$name} = $type;

                                } else {

                                    $newReservedHash{$name} = 'custom';
                                }
                            }

                            $modelObj->{reservedHash} = \%newReservedHash;

                            $modelObj->{ownerString} = undef;
                            $modelObj->{defaultEnabledWinmap} = undef;
                            $modelObj->{defaultDisabledWinmap} = undef;
                            $modelObj->{defaultInternalWinmap} = undef;

                            $newModelHash{$modelObj->{number}} = $modelObj;
                        }

                        $zonemapObj->{modelHash} = \%newModelHash;
                        delete $zonemapObj->{zoneModelHash};
                    }
                }
            }
        }

        return 1;
    }

    sub checkCompatibility {

        # Called by $self->loadConfigFile, $self->loadDataFile and ->importDataFile
        # The data file's header states which programme created the data file. This function checks
        #   that the programme was either Axmud or something compatible with Axmud (specifically, an
        #   earlier version of it)
        #
        # Expected arguments
        #   $scriptName     - The name of the programme that created the data file
        #
        # Return values
        #   'undef' on improper arguments or if the data file is incompatible with Axmud
        #   1 if the data file is compatible with Axmud

        my ($self, $scriptName, $check) = @_;

        # Check for improper arguments
        if (! defined $scriptName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkCompatibility', @_);
        }

        OUTER: foreach my $item (@axmud::COMPAT_FILE_LIST) {

            if ($scriptName eq $item) {

                # Data file is compatible
                return 1;
            }
        }

        # Data file is not compatible
        return undef;
    }

    sub compileTasks {

        # Called by $self->updateExtractedData to compile a list of tasks of a certain type; the
        #   returned list includes tasks from all profile's initial tasklists as well as the global
        #   initial tasklist and the custom tasklist
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $name       - A task's ->name, e.g. 'locator_task'. If set to 'undef', all tasks are
        #                   included in the returned list
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns the list of matching initial/custom tasks

        my ($self, $name, $check) = @_;

        # Local variables
        my (@emptyList, @taskList);

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->compileTasks', @_);
            return @emptyList;
        }

        # Profile initial tasklists
        if ($self->session) {

            foreach my $profObj ($self->session->ivValues('profHash')) {

                foreach my $taskObj ($profObj->ivValues('initTaskHash')) {

                    if (! $name || $taskObj->{name} eq $name) {

                        push (@taskList, $taskObj);
                    }
                }
            }
        }

        # Global initial tasklist
        foreach my $taskObj ($axmud::CLIENT->ivValues('initTaskHash')) {

            if (! $name || $taskObj->{name} eq $name) {

                push (@taskList, $taskObj);
            }
        }

        # Custom tasklist
        foreach my $taskObj ($axmud::CLIENT->ivValues('customTaskHash')) {

            if (! $name || $taskObj->{name} eq $name) {

                push (@taskList, $taskObj);
            }
        }

        return @taskList;
    }

    sub examineDataFile {

        # Called by GA::Cmd::TestFile->do, or by any other function (this is a debug function)
        # Loads a specified file as if it were a genuine Axmud data file (but not a config file).
        #   Returns information about the file
        # NB This function works even when the global flags forbidding the loading or importing of
        #   files are set
        # NB This function works, even if the file's header specifies an older version of Axmud
        # NB Because the Perl Storable module doesn't seem to offer a way to check that the file
        #   really was created by it, this function now only tests .axm files
        #
        # Expected arguments
        #   $path       - The full path of the file to check
        #   $mode       - 'return_header' returns just the header information (metadata),
        #               - 'remove_values' returns the hash, with all the values in the key-value
        #                   pairs set to 'undef' (removing all the references)
        #               - 'return_key' returns the value of a single specified key (returns a hash
        #                   containing a single key-value pair)
        #               - 'return_hash' returns the entire contents of the file as the original hash
        #
        # Optional arguments
        #   $selectKey  - In mode 'return_key' - the key whose value should be returned (the value
        #                   will be a scalar, or a scalar reference)
        #
        # Return values
        #   An empty hash on improper arguments, if the file doesn't exist, if it is unreadable or
        #       if it is in the wrong format
        #   Otherwise, returns the hash specified above

        my ($self, $path, $mode, $selectKey, $check) = @_;

        # Local variables
        my (
            $matchFlag, $hashRef, $fileType, $scriptName, $scriptVersion, $saveDate, $saveTime,
            $assocWorldProf,
            %emptyHash, %loadHash, %returnHash,
        );

        # Check for improper arguments
        if (
            ! defined $path
            || ! defined $mode
            || (
                defined $mode && $mode ne 'return_header' && $mode ne 'remove_values'
                && $mode ne 'return_key' && $mode ne 'return_hash'
            )
            || ($mode eq 'return_key' && ! defined $selectKey)
            || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->importDataFile', @_);
            return %emptyHash;
        }

        # Check that the specified file exists
        if (! (-e $path)) {

            return %emptyHash;
        }

        # The Perl Storable module doesn't seem to offer a way to check that the file really was
        #   created by it. To avoid an ugly Perl error, limit operations to files with compatible
        #   extensions
        OUTER: foreach my $ext (@axmud::COMPAT_EXT_LIST) {

            if ($path =~ m/\.$ext$/) {

                $matchFlag = TRUE;
                last OUTER;
            }
        }

        if (! $matchFlag) {

            return %emptyHash;
        }

        # Load all the data into a hash
        eval { $hashRef = Storable::lock_retrieve($path); };
        if (! $hashRef) {

            # ->lock_retrieve() failed
            return %emptyHash;

        } else {

            # Convert the hash referenced by $hashRef into a named hash
            %loadHash = %{$hashRef};

            # Extract the header information (metadata) from the hash
            $fileType = $loadHash{'file_type'};
            $scriptName = $loadHash{'script_name'};
            $scriptVersion = $loadHash{'script_version'};
            $saveDate = $loadHash{'save_date'};
            $saveTime = $loadHash{'save_time'};

            # Before v1.0.868, Axmud used 'assoc_world_defn' rather than 'assoc_world_prof', and
            #   the file_types 'worldprof'/'otherprof' were 'worlddefn'/'otherdefn'
            if ($loadHash{'file_type'} eq 'worlddefn') {
                $loadHash{'file_type'} = 'worldprof';
            } elsif ($loadHash{'file_type'} eq 'otherdefn') {
                $loadHash{'file_type'} = 'otherprof';
            }

            if ($loadHash{'assoc_world_defn'}) {
                $assocWorldProf = $loadHash{'assoc_world_defn'};
            } else {
                $assocWorldProf = $loadHash{'assoc_world_prof'};
            }

            # Do basic checks on the header information
            if (
                ! defined $fileType || ! defined $scriptName || ! defined $scriptVersion
                || ! defined $saveDate || ! defined $saveTime
            ) {
                # Wrong kind of file, or missing (or possibly corrupted) header (NB $assocWorldProf
                #   is 'undef' for some types of file)
                return %emptyHash;
            }

            # 'return_header' - just return the header (metadata)
            if ($mode eq 'return_header') {

                $returnHash{'file_type'} = $fileType;
                $returnHash{'script_name'} = $scriptName;
                $returnHash{'script_version'} = $scriptVersion;
                $returnHash{'save_date'} = $saveDate;
                $returnHash{'save_time'} = $saveTime;
                $returnHash{'assoc_world_prof'} = $assocWorldProf;

                return %returnHash;

            # 'remove_values' - return all the keys in the hash, but not the values (set the values
            #   to 'undef')
            } elsif ($mode eq 'remove_values') {

                foreach my $key (keys %loadHash) {

                    $returnHash{$key} = undef;
                }

                return %returnHash;

            # 'return_key' - return the specified key
            } elsif ($mode eq 'return_key') {

                if (! exists $loadHash{$selectKey}) {

                    # Return an empty hash
                    return %emptyHash;

                } else {

                    # Return a hash containing the single key-value pair
                    $returnHash{$selectKey} = $loadHash{$selectKey};

                    return %returnHash;
                }

            # 'return_hash' - return the entire loaded hash
            } elsif ($mode eq 'return_hash') {

                return %loadHash;
            }
        }
    }

    sub disableSaveLoad {

        # Called by $self->loadConfigFile or $self->saveConfigFile whenever a call to File::close()
        #   returns false, or whenever there's an error reading/writing the config file
        # Sets some GA::Client flags to prevent other files from being loaded/saved
        #
        # Expected arguemnts
        #   $readFlag   - Set to FALSE when called because of File::open or File::close returning
        #                   'false', or if a lock can't be taken out or released on a semaphore
        #                   file; this disables loading/saving of all files
        #               - Set to TRUE when called because of an error reading the config file
        #                   ($self->saveConfigFile doesn't have its own non-fatal errors, so there
        #                   is no need to check for that)
        #
        # Return values
        #   'undef'

        my ($self, $readFlag, $check) = @_;

        # Check for improper arguments
        if (! defined $readFlag || defined $check) {

            return $axmud::CLIENT::writeImproper($self->_objClass . '->disableSaveLoad', @_);
        }

        # Set GA::Client flags
        if (! $readFlag) {

            $axmud::CLIENT->set_loadConfigFlag(FALSE);
        }

        $axmud::CLIENT->set_saveConfigFlag(FALSE);
        $axmud::CLIENT->set_loadDataFlag(FALSE);
        $axmud::CLIENT->set_saveDataFlag(FALSE);


        if (! $readFlag) {

            return $self->writeError(
                'OS failed to open/close file (possible buffering problem) - loading/saving of'
                . ' files disabled',
                $self->_objClass . '->disableSaveLoad',
            );

        } else {

            # $self->setupConfigFile displays an error message
            return undef;
        }
    }

    sub getFileLock {

        # Can be called by any file-writing or file-reading function within GA::Obj::File
        #   (currently only called by ->loadConfigFile and ->saveConfigFile)
        # Takes out a lock on the semaphore file $sempahoreFile twinned with the data file
        #   $dataFile, so that the file can be either open for reading by one or more instances
        #   of Axmud (and one or more sessions), or open for writing by a single instance of Axmud
        #   (or by a single session)
        # If the semaphore file doesn't exist yet, it is created
        #
        # Expected arguments
        #   $semaphoreFile  - The path to the semaphore file, e.g. '/home/myname/file.txt'
        #
        # Optional arguments
        #   $exclusiveFlag  - If set to TRUE, an exclusive lock is taken out (for writing to the
        #                       file).
        #                   - If set to FALSE (or 'undef'), a shared lock is taken out (for reading
        #                       from the file)
        #   $dataFile       - The path to the data file. If specified, the semaphore file is marked
        #                       with the data file's name
        #
        # Return values
        #   'undef' on improper arguments, or if the semaphore file can't be opened, or if a lock
        #       can't be taken out on it (at all)
        #   Otherwise returns the file handle of the locked semaphore file (required by
        #       $self->releaseFileLock)

        my ($self, $semaphoreFile, $exclusiveFlag, $dataFile, $check) = @_;

        # Local variables
        my $semaphoreHandle;

        # Check for improper arguments
        if (! defined $semaphoreFile || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getFileLock', @_);
        }

        # If the semaphore file doesn't yet exist (because the main file being saved is actually
        #   new), create the semaphore file
        if (! (-e $semaphoreFile)) {

            my @list;

            if (! open ($semaphoreHandle, ">$semaphoreFile")) {

                return undef;
            }

            if ($dataFile) {
                @list = ($axmud::SCRIPT . ' semaphore file for ' . $dataFile);
            } else {
                @list = ($axmud::SCRIPT . ' semaphore file');
            }

            print $semaphoreHandle @list;
            close $semaphoreHandle;
        }

        # Get a lock on the semaphore file
        if (! open ($semaphoreHandle, ">>$semaphoreFile")) {

            return undef;
        }

        if ($exclusiveFlag && ! flock ($semaphoreHandle, Fcntl::LOCK_EX)) {
            return undef;
        } elsif (! flock ($semaphoreHandle, Fcntl::LOCK_SH)) {
            return undef;
        }

        # Return the filehandle to the locked semaphore file
        return $semaphoreHandle;
    }

    sub releaseFileLock {

        # Can be called by any file-writing or file-reading function within GA::Obj::File
        #   (currently only called by ->loadConfigFile and ->saveConfigFile)
        # Releases a lock taken out on a semaphore file twinned with a data file
        #
        # Expected arguments
        #   $semaphoreHandle    - Opened handle of the semaphore file
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $semaphoreHandle, $check) = @_;

        # Check for improper arguments
        if (! defined $semaphoreHandle || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->releaseFileLock', @_);
        }

        # Release the lock by closing the open filehandle
        close $semaphoreHandle;

        return 1;
    }

    sub readMarker {

        # Called by $self->loadConfigFile
        # Reads lines from an opened config file until it finds one that doesn't begin with the
        #   comment marker #
        # That line should begin with the status marker @@@
        # Returns the text after the status marker @@@ as a two-element list
        #   e.g. for '@@@ date Mon Aug 8, 2011', returns the list ('date', 'Mon Aug 8, 2011')
        #   e.g. for '@@@ time 12:23:22' returns the list ('time', '12:23:22')
        #   e.g. for '@@@ eos' (meaning end of section), returns the list ('eos', undef)
        #   e.g. for '@@@ eof' (meaning end of file), returns the list ('eof', undef)
        #
        # Expected arguments
        #   $fileHandle - filehandle of the config file (opened for reading)
        #
        # Return values
        #   An empty list on improper arguments, if the file can't be read, the end of the file is
        #       reached, the line can't be read, the line doesn't begin with @@@ or the @@@ isn't
        #       followed by at least one character
        #   or the @@@ isn't followed by at least one character, returns 'undef'


        #   Otherwise, the list described above

        my ($self, $fileHandle, $check) = @_;

        # Local variables
        my (
            $line, $position,
            @emptyList, @returnArray,
        );

        # Check for improper arguments
        if (! defined $fileHandle || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->readMarker', @_);
            return @emptyList;
        }

        # Read an entry from the file
        OUTER: while (1) {

            $line = <$fileHandle>;
            chomp $line;

            if (! defined $line) {

                # File can't be read, or end of file
                return @emptyList;
            }

            if (substr ($line, 0, 1) ne '#') {

                # $line should start with @@@
                if (substr ($line, 0, 4) ne '@@@ ') {

                    return @emptyList;
                }

                # $line starts with @@@, so continue processing it
                last OUTER;
            }
        }

        # Remove the @@@
        $line = substr($line, 4);

        # Extract the first word
        $position = index($line, ' ');

        if ($position < 1) {

            # Line consists of just one word
            return ($line, undef);

        } else {

            # Line consists of a word, plus an argument string
            return (substr($line, 0, $position), substr($line, $position + 1));
        }
    }

    sub readLine {

        # Called by $self->loadConfigFile and its sub-functions
        # Reads lines from an opened config file until it finds one that doesn't begin with the
        #   comment marker #
        # If that line begins with the status marker @@@, returns 'undef' (because we are expecting
        #   some readable data, not a marker)
        #
        # Expected arguments
        #   $fileHandle - filehandle of the config file (opened for reading)
        #
        # Return values
        #   'undef' on improper arguments, if the file can't be read, the end of the file is
        #       reached, of if there's a status marker where data should be
        #   Otherwise, returns the first line of data read from the file that doesn't begin with
        #       the comment marker #

        my ($self, $fileHandle, $check) = @_;

        # Local variables
        my $line;

        # Check for improper arguments
        if (! defined $fileHandle || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->readLine', @_);
        }

        # Read a line of data from the file
        while (1) {

            $line = <$fileHandle>;
            chomp $line;

            if (! defined $line || substr ($line, 0, 4) eq '@@@ ') {

                # File can't be read, or end of file; or there's a status marker where a line of
                #   data should be
                return undef;

            } elsif (substr ($line, 0, 2) ne '# ') {

                # This is a line of data. Return it
                return $line;
            }
        }
    }

    sub readValue {

        # Called by $self->loadConfigFile
        # Reads a single value from an opened config file, and stores it in the temporary hash of
        #   loaded data
        #
        # Expected arguments
        #   $failFlag   - Flag set to TRUE if any previous calls to $self->readValue, ->readFlag,
        #                   ->readList, ->readHash or ->readEndOfSection failed. If set to TRUE,
        #                   this function does nothing. If none of the calls have failed so far,
        #                   set to TRUE.
        #   $hashRef    - Reference to the temporary hash of loaded data
        #   $key        - The key in the temporary hash where the value read by this function is
        #                   stored
        #
        # Return values
        #   Returns the new value of $failFlag:
        #       TRUE if $failFlag is already set to TRUE, or if this function can't read a value
        #       FALSE otherwise (meaning that the function succeeded)

        my ($self, $failFlag, $hashRef, $key, $check) = @_;

        # Local variables
        my $value;

        # Check for improper arguments
        if (! defined $failFlag || ! defined $hashRef || ! defined $key || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->readValue', @_);
            return TRUE;
        }

        # Do nothing, if previous calls failed
        if ($failFlag) {

            return TRUE;
        }

        # Read the value
        $value = $self->readLine($$hashRef{'file_handle'});

        if (! defined $value) {

            # Operation failed
            $self->writeError(
                'Config file load error at item \'' . $key . '\'',
                 $self->_objClass . '->readValue',
            );

            return TRUE;

        } else {

            # Operation succeeded. Store the value in the temporary data hash
            $$hashRef{$key} = $value;
            return FALSE;
        }
    }

    sub readValueOrUndef {

        # Called by $self->loadConfigFile
        # Reads a single value from an opened config file, and stores it in the temporary hash of
        #   loaded data
        # Unlike $self->readValue, if the code reads an empty string, it uses the value 'undef'
        #   rather than an empty string
        #
        # Expected arguments
        #   $failFlag   - Flag set to TRUE if any previous calls to $self->readValue, ->readFlag,
        #                   ->readList, ->readHash or ->readEndOfSection failed. If set to TRUE,
        #                   this function does nothing. If none of the calls have failed so far,
        #                   set to TRUE.
        #   $hashRef    - Reference to the temporary hash of loaded data
        #   $key        - The key in the temporary hash where the value read by this function is
        #                   stored
        #
        # Return values
        #   Returns the new value of $failFlag:
        #       TRUE if $failFlag is already set to TRUE, or if this function can't read a value
        #       FALSE otherwise (meaning that the function succeeded)

        my ($self, $failFlag, $hashRef, $key, $check) = @_;

        # Local variables
        my $value;

        # Check for improper arguments
        if (! defined $failFlag || ! defined $hashRef || ! defined $key || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->readValue', @_);
            return TRUE;
        }

        # Do nothing, if previous calls failed
        if ($failFlag) {

            return TRUE;
        }

        # Read the value
        $value = $self->readLine($$hashRef{'file_handle'});

        if (! defined $value) {

            # Operation failed
            $self->writeError(
                'Config file load error at item \'' . $key . '\'',
                 $self->_objClass . '->readValueOrUndef',
            );

            return TRUE;

        } else {

            # Operation succeeded. Store the value in the temporary data hash
            if ($value eq '') {
                $$hashRef{$key} = undef;
            } else {
                $$hashRef{$key} = $value;
            }

            return FALSE;
        }
    }

    sub readFlag {

        # Called by $self->loadConfigFile
        # Reads a single flag from an opened config file, and stores it in the temporary hash of
        #   loaded data
        #
        # Expected arguments
        #   $failFlag   - Flag set to TRUE if any previous calls to $self->readValue, ->readFlag,
        #                   ->readList, ->readHash or ->readEndOfSection failed. If set to TRUE,
        #                   this function does nothing. If none of the calls have failed so far,
        #                   set to TRUE.
        #   $hashRef    - Reference to the temporary hash of loaded data
        #   $key        - The key in the temporary hash where the flag read by this function is
        #                   stored
        #
        # Return values
        #   Returns the new value of $failFlag:
        #       TRUE if $failFlag is already set to TRUE, or if this function can't read a flag
        #       FALSE otherwise (meaning that the function succeeded)

        my ($self, $failFlag, $hashRef, $key, $check) = @_;

        # Local variables
        my $flag;

        # Check for improper arguments
        if (! defined $failFlag || ! defined $hashRef || ! defined $key || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->readFlag', @_);
            return TRUE;
        }

        # Do nothing, if previous calls failed
        if ($failFlag) {

            return TRUE;
        }

        # Read the flag
        $flag = $self->readLine($$hashRef{'file_handle'});

        if (! defined $flag) {

            # Operation failed
            $self->writeError(
                'Config file load error at item \'' . $key . '\'',
                 $self->_objClass . '->readFlag',
            );

            return TRUE;

        } else {

            # Operation succeeded. Store the flag in the temporary data hash
            if ($flag) {
                $$hashRef{$key} = TRUE;
            } else {
                $$hashRef{$key} = FALSE;
            }

            return FALSE;
        }
    }

    sub readList {

        # Called by $self->loadConfigFile
        # Reads a list from an opened config file - consisting of the number of value to read,
        #   followed by the values themselves - and stores the values themselves in the temporary
        #   hash of loaded data
        #
        # Expected arguments
        #   $failFlag   - Flag set to TRUE if any previous calls to $self->readValue, ->readFlag,
        #                   ->readList, ->readHash or ->readEndOfSection failed. If set to TRUE,
        #                   this function does nothing. If none of the calls have failed so far,
        #                   set to TRUE.
        #   $hashRef    - Reference to the temporary hash of loaded data
        #   $key        - The key in the temporary hash where the list read by this function is
        #                   stored
        #
        # Return values
        #   Returns the new value of $failFlag:
        #       TRUE if $failFlag is already set to TRUE, if this function can't read a list or if
        #           the list contains the wrong number of values
        #       FALSE otherwise (meaning that the function succeeded)

        my ($self, $failFlag, $hashRef, $key, $check) = @_;

        # Local variables
        my (
            $number,
            @list,
        );

        # Check for improper arguments
        if (! defined $failFlag || ! defined $hashRef || ! defined $key || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->readList', @_);
            return TRUE;
        }

        # Do nothing, if previous calls failed
        if ($failFlag) {

            return TRUE;
        }

        # Read the number of items in the list
        $number = $self->readLine($$hashRef{'file_handle'});
        if (! defined $number || ! $axmud::CLIENT->intCheck($number, 0)) {

            # Operation failed
            $self->writeError(
                'Config file load error at item \'' . $key . '\'',
                 $self->_objClass . '->readList',
            );

            return TRUE;

        } else {

            for (my $count = 0; $count < $number; $count++) {

                my $value = $self->readLine($$hashRef{'file_handle'});
                if (! defined $value) {

                    # Missing value; operation failed
                    $self->writeError(
                        'Config file load error at item \'' . $key . '\' - missing value(s)',
                         $self->_objClass . '->readList',
                    );

                    return TRUE;

                } else {

                    push (@list, $value);
                }
            }

            # Operation succeeded. Store the list in the temporary data hash
            $$hashRef{$key} = \@list;
            return FALSE;
        }
    }

    sub readHash {

        # Called by $self->loadConfigFile
        # Reads a hash from an opened config file - consisting of the number of key-value pairs to
        #   read, followed by the keys and values themselves - and stores the complete hash in the
        #   temporary hash of loaded data
        #
        # Expected arguments
        #   $failFlag   - Flag set to TRUE if any previous calls to $self->readValue, ->readFlag,
        #                   ->readList, ->readHash or ->readEndOfSection failed. If set to TRUE,
        #                   this function does nothing. If none of the calls have failed so far,
        #                   set to TRUE.
        #   $hashRef    - Reference to the temporary hash of loaded data
        #   $key        - The key in the temporary hash where the hash read by this function is
        #                   stored
        #
        # Return values
        #   Returns the new value of $failFlag:
        #       TRUE if $failFlag is already set to TRUE, if this function can't read a hash or if
        #           the list contains the wrong number of key-value pairs
        #       FALSE otherwise (meaning that the function succeeded)

        my ($self, $failFlag, $hashRef, $key, $check) = @_;

        # Local variables
        my (
            $number,
            %hash,
        );

        # Check for improper arguments
        if (! defined $failFlag || ! defined $hashRef || ! defined $key || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->readHash', @_);
            return TRUE;
        }

        # Do nothing, if previous calls failed
        if ($failFlag) {

            return TRUE;
        }

        # Read the number of key-value pairs in the hash
        $number = $self->readLine($$hashRef{'file_handle'});
        if (! defined $number || ! $axmud::CLIENT->intCheck($number, 0)) {

            # Operation failed
            $self->writeError(
                'Config file load error at item \'' . $key . '\'',
                 $self->_objClass . '->readHash',
            );

            return TRUE;

        } else {

            for (my $count = 0; $count < $number; $count++) {

                my ($key, $value);

                $key = $self->readLine($$hashRef{'file_handle'});
                if (! defined $key) {

                    # Missing value; operation failed
                    $self->writeError(
                        'Config file load error at item \'' . $key . '\' - missing value(s)',
                         $self->_objClass . '->readHash',
                    );

                    return TRUE;
                }

                $value = $self->readLine($$hashRef{'file_handle'});
                if (! defined $value) {

                    # Missing value; operation failed
                    $self->writeError(
                        'Config file load error at item \'' . $key . '\' - missing value(s)',
                         $self->_objClass . '->readHash',
                    );

                    return TRUE;
                }

                $hash{$key} = $value;
            }

            # Operation succeeded. Store the list in the temporary data hash
            $$hashRef{$key} = \%hash;
            return FALSE;
        }
    }

    sub readEndOfSection {

        # Called by $self->loadConfigFile
        # Reads a single end-of-section line from an opened config file
        #
        # Expected arguments
        #   $failFlag   - Flag set to TRUE if any previous calls to $self->readValue, ->readFlag,
        #                   ->readList, ->readHash or ->readEndOfSection failed. If set to TRUE,
        #                   this function does nothing. If none of the calls have failed so far,
        #                   set to TRUE.
        #   $fileHandle - The config file's filehandle
        #
        # Return values
        #   Returns the new value of $failFlag:
        #       TRUE if $failFlag is already set to TRUE, or if this function can't read the
        #           end-of-section
        #       FALSE otherwise (meaning that the function succeeded)

        my ($self, $failFlag, $fileHandle, $check) = @_;

        # Local variables
        my $line;

        # Check for improper arguments
        if (! defined $failFlag || ! defined $fileHandle || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->readEndOfSection', @_);
            return FALSE;
        }

        # Do nothing, if previous calls failed
        if ($failFlag) {

            return TRUE;
        }

        # Read the end of section
        ($line) = $self->readMarker($fileHandle);

        if (! defined $line || $line ne 'eos') {

            # Operation failed
            return TRUE;

        } else {

            # Operation succeeded
            return FALSE;
        }
    }

    sub convert {

        # Called by $self->saveConfigFile
        # Converts an Axmud flag (TRUE or FALSE) into the values 1 or 0, so it can be written to the
        #   'config' file
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $flag   - The flag to convert (should be TRUE or FALSE). If 'undef', treated as FALSE
        #
        # Return values
        #   1 or 0

        my ($self, $flag, $check) = @_;

        # (No improper arguments to check)

        if ($flag) {
            return 1;
        } else {
            return 0;
        }
    }

    sub destroyStandardDir {

        # Called by GA::Cmd::DeleteWorld, or by any other code
        # Deletes the whole directory in which this object's file is stored - in the case of a
        #   'worldprof' file, deleting the directory $self->actualDir will also cause the
        #   'otherprof' and 'worldmodel' files, which are in the same directory, to be deleted
        # (If $self->actualDir hasn't been set yet, $self->standardDir is used)
        # No warning dialogue is shown - it's up to the calling code to do that
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if $self->actualDir isn't set or if it doesn't exist
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $dir;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->destroyStandardDir', @_);
        }

        # Decide which directory to delete
        if ($self->actualDir) {
            $dir = $self->actualDir;
        } else {
            $dir = $axmud::DATA_DIR . $self->standardDir;
        }

        if (! $dir || ! (-e $dir)) {

            # Directory not set or doesn't exist
            return undef;

        } else {

            # Delete the directory and everything it contains
            File::Path::remove_tree($dir);

            return 1;
        }
    }

    # Glob test mode

    sub globTest {

        # Called by $self->saveDataFile
        # Glob test mode: In earlier Axmud versions, saving of data files failed (and Axmud crashed)
        #   because of infinite recursions with two Perl objects referencing each other. If TRUE,
        #   ever save file operation (not including the config file) tests data for this problem,
        #   before saving it, writing the output to the terminal
        #
        # Expected arguments
        #   %saveHash   - A hash of data about to be saved to a data file
        #
        # Return values
        #   'undef' if the test fails (data file must not be saved)
        #   1 if the test succeeds (data file can be saved)

        my ($self, %saveHash) = @_;

        # Local variables
        my ($string, $line);

        # (no improper arguments to check)

        $string = $axmud::SCRIPT . " SAVE DATA TEST";
        print "$string\n";
        $line = "=" x length($string);
        print "$line\n";

        if (! $self->globTest_hash(1, \%saveHash)) {

            print "TEST FAILED\n";
            return undef;

        } else {

            print "TEST SUCCEEDED\n";
            return 1;
        }
    }

    sub globTest_list {

        # Called by $self->globTest or recursively by this function and/or $self->globTest_hash

        my ($self, $count, $listRef) = @_;

        $count++;
        if ($count >= 50) {

            # Likely infinite recursion; give up
            return undef;
        }

        foreach my $item (@$listRef) {

            my ($column, $result);

            $column = " " x $count;

            if (defined $item) {
                print "$column item $item\n";
            } else {
                print "$column item <undef>\n";
            }

            if (ref ($item) eq 'HASH' || ref ($item) =~ m/Axmud\:\:/) {
                $result = $self->globTest_hash($count, $item);
            } elsif (ref ($item) eq 'ARRAY') {
                $result = $self->globTest_list($count, $item);
            } else {
                $result = TRUE;
            }

            if (! $result) {

                return undef;
            }
        }

        return 1;
    }

    sub globTest_hash {

        # Called by $self->globTest or recursively by this function and/or $self->globTest_list

        my ($self, $count, $hashRef) = @_;

        $count++;
        if ($count >= 50) {

            # Likely infinite recursion; give up
            return undef;
        }

        foreach my $key (keys %$hashRef) {

            my ($value, $column, $result);

            $value = $$hashRef{$key};
            $column = " " x $count;

            if (defined $value) {
                print "$column key $key value $value\n";
            } else {
                print "$column key $key value <undef>\n";
            }

            if (ref ($value) eq 'HASH' || ref ($value) =~ m/Axmud\:\:/) {
                $result = $self->globTest_hash($count, $value);
            } elsif (ref ($value) eq 'ARRAY') {
                $result = $self->globTest_list($count, $value);
            } else {
                $result = TRUE;
            }

            if (! $result) {

                return undef;
            }
        }

        return 1;
    }

    # Client-renaming operations

    sub updateHeaderAfterRename {

        # In version v1.0.868, the client was renamed to Axmud, and ABasic was renamed to Axbasic.
        #   Some internal data structures were also renamed
        # This function is called by $self->loadDataFile and ->importDataFile to update the file's
        #   header data (the remaining data is update by the call to $self->updateDataAfterRename
        # Also called by GA::Client->copyPreConfigWorlds
        #
        # This code will probably be moved to an optional plugin at some point in the future
        #
        # Expected arguments
        #   %loadHash   - A hash of data that's just been loaded from this data file, before it has
        #                   been extracted and stored in memory
        #
        # Return values
        #   %loadHash, which has been updated (or not) as required

        my ($self, %loadHash) = @_;

        # (no improper arguments to check)

        if (exists $loadHash{'file_type'}) {

            if ($loadHash{'file_type'} eq 'worlddefn') {
                $loadHash{'file_type'} = 'worldprof';
            } elsif ($loadHash{'file_type'} eq 'otherdefn') {
                $loadHash{'file_type'} = 'otherprof';
            }
        }

        if (exists $loadHash{'assoc_world_defn'}) {

            $loadHash{'assoc_world_prof'} = $loadHash{'assoc_world_defn'};
            delete $loadHash{'assoc_world_defn'};
        }

        return %loadHash;
    }

    sub updateDataAfterRename {

        # In version v1.0.868, the client was renamed to Axmud, and ABasic was renamed to Axbasic.
        #   Some internal data structures were also renamed
        # This function is called by $self->extractData to update the file's data (not including the
        #   header data, which was updated in the earlier call to $self->updateHeaderAfterRename)
        # This code will probably be moved to an optional plugin at some point in the future
        #
        # Expected arguments
        #   %loadHash   - A hash of data that's just been loaded from this data file, before it has
        #                   been extracted and stored in memory
        #
        # Return values
        #   %loadHash, which has been updated (or not) as required

        my ($self, %loadHash) = @_;

        # Local variables
        my ($obj, $hashRef, $subHashRef);

        # (no improper arguments to check)

        if ($self->fileType eq 'worldprof') {

            if (exists $loadHash{'world_defn'}) {

                $loadHash{'world_prof'} = $loadHash{'world_defn'};
                delete $loadHash{'world_defn'};
            }

            if (exists $loadHash{'world_prof'}) {

                $loadHash{'world_prof'} = $self->update_profile_world($loadHash{'world_prof'});
            }

        } elsif ($self->fileType eq 'otherprof') {

            if (exists $loadHash{'defn_priority_list'}) {

                $loadHash{'prof_priority_list'} = $loadHash{'defn_priority_list'};
                delete $loadHash{'defn_priority_list'};
            }

            if (exists $loadHash{'defn_hash'}) {

                $loadHash{'prof_hash'} = $loadHash{'defn_hash'};
                delete $loadHash{'defn_hash'};
            }

            # no update required for 'prof_priority_list'

            if (exists $loadHash{'skeleton_hash'}) {

                $hashRef = $loadHash{'skeleton_hash'};
                foreach my $key (keys %$hashRef) {

                    $$hashRef{$key} = $self->update_profile_template($$hashRef{$key});
                }

                $loadHash{'template_hash'} = $hashRef;
                delete $loadHash{'skeleton_hash'};
            }

            if (exists $loadHash{'prof_hash'}) {

                $hashRef = $loadHash{'prof_hash'};
                foreach my $key (keys %$hashRef) {

                    $$hashRef{$key} = $self->update_profile_other($$hashRef{$key});
                }

                $loadHash{'prof_hash'} = $hashRef;
            }

            if (exists $loadHash{'templ_hash'}) {

                $hashRef = $loadHash{'templ_hash'};
                foreach my $key (keys %$hashRef) {

                    $$hashRef{$key} = $self->update_cage_all($$hashRef{$key});
                }

                $loadHash{'cage_hash'} = $hashRef;
            }

        } elsif ($self->fileType eq 'worldmodel') {

            if (exists $loadHash{'world_model_obj'}) {

                $loadHash{'world_model_obj'}
                    = $self->update_obj_world_model($loadHash{'world_model_obj'});
            }

        } elsif ($self->fileType eq 'tasks') {

            # no update required for 'task_label_hash'
            # no update required for 'task_run_first_list'
            # no update required for 'task_run_last_list'

            if (exists $loadHash{'init_task_hash'}) {

                $hashRef = $loadHash{'init_task_hash'};
                foreach my $key (keys %$hashRef) {

                    $$hashRef{$key} = $self->update_task_all($$hashRef{$key});
                }

                $loadHash{'init_task_hash'} = $hashRef;
            }

            # no update required for 'init_task_order_list'
            # no update required for 'init_task_total'

            if (exists $loadHash{'custom_task_hash'}) {

                $hashRef = $loadHash{'custom_task_hash'};
                foreach my $key (keys %$hashRef) {

                    $$hashRef{$key} = $self->update_task_all($$hashRef{$key});
                }

                $loadHash{'custom_task_hash'} = $hashRef;
            }

        } elsif ($self->fileType eq 'scripts') {

            # no update required for 'script_dir_list'
            # no update required for 'init_script_hash'
            # no update required for 'init_script_order_list'

        } elsif ($self->fileType eq 'contacts') {

            # no update required for 'chat_name'
            # no update required for 'chat_email'
            # no update required for 'chat_accept_mode'

            if (exists $loadHash{'chat_contact_hash'}) {

                $hashRef = $loadHash{'chat_contact_hash'};
                foreach my $key (keys %$hashRef) {

                    $$hashRef{$key} = $self->update_obj_chat_contact($$hashRef{$key});
                }

                $loadHash{'chat_contact_hash'} = $hashRef;
            }

            # no update required for 'chat_icon'
            # no update required for 'chat_smiley_hash'

        } elsif ($self->fileType eq 'keycodes') {

            if (exists $loadHash{'keycode_obj_hash'}) {

                $hashRef = $loadHash{'keycode_obj_hash'};
                foreach my $key (keys %$hashRef) {

                    $$hashRef{$key} = $self->update_obj_keycode($$hashRef{$key});
                }

                $loadHash{'keycode_obj_hash'} = $hashRef;
            }

            if (exists $loadHash{'current_keycode_obj'}) {

                # If the keycode is missing from GA::Client->keycodeObjHash (for some reason), don't
                #   let it be added to GA::Client->currentKeycodeObj
                $obj = $loadHash{'current_keycode_obj'};
                if (! exists $$hashRef{$obj->name}) {

                    delete $loadHash{'current_keycode_obj'};
                }
            }

        } elsif ($self->fileType eq 'dicts') {

            if (exists $loadHash{'dict_hash'}) {

                $hashRef = $loadHash{'dict_hash'};
                foreach my $key (keys %$hashRef) {

                    $$hashRef{$key} = $self->update_obj_dict($$hashRef{$key});
                }

                $loadHash{'dict_hash'} = $hashRef;
            }

        } elsif ($self->fileType eq 'toolbar') {

            if (exists $loadHash{'toolbar_hash'}) {

                $hashRef = $loadHash{'toolbar_hash'};
                foreach my $key (keys %$hashRef) {

                    $$hashRef{$key} = $self->update_obj_toolbar($$hashRef{$key});
                }

                $loadHash{'toolbar_hash'} = $hashRef;
            }

            # no update required for 'toolbar_list'

        } elsif ($self->fileType eq 'usercmds') {

            # no update required for 'user_cmd_hash'

        } elsif ($self->fileType eq 'zonemaps') {

            if (exists $loadHash{'zonemap_hash'}) {

                $hashRef = $loadHash{'zonemap_hash'};
                foreach my $key (keys %$hashRef) {

                    $$hashRef{$key} = $self->update_obj_zonemap($$hashRef{$key});
                }

                $loadHash{'zonemap_hash'} = $hashRef;
            }

            # ($subHashRef represents a subset of key-value pairs in $hashRef)
            if (exists $loadHash{'standard_zonemap_hash'}) {

                $subHashRef = $loadHash{'standard_zonemap_hash'};
                foreach my $key (keys %$subHashRef) {

                    # If the zonemap is missing from GA::Client->zonemapHash (for some reason),
                    #   don't let it be added to GA::Client->standardZonemapHash
                    if (exists $$hashRef{$key}) {

                        $$subHashRef{$key} = $$hashRef{$key};
                    }
                }

                $loadHash{'standard_zonemap_hash'} = $subHashRef;
            }

        } elsif ($self->fileType eq 'winmaps') {

            if (exists $loadHash{'winmap_hash'}) {

                $hashRef = $loadHash{'winmap_hash'};
                foreach my $key (keys %$hashRef) {

                    $$hashRef{$key} = $self->update_obj_winmap($$hashRef{$key});
                }

                $loadHash{'winmap_hash'} = $hashRef;
            }

            # ($subHashRef represents a subset of key-value pairs in $hashRef)
            if (exists $loadHash{'standard_winmap_hash'}) {

                $subHashRef = $loadHash{'standard_winmap_hash'};
                foreach my $key (keys %$subHashRef) {

                    # If the winmap is missing from GA::Client->winmapHash (for some reason),
                    #   don't let it be added to GA::Client->standardWinmapHash
                    if (exists $$hashRef{$key}) {

                        $$subHashRef{$key} = $$hashRef{$key};
                    }
                }

                $loadHash{'standard_winmap_hash'} = $subHashRef;
            }

            if (exists $loadHash{'colour_scheme_hash'}) {

                $hashRef = $loadHash{'colour_scheme_hash'};
                foreach my $key (keys %$hashRef) {

                    $$hashRef{$key} = $self->update_obj_colourscheme($$hashRef{$key});
                }

                $loadHash{'colour_scheme_hash'} = $hashRef;
            }

        } elsif ($self->fileType eq 'tts') {

            if (exists $loadHash{'tts_obj_hash'}) {

                $hashRef = $loadHash{'tts_obj_hash'};
                foreach my $key (keys %$hashRef) {

                    $$hashRef{$key} = $self->update_obj_tts($$hashRef{$key});
                }

                $loadHash{'tts_obj_hash'} = $hashRef;
            }
        }

        # Mark this data file as needing to be saved, whether the data it contains has actually been
        #   updated or not
        $self->ivPoke('modifyFlag', TRUE);

        return %loadHash;
    }

    sub update_cage_all {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Templ::XXX > Games::Axmud::Cage::XXX
        # Converts AMud::MaskTempl::XXX > Games::Axmud::CageMask::XXX

        my ($self, $obj) = @_;

        # Local variables
        my ($class, $flag, $hashRef);

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Templ\:\:/) {

            $class =~ s/^AMud\:\:Templ/Games::Axmud::Cage/;
            $flag = TRUE;

        } elsif ($class =~ m/^AMud\:\:MaskTempl\:\:/) {

            $class =~ s/^AMud\:\:MaskTempl/Games::Axmud::CageMask/;
            $flag = TRUE;
        }

        # Updated ->_objName
        $obj->{_objName} = $obj->{_name};
        delete $obj->{_name};

        if ($flag) {

            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'otherprof')
            if ($obj->{_parentFile} && $obj->{_parentFile} eq 'otherdefn') {

                $obj->{_parentFile} = 'otherprof';
            }

            # Update IVs
            if ($class =~ m/Route$/) {

                $hashRef = $obj->{routeHash};
                foreach my $key (keys %$hashRef) {

                    $$hashRef{$key} = $self->update_obj_route($$hashRef{$key});
                }

                $obj->{routeHash} = $hashRef;

            } elsif ($class =~ m/(Trigger|Alias|Macro|Timer|Hook)$/) {

                $hashRef = $obj->{interfaceHash};
                foreach my $key (keys %$hashRef) {

                    $$hashRef{$key} = $self->update_interface_all($$hashRef{$key});
                }

                $obj->{interfaceHash} = $hashRef;
            }

            $obj->{cageType} = $obj->{templType};
            delete $obj->{templType};

            $obj->{profName} = $obj->{defnName};
            delete $obj->{defnName};

            $obj->{profCategory} = $obj->{defnCategory};
            delete $obj->{defnCategory};

            # Update @ISA
            if ($class =~ m/(Cmd|Route)$/) {

                @obj::ISA = qw(Games::Axmud::Generic::Cage Games::Axmud);

            } else {

                @obj::ISA = qw(
                    Games::Axmud::Generic::InterfaceCage Games::Axmud::Generic::Cage
                    Games::Axmud
                );
            }
        }

        return $obj;
    }

    sub update_interface_all {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Interface::XXX > Games::Axmud::Interface:::XXX

        my ($self, $obj) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Interface\:\:/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'undef')

            # Update IVs
            $obj->{assocProf} = $obj->{assocDefn};
            delete $obj->{assocDefn};

            $obj->{assocProfCategory} = $obj->{assocDefnCategory};
            delete $obj->{assocDefnCategory};

            # Update @ISA
            @obj::ISA = qw(Games::Axmud::Generic::Interface Games::Axmud);
        }

        return $obj;
    }

    sub update_modelobj_all {

        # Called by $self->updateDataAfterRename
        # Converts AMud::ModelObj::Region > Games::Axmud::ModelObj::Region

        my ($self, $obj) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:ModelObj\:\:/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'undef' or 'worldmodel')

            # (No IVs to update)
            # Games::Axmud::ModelObj::Region->regionmapObj is handled by ->update_obj_world_model

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_chat_contact {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::ChatContact > Games::Axmud::Obj::ChatContact

        my ($self, $obj) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:ChatContact/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'contacts')

            # (No IVs to update)

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_component {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::Component > Games::Axmud::Obj::Component

        my ($self, $obj) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:Component/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is world name)

            # (No IVs to update)

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_colourscheme {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::ColourScheme > Games::Axmud::Obj::ColourScheme

        my ($self, $obj) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:ColourScheme/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'winmaps')

            # (No IVs to update)

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_dict {

        # Called by $self->updateDataAfterRename (and also by GA::Client->copyPreConfigWorlds)
        # Converts AMud::Obj::Dict > Games::Axmud::Obj::Dict

        my ($self, $obj) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:Dict/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'dicts')

            # (No IVs to update)

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_exit {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::Exit > Games::Axmud::Obj::Exit

        my ($self, $obj) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:Exit/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'undef' or 'worldmodel')

            # (No IVs to update)

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_keycode {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::Keycode > Games::Axmud::Obj::Keycode

        my ($self, $obj) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:Keycode/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'keycodes')

            # (No IVs to update)

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_maplabel {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::MapLabel > Games::Axmud::Obj::MapLabel

        my ($self, $obj) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:MapLabel/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'worldmodel')

            # (No IVs to update)

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_mission {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::Mission > Games::Axmud::Obj::Mission

        my ($self, $obj) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:Mission/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is world name)

            # (No IVs to update)

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_monitor {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::Monitor > Games::Axmud::Obj::Monitor

        my ($self, $obj) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:Monitor/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'otherprof')
            if ($obj->{_parentFile} && $obj->{_parentFile} eq 'otherdefn') {

                $obj->{_parentFile} = 'otherprof';
            }

            # (No IVs to update)

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_protect {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::Protect > Games::Axmud::Obj::Protect

        my ($self, $obj) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:Protect/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'otherprof')
            if ($obj->{_parentFile} && $obj->{_parentFile} eq 'otherdefn') {

                $obj->{_parentFile} = 'otherprof';
            }

            # (No IVs to update)

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_quest {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::Quest > Games::Axmud::Obj::Quest

        my ($self, $obj) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:Quest/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is world name)

            # (No IVs to update)

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_regionmap {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::Regionmap > Games::Axmud::Obj::Regionmap

        my ($self, $obj) = @_;

        # Local variables
        my ($class, $hashRef, $pathHashRef);

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:Regionmap/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'worldmodel')

            # Update IVs
            $hashRef = $obj->{gridLabelHash};
            foreach my $key (keys %$hashRef) {

                $$hashRef{$key} = $self->update_obj_maplabel($$hashRef{$key});
            }

            $obj->{gridLabelHash} = $hashRef;

            $pathHashRef = $obj->{regionPathHash};
            foreach my $key (keys %$pathHashRef) {

                $$pathHashRef{$key} = $self->update_obj_regionpath($$pathHashRef{$key});
            }

            $obj->{regionPathHash} = $pathHashRef;

            $hashRef = $obj->{safeRegionPathHash};
            foreach my $key (keys %$hashRef) {

                $$hashRef{$key} = $$pathHashRef{$key};
            }

            $obj->{safeRegionPathHash} = $pathHashRef;

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_regionpath {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::RegionPath > Games::Axmud::Obj::RegionPath

        my ($self, $obj) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:RegionPath/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'worldmodel')

            # (No IVs to update)

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_route {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::Route > Games::Axmud::Obj::Route

        my ($self, $obj) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:Route/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'otherprof')
            if ($obj->{_parentFile} && $obj->{_parentFile} eq 'otherdefn') {

                $obj->{_parentFile} = 'otherprof';
            }

            # (No IVs to update)

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_skillhistory {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::SkillHistory > Games::Axmud::Obj::SkillHistory

        my ($self, $obj) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:SkillHistory/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'otherprof')
            if ($obj->{_parentFile} && $obj->{_parentFile} eq 'otherdefn') {

                $obj->{_parentFile} = 'otherprof';
            }

            # (No IVs to update)

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_toolbar {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::Toolbar > Games::Axmud::Obj::Toolbar

        my ($self, $obj) = @_;

        # Local variables
        my ($class, $instruct);

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:Toolbar/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'toolbar')

            # Update IVs. Many ->instruct values are client commands; convert any client commands
            #   that are used with a default Axmud installation
            $instruct = $obj->{instruct};
            $instruct =~ s/^\;edittemplate\s/;editcage/;
            $obj->{instruct} = $instruct;

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_tts {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::Tts > Games::Axmud::Obj::Tts

        my ($self, $obj) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:Tts/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'tts')

            # (No IVs to update)

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_winmap {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::Winmap > Games::Axmud::Obj::Winmap

        my ($self, $obj) = @_;

        # Local variables
        my (
            $class, $listRef, $hashRef,
            @list,
        );

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:Winmap/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'winmaps')

            # Update IVs
            $hashRef = $obj->{zoneHash};
            foreach my $key (keys %$hashRef) {

                $$hashRef{$key} = $self->update_obj_winzone($$hashRef{$key}, $obj);
            }

            $obj->{zoneHash} = $hashRef;

            $listRef = $obj->{stripInitList};
            if (@$listRef) {

                do {

                    my ($string, $hashRef);

                    $string = shift @$listRef;
                    $hashRef = shift @$listRef;

                    $string =~ s/^AMud/Games::Axmud/;
                    push (@list, $string, $hashRef);

                } until (! @$listRef);

                $obj->{stripInitList} = \@list;
            }

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_winzone {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::Winzone > Games::Axmud::Obj::Winzone

        my ($self, $obj, $parent) = @_;

        # Local variables
        my ($class, $string);

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:Winzone/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'winmaps')

            # Update IVs
            if (defined $parent) {

                $obj->{winmapObj} = $parent;
            }

            if (defined $obj->{packageName}) {

                $string = $obj->{packageName};
                $string =~ s/^AMud/Games::Axmud/;
                $obj->{packageName} = $string;
            }

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_world_model {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::WorldModel > Games::Axmud::Obj::WorldModel

        my ($self, $obj) = @_;

        # Local variables
        my ($class, $flag, $hashRef, $modelHashRef, $mapHashRef);

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud:\:WorldModel/) {

            $class =~ s/^AMud/Games::Axmud::Obj/;
            $flag = TRUE;

        } elsif ($class =~ m/^AMud\:\:Obj\:\:WorldModel/) {

            $class =~ s/^AMud/Games::Axmud/;
            $flag = TRUE;
        }

        if ($flag) {

            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'worldmodel')

            # Update IVs
            $modelHashRef = $obj->{model};
            foreach my $key (keys %$modelHashRef) {

                $$modelHashRef{$key} = $self->update_modelobj_all($$modelHashRef{$key});
            }

            $obj->{model} = $modelHashRef;

            my @ivList = qw(
                regionModel roomModel weaponModel armourModel garmentModel charModel minionModel
                sentientModel creatureModel portableModel decorationModel customModel
            );

            foreach my $iv (@ivList) {

                my $subHashRef = $obj->{$iv};
                foreach my $key (keys %$subHashRef) {

                    $$subHashRef{$key} = $$modelHashRef{$key};
                }

                $obj->{$iv} = $subHashRef;
            }

            $hashRef = $obj->{exitModel};
            foreach my $key (keys %$hashRef) {

                $$hashRef{$key} = $self->update_obj_exit($$hashRef{$key});
            }

            $obj->{exitModel} = $hashRef;

            $mapHashRef = $obj->{regionmapHash};
            foreach my $key (keys %$mapHashRef) {

                $$mapHashRef{$key} = $self->update_obj_regionmap($$mapHashRef{$key});
            }

            $obj->{regionmapHash} = $mapHashRef;

            # (We can now do Games::Axmud::ModelObj::Room->regionmapObj)
            $hashRef = $obj->{regionModel};
            foreach my $thisObj (values %$hashRef) {

                $thisObj->{regionmapObj} = $$mapHashRef{$thisObj->{name}};
            }

            $hashRef = $obj->{knownCharHash};
            foreach my $key (keys %$hashRef) {

                my $oldObj = $$hashRef{$key};

                $$hashRef{$key} = $$modelHashRef{$oldObj->{number}};
            }

            $obj->{knownCharHash} = $hashRef;

            $hashRef = $obj->{minionStringHash};
            foreach my $key (keys %$hashRef) {

                my $oldObj = $$hashRef{$key};

                # Values in this hash can be model or non-model objects
                if (defined $oldObj->{number}) {

                    # Model object
                    $$hashRef{$key} = $$modelHashRef{$oldObj->{number}};

                } else {

                    # Non-model object
                    $$hashRef{$key} = $self->update_modelobj_all($oldObj);
                }
            }

            $obj->{minionStringHash} = $hashRef;

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_obj_zone_model {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::ZoneModel > Games::Axmud::Obj::ZoneModel

        my ($self, $obj, $parent) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:ZoneModel/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'zonemaps')

            # Update IVs
            if (defined $parent) {

                $obj->{zonemapObj} = $parent;
            }
        }

        # Update @ISA
        @obj::ISA = qw(Games::Axmud);

        return $obj;
    }

    sub update_obj_zonemap {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Obj::Zonemap > Games::Axmud::Obj::Zonemap

        my ($self, $obj) = @_;

        # Local variables
        my ($class, $hashRef);

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Obj\:\:Zonemap/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'zonemaps')

            # Update IVs
            $hashRef = $obj->{modelHash};
            foreach my $key (keys %$hashRef) {

                $$hashRef{$key} = $self->update_obj_zone_model($$hashRef{$key}, $obj);
            }

            $obj->{modelHash} = $hashRef;

            # Just to be safe
            $obj->{tempSession} = undef;

            # Update @ISA
            @obj::ISA = qw(Games::Axmud);
        }

        return $obj;
    }

    sub update_profile_world {

        # Called by $self->updateDataAfterRename
        # Converts Converts AMud::Defn::World > Games::Axmud::Profile::World

        my ($self, $obj) = @_;

        # Local variables
        my ($class, $hashRef);

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Defn\:\:World/) {

            $class =~ s/^AMud\:\:Defn/Games::Axmud::Profile/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is world name)

            # Update IVs
            $hashRef = $obj->{initTaskHash};
            foreach my $key (keys %$hashRef) {

                $$hashRef{$key} = $self->update_task_all($$hashRef{$key});
            }

            $obj->{initTaskHash} = $hashRef;

            $hashRef = $obj->{missionHash};
            foreach my $key (keys %$hashRef) {

                $$hashRef{$key} = $self->update_obj_mission($$hashRef{$key});
            }

            $obj->{missionHash} = $hashRef;

            $hashRef = $obj->{questHash};
            foreach my $key (keys %$hashRef) {

                $$hashRef{$key} = $self->update_obj_quest($$hashRef{$key});
            }

            $obj->{questHash} = $hashRef;

            $hashRef = $obj->{componentHash};
            foreach my $key (keys %$hashRef) {

                $$hashRef{$key} = $self->update_obj_component($$hashRef{$key});
            }

            $obj->{componentHash} = $hashRef;

            $obj->{profName} = $obj->{defnName};
            delete $obj->{defnName};

            $obj->{profCategory} = $obj->{defnCategory};
            delete $obj->{defnCategory};

            $obj->{profSensitivityFlag} = $obj->{defnSensitivityFlag};
            delete $obj->{defnSensitivityFlag};

            $obj->{profHash} = $obj->{defnHash};
            delete $obj->{defnHash};

            # Update @ISA
            @obj::ISA = qw(Games::Axmud::Generic::Profile Games::Axmud);
        }

        return $obj;
    }

    sub update_profile_other {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Defn::XXX > Games::Axmud::Profile::XXX

        my ($self, $obj) = @_;

        # Local variables
        my (
            $class, $listRef, $hashRef,
            @list, @list2, @list3,
        );

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Defn\:\:/) {

            $class =~ s/^AMud\:\:Defn/Games::Axmud::Profile/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'otherprof')
            if ($obj->{_parentFile} && $obj->{_parentFile} eq 'otherdefn') {

                $obj->{_parentFile} = 'otherprof';
            }

            # Update IVs
            $hashRef = $obj->{initTaskHash};
            foreach my $key (keys %$hashRef) {

                $$hashRef{$key} = $self->update_task_all($$hashRef{$key});
            }

            $obj->{initTaskHash} = $hashRef;

            if ($class =~ m/Char$/) {

                $listRef = $obj->{skillHistoryList};
                foreach my $thisObj (@$listRef) {

                    push (@list, $self->update_obj_skillhistory($thisObj));
                }

                $obj->{skillHistoryList} = \@list;

                $listRef = $obj->{protectObjList};
                foreach my $thisObj (@$listRef) {

                    push (@list2, $self->update_obj_protect($thisObj));
                }

                $obj->{protectObjList} = \@list2;

                $listRef = $obj->{monitorObjList};
                foreach my $thisObj (@$listRef) {

                    push (@list3, $self->update_obj_monitor($thisObj));
                }

                $obj->{monitorObjList} = \@list3;
            }

            $obj->{profName} = $obj->{defnName};
            delete $obj->{defnName};

            $obj->{profCategory} = $obj->{defnCategory};
            delete $obj->{defnCategory};

            $obj->{profSensitivityFlag} = $obj->{defnSensitivityFlag};
            delete $obj->{defnSensitivityFlag};

            if ($class =~ m/Char$/) {

                $obj->{customProfHash} = $obj->{customDefnHash};
                delete $obj->{customDefnHash};
            }

            # Update @ISA
            @obj::ISA = qw(Games::Axmud::Generic::Profile Games::Axmud);
        }

        return $obj;
    }

    sub update_profile_template {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Defn::Skeleton > Games::Axmud::Profile::Template

        my ($self, $obj) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Defn\:\:Skeleton/) {

            $class =~ s/^AMud\:\:Defn\:\:Skeleton/Games::Axmud::Profile::Template/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'otherprof')
            if ($obj->{_parentFile} && $obj->{_parentFile} eq 'otherdefn') {

                $obj->{_parentFile} = 'otherprof';
            }

            # (No IVs to update)

            # Update @ISA
            @obj::ISA = qw(Games::Axmud::Generic::Profile Games::Axmud);
        }

        return $obj;
    }

    sub update_task_all {

        # Called by $self->updateDataAfterRename
        # Converts AMud::Task::XXX > Games::Axmud::Task::XXX

        my ($self, $obj) = @_;

        # Local variables
        my $class;

        # (no improper arguments to check)

        # Update class
        $class = ref $obj;
        if ($class =~ m/^AMud\:\:Task\:\:/) {

            $class =~ s/^AMud/Games::Axmud/;
            bless $obj, $class;
            $obj->{_objClass} = $class;

            $obj->{_objName} = $obj->{_name};
            delete $obj->{_name};

            # (->_parentFile is 'undef')

            # Update IVs
            if (exists $obj->{ttsProfile}) {

                $obj->{ttsConfig} = $obj->{ttsProfile};
                delete $obj->{ttsProfile};
            }

            if ($obj->{name} eq 'notepad_task') {

                $obj->{profNoteHash} = $obj->{defnNoteHash};
                delete $obj->{defnNoteHash};
            }

            # Update @ISA
            @obj::ISA = qw(Games::Axmud::Generic::Task Games::Axmud);
        }

        return $obj;
    }

    ##################
    # Accessors - set

    sub set_modifyFlag {

        # NB The calling function, $func, is disregarded

        my ($self, $flag, $func, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_modifyFlag', @_);
        }

        if ($flag) {
            $self->{modifyFlag} = TRUE;
        } else {
            $self->{modifyFlag} = FALSE;
        }

        return $self->modifyFlag;
    }

    ##################
    # Accessors - get

    sub session
        { $_[0]->{session} }

    sub name
        { $_[0]->{name} }

    sub fileType
        { $_[0]->{fileType} }
    sub scriptName
        { $_[0]->{scriptName} }
    sub scriptVersion
        { $_[0]->{scriptVersion} }
    sub scriptConvertVersion
        { $_[0]->{scriptConvertVersion} }
    sub saveDate
        { $_[0]->{saveDate} }
    sub saveTime
        { $_[0]->{saveTime} }
    sub assocWorldProf
        { $_[0]->{assocWorldProf} }

    sub actualFileName
        { $_[0]->{actualFileName} }
    sub actualPath
        { $_[0]->{actualPath} }
    sub actualDir
        { $_[0]->{actualDir} }

    sub standardFileName
        { $_[0]->{standardFileName} }
    sub standardPath
        { $_[0]->{standardPath} }
    sub standardDir
        { $_[0]->{standardDir} }

    sub altFileName
        { $_[0]->{altFileName} }
    sub altPath
        { $_[0]->{altPath} }

    sub modifyFlag
        { $_[0]->{modifyFlag} }
}

# Package must return true
1
