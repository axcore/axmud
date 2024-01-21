#!/usr/bin/perl -w

# Define the MCP package object. Most of the code is inherited from GA::Generic::Mcp; all we need to
#   do is to write a custom ->msg function. The ->msg function is called whenever a valid MCP
#   message for this package is received from the world

{ package Games::Axmud::Mcp::PingPong;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Mcp Games::Axmud::Generic::Atcp Games::Axmud);

    ##################
    # Constructors

    ##################
    # Methods

    sub msg {

        # Called by GA::Session->processMcpMsg whenever an MCP message for this package is received
        #
        # Expected arguments
        #   $session    - The calling GA::Session
        #   $msg        - The MCP message name, e.g. 'mcp-negotiate-can'
        #
        # Optional arguments
        #   %hash       - A hash of key-value pairs which accompany the MCP message (may be an
        #                   empty hash)
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
        if (
            $msg ne 'dns-org-mud-moo-pingpong-ping'
            && $msg ne 'dns-org-mud-moo-pingpong-pong'
        ) {
            return undef;
        }

#        # Check that the required key-value pairs are all present; ignore any unexpected keys
#        if (! exists $hash{'foo'} || ! exists $hash{'bar'} || ! exists $hash{'baz'}) {
#
#            return undef;
#        }

        # Respond to the message. If we received a ping, send a pong. If we received a pong, send a
        #   ping. (Obviously, this would not be a good idea in a real MCP package implemtation)
        # By the way, if you want to send a multiline MCP message, call
        #   GA::Session->mcpSendMultiLine() instead
        if ($msg eq 'dns-org-mud-moo-pingpong-ping') {

            # Send an MCP message back to the server
            $session->mcpSendMsg(
                'dns-org-mud-moo-pingpong-pong',
#                # Optional key-value pairs
#                'key1',
#                'val1',
#                'key2',
#                'val2',
            );

        } elsif ($msg eq 'dns-org-mud-moo-pingpong-pong') {

            # Send an MCP message back to the server
            $session->mcpSendMsg(
                'dns-org-mud-moo-pingpong-ping',
#                # Optional key-value pairs
#                'key1',
#                'val1',
#                'key2',
#                'val2',
            );
        }

        # Return a true value to show that the message was accepted
        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

# Package must return a true value
1
