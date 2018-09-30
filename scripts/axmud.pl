#!/usr/bin/perl
package axmud;

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
# axmud.pl
# Axmud - a Multi-User Dungeon (MUD) client written in Perl5 / Gtk2
#
# This script is suitable for all users. Visually-impaired users might prefer to run baxmud.pl
#   instead, as it automatically enables features for those users, such as built-in screenreader
#   support

use strict;
use diagnostics;
use warnings;

use Glib qw(TRUE FALSE);

# Minimum standards for Perl
require 5.008;

# Set global variables
use vars qw(
    $SCRIPT $VERSION $DATE $NAME_SHORT $NAME_ARTICLE $BASIC_NAME $BASIC_ARTICLE $BASIC_VERSION
    $AUTHORS $COPYRIGHT $URL $DESCRIP $NAME_FILE @COMPAT_FILE_LIST @COMPAT_DIR_LIST @COMPAT_EXT_LIST
    $BLIND_MODE_FLAG $SAFE_MODE_FLAG $TEST_MODE_FLAG @TEST_MODE_LOGIN_LIST $TEST_MODE_CMD_FLAG
    $TEST_TERM_MODE_FLAG $TEST_GLOB_MODE_FLAG $TEST_PRE_CONFIG_FLAG @LICENSE_LIST @CREDIT_LIST
    $SHARE_DIR $DATA_DIR $CLIENT
);

$SCRIPT = 'Axmud';              # Name used in system messages
$VERSION = '1.1.174';           # Version number for this client
$DATE = '30 Sep 2018';
$NAME_SHORT = 'axmud';          # Lower-case version of $SCRIPT; same as the package name above
$NAME_ARTICLE = 'an Axmud';     # Name with an article
$BASIC_NAME = 'Axbasic';        # Name of Axmud's built-in scripting library
$BASIC_ARTICLE = 'an Axbasic';  # Name with an article
$BASIC_VERSION = '1.000';       # Version number for the Axbasic library
$AUTHORS = 'A S Lewis';
$COPYRIGHT = 'Copyright 2011-2018 A S Lewis';
$URL = 'http://axmud.sourceforge.net/';
$DESCRIP = 'A modern MUD client for MS Windows/Linux';

# Name used in headers of Axmud config/data files
$NAME_FILE = 'axmud';
# Names used in all versions of Axmud, past and present. Firstly, a list of script names used in the
#   headers to Axmud config/data files
@COMPAT_FILE_LIST = ('axmud', 'amud-client');
# Secondly, a list of partial data directory names used in all versions of Axmud (the actual
#   directory name adds '-data' to each string; see the setting of $DATA_DIR below)
@COMPAT_DIR_LIST = ('axmud', 'amud');
# Thirdly, a list of file extensions for Axmud data files (but not config files)
@COMPAT_EXT_LIST = ('axm', 'amd');

# Axmud blind mode: if this flag is TRUE, when Axmud starts the first time, it will do so with
#   settings optimised for users with a visual impairment
$BLIND_MODE_FLAG = FALSE;
# Axmud safe mode: this flag is (briefly) set to TRUE whenever GA::Session->perlCmd tries to execute
#   some arbitrary Perl code using the Safe module. In that situation, the error-trapping code below
#   won't try to call GA::Client->writePerlError (which produces a load of extra errors)
$SAFE_MODE_FLAG = FALSE;

# Axmud test mode: if this flag is TRUE, when Axmud starts it automatically connects and logs in to
#   the a world which is assumed to be running on your local system, without first opening the
#   Connections window
$TEST_MODE_FLAG = FALSE;
# If $TEST_MODE_FLAG is TRUE, the login details to use. Must be in the form
#   (world_name, host, port, username, password, offline_flag)
@TEST_MODE_LOGIN_LIST = ();
# If $TEST_MODE_FLAG is TRUE and this flag is also TRUE, GA::Session->start executes the ;test
#   command as soon as the session starts
$TEST_MODE_CMD_FLAG = FALSE;
# If $TEST_TERM_MODE_FLAG is TRUE, all text received from the world (except out-of-bounds text) is
#   written to the terminal, with non-printable characters like ESC written as <27>
$TEST_TERM_MODE_FLAG = FALSE;
# Glob test mode: In earlier Axmud versions, saving of data files failed (and Axmud crashed) because
#   of infinite recursions with two Perl objects referencing each other. If TRUE, every save file
#   operation (not including the config file) tests data for this problem, before saving it, writing
#   the output to the terminal
$TEST_GLOB_MODE_FLAG = FALSE;
# Pre-configured world test mode: When preparing for a release, the authors set this flag to TRUE to
#   stop Axmud complaining about missing pre-configured worlds
$TEST_PRE_CONFIG_FLAG = FALSE;

@LICENSE_LIST = (
    'This program is free software; you can redistribute it and/or modify it under',
    'the terms of the GNU General Public License as published by the Free Software',
    'Foundation; either version 3 of the License, or (at your option) any later',
    'version.',
    ' ',
    'This program is distributed in the hope that it will be useful, but WITHOUT ANY',
    'WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A',
    'PARTICULAR PURPOSE. See the GNU General Public License for more details.',
    ' ',
    'You should have received a copy of the GNU General Public License along with',
    'this program. If see <http://www.gnu.org/licenses/>',
);

@CREDIT_LIST = (
    'Axbasic library is based on Language::Basic by Amir Karger',
    'Pathfinding algorithms based on AI::Pathfinding::AStar by Aaron Dalton',
    'Chat task based on Kildclient plugin by Eduardo M Kalinowski',
    'Roman numeral conversion based on Text::Roman by Stanislaw Pusep',
    'Images/icons by Dave Stokes, www.fatcow.com and A S Lewis. License information',
    '   and full attributions can be found in /images/COPYING and /icons/COPYING',
    'Sound by KevanGC, AirMan, AngryFlash, battlestar10, Brandondorf, Cam Martinez,',
    '   Christopher, Conor, Daniel Simon, DrumM8, G-rant, Grant Evans, Grandpa,',
    '   J Blow, J Bravo, Kevan, KevanGC, Lisa Redfern, Maximilien, Mike Koenig,',
    '   Muska666, Pool Shot, PsychoBird, RA The Sun God, Ragdoll485, Samantha Enrico,',
    '   Simon Craggs, Snore Man, Sonidor, Sound Explorer, Stephan, Sweeper, tamskp,',
    '   Tim Fryer, Vladimir, Willem Hunt and Yannick Lemieux. License information and',
    '   full attributions can be found in /items/sounds/COPYING',
    'Documentation and help files by A S Lewis. Licence information can be found in',
    '   /help/COPYING',
);

# External dependencies (Glib is commented out as it's already been used)
use Archive::Extract;
use Archive::Tar;
use Archive::Zip;
use Compress::Zlib;
use Encode qw(decode encode encodings find_encoding from_to);
use Fcntl qw(:flock);
use File::Basename;
use File::Copy qw(copy move);
use File::Copy::Recursive qw(dirmove);
use File::Fetch;
use File::Find;
use File::HomeDir qw(my_home);
use File::Path qw(remove_tree);
use File::ShareDir ':ALL';
use File::ShareDir::Install;
#use Glib qw(TRUE FALSE);
use Glib::Object::Subclass;
use Gnome2::Canvas;

if ($^O ne 'MSWin32') {

    # Wnck doesn't exist on MS Windows systems
    eval "use Gnome2::Wnck";
}

use Gtk2 '-init';
use IO::Socket::INET;
use IO::Socket::INET6;
use IO::Socket::SSL;
use IPC::Run qw(start);
use JSON;
use Math::Trig;
use Module::Load qw(load);
use Net::OpenSSH;
use POSIX qw(ceil);
use Regexp::IPv6 qw($IPv6_re);
use Safe;
use Scalar::Util qw(looks_like_number);
use Socket qw(AF_INET SOCK_STREAM inet_aton sockaddr_in);
use Symbol qw(qualify);
use Storable qw(lock_nstore lock_retrieve);
use Time::HiRes qw(gettimeofday);
use Time::Piece;

# Internal dependencies
use Games::Axmud;
use Language::Axbasic;
use Language::Axbasic::Expression;  # Due to way original Language::Basic was written,
use Language::Axbasic::Function;    #   quickest way to integrate it is to 'use' all the Axbasic
use Language::Axbasic::Statement;   #   source code files here
use Language::Axbasic::Subroutine;
use Language::Axbasic::Variable;

# All files required after the Axmud script has been compiled are stored in /share
$SHARE_DIR = File::ShareDir::dist_dir('Games-Axmud');
# Axmud's data directory. Axmud creates any data files from scratch if they don't already exist
$DATA_DIR = File::HomeDir->my_home . '/' . $NAME_SHORT . '-data';

# Put paths to plugins (all of them Perl modules) into @INC
push (@INC,
    $SHARE_DIR . '/plugins',
    $SHARE_DIR . '/private',
);

# Standard Perl error/warning trapping
$SIG{__DIE__} = sub {

    my (
        $errorFlag,
        @loopList, @sessionList,
        %hash,
    );

    if ($CLIENT) {

        # Errors generated by GA::Session->perlCmd cause a chain of errors, because the Perl Safe
        #   module uses its own namespace and can't call GA::Client->writePerlWarning
        # Workaround is to use a global flag and to generate our own error message if it's set

        # We don't know which GA::Session caused the Perl error, but we can leave Axmud in a (more
        #   or less) functional state by halting all client loops and session loops; the user can
        #   restart them, when ready, with the ';restart' command
        if (! $SAFE_MODE_FLAG) {

            $CLIENT->writePerlError(@_);

            if ($CLIENT->sessionHash && ! $CLIENT->suspendSessionLoopFlag) {

                $CLIENT->haltSessionLoops();
            }
        }

    } else {

        # (If the GA::Client object doesn't exist yet, better to die, than to carry on)
        die(@_);
    }
};

$SIG{__WARN__} = sub {

    # v1.1.159 - filter out same warning messages caused by Perl module/Gtk+ issues, that would
    #   otherwise spam the Console window and/or terminal
    # As of this version, the 'Failed to parse menu bar accelerator' warning is displayed in a *BSD
    #   terminal before being captured by $SIG{__WARN__}, so little we can do about it

#    if ($CLIENT && ! $SAFE_MODE_FLAG) {
#        $CLIENT->writePerlWarning(@_);
#    } else {
#        warn(@_);
#    }

    if (
        ! ($_[0] =~ m/gdk_pixbuf_from_pixdata\(\) called on/)
        && ! ($_[0] =~ m/GdkPixbuf-LOG \*\*\:/)
        && ! ($_[0] =~ m/Failed to parse menu bar accelerator/)
        && ! ($_[0] =~ m/Argument.*isn\'t numeric in numeric ge.*Archive\/Extract\.pm line/)
    ) {
        if ($CLIENT && ! $SAFE_MODE_FLAG) {
            $CLIENT->writePerlWarning(@_);
        } else {
            warn(@_);
        }
    }
};

# Create the main GA::Client object
$CLIENT = Games::Axmud::Client->new();
# Start the client. If this fails, terminate the script
if (! $CLIENT || ! $CLIENT->start()) {

    exit 1;
}

# Start Gtk2's main loop
Gtk2->main();

END {

    # Stop the client - unless the GA::Client->stop() function has already been called
    #   (the only other exit() call is in GA::Client->stop() )
    if (! $CLIENT->shutdownFlag) {

        $CLIENT->stop();
    }
}

=pod

=head1 NAME

Games::Axmud - Axmud, a modern Multi-User Dungeon (MUD) client written in Perl5
/ GTK2

=head1 SYNOPSIS

Axmud is known to work on MS Windows, Linux and *BSD. It might be possible to
install it on other systems such as MacOS, but the authors have not been able to
confirm this yet.

After installation (see the INSTALL file), visually-impaired users can run this
script

    baxmud.pl

Other users can run this script

    axmud.pl

Using either script, you can specify a world to which Axmud connects immediately

    axmud.pl empiremud.net 4000

If you omit the port number, Axmud connects using the generic port 23

    axmud.pl elephant.org

If a world profile already exists, you can specify its name instead

    axmud.pl cryosphere

Note that window tiling and multiple desktop support has not been implemented on
MS Windows yet.

=head1 DESCRIPTION

Axmud is a modern Multi-User Dungeon (MUD) client written in Perl 5 / GTK 2.
Its features include:

Telnet, SSH and SLL connections - ANSI/xterm/OSC/RGB colour - Full support for
all major MUD protocols, including MXP and GMCP (with partial Pueblo support) -
Class-based triggers, aliases, macros, timers and hooks - Graphical automapper
- 90 pre-configured worlds - Multiple approaches to scripting - Fully
customisable from top to bottom, using the command line or the extensive GUI
interface - Native support for visually-impaired users

=head1 AUTHOR

A S Lewis <aslewis@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2011-2018 A S Lewis

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <http://www.gnu.org/licenses/>.

=cut

# Package must return a true value
1;
