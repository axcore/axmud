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
# Games::Axmud::Obj::Tts
# A TTS configuration object storing settings for text-to-speech (TTS)

{ package Games::Axmud::Obj::Tts;

    use strict;
    use warnings;
    use diagnostics;

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
        #                   for other engines). For eSpeak/espeak-ng, in words per minute in the
        #                   range 10-200. If an invalid value or 'undef', the engine's default speed
        #                   is used
        #   $rate       - Word rate used with the TTS engine (Festival server and Swift only;
        #                   ignored for other engines, including Festival command line). For
        #                   Festival/Swift, in the range 0.50 - 2.00. If an invalid value or
        #                   'undef', the engine's default rate is used
        #   $pitch      - Word pitch used with the TTS engine (eSpeak and Swift only; ignored for
        #                   other engines). For eSpeak, in the range 0-99. For Swift, in the range
        #                   0.1 (10% of normal) to 5 (500% of normal). If an invalid value or
        #                   'undef', the engine's default pitch is used
        #   $volume     - Volume used with the TTS engine (Festival server and Swift only; ignored
        #                   for other engines, including Festival command line). For Festival/Swift,
        #                   in the range 0.33 - 6.00. If an invalid value or 'undef', the engine's
        #                   default pitch is used
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
            # Word speed used with the TTS engine(eSpeak only; ignored for other engines). For
            #   eSpeak, in words per minute in the range 10-200. If an invalid value or 'undef', the
            #   engine's default speed is used.
            speed                       => $speed,
            # Word rate used with the TTS engine (Festival server and Swift only; ignored for other
            #   engines, including Festival command line). For Festival/Swift, in the range 0.50 -
            #   2.00. If an invalid value or 'undef', the engine's default rate is used.
            rate                        => $rate,
            # Word pitch used with the TTS engine (eSpeak and Swift only; ignored for other
            #   engines). For eSpeak, in the range 0-99. For Swift, in the range 0.1 (10% of normal)
            #   to 5 (500% of normal). If an invalid value or 'undef', the engine's default pitch is
            #   used.
            pitch                       => $pitch,
            # Volume used with the TTS engine (Festival server and Swift only; ignored for other
            #   engines, including Festival command line). For Festival/Swift, in the range 0.33 -
            #   6.00. If an invalid value or 'undef', the engine's default pitch is used.
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

# Package must return a true value
1
