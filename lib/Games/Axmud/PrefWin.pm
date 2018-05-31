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
# Games::Axmud::PrefWin::XXX
# All 'pref' (preference) windows, inheriting from GA::Generic::ConfigWin

{ package Games::Axmud::PrefWin::Client;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::EditWin Games::Axmud::Generic::ConfigWin
        Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win Games::Axmud
    );

    ##################
    # Constructors

    # Contents of $self->editConfigHash after $self->new has been called:
    #   (none, however $self->tasks1Tab and ->tasks1Tab_refreshList both store data there)

#   sub new {}                  # Inherited from GA::Generic::ConfigWin

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}             # Inherited from GA::Generic::ConfigWin

#   sub winEnable {}            # Inherited from GA::Generic::ConfigWin

#   sub winDesengage {}         # Inherited from GA::Generic::FreeWin

#   sub winDestroy {}           # Inherited from GA::Generic::FreeWin

#   sub winShowAll {}           # Inherited from GA::Generic::Win

#   sub drawWidgets {}          # Inherited from GA::Generic::ConfigWin

#   sub redrawWidgets {}        # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

#   sub checkEditObj {}         # Inherited from GA::Generic::ConfigWin

    sub enableButtons {

        # Called by $self->drawWidgets
        # We only need a single button so, instead of calling the generic ->enableButtons, call a
        #   method that creates just one button
        #
        # Expected arguments
        #   $hBox       - The horizontal packing box in which the buttons live (not yet stored as
        #                   an IV)
        #   $tooltips   - A Gtk2::Tooltips object for the buttons (not yet stored as an IV)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, a list containing the Gtk::Button object created

        my ($self, $hBox, $tooltips, $check) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (! defined $hBox || ! defined $tooltips || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->enableButtons', @_);
            return @emptyList;
        }

        return $self->enableSingleButton($hBox, $tooltips);
    }

#   sub enableSingleButton {}   # Inherited from GA::Generic::ConfigWin

    sub setupNotebook {

        # Called by $self->enable
        # Creates the first tab for the notebook. The remaining tabs are created by
        #   $self->expandNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setupNotebook', @_);
        }

#       # Tab setup
#       my ($vBox, $table) = $self->addTab('_Client', $self->notebook);

        # Set up the rest of the first tab (all of it, in this case)
        $self->clientTab();

        # Set up the remaining tabs
        $self->expandNotebook();

#       # Tab complete
#       $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub expandNotebook {

        # Called by $self->setupNotebook
        # Set up additional tabs for the notebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->expandNotebook', @_);
        }

        $self->settingsTab();
        $self->pluginsTab();
        $self->commandsTab();
        $self->logsTab();
        $self->coloursTab();
        $self->workspacesTab();
        $self->windowsTab();
        $self->soundTab();
        $self->tasksTab();
        $self->scriptsTab();
        $self->chatTab();

        return 1;
    }

#   sub saveChanges {}          # Inherited from GA::Generic::ConfigWin

    # Notebook tabs

    sub clientTab {

        # Client tab - called by $self->setupNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clientTab', @_);
        }

        # Tab setup
        # Create a notebook within the main one, so that we have two rows of tabs
        my ($vBox, $innerNotebook) = $self->addInnerNotebookTab('_Client', $self->notebook);

        # Add tabs to the inner notebook
        $self->client1Tab($innerNotebook);
        $self->client2Tab($innerNotebook);
        $self->client3Tab($innerNotebook);
        $self->client4Tab($innerNotebook);
        $self->client5Tab($innerNotebook);

        return 1;
    }

    sub client1Tab {

        # Client1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->client1Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _1', $innerNotebook);

        # Left column
        $self->addLabel($table, '<b>Client settings</b>',
            0, 12, 0, 1);

        $self->addLabel($table, 'Script name',
            1, 3, 1, 2);
        my $entry = $self->addEntry($table, undef, FALSE,
            3, 6, 1, 2);
        $entry->set_text($axmud::SCRIPT);

        $self->addLabel($table, 'Script version',
            1, 3, 2, 3);
        my $entry6 = $self->addEntry($table, undef, FALSE,
            3, 6, 2, 3);
        $entry6->set_text($axmud::VERSION);

        $self->addLabel($table, 'Script date',
            1, 3, 3, 4);
        my $entry7 = $self->addEntry($table, undef, FALSE,
            3, 6, 3, 4);
        $entry7->set_text($axmud::DATE);

        $self->addLabel($table, 'Authors',
            1, 3, 4, 5);
        my $entry3 = $self->addEntry($table, undef, FALSE,
            3, 12, 4, 5);
        $entry3->set_text($axmud::AUTHORS);

        $self->addLabel($table, 'Copyright',
            1, 3, 5, 6);
        my $entry4 = $self->addEntry($table, undef, FALSE,
            3, 12, 5, 6);
        $entry4->set_text($axmud::COPYRIGHT);

        my $button = $self->addButton($table, 'About...', 'About ' . $axmud::SCRIPT, undef,
            1, 4, 6, 7);
        $button->signal_connect('clicked' => sub {

            # Only one About window can be open at a time
            if (! $axmud::CLIENT->aboutWin) {

                $self->quickFreeWin(
                    'Games::Axmud::OtherWin::About',
                    $self->session,
                    # config
                    'first_tab' => 'about',
                )

            } else {

                # Only one About window can be open at a time
                $axmud::CLIENT->aboutWin->restoreFocus();
                # Open it at the right page
                $axmud::CLIENT->aboutWin->notebook->set_current_page(0);
            }
        });

        my $button2 = $self->addButton(
            $table, 'Credits...', 'Show information about credits', undef,
            4, 6, 6, 7);
        $button2->signal_connect('clicked' => sub {

            # Only one About window can be open at a time
            if (! $axmud::CLIENT->aboutWin) {

                $self->quickFreeWin(
                    'Games::Axmud::OtherWin::About',
                    $self->session,
                    # config
                    'first_tab' => 'credits',
                )

            } else {

                # Only one About window can be open at a time
                $axmud::CLIENT->aboutWin->restoreFocus();
                # Open it at the right page
                $axmud::CLIENT->aboutWin->notebook->set_current_page(1);
            }
        });

        my $button3 = $self->addButton($table, 'Quick help...', 'Show quick help', undef,
            6, 9, 6, 7);
        $button3->signal_connect('clicked' => sub {

            # Only one About window can be open at a time
            if (! $axmud::CLIENT->aboutWin) {

                $self->quickFreeWin(
                    'Games::Axmud::OtherWin::About',
                    $self->session,
                    # config
                    'first_tab' => 'help',
                )

            } else {

                # Only one About window can be open at a time
                $axmud::CLIENT->aboutWin->restoreFocus();
                # Open it at the right page
                $axmud::CLIENT->aboutWin->notebook->set_current_page(2);
            }
        });

        my $button4 = $self->addButton($table, 'Licenses...', 'Show license information', undef,
            9, 12, 6, 7);
        $button4->signal_connect('clicked' => sub {

            # Only one About window can be open at a time
            if (! $axmud::CLIENT->aboutWin) {

                $self->quickFreeWin(
                    'Games::Axmud::OtherWin::About',
                    $self->session,
                    # config
                    'first_tab' => 'license',
                )

            } else {

                # Only one About window can be open at a time
                $axmud::CLIENT->aboutWin->restoreFocus();
                # Open it at the right page
                $axmud::CLIENT->aboutWin->notebook->set_current_page(3);
            }
        });

        # Right column
        $self->addLabel($table, 'Name in data files',
            7, 9, 1, 2);
        my $entry2 = $self->addEntry($table, undef, FALSE,
            9, 12, 1, 2);
        $entry2->set_text($axmud::NAME_FILE);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub client2Tab {

        # Client2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->client2Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _2', $innerNotebook);

        # Session list
        $self->addLabel($table, '<b>Session list</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of sessions (each corresponding to a single connection to a world)</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Num', 'text',
            'Current', 'bool',
            'Visible', 'bool',
            'Logged in', 'bool',
            'Status', 'text',
            'World', 'text',
            'Character', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 8,
            -1, 270);      # Fixed height

        # Initialise the simple list
        $self->client2Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add buttons
        my $button = $self->addButton($table,
            'Edit...', 'Edit the selected session', undef,
            1, 3, 8, 9);
        $button->signal_connect('clicked' => sub {

            my ($number, $session);

            ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                $session = $axmud::CLIENT->ivShow('sessionHash', $number);
                if ($session) {

                    # Open an 'pref' window for the selected session
                    $self->createFreeWin(
                        'Games::Axmud::PrefWin::Session',
                        $self,
                        $session,
                        'Session preferences',
                    );
                }
            }
        });

        my $button2 = $self->addButton($table,
            'Switch to session', 'Make the selected session the current (visible) one', undef,
            3, 6, 8, 9);
        $button2->signal_connect('clicked' => sub {

            my ($number, $session);

            ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                $session = $axmud::CLIENT->ivShow('sessionHash', $number);
                if ($session && $session->defaultTabObj) {

                    $session->defaultTabObj->paneObj->setVisibleTab($session->defaultTabObj);
                }

                # Refresh the simple list
                $self->client2Tab_refreshList($slWidget, scalar (@columnList / 2));
            }
        });

        my $button3 = $self->addButton($table,
            'Refresh list', 'Refresh the list of sessions', undef,
            9, 12, 8, 9);
        $button3->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->client2Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub client2Tab_refreshList {

        # Resets the simple list displayed by $self->client2Tab
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (@winList, @dataList);

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->client2Tab_refreshList', @_);
        }

        # Get a list of 'main' windows, so we can mark visible windows
        @winList = $axmud::CLIENT->desktopObj->listGridWins('main');

        # Compile the simple list data
        OUTER: foreach my $session ($axmud::CLIENT->listSessions()) {

            my ($currentFlag, $visibleFlag, $world, $char);

            if ($session eq $axmud::CLIENT->currentSession) {
                $currentFlag = TRUE;
            } else {
                $currentFlag = FALSE;
            }

            $visibleFlag = FALSE;
            INNER: foreach my $winObj (@winList) {

                if ($winObj->visibleSession && $winObj->visibleSession eq $session) {

                    $visibleFlag = TRUE;
                    last INNER;
                }
            }

            $world = $session->currentWorld->name;
            if ($session->currentChar) {

                $char = $session->currentChar->name;
            }

            push (@dataList,
                $session->number,
                $currentFlag,
                $visibleFlag,
                $session->loginFlag,
                $session->status,
                $world,
                $char,
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub client3Tab {

        # Client3 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->client3Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _3', $innerNotebook);

        # Directories (folders)
        $self->addLabel($table, '<b>Directories (folders)</b>',
            0, 12, 0, 1);

        $self->addLabel($table, 'Base directory',
            1, 3, 1, 2);
        my $entry = $self->addEntry($table, undef, FALSE,
            3, 12, 1, 2);
        $entry->set_text($axmud::SHARE_DIR);

        $self->addLabel($table, 'Data directory',
            1, 3, 2, 3);
        my $entry2 = $self->addEntry($table, undef, FALSE,
            3, 12, 2, 3);
        $entry2->set_text($axmud::DATA_DIR);

        # File permissions
        $self->addLabel($table, '<b>File permissions</b>',
            0, 12, 3, 4);

        $self->addLabel($table, 'Load config file',
            1, 5, 4, 5);
        my $checkButton = $self->addCheckButton($table, undef, FALSE,
            5, 6, 4, 5);
        $checkButton->set_active($axmud::CLIENT->loadConfigFlag);

        $self->addLabel($table, 'Save config file',
            1, 5, 5, 6);
        my $checkButton2 = $self->addCheckButton($table, undef, FALSE,
            5, 6, 5, 6);
        $checkButton2->set_active($axmud::CLIENT->saveConfigFlag);

        $self->addLabel($table, 'Load other files',
            1, 5, 6, 7);
        my $checkButton3 = $self->addCheckButton($table, undef, FALSE,
            5, 6, 6, 7);
        $checkButton3->set_active($axmud::CLIENT->loadDataFlag);

        $self->addLabel($table, 'Save other files',
            7, 11, 4, 5);
        my $checkButton4 = $self->addCheckButton($table, undef, FALSE,
            11, 12, 4, 5);
        $checkButton4->set_active($axmud::CLIENT->saveDataFlag);

        $self->addLabel($table, 'All files deleted at startup',
            7, 11, 5, 6);
        my $checkButton5 = $self->addCheckButton($table, undef, FALSE,
            11, 12, 5, 6);
        $checkButton5->set_active($axmud::CLIENT->deleteFilesAtStartFlag);

        $self->addLabel($table, 'File operation has failed',
            7, 11, 6, 7);
        my $checkButton6 = $self->addCheckButton($table, undef, FALSE,
            11, 12, 6, 7);
        $checkButton6->set_active($axmud::CLIENT->fileFailFlag);

        # File permissions
        $self->addLabel($table, '<b>Temporary backup file retention</b>',
            0, 12, 7, 8);

        $self->addLabel($table, 'Retain backup copies after saving',
            1, 5, 8, 9);
        my $checkButton8 = $self->addCheckButton($table, undef, FALSE,
            5, 6, 8, 9);
        $checkButton8->set_active($axmud::CLIENT->autoRetainFileFlag);

        my $button4 = $self->addButton($table,
            'Turn on', 'Retain backup copies after saving files', undef,
            7, 9, 8, 9);
        $button4->signal_connect('clicked' => sub {

            # Retain backups on
            $self->session->pseudoCmd('retainbackups on', $self->pseudoCmdMode);

            # Update the checkbutton
            $checkButton8->set_active($axmud::CLIENT->autoRetainFileFlag);
        });

        my $button5 = $self->addButton($table,
            'Turn off', 'Don\'t retain backup copies after saving files', undef,
            9, 12, 8, 9);
        $button5->signal_connect('clicked' => sub {

            # Retain backups off
            $self->session->pseudoCmd('retainbackups off', $self->pseudoCmdMode);

            # Update the checkbutton
            $checkButton8->set_active($axmud::CLIENT->autoRetainFileFlag);
        });

        # File permissions
        $self->addLabel($table, '<b>Auto-save</b>',
            0, 12, 9, 10);

        $self->addLabel($table, 'Enable auto-saves',
            1, 5, 10, 11);
        my $checkButton7 = $self->addCheckButton($table, undef, FALSE,
            5, 6, 10, 11);
        $checkButton7->set_active($axmud::CLIENT->autoSaveFlag);

        my $button = $self->addButton($table,
            'Turn on', 'Turns autosaves on', undef,
            7, 9, 10, 11);
        $button->signal_connect('clicked' => sub {

            # Turn autosave on
            $self->session->pseudoCmd('autosave on', $self->pseudoCmdMode);

            # Update the checkbutton
            $checkButton7->set_active($axmud::CLIENT->autoSaveFlag);
        });

        my $button2 = $self->addButton($table,
            'Turn off', 'Turns autosaves off', undef,
            9, 12, 10, 11);
        $button2->signal_connect('clicked' => sub {

            # Turn autosave off
            $self->session->pseudoCmd('autosave off', $self->pseudoCmdMode);

            # Update the checkbutton
            $checkButton7->set_active($axmud::CLIENT->autoSaveFlag);
        });

        $self->addLabel($table, 'Time interval (minutes)',
            1, 3, 11, 12);
        my $entry3 = $self->addEntryWithIcon($table, undef, 'int', 1, undef,
            3, 6, 11, 12);
        $entry3->set_text($axmud::CLIENT->autoSaveWaitTime);

        my $button3 = $self->addButton($table,
            'Set interval', 'Set the time between successive auto-saves', undef,
            7, 9, 11, 12);
        $button3->signal_connect('clicked' => sub {

            if ($self->checkEntryIcon($entry3)) {

                # Set autosave time
                $self->session->pseudoCmd('autosave ' . $entry3->get_text(), $self->pseudoCmdMode);

                # Update the checkbutton
                $checkButton7->set_active($axmud::CLIENT->autoSaveFlag);
            }
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub client3Tab_refreshList {

        # Resets the simple list displayed by $self->client3Tab
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (@fileList, @dataList);

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->client3Tab_refreshList', @_);
        }

        # Import the list of file objects
        @fileList = sort {lc($a->name) cmp lc($b->name)} ($axmud::CLIENT->ivValues('fileObjHash'));

        # Compile the simple list data
        foreach my $obj (@fileList) {

            push (@dataList,
                $obj->modifyFlag,
                $obj->fileType,
                $obj->name,
                $obj->actualPath,
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub client4Tab {

        # Client4 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->client4Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _4', $innerNotebook);

        # Client file objects
        $self->addLabel($table, '<b>Client file objects</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of data files currently in use by the client (session-independent)</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Not saved', 'bool',
            'File type', 'text',
            'File name', 'text',
            'Path', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);       # Fixed height

        # Initialise the simple list
        $self->client3Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add buttons
        my $button = $self->addButton($table,
            'Save', 'Save all files whose data has been modified', undef,
            1, 3, 10, 11);
        $button->signal_connect('clicked' => sub {

            # Save files
            $self->session->pseudoCmd('save', $self->pseudoCmdMode);

            # Refresh the simple list
            $self->client3Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button2 = $self->addButton($table,
            'Force save', 'Save all files, even if their data has not been modified', undef,
            3, 6, 10, 11);
        $button2->signal_connect('clicked' => sub {

            # Save files
            $self->session->pseudoCmd('save -f', $self->pseudoCmdMode);

            # Refresh the simple list
            $self->client3Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button3 = $self->addButton($table,
            'Refresh list', 'Refresh the list of file objects', undef,
            10, 12, 10, 11);
        $button3->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->client3Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub client5Tab {

        # Client5 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->client5Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _5', $innerNotebook);

        # Reserved names
        $self->addLabel($table, '<b>Reserved names</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of names that can\'t be used as object names</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Reserved name', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 12,
            -1, 300);      # Fixed height

        # Initialise the list
        @{$slWidget->{data}}
            = sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('constReservedHash'));

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub settingsTab {

        # Settings tab - called by $self->setupNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->settingsTab', @_);
        }

        # Tab setup
        # Create a notebook within the main one, so that we have two rows of tabs
        my ($vBox, $innerNotebook) = $self->addInnerNotebookTab('_Settings', $self->notebook);

        # Add tabs to the inner notebook
        $self->settings1Tab($innerNotebook);
        $self->settings2Tab($innerNotebook);
        $self->settings3Tab($innerNotebook);
        $self->settings4Tab($innerNotebook);
        $self->settings5Tab($innerNotebook);
        $self->settings6Tab($innerNotebook);
        $self->settings7Tab($innerNotebook);
        $self->settings8Tab($innerNotebook);
        $self->settings9Tab($innerNotebook);
        $self->settings10Tab($innerNotebook);
        $self->settings11Tab($innerNotebook);

        return 1;
    }

    sub settings1Tab {

        # Settings1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (
            @initList, @comboList, @setList, @comboList2,
            %comboHash,
        );

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->settings1Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _1', $innerNotebook);

        # Left column
        $self->addLabel($table, '<b>Session settings</b>',
            0, 12, 0, 1);

        $self->addLabel($table, 'Tab format',
            1, 3, 1, 2);

        @initList = (
            'b'     => 'World (Character)',
            'h'     => 'World - Character',
            'w'     => 'World',
            'c'     => 'Character',
        );

        do {

            my ($value, $descrip);

            $value = shift @initList;
            $descrip = shift @initList;

            push (@comboList, $descrip);
            $comboHash{$descrip} = $value;

        } until (! @initList);

        my $comboBox = $self->addComboBox($table, undef, \@comboList, 'Select format:',
            TRUE,               # No 'undef' value used
            3, 6, 1, 2);
        $comboBox->signal_connect('changed' => sub {

            my $choice = $comboBox->get_active_text();

            $self->session->pseudoCmd('setsession -' . $comboHash{$choice}, $self->pseudoCmdMode);
        });

        $self->addLabel($table, 'Maximum sessions',
            1, 3, 2, 3);
        my $entry = $self->addEntry($table, undef, FALSE,
            3, 6, 2, 3);
        $entry->set_text($axmud::CLIENT->sessionMax);

        my $entry2 = $self->addEntryWithIcon(
            $table,
            undef,
            'int',
            1,
            $axmud::CLIENT->constSessionMax,
            3, 5, 3, 4);
        my $button = $self->addButton(
            $table, 'Set', 'Set the maximum number of concurrent sessions', undef,
            5, 7, 3, 4);
        $button->signal_connect('clicked' => sub {

            my $num = $entry2->get_text();

            if ($self->checkEntryIcon($entry2)) {

                $self->session->pseudoCmd('maxsession ' . $num);

                $entry2->set_text('');
                $entry->set_text($axmud::CLIENT->sessionMax);
            }
        });

        $self->addLabel($table, 'Default character set',
            1, 3, 4, 5);

        @setList = $axmud::CLIENT->charSetList;
        # (Find the current character set, and put it at the top of the list)
        foreach my $item (@setList) {

            if ($item ne $axmud::CLIENT->charSet) {

                push (@comboList2, $item);
            }
        }

        unshift(@comboList2, $axmud::CLIENT->charSet);

        my $comboBox2 = $self->addComboBox($table, undef, \@comboList2, '',
            TRUE,               # No 'undef' value used
            3, 6, 4, 5);
        $comboBox2->signal_connect('changed' => sub {

            my ($choice, $index);

            $choice = $comboBox2->get_active_text();
            if ($choice) {

                $self->session->pseudoCmd(
                    'setcharset -d ' . $choice,
                    $self->pseudoCmdMode,
                );
            }
        });

        # Right column
        $self->addLabel($table, 'Use xterm title in tab instead (if available)',
            7, 11, 1, 2);

        my $checkButton = $self->addCheckButton($table, undef, TRUE,
            11, 12, 1, 2);
        $checkButton->set_active($axmud::CLIENT->xTermTitleFlag);
        $checkButton->signal_connect('toggled' => sub {

            $self->session->pseudoCmd('setsession -x', $self->pseudoCmdMode);
            $checkButton->set_active($axmud::CLIENT->xTermTitleFlag);
        });

        $self->addLabel($table, 'Use world\'s long name in tab (if available)',
            7, 11, 2, 3);

        my $checkButton2 = $self->addCheckButton($table, undef, TRUE,
            11, 12, 2, 3);
        $checkButton2->set_active($axmud::CLIENT->longTabLabelFlag);
        $checkButton2->signal_connect('toggled' => sub {

            $self->session->pseudoCmd('setsession -l', $self->pseudoCmdMode);
            $checkButton2->set_active($axmud::CLIENT->longTabLabelFlag);
        });

        $self->addLabel($table, 'Don\'t use tabs for a single session',
            7, 11, 3, 4);
        my $checkButton3 = $self->addCheckButton($table, undef, TRUE,
            11, 12, 3, 4);
        $checkButton3->set_active($axmud::CLIENT->simpleTabFlag);
        $checkButton3->signal_connect('toggled' => sub {

            $self->session->pseudoCmd('setsession -s', $self->pseudoCmdMode);
            $checkButton3->set_active($axmud::CLIENT->simpleTabFlag);
        });

        $self->addLabel($table, 'Confirm before click-closing \'main\' window',
            7, 11, 4, 5);
        my $checkButton4 = $self->addCheckButton($table, undef, TRUE,
            11, 12, 4, 5);
        $checkButton4->set_active($axmud::CLIENT->confirmCloseMainWinFlag);
        $checkButton4->signal_connect('toggled' => sub {

            $self->session->pseudoCmd('setsession -m', $self->pseudoCmdMode);
            $checkButton4->set_active($axmud::CLIENT->confirmCloseMainWinFlag);
        });

        $self->addLabel($table, 'Confirm before click-closing tab',
            7, 11, 5, 6);
        my $checkButton5 = $self->addCheckButton($table, undef, TRUE,
            11, 12, 5, 6);
        $checkButton5->set_active($axmud::CLIENT->confirmCloseTabFlag);
        $checkButton5->signal_connect('toggled' => sub {

            $self->session->pseudoCmd('setsession -t', $self->pseudoCmdMode);
            $checkButton5->set_active($axmud::CLIENT->confirmCloseTabFlag);
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub settings2Tab {

        # Settings2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->settings2Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _2', $innerNotebook);

        # Favourite world list
        $self->addLabel($table, '<b>Favourite world list</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $table, '<i>Worlds displayed at the top of the list in the Connections window</i>',
            1, 12, 1, 2);

        my $textView = $self->addTextView($table, undef, TRUE,
            1, 12, 2, 10,
            undef, undef, undef, undef,
            -1, 270);
        my $buffer = $textView->get_buffer();
        $buffer->set_text(join("\n", $axmud::CLIENT->favouriteWorldList));

        my $button = $self->addButton(
            $table, 'Set list', 'Set the list of favourite worlds', undef,
            1, 4, 10, 11);
        $button->signal_connect('clicked' => sub {

            my (
                $text,
                @list,
            );

            $text = $axmud::CLIENT->desktopObj->bufferGetText($buffer);

            # Split the contents of the textview into a list
            @list = split("\n", $text);

            # Set the favourite world list. By using a join so soon after a split, we safely
            #   eliminate newline chars
            $self->session->pseudoCmd(
                'setfavouriteworld ' . join(' ', @list),
                $self->pseudoCmdMode,
            );

            # Update the textview
            $buffer->set_text(join("\n", $axmud::CLIENT->favouriteWorldList));
        });

        my $button2 = $self->addButton(
            $table, 'Update list', 'Updates the list of favourite worlds', undef,
            9, 12, 10, 11);
        $button2->signal_connect('clicked' => sub {

            # Update the textview
            $buffer->set_text(join("\n", $axmud::CLIENT->favouriteWorldList));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub settings3Tab {

        # Settings3 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->settings3Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _3', $innerNotebook);

        # Pre-configured world list
        $self->addLabel($table, '<b>Pre-configured world list</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $table,
            '<i>List of pre-configured world profiles supplied with ' . $axmud::SCRIPT . '</i>',
            1, 12, 1, 2);

        my $textView = $self->addTextView($table, undef, FALSE,
            1, 12, 2, 10,
            undef, undef, undef, undef,
            -1, 270);
        my $buffer = $textView->get_buffer();
        $buffer->set_text(join("\n", sort {lc($a) cmp lc($b)} ($axmud::CLIENT->constWorldList)));

        $self->addLabel(
            $table,
            "If you want to restore one of the pre-configured worlds - replacing any existing"
            . " world with the same name - you\ncan use the <i>\';restoreworld\'</i> command. Read"
            . " the help for <i>\';restoreworld\'</i> <b>carefully</b> before you attempt this"
            . " operation.",
            1, 12, 10, 12);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub settings4Tab {

        # Settings4 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->settings4Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _4', $innerNotebook);

        # Session list
        $self->addLabel($table, '<b>Other world list</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of worlds which did not originally have pre-configured world profiles</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Adult', 'bool',
            'Short', 'text',
            'Long', 'text',
            'Address', 'text',
            'Port', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 300);      # Fixed height

        # Initialise the simple list
        $self->settings4Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub settings4Tab_refreshList {

        # Resets the simple list displayed by $self->settings4Tab
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my @dataList;

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->settings4Tab_refreshList',
                @_,
            );
        }

        # Compile the simple list data
        OUTER: foreach my $obj (
            sort {lc($a->name) cmp lc($b->name)} ($axmud::CLIENT->ivValues('constBasicWorldHash'))
        ) {
            push (@dataList,
                $obj->adultFlag,
                $obj->name,
                $obj->longName,
                $obj->address,
                $obj->port,
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub settings5Tab {

        # Settings5 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->settings5Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _5', $innerNotebook);

        # External applications
        $self->addLabel($table, '<b>External applications</b>',
            0, 12, 0, 1);

        $self->addLabel(
            $table,
            '<i>System command to open a link in a web browser (%s is substituted for the URL)</i>',
            1, 12, 1, 2);

        my $entry = $self->addEntry($table, undef, TRUE,
            1, 10, 2, 3);
        $entry->set_text($axmud::CLIENT->browserCmd);

        my $button = $self->addButton($table,
            'Set', 'Set the system command to run a web browser', undef,
            10, 12, 2, 3);
        $button->signal_connect('clicked' => sub {

            my $cmd = $entry->get_text();

            # Set the system command
            if ($cmd) {
                $self->session->pseudoCmd('setapplication -b <' . $cmd . '>', $self->pseudoCmdMode);
            } else {
                $self->session->pseudoCmd('setapplication -b', $self->pseudoCmdMode);
            }

            # Update the entry box
            $entry->set_text($axmud::CLIENT->browserCmd);
        });

        $self->addLabel(
            $table,
            '<i>System command to contact someone with an email application (%s is the email'
            . ' address to use)</i>',
            1, 12, 3, 4);

        my $entry2 = $self->addEntry($table, undef, TRUE,
            1, 10, 4, 5);
        $entry2->set_text($axmud::CLIENT->emailCmd);

        my $button2 = $self->addButton($table,
            'Set', 'Set the system command to run an email application', undef,
            10, 12, 4, 5);
        $button2->signal_connect('clicked' => sub {

            my $cmd = $entry2->get_text();

            # Set the system command
            if ($cmd) {
                $self->session->pseudoCmd('setapplication -e <' . $cmd . '>', $self->pseudoCmdMode);
            } else {
                $self->session->pseudoCmd('setapplication -e', $self->pseudoCmdMode);
            }

            # Update the entry box
            $entry2->set_text($axmud::CLIENT->audioCmd);
        });

        $self->addLabel(
            $table,
            '<i>System command to open a file in an audio player (%s is the full file path)</i>',
            1, 12, 5, 6);

        my $entry3 = $self->addEntry($table, undef, TRUE,
            1, 10, 6, 7);
        $entry3->set_text($axmud::CLIENT->audioCmd);

        my $button3 = $self->addButton($table,
            'Set', 'Set the system command to run an audio player', undef,
            10, 12, 6, 7);
        $button3->signal_connect('clicked' => sub {

            my $cmd = $entry3->get_text();

            # Set the system command
            if ($cmd) {
                $self->session->pseudoCmd('setapplication -a <' . $cmd . '>', $self->pseudoCmdMode);
            } else {
                $self->session->pseudoCmd('setapplication -a', $self->pseudoCmdMode);
            }

            # Update the entry box
            $entry3->set_text($axmud::CLIENT->audioCmd);
        });

        $self->addLabel(
            $table,
            '<i>System command to open a file in a text editor (%s is the full file path)</i>',
            1, 12, 7, 8);

        my $entry4 = $self->addEntry($table, undef, TRUE,
            1, 10, 8, 9);
        $entry4->set_text($axmud::CLIENT->textEditCmd);

        my $button4 = $self->addButton($table,
            'Set', 'Set the system command to open a text editor', undef,
            10, 12, 8, 9);
        $button4->signal_connect('clicked' => sub {

            my $cmd = $entry4->get_text();

            # Set the system command
            if ($cmd) {
                $self->session->pseudoCmd('setapplication -t <' . $cmd . '>', $self->pseudoCmdMode);
            } else {
                $self->session->pseudoCmd('setapplication -t', $self->pseudoCmdMode);
            }

            # Update the entry box
            $entry4->set_text($axmud::CLIENT->textEditCmd);
        });

        my $button5 = $self->addButton($table,
            'Use default Linux commands',
            'Set system commands commonly used on Linux installations',
            undef,
            1, 4, 9, 10);
        $button5->signal_connect('clicked' => sub {

            # Update external application commands
            $self->session->pseudoCmd('resetapplication -l', $self->pseudoCmdMode);
            # Update widgets
            $entry->set_text($axmud::CLIENT->browserCmd);
            $entry2->set_text($axmud::CLIENT->emailCmd);
            $entry3->set_text($axmud::CLIENT->audioCmd);
            $entry4->set_text($axmud::CLIENT->textEditCmd);
        });

        my $button6 = $self->addButton($table,
            'Use default MS Windows commands',
            'Set system commands commonly used on MS Windows installations',
            undef,
            4, 8, 9, 10);
        $button6->signal_connect('clicked' => sub {

            # Update external application commands
            $self->session->pseudoCmd('resetapplication -w', $self->pseudoCmdMode);
            # Update widgets
            $entry->set_text($axmud::CLIENT->browserCmd);
            $entry2->set_text($axmud::CLIENT->emailCmd);
            $entry3->set_text($axmud::CLIENT->audioCmd);
            $entry4->set_text($axmud::CLIENT->textEditCmd);
        });

        my $button7 = $self->addButton($table,
            'Detect default commands',
            'Set system commands commonly used on the current operation system',
            undef,
            8, 12, 9, 10);
        $button7->signal_connect('clicked' => sub {

            # Update external application commands
            $self->session->pseudoCmd('resetapplication', $self->pseudoCmdMode);
            # Update widgets
            $entry->set_text($axmud::CLIENT->browserCmd);
            $entry2->set_text($axmud::CLIENT->emailCmd);
            $entry3->set_text($axmud::CLIENT->audioCmd);
            $entry4->set_text($axmud::CLIENT->textEditCmd);
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub settings6Tab {

        # Settings6 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my ($min, $max, $string);

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->settings6Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _6', $innerNotebook);

        # Buffer sizes
        $self->addLabel($table, '<b>Buffer/textview sizes and system delays</b>',
            0, 12, 0, 1);

        $min = $axmud::CLIENT->constMinBufferSize;
        $max = $axmud::CLIENT->constMaxBufferSize;
        $string = 'range ' . $min . '-' . $max;

        $self->addLabel(
            $table,
            '<i>Size of display buffers (stores text received from the world, ' . $string
            . ', recommended size ' . $axmud::CLIENT->constDisplayBufferSize . ')</i>',
            1, 12, 1, 2);

        my $entry = $self->addEntryWithIcon($table, undef, 'int', $min, $max,
            1, 8, 2, 3);
        $entry->set_text($axmud::CLIENT->customDisplayBufferSize);

        my $button = $self->addButton($table,
            'Set', 'Set the size of display buffers', undef,
            8, 10, 2, 3);
        $button->signal_connect('clicked' => sub {

            my $size = $entry->get_text();

            if ($self->checkEntryIcon($entry)) {

                # Set the buffer size
                $self->session->pseudoCmd('setdisplaybuffer ' . $size, $self->pseudoCmdMode);
            }

            # Update the entry box
            $entry->set_text($axmud::CLIENT->customDisplayBufferSize);
        });

        my $button2 = $self->addButton($table,
            'Reset', 'Reset the size of display buffers', undef,
            10, 12, 2, 3);
        $button2->signal_connect('clicked' => sub {

            # Reset the buffer size
            $self->session->pseudoCmd('setdisplaybuffer', $self->pseudoCmdMode);

            # Update the entry box
            $entry->set_text($axmud::CLIENT->customDisplayBufferSize);
        });

        $self->addLabel(
            $table,
            '<i>Size of instruction buffers (stores processed instructions, ' . $string
            . ', recommended size ' . $axmud::CLIENT->constInstructBufferSize . ')</i>',
            1, 12, 3, 4);

        my $entry2 = $self->addEntryWithIcon($table, undef, 'int', $min, $max,
            1, 8, 4, 5);
        $entry2->set_text($axmud::CLIENT->customInstructBufferSize);

        my $button3 = $self->addButton($table,
            'Set', 'Set the size of instruction buffers', undef,
            8, 10, 4, 5);
        $button3->signal_connect('clicked' => sub {

            my $size = $entry2->get_text();

            if ($self->checkEntryIcon($entry)) {

                # Set the buffer size
                $self->session->pseudoCmd('setinstructionbuffer ' . $size, $self->pseudoCmdMode);
            }

            # Update the entry box
            $entry2->set_text($axmud::CLIENT->customInstructBufferSize);
        });

        my $button4 = $self->addButton($table,
            'Reset', 'Reset the size of instruction buffers', undef,
            10, 12, 4, 5);
        $button4->signal_connect('clicked' => sub {

            # Reset the buffer size
            $self->session->pseudoCmd('setinstructionbuffer', $self->pseudoCmdMode);

            # Update the entry box
            $entry2->set_text($axmud::CLIENT->customInstructBufferSize);
        });

        $self->addLabel(
            $table,
            '<i>Size of world command buffers (stores commands sent to the world, ' . $string
            . ', recommended size ' . $axmud::CLIENT->constCmdBufferSize . ')</i>',
            1, 12, 5, 6);

        my $entry3 = $self->addEntryWithIcon($table, undef, 'int', $min, $max,
            1, 8, 6, 7);
        $entry3->set_text($axmud::CLIENT->customCmdBufferSize);

        my $button5 = $self->addButton($table,
            'Set', 'Set the size of world command buffers', undef,
            8, 10, 6, 7);
        $button5->signal_connect('clicked' => sub {

            my $size = $entry3->get_text();

            if ($self->checkEntryIcon($entry)) {

                # Set the buffer size
                $self->session->pseudoCmd('setcommandbuffer ' . $size, $self->pseudoCmdMode);
            }

            # Update the entry box
            $entry3->set_text($axmud::CLIENT->customCmdBufferSize);
        });

        my $button6 = $self->addButton($table,
            'Reset', 'Reset the size of world command buffers', undef,
            10, 12, 6, 7);
        $button6->signal_connect('clicked' => sub {

            # Reset the buffer size
            $self->session->pseudoCmd('setcommandbuffer', $self->pseudoCmdMode);

            # Update the entry box
            $entry3->set_text($axmud::CLIENT->customCmdBufferSize);
        });

        $self->addLabel(
            $table,
            '<i>Size of textviews (used only when a maximum size is required, recommended size'
            . ' 10000, use 0 for no maximum)</i>',
            1, 12, 8, 9);

        my $entry4 = $self->addEntryWithIcon($table, undef, 'int', 0, $max,
            1, 8, 9, 10);
        $entry4->set_text($axmud::CLIENT->customTextBufferSize);

        my $button7 = $self->addButton($table,
            'Set', 'Set the textview size', undef,
            8, 10, 9, 10);
        $button7->signal_connect('clicked' => sub {

            my $size = $entry4->get_text();

            if ($self->checkEntryIcon($entry)) {

                # Set the textview size
                $self->session->pseudoCmd('settextview ' . $size, $self->pseudoCmdMode);
            }

            # Update the entry box
            $entry4->set_text($axmud::CLIENT->customTextBufferSize);
        });

        my $button8 = $self->addButton($table,
            'Reset', 'Reset the textview size', undef,
            10, 12, 9, 10);
        $button8->signal_connect('clicked' => sub {

            # Reset the textview size
            $self->session->pseudoCmd('settextview', $self->pseudoCmdMode);

            # Update the entry box
            $entry4->set_text($axmud::CLIENT->customTextBufferSize);
        });

        $self->addLabel(
            $table,
            '<i>Time to wait (in seconds) before treating received text as a prompt (range 0.1 - 5,'
            . ' recommended delay 0.5)</i>',
            1, 12, 10, 11);

        my $entry5 = $self->addEntryWithIcon($table, undef, 'float', 0.1, 5,
            1, 8, 11, 12);
        $entry5->set_text($axmud::CLIENT->promptWaitTime);

        my $button9 = $self->addButton($table,
            'Set', 'Set the system prompt delay', undef,
            8, 10, 11, 12);
        $button9->signal_connect('clicked' => sub {

            my $interval = $entry5->get_text();

            if ($self->checkEntryIcon($entry5)) {

                # Set the system prompt delay
                $self->session->pseudoCmd('setdelay -p ' . $interval, $self->pseudoCmdMode);

                # Update the entry box
                $entry5->set_text($axmud::CLIENT->promptWaitTime);
            }
        });

        my $button10 = $self->addButton($table,
            'Reset', 'Reset the system prompt delay', undef,
            10, 12, 11, 12);
        $button10->signal_connect('clicked' => sub {

            # Set the system prompt delay
            $self->session->pseudoCmd('setdelay -p', $self->pseudoCmdMode);

            # Update the entry box
            $entry5->set_text($axmud::CLIENT->promptWaitTime);
        });

        $self->addLabel(
            $table,
            '<i>Time to wait for a login (in seconds) before displaying a warning (recommended'
            . ' delay 60, use 0 to show immediately)</i>',
            1, 12, 12, 13);

        my $entry6 = $self->addEntryWithIcon($table, undef, 'int', 0, undef,
            1, 8, 13, 14);
        $entry6->set_text($axmud::CLIENT->loginWarningTime);

        my $button11 = $self->addButton($table,
            'Set', 'Set the system login warning delay', undef,
            8, 10, 13, 14);
        $button11->signal_connect('clicked' => sub {

            my $interval = $entry6->get_text();

            if ($self->checkEntryIcon($entry6)) {

                # Set the system login warning delay
                $self->session->pseudoCmd('setdelay -l ' . $interval, $self->pseudoCmdMode);

                # Update the entry box
                $entry6->set_text($axmud::CLIENT->loginWarningTime);
            }
        });

        my $button12 = $self->addButton($table,
            'Reset', 'Reset the system login warning delay', undef,
            10, 12, 13, 14);
        $button12->signal_connect('clicked' => sub {

            # Set the system prompt delay
            $self->session->pseudoCmd('setdelay -l', $self->pseudoCmdMode);

            # Update the entry box
            $entry6->set_text($axmud::CLIENT->loginWarningTime);
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub settings7Tab {

        # Settings7 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->settings7Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _7', $innerNotebook);

        # Telnet options
        $self->addLabel($table, '<b>Telnet option negotiations</b>',
            0, 6, 0, 1);

        my $checkButton = $self->addCheckButton($table, undef, TRUE,
            1, 2, 1, 2);
        $checkButton->set_active($axmud::CLIENT->useEchoFlag);
        $checkButton->signal_connect('toggled' => sub {

            $axmud::CLIENT->toggle_telnetOption('echo', $checkButton->get_active());
        });

        $self->addLabel($table, 'Allow ECHO (hide passwords, etc)',
            2, 6, 1, 2);

        my $checkButton2 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 2, 3);
        $checkButton2->set_active($axmud::CLIENT->useSgaFlag);
        $checkButton2->signal_connect('toggled' => sub {

            $axmud::CLIENT->toggle_telnetOption('sga', $checkButton2->get_active());
        });

        $self->addLabel($table, 'Allow SGA (Suppress Go Ahead)',
            2, 6, 2, 3);

        my $checkButton3 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 3, 4);
        $checkButton3->set_active($axmud::CLIENT->useTTypeFlag);
        $checkButton3->signal_connect('toggled' => sub {

            $axmud::CLIENT->toggle_telnetOption('ttype', $checkButton3->get_active());
        });

        $self->addLabel($table, 'Allow TTYPE (detect Terminal Type)',
            2, 6, 3, 4);

        my $checkButton4 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 4, 5);
        $checkButton4->set_active($axmud::CLIENT->useEorFlag);
        $checkButton4->signal_connect('toggled' => sub {

            $axmud::CLIENT->toggle_telnetOption('eor', $checkButton4->get_active());
        });

        $self->addLabel($table, 'Allow EOR (negotiate End Of Record)',
            2, 6, 4, 5);

        my $checkButton5 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 5, 6);
        $checkButton5->set_active($axmud::CLIENT->useNawsFlag);
        $checkButton5->signal_connect('toggled' => sub {

            $axmud::CLIENT->toggle_telnetOption('naws', $checkButton5->get_active());
        });

        $self->addLabel($table, 'Allow NAWS (Negotiate About Window Size)',
            2, 6, 5, 6);

        my $checkButton6 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 6, 7);
        $checkButton6->set_active($axmud::CLIENT->useNewEnvironFlag);
        $checkButton6->set_sensitive(FALSE);
        $self->addLabel($table, '<i>Allow NEW-ENVIRON (New Environment option)</i>',
            2, 6, 6, 7);

        my $checkButton7 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 7, 8);
        $checkButton7->set_active($axmud::CLIENT->useCharSetFlag);
        $checkButton7->set_sensitive(FALSE);
        $self->addLabel($table, '<i>Allow CHARSET (Character Set and translation)</i>',
            2, 6, 7, 8);

        $self->addLabel($table, '<b>OSC colour palette</b>',
            0, 6, 8, 9);
        my $checkButton8 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 9, 10);
        $checkButton8->set_active($axmud::CLIENT->oscPaletteFlag);
        $checkButton8->signal_connect('toggled' => sub {

            if (
                ($checkButton8->get_active && ! $axmud::CLIENT->oscPaletteFlag)
                || (! $checkButton8->get_active && $axmud::CLIENT->oscPaletteFlag)
            ) {
                $self->session->pseudoCmd('togglepalette',  $self->pseudoCmdMode);
            }
        });
        $self->addLabel($table, 'Allow use of OSC colour palette sequences',
            2, 6, 9, 10);

        # Terminal type negotiations
        $self->addLabel($table, '<b>Terminal type negotiations</b>',
            7, 13, 0, 1);

        $self->addLabel(
            $table,
            '<i>Custom client name (if not set, TTYPE/MTTS/MXP use \'' . $axmud::NAME_SHORT
            . '\')</i>',
            8, 13, 1, 2);
        my $entry = $self->addEntry($table, undef, TRUE,
            8, 13, 2, 3);
        $entry->set_text($axmud::CLIENT->customClientName);
        $entry->signal_connect('changed' => sub {

            my $name = $entry->get_text();

            # (Default value is an empty string)
            if (! $name) {

                $name = '';
            }

            $axmud::CLIENT->set_customClientName($name);
        });

        $self->addLabel(
            $table,
            '<i>Custom client version (if not set, not used by TTYPE/MTTS/MXP)</i>',
            8, 13, 3, 4);
        my $entry2 = $self->addEntry($table, undef, TRUE,
            8, 13, 4, 5);
        $entry2->set_text($axmud::CLIENT->customClientVersion);
        $entry2->signal_connect('changed' => sub {

            my $version = $entry2->get_text();

            # (Default value is an empty string)
            if (! $version) {

                $version = '';
            }

            $axmud::CLIENT->set_customClientVersion($version);
        });

        # TTYPE (not MTTS) negotiations
        $self->addLabel($table, '<i>TTYPE (not MTTS) negotiations (*also used by MXP)</i>',
            8, 13, 5, 6);

        my ($group, $radioButton) = $self->addRadioButton(
            $table, undef, '*Send nothing', undef,
            undef,      # IV set to this value when toggled
            TRUE,       # Sensitive widget
            8, 13, 6, 7);
        if ($axmud::CLIENT->termTypeMode eq 'send_nothing') {

            $radioButton->set_active(TRUE);
        }
        $radioButton->signal_connect('toggled' => sub {

            if ($radioButton->get_active()) {

                $axmud::CLIENT->set_termTypeMode('send_nothing');
            }
        });

        my ($group2, $radioButton2) = $self->addRadioButton(
            $table, $group, '*Sent client name, then usual list', undef, undef, TRUE,
            8, 13, 7, 8);
        if ($axmud::CLIENT->termTypeMode eq 'send_client') {

            $radioButton2->set_active(TRUE);
        }
        $radioButton2->signal_connect('toggled' => sub {

            if ($radioButton2->get_active()) {

                $axmud::CLIENT->set_termTypeMode('send_client');
            }
        });

        my ($group3, $radioButton3) = $self->addRadioButton(
            $table, $group2, '*Send client/name version, then usual list', undef, undef, TRUE,
            8, 13, 8, 9);
        if ($axmud::CLIENT->termTypeMode eq 'send_client_version') {

            $radioButton3->set_active(TRUE);
        }
        $radioButton3->signal_connect('toggled' => sub {

            if ($radioButton3->get_active()) {

                $axmud::CLIENT->set_termTypeMode('send_client_version');
            }
        });

        my ($group4, $radioButton4) = $self->addRadioButton(
            $table, $group3, '*Send custom client name/version, then usual list',
            undef, undef, TRUE,
            8, 13, 9, 10);
        if ($axmud::CLIENT->termTypeMode eq 'send_custom_client') {

            $radioButton4->set_active(TRUE);
        }
        $radioButton4->signal_connect('toggled' => sub {

            if ($radioButton4->get_active()) {

                $axmud::CLIENT->set_termTypeMode('send_custom_client');
            }
        });

        my ($group5, $radioButton5) = $self->addRadioButton(
            $table, $group4, 'Send usual terminal type list', undef, undef, TRUE,
            8, 13, 10, 11);
        if ($axmud::CLIENT->termTypeMode eq 'send_default') {

            $radioButton5->set_active(TRUE);
        }
        $radioButton5->signal_connect('toggled' => sub {

            if ($radioButton5->get_active()) {

                $axmud::CLIENT->set_termTypeMode('send_default');
            }
        });

        my ($group6, $radioButton6) = $self->addRadioButton(
            $table, $group5, 'Send \'unknown\'', undef, undef, TRUE,
            8, 13, 11, 12);
        if ($axmud::CLIENT->termTypeMode eq 'send_unknown') {

            $radioButton6->set_active(TRUE);
        }
        $radioButton6->signal_connect('toggled' => sub {

            if ($radioButton6->get_active()) {

                $axmud::CLIENT->set_termTypeMode('send_unknown');
            }
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub settings8Tab {

        # Settings8 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->settings8Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _8', $innerNotebook);

        # (Need just a little extra space to make everything fit)
        $table->set_col_spacings($self->spacingPixels - 1);
        $table->set_row_spacings($self->spacingPixels - 1);

        # MUD protocols
        $self->addLabel($table, '<b>MUD protocols</b>',
            0, 6, 0, 1);

        my $checkButton = $self->addCheckButton($table, undef, TRUE,
            1, 2, 1, 2);
        $checkButton->set_active($axmud::CLIENT->useMsdpFlag);
        $checkButton->signal_connect('toggled' => sub {

            $axmud::CLIENT->toggle_mudProtocol('msdp', $checkButton->get_active());
        });

        $self->addLabel($table, 'Allow MSDP (Mud Server Data Protocol)',
            2, 6, 1, 2);

        my $checkButton2 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 2, 3);
        $checkButton2->set_active($axmud::CLIENT->useMsspFlag);
        $checkButton2->signal_connect('toggled' => sub {

            $axmud::CLIENT->toggle_mudProtocol('mssp', $checkButton2->get_active());
        });

        $self->addLabel($table, 'Allow MSSP (Mud Server Status Protocol)',
            2, 6, 2, 3);

        my $checkButton3 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 3, 4);
        $checkButton3->set_active($axmud::CLIENT->useMccpFlag);
        $checkButton3->signal_connect('toggled' => sub {

            $axmud::CLIENT->toggle_mudProtocol('mccp', $checkButton3->get_active());
        });

        $self->addLabel($table, 'Allow MCCP (Mud Client Compression Protocol)',
            2, 6, 3, 4);

        my $checkButton4 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 4, 5);
        $checkButton4->set_active($axmud::CLIENT->useZmpFlag);
        $checkButton4->set_sensitive(FALSE);
        $self->addLabel($table, '<i>Allow ZMP (Zenith Mud Protocol)</i>',
            2, 6, 4, 5);

        my $checkButton5 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 5, 6);
        $checkButton5->set_active($axmud::CLIENT->useAard102Flag);
        $checkButton5->set_sensitive(FALSE);
        $self->addLabel($table, '<i>Allow AARDWOLF-102 (Aardwolf 102 channel)</i>',
            2, 6, 5, 6);

        my $checkButton6 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 6, 7);
        $checkButton6->set_active($axmud::CLIENT->useAtcpFlag);
        $checkButton6->signal_connect('toggled' => sub {

            $axmud::CLIENT->toggle_mudProtocol('atcp', $checkButton6->get_active());
        });

        $self->addLabel($table, 'Allow ATCP (Achaea Telnet Client Protocol)',
            2, 6, 6, 7);

        my $checkButton7 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 7, 8);
        $checkButton7->set_active($axmud::CLIENT->useGmcpFlag);
        $checkButton7->signal_connect('toggled' => sub {

            $axmud::CLIENT->toggle_mudProtocol('gmcp', $checkButton7->get_active());
        });

        $self->addLabel($table, 'Allow GMCP (Generic MUD Communication Protocol)',
            2, 6, 7, 8);

        my $checkButton8 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 8, 9);
        $checkButton8->set_active($axmud::CLIENT->useMttsFlag);
        $checkButton8->signal_connect('toggled' => sub {

            $axmud::CLIENT->toggle_mudProtocol('mtts', $checkButton8->get_active());
        });

        $self->addLabel($table, 'Allow MTTS (Mud Terminal Type Standard)',
            2, 6, 8, 9);

        my $checkButton9 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 9, 10);
        $checkButton9->set_active($axmud::CLIENT->useMcpFlag);
        $checkButton9->set_sensitive(FALSE);
        $self->addLabel($table, '<i>Allow MCP (Mud Client Protocol)</i>',
            2, 6, 9, 10);

        my $checkButton10 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 10, 11);
        $checkButton10->set_active($axmud::CLIENT->useMspFlag);
        # (->signal_connect appears below)

        $self->addLabel($table, 'Allow MSP (Mud Sound Protocol)',
            2, 6, 10, 11);

        my $checkButton11 = $self->addCheckButton($table, undef, TRUE,
            2, 3, 11, 12);
        $checkButton11->set_active($axmud::CLIENT->allowMspMultipleFlag);
        $checkButton11->signal_connect('toggled' => sub {

            $axmud::CLIENT->toggle_mspFlag('multiple', $checkButton11->get_active());
        });

        $self->addLabel($table, '<i>Allow MSP sounds to play concurrently</i>',
            3, 6, 11, 12);

        my $checkButton12 = $self->addCheckButton($table, undef, TRUE,
            2, 3, 12, 13);
        $checkButton12->set_active($axmud::CLIENT->allowMspLoadSoundFlag);
        $checkButton12->signal_connect('toggled' => sub {

            $axmud::CLIENT->toggle_mspFlag('load', $checkButton12->get_active());
        });

        $self->addLabel($table, '<i>Automatically download MSP sound files</i>',
            3, 6, 12, 13);

        my $checkButton13 = $self->addCheckButton($table, undef, TRUE,
            2, 3, 13, 14);
        $checkButton13->set_active($axmud::CLIENT->allowMspFlexibleFlag);
        $checkButton13->signal_connect('toggled' => sub {

            $axmud::CLIENT->toggle_mspFlag('flexible', $checkButton13->get_active());
        });

        $self->addLabel($table, '<i>Allow flexible tag placement (not recommended)</i>',
            3, 6, 13, 14);

        # (right column)
        my $checkButton14 = $self->addCheckButton($table, undef, TRUE,
            7, 8, 1, 2);
        $checkButton14->set_active($axmud::CLIENT->usePuebloFlag);
        $checkButton14->signal_connect('toggled' => sub {

            $axmud::CLIENT->toggle_mudProtocol('pueblo', $checkButton14->get_active());
        });

        $self->addLabel($table, 'Allow Pueblo (partial support)',
            8, 12, 1, 2);

        my $checkButton15 = $self->addCheckButton($table, undef, TRUE,
            7, 8, 2, 3);
        $checkButton15->set_active($axmud::CLIENT->useMxpFlag);
        # (->signal_connect appears below)

        $self->addLabel($table, 'Allow MXP (MUD eXtension Protocol)',
            8, 12, 2, 3);

        my $checkButton16 = $self->addCheckButton($table, undef, TRUE,
            8, 9, 3, 4);
        $checkButton16->set_active($axmud::CLIENT->allowMxpFontFlag);
        $checkButton16->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_allowMxpFlag('font', $checkButton16->get_active());
        });

        $self->addLabel($table, '<i>Allow MXP to change fonts</i>',
            9, 12, 3, 4);

        my $checkButton17 = $self->addCheckButton($table, undef, TRUE,
            8, 9, 4, 5);
        $checkButton17->set_active($axmud::CLIENT->allowMxpImageFlag);
        # (->signal_connect appears below)

        $self->addLabel($table, '<i>Allow MXP to display images</i>',
            9, 12, 4, 5);

        my $checkButton18 = $self->addCheckButton($table, undef, TRUE,
            8, 9, 5, 6);
        $checkButton18->set_active($axmud::CLIENT->allowMxpLoadImageFlag);
        $checkButton18->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_allowMxpFlag('load_image', $checkButton18->get_active());
        });

        $self->addLabel($table, '<i>Allow MXP to download image files</i>',
            9, 12, 5, 6);

        my $checkButton19 = $self->addCheckButton($table, undef, TRUE,
            8, 9, 6, 7);
        $checkButton19->set_active($axmud::CLIENT->allowMxpFilterImageFlag);
        $checkButton19->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_allowMxpFlag('filter_image', $checkButton19->get_active());
        });

        $self->addLabel($table, '<i>Allow MXP to use world\'s own graphics formats</i>',
            9, 12, 6, 7);

        my $checkButton20 = $self->addCheckButton($table, undef, TRUE,
            8, 9, 7, 8);
        $checkButton20->set_active($axmud::CLIENT->allowMxpSoundFlag);
        # (->signal_connect appears below)

        $self->addLabel($table, '<i>Allow MXP to play sound/music files</i>',
            9, 12, 7, 8);

        my $checkButton21 = $self->addCheckButton($table, undef, TRUE,
            8, 9, 8, 9);
        $checkButton21->set_active($axmud::CLIENT->allowMxpLoadSoundFlag);
        $checkButton21->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_allowMxpFlag('load_sound', $checkButton21->get_active());
        });

        $self->addLabel($table, '<i>Allow MXP to download sound/music files</i>',
            9, 12, 8, 9);

        my $checkButton22 = $self->addCheckButton($table, undef, TRUE,
            8, 9, 9, 10);
        $checkButton22->set_active($axmud::CLIENT->allowMxpGaugeFlag);
        $checkButton22->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_allowMxpFlag('gauge', $checkButton22->get_active());
        });

        $self->addLabel($table, '<i>Allow MXP to display gauges/status bars</i>',
            9, 12, 9, 10);

        my $checkButton23 = $self->addCheckButton($table, undef, TRUE,
            8, 9, 10, 11);
        $checkButton23->set_active($axmud::CLIENT->allowMxpFrameFlag);
        $checkButton23->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_allowMxpFlag('frame', $checkButton23->get_active());
        });

        $self->addLabel($table, '<i>Allow MXP to use frames</i>',
            9, 12, 10, 11);

        my $checkButton24 = $self->addCheckButton($table, undef, TRUE,
            8, 9, 11, 12);
        $checkButton24->set_active($axmud::CLIENT->allowMxpInteriorFlag);
        $checkButton24->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_allowMxpFlag('interior', $checkButton24->get_active());
        });

        $self->addLabel($table, '<i>Allow MXP to use frames inside \'main\' windows</i>',
            9, 12, 11, 12);

        my $checkButton25 = $self->addCheckButton($table, undef, TRUE,
            8, 9, 12, 13);
        $checkButton25->set_active($axmud::CLIENT->allowMxpCrosslinkFlag);
        $checkButton25->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_allowMxpFlag('crosslink', $checkButton25->get_active());
        });

        $self->addLabel($table, '<i>Allow MXP to crosslink to new servers</i>',
            9, 12, 12, 13);

        my $checkButton26 = $self->addCheckButton($table, undef, TRUE,
            8, 9, 13, 14);
        $checkButton26->set_active($axmud::CLIENT->allowMxpRoomFlag);
        $checkButton26->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_allowMxpFlag('room', $checkButton26->get_active());
        });

        $self->addLabel($table, '<i>Allow Locator task to use MXP room data</i>',
            9, 12, 13, 14);

        # Sensitise/desensitise buttons
        $self->settings8Tab_sensitiseButtons(
            $checkButton10, $checkButton11, $checkButton12, $checkButton15, $checkButton16,
            $checkButton17, $checkButton18, $checkButton19, $checkButton20, $checkButton21,
            $checkButton22, $checkButton23, $checkButton24, $checkButton25, $checkButton26,
        );

        # (->signal_connects from above)
        $checkButton10->signal_connect('toggled' => sub {

            # Sensitise/desensitise buttons
            $self->settings8Tab_sensitiseButtons(
                $checkButton10, $checkButton11, $checkButton12, $checkButton15, $checkButton16,
                $checkButton17, $checkButton18, $checkButton19, $checkButton20, $checkButton21,
                $checkButton22, $checkButton23, $checkButton24, $checkButton25, $checkButton26,
            );

            $axmud::CLIENT->toggle_mudProtocol('msp', $checkButton10->get_active());
        });

        $checkButton15->signal_connect('toggled' => sub {

            # Sensitise/desensitise buttons
            $self->settings8Tab_sensitiseButtons(
                $checkButton10, $checkButton11, $checkButton12, $checkButton15, $checkButton16,
                $checkButton17, $checkButton18, $checkButton19, $checkButton20, $checkButton21,
                $checkButton22, $checkButton23, $checkButton24, $checkButton25, $checkButton26,
            );

            $axmud::CLIENT->toggle_mudProtocol('mxp', $checkButton15->get_active());
        });

        $checkButton17->signal_connect('toggled' => sub {

            if (! $checkButton17->get_active()) {

                # (Only send an unsoliciated <SUPPORTS> tag once)
                $axmud::CLIENT->set_mxpPreventSupportFlag(TRUE);
                $checkButton18->set_active(FALSE);
                $checkButton19->set_active(FALSE);
                $axmud::CLIENT->set_mxpPreventSupportFlag(FALSE);
                $axmud::CLIENT->set_allowMxpFlag('image', FALSE);

            } else {

                $checkButton18->set_sensitive(TRUE);
                $checkButton19->set_sensitive(TRUE);
                $axmud::CLIENT->set_allowMxpFlag('image', TRUE);
            }

            # Sensitise/desensitise buttons
            $self->settings8Tab_sensitiseButtons(
                $checkButton10, $checkButton11, $checkButton12, $checkButton15, $checkButton16,
                $checkButton17, $checkButton18, $checkButton19, $checkButton20, $checkButton21,
                $checkButton22, $checkButton23, $checkButton24, $checkButton25, $checkButton26,
            );
        });

        $checkButton20->signal_connect('toggled' => sub {

            if (! $checkButton20->get_active()) {

                # (Only send an unsoliciated <SUPPORTS> tag once)
                $axmud::CLIENT->set_mxpPreventSupportFlag(TRUE);
                $checkButton21->set_active(FALSE);
                $axmud::CLIENT->set_mxpPreventSupportFlag(FALSE);
                $axmud::CLIENT->set_allowMxpFlag('sound', FALSE);

            } else {

                $checkButton21->set_sensitive(TRUE);
                $axmud::CLIENT->set_allowMxpFlag('sound', TRUE);
            }

            # Sensitise/desensitise buttons
            $self->settings8Tab_sensitiseButtons(
                $checkButton10, $checkButton11, $checkButton12, $checkButton15, $checkButton16,
                $checkButton17, $checkButton18, $checkButton19, $checkButton20, $checkButton21,
                $checkButton22, $checkButton23, $checkButton24, $checkButton25, $checkButton26,
            );
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub settings8Tab_sensitiseButtons {

        # Sensitises/desensitises various buttons in the tab, depending on current conditions
        #
        # Expected arguments
        #   $checkButton10, $checkButton11, $checkButton12, $checkButton15, $checkButton16,
        #   $checkButton17, $checkButton18, $checkButton19, $checkButton20, $checkButton21,
        #   $checkButton22, $checkButton23, $checkButton24, $checkButton25, $checkButton26,
        #       - The affected buttons
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my (
            $self, $checkButton10, $checkButton11, $checkButton12, $checkButton15, $checkButton16,
            $checkButton17, $checkButton18, $checkButton19, $checkButton20, $checkButton21,
            $checkButton22, $checkButton23, $checkButton24, $checkButton25, $checkButton26, $check
        ) = @_;

        # Local variables
        my @dataList;

        # Check for improper arguments
        if (
            ! defined $checkButton10 || ! defined $checkButton11 || ! defined $checkButton12
            || ! defined $checkButton15 || ! defined $checkButton16 || ! defined $checkButton17
            || ! defined $checkButton18 || ! defined $checkButton19 || ! defined $checkButton20
            || ! defined $checkButton21 || ! defined $checkButton22 || ! defined $checkButton23
            || ! defined $checkButton24 || ! defined $checkButton25 || ! defined $checkButton26
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->settings8Tab_sensitiseButtons',
                @_,
            );
        }

        if (! $checkButton10->get_active()) {

            $checkButton11->set_sensitive(FALSE);
            $checkButton12->set_sensitive(FALSE);

        } else {

            $checkButton11->set_sensitive(TRUE);
            $checkButton12->set_sensitive(TRUE);
        }

        if (! $checkButton15->get_active()) {

            $checkButton16->set_sensitive(FALSE);
            $checkButton17->set_sensitive(FALSE);
            $checkButton18->set_sensitive(FALSE);
            $checkButton19->set_sensitive(FALSE);
            $checkButton20->set_sensitive(FALSE);
            $checkButton21->set_sensitive(FALSE);
            $checkButton22->set_sensitive(FALSE);
            $checkButton23->set_sensitive(FALSE);
            $checkButton24->set_sensitive(FALSE);
            $checkButton25->set_sensitive(FALSE);
            $checkButton26->set_sensitive(FALSE);

        } else {

            $checkButton16->set_sensitive(TRUE);
            $checkButton17->set_sensitive(TRUE);

            if (! $checkButton17->get_active()) {
                $checkButton18->set_sensitive(FALSE);
                $checkButton19->set_sensitive(FALSE);
            } else {
                $checkButton18->set_sensitive(TRUE);
                $checkButton19->set_sensitive(TRUE);
            }

            $checkButton20->set_sensitive(TRUE);

            if (! $checkButton20->get_active()) {
                $checkButton21->set_sensitive(FALSE);
            } else {
                $checkButton21->set_sensitive(TRUE);
            }

            $checkButton22->set_sensitive(TRUE);
            $checkButton23->set_sensitive(TRUE);
            $checkButton24->set_sensitive(TRUE);
            $checkButton25->set_sensitive(TRUE);
            $checkButton26->set_sensitive(TRUE);
        }

        return 1;
    }

    sub settings9Tab {

        # Settings9 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->settings9Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _9', $innerNotebook);

        # Debugging flags (telnet options/negotiations)
        $self->addLabel($table, '<b>Debugging flags (telnet options/negotiations)</b>',
            0, 12, 0, 1);

        my $checkButton = $self->addCheckButton($table, undef, TRUE,
            1, 2, 1, 2);
        $checkButton->set_active($axmud::CLIENT->debugTelnetFlag);
        $checkButton->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugTelnetFlag', $checkButton->get_active());
        });

        $self->addLabel(
            $table,
            'Show debug messages while negotiating telnet options/MUD protocols',
            2, 12, 1, 2);

        my $checkButton2 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 2, 3);
        $checkButton2->set_active($axmud::CLIENT->debugTelnetMiniFlag);
        $checkButton2->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugTelnetMiniFlag', $checkButton2->get_active());
        });

        $self->addLabel(
            $table,
            'Show short debug messages while negotiating telnet options/MUD protocols',
            2, 12, 2, 3);

        my $checkButton3 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 3, 4);
        $checkButton3->set_active($axmud::CLIENT->debugTelnetLogFlag);
        $checkButton3->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugTelnetLogFlag', $checkButton3->get_active());
        });

        $self->addLabel(
            $table,
            'Tell telnet library to write its own negotiation logfile in ' . $axmud::SCRIPT
            . ' base directory',
            2, 12, 3, 4);

        my $checkButton4 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 4, 5);
        $checkButton4->set_active($axmud::CLIENT->debugMsdpFlag);
        $checkButton4->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugMsdpFlag', $checkButton4->get_active());
        });

        $self->addLabel(
            $table,
            'Show debug messages when MSDP data is sent to Status/Locator tasks',
            2, 12, 4, 5);

        my $checkButton5 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 5, 6);
        $checkButton5->set_active($axmud::CLIENT->debugMxpFlag);
        $checkButton5->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugMxpFlag', $checkButton5->get_active());
        });

        $self->addLabel(
            $table,
            'Show debug messages when invalid MXP tags are received',
            2, 12, 5, 6);

        my $checkButton6 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 6, 7);
        $checkButton6->set_active($axmud::CLIENT->debugMxpCommentFlag);
        $checkButton6->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugMxpCommentFlag', $checkButton6->get_active());
        });

        $self->addLabel(
            $table,
            'Show debug messages when MXP comments are received',
            2, 12, 6, 7);

        my $checkButton7 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 7, 8);
        $checkButton7->set_active($axmud::CLIENT->debugPuebloFlag);
        $checkButton7->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugPuebloFlag', $checkButton7->get_active());
        });

        $self->addLabel(
            $table,
            'Show debug messages when invalid Pueblo tags are received',
            2, 12, 7, 8);

        my $checkButton8 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 8, 9);
        $checkButton8->set_active($axmud::CLIENT->debugPuebloCommentFlag);
        $checkButton8->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugPuebloCommentFlag', $checkButton8->get_active());
        });

        $self->addLabel(
            $table,
            'Show debug messages when Pueblo comments are received',
            2, 12, 8, 9);

        my $checkButton9 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 9, 10);
        $checkButton9->set_active($axmud::CLIENT->debugAtcpFlag);
        $checkButton9->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugAtcpFlag', $checkButton9->get_active());
        });

        $self->addLabel(
            $table,
            'Show debug messages for incoming ATCP data',
            2, 12, 9, 10);

        my $checkButton10 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 10, 11);
        $checkButton10->set_active($axmud::CLIENT->debugGmcpFlag);
        $checkButton10->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugGmcpFlag', $checkButton10->get_active());
        });

        $self->addLabel(
            $table,
            'Show debug messages for incoming GMCP data',
            2, 12, 10, 11);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub settings10Tab {

        # Settings10 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->settings10Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page 1_0', $innerNotebook);

        # Debugging flags
        $self->addLabel($table, '<b>Debugging flags (other)</b>',
            0, 12, 0, 1);

        my $checkButton = $self->addCheckButton($table, undef, TRUE,
            1, 2, 1, 2);
        $checkButton->set_active($axmud::CLIENT->debugLineNumsFlag);
        $checkButton->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugLineNumsFlag', $checkButton->get_active());
        });

        $self->addLabel(
            $table, '\'Main\' window shows explicit display buffer line numbers',
            2, 12, 1, 2);

        my $checkButton2 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 2, 3);
        $checkButton2->set_active($axmud::CLIENT->debugLineTagsFlag);
        $checkButton2->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugLineTagsFlag', $checkButton2->get_active());
        });

        $self->addLabel(
            $table, '\'Main\' window shows explicit ' . $axmud::SCRIPT . ' colour/style tags',
            2, 12, 2, 3);

        my $checkButton3 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 3, 4);
        $checkButton3->set_active($axmud::CLIENT->debugLocatorFlag);
        # ( ->signal_connect appears below)

        $self->addLabel(
            $table, 'Locator task shows debug messages when it interprets room statements',
            2, 12, 3, 4);

        my $checkButton4 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 4, 5);
        $checkButton4->set_active($axmud::CLIENT->debugMaxLocatorFlag);

        $self->addLabel(
            $table,
            'Locator task shows <i>extensive</i> debug messages when it interprets room statements',
            2, 12, 4, 5);

        # (->signal_connects etc for the buttons above)
        if (! $axmud::CLIENT->debugLocatorFlag) {

            $checkButton4->set_sensitive(FALSE);
        }

        $checkButton3->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugLocatorFlag', $checkButton3->get_active());

            if (! $axmud::CLIENT->debugLocatorFlag) {

                # Turning off this button, also turns off the one immediately below (and
                #   desensitises it)
                $checkButton4->set_active(FALSE);
                $checkButton4->set_sensitive(FALSE);

            } else {

                # Re-sensitise the button below
                $checkButton4->set_sensitive(TRUE);
            }
        });

        $checkButton4->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugMaxLocatorFlag', $checkButton4->get_active());
        });

        my $checkButton5 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 5, 6);
        $checkButton5->set_active($axmud::CLIENT->debugMoveListFlag);
        $checkButton5->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugMoveListFlag', $checkButton5->get_active());
        });

        $self->addLabel(
            $table,
            'Locator task shows a summary of the number of room statements it\'s expecting',
            2, 12, 5, 6);

        my $checkButton6 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 6, 7);
        $checkButton6->set_active($axmud::CLIENT->debugParseObjFlag);
        $checkButton6->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugParseObjFlag', $checkButton6->get_active());
        });

        $self->addLabel(
            $table, 'Object parsing routines shows debug messages when parsing text',
            2, 12, 6, 7);

        my $checkButton7 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 7, 8);
        $checkButton7->set_active($axmud::CLIENT->debugCompareObjFlag);
        $checkButton7->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugCompareObjFlag', $checkButton7->get_active());
        });

        $self->addLabel(
            $table,
            'Object comparison routines shows debug messages when comparing objects',
            2, 12, 7, 8);

        my $checkButton8 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 8, 9);
        $checkButton8->set_active($axmud::CLIENT->debugExplainPluginFlag);
        $checkButton8->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugExplainPluginFlag', $checkButton8->get_active());
        });

        $self->addLabel(
            $table,
            'Show debug messages when a plugin fails to load, explaining the reason why',
            2, 12, 8, 9);

        my $checkButton9 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 9, 10);
        $checkButton9->set_active($axmud::CLIENT->debugCheckIVFlag);
        $checkButton9->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugCheckIVFlag', $checkButton9->get_active());
        });

        $self->addLabel(
            $table,
            'Show debug messages when any code accesses a non-existent property (IV)',
            2, 12, 9, 10);

        my $checkButton10 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 10, 11);
        $checkButton10->set_active($axmud::CLIENT->debugTableFitFlag);
        $checkButton10->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugTableFitFlag', $checkButton10->get_active());
        });

        $self->addLabel(
            $table,
            'Show error messages when table objects can\'t be added/resized in their windows',
            2, 12, 10, 11);

        my $checkButton11 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 11, 12);
        $checkButton11->set_active($axmud::CLIENT->debugTrapErrorFlag);
        $checkButton11->signal_connect('toggled' => sub {

            $axmud::CLIENT->set_debugFlag('debugTrapErrorFlag', $checkButton11->get_active());
        });

        $self->addLabel(
            $table,
            'Trap Perl errors/warnings and display them in the \'main\' window',
            2, 12, 11, 12);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub settings11Tab {

        # Settings11 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->settings11Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page 11', $innerNotebook);

        # Other flags
        $self->addLabel($table, '<b>Other flags</b>',
            0, 12, 0, 1);

        my $checkButton = $self->addCheckButton($table, undef, TRUE,
            1, 2, 1, 2);
        $checkButton->set_active($axmud::CLIENT->useScrollKeysFlag);
        $checkButton->signal_connect('toggled' => sub {

            if (
                ($checkButton->get_active && ! $axmud::CLIENT->useScrollKeysFlag)
                || (! $checkButton->get_active && $axmud::CLIENT->useScrollKeysFlag)
            ) {
                $self->session->pseudoCmd('togglewindowkey -s',  $self->pseudoCmdMode);
            }
        });
        $self->addLabel(
            $table,
            'Use \'page up\' / \'page down\' / \'home\' / \'end\' keys to scroll textviews',
            2, 12, 1, 2);

        my $checkButton2 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 2, 3);
        $checkButton2->set_active($axmud::CLIENT->smoothScrollKeysFlag);
        $checkButton2->signal_connect('toggled' => sub {

            if (
                ($checkButton2->get_active && ! $axmud::CLIENT->smoothScrollKeysFlag)
                || (! $checkButton2->get_active && $axmud::CLIENT->smoothScrollKeysFlag)
            ) {
                $self->session->pseudoCmd('togglewindowkey -m',  $self->pseudoCmdMode);
            }
        });
        $self->addLabel(
            $table,
            'When using those keys, don\'t scroll the entire height of the page (smooth scrolling)',
            2, 12, 2, 3);

        my $checkButton3 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 3, 4);
        $checkButton3->set_active($axmud::CLIENT->autoSplitKeysFlag);
        $checkButton3->signal_connect('toggled' => sub {

            if (
                ($checkButton3->get_active && ! $axmud::CLIENT->autoSplitKeysFlag)
                || (! $checkButton3->get_active && $axmud::CLIENT->autoSplitKeysFlag)
            ) {
                $self->session->pseudoCmd('togglewindowkey -p',  $self->pseudoCmdMode);
            }
        });
        $self->addLabel($table, 'Using those keys auto-engages split screen mode',
            2, 12, 3, 4);

        my $checkButton4 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 4, 5);
        $checkButton4->set_active($axmud::CLIENT->useCompleteKeysFlag);
        $checkButton4->signal_connect('toggled' => sub {

            if (
                ($checkButton4->get_active && ! $axmud::CLIENT->useCompleteKeysFlag)
                || (! $checkButton4->get_active && $axmud::CLIENT->useCompleteKeysFlag)
            ) {
                $self->session->pseudoCmd('togglewindowkey -t',  $self->pseudoCmdMode);
            }
        });
        $self->addLabel(
            $table,
            'Use \'tab\' / \'cursor up\' / \'cursor down\' keys to auto-complete commands',
            2, 12, 4, 5);

        my $checkButton5 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 5, 6);
        $checkButton5->set_active($axmud::CLIENT->useSwitchKeysFlag);
        $checkButton5->signal_connect('toggled' => sub {

            if (
                ($checkButton5->get_active && ! $axmud::CLIENT->useSwitchKeysFlag)
                || (! $checkButton5->get_active && $axmud::CLIENT->useSwitchKeysFlag)
            ) {
                $self->session->pseudoCmd('togglewindowkey -c',  $self->pseudoCmdMode);
            }
        });
        $self->addLabel($table, 'Use CTRL+TAB keys to switch between tabs in a window pane',
            2, 12, 5, 6);

        my $checkButton6 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 6, 7);
        $checkButton6->set_active($axmud::CLIENT->mainWinUrgencyFlag);
        $checkButton6->signal_connect('toggled' => sub {

            if (
                ($checkButton6->get_active && ! $axmud::CLIENT->mainWinUrgencyFlag)
                || (! $checkButton6->get_active && $axmud::CLIENT->mainWinUrgencyFlag)
            ) {
                $self->session->pseudoCmd('togglemainwindow -u',  $self->pseudoCmdMode);
            }
        });
        $self->addLabel(
            $table,
            'Set the \'main\' window\'s urgency hint when text is received from the world',
            2, 12, 6, 7);

        my $checkButton7 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 7, 8);
        $checkButton7->set_active($axmud::CLIENT->mainWinTooltipFlag);
        $checkButton7->signal_connect('toggled' => sub {

            if (
                ($checkButton7->get_active && ! $axmud::CLIENT->mainWinTooltipFlag)
                || (! $checkButton7->get_active && $axmud::CLIENT->mainWinTooltipFlag)
            ) {
                $self->session->pseudoCmd('togglemainwindow -t',  $self->pseudoCmdMode);
            }
        });
        $self->addLabel(
            $table,
            'Show tooltips in a session\'s default tab',
            2, 12, 7, 8);

        my $checkButton8 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 8, 9);
        $checkButton8->set_active($axmud::CLIENT->toolbarLabelFlag);
        $checkButton8->signal_connect('toggled' => sub {

            if (
                ($checkButton8->get_active && ! $axmud::CLIENT->toolbarLabelFlag)
                || (! $checkButton8->get_active && $axmud::CLIENT->toolbarLabelFlag)
            ) {
                $self->session->pseudoCmd('togglelabel',  $self->pseudoCmdMode);
            }
        });
        $self->addLabel(
            $table,
            'Show toolbar labels in the \'main\'/automapper windows',
            2, 12, 8, 9);

        my $checkButton9 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 9, 10);
        $checkButton9->set_active($axmud::CLIENT->irreversibleIconFlag);
        $checkButton9->signal_connect('toggled' => sub {

            if (
                ($checkButton9->get_active && ! $axmud::CLIENT->irreversibleIconFlag)
                || (! $checkButton9->get_active && $axmud::CLIENT->irreversibleIconFlag)
            ) {
                $self->session->pseudoCmd('toggleirreversible',  $self->pseudoCmdMode);
            }
        });
        $self->addLabel(
            $table,
            'Show irreversible icon in \'edit\' windows for actions that take place immediately',
            2, 10, 9, 10);

        my $button = $self->addButton($table,
            'Test icons', 'Test irreversible icons', undef,
            10, 12, 9, 10);
        $button->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('toggleirreversible -t', $self->pseudoCmdMode);
        });

        my $checkButton10 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 10, 11);
        $checkButton10->set_active($axmud::CLIENT->connectHistoryFlag);
        $checkButton10->signal_connect('toggled' => sub {

            if (
                ($checkButton10->get_active && ! $axmud::CLIENT->connectHistoryFlag)
                || (! $checkButton10->get_active && $axmud::CLIENT->connectHistoryFlag)
            ) {
                $self->session->pseudoCmd('togglehistory',  $self->pseudoCmdMode);
            }
        });
        $self->addLabel(
            $table,
            'Collect connection histories for each world',
            2, 12, 10, 11);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub pluginsTab {

        # Plugins tab - called by $self->setupNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->pluginsTab', @_);
        }

        # Tab setup
        # Create a notebook within the main one, so that we have two rows of tabs
        my ($vBox, $innerNotebook) = $self->addInnerNotebookTab('_Plugins', $self->notebook);

        # Add tabs to the inner notebook
        $self->plugins1Tab($innerNotebook);
        $self->plugins2Tab($innerNotebook);
        $self->plugins3Tab($innerNotebook);
        $self->plugins4Tab($innerNotebook);
        $self->plugins5Tab($innerNotebook);
        $self->plugins6Tab($innerNotebook);
        $self->plugins7Tab($innerNotebook);
        $self->plugins8Tab($innerNotebook);
        $self->plugins9Tab($innerNotebook);

        return 1;
    }

    sub plugins1Tab {

        # Plugins1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->plugins1Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _1', $innerNotebook);

        # Loaded plugins
        $self->addLabel($table, '<b>Loaded plugins</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of ' . $axmud::SCRIPT . ' plugins currently loaded (session-independent)</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Plugin', 'text',
            'Enabled', 'bool',
            'File path', 'text',
            'Version', 'text',
            'Requires', 'text',
            'Author', 'text',
            'Copyright', 'text',
            'Descrip', 'text',
            'Initial status', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 250);       # Fixed height

        # Initialise the simple list
        $self->plugins1Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add buttons
        my $button = $self->addButton($table,
            'Enable', 'Enable the selected plugin', undef,
            1, 3, 10, 11);
        $button->signal_connect('clicked' => sub {

            my ($plugin) = $self->getSimpleListData($slWidget, 1);
            if (defined $plugin) {

                # Enable this plugin
                $self->session->pseudoCmd('enableplugin ' . $plugin, $self->pseudoCmdMode);

                # Refresh the simple list
                $self->plugins1Tab_refreshList($slWidget, scalar (@columnList / 2));
            }
        });

        my $button2 = $self->addButton($table,
            'Disable', 'Disable the selected plugin', undef,
            3, 5, 10, 11);
        $button2->signal_connect('clicked' => sub {

            my ($plugin) = $self->getSimpleListData($slWidget, 1);
            if (defined $plugin) {

                # Disable this plugin
                $self->session->pseudoCmd('disableplugin ' . $plugin, $self->pseudoCmdMode);

                # Refresh the simple list
                $self->plugins1Tab_refreshList($slWidget, scalar (@columnList / 2));
            }
        });

        my $button3 = $self->addButton($table,
            'Test', 'Test a ' . $axmud::SCRIPT . ' plugin that hasn\'t been loaded', undef,
            5, 7, 10, 11);
        $button3->signal_connect('clicked' => sub {

            my ($plugin, $pluginObj);

            ($plugin) = $self->getSimpleListData($slWidget, 1);
            if (defined $plugin) {

                # Test this plugin
                $pluginObj = $axmud::CLIENT->ivShow('pluginHash', $plugin);
                $self->session->pseudoCmd(
                    'testplugin ' . $pluginObj->filePath,
                    $self->pseudoCmdMode,
                );

            } else {

                # Prompt the user for a plugin to test
                $self->session->pseudoCmd('testplugin', $self->pseudoCmdMode);
            }

            # Refresh the simple list
            $self->plugins1Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button4 = $self->addButton($table,
            'Load standard plugin', 'Load a new ' . $axmud::SCRIPT . ' standard plugin', undef,
            8, 10, 10, 11);
        $button4->signal_connect('clicked' => sub {

            # Disable this plugin
            $self->session->pseudoCmd('loadplugin -s', $self->pseudoCmdMode);

            # Refresh the simple list
            $self->plugins1Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button5 = $self->addButton($table,
            'Load custom plugin', 'Load a new ' . $axmud::SCRIPT . ' custom plugin', undef,
            10, 12, 10, 11);
        $button5->signal_connect('clicked' => sub {

            # Disable this plugin
            $self->session->pseudoCmd('loadplugin', $self->pseudoCmdMode);

            # Refresh the simple list
            $self->plugins1Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button6 = $self->addButton($table,
            'Refresh list', 'Refresh the list of loaded plugins', undef,
            10, 12, 11, 12);
        $button6->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->plugins1Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub plugins1Tab_refreshList {

        # Resets the simple list displayed by $self->plugins1Tab
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (@pluginList, @dataList);

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->plugins1Tab_refreshList',
                @_,
            );
        }

        # Import the list of plugins
        @pluginList = sort {lc($a->name) cmp lc($b->name)} ($axmud::CLIENT->ivValues('pluginHash'));

        # Compile the simple list data
        foreach my $obj (@pluginList) {

            my ($descrip, $author, $copyright);

            if ($obj->descrip) {

                # (Can't do a substr() operation on an 'undef' value)
                if (length ($obj->descrip) > 64) {
                    $descrip = substr($obj->descrip, 0, 64) . '...';
                } else {
                    $descrip = $obj->descrip;
                }
            }

            if ($obj->author) {

                if (length ($obj->author) > 64) {
                    $author = substr($obj->author, 0, 64) . '...';
                } else {
                    $author = $obj->author;
                }
            }

            if ($obj->copyright) {

                if (length ($obj->copyright) > 64) {
                    $copyright = substr($obj->copyright, 0, 64) . '...';
                } else {
                    $copyright = $obj->copyright;
                }
            }

            push (@dataList,
                $obj->name,
                $obj->enabledFlag,
                $obj->filePath,
                $obj->version,
                $obj->require,
                $descrip,
                $author,
                $copyright,
                $obj->init,
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub plugins2Tab {

        # Plugins2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->plugins2Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _2', $innerNotebook);

        # Initial plugins
        $self->addLabel($table, '<b>Initial plugins</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of ' . $axmud::SCRIPT . ' plugins loaded at startup (session-independent)</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            '#', 'int',
            'Plugin file', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);       # Fixed height

        # Initialise the simple list
        $self->plugins2Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add buttons
        my $button = $self->addButton($table,
            'Add standard', 'Add a new standard initial plugin', undef,
            1, 3, 10, 11);
        $button->signal_connect('clicked' => sub {

            # Add a new initial plugin
            $self->session->pseudoCmd('addinitialplugin -s', $self->pseudoCmdMode);

            # Refresh the simple list
            $self->plugins2Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button2 = $self->addButton($table,
            'Add custom', 'Add a new custom initial plugin', undef,
            3, 5, 10, 11);
        $button2->signal_connect('clicked' => sub {

            # Add a new initial plugin
            $self->session->pseudoCmd('addinitialplugin', $self->pseudoCmdMode);

            # Refresh the simple list
            $self->plugins2Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button3 = $self->addButton($table,
            'Delete', 'Delete the selected initial plugin', undef,
            5, 7, 10, 11);
        $button3->signal_connect('clicked' => sub {

            my ($plugin) = $self->getSimpleListData($slWidget, 1);
            if (defined $plugin) {

                # Delete the initial plugin
                $self->session->pseudoCmd('deleteinitialplugin ' . $plugin, $self->pseudoCmdMode);

                # Refresh the simple list
                $self->plugins2Tab_refreshList($slWidget, scalar (@columnList / 2));
            }
        });

        my $button4 = $self->addButton($table,
            'Test', 'Test the selected initial plugin', undef,
            7, 9, 10, 11);
        $button4->signal_connect('clicked' => sub {

            my ($plugin) = $self->getSimpleListData($slWidget, 1);
            if (defined $plugin) {

                # Delete the initial plugin
                $self->session->pseudoCmd('testplugin ' . $plugin, $self->pseudoCmdMode);

                # Refresh the simple list
                $self->plugins2Tab_refreshList($slWidget, scalar (@columnList / 2));
            }
        });

        my $button5 = $self->addButton($table,
            'Refresh list', 'Refresh the list of initial plugins', undef,
            10, 12, 10, 11);
        $button5->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->plugins2Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub plugins2Tab_refreshList {

        # Resets the simple list displayed by $self->plugins2Tab
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (
            $count,
            @dataList,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->plugins2Tab_refreshList',
                @_,
            );
        }

        # Compile the simple list data
        $count = 0;
        foreach my $path ($axmud::CLIENT->initPluginList) {

            $count++;

            push (@dataList, $count, $path);
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub plugins3Tab {

        # Plugins3 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->plugins3Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _3', $innerNotebook);

        # Plugin client commands
        $self->addLabel($table, '<b>Plugin client commands</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of client commands added by ' . $axmud::SCRIPT . ' plugins</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Command', 'text',
            'Plugin', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);       # Fixed height

        # Initialise the simple list
        $self->plugins3Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add buttons
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of client commands', undef,
            10, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->plugins3Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub plugins3Tab_refreshList {

        # Resets the simple list displayed by $self->plugins3Tab
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (
            @cmdList, @dataList,
            %cmdHash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->plugins3Tab_refreshList',
                @_,
            );
        }

        # Import the list of commands
        %cmdHash = $axmud::CLIENT->pluginCmdHash;
        @cmdList = sort {lc($a) cmp lc($b)} (keys %cmdHash);

        # Compile the simple list data
        foreach my $cmd (@cmdList) {

            push (@dataList, $cmd, $cmdHash{$cmd});
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub plugins4Tab {

        # Plugins4 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->plugins4Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _4', $innerNotebook);

        # Plugin tasks
        $self->addLabel($table, '<b>Plugin tasks</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of client tasks added by ' . $axmud::SCRIPT . ' plugins</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Task', 'text',
            'Plugin', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);       # Fixed height

        # Initialise the simple list
        $self->plugins4Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add buttons
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of tasks', undef,
            10, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->plugins4Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub plugins4Tab_refreshList {

        # Resets the simple list displayed by $self->plugins4Tab
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (
            @taskList, @dataList,
            %taskHash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->plugins4Tab_refreshList',
                @_,
            );
        }

        # Import the list of tasks
        %taskHash = $axmud::CLIENT->pluginTaskHash;
        @taskList = sort {lc($a) cmp lc($b)} (keys %taskHash);

        # Compile the simple list data
        foreach my $task (@taskList) {

            push (@dataList, $task, $taskHash{$task});
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub plugins5Tab {

        # Plugins5 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->plugins5Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _5', $innerNotebook);

        # Plugin tasks
        $self->addLabel($table, '<b>Plugin cages</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of cages added by ' . $axmud::SCRIPT . ' plugins</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Cage type', 'text',
            'Plugin', 'text',
            'Package name', 'text',
            '\'Edit\' window package name', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);       # Fixed height

        # Initialise the simple list
        $self->plugins5Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add buttons
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of cages', undef,
            10, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->plugins5Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub plugins5Tab_refreshList {

        # Resets the simple list displayed by $self->plugins5Tab
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (
            @cageList, @dataList,
            %cageHash, %packageHash, %editWinHash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->plugins5Tab_refreshList',
                @_,
            );
        }

        # Import the list of cages
        %cageHash = $axmud::CLIENT->pluginCageHash;
        %packageHash = $axmud::CLIENT->pluginCagePackageHash;
        %editWinHash = $axmud::CLIENT->pluginCageEditWinHash;
        @cageList = sort {lc($a) cmp lc($b)} (keys %cageHash);

        # Compile the simple list data
        foreach my $cage (@cageList) {

            push (@dataList,
                $cage,
                $cageHash{$cage},
                $packageHash{$cage},
                $editWinHash{$cage},
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub plugins6Tab {

        # Plugins6 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->plugins6Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _6', $innerNotebook);

        # Plugin 'grid' windows
        $self->addLabel($table, '<b>Plugin \'grid\' windows</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of \'grid\' window packages added by ' . $axmud::SCRIPT . ' plugins</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Package', 'text',
            'Plugin', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);       # Fixed height

        # Initialise the simple list
        $self->plugins6Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add buttons
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of packages', undef,
            10, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->plugins6Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub plugins6Tab_refreshList {

        # Resets the simple list displayed by $self->plugins6Tab
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (
            @winList, @dataList,
            %winHash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->plugins6Tab_refreshList',
                @_,
            );
        }

        # Import the list of packages
        %winHash = $axmud::CLIENT->pluginGridWinHash;
        @winList = sort {lc($a) cmp lc($b)} (keys %winHash);

        # Compile the simple list data
        foreach my $win (@winList) {

            push (@dataList, $win, $winHash{$win});
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub plugins7Tab {

        # Plugins7 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->plugins7Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _7', $innerNotebook);

        # Plugin 'free' windows
        $self->addLabel($table, '<b>Plugin \'free\' windows</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of \'free\' window packages added by ' . $axmud::SCRIPT . ' plugins</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Package', 'text',
            'Plugin', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);       # Fixed height

        # Initialise the simple list
        $self->plugins7Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add buttons
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of packages', undef,
            10, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->plugins7Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub plugins7Tab_refreshList {

        # Resets the simple list displayed by $self->plugins7Tab
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (
            @winList, @dataList,
            %winHash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->plugins7Tab_refreshList',
                @_,
            );
        }

        # Import the list of packages
        %winHash = $axmud::CLIENT->pluginFreeWinHash;
        @winList = sort {lc($a) cmp lc($b)} (keys %winHash);

        # Compile the simple list data
        foreach my $win (@winList) {

            push (@dataList, $win, $winHash{$win});
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub plugins8Tab {

        # Plugins8 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->plugins8Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _8', $innerNotebook);

        # Plugin 'free' windows
        $self->addLabel($table, '<b>Plugin strip objects</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of strip object packages added by ' . $axmud::SCRIPT . ' plugins</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Package', 'text',
            'Plugin', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);       # Fixed height

        # Initialise the simple list
        $self->plugins8Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add buttons
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of packages', undef,
            10, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->plugins8Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub plugins8Tab_refreshList {

        # Resets the simple list displayed by $self->plugins8Tab
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (
            @objList, @dataList,
            %objHash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->plugins8Tab_refreshList',
                @_,
            );
        }

        # Import the list of packages
        %objHash = $axmud::CLIENT->pluginStripObjHash;
        @objList = sort {lc($a) cmp lc($b)} (keys %objHash);

        # Compile the simple list data
        foreach my $win (@objList) {

            push (@dataList, $win, $objHash{$win});
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub plugins9Tab {

        # Plugins9 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->plugins9Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _9', $innerNotebook);

        # Plugin 'free' windows
        $self->addLabel($table, '<b>Plugin table objects</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of table object packages added by ' . $axmud::SCRIPT . ' plugins</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Package', 'text',
            'Plugin', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);       # Fixed height

        # Initialise the simple list
        $self->plugins9Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add buttons
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of packages', undef,
            10, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->plugins9Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub plugins9Tab_refreshList {

        # Resets the simple list displayed by $self->plugins9Tab
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (
            @objList, @dataList,
            %objHash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->plugins9Tab_refreshList',
                @_,
            );
        }

        # Import the list of packages
        %objHash = $axmud::CLIENT->pluginTableObjHash;
        @objList = sort {lc($a) cmp lc($b)} (keys %objHash);

        # Compile the simple list data
        foreach my $win (@objList) {

            push (@dataList, $win, $objHash{$win});
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub commandsTab {

        # Commands tab - called by $self->setupNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->commandsTab', @_);
        }

        # Tab setup
        # Create a notebook within the main one, so that we have two rows of tabs
        my ($vBox, $innerNotebook) = $self->addInnerNotebookTab('Co_mmands', $self->notebook);

        # Add tabs to the inner notebook
        $self->commands1Tab($innerNotebook);
        $self->commands2Tab($innerNotebook);
        $self->commands3Tab($innerNotebook);
        $self->commands4Tab($innerNotebook);
        $self->commands5Tab($innerNotebook);
        $self->commands6Tab($innerNotebook);

        return 1;
    }

    sub commands1Tab {

        # Commands1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->commands1Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _1', $innerNotebook);

        # Instruction sigils
        $self->addLabel($table, '<b>Instruction sigils</b>',
            0, 12, 0, 1);

        $self->addLabel($table, 'Client command sigil',
            1, 4, 1, 2);
        my $entry = $self->addEntry($table, undef, FALSE,
            4, 6, 1, 2);
        $entry->set_text($axmud::CLIENT->constClientSigil);

        my $checkButton = $self->addCheckButton($table, undef, TRUE,
            6, 8, 1, 2);
        $checkButton->set_active(TRUE);
        $checkButton->set_sensitive(FALSE);
        $checkButton->set_label('');            # Prevents Gtk2 messing up widget spacing

        $self->addLabel($table, 'Forced world command sigil',
            1, 4, 2, 3);
        my $entry2 = $self->addEntry($table, undef, FALSE,
            4, 6, 2, 3);
        $entry2->set_text($axmud::CLIENT->constForcedSigil);

        my $checkButton2 = $self->addCheckButton($table, undef, TRUE,
            6, 8, 2, 3);
        $checkButton2->set_active(TRUE);
        $checkButton2->set_sensitive(FALSE);
        $checkButton2->set_label('');

        $self->addLabel($table, 'Echo command sigil',
            1, 4, 3, 4);
        my $entry3 = $self->addEntry($table, undef, FALSE,
            4, 6, 3, 4);
        $entry3->set_text($axmud::CLIENT->constEchoSigil);

        my $checkButton3 = $self->addCheckButton($table, undef, TRUE,
            6, 8, 3, 4);
        $checkButton3->set_active($axmud::CLIENT->echoSigilFlag);
        $checkButton3->set_sensitive(FALSE);
        $checkButton3->set_label('');

        my $button = $self->addButton($table, 'Enable', 'Enable echo commands', undef,
            8, 10, 3, 4);
        $button->signal_connect('clicked' => sub {

            if (! $axmud::CLIENT->echoSigilFlag) {

                $self->session->pseudoCmd('togglesigil -e', $self->pseudoCmdMode);
                $checkButton3->set_active($axmud::CLIENT->echoSigilFlag);
            }
        });
        my $button2 = $self->addButton($table, 'Disable', 'Disable echo commands', undef,
            10, 12, 3, 4);
        $button2->signal_connect('clicked' => sub {

            if ($axmud::CLIENT->echoSigilFlag) {

                $self->session->pseudoCmd('togglesigil -e', $self->pseudoCmdMode);
                $checkButton3->set_active($axmud::CLIENT->echoSigilFlag);
            }
        });

        $self->addLabel($table, 'Perl command sigil',
            1, 4, 4, 5);
        my $entry4 = $self->addEntry($table, undef, FALSE,
            4, 6, 4, 5);
        $entry4->set_text($axmud::CLIENT->constPerlSigil);

        my $checkButton4 = $self->addCheckButton($table, undef, TRUE,
            6, 8, 4, 5);
        $checkButton4->set_active($axmud::CLIENT->perlSigilFlag);
        $checkButton4->set_sensitive(FALSE);
        $checkButton4->set_label('');

        my $button3 = $self->addButton($table, 'Enable', 'Enable Perl commands', undef,
            8, 10, 4, 5);
        $button3->signal_connect('clicked' => sub {

            if (! $axmud::CLIENT->perlSigilFlag) {

                $self->session->pseudoCmd('togglesigil -p', $self->pseudoCmdMode);
                $checkButton4->set_active($axmud::CLIENT->perlSigilFlag);
            }
        });
        my $button4 = $self->addButton($table, 'Disable', 'Disable Perl commands', undef,
            10, 12, 4, 5);
        $button4->signal_connect('clicked' => sub {

            if ($axmud::CLIENT->perlSigilFlag) {

                $self->session->pseudoCmd('togglesigil -p', $self->pseudoCmdMode);
                $checkButton4->set_active($axmud::CLIENT->perlSigilFlag);
            }
        });

        $self->addLabel($table, 'Script command sigil',
            1, 4, 5, 6);
        my $entry5 = $self->addEntry($table, undef, FALSE,
            4, 6, 5, 6);
        $entry5->set_text($axmud::CLIENT->constScriptSigil);

        my $checkButton5 = $self->addCheckButton($table, undef, TRUE,
            6, 8, 5, 6);
        $checkButton5->set_active($axmud::CLIENT->scriptSigilFlag);
        $checkButton5->set_sensitive(FALSE);
        $checkButton5->set_label('');

        my $button5 = $self->addButton($table, 'Enable', 'Enable script commands', undef,
            8, 10, 5, 6);
        $button5->signal_connect('clicked' => sub {

            if (! $axmud::CLIENT->scriptSigilFlag) {

                $self->session->pseudoCmd('togglesigil -s', $self->pseudoCmdMode);
                $checkButton5->set_active($axmud::CLIENT->scriptSigilFlag);
            }
        });
        my $button6 = $self->addButton($table, 'Disable', 'Disable script commands', undef,
            10, 12, 5, 6);
        $button6->signal_connect('clicked' => sub {

            if ($axmud::CLIENT->scriptSigilFlag) {

                $self->session->pseudoCmd('togglesigil -s', $self->pseudoCmdMode);
                $checkButton5->set_active($axmud::CLIENT->scriptSigilFlag);
            }
        });

        $self->addLabel($table, 'Multi command sigil',
            1, 4, 6, 7);
        my $entry6 = $self->addEntry($table, undef, FALSE,
            4, 6, 6, 7);
        $entry6->set_text($axmud::CLIENT->constMultiSigil);

        my $checkButton6 = $self->addCheckButton($table, undef, TRUE,
            6, 8, 6, 7);
        $checkButton6->set_active($axmud::CLIENT->multiSigilFlag);
        $checkButton6->set_sensitive(FALSE);
        $checkButton6->set_label('');

        my $button7 = $self->addButton($table, 'Enable', 'Enable multi commands', undef,
            8, 10, 6, 7);
        $button7->signal_connect('clicked' => sub {

            if (! $axmud::CLIENT->multiSigilFlag) {

                $self->session->pseudoCmd('togglesigil -m', $self->pseudoCmdMode);
                $checkButton6->set_active($axmud::CLIENT->multiSigilFlag);
            }
        });
        my $button8 = $self->addButton($table, 'Disable', 'Disable multi commands', undef,
            10, 12, 6, 7);
        $button8->signal_connect('clicked' => sub {

            if ($axmud::CLIENT->multiSigilFlag) {

                $self->session->pseudoCmd('togglesigil -m', $self->pseudoCmdMode);
                $checkButton6->set_active($axmud::CLIENT->multiSigilFlag);
            }
        });

        $self->addLabel($table, 'Speedwalk command sigil',
            1, 4, 7, 8);
        my $entry7 = $self->addEntry($table, undef, FALSE,
            4, 6, 7, 8);
        $entry7->set_text($axmud::CLIENT->constSpeedSigil);

        my $checkButton7 = $self->addCheckButton($table, undef, TRUE,
            6, 8, 7, 8);
        $checkButton7->set_active($axmud::CLIENT->speedSigilFlag);
        $checkButton7->set_sensitive(FALSE);
        $checkButton7->set_label('');

        my $button9 = $self->addButton($table, 'Enable', 'Enable speedwalk commands', undef,
            8, 10, 7, 8);
        $button9->signal_connect('clicked' => sub {

            if (! $axmud::CLIENT->speedSigilFlag) {

                $self->session->pseudoCmd('togglesigil -w', $self->pseudoCmdMode);
                $checkButton7->set_active($axmud::CLIENT->speedSigilFlag);
            }
        });
        my $button10 = $self->addButton($table, 'Disable', 'Disable speedwalk commands', undef,
            10, 12, 7, 8);
        $button10->signal_connect('clicked' => sub {

            if ($axmud::CLIENT->speedSigilFlag) {

                $self->session->pseudoCmd('togglesigil -w', $self->pseudoCmdMode);
                $checkButton7->set_active($axmud::CLIENT->speedSigilFlag);
            }
        });

        $self->addLabel($table, 'Bypass command sigil',
            1, 4, 8, 9);
        my $entry8 = $self->addEntry($table, undef, FALSE,
            4, 6, 8, 9);
        $entry8->set_text($axmud::CLIENT->constBypassSigil);

        my $checkButton8 = $self->addCheckButton($table, undef, TRUE,
            6, 8, 8, 9);
        $checkButton8->set_active($axmud::CLIENT->bypassSigilFlag);
        $checkButton8->set_sensitive(FALSE);
        $checkButton8->set_label('');

        my $button11 = $self->addButton($table, 'Enable', 'Enable bypass commands', undef,
            8, 10, 8, 9);
        $button11->signal_connect('clicked' => sub {

            if (! $axmud::CLIENT->bypassSigilFlag) {

                $self->session->pseudoCmd('togglesigil -b', $self->pseudoCmdMode);
                $checkButton8->set_active($axmud::CLIENT->bypassSigilFlag);
            }
        });
        my $button12 = $self->addButton($table, 'Disable', 'Disable bypass commands', undef,
            10, 12, 8, 9);
        $button12->signal_connect('clicked' => sub {

            if ($axmud::CLIENT->bypassSigilFlag) {

                $self->session->pseudoCmd('togglesigil -b', $self->pseudoCmdMode);
                $checkButton8->set_active($axmud::CLIENT->speedSigilFlag);
            }
        });

        # World command separator
        $self->addLabel($table, '<b>World command separator</b>',
            0, 12, 9, 10);

        $self->addLabel($table, 'Separator',
            1, 4, 10, 11);
        my $entry9 = $self->addEntry($table, undef, TRUE,
            4, 6, 10, 11,
            16, 16);
        $entry9->set_text($axmud::CLIENT->cmdSep);
        $entry9->set_icon_from_stock('secondary', 'gtk-yes');
        $entry9->signal_connect('changed' => sub {

            # (Borrowed from GA::Generic::EditWin->addEntryWithIcon and ->checkEntry. The value
            #   must not contain any spaces)

            my $value = $entry9->get_text();
            # Check whether $text is a valid value, or not

            if (! $value || length ($value) > 4 || $value =~ m/\s/) {
                $entry9->set_icon_from_stock('secondary', 'gtk-no');
            } else {
                $entry9->set_icon_from_stock('secondary', 'gtk-yes');
            }
        });

        my $button13 = $self->addButton(
            $table, 'Set', 'Sets the command separator (max 4 characters, no spaces)', undef,
            8, 10, 10, 11);
        $button13->signal_connect('clicked' => sub {

            my $separator = $entry9->get_text();

            if ($self->checkEntryIcon($entry9)) {

                # Set the command separator
                $self->session->pseudoCmd('commandseparator ' . $separator, $self->pseudoCmdMode);

                # Update the entry box
                $entry9->set_text($axmud::CLIENT->cmdSep);
            }
        });

        my $button14 = $self->addButton(
            $table, 'Reset', 'Resets the command separator to its default value', undef,
            10, 12, 10, 11);
        $button14->signal_connect('clicked' => sub {

            # Set the command separator
            $self->session->pseudoCmd('commandseparator', $self->pseudoCmdMode);

            # Update the entry box
            $entry9->set_text($axmud::CLIENT->cmdSep);
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub commands2Tab {

        # Commands2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->commands3Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _2', $innerNotebook);

        # Left column
        $self->addLabel($table, '<b>Instruction settings</b>',
            0, 6, 0, 1);
        $self->addLabel($table, '<i>Multi commands</i>',
            1, 6, 1, 2);

        my ($group, $radioButton) = $self->addRadioButton(
            $table, undef, 'Send to sessions with same world profile', undef,
            undef,      # IV set to this value when toggled
            TRUE,       # Sensitive widget
            1, 6, 2, 3);
        $radioButton->signal_connect('toggled' => sub {

            if ($radioButton->get_active() && $axmud::CLIENT->maxMultiCmdFlag) {

                $self->session->pseudoCmd('toggleinstruct -m', $self->pseudoCmdMode);
            }
        });

        my ($group2, $radioButton2) = $self->addRadioButton(
            $table, $group, 'Send to all sessions', undef, undef, TRUE,
            1, 6, 3, 4);
        if ($axmud::CLIENT->maxMultiCmdFlag) {

            $radioButton2->set_active(TRUE);
        }
        $radioButton2->signal_connect('toggled' => sub {


            if ($radioButton2->get_active() && ! $axmud::CLIENT->maxMultiCmdFlag) {

                $self->session->pseudoCmd('toggleinstruct -m', $self->pseudoCmdMode);
            }
        });

        $self->addLabel($table, '<i>World / speedwalk / multi / bypass commands</i>',
            1, 6, 4, 5);

        my ($group11, $radioButton11) = $self->addRadioButton(
            $table, undef, 'After processing, remove from command entry box', undef,
            undef,      # IV set to this value when toggled
            TRUE,       # Sensitive widget
            1, 6, 5, 6);
        $radioButton11->signal_connect('toggled' => sub {

            if ($radioButton11->get_active() && $axmud::CLIENT->preserveWorldCmdFlag) {

                $self->session->pseudoCmd('toggleinstruct -w', $self->pseudoCmdMode);
            }
        });

        my ($group12, $radioButton12) = $self->addRadioButton(
            $table, $group11, 'After processing, retain in command entry box', undef, undef, TRUE,
            1, 6, 6, 7);
        if ($axmud::CLIENT->preserveWorldCmdFlag) {

            $radioButton12->set_active(TRUE);
        }
        $radioButton12->signal_connect('toggled' => sub {

            if ($radioButton12->get_active() && ! $axmud::CLIENT->preserveWorldCmdFlag) {

                $self->session->pseudoCmd('toggleinstruct -w', $self->pseudoCmdMode);
            }
        });

        $self->addLabel($table, '<i>Client / echo / Perl / script commands</i>',
            1, 6, 7, 8);

        my ($group21, $radioButton21) = $self->addRadioButton(
            $table, undef, 'After processing, remove from command entry box', undef,
            undef,      # IV set to this value when toggled
            TRUE,       # Sensitive widget
            1, 6, 8, 9);
        $radioButton21->signal_connect('toggled' => sub {

            if ($radioButton21->get_active() && $axmud::CLIENT->preserveOtherCmdFlag) {

                $self->session->pseudoCmd('toggleinstruct -o', $self->pseudoCmdMode);
            }
        });

        my ($group22, $radioButton22) = $self->addRadioButton(
            $table,
            $group21,
            'After processing, retain in command entry box',
            undef,
            undef,
            TRUE,
            1, 6, 9, 10);
        if ($axmud::CLIENT->preserveOtherCmdFlag) {

            $radioButton22->set_active(TRUE);
        }
        $radioButton22->signal_connect('toggled' => sub {

            if ($radioButton22->get_active() && ! $axmud::CLIENT->preserveOtherCmdFlag) {

                $self->session->pseudoCmd('toggleinstruct -o', $self->pseudoCmdMode);
            }
        });

        # Right column
        $self->addLabel($table, '<i>Other settings</i>',
            7, 12, 1, 2);
        $self->addLabel($table, 'World commands also shown in \'main\' window',
            7, 11, 2, 3);
        my $checkButton = $self->addCheckButton($table, undef, TRUE,
            11, 12, 2, 3);
        $checkButton->set_active($axmud::CLIENT->confirmWorldCmdFlag);
        $checkButton->signal_connect('toggled' => sub {

            if (
                ($checkButton->get_active() && ! $axmud::CLIENT->confirmWorldCmdFlag)
                || (! $checkButton->get_active() && $axmud::CLIENT->confirmWorldCmdFlag)
            ) {
                $self->session->pseudoCmd('toggleinstruct -c', $self->pseudoCmdMode);
            }
        });

        $self->addLabel($table, 'Send short world commands in lower-case letters',
            7, 11, 3, 4);
        my $checkButton2 = $self->addCheckButton($table, undef, TRUE,
            11, 12, 3, 4);
        $checkButton2->set_active($axmud::CLIENT->convertWorldCmdFlag);
        $checkButton2->signal_connect('toggled' => sub {

            if (
                ($checkButton2->get_active() && ! $axmud::CLIENT->convertWorldCmdFlag)
                || (! $checkButton2->get_active() && $axmud::CLIENT->convertWorldCmdFlag)
            ) {
                $self->session->pseudoCmd('toggleinstruct -v', $self->pseudoCmdMode);
            }
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub commands3Tab {

        # Commands3 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->commands3Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _3', $innerNotebook);

        # Left column
        $self->addLabel($table, '<b>Redirect mode</b>',
            0, 6, 0, 1);
        my $entry6 = $self->addEntryWithIcon($table, undef, 'string', 1, undef,
            1, 6, 1, 2);
        $self->addLabel($table, '<i>The \'@\' symbol is replaced by a direction</i>',
            1, 6, 2, 3);

        my $button4 = $self->addButton(
            $table,
            'Redirect mode on',
            'Redirects direction commands, replacing the @ symbol with the direction',
            undef,
            1, 3, 3, 4);
       $button4->signal_connect('clicked' => sub {

            my $string = $entry6->get_text();

            if ($self->checkEntryIcon($entry6)) {

                # Turn redirect mode on
                $self->session->pseudoCmd('redirectmode <' . $string . '>', $self->pseudoCmdMode);

                # Reset the entry box
                $self->resetEntryBoxes($entry6);
            }
        });

        my $button5 = $self->addButton(
            $table,
            'Redirect mode off',
            'Turns off redirect mode',
            undef,
            3, 5, 3, 4);
        $button5->signal_connect('clicked' => sub {

            # Turn redirect mode on
            $self->session->pseudoCmd('redirectmode', $self->pseudoCmdMode);

            # Reset the entry box
            $self->resetEntryBoxes($entry6);
        });

        my ($group, $radioButton) = $self->addRadioButton(
            $table, undef, 'Redirect primary directions only', undef,
            undef,      # IV set to this value when toggled
            TRUE,       # Sensitive widget
            1, 6, 4, 5);
        if ($self->session->redirectMode eq 'primary_only') {

            $radioButton->set_active(TRUE);
        }
        $radioButton->signal_connect('toggled' => sub {

            if ($radioButton->get_active()) {

                $self->session->pseudoCmd('setredirectmode -p', $self->pseudoCmdMode);
            }
        });

        my ($group2, $radioButton2) = $self->addRadioButton(
            $table, $group, 'Redirect primary & secondary directions', undef, undef, TRUE,
            1, 6, 5, 6);
        if ($self->session->redirectMode eq 'primary_secondary') {

            $radioButton2->set_active(TRUE);
        }
        $radioButton2->signal_connect('toggled' => sub {

            if ($radioButton2->get_active()) {

                $self->session->pseudoCmd('setredirectmode -b', $self->pseudoCmdMode);
            }
        });

        my ($group3, $radioButton3) = $self->addRadioButton(
            $table, $group2, 'Redirect all direction commands', undef, undef, TRUE,
            1, 6, 6, 7);
        if ($self->session->redirectMode eq 'all_exits') {

            $radioButton3->set_active(TRUE);
        }
        $radioButton3->signal_connect('toggled' => sub {

            if ($radioButton3->get_active()) {

                $self->session->pseudoCmd('setredirectmode -a', $self->pseudoCmdMode);
            }
        });

        # Right column
        $self->addLabel($table, '<b>Auto-complete mode</b>',
            7, 13, 0, 1);

        my ($group11, $radioButton11) = $self->addRadioButton(
            $table, undef, 'Don\'t auto-complete instructions/world commands', undef,
            undef,      # IV set to this value when toggled
            TRUE,       # Sensitive widget
            8, 13, 1, 2);
        if ($axmud::CLIENT->autoCompleteMode eq 'none') {

            $radioButton11->set_active(TRUE);
        }
        $radioButton11->signal_connect('toggled' => sub {

            if ($radioButton11->get_active()) {

                $axmud::CLIENT->set_autoCompleteMode('none');
            }
        });

        my ($group12, $radioButton12) = $self->addRadioButton(
            $table, $group11, 'Auto-complete instructions/world commands', undef, undef, TRUE,
            8, 13, 2, 3);
        if ($axmud::CLIENT->autoCompleteMode eq 'auto') {

            $radioButton12->set_active(TRUE);
        }
        $radioButton12->signal_connect('toggled' => sub {

            if ($radioButton12->get_active()) {

                $axmud::CLIENT->set_autoCompleteMode('auto');
            }
        });

        $self->addLabel($table, '<i>Auto-complete type</i>',
            8, 13, 3, 4);

        my ($group21, $radioButton21) = $self->addRadioButton(
            $table, undef, 'Navigate through an instruction buffer', undef,
            undef,      # IV set to this value when toggled
            TRUE,       # Sensitive widget
            8, 13, 4, 5);
        if ($axmud::CLIENT->autoCompleteType eq 'instruct') {

            $radioButton21->set_active(TRUE);
        }
        $radioButton21->signal_connect('toggled' => sub {

            if ($radioButton21->get_active()) {

                $axmud::CLIENT->set_autoCompleteType('instruct');
            }
        });

        my ($group22, $radioButton22) = $self->addRadioButton(
            $table, $group21, 'Navigate through a world command buffer', undef, undef, TRUE,
            8, 13, 5, 6);
        if ($axmud::CLIENT->autoCompleteType eq 'cmd') {

            $radioButton22->set_active(TRUE);
        }
        $radioButton22->signal_connect('toggled' => sub {

            if ($radioButton22->get_active()) {

                $axmud::CLIENT->set_autoCompleteType('cmd');
            }
        });

        $self->addLabel($table, '<i>Buffer location</i>',
            8, 13, 6, 7);

        my ($group31, $radioButton31) = $self->addRadioButton(
            $table, undef, 'Use combined buffers', undef,
            undef,      # IV set to this value when toggled
            TRUE,       # Sensitive widget
            8, 13, 7, 8);
        if ($axmud::CLIENT->autoCompleteParent eq 'combined') {

            $radioButton31->set_active(TRUE);
        }
        $radioButton31->signal_connect('toggled' => sub {

            if ($radioButton31->get_active()) {

                $axmud::CLIENT->set_autoCompleteParent('combined');
            }
        });

        my ($group32, $radioButton32) = $self->addRadioButton(
            $table, $group31, 'Use session buffers', undef, undef, TRUE,
            8, 13, 8, 9);
        if ($axmud::CLIENT->autoCompleteParent eq 'session') {

            $radioButton32->set_active(TRUE);
        }
        $radioButton32->signal_connect('toggled' => sub {

            if ($radioButton32->get_active()) {

                $axmud::CLIENT->set_autoCompleteParent('session');
            }
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub commands4Tab {

        # Commands4 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (@columnList, @comboList);

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->commands4Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _4', $innerNotebook);

        # Custom user commands
        $self->addLabel($table, '<b>User commands</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>Customisable list of alternate forms for standard client commands</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'User command', 'text',
            'Standard client command', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 230);       # Fixed height

        # Initialise the list
        $self->commands4Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add entry boxes and editing buttons
        $self->addLabel($table, 'User command',
            1, 3, 10, 11);
        my $entry = $self->addEntryWithIcon($table, undef, 'string', 1, 32,
            3, 6, 10, 11);

        $self->addLabel($table, 'Standard command',
            7, 9, 10, 11);
        @comboList = sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('clientCmdHash'));
        my $combo = $self->addComboBox($table, undef, \@comboList, '',
            TRUE,               # No 'undef' value used
            9, 12, 10, 11);

        my $button = $self->addButton($table, 'Add', 'Add or replace a user command', undef,
            1, 3, 11, 12);
        $button->signal_connect('clicked' => sub {

            my ($user, $standard);

            $user = $entry->get_text();
            $standard = $combo->get_active_text();

            if ($self->checkEntryIcon($entry)) {

                # Add this user command
                $self->session->pseudoCmd(
                    'addusercommand ' . $standard . ' ' . $user,
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list and entry boxes
                $self->commands4Tab_refreshList($slWidget, scalar (@columnList / 2));
                $self->resetEntryBoxes($entry);
            }
        });

        my $button2 = $self->addButton($table, 'Delete', 'Delete the selected user command', undef,
            3, 5, 11, 12);
        $button2->signal_connect('clicked' => sub {

            my ($user) = $self->getSimpleListData($slWidget, 0);
            if (defined $user) {

                # Remove this user command
                $self->session->pseudoCmd(
                    'deleteusercommand ' . $user,
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list
                $self->commands4Tab_refreshList($slWidget, scalar (@columnList / 2));
                $self->resetEntryBoxes($entry);
            }
        });

        my $button3 = $self->addButton(
            $table,
            'Reset user commands',
            'Reset the list of user commands to the default list',
            undef,
            7, 10, 11, 12);
        $button3->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('resetusercommand', $self->pseudoCmdMode);

            # Refresh the simple list
            $self->commands4Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button4 = $self->addButton($table,
            'Dump', 'Display the list of user commands in the \'main\' window', undef,
            10, 12, 11, 12);
        $button4->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('listusercommand', $self->pseudoCmdMode);
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub commands4Tab_refreshList {

        # Called by $self->commands4Tab to refresh the Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::List
        #   $columns    - The number of columns in the list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (
            @sortedList, @dataList,
            %hash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->commands4Tab_refreshList',
                @_,
            );
        }

        # Import the hash of user commands (for quick lookup)
        %hash = $axmud::CLIENT->userCmdHash;
        @sortedList = sort {lc($a) cmp lc($b)} (keys %hash);

        # Compile the simple list data
        foreach my $cmd (@sortedList) {

            push (@dataList, $cmd, $hash{$cmd});
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub commands5Tab {

        # Commands5 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (
            @columnList, @sortedList, @dataList,
            %hash,
        );

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->commands5Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _5', $innerNotebook);

        # Default user commands
        $self->addLabel($table, '<b>Default user commands</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>Default list of alternate forms for standard client commands</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'User command', 'text',
            'Standard client command', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);       # Fixed height

        # Initialise the list
        %hash = $axmud::CLIENT->constUserCmdHash;
        @sortedList = sort {$a cmp $b} (keys %hash);
        foreach my $cmd (@sortedList) {

            push (@dataList, $cmd, $hash{$cmd});
        }

        $self->resetListData($slWidget, [@dataList], scalar (@columnList / 2));

        # Add a button
        my $button = $self->addButton($table,
            'Dump', 'Display the default list of user commands in the \'main\' window', undef,
            10, 12, 11, 12);
        $button->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('listusercommand -d', $self->pseudoCmdMode);
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub commands6Tab {

        # Commands6 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;


        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->commands6Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _6', $innerNotebook);

        # Client buffer settings
        $self->addLabel($table, '<b>Client buffer settings</b>',
            0, 12, 0, 1);

        # Left column - instruction buffer
        $self->addLabel($table, '<i>Instruction buffer</i>',
            1, 12, 1, 2);

        $self->addLabel($table, 'Max size',
            1, 3, 2, 3);
        my $entry = $self->addEntry($table, undef, FALSE,
            3, 6, 2, 3);

        $self->addLabel($table, 'Current size',
            1, 3, 3, 4);
        my $entry2 = $self->addEntry($table, undef, FALSE,
            3, 6, 3, 4);

        $self->addLabel($table, 'Total items processed',
            1, 3, 4, 5);
        my $entry3 = $self->addEntry($table, undef, FALSE,
            3, 6, 4, 5);

        $self->addLabel($table, 'Item number',
            1, 3, 5, 6);
        my $entry4 = $self->addEntryWithIcon($table, undef, 'int', 0, undef,
            3, 6, 5, 6);

        # Right column - instruction buffer
        my $button = $self->addButton($table,
            'Update', 'Update the displayed data', undef,
            9, 12, 0, 1);

        $self->addLabel($table, 'First item #',
            7, 9, 2, 3);
        my $entry5 = $self->addEntry($table, undef, FALSE,
            9, 12, 2, 3);

        $self->addLabel($table, 'Last item #',
            7, 9, 3, 4);
        my $entry6 = $self->addEntry($table, undef, FALSE,
            9, 12, 3, 4);

        my $button2 = $self->addButton($table,
            'View', 'View the specified buffer item', undef,
            7, 8, 5, 6);

        my $button3 = $self->addButton($table,
            'Dump', 'Display the specified buffer item in the \'main\' window', undef,
            8, 9, 5, 6);

        my $button4 = $self->addButton($table,
            'Dump last', 'Display the most recent buffer item in the \'main\' window', undef,
            9, 11, 5, 6);

        my $button5 = $self->addButton($table,
            'Dump 20', 'Display the most recent 20 buffer items in the \'main\' window', undef,
            11, 12, 5, 6);

        # Left column - world command buffer
        $self->addLabel($table, '<i>World command buffer</i>',
            1, 12, 6, 7);

        $self->addLabel($table, 'Max size',
            1, 3, 7, 8);
        my $entry8 = $self->addEntry($table, undef, FALSE,
            3, 6, 7, 8);

        $self->addLabel($table, 'Current size',
            1, 3, 8, 9);
        my $entry9 = $self->addEntry($table, undef, FALSE,
            3, 6, 8, 9);

        $self->addLabel($table, 'Total items processed',
            1, 3, 9, 10);
        my $entry10 = $self->addEntry($table, undef, FALSE,
            3, 6, 9, 10);

        $self->addLabel($table, 'Item number',
            1, 3, 10, 11);
        my $entry11 = $self->addEntryWithIcon($table, undef, 'int', 0, undef,
            3, 6, 10, 11);

        # Right column - world command buffer
        $self->addLabel($table, 'First item #',
            7, 9, 7, 8);
        my $entry12 = $self->addEntry($table, undef, FALSE,
            9, 12, 7, 8);

        $self->addLabel($table, 'Last item #',
            7, 9, 8, 9);
        my $entry13 = $self->addEntry($table, undef, FALSE,
            9, 12, 8, 9);

        my $button6 = $self->addButton($table,
            'View', 'View the specified buffer item', undef,
            7, 8, 10, 11);

        my $button7 = $self->addButton($table,
            'Dump', 'Display the specified buffer item in the \'main\' window', undef,
            8, 9, 10, 11);

        my $button8 = $self->addButton($table,
            'Dump last', 'Display the most recent buffer item in the \'main\' window', undef,
            9, 11, 10, 11);

        my $button9 = $self->addButton($table,
            'Dump 20', 'Display the most recent 20 buffer items in the \'main\' window', undef,
            11, 12, 10, 11);

        # ->signal_connects

        # 'Update'
        $button->signal_connect('clicked' => sub {

            # Instruction buffer
            $entry->set_text($axmud::CLIENT->customInstructBufferSize);
            $entry2->set_text($axmud::CLIENT->ivPairs('instructBufferHash'));
            $entry3->set_text($axmud::CLIENT->instructBufferCount);

            if (defined $axmud::CLIENT->instructBufferFirst) {

                $entry5->set_text($axmud::CLIENT->instructBufferFirst);
            }

            if (defined $axmud::CLIENT->instructBufferLast) {

                $entry6->set_text($axmud::CLIENT->instructBufferLast);
            }

            # World command buffer
            $entry8->set_text($axmud::CLIENT->customCmdBufferSize);
            $entry9->set_text($axmud::CLIENT->ivPairs('cmdBufferHash'));
            $entry10->set_text($axmud::CLIENT->cmdBufferCount);

            if (defined $axmud::CLIENT->cmdBufferFirst) {

                $entry12->set_text($axmud::CLIENT->cmdBufferFirst);
            }

            if (defined $axmud::CLIENT->cmdBufferLast) {

                $entry13->set_text($axmud::CLIENT->cmdBufferLast);
            }
        });

        # 'View'
        $button2->signal_connect('clicked' => sub {

            my $number = $entry4->get_text();

            if ($self->checkEntryIcon($entry4)) {

                # Open an 'edit' window for the specified buffer item
                $self->session->pseudoCmd(
                    'editinstructionbuffer -c ' . $number,
                    $self->pseudoCmdMode,
                );
            }
        });

        # 'Dump'
        $button3->signal_connect('clicked' => sub {

            my $number = $entry4->get_text();

            if ($self->checkEntryIcon($entry4)) {

                # Display the specified buffer item
                $self->session->pseudoCmd(
                    'dumpinstructionbuffer -c ' . $number,
                    $self->pseudoCmdMode,
                );
            }
        });

        # 'Dump last'
        $button4->signal_connect('clicked' => sub {

            # Display most recent buffer item
            $self->session->pseudoCmd('dumpinstructionbuffer -c', $self->pseudoCmdMode);
            # Show the number of the most recent buffer item
            if (defined $axmud::CLIENT->instructBufferLast) {

                $entry4->set_text($axmud::CLIENT->instructBufferLast);
            }
        });

        # 'Dump 20'
        $button5->signal_connect('clicked' => sub {

            my ($start, $stop);

            $stop = $axmud::CLIENT->instructBufferLast;
            $start = $stop - 19;
            if ($start < 0) {

                $start = 0;
            }

            # Display most recent buffer items
            $self->session->pseudoCmd(
                'dumpinstructionbuffer -c ' . $start . ' ' . $stop,
                $self->pseudoCmdMode,
            );
        });

        # 'View'
        $button6->signal_connect('clicked' => sub {

            my $number = $entry11->get_text();

            if ($self->checkEntryIcon($entry11)) {

                # Open an 'edit' window for the specified buffer item
                $self->session->pseudoCmd('editcommandbuffer -c ' . $number, $self->pseudoCmdMode);
            }
        });

        # 'Dump'
        $button7->signal_connect('clicked' => sub {

            my $number = $entry11->get_text();

            if ($self->checkEntryIcon($entry11)) {

                # Display the specified buffer item
                $self->session->pseudoCmd('dumpcommandbuffer -c ' . $number, $self->pseudoCmdMode);
            }
        });

        # 'Dump last'
        $button8->signal_connect('clicked' => sub {

            # Display most recent buffer item
            $self->session->pseudoCmd('dumpcommandbuffer -c', $self->pseudoCmdMode);
            # Show the number of the most recent buffer item
            if (defined $axmud::CLIENT->cmdBufferLast) {

                $entry11->set_text($axmud::CLIENT->cmdBufferLast);
            }
        });

        # 'Dump 20'
        $button9->signal_connect('clicked' => sub {

            my ($start, $stop);

            $stop = $axmud::CLIENT->cmdBufferLast;
            $start = $stop - 19;
            if ($start < 0) {

                $start = 0;
            }

            # Display most recent buffer items
            $self->session->pseudoCmd(
                'dumpcommandbuffer ' . $start . ' ' . $stop,
                $self->pseudoCmdMode,
            );
        });

        # Pseudo-click the button to set all the widgets
        $button->clicked();

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub logsTab {

        # Logs tab - called by $self->setupNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->logsTab', @_);
        }

        # Tab setup
        # Create a notebook within the main one, so that we have two rows of tabs
        my ($vBox, $innerNotebook) = $self->addInnerNotebookTab('_Logs', $self->notebook);

        # Add tabs to the inner notebook
        $self->logs1Tab($innerNotebook);
        $self->logs2Tab($innerNotebook);
        $self->logs3Tab($innerNotebook);
        $self->logs4Tab($innerNotebook);

        return 1;
    }

    sub logs1Tab {

        # Logs1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->logs1Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _1', $innerNotebook);

        # Log settings
        $self->addLabel($table, '<b>Log settings</b>',
            0, 12, 0, 1);

        $self->addLabel($table, 'Enable logging in general',
            1, 11, 1, 2);
        my $checkButton = $self->addCheckButton($table, undef, TRUE,
            11, 12, 1, 2);
        $checkButton->set_active($axmud::CLIENT->allowLogsFlag);
        $checkButton->signal_connect('toggled' => sub {

            $self->session->pseudoCmd('log -l', $self->pseudoCmdMode);
            $checkButton->set_active($axmud::CLIENT->allowLogsFlag);
        });

        $self->addLabel(
            $table, 'Enable deletion of standard logfiles (written by every session) when the'
            . ' client starts',
            1, 11, 2, 3);
        my $checkButton2 = $self->addCheckButton($table, undef, TRUE,
            11, 12, 2, 3);
        $checkButton2->set_active($axmud::CLIENT->deleteStandardLogsFlag);
        $checkButton2->signal_connect('toggled' => sub {

            $self->session->pseudoCmd('log -d', $self->pseudoCmdMode);
            $checkButton2->set_active($axmud::CLIENT->deleteStandardLogsFlag);
        });

        $self->addLabel(
            $table, 'Enable deletion of world logfiles (written by every session) when a session'
            . ' starts',
            1, 11, 3, 4);
        my $checkButton3 = $self->addCheckButton($table, undef, TRUE,
            11, 12, 3, 4);
        $checkButton3->set_active($axmud::CLIENT->deleteWorldLogsFlag);
        $checkButton3->signal_connect('toggled' => sub {

            $self->session->pseudoCmd('log -w', $self->pseudoCmdMode);
            $checkButton3->set_active($axmud::CLIENT->deleteWorldLogsFlag);
        });

        $self->addLabel(
            $table, 'Enable creation of new logfiles when the client starts',
            1, 11, 4, 5);
        my $checkButton4 = $self->addCheckButton($table, undef, TRUE,
            11, 12, 4, 5);
        $checkButton4->set_active($axmud::CLIENT->logClientFlag);
        $checkButton4->signal_connect('toggled' => sub {

            $self->session->pseudoCmd('log -s', $self->pseudoCmdMode);
            $checkButton4->set_active($axmud::CLIENT->logClientFlag);
        });

        $self->addLabel(
            $table, 'Enable creation of new logfiles at the start of every day',
            1, 11, 5, 6);
        my $checkButton5 = $self->addCheckButton($table, undef, TRUE,
            11, 12, 5, 6);
        $checkButton5->set_active($axmud::CLIENT->logDayFlag);
        $checkButton5->signal_connect('toggled' => sub {

            $self->session->pseudoCmd('log -y', $self->pseudoCmdMode);
            $checkButton5->set_active($axmud::CLIENT->logDayFlag);
        });

        $self->addLabel(
            $table, 'Lines in logfiles are prefixed by the current date',
            1, 11, 6, 7);
        my $checkButton6 = $self->addCheckButton($table, undef, TRUE,
            11, 12, 6, 7);
        $checkButton6->set_active($axmud::CLIENT->logPrefixDateFlag);
        $checkButton6->signal_connect('toggled' => sub {

            $self->session->pseudoCmd('log -a', $self->pseudoCmdMode);
            $checkButton6->set_active($axmud::CLIENT->logPrefixDateFlag);
        });

        $self->addLabel(
            $table, 'Lines in logfiles are prefixed by the current time',
            1, 11, 7, 8);
        my $checkButton7 = $self->addCheckButton($table, undef, TRUE,
            11, 12, 7, 8);
        $checkButton7->set_active($axmud::CLIENT->logPrefixTimeFlag);
        $checkButton7->signal_connect('toggled' => sub {

            $self->session->pseudoCmd('log -t', $self->pseudoCmdMode);
            $checkButton7->set_active($axmud::CLIENT->logPrefixTimeFlag);
        });

        $self->addLabel(
            $table, 'Logfiles record image filenames',
            1, 11, 8, 9);
        my $checkButton8 = $self->addCheckButton($table, undef, TRUE,
            11, 12, 8, 9);
        $checkButton8->set_active($axmud::CLIENT->logImageFlag);
        $checkButton8->signal_connect('toggled' => sub {

            $self->session->pseudoCmd('log -i', $self->pseudoCmdMode);
            $checkButton8->set_active($axmud::CLIENT->logImageFlag);
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub logs2Tab {

        # Logs2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->logs2Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _2', $innerNotebook);

        # Status task events
        $self->addLabel($table, '<b>Status task events</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $table,
            '<i>Number of logfile lines to write before/after a change in the character\'s life'
            . ' status</i>',
            1, 12, 1, 2);

        my $entry = $self->addEntryWithIcon($table, undef, 'int', 0, 999,
            1, 4, 2, 3);
        $entry->set_text($axmud::CLIENT->statusEventBeforeCount);

        my $button = $self->addButton(
            $table,
            'Set',
            'Set the number of lines to write before a change in life status',
            undef,
            4, 6, 2, 3);
        $button->signal_connect('clicked' => sub {

            my $number = $entry->get_text();

            if ($self->checkEntryIcon($entry)) {

                $self->session->pseudoCmd('setstatusevent -b ' . $number, $self->pseudoCmdMode);
            }
        });

        $self->addLabel($table, 'Lines to write before an event (0-999)',
            7, 12, 2, 3);

        my $entry2 = $self->addEntryWithIcon($table, undef, 'int', 0, 999,
            1, 4, 3, 4);
        $entry2->set_text($axmud::CLIENT->statusEventAfterCount);

        my $button2 = $self->addButton(
            $table,
            'Set',
            'Set the number of lines to write after a change in life status',
            undef,
            4, 6, 3, 4);
        $button2->signal_connect('clicked' => sub {

            my $number = $entry2->get_text();

            if ($self->checkEntryIcon($entry2)) {

                $self->session->pseudoCmd('setstatusevent -a ' . $number, $self->pseudoCmdMode);
            }
        });

        $self->addLabel($table, 'Lines to write after an event (0-999)',
            7, 12, 3, 4);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub logs3Tab {

        # Logs3 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (@columnList, @comboList);

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->logs3Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _3', $innerNotebook);

         # Client logging settings
        $self->addLabel($table, '<b>Client logging settings</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of logfiles written by every session</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Logfile', 'text',
            'Write?', 'bool',
            'Description', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);      # Fixed height

        # Initialise the list
        $self->logs3Tab_refreshList($slWidget, (scalar @columnList / 2));

        # Add a two combos and a button
        @comboList = $axmud::CLIENT->constLogOrderList;
        my $comboBox = $self->addComboBox($table, undef, \@comboList, '',
            TRUE,               # No 'undef' value used
            1, 4, 10, 11);

        my $button = $self->addButton($table,
            'Toggle', 'Change the setting for the selected logfile', undef,
            4, 6, 10, 11);
        $button->signal_connect('clicked' => sub {

            my $logfile = $comboBox->get_active_text();

            # Update the IV
            $self->session->pseudoCmd('log ' . $logfile, $self->pseudoCmdMode);

            # Refresh the simple list
            $self->logs3Tab_refreshList($slWidget, (scalar @columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub logs3Tab_refreshList {

        # Resets the simple list displayed by $self->logs3Tab
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::list
        #   $columns    - The number of columns
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (
            $hashRef,
            @dataList,
            %hash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->logs3Tab_refreshList', @_);
        }

        # Compile the simple list data
        foreach my $logfile ($axmud::CLIENT->constLogOrderList) {

            push (@dataList,
                $logfile,
                $axmud::CLIENT->ivShow('logPrefHash', $logfile),
                $axmud::CLIENT->ivShow('constLogDescripHash', $logfile),
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub logs4Tab {

        # Logs4 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (@columnList, @columnList2);

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->logs3Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _4', $innerNotebook);

         # Custom months/days
        $self->addLabel($table, '<b>Custom months/days</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of months of the year and days of the week, mostly used to write logfiles</i>',
            1, 12, 1, 2);

        # Add simple lists
        @columnList = (
            'Month', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 6, 2, 8,
            -1, 220);      # Fixed height

        @columnList2 = (
            'Day', 'text',
        );

        my $slWidget2 = $self->addSimpleList($table, undef, \@columnList,
            7, 12, 2, 8,
            -1, 220);      # Fixed height

        # Initialise the lists
        $self->logs4Tab_refreshList($slWidget, $slWidget2);

        # Add editing widgets
        $self->addLabel($table, 'New list of custom months <i>e.g. Gen Feb Mar...</i>',
            1, 6, 8, 9);
        my $entry = $self->addEntry($table, undef, TRUE,
            1, 6, 9, 10);
        my $button = $self->addButton($table,
            'Set', 'Set the list of custom months', undef,
            1, 3, 10, 11);
        my $button2 = $self->addButton($table,
            'Reset', 'Reset the list of custom months', undef,
            3, 6, 10, 11);

        $self->addLabel($table, 'New list of custom days <i>e.g. Lun Mar Mer...</i>',
            7, 12, 8, 9);
        my $entry2 = $self->addEntry($table, undef, TRUE,
            7, 12, 9, 10);
        my $button3 = $self->addButton($table,
            'Set', 'Set the list of custom days', undef,
            7, 9, 10, 11);
        my $button4 = $self->addButton($table,
            'Reset', 'Reset the list of custom days', undef,
            9, 12, 10, 11);

        # (->signal_connects from above)
        $button->signal_connect('clicked' => sub {

            my $string = $entry->get_text();

            if ($string ne '') {

                $self->session->pseudoCmd('setcustommonth ' . $string, $self->pseudoCmdMode);

                # Refresh the lists and reset the entries
                $self->logs4Tab_refreshList($slWidget, $slWidget2);
                $self->resetEntryBoxes($entry, $entry2);
            }
        });
        $button2->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('setcustommonth -r', $self->pseudoCmdMode);

            # Refresh the lists and reset the entries
            $self->logs4Tab_refreshList($slWidget, $slWidget2);
            $self->resetEntryBoxes($entry, $entry2);
        });
        $button3->signal_connect('clicked' => sub {

            my $string = $entry2->get_text();

            if ($string ne '') {

                $self->session->pseudoCmd('setcustomday ' . $string, $self->pseudoCmdMode);

                # Refresh the lists and reset the entries
                $self->logs4Tab_refreshList($slWidget, $slWidget2);
                $self->resetEntryBoxes($entry, $entry2);
            }
        });
        $button4->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('setcustomday -r', $self->pseudoCmdMode);

            # Refresh the lists and reset the entries
            $self->logs4Tab_refreshList($slWidget, $slWidget2);
            $self->resetEntryBoxes($entry, $entry2);
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub logs4Tab_refreshList {

        # Resets the simple lists displayed by $self->logs4Tab
        #
        # Expected arguments
        #   $slWidget, $slWidget2
        #       - The Gtk::Ex::Simple::Lists to reset
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $slWidget2, $check) = @_;

        # Check for improper arguments
        if (! defined $slWidget || ! defined $slWidget2 || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->logs4Tab_refreshList', @_);
        }

        # Reset the simple list
        $self->resetListData($slWidget, [$axmud::CLIENT->customMonthList], 1);
        $self->resetListData($slWidget2, [$axmud::CLIENT->customDayList], 1);

        return 1;
    }

    sub coloursTab {

        # Colours tab - called by $self->setupNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->coloursTab', @_);
        }

        # Tab setup
        # Create a notebook within the main one, so that we have two rows of tabs
        my ($vBox, $innerNotebook) = $self->addInnerNotebookTab('C_olours', $self->notebook);

        # Add tabs to the inner notebook
        $self->colours1Tab($innerNotebook);
        $self->colours2Tab($innerNotebook);
        $self->colours3Tab($innerNotebook);
        $self->colours4Tab($innerNotebook);
        $self->colours5Tab($innerNotebook);

        return 1;
    }

    sub colours1Tab {

        # Colours1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @tagList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->colours1Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _1', $innerNotebook);

        # Axmud colour tags settings
        $self->addLabel($table, '<b>' . $axmud::SCRIPT . ' standard (normal) colour tags</b>',
            0, 8, 0, 1);

        # Import IV from the GA::Client
        @tagList = $axmud::CLIENT->constColourTagList;

        for (my $row = 1; $row <= 8; $row++) {

            $self->colours1Tab_addRow(
                $table,
                $row,
                'colourTagHash',
                'constColourTagHash',
                shift @tagList,
            );
        }

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub colours1Tab_addRow {

        # Called by $self->colours1Tab and ->colours2Tab
        # Adds a single row of labels, entry boxes and buttons to allow configuration of a single
        #   colour tag
        #
        # Expected arguments
        #   $table      - The Gtk2::Table for this tab
        #   $row        - The number of the row in the Gtk2::Table displayed in this tab
        #   $iv         - The IV used, e.g. 'colourTagHash'
        #   $defaultIV  - The default colour used to set this IV, e.g. 'constColourTagHash'
        #   $tag        - The Axmud colour tag to edit, e.g. 'red'
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $table, $row, $iv, $defaultIV, $tag, $check) = @_;

        # Local variables
        my ($rgbColour, $rgbDefault);

        # Check for improper arguments
        if (
            ! defined $table || ! defined $row || ! defined $iv || ! defined $defaultIV
            || ! defined $tag || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->colours1Tab_addRow', @_);
        }

        # Initialise vars
        $rgbColour = $axmud::CLIENT->ivShow($iv, $tag);
        $rgbDefault = $axmud::CLIENT->ivShow($defaultIV, $tag);

        # Colour
        $self->addLabel($table, $tag,
            1, 3, $row, ($row + 1));

        my ($canvas, $canvasObj) = $self->addSimpleCanvas($table, $rgbColour,
            3, 4, $row, ($row + 1));

        my $entry = $self->addEntry($table, undef, FALSE,
            4, 6, $row, ($row + 1), 7, 7);
        $entry->set_text($axmud::CLIENT->ivShow($iv, $tag));

        my $button = $self->addButton($table, 'Change', 'Change this colour', undef,
            6, 7, $row, ($row + 1));
        $button->signal_connect('clicked' => sub {

            # Prompt the user to select a new colour, using the existing colour as an initial value
            my $rgbModify = $self->showColourSelectionDialogue(
                'Set \'' . $tag . '\' tag',
                $rgbColour,
            );

            if ($rgbModify) {

                $canvasObj = $self->fillSimpleCanvas($canvas, $canvasObj, $rgbModify);
                $entry->set_text($rgbModify);
                $rgbColour = $rgbModify;

                # Modify the stored colour tag immediately
                $self->session->pseudoCmd(
                    'setcolour ' . $tag . ' ' . $rgbModify,
                    $self->pseudoCmdMode,
                );
            }
        });

        # Default colour
        my $button2 = $self->addButton($table, 'Use default:', 'Use the default colour', undef,
            8, 9, $row, ($row + 1));
        $button2->signal_connect('clicked' => sub {

            $canvasObj = $self->fillSimpleCanvas($canvas, $canvasObj, $rgbDefault);
            $entry->set_text($rgbDefault);

            # Modify the stored colour tag immediately
            $self->session->pseudoCmd(
                'setcolour ' . $tag . ' ' . $rgbDefault,
                $self->pseudoCmdMode,
            );
        });

        $self->addSimpleCanvas($table, $rgbDefault,
            9, 10, $row, ($row + 1));

        my $entry2 = $self->addEntry($table, undef, FALSE,
            10, 12, $row, ($row + 1), 7, 7);
        $entry2->set_text($axmud::CLIENT->ivShow($defaultIV, $tag));

        return 1;
    }

    sub colours1Tab_applyAll {

        # Called by $self->colours1Tab and ->colours2Tab
        # Re-applies any colour scheme that uses a standard colour tag (e.g. 'red' instead of
        #   '#FF0000')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my %hash;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->colours1Tab_applyAll', @_);
        }

        # Compile a hash of colour scheme objects that use Axmud standard colour tags
        foreach my $obj (
            sort {lc($a->name) cmp lc($b->name)} ($axmud::CLIENT->ivValues('colourSchemeHash'))
        ) {
            my ($mode, $textFlag, $underlayFlag, $backgroundFlag);

            # (The flags are set to TRUE if the argument is an underlay tag, FALSE if not)
            ($mode, $textFlag) = $axmud::CLIENT->checkColourTags($obj->textColour);
            ($mode, $underlayFlag) = $axmud::CLIENT->checkColourTags($obj->textColour);
            ($mode, $backgroundFlag) = $axmud::CLIENT->checkColourTags($obj->textColour);

            if (! $textFlag || $underlayFlag || ! $backgroundFlag) {

                $hash{$obj->name} = undef;
            }
        }

        if (%hash) {

            # Update every 'internal' window
            foreach my $winObj ($axmud::CLIENT->desktopObj->listGridWins('internal')) {

                foreach my $name (keys %hash) {

                    $winObj->updateColourScheme($name);
                }
            }
        }

        return 1;
    }

    sub colours2Tab {

        # Colours2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @tagList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->colours2Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _2', $innerNotebook);

        # Axmud bold colour tags settings
        $self->addLabel($table, '<b>' . $axmud::SCRIPT . ' standard (bold) colour tags</b>',
            0, 8, 0, 1);

        # Import IV from the GA::Client
        @tagList = $axmud::CLIENT->constBoldColourTagList;

        for (my $row = 1; $row <= 8; $row++) {

            $self->colours1Tab_addRow(
                $table,
                $row,
                'boldColourTagHash',
                'constBoldColourTagHash',
                shift @tagList,
            );
        }

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub colours3Tab {

        # Colours3 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->colours3Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _3', $innerNotebook);

        # xterm-256 colours
        $self->addLabel($table, '<b>xterm-256 colours</b>',
            0, 12, 0, 1);
        $self->addLabel($table, 'Current colour cube:',
            1, 4, 1, 2);
        my $entry = $self->addEntry($table, undef, FALSE,
            4, 8, 1, 2);
        $entry->set_text($axmud::CLIENT->currentColourCube);

        my $button = $self->addButton(
            $table,
            'Switch cube',
            'Switch between xterm and netscape colour cubes', undef,
            8, 12, 1, 2);
        # ->signal_connect appears below

        # Add a simple list
        @columnList = (
            'xterm tag', 'text',
            'colour', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 12,
            -1, 290);      # Fixed height

        # Initialise the list
        $self->colours3Tab_refreshList($slWidget, scalar (@columnList / 2));

        # ->signal_connect from above
        $button->signal_connect('clicked' => sub {

            if ($axmud::CLIENT->currentColourCube eq 'xterm') {
                $self->session->pseudoCmd('setxterm -n', $self->pseudoCmdMode);
            } elsif ($axmud::CLIENT->currentColourCube eq 'netscape') {
                $self->session->pseudoCmd('setxterm -x', $self->pseudoCmdMode);
            }

            # Update widgets
            $entry->set_text($axmud::CLIENT->currentColourCube);
            $self->colours3Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub colours3Tab_refreshList {

        # Called by $self->colours3Tab to refresh the Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::List
        #   $columns    - The number of columns in the list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (
            @dataList,
            %hash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->colours3Tab_refreshList',
                @_,
            );
        }

        # Import the IV (for speed)
        %hash = $axmud::CLIENT->xTermColourHash;

        # Compile the simple list data
        for (my $count = 0; $count < 256; $count++) {

            my $tag = 'x' . $count;

            push (@dataList,
                $tag,
                $hash{$tag},
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub colours4Tab {

        # Colours4 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @comboList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->colours4Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _4', $innerNotebook);

        # Import a list of standard colour tags
        @comboList = ($axmud::CLIENT->constColourTagList, $axmud::CLIENT->constBoldColourTagList);

        # System message colours
        $self->addLabel($table, '<b>System message colours</b>',
            0, 12, 0, 1);

        $self->colours4Tab_addRow(
            $table,
            1,
            'customInsertCmdColour',
            'constInsertCmdColour',
            '-c',
            'World command colour',
            \@comboList,
        );

        $self->colours4Tab_addRow(
            $table,
            2,
            'customShowTextColour',
            'constShowTextColour',
            '-m',
            'System message colour',
            \@comboList,
        );

        $self->colours4Tab_addRow(
            $table,
            3,
            'customShowErrorColour',
            'constShowErrorColour',
            '-e',
            'System error colour',
            \@comboList,
        );

        $self->colours4Tab_addRow(
            $table,
            4,
            'customShowWarningColour',
            'constShowWarningColour',
            '-w',
            'System warning colour',
            \@comboList,
        );

        $self->colours4Tab_addRow(
            $table,
            5,
            'customShowDebugColour',
            'constShowDebugColour',
            '-d',
            'System debug colour',
            \@comboList,
        );

        $self->colours4Tab_addRow(
            $table,
            6,
            'customShowImproperColour',
            'constShowImproperColour',
            '-i',
            'System improper args colour',
            \@comboList,
        );

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub colours4Tab_addRow {

        # Called by $self->colours4Tab
        # Adds a single row of labels, entry boxes and buttons to allow configuration of a single
        #   system colour
        #
        # Expected arguments
        #   $table      - The Gtk2::Table for this tab
        #   $row        - The number of the row in the Gtk2::Table displayed in this tab
        #   $iv         - The IV used, e.g. 'customShowTextColour'
        #   $defaultIV  - The default colour used to set this IV, e.g. 'constShowTextColour'
        #   $switch     - Switch used in ';setsystemcolour' for this IV
        #   $descrip    - A short description, e.g. 'System message colour'
        #   $listRef    - Reference to a list of standard colour tags to display in a combo
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $table, $row, $iv, $defaultIV, $switch, $descrip, $listRef, $check) = @_;

        # Local variables
        my ($colour, $default);

        # Check for improper arguments
        if (
            ! defined $table || ! defined $row || ! defined $iv || ! defined $defaultIV
            || ! defined $switch || ! defined $descrip || ! defined $listRef || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->colours4Tab_addRow', @_);
        }

        # Initialise vars
        $colour = $axmud::CLIENT->$iv;
        $default = $axmud::CLIENT->$defaultIV;

        # Colour
        $self->addLabel($table, $descrip,
            1, 3, $row, ($row + 1));

        my ($canvas, $canvasObj) = $self->addSimpleCanvas($table, $colour,
            3, 4, $row, ($row + 1));

        my $entry = $self->addEntry($table, undef, FALSE,
            4, 6, $row, ($row + 1), 7, 7);
        $entry->set_text($colour);

        my $comboBox = $self->addComboBox($table, undef, $listRef, 'Change:',
            TRUE,               # No 'undef' value used
            6, 8, $row, ($row + 1));
        $comboBox->signal_connect('changed' => sub {

            my $modColour = $comboBox->get_active_text();

            if ($modColour ne 'Change:') {

                $canvasObj = $self->fillSimpleCanvas($canvas, $canvasObj, $modColour);
                $entry->set_text($modColour);
                $colour = $modColour;

                # Update IVs immediately
                $self->session->pseudoCmd(
                    'setsystemcolour ' . $switch . ' ' . $modColour,
                    $self->pseudoCmdMode,
                );

                # Need to reset the combo, too
                $comboBox->set_active(0);
            }
        });

        # Default colour
        my $button = $self->addButton($table, 'Use default:', 'Use the default colour', undef,
            8, 10, $row, ($row + 1));
        $button->signal_connect('clicked' => sub {

            $canvasObj = $self->fillSimpleCanvas($canvas, $canvasObj, $default);
            $entry->set_text($default);

            # Update IVs immediately
            $self->session->pseudoCmd(
                'setsystemcolour ' . $switch,
                $self->pseudoCmdMode,
            );
        });

        $self->addSimpleCanvas($table, $default,
            10, 11, $row, ($row + 1));

        my $entry2 = $self->addEntry($table, undef, FALSE,
            11, 13, $row, ($row + 1), 7, 7);
        $entry2->set_text($default);

        return 1;
    }

    sub colours5Tab {

        # Colours5 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (
            @columnList, @list, @comboList,
            %comboHash,
        );

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->colours5Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _5', $innerNotebook);

        # Colour schemes
        $self->addLabel($table, '<b>Colour schemes</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>List of colour schemes used by various windows</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Standard', 'bool',
            'Name', 'text',
            'Text', 'text',
            'Underlay', 'text',
            'Background', 'text',
            'Font', 'text',
            'Font size', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 230);      # Fixed height

        # Initialise the list
        $self->colours5Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add entry boxes and editing buttons
        $self->addLabel($table, 'Name',
            1, 3, 10, 11);
        my $entry = $self->addEntryWithIcon($table, undef, 'string', 1, 16,
            3, 6, 10, 11);

        my $button = $self->addButton($table, 'Add', 'Add the specified colour scheme', undef,
            6, 8, 10, 11);
        $button->signal_connect('clicked' => sub {

            my $name = $entry->get_text();

            if ($self->checkEntryIcon($entry)) {

                # Add this colour scheme
                $self->session->pseudoCmd('addcolourscheme ' . $name, $self->pseudoCmdMode);

                # Refresh the simple list and entry boxes
                $self->colours5Tab_refreshList($slWidget, scalar (@columnList / 2));
                $self->resetEntryBoxes($entry);
            }
        });

        my $button2 = $self->addButton($table, 'Edit...', 'Edit the selected colour scheme', undef,
            8, 10, 10, 11);
        $button2->signal_connect('clicked' => sub {

            my ($name, $obj, $childWinObj);

            ($name) = $self->getSimpleListData($slWidget, 1);
            if (defined $name) {

                $obj = $axmud::CLIENT->ivShow('colourSchemeHash', $name);
                if ($obj) {

                    # Open an 'edit' window for the user to customise the colour scheme
                    $childWinObj = $self->createFreeWin(
                        'Games::Axmud::EditWin::ColourScheme',
                        $self,
                        $self->session,
                        'Edit colour scheme \'' . $name . '\'',
                        $obj,
                        FALSE,              # Not temporary
                    );

                    if ($childWinObj) {

                        # When the 'edit' window closes, update widgets and/or IVs
                        $self->add_childDestroy(
                            $childWinObj,
                            'colours5Tab_refreshList',
                            [$slWidget, (scalar @columnList / 2)],
                        );
                    }

                    # Refresh the simple list and entry boxes
                    $self->colours5Tab_refreshList($slWidget, scalar (@columnList / 2));
                    $self->resetEntryBoxes($entry);
                }
            }
        });

        my $button3 = $self->addButton($table, 'Delete', 'Delete the selected colour scheme', undef,
            10, 12, 10, 11);
        $button3->signal_connect('clicked' => sub {

            my ($name, $obj);

            ($name) = $self->getSimpleListData($slWidget, 1);
            if (defined $name) {

                $obj = $axmud::CLIENT->ivShow('colourSchemeHash', $name);
                if ($obj) {

                    # Delete this colour scheme
                    $self->session->pseudoCmd('deletecolourscheme ' . $name, $self->pseudoCmdMode);

                    # Refresh the simple list and entry boxes
                    $self->colours5Tab_refreshList($slWidget, scalar (@columnList / 2));
                    $self->resetEntryBoxes($entry);
                }
            }
        });

        my $button4 = $self->addButton(
            $table,
            'Update windows',
            'Update \'internal\' windows which use the selected colour scheme',
            undef,
            1, 4, 11, 12);
        $button4->signal_connect('clicked' => sub {

            my ($name, $obj);

            ($name) = $self->getSimpleListData($slWidget, 1);
            if (defined $name) {

                $obj = $axmud::CLIENT->ivShow('colourSchemeHash', $name);
                if ($obj) {

                    # Update 'internal' windows
                    $self->session->pseudoCmd('updatecolourscheme ' . $name, $self->pseudoCmdMode);

                    # Refresh the simple list and entry boxes
                    $self->colours5Tab_refreshList($slWidget, scalar (@columnList / 2));
                    $self->resetEntryBoxes($entry);
                }
            }
        });

        @list = (
            'Apply to \'main\' windows'                         => ' -m',
            'Apply to \'protocol\' windows'                     => ' -p',
            'Apply to \'custom\' windows'                       => ' -c',
            'Apply to this session\'s \'internal\' windows'     => ' -s',
            'Apply to all \'internal\' windows'                 => '',      # Empty switch
        );

        do {
            my ($descrip, $switch);

            $descrip = shift @list;
            $switch = shift @list;

            push (@comboList, $descrip);
            $comboHash{$descrip} = $switch;

        } until (! @list);

        my $combo = $self->addComboBox($table, undef, \@comboList, '',
            TRUE,               # No 'undef' value used
            4, 8, 11, 12);

        my $button5 = $self->addButton(
            $table,
            'Apply',
            'Apply the selected colour scheme',
            undef,
            8, 10, 11, 12);
        $button5->signal_connect('clicked' => sub {

            my ($name, $obj, $descrip, $switch);

            ($name) = $self->getSimpleListData($slWidget, 1);
            if (defined $name) {

                $obj = $axmud::CLIENT->ivShow('colourSchemeHash', $name);
            }

            $descrip = $combo->get_active_text();
            if ($descrip) {

                $switch = $comboHash{$descrip};
            }

            if ($obj && defined $switch) {

                $self->session->pseudoCmd(
                    'applycolourscheme ' . $name . $switch,
                    $self->pseudoCmdMode,
                );
            }
        });

        my $button6 = $self->addButton(
            $table,
            'Reset list',
            'Reset the list of colour schemes',
            undef,
            10, 12, 11, 12);
        $button6->signal_connect('clicked' => sub {

            # Refresh the simple list and entry boxes
            $self->colours5Tab_refreshList($slWidget, scalar (@columnList / 2));
            $self->resetEntryBoxes($entry);
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub colours5Tab_refreshList {

        # Called by $self->colours5Tab to refresh the Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::List
        #   $columns    - The number of columns in the list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (@sortedList, @dataList);

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->colours5Tab_refreshList',
                @_,
            );
        }

        # Get a sorted list of colour schemes
        @sortedList
            = sort {lc($a->name) cmp lc($b->name)} ($axmud::CLIENT->ivValues('colourSchemeHash'));

        # Compile the simple list data
        foreach my $obj (@sortedList) {

            my $flag;

            if (
                $axmud::CLIENT->ivExists('constGridWinTypeHash', $obj->name)
                || $axmud::CLIENT->ivExists('constFreeWinTypeHash', $obj->name)
            ) {
                $flag = TRUE;
            } else {
                $flag = FALSE;
            }

            push (@dataList,
                $flag,
                $obj->name,
                $obj->textColour,
                $obj->underlayColour,
                $obj->backgroundColour,
                $obj->font,
                $obj->fontSize,
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub workspacesTab {

        # Workspaces tab - called by $self->setupNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->workspacesTab', @_);
        }

        # Tab setup
        # Create a notebook within the main one, so that we have two rows of tabs
        my ($vBox, $innerNotebook) = $self->addInnerNotebookTab('_Workspaces', $self->notebook);

        # Add tabs to the inner notebook
        $self->workspaces1Tab($innerNotebook);
        $self->workspaces2Tab($innerNotebook);
        $self->workspaces3Tab($innerNotebook);
        $self->workspaces4Tab($innerNotebook);
        $self->workspaces5Tab($innerNotebook);
        $self->workspaces6Tab($innerNotebook);
        $self->workspaces7Tab($innerNotebook);

        return 1;
    }

    sub workspaces1Tab {

        # Workspaces1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (
            $width, $height,
            @list, @comboList,
            %comboHash,
        );

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->workspaces1Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _1', $innerNotebook);

        # Left column
        $self->addLabel($table, '<b>Workspace (desktop) settings</b>',
            0, 12, 0, 1);

        $self->addLabel($table, 'Maximum workspace width',
            1, 3, 1, 2);
        my $entry = $self->addEntry($table, undef, FALSE,
            3, 6, 1, 2, 8, 8);
        $entry->set_text($axmud::CLIENT->constWorkspaceMaxWidth);

        $self->addLabel($table, 'Maximum workspace height',
            1, 3, 2, 3);
        my $entry2 = $self->addEntry($table, undef, FALSE,
            3, 6, 2, 3, 8, 8);
        $entry2->set_text($axmud::CLIENT->constWorkspaceMaxHeight);

        $self->addLabel($table, 'When adding workspaces,',
            1, 3, 3, 4);

        @list = (
            'move left from default workspace' => '-l',
            'move right from default workspace' => '-r',
            'after default workspace, start from left' => '-b',
            'ffter default workspace, start from right' => '-e',
        );

        do {
            my ($string, $switch);

            $string = shift @list;
            $switch = shift @list;

            $comboHash{$string} = $switch;
            push (@comboList, $string);

        } until (! @list);

        my $combo = $self->addComboBox($table, undef, \@comboList, '',
            TRUE,               # No 'undef' value used
            3, 8, 3, 4);

        my $button = $self->addButton($table,
            'Set', 'Set the default width/height', undef,
            8, 10, 3, 4);
        $button->signal_connect('clicked' => sub {

            my ($string, $switch);

            $string = $combo->get_active_text();
            $switch = $comboHash{$string};
            if ($switch) {

                $self->session->pseudoCmd('setworkspacedirection ' . $switch, $self->pseudoCmdMode);
            }
        });

        # Right column
        $self->addLabel($table, 'Minimum workspace width',
            6, 8, 1, 2);
        my $entry3 = $self->addEntry($table, undef, FALSE,
            8, 12, 1, 2, 8, 8);
        $entry3->set_text($axmud::CLIENT->constWorkspaceMinWidth);

        $self->addLabel($table, 'Minimum workspace height',
            6, 8, 2, 3);
        my $entry4 = $self->addEntry($table, undef, FALSE,
            8, 12, 2, 3, 8, 8);
        $entry4->set_text($axmud::CLIENT->constWorkspaceMinHeight);

        # Bottom section
        $self->addLabel($table, '<b>Window size settings</b>',
            0, 12, 4, 5);

        $width = $axmud::CLIENT->constWorkspaceMaxWidth;
        $height = $axmud::CLIENT->constWorkspaceMaxHeight;

        $self->addLabel($table, 'Default width for \'main\' windows (range 100-' . $width . ')',
            1, 6, 5, 6);
        my $entry5 = $self->addEntryWithIcon($table, undef, 'int', 100, $width,
            6, 8, 5, 6, 8, 8);
        $entry5->set_text($axmud::CLIENT->customMainWinWidth);

        $self->addLabel($table, 'Default height for \'main\' windows (range 100-' . $height . ')',
            1, 6, 6, 7);
        my $entry6 = $self->addEntryWithIcon($table, undef, 'int', 100, $height,
            6, 8, 6, 7, 8, 8);
        $entry6->set_text($axmud::CLIENT->customMainWinHeight);

        my $button2 = $self->addButton($table,
            'Set', 'Set the default width/height', undef,
            8, 10, 6, 7);
        $button2->signal_connect('clicked' => sub {

            if ($self->checkEntryIcon($entry5, $entry6)) {

                $self->session->pseudoCmd(
                    'setwindowsize -m ' . $entry5->get_text() . ' ' . $entry6->get_text(),
                    $self->pseudoCmdMode,
                );

                $entry5->set_text($axmud::CLIENT->customMainWinWidth);
                $entry6->set_text($axmud::CLIENT->customMainWinHeight);
            }
        });

        my $button3 = $self->addButton($table,
            'Reset', 'Reset the default width/height ', undef,
            10, 12, 6, 7);
        $button3->signal_connect('clicked' => sub {

            $self->session->pseudoCmd(
                'setwindowsize -m',
                $self->pseudoCmdMode,
            );

            $entry5->set_text($axmud::CLIENT->customMainWinWidth);
            $entry6->set_text($axmud::CLIENT->customMainWinHeight);
        });

        $self->addLabel(
            $table,
            'Default width for other \'grid\' windows (range 100-' . $width . ')',
            1, 6, 7, 8);
        my $entry7 = $self->addEntryWithIcon($table, undef, 'int', 100, $width,
            6, 8, 7, 8, 8, 8);
        $entry7->set_text($axmud::CLIENT->customGridWinWidth);

        $self->addLabel(
            $table,
            'Default height for other \'grid\' windows (range 100-' . $height . ')',
            1, 6, 8, 9);
        my $entry8 = $self->addEntryWithIcon($table, undef, 'int', 100, $height,
            6, 8, 8, 9, 8, 8);
        $entry8->set_text($axmud::CLIENT->customGridWinHeight);

        my $button4 = $self->addButton($table,
            'Set', 'Set the default width/height', undef,
            8, 10, 8, 9);
        $button4->signal_connect('clicked' => sub {

            if ($self->checkEntryIcon($entry7, $entry8)) {

                $self->session->pseudoCmd(
                    'setwindowsize -g ' . $entry7->get_text() . ' ' . $entry8->get_text(),
                    $self->pseudoCmdMode,
                );

                $entry7->set_text($axmud::CLIENT->customGridWinWidth);
                $entry8->set_text($axmud::CLIENT->customGridWinHeight);
            }
        });

        my $button5 = $self->addButton($table,
            'Reset', 'Reset the default width/height ', undef,
            10, 12, 8, 9);
        $button5->signal_connect('clicked' => sub {

            $self->session->pseudoCmd(
                'setwindowsize -g',
                $self->pseudoCmdMode,
            );

            $entry7->set_text($axmud::CLIENT->customGridWinWidth);
            $entry8->set_text($axmud::CLIENT->customGridWinHeight);
        });

        $self->addLabel($table, 'Default width for \'free\' windows',
            1, 6, 9, 10);
        my $entry9 = $self->addEntry($table, undef, FALSE,
            6, 8, 9, 10, 8, 8);
        $entry9->set_text($axmud::CLIENT->constFreeWinWidth);

        $self->addLabel($table, 'Default height for \'free\' windows',
            1, 6, 10, 11);
        my $entry10 = $self->addEntry($table, undef, FALSE,
            6, 8, 10, 11, 8, 8);
        $entry10->set_text($axmud::CLIENT->constFreeWinHeight);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub workspaces2Tab {

        # Workspaces2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->workspaces2Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _2', $innerNotebook);

        # Workspace panel sizes
        $self->addLabel($table, '<b>Workspace panel sizes</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $table,
            '<i>Custom panel sizes. If set, used for all workspaces. If not set, sizes are'
            . ' detected in all workspaces</i>',
            1, 12, 1, 2);

        $self->workspaces2Tab_panelRow($table, 'Left panel', 'customPanelLeftSize', '-l', 2);
        $self->workspaces2Tab_panelRow($table, 'Right panel', 'customPanelRightSize', '-r', 3);
        $self->workspaces2Tab_panelRow($table, 'Top panel', 'customPanelTopSize', '-t', 4);
        $self->workspaces2Tab_panelRow($table, 'Bottom panel', 'customPanelBottomSize', '-b', 5);

        # Window controls sizes
        $self->addLabel($table, '<b>Window controls sizes</b>',
            0, 12, 6, 7);
        $self->addLabel(
            $table,
            '<i>Window controls sizes. If all are set, used for all workspaces. If any are not set,'
            . ' sizes are detected in all workspaces</i>',
            1, 12, 7, 8);

        $self->workspaces2Tab_controlsRow($table, 'Left edge', 'customControlsLeftSize', '-l', 8);
        $self->workspaces2Tab_controlsRow($table, 'Right edge', 'customControlsRightSize', '-r', 9);
        $self->workspaces2Tab_controlsRow($table, 'Top edge', 'customControlsTopSize', '-t', 10);
        $self->workspaces2Tab_controlsRow(
            $table,
            'Bottom edge',
            'customControlsBottomSize',
            '-b',
            11,
        );

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub workspaces2Tab_panelRow {

        # Called by $self->workspaces2Tab; adds a row of widgets for a single GA::Client IV
        #
        # Expected arguments
        #   $table  - The Gtk2::Table for this tab
        #   $text   - The label text to use, e.g. 'Left panel'
        #   $iv     - The IV set by these widgets, e.g. ->customPanelLeftSize
        #   $switch - The switch to use in a ';setpanel' command, e.g. '-l'
        #   $row    - The row number on the Gtk2::Table
        #
        # Return values
        #   'undef' on improper arguments or if the check fails
        #   1 otherwise

        my ($self, $table, $text, $iv, $switch, $row, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $text || ! defined $iv || ! defined $switch
            || ! defined $row  || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->workspaces2Tab_panelRow',
                @_
            );
        }

        $self->addLabel($table, $text,
            1, 3, $row, ($row + 1));

        my $entry = $self->addEntry($table, undef, FALSE,
            3, 6, $row, ($row + 1), 16, 16);
        if (! defined ($axmud::CLIENT->$iv)) {
            $entry->set_text('(not set)');
        } else {
            $entry->set_text($axmud::CLIENT->$iv);
        }

        my $entry2 = $self->addEntryWithIcon(
            $table, undef, 'int', 0, undef,
            6, 8, $row, ($row + 1), 8, 8);

        my $button = $self->addButton($table,
            'Set', 'Set the panel size', undef,
            8, 10, $row, ($row + 1));
        $button->signal_connect('clicked' => sub {

            my $size = $entry2->get_text();
            if ($self->checkEntryIcon($entry2)) {

                $self->session->pseudoCmd(
                    'setpanel ' . $switch . ' ' . $size,
                    $self->pseudoCmdMode,
                );
            }

            if (! defined ($axmud::CLIENT->$iv)) {
                $entry->set_text('(not set)');
            } else {
                $entry->set_text($axmud::CLIENT->$iv);
            }

            $entry2->set_text('');
        });

        my $button2 = $self->addButton($table,
            'Don\'t use', 'Detect this panel size on every workspace', undef,
            10, 12, $row, ($row + 1));
        $button2->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('setpanel ' . $switch, $self->pseudoCmdMode);

            $entry->set_text('(not set)');
            $entry2->set_text('');
        });

        return 1;
    }

    sub workspaces2Tab_controlsRow {

        # Called by $self->workspaces2Tab; adds a row of widgets for a single GA::Client IV
        #
        # Expected arguments
        #   $table  - The Gtk2::Table for this tab
        #   $text   - The label text to use, e.g. 'Left side'
        #   $iv     - The IV set by these widgets, e.g. ->customControlsLeftSize
        #   $switch - The switch to use in a ';setwindowcontrols' command, e.g. '-l'
        #   $row    - The row number on the Gtk2::Table
        #
        # Return values
        #   'undef' on improper arguments or if the check fails
        #   1 otherwise

        my ($self, $table, $text, $iv, $switch, $row, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $text || ! defined $iv || ! defined $switch
            || ! defined $row  || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->workspaces2Tab_controlsRow',
                @_,
            );
        }

        $self->addLabel($table, $text,
            1, 3, $row, ($row + 1));

        my $entry = $self->addEntry($table, undef, FALSE,
            3, 6, $row, ($row + 1), 16, 16);
        if (! defined ($axmud::CLIENT->$iv)) {
            $entry->set_text('(not set)');
        } else {
            $entry->set_text($axmud::CLIENT->$iv);
        }

        my $entry2 = $self->addEntryWithIcon(
            $table, undef, 'int', 0, undef,
            6, 8, $row, ($row + 1), 8, 8);

        my $button = $self->addButton($table,
            'Set', 'Set the window controls size', undef,
            8, 10, $row, ($row + 1));
        $button->signal_connect('clicked' => sub {

            my $size = $entry2->get_text();
            if ($self->checkEntryIcon($entry2)) {

                $self->session->pseudoCmd(
                    'setwindowcontrols ' . $switch . ' ' . $size,
                    $self->pseudoCmdMode,
                );
            }

            if (! defined ($axmud::CLIENT->$iv)) {
                $entry->set_text('(not set)');
            } else {
                $entry->set_text($axmud::CLIENT->$iv);
            }

            $entry2->set_text('');
        });

        my $button2 = $self->addButton($table,
            'Don\'t use', 'Detect this window controls size on every workspace', undef,
            10, 12, $row, ($row + 1));
        $button2->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('setwindowcontrols ' . $switch, $self->pseudoCmdMode);

            $entry->set_text('(not set)');
            $entry2->set_text('');
        });

        return 1;
    }

    sub workspaces3Tab {

        # Workspaces3 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (
            $title,
            @columnList, @columnList2, @comboList,
        );

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->workspaces3Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _3', $innerNotebook);

        # Workspaces
        $self->addLabel($table, '<b>Workspaces</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of workspace objects (one for each workspace in use by ' . $axmud::SCRIPT
            . ')</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Object num', 'int',
            'Default', 'bool',
            'System num', 'text',
            'System name', 'text',
            'Width', 'int',
            'Height', 'int',
            'Default zonemap', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 6,
            -1, 110);           # Fixed height

        # Initialise the list
        $self->workspaces3Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add another simple list
        $self->addLabel($table,
            '<i>List of available (but unused) workspaces</i>',
            1, 12, 7, 8);

        @columnList2 = (
            'System num', 'int',
            'System name', 'text',
        );

        my $slWidget2 = $self->addSimpleList($table, undef, \@columnList2,
            1, 12, 8, 12,
            -1, 110);           # Fixed height

        # Initialise the list
        $self->workspaces3Tab_refreshList2($slWidget2, scalar (@columnList2 / 2));

        # Add editing widgets for both simple lists
        my $button = $self->addButton($table, 'View', 'View this workspace\'s settings', undef,
            1, 3, 6, 7);
        $button->signal_connect('clicked' => sub {

            my ($number, $obj);

            ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                $obj = $axmud::CLIENT->desktopObj->ivShow('workspaceHash', $number);
                if ($obj) {

                    # Open an 'edit' window for the selected workspace object
                    $self->createFreeWin(
                        'Games::Axmud::EditWin::Workspace',
                        $self,
                        $self->session,,
                        'Edit workspace object #' . $obj->number,
                        $obj,
                        FALSE,                          # Not temporary
                    );
                }
            }
        });

        my $button2 = $self->addButton(
            $table,
            'Remove',
            'Stop using this workspace for ' . $axmud::SCRIPT . ' windows',
            undef,
            3, 5, 6, 7);
        $button2->signal_connect('clicked' => sub {

            my ($num) = $self->getSimpleListData($slWidget, 0);
            if (defined $num) {

                $self->session->pseudoCmd(
                    'removeworkspace  ' . $num,
                    $self->pseudoCmdMode,
                );
            }

            # Update simple lists
            $self->workspaces3Tab_refreshList($slWidget, scalar (@columnList / 2));
            $self->workspaces3Tab_refreshList2($slWidget2, scalar (@columnList2 / 2));
        });

        $title = '(Optional) default zonemap';
        @comboList = (sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('zonemapHash')));

        my $combo = $self->addComboBox($table, undef, \@comboList, $title,
            TRUE,               # No 'undef' value used
            1, 5, 12, 13);

        my $button3 = $self->addButton($table, 'Use', 'Use the selected workspace', undef,
            5, 7, 12, 13);
        $button3->signal_connect('clicked' => sub {

            my ($num, $name, $zonemap, $string);

            ($num) = $self->getSimpleListData($slWidget2, 0);
            ($name) = $self->getSimpleListData($slWidget2, 1);
            $zonemap = $combo->get_active_text();
            if ($zonemap && $zonemap eq $title) {

                $zonemap = undef;
            }

            if ($zonemap) {
                $string = ' -z ' . $zonemap;
            } else {
                $string = '';
            }

            # Use either system number or name, depending on which is available (probably, both of
            #   them are)
            if (defined $num) {

                $self->session->pseudoCmd(
                    'useworkspace ' . $num . $string,
                    $self->pseudoCmdMode,
                );

            } elsif (defined $name) {

                $self->session->pseudoCmd(
                    'useworkspace ' . $name . $string,
                    $self->pseudoCmdMode,
                );
            }

            # Update simple lists
            $self->workspaces3Tab_refreshList($slWidget, scalar (@columnList / 2));
            $self->workspaces3Tab_refreshList2($slWidget2, scalar (@columnList2 / 2));
        });

        my $button4 = $self->addButton(
            $table,
            'Refresh lists',
            'Refresh the lists of workspaces',
            undef,
            10, 12, 12, 13);
        $button4->signal_connect('clicked' => sub {

            # Update simple lists
            $self->workspaces3Tab_refreshList($slWidget, scalar (@columnList / 2));
            $self->workspaces3Tab_refreshList2($slWidget2, scalar (@columnList2 / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub workspaces3Tab_refreshList {

        # Called by $self->workspaces3Tab to refresh the first Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::List
        #   $columns    - The number of columns in the list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my @dataList;

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->workspaces3Tab_refreshList',
                @_,
            );
        }

        # Compile the simple list data
        foreach my $obj (
            sort {$a->number <=> $b->number} ($axmud::CLIENT->desktopObj->ivValues('workspaceHash'))
        ) {
            my ($flag, $number, $name);

            if (! $obj->number) {
                $flag = TRUE;
            } else {
                $flag = FALSE;
            }

            if ($obj->wnckWorkspace) {

                $number = $obj->wnckWorkspace->get_number();
                $name = $obj->wnckWorkspace->get_name();

            } else {

                $number = $name = '(unknown)';
            }

            push (@dataList,
                $obj->number,
                $flag,
                $number,
                $name,
                $obj->currentWidth,
                $obj->currentHeight,
                $obj->defaultZonemap,
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub workspaces3Tab_refreshList2 {

        # Called by $self->workspaces3Tab to refresh the second Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::List
        #   $columns    - The number of columns in the list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (@workspaceList, @dataList);

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->workspaces3Tab_refreshList2',
                @_,
            );
        }

        # Get an ordered list of unused workspaces
        @workspaceList = $axmud::CLIENT->desktopObj->detectUnusedWorkspaces();

        # Compile the simple list data
        foreach my $workspace (@workspaceList) {

            push (@dataList,
                $workspace->get_number(),
                $workspace->get_name(),
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub workspaces4Tab {

        # Workspaces4 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (
            $defaultString,
            @columnList, @comboList,
        );

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->workspaces4Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _4', $innerNotebook);

        # Initial workspaces
        $self->addLabel($table, '<b>Initial workspaces</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of workspaces to use when ' . $axmud::SCRIPT . ' starts</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Number', 'int',
            'Default zonemap', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 240);           # Fixed height

        # Initialise the list
        $self->workspaces4Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add editing widgets
        $self->addLabel($table, 'Zonemap',
            1, 3, 10, 11);

        @comboList = sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('zonemapHash'));
        $defaultString = '(use default zonemap)';
        unshift (@comboList, $defaultString);

        my $combo = $self->addComboBox($table, undef, \@comboList, '',
            TRUE,               # No 'undef' value used
            3, 6, 10, 11);

        my $button = $self->addButton(
            $table,
            'Add workspace',
            'Add an initial workspace to those used when ' . $axmud::SCRIPT . ' starts',
            undef,
            6, 9, 10, 11);
        $button->signal_connect('clicked' => sub {

            my $zonemap = $combo->get_active_text();
            if ($zonemap eq $defaultString) {
                $self->session->pseudoCmd('addinitialworkspace', $self->pseudoCmdMode);
            } else {
                $self->session->pseudoCmd('addinitialworkspace ' . $zonemap, $self->pseudoCmdMode);
            }

            # Refresh the list
            $self->workspaces4Tab_refreshList($slWidget, scalar (@columnList / 2));
            $combo->set_active(0);
        });

        my $button2 = $self->addButton(
            $table,
            'Modify workspace',
            'Modify the selected workspace to use this zonemap',
            undef,
            9, 12, 10, 11);
        $button2->signal_connect('clicked' => sub {

            my ($number, $zonemap);

            ($number) = $self->getSimpleListData($slWidget, 0);
            $zonemap = $combo->get_active_text();

            if (defined $number) {

                if ($zonemap eq $defaultString) {

                    $self->session->pseudoCmd(
                        'modifyinitialworkspace ' . $number,
                        $self->pseudoCmdMode,
                    );

                } else {

                    $self->session->pseudoCmd(
                        'modifyinitialworkspace ' . $number . ' ' . $zonemap,
                        $self->pseudoCmdMode,
                    );
                }
            }

            # Refresh the list
            $self->workspaces4Tab_refreshList($slWidget, scalar (@columnList / 2));
            $combo->set_active(0);
        });

        my $button3 = $self->addButton(
            $table,
            'Delete workspace',
            'Delete the selected initial workspace',
            undef,
            6, 9, 11, 12);
        $button3->signal_connect('clicked' => sub {

            my ($number) = $self->getSimpleListData($slWidget, 0);

            if (defined $number) {

                $self->session->pseudoCmd(
                    'deleteinitialworkspace ' . $number,
                    $self->pseudoCmdMode,
                );
            }

            # Refresh the list
            $self->workspaces4Tab_refreshList($slWidget, scalar (@columnList / 2));
            $combo->set_active(0);
        });

        my $button4 = $self->addButton(
            $table,
            'Refresh list',
            'Refresh the list of initial workspaces',
            undef,
            9, 12, 11, 12);
        $button3->signal_connect('clicked' => sub {

            # Refresh the list
            $self->workspaces4Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub workspaces4Tab_refreshList {

        # Called by $self->workspaces4Tab to refresh the first Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::List
        #   $columns    - The number of columns in the list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my @dataList;

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->workspaces4Tab_refreshList',
                @_,
            );
        }

        # Compile the simple list data
        foreach my $number (sort {$a <=> $b} ($axmud::CLIENT->ivKeys('initWorkspaceHash'))) {

            my $zonemap = $axmud::CLIENT->ivShow('initWorkspaceHash', $number);
            if (! defined $zonemap) {

                $zonemap = '(default zonemap)';
            }

            push (@dataList,
                $number,
                $zonemap,
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub workspaces5Tab {

        # Workspaces5 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (
            $allString, $defaultString,
            @columnList, @emptyList,
        );

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->workspaces5Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _5', $innerNotebook);

        # Workspace grids
        $self->addLabel($table, '<b>Workspace grids</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of workspace grids on which \'grid\' windows are arranged</i>',
            1, 6, 1, 2);
        my $checkButton = $self->addCheckButton($table, undef, FALSE,
            8, 9, 1, 2);
        $checkButton->set_active($axmud::CLIENT->activateGridFlag);
        $self->addLabel($table, 'Grids are activated in general',
            9, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Workspace', 'int',
            'Grid num', 'int',
            'Session', 'text',
            'Zonemap', 'text',
            'Layers', 'int',
            'Max', 'int',
            'No. zones', 'int',
            'No. windows', 'int',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 9,
            -1, 200);           # Fixed height

        # Initialise the list
        $self->workspaces5Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add editing widgets
        $self->addLabel($table, 'Workspace:',
            1, 3, 9, 10);
        my $combo = $self->addComboBox($table, undef, \@emptyList, '',
            TRUE,               # No 'undef' value used
            3, 6, 9, 10);
        $allString = '(all workspaces)';
        $self->workspaces5Tab_resetCombo($combo, $allString);

        $self->addLabel($table, 'Default zonemap:',
            6, 9, 9, 10);
        my $combo2 = $self->addComboBox($table, undef, \@emptyList, '',
            TRUE,               # No 'undef' value used
            9, 12, 9, 10);
        $defaultString = '(' . $axmud::SCRIPT . ' chooses a zonemap)';
        $self->workspaces5Tab_resetCombo2($combo2, $defaultString);

        my $button = $self->addButton(
            $table,
            'Activate grids',
            'Activate workspace grid(s) on the specified workspace using the specified default'
            . ' zonemap',
            undef,
            1, 3, 10, 11);
        $button->signal_connect('clicked' => sub {

            my ($cmd, $number, $zonemap);

            $cmd = 'activategrid';

            $number = $combo->get_active_text();
            if ($number ne $allString) {

                $cmd .= ' ' . $number;
            }

            $zonemap = $combo2->get_active_text();
            if ($zonemap ne $defaultString) {

                $cmd .= ' -z ' . $zonemap;
            }

            $self->session->pseudoCmd($cmd, $self->pseudoCmdMode);

            # Refresh the list
            $self->workspaces5Tab_refreshList($slWidget, scalar (@columnList / 2));
            # Update widgets
            $self->workspaces5Tab_resetCombo($combo, $allString);
            $self->workspaces5Tab_resetCombo2($combo2, $defaultString);
            $checkButton->set_active($axmud::CLIENT->activateGridFlag);
        });

        my $button2 = $self->addButton(
            $table,
            'Disactivate grids',
            'Disactivate workspace grid(s) on the specified workspace',
            undef,
            3, 6, 10, 11);
        $button2->signal_connect('clicked' => sub {

            my ($cmd, $number);

            $cmd = 'disactivategrid';

            $number = $combo->get_active_text();
            if ($number ne $allString) {

                $cmd .= ' ' . $number;
            }

            $self->session->pseudoCmd($cmd, $self->pseudoCmdMode);

            # Refresh the list
            $self->workspaces5Tab_refreshList($slWidget, scalar (@columnList / 2));
            # Update widgets
            $self->workspaces5Tab_resetCombo($combo, $allString);
            $self->workspaces5Tab_resetCombo2($combo2, $defaultString);
            $checkButton->set_active($axmud::CLIENT->activateGridFlag);
        });

        my $button3 = $self->addButton(
            $table,
            'Reset selected grids',
            'Reset selected workspace grid using the specified default zonemap',
            undef,
            6, 9, 10, 11);
        $button3->signal_connect('clicked' => sub {

            my ($number, $cmd, $zonemap);

            ($number) = $self->getSimpleListData($slWidget, 1);
            if (defined $number) {

                $cmd = 'resetgrid ' . $number;

                $zonemap = $combo2->get_active_text();
                if ($zonemap ne $defaultString) {

                    $cmd .= ' ' . $zonemap;
                }

                $self->session->pseudoCmd($cmd, $self->pseudoCmdMode);
            }

            # Refresh the list
            $self->workspaces5Tab_refreshList($slWidget, scalar (@columnList / 2));
            # Update widgets
            $self->workspaces5Tab_resetCombo($combo, $allString);
            $self->workspaces5Tab_resetCombo2($combo2, $defaultString);
            $checkButton->set_active($axmud::CLIENT->activateGridFlag);
        });

        my $button4 = $self->addButton(
            $table,
            'Reset grids',
            'Reset workspace grid(s) on the specified workspace using the specified default'
            . ' zonemap',
            undef,
            9, 12, 10, 11);
        $button4->signal_connect('clicked' => sub {

            my ($cmd, $number, $zonemap);

            $cmd = 'resetgrid';

            $number = $combo->get_active_text();
            if (defined $number && $number ne $allString) {

                $cmd .= ' -w ' . $number;

                $zonemap = $combo2->get_active_text();
                if ($zonemap ne $defaultString) {

                    $cmd .= ' ' . $zonemap;
                }

                $self->session->pseudoCmd($cmd, $self->pseudoCmdMode);
            }

            # Refresh the list
            $self->workspaces5Tab_refreshList($slWidget, scalar (@columnList / 2));
            # Update widgets
            $self->workspaces5Tab_resetCombo($combo, $allString);
            $self->workspaces5Tab_resetCombo2($combo2, $defaultString);
            $checkButton->set_active($axmud::CLIENT->activateGridFlag);
        });

        my $button5 = $self->addButton(
            $table,
            'View selected grid',
            'View settings for the selected workspace grid',
            undef,
            6, 9, 11, 12);
        $button5->signal_connect('clicked' => sub {

            my ($number, $obj);

            ($number) = $self->getSimpleListData($slWidget, 1);
            if (defined $number) {

                $obj = $axmud::CLIENT->desktopObj->ivShow('gridHash', $number);
                if ($obj) {

                    # Open an 'edit' window to edit the workspace grid
                    $self->createFreeWin(
                        'Games::Axmud::EditWin::WorkspaceGrid',
                        $self,
                        $self->session,
                        'Edit workspace grid #' . $number,
                        $obj,
                        FALSE,                          # Not temporary
                    );
                }
            }
        });

        my $button6 = $self->addButton(
            $table,
            'Refresh list',
            'Refresh the list of workspace grids',
            undef,
            9, 12, 11, 12);
        $button6->signal_connect('clicked' => sub {

            # Refresh the list
            $self->workspaces5Tab_refreshList($slWidget, scalar (@columnList / 2));
            # Update widgets
            $self->workspaces5Tab_resetCombo($combo, $allString);
            $self->workspaces5Tab_resetCombo2($combo2, $defaultString);
            $checkButton->set_active($axmud::CLIENT->activateGridFlag);
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub workspaces5Tab_refreshList {

        # Called by $self->workspaces5Tab to refresh the first Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::List
        #   $columns    - The number of columns in the list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my @dataList;

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->workspaces5Tab_refreshList',
                @_,
            );
        }

        # Compile the simple list data
        foreach my $obj (
            sort {
                if ($a->workspaceObj->number != $b->workspaceObj->number) {
                    return $a->workspaceObj->number <=> $b->workspaceObj->number;
                } else {
                    return $a->number <=> $b->number;
                }
            }
            ($axmud::CLIENT->desktopObj->ivValues('gridHash'))
        ) {
            my $string;

            if ($obj->owner) {
                $string = $obj->owner->number;
            } else {
                $string = '(shared)';
            }

            push (@dataList,
                $obj->workspaceObj->number,
                $obj->number,
                $string,
                $obj->zonemap,
                $obj->currentLayer,
                $obj->maxLayers,
                $obj->ivPairs('zoneHash'),
                $obj->ivPairs('gridWinHash'),
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub workspaces5Tab_resetCombo {

        # Called by $self->workspaces5Tab to reset the contents of the first combobox
        #
        # Expected arguments
        #   $combo      - The combobox whose contents should be reset
        #   $title      - The title used in the combobox
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $combo, $title, $check) = @_;

        # Local variables
        my @comboList;

        # Check for improper arguments
        if (! defined $combo || ! defined $title || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->workspaces5Tab_resetCombo',
                @_,
            );
        }

        # Compile a list of combobox items
        @comboList = sort {$a <=> $b} ($axmud::CLIENT->desktopObj->ivKeys('workspaceHash'));
        unshift (@comboList, $title);

        # Reset the combobox
        $self->resetComboBox($combo, @comboList);

        return 1;
    }

    sub workspaces5Tab_resetCombo2 {

        # Called by $self->workspaces5Tab to reset the contents of the second combobox
        #
        # Expected arguments
        #   $combo      - The combobox whose contents should be reset
        #   $title      - The title used in the combobox
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $combo, $title, $check) = @_;

        # Local variables
        my @comboList;

        # Check for improper arguments
        if (! defined $combo || ! defined $title || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->workspaces5Tab_resetCombo2',
                @_,
            );
        }

        # Compile a list of combobox items
        @comboList = sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('zonemapHash'));
        unshift (@comboList, $title);

        # Reset the combobox
        $self->resetComboBox($combo, @comboList);

        return 1;
    }

    sub workspaces6Tab {

        # Workspaces6 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->workspaces6Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _6', $innerNotebook);

        # General workspace grid settings
        $self->addLabel($table, '<b>General workspace grid settings</b>',
            0, 12, 0, 1);

        $self->addLabel($table, 'Gridblock size (pixels)',
            1, 3, 1, 2);
        my $entry = $self->addEntryWithIcon($table, undef, 'int', 1, 100,
            3, 6, 1, 2, 4, 4);
        $entry->set_text($axmud::CLIENT->gridBlockSize);

        my $button = $self->addButton($table, 'Set size', 'Set the standard gridblock size', undef,
            6, 9, 1, 2);
        $button->signal_connect('clicked' => sub {

            if ($self->checkEntryIcon($entry)) {

                # Set gridblock size
                $self->session->pseudoCmd(
                    'setgrid -b ' . $entry->get_text(),
                    $self->pseudoCmdMode,
                );

                # Update the entry box
                $entry->set_text($axmud::CLIENT->gridBlockSize);
            }
        });

        my $button2 = $self->addButton(
            $table, 'Reset size', 'Reset the standard gridblock size', undef,
            9, 12, 1, 2);
        $button2->signal_connect('clicked' => sub {

            # Reset gridblock size
            $self->session->pseudoCmd('setgrid -b', $self->pseudoCmdMode);

            # Update the entry box
            $entry->set_text($axmud::CLIENT->gridBlockSize);
        });

        $self->addLabel($table, 'Max grid gap (gridblocks)',
            1, 3, 2, 3);
        my $entry2 = $self->addEntryWithIcon($table, undef, 'int', 0, 100,
            3, 6, 2, 3, 4, 4);
        $entry2->set_text($axmud::CLIENT->gridGapMaxSize);

        my $button3 = $self->addButton($table,
            'Set size',
            'Set the maximum size of the gap in the grid that is automatically filled in',
            undef,
            6, 9, 2, 3);
        $button3->signal_connect('clicked' => sub {

            if ($self->checkEntryIcon($entry2)) {

                # Set the max grid gap size
                $self->session->pseudoCmd(
                    'setgrid -g ' . $entry2->get_text(),
                    $self->pseudoCmdMode,
                );

                # Update the entry box
                $entry2->set_text($axmud::CLIENT->gridGapMaxSize);
            }
        });

        my $button4 = $self->addButton($table,
            'Reset size',
            'Reset the maximum size of the gap in the grid that is automatically filled in',
            undef,
            9, 12, 2, 3);
        $button4->signal_connect('clicked' => sub {

            # Reset max grid gap size
            $self->session->pseudoCmd('setgrid -g', $self->pseudoCmdMode);

            # Update the entry box
            $entry2->set_text($axmud::CLIENT->gridBlockSize);
        });

        $self->addLabel($table, 'Workspace grids activated in general',
            1, 5, 3, 4);
        my $checkButton = $self->addCheckButton($table, undef, FALSE,
            5, 6, 3, 4);
        $checkButton->set_active($axmud::CLIENT->activateGridFlag);

        my $button5 = $self->addButton(
            $table,
            'Activate grids',
            'Actcvate workspace grids in general',
            undef,
            6, 9, 3, 4);
        $button5->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('activategrid', $self->pseudoCmdMode);

            # Update widgets
            $checkButton->set_active($axmud::CLIENT->activateGridFlag);
        });

        my $button6 = $self->addButton(
            $table,
            'Disactivate grids',
            'Disactivate workspace grids in general',
            undef,
            9, 12, 3, 4);
        $button6->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('disactivategrid', $self->pseudoCmdMode);

            # Update widgets
            $checkButton->set_active($axmud::CLIENT->activateGridFlag);
        });

        $self->addLabel($table, 'Enable grid adjustment (fill small gaps)',
            1, 11, 5, 6);
        my $checkButton2 = $self->addCheckButton($table, undef, TRUE,
            11, 12, 5, 6);
        $checkButton2->set_active($axmud::CLIENT->gridAdjustmentFlag);
        $checkButton2->signal_connect('toggled' => sub {

            my $flag = $checkButton2->get_active();
            if (! $flag) {
                $flag = 0;
            } else {
                $flag = 1;
            }

            # Toggle grid adjustment
            $self->session->pseudoCmd('setgrid -a ' . $flag);

            # Update the checkbutton
            $checkButton2->set_active($axmud::CLIENT->gridAdjustmentFlag);
        });

        $self->addLabel($table, 'Enable edge correction (edge of desktop)',
            1, 11, 6, 7);
        my $checkButton3 = $self->addCheckButton($table, undef, TRUE,
            11, 12, 6, 7);
        $checkButton3->set_active($axmud::CLIENT->gridEdgeCorrectionFlag);
        $checkButton3->signal_connect('toggled' => sub {

            my $flag = $checkButton3->get_active();
            if (! $flag) {
                $flag = 0;
            } else {
                $flag = 1;
            }

            # Toggle edge correction
            $self->session->pseudoCmd('setgrid -e ' . $flag);

            # Update the checkbutton
            $checkButton3->set_active($axmud::CLIENT->gridEdgeCorrectionFlag);
        });

        $self->addLabel($table, 'Enable window reshuffling',
            1, 11, 7, 8);
        my $checkButton4 = $self->addCheckButton($table, undef, TRUE,
            11, 12, 7, 8);
        $checkButton4->set_active($axmud::CLIENT->gridReshuffleFlag);
        $checkButton4->signal_connect('toggled' => sub {

            my $flag = $checkButton4->get_active();
            if (! $flag) {
                $flag = 0;
            } else {
                $flag = 1;
            }

            # Toggle window reshuffling
            $self->session->pseudoCmd('setgrid -r ' . $flag);

            # Update the checkbutton
            $checkButton4->set_active($axmud::CLIENT->gridReshuffleFlag);
        });

        $self->addLabel($table, 'Enable hiding of other session\'s windows',
            1, 11, 8, 9);
        my $checkButton5 = $self->addCheckButton($table, undef, TRUE,
            11, 12, 8, 9);
        $checkButton5->set_active($axmud::CLIENT->gridInvisWinFlag);
        $checkButton5->signal_connect('toggled' => sub {

            my $flag = $checkButton5->get_active();
            if (! $flag) {
                $flag = 0;
            } else {
                $flag = 1;
            }

            # Toggle window reshuffling
            $self->session->pseudoCmd('setgrid -i ' . $flag);

            # Update the checkbutton
            $checkButton5->set_active($axmud::CLIENT->gridInvisWinFlag);
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub workspaces7Tab {

        # Workspaces7 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->workspaces7Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _7', $innerNotebook);

        # Zonemaps
        $self->addLabel($table, '<b>Zonemaps</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of zonemaps, which divide a workspace grid into distinct zones</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Name', 'text',
            'Standard', 'bool',
            'Full', 'bool',
            'Temporary', 'bool',
            'Number of zone models', 'int',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 9,
            -1, 240);       # Fixed height

        # Initialise the list
        $self->workspaces7Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add entry boxes and editing buttons
        $self->addLabel($table, 'Name',
            1, 2, 9, 10);
        my $entry = $self->addEntryWithIcon($table, undef, 'string', 1, 16,
            2, 5, 9, 10, 16, 16);
        my $entry2 = $self->addEntryWithIcon($table, undef, 'string', 1, 16,
            7, 10, 9, 10, 16, 16);

        my $button = $self->addButton($table, 'Add', 'Add the specified zonemap', undef,
            5, 7, 9, 10);
        $button->signal_connect('clicked' => sub {

            my $name = $entry->get_text();

            if ($self->checkEntryIcon($entry)) {

                # Add this zonemap
                $self->session->pseudoCmd('addzonemap ' . $name, $self->pseudoCmdMode);

                # Refresh the simple list and entry boxes
                $self->workspaces7Tab_refreshList($slWidget, scalar (@columnList / 2));
                $self->resetEntryBoxes($entry, $entry2);
            }
        });

        my $button2 = $self->addButton($table,
            'Clone', 'Clone the selected zonemap as a copy with this name', undef,
            10, 12, 9, 10);
        $button2->signal_connect('clicked' => sub {

            my ($zonemap, $clone);

            ($zonemap) = $self->getSimpleListData($slWidget, 0);
            $clone = $entry2->get_text();

            if (defined $zonemap && $self->checkEntryIcon($entry2)) {

                # Clone the zonemap
                $self->session->pseudoCmd(
                    'clonezonemap ' . $zonemap . ' ' . $clone,
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list and reset entry boxes
                $self->workspaces7Tab_refreshList($slWidget, scalar (@columnList / 2));
                $self->resetEntryBoxes($entry, $entry2);
            }
        });

        my $button3 = $self->addButton($table, 'Edit...', 'Edit the selected zonemap', undef,
            3, 5, 10, 11);
        $button3->signal_connect('clicked' => sub {

            my ($zonemap, $obj, $childWinObj);

            ($zonemap) = $self->getSimpleListData($slWidget, 0);
            if (defined $zonemap) {

                $obj = $axmud::CLIENT->ivShow('zonemapHash', $zonemap);
                if ($obj) {

                    # Open an 'edit' window to edit the zonemap
                    $childWinObj = $self->createFreeWin(
                        'Games::Axmud::EditWin::Zonemap',
                        $self,
                        $self->session,
                        'Edit zonemap \'' . $zonemap . '\'',
                        $obj,
                        FALSE,                          # Not temporary
                    );

                    if ($childWinObj) {

                        # When the 'edit' window closes, update widgets and/or IVs
                        $self->add_childDestroy(
                            $childWinObj,
                            'workspaces7Tab_refreshList',
                            [$slWidget, (scalar @columnList / 2)],
                        );
                    }
                }
            }
        });

        my $button4 = $self->addButton($table, 'Delete', 'Delete the selected zonemap', undef,
            5, 7, 10, 11);
        $button4->signal_connect('clicked' => sub {

            my ($zonemap) = $self->getSimpleListData($slWidget, 0);
            if (defined $zonemap) {

                # Delete the zonemap
                $self->session->pseudoCmd('deletezonemap ' . $zonemap, $self->pseudoCmdMode);

                # Refresh the simple list and reset entry boxes
                $self->workspaces7Tab_refreshList($slWidget, scalar (@columnList / 2));
                $self->resetEntryBoxes($entry, $entry2);
            }
        });

        my $button5 = $self->addButton($table,
            'Reset zonemap', 'Reset the selected zonemap, emptying its list of zone models', undef,
            7, 10, 10, 11);
        $button5->signal_connect('clicked' => sub {

            my ($zonemap) = $self->getSimpleListData($slWidget, 0);
            if (defined $zonemap) {

                # Reset the zonemap
                $self->session->pseudoCmd('resetzonemap ' . $zonemap, $self->pseudoCmdMode);

                # Refresh the simple list and reset entry boxes
                $self->workspaces7Tab_refreshList($slWidget, scalar (@columnList / 2));
                $self->resetEntryBoxes($entry, $entry2);
            }
        });

        my $button6 = $self->addButton($table,
            'Reset list', 'Reset the list of zonemaps', undef,
            10, 12, 10, 11);
        $button6->signal_connect('clicked' => sub {

            # Refresh the simple list and reset entry boxes
            $self->workspaces7Tab_refreshList($slWidget, scalar (@columnList / 2));
            $self->resetEntryBoxes($entry, $entry2);
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub workspaces7Tab_refreshList {

        # Called by $self->workspaces7Tab to refresh the Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::List
        #   $columns    - The number of columns in the list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (@sortedList, @dataList);

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->workspaces7Tab_refreshList',
                @_,
            );
        }

        # Get a sorted list of zonemaps
        @sortedList
            = sort {lc($a->name) cmp lc($b->name)} ($axmud::CLIENT->ivValues('zonemapHash'));

        # Compile the simple list data
        foreach my $zonemapObj (@sortedList) {

            my ($standardFlag, $count);

            if ($axmud::CLIENT->ivExists('standardZonemapHash', $zonemapObj->name)) {

                $standardFlag = TRUE;
            }

            push (@dataList,
                $zonemapObj->name,
                $standardFlag,
                $zonemapObj->fullFlag,
                $zonemapObj->tempFlag,
                $zonemapObj->ivPairs('modelHash'),
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub windowsTab {

        # Workspaces tab - called by $self->setupNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->windowsTab', @_);
        }

        # Tab setup
        # Create a notebook within the main one, so that we have two rows of tabs
        my ($vBox, $innerNotebook) = $self->addInnerNotebookTab('W_indows', $self->notebook);

        # Add tabs to the inner notebook
        $self->windows1Tab($innerNotebook);
        $self->windows2Tab($innerNotebook);
        $self->windows3Tab($innerNotebook);
        $self->windows4Tab($innerNotebook);
        $self->windows5Tab($innerNotebook);

        return 1;
    }

    sub windows1Tab {

        # Windows1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->windows1Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _1', $innerNotebook);

        # 'Grid' windows
        $self->addLabel($table, '<b>\'Grid\' windows</b>',
            0, 13, 0, 1);
        $self->addLabel($table, '<i>List of windows that can be arranged on a workspace grid</i>',
            1, 13, 1, 2);

       # Add a simple list
        @columnList = (
            '#', 'int',
            'Type', 'text',
            'Name', 'text',
            'Enab', 'bool',
            'Vis', 'bool',
            'Gtk', 'bool',
            'Wnck', 'bool',
            'Wsp', 'int',
            'WGrd', 'text',
            'Sesn', 'text',
            'Zone', 'int',
            'Layer', 'int',
            'X/Y', 'text',
            'Wid/Hei', 'text',
            'Zone X/Y', 'text',
            'Wid/Hei', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 13, 2, 8,
            -1, 180);      # Fixed height

        # Refresh the list
        $self->windows1Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add editing buttons
        my $button = $self->addButton($table,
            'View...', 'View the selected window\'s settings', undef,
            1, 3, 8, 9);
        $button->signal_connect('clicked' => sub {

            my ($number, $winObj);

            ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                $winObj = $axmud::CLIENT->desktopObj->ivShow('gridWinHash', $number);
                if ($winObj) {

                    # Open an 'edit' window for the selected 'grid' window
                    $self->createFreeWin(
                        'Games::Axmud::EditWin::Window',
                        $self,
                        $self->session,
                        'Edit \'grid\' window #' . $number,
                        $winObj,
                        FALSE,                  # Not temporary
                    );
                }
            }

            # Refresh the simple list
            $self->windows1Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button2 = $self->addButton($table,
            'Restore', 'Restore the selected window to its allocated zone', undef,
            3, 5, 8, 9);
        $button2->signal_connect('clicked' => sub {

            my ($number, $winObj);

            ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                $winObj = $axmud::CLIENT->desktopObj->ivShow('gridWinHash', $number);
                if ($winObj) {

                    # Restore the window
                    $self->session->pseudoCmd('restorewindow ' . $number, $self->pseudoCmdMode);
                }
            }

            # Refresh the simple list
            $self->windows1Tab_refreshList($slWidget, scalar (@columnList / 2), $number);
        });

        my $button3 = $self->addButton($table,
            'Restore all', 'Restore all windows to their allocated zones', undef,
            5, 7, 8, 9);
        $button3->signal_connect('clicked' => sub {

            # Restore all windows
            $self->session->pseudoCmd('restorewindow', $self->pseudoCmdMode);

            # Refresh the simple list and entry boxes
            $self->windows1Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button4 = $self->addButton($table, 'Close', 'Close the selected window', undef,
            7, 9, 8, 9);
        $button4->signal_connect('clicked' => sub {

            my ($number, $winObj);

            ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                $winObj = $axmud::CLIENT->desktopObj->ivShow('gridWinHash', $number);
                if ($winObj) {

                    # Close the window
                    $self->session->pseudoCmd('closewindow ' . $number, $self->pseudoCmdMode);
                }
            }

            # Refresh the simple list
            $self->windows1Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button5 = $self->addButton($table,
            'Fix', 'Fix the selected window in whichever zone it is currently located', undef,
            9, 11, 8, 9);
        $button5->signal_connect('clicked' => sub {

            my ($number, $winObj);

            ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                $winObj = $axmud::CLIENT->desktopObj->ivShow('gridWinHash', $number);
                if ($winObj) {

                    # Fix the window
                    $self->session->pseudoCmd('fixwindow ' . $number, $self->pseudoCmdMode);
                }
            }

            # Refresh the simple list
            $self->windows1Tab_refreshList($slWidget, scalar (@columnList / 2), $number);
        });

        my $button6 = $self->addButton(
            $table,
            'Fix/Resize',
            'Fix the selected window in whichever zone it is currently located, and resize to fit'
            . ' if possible',
            undef,
            11, 13, 8, 9);
        $button6->signal_connect('clicked' => sub {

            my ($number, $winObj);

            ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                $winObj = $axmud::CLIENT->desktopObj->ivShow('gridWinHash', $number);
                if ($winObj) {

                    # Fix/resize the window
                    $self->session->pseudoCmd('fixwindow -r ' . $number, $self->pseudoCmdMode);
                }
            }

            # Refresh the simple list
            $self->windows1Tab_refreshList($slWidget, scalar (@columnList / 2), $number);
        });

        $self->addLabel($table, 'Workspace',
            1, 2, 9, 10);
        my $entry = $self->addEntryWithIcon($table, undef, 'int', 0, undef,
            2, 5, 9, 10);
        $self->addLabel($table, 'Zone',
            5, 6, 9, 10);
        my $entry2 = $self->addEntryWithIcon($table, undef, 'int', 0, undef,
            6, 9, 9, 10);

        my $button7 = $self->addButton($table,
            'Move',
            'Move the selected window to the specified workspace and/or zone',
            undef,
            9, 11, 9, 10);
        $button7->signal_connect('clicked' => sub {

            my ($number, $winObj, $cmd);

            ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                $winObj = $axmud::CLIENT->desktopObj->ivShow('gridWinHash', $number);
                if ($winObj) {

                    $cmd = 'movewindow ' . $number;

                    if ($self->checkEntryIcon($entry)) {

                        # Use specified workspace
                        $cmd .= ' ' . $entry->get_text();

                    } else {

                        # Use window's existing workspace
                        $cmd .= ' ' . $winObj->workspaceObj->number;
                    }

                    if ($self->checkEntryIcon($entry2)) {

                        $cmd .= ' ' . $entry2->get_text();
                    }

                    # Move the window and reset entry boxes
                    $self->session->pseudoCmd($cmd, $self->pseudoCmdMode);
                    $self->resetEntryBoxes($entry, $entry2);
                }
            }

            # Refresh the simple list
            $self->windows1Tab_refreshList($slWidget, scalar (@columnList / 2), $number);
            $self->resetEntryBoxes($entry, $entry2);
        });

        my $button8 = $self->addButton(
            $table,
            'Move/Resize',
            'Move the selected window to the specified workspace and/or zone, and resize'
            . ' if possible',
            undef,
            11, 13, 9, 10);
        $button8->signal_connect('clicked' => sub {

            my ($number, $winObj, $cmd);

            ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                $winObj = $axmud::CLIENT->desktopObj->ivShow('gridWinHash', $number);
                if ($winObj) {

                    $cmd = 'movewindow -r ' . $number;

                    if ($self->checkEntryIcon($entry)) {

                        # Use specified workspace
                        $cmd .= ' ' . $entry->get_text();

                    } else {

                        # Use window's existing workspace
                        $cmd .= ' ' . $winObj->workspaceObj->number;
                    }

                    if ($self->checkEntryIcon($entry2)) {

                        $cmd .= ' ' . $entry2->get_text();
                    }

                    # Move the window and reset entry boxes
                    $self->session->pseudoCmd($cmd, $self->pseudoCmdMode);
                    $self->resetEntryBoxes($entry, $entry2);
                }
            }

            # Refresh the simple list
            $self->windows1Tab_refreshList($slWidget, scalar (@columnList / 2), $number);
        });

        $self->addLabel($table, 'Pattern',
            1, 2, 10, 11);
        my $entry3 = $self->addEntryWithIcon($table, undef, 'string', 1, undef,
            2, 5, 10, 11);
        my $button9 = $self->addButton($table,
            'Grab', 'Incorporate the first window matching the specified pattern (regex)', undef,
            5, 7, 10, 11);
        $button9->signal_connect('clicked' => sub {

            my $regex;

            if ($self->checkEntryIcon($entry3)) {

                $regex = $entry3->get_text();

                # Grab the window matching the regex
                $self->session->pseudoCmd(
                    'grabwindow <' . $regex . '>',
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list and entry boxes
                $self->windows1Tab_refreshList($slWidget, scalar (@columnList / 2));
                $self->resetEntryBoxes($entry3);
            }
        });

        my $button10 = $self->addButton($table,
            'Grab All', 'Incorporate all windows matching the specified pattern (regex)', undef,
            7, 9, 10, 11);
        $button10->signal_connect('clicked' => sub {

            my $regex;

            if ($self->checkEntryIcon($entry3)) {

                $regex = $entry3->get_text();

                # Grab all windows matching the regex
                $self->session->pseudoCmd(
                    'grabwindow -a <' . $regex . '>',
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list and entry boxes
                $self->windows1Tab_refreshList($slWidget, scalar (@columnList / 2));
                $self->resetEntryBoxes($entry3);
            }
        });

        my $button11 = $self->addButton($table,
            'Banish', 'Remove the selected external window from its workspace grid', undef,
            9, 11, 10, 11);
        $button11->signal_connect('clicked' => sub {

            my ($number, $winObj);

            ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                $winObj = $axmud::CLIENT->desktopObj->ivShow('gridWinHash', $number);
                if ($winObj) {


                    # Banish the external window
                    $self->session->pseudoCmd('banishwindow ' . $number, $self->pseudoCmdMode);
                }
            }

            # Refresh the simple list
            $self->windows1Tab_refreshList($slWidget, scalar (@columnList / 2), $number);
        });

        my $button12 = $self->addButton($table,
            'Banish all', 'Remove all external windows from their workspace grids', undef,
            11, 13, 10, 11);
        $button12->signal_connect('clicked' => sub {

            # Banish all external windows
            $self->session->pseudoCmd('banishwindow', $self->pseudoCmdMode);

            # Refresh the simple list
            $self->windows1Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        $self->addLabel($table, 'Window',
            1, 2, 11, 12);
        my $entry4 = $self->addEntryWithIcon($table, undef, 'int', 0, undef,
            2, 5, 11, 12);
        my $button13 = $self->addButton($table,
            'Swap', 'Swap the selected window with the specified window', undef,
            5, 7, 11, 12);
        $button13->signal_connect('clicked' => sub {

            my ($number, $winObj, $swapNumber, $swapWinObj);

            ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                $winObj = $axmud::CLIENT->desktopObj->ivShow('gridWinHash', $number);
                if ($self->checkEntryIcon($entry4)) {

                    $swapNumber = $entry4->get_text();
                    $swapWinObj = $axmud::CLIENT->desktopObj->ivShow('gridWinHash', $swapNumber);
                }

                if ($winObj && $swapWinObj) {

                    # Swap the two windows
                    $self->session->pseudoCmd(
                        'swapwindow ' . $number . ' ' . $swapNumber,
                        $self->pseudoCmdMode,
                    );
                }
            }

            # Refresh the simple list
            $self->windows1Tab_refreshList($slWidget, scalar (@columnList / 2), $number);
        });

        my $button14 = $self->addButton($table,
            'Dump', 'Display this list of windows in the \'main\' window', undef,
            9, 11, 11, 12);
        $button14->signal_connect('clicked' => sub {

            # List windows
            $self->session->pseudoCmd('listwindow', $self->pseudoCmdMode);

            # Refresh the simple list
            $self->windows1Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button15 = $self->addButton($table,
            'Refresh list', 'Refresh the list of windows', undef,
            11, 13, 11, 12);
        $button15->signal_connect('clicked' => sub {

            # Refresh the simple list and entry boxes
            $self->windows1Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub windows1Tab_refreshList {

        # Called by $self->windows1Tab to refresh the Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::List
        #   $columns    - The number of columns in the list
        #
        # Optional arguments
        #   $number     - A 'grid' window number which should be selected in the list (if specified)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $number, $check) = @_;

        # Local variables
        my (
            $count, $selectRow,
            @dataList,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->windows1Tab_refreshList',
                @_,
            );
        }

        # Compile the simple list data
        $count = 0;
        foreach my $winObj ($axmud::CLIENT->desktopObj->listGridWins()) {

            my ($gtk2Flag, $wnckFlag, $gridString, $sessionString, $areaObj);

            if ($winObj->winWidget) {

                $gtk2Flag = TRUE;
            }

            if ($winObj->wnckWin) {

                $wnckFlag = TRUE;
            }

            if (! $winObj->workspaceGridObj) {
                $gridString = ('n/a');
            } else {
                $gridString = $winObj->workspaceGridObj->number;
            }

            if (! $winObj->session) {
                $sessionString = ('n/a');
            } else {
                $sessionString = $winObj->session->number;
            }

            push (@dataList,
                $winObj->number,
                $winObj->winType,
                $winObj->winName,
                $winObj->enabledFlag,
                $winObj->visibleFlag,
                $gtk2Flag,
                $wnckFlag,
                $winObj->workspaceObj->number,
                $gridString,
                $sessionString,
            );

            $areaObj = $winObj->areaObj;
            if (! $areaObj) {

                push (@dataList, undef, undef, undef, undef, undef, undef);

            } else {

                push (@dataList,
                    $areaObj->zoneObj->number,
                    $areaObj->layer,
                    $areaObj->xPosPixels . '/' . $areaObj->yPosPixels,
                    $areaObj->widthPixels . '/' . $areaObj->heightPixels,
                    $areaObj->leftBlocks . '/' . $areaObj->topBlocks,
                    $areaObj->widthBlocks . '/' . $areaObj->heightBlocks,
                );
            }

            if (defined $number && $winObj->number eq $number) {

                $selectRow = $count;
            }

            $count++;
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        # Select a row, if required
        if (defined $selectRow) {

            $slWidget->select($selectRow);
        }

        return 1;
    }

    sub windows2Tab {

        # Windows2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->windows2Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _2', $innerNotebook);

        # 'Free' windows
        $self->addLabel($table, '<b>\'Free\' windows</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $table,
            '<i>List of windows that can\'t be arranged on a workspace grid (doesn\'t include'
            . ' \'dialogue\' windows)</i>',
            1, 12, 1, 2);

       # Add a simple list
        @columnList = (
            '#', 'int',
            'Type', 'text',
            'Name', 'text',
            'Enab', 'bool',
            'Vis', 'bool',
            'Gtk', 'bool',
            'Wnck', 'bool',
            'Wsp', 'int',
            'Sesn', 'int',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 280);      # Fixed height, matches previous tab

        # Refresh the list
        $self->windows2Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add editing buttons
        my $button = $self->addButton($table,
            'View...', 'View the selected window\'s settings', undef,
            1, 3, 10, 11);
        $button->signal_connect('clicked' => sub {

            my ($number, $winObj);

            ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                $winObj = $axmud::CLIENT->desktopObj->ivShow('freeWinHash', $number);
                if ($winObj) {

                    # Open an 'edit' window for the selected 'free' window
                    $self->createFreeWin(
                        'Games::Axmud::EditWin::Window',
                        $self,
                        $self->session,
                        'Edit \'free\' window #' . $number,
                        $winObj,
                        FALSE,                  # Not temporary
                    );
                }
            }

            # Refresh the simple list
            $self->windows2Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button2 = $self->addButton($table, 'Close', 'Close the selected window', undef,
            3, 5, 10, 11);
        $button2->signal_connect('clicked' => sub {

            my ($number, $winObj);

            ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                $winObj = $axmud::CLIENT->desktopObj->ivShow('freeWinHash', $number);
                if ($winObj) {

                    # Close the window
                    $self->session->pseudoCmd('closefreewindow ' . $number, $self->pseudoCmdMode);

                    if ($winObj ne $self) {

                        # Refresh the simple list
                        $self->windows2Tab_refreshList($slWidget, scalar (@columnList / 2));
                    }
                }
            }
        });

        my $button14 = $self->addButton($table,
            'Dump', 'Display this list of windows in the \'main\' window', undef,
            8, 10, 10, 11);
        $button14->signal_connect('clicked' => sub {

            # List windows
            $self->session->pseudoCmd('listfreewindow', $self->pseudoCmdMode);

            # Refresh the simple list
            $self->windows2Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button15 = $self->addButton($table,
            'Refresh list', 'Refresh the list of windows', undef,
            10, 12, 10, 11);
        $button15->signal_connect('clicked' => sub {

            # Refresh the simple list and entry boxes
            $self->windows2Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub windows2Tab_refreshList {

        # Called by $self->windows2Tab to refresh the Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::List
        #   $columns    - The number of columns in the list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my @dataList;

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->windows2Tab_refreshList',
                @_,
            );
        }

        # Compile the simple list data
        foreach my $winObj ($axmud::CLIENT->desktopObj->listFreeWins()) {

            my ($gtk2Flag, $wnckFlag, $sessionString);

            if ($winObj->winWidget) {

                $gtk2Flag = TRUE;
            }

            if ($winObj->wnckWin) {

                $wnckFlag = TRUE;
            }

            if (! $winObj->session) {
                $sessionString = ('n/a');
            } else {
                $sessionString = $winObj->session->number;
            }

            push (@dataList,
                $winObj->number,
                $winObj->winType,
                $winObj->winName,
                $winObj->enabledFlag,
                $winObj->visibleFlag,
                $gtk2Flag,
                $wnckFlag,
                $winObj->workspaceObj->number,
                $sessionString,
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub windows3Tab {

        # Windows3 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->windows3Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _3', $innerNotebook);

        # Winmaps
        $self->addLabel($table, '<b>Winmaps</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of winmaps, which determine the layout of \'internal\' windows when they are'
            . ' created</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Name', 'text',
            'Strips', 'int',
            'Winzones', 'int',
            'Table full', 'bool',
            'Default \'main\'', 'bool',
            '\'main\', no grids', 'bool',
            'Default \'internal\'', 'bool',
            'Default for worlds', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 9,
            -1, 210);       # Fixed height

        # Initialise the list
        $self->windows3Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add entry boxes and editing buttons
        $self->addLabel($table, 'Name',
            1, 2, 9, 10);
        my $entry = $self->addEntryWithIcon($table, undef, 'string', 1, 16,
            2, 5, 9, 10, 16, 16);
        my $entry2 = $self->addEntryWithIcon($table, undef, 'string', 1, 16,
            7, 10, 9, 10, 16, 16);

        my $button = $self->addButton($table, 'Add', 'Add the specified winmap', undef,
            5, 7, 9, 10);
        $button->signal_connect('clicked' => sub {

            my $name = $entry->get_text();

            if ($self->checkEntryIcon($entry)) {

                # Add this zonemap
                $self->session->pseudoCmd('addwinmap ' . $name, $self->pseudoCmdMode);

                # Refresh the simple list and entry boxes
                $self->windows3Tab_refreshList($slWidget, scalar (@columnList / 2));
                $self->resetEntryBoxes($entry, $entry2);
            }
        });

        my $button2 = $self->addButton($table,
            'Clone', 'Clone the selected zonemap as a copy with this name', undef,
            10, 12, 9, 10);
        $button2->signal_connect('clicked' => sub {

            my ($winmap, $clone);

            ($winmap) = $self->getSimpleListData($slWidget, 0);
            $clone = $entry2->get_text();

            if (defined $winmap && $self->checkEntryIcon($entry2)) {

                # Clone the winmap
                $self->session->pseudoCmd(
                    'clonewinmap ' . $winmap . ' ' . $clone,
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list and reset entry boxes
                $self->windows3Tab_refreshList($slWidget, scalar (@columnList / 2));
                $self->resetEntryBoxes($entry, $entry2);
            }
        });

        my $button3 = $self->addButton($table, 'Edit...', 'Edit the selected winmap', undef,
            3, 5, 10, 11);
        $button3->signal_connect('clicked' => sub {

            my ($winmap, $obj, $childWinObj);

            ($winmap) = $self->getSimpleListData($slWidget, 0);
            if (defined $winmap) {

                $obj = $axmud::CLIENT->ivShow('winmapHash', $winmap);
                if ($obj) {

                    # Open an 'edit' window to edit the winmap
                    $childWinObj = $self->createFreeWin(
                        'Games::Axmud::EditWin::Winmap',
                        $self,
                        $self->session,
                        'Edit winmap \'' . $winmap . '\'',
                        $obj,
                        FALSE,                          # Not temporary
                    );

                    if ($childWinObj) {

                        # When the 'edit' window closes, update widgets and/or IVs
                        $self->add_childDestroy(
                            $childWinObj,
                            'windows3Tab_refreshList',
                            [$slWidget, (scalar @columnList / 2)],
                        );
                    }
                }
            }
        });

        my $button4 = $self->addButton($table, 'Delete', 'Delete the selected winmap', undef,
            5, 7, 10, 11);
        $button4->signal_connect('clicked' => sub {

            my ($winmap) = $self->getSimpleListData($slWidget, 0);
            if (defined $winmap) {

                # Delete the winmap
                $self->session->pseudoCmd('deletewinmap ' . $winmap, $self->pseudoCmdMode);

                # Refresh the simple list and reset entry boxes
                $self->windows3Tab_refreshList($slWidget, scalar (@columnList / 2));
                $self->resetEntryBoxes($entry, $entry2);
            }
        });

        my $button5 = $self->addButton($table,
            'Reset winmap', 'Reset the selected winmap, emptying its list of winzones', undef,
            7, 10, 10, 11);
        $button5->signal_connect('clicked' => sub {

            my ($winmap) = $self->getSimpleListData($slWidget, 0);
            if (defined $winmap) {

                # Reset the winmap
                $self->session->pseudoCmd('resetwinmap ' . $winmap, $self->pseudoCmdMode);

                # Refresh the simple list and reset entry boxes
                $self->windows3Tab_refreshList($slWidget, scalar (@columnList / 2));
                $self->resetEntryBoxes($entry, $entry2);
            }
        });

        my $button6 = $self->addButton($table,
            'Reset list', 'Reset the list of winmaps', undef,
            10, 12, 10, 11);
        $button6->signal_connect('clicked' => sub {

            # Refresh the simple list and reset entry boxes
            $self->windows3Tab_refreshList($slWidget, scalar (@columnList / 2));
            $self->resetEntryBoxes($entry, $entry2);
        });

        my $button7 = $self->addButton($table,
            'Set default \'main\' winmap',
            'Set the default winmap for \'main\' windows',
            undef,
            2, 6, 11, 12);
        $button7->signal_connect('clicked' => sub {

            my ($winmap) = $self->getSimpleListData($slWidget, 0);
            if (defined $winmap) {

                # Reset the default winmap
                $self->session->pseudoCmd('setdefaultwinmap -m ' . $winmap, $self->pseudoCmdMode);
            }

            # Refresh the simple list and reset entry boxes
            $self->windows3Tab_refreshList($slWidget, scalar (@columnList / 2));
            $self->resetEntryBoxes($entry, $entry2);
        });

        my $button8 = $self->addButton($table,
            'Set default \'internal\' winmap',
            'Set the default winmap for other \'internal\' windows',
            undef,
            6, 9, 11, 12);
        $button8->signal_connect('clicked' => sub {

            my ($winmap) = $self->getSimpleListData($slWidget, 0);
            if (defined $winmap) {

                # Reset the default winmap
                $self->session->pseudoCmd('setdefaultwinmap -i ' . $winmap, $self->pseudoCmdMode);
            }

            # Refresh the simple list and reset entry boxes
            $self->windows3Tab_refreshList($slWidget, scalar (@columnList / 2));
            $self->resetEntryBoxes($entry, $entry2);
        });

        my $button9 = $self->addButton(
            $table,
            'Reset default winmaps',
            'Reset default winmaps for \'main\' and \'internal\' windows',
            undef,
            9, 12, 11, 12);
        $button9->signal_connect('clicked' => sub {

            # Reset default winmaps
            $self->session->pseudoCmd('setdefaultwinmap -r', $self->pseudoCmdMode);

            # Refresh the simple list and reset entry boxes
            $self->windows3Tab_refreshList($slWidget, scalar (@columnList / 2));
            $self->resetEntryBoxes($entry, $entry2);
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub windows3Tab_refreshList {

        # Called by $self->windows3Tab to refresh the Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::List
        #   $columns    - The number of columns in the list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (@sortedList, @dataList);

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->windows3Tab_refreshList',
                @_,
            );
        }

        # Get a sorted list of winmaps
        @sortedList = sort {lc($a->name) cmp lc($b->name)} ($axmud::CLIENT->ivValues('winmapHash'));

        # Compile the simple list data
        foreach my $winmapObj (@sortedList) {

            my ($string, $enabledFlag, $disabledFlag, $internalFlag);

            if ($winmapObj->worldHash) {

                $string = join(' ', sort {lc($a) cmp lc($b)} ($winmapObj->ivKeys('worldHash')));
            }

            if ($axmud::CLIENT->defaultEnabledWinmap eq $winmapObj->name) {
                $enabledFlag = TRUE;
            } else {
                $enabledFlag = FALSE;
            }

            if ($axmud::CLIENT->defaultDisabledWinmap eq $winmapObj->name) {
                $disabledFlag = TRUE;
            } else {
                $disabledFlag = FALSE;
            }

            if ($axmud::CLIENT->defaultInternalWinmap eq $winmapObj->name) {
                $internalFlag = TRUE;
            } else {
                $internalFlag = FALSE;
            }

            push (@dataList,
                $winmapObj->name,
                ($winmapObj->ivNumber('stripInitList') / 2),
                $winmapObj->ivPairs('zoneHash'),
                $winmapObj->fullFlag,
                $enabledFlag,
                $disabledFlag,
                $internalFlag,
                $string,
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub windows4Tab {

        # Windows4 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (
            $scriptDir, $posn, $shortPath,
            @buttonList, @columnList, @fileList,
            %buttonHash,
        );

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->windows4Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _4', $innerNotebook);

        # Import the IVs, so that the user can edit the list freely, without the changes becoming
        #   permanent (until they use the 'Apply changes' button, of course)
        @buttonList = $axmud::CLIENT->toolbarList;
        %buttonHash = $axmud::CLIENT->toolbarHash;

        # Toolbar buttons
        $self->addLabel($table, '<b>Toolbar buttons for \'internal\' windows</b>',
            0, 12, 0, 1);

        # Add a simple list
        @columnList = (
            '#', 'int',
            'Icon', 'pixbuf',
            'Name', 'text',
            'Custom', 'bool',
            'Description', 'text',
            'Instruction', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 1, 6,
            -1, 150);           # Fixed size

        # Initialise the list
        $self->windows4Tab_refreshList(
            $slWidget,
            scalar (@columnList / 2),
            \@buttonList,
            \%buttonHash,
        );

        # Get a list of .png files in /icons/custom
        $scriptDir = $axmud::SHARE_DIR;
        if ($^O eq 'MSWin32') {
            @fileList = glob($scriptDir . '\\icons\\custom\\*.png');
        } else {
            @fileList = glob($scriptDir . '/icons/custom/*.png');
        }

        $posn = 0;

        # Add editing widgets
        $self->addLabel($table, 'Name',
            1, 2, 6, 7);
        my $entry = $self->addEntryWithIcon($table, undef, 'string', 1, 16,
            2, 6, 6, 7);
        $self->addLabel($table, 'Description',
            6, 8, 6, 7);
        my $entry2 = $self->addEntryWithIcon($table, undef, 'string', 1, 32,
            8, 12, 6, 7);

        $self->addLabel($table, 'Instruction',
            2, 4, 7, 8);
        my $entry3 = $self->addEntryWithIcon($table, undef, 'string', 1, undef,
            4, 12, 7, 8);

        my ($image, $frame, $viewPort) = $self->addImage($table, $fileList[$posn], undef,
            FALSE,          # Don't use a scrolled window
            24, 24,
            1, 2, 7, 9);

        my $entry4 = $self->addEntry($table, undef, FALSE,
            4, 8, 8, 9);
        $shortPath = $fileList[$posn];
        if ($shortPath) {

            # Repair MSWin paths, so $scriptDir can be used in a substitution
            $scriptDir =~ s/\\/\\\\/g;
            # Do the substitution
            $shortPath =~ s/$scriptDir//;

            $entry4->set_text($shortPath);
        }

        my $button = $self->addButton($table, '<<', 'Switch to previous icon', undef,
            2, 3, 8, 9);
        $button->signal_connect('clicked' => sub {

            $posn--;
            if ($posn < 0) {

                $posn = (scalar @fileList) - 1;
            }

            # Change the displayed image
            my $newImage = $self->changeImage($viewPort, $frame, $image, $fileList[$posn]);
            if ($newImage) {

                $shortPath = $fileList[$posn];
                if ($shortPath) {

                    $shortPath =~ s/$scriptDir//;
                    $entry4->set_text($shortPath);
                    $image = $newImage;
                }
            }
        });

        my $button2 = $self->addButton($table, '>>', 'Switch to next icon', undef,
            3, 4, 8, 9);
        $button2->signal_connect('clicked' => sub {

            $posn++;
            if ($posn >= scalar @fileList) {

                $posn = 0;
            }

            # Change the displayed image, and store it as the current chat icon
            my $newImage = $self->changeImage($viewPort, $frame, $image, $fileList[$posn]);
            if ($newImage) {

                $shortPath = $fileList[$posn];
                if ($shortPath) {

                    $shortPath =~ s/$scriptDir//;
                    $entry4->set_text($shortPath);
                    $image = $newImage;
                }
            }
        });

        my $button3 = $self->addButton($table, 'Add custom', 'Add a custom toolbar button', undef,
            8, 10, 8, 9);
        $button3->signal_connect('clicked' => sub {

            my ($name, $descrip, $instruct, $buttonObj);

            $name = $entry->get_text();
            $descrip = $entry2->get_text();
            $instruct = $entry3->get_text();

            if ($self->checkEntryIcon($entry, $entry2, $entry3) && $shortPath) {

                # Check a toolbar button with that name doesn't already exist
                if (exists $buttonHash{$name}) {

                    $self->showMsgDialogue(
                        'Add toolbar button',
                        'error',
                        'A toolbar button called \''. $name . '\' already exists',
                        'ok',
                    );

                } elsif (! $axmud::CLIENT->nameCheck($name, 16)) {

                    $self->showMsgDialogue(
                        'Add toolbar button',
                        'error',
                        'Registry naming error: invalid name \'' . $name . '\'',
                        'ok',
                    );

                } else {

                    # Create a new toolbar button
                    $buttonObj = Games::Axmud::Obj::Toolbar->new(
                        $name,
                        $descrip,
                        TRUE,                   # Custom toolbar button
                        $scriptDir . $shortPath,
                        $instruct,
                        TRUE,                   # Require current session
                        TRUE,                   # Require connection
                    );

                    # Add the new toolbar button at the end of the list
                    if ($buttonObj) {

                        push (@buttonList, $name);
                        $buttonHash{$name} = $buttonObj;

                        # Refresh the simple list
                        $self->windows4Tab_refreshList(
                            $slWidget,
                            scalar (@columnList / 2),
                            \@buttonList,
                            \%buttonHash,
                        );

                        # Reset the entry boxes
                        $self->resetEntryBoxes($entry, $entry2, $entry3);
                    }
                }
            }
        });

        my $button4 = $self->addButton(
            $table,
            'Add separator',
            'Add a separator between toolbar button',
            undef,
            10, 12, 8, 9);
        $button4->signal_connect('clicked' => sub {

            # Add a separator to the list of toolbar buttons
            push (@buttonList, 'separator');

            # Refresh the simple list
            $self->windows4Tab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                \@buttonList,
                \%buttonHash,
            );
        });

        $self->addLabel($table, '<i>Edit existing buttons:</i>',
            1, 10, 9, 10);
        $self->addLabel($table, '<i>Click below to apply changes:</i>',
            10, 12, 9, 10);

        my $button5 = $self->addButton(
            $table,
            'View / edit',
            'View of edit the selected item',
            undef,
            1, 2, 10, 11);
        $button5->signal_connect('clicked' => sub {

            my ($posn, $name, $obj);

            ($posn) = $self->getSimpleListData($slWidget, 0);
            if (defined $posn) {

                # First item in list is numbered 1
                $posn--;

                $name = $buttonList[$posn];
                if ($name ne 'separator') {

                    $obj = $buttonHash{$name};

                    # Open an 'edit' window to edit the toolbar button
                    $self->createFreeWin(
                        'Games::Axmud::EditWin::Toolbar',
                        $self,
                        $self->session,
                        'Edit toolbar button \'' . $name . '\'',
                        $obj,
                        FALSE,                          # Not temporary
                    );

                    # Refresh the simple list
                    $self->windows4Tab_refreshList(
                        $slWidget,
                        scalar (@columnList / 2),
                        \@buttonList,
                        \%buttonHash,
                    );
                }
            }
        });

        my $button6 = $self->addButton($table, 'Move up', 'Move the selected item up',  undef,
            2, 5, 10, 11);
        $button6->signal_connect('clicked' => sub {

            my ($posn, $item);

            ($posn) = $self->getSimpleListData($slWidget, 0);
            if (defined $posn && $posn > 1) {

                # First item in list is numbered 1
                $posn--;

                # Remove the selected item from the list
                $item = splice (@buttonList, $posn, 1);
                # Move it one place higher
                splice (@buttonList, ($posn - 1), 0, $item);

                # Refresh the simple list
                $self->windows4Tab_refreshList(
                    $slWidget,
                    scalar (@columnList / 2),
                    \@buttonList,
                    \%buttonHash,
                );

                # Re-select the item at its new position
                $slWidget->select($posn - 1);
            }
        });

        my $button7 = $self->addButton($table, 'Move down', 'Move the selected item down',  undef,
            5, 6, 10, 11);
        $button7->signal_connect('clicked' => sub {

            my ($posn, $item);

            ($posn) = $self->getSimpleListData($slWidget, 0);
            if (defined $posn && $posn < ((scalar @buttonList) - 1)) {

                # First item in list is numbered 1
                $posn--;

                # Remove the selected item from the list
                $item = splice (@buttonList, $posn, 1);
                # Move it one place lower
                splice (@buttonList, ($posn + 1), 0, $item);

                # Refresh the simple list
                $self->windows4Tab_refreshList(
                    $slWidget,
                    scalar (@columnList / 2),
                    \@buttonList,
                    \%buttonHash,
                );

                # Re-select the item at its new position
                $slWidget->select($posn + 1);
            }
        });


        my $button8 = $self->addButton(
            $table, 'Delete', 'Remove the selected item from the list',  undef,
            6, 7, 10, 11);
        $button8->signal_connect('clicked' => sub {

            my ($posn) = $self->getSimpleListData($slWidget, 0);
            if (defined $posn) {

                # First item in list is numbered 1
                $posn--;

                # Remove the selected item from the list
                splice (@buttonList, $posn, 1);

                # Refresh the simple list
                $self->windows4Tab_refreshList(
                    $slWidget,
                    scalar (@columnList / 2),
                    \@buttonList,
                    \%buttonHash,
                );
            }
        });

        my $button9 = $self->addButton(
            $table, 'Use default buttons', 'Use the default set of toolbar buttons',  undef,
            10, 12, 10, 11);
        $button9->signal_connect('clicked' => sub {

            my $choice = $self->showMsgDialogue(
                'Use default toolbar buttons',
                'question',
                'Are you sure you want to reset the toolbar? (Any custom buttons you\'ve created'
                . ' will be destroyed)',
                'yes-no',
            );

            if ($choice && $choice eq 'yes') {

                # Replace the contents of the client's IVs with the default values
                $axmud::CLIENT->initialiseToolbar();
                # Re-import the IVs
                @buttonList = $axmud::CLIENT->toolbarList;
                %buttonHash = $axmud::CLIENT->toolbarHash;

                # Tell all 'internal' windows to re-draw their toolbar strip objects
                foreach my $winObj ($axmud::CLIENT->desktopObj->listGridWins('internal')) {

                    my $stripObj
                        = $winObj->ivShow('firstStripHash', 'Games::Axmud::Strip::Toolbar');

                    if ($stripObj) {

                        $stripObj->resetToolbar();
                    }
                }

                # Refresh the simple list
                $self->windows4Tab_refreshList(
                    $slWidget,
                    scalar (@columnList / 2),
                    \@buttonList,
                    \%buttonHash,
                );
            }
        });

        my $button10 = $self->addButton(
            $table, 'Reset buttons', 'Reset your changes to this list',  undef,
            1, 4, 11, 12);
        $button10->signal_connect('clicked' => sub {

            # Re-import the IVs
            @buttonList = $axmud::CLIENT->toolbarList;
            %buttonHash = $axmud::CLIENT->toolbarHash;

            # Refresh the simple list
            $self->windows4Tab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                \@buttonList,
                \%buttonHash,
            );
        });

        my $button11 = $self->addButton(
            $table, 'Refresh list', 'Refresh the list of toolbar buttons',  undef,
            4, 7, 11, 12);
        $button11->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->windows4Tab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                \@buttonList,
                \%buttonHash,
            );
        });

        my $button12 = $self->addButton(
            $table, 'Apply changes', 'Apply changes to \'internal\' windows now',  undef,
            10, 12, 11, 12);
        $button12->signal_connect('clicked' => sub {

            my $choice = $self->showMsgDialogue(
                'Apply changes',
                'question',
                'Are you sure you want to apply your changes now?',
                'yes-no',
            );

            if ($choice && $choice eq 'yes') {

                # Update the Client's IVs
                $axmud::CLIENT->set_toolbarHash(%buttonHash);
                $axmud::CLIENT->set_toolbarList(@buttonList);

                # Tell all 'internal' windows to re-draw their toolbar strip objects
                foreach my $winObj ($axmud::CLIENT->desktopObj->listGridWins('internal')) {

                    my $stripObj
                        = $winObj->ivShow('firstStripHash', 'Games::Axmud::Strip::Toolbar');

                    if ($stripObj) {

                        $stripObj->resetToolbar();
                    }
                }

                # Refresh the simple list
                $self->windows4Tab_refreshList(
                    $slWidget,
                    scalar (@columnList / 2),
                    \@buttonList,
                    \%buttonHash,
                );
            }
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub windows4Tab_refreshList {

        # Called by $self->windows4Tab to refresh the Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::List
        #   $columns        - The number of columns in the list
        #   $buttonListRef  - Reference to a list containing a local copy of GA::Client->buttonList
        #   $buttonHashRef  - Reference to a hash containing a local copy of GA::Client->buttonHash
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $buttonListRef, $buttonHashRef, $check) = @_;

        # Local variables
        my (
            $count,
            @dataList,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->windows4Tab_refreshList',
                @_,
            );
        }

        # Compile the simple list data
        $count = 0;
        foreach my $buttonName (@$buttonListRef) {

            my ($buttonObj, $path, $pixBuffer);

            $count++;

            if ($buttonName eq 'separator') {

                # Create a pixbuff for an icon which isn't used for built-in toolbar buttons
                $path = $axmud::SHARE_DIR . '/icons/main/separator.png';
                $pixBuffer = Gtk2::Gdk::Pixbuf->new_from_file($path);
                push (@dataList,
                    $count,
                    $pixBuffer,
                    $buttonName,
                    FALSE,
                    '(Separator between buttons)',
                    undef,
                );

            } else {

                # Get the GA::Obj::Toolbar
                $buttonObj = $$buttonHashRef{$buttonName};

                # Get the icon's file path
                if ($buttonObj->customFlag) {
                    $path = $buttonObj->iconPath;
                } else {
                    $path = $axmud::SHARE_DIR . '/icons/main/' . $buttonObj->iconPath;
                }

                # Create a pixbuff for the icon (unless the file doesn't exist)
                if (-e $path) {

                    $pixBuffer = Gtk2::Gdk::Pixbuf->new_from_file($path);
                }

                push (@dataList,
                    $count,
                    $pixBuffer,
                    $buttonName,
                    $buttonObj->customFlag,
                    $buttonObj->descrip,
                    $buttonObj->instruct,
                );
            }
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub windows5Tab {

        # Windows5 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->windows5Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _5', $innerNotebook);

        # Textview objects
        $self->addLabel($table, '<b>Textview objects</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of textview objects, handling areas of the window where text is displayed</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Num', 'int',
            'Session', 'int',
            'Window', 'int',
            'Pane', 'int',
            'Lock', 'bool',
            'Split', 'text',
            'Colour scheme', 'text',
            'Mono', 'bool',
            'Text', 'text',
            'Undly', 'text',
            'Bckgrnd', 'text',
            'Font', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 250);           # Fixed height

        # Initialise the list
        $self->windows5Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add editing widgets
        my $entry = $self->addEntryWithIcon($table, undef, 'int', 0, undef,
            1, 3, 10, 11);
        my $button = $self->addButton(
            $table,
            'Set default size', 'Sets the default size for textview objects', undef,
            3, 6, 10, 11);
        $button->signal_connect('clicked' => sub {

            if ($self->checkEntryIcon($entry)) {

                $self->session->pseudoCmd(
                    'settextview ' . $entry->get_text(),
                    $self->pseudoCmdMode,
                );
            }
        });

        my $button2 = $self->addButton(
            $table,
            'Reset default size', 'Resets the default size for textview objects', undef,
            6, 9, 10, 11);
        $button2->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('settextview', $self->pseudoCmdMode);
        });

        my $button3 = $self->addButton(
            $table,
            'Clear textview', 'Removes all text from the selected textview object', undef,
            9, 12, 10, 11);
        $button3->signal_connect('clicked' => sub {

            my ($number, $textViewObj);

            ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                $textViewObj = $axmud::CLIENT->desktopObj->ivShow('textViewHash', $number);
                if ($textViewObj && $textViewObj->paneObj) {

                    # Clear the textview of text
                    $self->session->pseudoCmd('cleartextview -t ' . $number, $self->pseudoCmdMode);
                }
            }

            # Refresh the simple list and entry boxes
            $self->windows5Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button4 = $self->addButton(
            $table,
            'Dump', 'Display the list of textview objects in the \'main\' window', undef,
            8, 10, 11, 12);
        $button4->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('listtextview', $self->pseudoCmdMode);

            # Refresh the simple list and entry boxes
            $self->windows5Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button5 = $self->addButton(
            $table,
            'Refresh', 'Refresh the list of textview objects', undef,
            10, 12, 11, 12);
        $button5->signal_connect('clicked' => sub {

            # Refresh the simple list and entry boxes
            $self->windows5Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub windows5Tab_refreshList {

        # Called by $self->windows5Tab to refresh the Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::List
        #   $columns    - The number of columns in the list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my @dataList;

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->windows5Tab_refreshList',
                @_,
            );
        }

        # Compile the simple list data
        foreach my $textViewObj (
            sort {$a->number <=> $b->number} ($axmud::CLIENT->desktopObj->ivValues('textViewHash'))
        ) {
            my $paneString;

            if ($textViewObj->paneObj) {

                $paneString = $textViewObj->paneObj->number;
            }

            push (@dataList,
                $textViewObj->number,
                $textViewObj->session->number,
                $textViewObj->winObj->number,
                $paneString,
                $textViewObj->scrollLockFlag,
                $textViewObj->splitScreenMode,
                $textViewObj->colourScheme,
                $textViewObj->monochromeFlag,
                $textViewObj->textColour,
                $textViewObj->underlayColour,
                $textViewObj->backgroundColour,
                $textViewObj->font . ' ' . $textViewObj->fontSize,
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub soundTab {

        # Sound tab - called by $self->setupNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->soundTab', @_);
        }

        # Tab setup
        # Create a notebook within the main one, so that we have two rows of tabs
        my ($vBox, $innerNotebook) = $self->addInnerNotebookTab('So_und', $self->notebook);

        # Add tabs to the inner notebook. TTS isn't implemented on MS Windows yet, so check before
        #   displaying TTS tabs
        $self->sound1Tab($innerNotebook);
        if ($^O eq 'MSWin32') {

            $self->sound2Tab_mswin($innerNotebook);

        } else {

            $self->sound2Tab($innerNotebook);
            $self->sound3Tab($innerNotebook);
            $self->sound4Tab($innerNotebook);
            $self->sound5Tab($innerNotebook);
            $self->sound6Tab($innerNotebook);
            $self->sound7Tab($innerNotebook);
        }

        return 1;
    }

    sub sound1Tab {

        # Sound1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (
            $standardFlag,
            @columnList,
        );

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->sound1Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _1', $innerNotebook);

        # Sound effects
        $self->addLabel($table, '<b>Sound effects</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>List of shortcuts to available sound effects</i>',
            1, 6, 1, 2);

        $standardFlag = FALSE;
        my $checkButton = $self->addCheckButton($table, undef, TRUE,
            6, 7, 1, 2);
        # (->signal_connect appears below)
        $self->addLabel($table, 'List only standard sound effects',
            7, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Standard', 'bool',
            'Name', 'text',
            'File', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 8,
            -1, 180);       # Fixed height

        # Initialise the list
        $self->sound1Tab_refreshList($slWidget, scalar (@columnList / 2), $standardFlag);

        # Add entry boxes and buttons
        $self->addLabel($table, 'Name',
            1, 2, 8, 9);
        my $entry = $self->addEntryWithIcon($table, undef, 'string', 1, 16,
            2, 6, 8, 9);

        my $button = $self->addButton($table,
            'Add...', 'Add or replace a sound effect with the specified name', undef,
            6, 8, 8, 9);
        $button->signal_connect('clicked' => sub {

            my $name = $entry->get_text();

            if ($self->checkEntryIcon($entry)) {

                # Add the sound effect. A dialogue window is opened to choose a file
                $self->session->pseudoCmd('addsoundeffect <' . $name . '>', $self->pseudoCmdMode);

                # Refresh the simple list and reset the entry box
                $self->sound1Tab_refreshList($slWidget, scalar (@columnList / 2), $standardFlag);
                $self->resetEntryBoxes($entry);
            }
        });

        my $button2 = $self->addButton($table,
            'Add with no file',
            'Add or replace a sound effect with the specified name, without a file',
            undef,
            8, 12, 8, 9);
        $button2->signal_connect('clicked' => sub {

            my $name = $entry->get_text();

            if ($self->checkEntryIcon($entry)) {

                # Add the sound effect. A dialogue window is opened to choose a file
                $self->session->pseudoCmd(
                    'addsoundeffect -d <' . $name . '>',
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list and reset the entry box
                $self->sound1Tab_refreshList($slWidget, scalar (@columnList / 2), $standardFlag);
                $self->resetEntryBoxes($entry);
            }
        });

        my $button5 = $self->addButton(
            $table,
            'Play',
            'Play the selected sound effect',
            undef,
            1, 2, 9, 10);
        $button5->signal_connect('clicked' => sub {

            my ($name) = $self->getSimpleListData($slWidget, 1);
            if (defined $name) {

                # Play the sound effect
                $self->session->pseudoCmd('playsoundeffect <' . $name . '>', $self->pseudoCmdMode);

                # Refresh the simple list
                $self->sound1Tab_refreshList($slWidget, scalar (@columnList / 2), $standardFlag);
            }
        });

        my $button3 = $self->addButton(
            $table,
            'Change sound file',
            'Change the file for the selected sound effect',
            undef,
            2, 4, 9, 10);
        $button3->signal_connect('clicked' => sub {

            my ($name) = $self->getSimpleListData($slWidget, 1);
            if (defined $name) {

                # Edit the sound effect. A dialogue window is opened to choose a file
                $self->session->pseudoCmd('addsoundeffect <' . $name . '>', $self->pseudoCmdMode);

                # Refresh the simple list and reset the entry box
                $self->sound1Tab_refreshList($slWidget, scalar (@columnList / 2), $standardFlag);
                $self->resetEntryBoxes($entry);
            }
        });

        my $button4 = $self->addButton(
            $table,
            'Use no sound file',
            'Use no file with the selected sound effect',
            undef,
            4, 5, 9, 10);
        $button4->signal_connect('clicked' => sub {

            my ($name) = $self->getSimpleListData($slWidget, 1);
            if (defined $name) {

                # Edit the sound effect. A dialogue window is opened to choose a file
                $self->session->pseudoCmd(
                    'addsoundeffect <' . $name . '> -d',
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list and reset the entry box
                $self->sound1Tab_refreshList($slWidget, scalar (@columnList / 2), $standardFlag);
                $self->resetEntryBoxes($entry);
            }
        });

        my $button6 = $self->addButton($table, 'Delete', 'Delete the selected sound effect', undef,
            5, 6, 9, 10);
        $button6->signal_connect('clicked' => sub {

            my ($name) = $self->getSimpleListData($slWidget, 1);
            if (defined $name) {

                # Delete the sound effect
                $self->session->pseudoCmd(
                    'deletesoundeffect <' . $name . '>',
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list and reset the entry box
                $self->sound1Tab_refreshList($slWidget, scalar (@columnList / 2), $standardFlag);
                $self->resetEntryBoxes($entry);
            }
        });

        my $button7 = $self->addButton($table, 'Delete all', 'Delete all sound effects', undef,
            6, 8, 9, 10);
        $button7->signal_connect('clicked' => sub {

            # Delete all sound effects
            $self->session->pseudoCmd('deletesoundeffect -a', $self->pseudoCmdMode);

            # Refresh the simple list and reset the entry box
            $self->sound1Tab_refreshList($slWidget, scalar (@columnList / 2), $standardFlag);
            $self->resetEntryBoxes($entry);
        });

        my $button8 = $self->addButton($table,
            'Reset all', 'Resets the list of sound effects to the default list', undef,
            8, 10, 9, 10);
        $button8->signal_connect('clicked' => sub {

            # Reset sound effects
            $self->session->pseudoCmd('resetsoundeffect', $self->pseudoCmdMode);

            # Refresh the simple list and reset the entry box
            $self->sound1Tab_refreshList($slWidget, scalar (@columnList / 2), $standardFlag);
            $self->resetEntryBoxes($entry);
        });

        my $button9 = $self->addButton($table,
            'Dump', 'Display the list of sound effects in the \'main\' window', undef,
            10, 12, 9, 10);
        $button9->signal_connect('clicked' => sub {

            # List sound effects
            $self->session->pseudoCmd('listsoundeffect', $self->pseudoCmdMode);

            # Refresh the simple list
            $self->sound1Tab_refreshList($slWidget, scalar (@columnList / 2), $standardFlag);
        });

        # (->signal_connect from above)
        $checkButton->signal_connect('toggled' => sub {

            $standardFlag = $checkButton->get_active();

            # Refresh the simple list
            $self->sound1Tab_refreshList($slWidget, scalar (@columnList / 2), $standardFlag);
        });

        my $checkButton2 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 10, 11);
        $checkButton2->set_active($axmud::CLIENT->allowSoundFlag);
        $checkButton2->signal_connect('toggled' => sub {

            if ($checkButton2->get_active()) {
                $self->session->pseudoCmd('sound on', $self->pseudoCmdMode);
            } else {
                $self->session->pseudoCmd('sound off', $self->pseudoCmdMode);
            }

            # Refresh the simple list
            $self->sound1Tab_refreshList($slWidget, scalar (@columnList / 2), $standardFlag);
        });

        $self->addLabel($table, 'Enable sound effects in general',
            2, 12, 10, 11);

        my $checkButton3 = $self->addCheckButton($table, undef, TRUE,
            1, 2, 11, 12);
        $checkButton3->set_active($axmud::CLIENT->allowAsciiBellFlag);
        $checkButton3->signal_connect('toggled' => sub {

            if ($checkButton3->get_active()) {
                $self->session->pseudoCmd('asciibell on', $self->pseudoCmdMode);
            } else {
                $self->session->pseudoCmd('asciibell off', $self->pseudoCmdMode);
            }
            # Refresh the simple list
            $self->sound1Tab_refreshList($slWidget, scalar (@columnList / 2), $standardFlag);
        });

        $self->addLabel($table, 'Enable beeps sent by the world (while sound effects are on)',
            2, 12, 11, 12);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub sound1Tab_refreshList {

        # Called by $self->sound1Tab to refresh the Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::List
        #   $columns        - The number of columns in the list
        #   $standardFlag   - If TRUE, only standard sound effects in the sound effects bank are
        #                       shown. If FALSE, all sound effects in the sound effects bank are
        #                       shown
        #
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $standardFlag, $check) = @_;

        # Local variables
        my (
            @sortedList, @dataList,
            %standardHash, %customHash,
        );

        # Check for improper arguments
        if (
            ! defined $slWidget || ! defined $columns || ! defined $standardFlag
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->sound1Tab_refreshList', @_);
        }

        # Import the hash of sound effects, and sort them
        %standardHash = $axmud::CLIENT->constStandardSoundHash;
        %customHash = $axmud::CLIENT->customSoundHash;
        @sortedList = sort {lc($a) cmp lc($b)} (keys %customHash);

        # Compile the simple list data
        foreach my $effect (@sortedList) {

            my $flag;

            if (! exists $standardHash{$effect}) {
                $flag = FALSE;
            } else {
                $flag = TRUE;
            }

            if ($flag || ! $standardFlag) {

                push (@dataList, $flag, $effect, $customHash{$effect});
            }
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub sound2Tab {

        # Sound2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @comboList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->sound2Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _2', $innerNotebook);

        # Text-to-speech (TTS)
        $self->addLabel($table, '<b>Text-to-speech (TTS)</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $table,
            '<i>Convert text to audible speech, using any of the TTS engines that '
            . $axmud::SCRIPT . ' supports</i>',
            1, 12, 1, 2);

        my $checkButton = $self->addCheckButton($table, undef, TRUE,
            1, 12, 2, 3);
        $checkButton->set_active($axmud::CLIENT->customAllowTTSFlag);
        $checkButton->set_label(
            'Enable text-to-speech for all users',
        );
        $checkButton->signal_connect('toggled' => sub {

            if ($checkButton->get_active()) {
                $axmud::CLIENT->set_customAllowTTSFlag(TRUE);
            } else {
                $axmud::CLIENT->set_customAllowTTSFlag(FALSE);
            }
        });

        my $checkButton9 = $self->addCheckButton($table, undef, TRUE,
            1, 12, 3, 4);
        $checkButton9->set_active($axmud::CLIENT->ttsSmoothFlag);
        $checkButton9->set_label(
            'Allow TTS smoothing (makes the voice sound more natural by treating some phrases as'
            . ' individual sentences)',
        );
        $checkButton9->signal_connect('toggled' => sub {

            if ($checkButton9->get_active()) {
                $axmud::CLIENT->set_ttsFlag('smooth', TRUE);
            } else {
                $axmud::CLIENT->set_ttsFlag('smooth', FALSE);
            }
        });

        # Settings for text-to-speech conversion in specific contexts
        $self->addLabel(
            $table,
            '<i>Settings for text-to-speech conversion in specific contexts</i>',
            1, 12, 4, 5);

        my $checkButton2 = $self->addCheckButton($table, undef, TRUE,
            1, 12, 5, 6);
        $checkButton2->set_active($axmud::CLIENT->ttsReceiveFlag);
        $checkButton2->set_label(
            'Convert text received from the world',
        );
        $checkButton2->signal_connect('toggled' => sub {

            if ($checkButton2->get_active()) {
                $axmud::CLIENT->set_ttsFlag('receive', TRUE);
            } else {
                $axmud::CLIENT->set_ttsFlag('receive', FALSE);
            }
        });

        my $checkButton3 = $self->addCheckButton($table, undef, TRUE,
            2, 12, 6, 7);
        $checkButton3->set_active($axmud::CLIENT->ttsLoginFlag);
        $checkButton3->set_label(
            'Don\'t convert received text before an automatic login is processed (but do convert'
            . ' prompts)',
        );
        $checkButton3->signal_connect('toggled' => sub {

            if ($checkButton3->get_active()) {
                $axmud::CLIENT->set_ttsFlag('login', TRUE);
            } else {
                $axmud::CLIENT->set_ttsFlag('login', FALSE);
            }
        });

        my $checkButton4 = $self->addCheckButton($table, undef, TRUE,
            1, 12, 7, 8);
        $checkButton4->set_active($axmud::CLIENT->ttsSystemFlag);
        $checkButton4->set_label(
            'Convert system messages',
        );
        $checkButton4->signal_connect('toggled' => sub {

            if ($checkButton4->get_active()) {
                $axmud::CLIENT->set_ttsFlag('system', TRUE);
            } else {
                $axmud::CLIENT->set_ttsFlag('system', FALSE);
            }
        });

        my $checkButton5 = $self->addCheckButton($table, undef, TRUE,
            1, 12, 8, 9);
        $checkButton5->set_active($axmud::CLIENT->ttsSystemErrorFlag);
        $checkButton5->set_label(
            'Convert system error messages',
        );
        $checkButton5->signal_connect('toggled' => sub {

            if ($checkButton5->get_active()) {
                $axmud::CLIENT->set_ttsFlag('error', TRUE);
            } else {
                $axmud::CLIENT->set_ttsFlag('error', FALSE);
            }
        });

        my $checkButton6 = $self->addCheckButton($table, undef, TRUE,
            1, 12, 9, 10);
        $checkButton6->set_active($axmud::CLIENT->ttsWorldCmdFlag);
        $checkButton6->set_label(
            'Convert world commands',
        );
        $checkButton6->signal_connect('toggled' => sub {

            if ($checkButton6->get_active()) {
                $axmud::CLIENT->set_ttsFlag('command', TRUE);
            } else {
                $axmud::CLIENT->set_ttsFlag('command', FALSE);
            }
        });

        my $checkButton7 = $self->addCheckButton($table, undef, TRUE,
            1, 12, 10, 11);
        $checkButton7->set_active($axmud::CLIENT->ttsDialogueFlag);
        $checkButton7->set_label(
            'Convert \'dialogue\' windows',
        );
        $checkButton7->signal_connect('toggled' => sub {

            if ($checkButton7->get_active()) {
                $axmud::CLIENT->set_ttsFlag('dialogue', TRUE);
            } else {
                $axmud::CLIENT->set_ttsFlag('dialogue', FALSE);
            }
        });

        my $checkButton8 = $self->addCheckButton($table, undef, TRUE,
            1, 12, 11, 12);
        $checkButton8->set_active($axmud::CLIENT->ttsTaskFlag);
        $checkButton8->set_label(
            'Allow some tasks (e.g. the Status and Locator tasks) to convert certain strings to'
            . ' speech',
        );
        $checkButton8->signal_connect('toggled' => sub {

            if ($checkButton8->get_active()) {
                $axmud::CLIENT->set_ttsFlag('task', TRUE);
            } else {
                $axmud::CLIENT->set_ttsFlag('task', FALSE);
            }
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub sound2Tab_mswin {

        # Sound2 tab (temporary tab for MS Windows users)
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @comboList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->sound2Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _2', $innerNotebook);

        # Text-to-speech (TTS)
        $self->addLabel($table, '<b>Text-to-speech (TTS)</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $table,
            '<i>Built-in text-to-speech capabilities haven\'t been implemented on MS Windows'
            . ' systems yet</i>',
            1, 12, 1, 2);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub sound3Tab {

        # Sound3 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @comboList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->sound3Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _3', $innerNotebook);

        # Text-to-speech (cont.)
        $self->addLabel($table, '<b>Text-to-speech (cont.)</b>',
            0, 12, 0, 1);

        # Left column
        $self->addLabel($table, '<i>Supported TTS engines</i>',
            1, 6, 1, 2);
        my $textView = $self->addTextView($table, undef, FALSE,
            1, 6, 2, 8,
            FALSE,          # Don't treat as a list
            FALSE,          # Don't remove empty lines
            TRUE,           # ...but do remove leading/trailing whitespace
            FALSE,          # Allow horizontal scrolling
            -1, 150);       # Fixed height
        my $buffer = $textView->get_buffer();
        $buffer->set_text(join("\n", $axmud::CLIENT->constTTSList));

        # Right column
        $self->addLabel($table, '<i>Festival server settings</i>',
            7, 12, 1, 2);

        $self->addLabel($table, 'Festival server port',
            7, 8, 2, 3);
        my $entry = $self->addEntryWithIcon($table, undef, 'int', 0, 65535,
            8, 10, 2, 3);
        $entry->set_text($axmud::CLIENT->ttsFestivalServerPort);
        my $button = $self->addButton($table, 'Set', 'Set the Festival server port', undef,
            10, 11, 2, 3);
        $button->signal_connect('clicked' => sub {

            if ($self->checkEntryIcon($entry)) {

                $self->session->pseudoCmd('speech port ' . $entry->get_text());
            }
        });
        my $button2 = $self->addButton(
            $table,
            'Reset',
            'Use the default Festival server port',
            undef,
            11, 12, 2, 3);
        $button2->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('speech port ' . $axmud::CLIENT->constTtsFestivalServerPort);
            $entry->set_text($axmud::CLIENT->ttsFestivalServerPort);
        });

        $self->addLabel(
            $table,
            'Try to start the Festival server whenever ' . $axmud::SCRIPT . ' starts up',
            7, 11, 3, 4);
        my $checkButton = $self->addCheckButton($table, undef, TRUE,
            11, 12, 3, 4);
        $checkButton->set_active($axmud::CLIENT->ttsStartServerFlag);
        $checkButton->signal_connect('toggled' => sub {

            if ($checkButton->get_active()) {
                $self->session->pseudoCmd('speech auto on');
            } else {
                $self->session->pseudoCmd('speech auto off');
            }
        });

        my $button3 = $self->addButton(
            $table, 'Start server', 'Start the Festival server on your system', undef,
            8, 10, 4, 5);
        $button3->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('speech restart');
        });

        my $button4 = $self->addButton(
            $table, 'Reconnect', 'Attempt to reconnect to the Festival server', undef,
            10, 12, 4, 5);
        $button4->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('speech reconnect');
        });

        # (add more labels, to get the spacing right)
        $self->addLabel($table, '',
            7, 12, 4, 5);
        $self->addLabel($table, '',
            7, 12, 5, 6);
        $self->addLabel($table, '',
            7, 12, 6, 7);
        $self->addLabel($table, '',
            7, 12, 7, 8);

        # Bottom section
        $self->addLabel($table, '<i>Text-to-speech engine test</i>',
            1, 12, 8, 9);
        $self->addLabel($table, 'Text to read aloud:',
            1, 3, 9, 10);
        my $entry2 = $self->addEntry($table, undef, TRUE,
            3, 12, 9, 10);
        $entry2->set_text('Hello, my name is ' . $axmud::SCRIPT . ' and I am your mud client.');

        @comboList = $axmud::CLIENT->constTTSList;
        my $combo = $self->addComboBox($table, undef, \@comboList, '',
            TRUE,               # No 'undef' value used
            8, 10, 10, 11);

        my $button5 = $self->addButton(
            $table, 'Test engine', 'Read aloud this text using the selected TTS engine', undef,
            10, 12, 10, 11);
        $button5->signal_connect('clicked' => sub {

            # (Actually, we use settings for the TTS configuration with the same name as the engine)

            my ($text, $configuration);

            $text = $entry2->get_text();
            $configuration = $combo->get_active_text();

            if ($text) {

                $self->session->pseudoCmd(
                    'speak -n ' . $configuration . ' <' . $text . '>',
                    $self->pseudoCmdMode,
                );
            }
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub sound4Tab {

        # Sound4 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (@columnList, @comboList);

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->sound4Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _4', $innerNotebook);

        # Text-to-speech configurations
        $self->addLabel($table, '<b>Text-to-speech configurations</b>',
            0, 13, 0, 1);
        $self->addLabel(
            $table,
            '<i>Text-to-speech configurations store voice settings for use in all kinds of'
            . ' situations</i>',
            1, 13, 1, 2);

        # Add a simple list
        @columnList = (
            'Name', 'text',
            'Engine', 'text',
            'Modifiable', 'bool',
            'Deletable', 'bool',
            'Voice', 'text',
            'Speed', 'int',
            'Pitch', 'int',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 13, 2, 10,
            -1, 230);       # Fixed height

        # Initialise the list
        $self->sound4Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add entries and buttons
        $self->addLabel($table, 'Configuration name',
            1, 3, 10, 11);
        my $entry = $self->addEntryWithIcon($table, undef, 'string', 1, 16,
            3, 5, 10, 11);

        $self->addLabel($table, 'Engine',
            5, 7, 10, 11);
        @comboList = $axmud::CLIENT->constTTSList;
        my $combo = $self->addComboBox($table, undef, \@comboList, '',
            TRUE,               # No 'undef' value used
            7, 9, 10, 11);

        my $button = $self->addButton(
            $table,
            'Add',
            'Add a new text-to-speech configuration',
            undef,
            9, 11, 10, 11);
        $button->signal_connect('clicked' => sub {

            my ($configuration, $engine);

            if ($self->checkEntryIcon($entry)) {

                $configuration = $entry->get_text();
                $engine = $combo->get_active_text();

                # Add the configuration
                $self->session->pseudoCmd(
                    'addconfig ' . $configuration . ' ' . $engine,
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list
                $self->sound4Tab_refreshList($slWidget, scalar (@columnList / 2));
            }
        });

        my $button2 = $self->addButton(
            $table,
            'Clone',
            'Clone the selected text-to-speech configuration',
            undef,
            11, 13, 10, 11);
        $button2->signal_connect('clicked' => sub {

            my ($original, $copy);

            if ($self->checkEntryIcon($entry)) {

                $copy = $entry->get_text();
                ($original) = $self->getSimpleListData($slWidget, 0);
                if (defined $original) {

                    # Clone the configuration
                    $self->session->pseudoCmd(
                        'cloneconfig ' . $original . ' ' . $copy,
                        $self->pseudoCmdMode,
                    );

                    # Refresh the simple list
                    $self->sound4Tab_refreshList($slWidget, scalar (@columnList / 2));
                }
            }
        });

        my $button3 = $self->addButton(
            $table,
            'Edit',
            'Edit the selected text-to-speech configuration',
            undef,
            7, 9, 11, 12);
        $button3->signal_connect('clicked' => sub {

            my ($configuration, $ttsObj, $childWinObj);

            ($configuration) = $self->getSimpleListData($slWidget, 0);
            if (defined $configuration) {

                # Get the corresponding GA::Obj::Tts object
                $ttsObj = $axmud::CLIENT->ivShow('ttsObjHash', $configuration);
                if ($ttsObj) {

                    # Open an 'edit' window for the configuration object
                    $self->createFreeWin(
                        'Games::Axmud::EditWin::TTS',
                        $self,
                        $self->session,
                        'Edit text-to-speech configuration \'' . $configuration . '\'',
                        $ttsObj,
                        FALSE,          # Not temporary
                    );
                }

                if ($childWinObj) {

                    # When the 'edit' window closes, update widgets and/or IVs
                    $self->add_childDestroy(
                        $childWinObj,
                        'sound4Tab_refreshList',
                        [$slWidget, (scalar @columnList / 2)],
                    );
                }
            }
        });

        my $button4 = $self->addButton(
            $table,
            'Delete',
            'Delete the selected text-to-speech configuration',
            undef,
            9, 11, 11, 12);
        $button4->signal_connect('clicked' => sub {

            my ($configuration) = $self->getSimpleListData($slWidget, 0);
            if (defined $configuration) {

                # Delete the configuration
                $self->session->pseudoCmd(
                    'deleteconfig ' . $configuration,
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list
                $self->sound4Tab_refreshList($slWidget, scalar (@columnList / 2));
            }
        });

        my $button5 = $self->addButton($table, 'Reset', 'Reset the list of configurations', undef,
            11, 13, 11, 12);
        $button5->signal_connect('clicked' => sub {

            my %ivHash;

            # Refresh the simple list and reset entry boxes
            $self->sound4Tab_refreshList($slWidget, (scalar @columnList / 2));
            $self->resetEntryBoxes($entry);
            $combo->set_active(0);
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub sound4Tab_refreshList {

        # Called by $self->sound4Tab to refresh the Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::List
        #   $columns    - The number of columns in the list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (
            @sortedList, @dataList,
            %hash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->sound4Tab_refreshList', @_);
        }

        # Import the hash of TTS configurations, and sort them
        %hash = $axmud::CLIENT->ttsObjHash;
        @sortedList = sort {lc($a->name) cmp lc($b->name)} (values %hash);

        # Compile the simple list data
        foreach my $obj (@sortedList) {

            push (@dataList, $obj->name, $obj->engine);

            if ($axmud::CLIENT->ivExists('constTtsFixedObjHash', $obj->name)) {
                push (@dataList, FALSE, FALSE);     # Not modifiable, not deletable
            } elsif ($axmud::CLIENT->ivExists('constTtsPermObjHash', $obj->name)) {
                push (@dataList, TRUE, FALSE);      # Modifiable, not deletable
            } else {
                push (@dataList, TRUE, TRUE);       # Modifiable, deletable
            }

            push (@dataList, $obj->voice, $obj->speed, $obj->pitch);
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub sound5Tab {

        # Sound5 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->sound5Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _5', $innerNotebook);

        # Text-to-speech attributes
        $self->addLabel($table, '<b>Text-to-speech attributes</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $table,
            '<i>Attributes used with the \';read\' and \';permread\' commands</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Attribute', 'text',
            'Assigned to task', 'text',
            'Built-in task', 'bool',
            '', 'text',                     # Dummy to keep the to the left
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);       # Fixed height

        # Initialise the list
        $self->sound5Tab_refreshList($slWidget, scalar (@columnList / 2), 'ttsAttribHash');

        # Add buttons
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of assigned attributes', undef,
            10, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->sound5Tab_refreshList($slWidget, scalar (@columnList / 2), 'ttsAttribHash');
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub sound5Tab_refreshList {

        # Called by $self->sound5Tab, ->sound6Tab and ->sound7Tab Tab to refresh the
        #   Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::List
        #   $columns    - The number of columns in the list
        #   $iv         - 'ttsAttribHash', 'ttsFlagAttribHash' or 'ttsAlertAttribHash'
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $iv, $check) = @_;

        # Local variables
        my @dataList;

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->sound5Tab_refreshList',
                @_,
            );
        }

        # Compile the simple list data
        foreach my $key (sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys($iv))) {

            my ($taskName, $flag);

            # A built-in task, or not?
            $taskName = $axmud::CLIENT->ivShow($iv, $key);
            if (! $axmud::CLIENT->ivExists('pluginTaskHash', $taskName)) {
                $flag = TRUE;
            } else {
                $flag = FALSE;
            }

            push (@dataList, $key, $taskName, $flag, '');
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub sound6Tab {

        # Sound6 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->sound6Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _6', $innerNotebook);

        # Text-to-speech flag attributes
        $self->addLabel($table, '<b>Text-to-speech flag attributes</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $table,
            '<i>Attributes used with the \';switch\' and \';permswitch\' commands</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Attribute', 'text',
            'Assigned to task', 'text',
            'Built-in task', 'bool',
            '', 'text',                     # Dummy to keep the to the left
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);       # Fixed height

        # Initialise the list
        $self->sound5Tab_refreshList($slWidget, scalar (@columnList / 2), 'ttsFlagAttribHash');

        # Add buttons
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of assigned attributes', undef,
            10, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->sound5Tab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                'ttsFlagAttribHash',
            );
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub sound7Tab {

        # Sound7 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->sound7Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _7', $innerNotebook);

        # Text-to-speech alert attributes
        $self->addLabel($table, '<b>Text-to-speech alert attributes</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $table,
            '<i>Attributes used with the \';alert\' and \';permalert\' commands</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Attribute', 'text',
            'Assigned to task', 'text',
            'Built-in task', 'bool',
            '', 'text',                     # Dummy to keep the to the left
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);       # Fixed height

        # Initialise the list
        $self->sound5Tab_refreshList($slWidget, scalar (@columnList / 2), 'ttsAlertAttribHash');

        # Add buttons
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of assigned attributes', undef,
            10, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->sound5Tab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                'ttsAlertAttribHash',
            );
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub tasksTab {

        # Tasks tab - called by $self->setupNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->tasksTab', @_);
        }

        # Tab setup
        # Create a notebook within the main one, so that we have two rows of tabs
        my ($vBox, $innerNotebook) = $self->addInnerNotebookTab('_Tasks', $self->notebook);

        # Add tabs to the inner notebook
        $self->tasks1Tab($innerNotebook, 'first');
        $self->tasks1Tab($innerNotebook, 'last');

        return 1;
    }

    sub tasks1Tab {

        # Tasks1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #   $type           - Which runlist is being edited - 'first' or 'last'
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $type, $check) = @_;

        # Local variables
        my (@columnList, @comboList);

        # Check for improper arguments
        if (! defined $innerNotebook || ! defined $type || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->tasks1Tab', @_);
        }

        # Tab setup
        my ($vBox, $table);

        if ($type eq 'first') {
            ($vBox, $table) = $self->addTab('Page _1', $innerNotebook);
        } else {
            ($vBox, $table) = $self->addTab('Page _2', $innerNotebook);
        }

        # Task runlists
        if ($type eq 'first') {

            $self->addLabel($table, '<b>Task first runlist</b>',
                0, 12, 0, 1);
            $self->addLabel($table,
                '<i>List of tasks that are run first, before any others, in each task loop</i>',
                1, 12, 1, 2);

        } else {

            $self->addLabel($table, '<b>Task last runlist</b>',
                0, 12, 0, 1);
            $self->addLabel($table,
                '<i>List of tasks that are run last, after any others, in each task loop</i>',
                1, 12, 1, 2);
        }

        # Add a simple list
        @columnList = (
            'Task name', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 230);     # Fixed height

        # Unusual step - need to save the simple list, because $self->tasks1Tab_refreshList
        #   updates both simple lists together. Because this is a 'pref' window, the lists are
        #   stored in $self->editConfigHash
        if ($type eq 'first') {
            $self->ivAdd('editConfigHash', 'first_list', $slWidget);
        } else {
            $self->ivAdd('editConfigHash', 'last_list', $slWidget);
        }

        # Initialise the simple list
        $self->tasks1Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add buttons
        @comboList = sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('taskPackageHash'));
        my $combo = $self->addComboBox($table, undef, \@comboList, '',
            TRUE,               # No 'undef' value used
            1, 3, 10, 11);

        my $button = $self->addButton($table, 'Add', 'Add the selected task to the runlist', undef,
            3, 5, 10, 11);
        $button->signal_connect('clicked' => sub {

            my (
                $task, $match,
                @newList,
            );

            $task = $combo->get_active_text();

            # Import the existing runlist
            if ($type eq 'first') {
                @newList = $axmud::CLIENT->taskRunFirstList;
            } else {
                @newList = $axmud::CLIENT->taskRunLastList;
            }

            # Check the task isn't already on the list
            OUTER: foreach my $item (@newList) {

                if ($item eq $task) {

                    $match = $item;
                    last OUTER;
                }
            }

            if (! $match) {

                # Task isn't already on the list, so put it there
                push (@newList, $task);
            }

            # Update the runlist
            if ($type eq 'first') {

                $self->session->pseudoCmd(
                    'setrunlist -f ' . join(' ', @newList),
                    $self->pseudoCmdMode,
                );

            } else {

                $self->session->pseudoCmd(
                    'setrunlist -l ' . join(' ', @newList),
                    $self->pseudoCmdMode,
                );
            }

            # Refresh the simple list
            $self->tasks1Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button2 = $self->addButton($table,
            'Delete', 'Delete the selected task from the runlist', undef,
            5, 7, 10, 11);
        $button2->signal_connect('clicked' => sub {

            my (
                $task,
                @newList, @reducedList,
            );

            ($task) = $self->getSimpleListData($slWidget, 0);

            # Import the existing runlist
            if ($type eq 'first') {
                @newList = $axmud::CLIENT->taskRunFirstList;
            } else {
                @newList = $axmud::CLIENT->taskRunLastList;
            }

            # Remove the selected task from the list (if it is present)
            foreach my $item (@newList) {

                if ($item ne $task) {

                    push (@reducedList, $item);
                }
            }

            # Update the runlist
            if ($type eq 'first') {

                $self->session->pseudoCmd(
                    'setrunlist -f ' . join(' ', @reducedList),
                    $self->pseudoCmdMode,
                );

            } else {

                $self->session->pseudoCmd(
                    'setrunlist -l ' . join(' ', @reducedList),
                    $self->pseudoCmdMode,
                );
            }

            # Refresh the simple list
            $self->tasks1Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button3 = $self->addButton($table,
            'Use default list', 'Use the default first and last runlists', undef,
            7, 10, 10, 11);
        $button3->signal_connect('clicked' => sub {

            # Set the default runlists
            $self->session->pseudoCmd('setrunlist -d', $self->pseudoCmdMode);

            # Refresh the simple list
            $self->tasks1Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button4 = $self->addButton($table,
            'Dump', 'Display both runlists in the \'main\' window', undef,
            10, 12, 10, 11);
        $button4->signal_connect('clicked' => sub {

            # Display runlists
            $self->session->pseudoCmd('setrunlist', $self->pseudoCmdMode);

            # Refresh the simple list
            $self->tasks1Tab_refreshList($slWidget, scalar (@columnList / 2));
        });


        my $button5 = $self->addButton($table,
            'Move up', 'Move the selected task up the runlist', undef,
            1, 3, 11, 12);
        $button5->signal_connect('clicked' => sub {

            my (
                $task, $match, $count,
                @newList, @modList,
            );

            ($task) = $self->getSimpleListData($slWidget, 0);
            if ($task) {

                # Import the existing runlist
                if ($type eq 'first') {
                    @newList = $axmud::CLIENT->taskRunFirstList;
                } else {
                    @newList = $axmud::CLIENT->taskRunLastList;
                }

                # Remove the selected task from the list
                $count = -1;
                foreach my $item (@newList) {

                    $count++;

                    if ($item ne $task || $count == 0) {

                        push (@modList, $item);

                    } else {

                        $match = $count;
                    }
                }

                if (defined $match) {

                    # A task was removed. Replace it one place higher
                    $match--;
                    splice (@modList, $match, 0, $task);
                }

                # Update the runlist
                if ($type eq 'first') {

                    $self->session->pseudoCmd(
                        'setrunlist -f ' . join(' ', @modList),
                        $self->pseudoCmdMode,
                    );

                } else {

                    $self->session->pseudoCmd(
                        'setrunlist -l ' . join(' ', @modList),
                        $self->pseudoCmdMode,
                    );
                }
            }

            # Refresh the simple list and select the same line
            $self->tasks1Tab_refreshList($slWidget, scalar (@columnList / 2));
            if (defined $match) {

                $slWidget->select($match);
            }
        });

        my $button6 = $self->addButton($table,
            'Move down', 'Move the selected task up the runlist', undef,
            10, 12, 11, 12);
        $button6->signal_connect('clicked' => sub {

            my (
                $task, $match, $count,
                @newList, @modList,
            );

            ($task) = $self->getSimpleListData($slWidget, 0);
            if ($task) {

                # Import the existing runlist
                if ($type eq 'first') {
                    @newList = $axmud::CLIENT->taskRunFirstList;
                } else {
                    @newList = $axmud::CLIENT->taskRunLastList;
                }

                # Remove the selected task from the list
                $count = -1;
                foreach my $item (@newList) {

                    $count++;

                    if ($item ne $task || $count == (scalar (@newList) - 1)) {

                        push (@modList, $item);

                    } else {

                        $match = $count;
                    }
                }

                if (defined $match) {

                    # A task was removed. Replace it one place lower
                    $match++;
                    splice (@modList, $match, 0, $task);
                }

                # Update the runlist
                if ($type eq 'first') {

                    $self->session->pseudoCmd(
                        'setrunlist -f ' . join(' ', @modList),
                        $self->pseudoCmdMode,
                    );

                } else {

                    $self->session->pseudoCmd(
                        'setrunlist -l ' . join(' ', @modList),
                        $self->pseudoCmdMode,
                    );
                }
            }

            # Refresh the simple list and select the same line
            $self->tasks1Tab_refreshList($slWidget, scalar (@columnList / 2));
            if (defined $match) {

                $slWidget->select($match);
            }
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub tasks1Tab_refreshList {

        # Called by $self->tasks1Tab to refresh the Gtk::Ex::Simple::Lists
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::List (not used here)
        #   $columns        - The number of columns in the list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (
            $thisSimpleList,
            @firstList, @lastList,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->tasks1Tab_refreshList', @_);
        }

        # $self->tasks1Tab is used for two tabs; refresh the simple list in both
        $thisSimpleList = $self->ivShow('editConfigHash', 'first_list');
        @firstList = $axmud::CLIENT->taskRunFirstList;

        $self->resetListData($thisSimpleList, [@firstList], $columns);

        # (The second simple list may not have been created yet)
        if ($self->ivExists('editConfigHash', 'last_list')) {

            $thisSimpleList = $self->ivShow('editConfigHash', 'last_list');
            @lastList = $axmud::CLIENT->taskRunLastList;

            $self->resetListData($thisSimpleList, [@lastList], $columns);
        }

        return 1;
    }

    sub scriptsTab {

        # Scripts tab
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            @columnList, @initList, @comboList,
            %comboHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->scriptsTab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Sc_ripts', $self->notebook);

        # Initial tasks
        $self->addLabel($table, '<b>Initial scripts</b>',
            0, 13, 0, 1);
        $self->addLabel($table,
            '<i>List of initial scripts that start with every new session (after the character'
            . ' logs in)</i>',
            1, 13, 1, 2);

        # Add a simple list
        @columnList = (
            'Script' => 'text',
            'Run mode' => 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 13, 2, 10,
            -1, 260);     # Fixed height

        # Initialise the list
        $self->scriptsTab_refreshList($slWidget, (scalar @columnList / 2));

        # Add editing entry boxes/buttons
        $self->addLabel($table, 'Script name',
            1, 3, 10, 11);
        my $entry = $self->addEntryWithIcon($table, undef, 'string', 1, undef,
            3, 7, 10, 11);

        $self->addLabel($table, 'Run mode',
            7, 9, 10, 11);

        @initList = (
            'no_task'       => 'Run without a task',
            'run_task'      => 'Run from within a task',
            'run_task_win'  => 'Run in \'forced window\' mode',
        );

        do {

            my ($value, $string, $descrip);

            $value = shift @initList;
            $string = shift @initList;
            $descrip = 'Mode \'' . $value . '\' - ' . $string;

            push (@comboList, $descrip);
            $comboHash{$descrip} = $value;

        } until (! @initList);

        my $combo = $self->addComboBox($table, undef, \@comboList, '',
            TRUE,               # No 'undef' value used
            9, 13, 10, 11);

        my $button = $self->addButton(
            $table,
            'Add',
            'Add this script to the global list of initial scripts',
            undef,
            1, 3, 11, 12,
        );
        $button->signal_connect('clicked' => sub {

            my ($scriptName, $descrip, $mode, $switch);

            if ($self->checkEntryIcon($entry)) {

                $scriptName = $entry->get_text();
                $descrip = $combo->get_active_text();
                $mode = $comboHash{$descrip};

                if ($mode eq 'no_task') {
                    $switch = '-r';
                } elsif ($mode eq 'run_task') {
                    $switch = '-t';
                } else {
                    $switch = '-c';
                }

                $self->session->pseudoCmd(
                    'addinitialscript ' . $scriptName . ' ' . $switch,
                    $self->pseudoCmdMode,
                );

                # Reset the simple list and reset the entry box
                $self->scriptsTab_refreshList($slWidget, (scalar @columnList / 2));
                $self->resetEntryBoxes($entry);
            }
        });

        my $button2 = $self->addButton(
            $table,
            'Delete',
            'Delete the selected script',
            undef,
            3, 5, 11, 12);
        $button2->signal_connect('clicked' => sub {

            my ($name) = $self->getSimpleListData($slWidget, 0);
            if (defined $name) {

                $self->session->pseudoCmd(
                    'deleteinitialscript ' . $name,
                    $self->pseudoCmdMode,
                );

                # Reset the simple list and reset the entry box
                $self->scriptsTab_refreshList($slWidget, (scalar @columnList / 2));
                $self->resetEntryBoxes($entry);
            }
        });

        my $button3 = $self->addButton($table,
            'Move up', 'Move the selected script up the list', undef,
            5, 7, 11, 12);
        $button3->signal_connect('clicked' => sub {

            my (
                $script, $match, $count,
                @orderList, @modList,
            );

            ($script) = $self->getSimpleListData($slWidget, 0);
            if (defined $script) {

                # Import the existing order list
                @orderList = $axmud::CLIENT->initScriptOrderList;

                # Remove the selected script from the list
                $count = -1;
                foreach my $item (@orderList) {

                    $count++;

                    if ($item ne $script || $count == 0) {

                        push (@modList, $item);

                    } else {

                        $match = $count;
                    }
                }

                if (defined $match) {

                    # A script was removed. Replace it one place higher
                    $match--;
                    splice (@modList, $match, 0, $script);
                }

                # Update the list
                $axmud::CLIENT->set_initScriptOrderList(@modList);

                # Refresh the simple list and select the same line
                $self->scriptsTab_refreshList($slWidget, scalar (@columnList / 2));
                if (defined $match) {

                    $slWidget->select($match);
                }
            }
        });

        my $button4 = $self->addButton($table,
            'Move down', 'Move the selected script down the list', undef,
            7, 9, 11, 12);
        $button4->signal_connect('clicked' => sub {

            my (
                $script, $match, $count,
                @orderList, @modList,
            );

            ($script) = $self->getSimpleListData($slWidget, 0);
            if (defined $script) {

                # Import the existing order list
                @orderList = $axmud::CLIENT->initScriptOrderList;

                # Remove the selected script from the list
                $count = -1;
                foreach my $item (@orderList) {

                    $count++;

                    if ($item ne $script || $count == (scalar (@orderList) - 1)) {

                        push (@modList, $item);

                    } else {

                        $match = $count;
                    }
                }

                if (defined $match) {

                    # A script was removed. Replace it one place lower
                    $match++;
                    splice (@modList, $match, 0, $script);
                }

                # Update the list
                $axmud::CLIENT->set_initScriptOrderList(@modList);

                # Refresh the simple list and select the same line
                $self->scriptsTab_refreshList($slWidget, scalar (@columnList / 2));
                if (defined $match) {

                    $slWidget->select($match);
                }
            }
        });

        my $button5 = $self->addButton(
            $table,
            'Dump',
            'Display this profile\'s list of initial tasks in the \'main\' window',
            undef,
            9, 11, 11, 12,
        );
        $button5->signal_connect('clicked' => sub {

            # Display initial scripts
            $self->session->pseudoCmd('listinitialscript', $self->pseudoCmdMode);

            # Reset the simple list
            $self->scriptsTab_refreshList($slWidget, (scalar @columnList / 2));
        });

        my $button6 = $self->addButton(
            $table,
            'Refresh list',
            'Refresh the list of initial scripts',
            undef,
            11, 13, 11, 12,
        );
        $button6->signal_connect('clicked' => sub {

            # Reset the simple list
            $self->scriptsTab_refreshList($slWidget, (scalar @columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub scriptsTab_refreshList {

        # Called by $self->scriptsTab to refresh the Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::List
        #   $columns    - Number of columns in the simple list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my @dataList;

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->scriptsTab_refreshList',
                @_,
            );
        }

        # Compile the simple list data
        OUTER: foreach my $scriptName ($axmud::CLIENT->initScriptOrderList) {

            push (@dataList,
                $scriptName,
                $axmud::CLIENT->ivShow('initScriptHash', $scriptName),
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub chatTab {

        # Chat tab - called by $self->setupNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->chatTab', @_);
        }

        # Tab setup
        # Create a notebook within the main one, so that we have two rows of tabs
        my ($vBox, $innerNotebook) = $self->addInnerNotebookTab('C_hat', $self->notebook);

        # Add tabs to the inner notebook
        $self->chat1Tab($innerNotebook);
        $self->chat2Tab($innerNotebook);
        $self->chat3Tab($innerNotebook);
        $self->chat4Tab($innerNotebook);
        $self->chat5Tab($innerNotebook);

        return 1;
    }

    sub chat1Tab {

        # Chat1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->chat1Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _1', $innerNotebook);

        # Chat task actions
        $self->addLabel($table, '<b>Chat task actions</b>',
            0, 12, 0, 1);

        # Left column
        $self->addLabel($table, '<i>Incoming calls</i>',
            1, 6, 1, 2);

        my $button = $self->addButton($table, 'Listen', 'Listen out for incoming calls', undef,
            1, 2, 2, 3);
        $button->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('chatlisten', $self->pseudoCmdMode);
        });
        $self->addLabel($table, 'Listen out for incoming calls',
            2, 6, 2, 3);

        my $button2 = $self->addButton($table, 'Ignore', 'Stop listening for incoming calls', undef,
            1, 2, 3, 4);
        $button2->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('chatignore', $self->pseudoCmdMode);
        });
        $self->addLabel($table, 'Stop listening out for incoming calls',
            2, 6, 3, 4);

        my ($group, $radioButton) = $self->addRadioButton($table, undef, undef, undef, undef, TRUE,
            1, 2, 4, 5);
        if ($axmud::CLIENT->chatAcceptMode eq 'accept_all') {

            $radioButton->set_active(TRUE);
        }
        $self->addLabel($table, 'Auto-accept all incoming calls',
            2, 6, 4, 5);

        my ($group2, $radioButton2) = $self->addRadioButton(
            $table, $group, undef, undef, undef, TRUE,
            1, 2, 5, 6);
        if ($axmud::CLIENT->chatAcceptMode eq 'accept_contact') {

            $radioButton2->set_active(TRUE);
        }
        $self->addLabel($table, 'Auto-accept calls from known contacts',
            2, 6, 5, 6);

        my ($group3, $radioButton3) = $self->addRadioButton(
            $table, $group, undef, undef, undef, TRUE,
            1, 2, 6, 7);
        if ($axmud::CLIENT->chatAcceptMode eq 'prompt') {

            $radioButton3->set_active(TRUE);
        }
        $self->addLabel($table, 'Ask before accepting incoming calls',
            2, 6, 6, 7);

        $radioButton->signal_connect('toggled' => sub {

            if ($radioButton->get_active()) {

                $self->session->pseudoCmd('chatset -i', $self->pseudoCmdMode);
            }
        });
        $radioButton2->signal_connect('toggled' => sub {

            if ($radioButton2->get_active()) {

                $self->session->pseudoCmd('chatset -c', $self->pseudoCmdMode);
            }
        });
        $radioButton3->signal_connect('toggled' => sub {

            if ($radioButton3->get_active()) {

                $self->session->pseudoCmd('chatset -u', $self->pseudoCmdMode);
            }
        });

        # Right column
        $self->addLabel($table, '<i>Outgoing calls (see also page 4)</i>',
            7, 13, 1, 2);

        my $entry = $self->addEntryWithIcon($table, undef, 'string', 3, 128,
            7, 10, 2, 3);
        $self->addLabel($table, 'IP address',
            10, 12, 2, 3);

        my $entry2 = $self->addEntryWithIcon($table, undef, 'int', 0, 65535,
            7, 10, 3, 4);
        $entry2->set_text($axmud::CLIENT->constChatPort);
        $self->addLabel($table, 'Port',
            10, 12, 3, 4);

        my $button4 = $self->addButton($table,
            'MudMaster call', 'Call using the MudMaster protocol', undef,
            7, 9, 4, 5);
        $button4->signal_connect('clicked' => sub {

            my ($ip, $port);

            if ($self->checkEntryIcon($entry, $entry2)) {

                $ip = $entry->get_text();
                $port = $entry2->get_text();

                $self->session->pseudoCmd(
                    'chatmcall ' . $ip . ' ' . $port,
                    $self->pseudoCmdMode,
                );
            }
        });

        my $button5 = $self->addButton($table, 'zChat call', 'Call using the zChat protocol', undef,
            9, 12, 4, 5);
        $button5->signal_connect('clicked' => sub {

            my ($ip, $port);

            if ($self->checkEntryIcon($entry, $entry2)) {

                $ip = $entry->get_text();
                $port = $entry2->get_text();

                $self->session->pseudoCmd(
                    'chatzcall ' . $ip . ' ' . $port,
                    $self->pseudoCmdMode,
                );
            }
        });

        $self->addLabel($table, '<i>Current calls</i>',
            7, 12, 5, 6);
        my $button3 = $self->addButton($table,
            'Stop calls', 'Terminate all current chat sessions', undef,
            7, 8, 6, 7);
        $button3->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('chathangup', $self->pseudoCmdMode);
        });
        $self->addLabel($table, 'Terminate all current chat sessions',
            8, 12, 6, 7);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub chat2Tab {

        # Chat2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (
            $radioChoice, $switchString,
            @buttonList, @textButtonList, @noTextButtonList,
        );

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->chat2Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _2', $innerNotebook);

        # Chat task actions
        $self->addLabel($table, '<b>Chat task actions (cont.)</b>',
            0, 12, 0, 1);

        # Left column
        my ($group, $radioButton) = $self->addRadioButton(
            $table, undef, 'Apply to all sessions', undef, undef, TRUE,
            1, 6, 1, 2);

        my ($group2, $radioButton2) = $self->addRadioButton(
            $table, $group, 'Apply to group:', undef, undef, TRUE,
            1, 3, 2, 3);
        my $entry = $self->addEntryWithIcon($table,
            undef, 'string', 1, 16,
            3, 6, 2, 3);
        $entry->set_sensitive(FALSE);       # Starts insensitive

        my ($group3, $radioButton3) = $self->addRadioButton(
            $table, $group, 'Apply to name:', undef, undef, TRUE,
            1, 3, 3, 4);
        my $entry2 = $self->addEntryWithIcon($table,
            undef, 'string', 1, 16,
            3, 6, 3, 4);
        $entry2->set_sensitive(FALSE);       # Starts insensitive

        $radioChoice = 0;
        $switchString = '';

        my $button = $self->addButton($table,
            'Allow snooping', 'Allow the selected contacts to snoop you', undef,
            1, 3, 6, 7);
        $button->signal_connect('clicked' => sub {

            if (defined $switchString) {

                $self->session->pseudoCmd('chatset -a' . $switchString, $self->pseudoCmdMode);
            }
        });

        my $button2 = $self->addButton($table,
            'Forbid snooping ', 'Forbid the selected contacts from snooping you', undef,
            3, 6, 6, 7);
        $button2->signal_connect('clicked' => sub {

            if (defined $switchString) {

                $self->session->pseudoCmd('chatset -f' . $switchString, $self->pseudoCmdMode);
            }
        });

        my $button3 = $self->addButton($table,
            'Mark public', 'Mark the selected chat sessions as \'public\'', undef,
            1, 3, 7, 8);
        $button3->signal_connect('clicked' => sub {

            if (defined $switchString) {

                $self->session->pseudoCmd('chatset -p' . $switchString, $self->pseudoCmdMode);
            }
        });
        my $button4 = $self->addButton($table,
            'Mark private ', 'Mark the selected chat sessions as \'private\'', undef,
            3, 6, 7, 8);
        $button4->signal_connect('clicked' => sub {

            if (defined $switchString) {

                $self->session->pseudoCmd('chatset -v' . $switchString, $self->pseudoCmdMode);
            }
        });

        my $button5 = $self->addButton($table,
            'Mark serving', 'Mark the selected chat sessions as \'serving\'', undef,
            1, 3, 8, 9);
        $button5->signal_connect('clicked' => sub {

            if (defined $switchString) {

                $self->session->pseudoCmd('chatset -s' . $switchString, $self->pseudoCmdMode);
            }
        });
        my $button6 = $self->addButton($table,
            'Mark not serving ', 'Mark the selected chat sessions as \'not serving\'', undef,
            3, 6, 8, 9);
        $button6->signal_connect('clicked' => sub {

            if (defined $switchString) {

                $self->session->pseudoCmd('chatset -z' . $switchString, $self->pseudoCmdMode);
            }
        });

        # Right column
        my $entry3 = $self->addEntryWithIcon($table, undef, 'string', 1, undef,
            7, 13, 1, 2);

        my $button7 = $self->addButton($table, 'Chat', 'Chat to the selected contacts', undef,
            7, 10, 2, 3);
        $button7->signal_connect('clicked' => sub {

            if ($radioButton->get_active()) {

                # ;chatall <text>
                $self->session->pseudoCmd('chatall ' . $entry3->get_text(), $self->pseudoCmdMode);

            } elsif ($self->checkEntryIcon($entry)) {

                # ;chatgroup <group> <text>
                $self->session->pseudoCmd(
                    'chatgroup ' . $entry->get_text() . ' ' . $entry3->get_text(),
                     $self->pseudoCmdMode,
                );

            } elsif ($self->checkEntryIcon($entry2)) {

                # ;chat <name> <text>
                $self->session->pseudoCmd(
                    'chat ' . $entry2->get_text() . ' ' . $entry3->get_text(),
                     $self->pseudoCmdMode,
                );
            }
        });
        my $button8 = $self->addButton($table, 'Emote', 'Emote to the selected contacts', undef,
            10, 13, 2, 3);
        $button8->signal_connect('clicked' => sub {

            if ($radioButton->get_active()) {

                # ;emoteall <text>
                $self->session->pseudoCmd('emoteall ' . $entry3->get_text(), $self->pseudoCmdMode);

            } elsif ($self->checkEntryIcon($entry)) {

                # ;emotegroup <group> <text>
                $self->session->pseudoCmd(
                    'emotegroup ' . $entry->get_text() . ' ' . $entry3->get_text(),
                     $self->pseudoCmdMode,
                );

            } elsif ($self->checkEntryIcon($entry2)) {

                # ;emote <name> <text>
                $self->session->pseudoCmd(
                    'emote ' . $entry2->get_text() . ' ' . $entry3->get_text(),
                     $self->pseudoCmdMode,
                );
            }
        });

        my $button9 = $self->addButton($table, 'Ping', 'Ping the selected contacts', undef,
            7, 10, 3, 4);
        $button9->signal_connect('clicked' => sub {

            if (defined $switchString) {

                $self->session->pseudoCmd('chatping' . $switchString, $self->pseudoCmdMode);
            }
        });
        my $button10 = $self->addButton($table,
            'DND', 'Send \'Do not disturb\' message to selected contacts (MM only)', undef,
            10, 13, 3, 4);
        $button10->signal_connect('clicked' => sub {

            if (defined $switchString) {

                $self->session->pseudoCmd('chatdnd' . $switchString, $self->pseudoCmdMode);
            }
        });

        my $button11 = $self->addButton($table,
            'Submit', 'Allow the selected contacts to send you remote commands', undef,
            7, 9, 4, 5);
        $button11->signal_connect('clicked' => sub {

            if (defined $switchString) {

                $self->session->pseudoCmd('chatsubmit' . $switchString, $self->pseudoCmdMode);
            }
        });
        my $button12 = $self->addButton($table,
            'Escape', 'Forbid the selected contacts from sending you remote commands', undef,
            9, 11, 4, 5);
        $button12->signal_connect('clicked' => sub {

            if (defined $switchString) {

                $self->session->pseudoCmd('chatescape' . $switchString, $self->pseudoCmdMode);
            }
        });
        my $button13 = $self->addButton($table,
            'Send cmd', 'Send a command to the selected contacts', undef,
            11, 13, 4, 5);
        $button13->signal_connect('clicked' => sub {

            if (defined $switchString) {

                # ;chatcmd <switches> <text>
                $self->session->pseudoCmd(
                    'chatcommand' . $switchString . ' ' . $entry3->get_text(),
                     $self->pseudoCmdMode,
                );
            }
        });

        my $button14 = $self->addButton($table,
            'Send file', 'Sends a file to the selected contacts', undef,
            7, 10, 5, 6);
        $button14->signal_connect('clicked' => sub {

            if (defined $switchString) {

                if ($self->checkEntryIcon($entry3)) {

                    # ;chatsendfile <switches> <file>
                    $self->session->pseudoCmd(
                        'chatsendfile' . $switchString . ' ' . $entry3->get_text(),
                        $self->pseudoCmdMode,
                    );

                } else {

                    # ;chatsendfile <switches>
                    $self->session->pseudoCmd('chatsendfile' . $switchString, $self->pseudoCmdMode);
                }
            }
        });
        my $button15 = $self->addButton($table,
            'Stop file',
            'Cancels any files transfers in progress with the selected contacts',
            undef,
            10, 13, 5, 6);
        $button15->signal_connect('clicked' => sub {

            if (defined $switchString) {

                $self->session->pseudoCmd('chatstopfile' . $switchString, $self->pseudoCmdMode);
            }
        });

        my $button16 = $self->addButton($table,
            'Snoop', 'Requests to snoop on the selected contacts', undef,
            7, 10, 6, 7);
        $button16->signal_connect('clicked' => sub {

            if (defined $switchString) {

                $self->session->pseudoCmd('chatsnoop' . $switchString, $self->pseudoCmdMode);
            }
        });
        my $button17 = $self->addButton($table,
            'Hang up', 'Hang up on the selected contacts', undef,
            10, 13, 6, 7);
        $button17->signal_connect('clicked' => sub {

            if (defined $switchString) {

                $self->session->pseudoCmd('chathangup' . $switchString, $self->pseudoCmdMode);
            }
        });

        my $button18 = $self->addButton($table,
            'Peek', 'Ask for a list of the selected contacts\' own chat connections', undef,
            7, 10, 7, 8);
        $button18->signal_connect('clicked' => sub {

            if (defined $switchString) {

                $self->session->pseudoCmd('chatpeek' . $switchString, $self->pseudoCmdMode);
            }
        });
        my $button19 = $self->addButton($table,
            'Request', 'Connect to all of the selected contacts\' own chat connections', undef,
            10, 13, 7, 8);
        $button19->signal_connect('clicked' => sub {

            if (defined $switchString) {

                $self->session->pseudoCmd('chatrequest' . $switchString, $self->pseudoCmdMode);
            }
        });

        my $button20 = $self->addButton($table,
            'Set encoding', 'Set the encoding used in the selected chat sessions', undef,
            7, 10, 8, 9);
        $button20->signal_connect('clicked' => sub {

            if (defined $switchString) {

                # ;chatset -e <encoding> <switches>
                $self->session->pseudoCmd(
                    'chatset -e ' . $entry3->get_text() . $switchString,
                     $self->pseudoCmdMode,
                );
            }

        });
        my $button21 = $self->addButton($table,
            'Default encoding ', 'Use default encoding in the selected chat sessions', undef,
            10, 13, 8, 9);
        $button21->signal_connect('clicked' => sub {

            if (defined $switchString) {

                # ;chatset -e <switches>
                $self->session->pseudoCmd(
                    'chatset -e' . $switchString,
                     $self->pseudoCmdMode,
                );
            }
        });

        # List of all buttons which are sensitised, or not, depending on the radio buttons and entry
        #   boxes
        @buttonList = (
            $button, $button2, $button3, $button4, $button5, $button6, $button7, $button8, $button9,
            $button10, $button11, $button12, $button13, $button14, $button15, $button16, $button17,
            $button18, $button19, $button20, $button21,
        );

        # List of buttons which only be sensitised when there is acceptable text in $entry3
        @textButtonList = (
            $button7, $button8, $button13, $button20,
        );

        # List of buttons which are not in @textButtonList
        @noTextButtonList = (
            $button, $button2, $button3, $button4, $button5, $button6, $button9, $button10,
            $button11, $button12, $button14, $button15, $button16, $button17, $button18, $button19,
            $button21,
        );

        # Some buttons start desensitised
        $self->desensitiseWidgets(@textButtonList);

        # Entry/radio button signal_connects
        $radioButton->signal_connect('toggled' => sub {

            $radioChoice = 0;
            $switchString = '';         # Apply to all sessions - no switch needed

            $entry->set_sensitive(FALSE);
            $entry->set_text('');
            $entry2->set_sensitive(FALSE);
            $entry2->set_text('');

            $self->sensitiseWidgets(@noTextButtonList);
            if ($self->checkEntryIcon($entry3)) {
                $self->sensitiseWidgets(@textButtonList);
            } else {
                $self->desensitiseWidgets(@textButtonList);
            }
        });

        $radioButton2->signal_connect('toggled' => sub {

            $radioChoice = 1;
            $switchString = '';         # $switchString set below

            $entry->set_sensitive(TRUE);
            $entry->set_text('');
            $entry2->set_sensitive(FALSE);
            $entry2->set_text('');
            $self->desensitiseWidgets(@buttonList);
        });

        $radioButton3->signal_connect('toggled' => sub {

            $radioChoice = 2;
            $switchString = '';         # $switchString set below

            $entry->set_sensitive(FALSE);
            $entry->set_text('');
            $entry2->set_sensitive(TRUE);
            $entry2->set_text('');
            $self->desensitiseWidgets(@buttonList);
        });

        $entry->signal_connect('changed' => sub {

            if ($self->checkEntryIcon($entry)) {

                # e.g. '-g mygroup'
                $switchString = ' -g ' . $entry->get_text();

                $self->sensitiseWidgets(@noTextButtonList);
                if ($self->checkEntryIcon($entry3)) {
                    $self->sensitiseWidgets(@textButtonList);
                } else {
                    $self->desensitiseWidgets(@textButtonList);
                }

            } else {

                # No buttons can be used
                $switchString = undef;
                $self->desensitiseWidgets(@buttonList);
            }
        });
        $entry2->signal_connect('changed' => sub {

            if ($self->checkEntryIcon($entry2)) {

                # e.g. '-n myname'
                $switchString = ' -n ' . $entry2->get_text();

                $self->sensitiseWidgets(@noTextButtonList);
                if ($self->checkEntryIcon($entry3)) {
                    $self->sensitiseWidgets(@textButtonList);
                } else {
                    $self->desensitiseWidgets(@textButtonList);
                }

            } else {

                # No buttons can be used
                $switchString = undef;
                $self->desensitiseWidgets(@buttonList);
            }
        });
        $entry3->signal_connect('changed' => sub {

            if ($self->checkEntryIcon($entry3)) {

                if (
                    $self->checkEntryIcon($entry)
                    || $self->checkEntryIcon($entry2)
                    || $radioButton->get_active()
                ) {
                    $self->sensitiseWidgets(@buttonList);

                } else {

                    $self->sensitiseWidgets(@noTextButtonList);
                    $self->desensitiseWidgets(@textButtonList);
                }

            } else {

                if (
                    $self->checkEntryIcon($entry)
                    || $self->checkEntryIcon($entry2)
                    || $radioButton->get_active()
                ) {
                    $self->sensitiseWidgets(@noTextButtonList);
                    $self->desensitiseWidgets(@textButtonList);

                } else {

                    $self->desensitiseWidgets(@buttonList);
                }
            }
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub chat3Tab {

        # Chat3 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (
            $scriptDir, $posn, $count, $shortPath,
            @fileList, @taskList,
        );

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->chat3Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _3', $innerNotebook);

        # Chat options
        $self->addLabel($table, '<b>Chat options</b>',
            0, 12, 0, 1);

        # Left column
        $self->addLabel($table, '<i>Choose an icon for all your chat sessions</i>',
            1, 6, 1, 2);

        # Get a list of .bmp files in /icons/chat
        $scriptDir = $axmud::SHARE_DIR;
        if ($^O eq 'MSWin32') {
            @fileList = glob($scriptDir . '\\icons\\chat\\*.bmp');
        } else {
            @fileList = glob($scriptDir . '/icons/chat/*.bmp');
        }

        # Move the default chat icon to the top of the list (not sure if different code for MSWin is
        #   actually necessary, but let's keep items in @fileList consistent)
        if ($^O eq 'MSWin32') {
            unshift (@fileList, $scriptDir . '\\' . $axmud::CLIENT->constChatIcon);
        } else {
            unshift (@fileList, $scriptDir . '/' . $axmud::CLIENT->constChatIcon);
        }

        # Find the position of the current chat icon in the list
        $count = -1;
        OUTER: foreach my $file (@fileList) {

            $count++;
            if ($file eq $axmud::CLIENT->chatIcon) {

                $posn = $count;
                last OUTER;
            }
        }

        # If the .bmp file used for the current icon no longer exists, use the default chat icon
        #   instead
        if (! defined $posn) {

            $posn = 0;
            $axmud::CLIENT->set_chatIcon($scriptDir . '/' . $axmud::CLIENT->constChatIcon);
        }

        # Add a frame, containing one of the chat icons
        my ($image, $frame, $viewPort) = $self->addImage($table, $fileList[$posn], undef,
            FALSE,          # Don't use a scrolled window
            128, 128,
            1, 4, 2, 6);

        # Add an entry beneath the frame to display the current icon shown
        my $entry = $self->addEntry($table, undef, FALSE,
                1, 6, 6, 7);
        $shortPath = $fileList[$posn];
        if ($shortPath) {

            # Repair MSWin paths, so $scriptDir can be used in a substitution
            $scriptDir =~ s/\\/\\\\/g;
            # Do the substitution
            $shortPath =~ s/$scriptDir//;

            $entry->set_text($shortPath);
        }

        # Add two buttons to cycle through images
        my $button = $self->addButton($table, '<<', 'Switch to previous image', undef,
            4, 5, 2, 3);
        $button->signal_connect('clicked' => sub {

            my $newImage;

            $posn--;
            if ($posn < 0) {

                $posn = (scalar @fileList) - 1;
            }

            # Change the displayed image
            $newImage = $self->changeImage($viewPort, $frame, $image, $fileList[$posn]);
            if ($newImage) {

                $shortPath = $fileList[$posn];
                $shortPath =~ s/$scriptDir//;
                $entry->set_text($shortPath);
                $image = $newImage;
            }
        });

        my $button2 = $self->addButton($table, '>>', 'Switch to next image', undef,
            5, 6, 2, 3);
        $button2->signal_connect('clicked' => sub {

            my $newImage;

            $posn++;
            if ($posn >= scalar @fileList) {

                $posn = 0;
            }

            # Change the displayed image, and store it as the current chat icon
            $newImage = $self->changeImage($viewPort, $frame, $image, $fileList[$posn]);
            if ($newImage) {

                $shortPath = $fileList[$posn];
                $shortPath =~ s/$scriptDir//;
                $entry->set_text($shortPath);
                $image = $newImage;
            }
        });

        my $button3 = $self->addButton($table,
            'Choose file...', 'Select a .bmp file to use as the chat icon', undef,
            4, 6, 3, 4);
        $button3->signal_connect('clicked' => sub {

            my ($newFile, $count, $newImage);

            $newFile = $self->showFileChooser(
                'Select an icon file (must be .bmp)',
                'open',
            );

            if ($newFile) {

                # Check it's a .bmp file
                if (substr($newFile, -4) ne '.bmp') {

                    return $self->showMsgDialogue(
                        'Choose chat icon',
                        'warning',
                        'Only Windows bitmap (.bmp) files can be used as chat icons',
                        'ok',
                    );
                }

                # Insert this file into the list of files just after the current position
                $posn++;
                if ($posn >= scalar @fileList) {

                    $posn = 0;
                }

                splice(@fileList, $posn, 0, $newFile);

                # Change the displayed image, and store it as the current chat icon
                $newImage = $self->changeImage($viewPort, $frame, $image, $newFile);
                if ($newImage) {

                    $shortPath = $fileList[$posn];
                    $shortPath =~ s/$scriptDir//;
                    $entry->set_text($shortPath);
                    $image = $newImage;
                }

                # If this file exists somewhere else in the list, remove the duplicate
                $count = -1;
                OUTER: foreach my $item (@fileList) {

                    $count++;
                    if ($count != $posn && $item eq $newFile) {

                        splice(@fileList, $count, 1);
                        last OUTER;

                        if ($count < $posn) {

                            # The duplicate came before $posn; since the duplicate has been
                            #   removed, $posn shifts one to the left
                            $posn--;
                        }
                    }
                }
            }
        });

        my $button4 = $self->addButton($table, 'Use random', 'Choose a random icon', undef,
            4, 6, 4, 5);
        $button4->signal_connect('clicked' => sub {

            my $newImage;

            $posn = int(rand(scalar @fileList));

            # Change the displayed image, and store it as the current chat icon
            $newImage = $self->changeImage($viewPort, $frame, $image, $fileList[$posn]);
            if ($newImage) {

                $shortPath = $fileList[$posn];
                $shortPath =~ s/$scriptDir//;
                $entry->set_text($shortPath);
                $image = $newImage;
            }
        });

        my $button5 = $self->addButton($table, 'Use default', 'Use the default icon', undef,
            4, 6, 5, 6);
        $button5->signal_connect('clicked' => sub {

            my $newImage;

            # It's the first icon in the list
            $posn = 0;

            # Change the displayed image
            $newImage = $self->changeImage($viewPort, $frame, $image, $fileList[$posn]);
            if ($newImage) {

                $shortPath = $fileList[$posn];
                $shortPath =~ s/$scriptDir//;
                $entry->set_text($shortPath);
                $image = $newImage;
            }
        });

        # Right column
        $self->addLabel($table, '<i>Choose a chat name (or leave empty)</i>',
            7, 12, 1, 2);

        my $entry2 = $self->addEntryWithIcon($table, undef, 'string', 3, 16,
            7, 12, 2, 3);
        my $entry3 = $self->addEntry($table, undef, FALSE,
            7, 12, 3, 4);
        if ($axmud::CLIENT->chatName) {
            $entry3->set_text($axmud::CLIENT->chatName);
        } elsif ($self->session->currentChar) {
            $entry3->set_text($self->session->currentChar->name);
        }

        $self->addLabel($table, '<i>Choose an email address to broadcast (or leave empty)</i>',
            7, 12, 4, 5);

        my $entry4 = $self->addEntryWithIcon($table, undef, 'string', 3, 128,
            7, 12, 5, 6);
        my $entry5 = $self->addEntry($table, undef, FALSE,
            7, 12, 6, 7);
        if ($axmud::CLIENT->chatEmail) {

            $entry5->set_text($axmud::CLIENT->chatEmail);
        }

        my $button6 = $self->addButton(
            $table,
            'Apply these changes now',
            'Store the icon, chat name and email and inform any running Chat tasks',
            undef,
            1, 12, 7, 8);
        $button6->signal_connect('clicked' => sub {

            my ($name, $email);

            # Update the icon
            if ($fileList[$posn] ne $axmud::CLIENT->chatIcon) {

                $self->session->pseudoCmd(
                    'chatseticon ' . $fileList[$posn],
                    $self->pseudoCmdMode,
                );
            }

            # Update the chat name
            if ($self->checkEntryIcon($entry2)) {

                $name = $entry2->get_text();
                $self->session->pseudoCmd('chatsetname ' . $name, $self->pseudoCmdMode);

            } else {

                # Use the current character's name
                $self->session->pseudoCmd('chatsetname', $self->pseudoCmdMode);
            }

            # Update the chat email
            if ($self->checkEntryIcon($entry4)) {

                $email = $entry4->get_text();
                $self->session->pseudoCmd(
                    'chatsetemail ' . $email,
                    $self->pseudoCmdMode,
                );

            } else {

                # Don't use an email
                $self->session->pseudoCmd('chatsetemail', $self->pseudoCmdMode);
            }

            # Update the two insensitive entry boxes
            if ($axmud::CLIENT->chatName) {
                $entry3->set_text($axmud::CLIENT->chatName);
            } elsif ($self->session->currentChar) {
                $entry3->set_text($self->session->currentChar->name);
            }

            if ($axmud::CLIENT->chatEmail) {

                $entry5->set_text($axmud::CLIENT->chatEmail);
            }
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub chat4Tab {

        # Chat4 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->chat4Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _4', $innerNotebook);

        # Chat task actions
        $self->addLabel($table, '<b>Chat contact list</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>List of stored chat contacts available to the Chat task</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            '', 'pixbuf',       # GA::Obj::ChatContact->lastIconScaled
            'Name', 'text',
            'Protocol', 'text',
            'IP', 'text',
            'Port', 'text',
            'Email', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 8,
            -1, 200);       # Fixed height

        # Initialise the list
        $self->chat4Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add entry boxes for new chat contacts
        $self->addLabel($table, 'Name',
            1, 3, 8, 9);
        my $entry = $self->addEntryWithIcon($table, undef, 'string', 1, 16,
            3, 6, 8, 9);
        $self->addLabel($table, 'IP address',
            7, 9, 8, 9);
        my $entry2 = $self->addEntryWithIcon($table, undef, 'string', 1, undef,
            9, 12, 8, 9);
        $self->addLabel($table, 'Port',
            1, 3, 9, 10);
        my $entry3 = $self->addEntryWithIcon($table, undef, 'int', 0, 65535,
            3, 6, 9, 10);
        $entry3->set_text($axmud::CLIENT->constChatPort);

        # Add editing buttons
        my $button = $self->addButton($table, 'Add', 'Add the chat contact', undef,
            7, 9, 9, 10);
        $button->signal_connect('clicked' => sub {

            my ($name, $ip, $port);

            if ($self->checkEntryIcon($entry, $entry2, $entry3)) {

                $name = $entry->get_text();
                $ip = $entry2->get_text();
                $port = $entry3->get_text();

                # Create a new GA::Obj::ChatContact, using the zChat protocol as the default
                $self->session->pseudoCmd(
                    'addcontact ' . $name . ' ' . $ip . ' ' . $port,
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list and entry boxes
                $self->chat4Tab_refreshList($slWidget, scalar (@columnList / 2));
                $self->resetEntryBoxes($entry, $entry2);
                $entry3->set_text($axmud::CLIENT->constChatPort);
            }
        });

        my $button2 = $self->addButton($table, 'Edit...', 'Edit the selected chat contact', undef,
            9, 10, 9, 10);
        $button2->signal_connect('clicked' => sub {

            my ($name, $contactObj, $childWinObj);

            ($name) = $self->getSimpleListData($slWidget, 1);
            if (defined $name) {

                # Get the blessed reference
                $contactObj = $axmud::CLIENT->ivShow('chatContactHash', $name);
                if ($contactObj) {

                    # Open up an 'edit' window to edit the GA::Obj::ChatContact
                    $self->createFreeWin(
                        'Games::Axmud::EditWin::ChatContact',
                        $self,
                        $self->session,
                        'Edit chat contact \'' . $name . '\'',
                        $contactObj,
                        FALSE,                  # Not temporary
                    );
                }

                if ($childWinObj) {

                    # When the 'edit' window closes, update widgets and/or IVs
                    $self->add_childDestroy(
                        $childWinObj,
                        'chat4Tab_refreshList',
                        [$slWidget, (scalar @columnList / 2)],
                    );
                }
            }
        });

        my $button3 = $self->addButton($table, 'Delete', 'Delete the selected chat contact', undef,
            10, 12, 9, 10);
        $button3->signal_connect('clicked' => sub {

            my ($name) = $self->getSimpleListData($slWidget, 1);
            if (defined $name) {

                # Delete the contact
                $self->session->pseudoCmd('deletecontact ' . $name, $self->pseudoCmdMode);

                # Refresh the simple list
                $self->chat4Tab_refreshList($slWidget, scalar (@columnList / 2));
            }
        });

        my $button4 = $self->addButton($table, 'Call...', 'Call the selected chat contact', undef,
            7, 9, 10, 11);
        $button4->signal_connect('clicked' => sub {

            my ($name) = $self->getSimpleListData($slWidget, 1);
            if (defined $name) {

                # Call the contact
                $self->session->pseudoCmd('chatcall ' . $name, $self->pseudoCmdMode);

                # Refresh the simple list
                $self->chat4Tab_refreshList($slWidget, scalar (@columnList / 2));
            }
        });

        my $button5 = $self->addButton(
            $table, 'Refresh list', 'Refresh the list of chat contacts', undef,
            9, 12, 10, 11);
        $button5->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->chat4Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub chat4Tab_refreshList {

        # Called by $self->chat4Tab to refresh the Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::List
        #   $columns    - The number of columns in the list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (@objList, @dataList);

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->chat4Tab_refreshList', @_);
        }

        # Get a sorted list of GA::Obj::ChatContact objects
        @objList
            = sort {lc($a->name) cmp lc($b->name)} ($axmud::CLIENT->ivValues('chatContactHash'));

        # Compile the simple list data
        foreach my $obj (@objList) {

            my $protocol;

            if ($obj->protocol == 0) {
                $protocol = 'MM';
            } else {
                $protocol = 'zChat';
            }

            push (@dataList,
                $obj->lastIconScaled,
                $obj->name,
                $protocol,
                $obj->ip,
                $obj->port,
                $obj->email,
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub chat5Tab {

        # Chat5 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->chat5Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _5', $innerNotebook);

        # Chat task actions
        $self->addLabel($table, '<b>Current chat connections</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $table, '<i>List of current connections to chat contacts (in all sessions)</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Session', 'int',
            '', 'pixbuf',           # GA::Obj::ChatContact->lastIconScaled
            'Name', 'text',
            'Contact', 'text',
            'Protocol', 'text',
            'IP', 'text',
            'Port', 'text',
            'Group', 'text',
            'Can snoop', 'bool',
            'Is snooping', 'bool',
            'Public', 'bool',
            'Serving', 'bool',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 8,
            -1, 270);       # Fixed height

        # Initialise the list
        $self->chat5Tab_refreshList($slWidget, scalar (@columnList / 2));

        # Add editing buttons
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of connections', undef,
            9, 12, 8, 9);
        $button->signal_connect('clicked' => sub {

            # Refresh the list
            $self->chat5Tab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub chat5Tab_refreshList {

        # Called by $self->chat5Tab to refresh the Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::List
        #   $columns    - The number of columns in the list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (@taskList, @dataList);

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->chat5Tab_refreshList', @_);
        }

        # Get a list of chat tasks running in every GA::Session
        foreach my $session ($axmud::CLIENT->listSessions()) {

            my @list;

            # If this session has a lead chat task...
            if ($session->chatTask) {

                # Add all chat tasks for this session
                @list = sort {
                            if ($a->remoteName && $b->remoteName) {
                                lc($a->remoteName) cmp lc($b->remoteName);
                            } else {
                                lc($a) cmp lc($b);
                            }
                        } ($session->chatTask->findAllTasks());

                if (@list) {

                    push (@taskList, @list);
                }
            }
        }

        # Compile the simple list data
        foreach my $taskObj (@taskList) {

            my ($protocol, $contact, $icon);

            # Only display Chat tasks connected to someone
            if ($taskObj->sessionFlag) {

                if ($taskObj->chatType == 0) {
                    $protocol = 'MM';
                } else {
                    $protocol = 'zChat';
                }

                if ($taskObj->chatContactObj) {

                    $icon = $taskObj->chatContactObj->lastIconScaled;
                    $contact = $taskObj->chatContactObj->name;

                } else {

                    $icon = $taskObj->remoteIconScaled;
                }

                push (@dataList,
                    $taskObj->session->number,
                    $icon,
                    $taskObj->remoteName,
                    $contact,
                    $protocol,
                    $taskObj->remoteIP,
                    $taskObj->remotePort,
                    $taskObj->localGroup,
                    $taskObj->allowSnoopFlag,
                    $taskObj->isSnoopedFlag,
                    $taskObj->publicConnectionFlag,
                    $taskObj->servingFlag,
                );
            }
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::PrefWin::Path;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::EditWin Games::Axmud::Generic::ConfigWin
        Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win Games::Axmud
    );

    ##################
    # Constructors

    # Contents of $self->editConfigHash after $self->new has been called:
    #   'room_list'     => A list of GA::ModelObj::Room objects along the path
    #   'exit_list'     => A list of GA::Obj::Exit objects linking the rooms on the path
    #   'cmd_list'      => A list of commands used to move along the path
    #   'reverse_list'  => A list of commands used to move along the path in the reverse direction
    #                       (an empty list, if unknown)

    sub new {

        # Called by GA::Generic::Win->createFreeWin
        # Creates a new instance of a 'config' window (any 'free' window object inheriting from this
        #   object, namely 'edit' windows and 'pref' windows)
        #
        # Expected arguments
        #   $number         - Unique number for this window object
        #   $workspaceObj   - The GA::Obj::Workspace handling the workspace in which this window
        #                       should be created
        #   $owner          - The owner; a 'grid' window object (but not an 'external' window) or a
        #                       'free' window object. When this window opens/closes, the owner is
        #                       informed via calls to its ->add_childFreeWin / ->del_childFreeWin
        #                       functions
        #
        # Optional arguments
        #   $session        - The GA::Session from which this function was called. 'undef' if the
        #                       calling function didn't specify a session and $owner's ->session IV
        #                       is also 'undef'
        #   $title          - A string to use as the window title. If 'undef', a generic title is
        #                       used
        #   $editObj        - The object to be edited in the window (for 'edit' windows only;
        #                       should be 'undef' for 'pref' windows)
        #   $tempFlag       - Flag set to TRUE if $editObj is either temporary, or has not yet been
        #                       added to any registry (usually because the user needs to name it
        #                       first). Set to FALSE (or 'undef') otherwise. Ignored if $editObj is
        #                       not specified
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'config' window; for example, for example,
        #                       GA::PrefWin::TaskStart uses it to specify a task name and type.
        #                       Set to an empty hash if not required
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $workspaceObj, $owner, $session, $title, $editObj, $tempFlag,
            %configHash,
        ) = @_;

        # Local variables
        my ($winType, $winName);

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $workspaceObj || ! defined $owner) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Set the values to use for some standard window IVs
        if ($editObj) {

            $winType = 'edit';
            $winName = 'edit';
            if (! defined $title) {

                $title = 'Edit window';
            }

        } else {

            $winType = 'pref';
            $winName = 'pref';
            if (! defined $title) {

                $title = 'Preference window';
            }
        }

        # Setup
        my $self = {
            _objName                    => $winType . '_win_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard window object IVs
            # --------------------------

            # Unique number for this window object
            number                      => $number,
            # The window category - 'grid' or 'free'
            winCategory                 => 'free',
            # The window type, any of the keys in GA::Client->constFreeWinTypeHash
            winType                     => $winType,
            # A name for the window (for 'config' windows, the same as the window type)
            winName                     => $winName,
            # The GA::Obj::Workspace object for the workspace in which this window is created
            workspaceObj                => $workspaceObj,
            # The owner; a 'grid' window object (but not an 'external' window) or a 'free' window
            #   object. When this window opens/closes, the owner is informed via calls to its
            #   ->add_childFreeWin / ->del_childFreeWin functions
            owner                       => $owner,
            # The GA::Session from which this function was called. 'undef' if the calling function
            #   didn't specify a session and $owner's ->session IV is also 'undef'
            session                     => $session,
             # When GA::Session->pseudoCmd is called to execute a client command, the mode in which
            #   it should be called (usually 'win_error' or 'win_only', which causes errors to be
            #   displayed in a 'dialogue' window)
            pseudoCmdMode               => 'win_error',

            # The window widget. For most window objects, the Gtk2::Window. For pseudo-windows, the
            #   parent 'main' window's Gtk2::Window
            # The code should use this IV when it wants to do something to the window itself
            #   (minimise it, make it active, etc)
            winWidget                   => undef,
            # The window container. For most window objects, the Gtk2::Window. For pseudo-windows,
            #   the parent GA::Table::PseudoWin table object
            # The code should use this IV when it wants to add, modify or remove widgets inside the
            #   window itself
            winBox                      => undef,
            # The Gnome2::Wnck::Window, if known
            wnckWin                     => undef,
            # Flag set to TRUE if the window actually exists (after a call to $self->winEnable),
            #   FALSE if not
            enabledFlag                 => FALSE,
            # Flag set to TRUE if the Gtk2 window itself is visible (after a call to
            #   $self->setVisible), FALSE if it is not visible (after a call to $self->setInvisible)
            visibleFlag                 => TRUE,
            # Registry hash of 'free' windows (excluding 'dialogue' windows) for which this window
            #   is the parent, a subset of GA::Obj::Desktop->freeWinHash. Hash in the form
            #       $childFreeWinHash{unique_number} = blessed_reference_to_window_object
            childFreeWinHash            => {},
            # When a child 'free' window (excluding 'dialogue' windows) is destroyed, this parent
            #   window is informed via a call to $self->del_childFreeWin
            # When the child is destroyed, this window might want to call some of its own functions
            #   to update various widgets and/or IVs, in which case this window adds an entry to
            #   this hash; a hash in the form
            #       $childDestroyHash{unique_number} = list_reference
            # ...where 'unique_number' is the child window's ->number, and 'list_reference' is a
            #   reference to a list in groups of 2, in the form
            #       (sub_name, argument_list_ref, sub_name, argument_list_ref...)
            childDestroyHash            => {},

            # The container widget into which all other widgets are packed (usually a Gtk2::VBox or
            #   Gtk2::HBox, but any container widget can be used; takes up the whole window client
            #   area)
            packingBox                  => undef,       # Gtk2::VBox

            # Standard IVs for 'free' windows

            # The window's default size, in pixels
            widthPixels                 => $axmud::CLIENT->constFreeWinWidth,
            heightPixels                => $axmud::CLIENT->constFreeWinHeight,
            # Default border/item spacing sizes used in the window, in pixels
            borderPixels                => $axmud::CLIENT->constFreeBorderPixels,
            spacingPixels               => $axmud::CLIENT->constFreeSpacingPixels,

            # A string to use as the window title. If 'undef', a generic title is used
            title                       => $title,
            # Hash containing any number of key-value pairs needed for this particular 'config'
            #   window; for example, for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            configHash                  => {%configHash},

            # Standard IVs for 'config' windows

            # Widgets
            notebook                    => undef,       # Gtk2::Notebook
            hBox                        => undef,       # Gtk2::HBox
            tooltips                    => undef,       # Gtk2::Tooltips
            okButton                    => undef,       # Gtk2::Button
            cancelButton                => undef,       # Gtk2::Button
            resetButton                 => undef,       # Gtk2::Button
            saveButton                  => undef,       # Gtk2::Button

            # The standard table size for the notebook (any 'edit'/'pref' window can use a different
            #   size, if it wants)
            tableSize                   => 12,

            # The object to be edited in the window (for 'edit' windows only; should be 'undef' for
            #   'pref' windows)
            editObj                     => $editObj,
            # Flag set to TRUE if $editObj is either temporary, or has not yet been added to any
            #   registry (usually because the user needs to name it first). Set to FALSE
            #   (or 'undef') otherwise. Ignored if $editObj is not specified
            tempFlag                    => $tempFlag,
            # Flag that can be set to TRUE (usually by $self->setupNotebook or ->expandNotebook) if
            #   $editObj is a current object (e.g. if it is a current profile); set to FALSE at all
            #   other times
            currentFlag                 => FALSE,
            # For 'edit' windows, a hash of IVs in $editObj that should be changed. If no changes
            #   have been made in the 'edit' window, the hash is empty; otherwise the hash contains
            #   the new values for each IV to be modified
            # Hash in the form:
            #   $editHash{iv_name} = scalar;
            #   $editHash{iv_name} = list_reference;
            #   $editHash{iv_name} = hash_reference;
            # For 'pref' windows, a hash of key-value pairs set by the window's widgets;
            #   $self->enableButtons can access this hash to perform any necessary actions
            #   ('pref' windows don't make a call to ->saveChanges)
            editHash                    => {},
            # Hash containing any number of key-value pairs needed for this particular
            #   'edit'/'pref' window; for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            editConfigHash              => \%configHash,

            # IVs for this type of window

            # A list of GA::ModelObj::Room objects along the path
            roomList                    => [],
            # The first room in the list
            initialRoomObj              => undef,
            # The last room in the list
            targetRoomObj               => undef,

            # A list of GA::Obj::Exit objects, linking the room objects on the path
            exitList                    => [],
            # A list of commands (using assisted moves if allowed) to go along the path
            cmdList                     => [],
            reverseCmdList              => [],
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}             # Inherited from GA::Generic::ConfigWin

#   sub winEnable {}            # Inherited from GA::Generic::ConfigWin

#   sub winDesengage {}         # Inherited from GA::Generic::FreeWin

#   sub winDestroy {}           # Inherited from GA::Generic::FreeWin

#   sub winShowAll {}           # Inherited from GA::Generic::Win

#   sub drawWidgets {}          # Inherited from GA::Generic::ConfigWin

#   sub redrawWidgets {}        # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

#   sub checkEditObj {}         # Inherited from GA::Generic::ConfigWin

    sub enableButtons {

        # Called by $self->drawWidgets
        # We only need a single button so, instead of calling the generic ->enableButtons, call a
        #   method that creates just one button
        #
        # Expected arguments
        #   $hBox       - The horizontal packing box in which the buttons live (not yet stored as
        #                   an IV)
        #   $tooltips   - A Gtk2::Tooltips object for the buttons (not yet stored as an IV)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, a list containing the Gtk::Button object created

        my ($self, $hBox, $tooltips, $check) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (! defined $hBox || ! defined $tooltips || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->enableButtons', @_);
            return @emptyList;
        }

        return $self->enableSingleButton($hBox, $tooltips);
    }

#   sub enableSingleButton {}   # Inherited from GA::Generic::ConfigWin

    sub setupNotebook {

        # Called by $self->winEnable
        # Creates the first tab for the notebook. The remaining tabs are created by
        #   $self->expandNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($roomListRef, $exitListRef, $cmdListRef, $reverseListRef) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setupNotebook', @_);
        }

        # Tab setup, using the standard table size
        my ($vBox, $table) = $self->addTab('_Summary', $self->notebook);

        # Extract data from $self->editConfigHash, and use it to set initial values for the
        #   non-standard IVs
        $roomListRef = $self->ivShow('editConfigHash', 'room_list');
        $self->ivPoke('roomList', @$roomListRef);

        $exitListRef = $self->ivShow('editConfigHash', 'exit_list');
        $self->ivPoke('exitList', @$exitListRef);

        $cmdListRef = $self->ivShow('editConfigHash', 'cmd_list');
        $self->ivPoke('cmdList', @$cmdListRef);

        $reverseListRef = $self->ivShow('editConfigHash', 'reverse_list');
        $self->ivPoke('reverseCmdList', @$reverseListRef);

        $self->ivPoke('initialRoomObj', $$roomListRef[0]);
        $self->ivPoke('targetRoomObj', $$roomListRef[-1]);

        # Set up the rest of the tab
        $self->summaryTab($table);

        # Set up the remaining tabs
        $self->expandNotebook();

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub expandNotebook {

        # Called by $self->setupNotebook
        # Set up additional tabs for the notebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->expandNotebook', @_);
        }

        $self->pathTab();
        if ($self->reverseCmdList) {

            $self->reversePathTab();
        }

        return 1;
    }

    sub saveChanges {

        # Called by $self->buttonOK
        # Unlike GA::Generic::EditWin, there is no Perl object in which we have to store IVs. This
        #   function does nothing except to get called by the inherited functions
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->saveChanges', @_);
        }

        # Nothing to do
        return 1;
    }

    # Notebook tabs

    sub summaryTab {

        # Summary tab
        #
        # Expected arguments
        #   $table  - The Gtk2::Table
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $table, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $table || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->summaryTab', @_);
        }

#       # Tab setup (already created by the calling function)
#        my ($vBox, $table) = $self->addTab('_Summary', $self->notebook);

        # Shortest path found
        $self->addLabel(
            $table,
            '<b>Shortest path found in ' . $self->ivNumber('exitList') . ' steps</b>',
            0, 12, 0, 1,
        );

        if ($self->reverseCmdList) {

            $self->addLabel($table, '<i>(Reverse path also found)</i>',
                1, 12, 1, 2);

        } else {

            $self->addLabel($table, '<i>(Reverse path not found)</i>',
                1, 12, 1, 2);
        }

        # Add a simple list
        @columnList = (
            '#', 'text',
            'Region', 'text',
            'Room #', 'text',
            'Room tag', 'text',
            'Exit #', 'text',
            'Nominal dir', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 300);       # Fixed height

        # Initialise the list
        $self->summaryTab_refreshList($slWidget, (scalar @columnList / 2));

        # Add editing buttons
        my $button = $self->addButton(
            $table,
            'Edit room...',
            'Edit the selected room model object',
            undef,
            8, 10, 10, 11,
        );
        $button->signal_connect('clicked' => sub {

            my ($roomNum, $roomObj);

            ($roomNum) = $self->getSimpleListData($slWidget, 2);
            if (defined $roomNum) {

                $roomObj = $self->session->worldModelObj->ivShow('modelHash', $roomNum);

                # Open the room's 'edit' window
                $self->createFreeWin(
                    'Games::Axmud::EditWin::ModelObj::Room',
                    $self,
                    $self->session,
                    'Edit ' . $roomObj->category . ' model object #' . $roomObj->number,
                    $roomObj,
                    FALSE,                          # Not temporary
                );
            }
        });

        my $button2 = $self->addButton(
            $table, 'Edit exit...', 'Edit the selected exit object', undef,
            10, 12, 10, 11);
        $button2->signal_connect('clicked' => sub {

            my ($exitNum, $exitObj);

            ($exitNum) = $self->getSimpleListData($slWidget, 4);
            if (defined $exitNum) {

                $exitObj = $self->session->worldModelObj->ivShow('exitModelHash', $exitNum);

                # Open up an 'edit' window to edit the object
                $self->createFreeWin(
                    'Games::Axmud::EditWin::Exit',
                    $self,
                    $self->session,
                    'Edit exit model object #' . $exitObj->number,
                    $exitObj,
                    FALSE,                          # Not temporary
                );
            }
        });

#        # Tab complete
#        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub summaryTab_refreshList {

        # Called by $self->summaryTab to refresh the Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::List
        #   $columns    - The number of columns in the list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (
            $count,
            @dataList,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->summaryTab_refreshList', @_);
        }

        # Compile the simple list data (these IVs are not saved to $self->editHash)
        $count = -1;
        foreach my $roomObj ($self->roomList) {

            my ($regionObj, $regionName, $exitObj, $exitNum, $dir);

            $count++;

            if ($roomObj->parent) {

                $regionObj = $self->session->worldModelObj->ivShow('modelHash', $roomObj->parent);
                $regionName = $regionObj->name;
            }

            $exitObj = $self->ivIndex('exitList', $count);
            if ($exitObj) {

                # $exitObj is undefined for the last spin of this loop
                $exitNum = $exitObj->number;
                $dir = $exitObj->dir;
            }

            push (@dataList,
                $count + 1,
                $regionName,            # May be 'undef'
                $roomObj->number,
                $roomObj->roomTag,      # May be 'undef'
                $exitNum,               # May be 'undef'
                $dir,                   # May be 'undef'
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub pathTab {

        # Path tab
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->pathTab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('_Path', $self->notebook);

        # Path
        $self->addLabel($table, '<b>Path</b>',
            0, 12, 0, 1);

        $self->pathTab_addWidgets(
            $table,
            $self->initialRoomObj->roomTag,
            $self->targetRoomObj->roomTag,
            $self->cmdList,
        );

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub reversePathTab {

        # ReversePath tab
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reversePathTab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('_Reverse path', $self->notebook);

        # Path
        $self->addLabel($table, '<b>Reverse path</b>',
            0, 12, 0, 1);

        $self->pathTab_addWidgets(
            $table,
            $self->targetRoomObj->roomTag,
            $self->initialRoomObj->roomTag,
            $self->reverseCmdList,
        );

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub pathTab_addWidgets {

        # Called by $self->pathTab and $self->reversePathTab
        # Adds common widgets to both tabs
        #
        # Expected arguments
        #   $table      - The Gtk2::Table in this tab
        #
        # Optional arguments
        #   $roomTag, $otherRoomTag
        #               - The room tags at each end of the path (may not exits)
        #   @cmdList    - A list of commands to move between them (from either $self->cmdList or
        #                   $self->reverseCmdList)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $table, $roomTag, $otherRoomTag, @cmdList) = @_;

        # Local variables
        my (
            $worldString,
            @comboList, @profList,
        );

        # Check for improper arguments
        if (! defined $table) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->pathTab_addWidgets', @_);
        }

        # Add widgets to the table
        $self->addLabel($table, '<i>Combined commands (copy the path from here)</i>',
            1, 6, 1, 2);
        my $textView = $self->addTextView($table, undef, FALSE,
            1, 12, 2, 5,
            FALSE,          # Don't treat as a list
            FALSE,          # Don't remove empty lines
            TRUE,           # ...but do remove leading/trailing whitespace
            FALSE,          # Allow horizontal scrolling
            -1, 100);       # Fixed height
        my $buffer = $textView->get_buffer();
        $buffer->set_text(join($axmud::CLIENT->cmdSep, @cmdList));

        $self->addLabel($table, '<i>Split commands (edit the path here)</i>',
            1, 6, 5, 6);
        my $textView2 = $self->addTextView($table, undef, TRUE,
            1, 6, 6, 12,
            TRUE,           # Treat as a list
            TRUE,           # Remove empty lines
            TRUE,           # Remove leading/trailing whitespace
            FALSE,          # Allow horizontal scrolling
            400, 200);      # Fixed width/height
        my $buffer2 = $textView2->get_buffer();
        $buffer2->set_text(join("\n", @cmdList));

        # Editing the second textview automatically updates the first one
        $buffer2->signal_connect('changed' => sub {

            my (
                $startIter, $endIter, $text,
                @lineList,
            );

            $startIter = $buffer2->get_start_iter();
            $endIter = $buffer2->get_end_iter();
            $text = $buffer2->get_text($startIter, $endIter, 1);

            # Set the other textview's contents to match this one
            @lineList = split("\n", $text);
            $buffer->set_text(join($axmud::CLIENT->cmdSep, @lineList));
        });

        $self->addLabel($table, 'Initial tag',
            7, 9, 6, 7);
        my $entry = $self->addEntryWithIcon($table, undef, 'string', 1, undef,
            9, 12, 6, 7);
        if ($roomTag) {

            $entry->set_text($roomTag);
        }

        $self->addLabel($table, 'Target tag',
            7, 9, 7, 8);
        my $entry2 = $self->addEntryWithIcon($table, undef, 'string', 1, undef,
            9, 12, 7, 8);
        if ($otherRoomTag) {

            $entry2->set_text($otherRoomTag);
        }

        $self->addLabel($table, 'Route type',
            7, 9, 8, 9);
        @comboList = ('road', 'quick'); # Circuit routes can't be created here
        my $combo = $self->addComboBox($table, undef, \@comboList, '',
            TRUE,               # No 'undef' value used
            9, 12, 8, 9);

        $self->addLabel($table, 'Hoppable',
            7, 11, 9, 10);
        my $checkButton = $self->addCheckButton($table, undef, TRUE,
            11, 12, 9, 10, 1, 0.5);
        $checkButton->set_active(TRUE);

        $self->addLabel($table, 'Profile',
            7, 9, 10, 11);
        # Get a list of non-world current profiles
        foreach my $category ($self->session->profPriorityList) {

            my $profObj;

            if ($category ne 'world' && $self->session->ivExists('currentProfHash', $category)) {

                $profObj = $self->session->ivShow('currentProfHash', $category);
                push (@profList, $profObj->name);
            }
        }

        # Default combo option is 'use current world'
        $worldString = '<use current world>';
        push (@profList, $worldString);

        # Reverse the list, so that it is in reverse-priority order (and so that 'use current world'
        #   appears at the top)
        @profList = reverse @profList;

        my $combo2 = $self->addComboBox($table, undef, \@profList, '',
            TRUE,               # No 'undef' value used
            9, 12, 10, 11);

        my $button = $self->addButton(
            $table,
            'Add pre-defined route',
            'Create a pre-defined route using this path',
            undef,
            7, 12, 11, 12,
        );
        $button->set_sensitive(FALSE);  # Button initially desensitised
        $button->signal_connect('clicked' => sub {

            my ($initialTag, $targetTag, $routeType, $flag, $profName, $cmd, $pathText);

            # Only create a route if both entry boxes are full
            if ($self->checkEntryIcon($entry, $entry2)) {

                $initialTag = $entry->get_text();
                $targetTag = $entry2->get_text();
                $routeType = $combo->get_active_text();
                $flag = $checkButton->get_active();
                $profName = $combo2->get_active_text();

                # Use the edited (not necessarily the original) path
                $pathText = $axmud::CLIENT->desktopObj->bufferGetText($buffer);

                # Prepare the client command
                $cmd = 'addroute <' . $initialTag . '> <' . $targetTag . '> <' . $pathText . '>';

                if ($routeType eq 'quick') {
                    $cmd .= ' -q';
                } else {
                    $cmd .= ' -o';      # Road route
                }

                if ($profName ne $worldString) {

                    $cmd .= ' -d ' . $profName;
                }

                if (! $flag) {

                    $cmd .= ' -h';
                }

                # Create the GA::Obj::Route
                $self->session->pseudoCmd($cmd, $self->pseudoCmdMode);
            }
        });

        # The 'Add pre-defined route' button should be desensitised when $entry and $entry2 contain
        #   unacceptable text
        $entry->signal_connect('changed' => sub {

            if ($self->checkEntryIcon($entry, $entry2)) {
                $button->set_sensitive(TRUE);
            } else {
                $button->set_sensitive(FALSE);
            }
        });
        $entry2->signal_connect('changed' => sub {

            if ($self->checkEntryIcon($entry, $entry2)) {
                $button->set_sensitive(TRUE);
            } else {
                $button->set_sensitive(FALSE);
            }
        });

        my $button2 = $self->addButton(
            $table,
            'Abbreviate',
            'Abbreviate the directions displayed in this tab',
            undef,
            7, 10, 1, 2,
        );
        $button2->signal_connect('clicked' => sub {

            my (
                $dictObj, $startIter, $endIter, $text,
                @lineList, @newList,
            );

            # Import the session's current dictionary (for convenience)
            $dictObj = $self->session->currentDict;

            # Get a list of directions from the second textview
            $startIter = $buffer2->get_start_iter();
            $endIter = $buffer2->get_end_iter();
            $text = $buffer2->get_text($startIter, $endIter, 1);

            @lineList = split("\n", $text);

            # Abbreviate each direction, if possible
            foreach my $cmd (@lineList) {

                my $abbrevDir = $dictObj->abbrevDir($cmd);

                if ($abbrevDir) {
                    push (@newList, $abbrevDir);
                } else {
                    push (@newList, $cmd);
                }
            }

            # Update each textview
            $buffer->set_text(join($axmud::CLIENT->cmdSep, @newList));
            $buffer2->set_text(join("\n", @newList));
        });

        my $button3 = $self->addButton(
            $table,
            'Unabbreviate',
            'Unabbreviate the directions displayed in this tab',
            undef,
            10, 12, 1, 2,
        );
        $button3->signal_connect('clicked' => sub {

            my (
                $dictObj, $startIter, $endIter, $text,
                @lineList, @newList,
            );

            # Import the session's current dictionary (for convenience)
            $dictObj = $self->session->currentDict;

            # Get a list of directions from the second textview
            $startIter = $buffer2->get_start_iter();
            $endIter = $buffer2->get_end_iter();
            $text = $buffer2->get_text($startIter, $endIter, 1);

            @lineList = split("\n", $text);

            # Unabbreviate each direction, if possible
            foreach my $cmd (@lineList) {

                push (@newList, $dictObj->unabbrevDir($cmd));
            }

            # Update each textview
            $buffer->set_text(join($axmud::CLIENT->cmdSep, @newList));
            $buffer2->set_text(join("\n", @newList));
        });

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub roomList
        { my $self = shift; return @{$self->{roomList}}; }
    sub initialRoomObj
        { $_[0]->{initialRoomObj} }
    sub targetRoomObj
        { $_[0]->{targetRoomObj} }

    sub exitList
        { my $self = shift; return @{$self->{exitList}}; }
    sub cmdList
        { my $self = shift; return @{$self->{cmdList}}; }
    sub reverseCmdList
        { my $self = shift; return @{$self->{reverseCmdList}}; }
}

{ package Games::Axmud::PrefWin::Search;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::EditWin Games::Axmud::Generic::ConfigWin
        Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win Games::Axmud
    );

    ##################
    # Constructors

    # Contents of $self->editConfigHash after $self->new has been called:
    #   (none)

    sub new {

        # Called by GA::Generic::Win->createFreeWin
        # Creates a new instance of a 'config' window (any 'free' window object inheriting from this
        #   object, namely 'edit' windows and 'pref' windows)
        #
        # Expected arguments
        #   $number         - Unique number for this window object
        #   $workspaceObj   - The GA::Obj::Workspace handling the workspace in which this window
        #                       should be created
        #   $owner          - The owner; a 'grid' window object (but not an 'external' window) or a
        #                       'free' window object. When this window opens/closes, the owner is
        #                       informed via calls to its ->add_childFreeWin / ->del_childFreeWin
        #                       functions
        #
        # Optional arguments
        #   $session        - The GA::Session from which this function was called. 'undef' if the
        #                       calling function didn't specify a session and $owner's ->session IV
        #                       is also 'undef'
        #   $title          - A string to use as the window title. If 'undef', a generic title is
        #                       used
        #   $editObj        - The object to be edited in the window (for 'edit' windows only;
        #                       should be 'undef' for 'pref' windows)
        #   $tempFlag       - Flag set to TRUE if $editObj is either temporary, or has not yet been
        #                       added to any registry (usually because the user needs to name it
        #                       first). Set to FALSE (or 'undef') otherwise. Ignored if $editObj is
        #                       not specified
        #   %configHash     - Hash containing any number of key-value pairs needed for this
        #                       particular 'config' window; for example, for example,
        #                       GA::PrefWin::TaskStart uses it to specify a task name and type. Set
        #                       to an empty hash if not required
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $workspaceObj, $owner, $session, $title, $editObj, $tempFlag,
            %configHash,
        ) = @_;

        # Local variables
        my ($winType, $winName);

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $workspaceObj || ! defined $owner) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Set the values to use for some standard window IVs
        if ($editObj) {

            $winType = 'edit';
            $winName = 'edit';
            if (! defined $title) {

                $title = 'Edit window';
            }

        } else {

            $winType = 'pref';
            $winName = 'pref';
            if (! defined $title) {

                $title = 'Preference window';
            }
        }

        # Setup
        my $self = {
            _objName                    => $winType . '_win_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard window object IVs
            # --------------------------

            # Unique number for this window object
            number                      => $number,
            # The window category - 'grid' or 'free'
            winCategory                 => 'free',
            # The window type, any of the keys in GA::Client->constFreeWinTypeHash
            winType                     => $winType,
            # A name for the window (for 'config' windows, the same as the window type)
            winName                     => $winName,
            # The GA::Obj::Workspace object for the workspace in which this window is created
            workspaceObj                => $workspaceObj,
            # The owner; a 'grid' window object (but not an 'external' window) or a 'free' window
            #   object. When this window opens/closes, the owner is informed via calls to its
            #   ->add_childFreeWin / ->del_childFreeWin functions
            owner                       => $owner,
            # The GA::Session from which this function was called. 'undef' if the calling function
            #   didn't specify a session and $owner's ->session IV is also 'undef'
            session                     => $session,
            # When GA::Session->pseudoCmd is called to execute a client command, the mode in which
            #   it should be called (usually 'win_error' or 'win_only', which causes errors to be
            #   displayed in a 'dialogue' window)
            pseudoCmdMode               => 'win_error',

            # The window widget. For most window objects, the Gtk2::Window. For pseudo-windows, the
            #   parent 'main' window's Gtk2::Window
            # The code should use this IV when it wants to do something to the window itself
            #   (minimise it, make it active, etc)
            winWidget                   => undef,
            # The window container. For most window objects, the Gtk2::Window. For pseudo-windows,
            #   the parent GA::Table::PseudoWin table object
            # The code should use this IV when it wants to add, modify or remove widgets inside the
            #   window itself
            winBox                      => undef,
            # The Gnome2::Wnck::Window, if known
            wnckWin                     => undef,
            # Flag set to TRUE if the window actually exists (after a call to $self->winEnable),
            #   FALSE if not
            enabledFlag                 => FALSE,
            # Flag set to TRUE if the Gtk2 window itself is visible (after a call to
            #   $self->setVisible), FALSE if it is not visible (after a call to $self->setInvisible)
            visibleFlag                 => TRUE,
            # Registry hash of 'free' windows (excluding 'dialogue' windows) for which this window
            #   is the parent, a subset of GA::Obj::Desktop->freeWinHash. Hash in the form
            #       $childFreeWinHash{unique_number} = blessed_reference_to_window_object
            childFreeWinHash            => {},
            # When a child 'free' window (excluding 'dialogue' windows) is destroyed, this parent
            #   window is informed via a call to $self->del_childFreeWin
            # When the child is destroyed, this window might want to call some of its own functions
            #   to update various widgets and/or IVs, in which case this window adds an entry to
            #   this hash; a hash in the form
            #       $childDestroyHash{unique_number} = list_reference
            # ...where 'unique_number' is the child window's ->number, and 'list_reference' is a
            #   reference to a list in groups of 2, in the form
            #       (sub_name, argument_list_ref, sub_name, argument_list_ref...)
            childDestroyHash            => {},

            # The container widget into which all other widgets are packed (usually a Gtk2::VBox or
            #   Gtk2::HBox, but any container widget can be used; takes up the whole window client
            #   area)
            packingBox                  => undef,       # Gtk2::VBox

            # Standard IVs for 'free' windows

            # The window's default size, in pixels
            widthPixels                 => $axmud::CLIENT->constFreeWinWidth,
            heightPixels                => $axmud::CLIENT->constFreeWinHeight,
            # Default border/item spacing sizes used in the window, in pixels
            borderPixels                => $axmud::CLIENT->constFreeBorderPixels,
            spacingPixels               => $axmud::CLIENT->constFreeSpacingPixels,

            # A string to use as the window title. If 'undef', a generic title is used
            title                       => $title,
            # Hash containing any number of key-value pairs needed for this particular 'config'
            #   window; for example, for example, GA::PrefWin::TaskStart uses it to specify a task
            #   name and type. Set to an empty hash if not required
            configHash                  => {%configHash},

            # Standard IVs for 'config' windows

            # Widgets
            notebook                    => undef,       # Gtk2::Notebook
            hBox                        => undef,       # Gtk2::HBox
            tooltips                    => undef,       # Gtk2::Tooltips
            okButton                    => undef,       # Gtk2::Button
            cancelButton                => undef,       # Gtk2::Button
            resetButton                 => undef,       # Gtk2::Button
            saveButton                  => undef,       # Gtk2::Button

            # The standard table size for the notebook (any 'edit'/'pref' window can use a different
            #   size, if it wants)
            tableSize                   => 12,

            # The object to be edited in the window (for 'edit' windows only; should be 'undef' for
            #   'pref' windows)
            editObj                     => $editObj,
            # Flag set to TRUE if $editObj is either temporary, or has not yet been added to any
            #   registry (usually because the user needs to name it first). Set to FALSE
            #   (or 'undef') otherwise. Ignored if $editObj is not specified
            tempFlag                    => $tempFlag,
            # Flag that can be set to TRUE (usually by $self->setupNotebook or ->expandNotebook) if
            #   $editObj is a current object (e.g. if it is a current profile); set to FALSE at all
            #   other times
            currentFlag                 => FALSE,
            # For 'edit' windows, a hash of IVs in $editObj that should be changed. If no changes
            #   have been made in the 'edit' window, the hash is empty; otherwise the hash contains
            #   the new values for each IV to be modified
            # Hash in the form:
            #   $editHash{iv_name} = scalar;
            #   $editHash{iv_name} = list_reference;
            #   $editHash{iv_name} = hash_reference;
            # For 'pref' windows, a hash of key-value pairs set by the window's widgets;
            #   $self->enableButtons can access this hash to perform any necessary actions
            #   ('pref' windows don't make a call to ->saveChanges)
            editHash                    => {},
            # Hash containing any number of key-value pairs needed for this particular
            #   'edit'/'pref' window; for example, GA::PrefWin::TaskStart uses it to specify a
            #   task name and type. Set to an empty hash if not required
            editConfigHash              => \%configHash,

            # IVs for this type of window

            # A flag which, if set to TRUE, means that every object in every region of the world
            #   model is searched
            searchAllFlag               => TRUE,
            # If ->searchAllFlag is not set, then the name of the region in which to search
            searchRegion                => undef,

            # Which categories of world model objects to search, in the form
            #   $categoryHash{world_model_category} = undef
            categoryHash                => {
                'region'                => undef,
                'room'                  => undef,
                'weapon'                => undef,
                'armour'                => undef,
                'garment'               => undef,
                'char'                  => undef,
                'minion'                => undef,
                'sentient'              => undef,
                'creature'              => undef,
                'portable'              => undef,
                'decoration'            => undef,
                'custom'                => undef,
            },

            # IVs required by this 'edit' window (but not by GA::Generic::EditWin)
            # A hash to specify which world model IVs should be searched, in the form
            #   $searchHash{iv_name} = search_string
            # Each IV to be checked is added to this hash as a key. The key's value is a search
            #   string (where appropriate); otherwise the value is 'undef'
            # NB Some IVs can be checked in two ways, in which case there are two keys added to the
            #   hash: 'name' and '_name'
            searchHash                  => {},
            # A parallel hash for IVs that should be checked against a range of values, in the form
            #   $searchRangeHash{iv_name} = operator
            # ...where 'operator' is set to '==', '>', '>=', '<', '<=' or 'min-max'
            searchRangeHash             => {},
            # A parallel hash for IVs that should be checked against a range of values, when the
            #   operator is 'min-max'
            # The minimum value is the value stored in ->searchHash; the maximum value is the value
            #   stored in this hash
            searchUpperHash             => {},
            # Another parallel hash which, this time, contains all possible IVs (i.e. all possible
            #   keys in ->searchHash), and tells us what kind of check is done on this IV, in the
            #   form
            #       $searchTypeHash{iv_name} = type
            # 'type' is one of the following:
            #   'match'         - perform a regex on the IV's value
            #   'flag'          - check whether the IV flag is set (or not)
            #   'string_equal'  - check whether the IV string is an exact match for the IV's value
            #   'range'         - check whether the IV number is in a certain range, or not
            #   'include'       - check whether the an exact match is found in the IV list
            #   'list_match'    - perform a regex on every item in the IV list
            #   'key'           - check whether the key exists in the IV hash
            #   'not_key'       - check whether the key doesn't exist in the IV hash
            #   'used_hash'     - check that the IV hash is not empty
            #   'value_match'   - perform a regex on the values in every key-value pair in the hash
            #                       IV
            #   'special'   - do something else
            searchTypeHash              => {},

            # A hash used by $self->performSearch to compile a list of all world model objects in a
            #   region
            compileHash                 => {},
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}             # Inherited from GA::Generic::ConfigWin

#   sub winEnable {}            # Inherited from GA::Generic::ConfigWin

#   sub winDesengage {}         # Inherited from GA::Generic::FreeWin

#   sub winDestroy {}           # Inherited from GA::Generic::FreeWin

#   sub winShowAll {}           # Inherited from GA::Generic::Win

#   sub drawWidgets {}          # Inherited from GA::Generic::ConfigWin

#   sub redrawWidgets {}        # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

#   sub checkEditObj {}         # Inherited from GA::Generic::ConfigWin

    sub enableButtons {

        # Called by $self->drawWidgets
        # We only need a single button so, instead of calling the generic ->enableButtons, call a
        #   method that creates just one button
        #
        # Expected arguments
        #   $hBox       - The horizontal packing box in which the buttons live (not yet stored as
        #                   an IV)
        #   $tooltips   - A Gtk2::Tooltips object for the buttons (not yet stored as an IV)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, a list containing the Gtk::Button object created

        my ($self, $hBox, $tooltips, $check) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (! defined $hBox || ! defined $tooltips || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->enableButtons', @_);
            return @emptyList;
        }

        return $self->enableSingleButton($hBox, $tooltips);
    }

#   sub enableSingleButton {}   # Inherited from GA::Generic::ConfigWin

    sub setupNotebook {

        # Called by $self->winEnable
        # Creates the first tab for the notebook. The remaining tabs are created by
        #   $self->expandNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setupNotebook', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('_Search', $self->notebook);

        # Set up the rest of the tab
        $self->searchTab($table);

        # Set up the remaining tabs
        $self->expandNotebook();

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub expandNotebook {

        # Called by $self->setupNotebook
        # Set up additional tabs for the notebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->expandNotebook', @_);
        }

        $self->propertiesTab();
        $self->properties2Tab();
        $self->resultsTab();

        return 1;
    }

#   sub saveChanges {}          # Inherited from GA::Generic::ConfigWin

    # Notebook tabs

    sub searchTab {

        # Search tab
        #
        # Expected arguments
        #   $table  - The Gtk2::Table
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $table, $check) = @_;

        # Local variables
        my (@comboList, @widgetList);

        # Check for improper arguments
        if (! defined $table || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->searchTab', @_);
        }

#       # Tab setup (already created by the calling function)
#       my ($vBox, $table) = $self->addTab('_Search', $self->notebook);

        # Top section
        $self->addLabel($table, '<b>Search options</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>Specify which parts of the world model to search</i>',
            1, 12, 1, 2);

        my ($radioGroup, $radioButton, $radioButton2, $radioButton3);

        ($radioGroup, $radioButton) = $self->addRadioButton(
            $table,
            undef,
            'Search entire world model',
            undef, undef, TRUE,
            1, 6, 2, 3,
        );
        $radioButton->signal_connect('toggled' => sub {

            if ($radioButton->get_active()) {

                $self->ivPoke('searchAllFlag', TRUE);
                $self->ivUndef('searchRegion');
            }
        });

        ($radioGroup, $radioButton2) = $self->addRadioButton(
            $table,
            $radioGroup,
            'Search in current region',
            undef, undef,
            TRUE,
            1, 6, 3, 4
        );
        $radioButton2->signal_connect('toggled' => sub {

            $self->ivPoke('searchAllFlag', FALSE);
            $self->ivPoke('searchRegion', $self->session->mapWin->currentRegionmap->name);
        });
        # This widget is insensitive, if the current session doesn't have an Automapper window open,
        #   or if the Automapper window has no current regionmap
        if (! $self->session->mapWin || ! $self->session->mapWin->currentRegionmap) {

            $radioButton2->set_state('insensitive');
        }

        ($radioGroup, $radioButton3) = $self->addRadioButton(
            $table,
            $radioGroup,
            'Search in region:',
            undef, undef,
            TRUE,
            1, 3, 4, 5,
        );

        # Get a sorted list of regionmap names
        @comboList = sort {lc($a) cmp lc($b)}
                        ($self->session->worldModelObj->ivKeys('regionmapHash'));

        my $combo = $self->addComboBox($table, undef, \@comboList, '',
            TRUE,               # No 'undef' value used
            3, 6, 4, 5);
        $combo->signal_connect('changed' => sub {

            if ($radioButton3->get_active()) {

                $self->ivPoke('searchAllFlag', TRUE);
                $self->ivPoke('searchRegion', $combo->get_active_text());
            }
        });

        $radioButton3->signal_connect('toggled' => sub {

            $self->ivPoke('searchAllFlag', FALSE);
            $self->ivPoke('searchRegion', $combo->get_active_text());
        });

        # This radiobutton and its combobox are insensitive, if there are no regions
        if (! $self->session->worldModelObj->regionmapHash) {

            $radioButton3->set_state('insensitive');
            $combo->set_state('insensitive');
        }

        my $checkButton = $self->addCheckButton($table, undef, TRUE,
            9, 10, 2, 3);
        $checkButton->set_active($self->session->worldModelObj->searchSelectRoomsFlag);
        $checkButton->signal_connect('toggled' => sub {

            if ($checkButton->get_active()) {
                $self->session->worldModelObj->set_searchSelectRoomsFlag(TRUE);
            } else {
                $self->session->worldModelObj->set_searchSelectRoomsFlag(FALSE);
            }
        });

        $self->addLabel($table, 'Select matching rooms on map',
            10, 12, 2, 3);

        # Bottom section
        $self->addLabel($table, '<i>Specify which categories of model object to search</i>',
            1, 12, 6, 7);

        # Add check buttons, one for each category of world model object
        push (
            @widgetList,
            $self->searchTab_addCheckButton($table, 'region', 'Search regions', 1, 2, 7, 8),
        );

        push (
            @widgetList,
            $self->searchTab_addCheckButton($table, 'room', 'Search rooms', 1, 2, 8, 9),
        );

        push (
            @widgetList,
            $self->searchTab_addCheckButton($table, 'weapon', 'Search weapons', 1, 2, 9, 10),
        );

        push (
            @widgetList,
            $self->searchTab_addCheckButton($table, 'armour', 'Search armour', 1, 2, 10, 11),
        );

        push (
            @widgetList,
            $self->searchTab_addCheckButton($table, 'garment', 'Search garments', 5, 6, 7, 8),
        );

        push (
            @widgetList,
            $self->searchTab_addCheckButton($table, 'char', 'Search characters', 5, 6, 8, 9),
        );

        push (
            @widgetList,
            $self->searchTab_addCheckButton($table, 'minion', 'Search minions', 5, 6, 9, 10),
        );

        push (
            @widgetList,
            $self->searchTab_addCheckButton($table, 'sentient', 'Search sentients', 5, 6, 10, 11),
        );

        push (
            @widgetList,
            $self->searchTab_addCheckButton($table, 'creature', 'Search creatures', 9, 10, 7, 8),
        );

        push (
            @widgetList,
            $self->searchTab_addCheckButton($table, 'portable', 'Search portables', 9, 10, 8, 9),
        );

        push (
            @widgetList,
            $self->searchTab_addCheckButton(
                $table,
                'decoration',
                'Search decorations',
                9, 10, 9, 10,
            ),
        );

        push (
            @widgetList,
            $self->searchTab_addCheckButton(
                $table,
                'custom',
                'Search custom objects',
                9, 10, 10, 11,
            ),
        );

        # Add buttons
        my $button = $self->addButton(
            $table,
            'Select all',
            'Select all the categories of model object',
            undef,
            1, 4, 11, 12,
        );

        $button->signal_connect('clicked' => sub {

            foreach my $widget (@widgetList) {

                $widget->set_active(TRUE);
            }

            $self->ivPoke('categoryHash',
                'region', undef,
                'room', undef,
                'weapon', undef,
                'armour', undef,
                'garment', undef,
                'character', undef,
                'minion', undef,
                'sentient', undef,
                'creature', undef,
                'portable', undef,
                'decoration', undef,
                'custom', undef,
            );
        });

        my $button2 = $self->addButton(
            $table,
            'Unselect all',
            'Unselect all the categories of model object',
            undef,
            4, 7, 11, 12,
        );
        $button2->signal_connect('clicked' => sub {

            foreach my $widget (@widgetList) {

                $widget->set_active(FALSE);
            }

            $self->ivEmpty('categoryHash');
        });

#       # Tab complete (handled by the calling function)
#       $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub searchTab_addCheckButton {

        # Called by $self->searchTab
        # Creates a single Gtk2::CheckButton at the specified table position
        #
        # Expected arguments
        #   $table      - The Gtk2::Table
        #   $category   - The category of model object, e.g. 'room', 'weapon' etc
        #   $label      - The text of the accompanying label
        #   $leftAttach, $rightAttach, $topAttach, $bottomAttach
        #               - The position of the checkbutton in the table
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, returns the Gtk2::CheckButton created

        my (
            $self, $table, $category, $label, $leftAttach, $rightAttach, $topAttach, $bottomAttach,
            $check,
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $category || ! defined $label || ! defined $leftAttach
            || ! defined $rightAttach || ! defined $topAttach || ! defined $bottomAttach
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->searchTab_addCheckButton',
                @_,
            );
        }

        # Add the checkbutton
        my $checkButton = $self->addCheckButton(
            $table,
            undef,
            TRUE,
            $leftAttach, $rightAttach, $topAttach, $bottomAttach,
        );

        # Add the accompanying label
        $self->addLabel(
            $table,
            $label,
            ($leftAttach + 1), ($rightAttach + 2), $topAttach, $bottomAttach,
        );

        # All the checkbuttons start selected
        $checkButton->set_active(TRUE);

        # Signal connect
        $checkButton->signal_connect('toggled' => sub {

            if ($checkButton->get_active()) {
                $self->ivAdd('categoryHash', $category, undef);
            } else {
                $self->ivDelete('categoryHash', $category);
            }
        });

        return $checkButton;
    }

    sub propertiesTab {

        # Properties tab
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->propertiesTab', @_);
        }

        # Tab setup
        # Create a notebook within the main one, so that we have two rows of tabs
        my ($vBox, $innerNotebook) = $self->addInnerNotebookTab('_Properties 1-4', $self->notebook);

        # Add tabs to the inner notebook
        $self->propertiesGroup1Tab($innerNotebook);
        $self->propertiesGroup2Tab($innerNotebook);
        $self->propertiesGroup3Tab($innerNotebook);
        $self->propertiesGroup4Tab($innerNotebook);

        return 1;
    }

    sub properties2Tab {

        # Properties2 tab
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->properties2Tab', @_);
        }

        # Tab setup
        # Create a notebook within the main one, so that we have two rows of tabs
        my ($vBox, $innerNotebook) = $self->addInnerNotebookTab('P_roperties 5', $self->notebook);

        # Add tabs to the inner notebook
        $self->propertiesRegionsTab($innerNotebook);
        $self->propertiesRooms1Tab($innerNotebook);
        $self->propertiesRooms2Tab($innerNotebook);
        $self->propertiesCharactersTab($innerNotebook);
        $self->propertiesMinionsTab($innerNotebook);
        $self->propertiesSentients1Tab($innerNotebook);
        $self->propertiesSentients2Tab($innerNotebook);
        $self->propertiesCreatures1Tab($innerNotebook);
        $self->propertiesCreatures2Tab($innerNotebook);
        $self->propertiesPortsDecsTab($innerNotebook);

        return 1;
    }

    sub propertiesGroup1Tab {

        # PropertiesGroup1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->propertiesGroup1Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Group _1', $innerNotebook);

        # Connection details
        $self->addLabel($table, '<b>Group 1 properties</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>Applies to all categories of world model object</i>',
            1, 12, 1, 2);

        $self->propertiesTab_addEntryWithIcon($table, 'name', 'match',
            'Name matches', 'string', 1, undef, 2);
        $self->propertiesTab_addEntryWithIcon($table, 'privateHash', 'key',
            'Has private property', 'string', 1, undef, 3);
        $self->propertiesTab_addEntryWithIcon($table, 'sourceCodePath', 'match',
            'Source code path matches', 'string', 1, undef, 4);
        $self->propertiesTab_addEntryWithIcon($table, 'notesList', 'list_match',
            'Line in notes matches', 'string', 1, undef, 5);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub propertiesGroup2Tab {

        # PropertiesGroup2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->propertiesGroup2Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Group _2', $innerNotebook);

        # Connection details
        $self->addLabel($table, '<b>Group 2 properties</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $table,
            '<i>Applies to all categories of world model object except regions and rooms</i>',
            1, 12, 1, 2,
        );

        $self->propertiesTab_addEntryWithIcon($table, 'noun', 'match',
            'Main noun matches', 'string', 1, undef, 2);
        $self->propertiesTab_addEntryWithIcon($table, 'otherNounList', 'include',
            'Other noun list includes', 'string', 1, undef, 3);
        $self->propertiesTab_addEntryWithIcon($table, 'adjList', 'include',
            'Adjective list includes', 'string', 1, undef, 4);
        $self->propertiesTab_addEntryWithIcon($table, 'pseudoAdjList', 'include',
            'Pseudo-adjective list includes', 'string', 1, undef, 5);
        $self->propertiesTab_addEntryWithIcon($table, 'rootAdjList', 'include',
            'Root adjective list includes', 'string', 1, undef, 6);
        $self->propertiesTab_addEntryWithIcon($table, 'unknownWordList', 'include',
            'Unknown word list includes', 'string', 1, undef, 7);
        $self->propertiesTab_addEntryWithIcon($table, 'baseString', 'match',
            'Base string matches', 'string', 1, undef, 8);
        $self->propertiesTab_addEntryWithIcon($table, 'descrip', 'match',
            'Description matches', 'string', 1, undef, 9);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub propertiesGroup3Tab {

        # PropertiesGroup3 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->propertiesGroup3Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Group _3', $innerNotebook);

        # Connection details
        $self->addLabel($table, '<b>Group 3 properties</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $table,
            '<i>Applies to characters, minions, sentients, creatures and custom objects</i>',
            1, 12, 1, 2,
        );

        $self->propertiesTab_addCheckButton($table, 'explicitFlag', 'flag',
            'Explicit in room description?', 2);
        $self->propertiesTab_addCheckButton($table, 'alreadyAttackedFlag', 'flag',
            'Already attacked?', 3);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub propertiesGroup4Tab {

        # PropertiesGroup4 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->propertiesGroup4Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Group _4', $innerNotebook);

        # Connection details
        $self->addLabel($table, '<b>Group 4 properties</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $table,
            '<i>Applies to weapons, armour, garments, portables, decorations and custom'
            . ' objects</i>',
            1, 12, 1, 2,
        );

        $self->propertiesTab_addCheckButton($table, 'explicitFlag', 'flag',
            'Explicit in room description?', 2);
        $self->propertiesTab_addEntryWithRange($table, 'weight', 'range',
            'Object\'s weight', 'float', 0, undef, 3);
        $self->propertiesTab_addEntryWithRange($table, 'bonusHash', 'range',
            'Stat bonuses', 'int', undef, undef, 4);
        $self->propertiesTab_addEntryWithRange($table, 'condition', 'range',
            'Condition (0-100)', 'int', 0, undef, 5);
        $self->propertiesTab_addCheckButton($table, 'fixableFlag', 'flag',
            'Fixable/repairable?', 6);
        $self->propertiesTab_addCheckButton($table, 'sellableFlag', 'flag',
            'Sellable?', 7);
        $self->propertiesTab_addEntryWithRange($table, 'buyValue', 'range',
            'Value when bought', 'float', 0, undef, 8);
        $self->propertiesTab_addEntryWithRange($table, 'sellValue', 'range',
            'Value when sold', 'float', 0, undef, 9);
        $self->propertiesTab_addEntryWithIcon($table, 'exclusiveHash', 'key',
            'Exclusive hash includes profile', 'string', 1, undef, 10);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub propertiesRegionsTab {

        # PropertiesRegions tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->propertiesRegionsTab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Re_gions', $innerNotebook);

        # Connection details
        $self->addLabel($table, '<b>Group 5 properties</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>Properties which apply only to regions</i>',
            1, 12, 1, 2);

        $self->propertiesTab_addCheckButton($table, 'tempRegionFlag', 'flag',
            'Region is temporary?', 2);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub propertiesRooms1Tab {

        # PropertiesRooms1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->propertiesRooms1Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('_Rooms 1', $innerNotebook);

        # Connection details
        $self->addLabel($table, '<b>Group 5 properties</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>Properties which apply only to rooms (page 1/2)</i>',
            1, 12, 1, 2);

        $self->propertiesTab_addEntryWithIcon($table, 'descripHash', 'value_match',
            'Verbose descrips match', 'string', 1, undef, 2);
        $self->propertiesTab_addEntryWithIcon($table, 'titleList', 'list_match',
            'Room titles match', 'string', 1, undef, 3);
        $self->propertiesTab_addEntryWithIcon($table, 'sortedExitList', 'include',
            'Exits include', 'string', 1, undef, 4);
        $self->propertiesTab_addEntryWithIcon($table, 'visitHash', 'key',
            'Visitors include', 'string', 1, undef, 5);
        $self->propertiesTab_addEntryWithIcon($table, '_visitHash', 'not_key',
            'Visitors don\'t include', 'string', 1, undef, 6);
        $self->propertiesTab_addEntryWithIcon($table, 'exclusiveHash', 'key',
            'Exclusive hash includes profile', 'string', 1, undef, 7);
        $self->propertiesTab_addEntryWithIcon($table, 'roomFlagHash', 'key',
            'Room flags include', 'string', 1, undef, 8);
        $self->propertiesTab_addEntryWithIcon($table, 'roomGuild', 'match',
            'Room guild matches', 'string', 1, undef, 9);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub propertiesRooms2Tab {

        # PropertiesRooms2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->propertiesRooms2Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Rooms 2', $innerNotebook);

        # Connection details
        $self->addLabel($table, '<b>Group 5 properties</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>Properties which apply only to rooms (page 2/2)</i>',
            1, 12, 1, 2);

        $self->propertiesTab_addCheckButton($table, 'hiddenObjHash', 'used_hash',
            'Contains hidden objects?', 2);
        $self->propertiesTab_addEntryWithIcon($table, '_hiddenObjHash', 'special',
            'Hidden object name matches', 'string', 1, undef, 3);
        $self->propertiesTab_addEntryWithIcon($table, 'searchHash', 'key',
            'Search strings include', 'string', 1, undef, 4);
        $self->propertiesTab_addEntryWithIcon($table, '_searchHash', 'value_match',
            'Search responses match', 'string', 1, undef, 5);
        $self->propertiesTab_addEntryWithIcon($table, 'nounList', 'include',
            'Noun list includes', 'string', 1, undef, 6);
        $self->propertiesTab_addEntryWithIcon($table, 'adjList', 'include',
            'Adjective list includes', 'string', 1, undef, 7);
        $self->propertiesTab_addEntryWithIcon($table, 'arriveScriptList', 'include',
            'Arrival scripts to run include', 'string', 1, undef, 8);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub propertiesCharactersTab {

        # PropertiesCharacters tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->propertiesCharactersTab',
                @_,
            );
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('_Characters', $innerNotebook);

        # Connection details
        $self->addLabel($table, '<b>Group 5 properties</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>Properties which apply only to characters</i>',
            1, 12, 1, 2);

        $self->propertiesTab_addEntryWithIcon($table, 'guild', 'match',
            'Guild matches', 'string', 1, undef, 2);
        $self->propertiesTab_addEntryWithIcon($table, 'race', 'match',
            'Race matches', 'string', 1, undef, 3);
        $self->propertiesTab_addCheckButton($table, 'ownCharFlag', 'flag',
            'Belongs to you?', 4);
        $self->propertiesTab_addEntryWithIcon($table, 'owner', 'match',
            'Owner\'s name matches', 'string', 1, undef, 5);
        @list = ('mortal', 'wiz', 'test');
        $self->propertiesTab_addComboBox($table, 'mortalStatus', 'string_equal',
            'Mortal status is', \@list, 6);
        @list = ('friendly', 'neutral', 'hostile');
        $self->propertiesTab_addComboBox($table, 'diplomaticStatus', 'string_equal',
            'Diplomatic status is', \@list, 7);
        $self->propertiesTab_addCheckButton($table, 'grudgeFlag', 'flag',
            'Ever attacked you?', 8);
        $self->propertiesTab_addEntryWithRange($table, 'level', 'range',
            'Level', 'int', 0, undef, 9);
        $self->propertiesTab_addEntryWithIcon($table, 'questList', 'key',
            'Quest list includes', 'string', 1, undef, 10);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub propertiesMinionsTab {

        # PropertiesMinions tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->propertiesMinionsTab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('_Minions', $innerNotebook);

        # Connection details
        $self->addLabel($table, '<b>Group 5 properties</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>Properties which apply only to minions</i>',
            1, 12, 1, 2);

        $self->propertiesTab_addEntryWithIcon($table, 'guild', 'match',
            'Guild matches', 'string', 1, undef, 2);
        $self->propertiesTab_addEntryWithIcon($table, 'race', 'match',
            'Race matches', 'string', 1, undef, 3);
        $self->propertiesTab_addCheckButton($table, 'ownMinionFlag', 'flag',
            'Belongs to you?', 4);
        $self->propertiesTab_addEntryWithRange($table, 'level', 'range',
            'Level', 'int', 0, undef, 5);
        $self->propertiesTab_addEntryWithRange($table, 'value', 'range',
            'Cost of acquiring', 'int', 0, undef, 6);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub propertiesSentients1Tab {

        # PropertiesSentients1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->propertiesSentients1Tab',
                @_,
            );
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('_Sentients 1', $innerNotebook);

        # Connection details
        $self->addLabel($table, '<b>Group 5 properties</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>Properties which apply only to sentients (page 1/2)</i>',
            1, 12, 1, 2);

        $self->propertiesTab_addEntryWithIcon($table, 'guild', 'match',
            'Guild matches', 'string', 1, undef, 2);
        $self->propertiesTab_addEntryWithIcon($table, 'race', 'match',
            'Race matches', 'string', 1, undef, 3);
        $self->propertiesTab_addCheckButton($table, 'talkativeFlag', 'flag',
            'Talkative?', 4);
        $self->propertiesTab_addEntryWithIcon($table, 'talkList', 'list_match',
            'Talk list includes match', 'string', 1, undef, 5);
        $self->propertiesTab_addCheckButton($table, 'actionFlag', 'flag',
            'Seen performing actions?', 6);
        $self->propertiesTab_addEntryWithIcon($table, 'actionList', 'list_match',
            'Action list includes match', 'string', 1, undef, 7);
        $self->propertiesTab_addCheckButton($table, 'unfriendlyFlag', 'flag',
            'Ever initiated combat?', 8);
        @list = ('good', 'evil', 'neutral');
        $self->propertiesTab_addComboBox($table, 'morality', 'string_equal',
            'Morality is', \@list, 9);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub propertiesSentients2Tab {

        # PropertiesSentients2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->propertiesSentients2Tab',
                @_,
            );
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('_Sentients 2', $innerNotebook);

        # Connection details
        $self->addLabel($table, '<b>Group 5 properties</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>Properties which apply only to sentients (page 2/2)</i>',
            1, 12, 1, 2);

        $self->propertiesTab_addCheckButton($table, 'wanderFlag', 'flag',
            'Tends to wander off (of own volition)?', 2);
        $self->propertiesTab_addCheckButton($table, 'fleeFlag', 'flag',
            'Has ever fleed combat?', 3);
        $self->propertiesTab_addCheckButton($table, 'quickFleeFlag', 'flag',
            'Tends to flee combat quickly?', 4);
        $self->propertiesTab_addCheckButton($table, 'noAttackFlag', 'flag',
            'Should NEVER be attacked?', 5);
        $self->propertiesTab_addCheckButton($table, 'mercyFlag', 'flag',
            'Mercies, rather than kills, opponents?', 6);
        $self->propertiesTab_addEntryWithIcon($table, 'questName', 'match',
            'Associated with quest matching', 'string', 1, undef, 7);
        $self->propertiesTab_addEntryWithRange($table, 'level', 'range',
            'Level', 'int', 0, undef, 8);
        $self->propertiesTab_addEntryWithRange($table, 'cashList', 'range',
            'Average cash', 'float', 0, undef, 9);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub propertiesCreatures1Tab {

        # PropertiesCreatures1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->propertiesCreatures1Tab',
                @_,
            );
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('_Creatures 1', $innerNotebook);

        # Connection details
        $self->addLabel($table, '<b>Group 5 properties</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>Properties which apply only to creatures (page 1/2)</i>',
            1, 12, 1, 2);

        $self->propertiesTab_addEntryWithIcon($table, 'guild', 'match',
            'Guild matches', 'string', 1, undef, 2);
        $self->propertiesTab_addEntryWithIcon($table, 'race', 'match',
            'Race matches', 'string', 1, undef, 3);
        $self->propertiesTab_addCheckButton($table, 'actionFlag', 'flag',
            'Seen performing actions?', 4);
        $self->propertiesTab_addEntryWithIcon($table, 'actionList', 'list_match',
            'Action list includes match', 'string', 1, undef, 5);
        $self->propertiesTab_addCheckButton($table, 'unfriendlyFlag', 'flag',
            'Ever initiated combat?', 6);
        @list = ('good', 'evil', 'neutral');
        $self->propertiesTab_addComboBox($table, 'morality', 'string_equal',
            'Morality is', \@list, 7);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub propertiesCreatures2Tab {

        # PropertiesCreatures2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->propertiesCreatures2Tab',
                @_,
            );
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('_Creatures 2', $innerNotebook);

        # Connection details
        $self->addLabel($table, '<b>Group 5 properties</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>Properties which apply only to creatures (page 2/2)</i>',
            1, 12, 1, 2);

        $self->propertiesTab_addCheckButton($table, 'wanderFlag', 'flag',
            'Tends to wander off (of own volition)?', 2);
        $self->propertiesTab_addCheckButton($table, 'fleeFlag', 'flag',
            'Has ever fleed combat?', 3);
        $self->propertiesTab_addCheckButton($table, 'quickFleeFlag', 'flag',
            'Tends to flee combat quickly?', 4);
        $self->propertiesTab_addCheckButton($table, 'noAttackFlag', 'flag',
            'Should NEVER be attacked?', 5);
        $self->propertiesTab_addCheckButton($table, 'mercyFlag', 'flag',
            'Mercies, rather than kills, opponents?', 6);
        $self->propertiesTab_addEntryWithIcon($table, 'questName', 'match',
            'Associated with quest matching', 'string', 1, undef, 7);
        $self->propertiesTab_addEntryWithRange($table, 'level', 'range',
            'Level', 'int', 0, undef, 8);
        $self->propertiesTab_addEntryWithRange($table, 'cashList', 'range',
            'Average cash', 'float', 0, undef, 9);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub propertiesPortsDecsTab {

        # PropertiesPortsDecs tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (@portList, @decList);

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->propertiesPortsDecsTab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Ports/_Decs', $innerNotebook);

        # Connection details
        $self->addLabel($table, '<b>Group 5 properties</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>Properties which only apply to portables/decorations</i>',
            1, 12, 1, 2);

        @portList = $self->session->currentDict->portableTypeList;
        @decList = $self->session->currentDict->decorationTypeList;

        $self->propertiesTab_addComboBox($table, 'type', 'special',
            'Portable object type is', \@portList, 2);
        $self->propertiesTab_addComboBox($table, '_type', 'special',
            'Decoration object type is', \@decList, 3);

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub propertiesTab_addCheckButton {

        # Called by several $self->propertiesXXX tabs
        # Adds a single line to the tab with a main checkbutton, a label and a second checkbutton
        #   to specify the state of the flag
        #
        # Expected arguments
        #   $table      - The Gtk2::Table
        #   $iv         - The IV to add to the search - matches a key in $self->searchHash
        #   $ivType     - What kind of checking should be done on this IV (see the comments in
        #                   ->new)
        #   $label      - The accompanying label text
        #   $topAttach  - The position of the line in the table
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $table, $iv, $ivType, $label, $topAttach, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $iv || ! defined $ivType || ! defined $label
            || ! defined $topAttach || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->propertiesTab_addCheckButton',
                @_,
            );
        }

        # Add a checkbutton which turns on/off checking this IV completely
        my $checkButton = $self->addCheckButton($table, undef, TRUE,
            1, 2, $topAttach, ($topAttach + 1), 0, 0.5);

        # Add the accompanying label
        $self->addLabel($table, $label,
            2, 10, $topAttach, ($topAttach + 1));
        # Add a second label, to make clear which checkbutton is which
        $self->addLabel($table, 'Set flag:',
            10, 11, $topAttach, ($topAttach + 1));

        # Add a second checkbutton to specify the state of the flag
        my $checkButton2 = $self->addCheckButton($table, undef, TRUE,
            11, 12, $topAttach, ($topAttach + 1), 1, 0.5);

        # Signal connects
        $checkButton->signal_connect('toggled' => sub {

            if ($checkButton->get_active()) {

                if ($checkButton2->get_active()) {
                    $self->ivAdd('searchHash', $iv, TRUE);
                } else {
                    $self->ivAdd('searchHash', $iv, FALSE);
                }

            } else {

                $self->ivDelete('searchHash', $iv);
            }
        });

        $checkButton2->signal_connect('toggled' => sub {

            if ($checkButton->get_active()) {

                if ($checkButton2->get_active()) {
                    $self->ivAdd('searchHash', $iv, TRUE);
                } else {
                    $self->ivAdd('searchHash', $iv, FALSE);
                }

            } else {

                $self->ivDelete('searchHash', $iv);
            }
        });

        $self->ivAdd('searchTypeHash', $iv, $ivType);

        return 1;
    }

    sub propertiesTab_addComboBox {

        # Called by several $self->propertiesXXX tabs
        # Adds a single line to the tab with a main checkbutton, a label and a combobox
        #
        # Expected arguments
        #   $table      - The Gtk2::Table
        #   $iv         - The IV to add to the search - matches a key in $self->searchHash
        #   $ivType     - What kind of checking should be done on thiss IV (see the comments in
        #                   ->new)
        #   $label      - The accompanying label text
        #   $listRef    - Reference to a list containing the values to put in the combobox
        #   $topAttach  - The position of the line in the table
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $table, $iv, $ivType, $label, $listRef, $topAttach, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $iv || ! defined $ivType || ! defined $label
            || ! defined $listRef || ! defined $topAttach || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->propertiesTab_addComboBox',
                @_,
            );
        }

        # Add a checkbutton which turns on/off checking this IV completely
        my $checkButton = $self->addCheckButton($table, undef, TRUE,
            1, 2, $topAttach, ($topAttach + 1), 0, 0.5);

        # Add the accompanying label
        $self->addLabel($table, $label,
            2, 9, $topAttach, ($topAttach + 1));

        # Add a combobox
        my $combo = $self->addComboBox($table, undef, $listRef, '',
            TRUE,               # No 'undef' value used
            9, 12, $topAttach, ($topAttach + 1));

        # Signal connects
        $checkButton->signal_connect('toggled' => sub {

            if ($checkButton->get_active()) {
                $self->ivAdd('searchHash', $iv, $combo->get_active_text());
            } else {
                $self->ivDelete('searchHash', $iv);
            }
        });

        $combo->signal_connect('changed' => sub {

            if ($checkButton->get_active()) {
                $self->ivAdd('searchHash', $iv, $combo->get_active_text());
            } else {
                $self->ivDelete('searchHash', $iv);
            }
        });

        $self->ivAdd('searchTypeHash', $iv, $ivType);

        return 1;
    }

    sub propertiesTab_addEntryWithIcon {

        # Called by several $self->propertiesXXX tabs
        # Adds a single line to the tab with a main checkbutton, a label and an entry
        #
        # Expected arguments
        #   $table      - The Gtk2::Table
        #   $iv         - The IV to add to the search - matches a key in $self->searchHash
        #   $ivType     - What kind of checking should be done on this IV (see the comments in
        #                   ->new)
        #   $label      - The accompanying label text
        #   $mode       - 'int', 'float', 'string' or a reference to a function
        #               - if 'int', an integer is expected with the specified min/max values
        #               - if 'float', a floating point number is expected with the specified min/max
        #                   values
        #               - if 'string', a string is expected (which might be a number) with the
        #                   specified min/max length
        #               - if a function reference, a function is called which should return FALSE or
        #                   TRUE, depending on the value of the entry; the icon is set accordingly
        #   $min, $max  - The values described above (ignored when $mode is a function reference).
        #                   If $min is 'undef', there is no minimum; if $max is 'undef', there is no
        #                   maximum
        #   $topAttach  - The position of the line in the table
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise


        my ($self, $table, $iv, $ivType, $label, $mode, $min, $max, $topAttach, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $iv || ! defined $ivType || ! defined $label
            || ! defined $mode || ! defined $topAttach || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->propertiesTab_addEntryWithIcon',
                @_,
            );
        }

        # Add a checkbutton which turns on/off checking this IV completely
        my $checkButton = $self->addCheckButton($table, undef, TRUE,
            1, 2, $topAttach, ($topAttach + 1));

        # Add the accompanying label
        $self->addLabel($table, $label,
            2, 6, $topAttach, ($topAttach + 1));

        # Add the entry box
        my $entry = $self->addEntryWithIcon($table, undef, $mode, $min, $max,
            6, 12, $topAttach, ($topAttach + 1));

        # Signal connects
        $checkButton->signal_connect('toggled' => sub {

            if ($checkButton->get_active() && $self->checkEntryIcon($entry)) {
                $self->ivAdd('searchHash', $iv, $entry->get_text());
            } else {
                $self->ivDelete('searchHash', $iv);
            }
        });

        $entry->signal_connect('changed' => sub {

            if ($checkButton->get_active()) {
                $self->ivAdd('searchHash', $iv, $entry->get_text());
            } else {
                $self->ivDelete('searchHash', $iv);
            }
        });

        $self->ivAdd('searchTypeHash', $iv, $ivType);

        return 1;
    }

    sub propertiesTab_addEntryWithRange {

        # Called by several $self->propertiesXXX tabs
        # Adds a single line to the tab with a main checkbutton, a label, a combobox specifiying an
        #   operator (equals, less than, etc) and one or two entry boxes
        # Used with IVs that have numeric values
        #
        # Expected arguments
        #   $table      - The Gtk2::Table
        #   $iv         - The IV to add to the search - matches a key in $self->searchHash
        #   $ivType     - What kind of checking should be done on this IV (see the comments in
        #                    ->new)
        #   $label      - The accompanying label text
        #   $mode       - What kind of value is expected - should be 'int' or 'float'
        #   $min, $max  - The values described above (ignored when $mode is a function reference).
        #                   If $min is 'undef', there is no minimum; if $max is 'undef', there is no
        #                   maximum
        #   $topAttach  - The position of the line in the table
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $table, $iv, $ivType, $label, $mode, $min, $max, $topAttach, $check) = @_;

        # Local variables
        my @comboList;

        # Check for improper arguments
        if (
            ! defined $table || ! defined $iv || ! defined $ivType || ! defined $label
            || ! defined $mode || ! defined $topAttach || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->propertiesTab_addEntryWithRange',
                @_,
            );
        }

        # Add a checkbutton which turns on/off checking this IV completely
        my $checkButton = $self->addCheckButton($table, undef, TRUE,
            1, 2, $topAttach, ($topAttach + 1));

        # Add the accompanying label
        $self->addLabel($table, $label,
            2, 4, $topAttach, ($topAttach + 1));

        # Add a combo
        @comboList = (
            '==',
            '>',
            '>=',
            '<',
            '<=',
            'min-max',
        );

        my $combo = $self->addComboBox($table, undef, \@comboList, '',
            TRUE,               # No 'undef' value used
            4, 6, $topAttach, ($topAttach + 1));

        # Add two entry boxes, the second only available when the combo box is set to 'min-max',
        my $entry = $self->addEntryWithIcon($table, undef, $mode, $min, $max,
            6, 8, $topAttach, ($topAttach + 1));
        $self->addLabel($table, '(Max:)',
            8, 10, $topAttach, ($topAttach + 1));
        my $entry2 = $self->addEntryWithIcon($table, undef, $mode, $min, $max,
            10, 12, $topAttach, ($topAttach + 1));

        # Signal connects - since it's not a trivially simple check (but the same for all the
        #   widgets), call a special function to respond
        $checkButton->signal_connect('toggled' => sub {

            $self->propertiesTab_checkRange($iv, $checkButton, $combo, $entry, $entry2);
        });

        $combo->signal_connect('changed' => sub {

            my $comboText = $combo->get_active_text;

            $self->propertiesTab_checkRange($iv, $checkButton, $combo, $entry, $entry2);
        });

        $entry->signal_connect('changed' => sub {

            $self->propertiesTab_checkRange($iv, $checkButton, $combo, $entry, $entry2);
        });

        $entry2->signal_connect('changed' => sub {

            $self->propertiesTab_checkRange($iv, $checkButton, $combo, $entry, $entry2);
        });

        $self->ivAdd('searchTypeHash', $iv, $ivType);

        return 1;
    }

    sub resultsTab {

        # Results tab
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $wmObj,
            @columnList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resultsTab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('R_esults', $self->notebook);

        # Import the world model object
        $wmObj = $self->session->worldModelObj;

        # Search results
        $self->addLabel($table, '<b>Search results</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>List of matching world model objects</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Model #', 'int',
            'Category', 'text',
            'Name', 'text',
            'Parent #', 'text',     # Must be 'text', or objects without parents shown as 0
            'Parent category', 'text',
            'Parent name', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 8,
            -1, 220);      # Fixed height

        # Add some entries
        $self->addLabel($table, 'Max matches:',
            1, 3, 8, 9);
        my $entry = $self->addEntryWithIcon($table, undef, 'int', 1, undef,
            3, 6, 8, 9);

        $self->addLabel($table, 'Max objects to search:',
            6, 9, 8, 9);
        my $entry2 = $self->addEntryWithIcon($table, undef, 'int', 1, undef,
            9, 12, 8, 9);

        $self->addLabel($table, 'No. matches:',
            1, 3, 9, 10);
        my $entry3 = $self->addEntry($table, undef, FALSE,
            3, 6, 9, 10);
        $self->addLabel($table, 'Size of world model:',
            6, 9, 9, 10);
        my $entry4 = $self->addEntry($table, undef, FALSE,
            9, 12, 9, 10);

        # Set entry box initial values
        $entry->set_text($wmObj->searchMaxMatches);
        $entry2->set_text($wmObj->searchMaxObjects);
        $entry4->set_text($wmObj->modelActualCount);

        # Add some buttons
        my $button = $self->addButton(
            $table, 'Search model', 'Perform a world model search', undef,
            1, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            my ($matchMax, $objMax, $matchCount);

            if ($self->checkEntryIcon($entry)) {

                $matchMax = $entry->get_text();
                if ($matchMax > $wmObj->modelObjCount) {

                    # (Use the actual number of objects in the model)
                    $matchMax = $wmObj->modelObjCount;
                }

            } else {

                # (Use the actual number of objects in the model once again)
                $matchMax = $wmObj->modelObjCount;
            }

            if ($self->checkEntryIcon($entry2)) {

                $objMax = $entry2->get_text();
                if ($objMax > $wmObj->modelObjCount) {

                    $objMax = $wmObj->modelObjCount;
                }

            } else {

                $objMax = $wmObj->modelObjCount;
            }

            # Check that there's at least on entry in ->categoryHash (if it's empty, then no objects
            #   in the world model can match)
            if (! $self->categoryHash) {

                $self->showMsgDialogue(
                    'Search',
                    'error',
                    'You have unselected all categories of model object, so your search won\'t'
                    . ' match anything. (Go to the \'Search\' tab to select some categories.)',
                    'ok',
                );

            } elsif (! $wmObj->model) {

                $self->showMsgDialogue(
                    'Search',
                    'error',
                    'The world model is currently empty.',
                    'ok',
                );

            } else {

                # Perform the search, and display the results in the simple list
                # Change the label on the button so that, during long searches, the user can see
                #   when the search starts, and when it stops
                $button->set_label('Searching...');
                $matchCount = $self->performSearch($slWidget, $matchMax, $objMax);
                $button->set_label('Search');

                # Display the number of matches in the entry box
                $entry3->set_text($matchCount);
                # While we're at it, update the size of the world model
                $entry4->set_text($wmObj->modelActualCount);
            }
        });

        my $button2 = $self->addButton($table, 'Edit...', 'Edit the selected model object', undef,
            1, 3, 11, 12);
        $button2->signal_connect('clicked' => sub {

            my ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number && $wmObj->ivExists('modelHash', $number)) {

                # Open up an 'edit' window for the child object
                $self->openChildEditWin($number);
            }
        });

        my $button3 = $self->addButton(
            $table,
            'Clear',
            'Clear the list of world model objects',
            undef,
            10, 12, 11, 12,
        );
        $button3->signal_connect('clicked' => sub {

            # Empty the list
            @{$slWidget->{data}} = ();
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    # Support functions

    sub propertiesTab_checkRange {

        # Called by several parts of $self->propertiesTab_addEntryWithRange, in the
        #   ->signal_connect anonymous subroutine
        # Since it's not a trivally simple check (but the same for all four widgets created by the
        #   calling function), use the same function for each
        #
        # Expected arguments
        #   $iv             - The IV to add to the search - matches a key in $self->searchHash
        #   $checkButton    - The Gtk2::CheckButton
        #   $combo          - The Gtk2::ComboBox
        #   $entry, $entry2 - The two Gtk2::Entry boxes
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $iv, $checkButton, $combo, $entry, $entry2, $check) = @_;

        # Local variables
        my ($comboText, $entryText, $entryText2);

        # Check for improper arguments
        if (
            ! defined $iv || ! defined $checkButton || ! defined $combo || ! defined $entry
            || ! defined $entry2 || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->propertiesTab_checkRange',
                @_,
            );
        }

        $comboText = $combo->get_active_text();
        if ($self->checkEntryIcon($entry)) {

            $entryText = $entry->get_text();
        }

        if ($self->checkEntryIcon($entry2)) {

            $entryText2 = $entry2->get_text();
        }

        if ($checkButton->get_active() && $comboText) {

            if ($comboText ne 'min-max' && $entryText) {

                $self->ivAdd('searchHash', $iv, $entryText);
                $self->ivAdd('searchRangeHash', $iv, $comboText);
                $self->ivDelete('searchUpperHash', $iv);

            } elsif ($comboText eq 'min-max' && $self->checkEntryIcon($entry, $entry2)) {

                # Use the higher value as the maximum
                if ($entryText2 < $entryText) {

                    ($entryText2, $entryText) = ($entryText, $entryText2);
                }

                $self->ivAdd('searchHash', $iv, $entryText);
                $self->ivAdd('searchRangeHash', $iv, $comboText);
                $self->ivAdd('searchUpperHash', $iv, $entryText2);

            } else {

                $self->ivDelete('searchHash', $iv);
                $self->ivDelete('searchRangeHash', $iv);
                $self->ivDelete('searchUpperHash', $iv);
            }

        } else {

            $self->ivDelete('searchHash', $iv);
            $self->ivDelete('searchRangeHash', $iv);
            $self->ivDelete('searchUpperHash', $iv);
        }

        # $entry2 is only sensitive when the combo is set to 'min-max'
        if ($comboText eq 'min-max') {

            $entry2->set_sensitive(TRUE);

        } else {

            $entry2->set_text('');
            $entry2->set_sensitive(TRUE);
        }

        return 1;
    }

    sub performSearch {

        # Called by $self->resultsTab
        # Perform a search for world model objects matching the parameters specified by the user and
        #   stored (mainly) in $self->searchHash
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::List
        #   $matchMax       - The maximum number of matching model objects before the search
        #                       algorithm gives up
        #   $objMax         - The maximum number of model objects searched before the search
        #                       algorithm gives up
        #
        # Return values
        #   'undef' on improper arguments or if the search yields no matches
        #   Otherwise returns the number of matches

        my ($self, $slWidget, $matchMax, $objMax, $check) = @_;

        # Local variables
        my (
            $wmObj, $count, $regionmapObj, $regionmapNum,
            @objList, @matchList, @matchRoomList, @dataList, @mapWinList,
        );

#       (Error checking removed for speed)

#        # Check for improper arguments
#        if (! defined $slWidget || ! defined $matchMax || ! defined $objMax || defined $check) {
#
#             return $axmud::CLIENT->writeImproper($self->_objClass . '->performSearch', @_);
#        }

        # Import the world model
        $wmObj = $self->session->worldModelObj;

        if ($self->searchAllFlag) {

            # Start at model object #1, and continue until we reach the supplied limits (the calling
            #   function has already checked that these limits aren't larger than the model itself)
            $count = 0;
            do {

                my $obj;

                $count++;
                # (Don't use usual ->ivShow method for improved speed)
                $obj = $wmObj->{modelHash}{$count};

                # Check that the object's category, ->category, is one of the ones we want to
                #   search (in which case, it appears as a key in $self->categoryHash)
                if (defined $obj && exists $self->{'categoryHash'}{$obj->category}) {

                    # If the object matches our search terms, add it to the list of matches
                    if ($self->checkObj($obj)) {

                        push (@matchList, $obj);
                        if ($obj->category eq 'room') {

                            push (@matchRoomList, $obj, 'room');
                        }
                    }
                }

            } until ($count == $objMax || scalar @matchList == $matchMax);

        } else {

            # Compile a list of all model objects in the specified region, saving it as a hash
            #   in the form
            #       $hash{model_number} = blessed_reference_to_model_object

            # First, empty the hash after previous searches
            $self->ivEmpty('compileHash');

            # Find the model object for the region specified by $self->searchRegion, and use it
            #   as the first item in the hash
            $regionmapObj = $wmObj->ivShow('regionmapHash', $self->searchRegion);
            if (defined $regionmapObj) {

                $regionmapNum = $regionmapObj->number;
                $self->{'compileHash'}{$regionmapNum} = $wmObj->{'modelHash'}{$regionmapNum};

                # Compile a list of all model objects in the specified region, by calling
                #   ->compileObjHash recursively
                $self->compileObjHash($wmObj->{'modelHash'}{$regionmapNum});
            }

            # Sort the objects in the hash in order of model number

#           (Auto-deref is expected to be disabled in future version of Perl)
#           @objList = sort {$a->number <=> $b->number} (values $self->{'compileHash'});
            @objList = sort {$a->number <=> $b->number} ( values %{$self->{'compileHash'}} );

            # Perform the same search as above
            foreach my $obj (@objList) {

                if (exists $self->{'categoryHash'}{$obj->category}) {

                    # If the object matches our search terms, add it to the list of matches
                    if ($self->checkObj($obj)) {

                        push (@matchList, $obj);
                        if ($obj->category eq 'room') {

                            push (@matchRoomList, $obj, 'room');
                        }
                    }
                }
            }
        }

        # Display the list of objects in the simple list
        if (! @matchList) {

            # No matches were found
            $self->showMsgDialogue(
                'Search',
                'info',
                'No matching objects were found in the world model',
                'ok',
            );

        } else {

            # Update the simple list
            foreach my $obj (@matchList) {

                my $parentObj;

                if ($obj->parent) {

                    $parentObj = $wmObj->{'modelHash'}{$obj->parent};
                }

                if ($parentObj) {

                    push (@dataList,
                        $obj->number,
                        $obj->category,
                        $obj->name,
                        $parentObj->number,
                        $parentObj->category,
                        $parentObj->name,
                    );

                } else {

                    push (@dataList,
                        $obj->number,
                        $obj->category,
                        $obj->name,
                        undef,
                        undef,
                        undef,
                    );
                }
            }

            # Reset the simple list
            $self->resetListData($slWidget, [@dataList], 6);

            # If there were any matching rooms, and if the flag is set, tell the world model to
            #   select all matching rooms in Automapper windows
            #   select the rooms on the map
            if (@matchRoomList && $wmObj->searchSelectRoomsFlag) {

                # Get a list of Automapper windows using this world model
                @mapWinList = $wmObj->collectMapWins();
                foreach my $mapWin (@mapWinList) {

                    # Clear the previous selection(s)
                    $mapWin->setSelectedObj();

                    # Select the matching room(s)
                    $mapWin->setSelectedObj(\@matchRoomList, TRUE);
                }
            }
        }

        # Operation complete
        return scalar @matchList;
    }

    sub checkObj {

        # Called by $self->performSearch
        # Given the number of a world model object, checks whether its IVs match those specified by
        #   the IVs in $self->searchHash
        #
        # Expected arguments
        #   $obj    - Blessed reference of the model object to check
        #
        # Return values
        #   'undef' on improper arguments or if the object doesn't match IVs specified by
        #       $self->searchHash
        #   1 if the object matches

        my ($self, $obj, $check) = @_;

        # Local variables
        my $wmObj;

#       (Error checking removed for speed)

#        # Check for improper arguments
#        if (! defined $obj || defined $check) {
#
#            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkObj', @_);
#        }

        # Import the world model object
        $wmObj = $self->session->worldModelObj;

        # Check each IV in turn (for improved speed, we don't use ->ivKeys, etc)

#       (Auto-deref is expected to be disabled in future version of Perl)
#       OUTER: foreach my $iv (keys $self->{'searchHash'}) {
        OUTER: foreach my $iv ( keys %{$self->{'searchHash'}} ) {

            my ($search, $type, $ivCode, $rangeOp, $flag);

            # Get the value corresponding to the key $iv in the hash $self->searchHash
            $search = $self->{'searchHash'}{$iv};
            # Get the search type (e.g. 'match', 'key', 'special' etc)
            $type = $self->{'searchTypeHash'}{$iv};

            # Some settings of $iv begin with an underline; e.g. $iv can be set to both
            #   'visitHash' (when we want to check a key exists in the hash) and '_visitHash'
            #   (when we want to check the key doesn't exit)
            # By having both 'visitHash' and '_visitHash', we can perform two different operation on
            #   the same IV (i.e. there can be two entries in the hash $self->searchHash, not one
            #   which potentially overwrites another)
            $ivCode = $iv;      # Might begin with an underline
            $iv =~ s/_//;       # Does not begin with an underline

            # Some IVs exist in one category of model object, but not in other categories. We need
            #   to check that the IV actually exists
            if (! exists $obj->{$iv}) {

                # Can't be a match if the IV isn't used in this category of model object
                return undef;

            } elsif ($type eq 'match') {

                # Perform a regex on the scalar IV's value, to see whether it matches the
                #   user-specified value in $search (NB The search is case-insensitive)
                if (! defined $obj->$iv || ! ($obj->$iv =~ m/$search/i)) {

                    # This object doesn't match
                    return undef;
                }

            } elsif ($type eq 'flag') {

                # Check whether the scalar IV, which is a flag, matches the user-specified value in
                #   $search (i.e. either 'on' or 'off')
                if (($obj->$iv && ! $search) || (! $obj->$iv && $search)) {

                    return undef;
                }

            } elsif ($type eq 'string_equal') {

                # Check whether the scalar IV's value is an exact match for the value of $search
                if ($obj->$iv ne $search) {

                    return undef;
                }

            } elsif ($type eq 'range') {

                # Get the range operator specified by the user
                $rangeOp = $self->{'searchRangeHash'}{$ivCode};

                if (
                    ! defined $obj->$iv
                    || ($rangeOp eq '==' && $obj->$iv != $search)
                    || ($rangeOp eq '>' && $obj->$iv <= $search)
                    || ($rangeOp eq '>=' && $obj->$iv < $search)
                    || ($rangeOp eq '<' && $obj->$iv >= $search)
                    || ($rangeOp eq '<=' && $obj->$iv > $search)
                    # Min/max: minimum value stored in $search, maximum value stored in
                    #   $self->searchUpperHash)
                    || (
                        $rangeOp eq 'min-max'
                        && ($obj->$iv < $search || $obj->$iv > $self->{'searchUpperHash'}{$ivCode})
                    )
                ) {
                    return undef;
                }


            } elsif ($type eq 'include') {

                # Check whether the list IV includes an element which is an exact match for the
                #   value of $search
                INNER: foreach my $element ($obj->$iv) {

                    if ($element eq $search) {

                        $flag = TRUE;
                        last INNER;
                    }
                }

                if (! $flag) {

                    return undef;
                }

            } elsif ($type eq 'list_match') {

                # Perform a regex on every element in a list IV, to see whether it matches the value
                #   of $search
                INNER: foreach my $element ($obj->$iv) {

                    if ($element =~ m/$search/i) {

                        $flag = TRUE;
                        last INNER;
                    }
                }

                if (! $flag) {

                    return undef;
                }

            } elsif ($type eq 'key') {

                # Check whether the hash IV contains a key which is an exact match for the value of
                #   $search
                if (! exists $obj->{$iv}{$search}) {

                    return undef;
                }

            } elsif ($type eq 'not_key') {

                # Check whether the hash IV does NOT contain a key which is an exact match for the
                #   value of $search
                if (exists $obj->{$iv}{$search}) {

                    return undef;
                }

            } elsif ($type eq 'used_hash') {

                # Check whether the hash IV contains at least one key
                if (
                    ($obj->$iv && ! $search)
                    || (! $obj->$iv && $search)
                ) {
                    return undef;
                }

            } elsif ($type eq 'value_match') {

                # Perform a regex on all of the values in the hash IV, hoping to find one that
                #   matches $search

#               (Auto-deref is expected to be disabled in future version of Perl)
#               INNER: foreach my $value (values $obj->{$iv}) {
                INNER: foreach my $value ( values %{$obj->{$iv}} ) {

                    if ($value =~ m/$search/i) {

                        $flag = TRUE;
                        last INNER;
                    }
                }

                if (! $flag) {

                    return undef;
                }

            } elsif ($type eq 'special') {

                if ($ivCode eq '_hiddenObjHash') {

                    # $obj->hiddenObjHash is in the form
                    #   hash{unique_number_of_hidden_object} = 'commands_to_obtain_it'
                    # Check whether the any of the objects stored in this hash have a ->name
                    #   matching $search

#                   (Auto-deref is expected to be disabled in future version of Perl)
#                   INNER: foreach my $number (keys $obj->{$iv}) {
                    INNER: foreach my $number ( keys %{$obj->{$iv}} ) {

                        my $obj = $wmObj->{'modelHash'}{$number};

                        if (defined $obj && ($obj->name =~ m/$search/i)) {

                            $flag = TRUE;
                            last INNER;
                        }
                    }

                    if (! $flag) {

                        return undef;
                    }

                } elsif ($ivCode eq 'type') {

                    # We are checking a portable object's type - we must check that it's not a
                    #   decoration
                    if ($obj->category ne 'portable' || $obj->$iv ne $search) {

                        return undef;
                    }

                } elsif ($ivCode eq '_type') {

                    # We are checking a decoration object's type - we must check that it's not a
                    #   decoration
                    if ($obj->category ne 'decoration' || $obj->$iv ne $search) {

                        return undef;
                    }

#               Error checking removed for speed
#               } else {
#
#                   return $self->writeError(
#                       'Search error: unrecognised ivCode \'' . $ivCode . '\'',
#                       $self->_objClass . '->new',
#                   );
                }

#           Error checking removed for speed
#           } else {
#
#               return $self->session->writeError(
#                   'Search error: unrecognised type \'' . $type . '\'',
#                   $self->_objClass . '->new',
#               );
            }
        }

        # The world model object $obj is a match
        return 1;
    }

    sub compileObjHash {

        # Called by $self->performSearch when $self->searchAllFlag is not set, and by this function
        #   recursively
        # Given a world model object which already exists as a key-value pair in $self->compileHash,
        #   add all of its child objects to the same hash, and then call this function recursively
        #   for each of those objects
        #
        # Expected arguments
        #   $obj        - Blessed reference to a model object
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $obj, $check) = @_;

#       (Error checking removed for speed)

#        # Check for improper arguments
#        if (! defined $obj || defined $check) {
#
#            return $axmud::CLIENT->writeImproper($self->_objClass . '->compileObjHash', @_);
#        }

        # (For improved speed, don't use ->ivValues, etc)

#       (Auto-deref is expected to be disabled in future version of Perl)
#       foreach my $childObj (values $obj->{childHash}) {
        foreach my $childObj ( values %{$obj->{childHash}} ) {

            # Add the child object to the main hash
            $self->{compileHash}{$childObj->number} = $childObj;
            # Call this function recursively to add its children, too
            $self->compileObjHash($childObj);
        }

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub searchAllFlag
        { $_[0]->{searchAllFlag} }
    sub searchRegion
        { $_[0]->{searchRegion} }

    sub categoryHash
        { my $self = shift; return %{$self->{categoryHash}}; }

    sub searchHash
        { my $self = shift; return %{$self->{searchHash}}; }
    sub searchRangeHash
        { my $self = shift; return %{$self->{searchRangeHash}}; }
    sub searchUpperHash
        { my $self = shift; return %{$self->{searchUpperHash}}; }
    sub searchTypeHash
        { my $self = shift; return %{$self->{searchTypeHash}}; }

    sub compileHash
        { my $self = shift; return %{$self->{compileHash}}; }
}

{ package Games::Axmud::PrefWin::Session;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::EditWin Games::Axmud::Generic::ConfigWin
        Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win Games::Axmud
    );

    ##################
    # Constructors

    # Contents of $self->editConfigHash after $self->new has been called:
    #   (none)

#   sub new {}                  # Inherited from GA::Generic::ConfigWin

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}             # Inherited from GA::Generic::ConfigWin

#   sub winEnable {}            # Inherited from GA::Generic::ConfigWin

#   sub winDesengage {}         # Inherited from GA::Generic::FreeWin

#   sub winDestroy {}           # Inherited from GA::Generic::FreeWin

#   sub winShowAll {}           # Inherited from GA::Generic::Win

#   sub drawWidgets {}          # Inherited from GA::Generic::ConfigWin

#   sub redrawWidgets {}        # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

#   sub checkEditObj {}         # Inherited from GA::Generic::ConfigWin

    sub enableButtons {

        # Called by $self->drawWidgets
        # We only need a single button so, instead of calling the generic ->enableButtons, call a
        #   method that creates just one button
        #
        # Expected arguments
        #   $hBox       - The horizontal packing box in which the buttons live (not yet stored as
        #                   an IV)
        #   $tooltips   - A Gtk2::Tooltips object for the buttons (not yet stored as an IV)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, a list containing the Gtk::Button object created

        my ($self, $hBox, $tooltips, $check) = @_;

        # Local variables
        my @emptyList;

        # Check for improper arguments
        if (! defined $hBox || ! defined $tooltips || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->enableButtons', @_);
            return @emptyList;
        }

        return $self->enableSingleButton($hBox, $tooltips);
    }

#   sub enableSingleButton {}   # Inherited from GA::Generic::ConfigWin

    sub setupNotebook {

        # Called by $self->enable
        # Creates the first tab for the notebook. The remaining tabs are created by
        #   $self->expandNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setupNotebook', @_);
        }

#       # Tab setup
#       my ($vBox, $table) = $self->addTab('_Session', $self->notebook);

        # Set up the rest of the first tab (all of it, in this case)
        $self->sessionTab();

        # Set up the remaining tabs
        $self->expandNotebook();

#       # Tab complete
#       $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub expandNotebook {

        # Called by $self->setupNotebook
        # Set up additional tabs for the notebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->expandNotebook', @_);
        }

        $self->interfacesTab();
        $self->tasksTab();
        $self->recordingTab();
        $self->protocolsTab();
        $self->msdpTab();
        $self->msspTab();
        $self->mxpTab();
        $self->atcpTab();
        $self->gmcpTab();

        return 1;
    }

#   sub saveChanges {}          # Inherited from GA::Generic::ConfigWin

    # Notebook tabs

    sub sessionTab {

        # Session tab - called by $self->setupNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->sessionTab', @_);
        }

        # Tab setup
        # Create a notebook within the main one, so that we have two rows of tabs
        my ($vBox, $innerNotebook) = $self->addInnerNotebookTab('_Session', $self->notebook);

        # Add tabs to the inner notebook
        $self->session1Tab($innerNotebook);
        $self->session2Tab($innerNotebook);
        $self->session3Tab($innerNotebook);
        $self->session4Tab($innerNotebook);

        return 1;
    }

    sub session1Tab {

        # Session1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->session1Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _1', $innerNotebook);

        # Left column
        $self->addLabel($table, '<b>Session settings</b>',
            0, 6, 0, 1);

        $self->addLabel($table, 'Session number',
            1, 3, 1, 2);
        my $entry = $self->addEntry($table, undef, FALSE,
            3, 6, 1, 2);

        $self->addLabel($table, 'Session start complete',
            1, 5, 2, 3);
        my $checkButton = $self->addCheckButton($table, undef, FALSE,
            5, 6, 2, 3);

        $self->addLabel($table, 'Automatic login complete',
            1, 5, 3, 4);
        my $checkButton2 = $self->addCheckButton($table, undef, FALSE,
            5, 6, 3, 4);

        $self->addLabel($table, 'Client (system) time (secs)',
            1, 3, 4, 5);
        my $entry2 = $self->addEntry($table, undef, FALSE,
            3, 6, 4, 5);

        $self->addLabel($table, 'Session time (secs)',
            1, 3, 5, 6);
        my $entry3 = $self->addEntry($table, undef, FALSE,
            3, 6, 5, 6);

        $self->addLabel($table, 'Delayed quit',
            1, 3, 6, 7);
        my $entry4 = $self->addEntry($table, undef, FALSE,
            3, 6, 6, 7);

        $self->addLabel($table, 'Current character set',
            1, 3, 7, 8);
        my $entry5 = $self->addEntry($table, undef, FALSE,
            3, 6, 7, 8);

        $self->addLabel($table, '<b>Current connection</b>',
            0, 6, 8, 9);

        $self->addLabel($table, 'Host',
            1, 3, 9, 10);
        my $entry6 = $self->addEntry($table, undef, FALSE,
            3, 6, 9, 10);

        $self->addLabel($table, 'Protocol',
            1, 3, 10, 11);
        my $entry7 = $self->addEntry($table, undef, FALSE,
            3, 6, 10, 11);

        # Right column
        my $button = $self->addButton($table, 'Update', 'Update the displayed data', undef,
            10, 12, 0, 1);
        # (->signal_connect appears below)

        $self->addLabel($table, 'Current world',
            7, 9, 1, 2);
        my $entry8 = $self->addEntry($table, undef, FALSE,
            9, 12, 1, 2);

        $self->addLabel($table, 'Current guild',
            7, 9, 2, 3);
        my $entry9 = $self->addEntry($table, undef, FALSE,
            9, 12, 2, 3);

        $self->addLabel($table, 'Current race',
            7, 9, 3, 4);
        my $entry10 = $self->addEntry($table, undef, FALSE,
            9, 12, 3, 4);

        $self->addLabel($table, 'Current character',
            7, 9, 4, 5);
        my $entry11 = $self->addEntry($table, undef, FALSE,
            9, 12, 4, 5);

        $self->addLabel($table, 'Current dictionary',
            7, 9, 5, 6);
        my $entry12 = $self->addEntry($table, undef, FALSE,
            9, 12, 5, 6);

        $self->addLabel($table, 'Current mission',
            7, 9, 6, 7);
        my $entry13 = $self->addEntry($table, undef, FALSE,
            9, 12, 6, 7);

        $self->addLabel($table, 'Port',
            7, 9, 9, 10);
        my $entry14 = $self->addEntry($table, undef, FALSE,
            9, 12, 9, 10);

        $self->addLabel($table, 'Connection status',
            7, 9, 10, 11);
        my $entry15 = $self->addEntry($table, undef, FALSE,
            9, 12, 10, 11);

        # ->signal_connects
        $button->signal_connect('clicked' => sub {

            $checkButton->set_active($self->session->startCompleteFlag);
            $checkButton2->set_active($self->session->loginFlag);

            $entry->set_text($self->session->number);
            $entry2->set_text($axmud::CLIENT->clientTime);
            $entry3->set_text($self->session->sessionTime);

            if (defined $self->session->delayedQuitTime) {

                $entry4->set_text(
                    $axmud::CLIENT->clientSigil . $self->session->delayedQuitCmd . ' at '
                    . $self->session->delayedQuitTime,
                );

            } else {

                $entry4->set_text('');
            }

            $entry5->set_text($self->session->sessionCharSet);

            if ($self->session->host) {
                $entry6->set_text($self->session->host);
            } else {
                $entry6->set_text('(none)');
            }

            if ($self->session->protocol) {
                $entry7->set_text($self->session->protocol);
            } else {
                $entry7->set_text('(none)');
            }

            if ($self->session->currentWorld) {
                $entry8->set_text($self->session->currentWorld->name);
            } else {
                $entry8->set_text('(none)');
            }

            if ($self->session->currentGuild) {
                $entry9->set_text($self->session->currentGuild->name);
            } else {
                $entry9->set_text('(none)');
            }

            if ($self->session->currentRace) {
                $entry10->set_text($self->session->currentRace->name);
            } else {
                $entry10->set_text('(none)');
            }

            if ($self->session->currentChar) {
                $entry11->set_text($self->session->currentChar->name);
            } else {
                $entry11->set_text('(none)');
            }

            $entry12->set_text($self->session->currentDict->name);

            if ($self->session->currentMission) {
                $entry13->set_text($self->session->currentMission->name);
            } else {
                $entry13->set_text('(none)');
            }

            if ($self->session->port) {
                $entry14->set_text($self->session->port);
            } else {
                $entry14->set_text('(none)');
            }

            $entry15->set_text($self->session->status);
        });

        # Pseudo-click the button to set all the widgets
        $button->clicked();

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub session2Tab {

        # Session2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->session2Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _2', $innerNotebook);

        # Session file objects
        $self->addLabel($table, '<b>Session file objects</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>List of data files currently in use by this session</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Not saved', 'bool',
            'File type', 'text',
            'File name', 'text',
            'Path', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 230);       # Fixed height

        # Add more widgets (displayed values set by the call to $self->session2Tab_refreshList)
        $self->addLabel($table, 'No saving on disconnection',
            1, 3, 10, 11);
        my $checkButton = $self->addCheckButton($table, undef, FALSE,
            3, 4, 10, 11);

        $self->addLabel($table, 'Next autosave time',
            4, 6, 10, 11);
        my $entry = $self->addEntry($table, undef, FALSE,
            6, 8, 10, 11, 8, 8);

        $self->addLabel($table, 'Previous autosave time',
            8, 10, 10, 11);
        my $entry2 = $self->addEntry($table, undef, FALSE,
            10, 12, 10, 11, 8, 8);

        my $button = $self->addButton($table,
            'Save', 'Save all files whose data has been modified', undef,
            1, 3, 11, 12);
        $button->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('save', $self->pseudoCmdMode);

            # Refresh the simple list
            $self->session2Tab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                $checkButton,
                $entry,
                $entry2,
            );
        });

        my $button2 = $self->addButton($table,
            'Force save', 'Save all files, even if their data has not been modified', undef,
            3, 6, 11, 12);
        $button2->signal_connect('clicked' => sub {

            $self->session->pseudoCmd('save -f', $self->pseudoCmdMode);

            # Refresh the simple list
            $self->session2Tab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                $checkButton,
                $entry,
                $entry2,
            );
        });

        my $button3 = $self->addButton($table,
            'Refresh list', 'Refresh the list of file objects', undef,
            9, 12, 11, 12);
        $button3->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->session2Tab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                $checkButton,
                $entry,
                $entry2,
            );
        });

        # We can now initialise the widgets
        $self->session2Tab_refreshList(
            $slWidget,
            scalar (@columnList / 2),
            $checkButton,
            $entry,
            $entry2,
        );

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub session2Tab_refreshList {

        # Resets the simple list displayed by $self->session2Tab
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #   $checkButton, $entry, $entry2
        #                   - Three widgets whose values should be refreshed at the same time
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $checkButton, $entry, $entry2, $check) = @_;

        # Local variables
        my (@fileList, @dataList);

        # Check for improper arguments
        if (
            ! defined $slWidget || ! defined $columns || ! defined $checkButton
            || ! defined $entry || ! defined $entry2 || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->session2Tab_refreshList',
                @_,
            );
        }

        # Get a sorted list of file objects
        @fileList = sort {lc($a->name) cmp lc($b->name)}
                        ($self->session->ivValues('sessionFileObjHash'));

        # Compile the simple list data
        foreach my $obj (@fileList) {

            push (@dataList,
                $obj->modifyFlag,
                $obj->fileType,
                $obj->name,
                $obj->actualPath,
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        # Refresh the other widgets
        $checkButton->set_active($self->session->disconnectNoSaveFlag);
        $entry->set_text($self->session->autoSaveCheckTime);
        $entry2->set_text($self->session->autoSaveLastTime);

        return 1;
    }

    sub session3Tab {

        # Session3 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;


        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->session3Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _3', $innerNotebook);

        # Left column
        $self->addLabel($table, '<b>Session buffer settings (1/2)</b>',
            0, 12, 0, 1);

        $self->addLabel($table, '<i>Display buffer</i>',
            1, 12, 1, 2);

        $self->addLabel($table, 'Max size',
            1, 3, 2, 3);
        my $entry = $self->addEntry($table, undef, FALSE,
            3, 6, 2, 3);

        $self->addLabel($table, 'Current size',
            1, 3, 3, 4);
        my $entry2 = $self->addEntry($table, undef, FALSE,
            3, 6, 3, 4);

        $self->addLabel($table, 'Total lines received',
            1, 3, 4, 5);
        my $entry3 = $self->addEntry($table, undef, FALSE,
            3, 6, 4, 5);

        $self->addLabel($table, 'Line number',
            1, 3, 5, 6);
        my $entry4 = $self->addEntryWithIcon($table, undef, 'int', 0, undef,
            3, 6, 5, 6);

        # Right column
        my $button = $self->addButton($table,
            'Update', 'Update the displayed data', undef,
            9, 12, 0, 1);

        $self->addLabel($table, 'First line #',
            7, 9, 2, 3);
        my $entry5 = $self->addEntry($table, undef, FALSE,
            9, 12, 2, 3);

        $self->addLabel($table, 'Last line #',
            7, 9, 3, 4);
        my $entry6 = $self->addEntry($table, undef, FALSE,
            9, 12, 3, 4);

        $self->addLabel($table, 'Since last line (secs)',
            7, 9, 4, 5);
        my $entry7 = $self->addEntry($table, undef, FALSE,
            9, 12, 4, 5);

        my $button2 = $self->addButton($table,
            'View', 'View the specified buffer line', undef,
            7, 8, 5, 6);

        my $button3 = $self->addButton($table,
            'Dump', 'Display the specified buffer line in the \'main\' window', undef,
            8, 9, 5, 6);

        my $button4 = $self->addButton($table,
            'Dump last', 'Display the most recent buffer line in the \'main\' window', undef,
            9, 11, 5, 6);

        my $button5 = $self->addButton($table,
            'Dump 20', 'Display the most recent 20 buffer lines in the \'main\' window', undef,
            11, 12, 5, 6);

        # ->signal_connects

        # 'Update'
        $button->signal_connect('clicked' => sub {

            $entry->set_text($axmud::CLIENT->customDisplayBufferSize);
            $entry2->set_text($self->session->ivPairs('displayBufferHash'));
            $entry3->set_text($self->session->displayBufferCount);

            if (defined $self->session->displayBufferFirst) {

                $entry5->set_text($self->session->displayBufferFirst);
            }

            if (defined $self->session->displayBufferLast) {

                $entry6->set_text($self->session->displayBufferLast);
            }

            if (defined $self->session->lastDisplayTime) {

                $entry7->set_text($self->session->sessionTime - $self->session->lastDisplayTime);
            }
        });

        # 'View'
        $button2->signal_connect('clicked' => sub {

            my $number = $entry4->get_text();

            if ($self->checkEntryIcon($entry4)) {

                # Open an 'edit' window for the specified buffer line
                $self->session->pseudoCmd('editdisplaybuffer ' . $number, $self->pseudoCmdMode);
            }
        });

        # 'Dump'
        $button3->signal_connect('clicked' => sub {

            my $number = $entry4->get_text();

            if ($self->checkEntryIcon($entry4)) {

                # Display the specified buffer line
                $self->session->pseudoCmd('dumpdisplaybuffer ' . $number, $self->pseudoCmdMode);
            }
        });

        # 'Dump last'
        $button4->signal_connect('clicked' => sub {

            # Display most recent buffer line
            $self->session->pseudoCmd('dumpdisplaybuffer', $self->pseudoCmdMode);
            # Show the number of the most recent buffer line
            if (defined $self->session->displayBufferLast) {

                $entry4->set_text($self->session->displayBufferLast);
            }
        });

        # 'Dump 20'
        $button5->signal_connect('clicked' => sub {

            my ($start, $stop);

            $stop = $self->session->displayBufferLast;
            $start = $stop - 19;
            if ($start < 0) {

                $start = 0;
            }

            # Display most recent buffer lines
            $self->session->pseudoCmd(
                'dumpdisplaybuffer ' . $start . ' ' . $stop,
                $self->pseudoCmdMode,
            );
        });

        # Pseudo-click the button to set all the widgets
        $button->clicked();

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub session4Tab {

        # Session4 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;


        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->session4Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _4', $innerNotebook);

        # Session buffer settings
        $self->addLabel($table, '<b>Session buffer settings (2/2)</b>',
            0, 12, 0, 1);

        # Left column - instruction buffer
        $self->addLabel($table, '<i>Instruction buffer</i>',
            1, 12, 1, 2);

        $self->addLabel($table, 'Max size',
            1, 3, 2, 3);
        my $entry = $self->addEntry($table, undef, FALSE,
            3, 6, 2, 3);

        $self->addLabel($table, 'Current size',
            1, 3, 3, 4);
        my $entry2 = $self->addEntry($table, undef, FALSE,
            3, 6, 3, 4);

        $self->addLabel($table, 'Total items processed',
            1, 3, 4, 5);
        my $entry3 = $self->addEntry($table, undef, FALSE,
            3, 6, 4, 5);

        $self->addLabel($table, 'Item number',
            1, 3, 5, 6);
        my $entry4 = $self->addEntryWithIcon($table, undef, 'int', 0, undef,
            3, 6, 5, 6);

        # Right column - instruction buffer
        my $button = $self->addButton($table,
            'Update', 'Update the displayed data', undef,
            9, 12, 0, 1);

        $self->addLabel($table, 'First item #',
            7, 9, 2, 3);
        my $entry5 = $self->addEntry($table, undef, FALSE,
            9, 12, 2, 3);

        $self->addLabel($table, 'Last item #',
            7, 9, 3, 4);
        my $entry6 = $self->addEntry($table, undef, FALSE,
            9, 12, 3, 4);

        $self->addLabel($table, 'Since last item (secs)',
            7, 9, 4, 5);
        my $entry7 = $self->addEntry($table, undef, FALSE,
            9, 12, 4, 5);

        my $button2 = $self->addButton($table,
            'View', 'View the specified buffer item', undef,
            7, 8, 5, 6);

        my $button3 = $self->addButton($table,
            'Dump', 'Display the specified buffer item in the \'main\' window', undef,
            8, 9, 5, 6);

        my $button4 = $self->addButton($table,
            'Dump last', 'Display the most recent buffer item in the \'main\' window', undef,
            9, 11, 5, 6);

        my $button5 = $self->addButton($table,
            'Dump 20', 'Display the most recent 20 buffer items in the \'main\' window', undef,
            11, 12, 5, 6);

        # Left column - world command buffer
        $self->addLabel($table, '<i>World command buffer</i>',
            1, 12, 6, 7);

        $self->addLabel($table, 'Max size',
            1, 3, 7, 8);
        my $entry8 = $self->addEntry($table, undef, FALSE,
            3, 6, 7, 8);

        $self->addLabel($table, 'Current size',
            1, 3, 8, 9);
        my $entry9 = $self->addEntry($table, undef, FALSE,
            3, 6, 8, 9);

        $self->addLabel($table, 'Total items processed',
            1, 3, 9, 10);
        my $entry10 = $self->addEntry($table, undef, FALSE,
            3, 6, 9, 10);

        $self->addLabel($table, 'Item number',
            1, 3, 10, 11);
        my $entry11 = $self->addEntryWithIcon($table, undef, 'int', 0, undef,
            3, 6, 10, 11);

        # Right column - world command buffer
        $self->addLabel($table, 'First item #',
            7, 9, 7, 8);
        my $entry12 = $self->addEntry($table, undef, FALSE,
            9, 12, 7, 8);

        $self->addLabel($table, 'Last item #',
            7, 9, 8, 9);
        my $entry13 = $self->addEntry($table, undef, FALSE,
            9, 12, 8, 9);

        $self->addLabel($table, 'Since last item (secs)',
            7, 9, 9, 10);
        my $entry14 = $self->addEntry($table, undef, FALSE,
            9, 12, 9, 10);

        my $button6 = $self->addButton($table,
            'View', 'View the specified buffer item', undef,
            7, 8, 10, 11);

        my $button7 = $self->addButton($table,
            'Dump', 'Display the specified buffer item in the \'main\' window', undef,
            8, 9, 10, 11);

        my $button8 = $self->addButton($table,
            'Dump last', 'Display the most recent buffer item in the \'main\' window', undef,
            9, 11, 10, 11);

        my $button9 = $self->addButton($table,
            'Dump 20', 'Display the most recent 20 buffer items in the \'main\' window', undef,
            11, 12, 10, 11);

        # ->signal_connects

        # 'Update'
        $button->signal_connect('clicked' => sub {

            # Instruction buffer
            $entry->set_text($axmud::CLIENT->customInstructBufferSize);
            $entry2->set_text($self->session->ivPairs('instructBufferHash'));
            $entry3->set_text($self->session->instructBufferCount);

            if (defined $self->session->instructBufferFirst) {

                $entry5->set_text($self->session->instructBufferFirst);
            }

            if (defined $self->session->instructBufferLast) {

                $entry6->set_text($self->session->instructBufferLast);
            }

            if (defined $self->session->lastInstructTime) {

                $entry7->set_text($self->session->sessionTime - $self->session->lastInstructTime);
            }

            # World command buffer
            $entry8->set_text($axmud::CLIENT->customCmdBufferSize);
            $entry9->set_text($self->session->ivPairs('cmdBufferHash'));
            $entry10->set_text($self->session->cmdBufferCount);

            if (defined $self->session->cmdBufferFirst) {

                $entry12->set_text($self->session->cmdBufferFirst);
            }

            if (defined $self->session->cmdBufferLast) {

                $entry13->set_text($self->session->cmdBufferLast);
            }

            if (defined $self->session->lastCmdTime) {

                $entry14->set_text($self->session->sessionTime - $self->session->lastCmdTime);
            }
        });

        # 'View'
        $button2->signal_connect('clicked' => sub {

            my $number = $entry4->get_text();

            if ($self->checkEntryIcon($entry4)) {

                # Open an 'edit' window for the specified buffer item
                $self->session->pseudoCmd(
                    'editinstructionbuffer -s ' . $number,
                    $self->pseudoCmdMode,
                );
            }
        });

        # 'Dump'
        $button3->signal_connect('clicked' => sub {

            my $number = $entry4->get_text();

            if ($self->checkEntryIcon($entry4)) {

                # Display the specified buffer item
                $self->session->pseudoCmd(
                    'dumpinstructionbuffer -s ' . $number,
                    $self->pseudoCmdMode,
                );
            }
        });

        # 'Dump last'
        $button4->signal_connect('clicked' => sub {

            # Display most recent buffer item
            $self->session->pseudoCmd('dumpinstructionbuffer -s', $self->pseudoCmdMode);
            # Show the number of the most recent buffer item
            if (defined $self->session->instructBufferLast) {

                $entry4->set_text($self->session->instructBufferLast);
            }
        });

        # 'Dump 20'
        $button5->signal_connect('clicked' => sub {

            my ($start, $stop);

            $stop = $self->session->instructBufferLast;
            $start = $stop - 19;
            if ($start < 0) {

                $start = 0;
            }

            # Display most recent buffer items
            $self->session->pseudoCmd(
                'dumpinstructionbuffer ' . $start . ' ' . $stop,
                $self->pseudoCmdMode,
            );
        });

        # 'View'
        $button6->signal_connect('clicked' => sub {

            my $number = $entry11->get_text();

            if ($self->checkEntryIcon($entry11)) {

                # Open an 'edit' window for the specified buffer item
                $self->session->pseudoCmd('editcommandbuffer -s ' . $number, $self->pseudoCmdMode);
            }
        });

        # 'Dump'
        $button7->signal_connect('clicked' => sub {

            my $number = $entry11->get_text();

            if ($self->checkEntryIcon($entry11)) {

                # Display the specified buffer item
                $self->session->pseudoCmd('dumpcommandbuffer -s ' . $number, $self->pseudoCmdMode);
            }
        });

        # 'Dump last'
        $button8->signal_connect('clicked' => sub {

            # Display most recent buffer item
            $self->session->pseudoCmd('dumpcommandbuffer -s', $self->pseudoCmdMode);
            # Show the number of the most recent buffer item
            if (defined $self->session->cmdBufferLast) {

                $entry11->set_text($self->session->cmdBufferLast);
            }
        });

        # 'Dump 20'
        $button9->signal_connect('clicked' => sub {

            my ($start, $stop);

            $stop = $self->session->cmdBufferLast;
            $start = $stop - 19;
            if ($start < 0) {

                $start = 0;
            }

            # Display most recent buffer items
            $self->session->pseudoCmd(
                'dumpcommandbuffer ' . $start . ' ' . $stop,
                $self->pseudoCmdMode,
            );
        });

        # Pseudo-click the button to set all the widgets
        $button->clicked();

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub interfacesTab {

        # Interfaces tab - called by $self->setupNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->interfacesTab', @_);
        }

        # Tab setup
        # Create a notebook within the main one, so that we have two rows of tabs
        my ($vBox, $innerNotebook) = $self->addInnerNotebookTab('_Interfaces', $self->notebook);

        # Add tabs to the inner notebook
        $self->interfaces1Tab($innerNotebook);
        $self->interfaces2Tab($innerNotebook, 'trigger', 2);
        $self->interfaces2Tab($innerNotebook, 'alias', 3);
        $self->interfaces2Tab($innerNotebook, 'macro', 4);
        $self->interfaces2Tab($innerNotebook, 'timer', 5);
        $self->interfaces2Tab($innerNotebook, 'hook', 6);

        return 1;
    }

    sub interfaces1Tab {

        # Interfaces1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my (
            $listType,
            @columnList, @list, @comboList, $title,
            %comboHash,
        );

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->interfaces1Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _1', $innerNotebook);

        # Left column
        $self->addLabel($table, '<b>Active interfaces</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>List of interfaces which are currently active</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            '#', 'int',
            'Name', 'text',
            'Category', 'text',
            'Indep', 'bool',
            'Enabled', 'bool',
            'Associated profile', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 230);       # Fixed height

        # Initialise the list
        $listType = 'all';
        $self->interfacesTab_refreshList($slWidget, scalar (@columnList / 2), $listType);

        # Add buttons and combos
        my $button = $self->addButton($table,
            'Enable', 'Enable the selected active interface', undef,
            1, 3, 10, 11);
        $button->signal_connect('clicked' => sub {

            my ($name) = $self->getSimpleListData($slWidget, 1);
            if (defined $name) {

                # Enable the active interface
                $self->session->pseudoCmd('enableactiveinterface ' . $name, $self->pseudoCmdMode);
                # Refresh the simple list
                $self->interfacesTab_refreshList($slWidget, scalar (@columnList / 2), $listType);
            }
        });

        my $button2 = $self->addButton($table,
            'Disable', 'Disable the selected active interface', undef,
            3, 5, 10, 11);
        $button2->signal_connect('clicked' => sub {

            my ($name) = $self->getSimpleListData($slWidget, 1);
            if (defined $name) {

                # Disable the active interface
                $self->session->pseudoCmd('disableactiveinterface ' . $name, $self->pseudoCmdMode);
                # Refresh the simple list
                $self->interfacesTab_refreshList($slWidget, scalar (@columnList / 2), $listType);
            }
        });

        my $button3 = $self->addButton($table,
            'Edit', 'Edit the selected active interface', undef,
            5, 7, 10, 11);
        $button3->signal_connect('clicked' => sub {

            my ($number, $interfaceObj);

            ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                $interfaceObj = $self->session->ivShow('interfaceNumHash', $number);
                if ($interfaceObj) {

                    # Open up an 'edit' window to edit the object
                    $self->createFreeWin(
                        'Games::Axmud::EditWin::Interface::Active',
                        $self,
                        $self->session,
                        'Edit active ' . $interfaceObj->category . ' interface \''
                        . $interfaceObj->name . '\'',
                        $interfaceObj,
                        FALSE,                          # Not temporary
                    );
                }

                # Refresh the simple list
                $self->interfacesTab_refreshList($slWidget, scalar (@columnList / 2), $listType);
            }
        });

        # Prepare a list of combo items. The keys are the combo items themselves, the corresponding
        #   values are arguments to send to $self->interfacesTab_refreshList
        @list = (
            'Numerically'       => 'all',
            'Alphabetically'    => 'alpha',
            'Dependent only'    => 'dependent',
            'Independent only'  => 'independent',
            'Triggers only'     => 'trigger',
            'Aliases only'      => 'alias',
            'Macros only'       => 'macro',
            'Timers only'       => 'timer',
            'Hooks only'        => 'hook',
        );

        do {

            my $key = shift @list;
            my $value = shift @list;

            push (@comboList, $key);
            $comboHash{$key} = $value;

        } until (! @list);

        # Add the combo
        $title = 'View interfaces:';
        my $comboBox = $self->addComboBox($table, undef, \@comboList, $title,
            FALSE,          # Title, so no 'undef' value seen
            9, 12, 10, 11);
        $comboBox->signal_connect('changed' => sub {

            my $text = $comboBox->get_active_text();

            if ($text ne $title) {

                # Refresh the simple list
                $listType = $comboHash{$text};
                $self->interfacesTab_refreshList($slWidget, scalar (@columnList / 2), $listType);
            }
        });

        my $button4 = $self->addButton($table,
            'Enable all', 'Enable all active interfaces', undef,
            1, 4, 11, 12);
        $button4->signal_connect('clicked' => sub {

            # Enable all active interfaces
            $self->session->pseudoCmd('enableactiveinterface', $self->pseudoCmdMode);
            # Refresh the simple list
            $self->interfacesTab_refreshList($slWidget, scalar (@columnList / 2), $listType);
        });

        my $button5 = $self->addButton($table,
            'Disable all', 'Disable all active interfaces', undef,
            4, 7, 11, 12);
        $button5->signal_connect('clicked' => sub {

            # Disable all active interfaces
            $self->session->pseudoCmd('disableactiveinterface', $self->pseudoCmdMode);
            # Refresh the simple list
            $self->interfacesTab_refreshList($slWidget, scalar (@columnList / 2), $listType);
        });

        my $button6 = $self->addButton($table,
            'Update list', 'Update the list of interfaces', undef,
            10, 12, 11, 12);
        $button6->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->interfacesTab_refreshList($slWidget, scalar (@columnList / 2), $listType);
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub interfacesTab_refreshList {

        # Resets the simple list displayed by $self->interface1Tab and ->interface2Tab
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #   $type           - A string desribing the subset of active interfaces to show - set to
        #                       'all', 'alpha', 'dependent', 'independent', 'trigger', 'alias',
        #                       'macro', 'timer', 'hook'
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $type, $check) = @_;

        # Local variables
        my (
            $iv,
            @modList, @sortedList, @dataList,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || ! defined $type || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->interfacesTab_refreshList',
                @_,
            );
        }

        # Get a list of active interfaces, and then remove any that we don't want to show (according
        #   to the value of $type)
        foreach my $obj ($self->session->ivValues('interfaceHash')) {

            if (
                $type eq 'all'
                || $type eq 'alpha'
                || ($type eq 'dependent' && ! $obj->indepFlag)
                || ($type eq 'independent' && $obj->indepFlag)
                || ($obj->category eq $type)        # 'trigger', 'alias', etc
            ) {
                push (@modList, $obj);
            }
        }

        # Sort the list, as appropriate. The default is to sort numerically
        if ($type eq 'all') {

            @sortedList = sort {$a->number <=> $b->number} (@modList);

        } elsif ($type eq 'alpha' || $type eq 'dependent' || $type eq 'independent') {

            @sortedList = sort {lc($a->name) cmp lc($b->name)} (@modList);

        } else {

            $iv = $type . 'OrderList';      # e.g. 'triggerOrderList'

            foreach my $number ($self->session->$iv) {

                push (@sortedList, $self->session->ivShow('interfaceNumHash', $number));
            }
        }

        # Compile the simple list data
        foreach my $obj (@sortedList) {

            push (@dataList,
                $obj->number,
                $obj->name,
                $obj->category,
                $obj->indepFlag,
                $obj->enabledFlag,
                $obj->assocProf,
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub interfaces2Tab {

        # Interfaces2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #   $category       - The category of interface to show: 'trigger', 'alias', 'macro',
        #                       'timer' or 'hook'
        #   $number         - The page number to use
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $category, $number, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (
            ! defined $innerNotebook || ! defined $category || ! defined $number || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->interfaces2Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _' . $number, $innerNotebook);

        # Left column
        $self->addLabel($table, '<b>Active ' . $category . ' interfaces</b>',
            0, 12, 0, 1);
        $self->addLabel(
            $table, '<i>List of ' . $category . ' interfaces, in the order in which they are'
            . ' consulted</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            '#', 'int',
            'Name', 'text',
            'Category', 'text',
            'Indep', 'bool',
            'Enabled', 'bool',
            'Associated profile', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 230);       # Fixed height

        # Initialise the list
        $self->interfacesTab_refreshList($slWidget, scalar (@columnList / 2), $category);

        # Add buttons and combos
        my $button = $self->addButton($table,
            'Enable', 'Enable the selected active interface', undef,
            1, 3, 10, 11);
        $button->signal_connect('clicked' => sub {

            my ($name) = $self->getSimpleListData($slWidget, 1);
            if (defined $name) {

                # Enable the active interface
                $self->session->pseudoCmd('enableactiveinterface ' . $name, $self->pseudoCmdMode);

                # Refresh the simple list
                $self->interfacesTab_refreshList($slWidget, scalar (@columnList / 2), $category);
            }
        });

        my $button2 = $self->addButton($table,
            'Disable', 'Disable the selected active interface', undef,
            3, 5, 10, 11);
        $button2->signal_connect('clicked' => sub {

            my ($name) = $self->getSimpleListData($slWidget, 1);
            if (defined $name) {

                # Enable the active interface
                $self->session->pseudoCmd('disableactiveinterface ' . $name, $self->pseudoCmdMode);

                # Refresh the simple list
                $self->interfacesTab_refreshList($slWidget, scalar (@columnList / 2), $category);
            }
        });

        my $button3 = $self->addButton($table,
            'Edit', 'Edit the selected active interface', undef,
            5, 7, 10, 11);
        $button3->signal_connect('clicked' => sub {

            my ($number, $interfaceObj);

            ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                $interfaceObj = $self->session->ivShow('interfaceNumHash', $number);
                if ($interfaceObj) {

                    # Open up an 'edit' window to edit the object
                    $self->createFreeWin(
                        'Games::Axmud::EditWin::Interface::Active',
                        $self,
                        $self->session,
                        'Edit active ' . $interfaceObj->category . ' interface \''
                        . $interfaceObj->name . '\'',
                        $interfaceObj,
                        FALSE,                          # Not temporary
                    );
                }

                # Refresh the simple list
                $self->interfacesTab_refreshList($slWidget, scalar (@columnList / 2), $category);
            }
        });

        my $button4 = $self->addButton($table,
            'Move up', 'Move the selected active interface up the list', undef,
            8, 10, 10, 11);
        $button4->signal_connect('clicked' => sub {

            my ($number, $iv, $posn);

            ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                # Get the interface's current position in the list
                $iv = $category . 'OrderList';      # e.g. 'triggerOrderList'
                $posn = $self->session->ivFind($iv, $number);
                # Can't move the interface if it's already at the top of the list
                if (defined $posn && $posn != 0) {

                    # Move the active interface. The client command understands the position to be
                    #   a number in the range 1..., whereas $posn is an index in the range 0...,
                    #   so to move the interface up one position, we just use $posn
                    $self->session->pseudoCmd(
                        'moveactiveinterface ' . $number . ' ' . $posn,
                        $self->pseudoCmdMode,
                    );

                    # Refresh the simple list
                    $self->interfacesTab_refreshList(
                        $slWidget,
                        scalar (@columnList / 2),
                        $category,
                    );

                    # The interface should still be highlighted, after being moved up
                    $slWidget->select($posn - 1);
                }
            }
        });

        my $button5 = $self->addButton($table,
            'Move down', 'Move the selected active interface down the list', undef,
            10, 12, 10, 11);
        $button5->signal_connect('clicked' => sub {

            my ($number, $iv, $posn);

            ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                # Get the interface's current position in the list
                $iv = $category . 'OrderList';      # e.g. 'triggerOrderList'
                $posn = $self->session->ivFind($iv, $number);
                # Can't move the interface if it's already at the bottom of the list
                if (defined $posn && $posn < ((scalar $self->session->$iv) - 1)) {

                    # Move the active interface. The client command understands the position to be
                    #   a number in the range 1..., whereas $posn is an index in the range 0...,
                    #   so to move the interface down one position, we must add 2 to $posn
                    $self->session->pseudoCmd(
                        'moveactiveinterface ' . $number . ' ' . ($posn + 2),
                        $self->pseudoCmdMode,
                    );

                    # Refresh the simple list
                    $self->interfacesTab_refreshList(
                        $slWidget,
                        scalar (@columnList / 2),
                        $category,
                    );

                    # The interface should still be highlighted, after being moved down
                    $slWidget->select($posn + 1);
                }
            }
        });

        my $button6 = $self->addButton(
            $table,
            'Edit ' . $category . ' interface model',
            'Edit the model for this type of interface',
            undef,
            1, 5, 11, 12);
        $button6->signal_connect('clicked' => sub {

            my $obj = $axmud::CLIENT->ivShow('interfaceModelHash', 'trigger');
            if ($obj) {

                # Open up an 'edit' window to edit the object
                $self->createFreeWin(
                    'Games::Axmud::EditWin::InterfaceModel',
                    $self,
                    $self->session,
                    'Edit ' . $category . ' interface model',
                    $obj,
                    FALSE,                          # Not temporary
                );
            }
        });

        my $button7 = $self->addButton($table,
            'Update list', 'Update the list of interfaces', undef,
            10, 12, 11, 12);
        $button7->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->interfacesTab_refreshList($slWidget, scalar (@columnList / 2), $category);
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub tasksTab {

        # Tasks tab
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->tasksTab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('_Tasks', $self->notebook);

        # Current tasks
        $self->addLabel($table, '<b>Current tasks</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of tasks in this session\'s current tasklist (showing task window status)</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Task', 'text',
            'Allowed', 'bool',
            'Required', 'bool',
            'Open on start', 'bool',
            'Open now', 'bool',
            'Preferred locations', 'text',
            'Use winmap', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 300);       # Fixed height

        # Refresh the list
        $self->tasksTab_refreshList($slWidget, scalar (@columnList / 2));

        # Add buttons to open/close windows
        my $button = $self->addButton($table,
            'Open window', 'Open a task window for the selected task (if allowed)', undef,
            1, 3, 10, 11);
        $button->signal_connect('clicked' => sub {

            my ($task) = $self->getSimpleListData($slWidget, 0);
            if (defined $task) {

                # Open a task window for this task
                $self->session->pseudoCmd(
                    'opentaskwindow ' . $task,
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list
                $self->tasksTab_refreshList($slWidget, scalar (@columnList / 2));
            }
        });

        my $button2 = $self->addButton($table,
            'Open all windows', 'Open task windows for all tasks (where possible)', undef,
            3, 5, 10, 11);
        $button2->signal_connect('clicked' => sub {

            # Open a task window for all tasks
            $self->session->pseudoCmd('opentaskwindow -a', $self->pseudoCmdMode);

            # Refresh the simple list
            $self->tasksTab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button3 = $self->addButton($table,
            'Close window', 'Closes the task window for the selected task (if open)', undef,
            5, 7, 10, 11);
        $button3->signal_connect('clicked' => sub {

            my ($task) = $self->getSimpleListData($slWidget, 0);
            if (defined $task) {

                # Close the task window for this task
                $self->session->pseudoCmd(
                    'closetaskwindow ' . $task,
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list
                $self->tasksTab_refreshList($slWidget, scalar (@columnList / 2));
            }
        });

        my $button4 = $self->addButton($table,
            'Close all windows', 'Close task windows for all tasks (when open)', undef,
            7, 9, 10, 11);
        $button4->signal_connect('clicked' => sub {

            # Close the task window for all tasks
            $self->session->pseudoCmd('closetaskwindow -a', $self->pseudoCmdMode);

            # Refresh the simple list
            $self->tasksTab_refreshList($slWidget, scalar (@columnList / 2));
        });

        my $button5 = $self->addButton($table,
            'Refresh list', 'Refresh the list of tasks and their task windows', undef,
            10, 12, 10, 11);
        $button5->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->tasksTab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub tasksTab_refreshList {

        # Called by $self->tasksTab to refresh the Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::List
        #   $columns    - The number of columns in the list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (@sortedList, @dataList);

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->tasksTab_refreshList', @_);
        }

        # Get a sorted list of current tasks
        @sortedList = sort {lc($a->name) cmp lc($b->name)}
                        ($self->session->ivValues('currentTaskHash'));

        # Compile the simple list data
        foreach my $obj (@sortedList) {

            push (@dataList,
                $obj->name,
                $obj->allowWinFlag,
                $obj->requireWinFlag,
                $obj->startWithWinFlag,
                $obj->taskWinFlag,
                join(' ', $obj->winPreferList),
                $obj->winmap,
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub recordingTab {

        # Recording tab
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (@columnList, @widgetList);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->recordingTab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('_Recording', $self->notebook);

        # Current tasks
        $self->addLabel($table, '<b>Current recording</b>',
            0, 12, 0, 1);

        $self->addLabel($table, 'Recording in progress:',
            1, 5, 1, 2);
        my $checkButton = $self->addCheckButton($table, undef, FALSE,
            5, 6, 1, 2);

        $self->addLabel($table, 'Recording paused:',
            7, 11, 1, 2);
        my $checkButton2 = $self->addCheckButton($table, undef, FALSE,
            11, 12, 1, 2);

        # (Other local variables required as arguments in calls to $self->recordingTab_refreshList)
        my ($entry, $entry2, $entry3, $entry4);

        # Add a simple list
        @columnList = (
            'Line', 'text',     # When no recording in progress, don't want '0' to appear in column
            'Insert', 'text',
            'Instruction', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 6,
            -1, 160);   # Fixed height

        # Add buttons to open/close windows
        $self->addLabel($table, '<b>Commands:</b> ',
            1, 3, 6, 7);
        $self->addLabel($table,
                '<b>></b> <i>world command,</i> '
                . '<b>;</b> <i>client command,</i> '
                . '<b>#</b> <i>\'main\' window comment</i>',
            3, 12, 6, 7);

        $self->addLabel($table, '<b>Breaks:</b> ',
            1, 3, 7, 8);
        $self->addLabel($table,
                '<b>@</b> <i>ordinary break,</i> '
                . '<b>t</b> <i>trigger break,</i> '
                . '<b>p</b> <i>pause break,</i> '
                . '<b>l</b> <i>locator break</i>',
            3, 12, 7, 8);

        my $button = $self->addButton($table,
            'Start/stop', 'Starts or stops the current recording', undef,
            1, 3, 8, 9);
        # (->signal_connect appears at the bottom)

        my $button2 = $self->addButton($table,
            'Pause/resume', 'Pauses or resumes the current recording', undef,
            3, 5, 8, 9);
        $button2->signal_connect('clicked' => sub {

            # Pause/resume the recording
            $self->session->pseudoCmd('pauserecording', $self->pseudoCmdMode);

            # Refresh the simple list and reset widgets
            $self->recordingTab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                $checkButton, $checkButton2, $entry, $entry2, $entry3,
            );
        });

        my $button3 = $self->addButton($table,
            'Add as mission', 'Save this recording as a new mission', undef,
            7, 10, 8, 9);
        $button3->signal_connect('clicked' => sub {

            my ($name, $descrip);

            if ($self->session->recordingList) {

                # Prompt the user for a mission name (and optional description)
                ($name, $descrip) = $self->showDoubleEntryDialogue(
                    'Add mission',
                    'Add a name for the mission',
                    '(Optional) add a description',
                );

                # Add the mission
                if ($name && $descrip) {

                    $self->session->pseudoCmd(
                        'add mission <' . $name . '> <' . $descrip . '>',
                        $self->pseudoCmdMode,
                    );

                } elsif ($name) {

                    $self->session->pseudoCmd('add mission <' . $name . '>', $self->pseudoCmdMode);
                }
            }

            # Refresh the simple list and reset widgets
            $self->recordingTab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                $checkButton, $checkButton2, $entry, $entry2, $entry3,
            );
        });

        my $button4 = $self->addButton($table,
            'Update list', 'Update the recording list', undef,
            10, 12, 8, 9);
        $button4->signal_connect('clicked' => sub {

            # Refresh the simple list and reset widgets
            $self->recordingTab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                $checkButton, $checkButton2, $entry, $entry2, $entry3,
            );
        });

        $self->addLabel($table, 'Instruction:',
            1, 3, 9, 10);
        $entry = $self->addEntryWithIcon($table, undef, 'string', 1, undef,
            3, 6, 9, 10);

        my $button5 = $self->addButton($table,
            'World cmd', 'Add a world command at the insertion point', undef,
            6, 8, 9, 10);
        $button5->signal_connect('clicked' => sub {

            if ($self->checkEntryIcon($entry)) {

                # Add the world command
                $self->session->pseudoCmd(
                    'worldcommand ' . $entry->get_text(),
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list and reset widgets
                $self->recordingTab_refreshList(
                    $slWidget,
                    scalar (@columnList / 2),
                    $checkButton, $checkButton2, $entry, $entry2, $entry3,
                );
            }
        });

        my $button6 = $self->addButton($table,
            'Client cmd', 'Add a client command at the insertion point', undef,
            8, 9, 9, 10);
        $button6->signal_connect('clicked' => sub {

            if ($self->checkEntryIcon($entry)) {

                # Add the client command
                $self->session->pseudoCmd(
                    'clientcommand ' . $entry->get_text(),
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list and reset widgets
                $self->recordingTab_refreshList(
                    $slWidget,
                    scalar (@columnList / 2),
                    $checkButton, $checkButton2, $entry, $entry2, $entry3,
                );
            }
        });

        my $button7 = $self->addButton($table,
            'Comment', 'Add a \'main\' window comment at the insertion point', undef,
            10, 12, 9, 10);
        $button7->signal_connect('clicked' => sub {

            if ($self->checkEntryIcon($entry)) {

                # Add the client command
                $self->session->pseudoCmd(
                    'clientcommand ' . $entry->get_text(),
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list and reset widgets
                $self->recordingTab_refreshList(
                    $slWidget,
                    scalar (@columnList / 2),
                    $checkButton, $checkButton2, $entry, $entry2, $entry3,
                );
            }
        });

        $self->addLabel($table, 'Pattern/interval:',
            1, 3, 10, 11);
        $entry2 = $self->addEntryWithIcon($table, undef, 'string', 1, undef,
            3, 5, 10, 11);

        my $button8 = $self->addButton($table,
            'Break',
            'Add an ordinary break at the insertion point',
            undef,
            5, 6, 10, 11);
        $button8->signal_connect('clicked' => sub {

            # Add the ordinary break
            $self->session->pseudoCmd('break', $self->pseudoCmdMode);

            # Refresh the simple list and reset widgets
            $self->recordingTab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                $checkButton, $checkButton2, $entry, $entry2, $entry3,
            );
        });

        my $button9 = $self->addButton($table,
            'Trigger break',
            'Add a trigger break at the insertion point, using the specified pattern',
            undef,
            6, 8, 10, 11);
        $button9->signal_connect('clicked' => sub {

            if ($self->checkEntryIcon($entry2)) {

                # Add the client command
                $self->session->pseudoCmd(
                    'break -t ' . $entry2->get_text(),
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list and reset widgets
                $self->recordingTab_refreshList(
                    $slWidget,
                    scalar (@columnList / 2),
                    $checkButton, $checkButton2, $entry, $entry2, $entry3,
                );
            }
        });

        my $button10 = $self->addButton($table,
            'Pause break',
            'Add a pause break at the insertion point, using the specified interval',
            undef,
            8, 10, 10, 11);
        $button10->signal_connect('clicked' => sub {

            if ($self->checkEntryIcon($entry2)) {

                # Add the trigger break
                $self->session->pseudoCmd(
                    'break -p ' . $entry2->get_text(),
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list and reset widgets
                $self->recordingTab_refreshList(
                    $slWidget,
                    scalar (@columnList / 2),
                    $checkButton, $checkButton2, $entry, $entry2, $entry3,
                );
            }
        });

        my $button11 = $self->addButton($table,
            'Locator break',
            'Add a pause break at the insertion point, using the specified interval',
            undef,
            10, 12, 10, 11);
        $button11->signal_connect('clicked' => sub {

            # Add the locator break
            $self->session->pseudoCmd('break -l', $self->pseudoCmdMode);

            # Refresh the simple list and reset widgets
            $self->recordingTab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                $checkButton, $checkButton2, $entry, $entry2, $entry3,
            );
        });

        $self->addLabel($table, 'Insertion point:',
            1, 3, 11, 12);
        $entry3 = $self->addEntryWithIcon($table, undef, 'int', 0, undef,
            3, 5, 11, 12);

        my $button12 = $self->addButton($table,
            'Set',
            'Sets the insertion point (use 0 to move it to the end)',
            undef,
            5, 6, 11, 12);
        $button12->signal_connect('clicked' => sub {

            if ($self->checkEntryIcon($entry3)) {

                # Set the insertion point
                $self->session->pseudoCmd(
                    'insertrecording ' . $entry3->get_text(),
                    $self->pseudoCmdMode,
                );

                # Refresh the simple list and reset widgets
                $self->recordingTab_refreshList(
                    $slWidget,
                    scalar (@columnList / 2),
                    $checkButton, $checkButton2, $entry, $entry2, $entry3,
                );
            }
        });

        my $button13 = $self->addButton($table,
            'Reset',
            'Moves the insertion point to the end',
            undef,
            6, 8, 11, 12);
        $button13->signal_connect('clicked' => sub {

            # Move the insertion point to the end
            $self->session->pseudoCmd('insertrecording', $self->pseudoCmdMode);

            # Refresh the simple list and reset widgets
            $self->recordingTab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                $checkButton, $checkButton2, $entry, $entry2, $entry3,
            );
        });

        my $button14 = $self->addButton($table,
            'Delete selected line',
            'Deletes the selected line',
            undef,
            9, 12, 11, 12);
        $button14->signal_connect('clicked' => sub {

            my ($number) = $self->getSimpleListData($slWidget, 0);
            if (defined $number) {

                # Delete the selected line
                $self->session->pseudoCmd('deleterecording ' . $number, $self->pseudoCmdMode);

                # Refresh the simple list and reset widgets
                $self->recordingTab_refreshList(
                    $slWidget,
                    scalar (@columnList / 2),
                    $checkButton, $checkButton2, $entry, $entry2, $entry3,
                );
            }
        });

        # Now we can initialise the list
        $self->recordingTab_refreshList(
            $slWidget,
            scalar (@columnList / 2),
            $checkButton, $checkButton2, $entry, $entry2, $entry3,
        );

        # If there is no recording in progress, many widgets begin desensitised
        @widgetList = (
            $button2, $button5, $button6, $button7, $button8, $button9, $button10, $button11,
            $button12, $button13, $button14, $entry, $entry2, $entry3,
        );

        if (! $self->session->recordingFlag) {

            $self->desensitiseWidgets(@widgetList);
        }

        # Finally, add a ->signal_connect for the 'Start/stop' button
        $button->signal_connect('clicked' => sub {

            # Start/stop the recording
            $self->session->pseudoCmd('record', $self->pseudoCmdMode);

            # When there is no recording in progress, most buttons are desensitised
            if ($self->session->recordingFlag) {
                $self->sensitiseWidgets(@widgetList);
            } else {
                $self->desensitiseWidgets(@widgetList);
            }

            # Refresh the simple list and reset widgets
            $self->recordingTab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                $checkButton, $checkButton2, $entry, $entry2, $entry3,
            );
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub recordingTab_refreshList {

        # Called by $self->recordingTab to refresh the Gtk::Ex::Simple::List
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::List
        #   $columns        - The number of columns in the list
        #   $checkButton, $checkButton2, $entry, $entry2, $entry3
        #                   - Widgets which must be updated at the same time as the simple list
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my (
            $self, $slWidget, $columns, $checkButton, $checkButton2, $entry, $entry2, $entry3,
            $check
        ) = @_;

        # Local variables
        my (@list, @dataList);

        # Check for improper arguments
        if (
            ! defined $slWidget || ! defined $columns || ! defined $checkButton
            || ! defined $checkButton2 || ! defined $entry || ! defined $entry2 || ! defined $entry3
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->recordingTab_refreshList',
                @_,
            );
        }

        # Import the recording list
        @list = $self->session->recordingList;
        if (@list) {

            # Compile the simple list data
            for (my $count = 0; $count < (scalar @list); $count++) {

                my $flag;

                # (If ->recordingPosn is 'undef', new lines are just added to the end of the list)
                if ($self->session->recordingPosn && $count == $self->session->recordingPosn) {
                    $flag = '>>>';
                } else {
                    $flag = '';
                }

                push (@dataList, ($count + 1), $flag, $list[$count]);
            }
        }

        # If ->recordingPosn is 'undef', add a blank line to the end of the simple list
        if (! $self->session->recordingPosn) {

            push (@dataList, '', '>>>', '');
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        # Update other widgets
        $checkButton->set_active($self->session->recordingFlag);
        $checkButton2->set_active($self->session->recordingPausedFlag);
        $self->resetEntryBoxes($entry, $entry2, $entry3);

        return 1;
    }

    sub protocolsTab {

        # Protocols tab - called by $self->setupNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->protocolsTab', @_);
        }

        # Tab setup
        # Create a notebook within the main one, so that we have two rows of tabs
        my ($vBox, $innerNotebook) = $self->addInnerNotebookTab('_Protocols', $self->notebook);

        # Add tabs to the inner notebook
        $self->protocols1Tab($innerNotebook);
        $self->protocols2Tab($innerNotebook);
        $self->protocols3Tab($innerNotebook);

        return 1;
    }

    sub protocols1Tab {

        # Protocols1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->protocols1Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _1', $innerNotebook);

       # Telnet option negotiations
        $self->addLabel($table, '<b>Telnet option negotiations</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>Current status of telnet options for this session</i>',
            1, 12, 1, 2);

        $self->addLabel($table, 'ECHO (hide passwords)',
            1, 4, 2, 3);
        my $checkButton = $self->addCheckButton($table, undef, FALSE,
            4, 5, 2, 3);
        my $entry = $self->addEntry($table, undef, FALSE,
            5, 12, 2, 3);

        $self->addLabel($table, 'SGA (Suppress Go Ahead)',
            1, 4, 3, 4);
        my $checkButton2 = $self->addCheckButton($table, undef, FALSE,
            4, 5, 3, 4);
        my $entry2 = $self->addEntry($table, undef, FALSE,
            5, 12, 3, 4);

        $self->addLabel($table, 'TTYPE (detect Terminal Type)',
            1, 4, 4, 5);
        my $checkButton3 = $self->addCheckButton($table, undef, FALSE,
            4, 5, 4, 5);
        my $entry3 = $self->addEntry($table, undef, FALSE,
            5, 12, 4, 5);

        $self->addLabel($table, 'EOR (negotiate End Of Record)',
            1, 4, 5, 6);
        my $checkButton4 = $self->addCheckButton($table, undef, FALSE,
            4, 5, 5, 6);
        my $entry4 = $self->addEntry($table, undef, FALSE,
            5, 12, 5, 6);

        $self->addLabel($table, 'NAWS (Negotiate About Window Size)',
            1, 4, 6, 7);
        my $checkButton5 = $self->addCheckButton($table, undef, FALSE,
            4, 5, 6, 7);
        my $entry5 = $self->addEntry($table, undef, FALSE,
            5, 12, 6, 7);

        $self->addLabel($table, 'NEW-ENVIRON (New Environment option)',
            1, 4, 7, 8);
        my $checkButton6 = $self->addCheckButton($table, undef, FALSE,
            4, 5, 7, 8);
        my $entry6 = $self->addEntry($table, undef, FALSE,
            5, 12, 7, 8);

        $self->addLabel($table, 'CHARSET (Character Set and translation)',
            1, 4, 8, 9);
        my $checkButton7 = $self->addCheckButton($table, undef, FALSE,
            4, 5, 8, 9);
        my $entry7 = $self->addEntry($table, undef, FALSE,
            5, 12, 8, 9);

        $self->protocols1Tab_updateWidgets(
            $entry, $entry2, $entry3, $entry4, $entry5, $entry6, $entry7, $checkButton,
            $checkButton2, $checkButton3, $checkButton4, $checkButton5, $checkButton6,
            $checkButton7,
        );

        my $button = $self->addButton($table, 'Update', 'Update the telnet options shown', undef,
            10, 12, 9, 10);
        $button->signal_connect('clicked' => sub {

            $self->protocols1Tab_updateWidgets(
                $entry, $entry2, $entry3, $entry4, $entry5, $entry6, $entry7, $checkButton,
                $checkButton2, $checkButton3, $checkButton4, $checkButton5, $checkButton6,
                $checkButton7,
            );
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub protocols1Tab_updateWidgets {

        # Called by $self->optionsTab to update the Gtk2::Entry boxes
        #
        # Expected arguments
        #   $entry, $entry2, $entry3, $entry4, $entry5, $entry6, $entry7
        #       - List of Gtk2::Entry boxes to update
        #   $checkButton, $checkButton2, $checkButton3, $checkButton4, $checkButton5, $checkButton6,
        #   $checkButton7
        #       - List of Gtk2::CheckButtons to update

        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my (
            $self, $entry, $entry2, $entry3, $entry4, $entry5, $entry6, $entry7, $checkButton,
            $checkButton2, $checkButton3, $checkButton4, $checkButton5, $checkButton6,
            $checkButton7, $check,
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $entry || ! defined $entry2 || ! defined $entry3 || ! defined $entry4
            || ! defined $entry5 || ! defined $entry6 || ! defined $entry7 || ! defined $checkButton
            || ! defined $checkButton2 || ! defined $checkButton3 || ! defined $checkButton4
            || ! defined $checkButton5 || ! defined $checkButton6 || ! defined $checkButton7
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->protocols1Tab_updateWidgets',
                @_,
            );
        }

        if ($self->session->echoMode eq 'no_invite') {
            $entry->set_text('Server has not suggested stopping ECHO yet');
        } elsif ($self->session->echoMode eq 'client_agree') {
            $entry->set_text('Server has suggested stopping ECHO and client has agreed');
        } elsif ($self->session->echoMode eq 'client_refuse') {
            $entry->set_text('Server has suggested stopping ECHO and client has refused');
        } elsif ($self->session->echoMode eq 'server_stop') {
            $entry->set_text('Server has resumed ECHO and client has agreeed');
        }

        if ($self->session->sgaMode eq 'no_invite') {
            $entry2->set_text('Server has not suggested SGA yet');
        } elsif ($self->session->sgaMode eq 'client_agree') {
            $entry2->set_text('Server has suggested SGA and client has agreed');
        } elsif ($self->session->sgaMode eq 'client_refuse') {
            $entry2->set_text('Server has suggested SGA and client has refused');
        } elsif ($self->session->sgaMode eq 'server_stop') {
            $entry3->set_text('Server has stopped SGA and client has agreeed');
        }

        if ($self->session->specifiedTType) {
            $entry3->set_text('Preferred terminal: ' . $self->session->specifiedTType);
        } else {
            $entry3->set_text('Preferred terminal: (not sent)');
        }

        if ($self->session->eorMode eq 'no_invite') {
            $entry4->set_text('Server has not negotiated EOR yet');
        } elsif ($self->session->eorMode eq 'client_agree') {
            $entry4->set_text('Server has suggested EOR negotiation and client has agreed');
        } elsif ($self->session->eorMode eq 'client_refuse') {
            $entry4->set_text('Server has suggested EOR negotiation and client has refused');
        }

        if ($self->session->nawsMode eq 'no_invite') {
            $entry5->set_text('Server has not suggested NAWS yet');
        } elsif ($self->session->nawsMode eq 'client_agree') {
            $entry5->set_text('Server has suggested NAWS and client has agreed');
        } elsif ($self->session->nawsMode eq 'client_refuse') {
            $entry5->set_text('Server has suggested NAWS and client has refused');
        }

        $entry6->set_text('(not yet implemented)');

        $entry7->set_text('(not yet implemented)');

        $checkButton->set_active($axmud::CLIENT->useEchoFlag);
        $checkButton2->set_active($axmud::CLIENT->useSgaFlag);
        $checkButton3->set_active($axmud::CLIENT->useTTypeFlag);
        $checkButton4->set_active($axmud::CLIENT->useEorFlag);
        $checkButton5->set_active($axmud::CLIENT->useNawsFlag);
        $checkButton6->set_active($axmud::CLIENT->useNewEnvironFlag);
        $checkButton7->set_active($axmud::CLIENT->useCharSetFlag);

        return 1;
    }

    sub protocols2Tab {

        # Protocols2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->protocols2Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _2', $innerNotebook);

        # MUD Protocol negotiations
        $self->addLabel($table, '<b>MUD protocol negotiations (1/2)</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>Current status of MUD protocols for this session</i>',
            1, 12, 1, 2);

        $self->addLabel($table, 'MSDP (Mud Server Data Protocol)',
            1, 4, 2, 3);
        my $checkButton = $self->addCheckButton($table, undef, FALSE,
            4, 5, 2, 3);
        my $entry = $self->addEntry($table, undef, FALSE,
            5, 12, 2, 3);

        $self->addLabel($table, 'MSSP (Mud Server Status Protocol)',
            1, 4, 3, 4);
        my $checkButton2 = $self->addCheckButton($table, undef, FALSE,
            4, 5, 3, 4);
        my $entry2 = $self->addEntry($table, undef, FALSE,
            5, 12, 3, 4);

        $self->addLabel($table, 'MCCP (Mud Client Compression Protocol)',
            1, 4, 4, 5);
        my $checkButton3 = $self->addCheckButton($table, undef, FALSE,
            4, 5, 4, 5);
        my $entry3 = $self->addEntry($table, undef, FALSE,
            5, 12, 4, 5);

        $self->addLabel($table, 'MSP (Mud Sound Protocol)',
            1, 4, 5, 6);
        my $checkButton4 = $self->addCheckButton($table, undef, FALSE,
            4, 5, 5, 6);
        my $entry4 = $self->addEntry($table, undef, FALSE,
            5, 12, 5, 6);

        $self->addLabel($table, 'MXP (Mud Xtension Protocol)',
            1, 4, 6, 7);
        my $checkButton5 = $self->addCheckButton($table, undef, FALSE,
            4, 5, 6, 7);
        my $entry5 = $self->addEntry($table, undef, FALSE,
            5, 12, 6, 7);

        $self->addLabel($table, 'PUEBLO',
            1, 4, 7, 8);
        my $checkButton6 = $self->addCheckButton($table, undef, FALSE,
            4, 5, 7, 8);
        my $entry6 = $self->addEntry($table, undef, FALSE,
            5, 12, 7, 8);

        $self->addLabel($table, 'ZMP (Zenith Mud Protocol)',
            1, 4, 8, 9);
        my $checkButton7 = $self->addCheckButton($table, undef, FALSE,
            4, 5, 8, 9);
        my $entry7 = $self->addEntry($table, undef, FALSE,
            5, 12, 8, 9);

        $self->addLabel($table, 'AARDWOLF-102',
            1, 4, 9, 10);
        my $checkButton8 = $self->addCheckButton($table, undef, FALSE,
            4, 5, 9, 10);
        my $entry8 = $self->addEntry($table, undef, FALSE,
            5, 12, 9, 10);

        $self->protocolsTab2_updateWidgets(
            $entry, $entry2, $entry3, $entry4, $entry5, $entry6, $entry7, $entry8, $checkButton,
            $checkButton2, $checkButton3, $checkButton4, $checkButton5, $checkButton6,
            $checkButton7, $checkButton8,
        );

        my $button = $self->addButton($table, 'Update', 'Update the MUD protocols shown', undef,
            10, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            $self->protocolsTab2_updateWidgets(
                $entry, $entry2, $entry3, $entry4, $entry5, $entry6, $entry7, $entry8, $checkButton,
                $checkButton2, $checkButton3, $checkButton4, $checkButton5, $checkButton6,
                $checkButton7, $checkButton8,
            );
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub protocolsTab2_updateWidgets {

        # Called by $self->protocolsTab2 to update the Gtk2::Entry boxes
        #
        # Expected arguments
        #   $entry, $entry2, $entry3, $entry4, $entry5, $entry6, $entry7, $entry8
        #           - List of Gtk2::Entry boxes to update
        #   $checkButton, $checkButton2, $checkButton3, $checkButton4, $checkButton5,
        #       $checkButton6, $checkButton7, $checkButton8
        #           - List of Gtk2::CheckButtons to update
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my (
            $self, $entry, $entry2, $entry3, $entry4, $entry5, $entry6, $entry7, $entry8,
            $checkButton, $checkButton2, $checkButton3, $checkButton4, $checkButton5, $checkButton6,
            $checkButton7, $checkButton8, $check,
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $entry || ! defined $entry2 || ! defined $entry3 || ! defined $entry4
            || ! defined $entry5 || ! defined $entry6 || ! defined $entry7 || ! defined $entry8
            || ! defined $checkButton || ! defined $checkButton2 || ! defined $checkButton3
            || ! defined $checkButton4 || ! defined $checkButton5 || ! defined $checkButton6
            || ! defined $checkButton7 || ! defined $checkButton8 || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->protocolsTab2_updateWidgets',
                @_,
            );
        }

        if ($self->session->msdpMode eq 'no_invite') {
            $entry->set_text('Server has not suggested MSDP yet');
        } elsif ($self->session->msdpMode eq 'client_agree') {
            $entry->set_text('Server has suggested MSDP and client has agreed');
        } elsif ($self->session->msdpMode eq 'client_refuse') {
            $entry->set_text('Server has suggested MSDP and client has refused');
        }

        if ($self->session->msspMode eq 'no_invite') {
            $entry2->set_text('Server has not suggested MSSP yet');
        } elsif ($self->session->msspMode eq 'client_agree') {
            $entry2->set_text('Server has suggested MSSP and client has agreed');
        } elsif ($self->session->msspMode eq 'client_refuse') {
            $entry2->set_text('Server has suggested MSSP and client has refused');
        }

        if ($self->session->mccpMode eq 'no_invite') {
            $entry3->set_text('Server has not suggested MCCP yet');
        } elsif ($self->session->mccpMode eq 'client_agree') {
            $entry3->set_text('Server has suggested MCCP and client has agreed');
        } elsif ($self->session->mccpMode eq 'client_refuse') {
            $entry3->set_text('Server has suggested MCCP and client has refused');
        } elsif ($self->session->mccpMode eq 'compress_start') {
            $entry3->set_text('Server has signalled MCCP compression has begun');
        } elsif ($self->session->mccpMode eq 'compress_error') {
            $entry3->set_text('MCCP has stopped after a compression error');
        } elsif ($self->session->mccpMode eq 'compress_stop') {
            $entry3->set_text('Server has terminated MCCP compression');
        }

        if ($self->session->mspMode eq 'no_invite') {
            $entry4->set_text('0 - Server has not suggested MSP yet');
        } elsif ($self->session->mspMode eq 'client_agree') {
            $entry4->set_text('1 - Server has suggested MSP and client has agreed');
        } elsif ($self->session->mspMode eq 'client_refuse') {
            $entry4->set_text('2 - Server has suggested MSP and client has refused');
        } elsif ($self->session->mspMode eq 'client_simulate') {

            $entry4->set_text(
                '3 - Server did not suggest MSP, but ' . $axmud::SCRIPT
                . ' is responding to MSP sound/music triggers',
            );
        }

        if ($self->session->mxpMode eq 'no_invite') {
            $entry5->set_text('Server has not suggested MXP yet');
        } elsif ($self->session->mxpMode eq 'client_agree') {
            $entry5->set_text('Server has suggested MXP and client has agreed');
        } elsif ($self->session->mxpMode eq 'client_refuse') {
            $entry5->set_text('Server has suggested MXP and client has refused');
        }

        if ($self->session->puebloMode eq 'no_invite') {
            $entry6->set_text('Server has not suggested Pueblo yet');
        } elsif ($self->session->puebloMode eq 'client_agree') {
            $entry6->set_text('Server has suggested Pueblo and client has agreed');
        } elsif ($self->session->puebloMode eq 'client_refuse') {
            $entry6->set_text('Server has suggested Pueblo and client has refused');
        }

        $entry7->set_text('(not yet implemented)');

        $entry8->set_text('(not yet implemented)');

        $checkButton->set_active($axmud::CLIENT->useMsdpFlag);
        $checkButton2->set_active($axmud::CLIENT->useMsspFlag);
        $checkButton3->set_active($axmud::CLIENT->useMccpFlag);
        $checkButton4->set_active($axmud::CLIENT->useMspFlag);
        $checkButton5->set_active($axmud::CLIENT->useMxpFlag);
        $checkButton6->set_active($axmud::CLIENT->usePuebloFlag);
        $checkButton7->set_active($axmud::CLIENT->useZmpFlag);
        $checkButton8->set_active($axmud::CLIENT->useAard102Flag);

        return 1;
    }

    sub protocols3Tab {

        # Protocols3 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->protocols3Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _3', $innerNotebook);

        # MUD Protocol negotiations
        $self->addLabel($table, '<b>MUD protocol negotiations (2/2)</b>',
            0, 12, 0, 1);
        $self->addLabel($table, '<i>Current status of MUD protocols for this session</i>',
            1, 12, 1, 2);

        $self->addLabel($table, 'ATCP (Achaea Telnet Client Protocol)',
            1, 4, 2, 3);
        my $checkButton = $self->addCheckButton($table, undef, FALSE,
            4, 5, 2, 3);
        my $entry = $self->addEntry($table, undef, FALSE,
            5, 12, 2, 3);

        $self->addLabel($table, 'GMCP (Generic MUD Communication Protocol)',
            1, 4, 3, 4);
        my $checkButton2 = $self->addCheckButton($table, undef, FALSE,
            4, 5, 3, 4);
        my $entry2 = $self->addEntry($table, undef, FALSE,
            5, 12, 3, 4);

        $self->addLabel($table, 'MTTS (Mud Terminal Type Standard)',
            1, 4, 4, 5);
        my $checkButton3 = $self->addCheckButton($table, undef, FALSE,
            4, 5, 4, 5);
        my $entry3 = $self->addEntry($table, undef, FALSE,
            5, 12, 4, 5);

        $self->addLabel($table, 'MCP (Mud Client Protocol)',
            1, 4, 5, 6);
        my $checkButton4 = $self->addCheckButton($table, undef, FALSE,
            4, 5, 5, 6);
        my $entry4 = $self->addEntry($table, undef, FALSE,
            5, 12, 5, 6);

        $self->protocolsTab3_updateWidgets(
            $entry, $entry2, $entry3, $entry4, $checkButton, $checkButton2, $checkButton3,
            $checkButton4,
        );

        my $button = $self->addButton($table, 'Update', 'Update the MUD protocols shown', undef,
            10, 12, 6, 7);
        $button->signal_connect('clicked' => sub {

            $self->protocolsTab3_updateWidgets(
                $entry, $entry2, $entry3, $entry4, $checkButton, $checkButton2, $checkButton3,
                $checkButton4,
            );
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub protocolsTab3_updateWidgets {

        # Called by $self->protocolsTab3 to update the Gtk2::Entry boxes
        #
        # Expected arguments
        #   $entry, $entry2, $entry3, $entry4
        #           - List of Gtk2::Entry boxes to update
        #   $checkButton, $checkButton2, $checkButton3, $checkButton4
        #           - List of Gtk2::CheckButtons to update
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my (
            $self, $entry, $entry2, $entry3, $entry4, $checkButton, $checkButton2, $checkButton3,
            $checkButton4, $check,
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $entry || ! defined $entry2 || ! defined $entry3 || ! defined $entry4
            || ! defined $checkButton || ! defined $checkButton2 || ! defined $checkButton3
            || ! defined $checkButton4 || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->protocolsTab3_updateWidgets',
                @_,
            );
        }

        if ($self->session->atcpMode eq 'no_invite') {
            $entry->set_text('Server has not suggested ATCP yet');
        } elsif ($self->session->atcpMode eq 'client_agree') {
            $entry->set_text('Server has suggested ATCP and client has agreed');
        } elsif ($self->session->atcpMode eq 'client_refuse') {
            $entry->set_text('Server has suggested ATCP and client has refused');
        }

        if ($self->session->gmcpMode eq 'no_invite') {
            $entry2->set_text('Server has not suggested GMCP yet');
        } elsif ($self->session->gmcpMode eq 'client_agree') {
            $entry2->set_text('Server has suggested GMCP and client has agreed');
        } elsif ($self->session->gmcpMode eq 'client_refuse') {
            $entry2->set_text('Server has suggested GMCP and client has refused');
        }

        if ($self->session->specifiedTType) {
            $entry3->set_text('Preferred terminal: ' . $self->session->specifiedTType);
        } else {
            $entry3->set_text('Preferred terminal: (not sent)');
        }

        $entry4->set_text('(not yet implemented)');

        $checkButton->set_active($axmud::CLIENT->useAtcpFlag);
        $checkButton2->set_active($axmud::CLIENT->useGmcpFlag);
        $checkButton3->set_active($axmud::CLIENT->useMttsFlag);
        $checkButton4->set_active($axmud::CLIENT->useMcpFlag);

        return 1;
    }

    sub msdpTab {

        # Msdp tab - called by $self->setupNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->msdpTab', @_);
        }

        # Tab setup
        # Create a notebook within the main one, so that we have two rows of tabs
        my ($vBox, $innerNotebook) = $self->addInnerNotebookTab('_MSDP', $self->notebook);

        # Add tabs to the inner notebook
        $self->msdp1Tab($innerNotebook);
        $self->msdp2Tab($innerNotebook);
        $self->msdp3Tab($innerNotebook);
        $self->msdp4Tab($innerNotebook);
        $self->msdp5Tab($innerNotebook);
        $self->msdp6Tab($innerNotebook);
        $self->msdp7Tab($innerNotebook);
        $self->msdp8Tab($innerNotebook);

        return 1;
    }

    sub msdp1Tab {

        # Msdp1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->msdp1Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _1', $innerNotebook);

        # MSDP generic commands
        $self->addLabel($table, '<b>MSDP generic commands</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of generic (official) commands supported by the server</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Supported', 'bool',
            'Command', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10, -1, 270);      # Fixed height

        # Initialise the list
        $self->msdp1Tab_refreshList(
            $slWidget,
            scalar (@columnList / 2),
            'msdpGenericCmdHash',
        );

        # Add a button
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of commands', undef,
            9, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            $self->msdp1Tab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                'msdpGenericCmdHash',
            );
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub msdp1Tab_refreshList {

        # Resets the simple list displayed by $self->msdp1Tab, etc
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #   $iv             - The hash IV whose key-value pairs should be displayed
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $iv, $check) = @_;

        # Local variables
        my (
            @dataList,
            %hash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || ! defined $iv || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->msdp1Tab_refreshList',
                @_,
            );
        }

        # Import the hash IV
        %hash = $self->session->$iv;

        # Compile the simple list data
        foreach my $key (sort {lc($a) cmp lc($b)} (keys %hash)) {

            push (@dataList,
                $hash{$key},
                $key,
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub msdp2Tab {

        # Msdp2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->msdp2Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _2', $innerNotebook);

        # MSDP custom commands
        $self->addLabel($table, '<b>MSDP custom commands</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of custom (unofficial) commands supported by the server</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Supported', 'bool',
            'Command', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);      # Fixed height

        # Initialise the list
        $self->msdp1Tab_refreshList(
            $slWidget,
            scalar (@columnList / 2),
            'msdpCustomCmdHash',
        );

        # Add a button
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of commands', undef,
            9, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            $self->msdp1Tab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                'msdpCustomCmdHash',
            );
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub msdp3Tab {

        # Msdp3 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->msdp3Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _3', $innerNotebook);

        # MSDP generic lists
        $self->addLabel($table, '<b>MSDP generic lists</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of generic (official) lists supported by the server</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Supported', 'bool',
            'List', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);      # Fixed height

        # Initialise the list
        $self->msdp1Tab_refreshList(
            $slWidget,
            scalar (@columnList / 2),
            'msdpGenericListHash',
        );

        # Add a button
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of lists', undef,
            9, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            $self->msdp1Tab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                'msdpGenericListHash',
            );
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub msdp4Tab {

        # Msdp4 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->msdp4Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _4', $innerNotebook);

        # MSDP custom lists
        $self->addLabel($table, '<b>MSDP custom lists</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of custom (unofficial) lists supported by the server</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Supported', 'bool',
            'List', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);      # Fixed height

        # Initialise the list
        $self->msdp1Tab_refreshList(
            $slWidget,
            scalar (@columnList / 2),
            'msdpCustomListHash',
        );

        # Add a button
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of lists', undef,
            9, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            $self->msdp1Tab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                'msdpCustomListHash',
            );
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub msdp5Tab {

        # Msdp5 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->msdp5Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _5', $innerNotebook);

        # MSDP generic configurable variables
        $self->addLabel($table, '<b>MSDP generic configurable variables</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of generic (official) configurable variables supported by the server</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Supported', 'bool',
            'Variable', 'text',
            'Value', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);      # Fixed height

        # Initialise the list
        $self->msdp5Tab_refreshList(
            $slWidget,
            scalar (@columnList / 2),
            'msdpGenericConfigFlagHash',
            'msdpGenericConfigValHash',
        );

        # Add a button
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of configurable variables', undef,
            9, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            $self->msdp5Tab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                'msdpGenericConfigFlagHash',
                'msdpGenericConfigValHash',
            );
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub msdp5Tab_refreshList {

        # Resets the simple list displayed by $self->msdp5Tab, etc
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #   $iv, $iv2       - The hash IVs whose key-value pairs should be displayed
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $iv, $iv2, $check) = @_;

        # Local variables
        my (
            @dataList,
            %hash, %hash2,
        );

        # Check for improper arguments
        if (
            ! defined $slWidget || ! defined $columns || ! defined $iv || ! defined $iv2
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->msdp5Tab_refreshList',
                @_,
            );
        }

        # Import the hash IVs
        %hash = $self->session->$iv;
        %hash2 = $self->session->$iv2;

        # Compile the simple list data
        foreach my $key (sort {lc($a) cmp lc($b)} (keys %hash)) {

            push (@dataList,
                $hash{$key},    # Flag
                $key,
                $hash2{$key},   # Value
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub msdp6Tab {

        # Msdp6 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->msdp6Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _6', $innerNotebook);

        # MSDP generic configurable variables
        $self->addLabel($table, '<b>MSDP custom configurable variables</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of custom (unofficial) configurable variables supported by the server</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Supported', 'bool',
            'Variable', 'text',
            'Value', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);      # Fixed height

        # Initialise the list
        $self->msdp5Tab_refreshList(
            $slWidget,
            scalar (@columnList / 2),
            'msdpCustomConfigFlagHash',
            'msdpCustomConfigValHash',
        );

        # Add a button
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of configurable variables', undef,
            9, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            $self->msdp5Tab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                'msdpCustomConfigFlagHash',
                'msdpCustomConfigValHash',
            );
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub msdp7Tab {

        # Msdp7 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->msdp7Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _7', $innerNotebook);

        # MSDP generic configurable variables
        $self->addLabel($table, '<b>MSDP generic reportable variables</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of generic (official) reportable variables supported by the server</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Reportable', 'bool',
            'Reported', 'bool',
            'Sendable', 'bool',
            'Variable', 'text',
            'Value', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);      # Fixed height

        # Initialise the list
        $self->msdp7Tab_refreshList(
            $slWidget,
            scalar (@columnList / 2),
            'msdpGenericReportableFlagHash',
            'msdpGenericReportedFlagHash',
            'msdpGenericSendableFlagHash',
            'msdpGenericValueHash',
        );

        # Add a button
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of reportable variables', undef,
            9, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            $self->msdp7Tab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                'msdpGenericReportableFlagHash',
                'msdpGenericReportedFlagHash',
                'msdpGenericSendableFlagHash',
                'msdpGenericValueHash',
            );
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub msdp7Tab_refreshList {

        # Resets the simple list displayed by $self->msdp7Tab, etc
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #   $iv, $iv2, $iv3, $iv4
        #                   - The hash IVs whose key-value pairs should be displayed
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $iv, $iv2, $iv3, $iv4, $check) = @_;

        # Local variables
        my (
            @dataList,
            %hash, %hash2, %hash3, %hash4, %combHash,
        );

        # Check for improper arguments
        if (
            ! defined $slWidget || ! defined $columns || ! defined $iv || ! defined $iv2
            || ! defined $iv3 || ! defined $iv4 || defined $check
        ) {
            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->msdp7Tab_refreshList',
                @_,
            );
        }

        # Import the hash IVs
        %hash = $self->session->$iv;        # Flag
        %hash2 = $self->session->$iv2;      # Flag
        %hash3 = $self->session->$iv3;      # Flag
        %hash4 = $self->session->$iv4;      # Value

        # (Compile a single hash of keys which exist in all three flag hashes)
        foreach my $key (keys %hash) {

            $combHash{$key} = undef;
        }

        foreach my $key (keys %hash2) {

            $combHash{$key} = undef;
        }

        foreach my $key (keys %hash3) {

            $combHash{$key} = undef;
        }

        # Compile the simple list data
        foreach my $key (sort {lc($a) cmp lc($b)} (keys %combHash)) {

            my $value = $hash4{$key};
            if (defined $value) {

                # $value can be a scalar or a list/hash reference, representing an MSDP embedded
                #   array/table. Reduce this to a single string
                $value = $self->msdp7Tab_parseScalar($value);
            }

            push (@dataList,
                $hash{$key},        # Flag
                $hash2{$key},       # Flag
                $hash3{$key},       # Flag
                $key,
                $value,
            );
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub msdp7Tab_parseScalar {

        # Called by $self->msdp7Tab_refreshList and recursively by ->msdp7Tab_parseScalar,
        #   ->msdp7Tab_parseArray and msdp7Tab_parseTable
        # The value of an MSDP variable can be a scalar, or a list/hash reference representing an
        #   embedded array/table. Call these functions recursively to reduce them all to a single
        #   string we can display in the simple list.
        #
        # Expected arguments
        #   $arg        - A scalar, or a list/hash reference
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the modified string

        my ($self, $arg, $check) = @_;

        # Check for improper arguments
        if (! defined $arg || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->msdp7Tab_parseScalar',
                @_,
            );
        }

        if (ref $arg eq 'HASH') {
            return ' { ' . $self->msdp7Tab_parseTable($arg) . ' }';
        } elsif (ref $arg eq 'ARRAY') {
            return ' ( ' . $self->msdp7Tab_parseArray($arg) . ' )';
        } else {
            return ' ' . $arg;
        }
    }

    sub msdp7Tab_parseArray {

        # Called by $self->msdp7Tab_refreshList and recursively by ->msdp7Tab_parseScalar,
        #   ->msdp7Tab_parseArray and msdp7Tab_parseTable
        # The value of an MSDP variable can be a scalar, or a list/hash reference representing an
        #   embedded array/table. Call these functions recursively to reduce them all to a single
        #   string we can display in the simple list.
        #
        # Expected arguments
        #   $arg        - A list reference
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the modified string

        my ($self, $arg, $check) = @_;

        # Local variables
        my $string;

        # Check for improper arguments
        if (! defined $arg || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->msdp7Tab_parseScalar',
                @_,
            );
        }

        $string = '';
        foreach my $item (@$arg) {

            if (ref $item eq 'HASH') {
                $string .= ' { ' . $self->msdp7Tab_parseTable($item) . ' }';
            } elsif (ref $item eq 'ARRAY') {
                $string .= ' ( ' . $self->msdp7Tab_parseArray($item) . ' )';
            } else {
                $string .= ' ' . $item;
            }
        }

        return $string;
    }

    sub msdp7Tab_parseTable {

        # Called by $self->msdp7Tab_refreshList and recursively by ->msdp7Tab_parseScalar,
        #   ->msdp7Tab_parseArray and msdp7Tab_parseTable
        # The value of an MSDP variable can be a scalar, or a list/hash reference representing an
        #   embedded array/table. Call these functions recursively to reduce them all to a single
        #   string we can display in the simple list.
        #
        # Expected arguments
        #   $arg        - A hash reference
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the modified string

        my ($self, $arg, $check) = @_;

        # Local variables
        my $string;

        # Check for improper arguments
        if (! defined $arg || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->msdp7Tab_parseScalar',
                @_,
            );
        }

        $string = '';
        foreach my $key (sort {lc($a) cmp lc($b)} (keys %$arg)) {

            my $value = $$arg{$key};

            if (ref $value eq 'HASH') {
                $string .= ' ' . $key . ': { ' . $self->msdp7Tab_parseTable($value) . ' }';
            } elsif (ref $value eq 'ARRAY') {
                $string .= ' ' . $key . ': ( ' . $self->msdp7Tab_parseArray($value) . ' )';
            } else {
                $string .= ' ' . $key . ': ' . $value;
            }
        }

        return $string;
    }

    sub msdp8Tab {

        # Msdp8 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->msdp8Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _8', $innerNotebook);

        # MSDP generic configurable variables
        $self->addLabel($table, '<b>MSDP custom reportable variables</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of custom (unofficial) reportable variables supported by the server</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Reportable', 'bool',
            'Reported', 'bool',
            'Sendable', 'bool',
            'Variable', 'text',
            'Value', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);      # Fixed height

        # Initialise the list
        $self->msdp7Tab_refreshList(
            $slWidget,
            scalar (@columnList / 2),
            'msdpCustomReportableFlagHash',
            'msdpCustomReportedFlagHash',
            'msdpCustomSendableFlagHash',
            'msdpCustomValueHash',
        );

        # Add a button
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of reportable variables', undef,
            9, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            $self->msdp7Tab_refreshList(
                $slWidget,
                scalar (@columnList / 2),
                'msdpCustomReportableFlagHash',
                'msdpCustomReportedFlagHash',
                'msdpCustomSendableFlagHash',
                'msdpCustomValueHash',
            );
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub msspTab {

        # Mssp tab - called by $self->setupNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->msspTab', @_);
        }

        # Tab setup
        # Create a notebook within the main one, so that we have two rows of tabs
        my ($vBox, $innerNotebook) = $self->addInnerNotebookTab('M_SSP', $self->notebook);

        # Add tabs to the inner notebook
        $self->mssp1Tab($innerNotebook);
        $self->mssp2Tab($innerNotebook);

        return 1;
    }

    sub mssp1Tab {

        # Mssp1 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->mssp1Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _1', $innerNotebook);

        # MSSP data
        $self->addLabel($table, '<b>MSSP generic data</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of generic (official) MSSP variables for the current connection\'s world</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Variable', 'text',
            'Value', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);      # Fixed height

        # Initialise the list
        $self->mssp1Tab_refreshList($slWidget, (scalar @columnList / 2), 'official');

        # Add a button
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of MSSP variables', undef,
            9, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->mssp1Tab_refreshList($slWidget, (scalar @columnList / 2), 'official');
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub mssp1Tab_refreshList {

        # Resets the simple list displayed by $self->mssp1Tab and ->mssp2Tab
        #
        # Expected arguments
        #   $slWidget   - The Gtk::Ex::Simple::list
        #   $columns    - The number of columns
        #   $type       - 'official' or 'custom'
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $type, $check) = @_;

        # Local variables
        my (
            @dataList,
            %ivHash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->mssp1Tab_refreshList',
                @_,
            );
        }

        # Import the IV from the current world profile
        if ($type eq 'official') {
            %ivHash = $self->session->currentWorld->msspGenericValueHash;
        } else {
            %ivHash = $self->session->currentWorld->msspCustomValueHash;
        }

        # Compile the simple list data
        foreach my $key (sort {lc($a) cmp lc($b)} (keys %ivHash)) {

            push (@dataList, $key, $ivHash{$key});
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub mssp2Tab {

        # Mssp2 tab
        #
        # Expected arguments
        #   $innerNotebook  - The Gtk2::Notebook object inside $self->notebook
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $innerNotebook, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (! defined $innerNotebook || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->mssp2Tab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('Page _2', $innerNotebook);

        # MSSP data
        $self->addLabel($table, '<b>MSSP custom data</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of custom (unofficial) MSSP variables for the current connection\'s world</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Variable', 'text',
            'Value', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 270);      # Fixed height

        # Initialise the list
        $self->mssp1Tab_refreshList($slWidget, (scalar @columnList / 2), 'custom');

        # Add a button
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of MSSP variables', undef,
            9, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            # Refresh the simple list
            $self->mssp1Tab_refreshList($slWidget, (scalar @columnList / 2), 'custom');
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub mxpTab {

        # Mxp tab
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->mxpTab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('M_XP', $self->notebook);

        # MXP entities
        $self->addLabel($table, '<b>MXP entities</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of values stored in MXP entities (some of which may be private)</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Entity name', 'text',
            'Value', 'text',
            'Description', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 300);      # Fixed height

        # Initialise the list
        $self->mxpTab_refreshList($slWidget, scalar (@columnList / 2));

        # Add a button
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of MXP entities', undef,
            9, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            $self->atcpTab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub mxpTab_refreshList {

        # Resets the simple list displayed by $self->mxpTab
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (
            @dataList,
            %hash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->mxpTab_refreshList', @_);
        }

        # Import the hash IV
        %hash = $self->session->mxpEntityHash;

        # Compile the simple list data
        foreach my $key (sort {lc($a) cmp lc($b)} (keys %hash)) {

            my ($entityObj, $value, $descrip);

            $entityObj = $hash{$key};
            if ($entityObj->privateFlag) {
                $value = '<private>';
            } else {
                $value = $entityObj->value;
            }

            if (! defined $entityObj->privateFlag) {
                $descrip = '<not set>';
            } else {
                $descrip = $entityObj->descArg;
            }

            push (@dataList, $entityObj->name, $value, $descrip);
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub atcpTab {

        # Atcp tab
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->atcpTab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('_ATCP', $self->notebook);

        # ATCP data
        $self->addLabel($table, '<b>ATCP data</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of data supplied by the current world using the ATCP protocol</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Package', 'text',
            'Data', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 300);      # Fixed height

        # Initialise the list
        $self->atcpTab_refreshList($slWidget, scalar (@columnList / 2));

        # Add a button
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of ATCP data', undef,
            9, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            $self->atcpTab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub atcpTab_refreshList {

        # Resets the simple list displayed by $self->atcpTab
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (
            @dataList,
            %hash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->atcpTab_refreshList', @_);
        }

        # Import the hash IV
        %hash = $self->session->atcpDataHash;

        # Compile the simple list data
        foreach my $key (sort {lc($a) cmp lc($b)} (keys %hash)) {

            my $dataObj = $hash{$key};

            push (@dataList, $key, $axmud::CLIENT->encodeJson($dataObj->data));
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    sub gmcpTab {

        # Gmcp tab
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my @columnList;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->gmcpTab', @_);
        }

        # Tab setup
        my ($vBox, $table) = $self->addTab('_GMCP', $self->notebook);

        # GMCP data
        $self->addLabel($table, '<b>GMCP data</b>',
            0, 12, 0, 1);
        $self->addLabel($table,
            '<i>List of data supplied by the current world using the GMCP protocol</i>',
            1, 12, 1, 2);

        # Add a simple list
        @columnList = (
            'Package', 'text',
            'Data', 'text',
        );

        my $slWidget = $self->addSimpleList($table, undef, \@columnList,
            1, 12, 2, 10,
            -1, 300);      # Fixed height

        # Initialise the list
        $self->gmcpTab_refreshList($slWidget, scalar (@columnList / 2));

        # Add a button
        my $button = $self->addButton($table,
            'Refresh list', 'Refresh the list of GMCP data', undef,
            9, 12, 10, 11);
        $button->signal_connect('clicked' => sub {

            $self->gmcpTab_refreshList($slWidget, scalar (@columnList / 2));
        });

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    sub gmcpTab_refreshList {

        # Resets the simple list displayed by $self->gmcpTab
        #
        # Expected arguments
        #   $slWidget       - The Gtk::Ex::Simple::list
        #   $columns        - The number of columns
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $slWidget, $columns, $check) = @_;

        # Local variables
        my (
            @dataList,
            %hash,
        );

        # Check for improper arguments
        if (! defined $slWidget || ! defined $columns || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->gmcpTab_refreshList', @_);
        }

        # Import the hash IV
        %hash = $self->session->gmcpDataHash;

        # Compile the simple list data
        foreach my $key (sort {lc($a) cmp lc($b)} (keys %hash)) {

            my $dataObj = $hash{$key};

            push (@dataList, $key, $axmud::CLIENT->encodeJson($dataObj->data));
        }

        # Reset the simple list
        $self->resetListData($slWidget, [@dataList], $columns);

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

{ package Games::Axmud::PrefWin::TaskStart;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::EditWin Games::Axmud::Generic::ConfigWin
        Games::Axmud::Generic::FreeWin Games::Axmud::Generic::Win Games::Axmud
    );

    ##################
    # Constructors

    # Contents of $self->editConfigHash after $self->new has been called:
    #   'type'          => The task type: 'current', 'global_initial', 'profile_initial' or 'custom'
    #   'task_name'     => The task's standard ->name, e.g. 'status_task', 'locator_task'
    #   'prof_name'     => Name of the task's parent profile ('undef' if no parent profile)

#   sub new {}                  # Inherited from GA::Generic::ConfigWin

    ##################
    # Methods

    # Standard window object functions

#   sub winSetup {}             # Inherited from GA::Generic::ConfigWin

#   sub winEnable {}            # Inherited from GA::Generic::ConfigWin

#   sub winDesengage {}         # Inherited from GA::Generic::FreeWin

#   sub winDestroy {}           # Inherited from GA::Generic::FreeWin

#   sub winShowAll {}           # Inherited from GA::Generic::Win

#   sub drawWidgets {}          # Inherited from GA::Generic::ConfigWin

#   sub redrawWidgets {}        # Inherited from GA::Generic::Win

    # ->signal_connects

    # Other functions

#   sub checkEditObj {}         # Inherited from GA::Generic::ConfigWin

    sub enableButtons {

        # Called by $self->drawWidgets
        # Creates the Start task/Cancel buttons at the bottom of the window
        #
        # Expected arguments
        #   $hBox       - The horizontal packing box in which the buttons live
        #   $tooltips   - A Gtk2::Tooltips object for the buttons
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, a list containing the two Gtk::Button objects created

        my ($self, $hBox, $tooltips, $check) = @_;

        # Local variables
        my (
            $type, $taskName, $profName, $radioChoice, $radioChoice2,
            @emptyList,
        );

        # Check for improper arguments
        if (! defined $hBox || ! defined $tooltips || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->enableButtons', @_);
            return @emptyList;
        }

        # Extract keys from $self->editConfigHash
        $type = $self->ivShow('editConfigHash', 'type');
        $taskName = $self->ivShow('editConfigHash', 'task_name');
        $profName = $self->ivShow('editConfigHash', 'prof_name');

        # Create the 'Start task' / 'Add task' button in place of the OK button. For custom tasks,
        #   the button starts desensitised
        my $okButton;
        if ($type eq 'current') {

            # Tasks in the current tasklist
            $okButton = Gtk2::Button->new('Start task');
            $tooltips->set_tip($okButton, 'Start task with these options');

        } else {

            # Tasks not in the current tasklist
            $okButton = Gtk2::Button->new('Add task');
            $tooltips->set_tip($okButton, 'Add task with these options');

            if ($type eq 'custom') {

                $okButton->set_sensitive(FALSE);
            }
        }

        $okButton->signal_connect('clicked' => sub {

            my $cmd;

            # Prepare the client command to execute, e.g. ';starttask -e status_task -f 2000 -w'
            if ($type eq 'current') {

                $cmd = 'starttask ' . $taskName;

            } elsif ($type eq 'global_initial') {

                $cmd = 'addinitialtask ' . $taskName;

            } elsif ($type eq 'profile_initial') {

                $cmd = 'addinitialtask ' . $taskName . ' ' . $profName;

            } elsif ($type eq 'custom') {

                $cmd = 'addcustomtask ' . $taskName . ' ' . $self->ivShow('editHash', 'entry');

            } else {

                return $self->writeError(
                    'Unrecognised task type \'' . $type  . '\'',
                    $self->_objClass . '->setupNotebook',
                );
            }

            if ($self->ivExists('editHash', 'radio_choice')) {

                $radioChoice = $self->ivShow('editHash', 'radio_choice');

                if ($radioChoice == 1 && $self->ivExists('editHash', 'combo')) {
                    $cmd .= ' -e ' . $self->ivShow('editHash', 'combo');
                } elsif ($radioChoice == 2 && $self->ivExists('editHash', 'combo_2')) {
                    $cmd .= ' -n ' . $self->ivShow('editHash', 'combo_2');
                } elsif ($radioChoice == 3 && $self->ivExists('editHash', 'combo_3')) {
                    $cmd .= ' -s ' . $self->ivShow('editHash', 'combo_3');
                } elsif ($radioChoice == 4 && $self->ivExists('editHash', 'entry_2')) {
                    $cmd .= ' -t ' . $self->ivShow('editHash', 'entry_2');
                }
            }

            if ($self->ivExists('editHash', 'radio_choice_2')) {

                $radioChoice2 = $self->ivShow('editHash', 'radio_choice_2');

                if ($radioChoice2 == 1 && $self->ivExists('editHash', 'entry_3')) {
                    $cmd .= ' -f ' . $self->ivShow('editHash', 'entry_3');
                } elsif ($radioChoice2 == 2 && $self->ivExists('editHash', 'entry_4')) {
                    $cmd .= ' -u ' . $self->ivShow('editHash', 'entry_4');
                }
            }

            if ($self->ivExists('editHash', 'check_button')) {

                $cmd .= ' -w';
            }

            # Execute the client command
            $self->session->pseudoCmd($cmd, $self->pseudoCmdMode);

            # Close the 'pref' window
            $self->winDestroy();
        });

        $hBox->pack_end($okButton, 0, 0, $self->borderPixels);

        # Create the cancel button
        my $cancelButton = Gtk2::Button->new('Cancel');
        $cancelButton->signal_connect('clicked' => sub {

            $self->buttonCancel();
        });
        $tooltips->set_tip($cancelButton, 'Cancel');
        $hBox->pack_end($cancelButton, 0, 0, $self->spacingPixels);

        return ($okButton, $cancelButton);
    }

#   sub enableSingleButton {}   # Inherited from GA::Generic::ConfigWin

    sub setupNotebook {

        # Called by $self->winEnable
        # Creates the first tab for the notebook. The remaining tabs are created by
        #   $self->expandNotebook
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my $type;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setupNotebook', @_);
        }

        # Extract data from $self->editConfigHash
        $type = $self->ivShow('editConfigHash', 'type');

        # Tab setup, using the standard table size
        my ($vBox, $table);

        if ($type eq 'current') {

            # Current tasklist tasks
            ($vBox, $table) = $self->addTab('_Current task', $self->notebook);

        } elsif (
            $type eq 'global_initial'
            || $type eq 'profile_initial'
        ) {
            # Initial tasklist tasks
            ($vBox, $table) = $self->addTab('_Initial task', $self->notebook);

        } else {

            # Custom tasklist tasks
            ($vBox, $table) = $self->addTab('Custo_m task', $self->notebook);
        }

        # Set up the rest of the tab
        $self->taskTab($table);

        # Set up the remaining tabs
        $self->expandNotebook();

        # Tab complete
        $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

#   sub expandNotebook {}       # Inherited from GA::Generic::ConfigWin

#   sub saveChanges {}          # Inherited from GA::Generic::ConfigWin

    # Notebook tabs

    sub taskTab {

        # Task tab - called by $self->setupNotebook
        #
        # Expected arguments
        #   $table  - The Gtk2::Table
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $table, $check) = @_;

        # Local variables
        my (
            $type,
            @taskList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->taskTab', @_);
        }

#       # Tab setup (already created by the calling function)
#       my ($vBox, $table) = $self->addTab('_Task', $self->notebook);

        # Get a list of available tasks (actually, the list of task standard names)
        @taskList = sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('taskPackageHash'));
        # Extract data from $self->editConfigHash
        $type = $self->ivShow('editConfigHash', 'type');

        # Start options
        my $entry;
        if ($type eq 'custom') {

            # Custom tasklist tasks
            $self->addLabel($table, '<b>Start options</b> - Custom task name (3-32 chars):',
                0, 8, 0, 1);
            $entry = $self->addEntryWithIcon($table, undef, 'string', 3, 32,
                8, 12, 0, 1);
            $entry->signal_connect('changed' => sub {

                my $text = $entry->get_text();

                if ($self->checkEntryIcon($entry)) {

                    $self->ivAdd('editHash', 'entry', $text);
                    $self->okButton->set_sensitive(TRUE);

                } else {

                    $self->ivDelete('editHash', 'entry');
                    $self->okButton->set_sensitive(FALSE);
                }
            });

        } else {

            # Current tasklist / initial tasklist tasks
            $self->addLabel($table, '<b>Start options</b>',
                0, 12, 0, 1);
        }

        my ($group, $radioButton) = $self->addRadioButton($table, undef, undef, undef, undef, TRUE,
            1, 2, 1, 2);
        $radioButton->signal_connect('toggled' => sub {

            $self->ivAdd('editHash', 'radio_choice', 0);
        });
        $self->addLabel($table, 'Start the task immediately',
            2, 12, 1, 2);

        ($group, $radioButton) = $self->addRadioButton($table, $group, undef, undef, undef, TRUE,
            1, 2, 2, 3);
        $radioButton->signal_connect('toggled' => sub {

            $self->ivAdd('editHash', 'radio_choice', 1);
        });
        $self->addLabel($table, 'Wait for another task to exist, before starting',
            2, 8, 2, 3);
        my $comboBox = $self->addComboBox($table, undef, \@taskList, 'Select task',
            FALSE,              # 'undef' value allowed
            8, 12, 2, 3);
        $comboBox->signal_connect('changed' => sub {

            my $text = $comboBox->get_active_text();

            if ($text ne 'Select task') {
                $self->ivAdd('editHash', 'combo', $text);
            } else {
                $self->ivDelete('editHash', 'combo');
            }
        });

        ($group, $radioButton) = $self->addRadioButton($table, $group, undef, undef, undef, TRUE,
            1, 2, 3, 4);
        $radioButton->signal_connect('toggled' => sub {

            $self->ivAdd('editHash', 'radio_choice', 2);
        });
        $self->addLabel($table, 'Wait for another task to not exist, before starting',
            2, 8, 3, 4);
        my $comboBox2 = $self->addComboBox($table, undef, \@taskList, 'Select task',
            FALSE,              # 'undef' value allowed
            8, 12, 3, 4);
        $comboBox2->signal_connect('changed' => sub {

            my $text = $comboBox2->get_active_text();

            if ($text ne 'Select task') {
                $self->ivAdd('editHash', 'combo_2', $text);
            } else {
                $self->ivDelete('editHash', 'combo_2');
            }
        });

        ($group, $radioButton) = $self->addRadioButton($table, $group, undef, undef, undef, TRUE,
            1, 2, 4, 5);
        $radioButton->signal_connect('toggled' => sub {

            $self->ivAdd('editHash', 'radio_choice', 3);
        });
        $self->addLabel($table, 'Wait for another task to start/stop, before starting',
            2, 8, 4, 5);
        my $comboBox3 = $self->addComboBox($table, undef, \@taskList, 'Select task',
            FALSE,              # 'undef' value allowed
            8, 12, 4, 5);
        $comboBox3->signal_connect('changed' => sub {

            my $text = $comboBox3->get_active_text();

            if ($text ne 'Select task') {
                $self->ivAdd('editHash', 'combo_3', $text);
            } else {
                $self->ivDelete('editHash', 'combo_3');
            }
        });

        ($group, $radioButton) = $self->addRadioButton($table, $group, undef, undef, undef, TRUE,
            1, 2, 5, 6);
        $radioButton->signal_connect('toggled' => sub {

            $self->ivAdd('editHash', 'radio_choice', 4);
        });
        $self->addLabel($table, 'Start the task after this many minutes:',
            2, 8, 5, 6);
        my $entry2 = $self->addEntryWithIcon($table, undef, 'int', 0, 10080,        # 7 days
            8, 12, 5, 6);
        $entry2->signal_connect('changed' => sub {

            my $text = $entry2->get_text();

            if ($self->checkEntryIcon($entry2)) {
                $self->ivAdd('editHash', 'entry_2', $text);
            } else {
                $self->ivDelete('editHash', 'entry_2');
            }
        });

        # Group 2 switches
        $self->addLabel($table, '<b>Stop options</b>',
            0, 12, 6, 7);

        ($group, $radioButton) = $self->addRadioButton($table, undef, undef, undef, undef, TRUE,
            1, 2, 7, 8);
        $radioButton->signal_connect('toggled' => sub {

            $self->ivAdd('editHash', 'radio_choice_2', 0);
        });
        $self->addLabel($table, 'Run the task for an unlimited amount of time',
            2, 12, 7, 8);

        ($group, $radioButton) = $self->addRadioButton($table, $group, undef, undef, undef, TRUE,
            1, 2, 8, 9);
        $radioButton->signal_connect('toggled' => sub {

            $self->ivAdd('editHash', 'radio_choice_2', 1);
        });
        $self->addLabel($table, 'Run the task for this many minutes:',
            2, 8, 8, 9);
        my $entry3 = $self->addEntryWithIcon($table, undef, 'int', 0, 10080,        # 7 days
            8, 12, 8, 9);
        $entry3->signal_connect('changed' => sub {

            my $text = $entry3->get_text();

            if ($self->checkEntryIcon($entry3)) {
                $self->ivAdd('editHash', 'entry_3', $text);
            } else {
                $self->ivDelete('editHash', 'entry_3');
            }
        });

        ($group, $radioButton) = $self->addRadioButton($table, $group, undef, undef, undef, TRUE,
            1, 2, 9, 10);
        $radioButton->signal_connect('toggled' => sub {

            $self->ivAdd('editHash', 'radio_choice_2', 2);
        });
        $self->addLabel($table,
            'Run the task until the task loop time reaches:',
            2, 12, 9, 10);
        my $entry4 = $self->addEntryWithIcon($table, undef, 'int', 0, 604800,       # 7 days
            8, 12, 9, 10);
        $entry4->signal_connect('changed' => sub {

            my $text = $entry4->get_text();

            if ($self->checkEntryIcon($entry4)) {
                $self->ivAdd('editHash', 'entry_4', $text);
            } else {
                $self->ivDelete('editHash', 'entry_4');
            }
        });

        # Group 3 switches
        $self->addLabel($table, '<b>Task window options</b>',
            0, 12, 10, 11);

        my $checkButton = $self->addCheckButton($table, undef, TRUE,
            1, 2, 11, 12);
        $checkButton->signal_connect('toggled' => sub {

            if ($checkButton->get_active()) {
                $self->ivAdd('editHash', 'check_button', TRUE);
            } else {
                $self->ivDelete('editHash', 'check_button');
            }
        });
        $self->addLabel($table,
            'Task runs <i>without</i> opening a task window (if it normally uses one)',
            2, 12, 11, 12);

#       # Tab complete (handled by the calling function)
#       $vBox->pack_start($table, 0, 0, 0);

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

# Package must return true
1
