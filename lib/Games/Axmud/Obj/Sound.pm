# Copyright (C) 2011-2020 A S Lewis
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
# Games::Axmud::Obj::Sound
# Handles playing of sounds other than Axmud sound effects (mostly those initiated by MSP)

{ package Games::Axmud::Obj::Sound;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Client->playSoundFile
        # Creates a new instance of the sound object
        #
        # Expected arguments
        #   $session    - The calling GA::Session
        #   $number     - Unique harness number for this session (not necessarily unique among all
        #                   existing sessions), used to identify this object in its registry,
        #                   GA::Session->soundHarnessHash
        #   $path       - Full file path of the sound file that was played
        #   $harness    - The IPC::Run harness used to play the sound
        #   $delFlag    - Set to TRUE if the file $path should be deleted, when it has finished
        #                   playing, set to FALSE (or 'undef') otherwise. (Used for MXP sound files
        #                   which are converted from a world-specific file format, and which should
        #                   be deleted after being played)
        #   $type       - For MSP-generated sounds, the sound trigger type - 'sound' or 'music'. For
        #                   anything else, set to 'other'
        #   $volume     - For MSP-generated sounds, the volume (a value between 0-100)
        #   $repeat     - For MSP-generated sounds, the number of repeats. 1 - play once, 2 - play
        #                   twice (etc), -1 - play indefinitely
        #   $priority   - For MSP-generated sounds, the sound priority (a value between 0-100)
        #   $continue   - For MSP-generated sounds, a continue flag. 1 - sound continues playing if
        #                   requested again; 0 - sound restarts if requested again
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $session, $number, $path, $harness, $delFlag, $type, $volume, $repeat,
            $priority, $continue, $check,
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $number || ! defined $path
            || ! defined $harness || ! defined $delFlag || ! defined $type || ! defined $volume
            || ! defined $repeat || ! defined $priority || ! defined $continue || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'sound_process_' . $number,
            _parentFile                 => undef,           # No parent file object
            _parentWorld                => undef,           # No parent file object
            _objClass                   => $class,
            _privFlag                   => FALSE,           # All IVs are public

            # IVs
            # ---

            # The calling GA::Session
            $session                    => $session,
            # Unique harness number for this session (not necessarily unique among all existing
            #   sessions)
            number                      => $number,
            # Full file path of the sound file that was played
            path                        => $path,
            # The IPC::Run harness used to play the sound (and required for stopping the sound, when
            #   it's finished or when MSP instructs us)
            harness                     => $harness,
            # Set to TRUE if the file $path should be deleted, when it has finished playing, set to
            #   FALSE (or 'undef') otherwise. (Used for MXP sound files which are converted from a
            #   world-specific file format, and which should be deleted after being played)
            delFlag                     => $delFlag,
            # For MSP-generated sounds, the sound trigger type - 'sound' or 'music'. For anything
            #   else, set to 'other'
            type                        => $type,
            # For MSP-generated sounds, the volume (a value between 0-100)
            volume                      => $volume,
            # For MSP-generated sounds, the number of repeats. 1 - play once, 2 - play twice (etc),
            #   -1 - play indefinitely
            repeat                      => $repeat,
            # For MSP-generated sounds, the sound priority (a value between 0-100)
            priority                    => $priority,
            # For MSP-generated sounds, a continue flag. 1 - sound continues playing if requested
            #   again; 0 - sound restarts if requested again
            continue                    => $continue,
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    sub stop {

        # Called by whichever part of the code stops the sound from playing (or reacts, when the
        #   sound has finished playing)
        # Makes sure the sound has stopped playing, updates the harness, and deletes the sound file
        #   itself if it's been marked for deletion
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $noDelFlag  - Set to TRUE if this sound has been stopped, so that it can be restarted
        #                   (in which case the sound file should not be deleted). Otherwise set to
        #                   FALSE (or 'undef')
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $noDelFlag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->stop', @_);
        }

        $self->harness->finish();
        if (! $noDelFlag && $self->delFlag && -e $self->path) {

            unlink $self->path;
        }

        return 1;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub session
        { $_[0]->{session} }
    sub number
        { $_[0]->{number} }
    sub path
        { $_[0]->{path} }
    sub harness
        { $_[0]->{harness} }
    sub delFlag
        { $_[0]->{delFlag} }
    sub type
        { $_[0]->{type} }
    sub volume
        { $_[0]->{volume} }
    sub repeat
        { $_[0]->{repeat} }
    sub priority
        { $_[0]->{priority} }
    sub continue
        { $_[0]->{continue} }
}

# Package must return a true value
1
