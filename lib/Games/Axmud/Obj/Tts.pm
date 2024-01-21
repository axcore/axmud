# Copyright (C) 2011-2024 A S Lewis
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
# Games::Axmud::Obj::Tts
# A TTS configuration object storing settings for text-to-speech (TTS)
# Games::Axmud::Obj::TtsJob
# An object storing parameters for a single piece of text, to be converted to speech

{ package Games::Axmud::Obj::Tts;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Creates a new instance of the TTS (text-to-speech) object
        #
        # Expected arguments
        #   $name       - A unique string name for this TTS object (max 16 chars, containing
        #                   A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable.
        #                   Reserved names in $axmud::CLIENT->constReservedHash allowed)
        #   $engine     - TTS engine to use (must be one of the values in
        #                   GA::CLIENT->constTTSList)
        #
        # Optional arguments
        #   $voice      - Voice used with the TTS engine (eSpeak, espeak-ng, Flite, Festival server,
        #                   Swift only; ignored when the engine is Festival command line). If an
        #                   empty string or 'undef', the engine's default voice is used
        #   $speed      - Word speed used with the TTS engine (eSpeak and espeak-ng only; ignored
        #                   for other engines). A value in the range 0-100. If an invalid value or
        #                   'undef', the engine's default speed is used
        #   $rate       - Word rate used with the TTS engine (Festival server and Swift only;
        #                   ignored for other engines, including Festival command line). A value in
        #                   the range 0-100. If an invalid value or 'undef', the engine's default
        #                   rate is used
        #   $pitch      - Word pitch used with the TTS engine (eSpeak and Swift only; ignored for
        #                   other engines). A value in the range 0-100. If an invalid value or
        #                   'undef', the engine's default pitch is used
        #   $volume     - Volume used with the TTS engine (Festival server and Swift only; ignored
        #                   for other engines, including Festival command line). A value in the
        #                   range 0-100. If an invalid value or 'undef', the engine's default pitch
        #                   is used
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $name, $engine, $voice, $speed, $rate, $pitch, $volume, $check) = @_;

        # Local variables
        my $ttsObj;

        # Check for improper arguments
        if (! defined $class || ! defined $name || ! defined $engine || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that $name is valid and not already in use by another TTS object
        if (! ($name =~ m/^[[:alpha:]\_]{1}[[:word:]]{0,15}$/)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $class . '->new',
            );

        } elsif ($axmud::CLIENT->ivExists('ttsObjHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: there is already a TTS object called \'' . $name . '\'',
                $class . '->new',
            );
        }

        # Check the engine is valid. The remaining arguments are checked by GA::Client->tts, which
        #   uses default voice/word speed/word pitch as required
        if (! defined $axmud::CLIENT->ivFind('constTTSList', $engine)) {

            return $axmud::CLIENT->writeError(
                'Unrecognised TTS engine \'' . $engine . '\'',
                $class . '->new',
            );
        }

        # Find the TTS configuration object with the same name as the engine (which has default
        #   settings for voice, speed and pitch)
        if ($name ne $engine) {

            $ttsObj = $axmud::CLIENT->ivShow('ttsObjHash', $engine);
        }

        # (The first time Axmud runs, that object might not exist yet...)
        if ($ttsObj) {

            # Use the engine's default settings for the voice, speed, pitch, rate and volume, unless
            #   they were specified by the calling function's argument(s)
            if (! defined $voice) {

                $voice = $ttsObj->voice;
            }

            if (! defined $speed) {

                $speed = $ttsObj->speed;
            }

            if (! defined $rate) {

                $rate = $ttsObj->rate;
            }

            if (! defined $pitch) {

                $pitch = $ttsObj->pitch;
            }

            if (! defined $volume) {

                $volume = $ttsObj->volume;
            }
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'tts',
            _parentWorld                => undef,
            _privFlag                   => FALSE,        # All IVs are public

            # IVs
            # ---

            #  A unique name for the TTS object (max 16 chars)
            name                        => $name,
            # TTS engine to use (must be one of the values in GA::CLIENT->constTTSList)
            engine                      => $engine,
            # Voice used with the TTS engine (eSpeak, Flite, Festival server, Swift only; ignored
            #   when the engine is Festival command line). If an empty string or 'undef', the
            #   engine's default voice is used
            voice                       => $voice,
            # Word speed used with the TTS engine(eSpeak only; ignored for other engines). A value
            #   in the range 0-100. If an invalid value or 'undef', the engine's default speed is
            #   used
            speed                       => $speed,
            # Word rate used with the TTS engine (Festival server and Swift only; ignored for other
            #   engines, including Festival command line). A value in the range 0-100. If an invalid
            #   value or 'undef', the engine's default rate is used
            rate                        => $rate,
            # Word pitch used with the TTS engine (eSpeak and Swift only; ignored for other
            #   engines). A value in the range 0-100. If an invalid value or 'undef', the engine's
            #   default pitch is used
            pitch                       => $pitch,
            # Volume used with the TTS engine (Festival server and Swift only; ignored for other
            #   engines, including Festival command line). A value in the range 0-100. If an invalid
            #   value or 'undef', the engine's default pitch is used
            volume                      => $volume,

            # List of exclusive patterns. If set, only received lines matching these patterns will
            #   be read aloud by the TTS engine. Patterns are tested case-insensitively
            # NB GA::Client->tts automatically splits its supplied string into lines, separated by
            #   a newline character, and tests each line against these patterns).
            exclusiveList               => [],
            # List of excluded patterns. If set, received lines matching these patterns will NOT be
            #   sent to the TTS engine, but all other lines WILL be sent to the engine. Ignored if
            #   $self->exclusiveList is set. Patterns are tested case-insensitively
            excludedList                => [],
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    sub clone {

        # Called by GA::Cmd::CloneConfig->do
        # Creates a clone of an existing TTS configuration object
        #
        # Expected arguments
        #   $name       - A unique string name for this TTS object (max 16 chars, containing
        #                   A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable.
        #                   Must not exist as a key in the global hash of reserved names,
        #                   $axmud::CLIENT->constReservedHash)
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($self, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Check that $name is valid and not already in use by another TTS object
        if (! $axmud::CLIENT->nameCheck($name, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $self->_objClass . '->clone',
            );

        } elsif ($axmud::CLIENT->ivExists('ttsObjHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: there is already a TTS object called \'' . $name . '\'',
                $self->_objClass . '->clone',
            );
        }

        # Setup
        my $clone = {
            _objName                    => $name,
            _objClass                   => $self->_objClass,
            _parentFile                 => 'tts',
            _parentWorld                => undef,
            _privFlag                   => FALSE,        # All IVs are public

            name                        => $name,
            engine                      => $self->engine,
            voice                       => $self->voice,
            speed                       => $self->speed,
            rate                        => $self->rate,
            pitch                       => $self->pitch,
            volume                      => $self->volume,

            exclusiveList               => [$self->exclusiveList],
            excludedList                => [$self->excludedList],
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

    sub name
        { $_[0]->{name} }
    sub engine
        { $_[0]->{engine} }
    sub voice
        { $_[0]->{voice} }
    sub speed
        { $_[0]->{speed} }
    sub rate
        { $_[0]->{rate} }
    sub pitch
        { $_[0]->{pitch} }
    sub volume
        { $_[0]->{volume} }

    sub exclusiveList
        { my $self = shift; return @{$self->{exclusiveList}}; }
    sub excludedList
        { my $self = shift; return @{$self->{excludedList}}; }
}

{ package Games::Axmud::Obj::TtsJob;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Client->tts (only)
        # Creates a new instance of the TTS (text-to-speech) job object
        #
        # Expected arguments
        #   $text       - The text to convert to speech (should not be an empty string)
        #   $engine     - TTS engine to use (must be one of the values in
        #                   GA::CLIENT->constTTSList)
        #
        # Optional arguments
        #   $voice      - Voice used with the TTS engine (eSpeak, espeak-ng, Flite, Festival server,
        #                   Swift only; ignored when the engine is Festival command line). If an
        #                   empty string or 'undef', the engine's default voice is used
        #   $speed      - Word speed used with the TTS engine (eSpeak and espeak-ng only; ignored
        #                   for other engines). A value in the range 0-100. If an invalid value or
        #                   'undef', the engine's default speed is used
        #   $rate       - Word rate used with the TTS engine (Festival server and Swift only;
        #                   ignored for other engines, including Festival command line). A value in
        #                   the range 0-100. If an invalid value or 'undef', the engine's default
        #                   rate is used
        #   $pitch      - Word pitch used with the TTS engine (eSpeak and Swift only; ignored for
        #                   other engines). A value in the range 0-100. If an invalid value or
        #                   'undef', the engine's default pitch is used
        #   $volume     - Volume used with the TTS engine (Festival server and Swift only; ignored
        #                   for other engines, including Festival command line). A value in the
        #                   range 0-100. If an invalid value or 'undef', the engine's default pitch
        #                   is used
        #   $urgentFlag - Flag set to TRUE if this is a so-called 'urgent' job (performed before
        #                   any other job), FALSE or 'undef' if not
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $text, $engine, $voice, $speed, $rate, $pitch, $volume, $urgentFlag, $check
        ) = @_;

        # Local variables
        my $ttsObj;

        # Check for improper arguments
        if (! defined $class || ! defined $text || ! defined $engine || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Remove leading/trailing whitespace, and reduce any remaining whitespace to one character
        #   (this will save a lot of trouble later on)
        $text = $axmud::CLIENT->trimWhitespace($text, TRUE);
        # Use a TRUE or FALSE flag value, but not undef
        if (! defined $urgentFlag) {

            $urgentFlag = FALSE;
        }

        # Setup
        my $self = {
            _objName                    => 'tts_job',
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => FALSE,       # All IVs are public

            # IVs
            # ---

            #  The whole text due to be converted to speech (should not be an empty string)
            text                        => $text,
            # The actual text to convert to speech. Depending on the value of
            #   GA::Client->ttsJobMode, this may be the whole of $self->text, or just a sentence
            #   in it, or just a word in it
            # (An empty string is also possible; see the comments in $self->prepareText)
            currentText                 => $text,
            # Flag set to TRUE if this is a so-called 'urgent' job (performed before any other job),
            #   FALSE if not
            urgentFlag                  => $urgentFlag,
            # Flag set to FALSE as soon as any part of $self->text is converted to speech
            newFlag                     => TRUE,

            # TTS engine to use (must be one of the values in GA::CLIENT->constTTSList)
            engine                      => $engine,
            # Voice used with the TTS engine (eSpeak, Flite, Festival server, Swift only; ignored
            #   when the engine is Festival command line). If an empty string or 'undef', the
            #   engine's default voice is used
            voice                       => $voice,
            # Word speed used with the TTS engine(eSpeak only; ignored for other engines). A value
            #   in the range 0-100. If an invalid value or 'undef', the engine's default speed is
            #   used
            speed                       => $speed,
            # Word rate used with the TTS engine (Festival server and Swift only; ignored for other
            #   engines, including Festival command line). A value in the range 0-100. If an invalid
            #   value or 'undef', the engine's default rate is used
            rate                        => $rate,
            # Word pitch used with the TTS engine (eSpeak and Swift only; ignored for other
            #   engines). A value in the range 0-100. If an invalid value or 'undef', the engine's
            #   default pitch is used
            pitch                       => $pitch,
            # Volume used with the TTS engine (Festival server and Swift only; ignored for other
            #   engines, including Festival command line). A value in the range 0-100. If an invalid
            #   value or 'undef', the engine's default pitch is used
            volume                      => $volume,
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub findNextSentence {

        # Called by functions in GA::Client
        # Given a pointer to a character in $self->text (the first character is zero), find the
        #   beginning of the next sentence in $self->text, if any
        #
        # Expected arguments
        #   $pointer    - The position of a character in $self->text
        #
        # Return values
        #   'undef' on improper arguments, if there is an error or if $pointer is already pointing
        #       at the last sentence
        #   Otherwise, returns the position of the beginning of the next sentence

        my ($self, $pointer, $check) = @_;

        # Local variables
        my (
            $text,
            @list,
        );

        # Check for improper arguments
        if (! defined $pointer || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->findNextSentence', @_);
        }

        # First check that $pointer actually points to a character in $self->text
        if ($pointer < 0 || length($self->text) == 0 || $pointer >= length($self->text)) {

            return undef;
        }

        # Remove everything before the pointer
        $text = substr($self->text, $pointer);

        # Split the remaining text into sentences. Set the pointer after the first one (if any)
        @list = $text =~ m/[^\.\!\?]+[\.\!\?]*/g;

        $pointer += length($list[0]);
        shift @list;

        # Discard sentences containing no alphanumeric characters
        while (@list && ! ($list[0] =~ m/[[[[:alnum:]]/)) {

            $pointer += length $list[0];
            shift @list;
        }

        if (@list) {

            return $pointer;

        } else {

            # Only one sentence
            return undef;
        }
    }

    sub findPreviousSentence {

        # Called by functions in GA::Client
        # Given a pointer to a character in $self->text (the first character is zero), find the
        #   beginning of the previous sentence in $self->text, if any
        #
        # Expected arguments
        #   $pointer    - The position of a character in $self->text
        #
        # Return values
        #   'undef' on improper arguments, if there is an error or if $pointer is already pointing
        #       at the first sentence
        #   Otherwise, returns the position of the beginning of the previous sentence

        my ($self, $pointer, $check) = @_;

        # Local variables
        my (
            $text,
            @list,
        );

        # Check for improper arguments
        if (! defined $pointer || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->findPreviousSentence', @_);
        }

        # If the pointer is already at the first character (position 0), then there cannot be a
        #   previouis sentence
        # Also check that $pointer actually points to a character in $self->text, or the
        #   hypothetical character immediately after it
        if ($pointer <= 0 || length($self->text) == 0 || $pointer >= (length($self->text) + 1)) {

            return undef;
        }

        # Remove everything from the pointer, onwards
        $text = substr($self->text, 0, $pointer);

        # Split the remaining text into sentences, and use the last (or only) one
        @list = $text =~ m/[^\.\!\?]+[\.\!\?]*/g;

        # Discard sentences containing no alphanumeric characters
        while (@list && ! ($list[-1] =~ m/[[[[:alnum:]]/)) {

            pop @list;
        }

        if (! @list) {

            # Remaining $text contained no sentences
            return undef;

        } elsif (@list == 1) {

            # Remaining $text contained only one sentence
            return 0;

        } else {

            # Pointer should be just after the last unpopped sentence in @list
            pop @list;
            return length(join('', @list));
        }
    }

    sub findNextWord {

        # Called by functions in GA::Client
        # Given a pointer to a character in $self->text (the first character is zero), find the
        #   beginning of the next word in $self->text, if any
        #
        # Expected arguments
        #   $pointer    - The position of a character in $self->text
        #
        # Return values
        #   'undef' on improper arguments, if there is an error or if $pointer is already pointing
        #       at the last word
        #   Otherwise, returns the position of the beginning of the next word

        my ($self, $pointer, $check) = @_;

        # Local variables
        my (
            $text,
            @list,
        );

        # Check for improper arguments
        if (! defined $pointer || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->findNextWord', @_);
        }

        # First check that $pointer actually points to a character in $self->text
        if ($pointer < 0 || length($self->text) == 0 || $pointer >= length($self->text)) {

            return undef;
        }

        # Remove everything before the pointer
        $text = substr($self->text, $pointer);

        # Split the remaining text into words. Set the pointer after the first word (if any)
        @list = $text =~ m/[^\s]+[\s]*/g;

        $pointer += length($list[0]);
        shift @list;

        # Discard words containing no alphanumeric characters
        while (@list && ! ($list[0] =~ m/[[[[:alnum:]]/)) {

            $pointer += length $list[0];
            shift @list;
        }

        if (@list) {

            return $pointer;

        } else {

            # No next word to return
            return undef;
        }
    }

    sub findPreviousWord {

        # Called by functions in GA::Client
        # Given a pointer to a character in $self->text (the first character is zero), find the
        #   beginning of the previous word in $self->text, if any
        #
        # Expected arguments
        #   $pointer    - The position of a character in $self->text
        #
        # Return values
        #   'undef' on improper arguments, if there is an error or if $pointer is already pointing
        #       at the first word
        #   Otherwise, returns the position of the beginning of the previous word

        my ($self, $pointer, $check) = @_;

        # Local variables
        my (
            $text,
            @list,
        );

        # Check for improper arguments
        if (! defined $pointer || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->findPreviousWord', @_);
        }

        # If the pointer is already at the first character (position 0), then there cannot be a
        #   previouis word
        # Also check that $pointer actually points to a character in $self->text, or the
        #   hypothetical character immediately after it
        if ($pointer <= 0 || length($self->text) == 0 || $pointer >= (length($self->text) + 1)) {

            return undef;
        }

        # Remove everything at the pointer onwards
        $text = substr($self->text, 0, $pointer);

        # Split the remaining text into words, and use the last (or only) one
        @list = $text =~ m/[^\s]+[\s]*/g;

        # Discard words containing no alphanumeric characters
        while (@list && ! ($list[-1] =~ m/[[[[:alnum:]]/)) {

            pop @list;
        }

        if (! @list) {

            # Remaining $text contained no words
            return undef;

        } elsif (@list == 1) {

            # Remaining $text contained only one word
            return 0;

        } else {

            # Pointer should be just after the last unpopped word in @list
            pop @list;
            return length(join('', @list));
        }
    }

    sub prepareText {

        # Called by GA::Client->ttsPerformJobs
        # Sets the value of $self->currentText, which might be the whole of $self->text, or just
        #   one sentence, or just one word
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
            $text,
            @list,
        );

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->prepareText', @_);
        }

        if ($axmud::CLIENT->ttsJobMode eq 'default' || $axmud::CLIENT->ttsJobAutoFlag) {

            $self->ivPoke('currentText', $self->text);

        } else {

            # GA::Client->ttsJobMiniPointer points at a position in $self->text. Use the whole
            #   sentence/word after (and including) that character

            # Remove everything before the pointer
            $text = $self->text;
            if ($axmud::CLIENT->ttsJobMiniPointer > 0) {

                $text = substr($text, $axmud::CLIENT->ttsJobMiniPointer);
            }

            if ($axmud::CLIENT->ttsJobMode eq 'sentence') {

                # Split the remaining text into sentences, and use the first sentence
                @list = $text =~ m/[^\.\!\?]+[\.\!\?]*/g;

            } else {

                # Split the remaining text into words, and use the first word
                @list = $text =~ m/[^\s]+[\s]*/g;
            }

            # Discard words/sentences containing no alphanumeric characters
            while (@list && ! ($list[0] =~ m/[[[[:alnum:]]/)) {

                shift @list;
            }

            if (! @list) {

                # No alphanumeric text found. Set the IV to an empty string; the calling code
                #   checks for that
                $self->ivPoke('currentText', '');

            } else {

                $self->ivPoke(
                    'currentText',
                    $axmud::CLIENT->trimWhitespace($list[0]),
                );
            }
        }

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub text
        { $_[0]->{text} }
    sub currentText
        { $_[0]->{currentText} }
    sub urgentFlag
        { $_[0]->{urgentFlag} }
    sub newFlag
        { $_[0]->{newFlag} }

    sub engine
        { $_[0]->{engine} }
    sub voice
        { $_[0]->{voice} }
    sub speed
        { $_[0]->{speed} }
    sub rate
        { $_[0]->{rate} }
    sub pitch
        { $_[0]->{pitch} }
    sub volume
        { $_[0]->{volume} }
}

# Package must return a true value
1
