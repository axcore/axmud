#!/usr/bin/perl
package convertlpc;
#: Version: 1.0
#: Description: Converts world model into LPC
#: Author: A S Lewis
#: Copyright: This plugin is in the public domain, but you are encouraged to share any modifications
#       and improvements you make!

#  =-=-=-=-=-=-=-=-=-=
#  PLUGIN INSTRUCTIONS
#  =-=-=-=-=-=-=-=-=-=
#
#   This plugin can be used to convert the contents of the current world model (which stores the
#       maps you've drawn in the Automapper window) into LPC files; specifically those used by the
#       DeadSouls mudlib.
#   The new LPC files can then be copied onto the machine on which the MUD is running.
#   Simply re-start the MUD and - hey presto! - the contents of your maps will appear in the MUD,
#       as if by magic.
#
#   This plugin produces LPC files for rooms and objects using a standard format, but if you have an
#       understanding of Perl, you can easily modify the plugin code to make it produce files in a
#       different format.
#   You could also modify the plugin to produce LPC files for other LPC mudlibs, or for other code
#       bases altogether.
#
#   This is a step-by-step guide for doing your first conversion. (Since you have access to MUD
#       code, we're assuming that you possess basic computer skills such as copying files and
#       navigating through directories/folders.)
#
#   1. First, connect to the world in OFFLINE mode, as very large maps will take a long time to
#       convert, and you won't be able to type commands during this process. (If you're an admin
#       user at the world who is unlikely to be attacked by NPCs, then of course you can connect in
#       online mode.)
#
#   2. Load the plugin using this (client) command:
#
#           ;loadplugin -s
#
#      It might be more convenient to have the plugin load every time you start Axmud, in which case
#           you should use this command:
#
#           ;addinitialplugin -s
#
#      If you have copied the plugin to Axmud's data folder, because you want to modify it for your
#           own purposes, then don't use the -s switch
#
#           ;loadplugin
#           ;addinitialplugin
#
#   3. Convert your world model into LPC files with this command:
#
#           ;convertlpc
#
#   4. The LPC files are stored in your usual data directory (folder). For a normal Axmud
#       installation on a Linux machine, it will be something like:
#
#           /home/<your name>/axmud-data/clpc_output
#
#   5. Navigate into the .../clpc_output/<world_name>/domains directory, and you'll find a list
#       of sub-directories, one for each region in your world model.
#
#   6. Copy all of these directories onto the machine on which the MUD is running. On a DeadSouls
#       installation, they should be copied into the .../ds/lib/domains directory.
#
#   7. Restart the MUD (or update the mudlib in the usual way). As if by magic, the contents of your
#       world model will appear in the MUD, ready to be played!
#
#   Now you can modify this plugin to suit your requirements.
#
#   8. Before modifying anything, it would be a good idea to copy the plugin into your data
#       directory. There's a 'plugins' directory there which Axmud will not disturb, even if you
#       update or re-install Axmud. (You need to copy both this file and the '_convertlpc_cmds.pm'
#       file.)
#
#   9. (If you used the ';addinitialplugin' command earlier, you should now use the
#       ';deleteinitialplugin' command for the plugin at its old location, before using the
#       ';addinitialplugin' command to add the plugin at its new location.)
#
#   10. Look through the global variables in this file. You can modify any of them which aren't
#       marked 'DO NOT MODIFY!'
#
#   11. The conversion code is in the '_convertlpc_cmds.pm' file, which is loaded automatically
#       whenever this plugin is loaded.
#
#   12. If you want to change the format of the converted LPC files, you can modify any of the
#       following subroutines, following the pattern of the existing code:
#
#           ->prepareRoom
#           ->prepareWeapon
#           ->prepareArmour
#           ->prepareGarment
#           ->prepareSentient
#           ->prepareCreature
#           ->preparePortable
#           ->prepareDecoration
#
#   13. It's VERY unlikely that you will need to modify any other subroutines.
#
#   14. Perl modules can't be unloaded or re-loaded, so you will need to restart Axmud before trying
#       to use the modified code.
#
#   15. The world model is stored in various Perl objects (rooms are represented by
#           GA::ModelObj::Room objects, sentient NPCS by GA::ModelObj::Sentient objecs, and so on).
#           If you need to refer to this code, in order to see exactly what information is stored
#           by the world model and how it is stored, you can look at this file:
#
#           .../axmud/lib/world_model_objs.pm

use strict;
use diagnostics;
use warnings;

# Modules used by this plugin
require _convertlpc_cmds;

# Standard BEGIN / END functions
BEGIN {

    use Glib qw(TRUE FALSE);

    # Global variables (for the plugin)
    use vars qw(
        $CONVERT_TYPE $DIRECTORY $NO_ERROR_FLAG $MAX_FILES $MAX_FILE_NAME_SIZE $UPDATE_COUNT
        $NEST_DIRECTORIES_FLAG $NO_UNDERLINE_FLAG $MAX_WORDS $NULL_OBJ_DESCRIP $DEFAULT_WEIGHT
        $DEFAULT_CURRENCY $DEFAULT_VALUE $SENTIENT_DEFAULT_RACE $CREATURE_DEFAULT_RACE
        $DEFAULT_GENDER
        @COPYRIGHT_LIST @CATEGORY_LIST
        %REMOVE_HASH %SPECIAL_NAME_HASH %DIRECTORY_HASH %CATEGORY_HASH
    );

    # If you want error messages (etc) to show something other than 'LPC', change this variable
    $CONVERT_TYPE = 'LPC';
    # All converted LPC files saved to this directory
    $DIRECTORY = $axmud::DATA_DIR . '/clpc_output';
    # Flag set to TRUE if the ';convertlpc' command should give up at the first error, FALSE if it
    #   should continue (if possible)
    $NO_ERROR_FLAG = TRUE;
    # Max number of LPC files to convert before giving up
    $MAX_FILES = 100000;
    # Max characters in each file name (not including the number added to differentiate objects
    #   with the same name, e.g. 'start4.c', and not including the .c)
    $MAX_FILE_NAME_SIZE = 32;
    # Show a message in the 'main' window after converting this many files (set to 0 to avoid
    #   showing updates)
    $UPDATE_COUNT = 1000;
    # Flag set to TRUE if the LPC directory corresponding to a world model region should be nested
    #   inside the directory of its parent region; set to FALSE if  every world model region has an
    #   LPC directory in /clpc_output/<world>/domains/
    $NEST_DIRECTORIES_FLAG = TRUE;
    # Directory/file names don't contain underline characters in place of whitespace; instead,
    #   whitespace is removed entirely (e.g. 'big white house' > 'bigwhitehouse')
    $NO_UNDERLINE_FLAG = TRUE;
    # If set to 0, the whole room title (brief description) is used for the converted file name. For
    #   other model objects, the whole of the object's base string is used
    # If set to a positive integer, only that many words are used (not including any of the words
    #   stored in %REMOVE_HASH, which are removed in any case)
    # e.g. 'big white house' > 'bigwhite' (if this variable is set to 2)
    $MAX_WORDS = 2;
    # Hash of words that should be removed from the room title or the object base string, when
    #   deciding its corresponding filename. Removeable words are stored as keys in the hash; the
    #   corresponding values are ignored.
    # To stop word removal altogether, simply empty this hash. Otherwise, add or remove words as
    #   you please
    %REMOVE_HASH = (
        # Articles
        'a'         => undef,
        'an'        => undef,
        'the'       => undef,
        # Prepositions
        'above'     => undef,
        'at'        => undef,
        'below'     => undef,
        'for'       => undef,
        'in'        => undef,
        'of'        => undef,
        'off'       => undef,
        'onto'      => undef,
        'to'        => undef,
        'with'      => undef,
        'without'   => undef,
    );
    # When converting model objects (other than rooms), if the object doesn't contain a description,
    #   this string is used as the description
    $NULL_OBJ_DESCRIP = 'This object that hasn\'t been described yet.';
    # Default mass for model objects
    $DEFAULT_WEIGHT = 100;
    # Default value and currency for model objects
    $DEFAULT_CURRENCY = 'silver';
    $DEFAULT_VALUE = 10;
    # Default race/gender for 'sentient' and 'creature' objects
    $SENTIENT_DEFAULT_RACE = 'human';
    $CREATURE_DEFAULT_RACE = 'orc';
    $DEFAULT_GENDER = 'male';
    # List of lines added to the beginning of every file, typically used for copyright messages and
    #   other such comments
    @COPYRIGHT_LIST = (
        '/*   Copyright (C) 2016 The Gods of DeathMud   */',
        '/*         See the file /copyright.txt         */',
    );
    # Hash of world model region names (stored as keys), and the corresponding directory names
    #   (stored as values), in case you don't want this plugin to decide the name of the directory
    #   for one or more regions
    %SPECIAL_NAME_HASH = (
#       'Northern desert'   => 'ndesert',        # Save this domain in .../<world>/domains/ndesert/
    );
    # Each world model region has its own directory, and each directory typically has
    #   sub-directories for each type of object - rooms in one sub-directory, weapons in another,
    #   and so-on
    # The keys in the hash represent model object categories, and they should not be changed (nor
    #   should you remove or add extra keys, unless of course you're willing to change the rest of
    #   the plugin code yourself)
    # Each key's corresponding value is the sub-directory used by the DeadSouls mudlib to store this
    #   type of object; you can change these if you want (e.g. change the value 'npc' to 'mon', if
    #   you want all sentients and creatures to be stored in a sub-directory called 'mon'), but
    #   don't change the value to an empty string or 'undef'
    %DIRECTORY_HASH = (
        'room'          => 'room',
        'weapon'        => 'weap',
        'armour'        => 'armor',
        'garment'       => 'armor',
        'sentient'      => 'npc',
        'creature'      => 'npc',
        'portable'      => 'obj',
        'decoration'    => 'obj',
    );
    # Corresponding hash, which tells the plugin which categories of model object should be
    #   converted. Once again, the keys must not be modified, but you can change any of the TRUE
    #   values to FALSE to prevent them from being written
    %CATEGORY_HASH = (
        'room'          => TRUE,
        'weapon'        => TRUE,
        'armour'        => TRUE,
        'garment'       => TRUE,
        'sentient'      => TRUE,
        'creature'      => TRUE,
        'portable'      => TRUE,
        'decoration'    => TRUE,
    );
    # List of model object categories in the order they're written. DO NOT MODIFY THIS LIST.
    @CATEGORY_LIST = (
        'weapon',
        'armour',
        'garment',
        'sentient',
        'creature',
        'portable',
        'decoration',
        # (Rooms are always created last, so that the LPC files can contain the room's inventory)
        'room',
    );
}

END {}

# Add client commands
$axmud::CLIENT->addPluginCmds(
    'convertlpc',
        '@convertlpc plugin',
            'ConvertLPC'
);

# Package must return true
1
