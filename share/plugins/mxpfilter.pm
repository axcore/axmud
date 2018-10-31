#!/usr/bin/perl
package mxpfilter;
#: Version: 1.0
#: Description: Example of a plugin that implements MXP image/sound filters
#: Author: A S Lewis
#: Copyright: This plugin is in the public domain, but you are encouraged to share any modifications
#       and improvements you make!

#  =-=-=-=-=-=-=-=-=-=
#  PLUGIN INSTRUCTIONS
#  =-=-=-=-=-=-=-=-=-=
#
#   MXP (Mud eXtension Protocol) allows a world to specify its own image/sound format. The world
#       must also provide a client plugin which converts the image/sound file into one which the
#       client supports. In this way, the world can prevent the user from viewing image files and/or
#       hearing sound files until they are required.
#   This plugin demonstrates how to write such a plugin for Axmud. MU* Administrators can modify it
#       to suit their own needs.
#
#   1. Rename the plugin from 'mxpfilter' to something else, if you want. Modify lines 2 and 47.
#
#   2. Every time Axmud tries to apply an MXP file filter, a function in this plugin is called. This
#       plugin uses a function called &convertFile(). If you want to rename the function, modify
#       lines 48 and 51.
#
#   3. The code which performs the conversion starts at line 101. Modify it in any way you please.

use strict;
use diagnostics;
use warnings;

use File::Copy qw(copy);

# Modules used by this plugin
#   (none)

# Standard BEGIN / END functions
BEGIN {

    use Glib qw(TRUE FALSE);
}

END {}

# Inform the client which this plugin's functions should be called
$axmud::CLIENT->addPluginMxpFilters(
    'mxpfilter',                # The name of this plugin
        \&convertFile,          # The name of the conversion function defined below
);

sub convertFile {

    # Called by GA::Session->processMxpImageElement and ->processMspSoundTrigger
    # Converts an image/sound file in the world's own file format into a file format supported by
    #   the client. This example function could convert a .gff file into a .gif file
    #
    # Expected arguments
    #   $path   - The full file path of the file to convert, e.g.
    #               '/home/myname/axmud_data/mxp/deathmud/myimage.gff'
    #   $src    - The source file extension specified by the MXP <FILTER> tag, e.g. 'gff'
    #   $dest   - The destination file extension specified by the MXP <FILTER> tag, e.g. 'gif'
    #   $proc   - An optional numerical parameter used to support multiple conversions, as needed
    #               (see the MXP spec). Default value is 0
    #
    # Return values
    #   'undef' on improper arguments
    #   Otherwise, returns the full file path of the converted file, e.g.
    #       '/home/myname/axmud_data/mxp/deathmud/myimage.gif'
    #   1 otherwise

    my ($path, $src, $dest, $proc, $check) = @_;

    # Local variables
    my $newPath;

    # Check for improper arguments
    if (! defined $path || ! defined $src || ! defined $dest || ! defined $proc || defined $check) {

        return $axmud::CLIENT->writeImproper('&convertFile', @_);
    }

    # Check that the file actually exists (this check has already been done, but there's no harm
    #   doing it again)
    if (! -e $path) {

        return undef;
    }

    # Check that the file has the right file extension. For example, check that it's a .gff file
    if (! ($path =~ m/\.$src$/)) {

        return undef;
    }

    # Convert the file from the world's own file format into one supported by the client
    # In this example plugin, we'll 'convert' the file by changing its file extension, but your
    #   plugin will have to do an actual conversion of some kind
    # If you want a temporary directory to work in, you can use ../axmud_data/tmp/
    # Files in ../axmud_data/tmp/ are deleted whenever the client starts and stops but, in any case,
    #   the calling function will delete the converted file as soon as it's used
    $newPath = $path;
    $newPath =~ s/$src$/$dest/;

    if (! File::Copy::copy($path, $newPath)) {

        return undef;

    } else {

        return $newPath;
    }
}

# Package must return a true value
1
