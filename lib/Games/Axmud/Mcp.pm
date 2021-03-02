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
# Games::Axmud::Mcp::Obj::MultiLine
# The code that stores MCP multiline data until the server has finished sending them
# Games::Axmud::Mcp::XXX
# The code that handles an MCP package object

{ package Games::Axmud::Mcp::Obj::MultiLine;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Atcp Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Session->extractMcpArgs
        # MCP multiline messages comprise a message, spread over one or more lines. The lines occur
        #   in order, but not necessarily consecutively, so the lines' contents are stored here
        #   until a multiline termination message is received
        #
        # Expected arguments
        #   $name           - The name of this object is the MCP data tag specified in the MCP
        #                       message
        #   $msg            - The MCP message, e.g. 'mcp-negotiate-can'
        #   $normalListRef  - Reference to a list of normal (i.e. single-line) key-value pairs
        #                       which can't be updated by multiline continuation lines. List in the
        #                       form (key, value, key, value...)
        #   $multiListRef   - Reference to a list of multiline key-value pairs which can be updated
        #                       by multiline continuation lines. List in the form
        #                       (key, value, key, value...), where each value is an empty string
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $name, $msg, $normalListRef, $multiListRef, $check) = @_;

        # Local variables
        my (%normalHash, %multiHash);

        # Check for improper arguments
        if (
            ! defined $class || ! defined $name || ! defined $msg || ! defined $normalListRef
            || ! defined $multiListRef || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Convert the list references to hashes (the calling code has already checked for
        #   duplicate keys)
        if (@$normalListRef) {

            do {

                my ($key, $value);

                $key = shift @$normalListRef;
                $value = shift @$normalListRef;

                $normalHash{$key} = $value;

            } until (! @$normalListRef);
        }

        if (@$multiListRef) {

            do {

                my ($key, $value);

                $key = shift @$multiListRef;
                $value = shift @$multiListRef;

                $multiHash{$key} = $value;

            } until (! @$multiListRef);
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => undef,
            _parentWorld                => undef,
            _privFlag                   => TRUE,            # All IVs are private

            # IVs
            # ---

            # The name of this object is the MCP data tag specified in the MCP message
            name                        => $name,
            # The MCP message, e.g. 'mcp-negotiate-can'
            msg                         => $msg,

            # Hash of key-value pairs with single-line values that can't be modified in MCP
            #   multiline continuation lines
            normalHash                  => {%normalHash},
            # Hash of key-value pairs with multi-line values that can be modified in MCP multiline
            #   continuation lines
            multiHash                   => {%multiHash},
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
    sub msg
        { $_[0]->{msg} }

    sub normalHash
        { my $self = shift; return %{$self->{normalHash}}; }
    sub multiHash
        { my $self = shift; return %{$self->{multiHash}}; }
}

{ package Games::Axmud::Mcp::Cord;

    # This package provides no functions of its own, as all 'mcp-cord' messages are handled by
    #   GA::Session->processMcpMsg

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Mcp Games::Axmud::Generic::Atcp Games::Axmud);

    ##################
    # Constructors

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::Mcp::NegotiateCan;

    # This package provides no functions of its own, as all 'mcp-negotiate' messages are handled by
    #   GA::Session->processMcpMsg

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Mcp Games::Axmud::Generic::Atcp Games::Axmud);

    ##################
    # Constructors

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::Mcp::SimpleEdit;

    # Implementation of 'dns-org-mud-moo-simpleedit', along with
    #   Games::Axmud::OtherWin::McpSimpleEdit

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Mcp Games::Axmud::Generic::Atcp Games::Axmud);

    ##################
    # Constructors

    ##################
    # Methods

    sub msg {

        # Called by GA::Session->processMcpMsg
        # Stores values and opens a window for the user to edit one or more lines of text
        #
        # Expected arguments
        #   $session    - The calling GA::Session
        #   $msg        - The MCP message name, e.g. 'mcp-negotiate-can'
        #
        # Optional arguments
        #   %hash       - A hash of key-value pairs which accompany the MCP message
        #               - Could conceivably be an empty hash, but we expect the keys 'reference',
        #                   'name', 'content' and 'type'
        #
        # Return values
        #   'undef' on improper arguments or if there's an error processing the message
        #   1 if the message is processed successfully

        my ($self, $session, $msg, %hash) = @_;

        # Local variables
        my ($name, $text, $winObj);

        # Check for improper arguments
        if (! defined $session || ! defined $msg) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->msg', @_);
        }

        # Check that the MCP message actually belongs to this package
        $name = $self->name;
        if (! ($msg =~ m/^$name\-/)) {

            return undef;
        }

        # Check that the message is recognised by this package
        if ($msg ne 'dns-org-mud-moo-simpleedit-content') {

            return undef;
        }

        # Check that the required key-value pairs are all present; ignore any unexpected keys
        if (
            ! exists $hash{'reference'}
            || ! exists $hash{'name'}
            || ! exists $hash{'content'}
            || ! exists $hash{'type'}
            || (
                $hash{'type'} ne 'string'
                && $hash{'type'} ne 'string-list'
                && $hash{'type'} ne 'moo-code'
            )
        ) {
            return undef;
        }

        if ($hash{'type'} eq 'string') {

            # $hash{'content'} represents a single-line value

            # Prompt the user to edit the value
            $text = $session->mainWin->showEntryDialogue(
                'MCP Edit',
                $hash{'name'},
                undef,              # No max chars
                $hash{'content'},
                FALSE,              # Not obscure
            );

            if (! defined $text) {

                # Send back the unedited value
                $text = $hash{'content'};
            }

            # Send the MCP message (only one multiline part)
            $session->mcpSendMultiLine(
                'dns-org-mud-moo-simpleedit-set',
                    'reference',
                    $hash{'reference'},
                    'content',
                    $text,
                    'type',
                    $hash{'type'},
            );

        } else {

            # $hash{'content'} represents one or more lines of text

            # Open a window to edit the text (an 'other' window). Pass it all the key-value pairs,
            #   so it can call GA::Session->mcpSendMultiLine() when the user has finished editing
            $winObj = $session->mainWin->quickFreeWin(
                'Games::Axmud::OtherWin::McpSimpleEdit',
                $session,
                # Config
                'mcp_reference' => $hash{'reference'},
                'mcp_name'      => $hash{'name'},
                'mcp_content'   => $hash{'content'},
                'mcp_type'      => $hash{'type'},
            );

            if (! $winObj) {

                return undef;

            } else {

                return 1;
            }
        }
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

# Package must return a true value
1
