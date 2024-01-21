#!/usr/bin/perl
package zmptest;
#: Version: 1.0
#: Description: An example plugin that shows how to implement ZMP packages
#: Author: A S Lewis
#: Copyright: This plugin is in the public domain, but you are encouraged to share any modifications
#       and improvements you make!

#  =-=-=-=-=-=-=-=-=-=
#  PLUGIN INSTRUCTIONS
#  =-=-=-=-=-=-=-=-=-=
#
#   This example plugin responds to ZMP commands at imaginary MUD, deathmud.com 6666. You can modify
#       it to respond to ZMP commands at any real world
#
#   The plugin needs to be loaded before you connect to a real world. Connect to any world in
#       'offline' mode, and then type:
#
#       ;addinitialplugin -s
#       ;save
#
#   A ZMP package called 'axmud' is created every time Axmud starts (before connecting to any world)

use strict;
#use diagnostics;
use warnings;

# Standard BEGIN / END functions
BEGIN {

    use Glib qw(TRUE FALSE);

    # Global variables (for the plugin)
    use vars qw(
        $PACKAGE
    );
}

END {}

# Create the ZMP package object
$PACKAGE = Games::Axmud::Obj::Zmp->new(
    # ZMP package name
    'com.deathmud',
    # Specify a world profile name, if you want the ZMP package to work only at that world. If you
    #   specify 'undef', it's available for any waold
    undef,
    # ZMP commands and the function (in this plugin) that responds to them
    'hello',
        \&hello_world,
);

# Response functions

sub hello_world {

    my ($session, $packageCmd, @paramList) = @_;

    $session->writeText('ZMPTEST: ' . $packageCmd . ' ' . join(' ', @paramList));

    # Axmud expects functions to return some kind of success or failure value. The default is 1 for
    #   success, 'undef' for failure
    return 1;
}

# Package must return a true value
1
