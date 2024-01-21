# Copyright (C) 2011-2024 A S Lewis
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
# Language::Axbasic, based on Language::Basic by Amir Karger

{ package Language::Axbasic;

    use strict;
    use warnings;
#   use diagnostics;

    use Fcntl qw(SEEK_SET SEEK_END);
    use File::Basename;
    use Glib qw(TRUE FALSE);
    use Math::Trig;
    use POSIX qw(ceil);
    use Scalar::Util qw(looks_like_number);

    require Exporter;
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
    @ISA = qw(Exporter Games::Axmud);
    @EXPORT = qw();

    # Sub-packages
    {
        package Language::Axbasic::Script;
        package Language::Axbasic::RawScript;
        package Language::Axbasic::Subroutine;
        package Language::Axbasic::Line;

        package Language::Axbasic::TokenGroup;
        package Language::Axbasic::Token;

        package Language::Axbasic::Statement;
        package Language::Axbasic::Expression;
        package Language::Axbasic::Variable;
        package Language::Axbasic::Function;

        package Language::Axbasic::String;
        package Language::Axbasic::Boolean;
        package Language::Axbasic::Numeric;
    }

    ##################
    # Accessors - get

    # There are five standard IVs for every Axmud (and Axbasic) Perl object
    sub _objName
        { $_[0]->{_objName} }
    sub _objClass
        { $_[0]->{_objClass} }
    sub _parentFile
        { $_[0]->{_parentFile} }
    sub _parentWorld
        { $_[0]->{_parentWorld} }
    sub _privFlag
        { $_[0]->{_privFlag} }
}

{ package Language::Axbasic::Error;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Error::ISA = qw(
        Language::Axbasic
    );

    ##################
    # Constructors

    sub new {

        # Creates a new instance of the Axbasic error object which stores data produced by an
        #   Axbasic error. Called whenever any part of the Axbasic code calls ->setError or
        #   ->setDebug
        # The details of the error are stored in this object, and this object's blessed reference
        #   can then be added to LA::Script->errorList
        #
        # Expected arguments
        #   $scriptObj  - Blessed reference to the parent LA::Script
        #   $category   - 'error' (calls from ->setError) or 'debug' (calls from ->setDebug)
        #   $errorCode  - The error message to display, e.g. 'syntax_error'
        #   $func       - A string describing the function that generated the error (e.g.
        #                   'Language::Axbasic::Statement->parse')
        #
        # Optional arguments
        #   $line       - Which line number in the script produced the error, if any (matches
        #                   LA::Script->currentLine, 'undef' if no specific line)
        #   %errorHash  - A hash of arguments used to substitute words in $errorCode (see comments
        #                   below; can be an empty hash)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $scriptObj, $category, $errorCode, $func, $line, %errorHash) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $scriptObj || ! defined $category || ! defined $errorCode
            || ! defined $func
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

            # IVs
            # ---

            # What kind of error this is ('error' or 'debug')
            category                    => $category,

            # The error message itself
            # $errorCode is a string. For standard error messages, words are separated by underline
            #   characters, e.g. 'syntax_error' or 'illegal_word_WORD'. For non-standard error
            #   messages and debug messages, just use spaces
            # For standard error messages, any word in $errorCode in CAPITALS, like the
            #   aforementioned WORD, is usually intended to be substituted using %errorHash. (If
            #   the word is not in capitals, substitution will still work)
            errorCode                   => $errorCode,
            # A string describing the function that generated the error
            func                        => $func,
            # Which line number in the script produced the error ('undef' if no specific line)
            line                        => $line,

            # A hash of arguments used to substitute words in $errorCode (empty if there are no
            #   words to substitute)
            # For example, in the hypothetical error 'WORD_is_an_illegal_word', the key-value pair
            #   added to this hash would be
            #       key:    WORD (all capitals signifies that this word should be substituted)
            #       value:  the offending word itself, 'prnit' perhaps
            errorHash                   => \%errorHash,
        };

        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub category
        { $_[0]->{category} }

    sub errorCode
        { $_[0]->{errorCode} }
    sub func
        { $_[0]->{func} }
    sub line
        { $_[0]->{line} }

    sub errorHash
        { my $self = shift; return %{$self->{errorHash}}; }
}

{ package Language::Axbasic::RawScript;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::RawScript::ISA = qw(
        Language::Axbasic
    );

    ##################
    # Constructors

    sub new {

        # The class that handles a whole Axbasic script in its original, human-edited form
        #   (including empty lines, comments, leading whitespace, and primitive line numbers)
        # The contents of the script can be edited freely. When LA::Script->new is called, it calls
        #   LA::RawScript->upload to make a copy of the script without empty lines, comments, or
        #   primitive line numbers
        # After the call to LA::RawScript->upload, the copy of the script stored in LA::Script is
        #   fixed (and cannot be edited); meanwhile the copy stored in LA::RawScript can continue to
        #   be edited freely
        #
        # Call ->new to create the Perl object, ->loadFile to read a script into memory from a
        #   file, ->saveFile to save a script in memory to file
        # Don't call ->upload directly; let LA::Script do it
        #
        # Expected arguments
        #   $session    - The parent GA::Session
        #   $name       - A named for the script
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $session || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Perl object components
            # ----------------------

            # The parent GA::Session
            session                     => $session,

            # Raw script IVs
            # --------------

            # The script name
            name                        => $name,
            # The full file path from which the script is loaded, every time $self->loadFile is
            #   called
            filePath                    => undef,

            # The lines of the script. A hash in the form
            #   $lineHash{line_number} = string_of_text
            # ...where 'line_number' is in the range 1 to $self->lineCount
            #
            # (NB 'line_number' refers to the physical line number in the script - not the primitive
            #   line number, if it is being used)
            lineHash                    => {},
            # How many lines in total (0 when the script is empty)
            lineCount                   => 0,

            # Flag set to TRUE whenever the script is modified. Set back to FALSE after any load or
            #   save operation
            modifyFlag                  => FALSE,
        };

        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub setError {

        # Can be called by any of the methods in this object when they notice an error caused by the
        #   Perl Code
        # (Replaces LA::Script->setError, which can't be called because the corresponding
        #   LA::Script object probably doesn't exist yet)
        #
        # Expected arguments
        #   $errorMsg   - The error message to display
        #   $func       - A string describing the function that generated the error (e.g.
        #                   'Language::Axbasic::Statement->parse')
        #
        # Return values
        #   'undef'

        my ($self, $errorMsg, $func, $check) = @_;

        # Check for improper arguments
        if (! defined $errorMsg || ! defined $func || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setError', @_);
        }

        $self->session->writeText('AXBASIC: ERROR: ' . $errorMsg . ' (' . $func . ')');

        # This return value should trickle all the way down to LA::Script->parse or
        #   LA::Script->implement
        return undef;
    }

    sub loadFile {

        # Loads a file into memory. The file should contain an Axbasic script
        # If the load succeeds, the contents of $self->lineHash and $self->lineCount are set from
        #   the contents of the file, and ->modifyFlag is set to FALSE.
        # If the load fails, these IVs are not changed
        #
        # Expected arguments
        #   $filePath   - Full path to the file to be loaded (must end with .bas)
        #
        # Return values
        #   'undef' on improper arguments, if file loading/saving has been disabled, if the file
        #       doesn't exist, or if it can't be loaded, or if an operation to sort the lines into
        #       the right order fails
        #   1 otherwise

        my ($self, $filePath, $check) = @_;

        # Local variables
        my (
            $semaphoreHandle, $fileHandle, $lineCount, $result,
            %lineHash,
        );

        # Check for improper arguments
        if (! defined $filePath || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->loadFile', @_);
        }

        # Check that file loading is enabled
        if (! $axmud::CLIENT->loadDataFlag) {

            return $self->setError(
                'Can\'t load Axbasic script because file access is disabled',
                $self->_objClass . '->loadFile',
            );
        }

        # Check that the specified file exists
        if (! (-e $filePath)) {

            return $self->setError(
                'Can\'t load Axbasic script because the file \'' . $filePath . '\' doesn\'t exist',
                $self->_objClass . '->loadFile',
            );
        }

        # Check that the specified file appears to be a .bas file
        if (! $filePath =~ m/\.bas$/) {

            return $self->setError(
                'Can\'t load Axbasic script because file doesn\'t appear to be a .bas file',
                $self->_objClass . '->loadFile',
            );
        }

        # Get a shared lock on the twinned semaphore file using GA::Obj::File's file lock functions
        $semaphoreHandle = $axmud::CLIENT->configFileObj->getFileLock(
            $axmud::DATA_DIR . '/data/temp/axbasic.sem',    # Semaphore file
            FALSE,                                          # Shared lock for reading
            $filePath,
        );

        # Don't try to load the file if no lock could be taken out on the semaphore file
        if (! $semaphoreHandle) {

            return $self->setError(
                'General error loading the Axbasic script',
                $self->_objClass . '->loadFile',
            );
        }

        # Open the file for reading
        if (! open ($fileHandle, "<$filePath")) {

            return $self->setError(
                'General error loading the Axbasic script',
                $self->_objClass . '->loadFile',
            );
        }

        # Read the file
        $lineCount = 0;
        while (defined (my $line = <$fileHandle>)) {

            chomp $line;
            $lineCount++;
            $lineHash{$lineCount} = $line;
        }

        # Close the file
        $result = close $fileHandle;
        # Release the lock on the semaphore file
        $axmud::CLIENT->configFileObj->releaseFileLock($semaphoreHandle);

        if ($result) {

            # Loading succeeded. Transfer the file's contents to this object's IVs
            $self->ivPoke('filePath', $filePath);
            $self->ivPoke('lineHash', %lineHash);
            $self->ivPoke('lineCount', $lineCount);
            $self->ivPoke('modifyFlag', FALSE);

            return 1;

        } else {

            # Loading failed
            return $self->setError(
                'General error loading the Axbasic script',
                $self->_objClass . '->loadFile',
            );
        }
    }

    sub saveFile {

        # Saves a file from memory. The file should contain an Axbasic script.
        # If the save succeeds, ->modifyFlag is set to FALSE. If the save fails, the flag is not
        #   changed
        #
        # Expected arguments
        #   $filePath   - Full path to the file to be saved (must end with .bas)
        #
        # Return values
        #   'undef' on improper arguments, if file loading/saving has been disabled, if the script
        #       in memory is empty or if the file can't be saved
        #   1 otherwise

        my ($self, $filePath, $check) = @_;

        # Local variables
        my (
            $semaphoreHandle, $fileHandle, $result,
            @list,
        );

        # Check for improper arguments
        if (! defined $filePath || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->saveFile', @_);
        }

        # Check that file saving is enabled
        if (! $axmud::CLIENT->saveDataFlag) {

            return $self->setError(
                'Can\'t save Axbasic script because file access is disabled',
                $self->_objClass . '->saveFile',
            );
        }

        # Check that the specified file appears to be a .bas file
        if (! $filePath =~ m/\.bas$/) {

            return $self->setError(
                'Can\'t save Axbasic script because file doesn\'t appear to be a .bas file',
                $self->_objClass . '->saveFile',
            );
        }

        # Don't save anything if the script is empty
        if (! $self->lineCount) {

            return $self->setError(
                'Can\'t save Axbasic script because the script in memory is empty',
                $self->_objClass . '->saveFile',
            );
        }

        # Get an exclusive lock on the twinned semaphore file using GA::Obj::FileObj's file lock
        $semaphoreHandle = $axmud::CLIENT->configFileObj->getFileLock(
            $axmud::DATA_DIR . '/data/temp/axbasic.sem',    # Semaphore file
            TRUE,                                           # Exclusive lock for writing
            $filePath,
        );

        # Don't try to save the file if no lock could be taken out on the semaphore file
        if (! defined $semaphoreHandle) {

            return $self->setError(
                'General error saving the Axbasic script',
                $self->_objClass . '->saveFile',
            );
        }

        # Open the file for writing, overwriting previous contents
        if (! open ($fileHandle, ">$filePath")) {

            return $self->setError(
                'General error saving the Axbasic script',
                $self->_objClass . '->saveFile',
            );
        }

        # Retrieve the contents of the script as a list of strings, in order, from 1 to
        #   $self->lineCount
        if ($self->lineCount) {

            for (my $count = 1; $count <= $self->lineCount; $count++) {

                if ($self->ivExists('lineHash', $count)) {

                    push (@list, $self->ivShow('lineHash', $count));
                }
            }
        }

        # Add newline characters to every entry in @list before writing the whole list to the file
        foreach my $item (@list) {

            $item .= "\n";
        }

        print $fileHandle @list;

        # Writing complete
        $result = close $fileHandle;
        # Release the lock on the semaphore file
        $axmud::CLIENT->configFileObj->releaseFileLock($semaphoreHandle);

        if ($result) {

            # Saving succeeded
            $self->ivPoke('modifyFlag', FALSE);

            return 1;

        } else {

            # Saving failed
            return $self->setError(
                'General error saving the Axbasic script',
                $self->_objClass . '->saveFile',
            );
        }
    }

    sub upload {

        # Called by LA::Script->new
        # Processes the script in memory to remove all the extraneous stuff, including:
        #   - empty lines
        #   - leading whitespace at the beginning of lines
        #   - lines starting with comments (REM xxx)
        # Also checks whether the Axbasic script seems to be using primitive line numbers. If so,
        #   the line numbers are removed from the beginning of each line and stored instead in a
        #   LA::Line object
        # (However, statements like 'goto 550' don't have the line number removed - it's up to
        #   LA::Statement::Goto to deal with it)
        #
        # From the resulting stripped-down script, for every line of Axbasic, a new LA::Line
        #   object is created, and its blessed reference added to LA::Script->lineHash
        # In this manner, the raw script stored in a LA::RawScript object is uploaded as a
        #   stripped-down copy of the script stored in a LA::Script object
        #
        # Expected arguments
        #   $scriptObj  - Blessed reference to the LA::Script object, to which the script must
        #                   be uploaded
        #
        # Return values
        #   'undef' on improper arguments, or if there is no script in memory, if there is an error
        #       creating a LA::Line object, or if the script is empty (once all the extraneous stuff
        #       has been removed)
        #   1 on success

        my ($self, $scriptObj, $check) = @_;

        # Local variables
        my (
            $count, $procLineCount, $firstLine, $executionMode,
            @initialList,
            %uploadHash, %primLineHash,
        );

        # Check for improper arguments
        if (! defined $scriptObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->upload', @_);
        }

        # Check that there's a script in memory
        if (! $self->lineCount) {

            return $self->setError(
                'Can\'t process Axbasic script (the file is probably empty)',
                $self->_objClass . '->upload',
            );
        }

        # Find the first line which contains a character. Test the first character on that line;
        #   if it's a digit, assume that the script uses primitive line numbering
        $count = 0;
        do {

            $count++;
            $firstLine = $self->ivShow('lineHash', $count);

            if ($firstLine =~ m/\w/) {

                # This contains at least one character, so use it as the first line
                $count = $self->lineCount;      # Escape the loop
            }

        } until ($count >= $self->lineCount);

        if ($firstLine =~ m/^\s*(\d+)\s+/) {

            # Primitive line numbering is now in effect
            $executionMode = 'line_num';

            # Make sure all the lines in the script are in the right order
            $self->sortLines();

        } else {

            # No primitive line numbering
            $executionMode = 'no_line_num';
        }

        # For each line in the script...
        $procLineCount = 0;
        OUTER: for (my $origLineCount = 1; $origLineCount <= $self->lineCount; $origLineCount++) {

            my ($lineText, $lineObj);

            # Check that the line exists
            if (! $self->ivExists('lineHash', $origLineCount)) {

                # There is no reason why it should not exist - it's an error
                return $self->setError(
                    'Can\'t process Axbasic script, missing line #' . $origLineCount,
                    $self->_objClass . '->upload',
                );
            }

            # Check that the line actually contains some text
            $lineText = $self->ivShow('lineHash', $origLineCount);
            if (! $lineText || $lineText =~ m/^\s+$/) {

                # This is an empty line. Move on to the next one
                next OUTER;
            }

            # No primitive line numbering...
            if ($executionMode eq 'no_line_num') {

                # Remove any whitespace from the beginning and end of the line
                $lineText = $axmud::CLIENT->trimWhitespace($lineText);

                # If the whole line is a comment, ignore it
                if ($lineText =~ /^rem /i) {

                    next OUTER;
                }

                # Create a LA::Line with what's left of the line (after whitespace was removed)
                $procLineCount++;
                $lineObj = Language::Axbasic::Line->new(
                    $scriptObj,
                    $lineText,
                    $origLineCount,
                    $procLineCount,
                );

                if (! defined $lineObj) {

                    return $self->setError(
                        'Can\'t upload Axbasic script, error creating line #' . $origLineCount,
                        $self->_objClass . 'upload',
                    );

                } else {

                    $uploadHash{$procLineCount} = $lineObj;
                }

            # Primitive line numbering...
            } elsif ($executionMode eq 'line_num') {

                my ($result, $primLineNum, $lineBody);

                # Check that the line starts with a number, and has a body (text after the line
                #    number)
                $result = $lineText =~ m/^\s*(\d+)\s+(.*)/;
                $primLineNum = $1;
                $lineBody = $2;

                if (! $result) {

                    return $self->setError(
                        'Can\'t process Axbasic script, invalid primitive line number format at'
                         . ' line #' . $origLineCount,
                        $self->_objClass . '->upload',
                    );
                }

                # Remove any whitespace from the end of the line body
                $lineBody =~ s/\s+$//;

                # Create a LA::Line with the line body
                $procLineCount++;
                $lineObj = Language::Axbasic::Line->new(
                    $scriptObj,
                    $lineBody,
                    $origLineCount,
                    $procLineCount,
                    $primLineNum,
                );

                if (! defined $lineObj) {

                    return $self->setError(
                        'Can\'t process Axbasic script, error creating line #'
                        . $origLineCount,
                        $self->_objClass . '->upload',
                    );

                } else {

                    $uploadHash{$procLineCount} = $lineObj;
                    # Update the hash which converts the primitive line number into the processed
                    #   line number
                    $primLineHash{$primLineNum} = $procLineCount;
                }
            }
        }

        if (! $procLineCount) {

            # Nothing to upload. Use the same error message for an empty file, as for a file which
            #   just contains a load of whitespace
            return $self->setError(
                'Can\'t process Axbasic script (the file is probably empty)',
                $self->_objClass . '->upload',
            );

        } else {

            # Upload the processed script to the LA::Script object
            $scriptObj->download(
                ($procLineCount + 1),       # Stored as LA::Script->lineCount
                $executionMode,             # ->executionMode
                \%uploadHash,               # ->lineHash
                \%primLineHash,             # ->primLineHash
            );

            return 1;
        }
    }

    sub sortLines {

        # Called by $self->upload
        # Sorts the script's lines into the right order
        #   e.g. '20 goto 10 : 10 print "hello"' becomes '10 print "hello" : 20 goto 10'
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
            $total,
            @list, @sortedList,
            %lineHash, %tempHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->sortLines', @_);
        }

        # First import the values of the $self->lineHash into a list, so we can re-fill it. The
        #   current hash keys are now irrelevant
        @list = $self->ivValues('lineHash');

        # Put the lines into a new hash, one by one
        # The keys of the hash are the primitive line number. The values are the whole line,
        #   including the primitive line number
        foreach my $line (@list) {

            my $primLineNum;

            if ($line =~ m/^\s*(\d+)(\s+)/) {

                $primLineNum = $1;

                # Check that a line with the same number doesn't already exist (duplicates are not
                #   allowed)
                if (exists $tempHash{$primLineNum}) {

                    return $self->setError(
                        'Duplicate line #' . $primLineNum,
                        $self->_objClass . '->sortLines',
                    );

                # Otherwise use this line
                } else {

                    $tempHash{$primLineNum} = $line;
                }

            } else {

                # Now that we're using primitive line numbering, lines without numbers are not
                #   allowed (but empty lines are allowed, and just ignored)
                if ($line =~ m/\w/) {

                    return $self->setError(
                        'Un-numbered line in raw script (expecting all lines to be numbered)',
                        $self->_objClass . '->sortLines',
                    );
                }
            }
        }

        # Compile a sorted list of the primitive line numbers
        @sortedList = sort {$a <=> $b} (keys %tempHash);

        # Re-stock the original hash
        $total = scalar @sortedList;
        for (my $count = 1; $count <= $total; $count++) {

            $lineHash{$count} = $tempHash{shift @sortedList};
        }

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub session
        { $_[0]->{session} }

    sub name
        { $_[0]->{name} }
    sub filePath
        { $_[0]->{filePath} }

    sub lineHash
        { my $self = shift; return %{$self->{lineHash}}; }
    sub lineCount
        { $_[0]->{lineCount} }

    sub modifyFlag
        { $_[0]->{modifyFlag} }
}

{ package Language::Axbasic::Script;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Script::ISA = qw(
        Language::Axbasic
    );

    ##################
    # Constructors

    sub new {

        # The class that handles a whole script in a processed form (with all the empty lines,
        #   comments, etc removed).
        # Call ->new to create a LA::Script object, which automatically downloads the code from
        #   the specified LA::RawScript object
        # (LA::RawScript contains a script includes whitespace, empty lines, comments and possibly
        #   line numbers; LA::Script contains a script with all that stuff removed)
        #
        # Once created, the script stored in this object can be accessed in two modes:
        #   - Call ->parse to parse the script, looking for errors, but don't actually execute it
        #   - Call ->implement to parse the script, line-by-line, and then execute it
        # If the Axbasic script pauses (usually when the script is being executed as an Axmud task),
        #   call ->parse or ->implement again to resume execution
        #
        # Expected arguments
        #   $session        - The parent GA::Session
        #
        # Optional arguments
        #   $rawScriptObj   - Blessed reference of the LA::RawScript from which to download the
        #                       Axbasic script. If not specified, no script is downloaded (this
        #                       is useful for accessing default values stored in this object's IVs)
        #
        # Return values
        #   'undef' on improper arguments, or if the specified raw script can't be uploaded or if
        #       there's an error setting up intrinsic function objects
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $rawScriptObj, $check) = @_;

        # Local variables
        my (
            @keywordList, @logicalOpList,
            %keywordHash,
        );

        # Check for improper arguments
        if (! defined $class || ! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Define the list of Axbasic keywords - used to set more than one IV
        @keywordList = (
            'access', 'addalias', 'addcongauge', 'addconstatus', 'addgauge', 'addhook', 'addmacro',
            'addstatus', 'addtimer', 'addtrig', 'angle', 'array', 'beep', 'begin', 'break',
            'bypass', 'call', 'case', 'client', 'cls', 'close', 'closewin', 'create', 'data',
            'debug', 'def', 'degrees', 'delalias', 'delgauge', 'delhook', 'deliface', 'delmacro',
            'delstatus', 'deltimer', 'deltrig', 'dim', 'dimensions', 'do', 'each', 'else',
            'elseif', 'emptywin', 'end', 'erase', 'error', 'exit', 'flashwin', 'for', 'global',
            'gosub', 'goto', 'help', 'if', 'in', 'input', 'let', 'local', 'login', 'loop', 'lower',
            'multi', 'move', 'name', 'needtask', 'new', 'newold', 'next', 'nextiface', 'nolet',
            'numeric', 'old', 'on', 'open', 'openentry', 'openwin', 'option', 'org', 'organization',
            'outin', 'output', 'paintwin', 'pause', 'peek', 'peekequals', 'peekexists', 'peekfind',
            'peekfirst', 'peekget', 'peekindex', 'peekkeys', 'peeklast', 'peekmatch', 'peeknumber',
            'peekpairs', 'peekshow', 'peekvalues', 'perl', 'persist', 'play',  'poke', 'pokeadd',
            'pokedec', 'pokedechash', 'pokedelete', 'pokedivide', 'pokeempty', 'pokefalse',
            'pokeinc', 'pokeinchash', 'pokeint', 'pokeminus', 'pokemultiply', 'pokeplus', 'pokepop',
            'pokepush', 'pokereplace', 'pokeset', 'pokeshift', 'poketrue', 'pokeundef',
            'pokeunshift', 'pop', 'print', 'profile', 'pseudo', 'push', 'radians', 'randomize',
            'read', 'redim', 'redirect', 'relay', 'rem', 'require', 'reset', 'restore', 'return',
            'revpath', 'select', 'send', 'setalias', 'setgauge', 'sethook', 'setmacro', 'setstatus',
            'settimer', 'settrig', 'shift', 'silent', 'size', 'skipiface', 'sleep', 'sort',
            'sortcase', 'sortcaser', 'sortr', 'speak', 'speed', 'step', 'stop', 'string', 'sub',
            'tab', 'text', 'titlewin', 'then', 'to', 'typo', 'unflashwin', 'unshift', 'until',
            'upper', 'waitactive', 'waitalias', 'waitalive', 'waitarrive', 'waitdead', 'waitep',
            'waitgp', 'waithook', 'waithp', 'waitmacro', 'waitmp', 'waitnextxp', 'waitnotactive',
            'waitpassout', 'waitscript', 'waitsleep', 'waitsp', 'waittask', 'waittimer',
            'waittotalxp', 'waittrig', 'waitxp', 'warning', 'while', 'winaddcongauge',
            'winaddconstatus', 'winaddgauge', 'winaddstatus', 'windelgauge', 'windelstatus',
            'winsetgauge', 'winsetstatus', 'write', 'writewin',
        );

        foreach my $keyword (@keywordList) {

            $keywordHash{$keyword} = undef;
        }

        # Define the list of logical operators - used to set more than one IV
        @logicalOpList = ('and', 'or', 'not');

        # Setup
        my $self = {
            _objName                    => $class,      # Name Axbasic objects after their class
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Perl object components
            # ----------------------

            # The parent GA::Session
            session                     => $session,

            # Script IVs
            # ----------

            # The script name (matches the ->name of the LA::RawScript object from which the Axbasic
            #   script has been downloaded; set to 'undef' until then)
            name                        => undef,
            # The full file path from which the script is loaded, every time LA::RawScript->loadFile
            #   is called (set by this function, if a script is downloaded, but remains set to
            #   'undef' otherwise)
            filePath                    => undef,

            # All the lines in the script, a hash in the form
            #   $lineHash{line_number} = blessed_reference_to_LA::Line object
            # The first line number is $lineHash{1}
            lineHash                    => {},
            # How many lines in total (0 when the script is empty)
            lineCount                   => 0,
            # The current line number (matches a key in $self->lineHash)
            currentLine                 => undef,
            # The next line to execute (the line's ->procLineNum, not its blessed reference)
            nextLine                    => undef,
            # Blessed reference of the next statement to execute
            nextStatement               => undef,

            # A hash to convert primitive line numbers into ->procLineNum values
            #   e.g.    10 PRINT "hello"
            #           20 GOTO 10
            #   key = 10, value = 0 / key = 20, value = 1
            primLineHash                => {},

            # Execution mode:
            #   'not_set' - not set yet
            #   'no_line_num' - modern-style BASIC scripts without line numbers, GOTO, etc
            #   'line_num' primitive BASIC scripts with line numbers, GOTO, etc
            # When LA::RawScript->upload is called, it sets this IV. If the first character in
            #   the raw script is a number, it assumes that it's a primitive script with line
            #   numbers, and sets this IV to 'line_num'. Otherwise, sets it to 'no_line_num'
            executionMode               => 'not_set',
            # Normally, only the first error message generated is displayed in the 'main' window by
            #   $self->terminateExecution. In that case, this flag is set to FALSE.
            # If the flag is set to TRUE, all error messages are displayed (this can make for a
            #   confusing experience for the user, which is why it's turned off by default)
            allErrorsFlag               => FALSE,
            # Flag set to TRUE at the start of a call to $self->implement, and set back to FALSE
            #   when that function ends.
            # When the flag is true, any recursive calls to $self->implement are ignored; this
            #   prevents any part of the Axmud code calling ->implement, which in turn calls some
            #   part of the Axmud code, which in turns calls ->implement again
            implementFlag               => FALSE,

            # A list of all Axbasic keywords
            keywordList                 => \@keywordList,
            # A hash of keywords (for lookup by the Axbasic help functions), in the form
            #   $keywordHash{keyword} = undef
            keywordHash                 => \%keywordHash,
            # A list of Axbasic keywords only available in $self->executionMode 'no_line_num'
            #   (modern-style BASIC scripts)
            modernKeywordList           => [
                'call', 'case', 'do', 'exit', 'global', 'local', 'loop', 'numeric', 'select',
                'string', 'sub', 'until', 'while',
            ],
            # A list of Axbasic keywords only available in $self->executionMode 'line_num'
            #   (primitive BASIC scripts)
            primKeywordList             => [
                'goto', 'gosub', 'on',
            ],
            # A list of keywords used to set/fetch Axmud's internal variables
            peekPokeList                => [
                'peek', 'peekequals', 'peekexists', 'peekfind', 'peekfirst', 'peekget', 'peekindex',
                'peekkeys', 'peeklast', 'peekmatch', 'peeknumber', 'peekpairs', 'peekshow',
                'peekvalues', 'poke', 'pokeadd', 'pokedec', 'pokedechash', 'pokedelete',
                'pokedivide', 'pokeempty', 'pokefalse', 'pokeinc', 'pokeinchash', 'pokeint',
                'pokeminus', 'pokemultiply', 'pokeplus', 'pokepop', 'pokepush', 'pokereplace',
                'pokeset', 'pokeshift', 'poketrue', 'pokeundef', 'pokeunshift',
            ],
            # A hash of keywords that can't begin a statement. The keys in the hash are the keywords
            #   themselves; the corresponding values are keywords which can begin a statement. When
            #   the user types a command like ';axbasic help angle', they are presented help for the
            #   value ('option') corresponding to the key ('angle')
            weakKeywordHash             => {
                'access'                => 'open',
                'array'                 => 'peek',      # Also used in POKE, PEEK..., POKE...
                'angle'                 => 'option',
                'begin'                 => 'reset',
                'create'                => 'open',
                'degrees'               => 'option',
                'dimensions'            => 'let',
                'each'                  => 'for',
                'in'                    => 'for',
                'lower'                 => 'let',
                'name'                  => 'open',
                'needtask'              => 'option',
                'new'                   => 'open',
                'newold'                => 'open',
                'nolet'                 => 'option',
                'numeric'               => 'sub',
                'old'                   => 'open',
                'org'                   => 'open',
                'organization'          => 'open',
                'outin'                 => 'open',
                'output'                => 'open',
                'persist'               => 'option',
                'pseudo'                => 'option',
                'radians'               => 'option',
                'redirect'              => 'option',
                'require'               => 'option',
                'silent'                => 'option',
                'size'                  => 'let',
                'step'                  => 'for',
                'string'                => 'sub',
                'tab'                   => 'print',
                'text'                  => 'open',
                'then'                  => 'for',
                'to'                    => 'for',
                'typo'                  => 'option',
                'upper'                 => 'let',
            },
            # A hash of keywords that are either synonyms of other keywords (such as PAUSE and
            #   SLEEP), or whose code is so similar that their LA::Statement objects should be
            #   combined (such as ADDGAUGE and ADDCONGAUGE)
            equivKeywordHash            => {
                'addcongauge'           => 'addgauge',
                'addconstatus'          => 'addstatus',
                'elseif'                => 'else',
                'sleep'                 => 'pause',
                'winaddcongauge'        => 'addgauge',
                'winaddconstatus'       => 'addstatus',
                'winaddgauge'           => 'addgauge',
                'winaddstatus'          => 'addstatus',
                'windelgauge'           => 'delgauge',
                'windelstatus'          => 'delstatus',
                'winsetgauge'           => 'setgauge',
                'winsetstatus'          => 'setstatus',
            },
            # A list of statements that interact directly with Axmud
            clientKeywordList           => [
                'addalias', 'addcongauge', 'addconstatus', 'addgauge', 'addstatus', 'addhook',
                'addmacro', 'addtimer', 'addtrig', 'array', 'beep', 'break', 'bypass', 'client',
                'closewin', 'debug', 'delalias', 'delgauge', 'deliface', 'delhook', 'delmacro',
                'delstatus', 'deltimer', 'deltrig', 'emptywin', 'error', 'flashwin', 'login',
                'move', 'multi', 'nextiface', 'openentry', 'openwin', 'paintwin', 'pause', 'peek',
                'peekequals', 'peekexists', 'peekfind', 'peekfirst', 'peekget', 'peekindex',
                'peekkeys', 'peeklast', 'peekmatch', 'peeknumber', 'peekpairs', 'peekshow',
                'peekvalues', 'perl', 'play', 'poke', 'pokeadd', 'pokedec', 'pokedechash',
                'pokedelete', 'pokedivide', 'pokeempty', 'pokefalse', 'pokeinc', 'pokeinchash',
                'pokeint', 'pokeminus', 'pokemultiply', 'pokeplus', 'pokepop', 'pokepush',
                'pokereplace', 'pokeset', 'pokeshift', 'poketrue', 'pokeundef', 'pokeunshift',
                'profile', 'relay', 'revpath', 'send',  'setalias', 'setgauge', 'sethook',
                'setmacro', 'setstatus', 'settimer', 'settrig', 'skipiface', 'sleep', 'speak',
                'speed', 'titlewin', 'unflashwin', 'waitactive', 'waitalias', 'waitalive',
                'waitarrive', 'waitdead', 'waitep', 'waitgp', 'waithook', 'waithp', 'waitmacro',
                'waitmp', 'waitnextxp', 'waitpassout', 'waitscript', 'waitsleep', 'waitsp',
                'waittask', 'waittimer', 'waittotalxp', 'waittrig', 'waitxp', 'warning',
                'winaddcongauge', 'winaddconstatus', 'winaddgauge', 'winaddstatus', 'windelgauge',
                'windelstatus', 'winsetgauge', 'winsetstatus', 'write', 'writewin',
            ],
            # A list of keywords that are ignored when the Axbasic script isn't being run from
            #   within a task
            taskKeywordList             => [
                'addcongauge', 'addgauge', 'addconstatus', 'addstatus', 'break', 'closewin',
                'delgauge', 'emptywin', 'flashwin', 'openentry', 'openwin', 'paintwin', 'pause',
                'setalias', 'setgauge', 'sethook', 'setmacro', 'settimer', 'settrig', 'sleep',
                'titlewin', 'unflashwin', 'waitactive', 'waitalias', 'waitalive', 'waitarrive',
                'waitdead', 'waitep', 'waitgp', 'waithook', 'waithp', 'waitmacro',  'waitmp',
                'waitnextxp', 'waitnotactive', 'waitpassout', 'waitscript', 'waitsleep', 'waitsp',
                'waittask', 'waittimer', 'waittotalxp', 'waittrig', 'waitxp', 'winaddcongauge',
                'winaddconstatus', 'winaddgauge', 'winaddstatus', 'windelgauge', 'windelstatus',
                'winsetgauge', 'winsetstatus', 'writewin',
            ],

            # A list of logical operators ('and', 'or', 'not')
            logicalOpList               => \@logicalOpList,
            # A list of regular expression with which to split a line of Axbasic into a series of
            #   tokens, in the format
            #       $regexHash{token_category} = regex_to_identify_it
            regexHash                   => {
                'short_comment'         => '(?i)!($|.*)',
                'comment'               => '(?i)REM($|\s.*)',
                'keyword'               => "(?i)(" . join("|", @keywordList) . ")\\b",
                'identifier'            => '(?i)[A-Z][A-Z0-9_]*\\$?',
                'logical_operator'      => "(?i)(" . join("|", @logicalOpList) . ")\\b",
                'string_constant'       => '".*?"',
                'numeric_constant'      => '(\\d*\\.)?\\d+',
                'left_paren'            => '\\(',
                'right_paren'           => '\\)',
                'file_channel'          => '\#[0-9]+\s*\:?',
                'separator'             => '[,;]' ,
                'arithmetic_operator'   => '[-+&]',
                'multiplicative_operator'
                                        => '[*/\^]',
                'relational_operator'   => '<[=>]?|>=?|=',
                'assignment_operator'   => '=',
                'statement_end'         =>  ':',
            },

            # The list of token categories, in a standard order
            categoryList                => [
                'short_comment',
                'comment',
                'keyword',
                'identifier',
                'logical_operator',
                'string_constant',
                'numeric_constant',
                'left_paren',
                'right_paren',
                'file_channel',
                'separator',
                'arithmetic_operator',
                'multiplicative_operator',
                'relational_operator',
                'assignment_operator',
                'statement_end',
            ],

            # The script's status:
            #   'waiting' - parsing (or implementation) not yet started
            #   'parsing' - being parsed (or implemented)
            #   'paused' - being parsed (or implemented), but paused (normally when the Axbasic
            #       script is being run as an Axmud task)
            #   'wait_input' - being implemented (when the Axbasic script is being run as an Axmud
            #       task), but waiting for INPUT
            #   'finished' - parsed (or implemented) and finished
            #   'basic_error' - parsed (or implemented) but found an error in the Axbasic script
            #   'perl_error' - parsed (or implemented) but found an error in the Perl Code
            #   'wait_status' - being implemented, but execution has halted after a statement like
            #       WAITHP. Control is passed back to the parent task, but the parent task isn't
            #       paused
            #   'wait_active' - being implemented, but execution has halted after a WAITACTIVE
            #       statement. Control is passed back to the parent task, but the parent task isn't
            #       paused
            #   'wait_not_active' - being implemented, but execution has halted after a
            #       WAITNOTACTIVE statement. Control is passed back to the parent task, but the
            #       parent task isn't paused
            # NB Only the first error message sets ->scriptStatus
            scriptStatus                => 'waiting',
            # The execution mode
            #   'waiting' - execution not yet started
            #   'parse' - parse, but don't execute (used for checking for syntax errors), set when
            #       $self->parse is called
            #   'implement - execute (implement), set when $self->implement is called
            #   'finished' - parsing/implementation finished
            executionStatus             => 'waiting',

            # Blessed reference of the Script task running the script ('undef' if the script isn't
            #   being run from within a task)
            parentTask                  => undef,
            # When the script is being run by an Axmud task, it's useful to limit the number of
            #   steps allowed on each spin of the task loop; so that if the script gets into a very
            #   long calculation (or even an infinite loop), the Axmud client doesn't freeze
            # If the value is set to 0, there is no maximum: the script will keep running until a
            #   PAUSE, BREAK or END (etc) statement
            stepMax                     => 100,
            # How many steps have been used during this task loop (0 if script not run by a task)
            stepCount                   => 0,

            # List of names of the independent interfaces created by ADDTRIG, ADDALIAS, ADDMACRO,
            #   ADDTIMER and ADDHOOK statements, which are stored in the current world's cages
            #   (unless a different cage is specified)
            # If OPTION PERSIST has not been used, all these interfaces must are deleted when the
            #   Axbasic script terminates
            # The list is in the form:
            #   (
            #       independent_interface_name, profile_name, category,
            #       independent_interface_name, profile_name, category
            #       ...
            #   )
            # 'category' will be one of 'trigger', 'alias', 'macro', 'timer' or 'hook'
            indepInterfaceList          => [],
            # IV which stores whether the most recent attempt to create an independent trigger
            #   (etc) was successful
            # Stores the name of the trigger (etc) for success, or 'undef' for failure (or when none
            #   yet created by this Axbasic script)
            indepInterfaceName          => undef,
            # List of names of the dependent interfaces created by SETTRIG (etc) and WAITTRIG (etc)
            #   statements.
            # These interfaces are deleted when the script terminates, regardless of whether
            #   OPTION PERSIST has been used
            # NB ->indepInterfaceList and ->indepInterfaceName are not currently updated to remove
            #   an interface, after a DELTRIG (etc) statement
            depInterfaceList            => [],
            # Flag which stores whether the most recent attempt to create a dependent trigger (etc)
            #   resulted in the creation of an interface
            # Stores the name of the interface for success, or 'undef' for failure (or when none
            #   created by this Axbasic script)
            depInterfaceName            => undef,
            # Every time a dependent interface created by a SETTRIG (etc) statement fires,
            #   information about the interface is stored in a LA::Notification object, which is
            #   then added to the end of this list. (The script can retrieve notifications from the
            #   list at its own convenience)
            # NB ->depInterfaceList and ->depInterfaceName ARE currently updated to remove an
            #   interface, after a DELIFACE statement
            notificationList            => [],
            # If there is more than one LA::Notification in ->notificationList, one of them (usually
            #   the first in the list) is the 'current' one. This IV stores the index containing the
            #   current LA::Notification. If there is one notification in the list, this IV is set
            #   to 0. When the list is empty, it is set to -1
            currentNotification         => -1,

            # Whenever an error is found, a LA::Error object is created to store details of the
            #   error, until the error message (or messages) can be displayed, at the moment when
            #   execution halts
            # The error objects are stored in this list. The first error generated corresponds to
            #   the first error object in the list
            errorList                   => [],

            # The following IVs are set with calls to $self->popSubStack and $self->pushSubStack
            # Subroutine/function stack. (Single-line functions, declared with the 'def' statement,
            #   aren't inserted into the stack)
            # In execution mode 1 (no line numbers), contains a list of LA::Subroutines; the first
            #   one in the list is the '*main" 'subroutine' which represents the main Axbasic
            #   script
            # In execution mode 2 (primitive line numbers), contains only '*main'
            subStackList                => [],
            # How many subroutines/functions are in the stack
            subCount                    => 0,
            # In execution mode 1 (no line numbers), not used
            # In execution mode 2 (primitive line numbers), contains a list of GOSUB or ON-GOSUB
            #   statements so that, upon RETURN, execution resumes with the line immediately after
            #   the GOSUB statement
            gosubStackList              => [],

            # Subroutines and functions have separate namespaces, so it's possible to have a
            #   function, and a subroutine, both called 'test'
            # Hash of subroutine names, so that we don't create two subroutines with the same name
            #   (this should cause an error). Hash in the form
            #       $subNameHash{name} = blessed_reference_to_LA::Subroutine
            # (This is only used in execution mode 1)
            subNameHash                 => {},
            # Hash of function names (including single-line functions). If a function is declared a
            #   second time, it overwrites the original profile (even if it's an intrinsic
            #   function). Hash in the form
            #       $funcNameHash{name} = blessed_reference_to_LA::Function
            # (This is only used in execution mode 1)
            funcNameHash                => {},
            # Hash of intrinsic (pre-defined) functions, in the form
            #   $funcArgHash{function_name} = argument_string
            # Each argument in the argument string is represented by a letter; N for a numeric
            #   argument, S for a string argument. Arguments after a ';' are optional. An empty
            #   argument string is used with intrinsic functions that take no arguments
            # Intrinsic function return either a string value (in which case, they end with $) or
            #   a numeric value
            funcArgHash                 => {
                # Pure BASIC functions (returning a numeric value)
                'abs'                   => 'N',
                'acos'                  => 'N',
                'angle'                 => 'NN',
                'asc'                   => 'S',
                'asin'                  => 'N',
                'atn'                   => 'N',
                'ceil'                  => 'N',
                'cos'                   => 'N',
                'cosh'                  => 'N',
                'cot'                   => 'N',
                'cpos'                  => 'SS;N',
                'cposr'                 => 'SS;N',
                'csc'                   => 'N',
                'date'                  => '',
                'deg'                   => 'N',
                'eof'                   => 'N',
                'epoch'                 => '',
                'exp'                   => 'N',
                'floor'                 => 'N',
                'fp'                    => 'N',
                'int'                   => 'N',
                'ip'                    => 'N',
                'len'                   => 'S',
                'log'                   => 'N',
                'log10'                 => 'N',
                'log2'                  => 'N',
                'match'                 => 'SS',
                'matchi'                => 'SS',
                'max'                   => 'NN',
                'min'                   => 'NN',
                'mod'                   => 'NN',
                'ncpos'                 => 'SS;N',
                'ncposr'                => 'SS;N',
                'pi'                    => '',
                'pos'                   => 'SS;N',
                'posr'                  => 'SS;N',
                'rad'                   => 'N',
                'remainder'             => 'NN',
                'rnd'                   => 'N',
                'round'                 => 'N;N',
                'sec'                   => 'N',
                'sgn'                   => 'N',
                'sin'                   => 'N',
                'sinh'                  => 'N',
                'sqr'                   => 'N',
                'tan'                   => 'N',
                'tanh'                  => 'N',
                'testpat'               => 'S',
                'time'                  => '',
                'trunc'                 => 'N;N',
                'val'                   => 'S',
                'version'               => '',
                # Pure BASIC functions (returning a string value)
                'chr$'                  => 'N',
                'date$'                 => '',
                'ip$'                   => '',
                'lcase$'                => 'S',
                'left$'                 => 'SN',
                'ltrim$'                => 'S',
                'mid$'                  => 'SN;N',
                'repeat$'               => 'SN',
                'right$'                => 'SN',
                'rtrim$'                => 'S',
                'str$'                  => 'N',
                'testpat$'              => 'S',
                'time$',                => '',
                'trim$'                 => 'S',
                'ucase$'                => 'S',
                # Axmud-dependent functions (returning a numeric value)
                'addexit'               => 'NS;S',
                'addfirstroom'          => '',
                'addlabel'              => 'SNNN',
                'addregion'             => 'S',
                'addroom'               => 'NNN',
                'addtempregion'         => ';S',
                'addtwinexit'           => 'N',
                'closemap'              => '',
                'connectexit'           => 'NN',
                'counttask'             => 'S',
                'delexit'               => 'N',
                'delregion'             => 'S',
                'delroom'               => 'N',
                'deltempregions'        => '',
                'disconnectexit'        => 'N',
                'getexitdest'           => 'N',
                'getexitnum'            => 'N',
                'getexittwin'           => 'N',
                'getlostroom'           => '',
                'getobjectalive'        => 'N',
                'getobjectcount'        => 'N',
                'getregionnum'          => '',
                'getroomexits'          => '',
                'getroomnum'            => '',
                'getroomobjects'        => ';S',
                'ifacecount'            => '',
                'ifacedefined'          => 'N',
                'ifacepos'              => '',
                'ifacenum'              => '',
                'ifacestrings'          => '',
                'ifacetime'             => '',
                'isexit'                => 'N',
                'isfinished'            => 'S',
                'ishiddenexit'          => 'N',
                'isregion'              => 'S',
                'isroom'                => 'N',
                'isscript'              => '',
                'ismap'                 => '',
                'istask'                => '',
                'istempregion'          => 'S',
                'iswin'                 => '',
                'openmap'               => '',
                'sethiddenexit'         => 'N',
                'setlight'              => 'S',
                'setmapmode'            => 'S',
                'setornament'           => 'N;S',
                'setrandomexit'         => 'N;S',
                'setregion'             => 'S',
                'setregionnum'          => 'N',
                'setroomnum'            => ';N',
                'setroomtagged'         => ';S',
                'timestamp'             => '',
                # Axmud-dependent functions (returning a string value)
                'abbrevdir$'            => 'S',
                'clientdate$'           => '',
                'clientname$'           => '',
                'clientversion$'        => '',
                'findtask$'             => 'S',
                'getexit$'              => 'N',
                'getexitdrawn$'         => 'N',
                'getexitstatus$'        => 'N',
                'getexittype$'          => 'N',
                'getlight$'             => '',
                'getmapmode$'           => '',
                'getobject$'            => 'N',
                'getobjectnoun$'        => 'N',
                'getobjecttype$'        => 'N',
                'getornament$'          => 'N',
                'getrandomexit$'        => 'N',
                'getregion$'            => '',
                'getroomdescrip$'       => ';S',
                'getroomguild$'         => '',
                'getroomsource$'        => '',
                'getroomtag$'           => '',
                'getroomtitle$'         => '',
                'iface$'                => '',
                'ifacedata$'            => '',
                'ifacename$'            => '',
                'ifacepop$'             => '',
                'ifaceselect$'          => 'N',
                'ifaceshift$'           => '',
                'ifacetext$'            => '',
                'ifacetype$'            => '',
                'popup$'                => 'SSS',
                'scriptname$'           => '',
                'showprofile$'          => '',
                'unabbrevdir$'          => 'S',
            },
            # While parsing the script (in $self->parse), we need to keep track of whether the line
            #   being parsed is within a subroutine declaration, or whether it is outside one - so
            #   that we can detect subroutines declared inside another, and respond to correctly to
            #   an END SUB
            # While parsing statements inside a subroutine declaration, this IV stores the
            #   LA::Subroutine. While parsing statements outside a subroutine declaration (but
            #   inside the implied *main subroutine), this IV is set to 'undef'
            currentParseSub             => undef,

            # Needed by a few statements (most notably PRINT statements) to display stuff in the
            #   way that BASIC is accustomed to displaying stuff
            column                      => 0,

            # Variable declare mode
            # When $self->parse processes a variable, it calls LA::Variable->lookup to find the
            #   LA::Variable in LA::Subroutine's ->localScalarHash / ->localArrayHash. If it's not
            #   there, it looks in this object's ->globalScalarHash / ->globalArrayHash
            # If the variable isn't there, it hasn't been declared yet. In execution mode
            #   'no_line_num', variables must be declared with GLOBAL or LOCAL statements before
            #   being used. (In execution mode 'line_num' (primitive line numbers), all variables
            #   are global and don't have to be declared, so this IV is ignored)
            # This IV is normally set to 'default'. When $self->parse is processing a GLOBAL
            #   statement, it is briefly set to 'global_scalar' (for scalars) or 'global_array' (for
            #   arrays). When processing a LOCAL or SUB statement, it is briefly set to
            #   'local_scalar' (for scalars) or 'local_array' (for arrays). When processing a PEEK
            #   or PEEK... statement, it is briefly set to 'peek_scalar' (for scalars) or
            #   'peek_array' (for arrays)
            # When processing a FOR EACH, POP, PUSH, SHIFT or UNSHIFT statement, or a SORT statement
            #   (or similar), it is set to 'simple'
            # A non-'default' value tells ->lookup to declare the variable by adding it one of the
            #   declared variable hashes. Otherwise, when the script refers to an undeclared
            #   variable, an error is produced
            declareMode                 => 'default',
            # Global variable hashes
            # A hash of global scalar variables, in the form
            #   $globalScalarHash{scalar_name} = blessed_reference_to_scalar_object
            # (The object is a LA::Variable::Scalar::String or LA::Variable::Scalar::Numeric)
            globalScalarHash            => {},
            # A hash of global array variables, in the form
            #   $globalArrayHash{array_name} = blessed_reference_to_array_object
            # (The object is a LA::Variable::Array::String or LA::Variable::Array::Numeric)
            globalArrayHash             => {},

            # Global data list - all the values in DATA statements, which are gathered by
            #   $self->parse and stored here until a READ statement accesses them
            globalDataList              => [],
            # The same data list, with items removed by successive READ statements. The whole list
            #   is reset to match the contents of ->globalDataList by a RESTORE statement
            readDataList                => [],

            # Hash of LA::FileChannel objects, each one representing a data file opened with an
            #   OPEN statement. Hash in the form
            #       $fileChannelHash{number} = blessed_reference_to_file_channel_object
            fileChannelHash             => {},

            # Hash of things declared with the OPTION statement
            #   KEY         VALUE
            #   angle       radians (default) / degrees
            #
            #       - Specifies the type of angle measure used with trigonometric and graphics
            #           functions
            #
            #   needtask    FALSE (default) / TRUE
            #
            #       - Script refuses to run without a parent task, if TRUE
            #
            #   nolet       FALSE (default) / TRUE
            #
            #       - Allows LET keyword to be omitted, if TRUE
            #
            #   persist     FALSE (default) / TRUE
            #
            #       - Independent triggers (etc) not destroyed when the script ends, if TRUE
            #
            #   pseudo      'show_all' / 'hide_complete' (default) / 'hide_system' / 'win_error'
            #                   / 'win_only'
            #
            #       - Sets ->pseudoCmdMode (so value in ->optionStatementHash not used)
            #
            #   redirect    FALSE (default) / TRUE
            #
            #       - If task window is not open, WRITEWIN statements redirect their output to the
            #           'main' window
            #
            #   require     0 / float (e.g. 1.0)
            #
            #       - Script refuses to run unless global variable $BASIC_VERSION >= float
            #
            #   silent      FALSE (default) / TRUE
            #
            #       - Script does not display  messages like 'AXBASIC: Executing 'test'' or
            #           'AXBASIC: Execution of 'test' complete'
            #
            #   typo        FALSE (default) / TRUE
            #
            #       - Allows GLOBAL/LOCAL variable declarations to be omitted, if TRUE. Ignored in
            #           scripts with line numbers
            optionStatementHash         => {
                'angle'                 => 'radians',
                'needtask'              => FALSE,
                'nolet'                 => FALSE,
                'persist'               => FALSE,
                'pseudo'                => 'hide_complete',   # If changed, also set ->pseudoCmdMode
                'redirect'              => FALSE,
                'require'               => 0,
                'silent'                => FALSE,
                'typo'                  => FALSE,
            },

            # List of variables which are expecting to be set by something the user types
            # Every item on the list is a LA::Variable to set
            inputList                   => [],
            # For statements that interact with Axmud directly, the pseudo command mode to use
            # NB If the default value is changed, the corresponding value in ->optionStatementHash
            #   must also be changed, and so must the help for OPTION statements
#           pseudoCmdMode               => 'show_all',        # Show all client command messages
            pseudoCmdMode               => 'hide_complete',   # Ignore success messages, show errors
            # Flag set to TRUE when the parent task's own ->forcedWinFlag is set to TRUE (set to
            #   FALSE otherwise)
            # In 'forced window' mode, the task opens an 'entry' task window before starting to
            #   execute the script. This script then redirects the output from PRINT statements to
            #   the task window. This allows the user to run old BASIC scripts - which obviously
            #   don't know how to open Axmud task windows - in their own window, away from the
            #   'main' window
            forcedWinFlag               => FALSE,
            # All Axbasic scripts must have one, and only one, END statement. When
            #   LA::Statement::end->parse() is run, it checks that this IV is FALSE. If so, it is
            #   set to TRUE; however, if it was already set to TRUE, we get an error
            endStatementFlag            => FALSE,
            # The name of the profile (matches a key in GA::Session->profHash) which is used by
            #   ADDTRIG (etc) and DELTRIG (etc) statements. The default value of the IV is 'undef',
            #   which means 'use the current world profile'. Otherwise, the specified profile is
            #   used
            useProfile                  => undef,
        };

        # Bless the object into existence
        bless $self, $class;

        # Initialise intrinsic functions
        if (! Language::Axbasic::Function::Intrinsic->initialise($self)) {

            # This error is fatal
            return undef;
        }

        # Download the specified raw script, if it was specified
        if ($rawScriptObj) {

            if (! $rawScriptObj->upload($self)) {

                # Download failed. Display any error messages
                if ($self->errorList) {

                    $self->terminateExecution();
                }

                return undef;

            } else {

                # Download complete. Remember the name of the raw script and the file path from
                #   which the script was loaded
                $self->ivPoke('name', $rawScriptObj->name);
                $self->ivPoke('filePath', $rawScriptObj->filePath);

                return $self;
            }

        } else {

            # Don't download a raw script
            return $self;
        }
    }

    ##################
    # Methods

    sub parse {

        # Parses the script, looping over the lines and parsing each line in turn
        # Can be called independently, in which it serves as a basic syntax checker, or can be
        #   called by $self->implement, right before the script is executed
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 if the script is parsed without an error

        my ($self, $check) = @_;

        # Local variables
        my ($lineObj, $mainSubObj);

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
            # Display the error message immediately, and halt execution
            return $self->terminateExecution();
        }

        # Only permit parsing of the script once
        if ($self->scriptStatus ne 'waiting') {

            $self->setDebug('Script already parsed', $self->_objClass . '->parse');
            # Display the error message immediately, and halt execution
            return $self->terminateExecution();
        }

        # Create the first subroutine (the equivalent of a main() function in many languages). This
        #   subroutine is implied and doesn't actually appear in the Axbasic code
        $mainSubObj = Language::Axbasic::Subroutine->new($self, '*main');
        if (! $mainSubObj) {

            $self->setDebug('Can\'t create *main subroutine', $self->_objClass . '->parse');
            # Display the error message immediately, and halt execution
            return $self->terminateExecution();

        } else {

            # This subroutine is the first one in the stack
            $self->ivPush('subStackList', $mainSubObj);
            $self->ivPoke('subCount', 1);

            $mainSubObj->set_stackPosn(0);

            # We keep track of the current subroutine being parsed, but set this IV to 'undef' when
            #   we're in the implied *main subroutine
            $self->ivUndef('currentParseSub');
        }

        # Mark the Axbasic script status as 'parsing' (being parsed/implemented), and the execution
        #   status as 1 (being parsed, not implemented)
        $self->ivPoke('scriptStatus', 'parsing');
        $self->ivPoke('executionStatus', 'parse');

        # Execution begins at line 1
        $self->ivPoke('currentLine', 1);

        # Parse the script by parsing each line in turn
        while ($self->scriptStatus eq 'parsing') {

            # Get the LA::Line object which is the next to be parsed
            $lineObj = $self->ivShow('lineHash', $self->currentLine);
            if (! defined $lineObj) {

                $self->setDebug('Missing line object', $self->_objClass . '->parse');
                # Display the error message immediately, and halt execution
                return $self->terminateExecution();
            }

            # Parse the line
            if ($self->executionStatus eq 'finished' || ! defined $lineObj->parse()) {

                # Execution has halted, either because the script has finished, or because of an
                #   error
                return $self->terminateExecution();
            }

            # Get the next line to be parsed
            if (! defined $self->nextLine) {

                if (! $self->ivExists('lineHash', ($lineObj->procLineNum + 1))) {

                    # Parsing is complete. Check there is exactly one END statement in the script,
                    #   and return the result
                    return $self->checkEndStatements();

                } else {

                    # Use the line immediately after $lineObj
                    $self->ivPoke('currentLine', $lineObj->procLineNum + 1);
                }

            } else {

                # $self->nextLine has been set by something, so parse that line on the next loop
                $self->ivPoke('currentLine', $self->nextLine);
                $self->ivUndef('nextLine');
            }
        }

        # Parsing is complete. Check there is exactly one END statement in the script, and return
        #   the result
        return $self->checkEndStatements();
    }

    sub implement {

        # Implements (executes) the Axbasic script
        # Once this object has been created (with a call to $self->new), can be called by anything
        #   to start implementing (executing) the script
        # If the script pauses for any reason (usually because it's being run by an Axmud 'Script'
        #   task), can be called again to resume implementation
        # Is also called by GA::Session->taskLoop when a paused script must be resumed
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or if the first subroutine can't be created, or if any
        #       functions called (and any functions they call in turn) return an error or if this
        #       function is called recursively
        #   1 if the script is implemented (executed) without an error or if it gets paused before
        #       encountering an error

        my ($self, $check) = @_;

        # Local variables
        my ($lineObj, $nextLine, $currentStatement);

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->implement', @_);
            # Display the error message immediately, and halt execution
            return $self->terminateExecution();
        }

        # If this function is called recursively, do nothing. (Don't return an error; if this
        #   function is being called by the Script task, we want it to call again on the next task
        #   loop)
        if ($self->implementFlag) {

            return undef;

        } else {

            # Prevent any part of the Axmud code from calling this function recursively; the flag is
            #   set back to FALSE when this function ends
            $self->ivPoke('implementFlag', TRUE);
        }

        # If this function is being called for the first time (executing the script from the
        #   start)...
        if ($self->scriptStatus eq 'waiting') {

            # Parse the script
            if (! $self->parse()) {

                # Parsing failed - cannot continue
                $self->ivPoke('implementFlag', FALSE);
                return undef;
            }

            # The script has had an opportunity to set OPTION SILENT, so we now show a confirmation
            if (! $self->ivShow('optionStatementHash', 'silent')) {

                $self->session->writeText('AXBASIC: Executing \'' . $self->name . '\'');
            }

            # Mark the Axbasic script status as 'parsing' (being parsed/implemented), and the
            #   execution status as 2 (being implemented, not merely parsed)
            $self->ivPoke('scriptStatus', 'parsing');
            $self->ivPoke('executionStatus', 'implement');

            # Execution begins at line 1
            $self->ivPoke('currentLine', 1);
            $self->ivPoke('nextLine', undef);
            $self->ivPoke(
                'nextStatement',
                $self->ivShow('lineHash', ($self->currentLine))->firstStatement,
            );

            # Empty the stacks (but retain the implied *main subroutine which is always the first
            #   subroutine in the stack), and set the display column to 0
            $self->ivPoke('subStackList', $self->ivShow('subNameHash', '*main'));
            $self->ivPoke('subCount', 0);
            $self->ivPoke('column', 0);

        # If this function is being called again (resuming execution after a pause)...
        } elsif ($self->scriptStatus eq 'paused') {

            # Mark the Axbasic script status as 'parsing' (being implemented)
            $self->ivPoke('scriptStatus', 'parsing');

        # If this function is being called again (resuming execution after pausing while waiting for
        #   INPUT)
        } elsif ($self->scriptStatus eq 'wait_input') {

            # Input has been received. Mark the Axbasic script status as 1 (being implemented)
            $self->ivPoke('scriptStatus', 'parsing');

        # If this function is being called again (resuming execution after halting, while waiting
        #   for the parent task to monitor another task)...
        } elsif ($self->scriptStatus eq 'wait_status') {

            # The parent task has finished monitoring another task. Mark the Axbasic script status
            #   as 1 (being implemented)
            $self->ivPoke('scriptStatus', 'parsing');

        # Error: called when the Axbasic script status is 'parsing' (script is being parsed or
        #   implemented) or when its execution status is 'implement' (actually executing the script,
        #   don't just checking it for errors)
        } elsif ($self->scriptStatus eq 'parsing' && $self->executionStatus eq 'implement') {

            $self->setDebug(
                'Language::Axbasic::Script->implement called, but script status is already 1',
                $self->_objClass . '->implement',
            );

            # Display the error message immediately, and halt execution
            $self->ivPoke('implementFlag', FALSE);
            return $self->terminateExecution();

        # Error: called when execution has already finished (status = 3, 4 or 5)
        } else {

            $self->setDebug(
                'Language::Axbasic::Script->implement called, but execution already finished',
                $self->_objClass . '->implement',
            );

            # Display the error message immediately, and halt execution
            $self->ivPoke('implementFlag', FALSE);
            return $self->terminateExecution();
        }

        # When the script is being run from within a task, ->parentTask is set
        if ($self->parentTask) {

            # Count the number of steps taken (statements executed) during each task loop
            $self->ivPoke('stepCount', 0);
        }

        # Loop over statements for as long as there are statements to execute
        do {

            if ($self->nextStatement->implement()) {

                # On lines with multiple statements, use the next statement on the line if there is
                #   one (otherwise $self->nextStatement is set to 'undef')
                if (defined $self->nextStatement) {

                    $self->ivPoke('nextStatement', $self->nextStatement->nextStatement);
                }
            }

            if (defined $self->nextStatement) {

                # Set the new current line (which might be the same as the old one)
                $self->ivPoke('currentLine', $self->nextStatement->lineObj->procLineNum);

            } else {

                if (defined $self->nextLine) {

                    # Some other part of the code has specified the new current line
                    $self->ivPoke('currentLine', $self->nextLine);
                    $self->ivUndef('nextLine');
                    $self->ivPoke(
                        'nextStatement',
                        $self->ivShow('lineHash', ($self->currentLine))->firstStatement,
                    );

                } elsif (
                    $self->scriptStatus eq 'parsing'
                    || $self->scriptStatus eq 'paused'
                    || $self->scriptStatus eq 'wait_input'
                    || $self->scriptStatus eq 'wait_status'
                ) {
                    # Script is at the end of a line
                    $self->ivPoke('currentLine', $self->currentLine + 1);
                    $self->ivPoke(
                        'nextStatement',
                        $self->ivShow('lineHash', ($self->currentLine))->firstStatement,
                    );
                }
            }

            # If the script is being run by a task (and if the script must periodically be paused
            #   while waiting for the next task loop), check if it's time to pause (but not if the
            #   script is already marked as paused/waiting for input or if execution has halted)
            if (
                $self->parentTask
                && $self->executionStatus ne 'finished'
                && $self->scriptStatus ne 'paused'
                && $self->scriptStatus ne 'wait_input'
            ) {
                # Another statement has been executed
                $self->ivIncrement('stepCount');

                if ($self->stepMax && $self->stepCount >= $self->stepMax) {

                    # It's time to pause until the next task loop
                    $self->ivPoke('scriptStatus', 'paused');
                }
            }

        # Continue implementing statements until script execution halts, pauses, halts to allow the
        #   parent task to monitor another task (=6) or pauses while expecting INPUT
        } until (
            $self->executionStatus eq 'finished'
            || $self->scriptStatus eq 'paused'
            || $self->scriptStatus eq 'wait_input'
            || $self->scriptStatus eq 'wait_status'
        );

        # Implementation complete (or script paused)
        $self->ivPoke('implementFlag', FALSE);

        if ($self->executionStatus eq 'finished') {

            return $self->terminateExecution();

        } else {

            return 1;
        }
    }

    sub setError {

        # Can be called by any Language::Axbasic:: function whenever it notices an error caused by
        #   the Axbasic script (errors probably caused by this Perl code should be addressed by
        #   calling $self->setDebug)
        # Creates a LA::Error object to store details of the error, so that all error messages can
        #   be displayed together when control is passed back to LA::Script
        # The calling function should then return 'undef', which trickles back down to
        #   LA::Script->parse or LA::Script->implement, one of which actually displays the
        #   error message(s) stored in LA::Script->errorList
        #
        # Expected arguments
        #   $errorCode  - The error message to display, e.g. 'syntax_error'
        #   $func       - A string describing the function that generated the error (e.g.
        #                   'Language::Axbasic::Statement->parse')
        #
        # Optional arguments
        #   %errorHash  - A hash of arguments used to substitute words in $errorCode (see the
        #                   comments in LA::Error; can be an empty hash)
        #
        # Return values
        #   'undef'

        my ($self, $errorCode, $func, %errorHash) = @_;

        # Local variables
        my $errorObj;

        # Check for improper arguments
        if (! defined $errorCode || ! defined $func) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setError', @_);
        }

        # Create an error object and add it to this script object's error list
        $errorObj = Language::Axbasic::Error->new(
            $self,
            'error',
            $errorCode,
            $func,
            $self->currentLine,
            %errorHash,
        );

        if ($errorObj) {

            $self->ivPush('errorList', $errorObj);
        }

        # Set status IVs (but only if they haven't been set by a previous error - the status IVs
        #   only record the first error message received)
        if ($self->executionStatus ne 'finished') {

            # 5 signifies a Axbasic script error
            $self->ivPoke('scriptStatus', 'basic_error');
            # 3 signifies execution has finished
            $self->ivPoke('executionStatus', 'finished');
        }

        # This return value should trickle all the way down to LA::Script->parse or
        #   LA::Script->implement, one of which actually displays the error message
        return undef;
    }

    sub setDebug {

        # Can be called by any Language::Axbasic:: function whenever it notices an error probably
        #   caused by the Perl code (errors caused by the Axbasic script should be addressed by
        #   calling $self->setError)
        # Creates a LA::Error object to store details of the error, so that all error messages can
        #   be displayed together when control is passed back to LA::Script
        # The calling function should then return 'undef', which trickles back down to
        #   LA::Script->parse or LA::Script->implement, one of which actually displays the
        #   error message(s) stored in LA::Script->errorList
        #
        # Expected arguments
        #   $errorCode  - The error message to display, e.g. 'syntax_error'
        #   $func       - A string describing the function that generated the error (e.g.
        #                   'Axbasic::Statement->parse')
        #
        # Optional arguments
        #   %errorHash  - A hash of arguments used to substitute words in $errorCode (see the
        #                   comments in LA::Error; can be an empty hash)
        #
        # Return values
        #   'undef'

        my ($self, $errorCode, $func, %errorHash) = @_;

        # Local variables
        my $errorObj;

        # Check for improper arguments
        if (! defined $errorCode || ! defined $func) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setDebug', @_);
        }

        # Create an error object and add it to this script object's error list
        $errorObj = Language::Axbasic::Error->new(
            $self,
            'debug',
            $errorCode,
            $func,
            $self->currentLine,
            %errorHash,
        );

        if ($errorObj) {

            $self->ivPush('errorList', $errorObj);
        }

        # Set status IVs (but only if they haven't been set by a previous error - the status IVs
        #   only record the first error message received)
        if ($self->executionStatus ne 'finished') {

            # 6 signifies a probably Perl code error
            $self->ivPoke('scriptStatus', 'perl_error');
            # 3 signifies execution has finished
            $self->ivPoke('executionStatus', 'finished');
        }

        # This return value should trickle all the way down to LA::Script->parse or
        #   LA::Script->implement, one of which actually displays the error message
        return undef;
    }

    sub checkEndStatements {

        # Called by $self->parse
        # Check that there is exactly one END statement in the Axbasic script
        # (Multiple END statements are picked up by LA::Statement::end->parse, so we don't need to
        #   check for that possibility)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there are no END statements in the script
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkEndStatements', @_);
        }

        if (! $self->endStatementFlag) {

            # Because the call to this function might be the last thing that $self->parse does, if
            #   there's an error, we have to call ->terminateExecution ourselves
            $self->setError(
                'Axbasic script does not contain an END statement',
                $self->_objClass . '->checkEndStatements',
            );

            return $self->terminateExecution();

        } else {

            return 1;
        }
    }

    sub terminateExecution {

        # Called by $self->parse or $self->implement after parsing/implementation halts, perhaps
        #   because the script has finished naturally, or perhaps because of an error
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or if execution doesn't appear to have been halted, or if
        #       execution halts after an error
        #   1 if execution halts successfully

        my ($self, $check) = @_;

        # Local variables
        my (
            $errorFlag,
            @msgList, @errorObjList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->terminateExecution', @_);
        }

        # If any interfaces were created with the ADDTRIG, ADDALIAS, ADDMACRO, ADDTIMER or ADDHOOK
        #   statements, and if OPTION PERSIST has not been set, then all those interfaces must be
        #   deleted
        $self->destroyOwnInterfaces();

        # Close all file channels which are open
        foreach my $channelObj ($self->ivValues('fileChannelHash')) {

            close $channelObj->fileHandle;
        }

        # Check that execution really has halted
        if ($self->executionStatus ne 'finished') {

            # Because the call to this function might be the last thing that $self->parse or
            #   $self->implement does, if there's an error, we have to use the Axmud error function
            return $self->setError(
                'Axbasic ->executionStatus not set to \'finished\' after execution halts',
                $self->_objClass . '->terminateExecution',
            );

        } elsif (
            $self->scriptStatus eq 'waiting' || $self->scriptStatus eq 'parsing'
            || $self->scriptStatus eq 'paused' || $self->scriptStatus eq 'wait_input'
        ) {
            # (Likewise)
            return $self->setError(
                'Axbasic ->scriptStatus not set to correct value after execution halts',
                $self->_objClass . '->terminateExecution',
            );
        }

        # Compile a list of messages to display, @msgList
        if (
            $self->scriptStatus eq 'basic_error'
            || $self->scriptStatus eq 'perl_error'
            || $self->scriptStatus eq 'wait_status'
            || $self->scriptStatus eq 'wait_active'
            || $self->scriptStatus eq 'wait_not_active'
        ) {
            # There were errors. Import the error list. Unless ->allErrorsFlag has been set to TRUE,
            #   we only display the first error generated
            @errorObjList = $self->errorList;
            if (! $self->allErrorsFlag && @errorObjList > 1) {

                @errorObjList = ($errorObjList[0]);
            }

            foreach my $errorObj (@errorObjList) {

                my (
                    $category, $errorCode, $lineObj,
                    %errorHash,
                );

                $category = $errorObj->category;
                $errorCode = $errorObj->errorCode;
                %errorHash = $errorObj->errorHash;

                # If any of the words in $errorCode are in capitals, they are meant to be keys in
                #   %errorHash which should be substituted for the corresponding values
                # (NB This algorithm will still work if the keys aren't in capitals)
                if (%errorHash) {

                    foreach my $key (keys %errorHash) {

                        if ($errorCode =~ m/$key/) {

                            my $value = $errorHash{$key};
                            $errorCode =~ s/$key/$value/;
                        }
                    }
                }

                # For 'error' messages (but not 'debug' messages)...
                if ($errorObj->category eq 'error') {

                    # For error messages caused by the Axbasic script, the message is in the form
                    #   of a string like 'lots_of_words_separated_by_underlines'
                    # Convert $errorCode (a string like 'syntax_error') into a message in English (a
                    #   string like 'Syntax error')
                    $errorCode =~ s/_/ /g;
                    $errorCode = uc(substr($errorCode, 0, 1)) . substr($errorCode, 1);
                }

                # If the error was caused by a certain line in the Axbasic script, add the line to
                #   the error message
                if (defined $errorObj->line) {

                    # Get the LA::Line object for the line on which the error occurred
                    $lineObj = $self->ivShow('lineHash', $errorObj->line);
                    if ($lineObj) {

                        if ($self->executionMode eq 'line_num') {

                            # For primitive code, use the primitive line number
                            $errorCode .= ', line #' . $lineObj->primLineNum;

                        } elsif ($self->executionMode eq 'no_line_num') {

                            # Otherwise use the line number in the raw (unprocessed) script stored
                            #   in LA::Script
                            $errorCode .= ', line ' . $lineObj->origLineNum;
                        }
                    }
                }

                # Add the error message to the list to be displayed
                if ($errorObj->category eq 'error') {

                    push (@msgList, 'AXBASIC: ERROR: ' . $errorCode);

                } elsif ($errorObj->category eq 'debug') {

                    push (@msgList, 'AXBASIC: DEBUG: ' . $errorCode);
                    if ($lineObj) {

                        push (@msgList, '   Line: ' . $lineObj->lineText);
                    }
                }
            }
        }

        # Add the final message to @msgList
        if (@msgList) {

            $errorFlag = TRUE;

            if ($self->allErrorsFlag) {

                if (@msgList == 1) {

                    push (
                        @msgList,
                        'AXBASIC: Execution of \'' . $self->name . '\' halted (1 error)',
                    );

                } else {

                    push (
                        @msgList,
                        'AXBASIC: Execution of \'' . $self->name . '\' halted (' . @msgList
                        . ' errors)',
                    );
                }

            } else {

                push (@msgList, 'AXBASIC: Execution of \'' . $self->name . '\' halted');
            }

        } elsif (! $self->ivShow('optionStatementHash', 'silent')) {

            push (@msgList, 'AXBASIC: Execution of \'' . $self->name . '\' complete');
        }

        # If the most recent PRINT statement terminated with a comma or semicolon, the first message
        #   in @msgList may be appended to the end of it
        if ($self->column != 0) {

            # Prepend a newline character to get around this problem
            $self->session->writeText(' ');
        }

        # Display the contents of @msgList
        foreach my $msg (@msgList) {

            $self->session->writeText($msg);
        }

        if ($errorFlag) {
            return undef;
        } else {
            return 1;
        }
    }

    sub download {

        # Called by LA::RawScript->upload, which is in turn called by $self->new
        # Stores the processed script in this object's IVs
        #
        # Expected arguments
        #   $lineCount      - Number of lines in the processed script
        #   $executionMode  - Stored as $self->executionMode
        #   $lineHashRef    - Reference to a hash, containing the lines of the processed script
        #   $primHashRef    - In scripts with primitive line numbers, reference to a hash which
        #                       converts those line numbers (e.g. 20 in '20 GOTO 10') into the line
        #                       number of the processed script (stored in $lineHashRef.) An empty
        #                       hash for scripts without line numbers
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $lineCount, $executionMode, $lineHashRef, $primHashRef, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $lineCount || ! defined $executionMode || ! defined $lineHashRef
            || ! defined $primHashRef || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->download', @_);
        }

        # Update IVs
        $self->ivPoke('lineCount', $lineCount);
        $self->ivPoke('executionMode', $executionMode);
        $self->ivPoke('lineHash', %$lineHashRef);
        $self->ivPoke('primLineHash', %$primHashRef);

        return 1;
    }

    sub destroyOwnInterfaces {

        # Called by $self->terminateExecution or by the parent task (if there is one) when the task
        #   itself has to stop
        # Destroys any independent interfaces created with the ADDTRIG, ADDALIAS, ADDMACRO, ADDTIMER
        #   and ADDHOOK statements, if the interfaces still exist (unless OPTION PERSIST has been
        #   specified)
        # Also destroys any interfaces created with the SETTRIG (etc) and WAITTRIG (etc) statements,
        #   regardless of whether OPTION PERSIST has been specified
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->destroyOwnInterfaces', @_);
        }

        # Destroy independent interfaces, if allowed
        if (
            ! $self->ivExists('optionStatementHash', 'persist')
            || ! $self->ivShow('optionStatementHash', 'persist')
        ) {
            @list = $self->indepInterfaceList;
            if (@list) {

                do {
                    my ($name, $profile, $category, $cmd);

                    $name = shift @list;
                    $profile = shift @list;
                    $category = shift @list;

                    # Delete the interface
                    $self->session->pseudoCmd(
                        'delete' . $category . ' ' . $name . ' -d ' . $profile,
                        $self->pseudoCmdMode,
                    );

                } until (! @list);
            }
        }

        # Destroy dependent interfaces
        foreach my $interfaceName ($self->depInterfaceList) {

            my ($obj, $string);

            # If the interface still exists...
            if ($self->session->ivExists('interfaceHash', $interfaceName)) {

                # Get the interface object
                $obj = $self->session->ivShow('interfaceHash', $interfaceName);
                # Cannot use ;deletetrigger for dependent interfaces, so we must remove it
                #   directly
                $self->session->removeInterface($obj);
            }
        }

        # Empty the lists - if the Axbasic script has a parent task, this function might be called
        #   twice
        $self->ivEmpty('indepInterfaceList');
        $self->ivEmpty('depInterfaceList');
        # Reset the two accompanying IVs, just to be sure
        $self->ivUndef('indepInterfaceName');
        $self->ivUndef('depInterfaceName');

        return 1;
    }

    sub returnCurrentSub {

        # Can be called by anything
        # Returns the blessed reference of the current subroutine/function (if none have been called
        #   yet, it's the '*main' subroutine)
        # Actually, returns the last entry in $self->subStackList
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if $self->subStackList is empty (should never happen)
        #   Otherwise returns the blessed reference to the subroutine/function object

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->returnCurrentSub', @_);
        }

        if (! $self->subStackList) {

            # There is no current subroutine or function (this should never happen)
            return undef;

        } else {

            return $self->ivIndex('subStackList', $self->ivLast('subStackList'));
        }
    }

    sub pushSubStack {

        # Can be called by anything
        # Adds a new subroutine/function to the top of the subroutine/function stack
        # In $self->executionMode 'no_line_num' (no line numbers), adds a LA::Subroutine
        # In $self->executionMode 'line_num' (primitive line numbers), not used
        #
        # Expected arguments
        #   $obj    - The object to add
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->pushSubStack', @_);
        }

        $self->ivPush('subStackList', $obj);
        $self->ivIncrement('subCount');

        return 1;
    }

    sub popSubStack {

        # Can be called by anything
        # Removes a new subroutine/function from the top of the subroutine/function stack
        # In $self->executionMode 'no_line_num' (no line numbers), removes a LA::Subroutine
        # In $self->executionMode 'line_num' (primitive line numbers), not used
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if $self->subStackList is empty (should never happen)
        #   The object at the top of the stack, otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->popSubStack', @_);
        }

        $self->ivDecrement('subCount');
        return $self->ivPop('subStackList');
    }

    sub setInputData {

        # Called by the parent task's ->entryCallback method
        # For every item of data the user types in the entry box (while waiting for an Axbasic INPUT
        #   statement), this function is called once to set the relevant variable
        #
        # Expected arguments
        #   $value      - The value to assign a variable
        #
        # Return values
        #   'undef' on improper arguments, or if the variable doesn't exist, or if
        #       $self->inputList (a list of variables awaiting input data) is empty, or if an
        #       error is generated while setting the variable
        #   1 otherwise

        my ($self, $value, $check) = @_;

        # Local variables
        my $varObj;

        # Check for improper arguments
        if (! defined $value || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setInputData', @_);
        }

        # Check that we're expecting some input data. This function shouldn't be called when
        #   $self->inputList is empty
        if (! $self->inputList) {

            # Just ignore the typed value
            return undef;
        }

        # Set the variable
        $varObj = $self->ivShift('inputList')->variable;
        $varObj->set($value);

        if ($self->errorList) {

            # Setting the variable generated an error, so we have to halt
            return $self->terminateExecution();

        } else {

            # Variable set successfully
            return 1;
        }
    }

    sub interfaceNotification {

        # Called by the parent task's ->triggerNotifySeen (etc) when one of the dependent interfaces
        #   created by a SETTRIG (etc) fires
        # Creates a LA::Notification object to store details of the fired interface, so that the
        #   script can retrieve them when it's ready
        #
        # The format of arguments supplied by different GA::Task::Script functions is as follows:
        #
        #   ->triggerNotifySeen: (line_of_text, group_string_list)
        #
        #       line_of_text: The line of text sent by the world which caused the trigger to fire
        #       group_string_list: A list of group substrings from the pattern match (the equivalent
        #           of @_)
        #
        #   ->aliasNotifySeen
        #
        #       world_cmd: The world command which caused the alias to fire
        #       group_string_list: A list of group substrings from the pattern match (the equivalent
        #           of @_)
        #
        #   ->macroNotifySeen
        #
        #       keycode_string: The keycode string (combination of keypresses, e.g. 'ctrl + f1'
        #           which caused the macro to fire
        #       empty_list: An empty list
        #
        #   ->timerNotifySeen
        #
        #       session_time: The value of GA::Session->sessionTime when the timer fired (and that
        #           caused the timer to fire)
        #
        #       other_time: For timers whose stimulus is an interval, the time (matches
        #           GA::Session->sessionTime) at which the timer was due to fire. This value will be
        #           less than or the same as session_time. For timers whose stimulus is a clock time
        #           (in the form HH:MM firing once a day, or 99:MM firing once an hour, at MM
        #           minutes past the hour), the stimulus itself
        #
        #   ->hookNotifySeen
        #
        #       hook_event: The hook event which caused the hook to fire
        #
        #       hook_var, hook_val: Zero, one or two items of additional data for this hook event.
        #           The number of items depends on the hook event
        #
        # Expected arguments
        #   $interfaceObj       - The active interface that fired
        #   $fireBecause        - A scalar describing why the interface fired
        #
        # Optional arguments
        #   @dataList           - A list of additional data, supplied by the interface when it
        #                           fired (may be an empty list)
        #
        # Return values
        #   'undef' on improper arguments or if the LA::Notification object can't be created
        #   1 otherwise

        my ($self, $interfaceObj, $fireBecause, @dataList) = @_;

        # Local variables
        my $obj;

        # Check for improper arguments
        if (! defined $interfaceObj || ! defined $fireBecause) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->interfaceNotification', @_);
        }

        # For triggers and aliases, @fireDataList (if it is populated at all) contains the whole
        #   matching line of text/world command, followed by any substrings. Remove the first
        #   element, leaving us with the substrings
        if (
            ($interfaceObj->category eq 'trigger' || $interfaceObj->category eq 'alias')
            && @dataList
        ) {
            shift @dataList;
        }

        # Create a LA::Notification object to store the information about the fired interface
        $obj = Language::Axbasic::Notification->new(
            $self,
            $interfaceObj,
            $fireBecause,
            @dataList,
        );

        if (! $obj) {

            return undef;

        } else {

            # Add this LA::Notification to the end of the script's list
            $self->ivPush('notificationList', $obj);
            # If the list was empty, make the first notification in the list, the current one
            if ($self->currentNotification == -1) {

                $self->ivPoke('currentNotification', 0);
            }

            return 1;
        }
    }

    sub updateInterfaces {

        # Called by the parent task, when it is paused and waiting for an interface to fire before
        #   resuming
        # Causes this LA::Script to update its IVs to remove the interface
        #
        # Expected arguments
        #   $interfaceName  - The name of the interface to remove
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $interfaceName, $check) = @_;

        # Local variables
        my (@ifaceList, @newList);

        # Check for improper arguments
        if (! defined $interfaceName || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateInterfaces', @_);
        }

        @ifaceList = $self->depInterfaceList;
        foreach my $name (@ifaceList) {

            my $obj = $self->session->ivShow('interfaceHash', $name);

            if ($obj && $obj->name ne $interfaceName) {

                push (@newList, $obj->name);
            }
        }

        $self->ivPoke('depInterfaceList', @newList);

        # Update the accompanying IV, if necessary
        if (
            defined $self->depInterfaceName
            && $self->depInterfaceName eq $interfaceName
        ) {
            $self->ivUndef('depInterfaceName');
        }

        return 1;
    }

    ##################
    # Accessors - set

    sub set_column {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $column, $check) = @_;

        # Check for improper arguments
        if (! defined $column || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_column', @_);
        }

        # Update IVs
        $self->ivPoke('column', $column);

        return 1;
    }

    sub set_currentNotification {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $number, $check) = @_;

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->set_currentNotification',
                @_,
            );
        }

        # Update IVs
        $self->ivPoke('currentNotification', $number);

        return 1;
    }

    sub rmv_currentNotification {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->rmv_currentNotification',
                @_,
            );
        }

        # Update IVs
        $self->ivSplice('notificationList', $self->currentNotification, 1);

        return 1;
    }

    sub inc_currentNotification {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $number, $check) = @_;

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->inc_currentNotification',
                @_,
            );
        }

        # Update IVs
        $self->ivIncrement('currentNotification');

        return 1;
    }

    sub set_currentParseSub {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_currentParseSub', @_);
        }

        # Update IVs
        $self->ivPoke('currentParseSub', $obj);

        return 1;
    }

    sub set_declareMode {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $mode, $check) = @_;

        # Check for improper arguments
        if (! defined $mode || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_declareMode', @_);
        }

        # Update IVs
        $self->ivPoke('declareMode', $mode);

        return 1;
    }

    sub set_depInterfaceName {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $name, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_depInterfaceName', @_);
        }

        # Update IVs
        $self->ivPoke('depInterfaceName', $name);

        return 1;
    }

    sub set_depInterfaceList {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, @list) = @_;

        # (No improper arguments to check - @list can be empty)

        $self->ivPoke('depInterfaceList', @list);

        return 1;
    }

    sub push_depInterfaceList {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->push_depInterfaceList', @_);
        }

        # Update IVs
        $self->ivPush('depInterfaceList', $obj);

        return 1;
    }

    sub set_endStatementFlag {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_endStatementFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('endStatementFlag', TRUE);
        } else {
            $self->ivPoke('endStatementFlag', FALSE);
        }

        return 1;
    }

    sub set_executionStatus {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $status, $check) = @_;

        # Check for improper arguments
        if (! defined $status || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_executionStatus', @_);
        }

        # Update IVs
        $self->ivPoke('executionStatus', $status);

        return 1;
    }

    sub add_fileChannel {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_fileChannel', @_);
        }

        # Update IVs
        $self->ivAdd('fileChannelHash', $obj->channel, $obj);

        return 1;
    }

    sub del_fileChannel {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_fileChannel', @_);
        }

        # Update IVs
        $self->ivDelete('fileChannelHash', $obj->channel);

        return 1;
    }

    sub set_forcedWinFlag {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_forcedWinFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('forcedWinFlag', TRUE);
        } else {
            $self->ivPoke('forcedWinFlag', FALSE);
        }

        return 1;
    }

    sub add_funcName {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $name, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $name || ! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_funcName', @_);
        }

        # Update IVs
        $self->ivAdd('funcNameHash', $name, $obj);

        return 1;
    }

    sub add_globalArray {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $name, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $name || ! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_globalArray', @_);
        }

        # Update IVs
        $self->ivAdd('globalArrayHash', $name, $obj);

        return 1;
    }

    sub push_globalDataList {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $expression, $check) = @_;

        # Check for improper arguments
        if (! defined $expression || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->push_globalDataList', @_);
        }

        # Update IVs
        $self->ivPush('globalDataList', $expression);

        return 1;
    }

    sub add_globalScalar {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $name, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $name || ! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_globalScalar', @_);
        }

        # Update IVs
        $self->ivAdd('globalScalarHash', $name, $obj);

        return 1;
    }

    sub push_gosubStackList {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->push_gosubStackList', @_);
        }

        # Update IVs
        $self->ivPush('gosubStackList', $obj);

        return 1;
    }

    sub pop_gosubStackList {

        # Returns 'undef' on improper arguments
        # Returns the popped value on success (or 'undef' if the list is empty)

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->pop_gosubStackList', @_);
        }

        # Update IVs
        return $self->ivPop('gosubStackList');
    }

    sub set_indepInterfaceName {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $name, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_indepInterfaceName', @_);
        }

        # Update IVs
        $self->ivPoke('indepInterfaceName', $name);

        return 1;
    }

    sub set_indepInterfaceList {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, @list) = @_;

        # (No improper arguments to check - @list can be empty)

        $self->ivPoke('indepInterfaceList', @list);

        return 1;
    }

    sub push_indepInterfaceList {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $name, $profName, $category, $check) = @_;

        # Check for improper arguments
        if (! defined $name || ! defined $profName || ! defined $category || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->push_indepInterfaceList',
                @_,
            );
        }

        # Update IVs
        $self->ivPush('indepInterfaceList', $name, $profName, $category);

        return 1;
    }

    sub push_inputList {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $lvalue, $check) = @_;

        # Check for improper arguments
        if (! defined $lvalue || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->push_inputList', @_);
        }

        # Update IVs
        $self->ivPush('inputList', $lvalue);

        return 1;
    }

    sub set_inputList {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, @list) = @_;

        # (No improper arguments to check - @list can be empty)

        $self->ivPoke('inputList', @list);

        return 1;
    }

    sub set_nextLine {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $number, $check) = @_;

        # Check for improper arguments
        if (! defined $number || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_nextLine', @_);
        }

        # Update IVs
        $self->ivPoke('nextLine', $number);

        return 1;
    }

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

    sub add_optionStatement {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $key, $value, $check) = @_;

        # Check for improper arguments
        if (! defined $key || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_optionStatement', @_);
        }

        # Update IVs
        $self->ivAdd('optionStatementHash', $key, $value);

        return 1;
    }

    sub set_pseudoCmdMode {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $mode, $check) = @_;

        # Check for improper arguments
        if (! defined $mode || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_pseudoCmdMode', @_);
        }

        # Update IVs
        $self->ivPoke('set_pseudoCmdMode', $mode);

        return 1;
    }

    sub set_readDataList {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, @list) = @_;

        # (No improper arguments to check - @list can be empty)

        $self->ivPoke('readDataList', @list);

        return 1;
    }

    sub push_readDataList {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $expression, $check) = @_;

        # Check for improper arguments
        if (! defined $expression || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->push_readDataList', @_);
        }

        # Update IVs
        $self->ivPush('readDataList', $expression);

        return 1;
    }

    sub shift_readDataList {

        # Returns 'undef' on improper arguments
        # Returns the shifted value on success (or 'undef' if the list is empty)

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->shift_readDataList', @_);
        }

        # Update IVs
        return $self->ivShift('readDataList');
    }

    sub set_scriptStatus {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $status, $check) = @_;

        # Check for improper arguments
        if (! defined $status || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_scriptStatus', @_);
        }

        # Update IVs
        $self->ivPoke('scriptStatus', $status);

        return 1;
    }

    sub set_stepCount {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $count, $check) = @_;

        # Check for improper arguments
        if (! defined $count || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_stepCount', @_);
        }

        # Update IVs
        $self->ivPoke('stepCount', $count);

        return 1;
    }

    sub add_subName {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $name, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $name || ! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_subName', @_);
        }

        # Update IVs
        $self->ivAdd('subNameHash', $name, $obj);

        return 1;
    }

    sub set_task {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_task', @_);
        }

        # Update IVs
        $self->ivPoke('parentTask', $obj);
        $self->ivPoke('stepMax', $obj->stepMax);

        return 1;
    }

    sub set_useProfile {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_useProfile', @_);
        }

        # Update IVs
        $self->ivPoke('useProfile', $name);

        return 1;
    }

    ##################
    # Accessors - get

    sub session
        { $_[0]->{session} }

    sub name
        { $_[0]->{name} }
    sub filePath
        { $_[0]->{filePath} }

    sub lineHash
        { my $self = shift; return %{$self->{lineHash}}; }
    sub lineCount
        { $_[0]->{lineCount} }
    sub currentLine
        { $_[0]->{currentLine} }
    sub nextLine
        { $_[0]->{nextLine} }
    sub nextStatement
        { $_[0]->{nextStatement} }

    sub primLineHash
        { my $self = shift; return %{$self->{primLineHash}}; }

    sub executionMode
        { $_[0]->{executionMode} }
    sub allErrorsFlag
        { $_[0]->{allErrorsFlag} }
    sub implementFlag
        { $_[0]->{implementFlag} }

    sub keywordList
        { my $self = shift; return @{$self->{keywordList}}; }
    sub keywordHash
        { my $self = shift; return %{$self->{keywordHash}}; }
    sub modernKeywordList
        { my $self = shift; return @{$self->{modernKeywordList}}; }
    sub primKeywordList
        { my $self = shift; return @{$self->{primKeywordList}}; }
    sub peekPokeList
        { my $self = shift; return @{$self->{peekPokeList}}; }
    sub weakKeywordHash
        { my $self = shift; return %{$self->{weakKeywordHash}}; }
    sub equivKeywordHash
        { my $self = shift; return %{$self->{equivKeywordHash}}; }
    sub clientKeywordList
        { my $self = shift; return @{$self->{clientKeywordList}}; }
    sub taskKeywordList
        { my $self = shift; return @{$self->{taskKeywordList}}; }
    sub logicalOpList
        { my $self = shift; return @{$self->{logicalOpList}}; }
    sub regexHash
        { my $self = shift; return %{$self->{regexHash}}; }
    sub categoryList
        { my $self = shift; return @{$self->{categoryList}}; }

    sub scriptStatus
        { $_[0]->{scriptStatus} }
    sub executionStatus
        { $_[0]->{executionStatus} }

    sub parentTask
        { $_[0]->{parentTask} }
    sub stepMax
        { $_[0]->{stepMax} }
    sub stepCount
        { $_[0]->{stepCount} }

    sub indepInterfaceList
        { my $self = shift; return @{$self->{indepInterfaceList}}; }
    sub indepInterfaceName
        { $_[0]->{indepInterfaceName} }
    sub depInterfaceList
        { my $self = shift; return @{$self->{depInterfaceList}}; }
    sub depInterfaceName
        { $_[0]->{depInterfaceName} }
    sub notificationList
        { my $self = shift; return @{$self->{notificationList}}; }
    sub currentNotification
        { $_[0]->{currentNotification} }

    sub errorList
        { my $self = shift; return @{$self->{errorList}}; }

    sub subStackList
        { my $self = shift; return @{$self->{subStackList}}; }
    sub subCount
        { $_[0]->{subCount} }
    sub gosubStackList
        { my $self = shift; return @{$self->{gosubStackList}}; }

    sub subNameHash
        { my $self = shift; return %{$self->{subNameHash}}; }
    sub funcNameHash
        { my $self = shift; return %{$self->{funcNameHash}}; }
    sub funcArgHash
        { my $self = shift; return %{$self->{funcArgHash}}; }
    sub currentParseSub
        { $_[0]->{currentParseSub} }

    sub column
        { $_[0]->{column} }

    sub declareMode
        { $_[0]->{declareMode} }
    sub globalScalarHash
        { my $self = shift; return %{$self->{globalScalarHash}}; }
    sub globalArrayHash
        { my $self = shift; return %{$self->{globalArrayHash}}; }

    sub globalDataList
        { my $self = shift; return @{$self->{globalDataList}}; }
    sub readDataList
        { my $self = shift; return @{$self->{readDataList}}; }

    sub fileChannelHash
        { my $self = shift; return %{$self->{fileChannelHash}}; }

    sub optionStatementHash
        { my $self = shift; return %{$self->{optionStatementHash}}; }

    sub inputList
        { my $self = shift; return @{$self->{inputList}}; }
    sub pseudoCmdMode
        { $_[0]->{pseudoCmdMode} }
    sub forcedWinFlag
        { $_[0]->{forcedWinFlag} }
    sub endStatementFlag
        { $_[0]->{endStatementFlag} }
    sub useProfile
        { $_[0]->{useProfile} }
}

{ package Language::Axbasic::Line;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Line::ISA = qw(
        Language::Axbasic
    );

    ##################
    # Constructors

    sub new {

        # Called by LA::RawScript->upload
        # The class that handles a single line in the script, which contains one or more statements
        #   (e.g. FOR A = 1 to 10 : NEXT A)
        # (This object has no ->implement method)
        #
        # Expected arguments
        #   $scriptObj      - Blessed reference to the parent LA::Script
        #   $lineText       - The line itself, e.g. 'FOR A = 1 to 10 : NEXT A'
        #   $origLineNum    - The number of this line in the original, unprocessed script (matches a
        #                       key in LA::RawScript->lineHash)
        #   $procLineNum    - The number of this line in the processed script stored by the parent
        #                       LA::Script (matches a key in LA::Script->lineHash)
        #
        # Optional arguments
        #   $primLineNum    - (LA::Script->executionMode 'line_num' for primitive line numbering)
        #                       the primitive line number of this line, e.g. '100 goto 50' > 100
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $scriptObj, $lineText, $origLineNum, $procLineNum, $primLineNum, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $scriptObj || ! defined $lineText
            || ! defined $origLineNum || ! defined $procLineNum || defined $check
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

            # IVs
            # ----

            # The line of text from the script
            lineText                    => $lineText,
            # The number of this line in the original, unprocessed script
            origLineNum                 => $origLineNum,
            # The number of this line in the processed script
            procLineNum                 => $procLineNum,
            # For primitive line numbering - the primitive line number (not related to ->origLineNum
            #   or ->procLineNum; may be 'undef')
            primLineNum                 => $primLineNum,

            # Set by $self->parse - blessed reference of the first LA::Statement on the line. Each
            #   statement has a ->nextStatement IV which gives us a list of statements in the order
            #   in which they should be parsed/implemented
            firstStatement              => undef,
        };

        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub parse {

        # Called by LA::Script->parse and LA::Script->implement
        # Breaks up a line into statements, then parses the statements in order
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or if there is an error
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my ($tokenGroup, $statement, $oldStatement);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->parse', @_);
        }

        # Create a token group
        $tokenGroup = Language::Axbasic::TokenGroup->new($self->scriptObj, $self->lineText);
        if (! defined $tokenGroup) {

            return $self->scriptObj->setDebug(
                'Can\'t create token group object',
                $self->_objClass . '->parse',
            );
        }

        # Break the line up into tokens, and store the tokens as a list in the token group (any
        #   access to the tokens is through the token group's methods)
        if (! $tokenGroup->lex()) {

            return undef;
        }

        # Parse statements on this line, one after the other
        do {

            # Create a statement object, and work out what kind of statement it is ($statement will
            #   be an object of the subclass LA::Statement::*)
            $statement = Language::Axbasic::Statement->new($self->scriptObj, $self, $tokenGroup);
            if (! defined $statement) {

                return $self->scriptObj->setDebug(
                    'Can\'t create statement object',
                    $self->_objClass . '->parse',
                );
            }

            # Parse the statement
            if (! $statement->parse()) {

                return undef;
            }

            # Build a list of statements in the line. The first statement on the line is stored in
            #   $self->firstStatement; every subsequent statement is stored in the previous
            #   statement object's ->nextStatement IV
            if (defined $oldStatement) {

                $oldStatement->set_nextStatement($statement);

            } else {

                $self->ivPoke('firstStatement', $statement);
            }

            $oldStatement = $statement;

            # Check the next token in the token group. If there are none, we have finished parsing
            #   this line. If it's a 'statement_end' token, another statement follows it. If it's
            #   some other kind of token, it's a syntax error

            # If there's a colon at the end of the statement, separating it from the next statement
            #   on the line, shift the corresponding token out of the token group so that, on the
            #   next DO..WHILE loop, the first token in the group is the beginning of the next
            #   statement can be parsed
            if (! $tokenGroup->shiftTokenIfCategory('statement_end')) {

                # But if there are other kinds of tokens at the end of the statement, it's a syntax
                #   error
                if (! defined $tokenGroup->testStatementEnd()) {

                    return $self->scriptObj->setError(
                        'syntax_error',
                        $self->_objClass . '->parse',
                    );
                }
            }

        } while (! defined $tokenGroup->testStatementEnd());

        # Parsing complete
        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub lineText
        { $_[0]->{lineText} }
    sub origLineNum
        { $_[0]->{origLineNum} }
    sub procLineNum
        { $_[0]->{procLineNum} }
    sub primLineNum
        { $_[0]->{primLineNum} }

    sub firstStatement
        { $_[0]->{firstStatement} }
}

{ package Language::Axbasic::Notification;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Notification::ISA = qw(
        Language::Axbasic
    );

    ##################
    # Constructors

    sub new {

        # Called by LA::Script->interfaceNotification
        # Whenever an interface created by a SETTRIG (etc) statement fires, information about the
        #   event is passed to LA::Script->interfaceNotification, which in turn calls this function
        # The new LA::Notification object stores information about a single such event, ready for
        #   the Axbasic script to use when it is ready
        #
        # Expected arguments
        #   $scriptObj          - Blessed reference to the parent LA::Script
        #   $interfaceObj       - The active interface which has fired
        #   $fireBecause        - A scalar describing why the interface fired (see the comments in
        #                           LA::Script->interfaceNotification for a list of values)
        #
        # Optional arguments
        #   @dataList           - A list of additional data, supplied by the interface when it
        #                           fired (may be an empty list)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $scriptObj, $interfaceObj, $fireBecause, @dataList) = @_;

        if (
            ! defined $class || ! defined $scriptObj || ! defined $interfaceObj
            || ! defined $fireBecause
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

            # IVs
            # ----

            # The active interface
            interfaceObj                => $interfaceObj,
            # IVs for quick checking
            category                    => $interfaceObj->category,
            number                      => $interfaceObj->number,
            name                        => $interfaceObj->name,
            time                        => $scriptObj->session->sessionTime,

            # A scalar describing why the interface fired (see the comments in
            #   LA::Script->interfaceNotification for a list of values)
            fireBecause                 => $fireBecause,
            # A list of additional data, supplied by the interface when it fired (may be an empty
            #   list)
            dataList                    => \@dataList,
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

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub interfaceObj
        { $_[0]->{interfaceObj} }
    sub category
        { $_[0]->{category} }
    sub number
        { $_[0]->{number} }
    sub name
        { $_[0]->{name} }
    sub time
        { $_[0]->{time} }

    sub fireBecause
        { $_[0]->{fireBecause} }
    sub dataList
        { my $self = shift; return @{$self->{dataList}}; }
}

{ package Language::Axbasic::TokenGroup;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::TokenGroup::ISA = qw(
        Language::Axbasic
    );

    ##################
    # Constructors

    sub new {

        # Called by LA::Line->parse (which also acts in the place of LA::Line->implement, which
        #   doesn't exist) or by any other function which wants to convert some text into a list of
        #   tokens
        #
        # The class that handles a group of tokens
        # Text from a line in the Axbasic script is lexed and turned into Axbasic tokens which are
        #   stored in this object's ->tokenList
        # Any access to these tokens (including creating them) is through this object's methods
        # Other classes' ->parse methods will usually eat their way through the tokens in this
        #   object's ->tokenList until the list is empty
        #
        # Expected arguments
        #   $scriptObj  - Blessed reference to the parent LA::Script
        #
        # Optional arguments
        #   $text       - The text to be lexed, e.g. 'FOR A = 1 to 10 : NEXT A' (may be a complete
        #                   line, or a partial line). If not specified, then $self->importTokens
        #                   should be called instead of $self->lex
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $scriptObj, $text, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $scriptObj || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'token_group',
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Perl object components
            # ----------------------

            # Blessed reference of the parent LA::Script object
            scriptObj                   => $scriptObj,

            # IVs
            # ---

            # The text to be lexed (if supplied)
            text                        => $text,
            # The list of tokens, compiled after lexing, and gradually removed (starting with the
            #   first token in the list) by calls to this object's methods
            tokenList                   => [],
            # Flag set to TRUE if the token group ended with a 'short_comment' token (which was not
            #   added to ->tokenList)
            shortCommentFlag            => FALSE,
        };

        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub lex {

        # Called by LA::Line->parse (which also acts in the place of LA::Line->implement, which
        #   doesn't exist) or by any other function which wants to convert some text into a list of
        #   tokens
        # Breaks the line of Axbasic text in $self->text into LA::Token objects and puts them in
        #   $self->tokenList, in the order in which they were encountered
        # Stops lexing at the first '!' token, which means the rest of the line is a comment
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there's an error creating a LA::Token object
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $token;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->lex', @_);
        }

        do {

            $token = Language::Axbasic::Token->new($self->scriptObj, $self->text);
            if (! defined $token) {

                return undef;
            }

            if (! $token->extract()) {

                # An invalid token, like 'string' instead of "string"
                return $self->scriptObj->setError(
                    'syntax_error',
                    $self->_objClass . '->lex',
                );

                return undef;

            } else {

                if ($token->category eq 'short_comment') {

                    # ! encountered, meaning that the rest of the line is a comment. Set a flag, so
                    #   that LA::Statement->refine knows this line did contain a valid token
                    $self->ivPoke('shortCommentFlag', TRUE);

                } else {

                    # LA::Token was able to extract a token from $self->text
                    # Add the LA::Token object to this object's token list and, on the next loop,
                    #   search for tokens on the remainder of $self->text
                    $self->ivPush('tokenList', $token);
                    $self->ivPoke('text', $token->remainText);
                }
            }

        # Continue until there are no tokens left
        } until ($self->text eq '' || $token->category eq 'short_comment');

        return 1;
    }

    sub lookAhead {

        # Can be called by anything (all access to tokens is via LA::TokenGroup's methods)
        # Returns the first token in the group without removing it from the group, but returns
        #   'undef' if there are no more tokens left
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there are no tokens left in $self->tokenList
        #   Otherwise returns the blessed reference of the token

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->lookAhead', @_);
        }

        if ($self->tokenList) {

            return $self->ivFirst('tokenList');

        } else {

            return undef;
        }
    }

    sub shiftToken {

        # Can be called by anything (all access to tokens is via LA::TokenGroup's methods)
        # Removes the first token in the group and returns its blessed reference, but returns
        #   'undef' if there are no more tokens left
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there are no tokens left in $self->tokenList
        #   Otherwise returns the blessed reference of the removed token

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->shiftToken', @_);
        }

        if ($self->tokenList) {

            return $self->ivShift('tokenList');

        } else {

            return undef;
        }
    }

    sub shiftMatchingToken {

        # Can be called by anything (all access to tokens is via LA::TokenGroup's methods)
        # If the text of the first token in the group (LA::Token->tokenText) matches the specified
        #   argument (exactly), removes it from the group and returns its blessed reference
        # Otherwise returns 'undef'
        #
        # Expected arguments
        #   $matchString    - The string to match
        #
        # Return values
        #   'undef' on improper arguments, if there are no tokens left in $self->tokenList  or if
        #       the first token doesn't match the specified string
        #   Otherwise returns the blessed reference of the removed token

        my ($self, $matchString, $check) = @_;

        # Check for improper arguments
        if (! defined $matchString || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->shiftMatchingToken', @_);
        }

        if ($self->tokenList && $self->ivFirst('tokenList')->tokenText eq $matchString) {

            return $self->ivShift('tokenList');

        } else {

            return undef;
        }
    }

    sub shiftTokenIfCategory {

        # Can be called by anything (all access to tokens is via LA::TokenGroup's methods)
        # If the first token in the group is of the specified category, removes the token from the
        #   group and returns its blessed reference
        # Otherwise returns 'undef'
        #
        # Expected arguments
        #   $category   - The category to match
        #
        # Return values
        #   'undef' on improper arguments, if there are no tokens left in $self->tokenList or if
        #       the first token doesn't match the specified category
        #   Otherwise returns the blessed reference of the removed token

        my ($self, $category, $check) = @_;

        # Local variables
        my $token;

        # Check for improper arguments
        if (! defined $category || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->shiftTokenIfCategory', @_);
        }

        if (! $self->tokenList) {

            # No tokens left to compare
            return undef;

        # Because the assignment operator '=' and the relational operator '=' are identical, we need
        #   special tests for them
        } elsif (
            $category eq 'relational_operator'
            && $self->ivFirst('tokenList')->category eq 'assignment_operator'
        ) {
            $token = $self->ivShift('tokenList');
            # Change it from an assignment to a relational operator
            $token->ivPoke('category', 'relational_operator');
            $token->set_category('relational_operator');

            return $token;

        } elsif (
            $category eq 'assignment_operator'
            && $self->ivFirst('tokenList')->category eq 'relational_operator'
        ) {
            $token = $self->ivShift('tokenList');
            # Change it from an assignment to a relational operator
            $token->set_category('assignment_operator');

            return $token;

        } elsif ($self->tokenList && $self->ivFirst('tokenList')->category eq $category) {

            # Token categories match (exactly)
            return $self->ivShift('tokenList');

        } else {

            # Token categories don't match at all
            return undef;
        }
    }

    sub importTokens {

        # Can be called by anything (all access to tokens is via LA::TokenGroup's methods)
        # Imports tokens into this group from another group until the other group has no more
        #   tokens, or until the other group's first token has ->tokenText that matches a specified
        #   string exactly (in which case, the token is not imported, and remains as the first token
        #   in the other group)
        #
        # Expected arguments
        #   $otherGroup     - The other LA::TokenGroup from which to taken tokens
        #
        # Optional arguments
        #   @matchList      - A list of strings. If any of them match the other group's ->tokenText,
        #                       that ends the process. (If the list is empty, all tokens to the end
        #                       of the group are taken)
        #
        # Return values
        #   'undef' on improper arguments, if there are no tokens left in $otherGroup's token list
        #       or if the first token in $otherGroup's token list matches a string in @matchList
        #       exactly
        #   Otherwise returns the number of tokens imported (which might be 0)

        my ($self, $otherGroup, @matchList) = @_;

        # Local variables
        my ($token, $count);

        # Check for improper arguments
        if (! defined $otherGroup) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->importTokens', @_);
        }

        # Import tokens
        $count = 0;
        do {

            $token = undef;

            if ($otherGroup->tokenList) {

                $token = $otherGroup->ivFirst('tokenList');
                if (defined $token) {

                    foreach my $matchString (@matchList) {

                        if ($token->tokenText eq $matchString) {

                            # Stop importing. Return the number of imported tokens (may be 0)
                            return $count;
                        }
                    }

                    # Otherwise, import this token
                    $self->ivPush('tokenList', $token);
                    $otherGroup->shiftToken();
                    $count++;
                }
            }

        } until (! defined $token);

        # Return the number of imported tokens (may be 0)
        return $count;
    }

    sub testStatementEnd {

        # Tests whether the statement being parsed has finished (ie there are no tokens left in the
        #   token group, or the first token in the group is a colon)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the first token in the group isn't a statement
        #       separator (ie colon)
        #   1 if there are no tokens left in the group, or the first token in the group is a
        #       statement separator

        my ($self, $check) = @_;

        # Local variables
        my $token;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->testStatementEnd', @_);
        }

        $token = $self->lookAhead();
        if (! $token || $token->category eq 'statement_end') {

            # No more tokens left, or we've reached the end of a statement
            return 1;

        } else {

            return undef;
        }
    }

    ##################
    # Accessors - set

    sub set_tokenList {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, @list) = @_;

        # (No improper arguments to check - @list can be empty)

        $self->ivPoke('tokenList', @list);

        return 1;
    }

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub text
        { $_[0]->{text} }
    sub tokenList
        { my $self = shift; return @{$self->{tokenList}}; }
    sub shortCommentFlag
        { $_[0]->{shortCommentFlag} }

}

{ package Language::Axbasic::Token;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::Token::ISA = qw(
        Language::Axbasic
    );

    ##################
    # Constructors

    sub new {

        # Called by LA::TokenGroup->lex
        # The class that handles a single token. The calling function calls ->new to create the
        #   LA::Token object, then ->extract to extract the token from the specified Axbasic text,
        #   leaving a shorter piece of text
        #
        # Expected arguments
        #   $scriptObj  - Blessed reference to the parent LA::Script
        #   $text       - Some Axbasic text, which may be a complete or partial line
        #                   eg 'FOR A = 1 to 10 : NEXT A'
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $scriptObj, $text, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $scriptObj || ! defined $text || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'token',
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Perl object components
            # ----------------------

            # Blessed reference of the parent LA::Script object
            scriptObj                   => $scriptObj,

            # IVs
            # ---

            # The text from which the token will be extracted - may be a complete or partial line of
            #   BASIC
            text                        => $text,
            # The remaining text in ->text, after the token has been extracted
            remainText                  => undef,

            # The extracted text of the token (e.g. 'print' or '$a'), converted to lower case
            #   (except for string constants), and with leading whitespace removed
            tokenText                   => undef,
            # The extracted text of the token, before conversion, and with leading whitespace intact
            origTokenText               => undef,
            # The leading whitespace (don't know why we need it, but still...)
            leadSpace                   => undef,

            # The category of this token - one of the elements in ->categoryList
            category                    => undef,
        };

        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub extract {

        # Called by LA::TokenGroup->lex
        # Extracts a single token from the beginning of $self->text. Reduces text outside of quotes
        #   strings to lowercase, and saves the results in this object's instance variables, so
        #   LA::TokenGroup->lex can access them
        #
        # Expected arguments
        #   (none besides self)
        #
        # Return values
        #   'undef' on improper arguments, if no token can be extracted from $self->line or if the
        #       whole of the rest of the line is a comment starting with !
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $text;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->extract', @_);
        }

        # The text from which the token is to be extracted
        $text = $self->text;

        # Check each category of token in order. (The order is important, because the category
        #   'identifier' matches nearly all alphanumeric text)
        OUTER: foreach my $category ($self->scriptObj->categoryList) {

            my ($regex, $origSpace, $tokenText);

            if (! $self->scriptObj->ivExists('regexHash', $category)) {

                return $self->scriptObj->setDebug(
                    'Missing regex for token category \'' . $category . '\'',
                    $self->_objClass . '->extract',
                );
            }

            $regex = $self->scriptObj->ivShow('regexHash', $category);

            if ($text =~ s/^(\s*)($regex)//) {

                # Found a token matching $category
                $origSpace = $1;
                $tokenText = $2;

                # (Special case: PRINT$ can be used as a variable, but PRINT obviously cannot.
                #   The $regex picks up the PRINT portion of PRINT$ as a keyword, so we need to
                #   convert it)
                if ($category eq 'keyword' && $text =~ s/^\$//) {

                    $category = 'identifier';
                    $tokenText .= '$';
                }

                # Most tokens are case-insensitive
                if ($category ne 'string_constant') {

                    $tokenText = lc($tokenText);
                }

                # Store details of the token in this object's IVs
                $self->ivPoke('origTokenText', $origSpace . $tokenText);
                $self->ivPoke('leadSpace', $origSpace);
                $self->ivPoke('tokenText', $tokenText);
                $self->ivPoke('category', $category);
                $self->ivPoke('remainText', $text);

                # Stop after finding the first bit of text matching a category of token in
                #   @categoryList
                last OUTER;
            }
        }

        if (! defined $self->category) {

            # No tokens found
            return undef;

        } else {

            # Token found
            return 1;
        }
    }

    ##################
    # Accessors - set

    sub set_category {

        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $category, $check) = @_;

        # Check for improper arguments
        if (! defined $category || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_category', @_);
        }

        # Update IVs
        $self->ivPoke('category', $category);

        return 1;
    }

    sub set_tokenText {

        # Called by LA::Statement::if->parse to convert an ELSEIF keyword token into an IF
        # Returns 'undef' on improper arguments
        # Returns 1 on success

        my ($self, $tokenText, $check) = @_;

        # Check for improper arguments
        if (! defined $tokenText || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_tokenText', @_);
        }

        # Update IVs
        $self->ivPoke('tokenText', $tokenText);

        return 1;
    }

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub text
        { $_[0]->{text} }
    sub remainText
        { $_[0]->{remainText} }

    sub tokenText
        { $_[0]->{tokenText} }
    sub origTokenText
        { $_[0]->{origTokenText} }
    sub leadSpace
        { $_[0]->{leadSpace} }

    sub category
        { $_[0]->{category} }
}

{ package Language::Axbasic::FileChannel;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    @Language::Axbasic::FileChannel::ISA = qw(
        Language::Axbasic
    );

    ##################
    # Constructors

    sub new {

        # Called by LA::Statement::open->implement
        # The class that handles a file channel, opened with an OPEN statement and closed with a
        #   CLOSE statement
        #
        # Expected arguments
        #   $scriptObj      - Blessed reference to the parent LA::Script
        #   $channel        - The file channel number (an integer, 1 or above)
        #   $filePath       - The file opened for reading/writing
        #   $fileHandle     - The filehandle used to read/write from the file
        #   $orgType        - In Axbasic, always set to 'text'
        #   $createType     - 'new', 'old' or 'newold'
        #   $accessType     - 'outin', 'input' or 'output'
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $scriptObj, $channel, $filePath, $fileHandle, $orgType, $createType,
            $accessType, $check
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $scriptObj || ! defined $channel || ! defined $filePath
            || ! defined $fileHandle || ! defined $orgType || ! defined $createType
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'file_channel',
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Perl object components
            # ----------------------

            # Blessed reference of the parent LA::Script object
            scriptObj                   => $scriptObj,

            # IVs
            # ---

            # The file channel number
            channel                     => $channel,
            # The file opened for reading/writing
            filePath                    => $filePath,
            # The filehandle used to read/write from the file
            fileHandle                  => $fileHandle,

            # OPEN statement options
            # For 'ORGANIZATION TEXT' (default), set to 'text'. Axbasic does not implement True
            #   BASIC's 'ORGANIZATION STREAM', 'ORGANIZATION RANDOM', 'ORGANIZATION RECORD' or
            #   'ORGANIZATION BYTE'
            orgType                     => $orgType,
            # For 'CREATE NEW', 'CREATE OLD' (default) or 'CREATE NEWOLD', set to 'new', 'old' or
            #   'newold'
            createType                  => $createType,
            # For 'ACCESS OUTIN' (default), 'ACCESS INPUT' or 'ACCESS OUTPUT', set to 'outin',
            #   'input' or 'output'
            accessType                  => $accessType,
        };

        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub scriptObj
        { $_[0]->{scriptObj} }

    sub channel
        { $_[0]->{channel} }
    sub filePath
        { $_[0]->{filePath} }
    sub fileHandle
        { $_[0]->{fileHandle} }

    sub orgType
        { $_[0]->{orgType} }
    sub createType
        { $_[0]->{createType} }
    sub accessType
        { $_[0]->{accessType} }
}

# Package must return a true value
1
