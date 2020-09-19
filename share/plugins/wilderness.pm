#!/usr/bin/perl
package wilderness;
#: Version: 1.0
#: Description: Converts pre-configured worlds to use wilderness mode
#: Author: A S Lewis
#: Copyright: This plugin is in the public domain, but you are encouraged to share any modifications
#       and improvements you make!

#  =-=-=-=-=-=-=-=-=-=
#  PLUGIN INSTRUCTIONS
#  =-=-=-=-=-=-=-=-=-=
#
#   Axmud v1.1.138 introduces wilderness mode for worlds that have large regions containing many
#       rooms, when those rooms have no exit lists. (Usually there's some kind of ASCII map instead)
#   Some of Axmud's pre-configured worlds are set up to draw maps without using wilderness mode; you
#       can use this plugin to modify them, so that maps can be more easily drawn using wilderness
#       mode
#
#   The pre-configured worlds which are modified by this plugin are:
#
#       EmpireMUD 2.0 ('empire')
#
#   NB It is not a good idea to use this plugin, if you've modified a pre-configured world profile
#       to change the way it interprets room statements (for example, if you have used the Locator
#       wizard on it). If you're not sure, ask for advice on the Axmud forum
#
#   Before doing any conversions, you have to load the plugin
#
#   1. Connect to any of the worlds listed above (in online or offline mode)
#
#   2. Load the plugin using this (client) command:
#
#           ;loadplugin -s
#
#   The plugin adds some new client commands. The command modifies the world profile. If you use the
#       same command a second time, those modificiations are reversed
#
#   3. Use one of these commands:
#
#           ;wildempire
#
#   4. Don't forget to save your changes!
#
#           ;save

use strict;
use diagnostics;
use warnings;

# Modules used by this plugin
require _wilderness_cmds;

# Standard BEGIN / END functions
BEGIN {}
END {}

# Add client commands
$axmud::CLIENT->addPluginCmds(
    'wilderness',
        '@wilderness plugin',
            'WildEmpire'
);

# Package must return a true value
1
