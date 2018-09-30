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
# Games::Axmud::Obj::Link
# Stores details about a clickable link in a Gtk2::TextView, retrieved when the user clicks the link

{ package Games::Axmud::Obj::Link;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Session->processMxpLinkElement, ->processMxpSendElement and
        #   GA::Obj::TextView->add_link
        # Creates a new instance of the link object, which stores details about a clickable link in
        #   a window, retrieved when the user clicks the link.
        # Also used for MXP clickable links (in <A>..</A> or <SEND>..</SEND> constructions)
        #
        # Expected arguments
        #   $number         - Number for this link object, unique within the parent textview object
        #                       (set to -1 when creating an incomplete link object, which isn't
        #                       applied to the textview until the whole link has been processed,
        #                       e.g. when called by GA::Session->processMxpLinkElement)
        #   $textViewObj    - The parent textview object (GA::Obj::TextView)
        #   $lineNum        - The line number for the Gtk2::TextBuffer line in which the link
        #                       appears (doesn't necessarily match the GA::Session's display buffer
        #                       line numbers)
        #   $posn           - The position of the first character of the link (first character on
        #                       the line is position 0)
        #   $type           - The type of link: 'www', 'mail', 'telnet', 'ssh', 'ssl', 'cmd',
        #                       'image' (or 'other' when the clickable text is empty)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $textViewObj, $lineNum, $posn, $type, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $textViewObj || ! defined $lineNum
            || ! defined $posn || ! defined $type || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'link_' . $number,
            _objClass                   => $class,
            _parentFile                 => $textViewObj->session->currentWorld->name,
            _parentWorld                => undef,
            _privFlag                   => FALSE,        # All IVs are public

            # IVs
            # ---

            # Number for this link object, unique within the parent textview object (set to -1 when
            #   creating an incomplete link object, which isn't applied to the textview until the
            #   whole link has been processed, e.g. when called by
            #   GA::Session->processMxpLinkElement)
            number                      => $number,
            # The parent textview object (GA::Obj::TextView)
            textViewObj                 => $textViewObj,
            # The line number for the Gtk2::TextBuffer line in which the link appears (doesn't
            #   necessarily match the GA::Session's display buffer line numbers)
            lineNum                     => $lineNum,
            # The position of the first character of the link (first character on the line is
            #   position 0)
            posn                        => $posn,
            # The type of link: 'www', 'mail', 'telnet', 'ssh', 'ssl', 'cmd', 'image' (or 'other'
            #   when $text is empty)
            type                        => $type,

            # The link itself, e.g. 'http://deathmud.org'. Acceptable formats:
            #
            #   (type = 'www')
            #   http://deathmud.org         - a URL opened by GA::Client->browserCmd (anything
            #                                   matching GA::Client->constUrlRegex)
            #
            #   (type = 'mail')
            #   mailto:god@deathmud.org     - an email sent by GA::Client->emailCmd
            #   admin@deathmud.org          - an email sent by GA::Client->emailCmd
            #
            #   ($type = 'telnet')
            #   telnet://deathmud.org:6666  - a new connection to a world, using telnet
            #   telnet://deathmud.org       - a new connection to a world, port 23
            #
            #   ($type = 'ssh')
            #   ssh://deathmud.org:6666     - a new connection to a world, using SSH
            #   ssh://deathmud.org          - a new connection to a world, generic port
            #
            #   ($type = 'ssl')
            #   ssl://deathmud.org:6666     - a new connection to a world, using SSL
            #   ssl://deathmud.org          - a new connection to a world, generic port
            #
            #   ($type = 'cmd')
            #   <any string>                - a clickable world command (used with MXP)
            #
            #   ($type = 'image')
            #   <any string>                - a clickable image, which sends the string as a world
            #                                   command. If the string contains %x and/or %y, they
            #                                   are substituted for the x/y coordinates of the mouse
            #                                   click
            #
            #   NB If 'undef' or an empty string , nothing happens when the user clicks the link
            #                   link
            #   NB MXP links can't be ssh:// or ssl://
            href                        => '',
            # The clickable text displayed, e.g. 'Click here for DeathMud website'. If 'undef', an
            #   empty string is stored as an IV (in the expectation that it will be updated with
            #   some text). For non-MXP links, will be the same as $href. For images, 'undef' or an
            #   empty string (since there is no text)
            text                        => '',
            # A hint for this link, if specified ('undef' if not)
            hint                        => undef,
            # The expire name, for links that expire, if specified ('undef' if not)
            expireName                  => undef,
            # Flag set to TRUE when the link expires
            expiredFlag                 => FALSE,

            # Flag set to TRUE if this is an MXP link, FALSE if it's a normal link
            mxpFlag                     => FALSE,
            # Flag set to TRUE if an MXP <SEND>..</SEND> specified PROMPT as one of its arguments
            mxpPromptFlag               => FALSE,
            # Flag set to TRUE if an MXP link's corresponding command should be sent to the world
            #   invisibly, FALSE if it should be visible (or not) as any other world command is
            mxpInvisFlag                => FALSE,

            # Mode for Pueblo links, which are implemented in the same way as MXP <A> or <SEND>
            #   links, depending on arguments
            # 'not_link' - not a Pueblo link, 'href_link' - <A HREF=...>, 'cmd_link'
            #   - <A XCH_CMD...>
            puebloMode                  => 'not_link',

            # Flag set to TRUE if a popup menu should be created when the user clicks on this link
            popupFlag                   => FALSE,
            # When ->popupFlag is TRUE, $self->href is split into a list of world commands, and
            #   stored in this IV (but the value of $self->href remains unchanged)
            popupCmdList                => [],
            # When ->popupFlag is TRUE, $self->hint is split into a list of menu items, and stored
            #   in this IV. If there is one more menu item than there are world commands, the
            #   first menu item (which is actually a hint) is removed and stored in $self->hint;
            #   otherwise $self->hint is set back to 'undef'
            popupItemList               => [],
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

    sub number
        { $_[0]->{number} }
    sub textViewObj
        { $_[0]->{textViewObj} }
    sub lineNum
        { $_[0]->{lineNum} }
    sub posn
        { $_[0]->{posn} }
    sub type
        { $_[0]->{type} }

    sub href
        { $_[0]->{href} }
    sub text
        { $_[0]->{text} }
    sub hint
        { $_[0]->{hint} }
    sub expireName
        { $_[0]->{expireName} }
    sub expiredFlag
        { $_[0]->{expiredFlag} }

    sub mxpFlag
        { $_[0]->{mxpFlag} }
    sub mxpPromptFlag
        { $_[0]->{mxpPromptFlag} }
    sub mxpInvisFlag
        { $_[0]->{mxpInvisFlag} }

    sub puebloMode
        { $_[0]->{puebloMode} }

    sub popupFlag
        { $_[0]->{popupFlag} }
    sub popupCmdList
        { my $self = shift; return @{$self->{popupCmdList}}; }
    sub popupItemList
        { my $self = shift; return @{$self->{popupItemList}}; }
}

# Package must return a true value
1
