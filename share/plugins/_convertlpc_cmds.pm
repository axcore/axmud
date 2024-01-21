#!/usr/bin/perl -w

# Client commands for the 'convertlpc' plugin

{ package Games::Axmud::Cmd::Plugin::ConvertLPC;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Plugin::Cmd Games::Axmud::Generic::Cmd Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Create a new instance of this command object (there should only be one)
        #
        # Expected arguments
        #   (none besides $class)
        #
        # Return values
        #   'undef' if GA::Generic::Cmd->new reports an error
        #   Blessed reference to the new object on success

        my ($class, $check) = @_;

        # Setup
        my $self = Games::Axmud::Generic::Cmd->new('convertlpc', FALSE, TRUE);
        if (! $self) {return undef};

        $self->{defaultUserCmdList} = ['clpc', 'convertlpc'];
        $self->{userCmdList} = \@{$self->{defaultUserCmdList}};
        $self->{descrip} = '(convertlpc plugin) Converts world model to '
                                . $convertlpc::CONVERT_TYPE;

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub do {

        my (
            $self, $session, $inputString, $userCmd, $standardCmd,
            $switch,
            $check,
        ) = @_;

        # Local variables
        my (
            $wmObj, $world, $noWriteFlag, $roomCount, $otherCount, $errorCount, $totalCount, $dir,
            $msg,
            @regionOrderList,
            %regionHash, %checkHash, %tierHash, %usedHash, %convertHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $self->improper($session, $inputString);
        }

        # Import the world model (which contains any maps you've drawn) and the current world's name
        #   (for convenience)
        $wmObj = $session->worldModelObj;
        $world = $session->currentWorld->name;

        # Deal with the switch, if specified
        if ($switch) {

            if ($switch ne '-n') {

                return $self->error(
                    $session, $inputString,
                    'Invalid switch (try \';convertlpc -n\')',
                );

            } else {

                # Don't actually write any LPC files
                $noWriteFlag = TRUE;
            }
        }

        # Compile a hash of regions, in the form
        #   $regionHash{world_model_number} = modified_region_name
        # ...where 'modified_region_name' is the region's usual name, with all whitespace converted
        #   to underline characters, all non-alphanumeric characters removed, and everything
        #   converted to lower-case (NB If $NO_UNDERLINE_FLAG is set, whitespace is removed
        #   rather than being converted)
        # %checkHash is used to make sure there are no duplicates of 'modified_region_name'
        foreach my $regionObj ($wmObj->ivValues('regionModelHash')) {

            my $name = $regionObj->name;

            if (exists $convertlpc::SPECIAL_NAME_HASH{$name}) {

                # Use the modified form specified by the global variable, e.g. use 'ndesert' rather
                #   than 'Northern desert'
                $name = $convertlpc::SPECIAL_NAME_HASH{$name};

            } elsif (! $convertlpc::NO_UNDERLINE_FLAG) {

                # Use the region name specified by the world model, but replace whitespace with
                #   underlines
                $name =~ s/\s+/_/;

            } else {

                # Use the region name specified by the world model, but remove whitespace
                $name =~ s/\s+//;
            }

            # Remove any leading whitespace
            $name =~ s/[^\w]//;
            $name = lc($name);

            if (exists $checkHash{$name}) {

                return $self->error(
                    $session, $inputString,
                    'Command produced a duplicate region name \'' . $name . '\'',
                );

            } else {

                $regionHash{$regionObj->number} = $name;
                $checkHash{$name} = undef;
            }
        }

        # Compile a parallel hash of regions, which allows us to create subdirectories for tiered
        #   (i.e. nested) domains, if required
        # If $NEST_DIRECTORIES_FLAG is TRUE, hash in the form
        #   $tierHash{world_model_number} = parent_modified_region_name/modified_region_name
        #   $tierHash{world_model_number} = modified_region_name    (for regions with no parent)
        # If $NEST_DIRECTORIES_FLAG is FALSE, hash in the form
        #   $tierHash{world_model_number} = modified_region_name    (for all regions)
        if (! $convertlpc::NEST_DIRECTORIES_FLAG) {

            %tierHash = %regionHash;

        } else {

            foreach my $regionObj ($wmObj->ivValues('regionModelHash')) {

                my ($path, $parentRegionObj);

                $path = $regionHash{$regionObj->number};
                $parentRegionObj = $regionObj;

                if ($regionObj->parent) {

                    do {

                        my $parentModName;

                        $parentRegionObj
                            = $wmObj->ivShow('regionModelHash', $parentRegionObj->parent);
                        $parentModName = $regionHash{$parentRegionObj->number};

                        $path = $parentModName . '/' . $path;

                    } until (! $parentRegionObj->parent);

                }

                $tierHash{$regionObj->number} = $path;
            }
        }

        # Perl requires us to create directories before creating sub-directories, so first compile a
        #   list of regions, in which child regions always appear after their parent regions
        @regionOrderList = $self->compileRegionList($session);
        if (! @regionOrderList) {

            # (If there are no regions, then there are also no rooms)
            return $self->error($session, $inputString, 'No regions or rooms found to convert');
        }

        if (! $noWriteFlag) {

            # Make sure the output directory exists
            if (! -e $convertlpc::DIRECTORY) {

                mkdir $convertlpc::DIRECTORY, 0755;
                if (! -e $convertlpc::DIRECTORY) {

                    return $self->error(
                        $session, $inputString,
                        'Failed to create directory ' . $convertlpc::DIRECTORY,
                    );
                }
            }

            # Make sure the /<world> directory exists
            $dir = $convertlpc::DIRECTORY . '/' . $world;
            mkdir $dir, 0755;
            if (! -e $dir) {

                return $self->error($session, $inputString, 'Failed to create directory ' . $dir);
            }

            # Make sure the /<world>/domains directory exists
            $dir = $convertlpc::DIRECTORY . '/' . $world . '/domains';
            mkdir $dir, 0755;
            if (! -e $dir) {

                return $self->error($session, $inputString, 'Failed to create directory ' . $dir);
            }

            # Create a directory for each region
            foreach my $regionNum (@regionOrderList) {

                my $path = $tierHash{$regionNum};

                $dir = $convertlpc::DIRECTORY . '/' . $world . '/domains/' . $path;

                mkdir $dir, 0755;
                if (! -e $dir) {

                    return $self->error(
                        $session, $inputString,
                        'Failed to create directory ' . $dir,
                    );
                }

                # Create sub-directories for rooms and other categories of model objects (sentients,
                #   creatures, decorations etc), regardless of whether we're going to convert those
                #   objects to LPC files, or not
                foreach my $type (keys %convertlpc::DIRECTORY_HASH) {

                    my $subDir = $convertlpc::DIRECTORY_HASH{$type};

                    $dir = $convertlpc::DIRECTORY . '/' . $world . '/domains/' . $path . '/'
                                . $subDir;

                    mkdir $dir, 0755;
                    if (! -e $dir) {

                        return $self->error(
                            $session, $inputString,
                            'Failed to create directory ' . $dir,
                        );
                    }
                }
            }
        }

        # In the LPC mudlib, every room has its own file. Many objects (orcs, swords etc) also
        #   have their own file, though some objects (usually immovable objects) are defined in the
        #   room code
        # Decide what the filepath will be used for each room in the world model
        OUTER: foreach my $regionObj ($wmObj->ivValues('regionModelHash')) {

            my ($regionmapObj, $regionPath);

            $regionmapObj = $wmObj->ivShow('regionmapHash', $regionObj->name);
            $regionPath = $tierHash{$regionObj->number};

            foreach my $roomNum ($regionmapObj->ivValues('gridRoomHash')) {

                my (
                    $roomObj, $roomPath, $fileHandle,
                    @list,
                );

                $roomObj = $wmObj->ivShow('modelHash', $roomNum);

                # Decide on the filepath of the LPC file for this room...
                $roomPath = $self->allocateRoomPath(
                    \%usedHash,     # Hash of filepaths that have already been used
                    $world,
                    $regionPath,    # (The directory in which this file is stored)
                    $roomObj,
                );

                # ...and store the filepath here
                $convertHash{$roomObj->number} = $roomPath;

                # Decide on the filepath for any objects in this room (any world model objects whose
                #   parent is this room)
                foreach my $childNum ($roomObj->ivKeys('childHash')) {

                    my ($childObj, $childPath);

                    $childObj = $wmObj->ivShow('modelHash', $childNum);

                    # If this is one of the categories of model object we're converting to LPC...
                    if (
                        $childObj->category ne 'room'
                        && exists $convertlpc::CATEGORY_HASH{$childObj->category}
                    ) {
                        # Decide on the filepath of this LPC file for this object...
                        $childPath = $self->allocateChildPath(
                            \%usedHash,     # Hash of filepaths that have already been used
                            $world,
                            $regionPath,    # (The directory in which this file is stored)
                            $childObj,
                        );

                        # ...and store it here
                        $convertHash{$childObj->number} = $childPath;
                    }
                }
            }
        }

        # Show an introductory message in the 'main' window
        if (! $noWriteFlag) {

            $self->writeText('Converting world model to ' . $convertlpc::CONVERT_TYPE . '...');

        } else {

            $self->writeText(
                'Simulating conversion of world model to ' . $convertlpc::CONVERT_TYPE . '...',
            );
        }

        # (Display the message above right now)
        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->do');

        # Work out how many files will be written
        $roomCount = 0;
        $otherCount = 0;
        $errorCount = 0;
        $totalCount = 0;

        OUTER: foreach my $category (@convertlpc::CATEGORY_LIST) {

            my $iv = $category . 'ModelHash';   # Instance variable, e.g. '->roomModelHash'

            # If we're allowed to write this type of object...
            if ($convertlpc::CATEGORY_HASH{$category}) {

                $totalCount += $wmObj->ivPairs($iv);
            }
        }

        # Now write files (or simulate writing files) for each category of object in turn, starting
        #   with rooms
        OUTER: foreach my $category (@convertlpc::CATEGORY_LIST) {

            my $iv = $category . 'ModelHash';   # Instance variable, e.g. '->roomModelHash'

            # If we're allowed to write this type of object...
            if ($convertlpc::CATEGORY_HASH{$category}) {

                INNER: foreach my $modelObj ($wmObj->ivValues($iv)) {

                    my (
                        $path, $fullPath, $fileHandle, $currentCount, $subName,
                        @list,
                    );

                    # Use the filepath that has already been allocated to this model object
                    $path = $convertHash{$modelObj->number};
                    if (! $path) {

                        # This object is a region, or some other non-room object that's not
                        #   actually contained in a room
                        next INNER;
                    }

                    # Prepare the file to write, before actually writing it
                    $subName = 'prepare' . ucfirst($category);      # e.g. ->prepareRoom

                    @list = $self->$subName($session, \%convertHash, $modelObj);
                    if (! @list) {

                        $errorCount++;

                        if ($convertlpc::NO_ERROR_FLAG) {

                            # Give up writing files at the first error
                            last OUTER;
                        }
                    }

                    # Add the copyright message (if any) to the top of the prepared file
                    unshift (@list, @convertlpc::COPYRIGHT_LIST);

                    if (! $noWriteFlag) {

                        # Now write the file
                        $fullPath = $convertlpc::DIRECTORY . '/' . $world . '/' . $path . '.c';

                        if (! open ($fileHandle, ">$fullPath")) {

                            $self->writeText(
                                '   Failed to write ' . $category . ' #' . $modelObj->number . ': '
                                . $fullPath,
                            );

                            $errorCount++;

                            if ($convertlpc::NO_ERROR_FLAG) {

                                # Give up writing files at the first error
                                last OUTER;
                            }

                        } else {

                            # File opened for writing
                            foreach my $line (@list) {

                                print $fileHandle $line . "\n";
                            }

                            close $fileHandle;

                            if ($category eq 'room') {
                                $roomCount++;
                            } else {
                                $otherCount++;
                            }
                        }

                    } else {

                        # Simulate writing files (actually, just keep count of the number of files
                        #   we would have written)
                        if ($category eq 'room') {
                            $roomCount++;
                        } else {
                            $otherCount++;
                        }
                    }

                    # Show an update from time to time, if necessary
                    $currentCount = $roomCount + $otherCount;
                    if (
                        $convertlpc::UPDATE_COUNT
                        && (
                            (
                                int ($currentCount / $convertlpc::UPDATE_COUNT)
                                    == ($currentCount / $convertlpc::UPDATE_COUNT)
                                || $currentCount == $totalCount
                            )
                        )
                    ) {
                        $self->writeText(
                            '   Generated files: ' . $currentCount . '/' . $totalCount
                            . ', errors: ' . $errorCount,
                        );

                        $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->do');
                    }

                    if ($currentCount >= $convertlpc::MAX_FILES) {

                        # Don't create unlimited model objects
                        $self->writeText(
                            'Reached file limit (' . $roomCount . '), not generating any more'
                            . ' files',
                        );

                        last OUTER;
                    }
                }
            }
        }

        # Operation complete. Show a confirmation message
        if (! $noWriteFlag) {
            $msg = 'Conversion';
        } else {
            $msg = 'Simulated conversion';
        }

        return $self->complete(
            $session, $standardCmd,
            $msg . ' complete (regions: ' . scalar (keys %regionHash) . ', rooms: ' . $roomCount
            . ', other objects: ' . $otherCount . ', errors: ' . $errorCount . ')',
        );
    }

    sub allocateRoomPath {

        # Called by $self->do
        #
        # Every room in the world model is converted to a single LPC file. This function creates a
        #   unique filepath for each room (i.e. if there's already a
        #   '/domains/<world>/town/room/shop.c', then use a filepath like
        #   '/domains/<world>/town/room/shop2.c' instead)
        #
        # Expected arguments
        #   $usedHashRef    - A hash in the form
        #                       $usedHash{file_path} = undef
        #   $world          - The current world's ->name
        #   $modRegionName  - The parent region's (modified) name
        #   $roomObj        - A GA::ModelObj::Room object in the world model
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $usedHashRef, $world, $modRegionName, $roomObj, $check) = @_;

        # Local variables
        my (
            $title, $filePath, $modFilePath,
            @wordList, @modList,
        );

        # Check for improper arguments
        if (
            ! defined $usedHashRef || ! defined $world || ! defined $modRegionName
            || ! defined $roomObj || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->allocateRoomPath', @_);
        }

        # Convert the room title (brief description) into a suitable file-like string
        $title = $roomObj->ivFirst('titleList');
        if (! $title) {

            # The room's brief description is not stored in the world model
            $title = 'genericroom';

        } else {

            # Remove any non-alphanumeric characters
            $title =~ s/[^\w\s]//;

            # Split the room title into words, so that we can remove any words we don't want
            @wordList = split(m/\s+/, lc($title));

            # Remove unwanted words like 'the', 'of', etc
            foreach my $word (@wordList) {

                if (! exists $convertlpc::REMOVE_HASH{$word}) {

                    push (@modList, $word);
                }
            }

            if (! @modList) {

                # Room's brief descrip inexplicably consists of nothing but articles like 'the'
                @modList = ('genericroom');
            }

            @wordList = @modList;

            # Reduce the number of words used, if the global variable is set
            if (
                $convertlpc::MAX_WORDS
                && $convertlpc::MAX_WORDS < (scalar @wordList)
            ) {
                @modList = ();

                for (my $count = 0; $count < $convertlpc::MAX_WORDS; $count++) {

                    push (@modList, $wordList[$count]);
                }

                @wordList = @modList;
            }

            if (! $convertlpc::NO_UNDERLINE_FLAG) {
                $title = join('_', @wordList);
            } else {
                $title = join('', @wordList);
            }

            # Apply max characters to the file name
            if (length ($title) > $convertlpc::MAX_FILE_NAME_SIZE) {

                $title = substr($title, 0, $convertlpc::MAX_FILE_NAME_SIZE);
            }
        }

        # Convert the filename into a filepath, e.g. convert 'start' into
        #   '/domains/<world>/town/room/start'
        $filePath = '/domains/' . $modRegionName . '/' . $convertlpc::DIRECTORY_HASH{'room'}
                        . '/' . $title;

        # If this file already exists, add a number to the file name to produce a unique file path
        #   (e.g. if 'start' is already used, try 'start2', 'start3', etc)
        if (exists $$usedHashRef{$filePath}) {

            $filePath = $self->modifyFilePath($usedHashRef, $filePath);
        }

        # Filepath generated
        $$usedHashRef{$filePath} = undef;

        return $filePath;
    }

    sub allocateChildPath {

        # Called by $self->do
        #
        # Most objects in the world model are converted to a single LPC file. This function creates
        #   a unique filepath for each object (i.e. if there's already a
        #   '/domains/<world>/town/npc/orc.c', then use a filepath like
        #   '/domains/<world>/town/npc/orc2.c' instead)
        #
        # Expected arguments
        #   $usedHashRef    - A hash in the form
        #                       $usedHash{file_path} = undef
        #   $world          - The current world's ->name
        #   $modRegionName  - The parent region's (modified) name
        #   $childObj       - A model object stored in one of the region's rooms (i.e. whose
        #                       ->parent is that room)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $usedHashRef, $world, $modRegionName, $childObj, $check) = @_;

        # Local variables
        my (
            $title, $filePath, $modFilePath,
            @wordList, @modList,
        );

        # Check for improper arguments
        if (
            ! defined $usedHashRef || ! defined $world || ! defined $modRegionName
            || ! defined $childObj || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->allocateChildPath', @_);
        }

        # Convert the object's base string (e.g. 'big sword') into a suitable filename-like string
        $title = $childObj->baseString;

        # Remove any non-alphanumeric characters (just in case)
        $title =~ s/[^\w\s]//;

        # Split the title into words, so that we can remove any words we don't want
        @wordList = split(m/\s+/, lc($title));

        # Remove unwanted words like 'the', 'of', etc
        foreach my $word (@wordList) {

            if (! exists $convertlpc::REMOVE_HASH{$word}) {

                push (@modList, $word);
            }
        }

        if (! @modList) {

            # Object's base string inexplicably consists of nothing but articles like 'the'
            @modList = ('genericroom');
        }

        @wordList = @modList;

        # Reduce the number of words used, if the global variable is set
        if (
            $convertlpc::MAX_WORDS
            && $convertlpc::MAX_WORDS < (scalar @wordList)
        ) {
            @modList = ();

            for (my $count = 0; $count < $convertlpc::MAX_WORDS; $count++) {

                push (@modList, $wordList[$count]);
            }

            @wordList = @modList;
        }

        if (! $convertlpc::NO_UNDERLINE_FLAG) {
            $title = join('_', @wordList);
        } else {
            $title = join('', @wordList);
        }

        # Apply max characters to the file name
        if (length ($title) > $convertlpc::MAX_FILE_NAME_SIZE) {

            $title = substr($title, 0, $convertlpc::MAX_FILE_NAME_SIZE);
        }

        # Convert the filename into a filepath, e.g. convert 'orc' into
        #   '/domains/<world>/town/sentient/orc'
        $filePath = '/domains/' . $modRegionName . '/'
                        . $convertlpc::DIRECTORY_HASH{$childObj->category} . '/' . $title;

        # If this file already exists, add a number to the file name to produce a unique file path
        #   (e.g. if 'orc' is already used, try 'orc2', 'orc3', etc)
        if (exists $$usedHashRef{$filePath}) {

            $filePath = $self->modifyFilePath($usedHashRef, $filePath);
        }

        # Filepath generated
        $$usedHashRef{$filePath} = undef;

        return $filePath;
    }

    sub modifyFilePath {

        # Called by $self->getFilePath
        #
        # The calling function generates a filepath, e.g. '/domains/town/room/start' or
        #   '/domains/<world>/town/npc/orc'
        # If that filepath has already been allocated to another model object, modify the filepath
        #   by adding a unique number to it, until we find a filepath that's available (but we don't
        #   use random numbers: we want '.../start2', '.../start3', '.../start4'... not
        #   '.../start591', '.../start3819', '.../start99999' etc)
        # Since there might be thousands of objects with the same title, this function uses an
        #   algorithm to find the first multiple of 100 ('.../start100', '.../start200',
        #   '.../start300' etc) that's available, and then starts checking 99 rooms before that
        #   ('.../start201', '.../start202' etc)
        # Note that filepaths are allocated in the sequence '.../start', '.../start2', '.../start3',
        #   not in the sequence '.../start1', '.../start2', '.../start3'
        #
        # Expected arguments
        #   $usedHashRef    - A hash in the form
        #                       $fileHash{file_path} = undef
        #   $filePath       - A filepath which is already in use by another object, e.g.
        #                       '/domains/town/room/start'
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $usedHashRef, $filePath, $check) = @_;

        # Local variables
        my ($count, $thisPath);

        # Check for improper arguments
        if (! defined $usedHashRef || ! defined $filePath || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->modifyFilePath', @_);
        }

        # Find the first available multiple of 100
        $count = 0;
        do {

            $count += 100;
            $thisPath = $filePath . $count;

        } until (! exists $$usedHashRef{$thisPath});

        # Now, start checking 99 before that (but the first file after 'xxx' should be 'xxx2',
        #   not 'xxx1'
        $count -= 100;      # First do...until loop will add 1
        if (! $count) {

            $count = 1;     # First do...until loop will add 1
        }

        do {

            $count++;      # So the first actual file that can ever be checked is, e.g. '.../start2'

            $thisPath = $filePath . $count;

            if (! exists $$usedHashRef{$thisPath}) {

                # This filepath is available
                return $thisPath;
            }

        } until (0);
    }

    sub compileRegionList {

        # Called by $self->do
        #
        # Compiles a list of model region numbers, in which any child region is guaranteed to
        #   appear after its parent
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #
        # Return values
        #   An empty list on improper arguments
        #   An ordered list of model region numbers on success (might be an empty list, if there are
        #       no regions in the world model)

        my ($self, $session, $check) = @_;

        # Local variables
        my (
            @emptyList, @list, @returnList,
            %parentHash,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->compileRegionList', @_);
            return @emptyList;
        }

        # Import the list of model region numbers
        @list = $session->worldModelObj->ivKeys('regionModelHash');
        if (! @list) {

            return @emptyList;
        }

        # Sort the list, so that parent regions always appear before their children
        do {

            my @modList;

            foreach my $regionNum (@list) {

                my $regionObj = $session->worldModelObj->ivShow('regionModelHash', $regionNum);

                if (
                    # This region has no parent
                    ! $regionObj->parent
                    # The region's parent has already been moved to @orderedList
                    || exists $parentHash{$regionObj->parent}
                ) {
                    push (@returnList, $regionNum);
                    $parentHash{$regionNum} = undef;

                } else {

                    # Try again on the next do.. loop, hoping that the region's parent region will
                    #   by then have been moved to @returnList
                    push (@modList, $regionNum);
                }
            }

            # Once every region has been added to @returnList, then @modList will be empty...
            @list = @modList;

        # ...allowing us to exit the do.. loop
        } until (! @list);

        return @returnList;
    }

    sub prepareRoom {

        # Called by $self->do
        #
        # Prepares a list of strings for a single world model room, which will be written as a
        #   single LPC file
        # (The code used is based on the Dead Souls room /domains/town/room/start.c)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $convertHashRef - Reference to the hash of file paths created by the calling function,
        #                       in the form
        #                           $convertHash{model_number} = file_path;
        #   $roomObj        - The room model object to use
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list of strings, which the calling function can write as an LPC
        #       file

        my ($self, $session, $convertHashRef, $roomObj, $check) = @_;

        # Local variables
        my (
            $day, $night,
            @emptyList, @list, @childList,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $convertHashRef || ! defined $roomObj
            || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->prepareRoom', @_);
            return @emptyList;
        }

        #    #include <lib.h>
        #    #include <terrain_types.h>
        #
        #    inherit LIB_ROOM;
        #
        push (@list,
            '#include <lib.h>',
            '#include <terrain_types.h>',
            ' ',
            'inherit LIB_ROOM;',
            ' ',
        );

        #    static void create() {
        #    room::create();
        #    SetClimate("outdoors");
        #    SetAmbientLight(30);
        push (@list,
            'static void create() {',
            '    room::create();',
            '    SetClimate("outdoors");',
            '    SetAmbientLight(30);',
        );

        #   SetShort("Village Road Intersection");
        if ($roomObj->titleList) {

            # Use the first available room title (brief description)
            push (@list,
                '    SetShort("' . $roomObj->ivFirst('titleList') . '");',
            );

        } else {

            # Use a generic room title
            push (@list,
                '    SetShort("Generic room");',
            );
        }

        #   SetNightLong("You are in the main intersection of the village, lit by...");
        #   SetDayLong("You are in the main intersection of the village...");
        if ($roomObj->ivExists('descripHash', 'day')) {
            $day = $roomObj->ivShow('descripHash', 'day');
        } else {
            $day = 'Generic description';
        }

        if ($roomObj->ivExists('descripHash', 'night')) {

            $night = $roomObj->ivShow('descripHash', 'night');

            } else {

            # If a separate description for night hours isn't known, use the description seen
            #   used in daylight hours
            $night = $day;
        }

        push (@list,
            '    SetNightLong("' . $night . '");',
            '    SetDayLong("' . $night . '");',
        );

        #   SetItems( ([ ]) );
        push (@list,
            '    SetItems( ([ ]) );',
        );

        #   SetExits( ([
        #                "south" : "/domains/town/room/south_road1",
        #                "east" : "/domains/town/room/vill_road2",
        #                "west" : "/domains/town/room/road1",
        #                "north" : "/domains/town/room/road0.c",
        #              ]) );
        push (@list,
            '    SetExits( ([',
        );

        foreach my $dir ($roomObj->ivKeys('exitNumHash')) {

            my ($exitNum, $exitObj, $destRoomNum, $destRoomObj, $destRoomPath);

            $exitNum = $roomObj->ivShow('exitNumHash', $dir);
            $exitObj = $session->worldModelObj->ivShow('exitModelHash', $exitNum);

            if ($exitObj->destRoom) {

                $destRoomNum = $exitObj->destRoom;
                $destRoomObj = $session->worldModelObj->ivShow('modelHash', $destRoomNum);
                $destRoomPath = $$convertHashRef{$destRoomNum};

            } else {

                $destRoomPath = "";     # Exit goes nowhere
            }

            push (@list,
                '                "' . $dir . '" : "' . $destRoomPath . '",',
            );
        }

        push (@list,
            '              ]) );',
        );

        #   AddTerrainType(T_ROAD);
        # (Use this only if the room has a room flag which marks it as a road)
        if (
            $roomObj->ivExists('roomFlagHash', 'main_route')
            || $roomObj->ivExists('roomFlagHash', 'minor_route')
            || $roomObj->ivExists('roomFlagHash', 'cross_route')
        ) {
            push (@list,
                '    AddTerrainType(T_ROAD);',
            );
        }

        #   SetInventory( ([ ]) );
        # (Not all child objects are converted to LPC files. Get a list of those that are)
        foreach my $childNum ($roomObj->ivKeys('childHash')) {

            if (exists $$convertHashRef{$childNum}) {

                push (@childList, $childNum);
            }
        }

        if (! @childList) {

            # (No child objects to convert)
            push (@list,
                '    SetInventory( ([ ]) );',
            );

        } else {

            # (Convert at least one child object)
            push (@list,
                '    SetInventory( ([',
            );

            foreach my $childNum (@childList) {

                push (@list,
                    '                "' . $$convertHashRef{$childNum} . '" : 1,',
                );
            }

            push (@list,
                '              ]) );',
            );
        }

        #   SetNoModify(0);
        #   SetEnters( ([ ]) );
        #   }
        #
        #   void init(){
        #       ::init();
        #   }
        push (@list,
            '    SetNoModify(0);',
            '    SetEnters( ([ ]) );',
            '}',
            '',
            'void init(){',
            '    ::init();',
            '}',
        );

        # Operation complete
        return @list;
    }

    sub prepareWeapon {

        # Called by $self->do
        #
        # Prepares a list of strings for a single world model weapon, which will be written as a
        #   single LPC file
        # (The code used is based on the Dead Souls object /domains/town/weap/sword.c)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $convertHashRef - Reference to the hash of file paths created by the calling function,
        #                       in the form
        #                           $convertHash{model_number} = file_path;
        #   $modelObj        - The weapon model object to use
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list of strings, which the calling function can write as an LPC
        #       file

        my ($self, $session, $convertHashRef, $modelObj, $check) = @_;

        # Local variables
        my (
            $adjString, $shortString, $longString, $weightString, $valueString,
            @emptyList, @list,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $convertHashRef || ! defined $modelObj
            || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->prepareWeapon', @_);
            return @emptyList;
        }

        #    #include <lib.h>
        #    #include <damage_types.h>
        #    #include <vendor_types.h>
        #
        #    inherit LIB_ITEM;
        #
        push (@list,
            '#include <lib.h>',
            '#include <damage_types.h>',
            '#include <vendor_types.h>',
            ' ',
            'inherit LIB_ITEM;',
            ' ',
        );

        #    static void create() {
        #    item::create();
        push (@list,
            'static void create() {',
            '    item::create();',
        );

        #   SetKeyName("short sword");
        #   SetId( ({ "sword", "short sword" }) );
        push (@list,
            '    SetKeyName("' . $modelObj->baseString . '");',
            '    SetId( ({ "' . $modelObj->noun . '", "' . $modelObj->baseString . '" }) );',
        );

        #   SetAdjectives( ({ "short" }) );
        foreach my $adj ($modelObj->adjList) {

            if ($adjString) {

                $adjString .= ', ';
            }

            $adjString = '"' . $adj . '"';
        }

        if (! $adjString) {

            push (@list,
                '    SetAdjectives();',
            );

        } else {

            push (@list,
                '    SetAdjectives( ({ ' . $adjString . '}) );',
            );
        }

        #   SetShort("a short sword");
        if ($modelObj->baseString =~ m/^[AEIOUaeiou]/) {
            $shortString = 'an ' . $modelObj->baseString;
        } else {
            $shortString = 'a ' . $modelObj->baseString;
        }

        push (@list,
            '    SetShort("' . $shortString . '");',
        );

        #   SetLong("A cheap and rather dull short sword.");
        if ($modelObj->descrip) {
            $longString = $modelObj->descrip;
        } else {
            $longString = $convertlpc::NULL_OBJ_DESCRIP;
        }

        push (@list,
            '    SetLong("' . $longString . '");',
        );

        #   SetMass(300);
        if ($modelObj->weight) {
            $weightString = $modelObj->weight;
        } else {
            $weightString = $convertlpc::DEFAULT_WEIGHT;
        }

        push (@list,
            '    SetMass(' . $weightString . ');',
        );

        #   SetBaseCost("silver", 800);
        if ($modelObj->buyValue) {
            $valueString = $modelObj->buyValue;
        } elsif ($modelObj->sellValue) {
            $valueString = $modelObj->sellValue;
        } else {
            $valueString = $convertlpc::DEFAULT_VALUE;
        }

        push (@list,
            '    SetBaseCost("' . $convertlpc::DEFAULT_CURRENCY . '", ' . $valueString . ');',
        );

        #   SetVendorType(VT_WEAPON);
        #   SetClass(30);
        #   SetDamageType(BLADE);
        #   SetWeaponType("blade");
        #   }
        #
        #   void init(){
        #       ::init();
        #   }
        push (@list,
            '    SetVendorType(VT_WEAPON);',
            '    SetClass(30);',
            '    SetDamageType(BLADE);',
            '    SetWeaponType("blade");',
            '}',
            '',
            'void init(){',
            '    ::init();',
            '}',
        );

        # Operation complete
        return @list;
    }

    sub prepareArmour {

        # Called by $self->do
        #
        # Prepares a list of strings for a single world model armour, which will be written as a
        #   single LPC file
        # (The code used is based on the Dead Souls object /domains/town/armor/chainmail.c)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $convertHashRef - Reference to the hash of file paths created by the calling function,
        #                       in the form
        #                           $convertHash{model_number} = file_path;
        #   $modelObj        - The weapon model object to use
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list of strings, which the calling function can write as an LPC
        #       file

        my ($self, $session, $convertHashRef, $modelObj, $check) = @_;

        # Local variables
        my (
            $adjString, $shortString, $longString, $weightString, $valueString,
            @emptyList, @list,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $convertHashRef || ! defined $modelObj
            || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->prepareArmour', @_);
            return @emptyList;
        }

        #    #include <lib.h>
        #    #include <armor_types.h>
        #    #include <damage_types.h>
        #
        #    inherit LIB_ARMOR;
        #
        push (@list,
            '#include <lib.h>',
            '#include <armor_types.h>',
            '#include <damage_types.h>',
            ' ',
            'inherit LIB_ARMOR;',
            ' ',
        );

        #    static void create() {
        #    armor::create();
        push (@list,
            'static void create() {',
            '    armor::create();',
        );

        #   SetKeyName("chainmail shirt");
        #   SetId( ({ "shirt", "chainmail shirt" }) );
        push (@list,
            '    SetKeyName("' . $modelObj->baseString . '");',
            '    SetId( ({ "' . $modelObj->noun . '", "' . $modelObj->baseString . '" }) );',
        );

        #   SetAdjectives( ({ "chainmail" }) );
        foreach my $adj ($modelObj->adjList) {

            if ($adjString) {

                $adjString .= ', ';
            }

            $adjString = '"' . $adj . '"';
        }

        if (! $adjString) {

            push (@list,
                '    SetAdjectives();',
            );

        } else {

            push (@list,
                '    SetAdjectives( ({ ' . $adjString . '}) );',
            );
        }

        #   SetShort("a chainmail shirt");
        if ($modelObj->baseString =~ m/^[AEIOUaeiou]/) {
            $shortString = 'an ' . $modelObj->baseString;
        } else {
            $shortString = 'a ' . $modelObj->baseString;
        }

        push (@list,
            '    SetShort("' . $shortString . '");',
        );

        #   SetLong("This is a shirt made of small, thin metal rings fashioned together as armor.");
        if ($modelObj->descrip) {
            $longString = $modelObj->descrip;
        } else {
            $longString = $convertlpc::NULL_OBJ_DESCRIP;
        }

        push (@list,
            '    SetLong("' . $longString . '");',
        );

        #   SetMass(200);
        if ($modelObj->weight) {
            $weightString = $modelObj->weight;
        } else {
            $weightString = $convertlpc::DEFAULT_WEIGHT;
        }

        push (@list,
            '    SetMass(' . $weightString . ');',
        );

        #   SetBaseCost("silver", 800);
        if ($modelObj->buyValue) {
            $valueString = $modelObj->buyValue;
        } elsif ($modelObj->sellValue) {
            $valueString = $modelObj->sellValue;
        } else {
            $valueString = $convertlpc::DEFAULT_VALUE;
        }

        push (@list,
            '    SetBaseCost("' . $convertlpc::DEFAULT_CURRENCY . '", ' . $valueString . ');',
        );

        #   SetProtection(BLUNT,5);
        #   SetProtection(BLADE,20);
        #   SetProtection(KNIFE,20);
        #   SetArmorType(A_ARMOR);
        #   }
        #
        #   void init(){
        #       ::init();
        #   }
        push (@list,
            '    SetProtection(BLUNT,5);',
            '    SetProtection(BLADE,20);',
            '    SetProtection(KNIFE,20);',
            '    SetArmorType(A_ARMOR);',
            '}',
            '',
            'void init(){',
            '    ::init();',
            '}',
        );

        # Operation complete
        return @list;
    }

    sub prepareGarment {

        # Called by $self->do
        #
        # Prepares a list of strings for a single world model garment, which will be written as a
        #   single LPC file
        # (The code used is based on the Dead Souls object /domains/town/armor/shirt.c)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $convertHashRef - Reference to the hash of file paths created by the calling function,
        #                       in the form
        #                           $convertHash{model_number} = file_path;
        #   $modelObj        - The weapon model object to use
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list of strings, which the calling function can write as an LPC
        #       file

        my ($self, $session, $convertHashRef, $modelObj, $check) = @_;

        # Local variables
        my (
            $adjString, $shortString, $longString, $weightString, $valueString,
            @emptyList, @list,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $convertHashRef || ! defined $modelObj
            || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->prepareGarment', @_);
            return @emptyList;
        }

        #    #include <lib.h>
        #    #include <armor_types.h>
        #    #include <damage_types.h>
        #
        #    inherit LIB_ARMOR;
        #
        push (@list,
            '#include <lib.h>',
            '#include <armor_types.h>',
            '#include <damage_types.h>',
            ' ',
            'inherit LIB_ARMOR;',
            ' ',
        );

        #    static void create() {
        #    armor::create();
        push (@list,
            'static void create() {',
            '    armor::create();',
        );

        #   SetKeyName("a white t-shirt");
        #   SetId( ({ "t-shirt", "white t-shirt" }) );
        push (@list,
            '    SetKeyName("' . $modelObj->baseString . '");',
            '    SetId( ({ "' . $modelObj->noun . '", "' . $modelObj->baseString . '" }) );',
        );

        #   SetAdjectives( ({ "white" }) );
        foreach my $adj ($modelObj->adjList) {

            if ($adjString) {

                $adjString .= ', ';
            }

            $adjString = '"' . $adj . '"';
        }

        if (! $adjString) {

            push (@list,
                '    SetAdjectives();',
            );

        } else {

            push (@list,
                '    SetAdjectives( ({ ' . $adjString . '}) );',
            );
        }

        #   SetShort("a white t-shirt");
        if ($modelObj->baseString =~ m/^[AEIOUaeiou]/) {
            $shortString = 'an ' . $modelObj->baseString;
        } else {
            $shortString = 'a ' . $modelObj->baseString;
        }

        push (@list,
            '    SetShort("' . $shortString . '");',
        );

        #   SetLong("An ordinary white t-shirt.");
        if ($modelObj->descrip) {
            $longString = $modelObj->descrip;
        } else {
            $longString = $convertlpc::NULL_OBJ_DESCRIP;
        }

        push (@list,
            '    SetLong("' . $longString . '");',
        );

        #   SetMass(2);
        if ($modelObj->weight) {
            $weightString = $modelObj->weight;
        } else {
            $weightString = $convertlpc::DEFAULT_WEIGHT;
        }

        push (@list,
            '    SetMass(' . $weightString . ');',
        );

        #   SetBaseCost("silver", 1);
        if ($modelObj->buyValue) {
            $valueString = $modelObj->buyValue;
        } elsif ($modelObj->sellValue) {
            $valueString = $modelObj->sellValue;
        } else {
            $valueString = $convertlpc::DEFAULT_VALUE;
        }

        push (@list,
            '    SetBaseCost("' . $convertlpc::DEFAULT_CURRENCY . '", ' . $valueString . ');',
        );

        #   SetArmorType(A_SHIRT);
        #   }
        #
        #   void init(){
        #       ::init();
        #   }
        push (@list,
            '    SetArmorType(A_SHIRT);',
            '}',
            '',
            'void init(){',
            '    ::init();',
            '}',
        );

        # Operation complete
        return @list;
    }

    sub prepareSentient {

        # Called by $self->do
        #
        # Prepares a list of strings for a single world model sentient, which will be written as a
        #   single LPC file
        # (The code used is based on the Dead Souls object /domains/town/npc/beggar.c)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $convertHashRef - Reference to the hash of file paths created by the calling function,
        #                       in the form
        #                           $convertHash{model_number} = file_path;
        #   $modelObj        - The weapon model object to use
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list of strings, which the calling function can write as an LPC
        #       file

        my ($self, $session, $convertHashRef, $modelObj, $check) = @_;

        # Local variables
        my (
            $adjString, $shortString, $longString, $raceString,
            @emptyList, @list,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $convertHashRef || ! defined $modelObj
            || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->prepareSentient', @_);
            return @emptyList;
        }

        #    #include <lib.h>
        #
        #    inherit LIB_SENTIENT;
        #
        push (@list,
            '#include <lib.h>',
            ' ',
            'inherit LIB_SENTIENT;',
            ' ',
        );

        #    static void create() {
        #    sentient::create();
        push (@list,
            'static void create() {',
            '    sentient::create();',
        );

        #   SetKeyName("beggar");
        #   SetId( ({ "beggar" }) );
        push (@list,
            '    SetKeyName("' . $modelObj->baseString . '");',
            '    SetId( ({ "' . $modelObj->noun . '", "' . $modelObj->baseString . '" }) );',
        );

        #   SetAdjectives( ({ "dirty" }) );
        foreach my $adj ($modelObj->adjList) {

            if ($adjString) {

                $adjString .= ', ';
            }

            $adjString = '"' . $adj . '"';
        }

        if (! $adjString) {

            push (@list,
                '    SetAdjectives();',
            );

        } else {

            push (@list,
                '    SetAdjectives( ({ ' . $adjString . '}) );',
            );
        }

        #   SetShort("a dirty beggar");
        if ($modelObj->baseString =~ m/^[AEIOUaeiou]/) {
            $shortString = 'an ' . $modelObj->baseString;
        } else {
            $shortString = 'a ' . $modelObj->baseString;
        }

        push (@list,
            '    SetShort("' . $shortString . '");',
        );

        #   SetLong("This beggar has something strangely noble about his aspect.");
        if ($modelObj->descrip) {
            $longString = $modelObj->descrip;
        } else {
            $longString = $convertlpc::NULL_OBJ_DESCRIP;
        }

        push (@list,
            '    SetLong("' . $longString . '");',
        );

        #   SetClass("fighter");
        #   SetLevel(1);
        #   SetWimpy(0);
        #   SetInventory( ([ ]) );
        push (@list,
            '    SetClass("fighter");',
            '    SetLevel(' . $modelObj->level . ');',
            '    SetWimpy(0);',
            '    SetInventory( ([ ]) );',
        );

        #   SetRace("human");
        #   SetGender("male");
        if ($modelObj->race) {
            $raceString = $modelObj->race;
        } else {
            $raceString = $convertlpc::SENTIENT_DEFAULT_RACE;
        }

        push (@list,
            '    SetRace("' . $raceString . '");',
            '    SetGender("' . $convertlpc::DEFAULT_GENDER . '");',
        );

        #    SetPolyglot(1);
        #    SetLanguage("common", 100);
        #    SetDefaultLanguage("common");
        push (@list,
            '    SetPolyglot(1);',
            '    SetLanguage("common", 100);',
            '    SetDefaultLanguage("common");',
        );

        #   }
        #
        #   void init(){
        #       ::init();
        #   }
        push (@list,
            '}',
            '',
            'void init(){',
            '    ::init();',
            '}',
        );

        # Operation complete
        return @list;
    }

    sub prepareCreature {

        # Called by $self->do
        #
        # Prepares a list of strings for a single world model creature, which will be written as a
        #   single LPC file
        # (The code used is based on the Dead Souls object /domains/town/npc/bear.c)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $convertHashRef - Reference to the hash of file paths created by the calling function,
        #                       in the form
        #                           $convertHash{model_number} = file_path;
        #   $modelObj        - The weapon model object to use
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list of strings, which the calling function can write as an LPC
        #       file

        my ($self, $session, $convertHashRef, $modelObj, $check) = @_;

        # Local variables
        my (
            $adjString, $shortString, $longString, $raceString,
            @emptyList, @list,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $convertHashRef || ! defined $modelObj
            || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->prepareCreature', @_);
            return @emptyList;
        }

        #    #include <lib.h>
        #
        #    inherit LIB_SENTIENT;
        #
        push (@list,
            '#include <lib.h>',
            ' ',
            'inherit LIB_SENTIENT;',
            ' ',
        );

        #    static void create() {
        #    sentient::create();
        push (@list,
            'static void create() {',
            '    sentient::create();',
        );

        #   SetKeyName("bear");
        #   SetId( ({ "bear" }) );
        push (@list,
            '    SetKeyName("' . $modelObj->baseString . '");',
            '    SetId( ({ "' . $modelObj->noun . '", "' . $modelObj->baseString . '" }) );',
        );

        #   SetAdjectives( ({ "brown" }) );
        foreach my $adj ($modelObj->adjList) {

            if ($adjString) {

                $adjString .= ', ';
            }

            $adjString = '"' . $adj . '"';
        }

        if (! $adjString) {

            push (@list,
                '    SetAdjectives();',
            );

        } else {

            push (@list,
                '    SetAdjectives( ({ ' . $adjString . '}) );',
            );
        }

        #   SetShort("a brown bear");
        if ($modelObj->baseString =~ m/^[AEIOUaeiou]/) {
            $shortString = 'an ' . $modelObj->baseString;
        } else {
            $shortString = 'a ' . $modelObj->baseString;
        }

        push (@list,
            '    SetShort("' . $shortString . '");',
        );

        #   SetLong("A large brown bear. Not as huge as a grizzly.");
        if ($modelObj->descrip) {
            $longString = $modelObj->descrip;
        } else {
            $longString = $convertlpc::NULL_OBJ_DESCRIP;
        }

        push (@list,
            '    SetLong("' . $longString . '");',
        );

        #   SetClass("fighter");
        #   SetLevel(1);
        #   SetWimpy(0);
        #   SetInventory( ([ ]) );
        push (@list,
            '    SetClass("fighter");',
            '    SetLevel(' . $modelObj->level . ');',
            '    SetWimpy(0);',
            '    SetInventory( ([ ]) );',
        );

        #   SetRace("bear");
        #   SetGender("male");
        if ($modelObj->race) {
            $raceString = $modelObj->race;
        } else {
            $raceString = $convertlpc::CREATURE_DEFAULT_RACE;
        }

        push (@list,
            '    SetRace("' . $raceString . '");',
            '    SetGender("' . $convertlpc::DEFAULT_GENDER . '");',
        );

        #   }
        #
        #   void init(){
        #       ::init();
        #   }
        push (@list,
            '}',
            '',
            'void init(){',
            '    ::init();',
            '}',
        );

        # Operation complete
        return @list;
    }

    sub preparePortable {

        # Called by $self->do
        #
        # Prepares a list of strings for a single world model portable, which will be written as a
        #   single LPC file
        # (The code used is based on the Dead Souls object /domains/town/obj/maglite.c)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $convertHashRef - Reference to the hash of file paths created by the calling function,
        #                       in the form
        #                           $convertHash{model_number} = file_path;
        #   $modelObj        - The weapon model object to use
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list of strings, which the calling function can write as an LPC
        #       file

        my ($self, $session, $convertHashRef, $modelObj, $check) = @_;

        # Local variables
        my (
            $adjString, $shortString, $longString, $weightString, $valueString,
            @emptyList, @list,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $convertHashRef || ! defined $modelObj
            || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->preparePortable', @_);
            return @emptyList;
        }

        #    #include <lib.h>
        #
        #    inherit LIB_ITEM;
        #
        push (@list,
            '#include <lib.h>',
            ' ',
            'inherit LIB_ITEM;',
            ' ',
        );

        #    static void create() {
        #    item::create();
        push (@list,
            'static void create() {',
            '    item::create();',
        );

        #   SetKeyName("match");
        #   SetId( ({ "wooden match" }) );
        push (@list,
            '    SetKeyName("' . $modelObj->baseString . '");',
            '    SetId( ({ "' . $modelObj->noun . '", "' . $modelObj->baseString . '" }) );',
        );

        #   SetAdjectives( ({ "wooden" }) );
        foreach my $adj ($modelObj->adjList) {

            if ($adjString) {

                $adjString .= ', ';
            }

            $adjString = '"' . $adj . '"';
        }

        if (! $adjString) {

            push (@list,
                '    SetAdjectives();',
            );

        } else {

            push (@list,
                '    SetAdjectives( ({ ' . $adjString . '}) );',
            );
        }

        #   SetShort("a wooden match");
        if ($modelObj->baseString =~ m/^[AEIOUaeiou]/) {
            $shortString = 'an ' . $modelObj->baseString;
        } else {
            $shortString = 'a ' . $modelObj->baseString;
        }

        push (@list,
            '    SetShort("' . $shortString . '");',
        );

        #   SetLong("A wooden match that might light if you strike it.");
        if ($modelObj->descrip) {
            $longString = $modelObj->descrip;
        } else {
            $longString = $convertlpc::NULL_OBJ_DESCRIP;
        }

        push (@list,
            '    SetLong("' . $longString . '");',
        );

        #   SetMass(10);
        if ($modelObj->weight) {
            $weightString = $modelObj->weight;
        } else {
            $weightString = $convertlpc::DEFAULT_WEIGHT;
        }

        push (@list,
            '    SetMass(' . $weightString . ');',
        );

        #   SetDollarCost(10);
        if ($modelObj->buyValue) {
            $valueString = $modelObj->buyValue;
        } elsif ($modelObj->sellValue) {
            $valueString = $modelObj->sellValue;
        } else {
            $valueString = $convertlpc::DEFAULT_VALUE;
        }

        push (@list,
            '    SetDollarCost(' . $valueString . ');',
        );

        #   }
        #
        #   void init(){
        #       ::init();
        #   }
        push (@list,
            '}',
            '',
            'void init(){',
            '    ::init();',
            '}',
        );

        # Operation complete
        return @list;
    }

    sub prepareDecoration {

        # Called by $self->do
        #
        # Prepares a list of strings for a single world model decoration, which will be written as a
        #   single LPC file
        # (The code used is based on the Dead Souls object /domains/town/obj/clocktower.c)
        #
        # Expected arguments
        #   $session        - The calling function's GA::Session
        #   $convertHashRef - Reference to the hash of file paths created by the calling function,
        #                       in the form
        #                           $convertHash{model_number} = file_path;
        #   $modelObj        - The weapon model object to use
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list of strings, which the calling function can write as an LPC
        #       file

        my ($self, $session, $convertHashRef, $modelObj, $check) = @_;

        # Local variables
        my (
            $adjString, $shortString, $longString, $weightString, $valueString,
            @emptyList, @list,
        );

        # Check for improper arguments
        if (
            ! defined $session || ! defined $convertHashRef || ! defined $modelObj
            || defined $check
        ) {
            $axmud::CLIENT->writeImproper($self->_objClass . '->prepareDecoration', @_);
            return @emptyList;
        }

        #    #include <lib.h>
        #
        #    inherit LIB_ITEM;
        #
        push (@list,
            '#include <lib.h>',
            ' ',
            'inherit LIB_ITEM;',
            ' ',
        );

        #    static void create() {
        #    item::create();
        push (@list,
            'static void create() {',
            '    item::create();',
        );

        #   SetKeyName("clock tower");
        #   SetId( ({ "great clock tower rising majestically into the sky", "tower" }) );
        push (@list,
            '    SetKeyName("' . $modelObj->baseString . '");',
            '    SetId( ({ "' . $modelObj->noun . '", "' . $modelObj->baseString . '" }) );',
        );

        #   SetAdjectives( ({ "great", "large" }) );
        foreach my $adj ($modelObj->adjList) {

            if ($adjString) {

                $adjString .= ', ';
            }

            $adjString = '"' . $adj . '"';
        }

        if (! $adjString) {

            push (@list,
                '    SetAdjectives();',
            );

        } else {

            push (@list,
                '    SetAdjectives( ({ ' . $adjString . '}) );',
            );
        }

        #   SetShort("a great clock tower rising majestically into the sky");
        if ($modelObj->baseString =~ m/^[AEIOUaeiou]/) {
            $shortString = 'an ' . $modelObj->baseString;
        } else {
            $shortString = 'a ' . $modelObj->baseString;
        }

        push (@list,
            '    SetShort("' . $shortString . '");',
        );

        #   SetLong("his is a large clock tower, rising magestically into the sky.");
        if ($modelObj->descrip) {
            $longString = $modelObj->descrip;
        } else {
            $longString = $convertlpc::NULL_OBJ_DESCRIP;
        }

        push (@list,
            '    SetLong("' . $longString . '");',
        );

        #   SetMass(1000000);
        # (ignore the model object's mass for something that no character could pick up)
        push (@list,
            '    SetMass(1000000);',
        );

        #   SetBaseCost("silver", 100);
        if ($modelObj->buyValue) {
            $valueString = $modelObj->buyValue;
        } elsif ($modelObj->sellValue) {
            $valueString = $modelObj->sellValue;
        } else {
            $valueString = $convertlpc::DEFAULT_VALUE;
        }

        push (@list,
            '    SetBaseCost("' . $convertlpc::DEFAULT_CURRENCY . '", ' . $valueString . ');',
        );

        #   }
        #
        #   void init(){
        #       ::init();
        #   }
        push (@list,
            '}',
            '',
            'void init(){',
            '    ::init();',
            '}',
        );

        # Operation complete
        return @list;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

# Package must return a true value
1
