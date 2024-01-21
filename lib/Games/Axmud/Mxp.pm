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
# Games::Axmud::Mxp::xxx
# Objects for use during MXP-enabled sessions

{ package Games::Axmud::Mxp::Dest;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Session->processMxpDestElement
        # Creates a new instance of the MXP destination object (which temporarily stores text tokens
        #   inside a <DEST>...</DEST> construction, which are sent to the specified frame when the
        #   construction is terminated
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $name       - The name of the frame to which text tokens inside the <DEST>...</DEST>
        #                   construction will be sent
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
            _parentFile                 => $session->currentWorld->name,
            _parentWorld                => undef,
            _privFlag                   => FALSE,        # All IVs are public

            # IVs
            # ---

            # The name of the frame to which text tokens inside the <DEST>...</DEST> construction
            #   will be sent
            name                        => $name,

            # The position in the frame at which the text will be inserted. 'undef' if not
            #   specified by the world
            xPos                        => undef,
            yPos                        => undef,
            # Flag set to TRUE if the EOF keyword was specified (after displaying the text, erase
            #   the rest of the text)
            eofFlag                     => FALSE,
            # Flag set to TRUE if the EOL keyword was specified (erase the current or specified
            #   line)
            eolFlag                     => FALSE,

            # When the <DEST> tag is processed, the name of the frame that was being used to display
            #   text received from the world (set to the contents of the GA::Session IVs at that
            #   moment)
            mxpCurrentFrame             => undef,
            mxpPrevFrame                => undef,
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

    sub name
        { $_[0]->{name} }

    sub xPos
        { $_[0]->{xPos} }
    sub yPos
        { $_[0]->{yPos} }
    sub eofFlag
        { $_[0]->{eofFlag} }
    sub eolFlag
        { $_[0]->{eolFlag} }

    sub mxpCurrentFrame
        { $_[0]->{mxpCurrentFrame} }
    sub mxpPrevFrame
        { $_[0]->{mxpPrevFrame} }
}

{ package Games::Axmud::Mxp::Element;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Session->processMxpElement
        # Creates a new instance of the MXP element object
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $name       - A unique string name for this MXP element (we'll assume that it has
        #                   already been checked for validity; should be lower case)
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
            _parentFile                 => $session->currentWorld->name,
            _parentWorld                => undef,
            _privFlag                   => FALSE,        # All IVs are public

            # IVs
            # ---

            # The (unique) element name
            name                        => $name,
            # The element definition (A string comprising certain MXP tags, possibly separated by
            #   whitespace; 'undef' if not set)
            defnArg                     => undef,
            # A list of tags in ->defnArg (if set), in the order they were first specified; e.g.
            #   if ->defnArg is '<COLOR red><B>', then the list is ('<COLOUR red>', '<B>')
            defnList                    => [],

            # The attribute list (a string), ATT=... ('undef' if not set)
            # NB If attributes are modified with an <!ATTLIST> tag, this IV is not updated
            attArg                      => undef,
            # An ordered list of attribute names, in the order in which they were declared
            attList                     => [],
            # A hash of attributes and their values, in the form
            #   $attHash{attribute_name} = default_value
            # ...where 'default_value' is an empty string if the attribute has no default value
            attHash                     => {},

            # The user-defined line tag, TAG=... ('undef' if not set)
            tagArg                      => undef,
            # The flag argument, FLAG=... ('undef' if not set)
            flagArg                     => undef,
            # The open argument, OPEN (set to FALSE for 'secure' tags, TRUE for 'open' tags;
            #   elements are secure by default)
            openFlag                    => FALSE,
            # The empty argument, EMPTY (set to FALSE or TRUE)
            emptyFlag                   => FALSE,
        };

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub setDefn {

        # Called by GA::Session->processMxpElement, when processing an element in the form
        #   <!ELEMENT element_name [definition] ... >
        # If [definition] is specified, it is stored in this object in 2 IVs. This function handles
        #   the setting of those IVs
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $defnArg    - The definition argument, e.g. '<COLOR RED><B>'
        #
        # Return values
        #   'undef' on improper arguments or if $defnArg contains characters outside <...> tags
        #   1 otherwise

        my ($self, $session, $defnArg, $check) = @_;

        # Local variables
        my (
            $origDefnArg,
            @defnList,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $defnArg || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setDefn', @_);
        }

        # $defnArg should consist of one or more <...> tags, possibly separated by whitespace
        # Extract each tag in turn
        $origDefnArg = $defnArg;
        do {

            my ($posn, $token, $element);

            $posn = index($defnArg, '<');
            if ($posn == -1) {

                # Unexpected text in the macro expansion (i.e. not inside <...>)
                return undef;

            } else {

                $token = $session->extractMxpPuebloElement(substr($defnArg, $posn));
                if (! defined $token || $token eq '') {

                    # Invalid element
                    return undef;

                } else {

                    # Remove the <...> tag from $defnArg
                    $element = substr($defnArg, $posn, length($token));
                    push (@defnList, $element);

                    substr($defnArg, $posn, length($token), '');
                }
            }

            # Trim leading and trailing whitespace, allowing $defnArg to be an empty string if we've
            #   removed all elements
            $defnArg = $axmud::CLIENT->trimWhitespace($defnArg);

        } until (! $defnArg);

        # Update IVs
        $self->ivPoke('defnArg', $origDefnArg);
        $self->ivPoke('defnList', @defnList);

        return 1;
    }

    sub setAttList {

        # Called by GA::Session->processMxpElement, when processing an element in the form
        #   <!ELEMENT element_name [ATT=attribute_list] ... >
        #
        # If [ATT=attribute_list] is specified, it is stored in this object in 2 IVs. This function
        #   handles the setting of those IVs
        #
        # Expected arguments
        #   $session    - The calling function's GA::Session
        #   $attListArg - The attribute list (a string), e.g. 'col=red',
        #                   'color=red background=white flags'
        #
        # Return values
        #   'undef' on improper arguments or if the attribute list is invalid (i.e. malformed)
        #   1 otherwise

        my ($self, $session, $attListArg, $check) = @_;

        # Local variables
        my (
            $string,
            @newList,
            %newHash,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $attListArg || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setAttList', @_);
        }

        # Items can be in the form 'name=value', where 'value' is the attribute's default value, or
        #   in the form 'name', for attributes with no default value
        # Each argument can be single-quote or double-quoted; if not, the attribute value can be
        #   single quoted or double quoted (following the usual MXP rules)
        $string = $attListArg;
        do {

            my ($attName, $attValue);

            ($string, $attName, $attValue) = $session->extractMxpArgument($string);
            if (! defined $string) {

                # Invalid argument
                return undef;

            } else {

                # If the argument is not in the form 'argument_name=argument_value', then the
                #   attribute's default value is an empty string
                if (! defined $attValue) {

                    $attValue = '';
                }

                push (@newList, $attName);
                $newHash{$attName} = $attValue;

                # There must be whitepsace between this argument, and the next one (if any)
                if ($string && $string =~ m/^\S/) {

                    return undef;
                }
            }

        } until (! $string);

        # Attributes extracted; update IVs
        $self->ivPoke('attArg', $attListArg);
        $self->ivPoke('attList', @newList);
        $self->ivPoke('attHash', %newHash);

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }
    sub defnArg
        { $_[0]->{defnArg} }
    sub defnList
        { my $self = shift; return @{$self->{defnList}}; }

    sub attArg
        { $_[0]->{attArg} }
    sub attList
        { my $self = shift; return @{$self->{attList}}; }
    sub attHash
        { my $self = shift; return %{$self->{attHash}}; }

    sub tagArg
        { $_[0]->{tagArg} }
    sub flagArg
        { $_[0]->{flagArg} }
    sub openFlag
        { $_[0]->{openFlag} }
    sub emptyFlag
        { $_[0]->{emptyFlag} }
}

{ package Games::Axmud::Mxp::Entity;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Session->processMxpElement
        # Creates a new instance of the MXP entity object
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $name       - A unique string name for this MXP entity (unlike element names, entity
        #                   names are case-sensitive)
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
            _parentFile                 => $session->currentWorld->name,
            _parentWorld                => undef,
            _privFlag                   => FALSE,        # All IVs are public

            # IVs
            # ---

            # The (unique) entity name
            name                        => $name,
            # The entity's value (a string, set to 'undef' until the <!ELEMENT> tag has been
            #   processed)
            value                       => undef,

            # The description string, DESC=... ('undef' if not set)
            descArg                     => undef,
            # The private argument, PRIVATE (set to FALSE or TRUE)
            privateFlag                 => FALSE,
            # The publish argument, PUBLISH (set to FALSE or TRUE)
            publishFlag                 => FALSE,
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

    sub name
        { $_[0]->{name} }
    sub value
        { $_[0]->{value} }

    sub descArg
        { $_[0]->{descArg} }
    sub privateFlag
        { $_[0]->{privateFlag} }
    sub publishFlag
        { $_[0]->{publishFlag} }
}

{ package Games::Axmud::Mxp::Filter;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Session->processMxpFilterElement
        # Creates a new instance of the MXP file filter object
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $src        - The source file extension, e.g. 'gff'
        #   $dest       - The destination file extension, after the image/sound file is converted
        #                   to a file type that Axmud supports, e.g. 'gif'
        #   $name       - The name of the plugin which contains the conversion code
        #   $proc       - An optional numerical parameter used to support multiple conversions, as
        #                   needed (see the MXP spec). Default value is 0
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $src, $dest, $name, $proc, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $src || ! defined $dest
            || ! defined $name || ! defined $proc || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => $session->currentWorld->name,
            _parentWorld                => undef,
            _privFlag                   => FALSE,        # All IVs are public

            # IVs
            # ---

            # The source file extension, e.g. 'gff'
            src                         => $src,
            # The destination file extension, after the image/sound file is converted to a file type
            #   that Axmud supports, e.g. 'gif'
            dest                        => $dest,
            # The name of the plugin which contains the conversion code
            name                        => $name,
            # An optional numerical parameter used to support multiple conversions, as needed (see
            #   the MXP spec). Default value is 0
            proc                        => $proc,
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

    sub src
        { $_[0]->{src} }
    sub dest
        { $_[0]->{dest} }
    sub name
        { $_[0]->{name} }
    sub proc
        { $_[0]->{proc} }
}

{ package Games::Axmud::Mxp::Frame;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Session->processMxpFrameElement
        # Creates a new instance of the MXP frame object
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $name       - A unique string name for this MXP frame (the MXP spec doesn't say if it's
        #                   case-sensitive or not, so Axmud will treat them as case-senstitive)
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
            _parentFile                 => $session->currentWorld->name,
            _parentWorld                => undef,
            _privFlag                   => FALSE,        # All IVs are public

            # IVs
            # ---

            # The (unique) frame name (the MXP spec doesn't say if it's case-sensitive or not, so
            #   Axmud will treat them as case-sensitive)
            name                        => $name,
            # The frame title. If set to 'undef' (default), $self->name is used as the frame title
            title                       => undef,

            # MXP frames are implemented as pane objects (either inside the session's 'main' window,
            #   or inside a Frame task window)
            # The pane object for this frame
            paneObj                     => undef,
            # In case the pane has multiple tabs (unlikely, but possible), the tab used by this
            #   frame (a tab object, GA::Obj::Tab)
            tabObj                      => undef,
            # The textview object for this tab
            textViewObj                 => undef,

            # Flag set to TRUE if the frame is internal to the current MUD window (for Axmud, always
            #   the 'main' window); set to FALSE if a floating frame must be created (using the
            #   Frame task)
            internalFlag                => FALSE,
            # If ->internalFlag is TRUE, the alignment of the frame in the 'main' window - should be
            #   'left', 'right', 'bottom' or 'top' (default)
            align                       => 'top',

            # If ->internalFlag is FALSE, the Frame task object whose task window is used for this
            #   frame ('undef' if ->internalFlag is TRUE)
            taskObj                     => undef,
            # If ->internalFlag is FALSE, the position of the Frame task window (ignored if
            #   ->internalFlag is TRUE)
            # The coordinate of the left side of the frame - a percentage (ends in %), a number of
            #   character widths (ends in c) or a number of pixels. If a negative number is used,
            #   the value is relative to the right side of the screen, rather than the left. The
            #   character spacing uses the width of the character X.
            left                        => 0,
            # The coordinate of the top of the frame. Same syntax as for ->left. If a negative
            #   number is used, the value is relative to the bottom of the screen, rather than the
            #   right. The character spacing uses the height of the character X.
            top                         => 0,
            # The width of the frame. Same syntax as for ->left. A percentage refers to the
            #   percentage of the screen width. The MXP spec doesn't give a default value, so we'll
            #   use our own.
            width                       => '50%',
            # The height of the frame. Same syntax as for ->top. A percentage refers to the
            #   percentage of the screen height.
            height                      => '50%',

            # Flag set to TRUE if the frame is allowed to scroll; set to FALSE (default) if the
            #   frame isn't allowed to scroll
            scrollingFlag               => FALSE,
            # Flag set to TRUE if the frame is forced to 'stay on top' of the 'main' window. Ignored
            #   if ->internalFlag is TRUE
            floatingFlag                => FALSE,
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

    sub name
        { $_[0]->{name} }
    sub title
        { $_[0]->{title} }

    sub paneObj
        { $_[0]->{paneObj} }
    sub tabObj
        { $_[0]->{tabObj} }
    sub textViewObj
        { $_[0]->{textViewObj} }

    sub internalFlag
        { $_[0]->{internalFlag} }
    sub align
        { $_[0]->{align} }

    sub taskObj
        { $_[0]->{taskObj} }
    sub left
        { $_[0]->{left} }
    sub top
        { $_[0]->{top} }
    sub width
        { $_[0]->{width} }
    sub height
        { $_[0]->{height} }

    sub scrollingFlag
        { $_[0]->{scrollingFlag} }
    sub floatingFlag
        { $_[0]->{floatingFlag} }
}

{ package Games::Axmud::Mxp::StackObj;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Obj::TextView->createMxpStackObj
        # Creates a new instance of the MXP stack object, which stores the current state of the
        #   textview object's ->mxpModalStackHash, just before it is updated
        # Storing old copies of the hash allowing text attributes (colours, fonts etc) to be nested
        #
        # Expected arguments
        #   $session    - The calling GA::Session (not stored as an IV)
        #   $keyword    - The keyword of the corresponding MXP tag, e.g. 'B', 'FONT', etc
        #
        # Optional arguments
        #   %stackHash  - A copy of the calling textview object's ->->mxpModalStackHash (may be an
        #                   empty hash)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $keyword, %stackHash) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $session || ! defined $keyword) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => $keyword,
            _objClass                   => $class,
            _parentFile                 => $session->currentWorld->name,
            _parentWorld                => undef,
            _privFlag                   => FALSE,        # All IVs are public

            # IVs
            # ---

            # The keyword of the corresponding MXP tag, e.g. 'B', 'FONT', etc
            keyword                     => $keyword,
            # A copy of GA::Obj::TextViewObj->mxpModalStackHash, at the time the MXP tag was
            #   encountered
            stackHash                   => {%stackHash},
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

    sub keyword
        { $_[0]->{keyword} }
    sub stackHash
        { my $self = shift; return %{$self->{stackHash}}; }
}

{ package Games::Axmud::Mxp::Var;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Session->processMxpElement
        # Creates a new instance of the MXP variable object (which temporarily stores arguments
        #   in a <V>...</V> construction, until the code is ready to modify the GA::Mxp::Entity
        #   object, at which time this object's IVs are copied to the entity object)
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $name       - The name of the entity object which this <V>...</V> construction will
        #                   modify
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
            _parentFile                 => $session->currentWorld->name,
            _parentWorld                => undef,
            _privFlag                   => FALSE,        # All IVs are public

            # IVs
            # ---

            # The name of the corresponding GA::Mxp::Entity object
            name                        => $name,
            # Accumulated text tokens between matching <V>...</V> tags
            value                       => '',

            # Optional arguments from the <V...> tag
            # The description string, DESC=... ('undef' if not set)
            descArg                     => undef,
            # The private argument, PRIVATE (set to FALSE or TRUE)
            privateFlag                 => FALSE,
            # The publish argument, PUBLISH (set to FALSE or TRUE)
            publishFlag                 => FALSE,
            # The delete argument, DELETE (set to FALSE or TRUE)
            deleteFlag                  => FALSE,
            # The add argument, ADD (set to FALSE or TRUE)
            addFlag                     => FALSE,
            # The remove argument, REMOVE (set to FALSE or TRUE)
            removeFlag                  => FALSE,
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

    sub name
        { $_[0]->{name} }
    sub value
        { $_[0]->{value} }

    sub descArg
        { $_[0]->{descArg} }
    sub privateFlag
        { $_[0]->{privateFlag} }
    sub publishFlag
        { $_[0]->{publishFlag} }
    sub deleteFlag
        { $_[0]->{deleteFlag} }
    sub addFlag
        { $_[0]->{addFlag} }
    sub removeFlag
        { $_[0]->{removeFlag} }
}

# Package must return a true value
1
