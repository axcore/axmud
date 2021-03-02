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
# Games::Axmud::Obj::TextView
# A textview object, which handles a single Gtk3::TextView

{ package Games::Axmud::Obj::TextView;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Obj::Desktop->add_textview()
        # Creates a textview object, which handles a single Gtk3::TextView (or, in split screen
        #   mode, two textviews sharing a single Gtk3::TextBuffer)
        #
        # Expected arguments
        #   $session    - The GA::Session which controls this textview
        #   $number     - Unique number for this textview object across all sessions (matches
        #                   GA::Obj::Desktop->textViewCount)
        #   $winObj     - The window object (inheriting from GA::Generic::Win) in which this
        #                   object's textview(s) are displayed
        #
        # Optional aguments
        #   $paneObj    - For textview objects that will be added to the Gtk3::Grid in an 'internal'
        #                   window (specifically, added directly to a GA::Strip::Table object), that
        #                   GA::Strip::Table object. Set to 'undef' for a textview object created
        #                   for any other reason
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $number, $winObj, $paneObj, $check) = @_;

        # Local variables
        my %colourStyleHash;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $session || ! defined $number || ! defined $winObj
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Import constant hash with inintial values we need
        %colourStyleHash = $axmud::CLIENT->constColourStyleHash;

        # Setup
        my $self = {
            _objName                    => 'textview_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # IVs
            # ---

            # The GA::Session which controls this textview
            session                     => $session,
            # Unique number for this textview object across all sessions (matches
            #   GA::Obj::Desktop->textViewCount)
            number                      => $number,
            # The window object (inheriting from GA::Generic::Win) in which this object's
            #   textview(s) are displayed
            winObj                      => $winObj,
            # For textview objects that will be added to the Gtk3::Grid in an 'internal' window
            #   (specifically, added directly to a GA::Strip::Table object), that
            #   GA::Strip::Table object. Set to 'undef' for a textview object created for any
            #   other reason
            paneObj                     => $paneObj,

            # Widgets
            textView                    => undef,           # Gtk3::TextView
            textView2                   => undef,           # Gtk3::TextView
            buffer                      => undef,           # Gtk3::TextBuffer
            vPaned                      => undef,           # Gtk3::VPaned
            scroll                      => undef,           # Gtk3::ScrolledWindow
            scroll2                     => undef,           # Gtk3::ScrolledWindow
            startMark                   => undef,           # Gtk3::TextMark
            endMark                     => undef,           # Gtk3::TextMark
            searchMark                  => undef,           # Gtk3::TextMark
            popupMenu                   => undef,           # Gtk3::Menu

            # Other IVs

            # Flag set to TRUE when the scroll lock is enabled, FALSE when it is disabled (only
            #   applies to the original Gtk3::TextView)
            scrollLockFlag              => TRUE,
            # What type of scroll lock to apply - 'top' if the original textview should remain
            #   scrolled to the top, 'bottom' if it should remain scrolled to the bottom
            scrollLockType              => 'bottom',
            # Split screen mode. Because of performance issues with very large Gtk3::TextBuffers,
            #   if the user is likely to want a split screen (with two Gtk3::TextView, separated by
            #   a divider and sharing the same Gtk3::TextBuffer), it's usually better to create both
            #   Gtk3::TextViews when this textview object is created, rather than starting with a
            #   single textview and creating (or destroying) the second one as need be
            # This IV is set to the current split screen mode, and is updated whenever the mode is
            #   changed via calls to $self->setSplitScreenMode:
            #       'single'    - Only one Gtk3::TextView
            #       'split'     - Two Gtk3::TextViews with a divider between them, positioned so
            #                       they are both visible
            #       'hidden'    - Two Gtk3::TextViews with a divider between them, positioned at the
            #                       top of the screen so the second textview is invisible (and the
            #                       divider itself is almost invisible); however, the user is free
            #                       to move it manually, and when they do so, the IV remains set to
            #                       'hidden')
            splitScreenMode             => 'single',

            # The colour scheme applied to this textview object (matches a key in
            #   GA::Client->colourSchemeHash)
            # To apply a colour scheme, the textview object must not be called directly; instead,
            #   call $self->paneObj->updateColourScheme, ->applyColourScheme, ->applyMonochrome or
            #   ->removeMonochrome
            colourScheme                => undef,
            # The text colours
            textColour                  => undef,
            underlayColour              => undef,
            backgroundColour            => undef,
            # The font and fontsize
            font                        => undef,
            fontSize                    => undef,
            # Some parts of the code (for example the Status task) want to use a textview with only
            #   two colours - text and background. This is called 'monochrome mode'
            # Set to TRUE on the first call to $self->setMonochromeMode which changes the textview's
            #   background colour to a specified colour, and chooses suitable text/underlay colours
            #   (for example, specify 'blue' for white text on a blue background). The colours can
            #   be changed any time with further calls to ->setMonochromeMode
            # When TRUE, calls to ->insertText and ->showSystemText ignore any Axmud colour tags
            #   that are specified (but not Axmud style tags, which are processed as usual). Calls
            #   to ->insertCmd, ->showError, ->showWarning, ->showDebug, ->showImproper do not use
            #   their normal text colours
            # When TRUE, the colour scheme only changes on calls to ->setMonochromeMode. It doesn't
            #   change when a new colour scheme is applied (via a call to $self->objUpdate, itself
            #   called by GA::Table::Pane->applyColourScheme)
            # Set back to FALSE by a call to $self->resetMonochromeMode, at which point the colour
            #   scheme stored in $self->colourScheme is applied (it might have changed since this
            #   flag was first set to TRUE)
            monochromeFlag              => FALSE,
            # In monochrome mode, we need to know when the colours used are the same as those
            #   specified by the colour scheme, and when they're different (because if the colour
            #   scheme's colours change, by the time $self->objUpdate is called, there is no way
            #   of comparing the colour scheme's previous colours to the colours currently used in
            #   this textview)
            # Flag set whenever ->monochromeFlag is set to TRUE (and reset if ->monochromeFlag is
            #   set to FALSE)
            # When ->setMonochromeMode is called, this flag checks the textview's current
            #   background colour against the background specified by the colour scheme (we don't
            #   check the text colour, because it's normally set automatically to match the
            #   background)
            # If the background colours are different, this flag is set to TRUE. If they're the
            #   same, this flag is set to FALSE
            # When ->resetMonochromeMode is called, this flag is set back to FALSE
            monochromeModFlag           => FALSE,
            # Ovewrite mode. The default value is FALSE, in which calls to $self->insertText (etc)
            #   and ->insertCmd insert text at the end of the Gtk3::TextBuffer (or very near the
            #   end, if system messages are visible on the final lines)
            # Any code that uses cursor control to overwrite existing lines will call
            #   $self->setInsertPosn, ->adjustInsertPosn, ->adjustInsertLine, ->adjustInsertOffset
            #   or ->restoreInsertPosn
            # Calls to any of these functions turn on ovewrite mode, which sets the flag to TRUE.
            #   (Overwite mode can also be turned on via a call to $self->enableOverwrite(), or by
            #   specifying an optional argument in calls to $self->clearBufferAfterPosn,
            #   ->storeInsertPosn, etc
            # Once turned on, overwrite mode should not be turned off unless a connection to a world
            #   terminates (in which case, GA::Session->doDisconnect or ->reactDisconnect call
            #   $self->disableOverwrite()
            # When turned on, system messages are not displayed in the textview (and are instead
            #   diverted to the Session Console window), and when the buffer's size exceeds the
            #   maximum number of lines, the oldest line is not deleted
            overwriteFlag               => FALSE,

            # The maximum number of lines that the Gtk3::TextBuffer can contain. If 'undef' or 0,
            #   unlimited lines; otherwise when the maximum is reached, the earliest line is
            #   removed when a new line is added
            maxLines                    => $axmud::CLIENT->customTextBufferSize,
            # The oldest remaining line to delete when the buffer is full
            nextDeleteLine              => 0,

            # A scrolling region inside the buffer. If enabled, these two IVs are set to the line
            #   numbers of the top and bottom line of the scrolling region. If disabled, these two
            #   IVs are 'undef'
            # If defined, ->scrlRegionTop must be at least one less than ->scrlRegionBottom.
            #   ->scrlRegionTop must be 0 or above. If ->scrlRegionBottom is larger than the size
            #   of the buffer, then the size of the buffer is used
            scrlRegionTop               => undef,
            scrlRegionBottom            => undef,

            # Flag set to TRUE when the buffer contains some text, and FALSE when it is empty (is
            #   TRUE if the buffer contains a single newline character; is FALSE if an empty buffer
            #   has an empty string 'inserted' into it along with one or more tags)
            bufferTextFlag              => FALSE,
            # When the size of the visible textview needs to be updated, the new size can't be
            #   worked out until the changes have been rendered (via calls to either
            #   GA::Obj::Desktop->updateWidgets or GA::Generic::Win->winShowAll)
            # If the size must be updated, any code can set this flag (by calling
            #   $self->set_sizeUpdateFlag)
            sizeUpdateFlag              => FALSE,
            # GA::Obj::Desktop->updateWidgets and GA::Generic::Win->winShowAll, when called, check
            #   the flag and call $self->updateVisibleSize() to set the following IVs
            textWidthChars              => undef,
            textHeightChars             => undef,
            # Flag set to TRUE when the last line of the buffer ends in a newline character; FALSE
            #   if it ends in any other character. Initially set to TRUE, since an empty buffer is
            #   treated as though a whole line, ending in a newline character, has been removed
            #   from the beginning of the buffer (whether or not it has)
            newLineFlag                 => TRUE,
            # Flag set to TRUE when the current insertion position is preceded by a newline
            #   character (or if the the insertion position is at the beginning of the buffer, or if
            #   the buffer is empty), FALSE if the current insertion position is preceded by any
            #   other character
            insertNewLineFlag           => TRUE,
            # The default behaviour for calls to $self->insertText (but not to ->showSystemText)
            #   'before'    - prepends a newline character to the text
            #   'after'     - appends a newline character to the text
            #   'nl'        - same behaviour as 'after'
            #   'echo'      - does not prepend/append a newline character by default
            newLineDefault              => 'after',
            # Flag than can be set to TRUE by anything (via a call to $self->set_clearAfterInsert)
            #   if the buffer should be emptied, the next time any non-system or system text is
            #   inserted into it (the flag is automatically set back to FALSE after that operation)
            clearAfterInsertFlag        => TRUE,

            # The Gtk3::TextMark which marks the point in the Gtk3::TextBuffer at which
            #   $self->insertText inserts text, and at which $self->insertCmd inserts world
            #   commands. Whenever it is 'undef', both are inserted at the end of the buffer. Code
            #   can call $self->setInsertPosn to set a different insert position, and then call
            #   $self->resetInsertPosn to reset the insert position
            insertMark                  => undef,
            # When code wants to specify an insert position, it calls $self->setInsertPosn, which
            #   sets $self->insertMark
            # However, if some code (such as GA::Session->processMxpDestElement) needs to
            #   temporarily insert text at a particular location, we need to store the value of
            #   $self->insertMark before the call to ->setInsertPosn, so it can be restored when the
            #   calling code is ready (via a call to $self->resetInsertPosn)
            # In most cases, $self->insertMark will have been 'undef' meaning that text is inserted
            #   at the end of the buffer, in which case $self->resetInsertPosn will restore its
            #   value to 'undef'
            restoreInsertMark           => undef,
            # When $self->newLineFlag is FALSE (meaning the buffer doesn't end with a newline
            #   character) and a system message needs to be shown (via a call to
            #   $self->showSystemText, ->showError, ->showWarning, ->showDebug or ->showImproper),
            #   the Gtk3::TextMark is created at the end of the buffer and stored in this IV
            # An artificial newline character is then added to the end of the buffer, and the
            #   system message is shown after that. The next call to $self->insertText or
            #   ->insertCmd when $self->insertMark is set to 'undef' (meaning, the usual insertion
            #   point is at the end of the buffer) uses this iter as its insertion point. When the
            #   next newline character is shown, this IV is set back to 'undef', and the next call
            #   to $self->insertText/->insertCmd uses the end of the buffer as its insertion point
            #   again (showing new text after the system message)
            tempInsertMark              => undef,
            # $self->showError, ->showWarning, ->showDebug and ->showImproper always show text on
            #   separate lines and newline characters are automatically inserted after the system
            #   message. However, calls to ->showSystemText only insert a newline character by
            #   default; code can call ->showSystemText several times, to display a system message
            #   with different tags (for example, to show a system message containing a link), in
            #   the expectation that the final call will specify a newline character
            # This IV is set by $self->showSystemText (only) when a system message is displayed
            #   without a newline character, storing the mark at the end of the system message, that
            #   being the insertion point for the next call to $self->showSystemText
            # It is reset when $self->showSystemText displays a system message with a newline
            #   character, or when $self->showError, ->showWarning, ->showDebug or ->showImproper
            #   show a system message
            systemInsertMark            => undef,
            # When a system message without a newline character is displayed, it is also stored
            #   here, appended to any previous portions of the same line. When a system message with
            #   a newline character is displayed, it is appended to the contents of this IV (if
            #   any), the whole line is written to logs, and the IV is set back to 'undef'
            systemTextBuffer            => undef,

            # If a visible cursor is used, we have to implement it ourselves (a Gtk cursor is only
            #   visible when the textview has the focus, which is never)
            # Flag set to TRUE if a visible cursor is enabled, FALSE if it's disabled
            cursorEnableFlag            => FALSE,
            # Flag set to TRUE if the visible cursor is enabled and 'on', and set to FALSE if the
            #   visible cursor is either disabled or 'off'
            cursorOnFlag                => FALSE,
            # A visible cursor is implemented by creating a single Gtk3::TextTag and turning its
            #   underline on/off (i.e. from ->spinClientLoop)
            # Only one of these text tags exist; to move the visible cursor's position, we just
            #   remove the old tag and insert a new one
            # This Gtk3::TextMark stores the position at which the visible cursor has been placed
            #   (i.e. the position at which the Gtk3::TextTag has been inserted)
            cursorMark                  => undef,
            # If the visible cursor is at the end of the buffer, we have to add an extra space
            #   character, at that point, so the cursor is visible. The space character is
            #   destroyed before any text is inserted, and a new space character inserted afterwards
            # Flag set to TRUE if the visible cursor is at the end of the buffer, FALSE otherwise
            cursorEndFlag               => FALSE,
            # The ANSI control sequences 'Save Cursor Position' and 'Restore Cursor Position'
            #   require us to store and later retrieve a cursor position. Store the position as
            #   (y, x), rather than using a Gtk mark or iter
            # In case anything calls $self->restoreInsertPosn before calling ->storeInsertPosn, use
            #   a default position of the top-left corner
            storePosnYPos               => 0,
            storePosnXPos               => 0,

            # A hash of current GA::Obj::Link objects
            # Links objects can be added to the hash as soon as they are detected or (as is the case
            #   for MXP links) when the whole link has been processed
            # The link object is removed from the hash if the link expires (as is the case for some
            #   MXP links)
            # Hash in the form
            #   $linkObjHash{unique_number} = blessed_reference_of_link_object
            # ...where 'unique_number' is a number unique within this textview object
            linkObjHash                 => {},
            # A parallel hash of GA::Obj::Link objects, sorted by the Gtk3::TextBuffer line on
            #   which they appear (so that when the buffer is full and the earliest line is removed,
            #   any links on that line can also be removed)
            # Hash in the form
            #   $linkObjLineHash{line_num} = reference_to_list_of_link_objects
            # ... where 'reference_to_list_of_link_objects' is a list of GA::Obj::Link objects
            #   appearing on 'line_num', in order from left to right
            linkObjLineHash             => {},
            # Number of link objects objects ever created for this textview object (used to give
            #   each link object a unique number)
            linkObjCount                => 0,
            # If the mouse is hovering over a clickable link, the corresponding GA::Obj::Link (set
            #   to 'undef' when the mouse isn't hovering over a clickable link)
            currentLinkObj              => undef,
            # Flag set to TRUE if links are allowed at all in this textview object, FALSE if they're
            #   not allowed (in which case, any 'link' tags are ignored)
            allowLinkFlag               => TRUE,

            # A hash of buffer lines created by the GA::Session when this textview object is the
            #   session's default textview, so we can display an appropriate tooltip for lines of
            #   text received from the world (but not system messages, nor in textview objects that
            #   are not a session's default textview)
            # The tooltip is in the form 'Line 11, 09:17:12, Thu Dec 18, 2010', where the line
            #   number is the number of the corresponding display buffer object
            #   (GA::Buffer::Display)
            # Hash in the form
            #   $tooltipHash{our_line_num} = tooltip_text
            # ...where 'our_line_num' is the Gtk3::TextBuffer line number of the insert position
            #   used
            tooltipHash                 => {},
            # The 'our_line_num' for the last tooltip displayed, so when the mouse moves over a new
            #   line, we can make the tooltip 'follow' it. Set to 'undef' when no tooltip is
            #   displayed
            lastTooltipLine             => undef,

            # $self->showError, ->showWarning etc usually call GA::Client->playSound to play the
            #   'error' sound effect (nothing happens during the call if sound is turned off or if
            #   the effect is not available)
            # However, several system messages occuring one after the other might cause a cacophony
            #   of noise, so ->showError, ->showWarning etc don't make multiple calls to
            #   ->playSound within a certain period of time
            # When ->showError, ->showWarning etc call ->playSound, this IV is set to the time at
            #   which the next call to ->playSound is allowed
            # NB Any other part of the Axmud code can play the 'error' sound effect, any time it
            #   wants
            # How many seconds to wait between calls to ->playSound
            soundDelayTime              => 10,
            # The time (matches GA::Client->clientTime) at which the next call to ->playSound is
            #   allowed ('undef' if calls to ->playSound are allowed now)
            soundCheckTime              => undef,

            # 'Set Graphics Mode' ANSI escape sequences in text received from the world applies
            #   until the next occurence of that sequence. Each GA::Session needs to keep track
            #   of which graphic modes apply right now in the session's current textview object
            # (For protocols like MXP which use multiple frames, which Axmud implementes as multiple
            #   pane objects, we assume that ANSI escape sequences only apply in the current pane)
            # Hash of graphics modes which currently apply in this textview object, in the same
            #   form as GA::Client->constColourStyleHash:
            #
            #   %colourStyleHash = (
            #       # Colour tags - when set to 'undef', the default colours are used. Standard or
            #       #   xterm colour tags, but not RGB colour tags (because ANSI escape sequences
            #       #   don't use them, and because unlike standard/xterm colour, Gtk3::TextTags
            #       #   for RGB colours are not created until needed)
            #       text                => undef,   # Axmud colour tag, e.g. 'red' or 'x230'
            #       underlay            => undef,   # Axmud underlay colour tag, e.g. 'ul_white'
            #       # Style tags
            #       italics             => FALSE,
            #       underline           => FALSE,
            #       blink_slow          => FALSE,
            #       blink_fast          => FALSE,
            #       strike              => FALSE,
            #       link                => FALSE,
            #       # MXP font tags (which are dummy style tags)
            #       mxp_font            => undef,   # A string like 'mxpf_monospace_bold_12'
            #       # Justification
            #       justify             => 'left', 'right', 'centre' or 'undef' to represent the
            #                                       style tag 'justify_default'
            #   );
            #
            colourStyleHash             => {%colourStyleHash},
            # Hash of graphics modes which applied at the end of the previous line, in the same
            #   form as $self->colourStyleHash
            # Set by $self->insertText after every newline character (and also by
            #   $self->clearBuffer), but not by calls to ->showSystemText, etc)
            prevColourStyleHash         => {%colourStyleHash},

            # List of MXP open modal tags forming a stack. When an opening tag like <FONT> is found,
            #   it's 'pushed' to the stack. When the matching </FONT> tag is found, every tag from
            #   the top of the stack is 'popped' until we find the matching <FONT> tag
            # This allows for nested font and colour changes. It works well if the world uses only
            #   MXP colours or only ANSI escape sequence colours; not so well if it tries to
            #   combine them - because GA::Session->parseMxpElement is called to process the MXP
            #   tags, but it doesn't know the actual text attributes being used, because they're not
            #   set until the later call to $self->applyColourStyleTags
            # Every item in the list is a GA::Mxp::StackObj object
            mxpModalStackList           => [],
            # Hash of current MXP text attributes, modified whenever a GA::Mxp::StackObj object is
            #   pushed to/popped from the stack
            mxpModalStackHash           => {
                'bold_flag'             => FALSE,
                'italics_flag'          => FALSE,
                'underline_flag'        => FALSE,
                'strike_flag'           => FALSE,
                'colour_foreground'     => '',      # Use '' rather than 'undef' so we can use 'eq'
                'colour_background'     => '',
                'high_flag'             => FALSE,   # NB <HIGH> is implemented the same way as <B>
                'font_name'             => '',
                'font_size'             => '',
#               'font_foreground'       => '',      # Font colours stored in 'colour_xxx'
#               'font_background'       => '',
                'blink_flag'            => FALSE,
                'spacing'               => 0,       # Used only with HTML elements like <H1>, <HR>
            },
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    sub objEnable {

        # Called by anything after the call to $self->new
        # Creates the Gtk3::TextView itself, packed into a Gtk3::ScrolledWindow (the scrolled window
        #   is returned)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $splitScreenMode
        #                   - Sets the textview object's initial split screen mode - 'single' for a
        #                       single Gtk3::TextView, 'split' for two Gtk3::TextViews with a
        #                       divider between them, positioned so they are both visible, or
        #                       'hidden' for two Gtk3::Textviews with a divider between them,
        #                       positioned at the top of the screen so the second textview is
        #                       invisible (and the divider itself is almost invisible). If 'undef'
        #                       or an unrecognised value, the default value of 'single' is used
        #   $colourScheme   - The name of the GA::Obj::ColourScheme to use (matches a key in
        #                       GA::CLIENT->colourSchemeHash). If 'undef', the default colour
        #                       scheme for the parent window type is used
        #   $maxLines       - The maximum number of lines that can be shown in the Gtk3::TextView
        #                       (when the limit is reached, the earliest line is removed when a
        #                       new line is added)
        #   $newLineDefault - The default behaviour when a string is inserted into the
        #                       Gtk3::TextView: 'before' prepends a newline character to the string,
        #                       'after'/'nl' prepends a newline character after the string, 'echo'
        #                       does not prepend/a newline character by default. If 'undef' or an
        #                       unrecognised value, 'after' is used
        #   $oldBuffer      - If we want the new Gtk3::TextView to use an existing Gtk3::TextBuffer
        #                       any reason, that buffer; set to 'undef' otherwise
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the Gtk3::ScrolledWindow

        my (
            $self, $splitScreenMode, $colourScheme, $maxLines, $newLineDefault, $oldBuffer, $check
        ) = @_;

        # Local variables
        my ($colourSchemeObj, $bufferClass);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Apply split screen mode, using a default value if no recognised value was specified
        if (
            defined $splitScreenMode
            && (
                $splitScreenMode eq 'single' || $splitScreenMode eq 'split'
                || $splitScreenMode eq 'hidden'
            )
        ) {
            $self->ivPoke('splitScreenMode', $splitScreenMode);
        }

        # Apply the colour scheme, using a default one if none was specified
        if (! $colourScheme || ! $axmud::CLIENT->ivShow('colourSchemeHash', $colourScheme)) {

            $colourScheme = $self->winObj->winType;
        }

        $colourSchemeObj = $axmud::CLIENT->ivShow('colourSchemeHash', $colourScheme);

        $self->ivPoke('colourScheme', $colourSchemeObj->name);
        $self->ivPoke('textColour', $colourSchemeObj->textColour);
        $self->ivPoke('underlayColour', $colourSchemeObj->underlayColour);
        $self->ivPoke('backgroundColour', $colourSchemeObj->backgroundColour);
        $self->ivPoke('font', $colourSchemeObj->font);
        $self->ivPoke('fontSize', $colourSchemeObj->fontSize);

        # Apply the maximum number of lines, if specified; otherwise keep using the default value
        if (defined $maxLines) {

            $self->ivPoke('maxLines', $maxLines);
        }

        # Apply the default newline behaviour, if specified, otherwise keep using the default value
        if (
            defined $newLineDefault
            && (
                $newLineDefault eq 'before'
                || $newLineDefault eq 'after'
                || $newLineDefault eq 'nl'
                || $newLineDefault eq 'echo'
            )
        ) {
            $self->ivPoke('newLineDefault', $newLineDefault);
        }

        # If $oldBuffer wasn't specified, create a new Gtk3::TextBuffer
        if (! $oldBuffer) {

            $self->ivPoke('buffer', Gtk3::TextBuffer->new());

            # Create colour/style tags for the new textbuffer
            $self->createColourTags();
            $self->createStyleTags();

        } else {

            $self->ivPoke('buffer', $oldBuffer);
        }

        # Create the Gtk3::TextView(s)
        my ($scroll, $scroll2, $vPaned, $textView, $textView2);
        $textView = $self->createTextViewWidget($self->buffer, $colourSchemeObj);
        if ($self->splitScreenMode eq 'single') {

            # Pack the textview into a container widget
            $scroll = $self->setupScroller($textView);

        } else {

            $textView2 = $self->createTextViewWidget($self->buffer, $colourSchemeObj);

            # Pack the textviews into a container widget
            ($vPaned, $scroll, $scroll2) = $self->setupVPaned($textView, $textView2);
        }

        # Set the textview's CSS style
        $axmud::CLIENT->desktopObj->setTextViewObjStyle(
            $self->number,
            $axmud::CLIENT->returnRGBColour($self->textColour),
            $axmud::CLIENT->returnRGBColour($self->backgroundColour),
            $self->font,
            $self->fontSize,
            $textView,
            $textView2,
        );

        # Update IVs
        $self->ivPoke('textView', $textView);
        $self->ivPoke('textView2', $textView2);
        $self->ivPoke('vPaned', $vPaned);
        $self->ivPoke('scroll', $scroll);
        $self->ivPoke('scroll2', $scroll2);
        $self->ivPoke('sizeUpdateFlag', TRUE);

        # Create a mark at the end of the buffer, with right gravity, so that whenever text is
        #   inserted, we can scroll to that mark (and the mark stays at the end)
        # Also create a mark at the beginning of the buffer, with left gravity, for scrolling to the
        #   top
        my $startMark
            = $self->buffer->create_mark('start_mark', $self->buffer->get_start_iter(), TRUE);
        my $endMark
            = $self->buffer->create_mark('end_mark', $self->buffer->get_end_iter(), FALSE);
        # ($self->insertNewLine creates a 'line_N' mark after every newline character, but not at
        #   the beginning of the Gtk3::TextBuffer)
        $self->buffer->create_mark('line_0', $self->buffer->get_start_iter(), TRUE);

        # Create a search mark which moves whenever $self->searchBuffer is called, and is initially
        #   at the beginning of the buffer
        my $searchMark
            = $self->buffer->create_mark('search_mark', $self->buffer->get_start_iter(), TRUE);

        # Update IVs again
        $self->ivPoke('startMark', $startMark);
        $self->ivPoke('endMark', $endMark);
        $self->ivPoke('searchMark', $searchMark);

        # Gtk3::TextTags might not exist for any RGB tags that have just been copied to
        #   $self->textColour and/or $self->underlayColour, and $self->interpretTags won't have the
        #   opportunity to create them, so create them right away
        $self->updateRGBTags();

        if ($self->splitScreenMode eq 'single') {
            return $scroll;
        } else {
            return $vPaned;
        }
    }

    sub objDestroy {

        # Called by GA::Table::Pane->objDestroy, ->removeSessionTab and ->removeTab
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->objUpdate', @_);
        }

        # Update the GA::Obj::Desktop registry
        $axmud::CLIENT->desktopObj->del_textView($self);

        return 1;
    }

    sub objUpdate {

        # Called by GA::Table::Pane->applyColourScheme or ->updateColourScheme (must not be called
        #   directly)
        # Also called by $self->setMonochromeMode and ->resetMonochromeMode when a monochrome colour
        #   scheme is applied/removed
        #
        # Applies a colour scheme to this object's Gtk3::TextView(s)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $colourScheme
        #       - The new colour scheme to use (matches a key in GA::Client->colourSchemeHash).
        #           'undef' when called by $self->applyMonochrome, in which the colours already
        #           stored in $self->textColour, ->underlayColour and ->backgroundColour are used
        #
        # Return values
        #   'undef' on improper arguments or if the specified colour scheme doesn't exist
        #   1 otherwise

        my ($self, $colourScheme, $check) = @_;

        # Local variables
        my (
            $colourSchemeObj, $backgroundColour, $textColour,
            @list,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->objUpdate', @_);
        }

        # Get the colour scheme object (the calling function has already checked it exists)
        if ($colourScheme) {

            $colourSchemeObj = $axmud::CLIENT->ivShow('colourSchemeHash', $colourScheme);
            if (! $colourSchemeObj) {

                return undef;

            } else {

                # Make sure the colour scheme's colour/font values are acceptable, to avoid getting
                #   nasty Gtk errors
                $colourSchemeObj->repair();

                # Update IVs. When the colour scheme is updated, the scheme's colours aren't applied
                #   in monochrome mode with modified colours (because some code, usually a task,
                #   specifically requested those colours)
                $self->ivPoke('colourScheme', $colourSchemeObj->name);

                if (! $self->monochromeFlag) {

                    $self->ivPoke('textColour', $colourSchemeObj->textColour);
                    $self->ivPoke('underlayColour', $colourSchemeObj->underlayColour);
                    $self->ivPoke('backgroundColour', $colourSchemeObj->backgroundColour);

                } elsif (! $self->monochromeModFlag) {

                    $backgroundColour = $colourSchemeObj->backgroundColour;

                    if ($axmud::CLIENT->ivExists('constMonochromeHash', $backgroundColour)) {

                        # Choose a text colour to match the background colour in the standard way,
                        #   ignoring the text colour specified by the colour scheme
                        $textColour = $axmud::CLIENT->ivShow(
                            'constMonochromeHash',
                            $backgroundColour,
                        );

                    } else {

                        # Non-standard background colour tag, in which case use the colour specified
                        #   by the colour scheme itself, rather than choosing a matching colour
                        # (It's up to the person who edits the colour scheme to choose a suitable
                        #   colour)
                        $textColour = $colourSchemeObj->textColour;
                    }

                    # In monochrome mode, the underlay colour is always the same as the background
                    $self->ivPoke('textColour', $textColour);
                    $self->ivPoke('underlayColour', undef);
                    $self->ivPoke('backgroundColour', $backgroundColour);
                }

                # The fonts are applied in all situations
                $self->ivPoke('font', $colourSchemeObj->font);
                $self->ivPoke('fontSize', $colourSchemeObj->fontSize);
            }
        }

        # Update the textview's CSS style
        $axmud::CLIENT->desktopObj->setTextViewObjStyle(
            $self->number,
            $self->textColour,
            $self->backgroundColour,
            $self->font,
            $self->fontSize,
            $self->textView,
            $self->textView2,       # May be 'undef'
        );

        # Gtk3::TextTags might not exist for any RGB tags that have just been copied to
        #   $self->textColour and/or $self->underlayColour, and $self->interpretTags won't have the
        #   opportunity to create them, so create them right away
        $self->updateRGBTags();

        # Create any new Gtk3::TextTags that don't already exist, using a phoney call to
        #   $self->interpretTags
        # NB Default values for these IVs are 'undef', so we have to check for that
        if ($self->textColour) {

            push (@list, $self->textColour);
        }

        if ($self->underlayColour) {

            push (@list, $self->underlayColour);
        }

        if ($self->backgroundColour) {

            push (@list, $self->backgroundColour);
        }

        if (@list) {

            $self->interpretTags($self->newLineDefault, @list);
        }

        # Operation complete
        return 1;
    }

    # ->signal_connects

    sub setMotionNotifyEvent {

        # Called by $self->createTextViewWidget
        # Set up a ->signal_connect to watch out for the motion over clickable links
        #
        # Expected arguments
        #   $textView   - The Gtk3::TextView that generated the signal (later stored in either
        #                   $self->textView or $self->textView2)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $textView, $check) = @_;

        # Check for improper arguments
        if (! defined $textView || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setMotionNotifyEvent', @_);
        }

        $textView->signal_connect('motion-notify-event' => sub {

            $self->checkMousePosn(@_);

            # Return 'undef' to show that we haven't interfered with the widget
            return undef;
        });

        return 1;
    }

    sub setLeaveNotifyEvent {

        # Called by $self->createTextViewWidget
        # Set up a ->signal_connect to watch out for the motion over clickable links
        #
        # Expected arguments
        #   $textView   - The Gtk3::TextView that generated the signal (later stored in either
        #                   $self->textView or $self->textView2)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $textView, $check) = @_;

        # Check for improper arguments
        if (! defined $textView || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setLeaveNotifyEvent', @_);
        }

        $textView->signal_connect('leave-notify-event' => sub {

            my ($widget, $event) = @_;

            $self->hideTooltips();

            # Return 'undef' to show that we haven't interfered with the widget
            return undef;
        });

        return 1;
    }

    sub setFocusOutEvent {

        # Called by $self->createTextViewWidget
        # Set up a ->signal_connect to watch out for the motion over clickable links
        #
        # Expected arguments
        #   $textView   - The Gtk3::TextView that generated the signal (later stored in either
        #                   $self->textView or $self->textView2)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $textView, $check) = @_;

        # Check for improper arguments
        if (! defined $textView || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setFocusOutEvent', @_);
        }

        $textView->signal_connect('focus-out-event' => sub {

            my ($widget, $event) = @_;

            $self->hideTooltips();

            # Return 'undef' to show that we haven't interfered with the widget
            return undef;
        });

        return 1;
    }

    sub setButtonPressEvent {

        # Called by $self->createTextViewWidget
        # Set up a ->signal_connect to watch out for mouse clicks on a clickable link
        #
        # Expected arguments
        #   $textView   - The Gtk3::TextView that generated the signal (later stored in either
        #                   $self->textView or $self->textView2)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $textView, $check) = @_;

        # Check for improper arguments
        if (! defined $textView || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setButtonPressEvent', @_);
        }

        $textView->signal_connect('button-press-event' => sub {

            my ($widget, $event) = @_;

            # Local vars
            my ($result, $host, $port, $stripObj);

            # Any mouse click hides tooltips
            $self->hideTooltips();

            # If the mouse is currently above a clickable link, $self->currentLinkObj will be
            #   defined
            if ($event->type eq 'button-press' && defined $self->currentLinkObj) {

                # Left button
                if ($event->button == 1) {

                    if ($self->currentLinkObj->type eq 'www') {

                        $result = $axmud::CLIENT->openURL($self->currentLinkObj->href);

                    } elsif ($self->currentLinkObj->type eq 'mail') {

                        $result = $axmud::CLIENT->openEmail($self->currentLinkObj->href);

                    } elsif ($self->currentLinkObj->type eq 'telnet') {

                        # The link should be in the form telnet://deathmud.org:6666 or
                        #   telnet://deathmud.org
                        # Separate that into a host and a port
                        if ($self->currentLinkObj->href =~ m/^telnet\:\/\/([^\:\s]+)(\:(\d+))?/) {

                            $host = $1;
                            $port = $3;         # May be 'undef';

                            if ($host && $port) {

                                $result
                                    = $self->session->pseudoCmd('telnet ' . $host . ' ' . $port);

                            } else {

                                $result = $self->session->pseudoCmd('telnet ' . $host);
                            }
                        }

                    } elsif ($self->currentLinkObj->type eq 'ssh') {

                        # The link should be in the form ssh://deathmud.org:6666 or
                        #   ssh://deathmud.org
                        # Separate that into a host and a port
                        if ($self->currentLinkObj->href =~ m/^ssh\:\/\/([^\:\s]+)(\:(\d+))?/) {

                            $host = $1;
                            $port = $3;         # May be 'undef';

                            if ($host && $port) {
                                $result = $self->session->pseudoCmd('ssh ' . $host . ' ' . $port);
                            } else {
                                $result = $self->session->pseudoCmd('ssh ' . $host);
                            }
                        }

                    } elsif ($self->currentLinkObj->type eq 'ssl') {

                        # The link should be in the form ssl://deathmud.org:6666 or
                        #   ssl://deathmud.org
                        # Separate that into a host and a port
                        if ($self->currentLinkObj->href =~ m/^ssl\:\/\/([^\:\s]+)(\:(\d+))?/) {

                            $host = $1;
                            $port = $3;         # May be 'undef';

                            if ($host && $port) {
                                $result = $self->session->pseudoCmd('ssl ' . $host . ' ' . $port);
                            } else {
                                $result = $self->session->pseudoCmd('ssl ' . $host);
                            }
                        }

                    } elsif ($self->currentLinkObj->type eq 'cmd') {

                        if ($self->currentLinkObj->mxpPromptFlag) {

                            # Instead of sending a world command, copy the world command into the
                            #   'main' window's entry box
                            $stripObj = $self->paneObj->winObj->getStrip('entry');
                            if ($stripObj) {

                                $result = $stripObj->commandeerEntry(
                                    $self->session,
                                    $self->currentLinkObj->href,
                                );
                            }

                        } elsif ($self->currentLinkObj->popupCmdList) {

                            $result = $self->session->worldCmd(
                                $self->currentLinkObj->ivFirst('popupCmdList'),
                            );

                        } elsif ($self->currentLinkObj->href) {

                            $result = $self->session->worldCmd($self->currentLinkObj->href);

                        } else {

                            $result = $self->session->worldCmd($self->currentLinkObj->text);
                        }
                    }

                # Right button
                } elsif ($event->button == 3) {

                    if ($self->currentLinkObj->type eq 'cmd' && $self->currentLinkObj->popupFlag) {

                        # Create a popup menu, and send a world command if the user clicks on a menu
                        #   item
                        $result = $self->createPopupMenu($event);
                    }
                }

                # Clicking on a link resets the cursor
                $self->ivUndef('currentLinkObj');
                $textView->get_window('text')->set_cursor($axmud::CLIENT->constNormalCursor);
                return $result;
            }

            # Otherwise return 'undef' to show that we haven't interfered with the widget
            return undef;
        });

        return 1;
    }

    sub setTextViewScrollEvent {

        # Called by $self->enableSplitScreen and ->enableHiddenSplitScreen, as well as by
        #   GA::Table::Pane->addSimpleTab and ->addTab
        # Set up a ->signal_connect to watch out for scrolling in the Gtk3::ScrolledWindow which
        #   contains a textview
        #
        # Expected arguments
        #   $scroll     - The Gtk3::ScrolledWindow that generated the signal
        #   $textView   - The Gtk3::TextView it contains
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $scroll, $textView, $check) = @_;

        # Check for improper arguments
        if (! defined $scroll || ! defined $textView || defined $check) {

             return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->setTextViewScrollEvent',
                @_,
            );
        }

        # Detect scrolling, so we can reset the cursor (so the user can't move the cursor above a
        #   link, wait until the link scrolls away, and then still click the link)
        my $adjust = $scroll->get_vadjustment();
        $adjust->signal_connect('value-changed' => sub {

            my $window = $textView->get_window('text');

            if ($self->currentLinkObj) {

                $self->ivUndef('currentLinkObj');
                $window->set_cursor($axmud::CLIENT->constNormalCursor);
            }

            # (Any scrolling in the window hides tooltips)
            $self->hideTooltips();

            # Without this line, changes to the visible textview size, caused by the addition/
            #   removal of a scrollbar, are applied quickly enough
            $self->ivPoke('sizeUpdateFlag', TRUE);
        });

        return 1;
    }

    # Other functions - called by anything

    sub scrollToTop {

        # Can be called by anything
        # Scrolls the textview to the top
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $flag   - If set to TRUE, the second textview (created in split screen mode) is
        #               scrolled, if it exists. Otherwise, the original textview is scrolled
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $flag, $check) = @_;

        # Local variables
        my $textView;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->scrollToTop', @_);
        }

        if ($flag && $self->textView2 && $self->splitScreenMode eq 'split') {
            $textView = $self->textView2;
        } elsif ($self->textView) {
            $textView = $self->textView;
        }

        if ($textView) {

            # Apply the nice visual effect...
            $textView->scroll_to_mark($self->buffer->get_mark('start_mark'), 0.0, TRUE, 0, 0);

            # ...and instruct the GA::Session to make sure, on the next spin of its maintain loop,
            #   that the textview really is scrolled to the top
            $self->session->add_textViewScrollUp($textView);
        }

        return 1;
    }

    sub scrollToBottom {

        # Can be called by anything
        # Scrolls the textview to the bottom
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $flag   - If set to TRUE, the second textview (created in split screen mode) is
        #               scrolled, if it exists. Otherwise, the original textview is scrolled
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $flag, $check) = @_;

        # Local variables
        my $textView;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->scrollToBottom', @_);
        }

        if ($flag && $self->textView2 && $self->splitScreenMode eq 'split') {
            $textView = $self->textView2;
        } elsif ($self->textView) {
            $textView = $self->textView;
        }

        if ($textView) {

            # Apply the nice visual effect...
            $textView->scroll_to_mark($self->buffer->get_mark('end_mark'), 0.0, TRUE, 0, 1);

            # ...and instruct the GA::Session to make sure, on the next spin of its maintain loop,
            #   that the textview really is scrolled to the bottom
            $self->session->add_textViewScrollDown($textView);
        }

        return 1;
    }

    sub scrollToIter {

        # Can be called by anything
        # Scrolls the (original) textview to a specified Gtk3::TextIter (if split screen mode
        #   applies, the upper textview doesn't scroll)
        #
        # Expected arguments
        #   $iter   - Scroll to this Gtk3::TextIter
        #
        # Optional arguments
        #   $flag   - If set to TRUE, the second textview (created in split screen mode) is
        #               scrolled, if it exists. Otherwise, the original textview is scrolled
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $iter, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $iter || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->scrollToIter', @_);
        }

        if ($flag && $self->textView2 && $self->splitScreenMode eq 'split') {
            $self->textView2->scroll_to_iter($iter, 0.0, TRUE, 0, 1);
        } elsif ($self->textView) {
            $self->textView->scroll_to_iter($iter, 0.0, TRUE, 0, 1);
        }

        $self->winObj->winShowAll($self->_objClass . '->scrollToIter');

        return 1;
    }

    sub scrollToMark {

        # Can be called by anything
        # Scrolls the (original) textview to a specified Gtk3::TextMark (if split screen mode
        #   applies, the upper textview doesn't scroll)
        #
        # Expected arguments
        #   $mark   - Scroll to this Gtk3::TextMark
        #
        # Optional arguments
        #   $flag   - If set to TRUE, the second textview (created in split screen mode) is
        #               scrolled, if it exists. Otherwise, the original textview is scrolled
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $mark, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $mark || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->scrollToMark', @_);
        }

        if ($flag && $self->textView2 && $self->splitScreenMode eq 'split') {
            $self->textView2->scroll_to_mark($mark, 0.0, TRUE, 0, 1);
        } elsif ($self->textView) {
            $self->textView->scroll_to_mark($mark, 0.0, TRUE, 0, 1);
        }

        $self->winObj->winShowAll($self->_objClass . '->scrollToMark');

        return 1;
    }

    sub scrollToLock {

        # Can be called by anything
        # Convenience function for scrolling both textviews (or the single textview, if there is
        #   only one) to their 'locked' position
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->scrollToLock', @_);
        }

        # Scroll to the end of the buffer in each textview
        if ($self->scrollLockType eq 'top') {

            $self->scrollToTop();
            $self->scrollToTop(TRUE);

        } else {

            $self->scrollToBottom();
            $self->scrollToBottom(TRUE);
        }

        return 1;
    }

    sub clearBuffer {

        # Can be called by anything (also called by $self->insertText, ->insertQuick,
        #   ->showSystemText and ->showImage)
        # Empties the Gtk3::TextBuffer of text
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $overwriteFlag  - If TRUE, overwite mode is turned on (if not already on). If FALSE or
        #                       'undef', no change to overwrite mode is made
        #   $noCursorFlag   - If TRUE, don't call ->removeCursor or ->moveCursor, because the
        #                       calling function wants to handle visible cursors. If FALSE or
        #                       'undef', ->removeCursor and ->moveCursor are called as normal
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $overwriteFlag, $noCursorFlag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clearBuffer', @_);
        }

        # Turn on overwrite mode, if required by the calling function (and if it's not already
        #   turned on)
        if ($overwriteFlag && ! $self->overwriteFlag) {

            $self->enableOverwrite();
        }

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        if (! $noCursorFlag) {

            $self->removeCursor();
        }

        # Empty the buffer
        $self->buffer->set_text('');
        # Destroy any GA::Obj::Link objects whose links are no longer visible
        $self->reset_link();

        # If the cursor is visible, move it to the end of the buffer (i.e. insert a new
        #   Gtk3::TextTag)
        if (! $noCursorFlag) {

            $self->moveCursor();
        }

        # Update IVs
        $self->ivPoke('nextDeleteLine', 0);
        $self->ivPoke('bufferTextFlag', FALSE);
        $self->ivPoke('newLineFlag', TRUE);
        $self->ivPoke('insertNewLineFlag', TRUE);
        $self->ivPoke('clearAfterInsertFlag', FALSE);
        $self->ivUndef('insertMark');
        $self->ivUndef('restoreInsertMark');
        $self->ivUndef('tempInsertMark');
        $self->ivUndef('systemInsertMark');
        $self->ivUndef('systemTextBuffer');
        $self->ivPoke('cursorEnableFlag', FALSE);
        $self->ivPoke('cursorOnFlag', FALSE);
        $self->ivUndef('cursorMark');
        $self->ivPoke('cursorEndFlag', FALSE);
        $self->ivPoke('storePosnYPos', 0);
        $self->ivPoke('storePosnXPos', 0);
        $self->ivEmpty('linkObjHash');
        $self->ivEmpty('linkObjLineHash');
        $self->ivPoke('linkObjCount', 0);
        $self->ivUndef('currentLinkObj');
        $self->ivEmpty('tooltipHash');
        $self->ivPoke('lastTooltipLine', undef);
        # Reset colours/styles
        $self->ivPoke('colourStyleHash', $axmud::CLIENT->constColourStyleHash);
        $self->ivPoke('prevColourStyleHash', $axmud::CLIENT->constColourStyleHash);

        return 1;
    }

    sub clearBufferBeforeMark {

        # Can be called by anything
        # Empties the Gtk3::TextBuffer of text before a specified mark
        #
        # Expected arguments
        #   $mark           - The Gtk3::TextMark before which the buffer should be cleared
        #
        # Optional arguments
        #   $overwriteFlag  - If TRUE, overwite mode is turned on (if not already on). If FALSE or
        #                       'undef', no change to overwrite mode is made
        #
        # Return values
        #   'undef' on improper arguments or if the text can't be emptied
        #   1 otherwise

        my ($self, $mark, $overwriteFlag, $check) = @_;

        # Local variables
        my (
            $stopIter, $lineNum, $posn, $startIter,
            %tooltipHash, %newHash,
        );

        # Check for improper arguments
        if (! defined $mark || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clearBufferBeforeMark', @_);
        }

        # Turn on overwrite mode, if required by the calling function (and if it's not already
        #   turned on)
        if ($overwriteFlag && ! $self->overwriteFlag) {

            $self->enableOverwrite();
        }

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        $self->removeCursor();

        $stopIter = $self->buffer->get_iter_at_mark($mark);
        $lineNum = $stopIter->get_line();
        $posn = $stopIter->get_visible_line_offset();
        $startIter = $self->buffer->get_start_iter();
        if (! $startIter || ! $stopIter) {

            return undef;
        }

        # Empty the buffer before the specified mark
        $self->buffer->delete($startIter, $stopIter);

        # Update IVs generally
        $self->ivPoke('nextDeleteLine', 0);

        if (! $self->buffer->get_char_count()) {

            $self->ivPoke('bufferTextFlag', FALSE);
            $self->ivPoke('newLineFlag', TRUE);

        } else {

            $self->ivPoke('bufferTextFlag', TRUE);
            # (->newLineFlag retains its current value)
        }

        $self->ivPoke('sizeUpdateFlag', TRUE);
        $self->ivPoke('insertNewLineFlag', TRUE);
        $self->ivUndef('insertMark');
        $self->ivUndef('restoreInsertMark');
        $self->ivUndef('tempInsertMark');
        $self->ivUndef('systemInsertMark');

        if ($self->storePosnYPos < $lineNum) {

            $self->ivPoke('storePosnYPos', 0);
            $self->ivPoke('storePosnXPos', 0);

        } elsif ($self->storePosnYPos == $lineNum) {

            $self->ivPoke('storePosnYPos', 0);
            $self->ivPoke('storePosnXPos', $self->storePosnXPos - $posn);

        } else {

            $self->ivPoke('storePosnYPos', $self->storePosnYPos - $lineNum);
        }

        %tooltipHash = $self->tooltipHash;
        foreach my $key (keys %tooltipHash) {

            my ($value, $modKey);

            $value = $tooltipHash{$key};
            $modKey = $key - $lineNum;

            if ($modKey >= 0) {

                $newHash{$modKey} = $value;
            }
        }

        $self->ivPoke('tooltipHash', %newHash);
        $self->ivUndef('lastTooltipLine');

        # Destroy any GA::Obj::Link objects whose links are no longer visible
        $self->reset_link();

        # In case the visible cursor is at a position that's now been overwritten, redraw it
        $self->replaceCursor();

        return 1;
    }

    sub clearBufferAfterMark {

        # Can be called by anything
        # Empties the Gtk3::TextBuffer of text after a specified mark
        #
        # Expected arguments
        #   $mark           - The Gtk3::TextMark after which the buffer should be cleared
        #
        # Optional arguments
        #   $overwriteFlag  - If TRUE, overwite mode is turned on (if not already on). If FALSE or
        #                       'undef', no change to overwrite mode is made
        #
        # Return values
        #   'undef' on improper arguments or if the text can't be emptied
        #   1 otherwise

        my ($self, $mark, $overwriteFlag, $check) = @_;

        # Local variables
        my ($startIter, $lineNum, $posn, $stopIter, $oldBufferSize, $lastChar);

        # Check for improper arguments
        if (! defined $mark || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clearBufferAfterMark', @_);
        }

        # Turn on overwrite mode, if required by the calling function (and if it's not already
        #   turned on)
        if ($overwriteFlag && ! $self->overwriteFlag) {

            $self->enableOverwrite();
        }

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        $self->removeCursor();

        $startIter = $self->buffer->get_iter_at_mark($mark);
        $lineNum = $startIter->get_line();
        $posn = $startIter->get_visible_line_offset();
        $stopIter = $self->buffer->get_end_iter();
        $oldBufferSize = $stopIter->get_line();
        if (! $startIter || ! $stopIter) {

            return undef;
        }

        # Empty the buffer after the specified mark
        $self->buffer->delete($startIter, $stopIter);

        # Update IVs generally
        if ($self->nextDeleteLine < $lineNum) {

            $self->ivPoke('nextDeleteLine', $lineNum);
        }

        # Test the last character in the remaining buffer
        $stopIter = $self->buffer->get_end_iter();
        if (! $stopIter->backward_char()) {

            $self->ivPoke('bufferTextFlag', FALSE);

        } else {

            $self->ivPoke('bufferTextFlag', TRUE);
            $lastChar = $stopIter->get_text($self->buffer->get_end_iter());
            if ($lastChar eq "\n") {
                $self->ivPoke('newLineFlag', TRUE);
            } else {
                $self->ivPoke('newLineFlag', FALSE);
            }
        }

        $self->ivPoke('sizeUpdateFlag', TRUE);

        foreach my $iv (qw( insertMark restoreInsertMark systemInsertMark systemTextBuffer) ) {

            if (defined $self->$iv && ! $self->buffer->get_iter_at_mark($self->$iv)) {

                $self->ivUndef($iv);
                if ($iv eq 'insertMark') {

                    # If buffer is empty, this flag is TRUE
                    if (! $self->buffer->get_char_count()) {
                        $self->ivPoke('insertNewLineFlag', TRUE);
                    } else {
                        $self->ivPoke('insertNewLineFlag', FALSE);
                    }
                }
            }
        }

        if (
            $self->storePosnYPos > $lineNum
            || ($self->storePosnYPos == $lineNum && $self->storePosnXPos > $posn)
        ) {
            # The stored cursor location is invalidated
            $self->ivPoke('storePosnYPos', 0);
            $self->ivPoke('storePosnXPos', 0);
        }

        if ($oldBufferSize > $lineNum) {

            for (my $key = ($lineNum + 1); $key <= $oldBufferSize; $key++) {

                # (For speed, don't use ->ivDelete)
                delete $self->{tooltipHash}{$key};
            }
        }

        $self->ivUndef('lastTooltipLine');

        # Destroy any GA::Obj::Link objects whose links are no longer visible
        $self->reset_link();

        # In case the visible cursor is at a position that's now been overwritten, redraw it
        $self->replaceCursor();

        return 1;
    }

    sub clearLineBeforeMark {

        # Can be called by anything
        # Given a specified mark on a line in the Gtk3::TextBuffer, empties everything on the line
        #   up to that point
        # (In other words, all characters before the mark are replaced by space characters)
        #
        # Expected arguments
        #   $mark           - The Gtk3::TextMark before which the line should be emptied
        #
        # Optional arguments
        #   $overwriteFlag  - If TRUE, overwite mode is turned on (if not already on). If FALSE or
        #                       'undef', no change to overwrite mode is made
        #
        # Return values
        #   'undef' on improper arguments or if the text can't be cleared
        #   1 otherwise

        my ($self, $mark, $overwriteFlag, $check) = @_;

        # Local variables
        my ($stopIter, $lineNum, $posn, $startIter, $text);

        # Check for improper arguments
        if (! defined $mark || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clearLineAfterMark', @_);
        }

        # Turn on overwrite mode, if required by the calling function (and if it's not already
        #   turned on)
        if ($overwriteFlag && ! $self->overwriteFlag) {

            $self->enableOverwrite();
        }

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        $self->removeCursor();

        $stopIter = $self->buffer->get_iter_at_mark($mark);
        $lineNum = $stopIter->get_line();
        $posn = $stopIter->get_visible_line_offset();

        if ($posn == 0) {

            # Nothing to remove, as the insert position is at the beginning of the line
            return 1;
        }

        $startIter = $self->buffer->get_iter_at_line_offset($lineNum, 0);
        $text = ' ' x $posn;

        $self->buffer->insert_with_tags_by_name($startIter, $text);

        # (No IVs to update generally)

        # In case the visible cursor is at a position that's now been overwritten, redraw it
        $self->replaceCursor();

        return 1;
    }

    sub clearLineAroundMark {

        # Can be called by anything
        # Clears the line at the specified mark
        # (In other words, all characters on the same line are replaced by space characters)
        #
        # Expected arguments
        #   $mark           - The Gtk3::TextMark after which the line should be emptied
        #
        # Optional arguments
        #   $overwriteFlag  - If TRUE, overwite mode is turned on (if not already on). If FALSE or
        #                       'undef', no change to overwrite mode is made
        #
        # Return values
        #   'undef' on improper arguments or if the text can't be cleared
        #   1 otherwise

        my ($self, $mark, $overwriteFlag, $check) = @_;

        # Local variables
        my ($midIter, $lineNum, $posn, $startIter, $stopIter, $length, $text);

        # Check for improper arguments
        if (! defined $mark || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clearLineAfterMark', @_);
        }

        # Turn on overwrite mode, if required by the calling function (and if it's not already
        #   turned on)
        if ($overwriteFlag && ! $self->overwriteFlag) {

            $self->enableOverwrite();
        }

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        $self->removeCursor();

        $midIter = $self->buffer->get_iter_at_mark($mark);
        $lineNum = $midIter->get_line();
        $posn = $midIter->get_visible_line_offset();

        $startIter = $self->buffer->get_iter_at_line_offset($lineNum, 0);
        $stopIter = $self->buffer->get_iter_at_line_offset(($lineNum + 1), 0);
        $stopIter->backward_char();
        $length = $stopIter->get_visible_line_offset() - $startIter->get_visible_line_offset();
        $text = ' ' x $length;
        $self->buffer->insert_with_tags_by_name($startIter, $text);

        # (No IVs to update generally)

        # In case the visible cursor is at a position that's now been overwritten, redraw it
        $self->replaceCursor();

        return 1;
    }

    sub clearLineAfterMark {

        # Can be called by anything
        # Given a specified mark on a line in the Gtk3::TextBuffer, empties the rest of the line
        # (In other words, all characters after the mark are replaced by space characters, but the
        #   newline character is preserved, if present)
        #
        # Expected arguments
        #   $mark           - The Gtk3::TextMark after which the line should be emptied
        #
        # Optional arguments
        #   $overwriteFlag  - If TRUE, overwite mode is turned on (if not already on). If FALSE or
        #                       'undef', no change to overwrite mode is made
        #
        # Return values
        #   'undef' on improper arguments or if the text can't be cleared
        #   1 otherwise

        my ($self, $mark, $overwriteFlag, $check) = @_;

        # Local variables
        my ($startIter, $lineNum, $posn, $length, $endIter, $stopIter);

        # Check for improper arguments
        if (! defined $mark || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clearLineAfterMark', @_);
        }

        # Turn on overwrite mode, if required by the calling function (and if it's not already
        #   turned on)
        if ($overwriteFlag && ! $self->overwriteFlag) {

            $self->enableOverwrite();
        }

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        $self->removeCursor();

        $startIter = $self->buffer->get_iter_at_mark($mark);
        $lineNum = $startIter->get_line();
        $posn = $startIter->get_visible_line_offset();
        $length = $self->getLineLength($startIter);

        $endIter = $self->buffer->get_end_iter();
        if ($endIter->get_line() == $startIter->get_line()) {

            # Clear text to the end of the buffer, as we're on the last line
            $stopIter = $endIter;

        } else {

            # Preserve newline character at end of line
            $stopIter = $self->buffer->get_iter_at_line_offset($lineNum, ($length - 1));
        }

        if (! $startIter && ! $stopIter) {

            return undef;
        }

        # Clear the line portion
        $self->buffer->delete($startIter, $stopIter);

        # Update IVs generally
        foreach my $iv (qw( insertMark restoreInsertMark systemInsertMark systemTextBuffer) ) {

            if (defined $self->$iv && ! $self->buffer->get_iter_at_mark($self->$iv)) {

                $self->ivUndef($iv);
                if ($iv eq 'insertMark') {

                    # If buffer is empty, this flag is TRUE
                    if (! $self->buffer->get_char_count()) {
                        $self->ivPoke('insertNewLineFlag', TRUE);
                    } else {
                        $self->ivPoke('insertNewLineFlag', FALSE);
                    }
                }
            }
        }

        if (
            $self->storePosnYPos == $lineNum
            && $self->storePosnXPos >= $posn
            && $self->storePosnXPos <= $length
        ) {
            # The stored cursor location is invalidated
            $self->ivPoke('storePosnYPos', 0);
            $self->ivPoke('storePosnXPos', 0);
        }

        # In case the visible cursor is at a position that's now been overwritten, redraw it
        $self->replaceCursor();

        return 1;
    }

    sub clearBufferBeforePosn {

        # Can be called by anything
        # Empties the Gtk3::TextBuffer of text before a specified position
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $overwriteFlag  - If TRUE, overwite mode is turned on (if not already on). If FALSE or
        #                       'undef', no change to overwrite mode is made
        #   $currentYPos, $currentXPos
        #                   - The position to use. If either are not defined, the current insertion
        #                       position is used
        #
        # Return values
        #   'undef' on improper arguments or if the text can't be emptied
        #   1 otherwise

        my ($self, $overwriteFlag, $currentYPos, $currentXPos, $check) = @_;

        # Local variables
        my (
            $stopIter, $lineNum, $posn, $startIter,
            %tooltipHash, %newHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clearBufferBeforePosn', @_);
        }

        # Turn on overwrite mode, if required by the calling function (and if it's not already
        #   turned on)
        if ($overwriteFlag && ! $self->overwriteFlag) {

            $self->enableOverwrite();
        }

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        $self->removeCursor();

        if (! defined $currentYPos || ! defined $currentXPos) {

            # Get the current insertion position (or the end of the buffer, if no insertion position
            #   is set)
            ($currentYPos, $currentXPos) = $self->getInsertPosn();
        }

        $stopIter = $self->buffer->get_iter_at_line_offset($currentYPos, $currentXPos);
        $lineNum = $stopIter->get_line();
        $posn = $stopIter->get_visible_line_offset();
        $startIter = $self->buffer->get_start_iter();
        if (! $startIter || ! $stopIter) {

            return undef;
        }

        # Empty the buffer up to the specified position
        $self->buffer->delete($startIter, $stopIter);

        # Update IVs generally
        $self->ivPoke('nextDeleteLine', 0);

        if (! $self->buffer->get_char_count()) {

            $self->ivPoke('bufferTextFlag', FALSE);
            $self->ivPoke('newLineFlag', TRUE);

        } else {

            $self->ivPoke('bufferTextFlag', TRUE);
            # (->newLineFlag retains its current value)
        }

        $self->ivPoke('sizeUpdateFlag', TRUE);
        $self->ivPoke('insertNewLineFlag', TRUE);
        $self->ivUndef('insertMark');
        $self->ivUndef('restoreInsertMark');
        $self->ivUndef('tempInsertMark');
        $self->ivUndef('systemInsertMark');

        if ($self->storePosnYPos < $currentYPos) {

            $self->ivPoke('storePosnYPos', 0);
            $self->ivPoke('storePosnXPos', 0);

        } elsif ($self->storePosnYPos == $currentYPos) {

            $self->ivPoke('storePosnYPos', 0);
            $self->ivPoke('storePosnXPos', $self->storePosnXPos - $posn);

        } else {

            $self->ivPoke('storePosnYPos', $self->storePosnYPos - $lineNum);
        }

        %tooltipHash = $self->tooltipHash;
        foreach my $key (keys %tooltipHash) {

            my ($value, $modKey);

            $value = $tooltipHash{$key};
            $modKey = $key - $currentYPos;

            if ($modKey >= 0) {

                $newHash{$modKey} = $value;
            }
        }

        $self->ivPoke('tooltipHash', %newHash);
        $self->ivUndef('lastTooltipLine');

        # Destroy any GA::Obj::Link objects whose links are no longer visible
        $self->reset_link();

        # In case the visible cursor is at a position that's now been overwritten, redraw it
        $self->replaceCursor();

        return 1;
    }

    sub clearBufferAfterPosn {

        # Can be called by anything
        # Empties the Gtk3::TextBuffer of text after a specified position
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $overwriteFlag  - If TRUE, overwite mode is turned on (if not already on). If FALSE or
        #                       'undef', no change to overwrite mode is made
        #   $currentYPos, $currentXPos
        #                   - The position to use. If either are not defined, the current insertion
        #                       position is used
        #
        # Return values
        #   'undef' on improper arguments or if the text can't be emptied
        #   1 otherwise

        my ($self, $overwriteFlag, $currentYPos, $currentXPos, $check) = @_;

        # Local variables
        my ($startIter, $lineNum, $posn, $stopIter, $lastChar, $oldBufferSize);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clearBufferAfterPosn', @_);
        }

        # Turn on overwrite mode, if required by the calling function (and if it's not already
        #   turned on)
        if ($overwriteFlag && ! $self->overwriteFlag) {

            $self->enableOverwrite();
        }

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        $self->removeCursor();

        if (! defined $currentYPos || ! defined $currentXPos) {

            # Get the current insertion position (or the end of the buffer, if no insertion position
            #   is set)
            ($currentYPos, $currentXPos) = $self->getInsertPosn();
        }

        $startIter = $self->buffer->get_iter_at_line_offset($currentYPos, $currentXPos);
        $lineNum = $startIter->get_line();
        $posn = $startIter->get_visible_line_offset();
        $stopIter = $self->buffer->get_end_iter();
        $oldBufferSize = $stopIter->get_line();
        if (! $startIter || ! $stopIter) {

            return undef;
        }

        # Empty the buffer from the specified position
        $self->buffer->delete($startIter, $stopIter);

        # Update IVs generally
        if ($self->nextDeleteLine < $lineNum) {

            $self->ivPoke('nextDeleteLine', $lineNum);
        }

        # Test the last character in the remaining buffer
        $stopIter = $self->buffer->get_end_iter();
        if (! $stopIter->backward_char()) {

            $self->ivPoke('bufferTextFlag', FALSE);

        } else {

            $self->ivPoke('bufferTextFlag', TRUE);
            $lastChar = $stopIter->get_text($self->buffer->get_end_iter());
            if ($lastChar eq "\n") {
                $self->ivPoke('newLineFlag', TRUE);
            } else {
                $self->ivPoke('newLineFlag', FALSE);
            }
        }

        $self->ivPoke('sizeUpdateFlag', TRUE);

        foreach my $iv (qw( insertMark restoreInsertMark systemInsertMark systemTextBuffer) ) {

            if (defined $self->$iv && ! $self->buffer->get_iter_at_mark($self->$iv)) {

                $self->ivUndef($iv);
                if ($iv eq 'insertMark') {

                    # If buffer is empty, this flag is TRUE
                    if (! $self->buffer->get_char_count()) {
                        $self->ivPoke('insertNewLineFlag', TRUE);
                    } else {
                        $self->ivPoke('insertNewLineFlag', FALSE);
                    }
                }
            }
        }

        if (
            $self->storePosnYPos > $lineNum
            || ($self->storePosnYPos == $lineNum && $self->storePosnXPos > $posn)
        ) {
            # The stored cursor location is invalidated
            $self->ivPoke('storePosnYPos', 0);
            $self->ivPoke('storePosnXPos', 0);
        }

        if ($oldBufferSize > $lineNum) {

            for (my $key = ($lineNum + 1); $key <= $oldBufferSize; $key++) {

                # (For speed, don't use ->ivDelete)
                delete $self->{tooltipHash}{$key};
            }
        }

        $self->ivUndef('lastTooltipLine');

        # Destroy any GA::Obj::Link objects whose links are no longer visible
        $self->reset_link();

        # In case the visible cursor is at a position that's now been overwritten, redraw it
        $self->replaceCursor();

        return 1;
    }

    sub clearLineBeforePosn {

        # Called by GA::Session->processCtrlSequence (or by any other code)
        # Given a specified position on a line in the Gtk3::TextBuffer, empties everything on the
        #   line up to that point
        # (In other words, all characters before the position are replaced by space characters)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $overwriteFlag  - If TRUE, overwite mode is turned on (if not already on). If FALSE or
        #                       'undef', no change to overwrite mode is made
        #   $currentYPos, $currentXPos
        #                   - The position to use. If either are not defined, the current insertion
        #                       position is used
        #
        # Return values
        #   'undef' on improper arguments or if the text can't be cleared
        #   1 otherwise

        my ($self, $overwriteFlag, $currentYPos, $currentXPos, $check) = @_;

        # Local variables
        my ($startIter, $text);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clearLineBeforePosn', @_);
        }

        # Turn on overwrite mode, if required by the calling function (and if it's not already
        #   turned on)
        if ($overwriteFlag && ! $self->overwriteFlag) {

            $self->enableOverwrite();
        }

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        $self->removeCursor();

        if (! defined $currentYPos || ! defined $currentXPos) {

            # Get the current insertion position (or the end of the buffer, if no insertion position
            #   is set)
            ($currentYPos, $currentXPos) = $self->getInsertPosn();
        }

        if ($currentXPos == 0) {

            # Nothing to remove, as the insert position is at the beginning of the line
            return 1;
        }

        $startIter = $self->buffer->get_iter_at_line_offset($currentYPos, 0);
        $text = ' ' x $currentXPos;

        $self->buffer->insert_with_tags_by_name($startIter, $text);

        # (No IVs to update generally)

        # In case the visible cursor is at a position that's now been overwritten, redraw it
        $self->replaceCursor();

        return 1;
    }

    sub clearLineAroundPosn {

        # Called by GA::Session->processCtrlSequence (or by any other code)
        # Clears the line at the specified position
        # (In other words, all characters on the same line are replaced by space characters)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $overwriteFlag  - If TRUE, overwite mode is turned on (if not already on). If FALSE or
        #                       'undef', no change to overwrite mode is made
        #   $currentYPos, $currentXPos
        #                   - The position to use. If either are not defined, the current insertion
        #                       position is used
        #
        # Return values
        #   'undef' on improper arguments or if the text can't be cleared
        #   1 otherwise

        my ($self, $overwriteFlag, $currentYPos, $currentXPos, $check) = @_;

        # Local variables
        my ($startIter, $stopIter, $length, $text);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clearLineAroundPosn', @_);
        }

        # Turn on overwrite mode, if required by the calling function (and if it's not already
        #   turned on)
        if ($overwriteFlag && ! $self->overwriteFlag) {

            $self->enableOverwrite();
        }

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        $self->removeCursor();

        if (! defined $currentYPos || ! defined $currentXPos) {

            # Get the current insertion position (or the end of the buffer, if no insertion position
            #   is set)
            ($currentYPos, $currentXPos) = $self->getInsertPosn();
        }

        $startIter = $self->buffer->get_iter_at_line_offset($currentYPos, 0);
        $stopIter = $self->buffer->get_iter_at_line_offset(($currentYPos + 1), 0);
        $stopIter->backward_char();
        $length = $stopIter->get_visible_line_offset() - $startIter->get_visible_line_offset();
        $text = ' ' x $length;
        $self->buffer->insert_with_tags_by_name($startIter, $text);

        # (No IVs to update generally)

        # In case the visible cursor is at a position that's now been overwritten, redraw it
        $self->replaceCursor();

        return 1;
    }

    sub clearLineAfterPosn {

        # Called by GA::Session->processCtrlSequence (or by any other code)
        # Given a specified position on a line in the Gtk3::TextBuffer, empties the rest of the line
        # (In other words, all characters after the position are replaced by space characters, but
        #   the newline character is preserved, if present)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $overwriteFlag  - If TRUE, overwite mode is turned on (if not already on). If FALSE or
        #                       'undef', no change to overwrite mode is made
        #   $currentYPos, $currentXPos
        #                   - The position to use. If either are not defined, the current insertion
        #                       position is used
        #
        # Return values
        #   'undef' on improper arguments or if the text can't be cleared
        #   1 otherwise

        my ($self, $overwriteFlag, $currentYPos, $currentXPos, $check) = @_;

        # Local variables
        my ($startIter, $lineNum, $length, $endIter, $stopIter);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clearLineAfterPosn', @_);
        }

        # Turn on overwrite mode, if required by the calling function (and if it's not already
        #   turned on)
        if ($overwriteFlag && ! $self->overwriteFlag) {

            $self->enableOverwrite();
        }

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        $self->removeCursor();

        if (! defined $currentYPos || ! defined $currentXPos) {

            # Get the current insertion position (or the end of the buffer, if no insertion position
            #   is set)
            ($currentYPos, $currentXPos) = $self->getInsertPosn();
        }

        $startIter = $self->buffer->get_iter_at_line_offset($currentYPos, $currentXPos);
        $lineNum = $startIter->get_line();
        $length = $self->getLineLength($startIter);

        $endIter = $self->buffer->get_end_iter();
        if ($endIter->get_line() == $startIter->get_line()) {

            # Clear text to the end of the buffer, as we're on the last line
            $stopIter = $endIter;

        } else {

            # Preserve newline character at end of line
            $stopIter = $self->buffer->get_iter_at_line_offset($lineNum, ($length - 1));
        }

        # Clear the line portion
        $self->buffer->delete($startIter, $stopIter);

        # Update IVs generally
        foreach my $iv (qw( insertMark restoreInsertMark systemInsertMark systemTextBuffer) ) {

            if (defined $self->$iv && ! $self->buffer->get_iter_at_mark($self->$iv)) {

                $self->ivUndef($iv);
                if ($iv eq 'insertMark') {

                    # If buffer is empty, this flag is TRUE
                    if (! $self->buffer->get_char_count()) {
                        $self->ivPoke('insertNewLineFlag', TRUE);
                    } else {
                        $self->ivPoke('insertNewLineFlag', FALSE);
                    }
                }
            }
        }

        if (
            $self->storePosnYPos == $lineNum
            && $self->storePosnXPos >= $currentXPos
            && $self->storePosnXPos <= $length
        ) {
            # The stored cursor location is invalidated
            $self->ivPoke('storePosnYPos', 0);
            $self->ivPoke('storePosnXPos', 0);
        }

        # In case the visible cursor is at a position that's now been overwritten, redraw it
        $self->replaceCursor();

        return 1;
    }

    sub getInsertPosn {

        # Called by several functions in this textview object
        # Also alled by GA::Session->processMxpLinkElement, ->processMxpSendElement,
        #   GA::Session->processLineSegment or by any other code
        # Gets the position in the Gtk3::TextBuffer at which text is being inserted (via calls to
        #   $self->insertText), expressed in a line number and character offset
        # If no insertion position is specified by $self->insertMark or ->tempInsertMark, returns
        #   the position of the end of the buffer, as if the insertion position was set to that
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, a list in the form (line_number, character_number)

        my ($self, $check) = @_;

        # Local variables
        my (
            $mark, $iter,
            @emptyList,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getInsertPosn', @_);
            return @emptyList;
        }

        # Get the current insertion point
        if ($self->insertMark) {
            $mark = $self->insertMark;
        } elsif ($self->tempInsertMark) {
            $mark = $self->tempInsertMark;
        } elsif ($self->cursorMark) {
            $mark = $self->cursorMark;
        }

        if ($mark) {
            $iter = $self->buffer->get_iter_at_mark($mark);
        } else {
            $iter = $self->buffer->get_end_iter();
        }

        return ($iter->get_line(), $iter->get_visible_line_offset());
    }

    sub setInsertPosn {

        # Called by GA::Session->processMxpDestElement, GA::Session->processCtrlSequence (or by any
        #   other code)
        # Sets the position in the Gtk3::TextBuffer at which text is being inserted (via calls to
        #   $self->insertText, ->insertMultipleText, ->insertWithLinks or ->insertCmd)
        # The position is expressed as a line number and character offset
        # If the specified position doesn't exist, newline character and whitespace are added to
        #   the buffer so that text can be inserted there
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $yPos       - The line number. If 'undef', line 0 is used
        #   $xPos       - The character offset. If 'undef', offset 0 is used
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $yPos, $xPos, $check) = @_;

        # Local variables
        my (
            $lineIter, $length, $endIter, $posn, $beforeIter, $beforeString, $insertIter,
            $insertMark, $restoreMark,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setInsertPosn', @_);
        }

        # Turn on overwrite mode, if it's not already on
        if (! $self->overwriteFlag) {

            $self->enableOverwrite();
        }

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        $self->removeCursor();

        # Use default line number/character offset if they weren't specified
        if (! defined $yPos) {

            $yPos = 0;
        }

        if (! defined $xPos) {

            $xPos = 0;
        }

        # Before v3.20, Gtk doesn't allow the use of an invalid position, so we must check it's
        #   valid before proceeding

        # Check the end of the buffer
        if ($yPos > ($self->buffer->get_line_count() - 1)) {

            # The specified line doesn't exist, so we need to add some new (empty) ones
            do {

                $self->buffer->insert($self->buffer->get_end_iter(), "\n");

            } until ($yPos <= ($self->buffer->get_line_count() - 1));
        }

        # Check the size of the specified line
        $lineIter = $self->buffer->get_iter_at_line($yPos);
        $length = $self->getLineLength($lineIter);
        # Get the position of the iter just before the line's newline character, if any (there won't
        #   be one if this line is at the end of the buffer)
        # (Don't need to check that $endIter->get_visible_line_offset() matches the same value in
        #   $lineIter, since we already know it's the last line)
        $endIter = $self->buffer->get_end_iter();
        if ($endIter->get_line() == $lineIter->get_line()) {
            $posn = $length;
        } else {
            $posn = $length - 1;
        }

        # Check the length of the specified line
        if ($xPos > $posn) {

            # The specified line offset doesn't exist, so we need to add some empty space
            $beforeIter = $self->buffer->get_iter_at_line_offset($yPos, $posn);
            $beforeString = ' ' x ($xPos - $posn);
            $self->buffer->insert($beforeIter, $beforeString);
        }

        # Set the new insert position, storing the current position in case $self->resetInsertPosn
        #   is called
        $insertIter = $self->buffer->get_iter_at_line_offset($yPos, $xPos);
        $insertMark = $self->buffer->create_mark('insert_mark', $insertIter, TRUE);
        $self->ivPoke('insertMark', $insertMark);

        $insertIter = $self->buffer->get_iter_at_line_offset($yPos, $xPos);
        $restoreMark = $self->buffer->create_mark('restore_insert_mark', $insertIter, TRUE);
        $self->ivPoke('restoreInsertMark', $restoreMark);

        # If the cursor is visible, move it to this position (i.e. insert a new Gtk3::TextTag)
        $self->moveCursor($self->buffer->get_iter_at_mark($insertMark));

        return 1;
    }

    sub resetInsertPosn {

        # Called by GA::Session->processMxpDestElement (or by any other code)
        # Resets the position in the Gtk3::TextBuffer at which text is being inserted to the
        #   position before the most recent call to $self->setInsertPosn
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetInsertPosn', @_);
        }

        $self->ivPoke('insertMark', $self->restoreInsertMark);
        $self->ivUndef('restoreInsertMark');

        return 1;
    }

    sub adjustInsertPosn {

        # Called by GA::Session->processCtrlSequence (or by any other code)
        # Adjusts the position of the current insertion position
        #
        # Expected arguments
        #   $yAdjust    - The line number adjustment, e.g. -1 to move up a line, +2 to move down 2
        #                   lines, 0 to stay on the same line
        #   $xAdjust    - The character offset adjustment, e.g. -1 to move back one character, +2 to
        #                   move forwards 2 characters, 0 to stay in the same column
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the result of the call to $self->setInsertPosn

        my ($self, $yAdjust, $xAdjust, $check) = @_;

        # Local variables
        my ($yPos, $xPos, $iter);

        # Check for improper arguments
        if (! defined $yAdjust || ! defined $xAdjust || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->adjustInsertPosn', @_);
        }

        # Turn on overwrite mode, if it's not already on
        if (! $self->overwriteFlag) {

            $self->enableOverwrite();
        }

        # Get the current insertion position (or the end of the buffer, if no insertion position is
        #   set)
        ($yPos, $xPos) = $self->getInsertPosn();

        # Make the adjustment
        $yPos += $yAdjust;
        $xPos += $xAdjust;

        # Sanity checks. If $xPos is now greater than the length of the existing line,
        #   $self->setInsertPosn will add extra spaces; otherwise, we have to adjust bad values
        #   ourselves
        if ($yPos < 0) {

            $yPos = 0;
        }

        if ($xPos < 0) {

            $xPos = 0;
        }

        $iter = $self->buffer->get_end_iter();
        if ($yPos > $iter->get_line()) {

            $yPos = $iter->get_line();
        }

        # Change the insertion position
        return $self->setInsertPosn($yPos, $xPos);
    }

    sub adjustInsertLine {

        # Called by GA::Session->processCtrlSequence (or by any other code)
        # Adjusts the position of the current insertion position, moving it to the beginning of a
        #   line
        #
        # Expected arguments
        #   $yAdjust    - The line number adjustment, e.g. -1 to move up a line, +2 to move down 2
        #                   lines, 0 to stay on the same line
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the result of the call to $self->setInsertPosn

        my ($self, $yAdjust, $check) = @_;

        # Local variables
        my ($yPos, $xPos, $iter);

        # Check for improper arguments
        if (! defined $yAdjust || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->adjustInsertLine', @_);
        }

        # Turn on overwrite mode, if it's not already on
        if (! $self->overwriteFlag) {

            $self->enableOverwrite();
        }

        # Get the current insertion position (or the end of the buffer, if no insertion position is
        #   set)
        ($yPos) = $self->getInsertPosn();

        # Make the adjustment
        $yPos += $yAdjust;
        $xPos = 0;

        # Sanity checks. If $xPos is now greater than the length of the existing line,
        #   $self->setInsertPosn will add extra spaces; otherwise, we have to adjust bad values
        #   ourselves
        if ($yPos < 0) {

            $yPos = 0;
        }

        $iter = $self->buffer->get_end_iter();
        if ($yPos > $iter->get_line()) {

            $yPos = $iter->get_line();
        }

        # Change the insertion position
        return $self->setInsertPosn($yPos, $xPos);
    }

    sub adjustInsertOffset {

        # Called by GA::Session->processCtrlSequence (or by any other code)
        # Adjusts the position of the current insertion position
        #
        # Expected arguments
        #   $xPos       - The character offset. If 'undef', offset 0 is used
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the result of the call to $self->setInsertPosn

        my ($self, $xPos, $check) = @_;

        # Local variables
        my $yPos;

        # Check for improper arguments
        if (! defined $xPos || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->adjustInsertOffset', @_);
        }

        # Turn on overwrite mode, if it's not already on
        if (! $self->overwriteFlag) {

            $self->enableOverwrite();
        }

        # Get the current insertion position (or the end of the buffer, if no insertion position is
        #   set)
        ($yPos) = $self->getInsertPosn();

        # Sanity checks. If $xPos is now greater than the length of the existing line,
        #   $self->setInsertPosn will add extra spaces; otherwise, we have to adjust bad values
        #   ourselves
        if ($xPos < 0) {

            $xPos = 0;
        }

        # Change the insertion position
        return $self->setInsertPosn($yPos, $xPos);
    }

    sub storeInsertPosn {

        # Called by GA::Session->processCtrlSequence (or by any other code)
        # Stores the current insertion position, so it can be re-used as the new insertion position
        #   at some point in the future
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $overwriteFlag  - If TRUE, overwite mode is turned on (if not already on). If FALSE or
        #                       'undef', no change to overwrite mode is made
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $overwriteFlag, $check) = @_;

        # Local variables
        my ($currentYPos, $currentXPos);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->storeInsertPosn', @_);
        }

        # Turn on overwrite mode, if required by the calling function (and if it's not already
        #   turned on)
        if ($overwriteFlag && ! $self->overwriteFlag) {

            $self->enableOverwrite();
        }

        # Get the current insertion position (or the end of the buffer, if no insertion position is
        #   set)
        ($currentYPos, $currentXPos) = $self->getInsertPosn();

        $self->ivPoke('storePosnYPos', $currentYPos);
        $self->ivPoke('storePosnXPos', $currentXPos);

        return 1;
    }

    sub restoreInsertPosn {

        # Called by GA::Session->processCtrlSequence (or by any other code)
        # Restores the cursor position stored in an earlier call to $self->storeInsertPosn
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the result of the call to $self->setInsertPosn

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->restoreInsertPosn', @_);
        }

        # Turn on overwrite mode, if it's not already on
        if (! $self->overwriteFlag) {

            $self->enableOverwrite();
        }

        return $self->setInsertPosn($self->storePosnYPos, $self->storePosnXPos);
    }

    sub insertBackspace {

        # Called mostly by GA::Session->processIncomingData
        # Inserts a string probably containing one or more backspace characters
        # If overwrite mode is one, processes the string as received. If overwrite mode is off,
        #   replaces the backspace character with good ol' fashioned '^H', and displays it as a
        #   normal string
        #
        # Expected arguments
        #   $string - The string to insert. It's usually in the form "\b \b", or just "\b", but can
        #               contain any combination of characters (including an empty string)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $string, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (! defined $string || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->insertBackspace', @_);
        }

        if ($string eq '') {

            # Nothing to insert
            return 1;

        } elsif (! $self->overwriteFlag) {

            # Replace the backspace characters with ^H, and display $string as an ordinary string
            $string =~ s/\b/^H/g;
            return $self->insertText($string, 'echo');
        }

        # Otherwise, split $string into segments, adjusting the insert position for each backspace
        #   character it contains
        do {

            my ($index, $yPos, $xPos);

            $index = index($string, "\b");
            if ($index == 0) {

                # Set the new insert position one character earlier in the line (but if already at
                #   the beginning of a line, don't go any further backwards in the buffer)
                ($yPos, $xPos) = $self->getInsertPosn();
                if ($xPos > 0) {

                    $self->setInsertPosn($yPos, ($xPos - 1));
                }

                $string = substr($string, 1);

            } elsif ($index == -1 ) {

                # The rest of $string contains no backspace characters
                $self->insertText($string, 'echo');
                $string = '';

            } else {

                # String starts with one or more non-backspace characters
                $self->insertText(substr($string, 0, $index), 'echo');
                $string = substr($string, $index);
            }

        } until ($string eq '');

        return 1;
    }

    sub scrlRegionUp {

        # Called by $self->insertNewLine and GA::Session->processCtrlSequence
        # VT100 (and similar terminal standards) define an area of the textview, the scroll region,
        #   which should 'scroll' independently of the rest of the textview
        # Actually, when the region 'scrolls', we just delete the line at the top of the region,
        #   and add a new line at the bottom of it
        #
        # Expected arguments
        #   $num        - The number of lines to scroll (when called by $self->insertNewLine, set
        #                   to 1)
        #
        # Optional arguments
        #   $nlFlag     - Set to TRUE if the calling function hasn't inserted a newline character at
        #                   the bottom of the region (in which case, this function needs to do it).
        #                   Set to FALSE (or 'undef') if the newline character has already been
        #                   inserted, in which case this function only needs to delete the line at
        #                   the top of the region
        #
        # Return values
        #   'undef' on improper arguments, if the scroll region doesn't exist, if $num is not a
        #       positive integer or if the scroll region's IVs are set to invalid values
        #   1 otherwise

        my ($self, $num, $nlFlag, $check) = @_;

        # Check for improper arguments
        if (! defined $num || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->scrlRegionUp', @_);
        }

        # Check a scrolling region is defined, that $num is a valid integer, and that the buffer
        #   actually contains at least as many lines as specified by $self->scrlRegionBottom
        if (
            ! defined $self->scrlRegionTop
            || ! $axmud::CLIENT->intCheck($num, 1)
            || ($self->buffer->get_line_count() - 1) < ($self->scrlRegionBottom + 1)
        ) {
            return undef;
        }

        # Update the scrolling region $num times
        for (my $count = 0; $count < $num; $count++) {

            $self->buffer->delete(
                $self->buffer->get_iter_at_line_offset($self->scrlRegionTop, 0),
                $self->buffer->get_iter_at_line_offset(($self->scrlRegionTop + 1), 0),
            );

            if ($nlFlag) {

                # Newline character(s) haven't been inserted into the buffer by the calling
                #   function, so we need to insert them here
                $self->buffer->insert(
                    $self->buffer->get_iter_at_line_offset($self->scrlRegionBottom, 0),
                    "\n",
                );
            }

            # Update the tooltip IVs
            for (my $line = ($self->scrlRegionTop + 1); $line <= $self->scrlRegionBottom; $line++) {

                $self->ivAdd('tooltipHash', ($line - 1), $self->ivShow('tooltipHash', $line));
            }

            $self->ivAdd('tooltipHash', $self->scrlRegionBottom, '');
            $self->ivPoke('lastTooltipLine', undef);
        }

        # Operation complete
        return 1;
    }

    sub scrlRegionDown {

        # Called by GA::Session->processCtrlSequence (only)
        # VT100 (and similar terminal standards) define an area of the textview, the scroll region,
        #   which should 'scroll' independently of the rest of the textview
        # Actually, when the region 'scrolls', we just delete the line at the bottom of the region,
        #   and add a new line at the top of it
        #
        # Expected arguments
        #   $num        - The number of lines to scroll
        #
        # Return values
        #   'undef' on improper arguments, if the scroll region doesn't exist, if $num is not a
        #       positive integer or if the scroll region's IVs are set to invalid values
        #   1 otherwise

        my ($self, $num, $nlFlag, $check) = @_;

        # Check for improper arguments
        if (! defined $num || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->scrlRegionDown', @_);
        }

        # Check a scrolling region is defined, that $num is a valid integer, and that the buffer
        #   actually contains at least as many lines as specified by $self->scrlRegionTop
        if (
            ! defined $self->scrlRegionTop
            || ! $axmud::CLIENT->intCheck($num, 1)
            || ($self->buffer->get_line_count() - 1) < ($self->scrlRegionTop + 1)
        ) {
            return undef;
        }

        # Update the scrolling region $num times
        for (my $count = 0; $count < $num; $count++) {

            $self->buffer->delete(
                $self->buffer->get_iter_at_line_offset($self->scrlRegionBottom, 0),
                $self->buffer->get_iter_at_line_offset(($self->scrlRegionBottom + 1), 0),
            );

            # Newline character(s) haven't been inserted into the buffer by the calling
            #   function, so we need to insert them here
            $self->buffer->insert(
                $self->buffer->get_iter_at_line_offset($self->scrlRegionTop, 0),
                "\n",
            );

            # Update the tooltip IVs
            for (my $line = ($self->scrlRegionBottom - 1); $line >= $self->scrlRegionTop; $line++) {

                $self->ivAdd('tooltipHash', ($line + 1), $self->ivShow('tooltipHash', $line));
            }

            $self->ivAdd('tooltipHash', $self->scrlRegionTop, '');
            $self->ivPoke('lastTooltipLine', undef);
        }

        # Operation complete
        return 1;
    }

    # Other functions - text insertion

    sub insertText {

        # Can be called by anything
        # Inserts text into the Gtk3::TextBuffer, optionally applying Axmud colour/style tags and/or
        #   a newline character, and optionally emptying the buffer of text
        # NB This function doesn't write to any log files; the calling function can do that, if
        #   required
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $text       - The text to write. If undefined, the text <<undef>> is written
        #   @args       - Optional list of arguments, in any order:
        #                   - 'empty' (empties the buffer before writing $text)
        #                   - 'before' (prepends a newline character to $text)
        #                   - 'after' or 'nl' (appends a newline character to $text)
        #                   - 'echo' (does not prepend/append a newline character, overrides
        #                       'before', 'after' and 'nl' if they are specified)
        #                   - one or more Axmud colour tags. Only the first text colour (e.g. 'red')
        #                       is used, and only the first underlay colour ('UL_RED') is used.
        #                       The range of Axmud colour tags include:
        #                       - standard colour tags like 'red', 'BLUE', 'ul_red', 'UL_BLUE'
        #                           (case-sensititive)
        #                       - xterm colour tags (strings in the range 'x0' to 'x255', or
        #                           'ux0' to 'ux255'; case-insensitive, so 'X0' is valid)
        #                       - RGB colour tags (strings in the range '#000000' to '#FFFFFF', or
        #                           'u#000000' to 'u#FFFFFF'; case-insensitive, so 'U#AbCdEf' is
        #                           valid)
        #                   - one or more Axmud style tags ('italics', 'strike', etc)
        #
        #               - NB The default behaviour is set by $self->defaultNewLine, which is set to
        #                   'before', 'after', 'nl' or 'echo'. This default behaviour is only
        #                   applied if none of 'before', 'after', 'nl' and 'echo' are specified
        #
        # Notes
        #   If both 'echo' and any of 'before'/'after'/'nl' are specified (or if neither is
        #       specified), a newline character is NOT appended
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $text, @args) = @_;

        # Local variables
        my (
            $emptyFlag, $beforeFlag, $afterFlag, $linkFlag, $textColour, $underlayColour,
            $monochromeFlag, $beep, $mark, $iter, $tempInsertFlag,
            @styleTags,
        );

        # (No improper arguments to check)

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        $self->removeCursor();
        # If the buffer is due to be cleared before inserting any text, then clear it
        if ($self->clearAfterInsertFlag) {

            # The TRUE argument means 'don't remove/move the cursor'
            $self->clearBuffer(undef, TRUE);
        }

        # Interpret the list of @args
        ($emptyFlag, $beforeFlag, $afterFlag, $linkFlag, $textColour, $underlayColour, @styleTags)
            = $self->interpretTags($self->newLineDefault, @args);
        # Apply any colour overrides specified by the colour scheme or by this object's own
        #   monochrome mode
        ($monochromeFlag, $textColour, $underlayColour) = $self->modifyColourTags(
            $textColour,
            $underlayColour,
        );

        # Choose which colour tags to use (in monochrome mode, text/underlay colours are ignored)
        if (! $textColour) {

            $textColour = $self->textColour;
        }

        if (! $underlayColour) {

            $underlayColour = $self->underlayColour;
        }

        # If allowed, convert the colour of invisible text (e.g. black text with a black underlay
        #   on a black background) to something visible
        if (
            $axmud::CLIENT->convertInvisibleFlag
            && $textColour eq $self->backgroundColour
            && (
                $underlayColour eq 'ul_' . $self->backgroundColour
                || $underlayColour eq 'UL_' . $self->backgroundColour
            )
        ) {
            if ($axmud::CLIENT->ivExists('constPrettyTagHash', $textColour)) {
                $textColour = uc($textColour);
            } else {
                $textColour = lc($textColour);
            }
        }

        # Empty the buffer before writing text, if required
        if ($emptyFlag) {

            # The TRUE argument means 'don't remove/move the cursor'
            $self->clearBuffer(undef, TRUE);
        }

        # Prepare the message to send
        if (! defined $text) {

            # 'undef' is a valid value - represent it
            $text = "<<undef>>";
        }

        # If $text contains any ASCII 7 characters (bells) and sound is on, play the 'bell' sound.
        #   After that, even if sound is off, remove the ASCII 7 character from $text
        $beep = chr(7);
        if ($text =~ m/$beep/) {

            # Don't display the ASCII 7 character
            $text =~ s/$beep//g;

            # Play the bell once, if allowed (even if the character appears multiple times in $text;
            #   the call to ->playSound checks the status of GA::Client->allowSoundFlag)
            if ($axmud::CLIENT->allowAsciiBellFlag) {

                $axmud::CLIENT->playSound('bell');
            }
        }

        # Set the insertion point
        if ($self->insertMark) {

            $mark = $self->insertMark;

        } elsif ($self->tempInsertMark) {

            $mark = $self->tempInsertMark;
            if ($afterFlag) {

                # This code prevents a blank line being inserted between a world's prompt and the
                #   already-displayed Axmud system message
                $self->ivUndef('tempInsertMark');
                $afterFlag = FALSE;
                $tempInsertFlag = TRUE;
            }
        }

        if ($mark) {
            $iter = $self->buffer->get_iter_at_mark($mark);
        } elsif (! $self->systemInsertMark) {
            $iter = $self->buffer->get_end_iter();
        } else {

            # Incomplete system message after a call to $self->showSystemText without a newline
            #   character. Must insert an artificial newline character, and display $text after
            #   that
            $iter = $self->buffer->get_iter_at_mark($self->systemInsertMark);
            $iter = $self->insertNewLine($iter);
            $self->ivPoke('prevColourStyleHash', $self->colourStyleHash);
        }

        # (Don't prepend a newline character if the buffer is empty)
        if ($beforeFlag && $self->bufferTextFlag) {

            # (Make sure the beginning of a link appears after the extra newline character, not
            #   before it)
            $iter = $self->insertNewLine($iter);
            $self->ivPoke('prevColourStyleHash', $self->colourStyleHash);
        }

        # Create a link object, if required
        if ($linkFlag && $text) {

            $self->setupLink($iter, $text);
        }

        # Insert the text into the Gtk3::TextBuffer
        if (! $monochromeFlag) {

            $iter = $self->insertWithTags(
                $iter,
                $text,
                $textColour,
                $underlayColour,
                @styleTags,
            );

        } else {

            $iter = $self->insertWithTags(
                $iter,
                $text,
                @styleTags,
            );
        }

        if ($afterFlag) {

            # (Make sure the end of a link appears before the extra newline character, not
            #   after it)
            $iter = $self->insertNewLine($iter);
            $self->ivPoke('prevColourStyleHash', $self->colourStyleHash);
        }

        if ($self->insertMark) {

            # The next call to $self->insertText, ->insertCmd etc uses the insertion point
            #   immediately after $iter
            $mark = $self->buffer->create_mark('insert_mark', $iter, TRUE);
            $self->ivPoke('insertMark', $mark);
            # If the cursor is visible, move it to this position (i.e. insert a new Gtk3::TextTag)
            $self->moveCursor($self->buffer->get_iter_at_mark($mark));

        } elsif ($tempInsertFlag) {

            # Continue using this temporary insertion point, before a line with a system message
            #   (and don't restore the cursor yet)
            $mark = $self->buffer->create_mark('temp_insert_mark', $iter, TRUE);
            $self->ivPoke('tempInsertMark', $mark);

        } else {

            # If the cursor is visible, move it to the end of the buffer (i.e. insert a new
            #   Gtk3::TextTag)
            $self->moveCursor();
        }

        # Apply scroll lock, if required
        if ($self->scrollLockFlag) {

            if ($self->scrollLockType eq 'top') {
                $self->scrollToTop();
            } else {
                $self->scrollToBottom();
            }
        }

        return 1;
    }

    sub insertMultipleText {

        # Can be called by anything (but mostly called by Session->displayLinePieces)
        # Instead of calling $self->insertText multiple times, this function can be called a single
        #   time for multiple pieces of text (which should save some processing time)
        #
        # Calls to $self->insertText use the default behaviour specified by $self->defaultNewLine,
        #   if none of the arguments 'empty', 'before', 'after', 'nl' or 'echo' are specified
        # However, this function ignores those arguments, except for 'before' for the first text
        #   piece and 'after' for the last text piece (if specified); for every other text piece,
        #   the default behaviour 'echo' is used
        #
        # Expected arguments
        #   @displayList    - List in groups of 2, in the form
        #                       (piece_of_text, reference_to_list_of_arguments)
        #                     ...where each group of 2 is the same as the arguments used in a single
        #                       call to $self->insertText
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, @displayList) = @_;

        # Local variables
        my ($firstFlag, $iter, $mark, $finalAfterFlag, $tempInsertFlag);

        # Check for improper arguments
        if (! @displayList) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->insertMultipleText', @_);
        }

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        $self->removeCursor();
        # If the buffer is due to be cleared before inserting any text, then clear it
        if ($self->clearAfterInsertFlag) {

            # The TRUE argument means 'don't remove/move the cursor'
            $self->clearBuffer(undef, TRUE);
        }

        # Some operations are only executed for the first 'piece_of_text' in @displayList
        $firstFlag = TRUE;

        # Process each text piece in turn
        do {

            my (
                $text, $listRef, $emptyFlag, $beforeFlag, $afterFlag, $linkFlag, $textColour,
                $underlayColour, $monochromeFlag, $beep,
                @styleTags,
            );

            $text = shift @displayList;
            $listRef = shift @displayList;

            # Interpret the list of @args
            (
                $emptyFlag, $beforeFlag, $afterFlag, $linkFlag, $textColour, $underlayColour,
                @styleTags,
            ) = $self->interpretTags($self->newLineDefault, @$listRef);
            # Apply any colour overrides specified by the colour scheme or by this object's own
            #   monochrome mode
            ($monochromeFlag, $textColour, $underlayColour) = $self->modifyColourTags(
                $textColour,
                $underlayColour,
            );

            # Choose which colour tags to use (in monochrome mode, text/underlay colours are
            #   ignored)
            if (! $textColour) {

                $textColour = $self->textColour;
            }

            if (! $underlayColour) {

                $underlayColour = $self->underlayColour;
            }

            # If allowed, convert the colour of invisible text (e.g. black text with a black
            #   underlay on a black background) to something visible
            if (
                $axmud::CLIENT->convertInvisibleFlag
                && $textColour eq $self->backgroundColour
                && (
                    $underlayColour eq 'ul_' . $self->backgroundColour
                    || $underlayColour eq 'UL_' . $self->backgroundColour
                )
            ) {
                if ($axmud::CLIENT->ivExists('constPrettyTagHash', $textColour)) {
                    $textColour = uc($textColour);
                } else {
                    $textColour = lc($textColour);
                }
            }

            # Empty the buffer before writing text, if required
            if ($emptyFlag) {

                # The TRUE argument means 'don't remove/move the cursor'
                $self->clearBuffer(undef, TRUE);
            }

            # Prepare the message to send
            if (! defined $text) {

                # 'undef' is a valid value - represent it
                $text = "<<undef>>";
            }

            # If $text contains any ASCII 7 characters (bells) and sound is on, play the 'bell'
            #   sound. After that, even if sound is off, remove the ASCII 7 character from $text
            $beep = chr(7);
            if ($text =~ m/$beep/) {

                # Don't display the ASCII 7 character
                $text =~ s/$beep//g;

                # Play the bell once, if allowed (even if the character appears multiple times in
                #   $text; the call to ->playSound checks the status of GA::Client->allowSoundFlag)
                if ($axmud::CLIENT->allowAsciiBellFlag) {

                    $axmud::CLIENT->playSound('bell');
                }
            }

            # For the first text piece, set the insertion point (all other pieces are inserted
            #   directly after that)
            if ($firstFlag) {

                # Set the insertion point
                if ($self->insertMark) {

                    $mark = $self->insertMark;

                } elsif ($self->tempInsertMark) {

                    $mark = $self->tempInsertMark;
                    if ($afterFlag) {

                        # This code prevents a blank line being inserted between a world's prompt
                        #   and the already-displayed Axmud system message
                        $self->ivUndef('tempInsertMark');
                        $afterFlag = FALSE;
                        # Act on the temporary insertion point once we've finished this do... loop
                        $tempInsertFlag = TRUE;
                    }
                }

                if ($mark) {
                    $iter = $self->buffer->get_iter_at_mark($mark);
                } elsif (! $self->systemInsertMark) {
                    $iter = $self->buffer->get_end_iter();
                } else {

                    # Incomplete system message after a call to $self->showSystemText without a
                    #   newline character. Must insert an artificial newline character, and display
                    #   $text after that
                    $iter = $self->buffer->get_iter_at_mark($self->systemInsertMark);
                    $iter = $self->insertNewLine($iter);
                    $self->ivPoke('prevColourStyleHash', $self->colourStyleHash);
                }

                # (Don't prepend a newline character if the buffer is empty, or for any text piece
                #   besides the first one)
                if ($beforeFlag && $self->bufferTextFlag) {

                    # (Make sure the beginning of a link appears after the extra newline character,
                    #   not before it)
                    $iter = $self->insertNewLine($iter);
                    $self->ivPoke('prevColourStyleHash', $self->colourStyleHash);
                }
            }

            # Create a link object, if required
            if ($linkFlag && $text) {

                $self->setupLink($iter, $text);
            }

            # Insert the text into the Gtk3::TextBuffer
            if (! $monochromeFlag) {

                $iter = $self->insertWithTags(
                    $iter,
                    $text,
                    $textColour,
                    $underlayColour,
                    @styleTags,
                );

            } else {

                $iter = $self->insertWithTags(
                    $iter,
                    $text,
                    @styleTags,
                );
            }

            # (Don't append a newline character for any text piece besides the last one)
            if (! @displayList && ($afterFlag || $tempInsertFlag)) {

                if (! $tempInsertFlag) {

                    # (Make sure the end of a link appears before the extra newline character, not
                    #   after it)
                    $iter = $self->insertNewLine($iter);
                    $self->ivPoke('prevColourStyleHash', $self->colourStyleHash);

                } else {

                    $iter = $self->buffer->get_end_iter();
                }

                $finalAfterFlag = TRUE;
            }

            # (Don't execute this some code blocks more than once)
            $firstFlag = FALSE;

        } until (! @displayList);

        if ($self->insertMark) {

            # The next call to $self->insertText, ->insertCmd etc uses the insertion point
            #   immediately after $iter
            $mark = $self->buffer->create_mark('insert_mark', $iter, TRUE);
            $self->ivPoke('insertMark', $mark);
            # If the cursor is visible, move it to this position (i.e. insert a new Gtk3::TextTag)
            $self->moveCursor($self->buffer->get_iter_at_mark($mark));

        } elsif ($tempInsertFlag && ! $finalAfterFlag) {

            # Continue using this temporary insertion point, before a line with a system message
            #   (and don't restore the cursor yet)
            $mark = $self->buffer->create_mark('temp_insert_mark', $iter, TRUE);
            $self->ivPoke('tempInsertMark', $mark);

        } else {

            # If the cursor is visible, move it to the end of the buffer (i.e. insert a new
            #   Gtk3::TextTag)
            $self->moveCursor();
        }

        # Apply scroll lock, if required
        if ($self->scrollLockFlag) {

            if ($self->scrollLockType eq 'top') {
                $self->scrollToTop();
            } else {
                $self->scrollToBottom();
            }
        }

        return 1;
    }

    sub insertWithLinks {

        # Can be called by any code
        # When a GA::Session receives text from the world, it automatically searches it for
        #   anything that looks like a clickable link, and divides the text into segments,
        #   assigning Axmud style tags as appropriate to make each link clickable
        # This function can be called by any non-session code that wants to send a piece of text to
        #   $self->insertText, and to have any links converted into clickable links automatically
        # The calling function specifies some $text. This function splits it into one or more
        #   segments, and calls $self->insertText for each segment, adding a 'link' tag when the
        #   whole segment is a clickable link, but otherwise preserving the calling function's
        #   arguments
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $text       - The text to write. If undefined, the text <<undef>> is written
        #   @args       - Optional list of arguments, in any order:
        #                   - 'empty' (empties the buffer before writing $text)
        #                   - 'before' (prepends a newline character to $text)
        #                   - 'after' or 'nl' (appends a newline character to $text)
        #                   - 'echo' (does not prepend/append a newline character, overrides
        #                       'before', 'after' and 'nl' if they are specified)
        #                   - one or more Axmud colour tags. Only the first text colour (e.g. 'red')
        #                       is used, and only the first underlay colour ('UL_RED') is used.
        #                       The range of Axmud colour tags include:
        #                       - standard colour tags like 'red', 'BLUE', 'ul_red', 'UL_BLUE'
        #                           (case-sensititive)
        #                       - xterm colour tags (strings in the range 'x0' to 'x255', or
        #                           'ux0' to 'ux255'; case-insensitive, so 'X0' is valid)
        #                       - RGB colour tags (strings in the range '#000000' to '#FFFFFF', or
        #                           'u#000000' to 'u#FFFFFF'; case-insensitive, so 'U#AbCdEf' is
        #                           valid)
        #                   - one or more Axmud style tags ('italics', 'strike', etc. If it includes
        #                       'link', $text isn't split into segments; we just call
        #                       $self->insertText directly)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the return value of the final call to $self->insertText

        my ($self, $text, @args) = @_;

        # Local variables
        my (
            $url, $shortUrl, $longMail, $mail, $result,
            @firstArgs, @lastArgs, @otherArgs,
        );

        # (No improper arguments to check)

        # Special case - if $text contains no characters, no point searching it for clickable links
        if (! $text) {

            return $self->insertText($text, @args);
        }

        # Remove 'empty', 'before', 'after', 'nl' and 'echo' from @args temporarily, so they can be
        #   used in the first/last calls to ->insertText as required
        # If @args contains 'link', then the whole of $text is treated as a clickable link and we
        #   can call ->insertText immediately
        foreach my $item (@args) {

            my $flag;

            if ($item eq 'link') {

                return $self->insertText($text, @args);
            }

            if ($item eq 'empty' || $item eq 'before' || $item eq 'echo') {

                push (@firstArgs, $item);
                $flag = TRUE;
            }

            if ($item eq 'after' || $item eq 'nl' || $item eq 'echo') {

                push (@lastArgs, $item);
                $flag = TRUE;
            }

            if (! $flag) {

                push (@otherArgs, $item);
            }
        }

        # (Unlike $self->setupLink, it's safe to assume that we have the entire link contained
        #   within $text)
        $url = $axmud::CLIENT->constUrlRegex;
        $shortUrl = $axmud::CLIENT->constShortUrlRegex;
        $longMail = "mailto\: " . $axmud::CLIENT->constEmailRegex;
        $mail = $axmud::CLIENT->constEmailRegex;

        # Now divide $text into one or more segments, and apply the 'link' tag to each segment, or
        #   not, as required
        do {

            my ($segment, $posn, $before);

            # (Check email first, otherwise gmail.com is detected and fred@gmail.com isn't)
            if (
                $text =~ m/($mail)/
                || $text =~ m/($url)/
                || $text =~ m/($longMail)/
                || ($axmud::CLIENT->shortUrlFlag && $text =~ m/($shortUrl)/)
                || $text =~ m/(telnet\:\/\/([^\:\s]+)(\:(\d+))?)/
                || $text =~ m/(ssh\:\/\/([^\:\s]+)(\:(\d+))?)/
                || $text =~ m/(ssl\:\/\/([^\:\s]+)(\:(\d+))?)/
            ) {
                $segment = $1;
                $posn = $-[1];
            }

            if (! $segment) {

                # Nothing in the rest of $text is a link
                $result = $self->insertText($text, @firstArgs, @lastArgs, @otherArgs);
                $text = '';
                # (Items in @firstArgs should only be sent on the first call to ->insertText; after
                #   that, we make sure everything appears on the same line by specifiying 'echo')
                @firstArgs = ('echo');

            } else {

                # Process everything before the matching portion
                if ($posn > 0) {

                    $result = $self->insertText(substr($text, 0, $posn), @firstArgs, @otherArgs);
                    @firstArgs = ('echo');
                }

                # Process the matching portion as a clickable link
                $result = $self->insertText($segment, 'link', @firstArgs, @otherArgs);
                @firstArgs = ('echo');

                # Remove everything up to and including the matching portion
                $text = substr($text, ($posn + length($segment)));
            }

        } until (! $text);

        # The return value is the return value of the most recent call to $self->insertText
        return $result;
    }

    sub insertQuick {

        # Can be called by any code
        # A combination of $self->clearBuffer and ->insertText, intended for task windows and the
        #   like which want to frequently replace the contents of the textview with a single
        #   string, and don't need to use Axmud colour/style tags or links (probably because
        #   $self->monochromeFlag is TRUE or the current colour scheme's ->overrideAllFlag is TRUE)
        # Empties the buffer and replaces it with a string, which can contain multiple newline
        #   characters. No newline characters are prepended/appended by this function
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $string - The string to display. If 'undef' (or an empty string), the buffer is simply
        #               emptied
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $string, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->insertQuick', @_);
        }

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        $self->removeCursor();

        # Clear the buffer. The TRUE argument means 'don't remove/move the cursor'
        $self->clearBuffer(undef, TRUE);
        # Fill the empty buffer with text
        if ($string) {

            $self->buffer->set_text($string);
        }

        # If the cursor is visible, move it to the end of the buffer (i.e. insert a new
        #   Gtk3::TextTag)
        $self->moveCursor();

        # Update IVs
        if ($string) {

            $self->ivPoke('bufferTextFlag', TRUE);
            $self->ivPoke('sizeUpdateFlag', TRUE);

            if ($string =~ m/\n$/) {

                $self->ivPoke('newLineFlag', TRUE);
                $self->ivPoke('insertNewLineFlag', TRUE);

            } else {

                $self->ivPoke('newLineFlag', FALSE);
                $self->ivPoke('insertNewLineFlag', FALSE);
            }

        } else {

            $self->ivPoke('bufferTextFlag', FALSE);
            $self->ivPoke('sizeUpdateFlag', TRUE);
        }

        # Scroll the textview to the bottom
        $self->scrollToBottom();

        return 1;
    }

    sub insertCmd {

        # Called by GA::Session->dispatchCmd and ->dispatchPassword when this textview object is
        #   the session's default textview object
        # Inserts text into the Gtk3::TextBuffer to show the world command/password, using a
        #   standard colour
        # NB This function doesn't write to any log files; the calling function does that
        #
        # Expected arguments
        #   $cmd        - The command to show. When GA::Session->dispatchCmd/->dispatchPassword
        #                   need to cancel a prompt, an empty string. A newline character is
        #                   automatically appended in both cases
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $cmd, $check) = @_;

        # Local variables
        my (
            $colourSchemeObj, $monochromeFlag, $textColour, $mark, $noNewLineFlag, $iter, $endIter,
            $endLine,
        );

        # Check for improper arguments
        if (! defined $cmd || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->insertCmd', @_);
        }

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        $self->removeCursor();
        # If the buffer is due to be cleared before inserting any text, then clear it
        if ($self->clearAfterInsertFlag) {

            # The TRUE argument means 'don't remove/move the cursor'
            $self->clearBuffer(undef, TRUE);
        }

        # Import the colour scheme in use
        $colourSchemeObj = $axmud::CLIENT->ivShow('colourSchemeHash', $self->colourScheme);
        # Choose which colour tags to use (in monochrome mode, text/underlay colours are ignored,
        #   but in this case we don't any apply overrides specified by the colour scheme)
        if ($self->monochromeFlag || ($colourSchemeObj && $colourSchemeObj->overrideAllFlag)) {
            $monochromeFlag = TRUE;
        } else {
            $textColour = $axmud::CLIENT->customInsertCmdColour;
        }

        # Set the insertion point
        if ($self->insertMark) {

            $mark = $self->insertMark;

        } elsif ($self->tempInsertMark) {

            $mark = $self->tempInsertMark;
            # This code prevents a blank line being inserted between a world's prompt and the
            #   already-displayed Axmud system message
            $self->ivUndef('tempInsertMark');
            $noNewLineFlag = TRUE;
        }

        if ($mark) {
            $iter = $self->buffer->get_iter_at_mark($mark);
        } elsif (! $self->systemInsertMark) {
            $iter = $self->buffer->get_end_iter();
        } else {

            # Incomplete system message after a call to $self->showSystemText without a newline
            #   character. Must insert an artificial newline character, and display $text after
            #   that
            $iter = $self->buffer->get_iter_at_mark($self->systemInsertMark);
            $iter = $self->insertNewLine($iter);
        }

        # Insert the text into the Gtk3::TextBuffer
        if ($cmd ne '') {

            if ($monochromeFlag) {
                $iter = $self->insertWithTags($iter, $cmd);
            } else {
                $iter = $self->insertWithTags($iter, $cmd, $textColour);
            }
        }

        # In overwrite mode, don't insert a newline character on the bottom line
        if (! $noNewLineFlag && $self->overwriteFlag) {

            $endIter = $self->buffer->get_end_iter();
            $endLine = $endIter->get_line();

            if ($endLine == $iter->get_line() && $endLine == ($self->textHeightChars - 1)) {

                $noNewLineFlag = TRUE;

                # Remove any text between the end of the world command, and the end of the buffer
                #   (so that the previous world command, if longer than this one, is no longer
                #   visible)
                if ($endIter->get_visible_line_offset() > $iter->get_visible_line_offset()) {

                    $self->buffer->delete($iter, $endIter);
                }

                # Move the insertion point back to the beginning of the line, so the next world
                #   command overwrites this one
                $iter = $self->buffer->get_iter_at_line_offset($endLine, 0);
            }
        }

        if (! $noNewLineFlag) {

            $iter = $self->insertNewLine($iter);
        }

        if ($self->insertMark) {

            # The next call to $self->insertText, ->insertCmd etc uses the insertion point
            #   immediately after $iter
            $mark = $self->buffer->create_mark('insert_mark', $iter, TRUE);
            $self->ivPoke('insertMark', $mark);
            # If the cursor is visible, move it to this position (i.e. insert a new Gtk3::TextTag)
            $self->moveCursor($self->buffer->get_iter_at_mark($mark));

        } else {

            # If the cursor is visible, move it to the end of the buffer (i.e. insert a new
            #   Gtk3::TextTag)
            $self->moveCursor();
        }

        if ($self->scrollLockFlag) {

            if ($self->scrollLockType eq 'top') {
                $self->scrollToTop();
            } else {
                $self->scrollToBottom();
            }
        }

        return 1;
    }

    sub showSystemText {

        # Called by Games::Axmud->writeText
        # Inserts system text into the Gtk3::TextBuffer, optionally applying Axmud colour/style tags
        #   and/or newline characters, and optionally emptying the buffer of text
        # Optionally updates the System task's window
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $text       - The system text to write. If undefined, the text <<undef>> is written
        #   @args       - List of arguments, in any order:
        #                   - 'empty' (empties the buffer before writing $text)
        #                   - 'before' (prepends a newline character to $text)
        #                   - 'after' or 'nl' (appends a newline character to $text)
        #                   - 'echo' (does not prepend/append a newline character, overrides
        #                       'before', 'after' and 'nl' if they are specified)
        #                   - one or more Axmud colour tags. Only the first text colour (e.g. 'red')
        #                       is used, and only the first underlay colour ('UL_RED') is used.
        #                       The range of Axmud colour tags include:
        #                       - standard colour tags like 'red', 'BLUE', 'ul_red', 'UL_BLUE'
        #                           (case-sensititive)
        #                       - xterm colour tags (strings in the range 'x0' to 'x255', or
        #                           'ux0' to 'ux255'; case-insensitive, so 'X0' is valid)
        #                       - RGB colour tags (strings in the range '#000000' to '#FFFFFF', or
        #                           'u#000000' to 'u#FFFFFF'; case-insensitive, so 'U#AbCdEf' is
        #                           valid)
        #                   - one or more Axmud style tags ('italics', 'strike', etc)
        #
        # Notes
        #   If both 'nl'/'after' and 'echo' are specified (or if neither is specified), a newline
        #       character IS appended
        #
        # Return values
        #   1

        my ($self, $text, @args) = @_;

        # Local variables
        my (
            $emptyFlag, $beforeFlag, $afterFlag, $linkFlag, $textColour, $underlayColour,
            $systemTask, $hereFlag, $taskFlag, $consoleFlag, $colourSchemeObj, $monochromeFlag,
            $modText, $beep, $iter,
            @styleTags, @modArgs,
        );

        # (No improper arguments to check)

        # Interpret the list of @args
        ($emptyFlag, $beforeFlag, $afterFlag, $linkFlag, $textColour, $underlayColour, @styleTags)
            = $self->interpretTags('after', @args);

        # Import the colour scheme in use
        $colourSchemeObj = $axmud::CLIENT->ivShow('colourSchemeHash', $self->colourScheme);
        # Choose which colour tags to use (in monochrome mode, text/underlay colours are ignored,
        #   but in this case we don't any apply overrides specified by the colour scheme)
        if ($self->monochromeFlag || ($colourSchemeObj && $colourSchemeObj->overrideAllFlag)) {

            $monochromeFlag = TRUE;

        } else {

            if (! $textColour) {

                $textColour = $axmud::CLIENT->customShowSystemTextColour;
            }

            if (! $underlayColour) {

                $underlayColour = $self->underlayColour;
            }
        }

        # Whether the message is written only in this textview (mode 'original'), or in both this
        #   textview and the System task's window ('both'), or in the System task's window only
        #   (mode 'task'), depends on the System task's IVs (if the task is running)
        $systemTask = $self->session->systemTask;
        if (! $systemTask) {

            $hereFlag = TRUE;

        } else {

            if ($systemTask->systemMode eq 'original') {

                $hereFlag = TRUE;

            } elsif ($systemTask->systemMode eq 'both') {

                $hereFlag = TRUE;
                $taskFlag = TRUE;

            } else {

                $taskFlag = TRUE;
            }
        }

        # If not allowed to write a system message in this textview, write to the Session Console
        #   window instead
        if (
            $hereFlag
            && (! $axmud::CLIENT->mainWinSystemMsgFlag || $self->overwriteFlag)
        ) {
            $hereFlag = FALSE;
            $consoleFlag = TRUE;
        }

        # Empty the buffer before writing text, if required (but not in the System task window or in
        #   the Session console window)
        if ($emptyFlag && $hereFlag) {

            # The TRUE argument means 'don't remove/move the cursor'
            $self->clearBuffer(undef, TRUE);
        }

        # Prepare the message to send
        $modText = $text;
        if (! defined $modText) {

            # 'undef' is a valid value - represent it
            $modText = "<<undef>>";
        }

        # If $text/$modText contains any ASCII 7 characters (bells), filter them out
        $beep = chr(7);
        $modText =~ s/$beep//g;
        if ($text) {

            $text =~ s/$beep//g;
        }

        if ($hereFlag) {

            # If the last piece of text inserted at the Gtk3::TextBuffer via a call to
            #   $self->insertText didn't end in a newline character, we need to insert an artifical
            #   newline character so the system message appears on its own line, at the end of the
            #   buffer
            if (
                # Last character in the buffer isn't a newline character
                ! $self->newLineFlag
                # The insertion point for $self->insertText and ->insertCmd is the end of the buffer
                && ! $self->insertMark
                # The call to this function wasn't preceded by another call to this function which
                #   didn't use a newline character
                && ! $self->systemInsertMark
            ) {
                $iter = $self->buffer->get_end_iter();
                $self->ivPoke(
                    'tempInsertMark',
                    $self->buffer->create_mark('temp_insert_mark', $iter, TRUE),
                );

                $beforeFlag = TRUE;
            }

            # If the cursor is visible, remove it temporarily (i.e. remove the existing
            #   Gtk3::TextTag)
            $self->removeCursor();
            # If the buffer is due to be cleared before inserting any text, then clear it
            if ($self->clearAfterInsertFlag) {

                # The TRUE argument means 'don't remove/move the cursor'
                $self->clearBuffer(undef, TRUE);
            }

            # Set the insertion point
            if ($self->systemInsertMark) {
                $iter = $self->buffer->get_iter_at_mark($self->systemInsertMark);
            } else {
                $iter = $self->buffer->get_end_iter();
            }

            # Insert a newline character into the Gtk3::TextBuffer
            if ($beforeFlag) {

                # (Make sure the beginning of a link appears after the extra newline character, not
                #   before it)
                $iter = $self->insertNewLine($iter);
            }

            # Create a link object, if required
            if ($linkFlag && $modText) {

                # Create a link object, if required
                $self->setupLink($iter, $modText);
            }

            # Insert the text into the Gtk3::TextBuffer
            if ($monochromeFlag) {

                $iter = $self->insertWithTags(
                    $iter,
                    $modText,
                    @styleTags,
                );

            } else {

                $iter = $self->insertWithTags(
                    $iter,
                    $modText,
                    $textColour,
                    $underlayColour,
                    @styleTags,
                );
            }

            if ($afterFlag) {

                # (Make sure the end of a link appears before the extra newline character, not
                #   after it)
                $self->insertNewLine($iter);
                $self->ivUndef('systemInsertMark');

                # Restore the cursor
                if ($self->tempInsertMark) {
                    $self->moveCursor($self->buffer->get_iter_at_mark($self->tempInsertMark));
                } else {
                    $self->replaceCursor();
                }

            } else {

                # (System message in the next call to this function is appended to this system
                #   message, which didn't end with a newline character)
                $self->ivPoke(
                    'systemInsertMark',
                    $self->buffer->create_mark('system_insert_mark', $iter, TRUE),
                );

                # (Don't restore the cursor until the complete line is displayed)
            }

            if ($self->scrollLockFlag) {

                if ($self->scrollLockType eq 'top') {
                    $self->scrollToTop();
                } else {
                    $self->scrollToBottom();
                }
            }
        }

        if (defined $text && $text ne '') {

            if ($taskFlag) {

                # Write the message in the System task window, but remove an 'empty' argument if one
                #   was specified for the 'main' window
                foreach my $item (@args) {

                    if ($item ne 'empty') {

                        push (@modArgs, $item);
                    }
                }

                $self->session->systemTask->showSystemText($text, @modArgs);
            }

            if ($consoleFlag) {

                # Send the message to the GA::Session, for display (now or later) in the Session
                #   Console window
                $self->session->add_systemMsg('system', $text);
            }

            # Write to logs and convert text-to-speech, if required
            # Only a complete line (ending in a newline character) is written to logs and/or
            #   converted to text-to-speech; until then, a partial system message is stored in a
            #   buffer
            if (! $self->systemTextBuffer) {
                $self->ivPoke('systemTextBuffer', $text);
            } else {
                $self->ivPoke('systemTextBuffer', $self->systemTextBuffer . $text);
            }
        }

        if (($beforeFlag || $afterFlag) && $self->systemTextBuffer) {

            # Write to logs
            $axmud::CLIENT->writeLog(
                $self->session,
                TRUE,                       # Not world-specific logs
                $self->systemTextBuffer,
                $beforeFlag,
                $afterFlag,
                'main', 'system',           # Write to these files
            );

            # Convert text-to-speech, if required (but don't try to convert an 'undef' or text
            #   containing no readable characters)
            if (
                $axmud::CLIENT->systemAllowTTSFlag
                && $axmud::CLIENT->ttsSystemFlag
                && defined $self->systemTextBuffer
                && $self->systemTextBuffer =~ m/\w/
                # Also, temporarily don't convert system messages if the GA::Session flag is set
                && ! $self->session->ttsTempDisableFlag
            ) {
                # Make sure the received text is visible in the textview(s)...
                $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showSystemText');

                # ...before converting text to speech
                if (
                    defined $self->session->ttsLastType
                    && $self->session->ttsLastType eq 'system'
                ) {
                    # (Don't read out 'system message' again and again and again!
                    $axmud::CLIENT->tts(
                        $self->systemTextBuffer,
                        'system',
                        'system',
                        $self->session,
                    );

                } else {

                    # Last TTS conversion was something other than a system message
                    $axmud::CLIENT->tts(
                        'System message: ' . $self->systemTextBuffer,
                        'system',
                        'system',
                        $self->session,
                    );
                }
            }

            # Fire any hooks that are using the system hook events
            $self->session->checkHooks('system_text', $self->systemTextBuffer);
            $self->session->checkHooks('system_all', $self->systemTextBuffer);

            $self->ivUndef('systemTextBuffer');
        }

        # This type of system message always requires a return value of 1
        return 1;
    }

    sub showError {

        # Called by Games::Axmud->writeError
        # Inserts a system error message into the Gtk3::TextBuffer and/or updates the System task's
        #   window
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $text       - The system text to write. If undefined, the text <<undef>> is written
        #   $func       - The function that produced the error (e.g.
        #                   'Games::Axmud::Client->helloWorld'). If 'undef', the function is not
        #                   displayed
        #
        # Return values
        #   'undef'

        my ($self, $text, $func, $check) = @_;

        # Local variables
        my (
            $colourSchemeObj, $monochromeFlag, $textColour, $msg, $systemTask, $hereFlag, $taskFlag,
            $consoleFlag, $iter, $beforeFlag,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->showError', @_);
        }

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        $self->removeCursor();
        # If the buffer is due to be cleared before inserting any text, then clear it
        if ($self->clearAfterInsertFlag) {

            # The TRUE argument means 'don't remove/move the cursor'
            $self->clearBuffer(undef, TRUE);
        }

        # Import the colour scheme in use
        $colourSchemeObj = $axmud::CLIENT->ivShow('colourSchemeHash', $self->colourScheme);
        # Choose which colour tags to use (in monochrome mode, text/underlay colours are ignored,
        #   but in this case we don't any apply overrides specified by the colour scheme)
        if ($self->monochromeFlag || ($colourSchemeObj && $colourSchemeObj->overrideAllFlag)) {
            $monochromeFlag = TRUE;
        } else {
            $textColour = $axmud::CLIENT->customShowErrorColour;
        }

        # Call to ->writeLog requires a TRUE/FALSE value
        $beforeFlag = FALSE;

        # Prepare the message to send
        if (! defined $text) {

            # 'undef' is a valid value - represent it
            $text = "<<undef>>";
        }

        if ($func) {
            $msg = "ERROR: $func: $text";
        } else {
            $msg = "ERROR: $text";
        }

        # Whether the message is written only in this textview (mode 'original'), or in both this
        #   textview and the System task's window ('both'), or in the System task's window only
        #   (mode 'task'), depends on the System task's IVs (if the task is running)
        $systemTask = $self->session->systemTask;
        if (! $systemTask) {

            $hereFlag = TRUE;

        } else {

            if ($systemTask->errorMode eq 'original') {

                $hereFlag = TRUE;

            } elsif ($systemTask->errorMode eq 'both') {

                $hereFlag = TRUE;
                $taskFlag = TRUE;

            } else {

                $taskFlag = TRUE;
            }
        }

        # If not allowed to write a system message in this textview, write to the Session Console
        #   window instead
        if (
            $hereFlag
            && (! $axmud::CLIENT->mainWinSystemMsgFlag || $self->overwriteFlag)
        ) {
            $hereFlag = FALSE;
            $consoleFlag = TRUE;
        }

        if ($hereFlag) {

            # If the previous call to $self->showSystemText displayed a message that didn't end in a
            #   newline character, $self->systemInsertMark is set
            # In that case, we must insert an artificial newline character, so this system message
            #   is displayed on its own line
            if ($self->systemInsertMark) {

                $iter = $self->buffer->get_iter_at_mark($self->systemInsertMark);
                $iter = $self->insertNewLine($iter);
                $self->ivUndef('systemInsertMark');

            # If the last piece of text inserted at the Gtk3::TextBuffer via a call to
            #   $self->insertText didn't end in a newline character, we need to insert an artifical
            #   newline character so the system message appears on its own line, at the end of the
            #   buffer
            } elsif (
                # Last character in the buffer isn't a newline character
                ! $self->newLineFlag
                # The insertion point for $self->insertText and ->insertCmd is the end of the buffer
                && ! $self->insertMark
            ) {
                $iter = $self->buffer->get_end_iter();
                $self->ivPoke(
                    'tempInsertMark',
                    $self->buffer->create_mark('temp_insert_mark', $iter, TRUE),
                );

                $beforeFlag = TRUE;
            }

            # If the cursor is visible, remove it temporarily (i.e. remove the existing
            #   Gtk3::TextTag)
            $self->removeCursor();
            # If the buffer is due to be cleared before inserting any text, then clear it
            if ($self->clearAfterInsertFlag) {

                # The TRUE argument means 'don't remove/move the cursor'
                $self->clearBuffer(undef, TRUE);
            }

            # Set the insertion point
            $iter = $self->buffer->get_end_iter();

            # Insert the text into the Gtk3::TextBuffer
            if ($beforeFlag) {

                # (Make sure the beginning of a link appears after the artificially-inserted newline
                #   character, not before it)
                $iter = $self->insertNewLine($iter);
            }

            if ($monochromeFlag) {
                $iter = $self->insertWithTags($iter, $msg);
            } else {
                $iter = $self->insertWithTags($iter, $msg, $textColour);
            }

            $self->insertNewLine($iter);

            # Restore the cursor
            if ($self->tempInsertMark) {
                $self->moveCursor($self->buffer->get_iter_at_mark($self->tempInsertMark));
            } else {
                $self->replaceCursor();
            }

            if ($self->scrollLockFlag) {

                if ($self->scrollLockType eq 'top') {
                    $self->scrollToTop();
                } else {
                    $self->scrollToBottom();
                }
            }
        }

        if (defined $msg && $msg ne '') {

            if ($taskFlag) {

                # Write the message in the System task window
                $self->session->systemTask->showError($msg);
            }

            if ($consoleFlag) {

                # Send the message to the GA::Session, for display (now or later) in the Session
                #   Console window
                $self->session->add_systemMsg('error', $msg);
            }

            # Write to logs
            $axmud::CLIENT->writeLog(
                $self->session,
                TRUE,                           # Not world-specific logs
                $msg,
                $beforeFlag,
                TRUE,                           # Use final newline character
                'main', 'errors', 'error',      # Write to these files
            );

            # Fire any hooks that are using the system hook events
            $self->session->checkHooks('system_error', $msg);
            $self->session->checkHooks('system_all', $msg);
            $self->session->checkHooks('system_all_error', $msg);
        }

        # Play a sound effect (if allowed, and if this textview object hasn't played the same
        #   sound effect recently)
        if (! $self->soundCheckTime || $self->soundCheckTime < $axmud::CLIENT->clientTime) {

            $axmud::CLIENT->playSound('error');
            # Don't play it again for a few seconds
            $self->ivPoke('soundCheckTime', ($axmud::CLIENT->clientTime + $self->soundDelayTime));
        }

        # Convert text-to-speech, if required (but don't try to convert an 'undef' or text
        #   containing no readable characters)
        if (
            $axmud::CLIENT->systemAllowTTSFlag
            && $axmud::CLIENT->ttsSystemFlag
            && defined $text
            && $text =~ m/\w/
            # Also, temporarily don't convert system messages if the GA::Session flag is set
            && ! $self->session->ttsTempDisableFlag
        ) {
            # Make sure the received text is visible in the textview(s)...
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showError');

            # ...before converting text to speech
            if (defined $self->session->ttsLastType && $self->session->ttsLastType eq 'error') {

                # (Don't read out 'system error' again and again and again!
                $axmud::CLIENT->tts($text, 'error', 'error', $self->session);

            } else {

                # Last TTS conversion was something other than a system error (etc) message
                $axmud::CLIENT->tts('System error: ' . $text, 'error', 'error', $self->session);
            }
        }

        # This type of system message always requires a return value of 'undef'
        return undef;
    }

    sub showWarning {

        # Called by Games::Axmud->writeWarning
        # Inserts a system warning message into the Gtk3::TextBuffer and/or updates the System
        #   task's window
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $text       - The system text to write. If undefined, the text <<undef>> is written
        #   $func       - The function that produced the warning (e.g.
        #                   'Games::Axmud::Client->helloWorld'). If 'undef', the function is not
        #                   displayed
        #
        # Return values
        #   'undef'

        my ($self, $text, $func, $check) = @_;

        # Local variables
        my (
            $colourSchemeObj, $monochromeFlag, $textColour, $msg, $systemTask, $hereFlag, $taskFlag,
            $consoleFlag, $iter, $beforeFlag,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->showWarning', @_);
        }

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        $self->removeCursor();
        # If the buffer is due to be cleared before inserting any text, then clear it
        if ($self->clearAfterInsertFlag) {

            # The TRUE argument means 'don't remove/move the cursor'
            $self->clearBuffer(undef, TRUE);
        }

        # Import the colour scheme in use
        $colourSchemeObj = $axmud::CLIENT->ivShow('colourSchemeHash', $self->colourScheme);
        # Choose which colour tags to use (in monochrome mode, text/underlay colours are ignored,
        #   but in this case we don't any apply overrides specified by the colour scheme)
        if ($self->monochromeFlag || ($colourSchemeObj && $colourSchemeObj->overrideAllFlag)) {
            $monochromeFlag = TRUE;
        } else {
            $textColour = $axmud::CLIENT->customShowWarningColour;
        }

        # Call to ->writeLog requires a TRUE/FALSE value
        $beforeFlag = FALSE;

        # Prepare the message to send
        if (! defined $text) {

            # 'undef' is a valid value - represent it
            $text = "<<undef>>";
        }

        if ($func) {
            $msg = "WARNING: $func: $text";
        } else {
            $msg = "WARNING: $text";
        }

        # Whether the message is written only in this textview (mode 'original'), or in both this
        #   textview and the System task's window ('both'), or in the System task's window only
        #   (mode 'task'), depends on the System task's IVs (if the task is running)
        $systemTask = $self->session->systemTask;
        if (! $systemTask) {

            $hereFlag = TRUE;

        } else {

            if ($systemTask->warningMode eq 'original') {

                $hereFlag = TRUE;

            } elsif ($systemTask->warningMode eq 'both') {

                $hereFlag = TRUE;
                $taskFlag = TRUE;

            } else {

                $taskFlag = TRUE;
            }
        }

        # If not allowed to write a system message in this textview, write to the Session Console
        #   window instead
        if (
            $hereFlag
            && (! $axmud::CLIENT->mainWinSystemMsgFlag || $self->overwriteFlag)
        ) {
            $hereFlag = FALSE;
            $consoleFlag = TRUE;
        }

        if ($hereFlag) {

            # If the previous call to $self->showSystemText displayed a message that didn't end in a
            #   newline character, $self->systemInsertMark is set
            # In that case, we must insert an artificial newline character, so this system message
            #   is displayed on its own line
            if ($self->systemInsertMark) {

                $iter = $self->buffer->get_iter_at_mark($self->systemInsertMark);
                $iter = $self->insertNewLine($iter);
                $self->ivUndef('systemInsertMark');

            # If the last piece of text inserted at the Gtk3::TextBuffer via a call to
            #   $self->insertText didn't end in a newline character, we need to insert an artifical
            #   newline character so the system message appears on its own line, at the end of the
            #   buffer
            } elsif (
                # Last character in the buffer isn't a newline character
                ! $self->newLineFlag
                # The insertion point for $self->insertText and ->insertCmd is the end of the buffer
                && ! $self->insertMark
            ) {
                $iter = $self->buffer->get_end_iter();
                $self->ivPoke(
                    'tempInsertMark',
                    $self->buffer->create_mark('temp_insert_mark', $iter, TRUE),
                );

                $beforeFlag = TRUE;
            }

            # If the cursor is visible, remove it temporarily (i.e. remove the existing
            #   Gtk3::TextTag)
            $self->removeCursor();
            # If the buffer is due to be cleared before inserting any text, then clear it
            if ($self->clearAfterInsertFlag) {

                # The TRUE argument means 'don't remove/move the cursor'
                $self->clearBuffer(undef, TRUE);
            }

            # Set the insertion point
            $iter = $self->buffer->get_end_iter();

            # Insert the text into the Gtk3::TextBuffer
            if ($beforeFlag) {

                # (Make sure the beginning of a link appears after the artificially-inserted newline
                #   character, not before it)
                $iter = $self->insertNewLine($iter);
            }

            if ($monochromeFlag) {
                $iter = $self->insertWithTags($iter, $msg);
            } else {
                $iter = $self->insertWithTags($iter, $msg, $textColour);
            }

            $self->insertNewLine($iter);

            # Restore the cursor
            if ($self->tempInsertMark) {
                $self->moveCursor($self->buffer->get_iter_at_mark($self->tempInsertMark));
            } else {
                $self->replaceCursor();
            }

            if ($self->scrollLockFlag) {

                if ($self->scrollLockType eq 'top') {
                    $self->scrollToTop();
                } else {
                    $self->scrollToBottom();
                }
            }
        }

        if (defined $msg && $msg ne '') {

            if ($taskFlag) {

                # Write the message in the System task window
                $self->session->systemTask->showWarning($msg);
            }

            if ($consoleFlag) {

                # Send the message to the GA::Session, for display (now or later) in the Session
                #   Console window
                $self->session->add_systemMsg('warning', $msg);
            }

            # Write to logs
            $axmud::CLIENT->writeLog(
                $self->session,
                TRUE,                           # Not world-specific logs
                $msg,
                $beforeFlag,
                TRUE,                           # Use final newline character
                'main', 'errors', 'warning',    # Write to these files
            );

            # Fire any hooks that are using the system hook events
            $self->session->checkHooks('system_warning', $msg);
            $self->session->checkHooks('system_all', $msg);
            $self->session->checkHooks('system_all_error', $msg);
        }

        # Play a sound effect (if allowed, and if this textview object hasn't played the same
        #   sound effect recently)
        if (! $self->soundCheckTime || $self->soundCheckTime < $axmud::CLIENT->clientTime) {

            $axmud::CLIENT->playSound('error');
            # Don't play it again for a few seconds
            $self->ivPoke('soundCheckTime', ($axmud::CLIENT->clientTime + $self->soundDelayTime));
        }

        # Convert text-to-speech, if required (but don't try to convert an 'undef' or text
        #   containing no readable characters)
        if (
            $axmud::CLIENT->systemAllowTTSFlag
            && $axmud::CLIENT->ttsSystemFlag
            && defined $text
            && $text =~ m/\w/
            # Also, temporarily don't convert system messages if the GA::Session flag is set
            && ! $self->session->ttsTempDisableFlag
        ) {
            # Make sure the received text is visible in the textview(s)...
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showWarning');

            # ...before converting text to speech
            if (defined $self->session->ttsLastType && $self->session->ttsLastType eq 'error') {

                # (Don't read out 'system warning' again and again and again!
                $axmud::CLIENT->tts($text, 'error', 'error', $self->session);

            } else {

                # Last TTS conversion was something other than a system error (etc) message
                $axmud::CLIENT->tts('System warning: ' . $text, 'error', 'error', $self->session);
            }
        }

        # This type of system message always requires a return value of 'undef'
        return undef;
    }

    sub showDebug {

        # Called by Games::Axmud->writeDebug or ->wd
        # Inserts a system debug message into the Gtk3::TextBuffer and/or updates the System task's
        #   window
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $text       - The system text to write. If undefined, the text <<undef>> is written
        #   $func       - The function that produced the debug message (e.g.
        #                   'Games::Axmud::Client->helloWorld'). If 'undef', the function is not
        #                   displayed
        #
        # Return values
        #   'undef'

        my ($self, $text, $func, $check) = @_;

        # Local variables
        my (
            $colourSchemeObj, $monochromeFlag, $textColour, $msg, $systemTask, $hereFlag, $taskFlag,
            $consoleFlag, $iter, $beforeFlag,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->showDebug', @_);
        }

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        $self->removeCursor();
        # If the buffer is due to be cleared before inserting any text, then clear it
        if ($self->clearAfterInsertFlag) {

            # The TRUE argument means 'don't remove/move the cursor'
            $self->clearBuffer(undef, TRUE);
        }

        # Import the colour scheme in use
        $colourSchemeObj = $axmud::CLIENT->ivShow('colourSchemeHash', $self->colourScheme);
        # Choose which colour tags to use (in monochrome mode, text/underlay colours are ignored,
        #   but in this case we don't any apply overrides specified by the colour scheme)
        if ($self->monochromeFlag || ($colourSchemeObj && $colourSchemeObj->overrideAllFlag)) {
            $monochromeFlag = TRUE;
        } else {
            $textColour = $axmud::CLIENT->customShowDebugColour;
        }

        # Call to ->writeLog requires a TRUE/FALSE value
        $beforeFlag = FALSE;

        # Prepare the message to send
        if (! defined $text) {

            # 'undef' is a valid value - represent it
            $text = "<<undef>>";
        }

        if ($func) {
            $msg = "DEBUG: $func: $text";
        } else {
            $msg = "DEBUG: $text";
        }

        # Whether the message is written only in this textview (mode 'original'), or in both this
        #   textview and the System task's window ('both'), or in the System task's window only
        #   (mode 'task'), depends on the System task's IVs (if the task is running)
        $systemTask = $self->session->systemTask;
        if (! $systemTask) {

            $hereFlag = TRUE;

        } else {

            if ($systemTask->debugMode eq 'original') {

                $hereFlag = TRUE;

            } elsif ($systemTask->debugMode eq 'both') {

                $hereFlag = TRUE;
                $taskFlag = TRUE;

            } else {

                $taskFlag = TRUE;
            }
        }

        # If not allowed to write a system message in this textview, write to the Session Console
        #   window instead
        if (
            $hereFlag
            && (! $axmud::CLIENT->mainWinSystemMsgFlag || $self->overwriteFlag)
        ) {
            $hereFlag = FALSE;
            $consoleFlag = TRUE;
        }

        if ($hereFlag) {

            # If the previous call to $self->showSystemText displayed a message that didn't end in a
            #   newline character, $self->systemInsertMark is set
            # In that case, we must insert an artificial newline character, so this system message
            #   is displayed on its own line
            if ($self->systemInsertMark) {

                $iter = $self->buffer->get_iter_at_mark($self->systemInsertMark);
                $iter = $self->insertNewLine($iter);
                $self->ivUndef('systemInsertMark');

            # If the last piece of text inserted at the Gtk3::TextBuffer via a call to
            #   $self->insertText didn't end in a newline character, we need to insert an artifical
            #   newline character so the system message appears on its own line, at the end of the
            #   buffer
            } elsif (
                # Last character in the buffer isn't a newline character
                ! $self->newLineFlag
                # The insertion point for $self->insertText and ->insertCmd is the end of the buffer
                && ! $self->insertMark
            ) {
                $iter = $self->buffer->get_end_iter();
                $self->ivPoke(
                    'tempInsertMark',
                    $self->buffer->create_mark('temp_insert_mark', $iter, TRUE),
                );

                $beforeFlag = TRUE;
            }
            # If the cursor is visible, remove it temporarily (i.e. remove the existing
            #   Gtk3::TextTag)
            $self->removeCursor();
            # If the buffer is due to be cleared before inserting any text, then clear it
            if ($self->clearAfterInsertFlag) {

                # The TRUE argument means 'don't remove/move the cursor'
                $self->clearBuffer(undef, TRUE);
            }

            # Set the insertion point
            $iter = $self->buffer->get_end_iter();

            # Insert the text into the Gtk3::TextBuffer
            if ($beforeFlag) {

                # (Make sure the beginning of a link appears after the artificially-inserted newline
                #   character, not before it)
                $iter = $self->insertNewLine($iter);
            }

            if ($monochromeFlag) {
                $iter = $self->insertWithTags($iter, $msg);
            } else {
                $iter = $self->insertWithTags($iter, $msg, $textColour);
            }

            $self->insertNewLine($iter);

            # Restore the cursor
            if ($self->tempInsertMark) {
                $self->moveCursor($self->buffer->get_iter_at_mark($self->tempInsertMark));
            } else {
                $self->replaceCursor();
            }

            if ($self->scrollLockFlag) {

                if ($self->scrollLockType eq 'top') {
                    $self->scrollToTop();
                } else {
                    $self->scrollToBottom();
                }
            }
        }

        if (defined $msg && $msg ne '') {

            if ($taskFlag) {

                # Write the message in the System task window
                $self->session->systemTask->showDebug($msg);
            }

            if ($consoleFlag) {

                # Send the message to the GA::Session, for display (now or later) in the Session
                #   Console window
                $self->session->add_systemMsg('debug', $msg);
            }

            # Write to logs
            $axmud::CLIENT->writeLog(
                $self->session,
                TRUE,                           # Not world-specific logs
                $msg,
                $beforeFlag,
                TRUE,                           # Use final newline character
                'main', 'errors', 'debug',      # Write to these files
            );

            # Fire any hooks that are using the system hook events
            $self->session->checkHooks('system_debug', $msg);
            $self->session->checkHooks('system_all', $msg);
            $self->session->checkHooks('system_all_error', $msg);
        }

        # Play a sound effect (if allowed, and if this textview object hasn't played the same
        #   sound effect recently)
        if (! $self->soundCheckTime || $self->soundCheckTime < $axmud::CLIENT->clientTime) {

            $axmud::CLIENT->playSound('error');
            # Don't play it again for a few seconds
            $self->ivPoke('soundCheckTime', ($axmud::CLIENT->clientTime + $self->soundDelayTime));
        }

        # Convert text-to-speech, if required (but don't try to convert an 'undef' or text
        #   containing no readable characters)
        if (
            $axmud::CLIENT->systemAllowTTSFlag
            && $axmud::CLIENT->ttsSystemFlag
            && defined $text
            && $text =~ m/\w/
            # Also, temporarily don't convert system messages if the GA::Session flag is set
            && ! $self->session->ttsTempDisableFlag
        ) {
            # Make sure the received text is visible in the textview(s)...
            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showDebug');

            # ...before converting text to speech
            if (defined $self->session->ttsLastType && $self->session->ttsLastType eq 'error') {

                # (Don't read out 'system debug' again and again and again!
                $axmud::CLIENT->tts($text, 'error', 'error', $self->session);

            } else {

                # Last TTS conversion was something other than a system error (etc) message
                $axmud::CLIENT->tts('System debug: ' . $text, 'error', 'error', $self->session);
            }
        }

        # This type of system message always requires a return value of 'undef'
        return undef;
    }

    sub showImproper {

        # Called by Games::Axmud->writeImproper
        # Inserts a system 'improper arguments' message into the Gtk3::TextBuffer and/or updates the
        #   System task's window
        #
        # Expected arguments
        #   $func       - The function that produced the message (e.g.
        #                   'Games::Axmud::Client->helloWorld')
        #
        # Optional arguments
        #   @args       - A list of arguments passed by the function that called the
        #                   ->writeImproper() function. If no arguments were passed, an empty list
        #
        # Return values
        #   'undef'

        my ($self, $func, @args) = @_;

        # Local variables
        my (
            $colourSchemeObj, $monochromeFlag, $textColour, $msg, $systemTask, $hereFlag, $taskFlag,
            $consoleFlag, $iter, $beforeFlag,
        );

        # Check for improper arguments
        if (! defined $func) {

            # This function mustn't call itself, so write something to the terminal
            print "ERROR: Recursive improper arguments call from $func\n";
            return undef;
        }

        # Import the colour scheme in use
        $colourSchemeObj = $axmud::CLIENT->ivShow('colourSchemeHash', $self->colourScheme);
        # Choose which colour tags to use (in monochrome mode, text/underlay colours are ignored,
        #   but in this case we don't any apply overrides specified by the colour scheme)
        if ($self->monochromeFlag || ($colourSchemeObj && $colourSchemeObj->overrideAllFlag)) {
            $monochromeFlag = TRUE;
        } else {
            $textColour = $axmud::CLIENT->customShowImproperColour;
        }

        # Call to ->writeLog requires a TRUE/FALSE value
        $beforeFlag = FALSE;

        # Prepare the message to send. Some of the values in @args might be 'undef'; these need to
        #   be replaced by some text that can actually be displayed
        foreach my $arg (@args) {

            if (! defined $arg) {

                $arg = "<<undef>>";
            }
        }

        $msg = "IMPROPER ARGS: $func() " . join (" ", @args);

        # Whether the message is written only in this textview (mode 'original'), or in both this
        #   textview and the System task's window ('both'), or in the System task's window only
        #   (mode 'task'), depends on the System task's IVs (if the task is running)
        $systemTask = $self->session->systemTask;
        if (! $systemTask) {

            $hereFlag = TRUE;

        } else {

            if ($systemTask->improperMode eq 'original') {

                $hereFlag = TRUE;

            } elsif ($systemTask->improperMode eq 'both') {

                $hereFlag = TRUE;
                $taskFlag = TRUE;

            } else {

                $taskFlag = TRUE;
            }
        }

        # If not allowed to write a system message in this textview, write to the Session Console
        #   window instead
        if (
            $hereFlag
            && (! $axmud::CLIENT->mainWinSystemMsgFlag || $self->overwriteFlag)
        ) {
            $hereFlag = FALSE;
            $consoleFlag = TRUE;
        }

        if ($hereFlag) {

            # If the previous call to $self->showSystemText displayed a message that didn't end in a
            #   newline character, $self->systemInsertMark is set
            # In that case, we must insert an artificial newline character, so this system message
            #   is displayed on its own line
            if ($self->systemInsertMark) {

                $iter = $self->buffer->get_iter_at_mark($self->systemInsertMark);
                $iter = $self->insertNewLine($iter);
                $self->ivUndef('systemInsertMark');

            # If the last piece of text inserted at the Gtk3::TextBuffer via a call to
            #   $self->insertText didn't end in a newline character, we need to insert an artifical
            #   newline character so the system message appears on its own line, at the end of the
            #   buffer
            } elsif (
                # Last character in the buffer isn't a newline character
                ! $self->newLineFlag
                # The insertion point for $self->insertText and ->insertCmd is the end of the buffer
                && ! $self->insertMark
            ) {
                $iter = $self->buffer->get_end_iter();
                $self->ivPoke(
                    'tempInsertMark',
                    $self->buffer->create_mark('temp_insert_mark', $iter, TRUE),
                );

                $beforeFlag = TRUE;
            }

            # If the cursor is visible, remove it temporarily (i.e. remove the existing
            #   Gtk3::TextTag)
            $self->removeCursor();
            # If the buffer is due to be cleared before inserting any text, then clear it
            if ($self->clearAfterInsertFlag) {

                # The TRUE argument means 'don't remove/move the cursor'
                $self->clearBuffer(undef, TRUE);
            }

            # Set the insertion point
            $iter = $self->buffer->get_end_iter();

            # Insert the text into the Gtk3::TextBuffer
            if ($beforeFlag) {

                # (Make sure the beginning of a link appears after the artificially-inserted newline
                #   character, not before it)
                $iter = $self->insertNewLine($iter);
            }

            if ($monochromeFlag) {
                $iter = $self->insertWithTags($iter, $msg);
            } else {
                $iter = $self->insertWithTags($iter, $msg, $textColour);
            }

            $self->insertNewLine($iter);

            # Restore the cursor
            if ($self->tempInsertMark) {
                $self->moveCursor($self->buffer->get_iter_at_mark($self->tempInsertMark));
            } else {
                $self->replaceCursor();
            }

            if ($self->scrollLockFlag) {

                if ($self->scrollLockType eq 'top') {
                    $self->scrollToTop();
                } else {
                    $self->scrollToBottom();
                }
            }
        }

        if (defined $msg && $msg ne '') {

            if ($taskFlag) {

                # Write the message in the System task window
                $self->session->systemTask->showImproper($msg);
            }

            if ($consoleFlag) {

                # Send the message to the GA::Session, for display (now or later) in the Session
                #   Console window
                $self->session->add_systemMsg('improper', $msg);
            }

            # Write to logs
            $axmud::CLIENT->writeLog(
                $self->session,
                TRUE,                           # Not world-specific logs
                $msg,
                $beforeFlag,
                TRUE,                           # Use final newline character
                'main', 'errors', 'improper',   # Write to these files
            );

            # Fire any hooks that are using the system hook events
            $self->session->checkHooks('system_improper', $msg);
            $self->session->checkHooks('system_all', $msg);
            $self->session->checkHooks('system_all_error', $msg);
        }

        # Play a sound effect (if allowed, and if this textview object hasn't played the same
        #   sound effect recently)
        if (! $self->soundCheckTime || $self->soundCheckTime < $axmud::CLIENT->clientTime) {

            $axmud::CLIENT->playSound('error');
            # Don't play it again for a few seconds
            $self->ivPoke('soundCheckTime', ($axmud::CLIENT->clientTime + $self->soundDelayTime));
        }

#        # v1.2.208 Improper args messages are incomprehensible, when converted to speech; so this
#        #   is now disabled
#        # Convert text-to-speech, if required (but don't try to convert an 'undef' or text
#        #   containing no readable characters)
#        if (
#            $axmud::CLIENT->systemAllowTTSFlag
#            && $axmud::CLIENT->ttsSystemFlag
#            && defined $msg
#            && $msg =~ m/\w/
#            # Also, temporarily don't convert system messages if the GA::Session flag is set
#            && ! $self->session->ttsTempDisableFlag
#        ) {
#            # Make sure the received text is visible in the textview(s)...
#            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->showImproper');
#
#            # ...before converting text to speech
#            $axmud::CLIENT->tts(
#                'System error: improper arguments in function: ' . $func,
#                'error',
#                'error',
#                $self->session,
#            );
#        }

        # This type of system message always requires a return value of 'undef'
        return undef;
    }

    sub showImage {

        # Can be called by anything
        # Inserts an image pixbuf into the textview at the current insertion point
        #
        # Expected arguments
        #   $pixbuf     - The Gtk3::Gdk::Pixbuf or Gtk3::Gdk::PixbufAnimation of the image to
        #                   display
        #
        # Optional arguments
        #   $linkObj    - For clickable images, the corresponding GA::Obj::Link object. Can be a an
        #                   incomplete link object created by GA::Session's MXP functions (for
        #                   example), or a completed link object stored in this textview object's
        #                   ->linkObjHash; otherwise 'undef'
        #   $padWidth, $padHeight
        #               - Optional padding around the image, in pixels (not the width/height of the
        #                   image itself; that is only specified by the pixbuf)
        #   @args       - Optional list of arguments, in any order:
        #                   - 'empty' (empties the buffer before writing $text)
        #                   - 'before' (prepends a newline character to $text)
        #                   - 'after' or 'nl' (appends a newline character to $text)
        #                   - 'echo' (does not prepend/append a newline character, overrides
        #                       'before', 'after' and 'nl' if they are specified)
        #
        #               - NB The default behaviour is set by $self->defaultNewLine, which is set to
        #                   'before', 'after', 'nl' or 'echo'. This default behaviour is only
        #                   applied if none of 'before', 'after', 'nl' and 'echo' are specified
        #               - NB If @args contains Axmud colour/style tags (as they might in a call to
        #                   $self->insertText), they are ignored
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $pixbuf, $linkObj, $padWidth, $padHeight, @args) = @_;

        # Local variables
        my (
            $animFlag, $emptyFlag, $beforeFlag, $afterFlag, $mark, $iter, $image, $packWidget,
            $ebox, $anchor, $lineNum, $posn, $newMark, $newIter, $tempInsertFlag,
        );

        # Check for improper arguments
        if (! defined $pixbuf) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->showImage', @_);
        }

        # Test whether the $pixbuf is an animated gif, received by this function as a
        #   Gtk3::Gdk::PixbufAnimation-related object, or an unanimated image (including gifs),
        #   received by this function as a Gtk3::Gdk::Pixbuf
        if (ref ($pixbuf) =~ /Anim/) {

            $animFlag = TRUE;
        }

        # If the cursor is visible, remove it temporarily (i.e. remove the existing Gtk3::TextTag)
        $self->removeCursor();
        # If the buffer is due to be cleared before inserting any text, then clear it
        if ($self->clearAfterInsertFlag || $emptyFlag) {

            # The TRUE argument means 'don't remove/move the cursor'
            $self->clearBuffer(undef, TRUE);
        }

        # Interpret the list of @args, ignoring most of the usual return values
        ($emptyFlag, $beforeFlag, $afterFlag) = $self->interpretTags($self->newLineDefault, @args);

        # Set the insertion point
        if ($self->insertMark) {

            $mark = $self->insertMark;

        } elsif ($self->tempInsertMark) {

            $mark = $self->tempInsertMark;
            if ($afterFlag) {

                # This code prevents a blank line being inserted between a world's prompt and the
                #   already-displayed Axmud system message
                $self->ivUndef('tempInsertMark');
                $afterFlag = FALSE;
                $tempInsertFlag = TRUE;
            }
        }

        if ($mark) {
            $iter = $self->buffer->get_iter_at_mark($mark);
        } elsif (! $self->systemInsertMark) {
            $iter = $self->buffer->get_end_iter();
        } else {

            # Incomplete system message after a call to $self->showSystemText without a newline
            #   character. Must insert an artificial newline character, and display $pixbuf after
            #   that
            $iter = $self->buffer->get_iter_at_mark($self->systemInsertMark);
            $iter = $self->insertNewLine($iter);
        }

        # (Don't prepend a newline character if the buffer is empty)
        if ($beforeFlag && $self->bufferTextFlag) {

            # (Make sure the beginning of a link appears after the extra newline character, not
            #   before it)
            $iter = $self->insertNewLine($iter);
        }

        # Get the position of the iter now, before it becomes invalid
        $lineNum = $iter->get_line();
        $posn = $iter->get_visible_line_offset();

        # Create the image
        if (! $animFlag) {

            $image = $packWidget = Gtk3::Image->new_from_pixbuf($pixbuf);

        } else {

            $image = $packWidget = Gtk3::Image->new();
            $image->set_from_animation($pixbuf);
        }

        # If the image should be clickable, pack it inside an event box
        if (defined $linkObj) {

            $ebox = Gtk3::EventBox->new();
            $ebox->signal_connect('button-press-event' => sub {

                my ($widget, $event) = @_;

                # Local variables
                my ($x, $y, $href);

                # Check the link is completed (not temporary) and that it hasn't expired
                if (
                    defined $linkObj->number
                    && $linkObj->number != -1
                    && $self->ivExists('linkObjHash', $linkObj->number)
                ) {
                    # Substitute for %x and %y
                    $x = $event->x;
                    $y = $event->y;
                    $href = $linkObj->href;

                    $href =~ s/\%x/$x/;
                    $href =~ s/\%y/$y/;

                    if ($linkObj->mxpInvisFlag) {
                        $self->session->send($href);
                    } else {
                        $self->session->worldCmd($href);
                    }
                }
            });

            $ebox->signal_connect('enter-notify-event' => sub {

                $self->textView->get_window('text')->set_cursor($axmud::CLIENT->constWWWCursor);
            });

            $ebox->signal_connect('leave-notify-event' => sub {

                $self->textView->get_window('text')->set_cursor($axmud::CLIENT->constNormalCursor);
            });

            $ebox->add($image);
            $packWidget = $ebox;
        }

        # Apply padding, if specified
        if ($padWidth && ! ($padWidth =~ m/\D/)) {

            my $hBox = Gtk3::HBox->new();
            $hBox->pack_start($packWidget, FALSE, FALSE, $padWidth);

            $packWidget = $hBox;
        }

        if ($padHeight && ! ($padHeight =~ m/\D/)) {

            my $vBox = Gtk3::VBox->new();
            $vBox->pack_start($packWidget, FALSE, FALSE, $padHeight);

            $packWidget = $vBox;
        }

        # Insert the image into the textview
        $anchor = $self->buffer->create_child_anchor($iter);
        $self->textView->add_child_at_anchor($packWidget, $anchor);

        # Set the new insert iter. The Gtk docs state that the image counts as one character
        $newIter = $self->buffer->get_iter_at_line_offset($lineNum, ($posn + 1));

        if ($afterFlag) {

            # (Make sure the end of a link appears before the extra newline character, not
            #   after it)
            $newIter = $self->insertNewLine($newIter);
        }

        if ($self->insertMark) {

            # The next call to $self->insertText, ->insertCmd etc uses the insertion point
            #   immediately after $newIter
            $newMark = $self->buffer->create_mark('insert_mark', $newIter, TRUE);
            $self->ivPoke('insertMark', $newMark);
            # If the cursor is visible, move it to this position (i.e. insert a new Gtk3::TextTag)
            $self->moveCursor($self->buffer->get_iter_at_mark($mark));

        } elsif ($tempInsertFlag) {

            # Continue using this temporary insertion point, before a line with a system message
            #   (and don't restore the cursor yet)
            $newMark = $self->buffer->create_mark('temp_insert_mark', $newIter, TRUE);
            $self->ivPoke('tempInsertMark', $newMark);

        } else {

            # If the cursor is visible, move it to the end of the buffer (i.e. insert a new
            #   Gtk3::TextTag)
            $self->moveCursor();
        }

        if ($self->scrollLockFlag) {

            if ($self->scrollLockType eq 'top') {
                $self->scrollToTop();
            } else {
                $self->scrollToBottom();
            }

        } else {

            # Scroll to the point immediately after the image's insertion point
            $self->scrollToIter($newIter);
        }

        # Animated pixbufs will not be visible reliably without this line
        $self->winObj->winShowAll($self->_objClass . '->showImage');

        return 1;
    }

    sub removeCursor {

        # Called by $self->insertText, ->insertMultipleText, ->insertQuick and ->insertCmd
        # 'Removes' the visible cursor, usually before a call to $self->moveCursor to move it
        #   somewhere else
        # Also removes the extract space character at the end of the buffer, if one was created by
        #   $self->moveCursor
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, if visible cursors are disabled in this textview or if no
        #       visible cursor has been drawn yet
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($nextIter, $iter);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->removeCursor', @_);
        }

        # Do nothing if visible cursors are disabled in this textview, or if no cursor has been
        #   drawn by an earlier call to $self->moveCursor
        if (! $self->cursorEnableFlag || ! $self->cursorMark) {

            return undef;
        }

        $nextIter = $self->buffer->get_iter_at_mark($self->cursorMark);
        if (! $nextIter) {

            return undef;

        } else {

            $nextIter->forward_char();
            $iter = $self->buffer->get_iter_at_mark($self->cursorMark);
        }

        # Remove the Gtk3::TextTag
        $self->buffer->remove_tag_by_name(
            'cursor',
            # Would like to remove the text tag just for the one space character, but it doesn't
            #   work
            $iter,
            $self->buffer->get_end_iter(),
        );

        # Remove the extra space that was added, if the cursor was position at the end of the buffer
        #   (if a system message has been displayed, it might not be the end of the buffer now)
        if ($self->cursorEndFlag) {

            $self->buffer->delete($iter, $nextIter);
        }

        # Remove the mark
        $self->buffer->delete_mark($self->cursorMark);

        # Update IVs
        $self->ivUndef('cursorMark');
        $self->ivPoke('cursorEndFlag', FALSE);

        return 1;
    }

    sub moveCursor {

        # Called by $self->insertText, ->insertMultipleText, ->insertQuick and ->insertCmd
        # 'Moves' the visible cursor to a specified position, or to the end of the buffer
        # If at the end of the buffer, or at the end of line, adds an extra space character so that
        #   the cursor is actually visible
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $iter   - The Gtk3::TextIter at which to position the cursor. If 'undef', the cursor is
        #               positioned at the end of the buffer
        #
        # Return values
        #   'undef' on improper arguments or if visible cursors are disabled in this textview
        #   1 otherwise

        my ($self, $iter, $check) = @_;

        # Local variables
        my ($endIter, $lastFlag, $cursorMark, $nextIter, $length);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->moveCursor', @_);
        }

        # Do nothing if visible cursors are disabled in this textview
        if (! $self->cursorEnableFlag) {

            return undef;
        }

        $endIter = $self->buffer->get_end_iter();
        if (! $iter || $endIter->get_line() == $iter->get_line()) {

            # Insert position is on the buffer's last line
            $lastFlag = TRUE;
        }

        if (
            ! defined $iter
            || (
                $lastFlag
                && $endIter->get_visible_line_offset() == $iter->get_visible_line_offset()
            )
        ) {
            $cursorMark = $self->buffer->create_mark('cursor_mark', $endIter, TRUE);

            # Insert a space character at the end of the buffer, so that the visible cursor is
            #   actually visible
            $self->buffer->insert_with_tags_by_name(
                $self->buffer->get_end_iter(),
                ' ',
                'cursor',
            );

            # Update IVs
            $self->ivPoke('cursorMark', $cursorMark);
            $self->ivPoke('cursorEndFlag', TRUE);

        } else {

            $cursorMark = $self->buffer->create_mark('cursor_mark', $iter, TRUE);

            $nextIter = $self->buffer->get_iter_at_mark($cursorMark);
            if (! $nextIter) {

                return undef;

            } else {

                $nextIter->forward_char();
                $iter = $self->buffer->get_iter_at_mark($cursorMark);
            }

            # If the visible cursor is at the end of a line (i.e. just before a newline character),
            #   insert a space character there so that the visible cursor is actually visible
            $length = $self->getLineLength($iter);
            if (
                ($lastFlag && $iter->get_visible_line_offset() >= $length)
                || (! $lastFlag && $iter->get_visible_line_offset() >= ($length - 1))
            ) {
                $self->buffer->insert_with_tags_by_name(
                    $iter,
                    ' ',
                    'cursor',
                );

            } else {

                # Just insert the Gtk3::TextTag for the cursor at this position
                $self->buffer->apply_tag_by_name(
                    'cursor',
                    $iter,
                    $nextIter,
                );
            }

            # Update IVs
            $self->ivPoke('cursorMark', $cursorMark);
            $self->ivPoke('cursorEndFlag', FALSE);
        }

        return 1;
    }

    sub replaceCursor {

        # Called by the clear buffer/clear line operations (e.g. $self->clearBufferAfterMark,
        #   ->clearLineAroundPosn, etc)
        # Calls $self->moveCursor with the correct arguments for the current situation
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the result of the call to $self->  moveCursor

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->replaceCursor', @_);
        }

        if ($self->insertMark) {
            return $self->moveCursor($self->buffer->get_iter_at_mark($self->insertMark));
        } else {
            return $self->moveCursor($self->buffer->get_end_iter());
        }
    }

    # Other functions - search the buffer

    sub setSearchMark {

        # Can be called by anything
        # Moves the Gtk3::TextMark used for searching the buffer from its current position to a new
        #   position
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $line   - The line number at which to place the mark. Use 0 for the beginning of the
        #               buffer, 1 for the second line, and so on. If 'undef' or if $line is greater
        #               than the size of the buffer, the mark is placed at the end of the buffer
        #   $offset - The offset on the line at which to place the mark. Use 0 for the beginning of
        #               the line, 1 to place the mark before the 2nd character, and so on. If
        #               'undef', the mark is placed at the end of the line (but before the newline
        #               character, if any)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $line, $offset, $check) = @_;

        # Local variables
        my ($size, $startIter, $length, $endIter);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setSearchMark', @_);
        }

        # Get the current size of the buffer
        $size = $self->buffer->get_line_count();
        if (! defined $line || $line >= $size) {

            $line = $size - 1;
        }

        # Get the iter at the start of that line
        $startIter = $self->buffer->get_iter_at_line_offset($line, 0);
        $length = $self->getLineLength($startIter);

        # Get the iter at the end of the buffer. If this line is not the last line in the buffer,
        #   we need to take account of the newline character
        $endIter = $self->buffer->get_end_iter();
        if ($endIter->get_line() != $startIter->get_line()) {

            $length--;
        }

        if (! defined $offset || $offset >= $length) {

            $offset = $length - 1;
            # Sanity check
            if ($offset < 0) {

                $offset = 0;
            }
        }

        # Move the search mark to the specified location
        $self->ivPoke(
            'searchMark',
            $self->buffer->create_mark(
                'search_mark',
                $self->buffer->get_iter_at_line_offset($line, $offset),
                TRUE,
            ),
        );

        return 1;
    }

    sub searchBuffer {

        # Can be called by anything
        # Searches the buffer using a specified pattern, stopping at the first matching text
        # If the beginning of the buffer is reached and no match is found, the search continues
        #   from the end of the buffer (and vice versa)
        # If a match is found, moves $self->searchMark to just before (or after) that location, so
        #   the next search can continue from that point
        #
        # Expected arguments
        #   $regex      - The regex to match
        #   $mode       - FALSE to search, line by line, from before $self->searchMark; TRUE to
        #                   search, line by line, from after $self->searchMark
        #
        # Optional arguments
        #   $selectFlag - If TRUE, the matching text is selected and the textview is scrolled to the
        #                   matching text
        #   $caseFlag   - If TRUE, a case-sensitive match is performed. If FALSE (or 'undef'), a
        #                   case-insensitive match is performed
        #
        # Return values
        #   An empty list on improper arguments or if no matching text is found
        #   1 otherwise

        my ($self, $regex, $mode, $selectFlag, $caseFlag, $check) = @_;

        # Local variables
        my (
            $size, $searchIter, $searchLine, $searchPosn, $text, $matchLine, $matchPosn, $matchLen,
            $matchIter,
            @emptyList,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->searchBuffer', @_);
            return @emptyList;
        }

        # Obviously, if the regex is empty, then there's nothing so search
        if ($regex eq '') {

            return @emptyList;
        }

        # Get the size of the buffer
        $size = $self->buffer->get_line_count();
        if (! $size) {

            # Buffer is empty
            return @emptyList;
        }

        # $self->searchIter records the position of the last successful search (or the position at
        #   which to start a search), so we'll start there
        $searchIter = $self->buffer->get_iter_at_mark($self->searchMark);
        if (! $searchIter) {

            # Something's gone wrong
            return @emptyList;
        }

        # If searching forwards, start searching from the first character after $searchIter
        if ($mode) {

            $searchIter->forward_char();
        }

        $searchLine = $searchIter->get_line();
        $searchPosn = $searchIter->get_line_offset();

        # Search lines, one by one, starting with $searchLine
        if (! $mode) {

            $text = $self->buffer->get_text(
                $self->buffer->get_iter_at_line_offset($searchLine, 0),
                $searchIter,
                FALSE,
            );

        } elsif ($searchLine >= ($size - 1)) {

            $text = $self->buffer->get_text(
                $searchIter,
                $self->buffer->get_end_iter(),
                FALSE,
            );

        } else {

            $text = $self->buffer->get_text(
                $searchIter,
                $self->buffer->get_iter_at_line_offset(($searchLine + 1), 0),
                FALSE,
            );
        }

        if (
            $text ne ''
            && (
                # Find last match in $text, just before $searchMark
                (
                    ! $mode
                    && (
                        (! $caseFlag && $text =~ m/$regex/gi)
                        || ($caseFlag && $text =~ m/$regex/g)
                    )
                # Find first match in $text, just after $searchMark
                ) || (
                    $mode
                    && (
                        (! $caseFlag && $text =~ m/$regex/i)
                        || ($caseFlag && $text =~ m/$regex/)
                    )
                )
            )
        ) {
            # Match found!
            $matchLine = $searchLine;
            $matchPosn = $-[0];
            $matchLen = $+[0] - $matchPosn;
            if ($mode) {

                $matchPosn += $searchPosn;
            }

            $self->setSearchMark($matchLine, $matchPosn);
            if ($selectFlag) {

                $self->selectTextInLine($matchLine, $matchPosn, $matchLen, TRUE);
            }

            return ($matchLine, $matchPosn, $matchLen);
        }

        # Search before (or after) $searchLine
        if ($size > 1) {

            if (! $mode && $searchLine > 0) {

                for (my $count = ($searchLine - 1); $count >= 0; $count--) {

                    $text = $self->buffer->get_text(
                        $self->buffer->get_iter_at_line_offset($count, 0),
                        $self->buffer->get_iter_at_line_offset(($count + 1), 0),
                        FALSE,
                    );

                    # Find last match in $text
                    if (
                        $text ne ''
                        && (
                            (! $caseFlag && $text =~ m/$regex/gi)
                            || ($caseFlag && $text =~ m/$regex/g)
                        )
                    ) {
                        # Match found!
                        $matchLine = $count;
                        $matchPosn = $-[0];
                        $matchLen = $+[0] - $matchPosn;

                        $self->setSearchMark($matchLine, $matchPosn);
                        if ($selectFlag) {

                            $self->selectTextInLine($matchLine, $matchPosn, $matchLen, TRUE);
                        }

                        return ($matchLine, $matchPosn, $matchLen);
                    }
                }

            } elsif ($mode && $searchLine < ($size - 1)) {

                for (my $count = ($searchLine + 1); $count <= ($size - 1); $count++) {

                    $text = $self->buffer->get_text(
                        $self->buffer->get_iter_at_line_offset($count, 0),
                        $self->buffer->get_iter_at_line_offset(($count + 1), 0),
                        FALSE,
                    );

                    # Find first match in $text
                    if (
                        $text ne ''
                        && (
                            (! $caseFlag && $text =~ m/$regex/i)
                            || ($caseFlag && $text =~ m/$regex/)
                        )
                    ) {
                        # Match found!
                        $matchLine = $count;
                        $matchPosn = $-[0];
                        $matchLen = $+[0] - $matchPosn;

                        $self->setSearchMark($matchLine, $matchPosn);
                        if ($selectFlag) {

                            $self->selectTextInLine($matchLine, $matchPosn, $matchLen, TRUE);
                        }

                        return ($matchLine, $matchPosn, $matchLen);
                    }
                }
            }

            # Reached the beginning (or the end) of the buffer, so now search the other part of the
            #   buffer from the opposite direction (i.e. if we reached the beginning of the buffer,
            #   search from the end)
            if (! $mode && $searchLine < ($size - 1)) {

                for (my $count = ($size - 1); $count > $searchLine; $count--) {

                    $text = $self->buffer->get_text(
                        $self->buffer->get_iter_at_line_offset($count, 0),
                        $self->buffer->get_iter_at_line_offset(($count + 1), 0),
                        FALSE,
                    );

                    # Find first match in $text
                    if (
                        $text ne ''
                        && (
                            (! $caseFlag && $text =~ m/$regex/i)
                            || ($caseFlag && $text =~ m/$regex/)
                        )
                    ) {
                        # Match found!
                        $matchLine = $count;
                        $matchPosn = $-[0];
                        $matchLen = $+[0] - $matchPosn;

                        $self->setSearchMark($matchLine, $matchPosn);
                        if ($selectFlag) {

                            $self->selectTextInLine($matchLine, $matchPosn, $matchLen, TRUE);
                        }

                        return ($matchLine, $matchPosn, $matchLen);
                    }
                }

            } elsif ($mode && $searchLine > 0) {

                for (my $count = 0; $count < $searchLine; $count++) {

                    $text = $self->buffer->get_text(
                        $self->buffer->get_iter_at_line_offset($count, 0),
                        $self->buffer->get_iter_at_line_offset(($count + 1), 0),
                        FALSE,
                    );

                    # Find first match in $text
                    if (
                        $text ne ''
                        && (
                            (! $caseFlag && $text =~ m/$regex/gi)
                            || ($caseFlag && $text =~ m/$regex/g)
                        )
                    ) {
                        # Match found!
                        $matchLine = $count;
                        $matchPosn = $-[0];
                        $matchLen = $+[0] - $matchPosn;

                        $self->setSearchMark($matchLine, $matchPosn);
                        if ($selectFlag) {

                            $self->selectTextInLine($matchLine, $matchPosn, $matchLen, TRUE);
                        }

                        return ($matchLine, $matchPosn, $matchLen);
                    }
                }
            }
        }

        # Now search the other part of $searchLine
        if ($mode) {

            $text = $self->buffer->get_text(
                $self->buffer->get_iter_at_line_offset($searchLine, 0),
                $searchIter,
                FALSE,
            );

        } elsif ($searchLine >= ($size - 1)) {

            $text = $self->buffer->get_text(
                $searchIter,
                $self->buffer->get_end_iter(),
                FALSE,
            );

        } else {

            $text = $self->buffer->get_text(
                $searchIter,
                $self->buffer->get_iter_at_line_offset(($searchLine + 1), 0),
                FALSE,
            );
        }

        if (
            $text ne ''
            && (
                # Find last match in $text, just before $searchMark
                (
                    $mode
                    && (
                        (! $caseFlag && $text =~ m/$regex/gi)
                        || ($caseFlag && $text =~ m/$regex/g)
                    )
                # Find first match in $text, just after $searchMark
                ) || (
                    ! $mode
                    && (
                        (! $caseFlag && $text =~ m/$regex/i)
                        || ($caseFlag && $text =~ m/$regex/)
                    )
                )
            )
        ) {
            # Match found!
            $matchLine = $searchLine;
            $matchPosn = $-[0];
            $matchLen = $+[0] - $matchPosn;
            if ($mode) {

                $matchPosn += $searchPosn;
            }

            $self->setSearchMark($matchLine, $matchPosn);
            if ($selectFlag) {

                $self->selectTextInLine($matchLine, $matchPosn, $matchLen, TRUE);
            }

            return ($matchLine, $matchPosn, $matchLen);
        }

        # No matches found
        return @emptyList;
    }

    sub selectTextInLine {

        # Can be called by anything, but mainly called by $self->searchBuffer
        # Selects some text on a single line, from one specified position to another. If required,
        #   the textview is scrolled to the start of the selected text
        #
        # Expected arguments
        #   $line           - The line number at which to select text. If the buffer doesn't contain
        #                       enough lines, no text is selected
        #   $offset         - The offset on the line from which to select text. If the line doesn't
        #                       contain enough characters, no text is selected
        #   $selectLength   - The length of the selected text. If it's longer than the line itself,
        #                       $selectLength is shortened so that only text on one line is selected
        #
        # Optional arguments
        #   $scrollFlag - If TRUE, the textview is scrolled to $line. If FALSE or 'undef', no
        #                   scrolling takes place
        #
        # Return values
        #   'undef' on improper arguments or if no text can be selected
        #   1 otherwise

        my ($self, $line, $offset, $selectLength, $scrollFlag, $check) = @_;

        # Local variables
        my ($size, $startIter, $lineLength, $endIter);

        # Check for improper arguments
        if (! defined $line || ! defined $offset || ! defined $selectLength || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->selectTextInLine', @_);
        }

        # Get the current size of the buffer
        $size = $self->buffer->get_line_count();
        if ($line >= $size) {

            # Buffer isn't big enough
            return undef;
        }

        # Get the iter at the specified position
        $startIter = $self->buffer->get_iter_at_line_offset($line, $offset);
        $lineLength = $self->getLineLength($startIter);

        # Get the iter at the end of the buffer. If this line is not the last line in the buffer,
        #   we need to take account of the newline character
        $endIter = $self->buffer->get_end_iter();
        if ($endIter->get_line() != $startIter->get_line()) {

            $lineLength--;
        }

        if ($offset >= $lineLength) {

            # The specified offset occurs after the end of the line
            return undef;

        } elsif (($offset + $selectLength) >= $lineLength) {

            # Reduce $selectLength so that text to the end of the line is selected
            $selectLength = $lineLength - $offset;
            if (! $selectLength) {

                # No text to select
                return undef;
            }
        }

        # Select the text
        $self->buffer->select_range(
            $startIter,
            $self->buffer->get_iter_at_line_offset($line, ($offset + $selectLength)),
        );

        # Scroll the textview, if required
        if ($scrollFlag) {

            if ($endIter->get_line() == $startIter->get_line()) {

                $self->scrollToBottom();

            } else {

                # Scroll to one line after the the matching text, as it looks nicer. The TRUE
                #   argument means to scroll $self->textView2, if split-screen mode is one
                $self->scrollToIter(
                    $self->buffer->get_iter_at_line_offset(($line + 1), 0),
                    TRUE,
                );
            }
        }

        return 1;
    }

    sub unselectText {

        # Can be called by anything
        # Unselects any text in the textview (possibly from an earlier call to
        #   $self->selectTextInLine)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $iter;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->unselectText', @_);
        }

        $iter = $self->buffer->get_iter_at_mark($self->searchMark);
        $self->buffer->select_range($iter, $iter);

        return 1;
    }

    # Other functions - must be called by specific code

    sub setupScroller {

        # Called by $self->objEnable, ->objUpdate and ->enableSingleScreen
        # Sets up the container widgets in which a single textview is displayed (when split screen
        #   mode is off)
        #
        # Expected arguments
        #   $textView       - The Gtk3::TextView to pack into its container widgets
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the Gtk3::ScrolledWindow which contains the textview

        my ($self, $textView, $check) = @_;

        # Check for improper arguments
        if (! defined $textView || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setupScroller', @_);
        }

        my $scroll = Gtk3::ScrolledWindow->new(undef, undef);
        $scroll->set_shadow_type($axmud::CLIENT->constShadowType);
        $scroll->set_policy('automatic', 'automatic');     # But word-wrapping turned on
        $scroll->set_border_width(0);

        # Pack the textview
        $scroll->add($textView);

        # Set up a ->signal_connect to detect scrolling, so we can reset the cursor (so the user
        #   can't move the cursor above a link, wait until the link scrolls away, and then still
        #   click the link)
        $self->setTextViewScrollEvent($scroll, $textView);

        return $scroll;
    }

    sub setupVPaned {

        # Called by $self->objUpdate, ->enableSplitScreen and ->enableHiddenSplitScreen
        # Sets up the container widgets in which the two textviews are displayed (when split screen
        #   mode is on)
        #
        # Expected arguments
        #   $textView, $textView2
        #           - The Gtk3::TextViews to pack into their container widgets
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list in the form
        #       (vpaned, scrolled_window, scrolled_window)

        my ($self, $textView, $textView2, $check) = @_;

        # Local variables
        my (
            $width, $height,
            @emptyList,
        );

        # Check for improper arguments
        if (! defined $textView || ! defined $textView2 || defined $check) {

             $axmud::CLIENT->writeImproper($self->_objClass . '->setupVPaned', @_);
             return @emptyList;
        }

        my $vPaned = Gtk3::VPaned->new();
        $vPaned->set_wide_handle(TRUE);

        # Decide where to put the Gtk3::VPaned divider
        $self->setDividerPosn($vPaned);

        # When replacing a single textview with two, the original textview ($textView) is added to
        #   the bottom half of the vpaned
        my $scroll = Gtk3::ScrolledWindow->new(undef, undef);
        $vPaned->pack2($scroll, FALSE, FALSE);
        $scroll->set_shadow_type($axmud::CLIENT->constShadowType);
        $scroll->set_policy('automatic', 'automatic');      # But word-wrapping turned on
        $scroll->set_border_width(0);

        my $scroll2 = Gtk3::ScrolledWindow->new(undef, undef);
        $vPaned->pack1($scroll2, FALSE, TRUE);
        $scroll2->set_shadow_type($axmud::CLIENT->constShadowType);
        $scroll2->set_policy('automatic', 'automatic');     # But word-wrapping turned on
        $scroll2->set_border_width(0);

        # Pack the textviews
        if ($textView->get_parent()) {

            $textView->unparent();
        }

        $scroll->add($textView);
        $scroll2->add($textView2);

        # Set up ->signal_connects to detect textview scrolling, so we can reset the cursor (so the
        #   user can't move the cursor above a link, wait until the link scrolls away, and then
        #   still click the link)
        $self->setTextViewScrollEvent($scroll, $textView);
        $self->setTextViewScrollEvent($scroll2, $textView2);

        return ($vPaned, $scroll, $scroll2)
    }

    sub setDividerPosn {

        # Called by $self->setupVPaned, ->enableSplitScreen and ->enableHiddenSplitScreen
        # In split screen modes 'split' and 'hidden', sets the position of the Gtk3::VPaned's
        #   divider
        #
        # Expected arguments
        #   $vPaned     - The Gtk3::VPaned object
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $vPaned, $check) = @_;

        # Local variables
        my ($width, $height);

        # Check for improper arguments
        if (! defined $vPaned || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setDividerPosn', @_);
        }

        # Decide where to put the divider
        if ($self->splitScreenMode eq 'split') {

            ($width, $height) = $self->paneObj->getTabSize();
            if (! defined $height) {
                $vPaned->set_position(100);
            } else {
                $vPaned->set_position(int($height / 2));
            }

        } elsif ($self->splitScreenMode eq 'hidden') {

            # Setting the position of the divider directly to 0 does not work, but this does work,
            #   for reasons unknown
            $vPaned->set_position(1);
            $vPaned->set_position(0);
        }

        return 1;
    }

    sub createTextViewWidget {

        # Called by various functions in this textview object (only) to create a uniform
        #   Gtk3::Textview widget
        #
        # Expected arguments
        #   $buffer         - The Gtk3::TextBuffer to use in the textview
        #
        # Optional arguments
        #   $schemeObj      - The colour scheme object (GA::Obj::ColourScheme), if known; otherwise,
        #                       this function looks it up
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $buffer, $schemeObj, $check) = @_;

        # Check for improper arguments
        if (! defined $buffer || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createTextViewWidget', @_);
        }

        # Fetch the colour scheme object, if not supplied
        if (! $schemeObj) {

            $schemeObj = $axmud::CLIENT->ivShow('colourSchemeHash', $self->colourScheme);
        }

        # Create the new textview
        my $textView = Gtk3::TextView->new_with_buffer($buffer);

        $textView->set_editable(FALSE);
        $textView->set_cursor_visible(FALSE);       # Invisible cursor
        $textView->set_can_focus(FALSE);
        $textView->set_justification('left');
        $textView->set_overwrite($self->overwriteFlag);

        if ($schemeObj->wrapMode eq 'no_wrap') {
            $textView->set_wrap_mode('none');
        } elsif ($schemeObj->wrapMode eq 'wrap_char') {
            $textView->set_wrap_mode('char');
        } elsif ($schemeObj->wrapMode eq 'wrap_word') {
            $textView->set_wrap_mode('word');
        } elsif ($schemeObj->wrapMode eq 'wrap_word_char') {
            $textView->set_wrap_mode('word-char');
        }

        # Set up ->signal_connects
        $self->setMotionNotifyEvent($textView);     # 'motion-notify-event'
        $self->setLeaveNotifyEvent($textView);      # 'leave-notify-event'
        $self->setFocusOutEvent($textView);         # 'focus-out-event'
        $self->setButtonPressEvent($textView);      # 'button-press-event'

        return $textView;
    }

    sub createColourTags {

        # Called by $self->objEnable
        # Defines the colour tags used by this Gtk3::TextView to change text and underlay colours
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (%colourTagHash, %boldColourTagHash, %xTermColourTagHash);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createColourTags', @_);
        }

        # Import IVs (for convenience)
        %colourTagHash = $axmud::CLIENT->colourTagHash;
        %boldColourTagHash = $axmud::CLIENT->boldColourTagHash;
        %xTermColourTagHash = $axmud::CLIENT->xTermColourHash;

        # Standard (normal) colour tags
        foreach my $tag (keys %colourTagHash) {

            # Text colours have tags in the format 'green' for normal colours and 'GREEN' for bold
            #   colours
            $self->buffer->create_tag(
                $tag,
                'foreground'    => $colourTagHash{$tag},
            );

            # Underlay colours have tags in the format 'ul_green' for normal colours and 'UL_GREEN'
            #   for bold colours
            $self->buffer->create_tag(
                'ul_' . $tag,
                'background'    => $colourTagHash{$tag},
            );
        }

        # Standard (bold) colour tags
        foreach my $tag (keys %boldColourTagHash) {

            $self->buffer->create_tag(
                $tag,
                'foreground'    => $boldColourTagHash{$tag},
            );

            $self->buffer->create_tag(
                'UL_' . $tag,
                'background'    => $boldColourTagHash{$tag},
            );
        }

        # XTerm colour tags
        foreach my $tag (keys %xTermColourTagHash) {

            # Text colours, e.g. 'x255'
            $self->buffer->create_tag(
                $tag,
                'foreground'    => $xTermColourTagHash{$tag},
            );

            # Underlay colours, e.g. 'ux255'
            $self->buffer->create_tag(
                'u' . $tag,
                'background'    => $xTermColourTagHash{$tag},
            );
        }

        # (NB RGB colour tags, e.g. '#ABCDEF', are created by $self->interpretTags when required)

        return 1;
    }

    sub updateStandardTag {

        # Called by GA::Cmd::SetColour->do
        # Updates the Gtk3::TextTag for a specified Axmud standard text colour tag, when the colour
        #   is modified
        # If the Gtk3::TextTag doesn't exist (for some reason), creates it
        #
        # Expected arguments
        #   $tag    - An Axmud standard text or underlay colour tag, e.g. 'red', 'BLUE', 'ul_red',
        #               'UL_BLUE')
        #
        # Return values
        #   'undef' on improper arguments or if $tag isn't an Axmud standard colour tag
        #   1 otherwise

        my ($self, $tag, $check) = @_;

        # Local variables
        my ($type, $underlayFlag, $boldType, $tagTable, $textTag, $rgb);

        # Check for improper arguments
        if (! defined $tag || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->updateStandardTag', @_);
        }

        # Check $tag is an Axmud standard colour tag
        ($type, $underlayFlag) = $axmud::CLIENT->checkColourTags($tag);
        $boldType = $axmud::CLIENT->checkBoldTags($tag);

        if (! $type || $type ne 'standard') {

            return undef;
        }

        # Get Gtk3 objects
        $tagTable = $self->buffer->get_tag_table();
        $textTag = $tagTable->lookup($tag);
        if (! $textTag) {

            # Add a new Gtk3::TextTag
            if (! $boldType) {

                if (! $underlayFlag) {

                    $self->buffer->create_tag(
                        $tag,
                        'foreground'    => $axmud::CLIENT->ivShow('colourTagHash', $tag),
                    );

                } else {

                    $self->buffer->create_tag(
                        $tag,
                        'background'    => $axmud::CLIENT->returnRGBColour($tag),
                    );
                }

            } else {

                if ($boldType eq 'text') {

                    $self->buffer->create_tag(
                        $tag,
                        'foreground'    => $axmud::CLIENT->ivShow('boldColourTagHash', $tag),
                    );

                } else {

                    $self->buffer->create_tag(
                        $tag,
                        'background'    => $axmud::CLIENT->returnRGBColour($tag),
                    );
                }
            }

        } else {

            # Modify an existing Gtk3::TextTag
            if (! $boldType) {

                if (! $underlayFlag) {

                    $textTag->set_property(
                        'foreground'    => $axmud::CLIENT->ivShow('colourTagHash', $tag),
                    );

                } else {

                    $textTag->set_property(
                        'background'    => $axmud::CLIENT->returnRGBColour($tag),
                    );
                }

            } else {

                if ($boldType eq 'text') {

                    $textTag->set_property(
                        'foreground'    => $axmud::CLIENT->ivShow('boldColourTagHash', $tag),
                    );

                } else {

                    $textTag->set_property(
                        'background'    => $axmud::CLIENT->returnRGBColour($tag),
                    );
                }
            }
        }

        return 1;
    }

    sub updateXTermTags {

        # Called by GA::Cmd::SetXTerm->do
        # Updates all Gtk3::TextTags for xterm colour tags, usually after the xterm colour cube is
        #   switched
        # If the Gtk3::TextTag doesn't exist (for some reason), creates it
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
            $tagTable,
            %tagHash,
        );

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->updateXTermTags', @_);
        }

        # Import the IV
        %tagHash = $axmud::CLIENT->xTermColourHash;
        # Get Gtk3::TextTagTable
        $tagTable = $self->buffer->get_tag_table();

        # Update (or create) each xterm colour tag in turn
        foreach my $tag (keys %tagHash) {

            my ($textTag, $underlayTag);

            # Text colours, e.g. 'x255'
            $textTag = $tagTable->lookup($tag);
            if (! $textTag) {

                $self->buffer->create_tag(
                    $tag,
                    'foreground'    => $tagHash{$tag},
                );

            } else {

                $textTag->set_property(
                    'foreground'    => $tagHash{$tag},
                );
            }

            # Underlay colours, e.g. 'ux255'
            $underlayTag = $tagTable->lookup('u' . $tag);
            if (! $underlayTag) {

                $self->buffer->create_tag(
                    'u' . $tag,
                    'background'    => $tagHash{$tag},
                );

            } else {

                $underlayTag->set_property(
                    'background'    => $tagHash{$tag},
                );
            }
        }

        return 1;
    }

    sub updateRGBTags {

        # Called by $self->objEnable and ->objUpdate (only)
        # When a colour scheme is applied to this textview, $self->textColour and/or
        #   ->underlayColour might be set
        # Gtk3::TextTags are usually created only as needed by $self->interpretTags, but that
        #   function won't have a chance to create Gtk3::TextTags if $self->textColour and/or
        #   ->underlayColour are now set to RGB colour tags like '#ABCDEF and 'u#ABCDEF'
        # Check which (if any) Gtk3::TextTags must be created, and create them
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($textColour, $underlayColour, $type, $ulFlag);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateRGBTags', @_);
        }

        if ($self->textColour) {

            $textColour = $self->textColour;

            ($type, $ulFlag) = $axmud::CLIENT->checkColourTags($textColour, 'rgb');
            if (defined $type && ! $self->buffer->get_tag_table->lookup($textColour)) {

                if (! $ulFlag) {

                    $self->buffer->create_tag(
                        $textColour,                                    # e.g. '#FFFFFF'
                        'foreground' => $textColour,                    # e.g. '#FFFFFF'
                    );

                } else {

                    # This should never be executed, but it's better to be safe than sorry
                    $self->buffer->create_tag(
                        $textColour,                                    # e.g. 'u#FFFFFF'
                        'background' => substr($textColour, 1),         # e.g. '#FFFFFF'
                    );
                }
            }
        }

        if ($self->underlayColour) {

            $underlayColour = $self->underlayColour;

            ($type, $ulFlag) = $axmud::CLIENT->checkColourTags($underlayColour, 'rgb');
            if (defined $type && ! $self->buffer->get_tag_table->lookup($underlayColour)) {

                if ($ulFlag) {

                    $self->buffer->create_tag(
                        $underlayColour,                                # e.g. 'u#FFFFFF'
                        'background' => substr($underlayColour, 1),     # e.g. '#FFFFFF'
                    );

                } else {

                    # This should never be executed, but it's better to be safe than sorry
                    $self->buffer->create_tag(
                        $underlayColour,                                # e.g. '#FFFFFF'
                        'foreground' => $underlayColour,                # e.g. '#FFFFFF'
                    );

                }
            }
        }

        return 1;
    }

    sub updateLinkTag {

        # Called by GA::Session->detectPueblo
        # When Pueblo is enabled, links are displayed in cyan and with no underline (normally, they
        #   are displayed with no particular colour, but with an underline)
        # This function modifies the Gtk3::TextTag's properties to display links in the correct way
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the 'link' tag is not updated
        #   1 if the 'link' tag is updated

        my ($self, $check) = @_;

        # Local variables
        my $linkTag;

        if (! $self->buffer || $self->session->puebloMode ne 'client_agree') {

            return undef;
        }

        $linkTag = $self->buffer->get_tag_table->lookup('link');
        if (! $linkTag) {

            return undef;
        }

        $linkTag->set_property(
            'foreground',
            $axmud::CLIENT->returnRGBColour($axmud::CLIENT->constPuebloLinkColour),
        );
        $linkTag->set_property('foreground-set', TRUE);
        $linkTag->set_property('underline', 'none');

        return 1;
    }

    sub createStyleTags {

        # Called by $self->objEnable
        # Defines the style tags used by this Gtk3::TextView to change the text style
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $background;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createStyleTags', @_);
        }

        # Italics
        $self->buffer->create_tag(
            'italics',
            'style'             => 'italic',
        );

        # Underline
        $self->buffer->create_tag(
            'underline',
            'underline'         => 'single',
        );

        # Blink: because the 'blink_slow' tag is sent to Gtk3 after the text and/or underlay tags,
        #   it overrules them when 'foreground-set' and 'background-set' are TRUE, but doesn't
        #   overrule them when 'foreground-set' and 'background-set' are FALSE. We can make the text
        #   blink by alternating the values between TRUE and FALSE.
        # NB Gtk3 doesn't understand Axmud colour tags like 'ul_green', so we must convert them to
        #   RGB
        $background = $axmud::CLIENT->returnRGBColour($self->backgroundColour);

        # Blink slow
        $self->buffer->create_tag(
            'blink_slow',
            'foreground'        => $background,
            'foreground-set'    => TRUE,                        # Text initially invisible
            'background'        => $background,
            'background-set'    => TRUE,                        # Underlay initially invisible
        );

        # Blink fast
        $self->buffer->create_tag(
            'blink_fast',
            'foreground'        => $background,
            'foreground-set'    => TRUE,
            'background'        => $background,
            'background-set'    => TRUE,
        );

        # Strikethrough
        $self->buffer->create_tag(
            'strike',
            'strikethrough'     => 1,
        );

        # Clickable links
        if ($self->session->puebloMode eq 'client_agree') {

            # In Pueblo mode, clickable links are cyan, and not underlined
            $self->buffer->create_tag(
                'link',
                'foreground'        => $axmud::CLIENT->returnRGBColour(
                                            $axmud::CLIENT->constPuebloLinkColour,
                                       ),
                'foreground-set'    => TRUE,
            );

        } else {

            # At all other times, clickable links are just underlined
            $self->buffer->create_tag(
                'link',
                'underline'         => 'single',
            );
        }

        # Justification
        $self->buffer->create_tag(
            'justify_left',
            'justification'     => 'left',
        );

        $self->buffer->create_tag(
            'justify_centre',
            'justification'     => 'center',
        );

        $self->buffer->create_tag(
            'justify_right',
            'justification'     => 'right',
        );

        $self->buffer->create_tag(
            'justify_default',
            'justification'     => 'left',
        );

        # A special tag, not related to any Axmud colour/style tag, which handles a visible cursor
        #   in the textview. Only one position in $self->buffer (if any) uses this tag at a time
        # It's added to the buffer after any text insertion operation, so it should overrule any
        #   'underline' tag that already exists at that position
        $self->buffer->create_tag(
            'cursor',
            'underline'         => 'single',
        );

        return 1;
    }

    sub setMonochromeMode {

        # Called by GA::Table::Pane->applyMonochrome (must not be called directly)
        # Applies a monochrome colour scheme to the textview(s), using the specified background
        #   colour, and choosing for itself a suitable text colour (if no text colour is
        #   also specified)
        # Sets $self->monochromeFlag to TRUE, if it's not already set
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $backgroundColour
        #           - The background colour to use (can be any Axmud colour tag, e.g 'red'). If it's
        #               an underlay tag like 'ul_red', the equivalent colour tag is used instead. If
        #               'undef', the background colour specified by $self->colourScheme is used
        #   $textColour
        #           - The text colour to use. Is normally 'undef', in which case this function will
        #               choose a suitable text colour to match the background. Should be specified
        #               if $backgroundColour is an Xterm or RGB colour tag, otherwise the text
        #               colour might not suit the background colour
        #
        # Return values
        #   'undef' on improper arguments or if a specified $backgroundColour is not a recognised
        #       Axmud colour tag
        #   1 otherwise

        my ($self, $backgroundColour, $textColour, $check) = @_;

        # Local variables
        my ($colourSchemeObj, $defaultFlag, $type, $underlayFlag);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setMonochromeMode', @_);
        }

        $colourSchemeObj = $axmud::CLIENT->ivShow('colourSchemeHash', $self->colourScheme);

        # If no $backgroundColour was specified, use the background colour from $self->colourScheme
        if (! defined $backgroundColour) {

            if ($colourSchemeObj) {

                $backgroundColour = $colourSchemeObj->backgroundColour;
                $defaultFlag = TRUE;

            } else {

                # Emergency fallback colour
                $backgroundColour = 'black';
            }

        } else {

            # Convert an underlay tag into a normal tag
            ($type, $underlayFlag) = $axmud::CLIENT->checkColourTags($backgroundColour);
            if ($type && $underlayFlag) {

                $backgroundColour = $axmud::CLIENT->swapColours($backgroundColour);
            }
        }

        # If no text colour was specified, choose one to match the background colour
        if (! $textColour) {

            if ($axmud::CLIENT->ivExists('constMonochromeHash', $backgroundColour)) {

                $textColour = $axmud::CLIENT->ivShow('constMonochromeHash', $backgroundColour);

            } elsif (! $defaultFlag) {

                # Non-standard background colour tag. Use a fallback text colour; if it doesn't
                #   match the background colour well, that's the fault of the calling function for
                #   not specifying $textColour
                if (uc($backgroundColour) eq '#FFFFFF' || lc($backgroundColour) eq 'x255') {
                    $textColour = 'black';
                } else {
                    $textColour = 'WHITE';
                }

            } elsif ($colourSchemeObj) {

                # Non-standard background colour tag supplied by the colour scheme, so use the text
                #   colour supplied by the colour scheme
                $textColour = $colourSchemeObj->textColour;

            } else {

                # Emergency fallback colour
                $backgroundColour = 'white';
            }
        }

        # Update IVs. Underlay colours are not used in monochrome mode, so that IV is set to 'undef'
        $self->ivPoke('textColour', $textColour);
        $self->ivUndef('underlayColour');
        $self->ivPoke('backgroundColour', $backgroundColour);
        $self->ivPoke('monochromeFlag', TRUE);

        if (! $colourSchemeObj || $colourSchemeObj->backgroundColour eq $backgroundColour) {
            $self->ivPoke('monochromeModFlag', FALSE);
        } else {
            $self->ivPoke('monochromeModFlag', TRUE);
        }

        # Apply the monochrome colour scheme
        return $self->objUpdate();
    }

    sub resetMonochromeMode {

        # Called by GA::Table::Pane->removeMonochrome (must not be called directly)
        # Removes the monochrome colour scheme currently being used, and restores the colour scheme
        #   specified by $self->colourScheme
        # Sets $self->monochromeFlag to FALSE, if it's not already set
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if a monochrome colour scheme isn't in use currently
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetMonochromeMode', @_);
        }

        if (! $self->monochromeFlag) {

            return undef;

        } else {

            $self->ivPoke('monochromeFlag', FALSE);
            $self->ivPoke('monochromeModFlag', FALSE);

            return $self->objUpdate($self->colourScheme);
        }
    }

    sub applyColourStyleTags {

        # Called by GA::Session->processLineSegment and ->applyTriggerStyle
        # Also called by GA::Buffer::Display->copyLine
        #
        # GA::CLIENT->constColourStyleHash specifies a standard format for describing the Axmud
        #   colour/style tags that apply at some offset in some text
        # This function takes a hash in that format, describing the tags that apply to an
        #   unspecified offset in this textview (which might have been displayed already, or not)
        # The hash is then updated using a list of Axmud colour/style tags, so that hash describes
        #   the tags that apply to a later offset in this textview (that hasn't been displayed yet)
        #
        # Expected arguments
        #   $session    - The calling GA::Session
        #   $listRef    - A reference to a list of Axmud colour/style tags which are used to modify
        #                   the hash (can be an empty list)
        #
        # Optional arguments
        #   %tagHash    - A hash in the format specified by GA::CLIENT->constColourStyleHash, i.e.
        #
        #                   'text'       => 'undef' or an Axmud text colour tag, e.g. 'red' or
        #                                       'x230'
        #                   'underlay'   => 'undef' or an Axmud underlay colour tag, e.g. 'ul_white'
        #                   'italics'    => TRUE or FALSE
        #                   'underline'  => TRUE or FALSE
        #                   'blink_slow' => TRUE or FALSE
        #                   'blink_fast' => TRUE or FALSE
        #                   'strike'     => TRUE or FALSE
        #                   'link'       => TRUE or FALSE
        #                   'mxp_font'   => TRUE or FALSE
        #                   'justify'    => 'left', 'right', 'centre', or 'undef' to represent the
        #                                       style tag 'justify_default'
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns the modified hash

        my ($self, $session, $listRef, %tagHash) = @_;

        # Local variables
        my (
            $attribsOffFlag,
            %styleHash, %justifyHash, %dummyHash,
        );

        # Check for improper arguments
        if (! defined $session || ! defined $listRef) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->applyColourStyleTags', @_);
        }

        # Import IVs (for quick lookup)
        %styleHash = $axmud::CLIENT->constStyleTagHash;
        %justifyHash = $axmud::CLIENT->constJustifyTagHash;
        %dummyHash = $axmud::CLIENT->constDummyTagHash;

        foreach my $tag (@$listRef) {

            my ($type, $underlayFlag, $boldishTag);

            # When called by GA::Session->applyTriggerStyle, @tagList can contain bold text colour
            #   tags like 'BLUE'. When called by GA::Session->processLineSegment, @tagList would
            #   instead contain the pair 'bold', 'blue'
            # @tagList might also contain bold underlay colours like 'UL_BLUE', but that doesn't
            #   affect the setting of $tagHash{'bold'} (which only applies to text colours)
            $type = $axmud::CLIENT->checkBoldTags($tag);
            if ($type && $type eq 'text') {

                # $tag is a bold colour tag. Pretend that we processed a 'bold' dummy tag during
                #   the last iteration of this loop
                $tagHash{'bold'} = TRUE;
                # Since we're about to change the text colour, we can rely on the following code to
                #   take care of $tagHash{'text'}, $tagHash{'real_text'} and so on
                $tag = lc($tag);
            }

            # PART 1: 'Dummy' style tags
            if (exists $dummyHash{$tag}) {

                if ($tag eq 'attribs_off') {

                    # A dummy tag created by GA::Session->processEscSequence, which corresponds to
                    #   'all attributes off'. We implement this by resetting %tagHash
                    %tagHash = $axmud::CLIENT->constColourStyleHash;
                    $attribsOffFlag = TRUE;

                } elsif ($tag eq 'bold') {

                    # A 'dummy' style tag
                    if (! $tagHash{'bold'}) {

                        $tagHash{'bold'} = TRUE;

                        # (If %tagHash currently contains no text colour, we have to add one, so
                        #   that the bold text is visible)
                        if (! $tagHash{'real_text'}) {
                            $tagHash{'real_text'} = uc($self->textColour);
                        } else {
                            $tagHash{'real_text'} = uc($tagHash{'real_text'});
                        }

                        # In conceal mode we don't make any changes to $tagHash{'text'} and
                        #   $tagHash{'underlay'}
                        if ($tagHash{'reverse'}) {

                            $tagHash{'underlay'}
                                = $axmud::CLIENT->swapColours($tagHash{'real_text'});

                        } elsif (! $tagHash{'conceal'}) {

                            $tagHash{'text'} = $tagHash{'real_text'};
                        }

                        # In conceal mode and reverse video mode, changing the underlay colour has
                        #   no effect
                        if (! $tagHash{'conceal'} && ! $tagHash{'reverse'}) {

                            $tagHash{'underlay'} = $tagHash{'real_underlay'};
                        }
                    }

                    # (A second 'bold' tag is ignored)

                } elsif ($tag eq 'bold_off') {

                    # A 'dummy' style tag
                    if ($tagHash{'bold'}) {

                        $tagHash{'bold'} = FALSE;

                        if ($tagHash{'real_text'}) {

                            $tagHash{'real_text'} = lc($tagHash{'real_text'});
                        }

                        if ($tagHash{'reverse'}) {

                            $tagHash{'underlay'}
                                = $axmud::CLIENT->swapColours($tagHash{'real_text'});

                        } elsif (! $tagHash{'conceal'}) {

                            $tagHash{'text'} = $tagHash{'real_text'};
                        }

                        # In conceal mode and reverse video mode, changing the underlay colour has
                        #   no effect
                        if (! $tagHash{'conceal'} && ! $tagHash{'reverse'}) {

                            $tagHash{'underlay'} = $tagHash{'real_underlay'};
                        }
                    }

                    # (A second consecutive 'bold_off' tag is ignored)

                } elsif ($tag eq 'reverse') {

                    # A 'dummy' style tag
                    if (! $tagHash{'reverse'}) {

                        $tagHash{'reverse'} = TRUE;

                        # In reverse video mode, the existing text colour is used as the underlay
                        #   colour. The existing underlay colour is ignored, if it is set, because
                        #   reverse video was designed for monochrome monitors
                        # In addition, the textview background colour is used as the new text colour

                        # Conceal mode takes priority over reverse video mode, if that is already on
                        if (! $tagHash{'conceal'}) {

                            $tagHash{'text'} = $self->backgroundColour;
                            if ($tagHash{'real_text'}) {

                                $tagHash{'underlay'}
                                    = $axmud::CLIENT->swapColours($tagHash{'real_text'});

                            } else {

                                $tagHash{'underlay'}
                                    = $axmud::CLIENT->swapColours($self->textColour);
                            }
                        }
                    }

                    # (A second 'reverse' tag is ignored)

                } elsif ($tag eq 'reverse_off') {

                    # A 'dummy' style tag
                    if ($tagHash{'reverse'}) {

                        $tagHash{'reverse'} = FALSE;
                        if (! $tagHash{'conceal'}) {

                            $tagHash{'text'} = $tagHash{'real_text'};
                            $tagHash{'underlay'} = $tagHash{'real_underlay'};
                        }
                    }

                    # (A second consecutive 'reverse_off' tag is ignored)

                } elsif ($tag eq 'conceal') {

                    # A 'dummy' style tag
                    if (! $tagHash{'conceal'}) {

                        $tagHash{'conceal'} = TRUE;

                        # In conceal mode, both the text and underlay colours are set to the same as
                        #   the textview background colour, so that the text is invisible unless the
                        #   user selects it with the mouse
                        # Conceal mode takes priority over reverse video mode, if that is already on
                        $tagHash{'text'} = $self->backgroundColour;
                        $tagHash{'underlay'}
                            = $axmud::CLIENT->swapColours($self->backgroundColour);
                    }

                    # (A second 'conceal' tag is ignored)

                } elsif ($tag eq 'conceal_off') {

                    # A 'dummy' style tag
                    if ($tagHash{'conceal'}) {

                        $tagHash{'conceal'} = FALSE;
                        if ($tagHash{'reverse'}) {

                            $tagHash{'text'} = $self->backgroundColour;
                            $tagHash{'underlay'}
                                = $axmud::CLIENT->swapColours($tagHash{'real_text'});

                        } else {

                            $tagHash{'text'} = $tagHash{'real_text'};
                            $tagHash{'underlay'} = $tagHash{'real_underlay'};
                        }
                    }

                    # (A second consecutive 'conceal_off' tag is ignored)

                } elsif ($tag eq 'mxpf_off') {

                    # (Other 'mxpf_...' tags are handled below)
                    $tagHash{'mxp_font'} = undef;
                }

            # PART 2: Justification style tags
            } elsif (exists $justifyHash{$tag}) {

                if ($tag eq 'justify_default') {
                    $tagHash{'justify'} = undef;
                } else {
                    $tagHash{'justify'} = substr($tag, 8);
                }

            # PART 3: Style tags
            } elsif (exists $styleHash{$tag}) {

                # (Codes listed in rough order of popularity)
                if ($tag eq 'link') {

                    if ($tagHash{'link'}) {
                        $tagHash{'link'} = FALSE;
                    } else {
                        $tagHash{'link'} = TRUE;
                    }

                } elsif ($tag eq 'link_off') {

                    $tagHash{'link'} = FALSE;

                } elsif (
                    $tag eq 'italics'
                    || $tag eq 'underline'
                    || $tag eq 'blink_slow'
                    || $tag eq 'blink_fast'
                    || $tag eq 'strike'
                ) {
                    # (A second consecutive tag reinforces the previous one)
                    $tagHash{$tag} = TRUE;

                } elsif ($tag eq 'italics_off') {

                    $tagHash{'italics'} = FALSE;

                } elsif ($tag eq 'underline_off') {

                    $tagHash{'underline'} = FALSE;

                } elsif ($tag eq 'blink_off') {

                    $tagHash{'blink_slow'} = FALSE;
                    $tagHash{'blink_fast'} = FALSE;

                } elsif ($tag eq 'strike_off') {

                    $tagHash{'strike'} = FALSE;
                }

            # PART 4: MXP style tags
            } elsif (substr($tag, 0, 5) eq 'mxpf_') {

                # Dummy style tags used for MXP fonts
                # Store the whole dummy tag, e.g. 'mxpf_monospace_bold_12' (NB 'mxpf_off' was
                #   handled further above)
                $tagHash{'mxp_font'} = $tag;

            } elsif (substr($tag, 0, 5) eq 'mxpm_') {

                # Dummy style tag used for MXP modes in the range 10-12, 19, 20-99 (which don't
                #   affect text attributes, so we don't add them to %tagHash)
                # ...

            # PART 5: Colour tags
            } else {

                ($type, $underlayFlag) = $axmud::CLIENT->checkColourTags($tag);
                if ($type) {

                    if ($type eq 'standard') {

                        # We're going to check $tag against the textview's object colour in a
                        #   moment, which is stored as (for example) 'RED' if it's a bold colour. We
                        #   need to compare it with 'RED', not 'red', if bold is on
                        if ($tagHash{'bold'}) {
                            $boldishTag = uc($tag);
                        } else {
                            $boldishTag = $tag;
                        }

                    } else {

                        # xterm/RGB colour tags should be case insensitive
                        $boldishTag = lc($tag);
                    }
                }

                # PART 5a: Text colour tags
                if ($type && ! $underlayFlag) {

                    if (
                        defined $tagHash{'real_text'}
                        && $tagHash{'real_text'} eq $tag
                    ) {
                        # (The re-occuring tag is ignored)

                    } elsif ($attribsOffFlag && $boldishTag eq $self->textColour) {

                        # After an 'attribs off', if the tag matches the 'main' window's normal text
                        #   colour, let that be the text colour
                        # (This takes care of ANSI escape sequences like '^[0;37;40m', meaning
                        #   'attribs off - white text - black underlay'. If we set
                        #   $tagHash{'underlay'} to 'ul_black', the next 'bold' tag - which was
                        #   intended to apply only to the text colour - will be applied to the
                        #   underlay colour, too.)
                        $tagHash{'real_text'} = undef;
                        if ($tagHash{'reverse'}) {

                            $tagHash{'text'} = $self->backgroundColour;
                            $tagHash{'underlay'}
                                = $axmud::CLIENT->swapColours($self->textColour);

                        } else {

                            $tagHash{'text'} = $tagHash{'real_text'};
                        }

                    } elsif ($tagHash{'bold'} && $type eq 'standard') {

                        # Bold text colour
                        $tagHash{'real_text'} = uc($tag);
                        # If the world is using an OSC colour palette to modify this colour, use the
                        #   modified form
                        if ($session->ivExists('oscColourHash', $tagHash{'real_text'})) {

                            $tagHash{'real_text'}
                                = $session->ivShow('oscColourHash', $tagHash{'real_text'});
                        }

                        # In conceal mode we don't make any changes to $tagHash{'text'} and
                        #   $tagHash{'underlay'}
                        if ($tagHash{'reverse'}) {

                            $tagHash{'underlay'}
                                = $axmud::CLIENT->swapColours($tagHash{'real_text'});

                        } elsif (! $tagHash{'conceal'}) {

                            $tagHash{'text'} = $tagHash{'real_text'};
                        }

                    } else {

                        # Normal colour, or a bold underlay colour like 'UL_BLUE', specified
                        #   directly by a call from GA::Session->applyTriggerStyle
                        $tagHash{'real_text'} = $tag;
                        # If the world is using an OSC colour palette to modify this colour, use the
                        #   modified form
                        if ($session->ivExists('oscColourHash', $tagHash{'real_text'})) {

                            $tagHash{'real_text'}
                                = $session->ivShow('oscColourHash', $tagHash{'real_text'});
                        }

                        if ($tagHash{'reverse'}) {

                            $tagHash{'underlay'}
                                = $axmud::CLIENT->swapColours($tagHash{'real_text'});

                        } elsif (! $tagHash{'conceal'}) {

                            $tagHash{'text'} = $tagHash{'real_text'};
                        }
                    }

                # PART 5b: Underlay colour tags
                } elsif ($type && $underlayFlag) {

                    if (
                        defined $tagHash{'real_underlay'}
                        && $tagHash{'real_underlay'} eq $tag
                    ) {
                        # (The re-occuring tag is ignored)

                    } elsif ($attribsOffFlag && $boldishTag eq $self->underlayColour) {

                        # After an 'attribs off', if the tag matches the 'main' window's normal
                        #   underlay colour, let that be the underlay colour
                        $tagHash{'real_underlay'} = undef;

                    } else {

                        $tagHash{'real_underlay'} = $tag;

                        # If the world is using an OSC colour palette to modify this colour, use the
                        #   modified form
                        if ($session->ivExists('oscColourHash', $tagHash{'real_underlay'})) {

                            $tagHash{'real_underlay'}
                                = $session->ivShow('oscColourHash', $tagHash{'real_underlay'});
                        }
                    }

                    # In conceal mode and reverse video mode, changing the underlay colour has no
                    #   effect
                    if (! $tagHash{'conceal'} && ! $tagHash{'reverse'}) {

                        $tagHash{'underlay'} = $tagHash{'real_underlay'};
                    }
                }
            }
        }

        return %tagHash;
    }

    sub listColourStyleTags {

        # Called by GA::Session->processLineSegment and GA::Buffer::Display->new, ->update
        # The argument is a hash, in the form specified by GA::CLIENT->constColourStyleHash, of
        #   Axmud colour/style tags that apply at some offset in the textview. This function
        #   converts the hash to a simple list
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   %tagHash    - A hash of Axmud colour/style tags in the form specified by
        #                   GA::CLIENT->constColourStyleHash. If an empty hash,
        #                   $self->colourStyleHash is used instead
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns the converted list of Axmud colour/style tags (may be an empty list)

        my ($self, %tagHash) = @_;

        # Local variables
        my @returnList;

        # (No improper arguments to check)

        # Import this textview's current hash of colour/style tags, if no hash was specified
        if (! %tagHash) {

            %tagHash = $self->colourStyleHash;
        }

        # Compile a list of colour/style tags which now apply (tags listed in rough order of
        #   popularity)
        if (defined $tagHash{'text'}) {

            push (@returnList, $tagHash{'text'});
        }

        if (defined $tagHash{'underlay'}) {

            push (@returnList, $tagHash{'underlay'});
        }

        if ($tagHash{'link'}) {

            push (@returnList, 'link');
        }

        if ($tagHash{'italics'}) {

            push (@returnList, 'italics');
        }

        if ($tagHash{'underline'}) {

            push (@returnList, 'underline');
        }

        if ($tagHash{'blink_slow'}) {

            push (@returnList, 'blink_slow');
        }

        if ($tagHash{'blink_fast'}) {

            push (@returnList, 'blink_fast');
        }

        if ($tagHash{'strike'}) {

            push (@returnList, 'strike');
        }

        if (defined $tagHash{'mxp_font'}) {

            push (@returnList, $tagHash{'mxp_font'});
        }

        if (defined $tagHash{'justify'}) {

            # e.g. 'justify_left'
            push (@returnList, 'justify_' . $tagHash{'justify'});
        }

        return @returnList;
    }

    sub showLinkTooltips {

        # Called by $self->checkMousePosn
        # Shows the tooltips window to display a link hint
        #
        # Expected arguments
        #   $linkObj        - The GA::Obj::Link whose ->hint must be displayed in the tooltip
        #
        # Return values
        #   'undef' on improper arguments or if the tooltip can't be shown
        #   1 otherwise

        my ($self, $linkObj, $check) = @_;

        # Local variables
        my $hint;

        # Check for improper arguments
        if (! defined $linkObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->showLinkTooltips', @_);
        }

        # Don't show tooltips if the parent window isn't active, or if the GA::Obj::Link object
        #   doesn't have a ->hint set
        $hint = $linkObj->hint;
        if (! $self->winObj->winWidget->is_active() || ! $hint) {

            return undef;

        } else {

            $self->textView->set_tooltip_text($hint);
            if ($self->textView2) {

                $self->textView2->set_tooltip_text($hint);
            }

            return 1;
        }
    }

    sub showSessionTooltips {

        # Called by $self->checkMousePosn (but only if this is the session's default textview, and
        #   if the mouse is hovering over a line containing text received from the world)
        # Shows the tooltips window to display information about the display buffer objects
        #   (GA::Buffer::Display) corresponding to this line
        #
        # Expected arguments
        #   $lineNum    - The line number of the Gtk3::TextBuffer line above which the mouse is
        #                   hovering
        #
        # Return values
        #   'undef' on improper arguments or if the tooltip can't be shown
        #   1 otherwise

        my ($self, $lineNum, $check) = @_;

        # Local variables
        my $tooltip;

        # Check for improper arguments
        if (! defined $lineNum || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->showSessionTooltips', @_);
        }

        # Don't show tooltips if the parent window isn't active
        if (! $self->winObj->winWidget->is_active()) {

            return undef;
        }

        if (defined $self->lastTooltipLine && $self->lastTooltipLine != $lineNum) {

            # The mouse has moved over a new line. Make the tooltip window 'follow' it by
            #   briefly resetting the tooltip
            $self->textView->set_tooltip_text('');
            if ($self->textView2) {

                $self->textView2->set_tooltip_text('');
            }

            $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->checkMousePosn');
        }

        # Show the window
        $tooltip = $self->ivShow('tooltipHash', $lineNum);
        $self->textView->set_tooltip_text($tooltip);
        if ($self->textView2) {

            $self->textView2->set_tooltip_text($tooltip);
        }

        $self->ivPoke('lastTooltipLine', $lineNum);

        return 1;
    }

    sub hideTooltips {

        # Called by $self->checkMousePosn and various ->signal_connects in this textview object
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the tooltip can't be hidden
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->hideTooltips', @_);
        }

        # Hide the tooltips window
        $self->textView->set_tooltip_text('');
        if ($self->textView2) {

            $self->textView2->set_tooltip_text('');
        }

        # Update IVs
        $self->ivUndef('lastTooltipLine');

        return 1;
    }

    sub useDisplayBufferNum {

        # Called by GA::Session->processLineSegment (only)
        # The calling function is informing us that this textview object is its default textview
        #   object, that it's about to call ->insertText, and that we should make a note of the
        #   session's current display buffer line number, so we can display our tooltips correctly
        #
        # Expected arguments
        #   $sessionLineNum     - The session's display buffer line number (matching
        #                           GA::Session->displayBufferCount)
        #
        # Return values
        #   'undef' on improper arguments

        #   1 otherwise

        my ($self, $sessionLineNum, $check) = @_;

        # Local variables
        my $iter;

        # Check for improper arguments
        if (! defined $sessionLineNum || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->useDisplayBufferNum', @_);
        }

        # The hash only needs to be updated, once per line of non-system message text
        # The Gtk3::Textbuffer renumbers its line every time we delete one from the beginning of the
        #   buffer, so here we must add $self->nextDeleteLine
        if (! $self->insertMark && $self->newLineFlag) {

            $iter = $self->buffer->get_end_iter();
            $self->ivAdd(
                'tooltipHash',
                ($iter->get_line() + $self->nextDeleteLine),
                'Line ' . $sessionLineNum . ', ' . $axmud::CLIENT->localTime,
            );
        }

        return 1;
    }

    sub createPopupMenu {

        # Called by ->signal_connect in $self->setButtonPressEvent
        # After the user has clicked on $self->currentLinkObj, creates a popup menu from which the
        #   user can select one of several menu items. If the user clicks on a menu item, the
        #   corresponding world command is sent
        # The menu options and corresponding world commands are (usually) set by an MXP
        #   <SEND>..</SEND> construction
        #
        # Expected arguments
        #   $event          - The 'button_press_event' signal emitted when the user clicks on a
        #                       clickable link in the tab
        #
        # Return values
        #   'undef' on improper arguments or if the popup menu can't be created
        #   1 otherwise

        my ($self, $event, $check) = @_;

        # Local variables
        my (
            $linkObj, $count,
            @optionList,
        );

        # Check for improper arguments
        if (! defined $event || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->createPopupMenu', @_);
        }

        # Check there is a current link object set (no reason why there shouldn't be)
        if (! $self->currentLinkObj) {

            return undef;

        } else {

            # $self->currentLinkObj will be set to 'undef' as soon as the popup menu is clicked,
            #   and before this function returns, so store the object as a local variable)
            $linkObj = $self->currentLinkObj;
        }

        # Create the popup menu
        my $menu = Gtk3::Menu->new();

        # The GA::Obj::Link stores menu items and corresponding world commands each as a single
        #   string, with items/commands separated by a | character
        # (If there was an extra item in @optionList, representing an extra tooltip hint to show
        #   e.g. "Click to see the menu", it has already been removed)
        @optionList = $linkObj->popupItemList;

        $count = -1;
        foreach my $cmd ($linkObj->popupCmdList) {

            my ($hint, $menuItem);

            $count++;

            # Prefer to use a hint over a raw command, if a hint was supplied
            $hint = shift (@optionList);
            $menuItem = Gtk3::MenuItem->new_with_label('');

            my $label = $menuItem->get_child();
            if ($hint) {

                if (! $count) {
                    $label->set_markup('<b>' . $hint . '</b>');
                } else {
                    $label->set_markup($hint);
                }

            } else {

                if (! $count) {
                    $label->set_markup('<b>' . $cmd . '</b>');
                } else {
                    $label->set_markup($cmd);
                }
            }

            $menu->append($menuItem);
            $menuItem->signal_connect('activate' => sub {

                my $stripObj = $self->paneObj->winObj->getStrip('entry');

                if ($linkObj->mxpPromptFlag && $stripObj) {
                    $stripObj->commandeerEntry($self->session, $cmd);
                } else {
                    $self->session->worldCmd($cmd);
                }
            });
        }

        $menu->popup(
            undef, undef, undef, undef,
            $event->button,
            $event->time,
        );

        $menu->show_all();

        # Store as an IV, so that $self->resetCurrentLink can destroy it, if the link expires
        $self->ivPoke('popupMenu', $menu);
        $menu->signal_connect('delete-event' => sub {

            $self->ivUndef('popupMenu');

            return undef;
        });

        return 1;
    }

    sub resetCurrentLink {

        # Called by GA::Session->processMxpOfficialElement when the GA::Obj::Link object stored in
        #   $self->currentLinkObj expires
        # Hides tooltips, resets the cursor, closes the popup menu
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if this isn't the 'main' window
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetCurrentLink', @_);
        }

        # Hide tooltips, if visible
        $self->hideTooltips();

        # Reset the cursor
        if ($self->textView) {

            $self->textView->get_window('text')->set_cursor($axmud::CLIENT->constNormalCursor);
        }

        # Close the popup menu
        if ($self->popupMenu) {

            $self->popupMenu->destroy();

            $self->ivUndef('popupMenu');
        }

        return 1;
    }

    sub toggleScrollLock {

        # Called by GA::Table::Pane->toggleScrollLock
        # Enables or disables this textview object's scroll lock mode, in which the textview scrolls
        #   to the bottom every time text is received from the world. (If split screen mode is
        #   enabled, only the original lower textview scrolls)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->toggleScrollLock', @_);
        }

        if (! $self->scrollLockFlag) {

            $self->ivPoke('scrollLockFlag', TRUE);

            # Scroll to the beginning/end of the buffer in the (original) textview immediately
            if ($self->scrollLockType eq 'top') {
                $self->scrollToTop();
            } else {
                $self->scrollToBottom();
            }

        } else {

            $self->ivPoke('scrollLockFlag', FALSE);

            $self->winObj->winShowAll($self->_objClass . '->toggleScrollLock');
        }

        # Operation complete
        return 1;
    }

    sub setSplitScreenMode {

        # Called by GA::Table::Pane->convertSimpleTab, ->convertTab and ->toggleSplitScreen
        # Sets this textview object's split screen mode, adding or removing a second textview and
        #   repositioning the divider between two textviews as required
        # This is a convenience function. Axmud code is free to call $self->enableSingleScreen,
        #   ->enableSplitScreen or ->enableHiddenSplitScreen directly, if preferred
        #
        # Expected arguments
        #   $mode   - One of the recognised values for $self->splitScreenMode, i.e. 'single',
        #               'split' or 'hidden'
        #
        # Return values
        #   'undef' on improper arguments or on general failure
        #   If $mode is already the same value as $self->splitScreenMode, nothing happens and
        #       'undef' is returned
        #   If $mode is 'split' or 'hidden', and if $self->splitScreenMode is already 'split' or
        #       'hidden', returns 'undef' (as no Gtk3 widgets need to be repacked)
        #   If $mode is 'single' and $self->splitScreenMode is not 'single', or vice-versa, then
        #       returns a packable widget which should be packed into the space occupied by the
        #       previous packable widget

        my ($self, $mode, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $mode
            || ($mode ne 'single' && $mode ne 'split' && $mode ne 'hidden')
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->setSplitScreenMode', @_);
        }

        if ($mode eq $self->splitScreenMode) {

            # No changes required
            return undef;

        } elsif ($mode eq 'single') {

            return $self->enableSingleScreen();

        } elsif ($mode eq 'split') {

            return $self->enableSplitScreen();

        } elsif ($mode eq 'hidden') {

            return $self->enableHiddenSplitScreen();
        }
    }

    sub enableSingleScreen {

        # Called by $self->setSplitScreenMode (or directly by any code)
        # Sets $self->splitScreenMode to 'single'
        # If $self->splitScreenMode was 'split' or 'hidden', replaces the existing Gtk3::VPaned,
        #   containing two textviews, with a Gtk3::Frame containing a single textview, and returns
        #   the frame. The calling function should pack the frame into the space previously occupied
        #   by the vpaned
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if $self->splitScreenMode is already 'single'
        #   Otherwise, returns the Gtk3::Frame

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->enableSingleScreen');
        }

        if ($self->splitScreenMode eq 'single') {

            # Nothing needs to be re-packed
            return undef

        } else {

            # Set the new mode
            $self->ivPoke('splitScreenMode', 'single');

            # Create the new Gtk3::TextView, using the same Gtk3::TextBuffer as the original one
            my $textView = $self->createTextViewWidget($self->buffer);

            # Set the textview's CSS style
            $axmud::CLIENT->desktopObj->setTextViewObjStyle(
                $self->number,
                $self->textColour,
                $self->backgroundColour,
                $self->font,
                $self->fontSize,
                $textView,
            );

            # Pack the textview into a container widget
            my $scroll = $self->setupScroller($textView);

            # Update IVs again
            $self->ivPoke('textView', $textView);
            $self->ivUndef('textView2');
            $self->ivUndef('vPaned');
            $self->ivPoke('scroll', $scroll);
            $self->ivUndef('scroll2');

            # In case split screen mode has just been turned off, check that the textview's size
            #   hasn't change (as soon as possible)
            $self->ivPoke('sizeUpdateFlag', TRUE);

            # Operation complete
            return $scroll;
        }
    }

    sub enableSplitScreen {

        # Called by $self->setSplitScreenMode (or directly by any code)
        # Sets $self->splitScreenMode to 'split'
        # If $self->splitScreenMode was 'single', replaces the existing Gtk3::Frame, containing a
        #   single textview, with a Gtk3::VPaned, containing two textviews, and returns the vpaned.
        #   The calling function should pack the vpaned into the space previously occupied by the
        #   frame
        # If $self->splitScreenMode was 'hidden', moves the divider so that the hidden textview
        #   becomes visible (if the user manually moved the divider, this function moves the
        #   divider to its default position for this mode)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if $self->splitScreenMode is currently 'split' or
        #       'hidden'
        #   Otherwise, returns the Gtk3::VPaned

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->enableSplitScreen');
        }

        if ($self->splitScreenMode eq 'split') {

            # Nothing needs to be re-packed
            return undef

        } else {

            if ($self->splitScreenMode eq 'hidden') {

                # Set the new mode
                $self->ivPoke('splitScreenMode', 'split');

                # Move the divider and rescroll textviews to the bottom (for tidiest visual effect)
                $self->setDividerPosn($self->vPaned);
                $axmud::CLIENT->desktopObj->updateWidgets($self->_objClass . '->enableSplitScreen');
                $self->scrollToLock();

                # Nothing needs to be re-packed
                return undef

            } else {

                # Set the new mode
                $self->ivPoke('splitScreenMode', 'split');

                # Create the new Gtk3::TextView, using the same Gtk3::TextBuffer as the original one
                my $textView2 = $self->createTextViewWidget($self->buffer);

                # Update the textviews' CSS style
                $axmud::CLIENT->desktopObj->setTextViewObjStyle(
                    $self->number,
                    $self->textColour,
                    $self->backgroundColour,
                    $self->font,
                    $self->fontSize,
                    $self->textView,
                    $textView2,
                );

                # Pack the textviews into a container widget
                my ($vPaned, $scroll, $scroll2) = $self->setupVPaned($self->textView, $textView2);

                # Update IVs again
                $self->ivPoke('textView2', $textView2);
                $self->ivPoke('vPaned', $vPaned);
                $self->ivPoke('scroll', $scroll);
                $self->ivPoke('scroll2', $scroll2);

                # Operation complete
                return $vPaned;
            }
        }
    }

    sub enableHiddenSplitScreen {

        # Called by $self->setSplitScreenMode (or directly by any code)
        # Sets $self->splitScreenMode to 'hidden'
        # If $self->splitScreenMode was 'single', replaces the existing Gtk3::Frame, containing a
        #   single textview, with a Gtk3::VPaned, containing two textviews, and returns the vpaned.
        #   The calling function should pack the vpaned into the space previously occupied by the
        #   frame
        # If $self->splitScreenMode was 'split', moves the divider so that the second textview
        #   becomes hidden
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if $self->splitScreenMode is currently 'split' or
        #       'hidden'
        #   Otherwise, returns the Gtk3::VPaned

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->enableHiddenSplitScreen');
        }

        if ($self->splitScreenMode eq 'hidden') {

            # Nothing needs to be re-packed
            return undef

        } else {

            if ($self->splitScreenMode eq 'split') {

                # Set the new mode
                $self->ivPoke('splitScreenMode', 'hidden');

                # Move the divider and rescroll textviews to the bottom (for tidiest visual effect)
                $self->setDividerPosn($self->vPaned);
                $axmud::CLIENT->desktopObj->updateWidgets(
                    $self->_objClass . '->enableHiddenSplitScreen',
                );

                $self->scrollToLock();

                # In case split screen mode has just been turned off, check that the textview's size
                #   hasn't change (as soon as possible)
                $self->ivPoke('sizeUpdateFlag', TRUE);

                # Nothing needs to be re-packed
                return undef

            } else {

                # Set the new mode
                $self->ivPoke('splitScreenMode', 'hidden');

                # Create the new Gtk3::TextView, using the same Gtk3::TextBuffer as the original one
                my $textView2 = $self->createTextViewWidget($self->buffer);

                # Update the textviews' CSS style
                $axmud::CLIENT->desktopObj->setTextViewObjStyle(
                    $self->number,
                    $self->textColour,
                    $self->backgroundColour,
                    $self->font,
                    $self->fontSize,
                    $self->textView,
                    $textView2,
                );

                # Pack the textviews into a container widget
                my ($vPaned, $scroll, $scroll2) = $self->setupVPaned($self->textView, $textView2);

                # Update IVs again
                $self->ivPoke('textView2', $textView2);
                $self->ivPoke('vPaned', $vPaned);
                $self->ivPoke('scroll', $scroll);
                $self->ivPoke('scroll2', $scroll2);

                # Operation complete
                return $vPaned;
            }
        }
    }

    sub checkMousePosn {

        # Called by ->signal_connects in $self->setMotionNotifyEvent
        # When the mouse moves over a clickable link in a Gtk3::TextView, we should change the mouse
        #   cursor. When the mouse moves away from a clickable link, we should restore the mouse
        #   cursor
        #
        # NB This function isn't used for clickable images. ->signal_connects for that are found in
        #   $self->showImage
        #
        # Expected arguments
        #   $textView   - The Gtk3::TextView over which the mouse is moving
        #   $event      - The Gtk3::Gdk::Event
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $textView, $event, $check) = @_;

        # Local variables
        my (
            $xPos, $yPos, $iter, $lineNum, $posn, $hoverFlag, $listRef, $window, $listRef2,
            $linkObj, $tooltipsFlag, $tooltip,
        );

        # Check for improper arguments
        if (! defined $textView || ! defined $event || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->checkMousePosn', @_);
        }

        # Get the mouse's position over the textview's buffer
        ($xPos, $yPos) = $textView->window_to_buffer_coords('widget', $event->x, $event->y);
        # Get the buffer iter corresponding to that position
        $iter = $textView->get_iter_at_location($xPos, $yPos);
        # Get the offsets for the buffer line and character directly beneath the mouse
        $lineNum = $iter->get_line();
        $posn = $iter->get_visible_line_offset();

        # Get all the tags associated with this iter, looking for the Axmud style tag 'link'
        # (Setting this flag makes any debug messages we might insert work without errors)
        $hoverFlag = FALSE;
        $listRef = $iter->get_tags();
        if (defined $listRef) {

            OUTER: foreach my $tag (@$listRef) {

                if ($tag->get_property('name') eq 'link') {

                    $hoverFlag = TRUE;
                    last OUTER;
                }
            }
        }

        # Only change the cursor, if the mouse has moved from a link to normal space, or vice-versa;
        #   of if the mouse has moved from one link to another
        $window = $textView->get_window('text');
        if (! $hoverFlag && $self->currentLinkObj) {

            # Reset the cursor
            $self->ivUndef('currentLinkObj');
            $window->set_cursor($axmud::CLIENT->constNormalCursor);
            # Hide tooltips
            $self->hideTooltips();

        } elsif ($hoverFlag) {

            # Find the corresponding GA::Obj::Link
            $listRef = $self->ivShow('linkObjLineHash', $lineNum + $self->nextDeleteLine);
            if (defined $listRef) {

                OUTER: foreach my $thisLinkObj (@$listRef) {

                    my $endPosn = $thisLinkObj->posn + length ($thisLinkObj->text);

                    if ($posn >= $thisLinkObj->posn && $posn < $endPosn) {

                        # Found the corresponding GA::Obj::Link
                        $linkObj = $thisLinkObj;
                        last OUTER;
                    }
                }
            }

            if (! $linkObj) {

                # Mouse is not above a link (or error finding a link)
                $self->ivUndef('currentLinkObj');
                $window->set_cursor($axmud::CLIENT->constNormalCursor);
                # Hide tooltips
                $self->hideTooltips();

            } elsif (! $self->currentLinkObj || $self->currentLinkObj ne $linkObj) {

                # Mouse is above a new link
                if ($linkObj->expiredFlag) {

                    # It's an expired link
                    $self->ivUndef('currentLinkObj');
                    $window->set_cursor($axmud::CLIENT->constNormalCursor);
                    # Hide tooltips
                    $self->hideTooltips();

                } else {

                    # Not an expired link
                    $self->ivPoke('currentLinkObj', $linkObj);

                    if ($linkObj->type eq 'www') {

                        $window->set_cursor($axmud::CLIENT->constWWWCursor);

                    } elsif ($linkObj->type eq 'cmd') {

                        # (Check ->popupFlag first, because a popup menu can also redirect to a
                        #   prompt)
                        if ($linkObj->popupFlag) {
                            $window->set_cursor($axmud::CLIENT->constPopupCursor);
                        } elsif ($linkObj->mxpPromptFlag) {
                            $window->set_cursor($axmud::CLIENT->constPromptCursor);
                        } else {
                            $window->set_cursor($axmud::CLIENT->constCmdCursor);
                        }

                    } elsif ($linkObj->type eq 'mail') {

                        $window->set_cursor($axmud::CLIENT->constMailCursor);

                    } elsif (
                        $linkObj->type eq 'telnet'
                        || $linkObj->type eq 'ssh'
                        || $linkObj->type eq 'ssl'
                    ) {
                        $window->set_cursor($axmud::CLIENT->constTelnetCursor);

                    } elsif ($linkObj->type eq 'image') {

                        $axmud::CLIENT->writeDebug(
                            'Mouse above image link; examine code please',
                            $self->_objClass . '->checkMousePosn',
                        );

                    } elsif ($linkObj->type eq 'other') {

                        $window->set_cursor($axmud::CLIENT->constNormalCursor);
                    }

                    # If it's an MXP link with a hint, show the hint in the tooltip window
                    if ($linkObj->hint) {

                        # Unhide the tooltips window and display $linkObj's ->hint
                        $self->showLinkTooltips($linkObj);
                        $tooltipsFlag = TRUE;

                    } else {

                        # Hide the tooltips window
                        $self->hideTooltips();
                    }
                }
            }
        }

        # If there's no link tooltip visible, consider showing the session tooltip instead
        if ($axmud::CLIENT->mainWinTooltipFlag && ! $tooltipsFlag && ! $self->currentLinkObj) {

            # Only lines created by the GA::Session, and displayed in its default textview object,
            #   cause key-value pairs to be added to this hash
            # NB The Gtk3::Textbuffer renumbers its line every time we delete one from the
            #   beginning of the buffer, so here we must add $self->nextDeleteLine
            if ($self->ivExists('tooltipHash', ($lineNum + $self->nextDeleteLine))) {

                $self->showSessionTooltips($lineNum + $self->nextDeleteLine);

            } elsif ($self->lastTooltipLine) {

                $self->hideTooltips();
            }
        }

        return 1;
    }

    sub updateVisibleSize {

        # Called by Games::Axmud::Obj::Desktop->updateWidgets (only) for any textview object whose
        #   ->sizeUpdateFlag is set
        # Updates IVs and informs the GA::Session
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($charWidth, $charHeight, $hashRef, $textViewWidth, $textViewHeight);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateVisibleSize', @_);
        }

        # Do nothing while split screen mode is on
        if ($self->splitScreenMode ne 'split') {

            # Get the width/height of a character in the Gtk3::TextView
            ($charWidth, $charHeight) = $self->getCharSize();
            # Get a Gtk3::Gdk::Rectangle
            $hashRef = $self->textView->get_visible_rect();
            # Get the size of the textview
            $textViewWidth = int($$hashRef{width} / $charWidth);
            $textViewHeight = int($$hashRef{height} / $charHeight);

            if (
                ! defined $self->textWidthChars
                || $textViewWidth != $self->textWidthChars
                || $textViewHeight != $self->textHeightChars
            ) {
                # The size has changed. Update IVs...
                $self->ivPoke('textWidthChars', $textViewWidth);
                $self->ivPoke('textHeightChars', $textViewHeight);
                # ...and inform the parent GA::Session
                $self->session->textViewSizeUpdate($self);
            }
        }

        $self->ivPoke('sizeUpdateFlag', FALSE);

        return 1;
    }

    sub getCharSize {

        # Called by $self->updateVisibleSize
        # Gets the size (in pixels) of a single character in the Gtk3::TextView
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $char       - The character whose size should be found. If 'undef', the character 'w'
        #                   is tested
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list in the form (width_pixels, height_pixels)

        my ($self, $char, $check) = @_;

        # Local variables
        my (
            $layout, $inkRect, $logicalRect,
            @emptyList,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getCharSize', @_);
            return @emptyList;
        }

        if (! $char) {

            $char = 'w';
        }

        # Get the Pango::Layout representing the character in this session's textview
        $layout = $self->textView->create_pango_layout($char);

        # Get the width/height of the character
        ($inkRect, $logicalRect) = $layout->get_pixel_extents();

        return ($$logicalRect{'width'}, $$logicalRect{'height'});
    }

    sub getLineLength {

        # For reasons unknown, calls to Gtk3::TextIter->get_chars_in_line returns the actual number
        #   of characters in a line, plus 10,000
        # Return the number of characters in a line, subtracting 10,000 if necessary
        #
        # Expected arguments
        #   $iter   - A Gtk3::TextIter anywhere on the line
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the (real) number of characters on the line

        my ($self, $iter, $check) = @_;

        # Local variables
        my $count;

        # Check for improper arguments
        if (! defined $iter || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->getLineLength', @_);
        }

        $count = $iter->get_chars_in_line();
        if ($count >= 10000) {

            $count -= 10000;
        }

        return $count;
    }

    sub setupLink {

        # Called by $self->insertText and ->showSystemText
        # Just before a clickable link is displayed in the textview, creates a GA::Obj::Link (or
        #   amends an existing one) to store data until the user clicks on the link
        #
        # Expected arguments
        #   $iter       - The Gtk3::TextIter marking the position in the Gtk3::TextBuffer
        #                   (stored in $self->buffer) at which the link will be displayed
        #   $text       - The text of the link itself
        #
        # Return values
        #   'undef' on improper arguments or if the link can't be created/amended
        #   1 otherwise

        my ($self, $iter, $text, $check) = @_;

        # Local variables
        my ($lineNum, $posn, $short, $email, $type, $listRef, $objNum, $linkObj);

        # Check for improper arguments
        if (! defined $iter || ! defined $text || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setupLink', @_);
        }

        # Get the position of the start of the link. If the buffer is full, take account of any
        #   lines that have been deleted from the start of it
        $lineNum = $iter->get_line() + $self->nextDeleteLine;
        $posn = $iter->get_line_offset();

        # Check $text to see if it matches the start of an acceptable link, in the form
        #   http://deathmud.org         - a URL opened by GA::Client->browserCmd
        #   deathmud.org                - a URL opened by GA::Client->browserCmd
        #   mailto:god@deathmud.org     - an email sent by GA::Client->emailCmd
        #   admin@deathmud.org          - an email sent by GA::Client->emailCmd
        #   telnet://deathmud.org:6666  - a new connection to a world, using telnet
        #   telnet://deathmud.org       - a new connection to a world, port 23
        #   ssh://deathmud.org:6666     - a new connection to a world, using SSH
        #   ssh://deathmud.org          - a new connection to a world, generic port
        #   ssl://deathmud.org:6666     - a new connection to a world, using SSL
        #   ssl://deathmud.org          - a new connection to a world, generic port
        # NB We don't check against GA::Client->constUrlRegex, etc, because $text might not contain
        #   the whole link, but we do check against GA::Client->constShortUrlRegex and against an
        #   email link without the mailto: part, in the hope that it was probably displayed by a
        #   single call to $self->insertText, etc
        # NB This function isn't used for MXP links, for which a GA::Obj::Link has already been
        #   created
        $short = '^' . $axmud::CLIENT->constShortUrlRegex;
        $email = '^' . $axmud::CLIENT->constEmailRegex;

        # (Check email first, otherwise gmail.com is detected and fred@gmail.com isn't)
        if ($text =~ m/^mailto\:/i || $text =~ m/$email/i) {

            $type = 'mail';

        } elsif (
            $text =~ m/^https?\:\/\//i
            || ($axmud::CLIENT->shortUrlFlag && $text =~ m/$short/i)
        ) {
            $type = 'www';

        } elsif ($text =~ m/^telnet\:\/\//i) {

            $type = 'telnet';

        } elsif ($text =~ m/^ssh\:\/\//i) {

            $type = 'ssh';

        } elsif ($text =~ m/^ssl\:\/\//i) {

            $type = 'ssl';

        } else {

            # This shouldn't happen
            $type = 'other';
        }

        # A single link may be created by one or more successive calls to $self->insertText (etc).
        #   If $text isn't the start of a link, we will be looking to add it to the end of an
        #   existing link
        # This textview object stores its own list of GA::Obj::Link objects which apply to the
        #   current insertion point; a hash in the form
        #       ->linkObjLineHash{line} = reference_to_list_of_GA::Obj::Link_objects
        $listRef = $self->ivShow('linkObjLineHash', $lineNum);

        if (defined $listRef) {

            # Check each GA::Obj::Link object in turn. If there's one which ends at $posn, we'll
            #   need to check if $text is part of the same link, or the start of a new link
            # (Don't need to check MXP links, which are always created whole)
            OUTER: foreach my $obj (@$listRef) {

                my $endPosn = $obj->posn + length ($obj->text);
                if (! $obj->mxpFlag && $endPosn == $posn) {

                    # $text is almost certainly part of the previous link
                    $linkObj = $obj;
                    # (->href and ->text are the same for non-MXP links)
                    $linkObj->ivPoke('href', $obj->href . $text);
                    $linkObj->ivPoke('text', $obj->text . $text);
                    last OUTER;
                }
            }
        }

        if (! $linkObj) {

            # Create a new GA::Obj::Link object
            $linkObj = $self->add_link($lineNum, $posn, $type);
            if (! $linkObj) {

                return undef;
            }

            # (For non-MXP links, ->href and ->text are the same)
            $linkObj->ivPoke('href', $text);
            $linkObj->ivPoke('text', $text);
        }

        return 1;
    }

    sub createMxpStackObj {

        # Called by GA::Session->processMxpModalElement
        # Creates an mxp stack object (GA::Mxp::StackObj) and adds it to this textview's stack
        #
        # Expected arguments
        #   $session        - The calling GA::Session
        #   $keyword        - The MXP element keyword (already converted to upper case)
        #
        # Optional arguments
        #   %stackHash      - A hash of key-value pairs which updates $self->mxpModalStackHash by
        #                       replacing one or more of its key-value pairs (might be an empty
        #                       hash)
        #
        # Return values
        #   'undef' on improper arguments or if the stack object can't be created
        #   Blessed reference to the newly-created object on success

        my ($self, $session, $keyword, %stackHash) = @_;

        # Local variables
        my $stackObj;

        # Check for improper arguments
        if (! defined $session || ! defined $keyword) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createMxpStackObj', @_);
        }

        # Create a new MXP stack object which preserves current MXP text attributes, just before we
        #   update $self->mxpModalStackHash
        $stackObj = Games::Axmud::Mxp::StackObj->new($session, $keyword, $self->mxpModalStackHash);
        if (! $stackObj ) {

            return undef;
        }

        # Update IVs
        $self->ivPush('mxpModalStackList', $stackObj);

        # Apply the new text attributes specified by %stackHash
        foreach my $key (keys %stackHash) {

            $self->ivAdd('mxpModalStackHash', $key, $stackHash{$key});
        }

        return $stackObj;
    }

    sub interpretTags {

        # Called by $self->insertText and ->showSystemText
        # Interprets a list of arguments passed to those functions, including Axmud colour and style
        #   tags and some additional strings for implementing newline characters and clearing the
        #   buffer
        # For RGB colour tags (e.g. '#FFFFFF' and 'u#FFFFFF'), a new Gtk3::TextTag is created, if
        #   one does not already exist
        # Duplicate arguments are ignored. Only the first text colour tag (if any) is used, and only
        #   the first underlay colour tag (if any) is used. Unrecognised tags are ignored
        #
        # Expected arguments
        #   $newLineDefault - The default behaviour for newline characters, if no behaviour is
        #                       specified in @args: 'before' prepends a newline character to the
        #                       text, 'after'/'nl' appends a newline character to the text, 'echo'
        #                       does not prepend/append a newline character at all
        #
        # Optional arguments
        #   @args       - The list of arguments to interpret, in any order:
        #                   - 'empty' (empties the buffer before writing text)
        #                   - 'before' (prepends a newline character to the text)
        #                   - 'after' or 'nl' (appends a newline character to $text)
        #                   - 'echo' (does not prepend/append a newline character, overrides
        #                       'before', 'after' and 'nl' if they are specified)
        #                   - one or more Axmud colour tags. Only the first text colour (e.g. 'red')
        #                       is used, and only the first underlay colour ('UL_RED') is used.
        #                       The range of Axmud colour tags include:
        #                       - standard colour tags like 'red', 'BLUE', 'ul_red', 'UL_BLUE'
        #                           (case-sensititive)
        #                       - xterm colour tags (strings in the range 'x0' to 'x255', or
        #                           'ux0' to 'ux255'; case-insensitive, so 'X0' is valid)
        #                       - RGB colour tags (strings in the range '#000000' to '#FFFFFF', or
        #                           'u#000000' to 'u#FFFFFF'; case-insensitive, so 'U#AbCdEf' is
        #                           valid)
        #                   - one or more Axmud style tags ('italics', 'strike', 'link' etc)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list in the form
        #       (
        #           $emptyFlag, $beforeFlag, $afterFlag, $linkFlag, $textColour, $underlayColour,
        #           @styleTags,
        #       )
        #   ...where the flags are set to TRUE or FALSE, $textColour is set to the first text
        #       colour tag found (or 'undef' if none are found), $underlayColour is set to the
        #       first underlay colour tag found (or 'undef' if none are found), and @styleTags
        #       contains a list of Axmud style tags (an empty list if none are found)
        #   NB If the 'link' style tag appears in @args, then $linkFlag will be TRUE, and the style
        #       tag will also appear in @styleTags

        my ($self, $newLineDefault, @args) = @_;

        # Local variables
        my (
            $emptyFlag, $beforeFlag, $afterFlag, $echoFlag, $linkFlag, $textColour, $underlayColour,
            $mxpfFlag, $relatedFlag,
            @styleTags,
            %styleHash,
        );

        # Check for improper arguments
        if (! defined $newLineDefault) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->interpretTags', @_);
        }

        # The flags are FALSE by default ($newLineDefault is applied at the end, if necessary)
        $emptyFlag = FALSE;
        $beforeFlag = FALSE;
        $afterFlag = FALSE;
        $echoFlag = FALSE;
        $linkFlag = FALSE;

        foreach my $item (@args) {

            my (
                $first, $second, $fontString, $spacing, $tag, $type, $underlayFlag,
                @wordList,
            );

            $first = lc(substr($item, 0, 1));
            $second = lc(substr($item, 0, 2));

            if ($item eq 'empty') {

                $emptyFlag = TRUE;
                $relatedFlag = TRUE;

            } elsif ($item eq 'before') {

                $beforeFlag = TRUE;
                $relatedFlag = TRUE;

            } elsif ($item eq 'after' || $item eq 'nl') {

                $afterFlag = TRUE;
                $relatedFlag = TRUE;

            } elsif ($item eq 'echo') {

                $echoFlag = TRUE;
                $relatedFlag = TRUE;

            } elsif ($axmud::CLIENT->ivExists('constStyleTagHash', $item)) {

                # It's an Axmud style tag (not including dummy style tags). Ignore duplicate style
                #   tags
                if (! exists $styleHash{$item}) {

                    push (@styleTags, $item);
                    $styleHash{$item} = undef;

                    if ($item eq 'link' && $self->allowLinkFlag) {

                        # (As well as adding the tag to @styleTags, set a flag; this saves a bit of
                        #   time for the calling function)
                        $linkFlag = TRUE;
                    }
                }

            } elsif (substr($item, 0, 5) eq 'mxpf_') {

                # It's a dummy style tag in the form 'mxpf_monospace_bold_12_p5', containing one or
                #   more of the following, separated by underlines: the font name (e.g.
                #   'monospace'), a font name modifier (e.g. 'bold'), the font size (e.g. '12') and
                #   the pixel spacing above and below the text (used for MXP HTML headings, e.g.
                #   'p5'; when not specified, a spacing of 0 is used)
                # Ignore duplicate 'mxpf_' tags
                if (! $mxpfFlag) {

                    # If a Gtk3::TextTag for this exact combination of fonts and font sizes doesn't
                    #   exist, create a new one
                    if (! $self->buffer->get_tag_table->lookup($item)) {

                        # Remove the 'mxpf' and replace underlines with whitespace, getting
                        #   something like 'monospace bold 12 p5'
                        $fontString = substr($item, 5);
                        $fontString =~ s/\_/ /g;

                        # The default pixel spacing is 0 (only MXP HTML headings need more)
                        $spacing = 0;
                        # Remove the pixel spacing component, if it was specified. Use only the
                        #   first one; ignore any subsequent ones
                        foreach my $word (split(/\s+/, $fontString)) {

                            if ($word =~ m/^p(\d+)$/) {

                                # (Ignore subsequent spacings)
                                if (! $spacing) {

                                    $spacing = $1;
                                }

                            } else {

                                push (@wordList, $word);
                            }
                        }

                        $fontString = join(' ', @wordList);

                        $self->buffer->create_tag(
                            $item,                                   # e.g. 'mxpf_monospace_bold_12'
                            'font'                  => $fontString,  # e.g. 'monospace bold 12'
                            'pixels-above-lines'    => $spacing,     # e.g. 5
                            'pixels-below-lines'    => $spacing,     # e.g. 5
                        );
                    }

                    push (@styleTags, $item);
                    $mxpfFlag = TRUE;
                }

            } elsif ($second eq 'ux') {

                # It's an xterm colour tag for the underlay. Check that it's valid before using it
                #   (and ignore an additional underlay colour, if one has already been specified)
                if (! $underlayColour) {

                    $tag = substr($item, 1);        # Strip away the initial 'u'
                    if ($axmud::CLIENT->ivExists('xTermColourHash', lc($tag))) {

                        # (xterm colour tags are lower-case, by default)
                        $underlayColour = lc($item);
                    }
                }

            } elsif ($first eq 'x') {

                # It's an xterm colour tag for text. Check that it's valid before using it
                #   (and ignore an additional text colour, if one has already been specified)
                if (! $textColour && $axmud::CLIENT->ivExists('xTermColourHash', lc($item))) {

                    # (xterm colour tags are lower-case, by default)
                    $textColour = lc($item);
                }

            } elsif ($second eq 'u#') {

                # It's an RGB colour tag for the underlay
                if (! $underlayColour) {

                    $tag = substr($item, 1);                    # Strip away the initial 'u'
                    if ($tag =~ m/^\#[A-Fa-f0-9]{6}$/) {

                        # (Gtk3 expects an upper-case string like '#FFFFFF')
                        $underlayColour = 'u' . uc($tag);
                        # There are 16.7 million possible RGB colour tags, so we take the pragmatic
                        #   approach and create a Gtk3::TextTag for each one, only when it is needed
                        if (! $self->buffer->get_tag_table->lookup($underlayColour)) {

                            $self->buffer->create_tag(
                                $underlayColour,                # e.g. 'u#FFFFFF'
                                'background' => uc($tag),       # e.g. '#FFFFFF'
                            );
                        }
                    }
                }

            } elsif ($first eq '#') {

                # It's an RGB colour tag for text
                if (! $textColour && $item =~ m/^\#[A-Fa-f0-9]{6}$/) {

                    # (Gtk3 expects an upper-case string like '#FFFFFF')
                    $textColour = uc($item);
                    # There are 16.7 million possible RGB colour tags, so we take the pragmatic
                    #   approach and create a Gtk3::TextTag for each one, only when it is needed
                    if (! $self->buffer->get_tag_table->lookup($textColour)) {

                        $self->buffer->create_tag(
                            $textColour,                        # e.g. '#FFFFFF'
                            'foreground' => $textColour,        # e.g. '#FFFFFF'
                        );
                    }
                }

            } else {

                # It's presumably an Axmud colour tag
                ($type, $underlayFlag) = $axmud::CLIENT->checkColourTags($item, 'standard');
                if ($type) {

                    # (Only use the first underlay colour tag)
                    if ($underlayFlag && ! $underlayColour) {

                        $underlayColour = $item;

                    } elsif (! $underlayFlag && ! $textColour) {

                        $textColour = $item;
                    }
                }
            }
        }

        # 'echo' overrides 'before', 'after' and 'nl', it specified
        if ($echoFlag) {

            $beforeFlag = FALSE;
            $afterFlag = FALSE;
        }

        # If none of 'before', 'after' and 'echo' were specified, use the default behaviour
        if (! $relatedFlag) {

            if ($newLineDefault eq 'echo') {
                $echoFlag = TRUE;
            } elsif ($newLineDefault eq 'before') {
                $beforeFlag = TRUE;
            } elsif ($newLineDefault eq 'after' || $newLineDefault eq 'nl') {
                $afterFlag = TRUE;
            }
        }

        return (
            $emptyFlag, $beforeFlag, $afterFlag, $linkFlag, $textColour, $underlayColour,
            @styleTags,
        );
    }

    sub modifyColourTags {

        # Called by $self->insertText after an earlier call to $self->interpretTags
        # Imports the colour scheme in use, then applies any colour overrides specified by that
        #   colour scheme or by this object's own monochrome mode
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $textColour     - The text colour tag that's going to be inserted into the
        #                       Gtk3::TextView (or 'undef' if no colour tag is going to be used)
        #   $underlayColour - The underlay colour tag that's going to be inserted into the
        #                       Gtk3::TextView (or 'undef' if no colour tag is going to be used)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns a list in the form
        #       (monochrome_flag, text_colour, underlay_colour)
        #   ...where 'text_colour' and 'underlay_colour' are the modified (or unmodified) values,
        #       and 'monochrome_flag' is TRUE is no colours can be used at all, FALSE otherwise

        my ($self, $textColour, $underlayColour, $check) = @_;

        # Local variables
        my (
            $colourSchemeObj, $monochromeFlag,
            @emptyList,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->insertWithTags', @_);
            return @emptyList;
        }

        # Import the colour scheme in use
        $colourSchemeObj = $axmud::CLIENT->ivShow('colourSchemeHash', $self->colourScheme);
        # Apply any colour overrides specified by the colour scheme or by this object's own
        #   monochrome mode
        if ($self->monochromeFlag || ($colourSchemeObj && $colourSchemeObj->overrideAllFlag)) {

            $monochromeFlag = TRUE;

        } else {

            $monochromeFlag = FALSE;

            if ($colourSchemeObj) {

                if (
                    defined $textColour
                    && $colourSchemeObj->ivExists('overrideHash', $textColour)
                ) {
                    $textColour = $colourSchemeObj->ivShow('overrideHash', $textColour);
                }

                if (
                    defined $underlayColour
                    && $colourSchemeObj->ivExists('overrideHash', $underlayColour)
                ) {
                    $underlayColour = $colourSchemeObj->ivShow('overrideHash', $underlayColour);
                }
            }
        }

        return ($monochromeFlag, $textColour, $underlayColour);
    }

    sub insertWithTags {

        # Called by $self->insertText, ->insertCmd, ->showSystemText, ->showError, ->showWarning,
        #   ->showDebug, ->showImproper and ->showImage
        # Inserts some text and (optionally) colour and style tags into the Gtk3::TextBuffer
        #
        # Expected arguments
        #   $iter       - The Gtk3::TextIter, representing the point in the buffer at which the text
        #                   is inserted
        #   $text       - A string consisting of 0, 1 or more characters which aren't newline
        #                   characters
        #
        # Optional arguments
        #   @tags       - A list of Axmud colour/style tags that apply to the whole of $text, but
        #                   not necessarily any text that was inserted before it (or will be
        #                   inserted after it). Can be an empty list
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the Gtk3::TextIter immediately after the inserted text (which might be
        #       the end of the textbuffer, or not)

        my ($self, $iter, $text, @tags) = @_;

        # Local variables
        my ($lineNum, $posn, $endIter, $length, $stopPosn, $stopIter, $newIter, $newLength);

        # Check for improper arguments
        if (! defined $iter || ! defined $text) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->insertWithTags', @_);
        }

        # Get the iter's position in the textview buffer
        $lineNum = $iter->get_line();
        $posn = $iter->get_visible_line_offset();

        # Strip any newline characters ($text shouldn't contain any, but we'll check anyway)
        # Also strip any null chars (in the text length calculations below, they have a length of
        #   both 0 and 1, which causes an Axmud crash)
        $text =~ s/[\n\r\x00]//;

#        # Insert the text and tags into the Gtk3::TextBuffer
#        $self->buffer->insert_with_tags_by_name($iter, $text, @tags);
        # Gtk overwrite mode doesn't work (for some reason), so we're forced to implement our own
        #   overwrite mode by deleting existing text before inserting new text
        $endIter = $self->buffer->get_end_iter();
        if ($self->overwriteFlag && $iter ne $endIter) {

            my ($length, $stopPosn, $stopIter);

            $length = $self->getLineLength($iter);
            $stopPosn = $posn + length($text);
            if ($endIter->get_line() == $iter->get_line()) {

                if ($stopPosn > $length) {

                    $stopPosn = $length;
                }

            } else {

                if (! $length) {

                    $stopPosn = $length;

                } elsif ($stopPosn >= $length) {

                    $stopPosn = $length - 1;
                }
            }

            $stopIter = $self->buffer->get_iter_at_line_offset($lineNum, $stopPosn);
            if ($stopIter ne $endIter) {

                $self->buffer->delete($iter, $stopIter);
            }
        }

        $self->buffer->insert_with_tags_by_name($iter, $text, @tags);

        # Get the iter after immediately after the inserted text. Gtk, for some reason, crashes if
        #   we try to get an iter outside the buffer, and some worlds (e.g. Kallisti) can cause
        #   such a crash, so we have to do a sanity check
        $posn += length ($text);
        $newLength = $self->getLineLength($iter);

        if ($posn > $newLength) {

            $posn = $newLength;
        }

        $newIter = $self->buffer->get_iter_at_line_offset($lineNum, $posn);

        # $self->insertNewLineFlag is set on every call to this function
        $self->ivPoke('insertNewLineFlag', FALSE);
        # $self->newLineFlag must be set if the buffer now ends with a newline character
        $endIter = $self->buffer->get_end_iter();

        # Confusingly, $newIter and $endIter are not the same, even if they both point at the same
        #   position in the buffer
        if (
            $newIter->get_line() eq $endIter->get_line()
            && $newIter->get_visible_line_offset eq $endIter->get_visible_line_offset()
        ) {
            $self->ivPoke('newLineFlag', FALSE);
            # Let's return $endIter rather than $newIter...
            $newIter = $endIter;
        }

        # Update IVs
        if ($text ne '') {

            $self->ivPoke('bufferTextFlag', TRUE);
            $self->ivPoke('sizeUpdateFlag', TRUE);
        }

        return $newIter;
    }

    sub insertNewLine {

        # Called by $self->insertText, ->insertMultipleText, ->insertCmd, ->showSystemText,
        #   ->showError, ->showWarning, ->showDebug, ->showImproper and ->showImage
        # Also called by $self->setInsertPosn to add empty lines, if they don't already exist
        # Inserts a newline character into the Gtk3::TextBuffer and updates IVs
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $iter   - The Gtk3::TextIter, representing the point in the buffer at which the newline
        #               character is inserted. If 'undef', the newline character is inserted at the
        #               end of the buffer
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the Gtk3::TextIter immediately after the inserted newline character
        #       (which might be the end of the textbuffer, or not)

        my ($self, $iter, $check) = @_;

        # Local variables
        my ($lineNum, $posn, $endIter, $forceFlag);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->insertNewLine', @_);
        }

        if (! defined $iter) {

            $iter = $self->buffer->get_end_iter();
        }

        # Get the iter's position in the textview buffer
        $lineNum = $iter->get_line();
        $posn = $iter->get_visible_line_offset();
        $endIter = $self->buffer->get_end_iter();

        if ($endIter->get_line() == $lineNum) {

            # We're on the buffer's last line
            if ($self->getLineLength($endIter) == $posn) {

                # We're at the end of the buffer, so insert a newline character as normal
                $self->buffer->insert($iter, "\n");
                $self->ivPoke('newLineFlag', TRUE);

                # Create a mark after this newline character, so the next line (which currently
                #   contains no characters at all) can be deleted when the buffer exceeds its
                #   maximum number of lines
                # (Lines aren't deleted in overwrite mode, so don't bother creating the marks)
                if (! $self->overwriteFlag) {

                    $self->buffer->create_mark(
                        'line_' . ($lineNum + 1 + $self->nextDeleteLine),
                        $self->buffer->get_end_iter(),
                        TRUE,
                    );

                    # If the buffer has exceeded its maximum number of lines, delete the oldest
                    #   remaining line
                    if ($self->maxLines && $lineNum >= $self->maxLines) {

                        $self->removeOldLine();
                    }
                }

            } else {

                # We're somewhere on the buffer's last line, but not at the end
                # Add a newline character to the end of the buffer, then move the insertion position
                #   to the beginning of the next line
                $self->buffer->insert($endIter, "\n");
                $self->setInsertPosn(($lineNum + 1), 0);
            }

        } else {

            # We're somewhere on a line, but not the buffer's last line
            # This line already ends with a newline character, so just move the insertion position
            #   to the beginning of the next line
            $self->setInsertPosn(($lineNum + 1), 0);
            # If a scrolling region scrolls, we're forced to add newline character(s) anyway
            $forceFlag = TRUE;
        }

        # $self->insertNewLineFlag is set on every call to this function (unless
        #   $self->tempInsertMark is set, in which case this newline follows a system message, and
        #   the actual insertion point is on some earlier line, in which case, we retain the current
        #   value of $self->insertNewLineFlag)
        if (! $self->tempInsertMark) {

            $self->ivPoke('insertNewLineFlag', TRUE);
        }

        # This flag is TRUE even if the buffer contains only a newline character
        $self->ivPoke('bufferTextFlag', TRUE);
        $self->ivPoke('sizeUpdateFlag', TRUE);

        if (defined $self->scrlRegionBottom && $self->scrlRegionBottom eq $lineNum) {

            # If a scroll region is defined, and if this function was called when the insertion
            #   position was on the line at the bottom of that region, then scroll all the lines in
            #   the region up by one (by deleting the first line in the region)
            $self->scrlRegionUp(1, $forceFlag);

            return $self->buffer->get_iter_at_line_offset($lineNum, 0);

        } else {

            # Just return the Gtk3::TextIter at the new insertion position
            return $self->buffer->get_iter_at_line_offset(($lineNum + 1), 0);
        }
    }

    sub removeOldLine {

        # Called by $self->insertNewLine
        # When the Gtk3::TextBuffer is full (i.e. the number of lines in the buffer exceeds the
        #   maximum), remove the oldest line
        # Also check $self->insertMark, etc, just in case they no longer exist (and update them, if
        #   so)
        # Never called in overwrite mode (i.e. when $self->overwriteFlag is TRUE)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($number, $startIter, $stopIter, $listRef, $ordinaryLineNum);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeOldLine', @_);
        }

        # v1.2.0 - because of Gtk3 performance issues, we no longer delete one line at a time,
        #   therefore keeping a constant number of lines in the buffer (once full)
        # Instead, we delete 100 lines at a time (or fewer, if the maximum textview size is small)
        if ($self->maxLines >= 1000) {

            $number = 100;

        } else {

            $number = int($self->maxLines / 10);
            if (! $number) {

                $number = 1;
            }
        }

        $startIter = $self->buffer->get_start_iter();
        $stopIter = $self->buffer->get_iter_at_line_offset($number, 0);
        if ($startIter && $stopIter) {

            # Perform the deletion operation
            $self->buffer->delete($startIter, $stopIter);

            for (my $count = 0; $count < $number; $count++) {

                # Remove any link objects for links on the deleted line(s)
                $listRef = $self->ivShow('linkObjLineHash', $self->nextDeleteLine);
                if (defined $listRef) {

                    foreach my $linkObj (@$listRef) {

                        $self->ivDelete('linkObjHash', $linkObj->number);
                    }

                    $self->ivDelete('linkObjLineHash', $self->nextDeleteLine);
                }

                # No need to display a tooltip for this line every again
                $self->ivDelete('tooltipHash', $self->nextDeleteLine);
            }

            # Do the IVs $self->insertMark, etc refer to a position on these line(s)? If so, they
            #   must be reset
            if ($self->insertMark && ! $self->insertMark->get_buffer()) {

                $self->ivPoke('insertMark', undef);
                $self->ivPoke('insertNewLineFlag', FALSE);
            }

            if ($self->restoreInsertMark && ! $self->restoreInsertMark->get_buffer()) {

                $self->ivPoke('restoreInsertMark', undef);
            }

            if ($self->tempInsertMark && ! $self->tempInsertMark->get_buffer()) {

                $self->ivPoke('tempInsertMark', undef);
            }

            if ($self->systemInsertMark && ! $self->systemInsertMark->get_buffer()) {

                $self->ivPoke('systemInsertMark', undef);
            }

            $self->ivIncrement('nextDeleteLine');
        }

        return 1;
    }

    sub enableOverwrite {

        # Mostly called by functions in this textview object, but can (in theory) be called by
        #   anything
        # Enables overwrite mode
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->enableOverwrite', @_);
        }

        $self->ivPoke('overwriteFlag', TRUE);

        $self->textView->set_overwrite(TRUE);
        if ($self->textView2) {

            $self->textView2->set_overwrite(TRUE);
        }

        return 1;
    }

    sub disableOverwrite {

        # Should only be called by GA::Session->doDisconnect or ->reactDisconnect when a (real)
        #   connection terminates, and when this is the session's default textview
        # Turns off overwrite mode (if on), and moves the insertion point to the end of
        #   $self->buffer
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->disableOverwrite', @_);
        }

        if ($self->overwriteFlag) {

            $self->ivPoke('overwriteFlag', FALSE);
            $self->ivUndef('insertMark');
            $self->ivUndef('restoreInsertMark');
            $self->ivUndef('tempInsertMark');
            $self->ivUndef('systemInsertMark');
            $self->ivUndef('scrlRegionTop');
            $self->ivUndef('scrlRegionBottom');

            if ($self->bufferTextFlag && ! $self->newLineFlag) {

                $self->insertNewLine($self->buffer->get_end_iter());
            }
        }

        return 1;
    }

    ##################
    # Accessors - set

    sub set_allowLinkFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_allowLinkFlag', @_);
        }

        if ($flag) {
            $self->ivPoke('allowLinkFlag', TRUE);
        } else {
            $self->ivPoke('allowLinkFlag', FALSE);
        }

        return 1;
    }

    sub set_clearAfterInsert {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_clearAfterInsert', @_);
        }

        $self->ivPoke('clearAfterInsertFlag', TRUE);

        return 1;
    }

    sub set_colourStyleHash {

        # Called by GA::Session->processLineSegment

        my ($self, %hash) = @_;

        # (No improper arguments to check)

        $self->ivPoke('colourStyleHash', %hash);

        return 1;
    }

    sub set_cursorEnableFlag {

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_cursorEnableFlag', @_);
        }

        if ($flag) {

            $self->ivPoke('cursorEnableFlag', TRUE);

            $self->moveCursor();

        } else {

            if ($self->cursorEnableFlag) {

                $self->removeCursor();
            }

            $self->ivPoke('cursorEnableFlag', FALSE);
        }

        return 1;
    }

    sub add_incompleteLink {

        # Called by various MXP functions in GA::Session to convert an incomplete link (one in
        #   which the link hasn't actually been applied to the Gtk3::TextView yet) into a complete
        #   one, stored in IVs in this textview object

        my ($self, $linkObj, $check) = @_;

        # Local variables
        my (
            $listRef, $modLineNum, $beginIter, $length, $endIter, $lastLineFlag, $startPosn,
            $startIter, $stopPosn, $stopIter,
        );

        # Check for improper arguments
        if (! defined $linkObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_incompleteLink', @_);
        }

        if ($linkObj->number != -1) {

            # Not an incomplete link object
            return undef;
        }

        # Update IVs
        $linkObj->ivPoke('number', $self->linkObjCount);

        $self->ivAdd('linkObjHash', $linkObj->number, $linkObj);

        if (! $self->ivExists('linkObjLineHash', $linkObj->lineNum)) {

            $self->ivAdd('linkObjLineHash', $linkObj->lineNum, []);
        }

        $listRef = $self->ivShow('linkObjLineHash', $linkObj->lineNum);
        push (@$listRef, $linkObj);
        $self->ivAdd('linkObjLineHash', $linkObj->lineNum, $listRef);

        $self->ivIncrement('linkObjCount');

        # The link object stores a line number which corresponds to the total number of lines
        #   displayed; if the buffer is full, take account of any lines that have been deleted
        $modLineNum = $linkObj->lineNum - $self->nextDeleteLine;

        # This function has historically been the cause of sudden crashes when $stopIter or even
        #   $startIter have been outside the length of the line, so we need to check both of them
        $beginIter = $self->buffer->get_iter_at_line_offset($modLineNum, 0);
        $length = $self->getLineLength($beginIter);
        $endIter = $self->buffer->get_end_iter();

        if ($endIter->get_line() == $beginIter->get_line()) {

            $lastLineFlag = TRUE;
        }

        # If the link starts beyond the end of the line (an unlikely but actually observed error),
        #   don't display a clickable link at all
        $startPosn = $linkObj->posn;
        if (
            ($lastLineFlag && $startPosn > $length)
            || (! $lastLineFlag && $startPosn > ($length - 1))
        ) {
            return undef;

        } else {

            $startIter = $self->buffer->get_iter_at_line_offset($modLineNum, $startPosn);
        }

        # If the link ends beyond the end of the line, move the end of the link to the end of the
        #   line so a clickable link can be displayed
        $stopPosn = $linkObj->posn + length ($linkObj->text);
        if ($endIter->get_line() == $startIter->get_line() && $stopPosn > $length) {
            $stopPosn = $length;
        } elsif ($endIter->get_line() != $startIter->get_line() && $stopPosn > ($length - 1)) {
            $stopPosn = $length - 1;
        }

        $stopIter = $self->buffer->get_iter_at_line_offset($modLineNum, $stopPosn);

        # Add Axmud 'link' and 'link_off' tags at the appropriate places
        if ($startIter && $stopIter) {

            $self->buffer->apply_tag_by_name('link', $startIter, $stopIter);
            return 1;

        } else {

            return undef;
        }
    }

    sub add_link {

        # Called by $self->setupLink

        my ($self, $lineNum, $posn, $type, $check) = @_;

        # Local variables
        my ($linkObj, $listRef);

        # Check for improper arguments
        if (! defined $lineNum || ! defined $posn || ! defined $type || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_link', @_);
        }

        $linkObj = Games::Axmud::Obj::Link->new($self->linkObjCount, $self, $lineNum, $posn, $type);
        if (! $linkObj) {

            return undef;

        } else {

            $self->ivAdd('linkObjHash', $linkObj->number, $linkObj);

            if (! $self->ivExists('linkObjLineHash', $lineNum)) {

                $self->ivAdd('linkObjLineHash', $lineNum, []);
            }

            $listRef = $self->ivShow('linkObjLineHash', $lineNum);
            push (@$listRef, $linkObj);

            $self->ivIncrement('linkObjCount');

            return $linkObj;
        }
    }

    sub reset_link {

        # Called by $self->clearBuffer

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_link', @_);
        }

        $self->ivEmpty('linkObjHash');
        $self->ivEmpty('linkObjLineHash');
        $self->ivPoke('linkObjCount', 0);

        return 1;
    }

    sub set_maxLines {

        # Called by GA::Cmd::SetTextView->do

        my ($self, $max, $check) = @_;

        # Local variables
        my ($endIter, $lineNum);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_maxLines', @_);
        }

        $self->ivPoke('maxLines', $max);

        # If $max is 'undef' or 0, the buffer is unlimited
        # For other integer values, check whether the buffer has exceeded its maximum number of
        #   lines and, if so, delete one or more lines
        if ($max) {

            # Get the line number of the last line
            $endIter = $self->buffer->get_end_iter();
            $lineNum = $endIter->get_line();

            if ($lineNum && ($lineNum - $self->nextDeleteLine) > $max) {

                do {

                    my ($mark, $listRef);

                    $mark = $self->buffer->get_mark('line_' . $self->nextDeleteLine);
                    if ($mark) {

                        $self->buffer->delete(
                            $self->buffer->get_start_iter(),
                            $self->buffer->get_iter_at_mark($mark),
                        );
                    }


                    # Remove any link objects for links on the deleted line
                    $listRef = $self->ivShow('linkObjLineHash', $self->nextDeleteLine);
                    if (defined $listRef) {

                        foreach my $linkObj (@$listRef) {

                            $self->ivDelete('linkObjHash', $linkObj->number);
                        }

                        $self->ivDelete('linkObjLineHash', $self->nextDeleteLine);
                    }

                    $self->ivIncrement('nextDeleteLine');

                } until (($lineNum - $self->nextDeleteLine) <= $max);
            }
        }

        return 1;
    }

    sub set_mxpModalStackList {

        # Called by GA::Session->popMxpStack

        my ($self, @list) = @_;

        # (No improper arguments to check)

        $self->ivPoke('mxpModalStackList', @list);

        return 1;
    }

    sub set_mxpModalStackHash {

        # Called by GA::Session->processLineSegment

        my ($self, %hash) = @_;

        # (No improper arguments to check)

        $self->ivPoke('mxpModalStackHash', %hash);

        return 1;
    }

    sub set_newLineDefault {

        my ($self, $default, $check) = @_;

        # Check for improper arguments
        if (! defined $default || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_newLineDefault', @_);
        }

        if ($default eq 'before' || $default eq 'after' || $default eq 'nl' || $default eq 'echo') {

            $self->ivPoke('newLineDefault', $default);
            return 1;

        } else {

            return undef;
        }
    }

    sub set_scrollLockType {

        my ($self, $type, $check) = @_;

        # Check for improper arguments
        if (! defined $type || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_scrollLockType', @_);
        }

        if ($type eq 'top') {
            $self->ivPoke('scrollLockType', 'top');
        } else {
            $self->ivPoke('scrollLockType', 'bottom');
        }

        return 1;
    }

    sub set_scrlRegion {

        my ($self, $top, $bottom, $check) = @_;

        # Check for improper arguments
        if (! defined $top || ! defined $bottom || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_scrlRegion', @_);
        }

        $self->ivPoke('scrlRegionTop', $top);
        $self->ivPoke('scrlRegionBottom', $bottom);

        return 1;
    }

    sub reset_scrlRegion {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_scrlRegion', @_);
        }

        $self->ivUndef('scrlRegionTop');
        $self->ivUndef('scrlRegionBottom');

        return 1;
    }

    sub set_sizeUpdateFlag {

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_sizeUpdateFlag', @_);
        }

        $self->ivPoke('sizeUpdateFlag', TRUE);

        return 1;
    }

    ##################
    # Accessors - get

    sub session
        { $_[0]->{session} }
    sub number
        { $_[0]->{number} }
    sub winObj
        { $_[0]->{winObj} }
    sub paneObj
        { $_[0]->{paneObj} }

    sub textView
        { $_[0]->{textView} }
    sub textView2
        { $_[0]->{textView2} }
    sub buffer
        { $_[0]->{buffer} }
    sub vPaned
        { $_[0]->{vPaned} }
    sub scroll
        { $_[0]->{scroll} }
    sub scroll2
        { $_[0]->{scroll2} }
    sub startMark
        { $_[0]->{startMark} }
    sub endMark
        { $_[0]->{endMark} }
    sub searchMark
        { $_[0]->{searchMark} }
    sub popupMenu
        { $_[0]->{popupMenu} }

    sub scrollLockFlag
        { $_[0]->{scrollLockFlag} }
    sub scrollLockType
        { $_[0]->{scrollLockType} }
    sub splitScreenMode
        { $_[0]->{splitScreenMode} }

    sub colourScheme
        { $_[0]->{colourScheme} }
    sub textColour
        { $_[0]->{textColour} }
    sub underlayColour
        { $_[0]->{underlayColour} }
    sub backgroundColour
        { $_[0]->{backgroundColour} }
    sub font
        { $_[0]->{font} }
    sub fontSize
        { $_[0]->{fontSize} }
    sub monochromeFlag
        { $_[0]->{monochromeFlag} }
    sub monochromeModFlag
        { $_[0]->{monochromeModFlag} }
    sub overwriteFlag
        { $_[0]->{overwriteFlag} }

    sub maxLines
        { $_[0]->{maxLines} }
    sub nextDeleteLine
        { $_[0]->{nextDeleteLine} }

    sub scrlRegionTop
        { $_[0]->{scrlRegionTop} }
    sub scrlRegionBottom
        { $_[0]->{scrlRegionBottom} }

    sub bufferTextFlag
        { $_[0]->{bufferTextFlag} }
    sub sizeUpdateFlag
        { $_[0]->{sizeUpdateFlag} }
    sub textWidthChars
        { $_[0]->{textWidthChars} }
    sub textHeightChars
        { $_[0]->{textHeightChars} }
    sub newLineFlag
        { $_[0]->{newLineFlag} }
    sub insertNewLineFlag
        { $_[0]->{insertNewLineFlag} }
    sub newLineDefault
        { $_[0]->{newLineDefault} }
    sub clearAfterInsertFlag
        { $_[0]->{clearAfterInsertFlag} }

    sub insertMark
        { $_[0]->{insertMark} }
    sub restoreInsertMark
        { $_[0]->{restoreInsertMark} }
    sub tempInsertMark
        { $_[0]->{tempInsertMark} }
    sub systemInsertMark
        { $_[0]->{systemInsertMark} }
    sub systemTextBuffer
        { $_[0]->{systemTextBuffer} }

    sub cursorEnableFlag
        { $_[0]->{cursorEnableFlag} }
    sub cursorOnFlag
        { $_[0]->{cursorOnFlag} }
    sub cursorMark
        { $_[0]->{cursorMark} }
    sub cursorEndFlag
        { $_[0]->{cursorEndFlag} }
    sub storePosnYPos
        { $_[0]->{storePosnYPos} }
    sub storePosnXPos
        { $_[0]->{storePosnXPos} }

    sub linkObjHash
        { my $self = shift; return %{$self->{linkObjHash}}; }
    sub linkObjLineHash
        { my $self = shift; return %{$self->{linkObjLineHash}}; }
    sub linkObjCount
        { $_[0]->{linkObjCount} }
    sub currentLinkObj
        { $_[0]->{currentLinkObj} }
    sub allowLinkFlag
        { $_[0]->{allowLinkFlag} }

    sub tooltipHash
        { my $self = shift; return %{$self->{tooltipHash}}; }
    sub lastTooltipLine
        { $_[0]->{lastTooltipLine} }

    sub soundDelayTime
        { $_[0]->{soundDelayTime} }
    sub soundCheckTime
        { $_[0]->{soundCheckTime} }

    sub colourStyleHash
        { my $self = shift; return %{$self->{colourStyleHash}}; }
    sub prevColourStyleHash
        { my $self = shift; return %{$self->{prevColourStyleHash}}; }

    sub mxpModalStackList
        { my $self = shift; return @{$self->{mxpModalStackList}}; }
    sub mxpModalStackHash
        { my $self = shift; return %{$self->{mxpModalStackHash}}; }
}

# Package must return a true value
1
