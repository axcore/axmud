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
# Games::Axmud::Obj::Component
# Handles room statement components

{ package Games::Axmud::Obj::Component;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Prepare a new instance of the room statement component object
        #
        # Expected arguments
        #   $session    - The parent GA::Session (not stored as an IV)
        #   $worldObj   - The world profile object to which this component belongs
        #   $name       - Unique name for this component (can match the component type) (max
        #                   16 chars)
        #   $type       - One of 'verb_title', 'verb_descrip', 'verb_exit', 'verb_content',
        #                   'verb_special', 'brief_title', 'brief_exit', 'brief_title_exit',
        #                   'brief_exit_title', 'brief_content', 'room_cmd', 'mudlib_path',
        #                   'weather', 'ignore_line', 'custom'
        #
        # Optional arguments
        #   $tempFlag   - If set to TRUE, this is a temporary component created for use with an
        #                   'edit' window; $name is not checked for validity. Otherwise set to FALSE
        #                   (or 'undef')
        #
        # Return values
        #   'undef' on improper arguments, or if $name or $type are invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $worldObj, $name, $type, $tempFlag, $check) = @_;

        # Local variables
        my $matchFlag;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $worldObj || ! defined $name
            || ! defined $type || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        if (! $tempFlag) {

            # Check that $name is valid and not already in use by another component
            if (! $axmud::CLIENT->nameCheck($name, 16)) {

                return $axmud::CLIENT->writeError(
                    'Registry naming error: invalid name \'' . $name . '\'',
                    $class . '->new',
                );

            } elsif ($worldObj->ivExists('componentHash', $name)) {

                return $axmud::CLIENT->writeError(
                    'Registry naming error: profile \'' . $worldObj->name . '\' already has a'
                    . ' component called \'' . $name . '\'',
                    $class . '->new',
                );
            }
        }

        # Check $type is valid
        OUTER: foreach my $standardType ($axmud::CLIENT->constComponentTypeList) {

            if ($type eq $standardType) {

                $matchFlag = TRUE;
                last OUTER;
            }
        }

        if (! $matchFlag) {

            return $session->writeError(
                'Invalid room statement component type \'' . $type . '\'',
                $class . '->new',
            );
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => $worldObj->name,
            _parentWorld                => undef,
            _privFlag                   => FALSE,                       # All IVs are public

            # Object IVs
            # ----------

            # Unique name for this component
            name                        => $name,
            # The component type, one of 'verb_title', 'verb_descrip', 'verb_exit', 'verb_content',
            #   'verb_special', 'brief_title', 'brief_exit', 'brief_title_exit', 'brief_exit_title',
            #   'brief_content', 'room_cmd', 'mudlib_path', 'weather', 'ignore_line', 'custom'
            type                        => $type,

            # The component's size - how many lines are in this component. If set to 0, the size
            #   is dynamic, and we use other IVs to find the extent of the component. If set to a
            #   positive integer like '1' or '3', the component is always that size. (Valid range:
            #   0-256)
            size                        => 0,           # Not a fixed size
            # The component's minimum size; ignored if ->size is not 0. If the minimum size is 0,
            #   the component is optional. (Valid range: 0-256)
            minSize                     => 0,
            # The maximum number of lines to check. If we check this many lines without finding
            #   the 'stop' line, the last line checked is the 'stop' line (this IV overrides all
            #   the others, and must not be set to 0. Valid range - 1-256)
            maxSize                     => 16,
            # As the Locator analyses text received from the world, looking for room statements, the
            #   way in which lines of text are checked against patterns/tags:
            #   'check_line' - Check each line, one at a time, against all patterns/tags
            #   'check_pattern_tag' - Check each set of patterns/tags, one at a time, against all
            #       lines (NB both sets of start patterns/tags are always checked first)
            analyseMode                 => 'check_line',
            # Flag set to FALSE if the Locator task should treat normal/bold standard colour tags
            #   interchangeably when using the IVs that follow (NB Setting this flag to FALSE makes
            #   the Locator task run a little faster)
            boldSensitiveFlag           => FALSE,
            # Flag set to TRUE if the Locator task should only use tags that applied at the
            #   beginning of the line, when it was displayed (because of tags at offset 0 on that
            #   line, or because of tags on earlier lines, depending on how the world sends its
            #   tags); set to FALSE if the Locator task should only use tags that were sent by the
            #   world on a particular line
            # NB If both ->useInitialTagsFlag and ->useExplicitTagsFlag are TRUE, then only tags
            #   explicity applied to the beginning of this line are used
            useInitialTagsFlag          => FALSE,
            # Flag set to TRUE if the Locator task should only use tags that were explicity applied
            #   to this line (i.e. because an escape sequence occured on this line); set to FALSE if
            #   the Locator Task should use tags that applied on any part of the line, including
            #   tags that appeared on previous lines and are still in effect
            # NB If both ->useInitialTagsFlag and ->useExplicitTagsFlag are TRUE, then only tags
            #   explicity applied to the beginning of this line are used
            useExplicitTagsFlag         => FALSE,
            # Flag set to TRUE if the Locator task should treat the lines of this component as a
            #   single string (good for worlds where, for example, an exit list is spread over more
            #   than one line); set to FALSE otherwise
            combineLinesFlag            => FALSE,

            # Option for worlds (like Achaea) which combine a room description and a contents list
            #   on the same line. If set to 'undef', the Locator task uses the whole line. If set
            #   to a standard/xterm/RGB colour tag, the task only uses text of that colour
            useTextColour               => undef,
            # Option for worlds (like BatMud, Discworld) which combine graphics (i.e. ASCII maps)
            #   and room statement on the same line. If set to 0, the Locator task uses the whole
            #   line. If set to a positive integer n, the task ignores the first n characters.
            #   Ignored if ->useTextColour is set
            # NB If ->combineLinesFlag is TRUE, only the first n characters of the combined line are
            #   ignored
            ignoreFirstChars            => 0,
            # Complementary option. If set to 0, the Locator task uses the whole line. If set to a
            #   positive integer n, the task ignores all characters after the first n characters.
            #   Ignored if ->useTextColour or ->ignoreFirstChars is set
            # NB If ->combineLinesFlag is TRUE, only the first n characters of the combined line are
            #   used
            useFirstChars               => 0,
            # Complementary option. Set to a regex. If the regex matches the line, only the
            #   contents of the group substrings are used (if there is more than one group
            #   substring, they are joined together as a single line of text).
            # If the regex doesn't match the line, or if this IV is undefined/an empty string, the
            #   whole line is used. Ignored if ->useTextColour, ->ignoreFirstChars or
            #   ->useFirstChars are set
            # NB If ->combineLinesFlag is TRUE, the pattern is matched against the combined line
            usePatternGroups            => undef,

            # A list of component types and/or names that the Locator task should NOT attempt to
            #   extract, IF this component can be successfully extracted (added for ZombieMUD, where
            #   two types of verbose description may be seen, each using the same format of exit
            #   list)
            # NB In case it's not clear, both component types (e.g. 'verb_descrip') and
            #   component names (e.g. 'verb_descrip_1') can be added to the list
            noExtractList               => [],

            # If ->size is 0, we use these IVs to find the extent of the component (if the component
            #   is before the anchor line, we count backwards and the 'start' line occurs after the
            #   'stop' line in the display buffer; otherwise, we count forwards, and the 'start'
            #   line occurs before the 'stop' line in the display buffer)
            # The Locator checks the IVs in the order they appear here
            # NB The IVs using Axmud colour/style tags can use any of the tags in
            #   GA::Client->constColourStyleList except the dummy style tags (like 'bold',
            #   'reverse_off' and 'attribs_off'), and can also use all xterm/RGB colour tags

            # Start at the first line which DOES include one of these patterns
            startPatternList            => [],
            # Start at the first line which DOES include one of these Axmud colour/style tags
            startTagList                => [],
            # Flag set to TRUE if all patterns/tags must be found in the line, in order for the
            #   line to be a start line (if any patterns/tags are specified), set to FALSE if only
            #   one pattern/tag needs to be found in the line, in order for the line to be a start
            #   line (if any patterns/tags are specified)
            startAllFlag                => FALSE,       # Any one pattern and/or tag must be found
            # Start at the first line which DOES match this mode: 'no_colour' - line contains no
            #   colour tags, 'no_style' - line contains no style tags (not including the dummy tags
            #   listed above), 'no_colour_style' - line contains no colour or style tags, 'default'
            #   - line may contain colour and/or style tags, depending on the contents of
            #   ->startTagList
            startTagMode                => 'default',

            # Start at the first line which DOES NOT include one of these patterns
            startNoPatternList          => [],
            # Start at the first line which DOES NOT include one of these Axmud colour/style tags
            startNoTagList              => [],
            # Flag set to TRUE if all patterns/tags must be found in the line, in order for the
            #   line to NOT be a start line (if any patterns/tags are specified), set to FALSE if
            #   only one pattern/tag needs to be found in the line, in order for the line to NOT be
            #   a start line (if any patterns/tags are specified)
            startNoAllFlag              => FALSE,       # Any one pattern and/or tag must be found
            # Start at the first line which DOES NOT match this mode: 'no_colour' - line contains no
            #   colour tags, 'no_style' - line contains no style tags (not including the dummy tags
            #   listed above), 'no_colour_style' - line contains no colour or style tags, 'default'
            #   - line may contain colour and/or style tags, depending on the contents of
            #   ->startNoTagList
            startNoTagMode              => 'default',

            # Skip the first line which DOES include one of these patterns
            # NB ->startPatternList and ->startNoPatternList (etc) are consulted before
            #   ->skipPatternList (etc), so a first line matching start patterns/tags cannot be
            #   skipped
            skipPatternList             => [],
            # Skip the first line which DOES include one of these Axmud colour/style tags
            skipTagList                 => [],
            # Flag set to TRUE if all patterns/tags must be found in the line, in order for the
            #   line to be skipped (if any patterns/tags are specified), set to FALSE if only one
            #   pattern/tag needs to be found in the line, in order for the line to be skipped
            #   (if any patterns/tags are specified)
            skipAllFlag                 => FALSE,       # Any one pattern and/or tag must be found
            # Skip the first line which DOES match this mode: 'no_colour' - line contains no
            #   colour tags, 'no_style' - line contains no style tags (not including the dummy tags
            #   listed above), 'no_colour_style' - line contains no colour or style tags, 'default'
            #   - line may contain colour and/or style tags, depending on the contents of
            #   ->skipTagList
            skipTagMode                 => 'default',

            # Stop before the first line which DOES include one of these patterns
            stopBeforePatternList       => [],
            # Stop before the first line which DOES include one of these Axmud colour/style tags
            stopBeforeTagList           => [],
            # Flag set to TRUE if all patterns/tags must be found in the line, in order for the
            #   line to be a stop-before line (if any patterns/tags are specified), set to FALSE if
            #   only one pattern/tag needs to be found in the line, in order for the line to be a
            #   stop-before line (if any patterns/tags are specified)
            stopBeforeAllFlag           => FALSE,       # Any one pattern and/or tag must be found
            # Stop before the first line which DOES match this mode: 'no_colour' - line contains no
            #   colour tags, 'no_style' - line contains no style tags (not including the dummy tags
            #   listed above), 'no_colour_style' - line contains no colour or style tags, 'default'
            #   - line may contain colour and/or style tags, depending on the contents of
            #   ->stopBeforeTagList
            stopBeforeTagMode           => 'default',

            # Stop before the first line which DOES NOT include one of these patterns
            stopBeforeNoPatternList     => [],
            # Stop before the first line which DOES NOT include one of these Axmud colour/style tags
            stopBeforeNoTagList         => [],
            # Flag set to TRUE if all patterns/tags must be found in the line, in order for the
            #   line to NOT be a stop-before line (if any patterns/tags are specified), set to FALSE
            #   if only one pattern/tag needs to be found in the line, in order for the line to NOT
            #   be a stop-before line (if any patterns/tags are specified)
            stopBeforeNoAllFlag         => FALSE,       # Any one pattern and/or tag must be found
            # Stop before the first line which DOES NOT match this mode: 'no_colour' - line contains
            #   no colour tags, 'no_style' - line contains no style tags (not including the dummy
            #   tags listed above), 'no_colour_style' - line contains no colour or style tags,
            #   'default' - line may contain colour and/or style tags, depending on the contents of
            #   ->stopBeforeNoTagList
            stopBeforeNoTagMode         => 'default',

            # Stop at the first line which DOES include one of these patterns
            stopAtPatternList           => [],
            # Stop at the first line which DOES include one of these Axmud colour/style tags
            stopAtTagList               => [],
            # Flag set to TRUE if all patterns/tags must be found in the line, in order for the
            #   line to be a stop-at line (if any patterns/tags are specified), set to FALSE if only
            #   one pattern/tag needs to be found in the line, in order for the line to be a stop-at
            #   line (if any patterns/tags are specified)
            stopAtAllFlag               => FALSE,       # Any one pattern and/or tag must be found
            # Stop at the first line which DOES match this mode: 'no_colour' - line contains no
            #   colour tags, 'no_style' - line contains no style tags (not including the dummy tags
            #   listed above), 'no_colour_style' - line contains no colour or style tags, 'default'
            #   - line may contain colour and/or style tags, depending on the contents of
            #   ->stopAtTagList
            stopAtTagMode               => 'default',

            # Stop at the first line which DOES NOT include one of these patterns
            stopAtNoPatternList         => [],
            # Stop at the first line which DOES NOT include one of these Axmud colour/style tags
            stopAtNoTagList             => [],
            # Flag set to TRUE if all patterns/tags must be found in the line, in order for the
            #   line to NOT be a stop-at line (if any patterns/tags are specified), set to FALSE if
            #   only one pattern/tag needs to be found in the line, in order for the line to NOT be
            #   a stop-at line (if any patterns/tags are specified)
            stopAtNoAllFlag             => FALSE,       # Any one pattern and/or tag must be found
            # Stop at the first line which DOES NOT match this mode: 'no_colour' - line contains no
            #   colour tags, 'no_style' - line contains no style tags (not including the dummy tags
            #   listed above), 'no_colour_style' - line contains no colour or style tags, 'default'
            #   - line may contain colour and/or style tags, depending on the contents of
            #   ->stopAtNoTagList
            stopAtNoTagMode             => 'default',

            # Stop at the nth line which starts with a capital letter. If 0, we don't check
            #   upper-case letters
            upperCount                  => 0,
            # Stop at the nth line which does starts with any alphanumeric character that's not a
            #   capital letter. If 0, we don't check these characters
            otherCount                  => 0,
            # Stop before/at a certain line:
            #   'no_char' - stop one line before/at the first line containing no characters at all
            #   'no_letter_num' - stop one line before/at the first line containing no alphanumeric
            #       characters
            #   'no_start_letter_num' - stop one line before/at the first line which doesn't start
            #       with an alphanumeric character
            #   'no_tag' - stop one line before/at the first line containing no Axmud colour/style
            #       tags at all (not including the dummy style tags like 'bold', 'reverse_off' and
            #       'attribs_off')
            #   'has_letter_num' - stop one line before/at the first line which DOES contain
            #       alphanumeric characters
            #   'has_start_letter_num' - stop one line before/at the first line which DOES start
            #       with an alphanumeric character
            #   'has_tag' - stop one line before/at the first line which DOES contain an Axmud
            #       colour/style tag (not including the dummy style tags like 'bold', 'reverse_off'
            #       and 'attribs_off')
            #   'default' - ignore this IV
            stopBeforeMode              => 'default',
            stopAtMode                  => 'default',
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    sub clone {

        # Creates a clone of an existing room statement component object
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $worldObj   - The world profile object to which the new component will belong
        #   $name       - Unique name for this component (can match the component type) (max
        #                   16 chars)
        #   $type       - One of 'ignore_line', 'verb_title', 'verb_descrip', 'verb_exit',
        #                   'verb_content', 'verb_special', 'brief_title', 'brief_exit',
        #                   'brief_title_exit', 'brief_exit_title', 'brief_content', 'room_cmd',
        #                   'mudlib_path', 'custom'
        #
        # Return values
        #   'undef' on improper arguments, or if $name or $type are invalid
        #   Blessed reference to the newly-created object on success

        my ($self, $session, $worldObj, $name, $type, $check) = @_;

        # Local variables
        my $matchFlag;

        # Check for improper arguments
        if (
            ! defined $session || ! defined $worldObj || ! defined $name || ! defined $type
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Check that $name is valid and not already in use by another component
        if (! $axmud::CLIENT->nameCheck($name, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $self->_objClass . '->clone',
            );

        } elsif ($worldObj->ivExists('componentHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: profile \'' . $worldObj->name . '\' already has a component'
                . ' called \'' . $name . '\'',
                $self->_objClass . '->clone',
            );
        }

        # Check $type is valid
        OUTER: foreach my $standardType ($axmud::CLIENT->constComponentTypeList) {

            if ($type eq $standardType) {

                $matchFlag = TRUE;
                last OUTER;
            }
        }

        if (! $matchFlag) {

            return $session->writeError(
                'Invalid room statement component type \'' . $type . '\'',
                $self->_objClass . '->clone',
            );
        }

        # Setup
        my $clone = {
            _objName                    => $name,
            _objClass                   => $self->_objClass,
            _parentFile                 => $worldObj->name,
            _parentWorld                => undef,
            _privFlag                   => FALSE,           # All IVs are public

            # Object IVs
            # ----------

            name                        => $name,
            type                        => $type,

            size                        => $self->size,
            minSize                     => $self->minSize,
            maxSize                     => $self->maxSize,
            analyseMode                 => $self->analyseMode,
            boldSensitiveFlag           => $self->boldSensitiveFlag,
            useInitialTagsFlag          => $self->useInitialTagsFlag,
            useExplicitTagsFlag         => $self->useExplicitTagsFlag,
            combineLinesFlag            => $self->combineLinesFlag,

            useTextColour               => $self->useTextColour,
            ignoreFirstChars            => $self->ignoreFirstChars,
            useFirstChars               => $self->useFirstChars,
            usePatternGroups            => $self->usePatternGroups,

            noExtractList               => [$self->noExtractList],

            startPatternList            => [$self->startPatternList],
            startTagList                => [$self->startTagList],
            startAllFlag                => $self->startAllFlag,
            startTagMode                => $self->startTagMode,

            startNoPatternList          => [$self->startNoPatternList],
            startNoTagList              => [$self->startNoTagList],
            startNoAllFlag              => $self->startNoAllFlag,
            startNoTagMode              => $self->startNoTagMode,

            skipPatternList             => [$self->skipPatternList],
            skipTagList                 => [$self->skipTagList],
            skipAllFlag                 => $self->skipAllFlag,
            skipTagMode                 => $self->skipTagMode,

            stopBeforePatternList       => [$self->stopBeforePatternList],
            stopBeforeTagList           => [$self->stopBeforeTagList],
            stopBeforeAllFlag           => $self->stopBeforeAllFlag,
            stopBeforeTagMode           => $self->stopBeforeTagMode,

            stopBeforeNoPatternList     => [$self->stopBeforeNoPatternList],
            stopBeforeNoTagList         => [$self->stopBeforeNoTagList],
            stopBeforeNoAllFlag         => $self->stopBeforeNoAllFlag,
            stopBeforeNoTagMode         => $self->stopBeforeNoTagMode,

            stopAtPatternList           => [$self->stopAtPatternList],
            stopAtTagList               => [$self->stopAtTagList],
            stopAtAllFlag               => $self->stopAtAllFlag,
            stopAtTagMode               => $self->stopAtTagMode,

            stopAtNoPatternList         => [$self->stopAtNoPatternList],
            stopAtNoTagList             => [$self->stopAtNoTagList],
            stopAtNoAllFlag             => $self->stopAtNoAllFlag,
            stopAtNoTagMode             => $self->stopAtNoTagMode,

            upperCount                  => $self->upperCount,
            otherCount                  => $self->otherCount,
            stopBeforeMode              => $self->stopBeforeMode,
            stopAtMode                  => $self->stopAtMode,
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
    sub type
        { $_[0]->{type} }

    sub size
        { $_[0]->{size} }
    sub minSize
        { $_[0]->{minSize} }
    sub maxSize
        { $_[0]->{maxSize} }
    sub analyseMode
        { $_[0]->{analyseMode} }
    sub boldSensitiveFlag
        { $_[0]->{boldSensitiveFlag} }
    sub useInitialTagsFlag
        { $_[0]->{useInitialTagsFlag} }
    sub useExplicitTagsFlag
        { $_[0]->{useExplicitTagsFlag} }
    sub combineLinesFlag
        { $_[0]->{combineLinesFlag} }

    sub useTextColour
        { $_[0]->{useTextColour} }
    sub ignoreFirstChars
        { $_[0]->{ignoreFirstChars} }
    sub useFirstChars
        { $_[0]->{useFirstChars} }
    sub usePatternGroups
        { $_[0]->{usePatternGroups} }

    sub noExtractList
        { my $self = shift; return @{$self->{noExtractList}}; }

    sub startPatternList
        { my $self = shift; return @{$self->{startPatternList}}; }
    sub startTagList
        { my $self = shift; return @{$self->{startTagList}}; }
    sub startAllFlag
        { $_[0]->{startAllFlag} }
    sub startTagMode
        { $_[0]->{startTagMode} }

    sub startNoPatternList
        { my $self = shift; return @{$self->{startNoPatternList}}; }
    sub startNoTagList
        { my $self = shift; return @{$self->{startNoTagList}}; }
    sub startNoAllFlag
        { $_[0]->{startNoAllFlag} }
    sub startNoTagMode
        { $_[0]->{startNoTagMode} }

    sub skipPatternList
        { my $self = shift; return @{$self->{skipPatternList}}; }
    sub skipTagList
        { my $self = shift; return @{$self->{skipTagList}}; }
    sub skipAllFlag
        { $_[0]->{skipAllFlag} }
    sub skipTagMode
        { $_[0]->{skipTagMode} }

    sub stopBeforePatternList
        { my $self = shift; return @{$self->{stopBeforePatternList}}; }
    sub stopBeforeTagList
        { my $self = shift; return @{$self->{stopBeforeTagList}}; }
    sub stopBeforeAllFlag
        { $_[0]->{stopBeforeAllFlag} }
    sub stopBeforeTagMode
        { $_[0]->{stopBeforeTagMode} }

    sub stopBeforeNoPatternList
        { my $self = shift; return @{$self->{stopBeforeNoPatternList}}; }
    sub stopBeforeNoTagList
        { my $self = shift; return @{$self->{stopBeforeNoTagList}}; }
    sub stopBeforeNoAllFlag
        { $_[0]->{stopBeforeNoAllFlag} }
    sub stopBeforeNoTagMode
        { $_[0]->{stopBeforeNoTagMode} }

    sub stopAtPatternList
        { my $self = shift; return @{$self->{stopAtPatternList}}; }
    sub stopAtTagList
        { my $self = shift; return @{$self->{stopAtTagList}}; }
    sub stopAtAllFlag
        { $_[0]->{stopAtAllFlag} }
    sub stopAtTagMode
        { $_[0]->{stopAtTagMode} }

    sub stopAtNoPatternList
        { my $self = shift; return @{$self->{stopAtNoPatternList}}; }
    sub stopAtNoTagList
        { my $self = shift; return @{$self->{stopAtNoTagList}}; }
    sub stopAtNoAllFlag
        { $_[0]->{stopAtNoAllFlag} }
    sub stopAtNoTagMode
        { $_[0]->{stopAtNoTagMode} }

    sub upperCount
        { $_[0]->{upperCount} }
    sub otherCount
        { $_[0]->{otherCount} }
    sub stopBeforeMode
        { $_[0]->{stopBeforeMode} }
    sub stopAtMode
        { $_[0]->{stopAtMode} }
}

# Package must return a true value
1
