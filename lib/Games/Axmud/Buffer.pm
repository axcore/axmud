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
# Games::Axmud::Buffer::XXX
# Display, instruction and world command buffer objects

{ package Games::Axmud::Buffer::Display;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Session->updateDisplayBuffer
        # The display buffer stores lines of text received from the world and displayed in the
        #   session's default textview object
        #
        # Expected arguments
        #   $session        - The calling GA::Session
        #   $parent         - Which registry stores this object - always 'session' for this type of
        #                       buffer object
        #   $number         - A number for this buffer object unique to the parent's registry
        #   $line           - The original line of text received from the world
        #   $stripLine      - $line after being stripped of escape sequences
        #   $modLine        - $stripLine after being modified by any matching interfaces (identical
        #                       to $stripLine if none match)
        #   $time           - The time at which the line was received, in seconds (matches
        #                       GA::Session->sessionTime)
        #   $newLineFlag    - Flag set to TRUE if the line ends with a newline character; FALSE if
        #                       not
        #
        # Optional arguments
        #   $offsetHashRef  - Hash of Axmud colour/style tags in the form
        #                       $offsetHash{$offset} = reference_to_list_of_Axmud_colour_style_tags
        #                   - Each offset represents the position of a character in $modLine,
        #                       immediately before which the equivalent escape sequence was received
        #                       (see the comments in GA::Session->updateDisplayBuffer)
        #                   - If 'undef', it is treated the same as an empty hash reference
        #   $tagHashRef     - Hash of Axmud colour/style tags in the form
        #                       $tagHash{tag} = reference_to_list_of_offsets_where_tags_occur
        #                   - If 'undef', it is treated the same as an empty hash reference
        #   $initialListRef - Reference to a list of Axmud colour/style tags that actually applied
        #                       at the beginning of the line (may be an empty list)
        #                   - If 'undef', it is treated the same as an empty list reference
        #   $mxpFlagHashRef - Hash of text appearing between matching custom elements which define
        #                       tag properties. Hash in the form
        #                       $mxpFlagHash{tag_property} = string
        #                   - If 'undef', it is treated the same way as an empty hash reference
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $session, $parent, $number, $line, $stripLine, $modLine, $time, $newLineFlag,
            $offsetHashRef, $tagHashRef, $initialListRef, $mxpFlagHashRef, $check,
        ) = @_;

        # Local variables
        my ($emptyFlag, $prevBufferObj);

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $parent || ! defined $number
            || ! defined $line || ! defined $stripLine || ! defined $modLine || ! defined $time
            || ! defined $newLineFlag || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Work out whether this counts as an empty line, or not
        if ($modLine =~ m/^\s*[\n\r]*$/) {
            $emptyFlag = TRUE;
        } else {
            $emptyFlag = FALSE;
        }

        # Use empty hash/list references, if none specified
        if (! defined $offsetHashRef) {

            $offsetHashRef = {};
        }

        if (! defined $tagHashRef) {

            $tagHashRef = {};
        }

        if (! defined $initialListRef) {

            $initialListRef = [];
        }

        if (! defined $mxpFlagHashRef) {

            $mxpFlagHashRef = {};
        }

        # Setup
        my $self = {
            _objName                    => 'display_buff_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,                      # No parent file object
            _parentWorld                => undef,                      # No parent file object
            _privFlag                   => TRUE,                       # All IVs are private

            # The calling GA::Session
            session                     => $session,
            # Which registry stores this object - always 'session' for this type of buffer object
            parent                      => $parent,
            # A number for this buffer object unique to the parent's registry
            number                      => $number,

            # The original line of text received from the world
            line                        => $line,
            # The line after being stripped of escape sequences
            stripLine                   => $stripLine,
            # The stripped line after (possibly) being modified by interfaces
            modLine                     => $modLine,
            # A list containing parts of the line. For lines that are received in a single packet,
            #   will contain one item (the same as $line); for lines that are received over two or
            #   more packets, will contain two or more items
            partList                    => [$line],
            # The time at which the line was received, in seconds (matches
            #   GA::Session->sessionTime. If parts of the line were received at different times, the
            #   time at which the first part was received)
            time                        => $time,
            # Flag set to TRUE if the line ends with a newline character; FALSE if not. When FALSE,
            #   text sent to the world is added to this object until the first newline character is
            #   sent (using the $self->update method)
            newLineFlag                 => $newLineFlag,
            # Flag set to TRUE if $modLine contains no characters (besides final newline
            #   characters) or just empty space (besides final newline characters); used for empty
            #   line suppression
            emptyFlag                   => $emptyFlag,

            # Hash of Axmud colour/style tags in the form
            #   $offsetHash{$offset} = reference_to_list_of_Axmud_colour_&_style_tags
            # NB Create a new hash reference because we can't assume the original one will remain
            #   unaltered
            offsetHash                  => {%$offsetHashRef},
            # Hash of Axmud colour/style tags in the form
            #   ->tagHash{tag} = reference_to_list_of_offsets_where_tags_occur
            tagHash                     => {%$tagHashRef},
            # Hash of 'mxpm_mode' tags that appear anywhere on this line, in the form
            #   $mxpModeHash{mode} = undef
            # ...where 'mode' is a number in the range 10-12, 19, 20-99
            mxpModeHash                 => {},

            # List of Axmud colour/style tags that were applied to the first character of this line,
            #   when it was displayed in the 'main' window
            # e.g. if the previous line used a 'blue' tag, but no 'attribs_off' after it, and if
            #   this line has no tags at all at offset 0, then the 'blue' tag still applies, and it
            #   exists in this list
            # e.g. if this line has a 'red' tag at offset 0, then that tag exists in this list,
            #   rather than the 'blue' tag that applied at the end of the previous line
            initialTagList              => [@$initialListRef],
            # List of Axmud colour/style tags that applied at the end of this line (i.e. the tags
            #   that will apply to the beginning of the next line, BEFORE any of the next line's
            #   tags are processed)
            finalTagList                => [],                  # Set below
            # List of Axmud colour/style tags that applied at the end of the previous line (copied
            #   from the buffer object's ->finalTagList from the previous line)
            previousTagList             => [],                  # Set below

            # MXP custom elements can define tag properties, e.g. from the MXP spec,
            #   <RName>...</RName>
            # If a closing tag has been processed on this line, and if the element defines tag
            #   properties, the text between the matching tags is stored in this buffer object
            # (If the text between the two matching tags contained newline characters, they have
            #   been removed)
            # Hash in the form
            #   $mxpFlagHash{tag_property} = text
            mxpFlagTextHash             => {%$mxpFlagHashRef},
        };

        # Bless the object into existence
        bless $self, $class;

        # If we've got a complete line, we can set the final tag list (otherwise, we must wait until
        #   the call to $self->update)
        if ($newLineFlag) {

            $self->{finalTagList} = [$session->currentTabObj->textViewObj->listColourStyleTags()];
        }

        # If this isn't the first buffer line, we can also set the previous tag list
        $prevBufferObj = $session->ivShow('displayBufferHash', ($number - 1));
        if ($prevBufferObj) {

            $self->{previousTagList} = [$prevBufferObj->finalTagList];
        }

        # Set the contents of $self->mxpModeHash, using any 'mxpm_mode' tags found in ->offsetHash
        $self->updateModes();

        return $self;
    }

    ##################
    # Methods

    sub update {

        # Called by GA::Session->updateDisplayBuffer when this object stores the most
        #   recently-displayed line of text from the world, and that line hasn't yet been terminated
        #   with a newline character
        # Updates the stored IVs
        #
        # Expected arguments
        #   $line           - The original line of text received from the world
        #   $stripLine      - $line after being stripped of escape sequences
        #   $modLine        - $stripLine after being modified by any matching interfaces (identical
        #                       to $stripLine if none match)
        #   $newLineFlag    - Flag set to TRUE if the line ends with a newline character; FALSE if
        #                       not
        #   $offsetHashRef  - Hash of Axmud colour/style tags in the form
        #                       $offsetHash{$offset} = reference_to_list_of_Axmud_colour_style_tags
        #                   - Each offset represents the position of a character in $modLine,
        #                       immediately before which the equivalent  escape sequence was
        #                       received (see the comments in GA::Session->updateDisplayBuffer)
        #   $tagHashRef     - Hash of Axmud colour/style tags in the form
        #                       $tagHash{tag} = reference_to_list_of_offsets_where_tags_occur
        #   $mxpFlagHashRef - Hash of text appearing between matching custom elements which define
        #                       tag properties in the form
        #                       $mxpFlagHash{tag_property} = string
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my (
            $self, $line, $stripLine, $modLine, $newLineFlag, $offsetHashRef, $tagHashRef,
            $mxpFlagHashRef,
            $check,
        ) = @_;

        # Local variables
        my (
            $size,
            %newTagHash, %newOffsetHash,
        );

        # Check for improper arguments
        if (
            ! defined $line || ! defined $stripLine || ! defined $modLine || ! defined $newLineFlag
            || ! defined $offsetHashRef || ! defined $tagHashRef || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->update', @_);
        }

        # The contents of $tagHashRef must be merged with the existing contents of $self->tagHash
        # At the same time, we must modify all the offsets in $tagHashRef; e.g. if the tag 'red'
        #   has the list of offsets [0, 4, 9], and if $self->modLine already contains 50
        #   characters, the offsets should be stored as [50, 54, 59]

        # Get the existing size of $self->modLine
        $size = length ($self->modLine);

        # Import the current tag hash for speed...
        %newTagHash = $self->tagHash;
        # ...and then update it with the new data
        foreach my $tag (keys %$tagHashRef) {

            my (
                $offsetListRef, $listRef,
                @newOffsetList,
            );

            # Convert a list like [0, 4, 9] to a list like [50, 54, 59]
            $offsetListRef = $$tagHashRef{$tag};
            foreach my $offset (@$offsetListRef) {

                push (@newOffsetList, ($offset + $size));
            }

            # Update the existing hash of tags
            if (exists $newTagHash{$tag}) {

                $listRef = $newTagHash{$tag};
                push (@$listRef, @newOffsetList);

            } else {

                $newTagHash{$tag} = \@newOffsetList;
            }
        }

        # Do the same with $offsetHashRef

        # Import the current offset hash for speed...
        %newOffsetHash = $self->offsetHash;
        # ...and then update it with the new data
        foreach my $offset (keys %$offsetHashRef) {

            $newOffsetHash{$offset + $size} = $$offsetHashRef{$offset};
        }

        # MXP tag properties for custom elements are rarer, so we don't need to import anything for
        #   speed
        foreach my $key (keys %$mxpFlagHashRef) {

            my $value = $$mxpFlagHashRef{$key};

            # (Guard against possibly that two sets of tags, e.g. <RName>...</RName>, appear on the
            #   same line
            if (! $self->ivExists('mxpFlagTextHash', $key)) {

                $self->ivAdd('mxpFlagTextHash', $key, $value);

            } else {

                $self->ivAdd(
                    'mxpFlagTextHash',
                    $key,
                    $self->ivShow('mxpFlagTextHash', $key) . $value,
                );
            }
        }

        # Update IVs. If $line is an empty string, it's because a packet beginning with a newline
        #   character was processed (otherwise, $line is a string whose initial portion matches the
        #   contents of $self->line)
        if (length ($line) > length ($self->line)) {

            $self->ivPush('partList', substr($line, length($self->line)));
        }

        $self->ivPoke('line', $self->line . $line);
        $self->ivPoke('stripLine', $self->stripLine . $stripLine);
        $self->ivPoke('modLine', $self->modLine . $modLine);
        $self->ivPoke('newLineFlag', $newLineFlag);

        if ($self->modLine =~ m/^\s*[\n\r]*$/) {
            $self->ivPoke('emptyFlag', TRUE);
        } else {
            $self->ivPoke('emptyFlag', FALSE);
        }

        $self->ivPoke('offsetHash', %newOffsetHash);
        $self->ivPoke('tagHash', %newTagHash);

        if ($newLineFlag) {

            $self->ivPoke(
                'finalTagList',
                $self->session->currentTabObj->textViewObj->listColourStyleTags(),
            );
        }

        # Update the ->mxpModeHash IV
        $self->updateModes();

        return 1;
    }

    sub updateModes {

        # Called by $self->new and $self->update
        # $self->mxpModeHash stores all the MXP modes (but only those in the range 10-12, 19, 20-99)
        #   that apply to this line
        # Update the hash
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $check) = @_;

        # Local variables
        my (%offsetHash, %modeHash);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateModes', @_);
        }

        # Import IVs (for convenience)
        %offsetHash = $self->offsetHash;
        %modeHash = $self->mxpModeHash;

        foreach my $offset (keys %offsetHash) {

            my ($listRef, $mode);

            $listRef = $offsetHash{$offset};

            foreach my $tag (@$listRef) {

                if (substr($tag, 0, 5) eq 'mxpm_') {

                    $mode = substr($tag, 5);
                    $modeHash{$mode} = undef;
                }
            }
        }

        # Update the IV
        $self->ivPoke('mxpModeHash', %modeHash);

        return 1;
    }

    sub copyLine {

        # Can be called by anything (for example, called by the Channels task)
        # Copies the contents of the line stored in this object into another textview, preserving
        #   the colour and style of the original line
        # Normal links (e.g. a line containing 'http://mywebsite.com') are clickable, but MXP links
        #   and so on are not
        #
        # Expected arguments
        #   $textViewObj    - The textview object (GA::Obj::TextView) into which the line is copied
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $textViewObj, $check) = @_;

        # Local variables
        my (
            $lastOffset, $lastNewline,
            @previousTagList, @lastList,
            %origHash, %modHash,
        );

        # Check for improper arguments
        if (! defined $textViewObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->copyLine', @_);
        }

        # Import the textview object's hash of styles and colours that apply at the current text
        #   insertion position, so it can be restored when this function has finished
        %modHash = %origHash = $textViewObj->colourStyleHash;

        # The colour/style tags that applied at the beginning of the original line must be applied
        #   to that hash
        @previousTagList = $self->previousTagList;
        %modHash = $textViewObj->applyColourStyleTags(
            $self->session,
            \@previousTagList,
            %modHash,
        );

        $textViewObj->set_colourStyleHash(%modHash);

        # Split the original line into portions, and insert each portion (along with the colour/
        #   style tags that apply to that portion) into the textview
        foreach my $offset (sort {$a <=> $b} ($self->ivKeys('offsetHash'))) {

            my ($listRef, $newline, $portion);

            # Get a list of colour/style tags that apply to this offset
            $listRef = $self->ivShow('offsetHash', $offset);

            # Decide where the newline character should be put
            if ($textViewObj->newLineDefault eq 'before') {

                if ($offset == 0) {
                    $newline = 'before';
                } else {
                    $newline = 'echo';
                }

            } elsif (
                $textViewObj->newLineDefault eq 'after'
                || $textViewObj->newLineDefault eq 'nl'
            ) {
                if ($offset == 0) {
                    $newline = 'echo';
                } else {
                    $newline = 'after';
                }
            }

            # Now we know where the previous portion of text ends, so we can display it
            if (defined $lastOffset) {

                $portion = substr($self->stripLine, $lastOffset, ($offset - $lastOffset));

                %modHash = $textViewObj->colourStyleHash;
                %modHash = $textViewObj->applyColourStyleTags(
                    $self->session,
                    \@lastList,
                    %modHash,
                );

                $textViewObj->set_colourStyleHash(%modHash);

                $textViewObj->insertText(
                    $portion,
                    $lastNewline,
                    $textViewObj->listColourStyleTags(),
                );
            }

            # This portion is displayed in the next iteration of the loop, so we know where the
            #   portion ends
            $lastOffset = $offset;
            $lastNewline = $newline;
            @lastList = @$listRef;
        }

        # Display the final portion
        if (defined $lastOffset) {

            %modHash = $textViewObj->colourStyleHash;

            %modHash = $textViewObj->applyColourStyleTags(
                $self->session,
                \@lastList,
                %modHash,
            );

            $textViewObj->set_colourStyleHash(%modHash);

            $textViewObj->insertText(
                substr($self->stripLine, $lastOffset),
                $lastNewline,
                $textViewObj->listColourStyleTags(),
            );
        }

        # Restore the textview's original colour/style hash, restoring it to its previous state
        $textViewObj->set_colourStyleHash(%origHash);

        # Operation complete
        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub session
        { $_[0]->{session} }
    sub parent
        { $_[0]->{parent} }
    sub number
        { $_[0]->{number} }

    sub line
        { $_[0]->{line} }
    sub stripLine
        { $_[0]->{stripLine} }
    sub modLine
        { $_[0]->{modLine} }
    sub partList
        { my $self = shift; return @{$self->{partList}}; }
    sub time
        { $_[0]->{time} }
    sub newLineFlag
        { $_[0]->{newLineFlag} }
    sub emptyFlag
        { $_[0]->{emptyFlag} }

    sub offsetHash
        { my $self = shift; return %{$self->{offsetHash}}; }
    sub tagHash
        { my $self = shift; return %{$self->{tagHash}}; }
    sub mxpModeHash
        { my $self = shift; return %{$self->{mxpModeHash}}; }

    sub initialTagList
        { my $self = shift; return @{$self->{initialTagList}}; }
    sub finalTagList
        { my $self = shift; return @{$self->{finalTagList}}; }
    sub previousTagList
        { my $self = shift; return @{$self->{previousTagList}}; }

    sub mxpFlagTextHash
        { my $self = shift; return %{$self->{mxpFlagTextHash}}; }
}

{ package Games::Axmud::Buffer::Instruct;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Client->updateInstructBuffer or GA::Session->updateInstructBuffer
        # The instruction buffer object stores instructions processed by a session, including
        #   world/forced world/client commands/echo/Perl/script/multi commands
        # In addition, if the user types 'north;kill troll;eat corpse', that chain of world
        #   commands is stored as a single GA::Buffer::Instruct (and also as three separate
        #   GA::Buffer::Cmd objects in the world command buffer)
        #
        # Expected arguments
        #   $session        - The calling GA::Session
        #   $parent         - Which registry stores this object - 'client' if stored in
        #                       GA::Client->instructBufferHash, 'session' if stored in
        #                       GA::Session->instructBufferHash
        #   $number         - A number for this buffer object unique to the parent's registry
        #   $instruct       - The instruction itself, e.g. ';setworld deathmud', 'north;kill orc'
        #   $type           - The type of instruction: 'client' for a client command, 'world' for a
        #                       world command, 'perl' for a Perl command and 'echo' for an echo
        #                       command
        #   $time           - The time at which the instruction was received, in seconds (matches
        #                       GA::Client->clientTime or GA::Session->sessionTime)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $parent, $number, $instruct, $type, $time, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $parent || ! defined $number
            || ! defined $instruct || ! defined $type || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'instruct_buff_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,                      # No parent file object
            _parentWorld                => undef,                      # No parent file object
            _privFlag                   => TRUE,                       # All IVs are private

            # The calling GA::Session
            session                     => $session,
            # Which registry stores this object - 'client' if stored in
            #   GA::Client->instructBufferHash, 'session' if stored in
            #   GA::Session->instructBufferHash
            parent                      => $parent,
            # A number for this buffer object unique to the parent's registry
            number                      => $number,

            # The instruction itself, e.g. ';setworld deathmud', 'north;kill orc'
            instruct                    => $instruct,
            # The type of instruction: 'client' for a client command, 'world' for a world command
            #   or a forced world command, 'echo' for an echo command, 'perl' for a Perl command,
            #   'script' for a script command and 'multi' for a multi command
            type                        => $type,
            # The time at which the instruction was received, in seconds (matches
            #   GA::Client->clientTime or GA::Session->sessionTime. Set to 'undef' if the
            #   session's ->status is still 'waiting')
            time                        => $time,
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

    sub session
        { $_[0]->{session} }
    sub parent
        { $_[0]->{parent} }
    sub number
        { $_[0]->{number} }

    sub instruct
        { $_[0]->{instruct} }
    sub type
        { $_[0]->{type} }
    sub time
        { $_[0]->{time} }
}

{ package Games::Axmud::Buffer::Cmd;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Client->updateCmdBuffer or GA::Session->updateCmdBuffer
        # The world command buffer object stores individual world commands processed by a session
        #
        # Expected arguments
        #   $session        - The calling GA::Session
        #   $parent         - Which registry stores this object - 'client' if stored in
        #                       GA::Client->instructBufferHash, 'session' if stored in
        #                       GA::Session->instructBufferHash
        #   $number         - A number for this buffer object unique to the parent's registry
        #                   - The Locator task can create one of these objects to handle a move by
        #                       the character, when they are following someone else; in which case,
        #                       $number should be set to -1
        #   $cmd            - The command itself, e.g. 'north', 'kill orc', 'eat corpse'
        #   $time           - The time at which the command was sent, in seconds (matches
        #                       GA::Client->clientTime or GA::Session->sessionTime)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $parent, $number, $cmd, $time, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $parent || ! defined $number
            || ! defined $cmd || ! defined $number || ! defined $time || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'cmd_buff_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,                      # No parent file object
            _parentWorld                => undef,                      # No parent file object
            _privFlag                   => TRUE,                       # All IVs are private

            # The calling GA::Session
            session                     => $session,
            # Which registry stores this object - 'client' if stored in
            #   GA::Client->instructBufferHash, 'session' if stored in
            #   GA::Session->instructBufferHash
            parent                      => $parent,
            # A number for this buffer object unique to the parent's registry
            # NB The Locator task can create one of these objects to handle a move by the character,
            #   when they are following someone else; in which case, $number should be set to -1
            number                      => $number,

            # The command itself, e.g. 'north', 'kill orc', 'eat corpse'
            cmd                         => $cmd,
            # The time at which the command was sent, in seconds (matches
            #   GA::Client->clientTime or GA::Session->sessionTime)
            time                        => $time,

            # IVs set by $self->interpretCmd, which decides whether $cmd is a look/glance or a
            #   movement command (or something different)
            # Flag set to TRUE if this is a 'look'/'short_look' command, FALSE if not
            lookFlag                    => FALSE,
            # Flag set to TRUE if this is a 'glance'/'short_glance' command, FALSE if not
            glanceFlag                  => FALSE,
            # Flag set to TRUE if this is a movement command (including redirect mode commands,
            #   assisted moves and teleport commands), FALSE if not
            moveFlag                    => FALSE,
            # If it's a movement command, the equivalent standard command ('go', 'fly', 'sail' etc)
            #   and the (unabbreviated) direction of movement. Both are set to 'undef' for redirect
            #   mode commands/assisted moves.
            moveDir                     => undef,
            moveVerb                    => undef,
            # Flag set to TRUE if this is an involuntary movement command caused by a follow
            #   pattern (GA::Profile::World->followPatternList and ->followAnchorPatternList)
            followFlag                  => FALSE,
            # Flag set to TRUE if this is an involuntary movement command caused by a follow
            #   anchor pattern (GA::Profile::World->->followAnchorPatternList only), meaning that
            #   no new room statement is expected
            followAnchorFlag            => FALSE,

            # Flag set to TRUE if this was a redirect mode command (in which case, ->moveFlag will
            #   also be TRUE). Set to FALSE otherwise
            redirectFlag                => FALSE,
            # For redirect mode commands, the substituted command (e.g. if $cmd is 'north',
            #   $redirectCmd might be 'sail north'). Set to 'undef' if not a redirect mode command
            redirectCmd                 => undef,

            # Flag set to TRUE if this was a teleportation command, resulting from a call by
            #   GA::Cmd::Teleport->do (or by equivalent code)
            teleportFlag                => FALSE,
            # If this is a teleportation command, the world model number of the destination room
            #   (if known)
            teleportDestRoom            => undef,

            # Flag set to TRUE if this was an assisted move, FALSE if not
            assistedFlag                => FALSE,
            # For assisted moves, the standard primary direction (corresponding to the custom
            #   primary direction $cmd). Set to 'undef' if not an assisted move
            assistedPrimary             => undef,
            # For assisted moves, a list of one or more world commands sent in place of $cmd. An
            #   empty list if not an assisted move
            assistedList                => [],
            # For assisted moves, the GA::Obj::Exit used for the move. Set to 'undef' if not an
            #   assisted move
            assistedExitObj             => undef,
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub interpretCmd {

        # Called by GA::Session->updateCmdBuffer (but not for redirect mode commands or assisted
        #   moves)
        # When the Locator task is running, it needs to know whether this is a look/glance or a
        #   movement command, or a different sort of command
        # This function uses the highest-priority command cage to decide, and then sets this
        #   object's IVs, so that the Locator task can consult them when it's ready
        #
        # Expected arguments
        #   $cage      - The highest-priority command cage
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $cage, $check) = @_;

        # Local variablesinterpretCmd
        my (
            $session, $cmd, $dirType, $lookCmd, $shLookCmd, $glanceCmd, $shGlanceCmd, $moveFlag,
            @patternList, @standardList,
        );

        # Check for improper arguments
        if (! defined $cage || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->interpretCmd', @_);
        }

        # Import IVs (for convenience)
        $session = $self->session;
        $cmd = $self->cmd;
        # Later on we'll need to know what kind of direction $cmd is (if any)
        $dirType = $session->currentDict->ivShow('combDirHash', $cmd);

        # (Do consult inferior cages)
        $lookCmd = $cage->ivShow('cmdHash', 'look', $session);
        $shLookCmd = $cage->ivShow('cmdHash', 'short_look', $session);
        if (($lookCmd && $lookCmd eq $cmd) || ($shLookCmd && $shLookCmd eq $cmd)) {

            # It's a 'look' command
            $self->ivPoke('lookFlag', TRUE);
            return 1;
        }

        $glanceCmd = $cage->ivShow('cmdHash', 'glance', $session);
        $shGlanceCmd = $cage->ivShow('cmdHash', 'short_glance', $session);
        if (($glanceCmd && $glanceCmd eq $cmd) || ($shGlanceCmd && $shGlanceCmd eq $cmd)) {

            # It's a 'glance command'
            $self->ivPoke('glanceFlag', TRUE);
            return 1;
        }

        # There are several standard commands in the commands cage that are movement commands
        #   (stored in $cage->moveCmdList)
        # The replacement strings usually contain the word 'direction'
        # Compile a list of patterns with the word 'direction' replaced by (.*), so that the
        #   replacement string 'ride direction' gets converted to 'ride (.*)', which matches the
        #   commands 'ride north', 'ride up' or even 'ride out'. Ignore any patterns which contain
        #   only '(.*)', and would therefore match any string
        # (If GA::Session->moveMode is set to 'is_move' or 'not_move', then $cmd has already been
        #   classified as definitely a movement command, or definitely not a movement command)
        if ($session->moveMode eq 'unknown') {

            foreach my $verb ($cage->moveCmdList) {

                # (Do consult inferior cages)
                my $replaceString = $cage->ivShow('cmdHash', $verb, $session);
                if ($replaceString && $replaceString ne 'direction') {

                    $replaceString =~ s/direction/(.*)/;

                    # Ignore patterns with no alphanumeric chars
                    if ($replaceString =~ m/\w/) {

                        push (@patternList, $replaceString);
                        # Store the standard command in a parallel list
                        push (@standardList, $verb);
                    }
                }
            }

            # Does $cmd match any of these patterns?
            if (@patternList) {

                for (my $count = 0; $count < scalar @patternList; $count++) {

                    my $pattern = $patternList[$count];

                    if ($cmd =~ m/$pattern/i) {

                        # It's a move command
                        $self->ivPoke('moveFlag', TRUE);
                        # Also store the standard command and the unabbreviated form of the
                        #   specified direction (for convenience)
                        $self->ivPoke('moveVerb', $standardList[$count]);

                        if (
                            $dirType
                            && ($dirType eq 'primaryDir' || $dirType eq 'primaryAbbrev')
                        ) {
                            $self->ivPoke('moveDir', $session->currentDict->checkPrimaryDir($1));

                        } elsif (
                            $dirType
                            && ($dirType eq 'secondaryDir' || $dirType eq 'secondaryAbbrev')
                        ) {
                            $self->ivPoke('moveDir', $session->currentDict->checkSecondaryDir($1));

                        } elsif (
                            $dirType
                            && ($dirType eq 'relativeDir' || $dirType eq 'relativeAbbrev')
                        ) {
                            $self->ivPoke('moveDir', $session->currentDict->checkRelativeDir($1));

                        } else {

                            $self->ivPoke('moveDir', $1);
                        }

                        return 1;
                    }
                }
            }
        }

        # If GA::Session->moveMode is 'is_move', this is definitely a movement command. If
        #   ->moveMose is 'unknown', we have to work out for ourselves whether it's a movement
        #   command, or not
        if ($session->moveMode eq 'is_move') {

            $moveFlag = TRUE;

        } elsif ($session->moveMode eq 'unknown') {

            if (
                # It's a command using a recognised custom direction...
                defined $dirType
                # The automapper knows the current location, and $cmd matches the directions of any
                #   of its exits
                || (
                    $session->mapObj->currentRoom
                    && $session->mapObj->currentRoom->ivExists('exitNumHash', $cmd)
                ) || (
                    $session->mapObj->ghostRoom
                    && $session->mapObj->ghostRoom->ivExists('exitNumHash', $cmd)
                )
            ) {
                $moveFlag = TRUE;
            }

            # Also Check alternative nominal directions in the current/ghost rooms' exits
            if (! $moveFlag && $session->mapObj->currentRoom) {

                OUTER: foreach my $exitNum (
                    $session->mapObj->currentRoom->ivValues('exitNumHash')
                ) {
                    my $exitObj = $session->worldModelObj->ivShow('exitModelHash', $exitNum);

                    if (
                        defined $exitObj->altDir
                        && index($exitObj->altDir, $cmd) > -1
                    ) {
                        $moveFlag = TRUE;
                        last OUTER;
                    }
                }
            }

            if (! $moveFlag && $session->mapObj->ghostRoom) {

                OUTER: foreach my $exitNum (
                    $session->mapObj->ghostRoom->ivValues('exitNumHash')
                ) {
                    my $exitObj = $session->worldModelObj->ivShow('exitModelHash', $exitNum);

                    if (
                        defined $exitObj->altDir
                        && index($exitObj->altDir, $cmd) > -1
                    ) {
                        $moveFlag = TRUE;
                        last OUTER;
                    }
                }
            }
        }

        if ($moveFlag) {

            # It's a movement command
            $self->ivPoke('moveFlag', TRUE);
            # If it's an abbreviated primary/secondary direction, store the unabbreviated form in
            #   ->moveDir
            if ($dirType && ($dirType eq 'primaryDir' || $dirType eq 'primaryAbbrev')) {
                $self->ivPoke('moveDir', $session->currentDict->checkPrimaryDir($cmd));
            } elsif ($dirType && ($dirType eq 'secondaryDir' || $dirType eq 'secondaryAbbrev')) {
                $self->ivPoke('moveDir', $session->currentDict->checkSecondaryDir($cmd));
            } elsif ($dirType && ($dirType eq 'relativeDir' || $dirType eq 'relativeAbbrev')) {
                $self->ivPoke('moveDir', $session->currentDict->checkRelativeDir($cmd));
            } else {
                $self->ivPoke('moveDir', $cmd);
            }

            # The Axmud standard command for this situation is 'go' (see the comments in the command
            #   cage)
            $self->ivPoke('moveVerb', 'go');
        }

        # Check complete
        return 1;
    }

    sub addRedirect {

        # Called by GA::Session->updateCmdBuffer (for redirect mode commands only)
        # Sets this object's redirect mode IVs
        #
        # Expected arguments
        #   $redirectCmd    - The substituted command e.g. if $cmd is 'north', $redirectCmd might be
        #                       'sail north')
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $redirectCmd, $check) = @_;

        # Check for improper arguments
        if (! defined $redirectCmd || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addRedirect', @_);
        }

        # Set IVs
        $self->ivPoke('moveFlag', TRUE);
        $self->ivPoke('redirectFlag', TRUE);
        $self->ivPoke('redirectCmd', $redirectCmd);

        return 1;
    }

    sub addAssisted {

        # Called by GA::Session->updateCmdBuffer (for assisted moves only)
        # Sets this object's assisted move IVs
        #
        # Expected arguments
        #   $standardCmd    - The standard primary direction equivalent to the custom primary
        #                       direction already stored in $self->cmd
        #   $assistedCmd    - The sequence of world commands used in the assisted move (e.g.
        #                       'open door;north')
        #   $exitObj        - The GA::Obj::Exit used in the move (an exit in the exit model)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $standardCmd, $assistedCmd, $exitObj, $check) = @_;

        # Local variables
        my (
            $cmdSep,
            @list,
        );

        # Check for improper arguments
        if (
            ! defined $standardCmd || ! defined $assistedCmd || ! defined $exitObj
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addAssisted', @_);
        }

        # Set IVs
        $self->ivPoke('moveFlag', TRUE);
        $self->ivPoke('assistedFlag', TRUE);
        $self->ivPoke('assistedPrimary', $standardCmd);
        $self->ivPoke('assistedExitObj', $exitObj);

        $cmdSep = $axmud::CLIENT->cmdSep;
        @list = split(m/$cmdSep/, $assistedCmd);
        $self->ivPoke('assistedList', @list);

        return 1;
    }

    sub addTeleport {

        # Called by GA::Session->updateCmdBuffer (for teleport commands resulting from a call by
        #    GA::Cmd::Teleport->do, or equivalent code)
        # Sets this object's teleport IVs
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $destRoom   - The world model number of the destination room (if known; 'undef' if not)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $destRoom, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addTeleport', @_);
        }

        # Set IVs
        $self->ivPoke('moveFlag', TRUE);
        $self->ivPoke('teleportFlag', TRUE);
        $self->ivPoke('teleportDestRoom', $destRoom);       # May be 'undef'

        return 1;
    }

    sub addFollow {

        # Called by GA::Task::Locator->processLine (for an involuntary follow move)
        # Sets this object's follow IVs
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $anchorFlag     - TRUE if no room statement is expected (meaning that the matching line
        #                       itself acts as a room anchor); FALSE (or 'undef') if a room
        #                       statement is expected as normal
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $anchorFlag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addFollow', @_);
        }

        # Set IVs
        $self->ivPoke('moveFlag', TRUE);
        $self->ivPoke('moveDir', $self->cmd);
        $self->ivPoke('moveVerb', 'go');
        $self->ivPoke('followFlag', TRUE);
        if ($anchorFlag) {

            $self->ivPoke('followAnchorFlag', TRUE);
        }

        return 1;
    }

    sub addMove {

        # Called by GA::Task::Locator->processLine (for an involuntary exit in a known direction)
        # Sets this object's IVs
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addMove', @_);
        }

        # Set IVs
        $self->ivPoke('moveFlag', TRUE);
        $self->ivPoke('moveDir', $self->cmd);
        $self->ivPoke('moveVerb', 'go');

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub session
        { $_[0]->{session} }
    sub parent
        { $_[0]->{parent} }
    sub number
        { $_[0]->{number} }

    sub cmd
        { $_[0]->{cmd} }
    sub time
        { $_[0]->{time} }

    sub lookFlag
        { $_[0]->{lookFlag} }
    sub glanceFlag
        { $_[0]->{glanceFlag} }
    sub moveFlag
        { $_[0]->{moveFlag} }
    sub moveDir
        { $_[0]->{moveDir} }
    sub moveVerb
        { $_[0]->{moveVerb} }
    sub followFlag
        { $_[0]->{followFlag} }
    sub followAnchorFlag
        { $_[0]->{followAnchorFlag} }

    sub redirectFlag
        { $_[0]->{redirectFlag} }
    sub redirectCmd
        { $_[0]->{redirectCmd} }

    sub teleportFlag
        { $_[0]->{teleportFlag} }
    sub teleportDestRoom
        { $_[0]->{teleportDestRoom} }

    sub assistedFlag
        { $_[0]->{assistedFlag} }
    sub assistedPrimary
        { $_[0]->{assistedPrimary} }
    sub assistedList
        { my $self = shift; return @{$self->{assistedList}}; }
    sub assistedExitObj
        { $_[0]->{assistedExitObj} }
}

# Package must return a true value
1
