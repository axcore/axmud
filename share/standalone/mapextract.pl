#!/usr/bin/perl
package mapextract;
# Axmud map extraction tool, by A S Lewis
# Version 1.0, 17 Dec 2018
# Version 1.1, 12 Feb 2019 (update to Gtk3)
# Works on data files produced by Axmud v1.1.0 or later
# This file is in the public domain

use strict;
use diagnostics;
use warnings;

use Glib qw(TRUE FALSE);

# Modules used by this script
use Gtk3 '-init';
use Storable qw(lock_nstore lock_retrieve);

# Global variable
use vars qw( $FINISH_FLAG );
$FINISH_FLAG = FALSE;

# Standard window creation
my $mainWin = Gtk3::Window->new('toplevel');
$mainWin->signal_connect('delete_event' => sub { Gtk3->main_quit; });
$mainWin->set_default_size(600, 400);
$mainWin->set_border_width(5);
$mainWin->set_position('center_always');
$mainWin->set_title('Axmud map extractor');

# Show a textview for confirmations, and a button to do stuff
my $vBox = Gtk3::VBox->new(FALSE, 0);
$mainWin->add($vBox);

my $scrollWin = Gtk3::ScrolledWindow->new(undef, undef);
$vBox->pack_start($scrollWin, TRUE, TRUE, 5);
$scrollWin->set_policy('automatic', 'automatic');
$scrollWin->set_border_width(0);

my $textView = Gtk3::TextView->new;
$scrollWin->add_with_viewport($textView);
$textView->set_can_focus(FALSE);
$textView->set_wrap_mode('word-char');
$textView->set_justification('left');
my $buffer = $textView->get_buffer();

my $button = Gtk3::Button->new_with_label('Select file');
$vBox->pack_start($button, FALSE, FALSE, 5);
$button->signal_connect('clicked' => sub {

    if (! $FINISH_FLAG) {

        &buttonCallback($button, $buffer);

    } else {

        $mainWin->destroy();
        exit;
    }
});

# Show the window
$buffer->set_text(
    "Has your map broken Axmud? Do you want to send your map to the authors, but can't? Then use"
    . " this script!\n\n"
    . "The script creates a copy of the map. It removes all labels, then it creates a new file"
    . " which can be saved in a convenient location (for example, your desktop.)\n\n"
    . "First find the location of Axmud's data directory. HINT: You can use the following client"
    . " command:\n\n"
    . "   ;listdatadirectory\n   ;ldd\n\n"
    . "When you've found the data directory, find the world model (map) file. For example, if you"
    . " want to extract a Discworld map, look for:\n\n"
    . "   .../data/worlds/discworld/worldmodel.axm\n\n"
    . "When you've found the right file, click the button below, and select that file.",
);

$mainWin->show_all();

# Main event loop
Gtk3->main();

# Callback functions

sub buttonCallback {

    my ($button, $buffer) = @_;

    $buffer->set_text("Selecting the worldmodel.axm file...");

    $button->set_sensitive(FALSE);

    # Get a path to the worldmodel.axm file
    my $path;

    my $dialogueWin = Gtk3::FileChooserDialog->new(
        'Select the world model file (worldmodel.axm)',
        $mainWin,
        'open',
        'gtk-cancel' => 'cancel',
        'gtk-ok' => 'ok'
    );

    $dialogueWin->set_position('center-always');
    $dialogueWin->signal_connect('delete-event' => sub {

        $dialogueWin->destroy();

        $buffer->insert_with_tags_by_name(
            $buffer->get_end_iter(),
            "\nOperation cancelled",
        );

        return &resetButton($button);
    });

    if ($dialogueWin->run ne 'ok') {

        $buffer->insert_with_tags_by_name(
            $buffer->get_end_iter(),
            "\nOperation failed",
        );

        return &resetButton($button);

    } else {

        $path = $dialogueWin->get_filename();
        $dialogueWin->destroy();

        $buffer->insert_with_tags_by_name(
            $buffer->get_end_iter(),
            "\nSelected file $path...",
        );
    }

    # Load the file
    my $hashRef = Storable::lock_retrieve($path);
    if (! $hashRef) {

        $buffer->insert_with_tags_by_name(
            $buffer->get_end_iter(),
            "\nCould not load $path",
        );

        return &resetButton($button);
    }

    # Extract the world model
    my $wmObj = $$hashRef{world_model_obj};
    if (! $wmObj) {

        $buffer->insert_with_tags_by_name(
            $buffer->get_end_iter(),
            "\nOperation failed - file does not contain a world model",
        );

        return &resetButton($button);
    }

    $buffer->insert_with_tags_by_name(
        $buffer->get_end_iter(),
        "\nRemoving labels...",
    );

    # Replace text of all map label objects
    my $hashRef2 = $wmObj->{regionmapHash};
    foreach my $regionmapObj (values %$hashRef2) {

        my $thisHashRef = $regionmapObj->{gridLabelHash};

        foreach my $mapLabelObj (values %$thisHashRef) {

            my $name = $mapLabelObj->{name};

            $mapLabelObj->{name} = "X" x length($name);
        }
    }

    # Replace character visits, if any
    my $hashRef3 = $wmObj->{roomModelHash};
    foreach my $roomObj (values %$hashRef3) {

        $roomObj->{visitHash} = {};
    }

    $buffer->insert_with_tags_by_name(
        $buffer->get_end_iter(),
        "\nSelecting save location...",
    );

    # Get a directory where the extracted file should be saved
    my $path2;

    my $dialogueWin2 = Gtk3::FileChooserDialog->new(
        'Set the name and location of the new file',
        $mainWin,
        'save',
        'gtk-cancel' => 'cancel',
        'gtk-ok' => 'ok'
    );

    $dialogueWin2->set_position('center-always');
    $dialogueWin2->signal_connect('delete-event' => sub {

        $dialogueWin2->destroy();

        $buffer->insert_with_tags_by_name(
            $buffer->get_end_iter(),
            "\nOperation cancelled",
        );

        return &resetButton($button);
    });

    if ($dialogueWin2->run ne 'ok') {

        $buffer->insert_with_tags_by_name(
            $buffer->get_end_iter(),
            "\nOperation failed",
        );

        return &resetButton($button);

    } else {

        $path2 = $dialogueWin2->get_filename();
        $dialogueWin2->destroy();
    }

    $buffer->insert_with_tags_by_name(
        $buffer->get_end_iter(),
        "\nSaving file to $path2...",
    );

    # Save the file
    $$hashRef{world_model_obj} = $wmObj;
    Storable::lock_nstore($hashRef, $path2);
    if ($@) {

        $buffer->insert_with_tags_by_name(
            $buffer->get_end_iter(),
            "\nCould not load $path",
        );

        return &resetButton($button);
    }

    $buffer->insert_with_tags_by_name(
        $buffer->get_end_iter(),
        "\nFile saved...\nOperation complete!",
    );

    return &resetButton($button);
}

sub resetButton {

    my ($button) = @_;

    $button->set_label('Close window');
    $button->set_sensitive(TRUE);

    $FINISH_FLAG = TRUE;

    return 1;
}
