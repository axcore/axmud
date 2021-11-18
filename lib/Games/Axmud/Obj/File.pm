# Copyright (C) 2011-2021 A S Lewis
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
    # Include module here, as well as in axmud.pl, so that .../t/00-compile.t won't fail
    use Fcntl qw(:flock);

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
                $standardPath = '\\' . $axmud::NAME_SHORT . '.ini';
                $altFileName = $axmud::NAME_SHORT . '.conf';
                $altPath = '\\' . $axmud::NAME_SHORT . '.conf';

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

        # (Convert forward slashes to backwards slashes on MS Windows)
        if ($^O eq 'MSWin32') {

            $standardFileName =~ s/\//\\/g;
            $standardPath =~ s/\//\\/g;
            $standardDir =~ s/\//\\/g;
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
            scriptVersion               => undef,    # e.g. '1.2.345'
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
            # This flag can be set to TRUE when a backup file (e.g. 'tasks.axm.bu') rather than the
            #   normal file (e.g. 'tasks.axm') is loaded
            # When TRUE, the next time this file is saved, the existing backup file is not replaced,
            #   and the flag is then set back to FALSE
            # In this way, if a file can't be loaded and the backup file is loaded instead, the
            #   faulty file is discarded (never becomes a backup file)
            preserveBackupFlag          => FALSE,
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
            #   in the GA::Client's directories. The TRUE argument signals that this function is the
            #   calling function
            OUTER: foreach my $world ($axmud::CLIENT->constWorldList) {

                if (! defined $axmud::CLIENT->copyPreConfigWorld($world, TRUE)) {

                    return $self->writeError(
                        'Error setting up \'' . $self->fileType . '\' data file',
                        $self->_objClass . '->setupConfigFile',
                    );
                }
            }

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
            @list, @workspaceList, @storeGridList, @itemList, @modList,
            %workspaceHash, %storeGridHash, %itemHash, %worldHash,
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

            if ($self->preserveBackupFlag) {

                # The file itself was missing/corrupted, so data was loaded from the backup file
                # Don't replace the (good) backup file; just replace the (faulty) file itself
                # NB For the config file, nothing in the Axmud code sets this flag to TRUE. Still,
                #   the code exists, for any future version that needs it
                $self->ivPoke('preserveBackupFlag', FALSE);

            } elsif (-e $path) {

                # If the config file already exists, make a backup copy (it's not really necessary
                #   for the config file, which is so small, but for larger data files which take a
                #   long time to save, it's necessary to have a backup before overwriting an
                #   existing file)
                if ($axmud::CLIENT->autoRetainFileFlag) {

                    # Retain this backup file where the user can easily find it
                    $backupFile = $path . '.bu';

                } else {

                    # This is a temporary backup file, so store it in the temporary files directory
                    #   directory
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
                $self->convert($client->autoRetainFileFlag),
            '# Auto-backup mode',
                $client->autoBackupMode,
            '# Auto-backup directory',
                $client->autoBackupDir,
            '# Auto-backup interval (days)',
                $client->autoBackupInterval,
            '# Time of last auto-backup (string in form \'Thu Dec 18, 2010\')',
                $client->autoBackupDate,
            '# Auto-backup file type',
                $client->autoBackupFileType,
            '# Append time to auto-backup files',
                $self->convert($client->autoBackupAppendFlag),
            '# Store large world models as multiple files',
                $self->convert($client->modelSplitSize),
            '# Approximate size of multiple world model files',
                $client->modelSplitSize,
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
            '# Previous client version',
                $client->prevClientVersion,
            '# Number of world profiles',
                scalar @modList,
            '# World profile list',
                @modList,
            '# Number of favourite worlds',
                scalar $client->favouriteWorldList,
            '# Favourite world list',
                $client->favouriteWorldList,
            '# Number of auto-connecting worlds',
                scalar $client->autoConnectList,
            '# Auto-connect list (world profile name followed by 0, 1 or more characters)',
                $client->autoConnectList,
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

        push (@list,
            '# Number of lines in log preamble',
                scalar $axmud::CLIENT->logPreambleList,
            '# Log preamble',
                $client->logPreambleList,
        );

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
            '# \'Free\' window default size',
                $client->customFreeWinWidth,
                $client->customFreeWinHeight,
            '# World command colour',
                $client->customInsertCmdColour,
            '# System message colour',
                $client->customShowSystemTextColour,
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
                $self->convert($client->shareMainWinFlag),
            '# (The setting to use when ' . $axmud::SCRIPT . ' next starts)',
                $client->restartShareMainWinMode,
            '# Workspace grids are activated',
                $self->convert($client->activateGridFlag),
            '# Store \'grid\' window positions',
                $self->convert($client->storeGridPosnFlag),
        );

        %storeGridHash = $client->storeGridPosnHash;
        @storeGridList = sort {lc($a) cmp lc($b)} (keys %storeGridHash);

        push (@list,
            '# Number of stored \'grid\' window positions',
                scalar @storeGridList,
            '# Stored \'grid\' window positions',
        );

        foreach my $winName (@storeGridList) {

            my $listRef = $storeGridHash{$winName};

            # To make the loading code simpler, store 4 values as a line, in the form 'x y wid hei'
            push (@list,
                $winName,
                $$listRef[0] . ' ' . $$listRef[1] . ' ' . $$listRef[2] . ' ' . $$listRef[3] . ' ',
            );
        }

        push (@list,
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
            '# Hijack cursor (etc) keys in blind mode',
                $self->convert($client->ttsHijackFlag),
            '# Hijack cursor (etc) keys when not in blind mode',
                $self->convert($client->ttsForceHijackFlag),
            '# Use TTS for received text',
                $self->convert($client->ttsReceiveFlag),
            '# Don\'t use TTS for received text before login (except prompts)',
                $self->convert($client->ttsLoginFlag),
            '# Don\'t use TTS for recognised prompts in received text after a login',
                $self->convert($client->ttsPromptFlag),
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
            '# Use MNES',
                $self->convert($client->useMnesFlag),
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
            '# Allow some illegal MXP keywords (e.g. those using hyphens)',
                $self->convert($client->allowMxpFlexibleFlag),
            '# Allow MXP to be artificially enabled (for IRE MUDs)',
                $self->convert($client->allowMxpPermFlag),
            '# Allow MSP to play concurrent sound triggers',
                $self->convert($client->allowMspMultipleFlag),
            '# Allow MSP to download sound files',
                $self->convert($client->allowMspLoadSoundFlag),
            '# Allow flexible MSP tag placement (not recommended)',
                $self->convert($client->allowMspFlexibleFlag),
            '# Allow MNES to send user\'s IP address',
                $self->convert($client->allowMnesSendIPFlag),
            '# TELNET OPTION NEGOTIATION CUSTOMISATION',
            '# Sending termtype mode',
                $client->termTypeMode,
            '# Customised client name',
                $client->customClientName,
            '# Customised client version',
                $client->customClientVersion,
            '# Use VT100 control sequences',
                $self->convert($client->useCtrlSeqFlag),
            '# Use visible cursor in default textview',
                $self->convert($client->useVisibleCursorFlag),
            '# Cursor blinks quickly, when visible',
                $self->convert($client->useFastCursorFlag),
            '# Use direct keyboard input in default textview',
                $self->convert($client->useDirectKeysFlag),
            '# TELNET OPTION DEBUG FLAGS',
            '# Show invalid escape sequence debug messages',
                $self->convert($client->debugEscSequenceFlag),
            '# Show option negotiation debug messages',
                $self->convert($client->debugTelnetFlag),
            '# Show option negotiation short debug messages',
                $self->convert($client->debugTelnetMiniFlag),
            '# Ask GA::Obj::Telnet to write negotiation logfile',
                $self->convert($client->debugTelnetLogFlag),
            '# Show MSDP debug messages for Status/Locator',
                $self->convert($client->debugMsdpFlag),
            '# Show debug messages for MXP problems',
                $self->convert($client->debugMxpFlag),
            '# Show debug messages for MXP comments',
                $self->convert($client->debugMxpCommentFlag),
            '# Show debug messages for Pueblo problems',
                $self->convert($client->debugPuebloFlag),
            '# Show debug messages for Pueblo comments',
                $self->convert($client->debugPuebloCommentFlag),
            '# Show debug messages for incoming ZMP data',
                $self->convert($client->debugZmpFlag),
            '# Show debug messages for incoming ATCP data',
                $self->convert($client->debugAtcpFlag),
            '# Show debug messages for incoming GMCP data',
                $self->convert($client->debugGmcpFlag),
            '# Show debug messages for MCP problems',
                $self->convert($client->debugMcpFlag),
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
            '# Number commification mode',
                $client->commifyMode,
            '# Detect short weblinks',
                $self->convert($client->shortUrlFlag),
            '# List of IP lookup services',
                scalar $client->ipLookupList,
                $client->ipLookupList,
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
            '# Show illegal exit direction debug messages',
                $self->convert($client->debugExitFlag),
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
            '# Allow popup windows showing the ' . $axmud::SCRIPT . ' logo',
                $self->convert($client->allowBusyWinFlag),
            '# Allow system messages to be displayed in the \'main\' window',
                $self->convert($client->mainWinSystemMsgFlag),
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
            '# Prompt user before closing session from the \'main\' window menu',
                $self->convert($client->confirmCloseMenuFlag),
            '# Prompt user before closing session from the \'main\' window toolbar',
                $self->convert($client->confirmCloseToolButtonFlag),
            '# Character set',
                $client->charSet,
            '# Maximum concurrent sessions',
                $client->sessionMax,
            '# Switch to \'offline\' mode on disconnection',
                $self->convert($client->offlineOnDisconnectFlag),
            '# Store connection history',
                $self->convert($client->connectHistoryFlag),
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
        if ($self->scriptConvertVersion >= 1_001_024) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'auto_backup_mode');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'auto_backup_dir');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'auto_backup_interval');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'auto_backup_date');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'auto_backup_file_type');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'auto_backup_append_flag');
        }
        if ($self->scriptConvertVersion >= 1_001_529) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_model_split_flag');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'model_split_size');
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
        if ($self->scriptConvertVersion >= 1_001_021) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'prev_client_version');
        }
        $failFlag = $self->readList($failFlag, \%dataHash, 'world_prof_list');
        $failFlag = $self->readList($failFlag, \%dataHash, 'favourite_world_list');
        if ($self->scriptConvertVersion >= 1_001_396) {

            $failFlag = $self->readList($failFlag, \%dataHash, 'auto_connect_list');
        }
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
        if ($self->scriptConvertVersion >= 1_001_395) {

            $failFlag = $self->readList($failFlag, \%dataHash, 'log_preamble_list');
        }
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
        if ($self->scriptConvertVersion >= 1_001_162) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_free_win_width');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_free_win_height');
        }
        $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_insert_cmd_colour');
        $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_show_system_text_colour');
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
            $failFlag = $self->readValue($failFlag, \%dataHash, 'restart_share_main_win_mode');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'activate_grid_flag');
        }
        if ($self->scriptConvertVersion >= 1_001_164) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'store_grid_posn_flag');
            $failFlag = $self->readHash($failFlag, \%dataHash, 'store_grid_posn_hash');
        }
        if ($self->scriptConvertVersion >= 1_000_800) {

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
            if ($self->scriptConvertVersion >= 1_002_073) {

                $failFlag = $self->readFlag($failFlag, \%dataHash, 'tts_hijack_flag');
            }
            if ($self->scriptConvertVersion >= 1_002_213) {

                $failFlag = $self->readFlag($failFlag, \%dataHash, 'tts_force_hijack_flag');
            }
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'tts_receive_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'tts_login_flag');
            if ($self->scriptConvertVersion >= 1_002_212) {

                $failFlag = $self->readFlag($failFlag, \%dataHash, 'tts_prompt_flag');
            }
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'tts_system_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'tts_system_error_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'tts_world_cmd_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'tts_dialogue_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'tts_task_flag');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'tts_festival_server_port');
            if ($self->scriptConvertVersion < 1_002_185) {

                $failFlag = $self->readFlag($failFlag, \%dataHash, 'discard_me');
            }
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
        if ($self->scriptConvertVersion >= 1_002_095) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_mnes_flag');
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
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'use_aard102_flag');
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
        if ($self->scriptConvertVersion >= 1_001_510) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_mxp_flexible_flag');
        }
        if ($self->scriptConvertVersion >= 1_002_020) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_mxp_perm_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_678) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_msp_multiple_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_msp_load_sound_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_886) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_msp_flexible_flag');
        }
        if ($self->scriptConvertVersion >= 1_002_095) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_mnes_send_ip_flag');
        }
        # Read telnet option negotiation customisation IVs
        if ($self->scriptConvertVersion >= 1_000_160) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'term_type_mode');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_client_name');
        }
        if ($self->scriptConvertVersion >= 1_000_666) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'custom_client_version');
        }
        if ($self->scriptConvertVersion >= 1_001_213) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'use_ctrl_seq_flag');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'use_visible_cursor_flag');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'use_fast_cursor_flag');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'use_direct_keys_flag');
        }
        # Set telnet negotiation debug flags
        if ($self->scriptConvertVersion >= 1_001_214) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_esc_sequence_flag');
        }
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
        if ($self->scriptConvertVersion >= 1_001_140) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_zmp_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_926) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_atcp_flag');
            $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_gmcp_flag');
        }
        if ($self->scriptConvertVersion >= 1_001_158) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_mcp_flag');
        }

        $failFlag = $self->readEndOfSection($failFlag, $fileHandle);

        # Read misc data
        $failFlag = $self->readList($failFlag, \%dataHash, 'custom_month_list');
        $failFlag = $self->readList($failFlag, \%dataHash, 'custom_day_list');
        if ($self->scriptConvertVersion >= 1_001_262) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'commify_mode');
        }
        if ($self->scriptConvertVersion >= 1_001_284) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'short_url_flag');
        }
        if ($self->scriptConvertVersion <= 1_000_922) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'discard_me');
        }
        if ($self->scriptConvertVersion >= 1_002_166) {

            $failFlag = $self->readList($failFlag, \%dataHash, 'ip_lookup_list');
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
        if ($self->scriptConvertVersion >= 1_001_282) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'debug_exit_flag');
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
        if ($self->scriptConvertVersion >= 1_001_136) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'allow_busy_win_flag');
        }
        if ($self->scriptConvertVersion >= 1_001_202) {

            $failFlag = $self->readFlag($failFlag, \%dataHash, 'main_win_system_msg_flag');
        }
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
        if ($self->scriptConvertVersion >= 1_002_102) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'confirm_close_menu_flag');
            $failFlag = $self->readValue($failFlag, \%dataHash, 'confirm_close_tool_button_flag');
        }
        if ($self->scriptConvertVersion >= 1_000_185) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'char_set');
        }
        if ($self->scriptConvertVersion >= 1_000_616) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'session_max');
        }
        if ($self->scriptConvertVersion >= 1_001_256) {

            $failFlag = $self->readValue($failFlag, \%dataHash, 'offline_on_disconnect_flag');
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

        ##############
        # Data updates

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
            if ($self->scriptConvertVersion >= 1_000_160) {

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
        }

        # v1.2.0 makes window tiling available on all operating systems
        if ($self->scriptConvertVersion < 1_002_000 && $^O eq 'MSWin32') {

            $dataHash{'store_grid_posn_flag'} = FALSE;

            # Show the Setup 'wiz' window again, so the user can choose a layout. As of this
            #   version, the 'wiz' window now checks that any initial tasks already exist and, if
            #   so, updates them (usually to make their windows upon automatically) rather than
            #   creating new initial tasks
            if (! $axmud::TEST_MODE_FLAG && ! $axmud::BLIND_MODE_FLAG) {

                $axmud::CLIENT->set_showSetupWizWinFlag(TRUE);
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
        if ($self->scriptConvertVersion >= 1_001_024) {

            $client->ivPoke('autoBackupMode', $dataHash{'auto_backup_mode'});
            $client->ivPoke('autoBackupDir', $dataHash{'auto_backup_dir'});
            $client->ivPoke('autoBackupInterval', $dataHash{'auto_backup_interval'});
            $client->ivPoke('autoBackupDate', $dataHash{'auto_backup_date'});
            $client->ivPoke('autoBackupFileType', $dataHash{'auto_backup_file_type'});
            $client->ivPoke('autoBackupAppendFlag', $dataHash{'auto_backup_append_flag'});
        }
        if ($self->scriptConvertVersion >= 1_001_529) {

            $client->ivPoke('allowModelSplitFlag', $dataHash{'allow_model_split_flag'});
            $client->ivPoke('modelSplitSize', $dataHash{'model_split_size'});
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
        if ($self->scriptConvertVersion >= 1_001_021) {

            $client->ivPoke('prevClientVersion', $dataHash{'prev_client_version'});
        }
        $client->ivPoke('configWorldProfList', @{$dataHash{'world_prof_list'}});
        $client->ivPoke('favouriteWorldList', @{$dataHash{'favourite_world_list'}});
        if ($self->scriptConvertVersion >= 1_001_396) {

            $client->ivPoke('autoConnectList', @{$dataHash{'auto_connect_list'}});
        }

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
        if ($self->scriptConvertVersion >= 1_001_395) {

            $client->ivPoke('logPreambleList', @{$dataHash{'log_preamble_list'}});
        }

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
        $client->ivPoke('customMainWinWidth', $dataHash{'custom_main_win_width'});
        $client->ivPoke('customMainWinHeight', $dataHash{'custom_main_win_height'});
        $client->ivPoke('customGridWinWidth', $dataHash{'custom_grid_win_width'});
        $client->ivPoke('customGridWinHeight', $dataHash{'custom_grid_win_height'});
        if ($self->scriptConvertVersion >= 1_001_162) {

            $client->ivPoke('customFreeWinWidth', $dataHash{'custom_free_win_width'});
            $client->ivPoke('customFreeWinHeight', $dataHash{'custom_free_win_height'});
        }

        $client->ivPoke('customInsertCmdColour', $dataHash{'custom_insert_cmd_colour'});
        $client->ivPoke('customShowSystemTextColour', $dataHash{'custom_show_system_text_colour'});
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

            if ($self->scriptConvertVersion < 1_001_394) {

                # The IV now uses the values 'default', 'on' and 'off', rather than TRUE and FALSE
                #   (which didn't work as intended). Just change the value to 'default'
                $client->ivPoke('restartShareMainWinMode', 'default');

            } elsif ($self->scriptConvertVersion < 1_002_026) {

                # Due to a bug, the value was set as 1 or 0, rather than 'on' or 'off'
                if ($dataHash{'restart_share_main_win_mode'}) {
                    $client->ivPoke('restartShareMainWinMode', 'on');
                } else {
                    $client->ivPoke('restartShareMainWinMode', 'off');
                }

            } else {

                $client->ivPoke(
                    'restartShareMainWinMode',
                    $dataHash{'restart_share_main_win_mode'},
                );
            }

            $client->ivPoke('activateGridFlag', $dataHash{'activate_grid_flag'});
        }
        if ($self->scriptConvertVersion >= 1_001_164) {

            my (%thisHash, %newHash);

            $client->ivPoke('storeGridPosnFlag', $dataHash{'store_grid_posn_flag'});

            # To make the saving code simpler, 4 values were stored on a line, in the form
            #   'x y wid hei'
            %thisHash = %{$dataHash{'store_grid_posn_hash'}};

            foreach my $key (keys %thisHash) {

                my $listRef = [ split(/\s+/, $thisHash{$key}) ];

                $newHash{$key} = $listRef;
            }

            $client->ivPoke('storeGridPosnHash', %newHash);
        }
        if ($self->scriptConvertVersion >= 1_000_800) {

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
            if ($self->scriptConvertVersion >= 1_002_073) {

                $client->ivPoke('ttsHijackFlag', $dataHash{'tts_hijack_flag'});
            }
            if ($self->scriptConvertVersion >= 1_002_213) {

                $client->ivPoke('ttsForceHijackFlag', $dataHash{'tts_force_hijack_flag'});
            }
            $client->ivPoke('ttsReceiveFlag', $dataHash{'tts_receive_flag'});
            $client->ivPoke('ttsLoginFlag', $dataHash{'tts_login_flag'});
            if ($self->scriptConvertVersion >= 1_002_212) {

                $client->ivPoke('ttsPromptFlag', $dataHash{'tts_prompt_flag'});
            }
            $client->ivPoke('ttsSystemFlag', $dataHash{'tts_system_flag'});
            $client->ivPoke('ttsSystemErrorFlag', $dataHash{'tts_system_error_flag'});
            $client->ivPoke('ttsWorldCmdFlag', $dataHash{'tts_world_cmd_flag'});
            $client->ivPoke('ttsDialogueFlag', $dataHash{'tts_dialogue_flag'});
            $client->ivPoke('ttsTaskFlag', $dataHash{'tts_task_flag'});
            # (Prefer an 'undef' value over an empty string)
            if ($dataHash{'tts_festival_server_port'} eq '') {
                $client->ivUndef('ttsFestivalServerPort');
            } else {
                $client->ivPoke('ttsFestivalServerPort', $dataHash{'tts_festival_server_port'});
            }
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
        if ($self->scriptConvertVersion >= 1_002_095) {

            $client->ivPoke('useMnesFlag', $dataHash{'use_mnes_flag'});
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
            $client->ivPoke('useAard102Flag', $dataHash{'use_aard102_flag'});
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
        if ($self->scriptConvertVersion >= 1_001_510) {

            $client->ivPoke('allowMxpFlexibleFlag', $dataHash{'allow_mxp_flexible_flag'});
        }
        if ($self->scriptConvertVersion >= 1_002_020) {

            $client->ivPoke('allowMxpPermFlag', $dataHash{'allow_mxp_perm_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_678) {

            $client->ivPoke('allowMspMultipleFlag', $dataHash{'allow_msp_multiple_flag'});
            $client->ivPoke('allowMspLoadSoundFlag', $dataHash{'allow_msp_load_sound_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_886) {

            $client->ivPoke('allowMspFlexibleFlag', $dataHash{'allow_msp_flexible_flag'});
        }
        if ($self->scriptConvertVersion >= 1_002_095) {

            $client->ivPoke('allowMnesSendIPFlag', $dataHash{'allow_mnes_send_ip_flag'});
        }
        # Set telnet option negotiation customisation IVs
        if ($self->scriptConvertVersion >= 1_000_160) {

            $client->ivPoke('termTypeMode', $dataHash{'term_type_mode'});
            $client->ivPoke('customClientName', $dataHash{'custom_client_name'});
        }
        if ($self->scriptConvertVersion >= 1_000_666) {

            $client->ivPoke('customClientVersion', $dataHash{'custom_client_version'});
        }
        if ($self->scriptConvertVersion >= 1_001_213) {

            $client->ivPoke('useCtrlSeqFlag', $dataHash{'use_ctrl_seq_flag'});
            $client->ivPoke('useVisibleCursorFlag', $dataHash{'use_visible_cursor_flag'});
            $client->ivPoke('useFastCursorFlag', $dataHash{'use_fast_cursor_flag'});
            $client->ivPoke('useDirectKeysFlag', $dataHash{'use_direct_keys_flag'});
        }
        # Set telnet negotiation debug flags
        if ($self->scriptConvertVersion >= 1_001_214) {

            $client->ivPoke('debugEscSequenceFlag', $dataHash{'debug_esc_sequence_flag'});
        }
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
        if ($self->scriptConvertVersion >= 1_001_140) {

            $client->ivPoke('debugZmpFlag', $dataHash{'debug_zmp_flag'});
        }
        if ($self->scriptConvertVersion >= 1_000_926) {

            $client->ivPoke('debugAtcpFlag', $dataHash{'debug_atcp_flag'});
            $client->ivPoke('debugGmcpFlag', $dataHash{'debug_gmcp_flag'});
        }
        if ($self->scriptConvertVersion >= 1_001_158) {

            $client->ivPoke('debugMcpFlag', $dataHash{'debug_mcp_flag'});
        }

        # Set misc data
        $client->ivPoke('customMonthList', @{$dataHash{'custom_month_list'}});
        $client->ivPoke('customDayList', @{$dataHash{'custom_day_list'}});
        if ($self->scriptConvertVersion >= 1_001_262) {

            $client->ivPoke('commifyMode', $dataHash{'commify_mode'});
        }
        if ($self->scriptConvertVersion >= 1_001_284) {

            $client->ivPoke('shortUrlFlag', $dataHash{'short_url_flag'});
        }
        if ($self->scriptConvertVersion >= 1_002_166) {

            $client->ivPoke('ipLookupList', @{$dataHash{'ip_lookup_list'}});
        }
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
        if ($self->scriptConvertVersion >= 1_001_282) {

            $client->ivPoke('debugExitFlag', $dataHash{'debug_exit_flag'});
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
        if ($self->scriptConvertVersion >= 1_001_136) {

            $client->ivPoke('allowBusyWinFlag', $dataHash{'allow_busy_win_flag'});
        }
        if ($self->scriptConvertVersion >= 1_001_202) {

            $client->ivPoke('mainWinSystemMsgFlag', $dataHash{'main_win_system_msg_flag'});
        }
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
        if ($self->scriptConvertVersion >= 1_002_102) {

            $client->ivPoke('confirmCloseMenuFlag', $dataHash{'confirm_close_menu_flag'});
            $client->ivPoke(
                'confirmCloseToolButtonFlag',
                $dataHash{'confirm_close_tool_button_flag'},
            );
        }
        if ($self->scriptConvertVersion >= 1_000_185) {

            $client->ivPoke('charSet', $dataHash{'char_set'});
        }
        if ($self->scriptConvertVersion >= 1_000_616) {

            $client->ivPoke('sessionMax', $dataHash{'session_max'});
        }
        if ($self->scriptConvertVersion >= 1_001_256) {

            $client->ivPoke('offlineOnDisconnectFlag', $dataHash{'offline_on_disconnect_flag'});
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
        #   'tasks', 'scripts', 'contacts', 'dicts', 'toolbar', 'usercmds', 'zonemaps', 'winmaps',
        #   'tts'
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
            && $self->fileType ne 'contacts' && $self->fileType ne 'dicts'
            && $self->fileType ne 'toolbar' && $self->fileType ne 'usercmds'
            && $self->fileType ne 'zonemaps' && $self->fileType ne 'winmaps'
            && $self->fileType ne 'tts'
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

                # Try loading the automatic backup, i.e. 'otherprof.axm.bu'
                if (! $self->loadDataFile(undef, undef, undef, TRUE)) {

                    return $self->writeError(
                        'Error reading \'' . $self->fileType . '\' data file',
                        $self->_objClass . '->setupDataFile',
                    );

                } else {

                    # The contents of the backup, now loaded into memory, must be saved at some
                    #   point
                    $self->ivPoke('modifyFlag', TRUE);
                    # Don't overwrite the existing backup file with the faulty one
                    $self->ivPoke('preserveBackupFlag', TRUE);

                    # File loaded (from backup)
                    return 1;
                }

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
        #   'tasks', 'scripts', 'contacts', 'dicts', 'toolbar', 'usercmds', 'zonemaps', 'winmaps',
        #   'tts'
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
            $checkWorldObj, $count, $buPath,
            %saveHash, %preserveHash, %reverseHash, %importHash, %usrCmdHash,
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

        # For the file type 'worldmodel', we might use a single monolithic file or, if the model is
        #   large, multiple smaller ones. A single monolithic file is handled by this function;
        #   multiple files are handled by a call to $self->saveDataFile_worldModel
        if ($self->fileType eq 'worldmodel') {

            if (
                ! $emergFlag
                && $axmud::CLIENT->allowModelSplitFlag
                && $self->session->worldModelObj->ivPairs('modelHash')
                        > $axmud::CLIENT->modelSplitSize
            ) {
                return $self->saveDataFile_worldModel($fileName, $path, $dir);
            } else {
                $self->session->worldModelObj->ivPoke('modelSaveFileCount', 0);
            }
        }

        # Otherwise, compile a special hash, %saveHash, that references all the data we want to save

        # First compile the header information (i.e. metadata)...
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

            if ($self->preserveBackupFlag) {

                # The file itself was missing/corrupted, so data was loaded from the backup file
                # Don't replace the (good) backup file; just replace the (faulty) file itself
                # NB For the config file, nothing in the Axmud code sets this flag to TRUE. Still,
                #   the code exists, for any future version that needs it
                $self->ivPoke('preserveBackupFlag', FALSE);

            } elsif (-e $path) {

                # If the call to ->lock_nstore fails, an existing file called $path will be
                #   destroyed or corrupted (this could be disastrous, especially if it contains a
                #   world profile, or something)
                # Create a backup of the file, if the file already exists, using File::Copy
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

    sub saveDataFile_worldModel {

        # Called by $self->saveDataFile
        # For the file type 'worldmodel', we might use a single monolithic file or, if the model is
        #   large, multiple smaller ones. A single monolithic file is handled by
        #   $self->saveDataFile; multiple files are handled by a call to this function
        #
        # Expected arguments
        #   $fileName   - The file name, i.e. 'worldmodel.axm'
        #   $path       - The full path, i.e. '/home/me/axmud-data/data/worldmodel.axm'
        #   $dir        - The directory, i.e. '/home/me/axmud-data/data/'
        #
        # Return values
        #   'undef' on improper arguments or if there is an error saving the data file(s) themselves
        #   1 otherwise

        my ($self, $fileName, $path, $dir, $check) = @_;

        # Local variables
        my (
            $tempDir, $count, $mainSavePath, $dirHandle,
            @ivList, @objList,
            %standardHash, %storeHash, %mainSaveHash,
        );

        # Check for improper arguments
        if (! defined $fileName || ! defined $path || ! defined $dir || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->saveDataFile_worldModel',
                @_,
            );
        }

        # When using multiple files, we use a 'main' file and multiple 'mini' files. The 'mini'
        #   files each contain a limited number of model objects (regions, rooms, weapons etc) and
        #   exit model objects. The 'main' file contains everything else

        # Because we're dealing with multiple files, rather than a single one, the way this function
        #   handles backup files is different. We'll create a temporary directory, save our files
        #   there and, if there are no problems, we'll then move the files into their proper
        #   directory
        # There's a (small) possibility that two sessions might saving their world model at the same
        #   time, in which case, this save operation fails
        $tempDir = $dir . '/temp/';
        if (-d $tempDir || ! mkdir ($tempDir, 0755)) {

            return undef;
        }

        # Prepare a standard header, used by all of these files
        $standardHash{'file_type'} = $self->fileType;
        $standardHash{'script_name'} = $axmud::NAME_FILE;
        $standardHash{'script_version'} = $axmud::VERSION;
        $standardHash{'save_date'} = $axmud::CLIENT->localDate();
        $standardHash{'save_time'} = $axmud::CLIENT->localTime();
        $standardHash{'assoc_world_prof'} = $self->assocWorldProf;

        # Empty all world model IVs which store model objects and exit model objects, storing them
        #   in a temporary hash. Everything left in GA::Obj::WorldModel is stored in the 'main' file
        @ivList = qw (
            modelHash
            regionModelHash roomModelHash weaponModelHash armourModelHash garmentModelHash
            charModelHash minionModelHash sentientModelHash creatureModelHash portableModelHash
            decorationModelHash customModelHash
            exitModelHash
        );

        foreach my $iv (@ivList) {

            $storeHash{$iv} = $self->session->worldModelObj->{$iv};
            $self->session->worldModelObj->{$iv} = {};
        }

        # Save the 'mini' files. Keep track of how many 'mini' files we've saved
        $count = 0;

        # Move the contents of the model, and the contents of the exit model, into flat lists so
        #   we can chop away at them, GA::Client->modelSplitSize objects at a time
        @objList = %{$storeHash{'modelHash'}};
        do {

            my (
                $thisSavePath,
                %thiSaveHash,
            );

            # Set the path for this mini world model file
            $count++;
            $thisSavePath = $tempDir . '/worldmodel_' . $count . '.axm';

            # All the 'mini' files have the same header
            %thiSaveHash = %standardHash;

            # @objList is a list in groups of 2, in the form (model_number, model_object...).
            #   Use the first $axmud::CLIENT->modelSplitSize objects
            $thiSaveHash{'model_hash'}
                = { splice(@objList, 0, ($axmud::CLIENT->modelSplitSize * 2)) };

            # Glob test mode: In earlier Axmud versions, saving of data files failed (and Axmud
            #   crashed) because of infinite recursions with two Perl objects referencing each
            #   other. If TRUE, every save file operation (not including the config file) tests data
            #   for this problem, before saving it, writing the output to the terminal
            if ($axmud::TEST_GLOB_MODE_FLAG && ! $self->globTest(%thiSaveHash)) {

                # (Delete the temporary directory before giving up)
                File::Path::remove_tree($tempDir);

                return undef;
            }

            # Save the 'mini' file
            eval { Storable::lock_nstore(\%thiSaveHash, $thisSavePath) };
            if ($@) {

                # Disable loading/saving in all sessions
                $axmud::CLIENT->disableAllFileAccess();

                # Delete the temporary directory before giving up
                File::Path::remove_tree($tempDir);

                return $self->writeError(
                    'Save data failure: \'' . $dir . '/worldmodel_' . $count . '.axm\' (existing'
                    . ' world model files are not affected, file loading/saving disabled)',
                    $self->_objClass . '->saveDataFile_worldModel',
                );
            }

        } until (! @objList);

        @objList = %{$storeHash{'exitModelHash'}};
        do {

            my (
                $thisSavePath,
                %thiSaveHash,
            );

            # Set the path for this mini world model file
            $count++;
            $thisSavePath = $tempDir . '/worldmodel_' . $count . '.axm';

            # All the 'mini' files have the same header
            %thiSaveHash = %standardHash;

            # @objList is a list in groups of 2, in the form (model_number, model_object...).
            #   Use the first $axmud::CLIENT->modelSplitSize objects
            $thiSaveHash{'exit_model_hash'}
                = { splice(@objList, 0, ($axmud::CLIENT->modelSplitSize * 2)) };

            # Glob check, if required
            if ($axmud::TEST_GLOB_MODE_FLAG && ! $self->globTest(%thiSaveHash)) {

                # (Delete the temporary directory before giving up)
                File::Path::remove_tree($tempDir);

                return undef;
            }

            # Save the 'mini' file
            eval { Storable::lock_nstore(\%thiSaveHash, $thisSavePath) };
            if ($@) {

                # Disable loading/saving in all sessions
                $axmud::CLIENT->disableAllFileAccess();

                # Delete the temporary directory before giving up
                File::Path::remove_tree($tempDir);

                return $self->writeError(
                    'Save data failure: \'' . $dir . '/worldmodel_' . $count . '.axm\' (existing'
                    . ' world model files are not affected, file loading/saving disabled)',
                    $self->_objClass . '->saveDataFile_worldModel',
                );
            }

        } until (! @objList);

        # Update the world model with the number of mini files it needs, the next time it's loaded
        $self->session->worldModelObj->ivPoke('modelSaveFileCount', $count);

        # Prepare the 'main' file
        %mainSaveHash = %standardHash;
        $mainSaveHash{'world_model_obj'} = $self->session->worldModelObj;

        # Glob check, if required
        if ($axmud::TEST_GLOB_MODE_FLAG && ! $self->globTest(%mainSaveHash)) {

            # (Delete the temporary directory before giving up)
            File::Path::remove_tree($tempDir);

            return undef;
        }

        # Save the 'main' file
        $mainSavePath = $tempDir . 'worldmodel.axm';
        eval { Storable::lock_nstore(\%mainSaveHash, $mainSavePath) };
        if ($@) {

            # Disable loading/saving in all sessions
            $axmud::CLIENT->disableAllFileAccess();

            # Delete the temporary directory before giving up
            File::Path::remove_tree($tempDir);

            return $self->writeError(
                'Save data failure: \'' . $path . '\' (existing world model files are not affected,'
                . ' file loading/saving disabled)',
                $self->_objClass . '->saveDataFile_worldModel',
            );
        }

        # Save operations successful. Before doing anything else, restore GA::Obj::WorldModel's
        #   IVs
        foreach my $iv (@ivList) {

            $self->session->worldModelObj->{$iv} = $storeHash{$iv};
            delete $storeHash{$iv};
        }

        # We can now deal with the pre-existing data files in $dir
        if ($self->preserveBackupFlag) {

            # The files themselves were missing/corrupted, so data was loaded from the backup files
            # Don't replace the (good) backup files; just remove the (faulty) files themselves
            $self->ivPoke('preserveBackupFlag', FALSE);

            if (opendir($dirHandle, $dir)) {

                my @fileList = readdir($dirHandle);
                closedir $dirHandle;

                foreach my $file (@fileList) {

                    if (
                        $file =~ m/worldmodel\.axm$/
                        || $file =~ m/worldmodel_\d+\.axm$/
                    ) {
                        unlink $dir . '/' . $file;
                    }
                }
            }

        } else {

            # Remove the existing backup files...
            if (opendir($dirHandle, $dir)) {

                my @fileList = readdir($dirHandle);
                closedir $dirHandle;

                foreach my $file (@fileList) {

                    if (
                        $file =~ m/worldmodel\.axm\.bu$/
                        || $file =~ m/worldmodel_\d+\.axm\.bu$/
                    ) {
                        unlink $dir . '/' . $file;
                    }
                }
            }

            # ...and replace them with the pre-existing data files
            if (opendir($dirHandle, $dir)) {

                my @fileList = readdir($dirHandle);
                closedir $dirHandle;

                foreach my $file (@fileList) {

                    if (
                        $file =~ m/worldmodel\.axm$/
                        || $file =~ m/worldmodel_\d+\.axm$/
                    ) {
                        File::Copy::move($dir . '/' . $file, $dir . '/' . $file . '.bu');
                    }
                }
            }
        }

        # Move everything from the temporary directory into the proper directory...
        if (opendir($dirHandle, $tempDir)) {

            my @fileList = readdir($dirHandle);
            closedir $dirHandle;

            foreach my $file (@fileList) {

                File::Copy::move($tempDir . $file, $dir . '/' . $file);
            }
        }

        # ...and delete the temporary directory
        File::Path::remove_tree($tempDir);

        # Finally, set this file object's metadata variables
        $self->ivPoke('scriptName', $mainSaveHash{'script_name'});
        $self->ivPoke('scriptVersion', $mainSaveHash{'script_version'});
        $self->ivPoke(
            'scriptConvertVersion',
            $axmud::CLIENT->convertVersion($mainSaveHash{'script_version'}),
        );
        $self->ivPoke('saveDate', $mainSaveHash{'save_date'});
        $self->ivPoke('saveTime', $mainSaveHash{'save_time'});
        $self->ivPoke('assocWorldProf', $mainSaveHash{'assoc_world_prof'});

        $self->ivPoke('actualFileName', $fileName);
        $self->ivPoke('actualPath', $path);
        $self->ivPoke('actualDir', $dir);

        # Mark the file object's data as not modified
        $self->set_modifyFlag(FALSE, $self->_objClass . '->saveDataFile');

        return 1;
    }

    sub loadDataFile {

        # Called by $self->setupDataFile (or by any other function) for the file types:
        #   'tasks', 'scripts', 'contacts', 'dicts', 'toolbar', 'usercmds', 'zonemaps', 'winmaps',
        #   'tts'
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
        #   $backupFlag - If TRUE, the function will try to load the automatic backup of the file
        #                   (e.g. 'tasks.axm.bu'). If FALSE (or 'undef'), the function loads the
        #                   normal copy of the file (e.g. 'tasks.axm')
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

        my ($self, $fileName, $path, $dir, $backupFlag, $check) = @_;

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

        # Load the automatic backup of the file, if required
        if ($backupFlag) {

            $fileName .= '.bu';
            $path .= '.bu';
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

            # Extract the header information (i.e. metadata) from the hash
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

            # For the file type 'worldmodel', we might use a single monolithic file or, if the model
            #   is large, multiple smaller ones. Check whether multiple files exist and, if so,
            #   load them, updating the world model that's currently stored in
            #   $loadHash{'world_model_obj'}
            if (
                $axmud::CLIENT->convertVersion($scriptVersion) >= 1_001_529
                && $self->fileType eq 'worldmodel'
                && ! $self->loadDataFile_worldModel($dir, \%loadHash)
            ) {
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
            #   the loaded file. The TRUE argument tells ->extractData that this is the calling
            #   function
            if (! $self->extractData(TRUE, %loadHash)) {

                # Load failed
                return undef;
            }

            # Apply patches to any pre-configured world profiles with serious problems, or whose
            #   DNS/IP/port has changed
            if (
                $fileType eq 'worldprof'
                && $axmud::CLIENT->ivExists('constWorldPatchHash', $assocWorldProf)
            ) {
                $self->patchWorldProf($assocWorldProf, $scriptVersion);
            }

            # Load complete
            return 1;
        }
    }

    sub loadDataFile_worldModel {

        # Called by $self->loadDataFile
        # For the file type 'worldmodel', we might use a single monolithic file or, if the model is
        #   large, multiple smaller ones (a 'main' file and several 'mini' files)
        # $self->loadDataFile loads the 'worldmodel.axm' file, which is either a monolithic file,
        #   or the 'main' file
        # This function checks whether the loaded file is a 'main' file and, if so, tries to load
        #   the remaining 'mini' files, merging the data from the 'main' and 'mini' files into a
        #   single world model
        #
        # Expected arguments
        #   $dir            - The directory from which the monolothic/'main' file was loaded
        #   $mainHashRef    - A hash containing data loaded from the monolithic or 'main' file.
        #                       The loaded world model itself (GA::Obj::WorldModel) is stored in
        #                       $$loadHashRef{'world_model_obj'}, and has not yet replaced the
        #                       world model in memory (GA::Session->worldModelObj). Anything loaded
        #                       from the 'mini' files is incorporated into that loaded world model
        #                       before the complete world model is transferred to
        #                       GA::Session->worldModelObj
        #
        # Return values
        #   'undef' on improper arguments or if we fail to load any 'mini' files that exist
        #   1 if the file loaded was a monolithic file, or if the 'main' and 'mini' files have all
        #       been loaded successfully

        my ($self, $dir, $mainHashRef, $check) = @_;

        # Local variables
        my (
            $wmObj,
            @modelList, @exitList,
        );

        # Check for improper arguments
        if (! defined $dir || ! defined $mainHashRef || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->loadDataFile_worldModel',
                @_,
            );
        }

        # Import the loaded world model
        $wmObj = $$mainHashRef{'world_model_obj'};
        if (! defined $wmObj) {

            # Load failure
            return undef;
        }

        # If it's a monolithic world model file, there's nothing for this function to do
        if (! exists $wmObj->{modelSaveFileCount} || ! $wmObj->{modelSaveFileCount}) {

            # The monolithic file's data can now be extracted into memory as normal
            return 1;
        }

        # Some 'mini' files exist; load them all
        for (my $count = 1; $count <= $wmObj->{modelSaveFileCount}; $count++) {

            my (
                $loadPath, $hashRef, $fileType, $scriptName, $scriptVersion, $saveDate, $saveTime,
                $assocWorldProf,
                %loadHash,
            );

            # If this 'mini' file doesn't exist, loading of the whole world model fails
            $loadPath = $dir . '/worldmodel_' . $count . '.axm';
            if (! -e $loadPath) {

                return undef;
            }

            # Load all the data into a hash
            eval { $hashRef = Storable::lock_retrieve($loadPath); };
            if (! $hashRef) {

                # ->lock_retrieve() failed
                return undef;
            }

            # Convert the hash referenced by $hashRef into a named hash
            %loadHash = %{$hashRef};

            # Check that the header information in the 'mini' file is exactly the same as for the
            #   'main' file
            if (
                $loadHash{'file_type'} ne $$mainHashRef{'file_type'}
                || $loadHash{'script_name'} ne $$mainHashRef{'script_name'}
                || $loadHash{'script_version'} ne $$mainHashRef{'script_version'}
                || $loadHash{'save_date'} ne $$mainHashRef{'save_date'}
                || $loadHash{'save_time'} ne $$mainHashRef{'save_time'}
                || $loadHash{'assoc_world_prof'} ne $$mainHashRef{'assoc_world_prof'}
            ) {
                return undef;
            }

            # Extract the data from the 'mini' file
            if (exists $loadHash{'model_hash'}) {

                # Extract some model objects (regions, room etc)
                push (@modelList, %{$loadHash{'model_hash'}});

            } elsif (exists $loadHash{'exit_model_hash'}) {

                # Extract some exit model objects
                push (@exitList, %{$loadHash{'exit_model_hash'}});

            } else {

                # If neither exist in the file, it must be corrupted
                return undef;
            }
        }

        # All mini model files loaded successfully, so incorporate their data into the loaded
        #   world model
        $wmObj->{modelHash} = {@modelList};
        $wmObj->{exitModelHash} = {@exitList};
        foreach my $obj (values %{$wmObj->{modelHash}}) {

            my $iv = $obj->category . 'ModelHash';      # e.g. ->regionModelHash

            $wmObj->{$iv}{$obj->number} = $obj;
        }

        # Operation complete
        return 1;
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

        # First compile the header information (i.e. metadata)...
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

            # Extract the header information (i.e. metadata) from the hash
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

            } elsif ($fileType eq 'keycodes') {

                # This type of data file was removed in v1.1.286
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

            # Extract the imported data. The FALSE argument tells ->extractData that this is the
            #   calling function
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
        #       'tasks', 'scripts', 'contacts', 'tts'
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

            # If the world model belonging to one world was imported into another using
            #   ;importFiles, the world model's ->_parentWorld won't have been updated yet
            if ($session->worldModelObj->_parentWorld ne $session->currentWorld->name) {

                # Update it now
                $session->worldModelObj->{_parentWorld} = $session->currentWorld->name;
                $self->set_modifyFlag(TRUE, $self->_objClass . '->extractData');
                # This file object's IV is also wrong
                $self->ivPoke('assocWorldProf', $session->currentWorld->name);
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
                            # (This IV subsequently renamed and/or removed)
#                            $compObj->{ignoreChars} = undef;
#                            $compObj->ivPoke('ignoreChars', 0);
                            $compObj->{ignoreChars} = 0;
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
                        # (This IV subsequently renamed and/or removed)
#                        $compObj->{usePatternBackRefs} = undef;
#                        $compObj->ivUndef('usePatternBackRefs');
                        $compObj->{usePatternBackRefs} = undef;
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

                        # (This IV subsequently renamed and/or removed)
#                        $profObj->{exitStateIgnoreList} = [];
#                        $profObj->ivEmpty('exitStateIgnoreList');
                        $profObj->{exitStateIgnoreList} = [];
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

                        # (This IV subsequently renamed and/or removed)
#                        $profObj->{customStatusVarHash} = {};
#                        $profObj->ivEmpty('customStatusVarHash');
                        $profObj->{customStatusVarHash} = {};
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

                        # (This IV subsequently renamed and/or removed)
#                        $profObj->{strictPromptsMode} = undef;
#                        $profObj->ivPoke('strictPromptsMode', FALSE);
                        $profObj->{strictPromptsMode} = undef;
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

                        # (This IV subsequently renamed and/or removed)
#                        $profObj->{exitStateDarkList} = [];
#                        $profObj->ivEmpty('exitStateDarkList');
                        $profObj->{exitStateDarkList} = [];
                        # (This IV subsequently renamed and/or removed)
#                        $profObj->{exitStateDangerList} = [];
#                        $profObj->ivEmpty('exitStateDangerList');
                        $profObj->{exitStateDangerList} = [];
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
                            # (This IV subsequently renamed and/or removed)
#                            $compObj->{stopTagMode} = undef;
#                            $compObj->ivPoke('stopTagMode', 0);
                            $compObj->{stopTagMode} = 0;
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

                            # (This IV subsequently renamed and/or removed)
#                            $compObj->{useAppliedTagsFlag} = undef;
#                            $compObj->ivPoke('useAppliedTagsFlag', FALSE);
                            $compObj->{useAppliedTagsFlag} = FALSE;
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

                        # (This IV subsequently renamed and/or removed)
#                        $profObj->{basicMappingMode} = undef;
#                        $profObj->ivPoke('basicMappingMode', 0);
                        $profObj->{basicMappingMode} = 0;
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

                        # (This IV subsequently renamed and/or removed)
#                        $profObj->{worldWarning} = undef;
#                        $profObj->ivUndef('worldWarning');
                        $profObj->{worldWarning} = undef;
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

                    foreach my $templObj ($self->session->ivValues('templateHash')) {

                        if (! $templObj->ivExists('_standardHash', 'notepadList')) {

                            # (Because this IV starts with an underline, have to set it directly)
                            $templObj->{'_standardHash'}{'notepadList'} = undef;
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

                        if ($version >= 1_000_543) {

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
                        }

                        if ($profObj->inventoryMode eq '0') {
                            $profObj->ivPoke('inventoryMode', 'match_all');
                        } elsif ($profObj->inventoryMode eq '1') {
                            $profObj->ivPoke('inventoryMode', 'start_stop');
                        } elsif ($profObj->inventoryMode eq '2') {
                            $profObj->ivPoke('inventoryMode', 'start_empty');
                        }

                        # (This IV subsequently renamed and/or removed)
                        if (! $profObj->basicMappingMode) {
#                            $profObj->ivPoke('basicMappingMode', FALSE);
                            $profObj->{'basicMappingMode'} = FALSE;
                        } else {
#                            $profObj->ivPoke('basicMappingMode', TRUE);
                            $profObj->{'basicMappingMode'} = TRUE;
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

            if ($version < 1_001_020) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{inventorySplitPatternList}) {

                        $profObj->{inventorySplitPatternList} = [];
                        $profObj->ivEmpty('inventorySplitPatternList');
                    }
                }
            }

            if ($version < 1_001_030) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{roomCmdIgnoreList}) {

                        $profObj->{roomCmdIgnoreList} = [];
                        $profObj->ivEmpty('roomCmdIgnoreList');
                    }
                }
            }

            if ($version < 1_001_074) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{exitStatePatternList}) {

                        $profObj->{exitStatePatternList} = [];
                        $profObj->ivEmpty('exitStatePatternList');
                    }
                }
            }

            if ($version < 1_001_082) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{transientExitPatternList}) {

                        $profObj->{transientExitPatternList} = [];
                        $profObj->ivEmpty('transientExitPatternList');
                    }
                }
            }

            if ($version < 1_001_124) {

                my (
                    $listRef,
                    @newList, @newList2, @combList,
                    %hash, %checkHash,
                );

                # This version merges several IVs into single lists, eliminating duplicates
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{channelList}) {

                        $profObj->{channelList} = [];
                        $profObj->ivEmpty('channelList');
                        $profObj->{noChannelList} = [];
                        $profObj->ivEmpty('noChannelList');

                        # Compile a hash of of patterns in the three existing IVs, sort them, then
                        #   compile the new IV
                        # In case the same pattern exists in multiple IVs, use the 'tell' pattern
                        #   first
                        $listRef = $profObj->{customDivertPatternList};
                        if (defined $listRef && @$listRef) {

                            do {

                                my $pattern = shift @$listRef;
                                my $flag = shift @$listRef;

                                $hash{$pattern} = ['custom', $flag];

                            } until (! @$listRef);
                        }

                        $listRef = $profObj->{socialPatternList};
                        if (defined $listRef) {

                            foreach my $pattern (@$listRef) {

                                # Set TRUE because in previous versions of Axmud, social/tell
                                #   patterns were not displayed in the 'main' window and the task
                                #   window
                                $hash{$pattern} = ['social', TRUE];
                            }
                        }

                        if (defined $listRef) {

                            $listRef = $profObj->{tellPatternList};
                            foreach my $pattern (@$listRef) {

                                $hash{$pattern} = ['tell', TRUE];
                            }
                        }

                        # Compile the new IV
                        foreach my $pattern (sort {lc($a) cmp lc($b)} (keys %hash)) {

                            $listRef = $hash{$pattern};

                            if (defined $listRef) {

                                push (@newList, $pattern, @$listRef);
                            }
                        }

                        $profObj->ivPoke('channelList', @newList);

                        # Repeat the process for the other IVs, eliminating duplicates using
                        #   %checkHash
                        $listRef = $profObj->{noTellPatternList};
                        if (defined $listRef) {

                            push (@combList, @$listRef);
                        }

                        $listRef = $profObj->{noSocialPatternList};
                        if (defined $listRef) {

                            push (@combList, @$listRef);
                        }

                        $listRef = $profObj->{noCustomDivertPatternList};
                        if (defined $listRef) {

                            push (@combList, @$listRef);
                        }

                        foreach my $pattern (@combList) {

                            if (! exists $checkHash{$pattern}) {

                                push (@newList2, $pattern);
                                $checkHash{$pattern} = undef;
                            }
                        }

                        # While we're at it, let's sort the list
                        @newList2 = sort {lc($a) cmp lc($b)} (@newList2);
                        $profObj->ivPoke('noChannelList', @newList2);

                        # Delete the old IVs
                        delete $profObj->{tellPatternList};
                        delete $profObj->{noTellPatternList};
                        delete $profObj->{socialPatternList};
                        delete $profObj->{noSocialPatternList};
                        delete $profObj->{customDivertPatternList};
                        delete $profObj->{noCustomDivertPatternList};
                    }
                }
            }

            if ($version < 1_001_133) {

                # Update world profiles with to write a new logfile
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! $profObj->ivExists('logPrefHash', 'channels')) {

                        $profObj->ivAdd(
                            'logPrefHash',
                            'channels',
                            # Use the same setting as for the Divert task
                            $profObj->ivShow('logPrefHash', 'divert'),
                        );
                    }
                }
            }

            if ($version < 1_001_184 && $self->session) {

                # This version adds an (optional) attribute to triggers, aliases, macros and hooks
                #   (but not timers)
                foreach my $cage ($self->session->ivValues('cageHash')) {

                    if (
                        $cage->{cageType} eq 'trigger'
                        || $cage->{cageType} eq 'alias'
                        || $cage->{cageType} eq 'macro'
                        || $cage->{cageType} eq 'hook'
                    ) {
                        foreach my $interfaceObj ($cage->ivValues('interfaceHash')) {

                            $interfaceObj->ivAdd('attribHash', 'cooldown', 0);
                        }
                    }
                }
            }

            if ($version < 1_001_191) {

                # This version renames a world profile IV and a component object IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    my (@oldList, @newList);

                    if (! exists $profObj->{groupPatternList}) {

                        $profObj->{groupPatternList} = $profObj->{singleBackRefPatternList};
                        delete $profObj->{singleBackRefPatternList};

                        foreach my $componentObj ($profObj->ivValues('componentHash')) {

                            if (! exists $componentObj->{usePatternGroups}) {

                                $componentObj->{usePatternGroups}
                                    = $componentObj->{usePatternBackRefs};
                                delete $componentObj->{usePatternBackRefs};
                            }
                        }

                        # ->loginSpecialList is in groups of 3. It was previously necessary to
                        #   surround the third item in double quotes, if it contained a group
                        #   substring variable like $1, but that's no longer necessary, so remove
                        #   the quotes
                        @oldList = $profObj->loginSpecialList;
                        while (@oldList) {

                            my ($item, $item2, $item3);

                            $item = shift @oldList;
                            $item2 = shift @oldList;
                            $item3 = shift @oldList;

                            $item3 =~ s/^\"(.*)\"$/$1/;

                            push (@newList, $item, $item2, $item3);

                        }

                        $profObj->ivPoke('loginSpecialList', @newList);
                    }
                }
            }

            if ($version < 1_001_258) {

                # Update world profiles to a list in groups of 1 with a list in groups of 2
                my $profObj = $axmud::CLIENT->ivShow('worldProfHash', $self->name);
                if ($profObj) {

                    my @newList;

                    foreach my $pattern ($profObj->transientExitPatternList) {

                        push (@newList, $pattern, undef);
                    }

                    $profObj->ivPoke('transientExitPatternList', @newList);
                }
            }

            if ($version < 1_001_262 && $self->session) {

                # Update character profiles with new IVs
                foreach my $profObj ($self->session->ivValues('profHash')) {

                    if ($profObj->{category} eq 'char' && ! exists $profObj->{qpCurrent}) {

                        $profObj->{qpCurrent} = undef;
                        $profObj->ivPoke('qpCurrent', 0);
                        $profObj->{qpNextLevel} = undef;
                        $profObj->ivPoke('qpNextLevel', 0);
                        $profObj->{qpTotal} = undef;
                        $profObj->ivPoke('qpTotal', 0);

                        $profObj->{opCurrent} = undef;
                        $profObj->ivPoke('opCurrent', 0);
                        $profObj->{opNextLevel} = undef;
                        $profObj->ivPoke('opNextLevel', 0);
                        $profObj->{opTotal} = undef;
                        $profObj->ivPoke('opTotal', 0);
                    }
                }
            }

            if ($version < 1_001_263 && $self->session) {

                # Modify some IVs in world profiles
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    my (
                        $hashRef, $listRef,
                        %newHash,
                    );

                    if (exists $profObj->{constLocalWimpyMax}) {

                        # (These are replaced by new character profile IVs)
                        delete $profObj->{constLocalWimpyMax};
                        delete $profObj->{remoteWimpyMax};

                        # (->customStatusVarHash is replaced by new ->msdpStatusVarHash, with a
                        #   subset of its key-value pairs, with the keys/value reversed)
                        $hashRef = $profObj->{customStatusVarHash};
                        delete $profObj->{customStatusVarHash};

                        foreach my $key (keys %$hashRef) {

                            my $value = $$hashRef{$key};

                            # A few pre-configured worlds were using the wrong format, so ignore the
                            #   key-value pairs where the value is 0
                            if (defined $value && $value ne '0') {

                                $newHash{$value} = $key;
                            }
                        }

                        $profObj->{msdpStatusVarHash} = {};
                        $profObj->ivPoke('msdpStatusVarHash', %newHash);

                        # (->statusFormatList is just a renamed IV)
                        $listRef = $profObj->{displayFormatList};

                        # While we're at it, convert old custom variables from #var_name# to new
                        #   @var_name@ format
                        foreach my $line (@$listRef) {

                            $line =~ s/\#([\w\_]+)\#/\@$1\@/g;

                            # In addition, some old variables have been renamed
                            $line =~ s/fight_count/fight_string/;
                            $line =~ s/interact_count/interact_string/;
                            $line =~ s/interaction_count/interact_string/;
                            $line =~ s/coward_count/coward_string/;
                            $line =~ s/temp_fight_count/temp_fight_string/;
                            $line =~ s/temp_interact_count/temp_interact_string/;
                            $line =~ s/temp_interaction_count/temp_interact_string/;
                            $line =~ s/temp_coward_count/temp_coward_string/;
                            $line =~ s/quest_points/qp_current/;
                        }

                        $profObj->{statusFormatList} = [];
                        $profObj->ivPoke('statusFormatList', @$listRef);
                        delete $profObj->{displayFormatList};
                    }
                }

                # Update character profiles with new IVs
                foreach my $profObj ($self->session->ivValues('profHash')) {

                    if ($profObj->{category} eq 'char' && ! exists $profObj->{healthPoints}) {

                        # (This IV subsequently renamed and/or removed)
#                        $profObj->{healthPoints} = undef;
#                        $profObj->ivPoke('healthPoints', 0);
                        $profObj->{healthPoints} = 0;
#                        $profObj->{healthPointsMax} = undef;
#                        $profObj->ivPoke('healthPointsMax', 0);
                        $profObj->{healthPointsMax} = 0;

#                        $profObj->{magicPoints} = undef;
#                        $profObj->ivPoke('magicPoints', 0);
                        $profObj->{magicPoints} = 0;
#                        $profObj->{magicPointsMax} = undef;
#                        $profObj->ivPoke('magicPointsMax', 0);
                        $profObj->{magicPointsMax} = 0;

#                        $profObj->{energyPoints} = undef;
#                        $profObj->ivPoke('energyPoints', 0);
                        $profObj->{energyPoints} = 0;
#                        $profObj->{energyPointsMax} = undef;
#                        $profObj->ivPoke('energyPointsMax', 0);
                        $profObj->{energyPointsMax} = 0;

#                        $profObj->{guildPoints} = undef;
#                        $profObj->ivPoke('guildPoints', 0);
                        $profObj->{guildPoints} = 0;
#                        $profObj->{guildPointsMax} = undef;
#                        $profObj->ivPoke('guildPointsMax', 0);
                        $profObj->{guildPointsMax} = 0;

#                        $profObj->{socialPoints} = undef;
#                        $profObj->ivPoke('socialPoints', 0);
                        $profObj->{socialPoints} = 0;
#                        $profObj->{socialPointsMax} = undef;
#                        $profObj->ivPoke('socialPointsMax', 0);
                        $profObj->{socialPointsMax} = 0;

                        $profObj->{remoteWimpyMax} = undef;
                        $profObj->ivPoke('remoteWimpyMax', 100);
                        $profObj->{constLocalWimpyMax} = 199;
                    }
                }
            }

            if ($version < 1_001_286 && $self->session) {

                my %hash = (
                    'kp_up'         => 'up',
                    'kp_down'       => 'down',
                    'kp_left'       => 'left',
                    'kp_right'      => 'right',
                    'kp_page_up'    => 'page_up',
                    'kp_page_down'  => 'page_down',
                    'kp_home'       => 'home',
                    'kp_end'        => 'end',
                    'kp_insert'     => 'insert',
                    'kp_delete'     => 'delete',
                );

                # This version removes some Axmud standard keycodes
                # Check macros in each macro cage, and convert any removed keycodes to their
                #   replacements
                foreach my $cage ($self->session->ivValues('cageHash')) {

                    if ($cage->{cageType} eq 'macro') {

                        foreach my $macroObj ($cage->ivValues('interfaceHash')) {

                            # The macro stimulus is a keycode/keycode string
                            my $stimulus = $macroObj->stimulus;

                            foreach my $regex (keys %hash) {

                                my $subst = $hash{$regex};

                                $stimulus =~ s/$regex/$subst/;
                            }

                            $macroObj->ivPoke('stimulus', $stimulus);
                        }
                    }
                }
            }

            if ($version < 1_001_298) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{mxpStatusVarHash}) {

                        $profObj->{mxpStatusVarHash} = {};
                        $profObj->ivEmpty('mxpStatusVarHash');
                    }
                }
            }

            if ($version < 1_001_308) {

                # Update world profiles by deleting an IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    delete $profObj->{'strictPromptsMode'};
                }
            }

            if ($version < 1_001_365) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{exitStateTagHash}) {

                        $profObj->{exitStateTagHash} = {};
                        $profObj->ivEmpty('exitStateTagHash');
                    }
                }
            }

            if ($version < 1_001_374) {

                # Update world profiles with a new IV
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{duplicateReplaceString}) {

                        $profObj->{duplicateReplaceString} = undef;
                        $profObj->ivUndef('duplicateReplaceString');
                    }
                }
            }

            if ($version < 1_001_382 && $self->session) {

                # This version adds a new trigger attribute. Update every trigger cage
                foreach my $cage ($self->session->ivValues('cageHash')) {

                    if ($cage->{cageType} eq 'trigger') {

                        foreach my $trigObj ($cage->ivValues('interfaceHash')) {

                            $trigObj->ivAdd('attribHash', 'ignore_response', FALSE);
                        }
                    }
                }
            }

            if ($version < 1_002_056) {

                # Update world profiles with new IVs
                foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

                    if (! exists $profObj->{mxpRoomTagStart}) {

                        $profObj->{mxpRoomTagStart} = undef;
                        $profObj->ivUndef('mxpRoomTagStart');
                        $profObj->{mxpRoomTagStop} = undef;
                        $profObj->ivUndef('mxpRoomTagStop');
                    }
                }
            }

            if ($version < 1_002_109 && $self->session) {

                # This version corrects a misspelled standard hook event
                foreach my $cage ($self->session->ivValues('cageHash')) {

                    if ($cage->{cageType} eq 'hook') {

                        foreach my $interfaceObj ($cage->ivValues('interfaceHash')) {

                            if ($interfaceObj->stimulus eq 'change_vivible') {

                                $interfaceObj->ivPoke('stimulus', 'change_visible');
                            }
                        }
                    }
                }
            }

        ### worldmodel ###########################################################################

        } elsif ($self->fileType eq 'worldmodel') {

            # (Import the world model, for convenience)
            $wmObj = $self->session->worldModelObj;

            # (Changes that must be made before any other changes)

            if ($version < 1_000_871) {

                # This version renames a number of IVs
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

            if ($version < 1_001_289) {

                # This version adds new IVs to the world model
                if (! exists $wmObj->{adjacentMode}) {

                    $wmObj->{adjacentMode} = undef;
                    $wmObj->ivPoke('adjacentMode', 'near');
                    $wmObj->{adjacentCount} = undef;
                    $wmObj->ivPoke('adjacentCount', 1);
                }
            }

            # (All remaining changes, in order)

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

#            if ($version < 1_000_018) {
#
#                # Update the room flag list
#                $wmObj->updateRoomFlags($self->session);
#            }

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
                        'Room tags and room guilds are now drawn in the Automapper window at a'
                        . ' slightly different position. Do you want to adjust your existing'
                        . ' room tags/guilds, so that they appear in the same position as before?',
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

                        # (This IV subsequently renamed and/or removed)
#                        $exitObj->{info} = undef;
#                        $exitObj->ivPoke('info', undef);
                        $exitObj->{info} = undef;
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

                        # (This IV subsequently renamed and/or removed)
#                        $exitObj->ivPoke('state', 6);
                        $exitObj->{state} = 6;
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

                    # (This IV subsequently renamed and/or removed)
#                    $wmObj->{updateOrnamentsFlag} = undef;
#                    $wmObj->ivPoke('updateOrnamentsFlag', FALSE);
                    $wmObj->{updateOrnamentsFlag} = FALSE;
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

#            if ($version < 1_000_572) {
#
#                # Update the room flag list
#                $wmObj->updateRoomFlags($self->session);
#            }

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

#            if ($version < 1_000_624) {
#
#                # Update the room flag list
#                $wmObj->updateRoomFlags($self->session);
#            }

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

                # This version removes three IVs which have been moved to GA::Client
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

            if ($version < 1_001_030) {

                # Add the new IV to all room model objects
                foreach my $obj ($wmObj->ivValues('roomModelHash')) {

                    if (! exists $obj->{tempRoomCmdList}) {

                        $obj->{tempRoomCmdList} = [];
                        $obj->ivEmpty('tempRoomCmdList');
                    }
                }
            }

            if ($version < 1_001_063) {

                # General update to the world model, aimed at drastically reducing its size by
                #   combining rarely-used IVs into single hash IVs

                # GA::Obj::Exit->breakHash, ->pickHash, ->unlockHash, ->openHash, ->closeHash,
                #   ->lockHash and ->ornamentFlag are removed entirely
                # ->info is just renamed, not removed/merged
                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    if (! exists $exitObj->{'exitOrnament'}) {

                        $exitObj->{exitOrnament} = undef;

                        if ($exitObj->{breakFlag}) {
                            $exitObj->ivPoke('exitOrnament', 'break');
                        } elsif ($exitObj->{pickFlag}) {
                            $exitObj->ivPoke('exitOrnament', 'pick');
                        } elsif ($exitObj->{lockFlag}) {
                            $exitObj->ivPoke('exitOrnament', 'lock');
                        } elsif ($exitObj->{openFlag}) {
                            $exitObj->ivPoke('exitOrnament', 'open');
                        } elsif ($exitObj->{impassFlag}) {
                            $exitObj->ivPoke('exitOrnament', 'impass');
                        } else {
                            $exitObj->ivPoke('exitOrnament', 'none');
                        }

                        delete $exitObj->{breakFlag};
                        delete $exitObj->{pickFlag};
                        delete $exitObj->{lockFlag};
                        delete $exitObj->{openFlag};
                        delete $exitObj->{impassFlag};
                        delete $exitObj->{ornamentFlag};

                        $exitObj->{exitInfo} = undef;
                        $exitObj->ivPoke('exitInfo', $exitObj->{info});
                        delete $exitObj->{info};

                        $exitObj->{doorHash} = {};

                        if (defined $exitObj->{breakCmd}) {

                            $exitObj->ivAdd('doorHash', 'break', $exitObj->{breakCmd});
                        }

                        if (defined $exitObj->{pickCmd}) {

                            $exitObj->ivAdd('doorHash', 'pick', $exitObj->{pickCmd});
                        }

                        if (defined $exitObj->{unlockCmd}) {

                            $exitObj->ivAdd('doorHash', 'unlock', $exitObj->{unlockCmd});
                        }

                        if (defined $exitObj->{openCmd}) {

                            $exitObj->ivAdd('doorHash', 'open', $exitObj->{openCmd});
                        }

                        if (defined $exitObj->{closeCmd}) {

                            $exitObj->ivAdd('doorHash', 'close', $exitObj->{closeCmd});
                        }

                        if (defined $exitObj->{lockCmd}) {

                            $exitObj->ivAdd('doorHash', 'lock', $exitObj->{lockCmd});
                        }

                        delete $exitObj->{breakHash};
                        delete $exitObj->{pickHash};
                        delete $exitObj->{unlockHash};
                        delete $exitObj->{openHash};
                        delete $exitObj->{closeHash};
                        delete $exitObj->{lockHash};

                        delete $exitObj->{breakCmd};
                        delete $exitObj->{pickCmd};
                        delete $exitObj->{unlockCmd};
                        delete $exitObj->{openCmd};
                        delete $exitObj->{closeCmd};
                        delete $exitObj->{lockCmd};
                    }
                }
            }

            if ($version < 1_001_064) {

                # This version adds a new IV to the world model
                if (! exists $wmObj->{buttonSetList}) {

                    $wmObj->{buttonSetList} = [];
                    $wmObj->ivEmpty('buttonSetList');
                }
            }

            if ($version < 1_001_069) {

                # This version adds a new IV to the world model
                if (! exists $wmObj->{preferRoomFlagList}) {

                    $wmObj->{preferRoomFlagList} = [];
                    $wmObj->ivEmpty('preferRoomFlagList');
                }
            }

            if ($version < 1_001_070) {

                # Apparently, $self->update_modelobj_all wasn't called for the world model's
                #   painter object (a non-model GA::ModelObj::Room object), and this causes a crash
                #   if the user tries to open the painter's edit window in a world model created
                #   before ->update_modelobj_all was
                # Foolproof fix is to reset the painter, no questions asked
                $wmObj->resetPainter($self->session);
            }

            if ($version < 1_001_071) {

                # Add the new IV to all room model objects
                foreach my $obj ($wmObj->ivValues('roomModelHash')) {

                    if (! exists $obj->{wildMode}) {

                        $obj->{wildMode} = undef;
                        $obj->ivPoke('wildMode', 'normal');
                    }
                }
            }

            if ($version < 1_001_077) {

                # Update and rename a world model IV
                if (! exists $wmObj->{constPainterIVList}) {

                    $wmObj->{constPainterIVList} = [
                        'wildMode',
                        'titleList',
                        'descripHash',
                        'exclusiveFlag',
                        'exclusiveHash',
                        'roomFlagHash',
                        'roomGuild',
                        'searchHash',
                    ];

                    delete $wmObj->{painterIVList};
                }
            }

            if ($version < 1_001_080) {

                # This version renames an IV to the world model
                if (exists $wmObj->{basicMappingMode}) {

                    $wmObj->{basicMappingFlag} = undef;
                    $wmObj->ivPoke('basicMappingFlag', $wmObj->{basicMappingMode});
                    delete $wmObj->{basicMappingMode};
                }
            }

            if ($version < 1_001_082) {

                # This version adds a new IV to the world model
                if (! exists $wmObj->{craftyMovesFlag}) {

                    $wmObj->{craftyMovesFlag} = undef;
                    $wmObj->ivPoke('craftyMovesFlag', FALSE);
                }
            }

            if ($version < 1_001_084) {

                # This version adds new IVs to the world model
                if (! exists $wmObj->{paintFromTitleHash}) {

                    $wmObj->{paintFromTitleHash} = {};
                    $wmObj->ivEmpty('paintFromTitleHash');
                    $wmObj->{paintFromDescripHash} = {};
                    $wmObj->ivEmpty('paintFromDescripHash');
                    $wmObj->{paintFromExitHash} = {};
                    $wmObj->ivEmpty('paintFromExitHash');
                    $wmObj->{paintFromObjHash} = {};
                    $wmObj->ivEmpty('paintFromObjHash');
                    $wmObj->{paintFromRoomCmdHash} = {};
                    $wmObj->ivEmpty('paintFromRoomCmdHash');
                }
            }

            if ($version < 1_001_087) {

                # This version adds a new IV to the world model
                if (! exists $wmObj->{preferBGColourList}) {

                    $wmObj->{preferBGColourList} = [];
                    $wmObj->ivEmpty('preferBGColourList');
                }

                # This version also adds new IVs to regionmaps
                foreach my $regionmapObj ($wmObj->ivValues('regionmapHash')) {

                    if (! exists $regionmapObj->{gridColourBlockHash}) {

                        $regionmapObj->{gridColourBlockHash} = {};
                        $regionmapObj->ivEmpty('gridColourBlockHash');
                        $regionmapObj->{gridColourObjHash} = {};
                        $regionmapObj->ivEmpty('gridColourObjHash');
                        $regionmapObj->{colourObjCount} = undef;
                        $regionmapObj->ivPoke('colourObjCount', 0);
                    }
                }
            }

            if ($version < 1_001_089) {

                # This version adds new IVs to the world model
                if (! exists $wmObj->{collectCheckedDirsFlag}) {

                    $wmObj->{defaultCheckedDirColour} = undef;
                    $wmObj->ivPoke('defaultCheckedDirColour', '#FF96AA');
                    $wmObj->{checkedDirColour} = undef;
                    $wmObj->ivPoke('checkedDirColour', '#FF96AA');

                    $wmObj->{collectCheckedDirsFlag} = undef;
                    $wmObj->ivPoke('collectCheckedDirsFlag', FALSE);
                    $wmObj->{drawCheckedDirsFlag} = undef;
                    $wmObj->ivPoke('drawCheckedDirsFlag', TRUE);
                    $wmObj->{checkableDirMode} = undef;
                    $wmObj->ivPoke('checkableDirMode', 'diku');
                }

                # It also adds a new IV to all room model objects
                foreach my $obj ($wmObj->ivValues('roomModelHash')) {

                    if (! exists $obj->{checkedDirHash}) {

                        $obj->{checkedDirHash} = {};
                        $obj->ivEmpty('checkedDirHash');
                    }
                }
            }

            if ($version < 1_001_097) {

                # This version adds new IVs to the world model
                if (! exists $wmObj->{mapLabelStyleHash}) {

                    $wmObj->{mapLabelStyleHash} = {};

                    $wmObj->{mapLabelStyleHash}{'Style 1'} = Games::Axmud::Obj::MapLabelStyle->new(
                        $self->session,
                        'Style 1',
                        '#C90640',
                    );

                    $wmObj->{mapLabelStyleHash}{'Style 2'} = Games::Axmud::Obj::MapLabelStyle->new(
                        $self->session,
                        'Style 2',
                        '#FF40E0',
                    ),

                    $wmObj->{mapLabelStyleHash}{'Style 3'} = Games::Axmud::Obj::MapLabelStyle->new(
                        $self->session,
                        'Style 3',
                        '#000000',
                        undef,          # No underlay colour
                        2,
                    );

                    $wmObj->{mapLabelStyleHash}{'Style 4'} = Games::Axmud::Obj::MapLabelStyle->new(
                        $self->session,
                        'Style 4',
                        '#000000',
                        undef,          # No underlay colour
                        4
                    );

                    $wmObj->{mapLabelStyle} = undef;
                    $wmObj->ivPoke('mapLabelStyle', 'Style 1');
                }

                # This version also adds new IVs to map label objects
                foreach my $regionmapObj ($wmObj->ivValues('regionmapHash')) {

                    foreach my $mapLabelObj ($regionmapObj->ivValues('gridLabelHash')) {

                        if (! exists $mapLabelObj->{style}) {

                            $mapLabelObj->{style} = undef;

                            $mapLabelObj->{textColour} = undef;
                            $mapLabelObj->ivPoke('textColour', $wmObj->defaultMapLabelColour);
                            $mapLabelObj->{underlayColour} = undef;
                            $mapLabelObj->ivUndef('underlayColour');
                            $mapLabelObj->{italicsFlag} = undef;
                            $mapLabelObj->ivPoke('italicsFlag', FALSE);
                            $mapLabelObj->{boldFlag} = undef;
                            $mapLabelObj->ivPoke('boldFlag', FALSE);
                            $mapLabelObj->{underlineFlag} = undef;
                            $mapLabelObj->ivPoke('underlineFlag', FALSE);
                            $mapLabelObj->{strikeFlag} = undef;
                            $mapLabelObj->ivPoke('strikeFlag', FALSE);
                            $mapLabelObj->{boxFlag} = undef;
                            $mapLabelObj->ivPoke('boxFlag', FALSE);
                            $mapLabelObj->{gravity} = undef;
                            $mapLabelObj->ivPoke('gravity', 'south');

                            if ($mapLabelObj->{relSize} == 1) {

                                $mapLabelObj->ivPoke('style', 'Style 1');

                            } elsif ($mapLabelObj->{relSize} == 2) {

                                $mapLabelObj->ivPoke('style', 'Style 3');

                            } elsif ($mapLabelObj->{relSize} == 4) {

                                $mapLabelObj->ivPoke('style', 'Style 4');

                            } else {

                                # Failsafe
                                $mapLabelObj->ivPoke('style', 'Style 1');
                            }
                        }
                    }
                }
            }

            if ($version < 1_001_101) {

                # This version adds new IVs to the world model
                if (! exists $wmObj->{defaultSelectBoxColour}) {

                    $wmObj->{defaultSelectBoxColour} = undef;
                    $wmObj->ivPoke('defaultSelectBoxColour', '#0088FF');
                    $wmObj->{selectBoxColour} = undef;
                    $wmObj->ivPoke('selectBoxColour', '#0088FF');
                }
            }

            if ($version < 1_001_104) {

                # This version adds new IVs to the world model
                if (! exists $wmObj->{mapLabelAlignXFlag}) {

                    $wmObj->{mapLabelAlignXFlag} = undef;
                    $wmObj->ivPoke('mapLabelAlignXFlag', FALSE);
                    $wmObj->{mapLabelAlignYFlag} = undef;
                    $wmObj->ivPoke('mapLabelAlignYFlag', FALSE);
                }
            }

            if ($version < 1_001_107) {

                my ($count, $hashRef, $listRef);

                # This version reorganises room flag IVs. Convert data in the old format to the
                #   new format
                if (! exists $wmObj->{roomFilterApplyHash}) {

                    # Add new IV definitions
                    $wmObj->{roomFilterApplyHash} = {};
                    $wmObj->ivEmpty('roomFilterApplyHash');
                    $wmObj->{roomFlagHash} = {};
                    $wmObj->ivEmpty('roomFlagHash');

                    # Set up ->roomFilterApplyHash, which replaces the old ->roomFilterHash
                    foreach my $filter ($axmud::CLIENT->constRoomFilterList) {

                        if ($wmObj->{roomFilterHash}{$filter}) {
                            $wmObj->ivAdd('roomFilterApplyHash', $filter, TRUE);
                        } else {
                            $wmObj->ivAdd('roomFilterApplyHash', $filter, FALSE);
                        }
                    }

                    # Create the default set of room flag objects, stored in new ->roomFlagHash
                    $wmObj->setupRoomFlags($self->session);

                    # Incorporate any changes to room flag colours made by the user
                    $hashRef = $wmObj->{roomFlagTextHash};
                    foreach my $oldFlag (keys %$hashRef) {

                        my ($newObj, $colour);

                        # Get the new room flag object
                        $newObj = $wmObj->ivShow('roomFlagHash', $oldFlag);

                        # Update colour
                        $colour = $wmObj->{roomFlagColourHash}{$oldFlag};
                        if (defined $colour) {

                            $newObj->ivPoke('colour', $colour);
                        }
                    }

                    # Set the priority for every room flag object, using the unchanged
                    #   ->roomFlagOrderedList IV
                    $count = 0;
                    $listRef = $wmObj->{roomFlagOrderedList};
                    foreach my $roomFlag (@$listRef) {

                        $count++;

                        my $newObj = $wmObj->ivShow('roomFlagHash', $roomFlag);
                        $newObj->ivPoke('priority', $count);
                    }

                    # Remove old IV definitions
                    delete $wmObj->{defaultRoomFilterList};
                    delete $wmObj->{defaultRoomFilterHash};
                    delete $wmObj->{defaultRoomFlagTextHash};
                    delete $wmObj->{defaultRoomFlagPriorityHash};
                    delete $wmObj->{defaultRoomFlagFilterHash};
                    delete $wmObj->{defaultRoomFlagColourHash};
                    delete $wmObj->{defaultRoomFlagDescripHash};
                    delete $wmObj->{defaultRoomFlagOrderedList};
                    delete $wmObj->{defaultRoomFlagReverseHash};

                    delete $wmObj->{roomFilterList};
                    delete $wmObj->{roomFilterHash};
                    delete $wmObj->{roomFlagTextHash};
                    delete $wmObj->{roomFlagPriorityHash};
                    delete $wmObj->{roomFlagFilterHash};
                    delete $wmObj->{roomFlagColourHash};
                    delete $wmObj->{roomFlagDescripHash};
                    # ( ->roomFlagOrderedList is retained)
                    delete $wmObj->{roomFlagReverseHash};
                }
            }

            if ($version < 1_001_112) {

                # Update the room flag list
                $wmObj->updateRoomFlags($self->session);
            }

            if ($version < 1_001_115) {

                # This version corrects drawing issues with unallocated exits, on which a 'confirm
                #   two-way exit' operation was performed
                # Check every exit in the model, looking 2-way exits and not region exits, at least
                #   one of which has been allocated a direction, whose ->mapDirs are not opposites
                #   and which are not marked as broken exits
                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    my $twinExitObj;

                    if (
                        defined $exitObj->twinExit
                        && ! $exitObj->regionFlag
                        && $exitObj->drawMode eq 'perm_alloc'
                        && ! $exitObj->brokenFlag
                    ) {
                        $twinExitObj = $wmObj->ivShow('exitModelHash', $exitObj->twinExit);

                        if (
                            ! $twinExitObj->brokenFlag
                            && $axmud::CLIENT->ivShow('constOppDirHash', $exitObj->mapDir)
                                    ne $twinExitObj->mapDir
                        ) {
                            # The problem is fixed by marking both as bent broken exits
                            $exitObj->ivPoke('brokenFlag', TRUE);
                            $exitObj->ivPoke('bentFlag', TRUE);
                            $twinExitObj->ivPoke('brokenFlag', TRUE);
                            $twinExitObj->ivPoke('bentFlag', TRUE);
                        }
                    }
                }
            }

            if ($version < 1_001_118) {

                # This version adds new IVs to the world model
                if (! exists $wmObj->{showNotesFlag}) {

                    $wmObj->{showNotesFlag} = undef;
                    $wmObj->ivPoke('showNotesFlag', TRUE);
                    $wmObj->{allowCtrlCopyFlag} = undef;
                    $wmObj->ivPoke('allowCtrlCopyFlag', TRUE);
                }
            }

            if ($version < 1_001_234) {

                # This version adds a new IV to the world model
                if (! exists $wmObj->{mapLabelTextViewFlag}) {

                    $wmObj->{mapLabelTextViewFlag} = undef;
                    $wmObj->ivPoke('mapLabelTextViewFlag', FALSE);
                }
            }

            if ($version < 1_001_235) {

                # This version adds a new IV to all room model objects
                foreach my $obj ($wmObj->ivValues('roomModelHash')) {

                    if (! exists $obj->{unspecifiedPatternList}) {

                        $obj->{unspecifiedPatternList} = [];
                        $obj->ivEmpty('unspecifiedPatternList');
                    }
                }
            }

            if ($version < 1_001_240) {

                # This version adds new IVs to the world model
                if (! exists $wmObj->{autoSlideMode}) {

                    $wmObj->{autoSlideMode} = undef;
                    $wmObj->ivPoke('autoSlideMode', 'default');
                    $wmObj->{autoSlideMax} = undef;
                    $wmObj->ivPoke('autoSlideMax', 10);
                }
            }

            if ($version < 1_001_241) {

                # This version removes an IV from all room model objects
                foreach my $obj ($wmObj->ivValues('roomModelHash')) {

                    delete $obj->{everMatchedFlag};
                }
            }

            if ($version < 1_001_250) {

                # This version adds a new IV to the world model
                if (! exists $wmObj->{autoRescueFlag}) {

                    $wmObj->{autoRescueFlag} = undef;
                    $wmObj->ivPoke('autoRescueFlag', FALSE);
                    $wmObj->{autoRescueFirstFlag} = undef;
                    $wmObj->ivPoke('autoRescueFirstFlag', FALSE);
                    $wmObj->{autoRescuePromptFlag} = undef;
                    $wmObj->ivPoke('autoRescuePromptFlag', FALSE);
                }
            }

            if ($version < 1_001_251) {

                # This version adds new IVs to the world model
                if (! exists $wmObj->{autoCompareMode}) {

                    $wmObj->{autoCompareMode} = undef;
                    if (! $wmObj->{autoCompareFlag}) {
                        $wmObj->ivPoke('autoCompareMode', 'default');
                    } else {
                        $wmObj->ivPoke('autoCompareMode', 'new');
                    }

                    $wmObj->{autoCompareAllFlag} = undef;
                    $wmObj->ivPoke('autoCompareAllFlag', FALSE);
                    $wmObj->{autoCompareMax} = undef;
                    $wmObj->ivPoke('autoCompareMax', 0);
                }
            }

            if ($version < 1_001_254) {

                # This version adds new IVs to the world model
                if (! exists $wmObj->{autoRescueNoMoveFlag}) {

                    $wmObj->{autoRescueNoMoveFlag} = undef;
                    $wmObj->ivPoke('autoRescueNoMoveFlag', FALSE);
                    $wmObj->{autoRescueVisitsFlag} = undef;
                    $wmObj->ivPoke('autoRescueVisitsFlag', FALSE);
                    $wmObj->{autoRescueForceFlag} = undef;
                    $wmObj->ivPoke('autoRescueForceFlag', FALSE);
                }
            }

#            if ($version < 1_001_289) {
#
#                # This version adds new IVs to the world model
#                if (! exists $wmObj->{adjacentMode}) {
#
#                    $wmObj->{adjacentMode} = undef;
#                    $wmObj->ivPoke('adjacentMode', 'near');
#                    $wmObj->{adjacentCount} = undef;
#                    $wmObj->ivPoke('adjacentCount', 1);
#                }
#            }

            if ($version < 1_001_290) {

                # This version adds a new IV to exit objects in the world model
                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    if (! exists $exitObj->{altDir}) {

                        $exitObj->{altDir} = undef;
                        $exitObj->ivUndef('altDir');
                    }
                }
            }

            if ($version < 1_001_295) {

                # This version adds new IVs to the world model
                if (! exists $wmObj->{defaultMysteryExitColour}) {

                    $wmObj->{defaultMysteryExitColour} = undef;
                    $wmObj->ivPoke('defaultMysteryExitColour', '#900700');
                    $wmObj->{mysteryExitColour} = undef;
                    $wmObj->ivPoke('mysteryExitColour', '#900700');
                }
            }

            if ($version < 1_001_295) {

                # This version adds a new IV to the world model
                if (! exists $wmObj->{quickPaintMultiFlag}) {

                    $wmObj->{quickPaintMultiFlag} = undef;
                    $wmObj->ivPoke('quickPaintMultiFlag', FALSE);
                }
            }

            if ($version < 1_001_306) {

                # This version fixes a flaw in the world model, in which room tags aren't deleted
                #   when a whole region is deleted
                foreach my $tag ($wmObj->ivKeys('roomTagHash')) {

                    my ($roomNum, $roomObj);

                    $roomNum = $wmObj->ivShow('roomTagHash', $tag);
                    $roomObj = $wmObj->ivShow('roomModelHash', $roomNum);

                    if (! $roomObj || ! defined $roomObj->roomTag || $roomObj->roomTag ne $tag) {

                        $wmObj->ivDelete('roomTagHash', $tag);
                    }
                }
            }

            if ($version < 1_001_314) {

                # This version adds a new IV to all map label objects
                foreach my $regionmapObj ($wmObj->ivValues('regionmapHash')) {

                    foreach my $mapLabelObj ($regionmapObj->ivValues('gridLabelHash')) {

                        # e.g. 'town_42'
                        $mapLabelObj->{id} = $mapLabelObj->{region} . '_' . $mapLabelObj->{number};
                    }
                }
            }

            if ($version < 1_001_318) {

                # Custom room flags did not have their ->customFlag IV set correctly. Fix it
                foreach my $roomFlagObj ($wmObj->ivValues('roomFlagHash')) {

                    if ($roomFlagObj->filter eq 'custom') {

                        $roomFlagObj->ivPoke('customFlag', TRUE);
                    }
                }
            }

            if ($version < 1_001_320) {

                # This version removes an IV from region model objects
                foreach my $regionObj ($wmObj->ivValues('regionModelHash')) {

                    delete $regionObj->{regionmapObj};
                }
            }

            if ($version < 1_001_325) {

                # This version adds new IVs room model objects
                foreach my $roomObj ($wmObj->ivValues('roomModelHash')) {

                    my $listRef;

                    if (! exists $roomObj->{invRepExitHash}) {

                        $roomObj->{involuntaryExitHash} = {};
                        $roomObj->ivEmpty('involuntaryExitHash');
                        $roomObj->{involuntaryExitPatternHash} = {};
                        $roomObj->ivEmpty('involuntaryExitPatternHash');

                        # Convert ->involuntaryExitPatternList to the new IV
                        $listRef = $roomObj->{involuntaryExitPatternList};
                        foreach my $pattern (@$listRef) {

                            $roomObj->ivAdd('involuntaryExitPatternHash', $pattern, undef);
                        }

                        delete $roomObj->{involuntaryExitPatternList};
                    }
                }
            }

            if ($version < 1_001_327) {

                my %newHash;

                # Room tags are supposed to be stored in lower-case letters. This version makes sure
                #   that is so
                foreach my $tag ($wmObj->ivKeys('roomTagHash')) {

                    $newHash{lc($tag)} = $wmObj->ivShow('roomTagHash', $tag);
                }

                $wmObj->ivPoke('roomTagHash', %newHash);

                foreach my $roomObj ($wmObj->ivValues('roomModelHash')) {

                    my $listRef;

                    if (defined $roomObj->roomTag) {

                        $roomObj->ivPoke('roomTag', lc($roomObj->roomTag));
                    }

                    # This version also adds a new IV to room model objects, and renames an existing
                    #   one
                    if (! exists $roomObj->{repulseExitPatternHash}) {

                        $roomObj->{repulseExitPatternHash} = {};
                        $roomObj->ivEmpty('repulseExitPatternHash');

                        # Convert ->repulseExitPatternList to the new IV
                        $listRef = $roomObj->{repulseExitPatternList};
                        foreach my $pattern (@$listRef) {

                            $roomObj->ivAdd('repulseExitPatternHash', $pattern, undef);
                        }

                        delete $roomObj->{repulseExitPatternList};

                        # Update the IV name
                        $roomObj->{invRepExitHash} = $roomObj->{involuntaryExitHash};
                        delete $roomObj->{involuntaryExitHash};
                    }
                }
            }

            if ($version < 1_001_328) {

                my %regionHash;

                # This version repairs some errors in exit model objects introduced in certain
                #   situations
                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    my ($roomObj, $regionObj);

                    # At some point in the past, two-way exits had their ->oneWayDir IV wrongly set.
                    #   This problem does not apply to more recent Axmud versions. Just update all
                    #   exits
                    if (! $exitObj->oneWayFlag && defined $exitObj->oneWayDir) {

                        $exitObj->ivUndef('oneWayDir');
                    }

                    # This error is fixed in this version
                    if (! $exitObj->regionFlag && ($exitObj->superFlag || $exitObj->notSuperFlag)) {

                        $exitObj->ivPoke('superFlag', FALSE);
                        $exitObj->ivPoke('notSuperFlag', FALSE);

                        $roomObj = $wmObj->ivShow('modelHash', $exitObj->parent);
                        $regionObj = $wmObj->ivShow('modelHash', $roomObj->parent);

                        # Any region paths using the exits will have to be updated
                        $wmObj->ivAdd('updatePathHash', $exitObj->number, $regionObj->name);
                        $wmObj->ivAdd('updateBoundaryHash', $exitObj->number, $regionObj->name);
                    }
                }
            }

            if ($version < 1_001_329) {

                my %checkHash;

                $self->writeText('Applying essential world model update. Please be patient...');
                $axmud::CLIENT->desktopObj->updateWidgets(
                    $self->_objClass . '->updateExtractedData',
                );

                # When pathfinding routines were updated to allow paths through adjacent regions,
                #   region paths may have been affected. In addition, there were some problems with
                #   'safe' region paths which are supposed to avoid rooms with hazardous room flags,
                #   but which didn't (in certain situations)
                # Check all region paths and replace any whose rooms are not in the same region
                OUTER: foreach my $regionmapObj ($wmObj->ivValues('regionmapHash')) {

                    INNER: foreach my $regionPathObj ($regionmapObj->ivValues('regionPathHash')) {

                        if (! exists $checkHash{$regionPathObj->startExit}) {

                            foreach my $roomNum ($regionPathObj->roomList) {

                                my ($roomObj, $firstExitObj);

                                # (For speed, don't use ->ivShow)
                                $roomObj = $wmObj->{modelHash}{$roomNum};
                                $firstExitObj = $wmObj->{exitModelHash}{$regionPathObj->startExit};

                                if (
                                    $roomObj
                                    && $firstExitObj
                                    && $roomObj->parent ne $regionmapObj->number
                                ) {
                                    # Any region paths using the first exit will have to be updated
                                    $wmObj->ivAdd(
                                        'updatePathHash',
                                        $firstExitObj->number,
                                        $regionmapObj->name,
                                    );

                                    # (Only need to add each exit once)
                                    $checkHash{$regionPathObj->startExit} = undef;

                                    # (Don't need to check the rest of the rooms in this path)
                                    next INNER;
                                }
                            }
                        }
                    }

                    # Update those region paths now
                    if ($wmObj->updatePathHash) {

                        $wmObj->updateRegionPaths($self->session);
                    }

                    # Now check for 'safe' region paths which should not have room with hazardous
                    #   room flags, but do
                    INNER: foreach my $regionPathObj (
                        $regionmapObj->ivValues('safeRegionPathHash')
                    ) {
                        if (! exists $checkHash{$regionPathObj->startExit}) {

                            foreach my $roomNum ($regionPathObj->roomList) {

                                my ($roomObj, $firstExitObj);

                                # (For speed, don't use ->ivShow)
                                $roomObj = $wmObj->{modelHash}{$roomNum};
                                $firstExitObj = $wmObj->{exitModelHash}{$regionPathObj->startExit};

                                foreach my $roomFlag ($roomObj->ivKeys('roomFlagHash')) {

                                    if (
                                        $axmud::CLIENT->ivExists('constRoomHazardHash', $roomFlag)
                                    ) {
                                        $regionmapObj->removePaths(
                                            $regionPathObj->startExit . '_'
                                            . $regionPathObj->stopExit,
                                            'safeRegionPathHash',
                                        );

                                        # (Don't need to check the rest of the rooms in this path)
                                        next INNER;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if ($version < 1_001_335) {

                # This version fixes a bug in which each regionmap's highest and lowest occupied
                #   levels were set only with rooms, not with rooms and labels
                # Reset all highest/lowest levels
                foreach my $regionmapObj ($wmObj->ivValues('regionmapHash')) {

                    $wmObj->ivAdd('checkLevelsHash', $regionmapObj->name, undef);
                }

                $wmObj->updateRegionLevels();
            }

            if ($version < 1_001_358) {

                # This version adds new IVs to the world model
                if (! exists $wmObj->{preDrawMinRooms}) {

                    $wmObj->{preDrawMinRooms} = undef;
                    $wmObj->ivPoke('preDrawMinRooms', 500);
                    $wmObj->{queueDrawMaxObjs} = undef;
                    $wmObj->ivPoke('queueDrawMaxObjs', 500);
                }
            }

#            if ($version < 1_001_358) {
#
#                # This version adds new IVs to the world model
#                if (! exists $wmObj->{fixedRoomTagFlag}) {
#
#                    $wmObj->{fixedRoomTagFlag} = undef;
#                    $wmObj->ivPoke('fixedRoomTagFlag', FALSE);
#                    $wmObj->{fixedRoomGuildFlag} = undef;
#                    $wmObj->ivPoke('fixedRoomGuildFlag', FALSE);
#                    $wmObj->{fixedExitTagFlag} = undef;
#                    $wmObj->ivPoke('fixedExitTagFlag', FALSE);
#                    $wmObj->{fixedLabelFlag} = undef;
#                    $wmObj->ivPoke('fixedLabelFlag', FALSE);
#                }
#            }

            if ($version < 1_001_376) {

                # This version adds a new IV to the world model
                if (! exists $wmObj->{retainDrawMinRooms}) {

                    $wmObj->{retainDrawMinRooms} = undef;
                    $wmObj->ivPoke('retainDrawMinRooms', 500);
                }
            }

            if ($version < 1_001_408) {

                # This version compresses the world model. Before we do that, the ->_objName and
                #   ->name IVs for room model object have become standardised, no longer depending
                #   on the room's title or verbose description; update all room objects
                foreach my $roomObj ($wmObj->ivValues('roomModelHash')) {

                    $roomObj->{_objName} = 'room';
                    $roomObj->{name} = 'room';
                }

                # Same for exit object, which no longer take the exit's direction as its ->name
                #   (since the direction can change anyway)
                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    $exitObj->{_objName} = 'exit';
                    $exitObj->{name} = 'exit';
                }

                # Now we can compress the world model. For each room object and exit object, any IVs
                #   which are set to default values can be completely removed. The new code gets its
                #   default values from the room object and the exit object stored in the global
                #   variables $DEFAULT_ROOM and $DEFAULT EXIT
                if ($wmObj->{modelHash}) {

                    $self->writeText('Applying essential world model update. Please be patient...');
                    $axmud::CLIENT->desktopObj->updateWidgets(
                        $self->_objClass . '->updateExtractedData',
                    );
                }

                foreach my $roomObj ($wmObj->ivValues('roomModelHash')) {

                    $roomObj->compress();
                }

                foreach my $exitObj ($wmObj->ivValues('exitModelHash')) {

                    $exitObj->compress();
                }

                # (This line makes sure the correct file object's ->modifyFlag is set)
                $wmObj->ivPoke('author', $wmObj->author);
            }

            if ($version < 1_001_409) {

                # This version adds a new IV to the world model
                if (! exists $wmObj->{roomFlagShowMode}) {

                    $wmObj->{roomFlagShowMode} = undef;
                    $wmObj->ivPoke('roomFlagShowMode', 'default');
                }
            }

            if ($version < 1_001_450) {

                # This version removes IVs from the world model
                delete $wmObj->{fixedRoomTagFlag};
                delete $wmObj->{fixedRoomGuildFlag};
                delete $wmObj->{fixedExitTagFlag};
                delete $wmObj->{fixedLabelFlag};

                # Also, the ->_objClass for room objects was set to the class of an exit object
                #   instead, so let's fix that
                foreach my $roomObj ($wmObj->ivValues('roomModelHash')) {

                    $roomObj->{_objClass} = ref $roomObj;
                }

                if ($wmObj->{painterObj}) {

                    $wmObj->{painterObj}->{_objClass} = ref $wmObj->{painterObj};
                }
            }

            if ($version < 1_001_453) {

                # This version adds a new IV to the world model
                if (! exists $wmObj->{blockUnselectFlag}) {

                    $wmObj->{blockUnselectFlag} = undef;
                    $wmObj->ivPoke('blockUnselectFlag', TRUE);
                }
            }

            if ($version < 1_001_456) {

                # This version adds a new IV to the world model
                if (! exists $wmObj->{queueDrawMaxExits}) {

                    $wmObj->{queueDrawMaxExits} = undef;
                    $wmObj->ivPoke('queueDrawMaxExits', 150);
                }
            }

            if ($version < 1_001_465) {

                # This version replaces an IV in map labels and map label styles
                foreach my $regionmapObj ($wmObj->ivValues('regionmapHash')) {

                    foreach my $labelObj ($regionmapObj->ivValues('gridLabelHash')) {

                        delete $labelObj->{gravity};

                        $labelObj->{rotateAngle} = undef;
                        $labelObj->ivPoke('rotateAngle', 0);
                    }
                }

                foreach my $styleObj ($wmObj->ivValues('mapLabelStyleHash')) {

                    delete $styleObj->{gravity};

                    $styleObj->{rotateAngle} = undef;
                    $styleObj->ivPoke('rotateAngle', 0);
                }

            }

            if ($version < 1_001_517) {

                # This version changes the IVs used in pre-drawing operations
                if (! exists $wmObj->{preDrawAllowFlag}) {

                    $wmObj->{preDrawAllowFlag} = undef;
                    $wmObj->ivPoke('preDrawAllowFlag', TRUE);

                    $wmObj->{preDrawRetainRooms} = undef;
                    $wmObj->ivPoke('preDrawRetainRooms', $wmObj->{retainDrawMinRooms});
                    delete $wmObj->{retainDrawMinRooms};

                    delete $wmObj->{queueDrawMaxObjs};
                    delete $wmObj->{queueDrawMaxExits};

                    $wmObj->{preDrawAllocation} = undef;
                    $wmObj->ivPoke('preDrawAllocation', 50);
                }
            }

            if ($version < 1_001_529) {

                # This version adds a new IV to the world model
                if (! exists $wmObj->{modelSaveFileCount}) {

                    $wmObj->{modelSaveFileCount} = undef;
                    $wmObj->ivPoke('modelSaveFileCount', 0);
                }
            }

            if ($version < 1_002_091) {

                # This version adds new IVs to the world model
                if (! exists $wmObj->{obscuredExitFlag}) {

                    $wmObj->{obscuredExitFlag} = undef;
                    $wmObj->ivPoke('obscuredExitFlag', FALSE);
                    $wmObj->{obscuredExitRadius} = undef;
                    $wmObj->ivPoke('obscuredExitRadius', 3);
                    $wmObj->{maxObscuredExitRadius} = undef;
                    $wmObj->ivPoke('maxObscuredExitRadius', 9);
                    $wmObj->{obscuredExitRedrawFlag} = undef;
                    $wmObj->ivPoke('obscuredExitRedrawFlag', FALSE);
                }

                # ...and to regionmaps
                foreach my $regionmapObj ($wmObj->ivValues('regionmapHash')) {

                    if (! exists $regionmapObj->{obscuredExitFlag}) {

                        $regionmapObj->{obscuredExitFlag} = undef;
                        $regionmapObj->ivPoke('obscuredExitFlag', FALSE);
                        $regionmapObj->{obscuredExitRadius} = undef;
                        $regionmapObj->ivPoke('obscuredExitRadius', 3);

                        $regionmapObj->{drawOrnamentsFlag} = undef;
                        if ($wmObj->drawExitMode eq 'ask_regionmap') {
                            $regionmapObj->ivPoke('drawOrnamentsFlag', $wmObj->drawOrnamentsFlag);
                        } else {
                            $regionmapObj->ivPoke('drawOrnamentsFlag', FALSE);
                        }

                        $regionmapObj->{obscuredExitRedrawFlag} = undef;
                        $regionmapObj->ivPoke('obscuredExitRedrawFlag', FALSE);
                    }
                }

            }

            if ($version < 1_002_150) {

                # This version adds region schemes
                if (! exists $wmObj->{regionSchemeHash}) {

                    # Remove colour IVs from the world model, and transfer them to a new 'default'
                    #   region scheme
                    $wmObj->{regionSchemeHash} = {};

                    $wmObj->{defaultSchemeObj} = undef;
                    $wmObj->ivPoke(
                        'defaultSchemeObj',
                        Games::Axmud::Obj::RegionScheme->new($self->session, $wmObj, 'default'),
                    );

                    $wmObj->ivAdd('regionSchemeHash', 'default', $wmObj->defaultSchemeObj);

                    foreach my $iv (
                        qw(
                            backgroundColour roomColour roomTextColour selectBoxColour borderColour
                            currentBorderColour currentFollowBorderColour currentWaitBorderColour
                            currentSelectBorderColour lostBorderColour lostSelectBorderColour
                            ghostBorderColour ghostSelectBorderColour selectBorderColour
                            roomAboveColour roomBelowColour roomTagColour selectRoomTagColour
                            roomGuildColour selectRoomGuildColour exitColour selectExitColour
                            selectExitTwinColour selectExitShadowColour randomExitColour
                            impassableExitColour mysteryExitColour checkedDirColour dragExitColour
                            exitTagColour selectExitTagColour mapLabelColour selectMapLabelColour
                        )
                    ) {
                        # (All but on IV is copied to the new scheme object)
                        if ($iv ne 'noBackgroundColour') {

                            $wmObj->defaultSchemeObj->{$iv} = $wmObj->{$iv};
                        }

                        delete $wmObj->{$iv};
                    }

                    # Add a new IV to regionmaps
                    foreach my $regionmapObj ($wmObj->ivValues('regionmapHash')) {

                        if (! exists $regionmapObj->{regionScheme}) {

                            $regionmapObj->{regionScheme} = undef;
                            $regionmapObj->ivUndef('regionScheme');
                        }
                    }
                }
            }

            if ($version < 1_003_003) {

                # This version fixes a typo in a world model IV
                if (! exists $wmObj->{maxObscuredExitRadius}) {

                    $wmObj->{maxObscuredExitRadius} = undef;
                    $wmObj->ivPoke('maxObscuredExitRadius', 9);
                    delete $wmObj->{maxobscuredExitRadius};
                }
            }

            if ($version < 1_003_017) {

                # This version adds new IVs to the world model
                if (! exists $wmObj->{roomInteriorXOffset}) {

                    $wmObj->{roomInteriorXOffset} = undef;
                    $wmObj->ivPoke('roomInteriorXOffset', 0);
                    $wmObj->{roomInteriorYOffset} = undef;
                    $wmObj->ivPoke('roomInteriorYOffset', 0);
                }
            }
        }

        ### new built-in tasks (new IVs for existing tasks are below) #############################

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

            if ($version < 1_001_127) {

                # This version adds a new built-in task
                if (! $axmud::CLIENT->ivExists('taskLabelHash', 'channels')) {

                    $axmud::CLIENT->ivAdd('taskLabelHash', 'chan', 'channels_task');
                    $axmud::CLIENT->ivAdd('taskLabelHash', 'channel', 'channels_task');
                    $axmud::CLIENT->ivAdd('taskLabelHash', 'channels', 'channels_task');
                }
            }

            if ($version < 1_001_164) {

                # This version renames the built-in Debugger task as the System task. Existing
                #   Debugger tasks are updated below
                if (! $axmud::CLIENT->ivExists('taskLabelHash', 'debugger')) {

                    $axmud::CLIENT->ivDelete('taskLabelHash', 'debug');
                    $axmud::CLIENT->ivDelete('taskLabelHash', 'debugger');

                    $axmud::CLIENT->ivAdd('taskLabelHash', 'sys', 'system_task');
                    $axmud::CLIENT->ivAdd('taskLabelHash', 'system', 'system_task');
                }
            }

            if ($version < 1_001_386) {

                # This version adds new built-in tasks
                if (! $axmud::CLIENT->ivExists('taskLabelHash', 'countdown')) {

                    $axmud::CLIENT->ivAdd('taskLabelHash', 'cd', 'countdown_task');
                    $axmud::CLIENT->ivAdd('taskLabelHash', 'count', 'countdown_task');
                    $axmud::CLIENT->ivAdd('taskLabelHash', 'countdown', 'countdown_task');

                    $axmud::CLIENT->ivAdd('taskLabelHash', 'mc', 'map_check_task');
                    $axmud::CLIENT->ivAdd('taskLabelHash', 'map', 'map_check_task');
                    $axmud::CLIENT->ivAdd('taskLabelHash', 'mapcheck', 'map_check_task');
                }
            }

            if ($version < 1_001_388) {

                # This version adds a new built-in task
                if (! $axmud::CLIENT->ivExists('taskLabelHash', 'connections')) {

                    $axmud::CLIENT->ivAdd('taskLabelHash', 'conn', 'connections_task');
                    $axmud::CLIENT->ivAdd('taskLabelHash', 'connect', 'connections_task');
                    $axmud::CLIENT->ivAdd('taskLabelHash', 'connections', 'connections_task');
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

                # This version updated the Status task with new IVs. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('status_task')) {

                    if (! exists $taskObj->{xpNextLevel}) {

                        # (This IV subsequently renamed and/or removed)
#                        $taskObj->{xpNextLevel} = undef;
#                        $taskObj->ivUndef('xpNextLevel');
                        $taskObj->{xpNextLevel} = undef;
                        # (This IV subsequently renamed and/or removed)
#                        $taskObj->{alignment} = undef;
#                        $taskObj->ivUndef('alignment');
                        $taskObj->{alignment} = undef;
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

                        # (This IV subsequently renamed and/or removed)
#                        $taskObj->{msdpRoomHash} = {};
#                        $taskObj->ivEmpty('msdpRoomHash');
                        $taskObj->{msdpRoomHash} = {};
#                        $taskObj->{msdpExitHash} = {};
#                        $taskObj->ivEmpty('msdpExitHash');
                        $taskObj->{msdpExitHash} = {};
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

                    # (This IV subsequently renamed and/or removed)
#                    $taskObj->{winType} = undef;
#                    $taskObj->ivPoke('winType', 'text');
                    $taskObj->{winType} = 'text';
                }
            }

            if ($version < 1_000_482 && $self->session) {

                # This version changes character life status. Update all initial/custom tasks
                foreach my $taskObj ($self->compileTasks('status_task')) {

                    # (This IV subsequently renamed and/or removed)
                    if ($taskObj->{lifeStatus} eq 'asleep') {
#                        $taskObj->ivPoke('lifeStatus', 'sleep');
                        $taskObj->{lifeStatus} = 'sleep';
                    } elsif ($taskObj->{lifeStatus} eq 'passed_out') {
#                        $taskObj->ivPoke('lifeStatus', 'passout');
                        $taskObj->{lifeStatus} = 'passout';
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
                        # (This IV subsequently renamed and/or removed)
#                        $taskObj->{gagFlag} = undef;
#                        $taskObj->ivPoke('gagFlag', TRUE);
                        $taskObj->{gagFlag} = TRUE;
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

                        # (This IV subsequently renamed and/or removed)
#                        $taskObj->{radioButton2} = undef;
#                        $taskObj->ivUndef('radioButton2');
                        $taskObj->{radioButton2} = undef;
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

                        # (This IV subsequently renamed and/or removed)
#                        $taskObj->{singleBackRefVarHash} = {};
#                        $taskObj->ivPoke('singleBackRefVarHash', %varHash);
                        $taskObj->{singleBackRefVarHash} = {%varHash};

                        $taskObj->{gaugeFlag} = undef;
                        $taskObj->ivPoke('gaugeFlag', FALSE);
                        $taskObj->{gaugeValueFlag} = undef;
                        $taskObj->ivPoke('gaugeValueFlag', TRUE);

                        # (This IV subsequently renamed and/or removed)
#                        $taskObj->{defaultGaugeFormatList} = [];
#                        $taskObj->ivPoke('defaultGaugeFormatList', @varList);
                        $taskObj->{defaultGaugeFormatList} = [@varList];
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

            # (These IVs subsequently renamed and/or removed)
#            if ($version < 1_000_691 && $self->session) {
#
#                # This version switched the order of some IVs in the Status task. Update all
#                #   initial/custom tasks
#                foreach my $taskObj ($self->compileTasks('status_task')) {
#
#                    my $string;
#
#                    $string = $taskObj->ivIndex('defaultFormatList', 1);
#
#                    # (No reason why any of these conditions should fail; these IVs aren't
#                    #   supposed to be altered)
#                    if ($string =~ m/^HP\: \@health_points\@.*\(\@social_points_max\@\)$/) {
#
#                        $taskObj->ivReplace(
#                            'defaultFormatList',
#                            1,
#                            'HP: @health_points@ (@health_points_max@) MP: @magic_points@'
#                            . ' (@magic_points_max@) EP: @energy_points@ (@energy_points_max@)'
#                            . ' GP: @guild_points@ (@guild_points_max@) SP: @social_points@'
#                            . ' (@social_points_max@)',
#                        );
#                    }
#
#                    if (
#                        $taskObj->ivIndex('displayVarList', 4) eq 'health_points'
#                        && $taskObj->ivIndex('displayVarList', 6) eq 'energy_points'
#                    ) {
#                        $taskObj->ivReplace('displayVarList', 6, 'magic_points');
#                        $taskObj->ivReplace('displayVarList', 7, 'magic_points_max');
#                        $taskObj->ivReplace('displayVarList', 8, 'energy_points');
#                        $taskObj->ivReplace('displayVarList', 9, 'energy_points_max');
#                    }
#
#                    if (
#                        $taskObj->ivIndex('singleBackRefVarList', 2) eq 'energy_points'
#                        && $taskObj->ivIndex('singleBackRefVarList', 4) eq 'magic_points'
#                    ) {
#                        $taskObj->ivReplace('singleBackRefVarList', 2, 'magic_points');
#                        $taskObj->ivReplace('singleBackRefVarList', 3, 'magic_points_max');
#                        $taskObj->ivReplace('singleBackRefVarList', 4, 'energy_points');
#                        $taskObj->ivReplace('singleBackRefVarList', 5, 'energy_points_max');
#                    }
#                }
#            }

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

            if ($version < 1_001_031 && $self->session) {

                # This version updates all tasks by renaming an IV
                foreach my $taskObj ($self->compileTasks()) {

                    if (! exists $taskObj->{taskType}) {

                        $taskObj->{taskType} = undef;
                        $taskObj->ivPoke('taskType', $taskObj->{taskList});

                        delete $taskObj->{taskList};
                    }
                }
            }

            if ($version < 1_001_093 && $self->session) {

                # This version updated the Locator task with a new IV, and renames some existing
                #   IVs. Update all initial/custom tasks
                foreach my $taskObj ($self->compileTasks('locator_task')) {

                    if (! exists $taskObj->{prevCmdBufferNum}) {

                        $taskObj->{prevCmdBufferNum} = undef;
                        $taskObj->ivUndef('prevCmdBufferNum');

                        $taskObj->{prevMoveObj} = undef;
                        $taskObj->ivPoke('prevMoveObj', $taskObj->{previousMoveObj});
                        delete $taskObj->{previousMoveObj};

                        $taskObj->{prevMove} = undef;
                        $taskObj->ivPoke('prevMove', $taskObj->{previousMove});
                        delete $taskObj->{previousMove};
                    }
                }
            }

            if ($version < 1_000_094 && $self->session) {

                # This version removes an IV in the Locator task
                foreach my $taskObj ($self->compileTasks('locator_task')) {

                    if (exists $taskObj->{resetTitleBarFlag}) {

                        delete $taskObj->{resetTitleBarFlag};
                    }
                }
            }

            if ($version < 1_001_118 && $self->session) {

                # This version updated the Locator task with new IVs. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('locator_task')) {

                    if (! exists $taskObj->{weatherHash}) {

                        $taskObj->{weatherHash} = {};
                        $taskObj->ivEmpty('weatherHash');
                        $taskObj->{showParsedFlag} = undef;
                        $taskObj->ivPoke('showParsedFlag', FALSE);
                    }
                }
            }

            if ($version < 1_001_120 && $self->session) {

                # This version fixes an error in which tasks in the global initial tasklist, created
                #   by GA::Client->addGlobalInitTask, did not have their ->taskType IV set correctly
                foreach my $taskObj ($axmud::CLIENT->ivValues('initTaskHash')) {

                    $taskObj->ivPoke('taskType', 'initial');
                }
            }

            if ($version < 1_001_121 && $self->session) {

                # This version adds an IV to all tasks
                foreach my $taskObj ($self->compileTasks()) {

                    if (! exists $taskObj->{colourScheme}) {

                        $taskObj->{colourScheme} = undef;
                        $taskObj->ivUndef('colourScheme');
                    }
                }
            }

            if ($version < 1_001_125 && $self->session) {

                # This version updated the Divert task, adding some new IVs and removing some
                #   existing ones. Update all initial/custom tasks
                foreach my $taskObj ($self->compileTasks('divert_task')) {

                    if (! exists $taskObj->{otherAlertColour}) {

                        $taskObj->{otherAlertColour} = undef;
                        $taskObj->ivPoke('otherAlertColour', 'magenta');
                        $taskObj->{otherAlertInterval} = undef;
                        $taskObj->ivPoke('otherAlertInterval', 10);
                        $taskObj->{otherAlertSound} = undef;
                        $taskObj->ivPoke('otherAlertSound', 'notify');

                        $taskObj->{warningCharLimit} = undef;
                        $taskObj->ivPoke('warningCharLimit', 0);
                        $taskObj->{otherCharLimit} = undef;
                        $taskObj->ivPoke('otherCharLimit', 0);

                        $taskObj->{otherRoomFlag} = undef;
                        $taskObj->ivPoke('otherRoomFlag', FALSE);
                        $taskObj->{otherUrgencyFlag} = undef;
                        $taskObj->ivPoke('otherUrgencyFlag', TRUE);

                        delete $taskObj->{gagFlag};
                    }
                }
            }

            if ($version < 1_001_128 && $self->session) {

                # This version updates all tasks with a new IV
                foreach my $taskObj ($self->compileTasks()) {

                    if (! exists $taskObj->{tabMode}) {

                        $taskObj->{tabMode} = undef;

                        if (
                            $taskObj->{allowWinFlag}
                            && defined $taskObj->{winmap}
                            && (
                                $taskObj->{winmap} eq 'basic_fill'
                                || $taskObj->{winmap} eq 'basic_part'
                                || $taskObj->{winmap} eq 'entry_fill'
                                || $taskObj->{winmap} eq 'entry_part'
                            )
                        ) {
                            # At the current time, there are no tasks whose ->tabMode is 'multi'
                            $taskObj->ivPoke('tabMode', 'simple');

                        } else {

                            $taskObj->ivUndef('tabMode');
                        }
                    }
                }
            }

            if ($version < 1_001_133 && $self->session) {

                # This version updated the Watch task with new IVs. Update all initial/custom tasks
                foreach my $taskObj ($self->compileTasks('watch_task')) {

                    if (! exists $taskObj->{channelsAlertColour}) {

                        $taskObj->{channelsAlertColour} = undef;
                        $taskObj->ivPoke('channelsAlertColour', 'YELLOW');
                        $taskObj->{channelsAlertInterval} = undef;
                        $taskObj->ivPoke('channelsAlertInterval', 10);
                    }
                }
            }

            if ($version < 1_001_164 && $self->session) {

                my $class = 'Games::Axmud::Task::System';

                # This version renames the built-in Debugger task as the System task
                foreach my $taskObj ($self->compileTasks('debugger_task')) {

                    # Rebless the task object into its new class
                    bless $taskObj, $class;

                    # Rename some existing IVs
                    $taskObj->{_objName} = 'system_task';
                    $taskObj->{_objClass} = $class;
                    $taskObj->{name} = 'system_task';
                    $taskObj->{prettyName} = 'System';
                    $taskObj->{shortName} = 'Sy';
                    $taskObj->{shortCutIV} = 'systemTask';
                    $taskObj->{descrip} = 'Diverts system messages into a new window';

                    # Change one task setting to fix an issue that prevented the window showing
                    #   coloured text
                    $taskObj->{monochromeFlag} = FALSE;

                    # Add new IVs
                    $taskObj->{systemMode} = undef;
                    $taskObj->ivPoke('systemMode', 'both');
                    $taskObj->{colourFlag} = undef;
                    $taskObj->ivPoke('colourFlag', TRUE);
                }
            }

            if ($version < 1_001_191 && $self->session) {

                # This version renames some Status task IVs. Update all initial/custom tasks
                foreach my $taskObj ($self->compileTasks('status_task')) {

                    if (! exists $taskObj->{groupVarList}) {

                        $taskObj->{groupVarList} = $taskObj->{singleBackRefVarList};
                        delete $taskObj->{singleBackRefVarList};

                        $taskObj->{groupVarHash} = $taskObj->{singleBackRefVarHash};
                        delete $taskObj->{singleBackRefVarHash};
                    }
                }
            }

            if ($version < 1_001_200 && $self->session) {

                # This version updated the RawToken task with new IVs. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('raw_token_task')) {

                    if (! exists $taskObj->{splitLineFlag}) {

                        $taskObj->{splitLineFlag} = undef;
                        $taskObj->ivPoke('splitLineFlag', FALSE);
                        $taskObj->{showTypeFlag} = undef;
                        $taskObj->ivPoke('showTypeFlag', FALSE);
                        $taskObj->{countPacketFlag} = undef;
                        $taskObj->ivPoke('countPacketFlag', FALSE);
                    }
                }
            }

            if ($version < 1_001_263 && $self->session) {

                my $tempTask;

                # This version completes a major rewrite of the Status task

                # Create a temporary task so we can access its IVs
                $tempTask = Games::Axmud::Task::Status->new($axmud::CLIENT);

                # Update IVs in all initial/custom tasks
                foreach my $taskObj ($self->compileTasks('status_task')) {

                    if (! exists $taskObj->{constCharVarHash}) {

                        # (New IVs)
                        $taskObj->{constCharVarHash} = {$tempTask->constCharVarHash};
                        $taskObj->{constFixedVarHash} = {$tempTask->constFixedVarHash};
                        $taskObj->{constPseudoVarHash} = {$tempTask->constPseudoVarHash};
                        $taskObj->{constLocalVarHash} = {$tempTask->constLocalVarHash};
                        $taskObj->{constCounterVarHash} = {$tempTask->constCounterVarHash};
                        $taskObj->{constCounterRevHash} = {$tempTask->constCounterRevHash};
                        $taskObj->{constPointHash} = {$tempTask->constPointHash};

                        $taskObj->{localVarHash} = {};
                        $taskObj->ivPoke('localVarHash', $tempTask->localVarHash);
                        $taskObj->{counterVarHash} = {};
                        $taskObj->ivPoke('counterVarHash', $tempTask->counterVarHash);
                        $taskObj->{counterBaseHash} = {};
                        $taskObj->ivPoke('counterBaseHash', $tempTask->counterBaseHash);

                        # (Renamed IV)
                        $taskObj->{counterStartTime} = undef;
                        $taskObj->ivPoke('counterStartTime', $tempTask->{tempTimerBaseline});
                        delete $taskObj->{tempTimerBaseline};

                        # (Removed IVs)
                        delete $taskObj->{defaultFormatList};
                        delete $taskObj->{displayVarList};
                        delete $taskObj->{groupVarList};
                        delete $taskObj->{groupVarHash};

                        delete $taskObj->{lifeStatusOverrideFlag};

                        delete $taskObj->{lifeStatus};
                        delete $taskObj->{lifeCount};
                        delete $taskObj->{deathCount};
                        delete $taskObj->{lifeMax};

                        delete $taskObj->{healthPoints};
                        delete $taskObj->{healthPointsMax};
                        delete $taskObj->{magicPoints};
                        delete $taskObj->{magicPointsMax};
                        delete $taskObj->{energyPoints};
                        delete $taskObj->{energyPointsMax};
                        delete $taskObj->{guildPoints};
                        delete $taskObj->{guildPointsMax};
                        delete $taskObj->{socialPoints};
                        delete $taskObj->{socialPointsMax};

                        delete $taskObj->{xpCurrent};
                        delete $taskObj->{xpNextLevel};
                        delete $taskObj->{xpTotal};

                        delete $taskObj->{worldQuestCount};
                        delete $taskObj->{worldQuestPointCount};
                        delete $taskObj->{worldQuestXPCount};
                        delete $taskObj->{worldQuestCashCount};

                        delete $taskObj->{questCount};
                        delete $taskObj->{questPointCount};
                        delete $taskObj->{questXPCount};
                        delete $taskObj->{questCashCount};

                        delete $taskObj->{level};
                        delete $taskObj->{alignment};

                        delete $taskObj->{localWimpy};
                        delete $taskObj->{constLocalWimpyMax};
                        delete $taskObj->{remoteWimpy};
                        delete $taskObj->{remoteWimpyMax};

                        delete $taskObj->{age};
                        delete $taskObj->{time};

                        delete $taskObj->{bankBalance};
                        delete $taskObj->{purseContents};

                        delete $taskObj->{fightCountFlag};
                        delete $taskObj->{fightCount};
                        delete $taskObj->{killCount};
                        delete $taskObj->{wimpyCount};
                        delete $taskObj->{fightDefeatCount};
                        delete $taskObj->{interactCountFlag};
                        delete $taskObj->{interactCount};
                        delete $taskObj->{interactSuccessCount};
                        delete $taskObj->{interactFailCount};
                        delete $taskObj->{interactFightCount};
                        delete $taskObj->{interactDisasterCount};

                        delete $taskObj->{fleeCount};
                        delete $taskObj->{escapeCount};

                        delete $taskObj->{tempXPCount};
                        delete $taskObj->{tempXPBaseline};
                        delete $taskObj->{tempQuestCount};
                        delete $taskObj->{tempQuestBaseline};
                        delete $taskObj->{tempBankCount};
                        delete $taskObj->{tempBankBaseline};
                        delete $taskObj->{tempPurseCount};
                        delete $taskObj->{tempPurseBaseline};
                    }
                }
            }

            if ($version < 1_002_058 && $self->session) {

                # This version updated the Locator task with new IVs. Update all initial/custom
                #   tasks
                foreach my $taskObj ($self->compileTasks('locator_task')) {

                    if (! exists $taskObj->{mxpPropCurrentHash}) {

                        $taskObj->{mxpPropCurrentHash} = {};
                        $taskObj->ivEmpty('mxpPropCurrentHash');
                        $taskObj->{mxpPropStartLine} = undef;
                        $taskObj->ivUndef('mxpPropStartLine');
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
                        # (This IV subsequently renamed and/or removed)
#                        $dictObj->ivPoke('primaryDirList', @primaryDirList);
                        $dictObj->{primaryDirList} = [@primaryDirList];
#                        $dictObj->{shortPrimaryDirList} = [];
#                        $dictObj->ivPoke('shortPrimaryDirList', @shortPrimaryDirList);
                        $dictObj->{shortPrimaryDirList} = [@shortPrimaryDirList];
#                        $dictObj->{shortPrimaryDirHash} = {};
#                        $dictObj->ivPoke('shortPrimaryDirHash', %shortPrimaryDirHash);
                        $dictObj->{shortPrimaryDirHash} = {%shortPrimaryDirHash};

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

            if ($version < 1_001_299) {

                # This version adds a new IV
                foreach my $dictObj ($axmud::CLIENT->ivValues('dictHash')) {


                    if (! exists $dictObj->{relativeDirHash}) {

                        $dictObj->{relativeDirHash} = {};
                        $dictObj->ivEmpty('relativeDirHash');
                        $dictObj->{relativeAbbrevHash} = {};
                        $dictObj->ivEmpty('relativeAbbrevHash');
                    }
                }
            }

        ### toolbar ###############################################################################

        } elsif ($self->fileType eq 'toolbar') {

            if ($version < 1_000_927) {

                my (
                    $oldName,
                    @buttonList,
                    %buttonHash,
                );

                # This version renames one of the toolbar buttons, because of clashes with
                #   GA::Client->constReservedHash
                foreach my $buttonObj ($axmud::CLIENT->ivValues('toolbarHash')) {

                    if ($buttonObj->name eq 'connect') {

                        $oldName = $buttonObj->name;
                        $buttonObj->ivPoke('name', 'connect_me');

                    } elsif ($buttonObj->name eq 'help') {

                        $oldName = $buttonObj->name;
                        $buttonObj->ivPoke('name', 'help_me');

                    } elsif ($buttonObj->name eq 'login') {

                        $oldName = $buttonObj->name;
                        $buttonObj->ivPoke('name', 'login_me');

                    } elsif ($buttonObj->name eq 'save') {

                        $oldName = $buttonObj->name;
                        $buttonObj->ivPoke('name', 'save_me');
                    }

                    $buttonHash{$buttonObj->name} = $buttonObj;
                    delete $buttonHash{$oldName};
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

            if ($version < 1_001_017) {

                # This version adds a toolbar button for the new quick preferences window. If the
                #   user still has a toolbar button for client preference window, and a new button
                #   before it

                my (
                    $obj,
                    @buttonList,
                );

                foreach my $item ($axmud::CLIENT->toolbarList) {

                    if ($item eq 'edit_client') {

                        # Insert the new button here
                        $obj = Games::Axmud::Obj::Toolbar->new(
                            'edit_quick',
                            'Set quick preferences',
                            FALSE,          # Default, not custom, toolbar button
                            'book_edit.png',
                            ';editquick',
                            TRUE,
                            TRUE,
                        );

                        if ($obj) {

                            push (@buttonList, $obj->name);
                            $axmud::CLIENT->ivAdd('toolbarHash', $obj->name, $obj);
                        }
                    }

                    # The existing button is added after the new one
                    push (@buttonList, $item);
                }

                $axmud::CLIENT->ivPoke('toolbarList', @buttonList);
            }

            if ($version < 1_001_028) {

                my (
                    $buttonObj,
                    @buttonList,
                );

                # This version renames one of the toolbar buttons, as the window it opens has also
                #   been renamed
                $buttonObj = $axmud::CLIENT->ivShow('toolbarHash', 'open_gui');
                if ($buttonObj) {

                    $buttonObj->ivPoke('name', 'open_viewer');

                    $buttonObj->ivPoke('descrip', 'Open object viewer window');
                    $buttonObj->ivPoke('iconPath', 'watermark_table.png');
                    $buttonObj->ivPoke('instruct', ';openobjectviewer');

                    $axmud::CLIENT->ivDelete('toolbarHash', 'open_gui');
                    $axmud::CLIENT->ivAdd('toolbarHash', 'open_viewer', $buttonObj);

                    foreach my $name ($axmud::CLIENT->toolbarList) {

                        if ($name eq 'open_gui') {
                            push (@buttonList, 'open_viewer');
                        } else {
                            push (@buttonList, $name);
                        }
                    }

                    $axmud::CLIENT->ivPoke('toolbarList', @buttonList);
                }
            }

            if ($version < 1_001_507) {

                my (
                    @newList,
                    %checkHash,
                );

                # This version removes a toolbar button, as the client command has been removed
                foreach my $name ($axmud::CLIENT->ivKeys('toolbarHash')) {

                    my $obj = $axmud::CLIENT->ivShow('toolbarHash', $name);

                    if ($obj->instruct eq ';screenshot') {

                        $axmud::CLIENT->ivDelete('toolbarHash', $name);
                        $checkHash{$name} = undef;
                    }
                }

                foreach my $name ($axmud::CLIENT->toolbarList) {

                    if (! exists $checkHash{$name}) {

                        push (@newList, $name);
                    }
                }

                $axmud::CLIENT->ivPoke('toolbarList', @newList);
            }


        ### usercmds ##############################################################################

        } elsif ($self->fileType eq 'usercmds') {

            if ($version < 1_000_507) {

                # This version removes the ;screenshot command
                foreach my $userCmd ($axmud::CLIENT->ivKeys('userCmdHash')) {

                    my $standardCmd = $axmud::CLIENT->ivShow('userCmdHash', $userCmd);

                    if ($standardCmd eq 'screenshot') {

                        $axmud::CLIENT->ivDelete('userCmdHash', $userCmd);
                    }
                }
            }

        ## zonemaps ###############################################################################

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

        ## winmaps ################################################################################

        } elsif ($self->fileType eq 'winmaps') {

            if ($version < 1_001_028) {

                my $obj;

                # Change the name of the colour scheme for 'viewer' windows, which used to be called
                #   'gui' windows
                $obj = $axmud::CLIENT->ivShow('colourSchemeHash', 'gui');
                if ($obj) {

                    $obj->ivPoke('name', 'viewer');

                    $axmud::CLIENT->ivDelete('colourSchemeHash', 'gui');
                    $axmud::CLIENT->ivAdd('colourSchemeHash', 'viewer', $obj);
                }
            }

            if ($version < 1_001_122) {

                # This version adds an IV to colour schemes
                foreach my $obj ($axmud::CLIENT->ivValues('colourSchemeHash')) {

                    if (! exists $obj->{overrideHash}) {

                        $obj->{overrideHash} = {};
                        $obj->ivEmpty('overrideHash');
                        $obj->{overrideAllFlag} = undef;
                        $obj->ivPoke('overrideAllFlag', FALSE);
                    }
                }
            }

            if ($version < 1_001_129) {

                # This version removes an initialisation setting from pane objects (GA::Table::Pane)
                # The IV modified is in the winzone object (GA::Obj::Winzone)
                foreach my $winmapObj ($axmud::CLIENT->ivValues('winmapHash')) {

                    foreach my $zoneObj ($winmapObj->ivValues('zoneHash')) {

                        if ($zoneObj->packageName eq 'Games::Axmud::Table::Pane') {

                            $zoneObj->ivDelete('initHash', 'no_label_flag');
                        }
                    }
                }
            }

            if ($version < 1_001_203) {

                # This version adds a new button in 'main' windows, for which we must update the
                #   equivalent winmaps
                foreach my $winmapObj ($axmud::CLIENT->ivValues('winmapHash')) {

                    my (@oldList, @newList);

                    if (
                        $winmapObj->name eq 'main_fill'
                        || $winmapObj->name eq 'main_part'
                        || $winmapObj->name eq 'main_empty'
                    ) {
                        @oldList = $winmapObj->stripInitList;
                        if (@oldList) {

                            do {

                                my ($package, $hashRef);

                                $package = shift @oldList;
                                $hashRef = shift @oldList;

                                if (
                                    $package eq 'Games::Axmud::Strip::Entry'
                                    && defined $hashRef
                                ) {
                                    $$hashRef{'console_flag'} = TRUE;
                                }

                                push (@newList, $package, $hashRef);

                            } until (! @oldList);

                            $winmapObj->{stripInitList} = \@newList;
                        }
                    }
                }
            }

            if ($version < 1_001_393) {

                # This version adds a new strip object, for which we must update the equivalent
                #   winmaps
                # This version adds a new button in 'main' windows, for which we must update the
                #   equivalent winmaps
                foreach my $winmapObj ($axmud::CLIENT->ivValues('winmapHash')) {

                    my (@oldList, @newList);

                    if (
                        $winmapObj->name eq 'main_fill'
                        || $winmapObj->name eq 'main_part'
                        || $winmapObj->name eq 'main_empty'
                    ) {
                        @oldList = $winmapObj->stripInitList;
                        if (@oldList) {

                            do {

                                my ($package, $hashRef);

                                $package = shift @oldList;
                                $hashRef = shift @oldList;

                                if ($package eq 'Games::Axmud::Strip::Entry') {

                                    # Add the search box just above the entry strip object (which
                                    #   we'll assume still exists)
                                    push (@newList, 'Games::Axmud::Strip::SearchBox', undef);

                                    # The entry strip object itself gets two new flags
                                    $$hashRef{'add_flag'} = TRUE;
                                    $$hashRef{'search_flag'} = TRUE;
                                }

                                push (@newList, $package, $hashRef);

                            } until (! @oldList);

                            $winmapObj->{stripInitList} = \@newList;
                        }
                    }
                }
            }

            if ($version < 1_001_400) {

                # This version adds an IV to colour scheme objects
                foreach my $obj ($axmud::CLIENT->ivValues('colourSchemeHash')) {

                    if (! exists $obj->{wrapMode}) {

                        $obj->{wrapMode} = undef;
                        $obj->ivPoke('wrapMode', 'wrap_word_char');
                    }
                }
            }

        ## tts ####################################################################################

        } elsif ($self->fileType eq 'tts') {

            if ($version < 1_001_005) {

                # This version adds support for a new TTS engine. Extremely unlikely that anyone has
                #   created a configuration object with the same name, but we'll overwrite it, if so
                my $obj = Games::Axmud::Obj::Tts->new(
                    'esng',
                    'esng',
                    'en',
                    150,
                    undef,
                    50,
                    undef,
                );

                if ($obj) {

                    $axmud::CLIENT->add_ttsObj($obj);
                }

                # Also update the default values for the TTS configuration for the swift engine, as
                #   they use different values on MS Windows and Linux
                my $obj2 = $axmud::CLIENT->ivShow('ttsObjHash', 'swift');
                if ($obj2) {

                    $obj2->ivUndef('speed');
                    $obj2->ivUndef('rate');
                    $obj2->ivUndef('pitch');
                    $obj2->ivUndef('volume');
                }
            }

            if ($version < 1_001_133) {

                my ($chanObj, $divObj);

                # Add a TTS configuration object for the new Channels task, by cloning the object
                #   for the existing Divert task
                if (! $axmud::CLIENT->ivShow('ttsObjHash', 'channels')) {

                    $divObj = $axmud::CLIENT->ivShow('ttsObjHash', 'divert');
                    if ($divObj) {

                        $chanObj = $divObj->clone('channels');
                        if ($chanObj) {

                            $axmud::CLIENT->add_ttsObj($chanObj);
                        }
                    }

                    # Update other Client hashes
                    $axmud::CLIENT->ivAdd('ttsFlagAttribHash', 'channels', 'channels_task');
                }
            }

            if ($version < 1_001_401) {

                # This version changes the scale used for speed, rate, pitch and volume. We now use
                #   a standard range of 0-100 for all speech engines
                # Update all TTS configuration objects
                foreach my $ttsObj ($axmud::CLIENT->ivValues('ttsObjHash')) {

                    my ($speed, $rate, $pitch, $volume);

                    if ($ttsObj->engine eq 'espeak') {

                        $speed = int(($ttsObj->speed - 10) / 1.9);
                        $pitch = int($ttsObj->pitch);

                    } elsif ($ttsObj->engine eq 'esng') {

                        $speed = int(($ttsObj->speed - 10) / 1.9);
                        $pitch = int($ttsObj->pitch);

                        # Some default values seem to have been missing from
                        #   GA::Client->constTtsDefaultList; fill them in as we go
                        if (! defined $ttsObj->volume) {
                            $volume = 80;
                        } else {
                            $volume = int($ttsObj->volume / 2);
                        }

                    # (flite doesn't use speed/rate/pitch/volume)

                    } elsif ($ttsObj->engine eq 'festival') {

                        $rate = int(($ttsObj->rate - 0.5) * 66);
                        $volume = int(($ttsObj->volume - 0.33) * 17.6);

                    } elsif ($ttsObj->engine eq 'swift') {

                        if ($^O eq 'MSWin32') {

                            if (! defined $ttsObj->speed) {
                                $speed = 30;
                            } else {
                                $speed = int(($ttsObj->speed - 100) / 3);
                            }

                        } else {

                            if (! defined $ttsObj->rate) {
                                $rate = 50;
                            } else {
                                $rate = int(($ttsObj->rate - 0.5) * 66);
                            }
                        }

                        if (! defined $ttsObj->pitch) {
                            $pitch = 50;
                        } else {
                            $pitch = int($ttsObj->pitch * 20);
                        }

                        if (! defined $ttsObj->volume) {
                            $volume = 80;
                        } elsif ($^O eq 'MSWin32') {
                            $volume = int($ttsObj->volume);
                        } else {
                            $volume = int(($ttsObj->volume - 0.33) * 17.6);
                        }
                    }

                    # For all four values, take care of rounding errors by increasing value of 98
                    #   or above to 100
                    if (defined $speed && $speed >= 98) {

                        $speed = 100;
                    }

                    if (defined $rate && $rate >= 98) {

                        $rate = 100;
                    }

                    if (defined $pitch && $pitch >= 98) {

                        $pitch = 100;
                    }

                    if (defined $volume && $volume >= 98) {

                        $volume = 100;
                    }

                    # Update the configuration. Some of these values may still be 'undef'
                    $ttsObj->ivPoke('speed', $speed);
                    $ttsObj->ivPoke('rate', $rate);
                    $ttsObj->ivPoke('pitch', $pitch);
                    $ttsObj->ivPoke('volume', $volume);
                }
            }
        }

        return 1;
    }

    sub patchWorldProf {

        # Called by $self->loadDataFile for a world profile that must be patched due to serious
        #   problems, or whose DNS/IP/port has changed
        # Checks the version number of the loaded file against the version number specified by the
        #   GA::Client IV, and applies the patch, if required
        #
        # Expected arguments
        #   $world          - The name of the world profile
        #   $fileVersion   - The Axmud version used to save the file that the calling function has
        #                       just loaded
        #
        # Return values
        #   'undef' on improper arguments, if the world profile doesn't need to be patched or if the
        #       user declines to apply a patch
        #   1 if the world profile is patched

        my ($self, $world, $fileVersion, $check) = @_;

        # Local variables
        my ($worldObj, $patchVersion, $choice);

        # Check for improper arguments
        if (! defined $world || ! defined $fileVersion || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->patchWorldProf', @_);
        }

        # Import the world profile
        $worldObj = $axmud::CLIENT->ivShow('worldProfHash', $world);

        # Convert versions, e.g. '1.1.0' to '1_001_000' (the calling function has already checked
        #   that $world exists in GA::Client->constWorldPatchHash
        $fileVersion = $axmud::CLIENT->convertVersion($fileVersion);
        $patchVersion = $axmud::CLIENT->convertVersion(
            $axmud::CLIENT->ivShow('constWorldPatchHash', $world),
        );

        if ($fileVersion >= $patchVersion) {

            # No patch required
            return undef;
        }

        # If the user has ever connected to this world, ask permission before patching it
        # Exception: if GA::Client->mainWin is undefined, it's because the global variable
        #   $TEST_MODE_FLAG is TRUE; in that case, don't bother asking for permission
        if ($worldObj->numberConnects && $axmud::CLIENT->mainWin) {

            # If the existing file object needs to be saved, asked permission before importing data
            #   into it
            $choice = $axmud::CLIENT->mainWin->showMsgDialogue(
                'Patch pre-configured world',
                'question',
                'The world profile \'' . $world . '\' requires a patch. Do you want to apply this'
                . ' patch now? (Click \'Yes\' unless you have modified the world profile yourself'
                . ' and you are CERTAIN that it is working properly)',
                'yes-no',
            );

            if ($choice eq 'no') {

                return undef;
            }
        }


        if ($world eq 'archipelago' && $fileVersion < 1_003_000) {

            $worldObj->ivPoke('referURL', 'http://mudstats.com/World/ArchipelagoMUD');
        }

        if (
            (
                $world eq 'achaea' || $world eq 'aetolia' || $world eq 'imperian'
                || $world eq 'lusternia'
            ) && $fileVersion < 1_002_041
        ) {
            my $compObj;

            # Fix for IRE's odd habit of sending a single EOR and a single SGA, which permanently
            #   disables the prompt-checking code in GA::Session->processLinePortion
            $worldObj->ivAdd('telnetOverrideHash', 'sga', undef);
            $worldObj->ivAdd('telnetOverrideHash', 'eor', undef);
            # Fix for IRE's refusal to do MXP telnet negotiation
            $worldObj->ivAdd('mxpOverrideHash', 'perm', TRUE);

            # Also remove the '(road)' in Achaea room titles
            if ($world eq 'achaea') {

                $compObj = $worldObj->ivShow('componentHash', 'verb_title');
                if ($compObj) {

                    $compObj->{usePatternGroups} = '(.*)\.';
                }
            }
        }

        if ($world eq 'alteraeon' && $fileVersion < 1_001_270) {

            # Patch to fix bad regex in the 'verb_exit' component
            my $compObj = $worldObj->ivShow('componentHash', 'verb_exit');
            if ($compObj) {

                $compObj->ivPoke('startPatternList', '^\[Exits: ');
            }
        }

        if ($world eq 'avalonrpg' && $fileVersion < 1_001_012) {

            my ($compObj, $missionObj);

            # Patch to fix handling of room statements, which doesn't work at night, and to fix the
            #   login mission, which no longer works at all
            $worldObj->ivDelete('componentHash', 'ignore_line');

            $compObj = Games::Axmud::Obj::Component->new(
                $axmud::CLIENT,
                $worldObj,
                'ignore_line',
                'ignore_line',
            );

            if ($compObj) {

                $compObj->{size} = 0;
                $compObj->{minSize} = 0;        # Optional
                $compObj->{maxSize} = 1;
                $compObj->{analyseMode} = 'check_line';
                $compObj->{boldSensitiveFlag} = FALSE;
                $compObj->{useInitialTagsFlag} = FALSE;
                $compObj->{combineLinesFlag} = FALSE;

                $compObj->{startPatternList} = [
                    '^The sky ',
                ];
                $compObj->{startTagList} = [];
                $compObj->{startAllFlag} = FALSE;
                $compObj->{startTagMode} = 'default';

                $worldObj->ivAdd('componentHash', $compObj->name, $compObj);
            }

            $missionObj = $worldObj->ivShow('missionHash', 'avalon_login');
            if ($missionObj) {

                $missionObj->ivPoke(
                    'missionList',
                        't What is the name',
                        'n',        # Send char name
                        't What is the password',
                        'w',        # Send account password
                        't Land of Avalon',
                        '> ',
                        ';login',
                );
            }
        }

        if ($world eq 'darkrealms' && $fileVersion < 1_003_000) {

            $worldObj->ivPoke('ipv4', '64.227.89.30 1138');
            $worldObj->ivPoke('worldURL', 'http://darkrealmscos.com/');
        }

        if ($world eq 'dawn' && $fileVersion < 1_003_000) {

            $worldObj->ivPoke('dns', 'dawnmud.com');
            $worldObj->ivPoke('ipv4', '76.91.216.39');
        }

        if (
            ($world eq 'dsdev' || $world eq 'dslocal' || $world eq 'dsprime')
            && $fileVersion < 1_001_270
        ) {
            my $compObj;

            # Patch to turn off VT100 control sequences, which are just annoying in a test
            #   environment
            $worldObj->ivAdd('termOverrideHash', 'useCtrlSeqFlag', FALSE);

            # Also use an excess command delay that doesn't cause a DS refusal
            $worldObj->ivPoke('excessCmdDelay', 1.5);

            # Also solved problem of command prompts being added to room titles, after several
            #   simultaneous movement commands
            $compObj = $worldObj->ivShow('componentHash', 'verb_title');
            if ($compObj) {

                $compObj->ivPoke('usePatternGroups', 'hp\:.*mp\:.*sp\:.*\>\s(.*)');
            }
        }

        if ($world eq 'discworld' && $fileVersion < 1_001_343) {

            my $compObj;

            # Patch to fix various issues over several versions of Axmud
            $worldObj->ivPush(
                'lockedPatternList',
                    '^The .* swings shut in your face',
            );

            $worldObj->ivPush(
                'failExitPatternList',
                    '^You just crawled\.  Give your arms a break',
                    '^You are too tall to go that way',
                    '^You struggle to leave (.*), but you can\'t make any headway',
            );

            # (Replace existing regex)
            $worldObj->ivPoke(
                'darkRoomPatternList',
                    'It\'s dark here, isn\'t it',
            );

            $worldObj->ivPoke(
                'transientExitPatternList',
                    'enter (.*) carriage',
                        undef,
                    'enter door',
                        undef,
            );

            # (MXP supplies gauge data, so the Status task doesn't need to create its own gauge
            #   level)
            $worldObj->ivEmpty('gaugeFormatList');
            # (Translate gauge entities into Status task variables)
            $worldObj->ivPoke(
                'mxpStatusVarHash',
                    'hp'        => 'health_points',
                    'maxhp'     => 'health_points_max',
                    'gp'        => 'guild_points',
                    'maxgp'     => 'guild_points_max',
                    'sp'        => 'social_points',
                    'maxsp'     => 'social_points_max',
                    'xp'        => 'xp_current',
            );

            $worldObj->ivPoke(
                'verboseAnchorPatternList',
                    '^.*There are (.*) obvious exits\: (.*)',
                    '^.*There is one obvious exit\: (.*)',
                    '^.*There are no obvious exits\.',
            );

            $worldObj->ivPoke(
                'verboseExitLeftMarkerList',
                    '^.*There are (.*) obvious exits\: ',
                    '^.*There is one obvious exit\: ',
                    '^.*There are no obvious exits\.',
            );

            $worldObj->ivPoke(
                'briefAnchorPatternList',
                '\ \[(.*)\]\.\s*$',
            );

            $worldObj->ivDelete('componentHash', 'verb_descrip');
            $worldObj->ivDelete('componentHash', 'verb_descrip_1');
            $worldObj->ivDelete('componentHash', 'verb_descrip_2');
            $worldObj->ivDelete('componentHash', 'ignore_line');
            $worldObj->ivDelete('componentHash', 'verb_exit');
            $worldObj->ivDelete('componentHash', 'brief_title_exit');

            $worldObj->ivPoke(
                'verboseComponentList',
                    'verb_descrip_1',       # no MXP
                    'verb_descrip_2',       # MXP
                    'ignore_line',
                    'anchor',
                    'verb_exit',
            );

            $compObj = Games::Axmud::Obj::Component->new(
                $axmud::CLIENT,
                $worldObj,
                'verb_descrip_1',
                'verb_descrip',
            );

            if ($compObj) {

                $compObj->{size} = 0;
                $compObj->{minSize} = 0;
                $compObj->{maxSize} = 16;
                $compObj->{analyseMode} = 'check_line';
                $compObj->{boldSensitiveFlag} = FALSE;
                $compObj->{useInitialTagsFlag} = FALSE;
                $compObj->{combineLinesFlag} = FALSE;

                $compObj->{usePatternBackRefs} = '^\s[\s\-\|\\\/\&\$\@\+\*]{10}\s(.*)',

                $compObj->{startPatternList} = [
                    '^\s[\s\-\|\\\/\&\$\@\+\*]{10}\s(.*)',
                ],
                $compObj->{startTagList} = [];
                $compObj->{startAllFlag} = FALSE;
                $compObj->{startTagMode} = 'default';

                $compObj->{stopBeforeNoPatternList} = [
                    '^\s[\s\-\|\\\/\&\$\@\+\*]{10}\s(.*)',
                ],
                $compObj->{stopBeforeNoTagList} = [];
                $compObj->{stopBeforeNoAllFlag} = FALSE;
                $compObj->{stopBeforeNoTagMode} = 'default';

                $compObj->{stopBeforePatternList} = [
                    '^\s..........\sIt is ',
                    '^\s..........\sThe land is lit up ',
                ],
                $compObj->{stopBeforeTagList} = [];
                $compObj->{stopBeforeAllFlag} = FALSE;
                $compObj->{stopBeforeTagMode} = 'default';

                $worldObj->ivAdd('componentHash', $compObj->name, $compObj);
            }

            $compObj = Games::Axmud::Obj::Component->new(
                $axmud::CLIENT,
                $worldObj,
                'verb_descrip_2',
                'verb_descrip',
            );

            if ($compObj) {

                $compObj->{size} = 0;
                $compObj->{minSize} = 0;
                $compObj->{maxSize} = 16;
                $compObj->{analyseMode} = 'check_line';
                $compObj->{boldSensitiveFlag} = FALSE;
                $compObj->{useInitialTagsFlag} = FALSE;
                $compObj->{combineLinesFlag} = FALSE;

                $compObj->{startPatternList} = [
                    '^\w',
                ],
                $compObj->{startTagList} = [];
                $compObj->{startAllFlag} = FALSE;
                $compObj->{startTagMode} = 'default';

                $compObj->{stopBeforeNoPatternList} = [
                    '^\w',
                ],
                $compObj->{stopBeforeNoTagList} = [];
                $compObj->{stopBeforeNoAllFlag} = FALSE;
                $compObj->{stopBeforeNoTagMode} = 'default';

                $compObj->{stopBeforePatternList} = [
                    '^It is ',
                    '^The land is lit up ',
                ],
                $compObj->{stopBeforeTagList} = [];
                $compObj->{stopBeforeAllFlag} = FALSE;
                $compObj->{stopBeforeTagMode} = 'default';

                $worldObj->ivAdd('componentHash', $compObj->name, $compObj);
            }

            $compObj = Games::Axmud::Obj::Component->new(
                $axmud::CLIENT,
                $worldObj,
                'ignore_line',
                'ignore_line',
            );

            if ($compObj) {

                $compObj->{size} = 0;
                $compObj->{minSize} = 0;
                $compObj->{maxSize} = 16;
                $compObj->{analyseMode} = 'check_line';
                $compObj->{boldSensitiveFlag} = FALSE;
                $compObj->{useInitialTagsFlag} = FALSE;
                $compObj->{combineLinesFlag} = FALSE;

                $compObj->{startPatternList} = [];
                $compObj->{startTagList} = [
                    'yellow',               # no mxp
                    '#FF8700',              # mxp
                    'x208',                 # xterm256
                ];
                $compObj->{startAllFlag} = FALSE;
                $compObj->{startTagMode} = 'default';

                $compObj->{stopBeforeNoPatternList} = [];
                $compObj->{stopBeforeNoTagList} = [
                    'yellow',
                    '#FF8700',
                    'x208',
                ];
                $compObj->{stopBeforeNoAllFlag} = FALSE;
                $compObj->{stopBeforeNoTagMode} = 'default';

                $worldObj->ivAdd('componentHash', $compObj->name, $compObj);
            }

            $compObj = Games::Axmud::Obj::Component->new(
                $axmud::CLIENT,
                $worldObj,
                'verb_exit',
                'verb_exit',
            );

            if ($compObj) {

                $compObj->{size} = 1;
                $compObj->{analyseMode} = 'check_line';
                $compObj->{boldSensitiveFlag} = FALSE;
                $compObj->{useInitialTagsFlag} = FALSE;
                $compObj->{combineLinesFlag} = TRUE;

                $compObj->{startPatternList} = [
                    '^.*There are (.*) obvious exits\: (.*)',
                    '^.*There is one obvious exit\: (.*)',
                    '^.*There are no obvious exits\.',
                ];
                $compObj->{startTagList} = [];
                $compObj->{startAllFlag} = FALSE;
                $compObj->{startTagMode} = 'default';

                $compObj->{stopBeforeNoPatternList} = [];
                $compObj->{stopBeforeNoTagList} = [];
                $compObj->{stopBeforeNoAllFlag} = FALSE;
                $compObj->{stopBeforeNoTagMode} = 'default';

                $worldObj->ivAdd('componentHash', $compObj->name, $compObj);
            }

            $compObj = Games::Axmud::Obj::Component->new(
                $axmud::CLIENT,
                $worldObj,
                'brief_title_exit',
                'brief_title_exit',
            );

            if ($compObj) {

                $compObj->{size} = 1;
                $compObj->{analyseMode} = 'check_line';
                $compObj->{boldSensitiveFlag} = FALSE;
                $compObj->{useInitialTagsFlag} = FALSE;
                $compObj->{combineLinesFlag} = FALSE;

                $worldObj->ivAdd('componentHash', $compObj->name, $compObj);
            }
        }

        if ($world eq 'dunemud' && $fileVersion < 1_002_000) {

            $worldObj->ivPoke('dns', 'dunemud.net');
            $worldObj->ivPoke('ipv4', '68.183.23.43');
        }

        if ($world eq 'edmud' && $fileVersion < 1_003_000) {

            $worldObj->ivPoke('dns', 'eternaldarkness.net');
            $worldObj->ivPoke('ipv4', '216.136.9.8');
            $worldObj->ivPoke('worldURL', 'eternaldarkness.net');
        }

        if ($world eq 'fkindgoms' && $fileVersion < 1_003_000) {

            $worldObj->ivPoke('port', 4000);
        }
        
        if ($world eq 'forestsedge' && $fileVersion < 1_003_000) {

            $worldObj->ivPoke('dns', 'mud.theforestsedge.com');
            $worldObj->ivPoke('ipv4', '167.114.137.18');
            $worldObj->ivPoke('port', 4000);
        }

        if ($world eq 'icesus' && $fileVersion < 1_003_000) {

            $worldObj->ivPoke('dns', 'naga.icesus.org');
            $worldObj->ivPoke('ipv4', '95.216.243.162');
            $worldObj->ivPoke('port', 4000);
            $worldObj->ivPoke('worldURL', 'http://www.icesus.org/');
        }

        if ($world eq 'islands' && $fileVersion < 1_002_000) {

            $worldObj->ivPoke('dns', 'play.islands-game.live');
            $worldObj->ivPoke('ipv4', '45.79.14.59');
        }

        if ($world eq 'kallisti' && $fileVersion < 1_002_041) {

            # Auto-disconnections no longer a problem so re-enabled MSDP
            $worldObj->ivDelete('telnetOverrideHash', 'msdp');

            # Looks like output for 'score' command and prompt have been updated, too
            $worldObj->ivPush(
                'groupPatternList',
                    '^\< \w+ \| (\d+)h (\d+)m (\d+)s',
                        1,
                        'health_points',
                        'show',
                    '^\< \w+ \| (\d+)h (\d+)m (\d+)s',
                        2,
                        'magic_points',
                        'show',
                    '^\< \w+ \| (\d+)h (\d+)m (\d+)s',
                        3,
                        'energy_points',
                        'show',
                    'Hitpoints\:\s(\d+)\s\/\s(\d+)\s+Mana\:\s(\d+)\s\/\s(\d+)\s+Stamina\:\s'
                        . '(\d+)\s\/\s(\d+)',
                        1,
                        'health_points',
                        'show',
                    'Hitpoints\:\s(\d+)\s\/\s(\d+)\s+Mana\:\s(\d+)\s\/\s(\d+)\s+Stamina\:\s'
                        . '(\d+)\s\/\s(\d+)',
                        2,
                        'health_points_max',
                        'show',
                    'Hitpoints\:\s(\d+)\s\/\s(\d+)\s+Mana\:\s(\d+)\s\/\s(\d+)\s+Stamina\:\s'
                        . '(\d+)\s\/\s(\d+)',
                        3,
                        'magic_points',
                        'show',
                    'Hitpoints\:\s(\d+)\s\/\s(\d+)\s+Mana\:\s(\d+)\s\/\s(\d+)\s+Stamina\:\s'
                        . '(\d+)\s\/\s(\d+)',
                        4,
                        'magic_points_max',
                        'show',
                    'Hitpoints\:\s(\d+)\s\/\s(\d+)\s+Mana\:\s(\d+)\s\/\s(\d+)\s+Stamina\:\s'
                        . '(\d+)\s\/\s(\d+)',
                        5,
                        'energy_points',
                        'show',
                    'Hitpoints\:\s(\d+)\s\/\s(\d+)\s+Mana\:\s(\d+)\s\/\s(\d+)\s+Stamina\:\s'
                        . '(\d+)\s\/\s(\d+)',
                        6,
                        'energy_points_max',
                        'show',
            );

            # Replace the command prompt pattern
            $worldObj->ivPoke(
                'cmdPromptPatternList',
                    '^\< \w+ \| (\d+)h (\d+)m (\d+)s \> .',
            );

            # Add a very common fail exit message
            $worldObj->ivPush(
                'failExitPatternList',
                    'Alas, you cannot go .*\.\.\.',
            );
        }

        if ($world eq 'luminari' && $fileVersion < 1_001_270) {

            # Patch to fix bad regex in the ->channelList
            $worldObj->ivPoke(
                'channelList',
                    '^\w+ chats, \'',
                        'tell', TRUE,
                    '^You chat, \'',
                        'tell', TRUE,
                    '^\[INFO\] ',
                        'social', TRUE,
            );
        }

        if ($world eq 'mud1' && $fileVersion < 1_001_270) {

            my $compObj;

            # Update overrides
            $worldObj->ivAdd('termOverrideHash', 'useVisibleCursorFlag', TRUE);

            # Update problems with room statement detection
            $worldObj->ivPoke(
                'notAnchorPatternList',
                    '^\*',
                    '^\w+$',
            );

            $compObj = $worldObj->ivShow('componentHash', 'verb_descrip');
            if ($compObj) {

                $compObj->{startNoPatternList} = [
                    '^\*',
                ];
                $compObj->{startNoTagList} = [];
                $compObj->{startNoAllFlag} = FALSE;
                $compObj->{startNoTagMode} = 'default';
            }
        }

        if ($world eq 'mudii' && $fileVersion < 1_001_270) {

            my ($missionObj, $compObj, $compObj2);

            # Update overrides
            $worldObj->ivAdd('termOverrideHash', 'useVisibleCursorFlag', TRUE);

            # Update login mission
            $missionObj = $worldObj->ivShow('missionHash', 'mudii_login');
            if ($missionObj) {

                $missionObj->ivPoke(
                    'missionList',
                        't ^\w+ login\:',
                        '> mud',
                        't ^Account ID\:',
                        'a',
                        't ^Password\:',
                        'w',
                        't Checking your mail',
                        '> ',
                        't Option',
                        '> p',
                        't By what name shall I call you',
                        'n',
                        't Elizabethan tearoom',
                        ';login',
                );
            }

            # Update problems with room statement detection
            $worldObj->ivPoke(
                'notAnchorPatternList',
                    '^\*',
                    '^\w+$',
            );

            $compObj = $worldObj->ivShow('componentHash', 'ignore_line');
            if ($compObj) {

                $compObj->{boldSensitiveFlag} = FALSE;

                $compObj->{startPatternList} = [];
                $compObj->{startTagList} = [];
                $compObj->{startAllFlag} = FALSE;
                $compObj->{startTagMode} = 'default';

                $compObj->{startNoPatternList} = [];
                $compObj->{startNoTagList} = [
                    'green',
                ];
                $compObj->{startNoAllFlag} = FALSE;
                $compObj->{startNoTagMode} = 'default';

                $compObj->{stopBeforePatternList} = [];
                $compObj->{stopBeforeTagList} = [
                    'green',
                ];
                $compObj->{stopBeforeAllFlag} = FALSE;
                $compObj->{stopBeforeTagMode} = 'default';
            }

            $compObj2 = $worldObj->ivShow('componentHash', 'verb_descrip');
            if ($compObj2) {

                $compObj2->{startNoPatternList} = [
                    '^It is raining\.',
                ];
                $compObj2->{startNoTagList} = [];
                $compObj2->{startNoAllFlag} = FALSE;
                $compObj2->{startNoTagMode} = 'default';
            }
        }

        if ($world eq 'mud2' && $fileVersion < 1_001_270) {

            my ($missionObj, $compObj, $compObj2);

            # Update overrides
            $worldObj->ivAdd('termOverrideHash', 'useVisibleCursorFlag', TRUE);

            # Update login mission
            $missionObj = $worldObj->ivShow('missionHash', 'mud2_login');
            if ($missionObj) {

                $missionObj->ivPoke(
                    'missionList',
                        't ^\w+ login\:',
                        '> mud',
                        't ^Account ID\:',
                        'a',
                        't ^Password\:',
                        'w',
                        't Hit return',
                        '> ',
                        't Option',
                        '> p',
                        't By what name shall I call you',
                        'n',
                        't Elizabethan tearoom',
                        ';login',
                );
            }

            # Update problems with room statement detection
            $worldObj->ivPoke(
                'notAnchorPatternList',
                    '^\*',
                    '^\w+$',
            );

            $compObj = $worldObj->ivShow('componentHash', 'ignore_line');
            if ($compObj) {

                $compObj->{boldSensitiveFlag} = FALSE;

                $compObj->{startPatternList} = [];
                $compObj->{startTagList} = [];
                $compObj->{startAllFlag} = FALSE;
                $compObj->{startTagMode} = 'default';

                $compObj->{startNoPatternList} = [];
                $compObj->{startNoTagList} = [
                    'green',
                ];
                $compObj->{startNoAllFlag} = FALSE;
                $compObj->{startNoTagMode} = 'default';

                $compObj->{stopBeforePatternList} = [];
                $compObj->{stopBeforeTagList} = [
                    'green',
                ];
                $compObj->{stopBeforeAllFlag} = FALSE;
                $compObj->{stopBeforeTagMode} = 'default';
            }

            $compObj2 = $worldObj->ivShow('componentHash', 'verb_descrip');
            if ($compObj2) {

                $compObj2->{startNoPatternList} = [
                    '^It is raining\.',
                ];
                $compObj2->{startNoTagList} = [];
                $compObj2->{startNoAllFlag} = FALSE;
                $compObj2->{startNoTagMode} = 'default';
            }
        }

        if ($world eq 'nanvaent' && $fileVersion < 1_001_343) {

            # Remove follow patterns, which conflict with some room descriptions, causing automapper
            #   to get lost
            $worldObj->ivEmpty('followPatternList');
        }

        if ($world eq 'nanvaent' && $fileVersion < 1_001_405) {

            # Update exit states
            $worldObj->ivPoke(
                'exitStateTagHash',
                'cyan',
                'emphasis',
            );
        }

        if ($world eq 'pict' && $fileVersion < 1_001_174) {

            $worldObj->ivPoke('dns', undef);
            $worldObj->ivPoke('ipv4', '136.62.89.155');
        }

        if ($world eq 'swmud' && $fileVersion < 1_001_012) {

            my $compObj;

            # Patch to fix handling of room statements, which doesn't work very well at all
            $worldObj->ivPoke(
                'verboseAnchorPatternList',
                    '^There are (.*) obvious exits\: (.*)',
                    '^The only obvious exit is (.*)\.',
                    '^There are no obvious exits\.',
            );

            $worldObj->ivPoke(
                'verboseExitDelimiterList',
                    ', and ',
                    ' and ',
                    ', ',
            );

            $worldObj->ivDelete('componentHash', 'verb_title');
            $worldObj->ivDelete('componentHash', 'verb_descrip');
            $worldObj->ivDelete('componentHash', 'ignore_line');
            $worldObj->ivDelete('componentHash', 'ignore_line_1');
            $worldObj->ivDelete('componentHash', 'ignore_line_2');
            $worldObj->ivDelete('componentHash', 'verb_exit');

            $worldObj->ivPoke(
                'verboseComponentList',
                    'verb_descrip',
                    'ignore_line_1',
                    'ignore_line_2',
                    'anchor',
                    'verb_exit',
            );

            $compObj = Games::Axmud::Obj::Component->new(
                $axmud::CLIENT,
                $worldObj,
                'verb_descrip',
                'verb_descrip',
            );

            if ($compObj) {

                $compObj->{size} = 0;
                $compObj->{minSize} = 0;
                $compObj->{maxSize} = 16;
                $compObj->{analyseMode} = 'check_line';
                $compObj->{boldSensitiveFlag} = FALSE;
                $compObj->{useInitialTagsFlag} = FALSE;
                $compObj->{combineLinesFlag} = FALSE;

                $compObj->{stopBeforePatternList} = [
                        '^\>',
                ];
                $compObj->{stopBeforeTagList} = [];
                $compObj->{stopBeforeAllFlag} = FALSE;
                $compObj->{stopBeforeTagMode} = 'default';

                $worldObj->ivAdd('componentHash', $compObj->name, $compObj);
            }

            $compObj = Games::Axmud::Obj::Component->new(
                $axmud::CLIENT,
                $worldObj,
                'ignore_line_1',
                'ignore_line',
            );

            if ($compObj) {

                $compObj->{size} = 0;
                $compObj->{minSize} = 0;
                $compObj->{maxSize} = 16;
                $compObj->{analyseMode} = 'check_line';
                $compObj->{boldSensitiveFlag} = FALSE;
                $compObj->{useInitialTagsFlag} = FALSE;
                $compObj->{combineLinesFlag} = FALSE;

                $compObj->{startPatternList} = [];
                $compObj->{startTagList} = ['green'];
                $compObj->{startAllFlag} = FALSE;
                $compObj->{startTagMode} = 'default';

                $compObj->{stopAtMode} = 'no_letter_num';

                $worldObj->ivAdd('componentHash', $compObj->name, $compObj);
            }

            $compObj = Games::Axmud::Obj::Component->new(
                $axmud::CLIENT,
                $worldObj,
                'ignore_line_2',
                'ignore_line',
            );

            if ($compObj) {

                $compObj->{size} = 1;                           # Fixed size
                $compObj->{analyseMode} = 'check_line';
                $compObj->{boldSensitiveFlag} = FALSE;
                $compObj->{useInitialTagsFlag} = FALSE;
                $compObj->{combineLinesFlag} = FALSE;

                $worldObj->ivAdd('componentHash', $compObj->name, $compObj);
            }

            $compObj = Games::Axmud::Obj::Component->new(
                $axmud::CLIENT,
                $worldObj,
                'verb_exit',
                'verb_exit',
            );

            if ($compObj) {

                $compObj->{size} = 0;
                $compObj->{minSize} = 1;
                $compObj->{maxSize} = 16;
                $compObj->{analyseMode} = 'check_line';
                $compObj->{boldSensitiveFlag} = FALSE;
                $compObj->{useInitialTagsFlag} = FALSE;
                $compObj->{combineLinesFlag} = TRUE;

                $compObj->{startPatternList} = [
                    '^There are (.*) obvious exits\: (.*)',
                    '^The only obvious exit is (.*)\.',
                    '^There are no obvious exits\.',
                ];
                $compObj->{startTagList} = [];
                $compObj->{startAllFlag} = FALSE;
                $compObj->{startTagMode} = 'default';

                $compObj->{stopPatternList} = [
                    '\.\s*$',
                ];
                $compObj->{stopTagList} = [];
                $compObj->{stopAllFlag} = FALSE;
                $compObj->{stopTagMode} = 'default';

                $compObj->{stopAtMode} = 'no_letter_num';

                $worldObj->ivAdd('componentHash', $compObj->name, $compObj);
            }
        }

        if ($world eq 'threekingdoms' && $fileVersion < 1_001_270) {

            my $compObj;

            # Patch to fix handling of verbose descriptions in room statements
            $compObj = $worldObj->ivShow('componentHash', 'verb_descrip');
            if ($compObj) {

                $compObj->{useExplicitTagsFlag} = TRUE;
            }
        }

        if ($world eq 'threescapes' && $fileVersion < 1_001_270) {

            my $compObj;

            # Patch to fix handling of verbose descriptions in room statements
            $compObj = $worldObj->ivShow('componentHash', 'verb_descrip');
            if ($compObj) {

                $compObj->{useExplicitTagsFlag} = TRUE;
            }
        }

        if ($world eq 'twotowers' && $fileVersion < 1_001_343) {

            my @newList;

            # Fix wrong channels regex
            foreach my $item ($worldObj->channelList) {

                if ($item eq '^You tell \w\: ') {
                    push (@newList, '^You tell \w+\: ');
                } else {
                    push (@newList, $item);
                }
            }

            # Patch to fix handling of brief room statements
            $worldObj->ivPoke(
                'briefAnchorPatternList',
                    '[^\s]\(([^\(\)]+\)\s\[[^\[\]]+)\]\s*$',        # Rooms with swimming
                    '[^\s]\(([^\(\)]+)\)\s*$',                      # Rooms without swimming
            );
        }

        if ($world eq 'twotowers' && $fileVersion < 1_001_405) {

            my $compObj;

            # Add a new failed exit
            $worldObj->ivPush('failExitPatternList', '^You\'re too tired to swim right now');

            # Update exit states
            $worldObj->ivPoke(
                'exitStateTagHash',
                'BLUE',
                'swim @@@',
            );

            # Set a duplicate exit replacement
            $worldObj->ivPoke('duplicateReplaceString', 'swim @@@');

            # Fix handling of room statements, after a Locator reset, in rooms with water exits
            $worldObj->ivPoke(
                'verboseAnchorPatternList',
                    '^\s\s\s\sThe only obvious exits are (.*)\.',
                    '^\s\s\s\sThe only obvious exit is (.*)\.',
            );

            $worldObj->ivDelete('componentHash', 'verb_exit');

            $worldObj->ivPoke(
                'verboseComponentList',
                    'verb_descrip',
                    'verb_exit_1',
                    'anchor',
                    'verb_exit_2',
            );

            $compObj = Games::Axmud::Obj::Component->new(
                $axmud::CLIENT,
                $worldObj,
                'verb_exit_1',
                'verb_exit',
            );

            if ($compObj) {

                $compObj->{size} = 0;
                $compObj->{minSize} = 0;                    # Optional
                $compObj->{maxSize} = 16;
                $compObj->{analyseMode} = 'check_line';
                $compObj->{boldSensitiveFlag} = FALSE;
                $compObj->{useInitialTagsFlag} = FALSE;
                $compObj->{combineLinesFlag} = FALSE;       # Water & normal exits on separate lines

                $compObj->{startPatternList} = [];
                $compObj->{startTagList} = [
                    'blue',
                ];
                $compObj->{startAllFlag} = FALSE;
                $compObj->{startTagMode} = 'default';

                $compObj->{stopAtPatternList} = [
                    '^\s\s\s\sThere is water to the (.*)\.',
                ];
                $compObj->{stopAtTagList} = [];
                $compObj->{stopAtAllFlag} = FALSE;
                $compObj->{stopAtTagMode} = 'default';

                $worldObj->ivAdd('componentHash', $compObj->name, $compObj);
            }

            $compObj = Games::Axmud::Obj::Component->new(
                $axmud::CLIENT,
                $worldObj,
                'verb_exit_2',
                'verb_exit',
            );

            if ($compObj) {

                $compObj->{size} = 0;
                $compObj->{minSize} = 1;
                $compObj->{maxSize} = 16;
                $compObj->{analyseMode} = 'check_line';
                $compObj->{boldSensitiveFlag} = FALSE;
                $compObj->{useInitialTagsFlag} = FALSE;
                $compObj->{combineLinesFlag} = FALSE;       # Water & normal exits on separate lines

                $compObj->{startPatternList} = [
                    '^\s\s\s\sThe only obvious exits are (.*)\.',
                    '^\s\s\s\sThe only obvious exit is (.*)\.',
                ];
                $compObj->{startTagList} = [];
                $compObj->{startAllFlag} = FALSE;
                $compObj->{startTagMode} = 'default';

                $compObj->{stopBeforeNoPatternList} = [
                    '^\s\s\s\sThe only obvious exits are (.*)\.',
                    '^\s\s\s\sThe only obvious exit is (.*)\.',
                ];
                $compObj->{stopBeforeNoTagList} = [];
                $compObj->{stopBeforeNoAllFlag} = FALSE;
                $compObj->{stopBeforeNoTagMode} = 'default';

                $worldObj->ivAdd('componentHash', $compObj->name, $compObj);
            }
        }

        if ($world eq 'twotowers' && $fileVersion < 1_002_000) {

            my $compObj;

            # Further fix to handling of room statements

            $worldObj->ivPoke(
                'verboseAnchorPatternList',
                    '^\s\s\s\sThe only obvious exits are (.*)',
                    '^\s\s\s\sThe only obvious exit is (.*)',
            );

            $worldObj->ivDelete('componentHash', 'verb_exit_1');
            $worldObj->ivDelete('componentHash', 'verb_exit_2');

            $compObj = Games::Axmud::Obj::Component->new(
                $axmud::CLIENT,
                $worldObj,
                'verb_exit_1',
                'verb_exit',
            );

            if ($compObj) {

                $compObj->{size} = 0;
                $compObj->{minSize} = 0;                    # Optional
                $compObj->{maxSize} = 16;
                $compObj->{analyseMode} = 'check_line';
                $compObj->{boldSensitiveFlag} = FALSE;
                $compObj->{useInitialTagsFlag} = FALSE;
                $compObj->{combineLinesFlag} = TRUE;

                $compObj->{startPatternList} = [];
                $compObj->{startTagList} = [
                    'blue',
                ];
                $compObj->{startAllFlag} = FALSE;
                $compObj->{startTagMode} = 'default';

                $compObj->{stopAtPatternList} = [
                    '^\s\s\s\sThere is water to the',
                ];
                $compObj->{stopAtTagList} = [];
                $compObj->{stopAtAllFlag} = FALSE;
                $compObj->{stopAtTagMode} = 'default';

                $worldObj->ivAdd('componentHash', $compObj->name, $compObj);
            }

            $compObj = Games::Axmud::Obj::Component->new(
                $axmud::CLIENT,
                $worldObj,
                'verb_exit_2',
                'verb_exit',
            );

            if ($compObj) {

                $compObj->{size} = 0;
                $compObj->{minSize} = 1;
                $compObj->{maxSize} = 16;
                $compObj->{analyseMode} = 'check_line';
                $compObj->{boldSensitiveFlag} = FALSE;
                $compObj->{useInitialTagsFlag} = FALSE;
                $compObj->{combineLinesFlag} = TRUE;

                $compObj->{startPatternList} = [
                    '^\s\s\s\sThe only obvious exits are',
                    '^\s\s\s\sThe only obvious exit is',
                ];
                $compObj->{startTagList} = [];
                $compObj->{startAllFlag} = FALSE;
                $compObj->{startTagMode} = 'default';

                $compObj->{stopAtPatternList} = [
                    '\.\s*$',
                ];
                $compObj->{stopAtTagList} = [];
                $compObj->{stopAtAllFlag} = FALSE;
                $compObj->{stopAtTagMode} = 'default';

                $worldObj->ivAdd('componentHash', $compObj->name, $compObj);
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
        if (! $hashRef || (ref $hashRef) ne 'HASH') {

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
        # Converts AMud::ModelObj::Region > Games::Axmud::ModelObj::Region, etc

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

        # NB The calling function, $func, is disregarded if specified

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

    sub set_preserveBackupFlag {

        # NB The calling function, $func, is disregarded if specified

        my ($self, $flag, $func, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_preserveBackupFlag', @_);
        }

        if ($flag) {
            $self->{preserveBackupFlag} = TRUE;
        } else {
            $self->{preserveBackupFlag} = FALSE;
        }

        return $self->preserveBackupFlag;
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
    sub preserveBackupFlag
        { $_[0]->{preserveBackupFlag} }
}

# Package must return a true value
1
