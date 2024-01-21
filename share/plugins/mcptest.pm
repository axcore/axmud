#!/usr/bin/perl
package mcptest;
#: Version: 1.0
#: Description: An example plugin that shows how to implement MCP packages
#: Author: A S Lewis
#: Copyright: This plugin is in the public domain, but you are encouraged to share any modifications
#       and improvements you make!

#  =-=-=-=-=-=-=-=-=-=
#  PLUGIN INSTRUCTIONS
#  =-=-=-=-=-=-=-=-=-=
#
#   This example plugin implements an imaginary MCP package at an imaginary MUD, deathmud.com 6666.
#       The imaginary package is therefore called dns-com-deathmud-pingpong. You can modify this
#       plugin to implement any real MCP package
#
#   The plugin needs to be loaded before you connect to a real world. Connect to any world in
#       'offline' mode, and then type:
#
#       ;addinitialplugin -s
#       ;save

use strict;
#use diagnostics;
use warnings;

# Modules used by this plugin
require _mcptest_objs;

# Standard BEGIN / END functions
BEGIN {

    use Glib qw(TRUE FALSE);
}

END {}

# Tell Axmud to add the MCP package object defined by this plugin
$axmud::CLIENT->addPluginMcpPackages(
    'mcptest',
        # The MCP package name
        'dns-com-deathmud-pingpong',
        # The MCP package object, written in Perl, inheriting most of its code from GA::Generic::Mcp
        #   and defined by this plugin
        'Games::Axmud::Mcp::PingPong',
        # Minimum version of the MCP package implemented by this plugin
        '1.0',
        # Maximum version of the MCP package implemented by this plugin
        '1.0',
        # List of MCP packages which this package supplants (in other words, a session won't use
        #   any of these package, if 'dns-com-deathmud-pingpong' can be used
        'dns-com-boringmud-pingpong',
        'dns-com-emptymud-pingpong',
);

# Package must return a true value
1
