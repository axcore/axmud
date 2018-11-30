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
# Games::Axmud::Strip::xxx
# Objects handling strips within an 'internal' window's client area

{ package Games::Axmud::Strip::MenuBar;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Strip Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Win::Internal->drawWidgets or ->addStripObj
        # Creates the GA::Strip::MenuBar - a non-compulsory strip object containing a Gtk2::MenuBar
        #
        # Expected arguments
        #   $number     - The strip object's number within the parent window (matches
        #                   GA::Win::Internal->stripCount, or -1 for a temporary strip object
        #                   created to access its default IVs)
        #   $winObj     - The parent window object (GA::Win::Internal). 'temp' for temporary strip
        #                   objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the strip object's
        #                   initialisation settings. The strip object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - (This type of strip object requires no initialisation settings)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $winObj, %initHash) = @_;

        # Local variables
        my %modHash;

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $winObj) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'strip_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard strip object IVs
            # -------------------------

            # The strip object's number within the parent window (matches
            #   GA::Win::Internal->stripCount, or -1 for a temporary strip object created to access
            #   its default IVs)
            number                      => $number,
            # The type of strip object (custom strip objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in strip objects)
            type                        => 'menu_bar',
            # The parent window object (GA::Win::Internal). 'temp' for temporary strip objects
            winObj                      => $winObj,

            # Flag set to TRUE if the strip object is visible (has actually drawn widgets in the
            #   window), set to FALSE if it is not visible (has drawn no widgets in the window, but
            #   still exists in GA::Win::Internal->stripHash, etc)
            # The flag might be set to FALSE in strip objects like GA::Strip::GaugeBox, which might
            #   have gauges to draw, or not, depending on current conditions. (Most strip objects
            #   have this flag set to TRUE all the time)
            # If FALSE, GA::Win::Internal->drawWidgets and ->addStripObj don't draw any widgets when
            #   called by this object's functions
            # NB Strip objects are created with this flag set to TRUE or FALSE, but once created,
            #   the flag's value shouldn't be modified by anything other than
            #   GA::Win::Internal->hideStripObj and ->revealStripObj (which in turn call
            #   $self->set_visibleFlag)
            visibleFlag                 => TRUE,
            # Flag set to TRUE is the strip object should be given its share of any extra space
            #   within the packing box (the extra space is divided equally between all children of
            #   the box whose ->expandFlag is TRUE)
            expandFlag                  => FALSE,
            # Flag set to TRUE if any space given to the strip object by the 'expand' option is
            #   actually allocated within the strip object, FALSE if it is used as padding outside
            #   it (on both sides)
            fillFlag                    => FALSE,
            # Flag set to TRUE if the strip object should be packed into its window with a small
            #   gap between strip objects to either side; FALSE if not (can be set to FALSE if the
            #   the strip object's widgets are drawn in a way, such that a gap is not necessary,
            #   for example in the toolbar strip object)
            spacingFlag                 => TRUE,
            # Flag set to TRUE if only one instance of this strip object should be added to the
            #   parent window, set to FALSE if any number of instances can be added
            jealousyFlag                => TRUE,
            # Flag set to TRUE if this strip object can be added when $axmud::BLIND_MODE_FLAG is
            #   TRUE, FALSE if it can't be added (because it's not useful for visually-impaired
            #   users)
            blindFlag                   => FALSE,
            # Flag set to TRUE if the main container widget, stored in $self->packingBox, should be
            #   allowed to accept the focus, FALSE if not. The restriction is applied during the
            #   call to GA::Win::Internal->drawWidgets and ->addStripObj. Even if FALSE, widgets in
            #   the container widget can be set to accept the focus (e.g. the Gtk2::Entry in
            #   GA::Strip::MenuBar)
            allowFocusFlag              => FALSE,

            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of strip object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this strip object and
            #   its widget(s). Can be any value, including 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => undef,

            # The container widget for this strip object (usually a Gtk2::HBox or Gtk2::VBox). This
            #   widget is the one added to the window's main Gtk2::HBox or Gtk2::VBox
            packingBox                  => undef,       # Gtk2::VBox

            # Other IVs
            # ---------

            # Widgets
            menuBar                     => undef,       # Gtk2::MenuBar

            # Menu items which will be sensitised or desensitised, depending on the context. Hash
            #   in the form:
            #       $menuItemHash{'item_name'} = gtk2_widget
            #   ...where:
            #       'item_name' is a descriptive scalar, e.g. 'move_up_level'
            #       'gtk2_widget' is the Gtk2 menu item
            menuItemHash                => {},

            # The menu column for 'plugins', which can be extended by any loaded plugins
            pluginMenu                  => undef,       # Gtk2::Menu
            # Hash of sub-menus in the 'plugins' menu column, one for each plugin that wants one, in
            #   the form
            #       $pluginHash{plugin_name} = menu_widget
            pluginHash                  => {},
            # Additional list of menu items added by plugins, which will be sensitised or
            #   desensitised, depending on the context. Hash in the form:
            #       $pluginMenuItemHash{'plugin_name'} = gtk2_widget
            pluginMenuItemHash          => {},

            # Flag set to TRUE when the 'save all sessions' menu item is selected (desensitises
            #   some other menu items)
            saveAllSessionsFlag         => FALSE,
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard strip object functions

    sub objEnable {

        # Called by GA::Win::Internal->drawWidgets or ->addStripObj
        # Sets up the strip object's widgets
        #
        # Expected arguments
        #   $winmapObj  - The winmap object (GA::Obj::Winmap) that specifies the layout of the
        #                   parent window
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $winmapObj, $check) = @_;

        # Check for improper arguments
        if (! defined $winmapObj || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Create a packing box
        my $vBox = Gtk2::VBox->new(FALSE, 0);
        $vBox->set_border_width(0);

        # Create a Gtk2::MenuBar
        my $menuBar = Gtk2::MenuBar->new();
        $vBox->pack_start($menuBar, TRUE, TRUE, 0);

        # 'World' column
        my $menuColumn_world = $self->drawWorldColumn();
        my $menuItem_world = Gtk2::MenuItem->new('_World');
        $menuItem_world->set_submenu($menuColumn_world);
        $menuBar->append($menuItem_world);

        # 'File' column
        my $menuColumn_file = $self->drawFileColumn();
        my $menuItem_file = Gtk2::MenuItem->new('_File');
        $menuItem_file->set_submenu($menuColumn_file);
        $menuBar->append($menuItem_file);

        # 'Edit' column
        my $menuColumn_edit = $self->drawEditColumn();
        my $menuItem_edit = Gtk2::MenuItem->new('_Edit');
        $menuItem_edit->set_submenu($menuColumn_edit);
        $menuBar->append($menuItem_edit);

        # 'Interfaces' column
        my $menuColumn_interfaces = $self->drawInterfacesColumn();
        my $menuItem_interfaces = Gtk2::MenuItem->new('_Interfaces');
        $menuItem_interfaces->set_submenu($menuColumn_interfaces);
        $menuBar->append($menuItem_interfaces);

        # 'Tasks' column
        my $menuColumn_tasks = $self->drawTasksColumn();
        my $menuItem_tasks = Gtk2::MenuItem->new('_Tasks');
        $menuItem_tasks->set_submenu($menuColumn_tasks);
        $menuBar->append($menuItem_tasks);

        # 'Display' column
        my $menuColumn_display = $self->drawDisplayColumn();
        my $menuItem_display = Gtk2::MenuItem->new('_Display');
        $menuItem_display->set_submenu($menuColumn_display);
        $menuBar->append($menuItem_display);

        # 'Commands' column
        my $menuColumn_commands = $self->drawCommandsColumn();
        my $menuItem_commands = Gtk2::MenuItem->new('_Commands');
        $menuItem_commands->set_submenu($menuColumn_commands);
        $menuBar->append($menuItem_commands);

        # 'Recordings' column
        my $menuColumn_recordings = $self->drawRecordingsColumn();
        my $menuItem_recordings = Gtk2::MenuItem->new('_Recordings');
        $menuItem_recordings->set_submenu($menuColumn_recordings);
        $menuBar->append($menuItem_recordings);

        # 'Axbasic' column
        my $menuColumn_basic = $self->drawAxbasicColumn();
        my $menuItem_basic = Gtk2::MenuItem->new('_' . $axmud::BASIC_NAME);
        $menuItem_basic->set_submenu($menuColumn_basic);
        $menuBar->append($menuItem_basic);

        # 'Plugins' column
        my $menuColumn_plugins = $self->drawPluginsColumn();
        my $menuItem_plugins = Gtk2::MenuItem->new('_Plugins');
        $menuItem_plugins->set_submenu($menuColumn_plugins);
        $menuBar->append($menuItem_plugins);

        # 'Help' column
        my $menuColumn_help = $self->drawHelpColumn();
        my $menuItem_help = Gtk2::MenuItem->new('_Help');
        $menuItem_help->set_submenu($menuColumn_help);
        $menuBar->append($menuItem_help);

        # Update IVs
        $self->ivPoke('packingBox', $vBox);
        $self->ivPoke('menuBar', $menuBar);
        $self->ivPoke('pluginMenu', $menuColumn_plugins);

        # If any plugins have registered their desire to create sub-menus, call those plugins and
        #   create the sub-menus now
        foreach my $pluginObj (sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivValues('pluginHash'))) {

            my ($funcRef, $subMenu);

            if (
                $pluginObj->enabledFlag
                && $axmud::CLIENT->ivExists('pluginMenuFuncHash', $pluginObj->name)
            ) {
                $funcRef = $axmud::CLIENT->ivShow('pluginMenuFuncHash', $pluginObj->name);
                $subMenu = $self->addPluginWidgets($pluginObj->name);

                if ($funcRef && $subMenu) {

                    &$funcRef($self, $subMenu);
                }
            }
        }

        # Sensitise/desensitise menu bar/toolbar items, depending on current conditions
        $axmud::CLIENT->desktopObj->restrictWidgets();

        return 1;
    }

    sub objDestroy {

        # Called by GA::Win::Internal->removeStripObj, just before the strip is removed from its
        #   parent window, and also by ->winDestroy and ->resetWinmap, to give this object a chance
        #   to do any necessary tidying up
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objDestroy', @_);
        }

        # (No tidying up required for this type of strip object)
        #   ...

        return 1;
    }

#   sub setWidgetsIfSession {}              # Inherited from GA::Generic::Strip

#   sub setWidgetsChangeSession {}          # Inherited from GA::Generic::Strip

    # ->signal_connects are stored in $self->drawWorldColumn, etc

    # Other functions

    sub drawWorldColumn {

        # Called by $self->enableMenu
        # Sets up the menu's 'World' column
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or if the menu can't be created
        #   Otherwise returns the Gtk2::Menu created

        my ($self, $check) = @_;

        # Local variables
        my $mode;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawWorldColumn', @_);
        }

        # Import IVs (for convenience)
        $mode = $self->winObj->pseudoCmdMode;

        # Set up column
        my $menuColumn_world = Gtk2::Menu->new();
        if (! $menuColumn_world) {

            return undef;
        }

        my $menuItem_connect = Gtk2::ImageMenuItem->new('_Connect...');
        my $menuImg_connect = Gtk2::Image->new_from_stock('gtk-connect', 'menu');
        $menuItem_connect->set_image($menuImg_connect);
        $menuItem_connect->signal_connect('activate' => sub {

            my $winObj;

            if ($self->winObj->visibleSession) {

                $self->winObj->visibleSession->pseudoCmd('connect', $mode);

            } else {

                # Can't use ';connect' because the parent window has no visible session

                # Check that the Connections window isn't already open
                if ($axmud::CLIENT->connectWin) {

                    # Window already open; draw attention to the fact by 'present'ing it
                    $axmud::CLIENT->connectWin->restoreFocus();

                } else {

                    # Open the Connections window
                    $winObj = $self->winObj->quickFreeWin(
                        'Games::Axmud::OtherWin::Connect',
                        $self->winObj->visibleSession,
                    );

                    if ($winObj) {

                        # Only one Connections window can be open at a time
                        $axmud::CLIENT->set_connectWin($winObj);
                    }
                }
            }
        });
        $menuColumn_world->append($menuItem_connect);

        my $menuItem_reconnect = Gtk2::ImageMenuItem->new('_Reconnect');
        my $menuImg_reconnect = Gtk2::Image->new_from_stock('gtk-connect', 'menu');
        $menuItem_reconnect->set_image($menuImg_reconnect);
        $menuItem_reconnect->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('reconnect', $mode);
        });
        $menuColumn_world->append($menuItem_reconnect);
        # (Requires a visible session)
        $self->ivAdd('menuItemHash', 'reconnect', $menuItem_reconnect);

        my $menuItem_reconnectOffline = Gtk2::MenuItem->new('Reconnect _offline');
        $menuItem_reconnectOffline->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('reconnect -o', $mode);
        });
        $menuColumn_world->append($menuItem_reconnectOffline);
        # (Requires a visible session)
        $self->ivAdd('menuItemHash', 'reconnect_offline', $menuItem_reconnectOffline);

        my $menuItem_xConnect = Gtk2::MenuItem->new('Reconnect (no _save)');
        $menuItem_xConnect->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('xconnect', $mode);
        });
        $menuColumn_world->append($menuItem_xConnect);
        # (Requires a visible session)
        $self->ivAdd('menuItemHash', 'xconnect', $menuItem_xConnect);

        my $menuItem_xConnectOffline = Gtk2::MenuItem->new('Reconnect offline (_no save)');
        $menuItem_xConnectOffline->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('xconnect -o', $mode);
        });
        $menuColumn_world->append($menuItem_xConnectOffline);
        # (Requires a visible session)
        $self->ivAdd('menuItemHash', 'xconnect_offline', $menuItem_xConnectOffline);

        $menuColumn_world->append(Gtk2::SeparatorMenuItem->new());   # Separator

        my $menuItem_login = Gtk2::ImageMenuItem->new('Character _login');
        my $menuImg_login = Gtk2::Image->new_from_stock('gtk-network', 'menu');
        $menuItem_login->set_image($menuImg_login);
        $menuItem_login->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('login', $mode);
        });
        $menuColumn_world->append($menuItem_login);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'login', $menuItem_login);

        $menuColumn_world->append(Gtk2::SeparatorMenuItem->new());   # Separator

        my $menuItem_quit = Gtk2::ImageMenuItem->new('Send _quit');
        my $menuImg_quit = Gtk2::Image->new_from_stock('gtk-disconnect', 'menu');
        $menuItem_quit->set_image($menuImg_quit);
        $menuItem_quit->signal_connect('activate' => sub {

            if (
                $self->promptUser(
                    'Confirm quit',
                    'Are you sure you want to send the \'quit\' command?',
                )
            ) {
                $self->winObj->visibleSession->pseudoCmd('quit', $mode);
            }
        });
        $menuColumn_world->append($menuItem_quit);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'quit', $menuItem_quit);

        my $menuItem_qquit = Gtk2::MenuItem->new('Send quit (no sa_ve)');
        $menuItem_qquit->signal_connect('activate' => sub {

            if (
                $self->promptUser(
                    'Confirm quit',
                    'Are you sure you want to send the \'quit\' command without saving?',
                )
            ) {
                $self->winObj->visibleSession->pseudoCmd('qquit', $mode);
            }
        });
        $menuColumn_world->append($menuItem_qquit);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'qquit', $menuItem_qquit);

        my $menuItem_quitAll = Gtk2::MenuItem->new('Send quit (_all sessions)');
        $menuItem_quitAll->signal_connect('activate' => sub {

            if (
                $self->promptUser(
                    'Confirm quit',
                    'Are you sure you want to send the \'quit\' command in all sessions?',
                )
            ) {
                $self->winObj->visibleSession->pseudoCmd('quitall', $mode);
            }
        });
        $menuColumn_world->append($menuItem_quitAll);
        # (Requires a visible session)
        $self->ivAdd('menuItemHash', 'quit_all', $menuItem_quitAll);

        $menuColumn_world->append(Gtk2::SeparatorMenuItem->new());   # Separator

        my $menuItem_exit = Gtk2::ImageMenuItem->new('_Exit session');
        my $menuImg_exit = Gtk2::Image->new_from_stock('gtk-disconnect', 'menu');
        $menuItem_exit->set_image($menuImg_exit);
        $menuItem_exit->signal_connect('activate' => sub {

            if (
                $self->promptUser(
                    'Confirm exit',
                    'Are you sure you want to exit this session?',
                )
            ) {
                $self->winObj->visibleSession->pseudoCmd('exit', $mode);
            }
        });
        $menuColumn_world->append($menuItem_exit);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'exit', $menuItem_exit);

        my $menuItem_xxit = Gtk2::MenuItem->new('E_xit session (no save)');
        $menuItem_xxit->signal_connect('activate' => sub {

            if (
                $self->promptUser(
                    'Confirm exit',
                    'Are you sure you want to exit this session without saving?',
                )
            ) {
                $self->winObj->visibleSession->pseudoCmd('xxit', $mode);
            }
        });
        $menuColumn_world->append($menuItem_xxit);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'xxit', $menuItem_xxit);

        my $menuItem_exitAll = Gtk2::MenuItem->new('Ex_it all sessions');
        $menuItem_exitAll->signal_connect('activate' => sub {

            if (
                $self->promptUser(
                    'Confirm exit',
                    'Are you sure you want to exit every session?',
                )
            ) {
                $self->winObj->visibleSession->pseudoCmd('exitall', $mode);
            }
        });
        $menuColumn_world->append($menuItem_exitAll);
        # (Requires a visible session)
        $self->ivAdd('menuItemHash', 'exit_all', $menuItem_exitAll);

        $menuColumn_world->append(Gtk2::SeparatorMenuItem->new());   # Separator

        my $menuItem_stopSession = Gtk2::ImageMenuItem->new('S_top session');
        my $menuImg_stopSession = Gtk2::Image->new_from_stock('gtk-close', 'menu');
        $menuItem_stopSession->set_image($menuImg_stopSession);
        $menuItem_stopSession->signal_connect('activate' => sub {

            # If the current session's status isn't 'offline' or 'disconnected' or if there are
            #   any unsaved files (both for the session, and for the client), prompt the user
            #   before stopping the session (which closes the tab); otherwise, stop the session
            #   right away
            if (
                $axmud::CLIENT->checkSessions($self->winObj->visibleSession)
                || $self->promptUser(
                    'Confirm stop session',
                    'Are you sure you want to stop this session?',
                )
            ) {
                $self->winObj->visibleSession->pseudoCmd('stopsession', $mode);
            }
        });
        $menuColumn_world->append($menuItem_stopSession);
        # (Requires a visible session)
        $self->ivAdd('menuItemHash', 'stop_session', $menuItem_stopSession);

        my $menuItem_stopClient = Gtk2::ImageMenuItem->new('Sto_p client');
        my $menuImg_stopClient = Gtk2::Image->new_from_stock('gtk-quit', 'menu');
        $menuItem_stopClient->set_image($menuImg_stopClient);
        $menuItem_stopClient->signal_connect('activate' => sub {

            # If there are any connected sessions or unsaved files, prompt the user before executing
            #   the client command; otherwise go ahead and do the ';stopclient' operation
            if (
                $axmud::CLIENT->checkSessions()
                || $self->promptUser(
                    'Confirm stop client',
                    'Are you sure you want to close the ' . $axmud::SCRIPT . ' client?',
                )
            ) {
                if ($self->winObj->visibleSession) {

                    $self->winObj->visibleSession->pseudoCmd('stopclient', $mode);

                } else {

                    # Can't use ';stopclient' because there is no current session
                    $axmud::CLIENT->stop();
                }
            }
        });
        $menuColumn_world->append($menuItem_stopClient);

        # Setup complete
        return $menuColumn_world;
    }

    sub drawFileColumn {

        # Called by $self->enableMenu
        # Sets up the menu's 'File' column
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or if the menu can't be created
        #   Otherwise returns the Gtk2::Menu created

        my ($self, $check) = @_;

        # Local variables
        my ($mode, $forceSwitch, $allSessionSwitch);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawFileColumn', @_);
        }

        # Import IVs (for convenience)
        $mode = $self->winObj->pseudoCmdMode;

        # A pair of radio buttons toggle the value of this string between '' and ' -f', used with
        #   the ';save' command
        $forceSwitch = '';
        # Another pair of buttons toggle the value of this string between '' and ' -a', used with
        #   the ';save' command
        $allSessionSwitch = '';

        # Set up column
        my $menuColumn_file = Gtk2::Menu->new();
        if (! $menuColumn_file) {

            return undef;
        }

        my $menuItem_loadAll = Gtk2::ImageMenuItem->new('_Load all');
        my $menuImg_loadAll = Gtk2::Image->new_from_stock('gtk-open', 'menu');
        $menuItem_loadAll->set_image($menuImg_loadAll);
        $menuItem_loadAll->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('load', $mode);
        });
        $menuColumn_file->append($menuItem_loadAll);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'load_all', $menuItem_loadAll);

            # 'Load files' submenu
            my $subMenu_loadFile = Gtk2::Menu->new();

            my $menuItem_loadFile_worldModel = Gtk2::MenuItem->new('_World model file');
            $menuItem_loadFile_worldModel->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('load -m', $mode);
            });
            $subMenu_loadFile->append($menuItem_loadFile_worldModel);

            my $menuItem_loadFile_tasks = Gtk2::MenuItem->new('_Tasks file');
            $menuItem_loadFile_tasks->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('load -t', $mode);
            });
            $subMenu_loadFile->append($menuItem_loadFile_tasks);

            my $menuItem_loadFile_scripts = Gtk2::MenuItem->new('_Scripts file');
            $menuItem_loadFile_scripts->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('load -s', $mode);
            });
            $subMenu_loadFile->append($menuItem_loadFile_scripts);

            my $menuItem_loadFile_contacts = Gtk2::MenuItem->new('_Contacts file');
            $menuItem_loadFile_contacts->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('load -n', $mode);
            });
            $subMenu_loadFile->append($menuItem_loadFile_contacts);

            my $menuItem_loadFile_dicts = Gtk2::MenuItem->new('_Dictionaries file');
            $menuItem_loadFile_dicts->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('load -y', $mode);
            });
            $subMenu_loadFile->append($menuItem_loadFile_dicts);

            my $menuItem_loadFile_toolbar = Gtk2::MenuItem->new('Tool_bar file');
            $menuItem_loadFile_toolbar->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('load -b', $mode);
            });
            $subMenu_loadFile->append($menuItem_loadFile_toolbar);

            my $menuItem_loadFile_userComm = Gtk2::MenuItem->new('_User commands file');
            $menuItem_loadFile_userComm->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('load -u', $mode);
            });
            $subMenu_loadFile->append($menuItem_loadFile_userComm);

            my $menuItem_loadFile_zonemaps = Gtk2::MenuItem->new('_Zonemaps file');
            $menuItem_loadFile_zonemaps->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('load -z', $mode);
            });
            $subMenu_loadFile->append($menuItem_loadFile_zonemaps);

            my $menuItem_loadFile_winmaps = Gtk2::MenuItem->new('Winma_ps file');
            $menuItem_loadFile_winmaps->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('load -p', $mode);
            });
            $subMenu_loadFile->append($menuItem_loadFile_winmaps);

            my $menuItem_loadFile_ttsObjs = Gtk2::MenuItem->new('Te_xt-to-speech file');
            $menuItem_loadFile_ttsObjs->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('load -x', $mode);
            });
            $subMenu_loadFile->append($menuItem_loadFile_ttsObjs);

        my $menuItem_loadFile = Gtk2::MenuItem->new('L_oad files');
        $menuItem_loadFile->set_submenu($subMenu_loadFile);
        $menuColumn_file->append($menuItem_loadFile);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'load_file', $menuItem_loadFile);

        $menuColumn_file->append(Gtk2::SeparatorMenuItem->new());   # Separator

        my $menuItem_saveAll = Gtk2::ImageMenuItem->new('_Save all');
        my $menuImg_saveAll = Gtk2::Image->new_from_stock('gtk-save', 'menu');
        $menuItem_saveAll->set_image($menuImg_saveAll);
        $menuItem_saveAll->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd(
                'save ' . $forceSwitch . $allSessionSwitch,
                $mode,
            );
        });
        $menuColumn_file->append($menuItem_saveAll);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'save_all', $menuItem_saveAll);

            # 'Save files' submenu
            my $subMenu_saveFile = Gtk2::Menu->new();

            my $menuItem_saveFile_config = Gtk2::MenuItem->new('C_onfig file');
            $menuItem_saveFile_config->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('save -i' . $forceSwitch, $mode);
            });
            $subMenu_saveFile->append($menuItem_saveFile_config);

            $subMenu_saveFile->append(Gtk2::SeparatorMenuItem->new());  # Separator

            my $menuItem_saveFile_prof = Gtk2::MenuItem->new('_Profile files');
            $menuItem_saveFile_prof->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('save -d' . $forceSwitch, $mode);
            });
            $subMenu_saveFile->append($menuItem_saveFile_prof);

            my $menuItem_saveFile_currentProf = Gtk2::MenuItem->new('Cu_rrent profile files');
            $menuItem_saveFile_currentProf->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('save -c' . $forceSwitch, $mode);
            });
            $subMenu_saveFile->append($menuItem_saveFile_currentProf);

            my $menuItem_saveFile_worldProf = Gtk2::MenuItem->new('World de_finition...');
            $menuItem_saveFile_worldProf->signal_connect('activate' => sub {

                # Display a 'dialogue' window, so the user can choose a world profile
                my (
                    $choice,
                    @worldList,
                );

                # Get an ordered list of all world profiles
                @worldList = $self->getWorldList();
                if (@worldList) {

                    # Display the dialogue
                    $choice = $self->winObj->showComboDialogue(
                        'Save file',
                        'Select a world profile to save',
                        FALSE,
                        \@worldList,
                    );

                    if ($choice) {

                        # Save the file
                        $self->winObj->visibleSession->pseudoCmd(
                            'save -o ' . $choice . $forceSwitch,
                            $mode,
                        );
                    }
                }
            });
            $subMenu_saveFile->append($menuItem_saveFile_worldProf);

            my $menuItem_saveFile_currentWorld = Gtk2::MenuItem->new('Curre_nt world files');
            $menuItem_saveFile_currentWorld->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('save -w' . $forceSwitch, $mode);
            });
            $subMenu_saveFile->append($menuItem_saveFile_currentWorld);

            $subMenu_saveFile->append(Gtk2::SeparatorMenuItem->new());  # Separator

            my $menuItem_saveFile_worldModel = Gtk2::MenuItem->new('_World model file');
            $menuItem_saveFile_worldModel->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('save -m' . $forceSwitch, $mode);
            });
            $subMenu_saveFile->append($menuItem_saveFile_worldModel);

            my $menuItem_saveFile_tasks = Gtk2::MenuItem->new('_Tasks file');
            $menuItem_saveFile_tasks->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('save -t' . $forceSwitch, $mode);
            });
            $subMenu_saveFile->append($menuItem_saveFile_tasks);

            my $menuItem_saveFile_scripts = Gtk2::MenuItem->new('_Scripts file');
            $menuItem_saveFile_scripts->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('save -s' . $forceSwitch, $mode);
            });
            $subMenu_saveFile->append($menuItem_saveFile_scripts);

            my $menuItem_saveFile_contacts = Gtk2::MenuItem->new('_Contacts file');
            $menuItem_saveFile_contacts->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('save -n' . $forceSwitch, $mode);
            });
            $subMenu_saveFile->append($menuItem_saveFile_contacts);

            my $menuItem_saveFile_dicts = Gtk2::MenuItem->new('_Dictionaries file');
            $menuItem_saveFile_dicts->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('save -y' . $forceSwitch, $mode);
            });
            $subMenu_saveFile->append($menuItem_saveFile_dicts);

            my $menuItem_saveFile_toolbar = Gtk2::MenuItem->new('Tool_bar file');
            $menuItem_saveFile_toolbar->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('save -b' . $forceSwitch, $mode);
            });
            $subMenu_saveFile->append($menuItem_saveFile_toolbar);

            my $menuItem_saveFile_userComm = Gtk2::MenuItem->new('_User commands file');
            $menuItem_saveFile_userComm->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('save -u' . $forceSwitch, $mode);
            });
            $subMenu_saveFile->append($menuItem_saveFile_userComm);

            my $menuItem_saveFile_zonemaps = Gtk2::MenuItem->new('_Zonemaps file');
            $menuItem_saveFile_zonemaps->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('save -z' . $forceSwitch, $mode);
            });
            $subMenu_saveFile->append($menuItem_saveFile_zonemaps);

            my $menuItem_saveFile_winmaps = Gtk2::MenuItem->new('Winma_ps file');
            $menuItem_saveFile_winmaps->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('save -p' . $forceSwitch, $mode);
            });
            $subMenu_saveFile->append($menuItem_saveFile_winmaps);

            my $menuItem_saveFile_ttsObjs = Gtk2::MenuItem->new('Te_xt-to-speech file');
            $menuItem_saveFile_ttsObjs->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('save -x' . $forceSwitch, $mode);
            });
            $subMenu_saveFile->append($menuItem_saveFile_ttsObjs);

        my $menuItem_saveFile = Gtk2::MenuItem->new('S_ave files');
        $menuItem_saveFile->set_submenu($subMenu_saveFile);
        $menuColumn_file->append($menuItem_saveFile);
        # (Requires a visible session whose status is 'connected' or 'offline' and
        #   $self->saveAllSessionsFlag set to FALSE)
        $self->ivAdd('menuItemHash', 'save_file', $menuItem_saveFile);

            # 'Save options' submenu
            my $subMenu_saveOptions = Gtk2::Menu->new();

            my $menuColumn_forced_radio1 = Gtk2::RadioMenuItem->new(undef, 'Forced saves o_ff');
            $menuColumn_forced_radio1->signal_connect('toggled' => sub {

                if ($menuColumn_forced_radio1->get_active()) {
                    $forceSwitch = '';
                } else {
                    $forceSwitch = ' -f';
                }
            });
            $subMenu_saveOptions->append($menuColumn_forced_radio1);

            my $menuColumn_forced_radio2 = Gtk2::RadioMenuItem->new(
                $menuColumn_forced_radio1->get_group(),
                'Forced saves o_n',
            );
            $subMenu_saveOptions->append($menuColumn_forced_radio2);

            $subMenu_saveOptions->append(Gtk2::SeparatorMenuItem->new());  # Separator

            my $menuColumn_allSession_radio1 = Gtk2::RadioMenuItem->new(
                undef,
                'Save in _this session',
            );
            $menuColumn_allSession_radio1->signal_connect('toggled' => sub {

                if ($menuColumn_allSession_radio1->get_active()) {

                    $allSessionSwitch = '';
                    $self->ivPoke('saveAllSessionsFlag', FALSE);

                } else {

                    $allSessionSwitch = ' -a';
                    $self->ivPoke('saveAllSessionsFlag', TRUE);
                }

                # Sensitise/desensitise menu bar/toolbar items, depending on current conditions
                $axmud::CLIENT->desktopObj->restrictWidgets();
            });
            $subMenu_saveOptions->append($menuColumn_allSession_radio1);

            my $menuColumn_allSession_radio2 = Gtk2::RadioMenuItem->new(
                $menuColumn_allSession_radio1->get_group(),
                'Save in _all sessions',
            );
            $subMenu_saveOptions->append($menuColumn_allSession_radio2);

            $subMenu_saveOptions->append(Gtk2::SeparatorMenuItem->new());  # Separator

            my $menuItem_autoSaves_off = Gtk2::MenuItem->new('T_urn auto-saves off');
            $menuItem_autoSaves_off->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('autosave off', $mode);
            });
            $subMenu_saveOptions->append($menuItem_autoSaves_off);

            my $menuItem_autoSaves_on = Gtk2::MenuItem->new('Tu_rn auto-saves on');
            $menuItem_autoSaves_on->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('autosave on', $mode);
            });
            $subMenu_saveOptions->append($menuItem_autoSaves_on);

            $subMenu_saveOptions->append(Gtk2::SeparatorMenuItem->new());  # Separator

            my $menuItem_autoSaves_setTime = Gtk2::MenuItem->new('_Set auto-save time...');
            $menuItem_autoSaves_setTime->signal_connect('activate' => sub {

                my $number = $self->winObj->showEntryDialogue(
                    'Set auto-save time',
                    'Enter a time in seconds',
                );

                if ($number) {

                    # Set the auto-save time
                    $self->winObj->visibleSession->pseudoCmd('autosave ' . $number, $mode);
                }
            });
            $subMenu_saveOptions->append($menuItem_autoSaves_setTime);

        my $menuItem_saveOptions = Gtk2::MenuItem->new('Sa_ve options');
        $menuItem_saveOptions->set_submenu($subMenu_saveOptions);
        $menuColumn_file->append($menuItem_saveOptions);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'save_options', $menuItem_saveOptions);

        $menuColumn_file->append(Gtk2::SeparatorMenuItem->new());   # Separator

        my $menuItem_importFile = Gtk2::MenuItem->new('I_mport files...');
        $menuItem_importFile->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('importfiles', $mode);
        });
        $menuColumn_file->append($menuItem_importFile);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'import_files', $menuItem_importFile);

#        my $menuItem_exportAllFile = Gtk2::MenuItem->new('_Export all files...');
#        $menuItem_exportAllFile->signal_connect('activate' => sub {
#
#            $self->winObj->visibleSession->pseudoCmd('exportfiles', $mode);
#        });
#        $menuColumn_file->append($menuItem_exportAllFile);
#        # (Requires a visible session whose status is 'connected' or 'offline')
#        $self->ivAdd('menuItemHash', 'export_all_files', $menuItem_exportAllFile);

            # 'Export files' submenu
            my $subMenu_exportFile = Gtk2::Menu->new();

            my $menuItem_exportFile_world = Gtk2::MenuItem->new('World _files...');
            $menuItem_exportFile_world->signal_connect('activate' => sub {

                # Display a 'dialogue' window, so the user can choose a world profile
                my (
                    $choice,
                    @worldList,
                );

                # Get an ordered list of all world profiles
                @worldList = $self->getWorldList();
                if (@worldList) {

                    # Display the dialogue
                    $choice = $self->winObj->showComboDialogue(
                        'Export file',
                        'Select a world profile to export',
                        FALSE,
                        \@worldList,
                    );

                    if ($choice) {

                        # Export the file
                        $self->winObj->visibleSession->pseudoCmd(
                            'exportfiles -w ' . $choice,
                            $mode,
                        );
                    }
                }
            });
            $subMenu_exportFile->append($menuItem_exportFile_world);

            $subMenu_exportFile->append(Gtk2::SeparatorMenuItem->new());    # Separator

            my $menuItem_exportFile_model = Gtk2::MenuItem->new('World _model file...');
            $menuItem_exportFile_model->signal_connect('activate' => sub {

                # Display a 'dialogue' window, so the user can choose a world profile
                my (
                    $choice,
                    @worldList,
                );

                # Get an ordered list of all world profiles
                @worldList = $self->getWorldList();
                if (@worldList) {

                    # Display the dialogue
                    $choice = $self->winObj->showComboDialogue(
                        'Export file',
                        'Select a world model to export',
                        FALSE,
                        \@worldList,
                    );

                    if ($choice) {

                        # Export the file
                        $self->winObj->visibleSession->pseudoCmd(
                            'exportfiles -m ' . $choice,
                            $mode,
                        );
                    }
                }
            });
            $subMenu_exportFile->append($menuItem_exportFile_model);

            my $menuItem_exportFile_tasks = Gtk2::MenuItem->new('_Tasks file');
            $menuItem_exportFile_tasks->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('exportfiles -t', $mode);
            });
            $subMenu_exportFile->append($menuItem_exportFile_tasks);

            my $menuItem_exportFile_scripts = Gtk2::MenuItem->new('_Scripts file');
            $menuItem_exportFile_scripts->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('exportfiles -s', $mode);
            });
            $subMenu_exportFile->append($menuItem_exportFile_scripts);

            my $menuItem_exportFile_contacts = Gtk2::MenuItem->new('_Contacts file');
            $menuItem_exportFile_contacts->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('exportfiles -n', $mode);
            });
            $subMenu_exportFile->append($menuItem_exportFile_contacts);

            my $menuItem_exportFile_dicts = Gtk2::MenuItem->new('_Dictionaries file');
            $menuItem_exportFile_dicts->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('exportfiles -y', $mode);
            });
            $subMenu_exportFile->append($menuItem_exportFile_dicts);

            my $menuItem_exportFile_toolbar = Gtk2::MenuItem->new('Tool_bar file');
            $menuItem_exportFile_toolbar->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('exportfiles -b', $mode);
            });
            $subMenu_exportFile->append($menuItem_exportFile_toolbar);

            my $menuItem_exportFile_userComm = Gtk2::MenuItem->new('_User commands file');
            $menuItem_exportFile_userComm->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('exportfiles -u', $mode);
            });
            $subMenu_exportFile->append($menuItem_exportFile_userComm);

            my $menuItem_exportFile_zonemaps = Gtk2::MenuItem->new('_Zonemaps file');
            $menuItem_exportFile_zonemaps->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('exportfiles -z', $mode);
            });
            $subMenu_exportFile->append($menuItem_exportFile_zonemaps);

            my $menuItem_exportFile_winmaps = Gtk2::MenuItem->new('Winma_ps file');
            $menuItem_exportFile_winmaps->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('exportfiles -p', $mode);
            });
            $subMenu_exportFile->append($menuItem_exportFile_winmaps);

            my $menuItem_exportFile_ttsObjs = Gtk2::MenuItem->new('Te_xt-to-speech file');
            $menuItem_exportFile_ttsObjs->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('exportfiles -x', $mode);
            });
            $subMenu_exportFile->append($menuItem_exportFile_ttsObjs);

        my $menuItem_exportFile = Gtk2::MenuItem->new('E_xport files');
        $menuItem_exportFile->set_submenu($subMenu_exportFile);
        $menuColumn_file->append($menuItem_exportFile);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'export_file', $menuItem_exportFile);

        $menuColumn_file->append(Gtk2::SeparatorMenuItem->new());   # Separator

        my $menuItem_importData = Gtk2::MenuItem->new('_Import data...');
        $menuItem_importData->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('importdata', $mode);
        });
        $menuColumn_file->append($menuItem_importData);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'import_data', $menuItem_importData);

            # 'Export data' submenu
            my $subMenu_exportData = Gtk2::Menu->new();

            my $menuItem_exportData_otherProf = Gtk2::MenuItem->new('_Non-world profiles...');
            $menuItem_exportData_otherProf->signal_connect('activate' => sub {

                # Display a 'dialogue' window, so the user can choose a non-world profile
                my (
                    $choice,
                    @otherProfList,
                );

                # Get an ordered list of all non-world profiles
                @otherProfList = $self->getOtherProfList();
                if (@otherProfList) {

                    # Display the dialogue
                    $choice = $self->winObj->showComboDialogue(
                        'Export data',
                        'Select a non-world profile to export',
                        FALSE,
                        \@otherProfList,
                    );

                    if ($choice) {

                        # Export the data
                        $self->winObj->visibleSession->pseudoCmd('exportdata -d ' . $choice, $mode);
                    }
                }
            });
            $subMenu_exportData->append($menuItem_exportData_otherProf);

            my $menuItem_exportData_singleCage = Gtk2::MenuItem->new('_Single cage...');
            $menuItem_exportData_singleCage->signal_connect('activate' => sub {

                # Display a 'dialogue' window, so the user can choose a cage
                my (
                    $choice,
                    @cageList,
                );

                # Get an ordered list of cages
                @cageList
                    = sort {lc($a) cmp lc($b)} ($self->winObj->visibleSession->ivKeys('cageHash'));
                if (@cageList) {

                    # Display the dialogue
                    $choice = $self->winObj->showComboDialogue(
                        'Export data',
                        'Select a cage to export',
                        FALSE,
                        \@cageList,
                    );

                    if ($choice) {

                        # Export the data
                        $self->winObj->visibleSession->pseudoCmd('exportdata -t ' . $choice, $mode);
                    }
                }
            });
            $subMenu_exportData->append($menuItem_exportData_singleCage);

            my $menuItem_exportData_profCages = Gtk2::MenuItem->new('_All cages in profile...');
            $menuItem_exportData_profCages->signal_connect('activate' => sub {

                # Display a 'dialogue' window, so the user can choose a profile
                my (
                    $choice,
                    @profList,
                );

                # Get an ordered list of profiles
                @profList
                    = sort {lc($a) cmp lc($b)} ($self->winObj->visibleSession->ivKeys('profHash'));

                if (@profList) {

                    # Display the dialogue
                    $choice = $self->winObj->showComboDialogue(
                        'Export data',
                        'Select a profile whose cages should be exported',
                        FALSE,
                        \@profList,
                    );

                    if ($choice) {

                        # Export the data
                        $self->winObj->visibleSession->pseudoCmd('exportdata -p ' . $choice, $mode);
                    }
                }
            });
            $subMenu_exportData->append($menuItem_exportData_profCages);

            my $menuItem_exportData_template = Gtk2::MenuItem->new('_Profile template...');
            $menuItem_exportData_template->signal_connect('activate' => sub {

                # Display a 'dialogue' window, so the user can choose a profile template
                my (
                    $choice,
                    @templList,
                );

                # Get an ordered list of all templates
                @templList = sort {lc($a) cmp lc($b)}
                                ($self->winObj->visibleSession->ivKeys('templateHash'));

                if (@templList) {

                    # Display the dialogue
                    $choice = $self->winObj->showComboDialogue(
                        'Export data',
                        'Select a profile template to export',
                        FALSE,
                        \@templList,
                    );

                    if ($choice) {

                        # Export the data
                        $self->winObj->visibleSession->pseudoCmd('exportdata -s ' . $choice, $mode);
                    }
                }
            });
            $subMenu_exportData->append($menuItem_exportData_template);

            $subMenu_exportData->append(Gtk2::SeparatorMenuItem->new());    # Separator

            my $menuItem_exportData_initialTask = Gtk2::MenuItem->new('(_Global) initial task...');
            $menuItem_exportData_initialTask->signal_connect('activate' => sub {

                # Display a 'dialogue' window, so the user can choose a (global) initial task
                my (
                    $choice,
                    @taskList,
                );

                # Get an ordered list of all (global) initial tasks
                @taskList = sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('initTaskHash'));
                if (@taskList) {

                    # Display the dialogue
                    $choice = $self->winObj->showComboDialogue(
                        'Export data',
                        'Select a (global) initial task to export',
                        FALSE,
                        \@taskList,
                    );

                    if ($choice) {

                        # Export the data
                        $self->winObj->visibleSession->pseudoCmd('exportdata -i ' . $choice, $mode);
                    }
                }
            });
            $subMenu_exportData->append($menuItem_exportData_initialTask);

            my $menuItem_exportData_customTask = Gtk2::MenuItem->new('_Custom task...');
            $menuItem_exportData_customTask->signal_connect('activate' => sub {

                # Display a 'dialogue' window, so the user can choose a custom task
                my (
                    $choice,
                    @taskList,
                );

                # Get an ordered list of all custom task names
                @taskList = sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('customTaskHash'));
                if (@taskList) {

                    # Display the dialogue
                    $choice = $self->winObj->showComboDialogue(
                        'Export data',
                        'Select a custom task to export',
                        FALSE,
                        \@taskList,
                    );

                    if ($choice) {

                        # Export the data
                        $self->winObj->visibleSession->pseudoCmd('exportdata -c ' . $choice, $mode);
                    }
                }
            });
            $subMenu_exportData->append($menuItem_exportData_customTask);

            $subMenu_exportData->append(Gtk2::SeparatorMenuItem->new());    # Separator

            my $menuItem_exportData_dict = Gtk2::MenuItem->new('_Dictionary...');
            $menuItem_exportData_dict->signal_connect('activate' => sub {

                # Display a 'dialogue' window, so the user can choose a dictionary
                my (
                    $choice,
                    @dictList,
                );

                # Get an ordered list of all dictionaries, with the current dictionary at the top of
                #   the list
                @dictList = $self->getDictList();
                if (@dictList) {

                    # Display the dialogue
                    $choice = $self->winObj->showComboDialogue(
                        'Export data',
                        'Select a dictionary to export',
                        FALSE,
                        \@dictList,
                    );

                    if ($choice) {

                        # Export the data
                        $self->winObj->visibleSession->pseudoCmd('exportdata -y ' . $choice, $mode);
                    }
                }
            });
            $subMenu_exportData->append($menuItem_exportData_dict);

            my $menuItem_exportData_zonemap = Gtk2::MenuItem->new('_Zonemap...');
            $menuItem_exportData_zonemap->signal_connect('activate' => sub {

                # Display a 'dialogue' window, so the user can choose a zonemap
                my (
                    $choice,
                    @zonemapList,
                );

                @zonemapList = (sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('zonemapHash')));
                if (@zonemapList) {

                    # Display the dialogue
                    $choice = $self->winObj->showComboDialogue(
                        'Export data',
                        'Select a zonemap to export',
                        FALSE,
                        \@zonemapList,
                    );

                    if ($choice) {

                        # Export the data
                        $self->winObj->visibleSession->pseudoCmd('exportdata -z ' . $choice, $mode);
                    }
                }
            });
            $subMenu_exportData->append($menuItem_exportData_zonemap);

            my $menuItem_exportData_winmap = Gtk2::MenuItem->new('_Winmap...');
            $menuItem_exportData_winmap->signal_connect('activate' => sub {

                # Display a 'dialogue' window, so the user can choose a winmap
                my (
                    $choice,
                    @winmapList,
                );

                @winmapList = (sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('winmapHash')));
                if (@winmapList) {

                    # Display the dialogue
                    $choice = $self->winObj->showComboDialogue(
                        'Export data',
                        'Select a winmap to export',
                        FALSE,
                        \@winmapList,
                    );

                    if ($choice) {

                        # Export the data
                        $self->winObj->visibleSession->pseudoCmd('exportdata -p ' . $choice, $mode);
                    }
                }
            });
            $subMenu_exportData->append($menuItem_exportData_winmap);

            my $menuItem_exportData_colScheme = Gtk2::MenuItem->new('C_olour scheme...');
            $menuItem_exportData_colScheme->signal_connect('activate' => sub {

                # Display a 'dialogue' window, so the user can choose a colour scheme
                my (
                    $choice,
                    @schemeList,
                );

                @schemeList = (
                    sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('colourSchemeHash'))
                );

                if (@schemeList) {

                    # Display the dialogue
                    $choice = $self->winObj->showComboDialogue(
                        'Export data',
                        'Select a colour scheme to export',
                        FALSE,
                        \@schemeList,
                    );

                    if ($choice) {

                        # Export the data
                        $self->winObj->visibleSession->pseudoCmd('exportdata -o ' . $choice, $mode);
                    }
                }
            });
            $subMenu_exportData->append($menuItem_exportData_colScheme);

            my $menuItem_exportData_ttsObj = Gtk2::MenuItem->new('_TTS object...');
            $menuItem_exportData_ttsObj->signal_connect('activate' => sub {

                # Display a 'dialogue' window, so the user can choose a TTS object
                my (
                    $choice,
                    @objList,
                );

                @objList = (sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('ttsObjHash')));
                if (@objList) {

                    # Display the dialogue
                    $choice = $self->winObj->showComboDialogue(
                        'Export data',
                        'Select a text-to-speech object to export',
                        FALSE,
                        \@objList,
                    );

                    if ($choice) {

                        # Export the data
                        $self->winObj->visibleSession->pseudoCmd('exportdata -x ' . $choice, $mode);
                    }
                }
            });
            $subMenu_exportData->append($menuItem_exportData_ttsObj);

        my $menuItem_exportData = Gtk2::MenuItem->new('Export _data');
        $menuItem_exportData->set_submenu($subMenu_exportData);
        $menuColumn_file->append($menuItem_exportData);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'export_data', $menuItem_exportData);

        $menuColumn_file->append(Gtk2::SeparatorMenuItem->new());   # Separator

            # 'Backup data' submenu
            my $subMenu_backupRestore = Gtk2::Menu->new();

            my $menuItem_backupData = Gtk2::MenuItem->new('_Backup all data files');
            $menuItem_backupData->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('backupdata', $mode);
            });
            $subMenu_backupRestore->append($menuItem_backupData);

            my $menuItem_restoreData = Gtk2::MenuItem->new('_Restore from backup...');
            $menuItem_restoreData->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('restoredata', $mode);
            });
            $subMenu_backupRestore->append($menuItem_restoreData);

        my $menuItem_backupRestore = Gtk2::MenuItem->new('_Backup data');
        $menuItem_backupRestore->set_submenu($subMenu_backupRestore);
        $menuColumn_file->append($menuItem_backupRestore);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'backup_restore_data', $menuItem_backupRestore);

        $menuColumn_file->append(Gtk2::SeparatorMenuItem->new());   # Separator

        my $menuItem_showFiles = Gtk2::ImageMenuItem->new('S_how file objects');
        my $menuImg_showFiles = Gtk2::Image->new_from_stock('gtk-dialog-info', 'menu');
        $menuItem_showFiles->set_image($menuImg_showFiles);
        $menuItem_showFiles->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('showfile', $mode);
        });
        $menuColumn_file->append($menuItem_showFiles);
        # (Requires a visible session)
        $self->ivAdd('menuItemHash', 'show_files', $menuItem_showFiles);

        my $menuItem_disableSaveWorld = Gtk2::ImageMenuItem->new('Disable wo_rld save');
        my $menuImg_disableSaveWorld = Gtk2::Image->new_from_stock('gtk-dialog-warning', 'menu');
        $menuItem_disableSaveWorld->set_image($menuImg_disableSaveWorld);
        $menuItem_disableSaveWorld->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('disablesaveworld', $mode);
        });
        $menuColumn_file->append($menuItem_disableSaveWorld);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'disable_world_save', $menuItem_disableSaveWorld);

        my $menuItem_disableSaveLoad = Gtk2::ImageMenuItem->new('Disa_ble all saves/loads');
        my $menuImg_disableSaveLoad = Gtk2::Image->new_from_stock('gtk-dialog-warning', 'menu');
        $menuItem_disableSaveLoad->set_image($menuImg_disableSaveLoad);
        $menuItem_disableSaveLoad->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('disablesaveload', $mode);
        });
        $menuColumn_file->append($menuItem_disableSaveLoad);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'disable_save_load', $menuItem_disableSaveLoad);

        # Setup complete
        return $menuColumn_file;
    }

    sub drawEditColumn {

        # Called by $self->enableMenu
        # Sets up the menu's 'Edit' column
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or if the menu can't be created
        #   Otherwise returns the Gtk2::Menu created

        my ($self, $check) = @_;

        # Local variables
        my $mode;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawEditColumn', @_);
        }

        # Import IVs (for convenience)
        $mode = $self->winObj->pseudoCmdMode;

        # Set up column
        my $menuColumn_edit = Gtk2::Menu->new();
        if (! $menuColumn_edit) {

            return undef;
        }

        my $menuItem_quickPrefs = Gtk2::ImageMenuItem->new(
            '_Quick preferences...',
        );
        my $menuImg_quickPrefs = Gtk2::Image->new_from_stock('gtk-preferences', 'menu');
        $menuItem_quickPrefs->set_image($menuImg_quickPrefs);
        $menuItem_quickPrefs->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('editquick', $mode);
        });
        $menuColumn_edit->append($menuItem_quickPrefs);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'edit_quick_prefs', $menuItem_quickPrefs);

        my $menuItem_clientPrefs = Gtk2::ImageMenuItem->new(
            $axmud::SCRIPT . ' pr_eferences...',
        );
        my $menuImg_clientPrefs = Gtk2::Image->new_from_stock('gtk-preferences', 'menu');
        $menuItem_clientPrefs->set_image($menuImg_clientPrefs);
        $menuItem_clientPrefs->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('editclient', $mode);
        });
        $menuColumn_edit->append($menuItem_clientPrefs);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'edit_client_prefs', $menuItem_clientPrefs);

        my $menuItem_sessionPrefs = Gtk2::ImageMenuItem->new('_Session preferences...');
        my $menuImg_sessionPrefs = Gtk2::Image->new_from_stock('gtk-preferences', 'menu');
        $menuItem_sessionPrefs->set_image($menuImg_sessionPrefs);
        $menuItem_sessionPrefs->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('editsession', $mode);
        });
        $menuColumn_edit->append($menuItem_sessionPrefs);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'edit_session_prefs', $menuItem_sessionPrefs);

        $menuColumn_edit->append(Gtk2::SeparatorMenuItem->new());   # Separator

        my $menuItem_editWorld = Gtk2::ImageMenuItem->new('Edit current _world...');
        my $menuImg_editWorld = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
        $menuItem_editWorld->set_image($menuImg_editWorld);
        $menuItem_editWorld->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('editworld', $mode);
        });
        $menuColumn_edit->append($menuItem_editWorld);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'edit_current_world', $menuItem_editWorld);

        my $menuItem_editGuild = Gtk2::ImageMenuItem->new('Edit current _guild...');
        my $menuImg_editGuild = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
        $menuItem_editGuild->set_image($menuImg_editGuild);
        $menuItem_editGuild->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('editguild', $mode);
        });
        $menuColumn_edit->append($menuItem_editGuild);
        # Requires a current session whose status is 'connected' or 'offline' and whose
        #   ->currentGuild is defined
        $self->ivAdd('menuItemHash', 'edit_current_guild', $menuItem_editGuild);

        my $menuItem_editRace = Gtk2::ImageMenuItem->new('Edit current _race...');
        my $menuImg_editRace = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
        $menuItem_editRace->set_image($menuImg_editRace);
        $menuItem_editRace->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('editrace', $mode);
        });
        $menuColumn_edit->append($menuItem_editRace);
        # Requires a current session whose status is 'connected' or 'offline' and whose
        #   ->currentRace is defined
        $self->ivAdd('menuItemHash', 'edit_current_race', $menuItem_editRace);

        my $menuItem_editChar = Gtk2::ImageMenuItem->new('Edit current _character...');
        my $menuImg_editChar = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
        $menuItem_editChar->set_image($menuImg_editChar);
        $menuItem_editChar->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('editchar', $mode);
        });
        $menuColumn_edit->append($menuItem_editChar);
        # Requires a current session whose status is 'connected' or 'offline' and whose
        #   ->currentChar is defined
        $self->ivAdd('menuItemHash', 'edit_current_char', $menuItem_editChar);

        $menuColumn_edit->append(Gtk2::SeparatorMenuItem->new());   # Separator

        my $menuItem_locatorWiz = Gtk2::ImageMenuItem->new('Run Locator wi_zard...');
        my $menuImg_locatorWiz = Gtk2::Image->new_from_stock('gtk-page-setup', 'menu');
        $menuItem_locatorWiz->set_image($menuImg_locatorWiz);
        $menuItem_locatorWiz->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('locatorwizard', $mode);
        });
        $menuColumn_edit->append($menuItem_locatorWiz);
        # (Requires a visible session whose status is 'connected' or 'offline'. A
        #   corresponding menu item also appears in $self->drawTasksColumn)
        $self->ivAdd('menuItemHash', 'run_locator_wiz', $menuItem_locatorWiz);

        my $menuItem_editWorldModel = Gtk2::ImageMenuItem->new('Edit _world model...');
        my $menuImg_editWorldModel = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
        $menuItem_editWorldModel->set_image($menuImg_editWorldModel);
        $menuItem_editWorldModel->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('editmodel', $mode);
        });
        $menuColumn_edit->append($menuItem_editWorldModel);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'edit_world_model', $menuItem_editWorldModel);

        my $menuItem_editDict = Gtk2::ImageMenuItem->new('Edit _dictionary...');
        my $menuImg_editDict = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
        $menuItem_editDict->set_image($menuImg_editDict);
        $menuItem_editDict->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('editdictionary', $mode);
        });
        $menuColumn_edit->append($menuItem_editDict);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'edit_dictionary', $menuItem_editDict);

        $menuColumn_edit->append(Gtk2::SeparatorMenuItem->new());   # Separator

            # 'Simulate' submenu
            my $subMenu_simulate = Gtk2::Menu->new();

            my $menuItem_simWorld = Gtk2::MenuItem->new('Simulate _world...');
            $menuItem_simWorld->signal_connect('activate' => sub {

                # Open a simulate world 'dialogue' window. The text entered is used in a
                #   ';simulateworld' command
                $self->winObj->visibleSession->pseudoCmd('simulateworld', $mode);
            });
            $subMenu_simulate->append($menuItem_simWorld);

            my $menuItem_simPrompt = Gtk2::MenuItem->new('Simulate p_rompt...');
            $menuItem_simPrompt->signal_connect('activate' => sub {

                # Open a simulate prompt 'dialogue' window. The text entered is used in a
                #   ';simulateprompt' command
                $self->winObj->visibleSession->pseudoCmd('simulateprompt', $mode);
            });
            $subMenu_simulate->append($menuItem_simPrompt);

            my $menuItem_simCmd = Gtk2::MenuItem->new('Simulate _command...');
            $menuItem_simCmd->signal_connect('activate' => sub {

                # Prompt the user for a world command
                my $cmd = $self->winObj->showEntryDialogue(
                    'Simulate world command',
                    'Enter a world command (not actually sent to the world)',
                );

                if ($cmd) {

                    $self->winObj->visibleSession->pseudoCmd(
                        'simulatecommand <' . $cmd . '>',
                        $mode,
                    );
                }
            });
            $subMenu_simulate->append($menuItem_simCmd);

            my $menuItem_simHook = Gtk2::MenuItem->new('Simulate _hook event...');
            $menuItem_simHook->signal_connect('activate' => sub {

                my (
                    $interfaceModel, $choice, $number, $cancelFlag, $cmd,
                    @eventList, @hookDataList,
                );

                # Get the hook interface model, and from there, a list of hook events
                $interfaceModel = $axmud::CLIENT->ivShow('interfaceModelHash', 'hook');
                @eventList = sort {$a cmp $b} ($interfaceModel->ivKeys('hookEventHash'));

                # Prompt the user for a hook event
                $choice = $self->winObj->showComboDialogue(
                    'Simulate hook event',
                    'Enter a hook event for ' . $axmud::SCRIPT . ' to simulate',
                    FALSE,
                    \@eventList,
                );

                if ($choice) {

                    # How many items of hook data are expected?
                    $number = $interfaceModel->ivShow('hookEventHash', $choice);
                    if ($number == 1) {

                        my $result = $self->winObj->showEntryDialogue(
                            'Simulate hook event',
                            'Enter hook data #1 for the hook \'' . $choice . '\'',
                        );

                        if (! $result) {

                            # Don't simulate the hook event
                            $cancelFlag = TRUE;

                        } else {

                            push (@hookDataList, $result);
                        }

                    } elsif ($number == 2) {

                        my @resultList = $self->winObj->showDoubleEntryDialogue(
                            'Simulate hook event',
                            'Enter hook data #1 for the hook \'' . $choice . '\'',
                            'Enter hook data #2',
                        );

                        # Both hook data items must contain at least one character
                        if (! @resultList || ! $resultList[0] || ! $resultList[1]) {

                            # Don't simulate the hook event
                            $cancelFlag = TRUE;

                        } else {

                            push (@hookDataList, @resultList);
                        }
                    }

                    if (! $cancelFlag) {

                        # Prepare the client command to execute...
                        $cmd = 'simulatehook ' . $choice;
                        foreach my $item (@hookDataList) {

                            $cmd .= ' <' . $item . '>';
                        }

                        # ...and execute it
                        $self->winObj->visibleSession->pseudoCmd($cmd, $mode);
                    }
                }
            });
            $subMenu_simulate->append($menuItem_simHook);

        my $menuItem_simulate = Gtk2::MenuItem->new('Sim_ulate');
        $menuItem_simulate->set_submenu($subMenu_simulate);
        $menuColumn_edit->append($menuItem_simulate);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'simulate', $menuItem_simulate);

        my $menuItem_patternTest = Gtk2::MenuItem->new('Test _patterns...');
        $menuItem_patternTest->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('testpattern', $mode);
        });
        $menuColumn_edit->append($menuItem_patternTest);

        # Setup complete
        return $menuColumn_edit;
    }

    sub drawInterfacesColumn {

        # Called by $self->enableMenu
        # Sets up the menu's 'Interfaces' column
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or if the menu can't be created
        #   Otherwise returns the Gtk2::Menu created

        my ($self, $check) = @_;

        # Local variables
        my $mode;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawInterfacesColumn', @_);
        }

        # Import IVs (for convenience)
        $mode = $self->winObj->pseudoCmdMode;

        # Set up column
        my $menuColumn_interfaces = Gtk2::Menu->new();
        if (! $menuColumn_interfaces) {

            return undef;
        }

        my $menuItem_activeInterfaces = Gtk2::MenuItem->new('Acti_ve interfaces...');
        $menuItem_activeInterfaces->signal_connect('activate' => sub {

            # Open a session preference window on the notebook's second page, so the user can see
            #   the list of active interfaces immediately
            $self->winObj->visibleSession->pseudoCmd('editactiveinterface', $mode);
        });
        $menuColumn_interfaces->append($menuItem_activeInterfaces);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'active_interfaces', $menuItem_activeInterfaces);

        $menuColumn_interfaces->append(Gtk2::SeparatorMenuItem->new());   # Separator

            # 'Triggers' submenu
            my $subMenu_showTriggers = Gtk2::Menu->new();

            my $menuItem_worldTriggers = Gtk2::MenuItem->new('_World triggers...');
            $menuItem_worldTriggers->signal_connect('activate' => sub {

                # Open the cage window on the notebook's second page, so the user can see the list
                #   of triggers immediately
                $self->winObj->visibleSession->pseudoCmd('editcage -t', $mode);
            });
            $subMenu_showTriggers->append($menuItem_worldTriggers);

            my $menuItem_guildTriggers = Gtk2::MenuItem->new('_Guild triggers...');
            $menuItem_guildTriggers->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage trigger_guild_' . $self->winObj->visibleSession->currentGuild->name,
                    $mode,
                );
            });
            $subMenu_showTriggers->append($menuItem_guildTriggers);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   guild)
            $self->ivAdd('menuItemHash', 'guild_triggers', $menuItem_guildTriggers);

            my $menuItem_raceTriggers = Gtk2::MenuItem->new('_Race triggers...');
            $menuItem_raceTriggers->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage trigger_race_' . $self->winObj->visibleSession->currentRace->name,
                    $mode,
                );
            });
            $subMenu_showTriggers->append($menuItem_raceTriggers);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   race)
            $self->ivAdd('menuItemHash', 'race_triggers', $menuItem_raceTriggers);

            my $menuItem_charTriggers = Gtk2::MenuItem->new('_Character triggers...');
            $menuItem_charTriggers->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage trigger_char_' . $self->winObj->visibleSession->currentChar->name,
                    $mode,
                );
            });
            $subMenu_showTriggers->append($menuItem_charTriggers);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   character)
            $self->ivAdd('menuItemHash', 'char_triggers', $menuItem_charTriggers);

        my $menuItem_showTriggers = Gtk2::MenuItem->new('_Triggers');
        $menuItem_showTriggers->set_submenu($subMenu_showTriggers);
        $menuColumn_interfaces->append($menuItem_showTriggers);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'show_triggers', $menuItem_showTriggers);

            # 'Aliases' submenu
            my $subMenu_showAliases = Gtk2::Menu->new();

            my $menuItem_worldAliases = Gtk2::MenuItem->new('World _aliases...');
            $menuItem_worldAliases->signal_connect('activate' => sub {

                # Open the cage window on the notebook's second page, so the user can see the list
                #   of aliases immediately
                $self->winObj->visibleSession->pseudoCmd('editcage -a', $mode);
            });
            $subMenu_showAliases->append($menuItem_worldAliases);

            my $menuItem_guildAliases = Gtk2::MenuItem->new('_Guild aliases...');
            $menuItem_guildAliases->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage alias_guild_' . $self->winObj->visibleSession->currentGuild->name,
                    $mode,
                );
            });
            $subMenu_showAliases->append($menuItem_guildAliases);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   guild)
            $self->ivAdd('menuItemHash', 'guild_aliases', $menuItem_guildAliases);

            my $menuItem_raceAliases = Gtk2::MenuItem->new('_Race aliases...');
            $menuItem_raceAliases->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage alias_race_' . $self->winObj->visibleSession->currentRace->name,
                    $mode,
                );
            });
            $subMenu_showAliases->append($menuItem_raceAliases);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   race)
            $self->ivAdd('menuItemHash', 'race_aliases', $menuItem_raceAliases);

            my $menuItem_charAliases = Gtk2::MenuItem->new('_Character aliases...');
            $menuItem_charAliases->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage alias_char_' . $self->winObj->visibleSession->currentChar->name,
                    $mode,
                );
            });
            $subMenu_showAliases->append($menuItem_charAliases);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   character)
            $self->ivAdd('menuItemHash', 'char_aliases', $menuItem_charAliases);

        my $menuItem_showAliases = Gtk2::MenuItem->new('_Aliases');
        $menuItem_showAliases->set_submenu($subMenu_showAliases);
        $menuColumn_interfaces->append($menuItem_showAliases);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'show_aliases', $menuItem_showAliases);

            # 'Macros' submenu
            my $subMenu_showMacros = Gtk2::Menu->new();

            my $menuItem_worldMacros = Gtk2::MenuItem->new('World _macros...');
            $menuItem_worldMacros->signal_connect('activate' => sub {

                # Open the cage window on the notebook's second page, so the user can see the list
                #   of macros immediately
                $self->winObj->visibleSession->pseudoCmd('editcage -m', $mode);
            });
            $subMenu_showMacros->append($menuItem_worldMacros);

            my $menuItem_guildMacros = Gtk2::MenuItem->new('_Guild macros...');
            $menuItem_guildMacros->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage macro_guild_' . $self->winObj->visibleSession->currentGuild->name,
                    $mode,
                );
            });
            $subMenu_showMacros->append($menuItem_guildMacros);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   guild)
            $self->ivAdd('menuItemHash', 'guild_macros', $menuItem_guildMacros);

            my $menuItem_raceMacros = Gtk2::MenuItem->new('_Race macros...');
            $menuItem_raceMacros->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage macro_race_' . $self->winObj->visibleSession->currentRace->name,
                    $mode,
                );
            });
            $subMenu_showMacros->append($menuItem_raceMacros);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   race)
            $self->ivAdd('menuItemHash', 'race_macros', $menuItem_raceMacros);

            my $menuItem_charMacros = Gtk2::MenuItem->new('_Character macros...');
            $menuItem_charMacros->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage macro_char_' . $self->winObj->visibleSession->currentChar->name,
                    $mode,
                );
            });
            $subMenu_showMacros->append($menuItem_charMacros);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   character)
            $self->ivAdd('menuItemHash', 'char_macros', $menuItem_charMacros);

        my $menuItem_showMacros = Gtk2::MenuItem->new('_Macros');
        $menuItem_showMacros->set_submenu($subMenu_showMacros);
        $menuColumn_interfaces->append($menuItem_showMacros);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'show_macros', $menuItem_showMacros);

            # 'Timers' submenu
            my $subMenu_showTimers = Gtk2::Menu->new();

            my $menuItem_worldTimers = Gtk2::MenuItem->new('World t_imers...');
            $menuItem_worldTimers->signal_connect('activate' => sub {

                # Open the cage window on the notebook's second page, so the user can see the list
                #   of timers immediately
                $self->winObj->visibleSession->pseudoCmd('editcage -i', $mode);
            });
            $subMenu_showTimers->append($menuItem_worldTimers);

            my $menuItem_guildTimers = Gtk2::MenuItem->new('_Guild timers...');
            $menuItem_guildTimers->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage timer_guild_' . $self->winObj->visibleSession->currentGuild->name,
                    $mode,
                );
            });
            $subMenu_showTimers->append($menuItem_guildTimers);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   guild)
            $self->ivAdd('menuItemHash', 'guild_timers', $menuItem_guildTimers);

            my $menuItem_raceTimers = Gtk2::MenuItem->new('_Race timers...');
            $menuItem_raceTimers->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage timer_race_' . $self->winObj->visibleSession->currentRace->name,
                    $mode,
                );
            });
            $subMenu_showTimers->append($menuItem_raceTimers);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   race)
            $self->ivAdd('menuItemHash', 'race_timers', $menuItem_raceTimers);

            my $menuItem_charTimers = Gtk2::MenuItem->new('_Character timers...');
            $menuItem_charTimers->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage timer_char_' . $self->winObj->visibleSession->currentChar->name,
                    $mode,
                );
            });
            $subMenu_showTimers->append($menuItem_charTimers);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   character)
            $self->ivAdd('menuItemHash', 'char_timers', $menuItem_charTimers);

        my $menuItem_showTimers = Gtk2::MenuItem->new('_Timers');
        $menuItem_showTimers->set_submenu($subMenu_showTimers);
        $menuColumn_interfaces->append($menuItem_showTimers);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'show_timers', $menuItem_showTimers);

            # 'Hooks' submenu
            my $subMenu_showHooks = Gtk2::Menu->new();

            my $menuItem_worldHooks = Gtk2::MenuItem->new('World _hooks...');
            $menuItem_worldHooks->signal_connect('activate' => sub {

                # Open the cage window on the notebook's second page, so the user can see the list
                #   of hooks immediately
                $self->winObj->visibleSession->pseudoCmd('editcage -h', $mode);
            });
            $subMenu_showHooks->append($menuItem_worldHooks);

            my $menuItem_guildHooks = Gtk2::MenuItem->new('_Guild hooks...');
            $menuItem_guildHooks->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage hook_guild_' . $self->winObj->visibleSession->currentGuild->name,
                    $mode,
                );
            });
            $subMenu_showHooks->append($menuItem_guildHooks);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   guild)
            $self->ivAdd('menuItemHash', 'guild_hooks', $menuItem_guildHooks);

            my $menuItem_raceHooks = Gtk2::MenuItem->new('_Race hooks...');
            $menuItem_raceHooks->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage hook_race_' . $self->winObj->visibleSession->currentRace->name,
                    $mode,
                );
            });
            $subMenu_showHooks->append($menuItem_raceHooks);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   race)
            $self->ivAdd('menuItemHash', 'race_hooks', $menuItem_raceHooks);

            my $menuItem_charHooks = Gtk2::MenuItem->new('_Character hooks...');
            $menuItem_charHooks->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage hook_char_' . $self->winObj->visibleSession->currentChar->name,
                    $mode,
                );
            });
            $subMenu_showHooks->append($menuItem_charHooks);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   character)
            $self->ivAdd('menuItemHash', 'char_hooks', $menuItem_charHooks);

        my $menuItem_showHooks = Gtk2::MenuItem->new('_Hooks');
        $menuItem_showHooks->set_submenu($subMenu_showHooks);
        $menuColumn_interfaces->append($menuItem_showHooks);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'show_hooks', $menuItem_showHooks);

        $menuColumn_interfaces->append(Gtk2::SeparatorMenuItem->new());   # Separator

            # 'Commands' submenu
            my $subMenu_showCmds = Gtk2::Menu->new();

            my $menuItem_worldCmds = Gtk2::MenuItem->new('_World commands...');
            $menuItem_worldCmds->signal_connect('activate' => sub {

                # Open the cage window on the notebook's second page, so the user can see the list
                #   OF commands immediately
                $self->winObj->visibleSession->pseudoCmd('editcage -c', $mode);
            });
            $subMenu_showCmds->append($menuItem_worldCmds);

            my $menuItem_guildCmds = Gtk2::MenuItem->new('_Guild commands...');
            $menuItem_guildCmds->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage cmd_guild_' . $self->winObj->visibleSession->currentGuild->name,
                    $mode,
                );
            });
            $subMenu_showCmds->append($menuItem_guildCmds);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   guild)
            $self->ivAdd('menuItemHash', 'guild_cmds', $menuItem_guildCmds);

            my $menuItem_raceCmds = Gtk2::MenuItem->new('_Race commands...');
            $menuItem_raceCmds->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage cmd_race_' . $self->winObj->visibleSession->currentRace->name,
                    $mode,
                );
            });
            $subMenu_showCmds->append($menuItem_raceCmds);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   race)
            $self->ivAdd('menuItemHash', 'race_cmds', $menuItem_raceCmds);

            my $menuItem_charCmds = Gtk2::MenuItem->new('_Character commands...');
            $menuItem_charCmds->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage cmd_char_' . $self->winObj->visibleSession->currentChar->name,
                    $mode,
                );
            });
            $subMenu_showCmds->append($menuItem_charCmds);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   character)
            $self->ivAdd('menuItemHash', 'char_cmds', $menuItem_charCmds);

        my $menuItem_showCmds = Gtk2::MenuItem->new('_Commands');
        $menuItem_showCmds->set_submenu($subMenu_showCmds);
        $menuColumn_interfaces->append($menuItem_showCmds);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'show_cmds', $menuItem_showCmds);

            # 'Routes' submenu
            my $subMenu_showRoutes = Gtk2::Menu->new();

            my $menuItem_worldRoutes = Gtk2::MenuItem->new('_World routes...');
            $menuItem_worldRoutes->signal_connect('activate' => sub {

                # Open the cage window on the notebook's second page, so the user can see the list
                #   OF routes immediately
                $self->winObj->visibleSession->pseudoCmd('editcage -r', $mode);
            });
            $subMenu_showRoutes->append($menuItem_worldRoutes);

            my $menuItem_guildRoutes = Gtk2::MenuItem->new('_Guild routes...');
            $menuItem_guildRoutes->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage route_guild_' . $self->winObj->visibleSession->currentGuild->name,
                    $mode,
                );
            });
            $subMenu_showRoutes->append($menuItem_guildRoutes);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   guild)
            $self->ivAdd('menuItemHash', 'guild_routes', $menuItem_guildRoutes);

            my $menuItem_raceRoutes = Gtk2::MenuItem->new('_Race routes...');
            $menuItem_raceRoutes->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage route_race_' . $self->winObj->visibleSession->currentRace->name,
                    $mode,
                );
            });
            $subMenu_showRoutes->append($menuItem_raceRoutes);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   race)
            $self->ivAdd('menuItemHash', 'race_routes', $menuItem_raceRoutes);

            my $menuItem_charRoutes = Gtk2::MenuItem->new('_Character routes...');
            $menuItem_charRoutes->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd(
                    'editcage route_char_' . $self->winObj->visibleSession->currentChar->name,
                    $mode,
                );
            });
            $subMenu_showRoutes->append($menuItem_charRoutes);
            # (Requires a visible session whose status is 'connected' or 'offline', and a current
            #   character)
            $self->ivAdd('menuItemHash', 'char_routes', $menuItem_charRoutes);

        my $menuItem_showRoutes = Gtk2::MenuItem->new('_Routes');
        $menuItem_showRoutes->set_submenu($subMenu_showRoutes);
        $menuColumn_interfaces->append($menuItem_showRoutes);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'show_routes', $menuItem_showRoutes);

        # Setup complete
        return $menuColumn_interfaces;
    }

    sub drawTasksColumn {

        # Called by $self->enableMenu
        # Sets up the menu's 'Tasks' column
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or if the menu can't be created
        #   Otherwise returns the Gtk2::Menu created

        my ($self, $check) = @_;

        # Local variables
        my $mode;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawTasksColumn', @_);
        }

        # Import IVs (for convenience)
        $mode = $self->winObj->pseudoCmdMode;

        # Set up column
        my $menuColumn_tasks = Gtk2::Menu->new();
        if (! $menuColumn_tasks) {

            return undef;
        }

        my $menuItem_freezeTasks = Gtk2::CheckMenuItem->new('_Freeze all tasks');
        $menuItem_freezeTasks->signal_connect('toggled' => sub {

            $self->winObj->visibleSession->pseudoCmd('freezetask', $mode);
        });
        $menuColumn_tasks->append($menuItem_freezeTasks);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'freeze_tasks', $menuItem_freezeTasks);

        $menuColumn_tasks->append(Gtk2::SeparatorMenuItem->new());  # Separator

            # 'Channels task' submenu
            my $subMenu_channelsTask = Gtk2::Menu->new();

            my $menuItem_channelsTask_addPattern = Gtk2::MenuItem->new('Add _channel pattern...');
            $menuItem_channelsTask_addPattern->signal_connect('activate' => sub {

                my ($pattern, $channel);

                # Prompt the user for a pattern/channel
                ($pattern, $channel) = $self->winObj->showDoubleEntryDialogue(
                    'Add channel pattern',
                    'Enter a pattern (regex)',
                    'Enter a channel (1-16 chars)',
                );

                if (defined $pattern && defined $channel) {

                    $self->winObj->visibleSession->pseudoCmd(
                        'addchannelpattern <' . $channel . '> <' . $pattern . '>',
                        $mode,
                    );
                }
            });
            $subMenu_channelsTask->append($menuItem_channelsTask_addPattern);

            my $menuItem_channelsTask_addException = Gtk2::MenuItem->new(
                'Add _exception pattern...',
            );
            $menuItem_channelsTask_addException->signal_connect('activate' => sub {

                # Prompt the user for a pattern
                my $pattern = $self->winObj->showEntryDialogue(
                    'Add exception pattern',
                    'Enter a pattern (regex)',
                );

                if (defined $pattern) {

                    $self->winObj->visibleSession->pseudoCmd(
                        'addchannelpattern -e <' . $pattern . '>',
                        $mode,
                    );
                }
            });
            $subMenu_channelsTask->append($menuItem_channelsTask_addException);

            my $menuItem_channelsTask_listPattern = Gtk2::MenuItem->new('_List patterns');
            $menuItem_channelsTask_listPattern->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('listchannelpattern', $mode);
            });
            $subMenu_channelsTask->append($menuItem_channelsTask_listPattern);

            $subMenu_channelsTask->append(Gtk2::SeparatorMenuItem->new());    # Separator

            my $menuItem_channelsTask_emptyWindow = Gtk2::MenuItem->new('_Empty Channels _window');
            $menuItem_channelsTask_emptyWindow->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('emptychannelswindow', $mode);
            });
            $subMenu_channelsTask->append($menuItem_channelsTask_emptyWindow);

            $subMenu_channelsTask->append(Gtk2::SeparatorMenuItem->new());    # Separator

            my $menuItem_channelsTask_editTask = Gtk2::ImageMenuItem->new('_Edit current task...');
            my $menuImg_channelsTask_editTask = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
            $menuItem_channelsTask_editTask->set_image($menuImg_channelsTask_editTask);
            $menuItem_channelsTask_editTask->signal_connect('activate' => sub {

                my $session = $self->winObj->visibleSession;

                # Open up a task 'edit' window to edit the task, with the 'main' window as the
                #   parent
                $self->winObj->createFreeWin(
                    'Games::Axmud::EditWin::Task',
                    $self->winObj,
                    $session,
                    'Edit ' . $session->channelsTask->prettyName . ' task',
                    $session->channelsTask,
                    FALSE,                          # Not temporary
                    # Config
                    'edit_flag' => FALSE,           # Some IVs for current tasks not editable
                );
            });
            $subMenu_channelsTask->append($menuItem_channelsTask_editTask);

        my $menuItem_channelsTask = Gtk2::MenuItem->new('Channe_ls task');
        $menuItem_channelsTask->set_submenu($subMenu_channelsTask);
        $menuColumn_tasks->append($menuItem_channelsTask);
        # (Requires a visible session whose status is 'connected' or 'offline' and is running a
        #   Channels task)
        $self->ivAdd('menuItemHash', 'channels_task', $menuItem_channelsTask);

            # 'Chat task' submenu
            my $subMenu_chatTask = Gtk2::Menu->new();

            my $menuItem_chatTask_listen = Gtk2::MenuItem->new('_Listen for incoming calls');
            $menuItem_chatTask_listen->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('chatlisten', $mode);
            });
            $subMenu_chatTask->append($menuItem_chatTask_listen);

            my $menuItem_chatTask_ignore = Gtk2::MenuItem->new('_Ignore incoming calls');
            $menuItem_chatTask_ignore->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('chatignore', $mode);
            });
            $subMenu_chatTask->append($menuItem_chatTask_ignore);

            $subMenu_chatTask->append(Gtk2::SeparatorMenuItem->new());    # Separator

            my $menuItem_chatTask_chatContact = Gtk2::MenuItem->new('_Chat with...');
            $menuItem_chatTask_chatContact->signal_connect('activate' => sub {

                my (
                    $choice,
                    @comboList,
                );

                # Get a sorted list of chat contact names
                @comboList = sort {lc($a) cmp lc($b)} ($axmud::CLIENT->ivKeys('chatContactHash'));
                if (! @comboList) {

                    $self->winObj->showMsgDialogue(
                        'Chat with contact',
                        'error',
                        'There is no-one in your contacts list',
                        'ok',
                    );

                } else {

                    # Prompt the user to choose a chat contact
                    $choice = $self->winObj->showComboDialogue(
                        'Select chat contact',
                        'Select the chat contact to call',
                        FALSE,
                        \@comboList,
                    );

                    if ($choice) {

                        $self->session->pseudoCmd(
                            'chatcall ' . $choice,
                            $mode,
                        );
                    }
                }
            });
            $subMenu_chatTask->append($menuItem_chatTask_chatContact);

            my $menuItem_chatTask_chatMM = Gtk2::MenuItem->new('Chat using _MudMaster...');
            $menuItem_chatTask_chatMM->signal_connect('activate' => sub {

                my ($host, $port);

                # Prompt the user for a host and port
                ($host, $port) = $self->winObj->showDoubleEntryDialogue(
                    'Chat using MudMaster',
                    'Enter a DNS/IP address',
                    '(Optional) enter the port',
                );

                if ($host) {

                    if (! $port) {

                        # (Don't use an empty string as the port)
                        $self->winObj->visibleSession->pseudoCmd('chatmcall ' . $host, $mode);

                    } else {

                        $self->winObj->visibleSession->pseudoCmd(
                            'chatmcall ' . $host . ' ' . $port,
                            $mode,
                        );
                    }
                }
            });
            $subMenu_chatTask->append($menuItem_chatTask_chatMM);

            my $menuItem_chatTask_chatZChat = Gtk2::MenuItem->new('Chat using _zChat...');
            $menuItem_chatTask_chatZChat->signal_connect('activate' => sub {

                my ($host, $port);

                # Prompt the user for an address and port
                ($host, $port) = $self->winObj->showDoubleEntryDialogue(
                    'Chat using zChat',
                    'Enter a DNS/IP address',
                    '(Optional) enter the port',
                );

                if ($host) {

                    if (! $port) {

                        # (Don't use an empty string as the port)
                        $self->winObj->visibleSession->pseudoCmd('chatzcall ' . $host, $mode);

                    } else {

                        $self->winObj->visibleSession->pseudoCmd(
                            'chatzcall ' . $host . ' ' . $port,
                            $mode,
                        );
                    }
                }
            });
            $subMenu_chatTask->append($menuItem_chatTask_chatZChat);

            $subMenu_chatTask->append(Gtk2::SeparatorMenuItem->new());    # Separator

            my $menuItem_chatTask_allowSnoop = Gtk2::MenuItem->new('_Allow everyone to snoop');
            $menuItem_chatTask_allowSnoop->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('chatset -a', $mode);
            });
            $subMenu_chatTask->append($menuItem_chatTask_allowSnoop);

            my $menuItem_chatTask_forbidSnoop = Gtk2::MenuItem->new('_Forbid all snooping');
            $menuItem_chatTask_forbidSnoop->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('chatset -f', $mode);
            });
            $subMenu_chatTask->append($menuItem_chatTask_forbidSnoop);

            $subMenu_chatTask->append(Gtk2::SeparatorMenuItem->new());    # Separator

            my $menuItem_chatTask_hangUpAll = Gtk2::MenuItem->new('_Hang up on everyone');
            $menuItem_chatTask_hangUpAll->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('chathangup', $mode);
            });
            $subMenu_chatTask->append($menuItem_chatTask_hangUpAll);

            $subMenu_chatTask->append(Gtk2::SeparatorMenuItem->new());    # Separator

            my $menuItem_chatTask_editTask = Gtk2::ImageMenuItem->new('_Edit lead chat task...');
            my $menuImg_chatTask_editTask = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
            $menuItem_chatTask_editTask->set_image($menuImg_chatTask_editTask);
            $menuItem_chatTask_editTask->signal_connect('activate' => sub {

                my $session = $self->winObj->visibleSession;

                # Open up a task 'edit' window to edit the task, with the 'main' window as the
                #   parent
                $self->winObj->createFreeWin(
                    'Games::Axmud::EditWin::Task',
                    $self->winObj,
                    $session,
                    'Edit ' . $session->chatTask->prettyName . ' task',
                    $session->chatTask,
                    FALSE,                          # Not temporary
                    # Config
                    'edit_flag' => FALSE,           # Some IVs for current tasks not editable
                );
            });
            $subMenu_chatTask->append($menuItem_chatTask_editTask);
            # (Requires a visible session whose status is 'connected' or 'offline' and is running a
            #   Chat task)
            $self->ivAdd('menuItemHash', 'edit_chat_task', $menuItem_chatTask_editTask);

        my $menuItem_chatTask = Gtk2::MenuItem->new('_Chat task');
        $menuItem_chatTask->set_submenu($subMenu_chatTask);
        $menuColumn_tasks->append($menuItem_chatTask);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'chat_task', $menuItem_chatTask);

            # 'Compass' submenu
            my $subMenu_compassTask = Gtk2::Menu->new();

            my $menuItem_compassTask_enableKeypad
                = Gtk2::MenuItem->new('_Enable keypad world commands');
            $menuItem_compassTask_enableKeypad->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('compass on', $mode);
            });
            $subMenu_compassTask->append($menuItem_compassTask_enableKeypad);

            my $menuItem_compassTask_disableKeypad
                = Gtk2::MenuItem->new('_Disable keypad world commands');
            $menuItem_compassTask_disableKeypad->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('compass off', $mode);
            });
            $subMenu_compassTask->append($menuItem_compassTask_disableKeypad);

            $subMenu_compassTask->append(Gtk2::SeparatorMenuItem->new());    # Separator

            my $menuItem_compassTask_addPattern = Gtk2::MenuItem->new('_Customise key...');
            $menuItem_compassTask_addPattern->signal_connect('activate' => sub {

                my (
                    $cmd, $keycode,
                    @comboList,
                );

                @comboList = (
                    'kp_0',
                    'kp_5',
                    'kp_divide',
                    'kp_multiply',
                    'kp_full_stop',
                    'kp_enter',
                );

                # Prompt the user for a pattern
                ($cmd, $keycode) = $self->winObj->showEntryComboDialogue(
                    'Customise keypad key',
                    '(Optional) world command',
                    'Keypad key',
                    \@comboList,
                    undef,          # No max chars
                    TRUE,           # Put combo above entry box
                );

                if (defined $keycode) {

                    if (defined $cmd) {

                        $self->winObj->visibleSession->pseudoCmd(
                            'compass ' . $keycode . ' ' . $cmd,
                            $mode,
                        );

                    } else {

                        $self->winObj->visibleSession->pseudoCmd('compass ' . $keycode, $mode);
                    }
                }
            });
            $subMenu_compassTask->append($menuItem_compassTask_addPattern);

            $subMenu_compassTask->append(Gtk2::SeparatorMenuItem->new());    # Separator

            my $menuItem_compassTask_editTask = Gtk2::ImageMenuItem->new('_Edit current task...');
            my $menuImg_compassTask_editTask = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
            $menuItem_compassTask_editTask->set_image($menuImg_compassTask_editTask);
            $menuItem_compassTask_editTask->signal_connect('activate' => sub {

                my $session = $self->winObj->visibleSession;

                # Open up a task 'edit' window to edit the task, with the 'main' window as the
                #   parent
                $self->winObj->createFreeWin(
                    'Games::Axmud::EditWin::Task',
                    $self->winObj,
                    $session,
                    'Edit ' . $session->compassTask->prettyName . ' task',
                    $session->compassTask,
                    FALSE,                          # Not temporary
                    # Config
                    'edit_flag' => FALSE,           # Some IVs for current tasks not editable
                );
            });
            $subMenu_compassTask->append($menuItem_compassTask_editTask);

        my $menuItem_compassTask = Gtk2::MenuItem->new('C_ompass task');
        $menuItem_compassTask->set_submenu($subMenu_compassTask);
        $menuColumn_tasks->append($menuItem_compassTask);
        # (Requires a visible session whose status is 'connected' or 'offline' and is running a
        #   Compass task)
        $self->ivAdd('menuItemHash', 'compass_task', $menuItem_compassTask);

            # 'Divert task' submenu
            my $subMenu_divertTask = Gtk2::Menu->new();

            my $menuItem_divertTask_addPattern = Gtk2::MenuItem->new('Add _channel pattern...');
            $menuItem_divertTask_addPattern->signal_connect('activate' => sub {

                my ($pattern, $channel);

                # Prompt the user for a pattern/channel
                ($pattern, $channel) = $self->winObj->showDoubleEntryDialogue(
                    'Add channel pattern',
                    'Enter a pattern (regex)',
                    'Enter a channel (1-16 chars)',
                );

                if (defined $pattern && defined $channel) {

                    $self->winObj->visibleSession->pseudoCmd(
                        'addchannelpattern <' . $channel . '> <' . $pattern . '>',
                        $mode,
                    );
                }
            });
            $subMenu_divertTask->append($menuItem_divertTask_addPattern);

            my $menuItem_divertTask_addException = Gtk2::MenuItem->new('Add _exception pattern...');
            $menuItem_divertTask_addException->signal_connect('activate' => sub {

                # Prompt the user for a pattern
                my $pattern = $self->winObj->showEntryDialogue(
                    'Add exception pattern',
                    'Enter a pattern (regex)',
                );

                if (defined $pattern) {

                    $self->winObj->visibleSession->pseudoCmd(
                        'addchannelpattern -e <' . $pattern . '>',
                        $mode,
                    );
                }
            });
            $subMenu_divertTask->append($menuItem_divertTask_addException);

            my $menuItem_divertTask_listPattern = Gtk2::MenuItem->new('_List patterns');
            $menuItem_divertTask_listPattern->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('listchannelpattern', $mode);
            });
            $subMenu_divertTask->append($menuItem_divertTask_listPattern);

            $subMenu_divertTask->append(Gtk2::SeparatorMenuItem->new());    # Separator

            my $menuItem_divertTask_emptyWindow = Gtk2::MenuItem->new('Empty divert _window');
            $menuItem_divertTask_emptyWindow->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('emptydivertwindow', $mode);
            });
            $subMenu_divertTask->append($menuItem_divertTask_emptyWindow);

            $subMenu_divertTask->append(Gtk2::SeparatorMenuItem->new());    # Separator

            my $menuItem_divertTask_editTask = Gtk2::ImageMenuItem->new('_Edit current task...');
            my $menuImg_divertTask_editTask = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
            $menuItem_divertTask_editTask->set_image($menuImg_divertTask_editTask);
            $menuItem_divertTask_editTask->signal_connect('activate' => sub {

                my $session = $self->winObj->visibleSession;

                # Open up a task 'edit' window to edit the task, with the 'main' window as the
                #   parent
                $self->winObj->createFreeWin(
                    'Games::Axmud::EditWin::Task',
                    $self->winObj,
                    $session,
                    'Edit ' . $session->divertTask->prettyName . ' task',
                    $session->divertTask,
                    FALSE,                          # Not temporary
                    # Config
                    'edit_flag' => FALSE,           # Some IVs for current tasks not editable
                );
            });
            $subMenu_divertTask->append($menuItem_divertTask_editTask);

        my $menuItem_divertTask = Gtk2::MenuItem->new('_Divert task');
        $menuItem_divertTask->set_submenu($subMenu_divertTask);
        $menuColumn_tasks->append($menuItem_divertTask);
        # (Requires a visible session whose status is 'connected' or 'offline' and is running a
        #   Divert task)
        $self->ivAdd('menuItemHash', 'divert_task', $menuItem_divertTask);

            # 'Inventory/Condition task' submenu
            my $subMenu_inventoryTask = Gtk2::Menu->new();

            my $menuItem_inventoryTask_activateTask = Gtk2::MenuItem->new('_Activate task');
            $menuItem_inventoryTask_activateTask->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('activateinventory', $mode);
            });
            $subMenu_inventoryTask->append($menuItem_inventoryTask_activateTask);

            my $menuItem_inventoryTask_disactivateTask = Gtk2::MenuItem->new('_Disactivate task');
            $menuItem_inventoryTask_disactivateTask->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('disactivateinventory', $mode);
            });
            $subMenu_inventoryTask->append($menuItem_inventoryTask_disactivateTask);

            $subMenu_inventoryTask->append(Gtk2::SeparatorMenuItem->new()); # Separator

            my $menuItem_inventoryTask_sellAll = Gtk2::MenuItem->new('_Sell all');
            $menuItem_inventoryTask_sellAll->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('sellall', $mode);
            });
            $subMenu_inventoryTask->append($menuItem_inventoryTask_sellAll);

            my $menuItem_inventoryTask_dropAll = Gtk2::MenuItem->new('D_rop all');
            $menuItem_inventoryTask_dropAll->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('dropall', $mode);
            });
            $subMenu_inventoryTask->append($menuItem_inventoryTask_dropAll);

            $subMenu_inventoryTask->append(Gtk2::SeparatorMenuItem->new());    # Separator

            my $menuItem_inventoryTask_editTask = Gtk2::ImageMenuItem->new(
                'Edit current _Inventory task...',
            );
            my $menuImg_inventoryTask_editTask = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
            $menuItem_inventoryTask_editTask->set_image($menuImg_inventoryTask_editTask);
            $menuItem_inventoryTask_editTask->signal_connect('activate' => sub {

                my $session = $self->winObj->visibleSession;

                # Open up a task 'edit' window to edit the task, with the 'main' window as the
                #   parent
                $self->winObj->createFreeWin(
                    'Games::Axmud::EditWin::Task',
                    $self->winObj,
                    $session,
                    'Edit ' . $session->inventoryTask->prettyName . ' task',
                    $session->inventoryTask,
                    FALSE,                          # Not temporary
                    # Config
                    'edit_flag' => FALSE,           # Some IVs for current tasks not editable
                );
            });
            $subMenu_inventoryTask->append($menuItem_inventoryTask_editTask);

            my $menuItem_conditionTask_editTask = Gtk2::ImageMenuItem->new(
                'Edit current _Condition task...',
            );
            my $menuImg_conditionTask_editTask = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
            $menuItem_conditionTask_editTask->set_image($menuImg_conditionTask_editTask);
            $menuItem_conditionTask_editTask->signal_connect('activate' => sub {

                my $session = $self->winObj->visibleSession;

                # Open up a task 'edit' window to edit the task, with the 'main' window as the
                #   parent
                $self->winObj->createFreeWin(
                    'Games::Axmud::EditWin::Task',
                    $self->winObj,
                    $session,
                    'Edit ' . $session->conditionTask->prettyName . ' task',
                    $session->conditionTask,
                    FALSE,                          # Not temporary
                    # Config
                    'edit_flag' => FALSE,           # Some IVs for current tasks not editable
                );
            });
            $subMenu_inventoryTask->append($menuItem_conditionTask_editTask);

        my $menuItem_inventoryTask = Gtk2::MenuItem->new('_Inventory/Condition tasks');
        $menuItem_inventoryTask->set_submenu($subMenu_inventoryTask);
        $menuColumn_tasks->append($menuItem_inventoryTask);
        # (Requires a visible session whose status is 'connected' or 'offline' and is running a
        #   Inventory task)
        $self->ivAdd('menuItemHash', 'inventory_task', $menuItem_inventoryTask);

            # 'Locator task' submenu
            my $subMenu_locatorTask = Gtk2::Menu->new();

            my $menuItem_locatorTask_resetTask = Gtk2::MenuItem->new('_Reset task');
            $menuItem_locatorTask_resetTask->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('resetlocatortask', $mode);
            });
            $subMenu_locatorTask->append($menuItem_locatorTask_resetTask);

            my $menuItem_locatorTask_toggleLocWin = Gtk2::MenuItem->new('Toggle task _window');
            $menuItem_locatorTask_toggleLocWin->signal_connect('activate' => sub {

                if ($self->winObj->visibleSession->locatorTask->winObj) {

                    $self->winObj->visibleSession->pseudoCmd('closetaskwindow locator', $mode);

                } else {

                    $self->winObj->visibleSession->pseudoCmd('opentaskwindow locator', $mode);
                }
            });
            $subMenu_locatorTask->append($menuItem_locatorTask_toggleLocWin);

            $subMenu_locatorTask->append(Gtk2::SeparatorMenuItem->new());   # Separator

            my $menuItem_locatorTask_toggleUnknown
                = Gtk2::MenuItem->new('_Toggle unknown word collection');
            $menuItem_locatorTask_toggleUnknown->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('collectunknownwords', $mode);
            });
            $subMenu_locatorTask->append($menuItem_locatorTask_toggleUnknown);

            my $menuItem_locatorTask_emptyUnknown
                = Gtk2::MenuItem->new('Empty _unknown word list');
            $menuItem_locatorTask_emptyUnknown->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('emptyunknownwords', $mode);
            });
            $subMenu_locatorTask->append($menuItem_locatorTask_emptyUnknown);

            my $menuItem_locatorTask_displayUnknown
                = Gtk2::MenuItem->new('_Display unknown word list');
            $menuItem_locatorTask_displayUnknown->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('listunknownwords', $mode);
            });
            $subMenu_locatorTask->append($menuItem_locatorTask_displayUnknown);

            $subMenu_locatorTask->append(Gtk2::SeparatorMenuItem->new());   # Separator

            my $menuItem_locatorWiz = Gtk2::ImageMenuItem->new('Run Locator wi_zard...');
            my $menuImg_locatorWiz = Gtk2::Image->new_from_stock('gtk-page-setup', 'menu');
            $menuItem_locatorWiz->set_image($menuImg_locatorWiz);
            $menuItem_locatorWiz->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('locatorwizard', $mode);
            });
            $subMenu_locatorTask->append($menuItem_locatorWiz);
            # (Requires a visible session whose status is 'connected' or 'offline'. A
            #   corresponding menu item also appears in $self->drawEditColumn)
            $self->ivAdd('menuItemHash', 'run_locator_wiz_2', $menuItem_locatorWiz);

            $subMenu_locatorTask->append(Gtk2::SeparatorMenuItem->new());   # Separator

            my $menuItem_locatorTask_editTask = Gtk2::ImageMenuItem->new('_Edit current task...');
            my $menuImg_locatorTask_editTask = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
            $menuItem_locatorTask_editTask->set_image($menuImg_locatorTask_editTask);
            $menuItem_locatorTask_editTask->signal_connect('activate' => sub {

                my $session = $self->winObj->visibleSession;

                # Open up a task 'edit' window to edit the task, with the 'main' window as the
                #   parent
                $self->winObj->createFreeWin(
                    'Games::Axmud::EditWin::Task',
                    $self->winObj,
                    $session,
                    'Edit ' . $session->locatorTask->prettyName . ' task',
                    $session->locatorTask,
                    FALSE,                          # Not temporary
                    # Config
                    'edit_flag' => FALSE,           # Some IVs for current tasks not editable
                );
            });
            $subMenu_locatorTask->append($menuItem_locatorTask_editTask);

        my $menuItem_locatorTask = Gtk2::MenuItem->new('_Locator task');
        $menuItem_locatorTask->set_submenu($subMenu_locatorTask);
        $menuColumn_tasks->append($menuItem_locatorTask);
        # (Requires a visible session whose status is 'connected' or 'offline' and is running a
        #   Locator task)
        $self->ivAdd('menuItemHash', 'locator_task', $menuItem_locatorTask);

            # 'Status task' submenu
            my $subMenu_statusTask = Gtk2::Menu->new();

            my $menuItem_statusTask_activateTask = Gtk2::MenuItem->new('_Activate task');
            $menuItem_statusTask_activateTask->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('activatestatustask', $mode);
            });
            $subMenu_statusTask->append($menuItem_statusTask_activateTask);

            my $menuItem_statusTask_disactivateTask = Gtk2::MenuItem->new('_Disactivate task');
            $menuItem_statusTask_disactivateTask->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('disactivatestatustask', $mode);
            });
            $subMenu_statusTask->append($menuItem_statusTask_disactivateTask);

            my $menuItem_statusTask_resetCounters = Gtk2::MenuItem->new('_Reset all counters');
            $menuItem_statusTask_resetCounters->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('resetcounter', $mode);
            });
            $subMenu_statusTask->append($menuItem_statusTask_resetCounters);

            $subMenu_statusTask->append(Gtk2::SeparatorMenuItem->new());    # Separator

            # 'Gauges' submenu
            my $subMenu_gauges = Gtk2::Menu->new();

            my $menuItem_statusTask_toggleStatWin = Gtk2::MenuItem->new('Toggle task _window');
            $menuItem_statusTask_toggleStatWin->signal_connect('activate' => sub {

                if ($self->winObj->visibleSession->statusTask->winObj) {

                    $self->winObj->visibleSession->pseudoCmd('closetaskwindow status', $mode);

                } else {

                    $self->winObj->visibleSession->pseudoCmd('opentaskwindow status', $mode);
                }
            });
            $subMenu_gauges->append($menuItem_statusTask_toggleStatWin);

            my $menuItem_statusTask_showGauge = Gtk2::MenuItem->new('Toggle _gauges');
            $menuItem_statusTask_showGauge->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('showstatusgauge', $mode);
            });
            $subMenu_gauges->append($menuItem_statusTask_showGauge);

            my $menuItem_statusTask_showGaugeLabel = Gtk2::MenuItem->new('Toggle gauge _labels');
            $menuItem_statusTask_showGaugeLabel->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('showstatusgauge -l', $mode);
            });
            $subMenu_gauges->append($menuItem_statusTask_showGaugeLabel);

            my $menuItem_gauges = Gtk2::MenuItem->new('D_isplay');
            $menuItem_gauges->set_submenu($subMenu_gauges);
            $subMenu_statusTask->append($menuItem_gauges);

            $subMenu_statusTask->append(Gtk2::SeparatorMenuItem->new());    # Separator

            my $menuItem_statusTask_editTask = Gtk2::ImageMenuItem->new('_Edit current task...');
            my $menuImg_statusTask_editTask = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
            $menuItem_statusTask_editTask->set_image($menuImg_statusTask_editTask);
            $menuItem_statusTask_editTask->signal_connect('activate' => sub {

                my $session = $self->winObj->visibleSession;

                # Open up a task 'edit' window to edit the task, with the 'main' window as the
                #   parent
                $self->winObj->createFreeWin(
                    'Games::Axmud::EditWin::Task',
                    $self->winObj,
                    $session,
                    'Edit ' . $session->statusTask->prettyName . ' task',
                    $session->statusTask,
                    FALSE,                          # Not temporary
                    # Config
                    'edit_flag' => FALSE,           # Some IVs for current tasks not editable
                );
            });
            $subMenu_statusTask->append($menuItem_statusTask_editTask);

        my $menuItem_statusTask = Gtk2::MenuItem->new('_Status task');
        $menuItem_statusTask->set_submenu($subMenu_statusTask);
        $menuColumn_tasks->append($menuItem_statusTask);
        # (Requires a visible session whose status is 'connected' or 'offline' and is running a
        #   Status task)
        $self->ivAdd('menuItemHash', 'status_task', $menuItem_statusTask);

            # 'Watch' submenu
            my $subMenu_watchTask = Gtk2::Menu->new();

            my $menuItem_watchTask_emptyWindow = Gtk2::MenuItem->new('Empty _watch window');
            $menuItem_watchTask_emptyWindow->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('emptywatchwindow', $mode);
            });
            $subMenu_watchTask->append($menuItem_watchTask_emptyWindow);

            $subMenu_watchTask->append(Gtk2::SeparatorMenuItem->new());    # Separator

            my $menuItem_watchTask_editTask = Gtk2::ImageMenuItem->new('_Edit current task...');
            my $menuImg_watchTask_editTask = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
            $menuItem_watchTask_editTask->set_image($menuImg_watchTask_editTask);
            $menuItem_watchTask_editTask->signal_connect('activate' => sub {

                my $session = $self->winObj->visibleSession;

                # Open up a task 'edit' window to edit the task, with the 'main' window as the
                #   parent
                $self->winObj->createFreeWin(
                    'Games::Axmud::EditWin::Task',
                    $self->winObj,
                    $session,
                    'Edit ' . $session->watchTask->prettyName . ' task',
                    $session->watchTask,
                    FALSE,                          # Not temporary
                    # Config
                    'edit_flag' => FALSE,           # Some IVs for current tasks not editable
                );
            });
            $subMenu_watchTask->append($menuItem_watchTask_editTask);

        my $menuItem_watchTask = Gtk2::MenuItem->new('_Watch task');
        $menuItem_watchTask->set_submenu($subMenu_watchTask);
        $menuColumn_tasks->append($menuItem_watchTask);
        # (Requires a visible session whose status is 'connected' or 'offline' and is running a
        #   Watch task)
        $self->ivAdd('menuItemHash', 'watch_task', $menuItem_watchTask);

        $menuColumn_tasks->append(Gtk2::SeparatorMenuItem->new());  # Separator

            # 'Other tasks' submenu
            my $subMenu_otherTask = Gtk2::Menu->new();

            my $menuItem_attackTask_editTask = Gtk2::ImageMenuItem->new(
                'Edit current _Attack task...',
            );
            my $menuImg_attackTask_editTask = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
            $menuItem_attackTask_editTask->set_image($menuImg_attackTask_editTask);
            $menuItem_attackTask_editTask->signal_connect('activate' => sub {

                my $session = $self->winObj->visibleSession;

                # Open up a task 'edit' window to edit the task, with the 'main' window as the
                #   parent
                $self->winObj->createFreeWin(
                    'Games::Axmud::EditWin::Task',
                    $self->winObj,
                    $session,
                    'Edit ' . $session->attackTask->prettyName . ' task',
                    $session->attackTask,
                    FALSE,                          # Not temporary
                    # Config
                    'edit_flag' => FALSE,           # Some IVs for current tasks not editable
                );
            });
            $subMenu_otherTask->append($menuItem_attackTask_editTask);
            # (Requires a visible session whose status is 'connected' or 'offline' and is running an
            #   Attack task)
            $self->ivAdd('menuItemHash', 'edit_attack_task', $menuItem_attackTask_editTask);

            my $menuItem_advanceTask_editTask = Gtk2::ImageMenuItem->new(
                'Edit current Ad_vance task...',
            );
            my $menuImg_advanceTask_editTask = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
            $menuItem_advanceTask_editTask->set_image($menuImg_advanceTask_editTask);
            $menuItem_advanceTask_editTask->signal_connect('activate' => sub {

                my $session = $self->winObj->visibleSession;

                # Open up a task 'edit' window to edit the task, with the 'main' window as the
                #   parent
                $self->winObj->createFreeWin(
                    'Games::Axmud::EditWin::Task',
                    $self->winObj,
                    $session,
                    'Edit ' . $session->advanceTask->prettyName . ' task',
                    $session->advanceTask,
                    FALSE,                          # Not temporary
                    # Config
                    'edit_flag' => FALSE,           # Some IVs for current tasks not editable
                );
            });
            $subMenu_otherTask->append($menuItem_advanceTask_editTask);
            # (Requires a visible session whose status is 'connected' or 'offline' and is running an
            #   Advance task)
            $self->ivAdd('menuItemHash', 'edit_advance_task', $menuItem_advanceTask_editTask);

            my $menuItem_rawTokenTask_editTask = Gtk2::ImageMenuItem->new(
                'Edit current Raw _Token task...',
            );
            my $menuImg_rawTokenTask_editTask = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
            $menuItem_rawTokenTask_editTask->set_image($menuImg_rawTokenTask_editTask);
            $menuItem_rawTokenTask_editTask->signal_connect('activate' => sub {

                my $session = $self->winObj->visibleSession;

                # Open up a task 'edit' window to edit the task, with the 'main' window as the
                #   parent
                $self->winObj->createFreeWin(
                    'Games::Axmud::EditWin::Task',
                    $self->winObj,
                    $session,
                    'Edit ' . $session->rawTokenTask->prettyName . ' task',
                    $session->rawTokenTask,
                    FALSE,                          # Not temporary
                    # Config
                    'edit_flag' => FALSE,           # Some IVs for current tasks not editable
                );
            });
            $subMenu_otherTask->append($menuItem_rawTokenTask_editTask);
            # (Requires a visible session whose status is 'connected' or 'offline' and is running a
            #   RawToken task)
            $self->ivAdd('menuItemHash', 'edit_raw_token_task', $menuItem_rawTokenTask_editTask);

            my $menuItem_systemTask_editTask = Gtk2::ImageMenuItem->new(
                'Edit current S_ystem task...',
            );
            my $menuImg_systemTask_editTask = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
            $menuItem_systemTask_editTask->set_image($menuImg_systemTask_editTask);
            $menuItem_systemTask_editTask->signal_connect('activate' => sub {

                my $session = $self->winObj->visibleSession;

                # Open up a task 'edit' window to edit the task, with the 'main' window as the
                #   parent
                $self->winObj->createFreeWin(
                    'Games::Axmud::EditWin::Task',
                    $self->winObj,
                    $session,
                    'Edit ' . $session->systemTask->prettyName . ' task',
                    $session->systemTask,
                    FALSE,                          # Not temporary
                    # Config
                    'edit_flag' => FALSE,           # Some IVs for current tasks not editable
                );
            });
            $subMenu_otherTask->append($menuItem_systemTask_editTask);
            # (Requires a visible session whose status is 'connected' or 'offline' and is running a
            #   System task)
            $self->ivAdd('menuItemHash', 'edit_system_task', $menuItem_systemTask_editTask);

            my $menuItem_taskListTask_editTask = Gtk2::ImageMenuItem->new(
                'Edit current _TaskList task...',
            );
            my $menuImg_taskListTask_editTask = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
            $menuItem_taskListTask_editTask->set_image($menuImg_taskListTask_editTask);
            $menuItem_taskListTask_editTask->signal_connect('activate' => sub {

                my $session = $self->winObj->visibleSession;

                # Open up a task 'edit' window to edit the task, with the 'main' window as the
                #   parent
                $self->winObj->createFreeWin(
                    'Games::Axmud::EditWin::Task',
                    $self->winObj,
                    $session,
                    'Edit ' . $session->taskListTask->prettyName . ' task',
                    $session->taskListTask,
                    FALSE,                          # Not temporary
                    # Config
                    'edit_flag' => FALSE,           # Some IVs for current tasks not editable
                );
            });
            $subMenu_otherTask->append($menuItem_taskListTask_editTask);
            # (Requires a visible session whose status is 'connected' or 'offline' and is running a
            #   TaskList task)
            $self->ivAdd('menuItemHash', 'edit_task_list_task', $menuItem_taskListTask_editTask);

        my $menuItem_otherTask = Gtk2::MenuItem->new('_Other built-in tasks');
        $menuItem_otherTask->set_submenu($subMenu_otherTask);
        $menuColumn_tasks->append($menuItem_otherTask);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'other_task', $menuItem_otherTask);

        # Setup complete
        return $menuColumn_tasks;
    }

    sub drawDisplayColumn {

        # Called by $self->enableMenu
        # Sets up the menu's 'Display' column
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or if the menu can't be created
        #   Otherwise returns the Gtk2::Menu created

        my ($self, $check) = @_;

        # Local variables
        my $mode;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawDisplayColumn', @_);
        }

        # Import IVs (for convenience)
        $mode = $self->winObj->pseudoCmdMode;

        # Set up column
        my $menuColumn_display = Gtk2::Menu->new();
        if (! $menuColumn_display) {

            return undef;
        }

        my $menuItem_openAutomapper = Gtk2::ImageMenuItem->new('Open auto_mapper');
        my $menuImg_openAutomapper = Gtk2::Image->new_from_stock('gtk-jump-to', 'menu');
        $menuItem_openAutomapper->set_image($menuImg_openAutomapper);
        $menuItem_openAutomapper->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('openautomapper', $mode);
        });
        $menuColumn_display->append($menuItem_openAutomapper);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'open_automapper', $menuItem_openAutomapper);

        my $menuItem_openViewer = Gtk2::ImageMenuItem->new('Open _object viewer');
        my $menuImg_openViewer = Gtk2::Image->new_from_stock('gtk-jump-to', 'menu');
        $menuItem_openViewer->set_image($menuImg_openViewer);
        $menuItem_openViewer->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('openobjectviewer', $mode);
        });
        $menuColumn_display->append($menuItem_openViewer);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'open_object_viewer', $menuItem_openViewer);

        $menuColumn_display->append(Gtk2::SeparatorMenuItem->new());    # Separator

        my $menuItem_sessionScreenshot = Gtk2::MenuItem->new('Take session _screenshot');
        $menuItem_sessionScreenshot->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('screenshot', $mode);
        });
        $menuColumn_display->append($menuItem_sessionScreenshot);
        # (Requires a visible session)
        $self->ivAdd('menuItemHash', 'session_screenshot', $menuItem_sessionScreenshot);

        $menuColumn_display->append(Gtk2::SeparatorMenuItem->new());    # Separator

            # 'Current layer' submenu
            my $subMenu_currentLayer = Gtk2::Menu->new();

            my $menuItem_currentLayer_moveUp = Gtk2::MenuItem->new('Move _up');
            $menuItem_currentLayer_moveUp->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('layerup', $mode);
            });
            $subMenu_currentLayer->append($menuItem_currentLayer_moveUp);

            my $menuItem_currentLayer_moveDown = Gtk2::MenuItem->new('Move _down');
            $menuItem_currentLayer_moveDown->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('layerdown', $mode);
            });
            $subMenu_currentLayer->append($menuItem_currentLayer_moveDown);

            $subMenu_currentLayer->append(Gtk2::SeparatorMenuItem->new());  # Separator

            my $menuItem_currentLayer_moveTop = Gtk2::MenuItem->new('Move to _top');
            $menuItem_currentLayer_moveTop->signal_connect('activate' => sub {

                # Get the workspace grid object used by the visible session; can't rely on
                #   $self->workspaceGridObj because 'main' windows might appear on several
                #   workspaces
                my $gridObj
                    = $self->winObj->workspaceObj->findWorkspaceGrid($self->visibleSession);

                if ($gridObj) {

                    $self->winObj->visibleSession->pseudoCmd(
                        'setlayer ' . ($gridObj->maxLayers - 1),
                        $mode,
                    );
                }
            });
            $subMenu_currentLayer->append($menuItem_currentLayer_moveTop);

            my $menuItem_currentLayer_moveBottom = Gtk2::MenuItem->new('Move to _bottom');
            $menuItem_currentLayer_moveBottom->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('setlayer 0', $mode);
            });
            $subMenu_currentLayer->append($menuItem_currentLayer_moveBottom);

            $subMenu_currentLayer->append(Gtk2::SeparatorMenuItem->new());  # Separator

            my $menuItem_currentLayer_setLayer = Gtk2::MenuItem->new('_Set layer...');
            $menuItem_currentLayer_setLayer->signal_connect('activate' => sub {

                my ($gridObj, $result);

                $gridObj = $self->winObj->workspaceObj->findWorkspaceGrid($self->visibleSession);

                if ($gridObj) {

                    # Display a dialogue to choose the new layer
                    $result = $self->winObj->showEntryDialogue(
                        'Set layer',
                        'Enter the new layer (in the range 0-' . ($gridObj->maxLayers - 1) . ')',
                    );

                    if ($result) {

                        # Set the layer
                        $self->winObj->visibleSession->pseudoCmd('setlayer ' . $result, $mode);
                    }
                }
            });
            $subMenu_currentLayer->append($menuItem_currentLayer_setLayer);

        my $menuItem_currentLayer = Gtk2::MenuItem->new('C_urrent layer');
        $menuItem_currentLayer->set_submenu($subMenu_currentLayer);
        $menuColumn_display->append($menuItem_currentLayer);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'current_layer', $menuItem_currentLayer);

            # 'Window storage' submenu
            my $subMenu_windowStorage = Gtk2::Menu->new();

            my $menuItem_autoStore
                = Gtk2::CheckMenuItem->new('Automatically store sizes/positions');
            $menuItem_autoStore->signal_connect('toggled' => sub {

                $self->winObj->visibleSession->pseudoCmd('togglewindowstorage', $mode);
            });
            $subMenu_windowStorage->append($menuItem_autoStore);

            my $menuItem_storeCurrent = Gtk2::MenuItem->new('Store current sizes/positions');
            $menuItem_storeCurrent->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('applywindowstorage', $mode);
            });
            $subMenu_windowStorage->append($menuItem_storeCurrent);

            $subMenu_windowStorage->append(Gtk2::SeparatorMenuItem->new());    # Separator

            my $menuItem_resetStorage = Gtk2::MenuItem->new('_Clear stored sizes/positions');
            $menuItem_resetStorage->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('clearwindowstorage', $mode);
            });
            $subMenu_windowStorage->append($menuItem_resetStorage);

        my $menuItem_windowStorage = Gtk2::MenuItem->new('\'Grid\' _window storage');
        $menuItem_windowStorage->set_submenu($subMenu_windowStorage);
        $menuColumn_display->append($menuItem_windowStorage);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'window_storage', $menuItem_windowStorage);

        $menuColumn_display->append(Gtk2::SeparatorMenuItem->new());    # Separator

        my $menuItem_testControls = Gtk2::MenuItem->new('_Test window controls');
        $menuItem_testControls->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('testwindowcontrols', $mode);
        });
        $menuColumn_display->append($menuItem_testControls);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'test_controls', $menuItem_testControls);

        my $menuItem_testPanels = Gtk2::MenuItem->new('T_est panels');
        $menuItem_testPanels->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('testpanel', $mode);
        });
        $menuColumn_display->append($menuItem_testPanels);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'test_panels', $menuItem_testPanels);

        # Setup complete
        return $menuColumn_display;
    }

    sub drawCommandsColumn {

        # Called by $self->enableMenu
        # Sets up the menu's 'Commands' column
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or if the menu can't be created
        #   Otherwise returns the Gtk2::Menu created

        my ($self, $check) = @_;

        # Local variables
        my $mode;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawCommandsColumn', @_);
        }

        # Import IVs (for convenience)
        $mode = $self->winObj->pseudoCmdMode;

        # Set up column
        my $menuColumn_commands = Gtk2::Menu->new();
        if (! $menuColumn_commands) {

            return undef;
        }

        my $menuItem_repeat = Gtk2::ImageMenuItem->new('_Repeat...');
        my $menuImg_repeat = Gtk2::Image->new_from_stock('gtk-redo', 'menu');
        $menuItem_repeat->set_image($menuImg_repeat);
        $menuItem_repeat->signal_connect('activate' => sub {

            # Display a 'dialogue' window so the user can choose the command to repeat, and how
            #   often
            my ($cmd, $number);

            # Display the dialogue
            ($cmd, $number) = $self->winObj->showDoubleEntryDialogue(
                'Repeat command',
                'Enter a world command to repeat',
                'Enter how often to repeat it',
            );

            if ($cmd && $number) {

                # Issue the command
                $self->winObj->visibleSession->pseudoCmd('repeat ' . $number . ' ' . $cmd, $mode);
            }
        });
        $menuColumn_commands->append($menuItem_repeat);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'repeat_cmd', $menuItem_repeat);

        my $menuItem_repeatSecond = Gtk2::ImageMenuItem->new('Repeat each _second...');
        my $menuImg_repeatSecond = Gtk2::Image->new_from_stock('gtk-redo', 'menu');
        $menuItem_repeatSecond->set_image($menuImg_repeatSecond);
        $menuItem_repeatSecond->signal_connect('activate' => sub {

            # Display a 'dialogue' window so the user can choose the command to repeat, and how
            #   often
            my ($cmd, $number);

            # Display the dialogue
            ($cmd, $number) = $self->winObj->showDoubleEntryDialogue(
                'Repeat command',
                'Enter a world command to repeat once a second',
                'Enter how often to repeat it',
            );

            if ($cmd && $number) {

                # Issue the command
                $self->winObj->visibleSession->pseudoCmd(
                    'intervalrepeat ' . $number . ' 1 ' . $cmd,
                    $mode,
                );
            }
        });
        $menuColumn_commands->append($menuItem_repeatSecond);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'repeat_second', $menuItem_repeatSecond);

        my $menuItem_repeatInterval = Gtk2::ImageMenuItem->new('Repeat at _intervals...');
        my $menuImg_repeatInterval = Gtk2::Image->new_from_stock('gtk-redo', 'menu');
        $menuItem_repeatInterval->set_image($menuImg_repeatInterval);
        $menuItem_repeatInterval->signal_connect('activate' => sub {

            # Display a 'dialogue' window so the user can choose the command to repeat, and how
            #   often
            my ($cmd, $number, $interval);

            # Display the dialogue
            ($cmd, $number) = $self->winObj->showDoubleEntryDialogue(
                'Repeat command',
                'Enter a world command to repeat',
                'Enter how often to repeat it',
            );

            if ($cmd && $number) {

                # Display a second dialogue to get the interval
                $interval = $self->winObj->showEntryDialogue(
                    'Repeat command',
                    'Enter an interval (in seconds) between repetitions',
                );

                if ($interval) {

                    # Issue the command
                    $self->winObj->visibleSession->pseudoCmd(
                        'intervalrepeat ' . $number . ' ' . $interval . ' ' . $cmd,
                        $mode,
                    );
                }
            }
        });
        $menuColumn_commands->append($menuItem_repeatInterval);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'repeat_interval', $menuItem_repeatInterval);

        $menuColumn_commands->append(Gtk2::SeparatorMenuItem->new());   # Separator

        my $menuItem_cancelRepeat = Gtk2::ImageMenuItem->new('_Cancel repeating commands');
        my $menuImg_cancelRepeat = Gtk2::Image->new_from_stock('gtk-cancel', 'menu');
        $menuItem_cancelRepeat->set_image($menuImg_cancelRepeat);
        $menuItem_cancelRepeat->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('stopcommand', $mode);
        });
        $menuColumn_commands->append($menuItem_cancelRepeat);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'cancel_repeat', $menuItem_cancelRepeat);

        # Setup complete
        return $menuColumn_commands;
    }

    sub drawRecordingsColumn {

        # Called by $self->enableMenu
        # Sets up the menu's 'Recordings' column
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or if the menu can't be created
        #   Otherwise returns the Gtk2::Menu created

        my ($self, $check) = @_;

        # Local variables
        my $mode;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawRecordingsColumn', @_);
        }

        # Import IVs (for convenience)
        $mode = $self->winObj->pseudoCmdMode;

        # Set up column
        my $menuColumn_recordings = Gtk2::Menu->new();
        if (! $menuColumn_recordings) {

            return undef;
        }

        my $menuItem_startStop = Gtk2::ImageMenuItem->new('_Start/stop recording');
        my $menuImg_startStop = Gtk2::Image->new_from_stock('gtk-media-record', 'menu');
        $menuItem_startStop->set_image($menuImg_startStop);
        $menuItem_startStop->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('record', $mode);
        });
        $menuColumn_recordings->append($menuItem_startStop);
        # (Requires a visible session whose status is 'connected' or 'offline', and
        #   GA::Session->recordingPausedFlag set to FALSE)
        $self->ivAdd('menuItemHash', 'start_stop_recording', $menuItem_startStop);

        my $menuItem_pauseResume = Gtk2::ImageMenuItem->new('_Pause/resume recording');
        my $menuImg_pauseResume = Gtk2::Image->new_from_stock('gtk-media-pause', 'menu');
        $menuItem_pauseResume->set_image($menuImg_pauseResume);
        $menuItem_pauseResume->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('pauserecording', $mode);
        });
        $menuColumn_recordings->append($menuItem_pauseResume);
        # (Requires a visible session whose status is 'connected' or 'offline', and
        #   GA::Session->recordingFlag set to TRUE)
        $self->ivAdd('menuItemHash', 'pause_recording', $menuItem_pauseResume);

        $menuColumn_recordings->append(Gtk2::SeparatorMenuItem->new()); # Separator

            # 'Add line' submenu
            my $subMenu_addLine = Gtk2::Menu->new();

            my $menuItem_addWorldCmd = Gtk2::MenuItem->new('Add _world command...');
            $menuItem_addWorldCmd->signal_connect('activate' => sub {

                # Display a 'dialogue' window, so the user can choose the command to add
                my $text = $self->winObj->showEntryDialogue(
                    'Recording',
                    'Enter a world command to add at this point in the recording',
                );

                if ($text) {

                    # Add the world command
                    $self->winObj->visibleSession->pseudoCmd('worldcommand' . $text, $mode);
                }
            });
            $subMenu_addLine->append($menuItem_addWorldCmd);

            my $menuItem_addClientCmd = Gtk2::MenuItem->new('Add _client command...');
            $menuItem_addClientCmd->signal_connect('activate' => sub {

                # Display a 'dialogue' window, so the user can choose the command to add
                my $text = $self->winObj->showEntryDialogue(
                    'Recording',
                    'Enter a client command to add at this point in the recording',
                );

                if ($text) {

                    # Add the client command
                    $self->winObj->visibleSession->pseudoCmd('clientcommand' . $text, $mode);
                }
            });
            $subMenu_addLine->append($menuItem_addClientCmd);

            my $menuItem_addComment = Gtk2::MenuItem->new('Add co_mment...');
            $menuItem_addComment->signal_connect('activate' => sub {

                # Display a 'dialogue' window, so the user can choose the comment to add
                my $text = $self->winObj->showEntryDialogue(
                    'Recording',
                    'Enter a comment to add at this point in the recording',
                );

                if ($text) {

                    # Add the comment
                    $self->winObj->visibleSession->pseudoCmd('comment' . $text, $mode);
                }
            });
            $subMenu_addLine->append($menuItem_addComment);

        my $menuItem_addLine = Gtk2::MenuItem->new('Add _line');
        $menuItem_addLine->set_submenu($subMenu_addLine);
        $menuColumn_recordings->append($menuItem_addLine);
        # (Requires a visible session whose status is 'connected' or 'offline' and a visible session
        #   whose ->recordingFlag set to TRUE)
        $self->ivAdd('menuItemHash', 'recording_add_line', $menuItem_addLine);

            # 'Add break' submenu
            my $subMenu_addBreak = Gtk2::Menu->new();

            my $menuItem_ordinaryBreak = Gtk2::MenuItem->new('Add _ordinary break');
            $menuItem_ordinaryBreak->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('break', $mode);
            });
            $subMenu_addBreak->append($menuItem_ordinaryBreak);

            my $menuItem_triggerBreak = Gtk2::MenuItem->new('Add _trigger break...');
            $menuItem_triggerBreak->signal_connect('activate' => sub {

                # Display a 'dialogue' window, so the user can choose the trigger pattern to add
                my $text = $self->winObj->showEntryDialogue(
                    'Recording',
                    'Enter a trigger pattern to add at this point in the recording',
                );

                if ($text) {

                    # Add the trigger break
                    $self->winObj->visibleSession->pseudoCmd('break -t ' . $text, $mode);
                }
            });
            $subMenu_addBreak->append($menuItem_triggerBreak);

            my $menuItem_pauseBreak = Gtk2::MenuItem->new('Add pause _break...');
            $menuItem_pauseBreak->signal_connect('activate' => sub {

                # Display a 'dialogue' window, so the user can choose the pause interval to add
                my $text = $self->winObj->showEntryDialogue(
                    'Recording',
                    'Enter the length of the pause break to add at this point in the recording',
                );

                if ($text) {

                    # Add the pause break
                    $self->winObj->visibleSession->pseudoCmd('break -p ' . $text, $mode);
                }
            });
            $subMenu_addBreak->append($menuItem_pauseBreak);

            my $menuItem_locatorBreak = Gtk2::MenuItem->new('Add _Locator task break');
            $menuItem_locatorBreak->signal_connect('activate' => sub {

                $self->winObj->visibleSession->pseudoCmd('break -l', $mode);
            });
            $subMenu_addBreak->append($menuItem_locatorBreak);

        my $menuItem_addBreak = Gtk2::MenuItem->new('Add _break');
        $menuItem_addBreak->set_submenu($subMenu_addBreak);
        $menuColumn_recordings->append($menuItem_addBreak);
        # (Requires a visible session whose status is 'connected' or 'offline' and a visible session
        #   whose ->recordingFlag set to TRUE)
        $self->ivAdd('menuItemHash', 'recording_add_break', $menuItem_addBreak);

        $menuColumn_recordings->append(Gtk2::SeparatorMenuItem->new()); # Separator

        my $menuItem_insertPoint = Gtk2::MenuItem->new('Set _insertion point...');
        $menuItem_insertPoint->signal_connect('activate' => sub {

            # Display a 'dialogue' window, so the user can choose the insertion point
            my $text = $self->winObj->showEntryDialogue(
                'Recording',
                'Enter the line number at which to continue the recording',
            );

            if ($text) {

                # Set the insertion point
                $self->winObj->visibleSession->pseudoCmd('insertrecording ' . $text, $mode);
            }
        });
        $menuColumn_recordings->append($menuItem_insertPoint);
        # (Requires a visible session whose status is 'connected' or 'offline' and a visible session
        #   whose ->recordingFlag set to TRUE)
        $self->ivAdd('menuItemHash', 'recording_set_insertion', $menuItem_insertPoint);

        my $menuItem_cancelInsert = Gtk2::MenuItem->new('Ca_ncel insertion point');
        $menuItem_cancelInsert->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('insertrecording', $mode);
        });
        $menuColumn_recordings->append($menuItem_cancelInsert);
        # (Requires a visible session whose status is 'connected' or 'offline' and a visible session
        #   whose ->recordingFlag set to TRUE)
        $self->ivAdd('menuItemHash', 'recording_cancel_insertion', $menuItem_cancelInsert);

        $menuColumn_recordings->append(Gtk2::SeparatorMenuItem->new()); # Separator

        my $menuItem_deleteLine = Gtk2::MenuItem->new('_Delete line...');
        $menuItem_deleteLine->signal_connect('activate' => sub {

            # Display a 'dialogue' window, so the user can choose the line to delete
            my $text = $self->winObj->showEntryDialogue(
                'Recording',
                'Enter the number of the line to delete',
            );

            if ($text) {

                # Delete the line
                $self->winObj->visibleSession->pseudoCmd('deleterecording ' . $text, $mode);
            }
        });
        $menuColumn_recordings->append($menuItem_deleteLine);
        # (Requires a visible session whose status is 'connected' or 'offline' and a visible session
        #   whose ->recordingFlag set to TRUE)
        $self->ivAdd('menuItemHash', 'recording_delete_line', $menuItem_deleteLine);

        my $menuItem_deleteMulti = Gtk2::MenuItem->new('D_elete lines...');
        $menuItem_deleteMulti->signal_connect('activate' => sub {

            # Display a 'dialogue' window, so the user can choose the lines to delete
            my ($start, $stop) = $self->winObj->showDoubleEntryDialogue(
                'Recording',
                'Enter the number of the first line to be deleted',
                'Enter the number of the last line to be deleted',
            );

            if (defined $start && defined $stop) {

                # Delete the line
                $self->winObj->visibleSession->pseudoCmd(
                    'deleterecording ' . $start . ' ' . $stop,
                    $mode,
                );
            }
        });
        $menuColumn_recordings->append($menuItem_deleteMulti);
        # (Requires a visible session whose status is 'connected' or 'offline' and a visible session
        #   whose ->recordingFlag set to TRUE)
        $self->ivAdd('menuItemHash', 'recording_delete_multi', $menuItem_deleteMulti);

        my $menuItem_deleteLast = Gtk2::MenuItem->new('Delete l_ast line');
        $menuItem_deleteLast->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('deleterecording', $mode);

        });
        $menuColumn_recordings->append($menuItem_deleteLast);
        # (Requires a visible session whose status is 'connected' or 'offline' and a visible session
        #   whose ->recordingFlag set to TRUE)
        $self->ivAdd('menuItemHash', 'recording_delete_last', $menuItem_deleteLast);

        $menuColumn_recordings->append(Gtk2::SeparatorMenuItem->new()); # Separator

        my $menuItem_showRecording = Gtk2::MenuItem->new('S_how recording');
        $menuItem_showRecording->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('listrecording', $mode);
        });
        $menuColumn_recordings->append($menuItem_showRecording);
        # (Requires a visible session whose status is 'connected' or 'offline' and a visible session
        #   whose ->recordingFlag set to TRUE)
        $self->ivAdd('menuItemHash', 'show_recording', $menuItem_showRecording);

        my $menuItem_copyRecording = Gtk2::MenuItem->new('Copy _recording');
        $menuItem_copyRecording->signal_connect('activate' => sub {

            $self->winObj->visibleSession->pseudoCmd('copyrecording', $mode);
        });
        $menuColumn_recordings->append($menuItem_copyRecording);
        # (Requires a visible session whose status is 'connected' or 'offline' and a visible session
        #   whose ->recordingFlag set to TRUE)
        $self->ivAdd('menuItemHash', 'copy_recording', $menuItem_copyRecording);

        # Setup complete
        return $menuColumn_recordings;
    }

    sub drawAxbasicColumn {

        # Called by $self->enableMenu
        # Sets up the menu's 'Axbasic' column
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or if the menu can't be created
        #   Otherwise returns the Gtk2::Menu created

        my ($self, $check) = @_;

        # Local variables
        my $mode;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawAxbasicColumn', @_);
        }

        # Import IVs (for convenience)
        $mode = $self->winObj->pseudoCmdMode;

        # Set up column
        my $menuColumn_basic = Gtk2::Menu->new();
        if (! $menuColumn_basic) {

            return undef;
        }

        my $menuItem_runScript = Gtk2::ImageMenuItem->new('Run _script...');
        my $menuImg_runScript = Gtk2::Image->new_from_stock('gtk-execute', 'menu');
        $menuItem_runScript->set_image($menuImg_runScript);
        $menuItem_runScript->signal_connect('activate' => sub {

            # Display a 'dialogue' window, so the user can choose the script to run
            my $text = $self->winObj->showEntryDialogue(
                'Run ' . $axmud::BASIC_NAME . ' script',
                'Enter the script to run (e.g. \'wumpus\')',
            );

            if ($text) {

                # Run the script
                $self->winObj->visibleSession->pseudoCmd('runscript ' . $text, $mode);
            }
        });
        $menuColumn_basic->append($menuItem_runScript);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'run_script', $menuItem_runScript);

        my $menuItem_runScriptTask = Gtk2::ImageMenuItem->new('Run script as _task...');
        my $menuImg_runScriptTask = Gtk2::Image->new_from_stock('gtk-execute', 'menu');
        $menuItem_runScriptTask->set_image($menuImg_runScriptTask);
        $menuItem_runScriptTask->signal_connect('activate' => sub {

            # Display a 'dialogue' window, so the user can choose the script to run
            my $text = $self->winObj->showEntryDialogue(
                'Run ' . $axmud::BASIC_NAME . ' script',
                'Enter the script to run as a task (e.g. \'wumpus\')',
            );

            if ($text) {

                # Run the script as a task
                $self->winObj->visibleSession->pseudoCmd('runscripttask ' . $text, $mode);
            }
        });
        $menuColumn_basic->append($menuItem_runScriptTask);
        # (Requires a visible session whose status is 'connected' or 'offline')
        $self->ivAdd('menuItemHash', 'run_script_task', $menuItem_runScriptTask);

        $menuColumn_basic->append(Gtk2::SeparatorMenuItem->new()); # Separator

        my $menuItem_checkScript = Gtk2::MenuItem->new('_Check script...');
        $menuItem_checkScript->signal_connect('activate' => sub {

            # Display a 'dialogue' window, so the user can choose the script to check
            my $text = $self->winObj->showEntryDialogue(
                'Check ' . $axmud::BASIC_NAME . ' script',
                'Enter the script to check (e.g. \'wumpus\')',
            );

            if ($text) {

                # Check the script
                $self->winObj->visibleSession->pseudoCmd('checkscript ' . $text, $mode);
            }
        });
        $menuColumn_basic->append($menuItem_checkScript);
        # (Requires a visible session)
        $self->ivAdd('menuItemHash', 'check_script', $menuItem_checkScript);

        my $menuItem_editScript = Gtk2::ImageMenuItem->new('_Edit script...');
        my $menuImg_editScript = Gtk2::Image->new_from_stock('gtk-edit', 'menu');
        $menuItem_editScript->set_image($menuImg_editScript);
        $menuItem_editScript->signal_connect('activate' => sub {

            # Display a 'dialogue' window, so the user can choose the script to check
            my $text = $self->winObj->showEntryDialogue(
                'Edit ' . $axmud::BASIC_NAME . ' script',
                'Enter the script to edit (e.g. \'wumpus\')',
            );

            if ($text) {

                # Edit the script
                $self->winObj->visibleSession->pseudoCmd('editscript ' . $text, $mode);
            }
        });
        $menuColumn_basic->append($menuItem_editScript);
        # (Requires a visible session)
        $self->ivAdd('menuItemHash', 'edit_script', $menuItem_editScript);

        # Setup complete
        return $menuColumn_basic;
    }

    sub drawPluginsColumn {

        # Called by $self->enableMenu
        # Sets up the menu's 'Plugins' column
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or if the menu can't be created
        #   Otherwise returns the Gtk2::Menu created

        my ($self, $check) = @_;

        # Local variables
        my $mode;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawPluginsColumn', @_);
        }

        # Import IVs (for convenience)
        $mode = $self->winObj->pseudoCmdMode;

        # Set up column
        my $menuColumn_plugins = Gtk2::Menu->new();
        if (! $menuColumn_plugins) {

            return undef;
        }

        my $menuItem_loadPlugin = Gtk2::ImageMenuItem->new('_Load plugin...');
        my $menuImg_loadPlugin = Gtk2::Image->new_from_stock('gtk-open', 'menu');
        $menuItem_loadPlugin->set_image($menuImg_loadPlugin);
        $menuItem_loadPlugin->signal_connect('activate' => sub {

            # Load the plugin
            $self->winObj->visibleSession->pseudoCmd('loadplugin', $mode);
        });
        $menuColumn_plugins->append($menuItem_loadPlugin);
        # (Requires a visible session)
        $self->ivAdd('menuItemHash', 'load_plugin', $menuItem_loadPlugin);

        my $menuItem_showPlugins = Gtk2::MenuItem->new('_Show plugins...');
        $menuItem_showPlugins->signal_connect('activate' => sub {

            # Open the client preference window at the right page
            my $prefWin = $self->winObj->createFreeWin(
                'Games::Axmud::PrefWin::Client',
                $self->winObj,
                $self->winObj->visibleSession,
                'Client preferences',
            );

            if ($prefWin) {

                $prefWin->notebook->set_current_page(2);
            }
        });
        $menuColumn_plugins->append($menuItem_showPlugins);
        # (Requires a visible session)
        $self->ivAdd('menuItemHash', 'show_plugin', $menuItem_showPlugins);

        # Setup complete
        return $menuColumn_plugins;
    }

    sub drawHelpColumn {

        # Called by $self->enableMenu
        # Sets up the menu's 'Help' column
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments, or if the menu can't be created
        #   Otherwise returns the Gtk2::Menu created

        my ($self, $check) = @_;

        # Local variables
        my $mode;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->drawHelpColumn', @_);
        }

        # Import IVs (for convenience)
        $mode = $self->winObj->pseudoCmdMode;

        # Set up column
        my $menuColumn_help = Gtk2::Menu->new();
        if (! $menuColumn_help) {

            return undef;
        }

        my $menuItem_help = Gtk2::ImageMenuItem->new('_Help...');
        my $menuImg_help = Gtk2::Image->new_from_stock('gtk-help', 'menu');
        $menuItem_help->set_image($menuImg_help);
        $menuItem_help->signal_connect('activate' => sub {

            # Check that the About window isn't already open
            if ($axmud::CLIENT->aboutWin) {

                # Only one About window can be open at a time
                $axmud::CLIENT->aboutWin->restoreFocus();
                # Open it at the right page
                $axmud::CLIENT->aboutWin->notebook->set_current_page(2);

            } else {

                # Open the About window
                my $winObj = $self->winObj->quickFreeWin(
                    'Games::Axmud::OtherWin::About',
                    $self->winObj->visibleSession,
                    # Config
                    'first_tab' => 'help',
                );

                if ($winObj) {

                    $axmud::CLIENT->set_aboutWin($winObj);
                }
            }
        });
        $menuColumn_help->append($menuItem_help);

        $menuColumn_help->append(Gtk2::SeparatorMenuItem->new());   # Separator

        my $menuItem_about = Gtk2::ImageMenuItem->new('_About...');
        my $menuImg_about = Gtk2::Image->new_from_stock('gtk-about', 'menu');
        $menuItem_about->set_image($menuImg_about);
        $menuItem_about->signal_connect('activate' => sub {

            # Check that the About window isn't already open
            if ($axmud::CLIENT->aboutWin) {

                # Window already open; draw attention to the fact by 'present'ing it
                $axmud::CLIENT->aboutWin->restoreFocus();
                # Open it at the right page
                $axmud::CLIENT->aboutWin->notebook->set_current_page(0);

            } else {

                # Open the About window
                my $winObj = $self->winObj->quickFreeWin(
                    'Games::Axmud::OtherWin::About',
                    $self->winObj->visibleSession,
                    # Config
                    'first_tab' => 'about',
                );

                if ($winObj) {

                    # Only one About window can be open at a time
                    $axmud::CLIENT->set_aboutWin($winObj);
                }
            }
        });
        $menuColumn_help->append($menuItem_about);

        my $menuItem_credits = Gtk2::MenuItem->new('_Credits...');
        $menuItem_credits->signal_connect('activate' => sub {

            # Check that the About window isn't already open
            if ($axmud::CLIENT->aboutWin) {

                # Window already open; draw attention to the fact by 'present'ing it
                $axmud::CLIENT->aboutWin->restoreFocus();
                # Open it at the right page
                $axmud::CLIENT->aboutWin->notebook->set_current_page(1);

            } else {

                # Open the About window
                my $winObj = $self->winObj->quickFreeWin(
                    'Games::Axmud::OtherWin::About',
                    $self->winObj->visibleSession,
                    # Config
                    'first_tab' => 'credits',
                );

                if ($winObj) {

                    # Only one About window can be open at a time
                    $axmud::CLIENT->set_aboutWin($winObj);
                }
            }
        });
        $menuColumn_help->append($menuItem_credits);

        my $menuItem_license = Gtk2::MenuItem->new('_Licenses...');
        $menuItem_license->signal_connect('activate' => sub {

            # Check that the About window isn't already open
            if ($axmud::CLIENT->aboutWin) {

                # Window already open; draw attention to the fact by 'present'ing it
                $axmud::CLIENT->aboutWin->restoreFocus();
                # Open it at the right page
                $axmud::CLIENT->aboutWin->notebook->set_current_page(3);

            } else {

                # Open the About window
                my $winObj = $self->winObj->quickFreeWin(
                    'Games::Axmud::OtherWin::About',
                    $self->winObj->visibleSession,
                    # Config
                    'first_tab' => 'license',
                );

                if ($winObj) {

                    # Only one About window can be open at a time
                    $axmud::CLIENT->set_aboutWin($winObj);
                }
            }
        });
        $menuColumn_help->append($menuItem_license);

        $menuColumn_help->append(Gtk2::SeparatorMenuItem->new());   # Separator

        my $menuItem_website = Gtk2::MenuItem->new($axmud::SCRIPT . ' _website...');
        $menuItem_website->signal_connect('activate' => sub {

            $axmud::CLIENT->openURL($axmud::URL);
        });
        $menuColumn_help->append($menuItem_website);
        # (Requires GA::Client->browserCmd)
        $self->ivAdd('menuItemHash', 'go_website', $menuItem_website);

        # Setup complete
        return $menuColumn_help;
    }

    sub addPluginWidgets {

        # Called by GA::Client->addPluginMenus to add a sub-menu in the 'plugins' column, for the
        #   benefit of a loaded plugin
        # Also called by $self->objEnable to add plugin sub-menus for 'internal' windows that are
        #   created after the plugins are loaded
        #
        # Expected arguments
        #   $plugin     - The plugin name
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise, returns the sub-menu to which the plugin's code can add new menu items

        my ($self, $plugin, $check) = @_;

        # Check for improper arguments
        if (! defined $plugin || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addPluginWidgets', @_);
        }

        # Create a sub-menu for this plugin. If this is the first plugin to add menu items, add a
        #   separator
        if (! $self->pluginHash) {

            $self->pluginMenu->append(Gtk2::SeparatorMenuItem->new());
        }

        # Add a sub-menu
        my $subMenu = Gtk2::Menu->new();

        my $menuItem = Gtk2::MenuItem->new('_' . $plugin . ' plugin');
        $menuItem->set_submenu($subMenu);
        $self->pluginMenu->append($menuItem);

        # Update IVs
        $self->ivAdd('pluginHash', $plugin, $subMenu);
        $self->ivAdd('pluginMenuItemHash', $plugin, $menuItem);

        return $subMenu;
    }

    sub sensitiseWidgets {

        # Can be called by anything, but usually called by GA::Win::Internal->restrictMenuBars
        # Given a list of Gtk2 widgets (all of them menu bar items), sets them as sensitive
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   @widgetList - A list of widget names, matching keys in GA::Win::Internal->menuItemHash
        #                   (e.g. 'move_up_level')
        #
        # Return values
        #   1

        my ($self, @widgetList) = @_;

        # (No improper arguments to check)

        foreach my $widgetName (@widgetList) {

            my $widget = $self->ivShow('menuItemHash', $widgetName);
            if ($widget) {

                $widget->set_sensitive(TRUE);
            }
        }

        return 1;
    }

    sub desensitiseWidgets {

        # Can be called by anything, but usually called by GA::Win::Internal->restrictMenuBars
        # Given a list of Gtk2 widgets (all of them menu bar items), sets them as insensitive
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   @widgetList - A list of widget names, matching keys in GA::Win::Internal->menuItemHash
        #                   (e.g. 'move_up_level')
        #
        # Return values
        #   1

        my ($self, @widgetList) = @_;

        # (No improper arguments to check)

        foreach my $widgetName (@widgetList) {

            my $widget = $self->ivShow('menuItemHash', $widgetName);
            if ($widget) {

                $widget->set_sensitive(FALSE);
            }
        }

        return 1;
    }

    # Menu bar support functions

    sub promptUser {

        # Called by most menu items in $self->drawWorldColumn
        # Before doing an action that will lead to the current connection being closed (e.g. 'Stop
        #   client', which runs the ';stopclient' command), prompt the user for confirmation
        # We don't want the user to lose their connection after accidentally clicking on a menu
        #   item; at the same time, we usually don't ask for confirmation when the user types the
        #   equivalent client command, because they are much less likely to make a mistake while
        #   typing, than while clicking
        #
        # Expected arguments
        #   $title  - The 'dialogue' window title
        #   $msg    - A message to display in the 'dialogue' window
        #
        # Return values
        #   'undef' on improper arguments or if the user clicks 'No' in the 'dialogue' window (or
        #       closes it without clicking 'Yes'
        #   1 if the user clicks on 'Yes' in the 'dialogue' window

        my ($self, $title, $msg, $check) = @_;

        # Local variables
        my $choice;

        # Check for improper arguments
        if (! defined $title || ! defined $msg || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->promptUser', @_);
        }

        # Prompt the user
        $choice = $self->winObj->showMsgDialogue(
            $title,
            'question',
            $msg,
            'yes-no',
        );

        if ($choice eq 'yes') {
            return 1;
        } else {
            return undef;
        }
    }

    sub getWorldList {

        # Called by $self->drawFileColumn
        # Compiles an ordered list of world profile names, with the visible session's current world
        #   as the first item in the list
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, the sorted list of world profile names

        my ($self, $check) = @_;

        # Local variables
        my (@emptyList, @worldList);

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getWorldList', @_);
            return @emptyList;
        }

        foreach my $profObj ($axmud::CLIENT->ivValues('worldProfHash')) {

            if ($profObj ne $self->winObj->visibleSession->currentWorld) {

                push (@worldList, $profObj->name);
            }
        }

        # Now sort the list alphabetically, but put the current world (if any) at the top
        @worldList = sort {lc($a) cmp lc($b)} (@worldList);
        unshift (@worldList, $self->winObj->visibleSession->currentWorld->name);

        # Operation complete
        return @worldList;
    }

    sub getOtherProfList {

        # Called by $self->drawFileColumn
        # Compiles an ordered list of non-world profile names
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, the sorted list of non-world profile names

        my ($self, $check) = @_;

        # Local variables
        my (@emptyList, @profList);

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getOtherProfList', @_);
            return @emptyList;
        }

        foreach my $profObj ($self->winObj->visibleSession->ivValues('profHash')) {

            if ($profObj->category ne 'world') {

                push (@profList, $profObj->name);
            }
        }

        # Now sort the list alphabetically
        @profList = sort {lc($a) cmp lc($b)} (@profList);

        # Operation complete
        return @profList;
    }

    sub getDictList {

        # Called by $self->drawFileColumn
        # Compiles an ordered list of dictionary names, with the current dictionary the first item
        #   on the list
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, the sorted list of dictionary names

        my ($self, $check) = @_;

        # Local variables
        my (@emptyList, @dictList);

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getDictList', @_);
            return @emptyList;
        }

        foreach my $dictName ($axmud::CLIENT->ivKeys('dictHash')) {

            if ($dictName ne $self->winObj->visibleSession->currentDict->name) {

                push (@dictList, $dictName);
            }
        }

        # Now sort the list alphabetically, and insert the current dictionary at the top of the list
        @dictList = sort {lc($a) cmp lc($b)} (@dictList);
        unshift (@dictList, $self->winObj->visibleSession->currentDict->name);

        # Operation complete
        return @dictList;
    }

    sub getFileObjList {

        # Called by $self->drawFileColumn
        # Compiles an ordered list of file object names
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a list in the form (list_reference, hash_reference):
        #       'list_reference'    - list of items to display in a combo box, e.g.
        #                               'deathmud (worldprof)'
        #       'hash_reference'    - hash in which each key is an item in 'list_reference', and
        #                               the corresponding value is the name of the file object
        #   Otherwise, the sorted list of file object names

        my ($self, $check) = @_;

        # Local variables
        my (
            @emptyList, @list, @sortedList,
            %regHash, %checkHash, %returnHash,
        );

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->getDictList', @_);
            return @emptyList;
        }

        # Get a list of client file objects, and sort them alphabetically
        %regHash = $axmud::CLIENT->fileObjHash;
        @list = sort {
            if ($a->fileType ne $b->fileType) {
                $a->fileType cmp $b->fileType
            } else {
                lc($a->name) cmp lc($b->name)
            }
        } (values %regHash);

        foreach my $obj (@list) {

            my $string;

            if ($obj->fileType eq 'worldprof') {
                $string = $obj->name . ' (type: worldprof)';
            } else {
                $string = $obj->name;
            }

            # Don't add the same file object more than once
            if (! exists $checkHash{$obj}) {

                push (@sortedList, $string);
                $returnHash{$string} = $obj;
                $checkHash{$obj} = undef;
            }
        }

        # Get a list of session file objects, and sort them alphabetically
        %regHash = $self->winObj->visibleSession->sessionFileObjHash;
        @list = sort {lc($a->name) cmp lc($b->name)} (values %regHash);

        foreach my $obj (@list) {

            my $string = $obj->name . ' (parent: ' . $obj->assocWorldProf . ')';

            # Don't add the same file object more than once
            if (! exists $checkHash{$obj}) {

                push (@sortedList, $string);
                $returnHash{$string} = $obj->name;
                $checkHash{$obj} = undef;
            }
        }

        # Operation complete
        return (\@sortedList, \%returnHash);
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub menuBar
        { $_[0]->{menuBar} }

    sub menuItemHash
        { my $self = shift; return %{$self->{menuItemHash}}; }

    sub pluginMenu
        { $_[0]->{pluginMenu} }
    sub pluginHash
        { my $self = shift; return %{$self->{pluginHash}}; }
    sub pluginMenuItemHash
        { my $self = shift; return %{$self->{pluginMenuItemHash}}; }

    sub saveAllSessionsFlag
        { $_[0]->{saveAllSessionsFlag} }
}

{ package Games::Axmud::Strip::Toolbar;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Strip Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Win::Internal->drawWidgets or ->addStripObj
        # Creates the GA::Strip::Toolbar - a non-compulsory strip object containing a Gtk2::Toolbar
        #
        # Expected arguments
        #   $number     - The strip object's number within the parent window (matches
        #                   GA::Win::Internal->stripCount, or -1 for a temporary strip object
        #                   created to access its default IVs)
        #   $winObj     - The parent window object (GA::Win::Internal). 'temp' for temporary strip
        #                   objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the strip object's
        #                   initialisation settings. The strip object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - (This type of strip object requires no initialisation settings)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $winObj, %initHash) = @_;

        # Local variables
        my %modHash;

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $winObj) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'strip_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard strip object IVs
            # -------------------------

            # The strip object's number within the parent window (matches
            #   GA::Win::Internal->stripCount, or -1 for a temporary strip object created to access
            #   its default IVs)
            number                      => $number,
            # The type of strip object (custom strip objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in strip objects)
            type                        => 'toolbar',
            # The parent window object (GA::Win::Internal). 'temp' for temporary strip objects
            winObj                      => $winObj,

            # Flag set to TRUE if the strip object is visible (has actually drawn widgets in the
            #   window), set to FALSE if it is not visible (has drawn no widgets in the window, but
            #   still exists in GA::Win::Internal->stripHash, etc)
            # The flag might be set to FALSE in strip objects like GA::Strip::GaugeBox, which might
            #   have gauges to draw, or not, depending on current conditions. (Most strip objects
            #   have this flag set to TRUE all the time)
            # If FALSE, GA::Win::Internal->drawWidgets and ->addStripObj don't draw any widgets when
            #   called by this object's functions
            # NB Strip objects are created with this flag set to TRUE or FALSE, but once created,
            #   the flag's value shouldn't be modified by anything other than
            #   GA::Win::Internal->hideStripObj and ->revealStripObj (which in turn call
            #   $self->set_visibleFlag)
            visibleFlag                 => TRUE,
            # Flag set to TRUE is the strip object should be given its share of any extra space
            #   within the packing box (the extra space is divided equally between all children of
            #   the box whose ->expandFlag is TRUE)
            expandFlag                  => FALSE,
            # Flag set to TRUE if any space given to the strip object by the 'expand' option is
            #   actually allocated within the strip object, FALSE if it is used as padding outside
            #   it (on both sides)
            fillFlag                    => FALSE,
            # Flag set to TRUE if the strip object should be packed into its window with a small
            #   gap between strip objects to either side; FALSE if not (can be set to FALSE if the
            #   the strip object's widgets are drawn in a way, such that a gap is not necessary,
            #   for example in the toolbar strip object)
            spacingFlag                 => FALSE,
            # Flag set to TRUE if only one instance of this strip object should be added to the
            #   parent window, set to FALSE if any number of instances can be added
            jealousyFlag                => TRUE,
            # Flag set to TRUE if this strip object can be added when $axmud::BLIND_MODE_FLAG is
            #   TRUE, FALSE if it can't be added (because it's not useful for visually-impaired
            #   users)
            blindFlag                   => FALSE,
            # Flag set to TRUE if the main container widget, stored in $self->packingBox, should be
            #   allowed to accept the focus, FALSE if not. The restriction is applied during the
            #   call to GA::Win::Internal->drawWidgets and ->addStripObj. Even if FALSE, widgets in
            #   the container widget can be set to accept the focus (e.g. the Gtk2::Entry in
            #   GA::Strip::MenuBar)
            allowFocusFlag              => FALSE,

            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of strip object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this strip object and
            #   its widget(s). Can be any value, including 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => undef,

            # The container widget for this strip object (usually a Gtk2::HBox or Gtk2::VBox). This
            #   widget is the one added to the window's main Gtk2::HBox or Gtk2::VBox
            packingBox                  => undef,       # Gtk2::VBox

            # Other IVs
            # ---------

            # Widgets
            toolbar                     => undef,       # Gtk2::Toolbar
            toolbarWidgetList           => [],          # Various

            # Toolbar buttons which will be sensitised or desensitised, depending on whether the
            #   session is connected to a world (or if it's in 'offline' mode). Hash in the form
            #       $requireConnectHash{'button_name'} = gtk2_widget
            requireConnectHash          => {},
            # Toolbar buttons which will be sensitised or desensitised, depending on whether there
            #   is a visible session for this window. Hash in the form
            #       $requireSessionHash{'button_name'} = gtk2_widget
            requireSessionHash          => {},
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard strip object functions

    sub objEnable {

        # Called by GA::Win::Internal->drawWidgets or ->addStripObj
        # Sets up the strip object's widgets
        #
        # Expected arguments
        #   $winmapObj  - The winmap object (GA::Obj::Winmap) that specifies the layout of the
        #                   parent window
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $winmapObj, $check) = @_;

        # Check for improper arguments
        if (! defined $winmapObj || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Create a packing box
        my $vBox = Gtk2::VBox->new(FALSE, 0);
        $vBox->set_border_width(0);

        # Create a Gtk2::MenuBar
        my $toolbar = Gtk2::Toolbar->new();
        $vBox->pack_start($toolbar, TRUE, TRUE, 0);

        # Update IVs
        $self->ivPoke('packingBox', $vBox);
        $self->ivPoke('toolbar', $toolbar);

        # Draw a set of buttons and separators
        $self->fillToolbar();

        return 1;
    }

    sub objDestroy {

        # Called by GA::Win::Internal->removeStripObj, just before the strip is removed from its
        #   parent window, and also by ->winDestroy and ->resetWinmap, to give this object a chance
        #   to do any necessary tidying up
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objDestroy', @_);
        }

        # (No tidying up required for this type of strip object)
        #   ...

        return 1;
    }

#   sub setWidgetsIfSession {}              # Inherited from GA::Generic::Strip

#   sub setWidgetsChangeSession {}          # Inherited from GA::Generic::Strip

    # ->signal_connects are stored in $self->fillToolbar

    # Other functions

    sub fillToolbar {

        # Called by $self->objEnable and ->resetToolbar
        # Draws a set of toolbar buttons and separators, and adds them to the existing toolbar
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
            $winObj,
            @widgetList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->fillToolbar', @_);
        }

        # Each toolbar button is a GA::Obj::Toolbar object
        foreach my $buttonName ($axmud::CLIENT->toolbarList) {

            my ($separator, $buttonObj, $path, $label, $iconName);

            if ($buttonName eq 'separator') {

                # Add a separator to the toolbar
                my $separator = Gtk2::SeparatorToolItem->new();

                $self->toolbar->insert($separator, -1);
                push (@widgetList, $separator);

            } else {

                $buttonObj = $axmud::CLIENT->ivShow('toolbarHash', $buttonName);

                # Set the path of the icon file. If it doesn't exist, use an emergency fallback icon
                if ($buttonObj->customFlag) {
                    $path = $buttonObj->iconPath;
                } else {
                    $path = $axmud::SHARE_DIR . '/icons/main/' . $buttonObj->iconPath;
                }

                if (! (-e $path)) {

                    # Spare icon
                    $path = $axmud::SHARE_DIR . '/icons/main/drop.png';
                }

                if ($axmud::CLIENT->toolbarLabelFlag) {

                    # Otherwise, $label remains as 'undef', which is what Gtk2::ToolButton is
                    #   expecting
                    $label = $buttonObj->descrip;
                }

                # Create the toolbar button itself
                my $toolButton_item = Gtk2::ToolButton->new(
                    Gtk2::Image->new_from_file($path),
                    $label,
                );
                $toolButton_item->set_tooltip_text($buttonObj->descrip);
                $toolButton_item->signal_connect('clicked' => sub {

                    if ($self->winObj->visibleSession) {

                        $self->winObj->visibleSession->doInstruct($buttonObj->instruct);

                    # The icons for ';connect' and ';openaboutwindow -h' are sensitised even when
                    #   there is no current session. Since we can't call ->doInstruct, process these
                    #   commands directly
                    } elsif ($buttonObj->instruct eq ';connect') {

                        # Check that the Connections window isn't already open
                        if ($axmud::CLIENT->connectWin) {

                            # Window already open; draw attention to the fact by 'present'ing it
                            $axmud::CLIENT->connectWin->restoreFocus();

                        } else {

                            # Open the Connections window
                            $winObj = $self->winObj->quickFreeWin(
                                'Games::Axmud::OtherWin::Connect',
                                $self->winObj->visibleSession,
                            );

                            if ($winObj) {

                                # Only one Connections window can be open at a time
                                $axmud::CLIENT->set_connectWin($winObj);
                            }
                        }

                    } elsif ($buttonObj->instruct eq ';openaboutwindow -h') {

                        # Check that the About window isn't already open
                        if ($axmud::CLIENT->aboutWin) {

                            # Window already open; draw attention to the fact by 'present'ing it
                            $axmud::CLIENT->aboutWin->restoreFocus();

                        } else {

                            # Open the About window
                            $winObj = $self->winObj->quickFreeWin(
                                'Games::Axmud::OtherWin::About',
                                $self->winObj->visibleSession,
                                # Config
                                'first_tab' => 'help',
                            );

                            if ($winObj) {

                                # Only one About window can be open at a time
                                $axmud::CLIENT->set_aboutWin($winObj);
                            }
                        }
                    }

                    # Sensitise/desensitise menu bar/toolbar items, depending on current conditions
                    $axmud::CLIENT->desktopObj->restrictWidgets();
                });

                $iconName = 'icon_' . $buttonObj->name;
                if ($buttonObj->requireConnectFlag) {

                    # (Button requires a connection to a world, even if it's in 'offline' mode)
                    $self->ivAdd('requireConnectHash', $iconName, $toolButton_item);

                } elsif ($buttonObj->requireSessionFlag) {

                    # (Button requires a current session)
                    $self->ivAdd('requireSessionHash', $iconName, $toolButton_item);

                } else {

                    # (Button always sensitised)
                    $self->ivDelete('requireConnectHash', $iconName);
                    $self->ivDelete('requireSessionHash', $iconName);
                }

                # Add the toolbar button to the toolbar
                $self->toolbar->insert($toolButton_item, -1);
                push (@widgetList, $toolButton_item);
            }
        }

        $self->toolbar->show_all();

        # Store the list of buttons and separators
        $self->ivPoke('toolbarWidgetList', @widgetList);

        # Sensitise/desensitise menu bar/toolbar items, depending on current conditions
        $axmud::CLIENT->desktopObj->restrictWidgets();

        # Setup complete
        return 1;
    }

    sub resetToolbar {

        # Called by GA::PrefWin::Client->toolbarTab to re-draw the list of toolbar buttons, after
        #   the GA::Client->toolbarHash and ->toolbarList have been modified
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->resetToolbar', @_);
        }

        # Remove the existing buttons and separators
        foreach my $widget ($self->toolbarWidgetList) {

            $axmud::CLIENT->desktopObj->removeWidget($self->toolbar, $widget);
        }

        # Draw a new set of buttons and separators
        $self->fillToolbar();

        return 1;
    }

    sub sensitiseWidgets {

        # Can be called by anything, but usually called by GA::Win::Internal->restrictMenuBars
        # Given a list of Gtk2 widgets (all of them menu bar items), sets them as sensitive
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   @widgetList - A list of widget names, matching keys in GA::Win::Internal->menuItemHash
        #                   (e.g. 'move_up_level')
        #
        # Return values
        #   1

        my ($self, @widgetList) = @_;

        # (No improper arguments to check)

        foreach my $widgetName (@widgetList) {

            my $widget;

            $widget = $self->ivShow('requireConnectHash', $widgetName);
            if (! $widget) {

                $widget = $self->ivShow('requireSessionHash', $widgetName);
            }

            if ($widget) {

                $widget->set_sensitive(TRUE);
            }
        }

        return 1;
    }

    sub desensitiseWidgets {

        # Can be called by anything, but usually called by GA::Win::Internal->restrictMenuBars
        # Given a list of Gtk2 widgets (all of them menu bar items), sets them as insensitive
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   @widgetList - A list of widget names, matching keys in GA::Win::Internal->menuItemHash
        #                   (e.g. 'move_up_level')
        #
        # Return values
        #   1

        my ($self, @widgetList) = @_;

        # (No improper arguments to check)

        foreach my $widgetName (@widgetList) {

            my $widget;

            $widget = $self->ivShow('requireConnectHash', $widgetName);
            if (! $widget) {

                $widget = $self->ivShow('requireSessionHash', $widgetName);
            }

            if ($widget) {

                $widget->set_sensitive(FALSE);
            }
        }

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub toolbar
        { $_[0]->{toolbar} }
    sub toolbarWidgetList
        { my $self = shift; return @{$self->{toolbarWidgetList}}; }

    sub requireConnectHash
        { my $self = shift; return %{$self->{requireConnectHash}}; }
    sub requireSessionHash
        { my $self = shift; return %{$self->{requireSessionHash}}; }
}

{ package Games::Axmud::Strip::Table;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Strip Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Win::Internal->drawWidgets or ->addStripObj
        # Creates the GA::Strip::Table - a compulsory strip object containing a Gtk2::Table, onto
        #   which widgets can be drawn
        #
        # Expected arguments
        #   $number     - The strip object's number within the parent window (matches
        #                   GA::Win::Internal->stripCount, or -1 for a temporary strip object
        #                   created to access its default IVs)
        #   $winObj     - The parent window object (GA::Win::Internal). 'temp' for temporary strip
        #                   objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the strip object's
        #                   initialisation settings. The strip object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #
        #                       'spacing' - The number of pixels between table objects. If
        #                           specified, can be any integer value in the range 0-10. If not
        #                           specified, an invalid value or 'undef',
        #                           GA::Client->constMainSpacingPixels or ->constGridSpacingPixels
        #                           is used
        #                       'border' - The number of pixels between table objects and the edge
        #                           of the table. If specified, can be any integer value in the
        #                           range 0-10. If not specified, an invalid value or 'undef', 0 is
        #                           used
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $winObj, %initHash) = @_;

        # Local variables
        my (
            $spacing,
            %modHash,
        );

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $winObj) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Default initialisation settings
        if ($winObj ne 'temp' && $winObj->winType eq 'main') {
            $spacing = $axmud::CLIENT->constMainSpacingPixels;
        } else {
            $spacing = $axmud::CLIENT->constGridSpacingPixels;
        }

        %modHash = (
            'spacing'                   => $spacing,
            'border'                    => 0,
        );

        # Interpret the initialisation settings in %initHash, if any
        foreach my $key (keys %modHash) {

            if (exists $initHash{$key}) {

                $modHash{$key} = $initHash{$key};
            }
        }

        # Setup
        my $self = {
            _objName                    => 'strip_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard strip object IVs
            # -------------------------

            # The strip object's number within the parent window (matches
            #   GA::Win::Internal->stripCount, or -1 for a temporary strip object created to access
            #   its default IVs)
            number                      => $number,
            # The type of strip object (custom strip objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in strip objects)
            type                        => 'table',
            # The parent window object (GA::Win::Internal). 'temp' for temporary strip objects
            winObj                      => $winObj,

            # Flag set to TRUE if the strip object is visible (has actually drawn widgets in the
            #   window), set to FALSE if it is not visible (has drawn no widgets in the window, but
            #   still exists in GA::Win::Internal->stripHash, etc)
            # The flag might be set to FALSE in strip objects like GA::Strip::GaugeBox, which might
            #   have gauges to draw, or not, depending on current conditions. (Most strip objects
            #   have this flag set to TRUE all the time)
            # If FALSE, GA::Win::Internal->drawWidgets and ->addStripObj don't draw any widgets when
            #   called by this object's functions
            # NB Strip objects are created with this flag set to TRUE or FALSE, but once created,
            #   the flag's value shouldn't be modified by anything other than
            #   GA::Win::Internal->hideStripObj and ->revealStripObj (which in turn call
            #   $self->set_visibleFlag)
            visibleFlag                 => TRUE,
            # Flag set to TRUE is the strip object should be given its share of any extra space
            #   within the packing box (the extra space is divided equally between all children of
            #   the box whose ->expandFlag is TRUE)
            expandFlag                  => TRUE,
            # Flag set to TRUE if any space given to the strip object by the 'expand' option is
            #   actually allocated within the strip object, FALSE if it is used as padding outside
            #   it (on both sides)
            fillFlag                    => TRUE,
            # Flag set to TRUE if the strip object should be packed into its window with a small
            #   gap between strip objects to either side; FALSE if not (can be set to FALSE if the
            #   the strip object's widgets are drawn in a way, such that a gap is not necessary,
            #   for example in the toolbar strip object)
            spacingFlag                 => TRUE,
            # Flag set to TRUE if only one instance of this strip object should be added to the
            #   parent window, set to FALSE if any number of instances can be added
            jealousyFlag                => TRUE,
            # Flag set to TRUE if this strip object can be added when $axmud::BLIND_MODE_FLAG is
            #   TRUE, FALSE if it can't be added (because it's not useful for visually-impaired
            #   users)
            blindFlag                   => TRUE,
            # Flag set to TRUE if the main container widget, stored in $self->packingBox, should be
            #   allowed to accept the focus, FALSE if not. The restriction is applied during the
            #   call to GA::Win::Internal->drawWidgets and ->addStripObj. Even if FALSE, widgets in
            #   the container widget can be set to accept the focus (e.g. the Gtk2::Entry in
            #   GA::Strip::MenuBar)
            allowFocusFlag              => FALSE,

            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of strip object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this strip object and
            #   its widget(s). Can be any value, including 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => undef,

            # The container widget for this strip object (usually a Gtk2::HBox or Gtk2::VBox). This
            #   widget is the one added to the window's main Gtk2::HBox or Gtk2::VBox
            packingBox                  => undef,       # Gtk2::ScrolledWindow

            # Other IVs
            # ---------

            # Gtk2 widgets to draw the table
            vBox                        => undef,       # Gtk2::VBox
            table                       => undef,       # Gtk2::Table

            # The table size actually used
            tableSize                   => undef,

            # Hash of tablezone objects (GA::Obj::Tablezone), each of which marks out an area of
            #   Gtk2::Table for a single table object. Hash in the form
            #       $zoneHash{number} = blessed_reference_to_tablezone_object
            tablezoneHash               => {},
            # Number of tablezones ever created for this Gtk2::Table (used to give every tablezone
            #   object a number unique to the Gtk2::Table)
            tablezoneCount              => 0,
            # Hash of table objects (inheriting from GA::Generic::Table) which occupy the space
            #   marked out by a single tablezone. Hash in the form
            #       $tableObjHash{number} = blessed_reference_to_table_object
            tableObjHash                => {},
            # Number of table objects ever created for this Gtk2::Table (used to give every table
            #   object a number unique to the Gtk2::Table)
            tableObjCount               => 0,
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard strip object functions

    sub objEnable {

        # Called by GA::Win::Internal->drawWidgets or ->addStripObj
        # Sets up the strip object's widgets
        #
        # Expected arguments
        #   $winmapObj  - The winmap object (GA::Obj::Winmap) that specifies the layout of the
        #                   parent window
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $winmapObj, $check) = @_;

        # Local variables
        my ($spacing, $border);

        # Check for improper arguments
        if (! defined $winmapObj || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Interpret $self->initHash, replacing any invalid values
        $spacing = $self->ivShow('initHash', 'spacing');
        if (! defined $spacing || ! $axmud::CLIENT->intCheck($spacing, 0, 10)) {

            $self->ivAdd('initHash', 'spacing', 0);
        }

        $border = $self->ivShow('initHash', 'border');
        if (! defined $border || ! $axmud::CLIENT->intCheck($border, 0, 10)) {

            $self->ivAdd('initHash', 'border', 0);
        }

        # Create a packing box (a scroller rather than a VBox/HBox, in this case)
        my $scroller = Gtk2::ScrolledWindow->new();
        $scroller->set_policy('automatic', 'automatic');

        # Create a Gtk2::Table whose columns and rows are equally-spaced
        my $vBox = Gtk2::VBox->new(FALSE, 0);
        $vBox->set_border_width($self->ivShow('initHash', 'border'));
        $scroller->add_with_viewport($vBox);

        my $table = Gtk2::Table->new($winmapObj->tableSize, $winmapObj->tableSize, FALSE);
        $vBox->pack_start($table, TRUE, TRUE, 0),
        # To avoid unfortunate textview scrolling problems, the spacing specified in $self->initHash
        #   is only applied when there are two or more table objects in the table
        $table->set_col_spacings(0);
        $table->set_row_spacings(0);

        # Update IVs
        $self->ivPoke('packingBox', $scroller);
        $self->ivPoke('vBox', $vBox);
        $self->ivPoke('table', $table);
        $self->ivPoke('tableSize', $winmapObj->tableSize);

        return 1;
    }

    sub objDestroy {

        # Called by GA::Win::Internal->removeStripObj, just before the strip is removed from its
        #   parent window, and also by ->winDestroy and ->resetWinmap, to give this object a chance
        #   to do any necessary tidying up
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objDestroy', @_);
        }

        # No tidying up required for this type of strip object, but we do call the same function for
        #   any table objects
        foreach my $tableObj ($self->ivValues('tableObjHash')) {

            $tableObj->objDestroy();
        }

        return 1;
    }

    sub setWidgetsIfSession {

        # Called by GA::Win::Internal->setWidgetsIfSession
        # Allows this strip object to sensitise or desensitise its widgets, depending on whether
        #   the parent window has a ->visibleSession at the moment
        # (NB Only 'main' windows have a ->visibleSession; for other 'grid' windows, the flag
        #   argument will be FALSE)
        #
        # Expected arguments
        #   $flag   - TRUE if the parent window has a visible session, FALSE if not
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setWidgetsIfSession', @_);
        }

        # Pass on the message to every table object
        foreach my $tableObj ($self->ivValues('tableObjHash')) {

            $tableObj->setWidgetsIfSession($flag);
        }

        return 1;
    }

    sub setWidgetsChangeSession {

        # Called by GA::Win::Internal->setWidgetsChangeSession
        # Allows this strip object to update its widgets whenever the visible session in any 'main'
        #   window changes
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

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->setWidgetsChangeSession',
                @_,
            );
        }

        # Pass on the message to every table object
        foreach my $tableObj ($self->ivValues('tableObjHash')) {

            $tableObj->setWidgetsChangeSession();
        }

        return 1;
    }

    # ->signal_connects

    # Other functions

    sub addTableObj {

        # Called by GA::Win::Internal->drawWidgets or any other code
        # Adds a table object (inheriting GA::Generic::Table) to this strip object's Gtk2::Table
        #
        # Expected arguments
        #   $packageName
        #       - The package name of the table object to add, e.g. 'Games::Axmud::Table::Pane'
        #   $left, $right, $top, $bottom
        #       - The coordinates of the top-left ($left, $top) and bottom-right ($right, $bottom)
        #           corners of the table object on the table
        #
        # Optional arguments
        #   $objName
        #       - An optional name to give to the table object, when it is created. If not
        #           specified, the table object's ->objName is given the same value as its ->number.
        #           If specified, $objName can be any string (avoid using short strings or numbers.
        #           No part of the code checks that table object names are unique; if two or more
        #           table objects share the same ->objName, usually the one with the lowest ->number
        #           'wins')
        #   %initHash
        #       - A hash containing arbitrary data to use as the table object's initialisation
        #           settings. The table object should use default initialisation settings unless it
        #           can succesfully interpret one or more of the key-value pairs in the hash, if
        #           there are any
        #
        # Return values
        #   'undef' on improper arguments, if the specified space on the table is invalid or already
        #       occupied by a tablezone, or if the table object can't be created
        #   Otherwise returns the blessed reference to the new table object

        my ($self, $packageName, $left, $right, $top, $bottom, $objName, %initHash) = @_;

        # Local variables
        my ($string, $zoneObj, $tableObj, $count);

        # Check for improper arguments
        if (
            ! defined $packageName || ! defined $left || ! defined $right || ! defined $top
            || ! defined $bottom
        ) {
             return $axmud::CLIENT->writeImproper($self->_objClass . '->addTableObj', @_);
        }

        # Table objects must inherit from GA::Generic::Table and must exist (in the case of table
        #   objects loaded from a plugin)
        if (
            ! $packageName =~ m/^Games\:\:Axmud\:\:Table\:\:/
            || ! $axmud::CLIENT->ivExists('customTableHash', $packageName)
        ) {
            if ($axmud::CLIENT->debugTableFitFlag) {

                $self->writeError(
                    'Unrecognised table object package \'' . $packageName . '\'',
                    $self->_objClass . '->addTableObj',
                )
            }

            return undef;
        }

        # Check that the specified area is not outside the bounds of the table
        $string = '(X ' . $left . '-' . $right . ', Y ' . $top . '-' . $bottom . ')';
        if (
            $left < 0 || $right <= $left || $right >= $self->tableSize
            || $top < 0 || $bottom <= $top || $bottom >= $self->tableSize
        ) {
            if ($axmud::CLIENT->debugTableFitFlag) {

                $self->writeError(
                    'Specified area ' . $string . ' is outside the bounds of the table',
                    $self->_objClass . '->addTableObj',
                )
            }

            return undef;
        }

        # Check that the specified area on the table is not already occupied by a tablezone
        foreach my $otherZoneObj ($self->ivValues('tablezoneHash')) {

            if (
                (
                    ($left >= $otherZoneObj->left && $left <= $otherZoneObj->right)
                    || ($right >= $otherZoneObj->left && $right <= $otherZoneObj->right)
                ) && (
                    ($top >= $otherZoneObj->top && $top <= $otherZoneObj->bottom)
                    || ($bottom >= $otherZoneObj->top && $bottom <= $otherZoneObj->bottom)
                )
            ) {
                if ($axmud::CLIENT->debugTableFitFlag) {

                    $self->writeError(
                        'Specified area ' . $string . ' is occupied by an existing table object',
                        $self->_objClass . '->addTableObj',
                    )
                }

                return undef;
            }
        }

        # Create a tablezone, which marks out an area on the Gtk2::Table as being in use by a
        #   single table object
        $zoneObj = Games::Axmud::Obj::Tablezone->new(
            $self->tablezoneCount,
            $packageName,
            $left,
            $top,
            $right,
            $bottom,
        );

        if (! $zoneObj) {

            if ($axmud::CLIENT->debugTableFitFlag) {

                $self->writeError(
                    'Could not allocate space for the table object at the specified position '
                    . $string,
                    $self->_objClass . '->addTableObj',
                )
            }

           return undef;
        }

        # If no $objName was specified, the table object's ->objName IV is the same as its ->number
        #   IV
        if (! defined $objName || $objName eq '') {

            $objName = $self->tableObjCount;
        }

        # Create table object
        $tableObj = $packageName->new($self->tableObjCount, $objName, $self, $zoneObj, %initHash);
        if (! $tableObj) {

            if ($axmud::CLIENT->debugTableFitFlag) {

                $self->writeError(
                    'Failed to create table object',
                    $self->_objClass . '->addTableObj',
                )
            }

            return undef;
        }

        # Set up the table object's widgets
        if (! $tableObj->objEnable()) {

            if ($axmud::CLIENT->debugTableFitFlag) {

                $self->writeError(
                    'Failed to set up the table object\'s widgets',
                    $self->_objClass . '->addTableObj',
                )
            }

            return undef;
        }

        # Add the new table object to this strip's Gtk2::Table
        $self->table->attach_defaults(
            $tableObj->packingBox,
            $zoneObj->left,
            # Axmud uses 59,59, but Gtk expects 60,60
            ($zoneObj->right + 1),
            $zoneObj->top,
            ($zoneObj->bottom + 1),
        );

        # Update IVs
        $self->ivAdd('tablezoneHash', $zoneObj->number, $zoneObj);
        $self->ivIncrement('tablezoneCount');
        $self->ivAdd('tableObjHash', $tableObj->number, $tableObj);
        $self->ivIncrement('tableObjCount');

        # To avoid unfortunate Gtk2 spacing issues, the spacing specified in $self->initHash is
        #   only applied when there are two or more simple list/textview/pane objects in the table
        $count = 0;
        foreach my $otherObj ($self->ivValues('tableObjHash')) {

            if (
                $otherObj->type eq 'simple_list'
                || $otherObj->type eq 'text_view'
                || $otherObj->type eq 'pane'
            ) {
                $count++;
            }
        }

        if ($count <= 1) {

            $self->table->set_col_spacings(0);
            $self->table->set_row_spacings(0);

        } else {

            $self->table->set_col_spacings($self->ivShow('initHash', 'spacing'));
            $self->table->set_row_spacings($self->ivShow('initHash', 'spacing'));
        }

        # Notify all of this window's strip objects of the new table object's birth
        foreach my $stripObj (
            sort {$a->number <=> $b->number} ($self->winObj->ivValues('stripHash'))
        ) {
            $stripObj->notify_addTableObj($tableObj);
        }

        # Notify all of this strip's table objects of the new table object's birth
        foreach my $otherTableObj (
            sort {$a->number <=> $b->number} ($self->ivValues('tableObjHash'))
        ) {
            if ($otherTableObj ne $tableObj) {

                $otherTableObj->notify_addTableObj($tableObj);
            }
        }

        return $tableObj;
    }

    sub removeTableObj {

        # Can be called by anything
        # Removes a table object (inheriting GA::Generic::Table) from this strip object's
        #   Gtk2::Table
        #
        # Expected arguments
        #   $tableObj   - The table object to remove
        #
        # Return values
        #   'undef' on improper arguments, if the table object is protected from removal or if the
        #       table object no longer exists on this strip
        #   1 otherwise

        my ($self, $tableObj, $check) = @_;

        # Local variables
        my ($existFlag, $matchFlag, $count);

        # Check for improper arguments
        if (! defined $tableObj || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->removeTableObj', @_);
        }

        # Don't remove the table object if it's protected
        if (! $tableObj->allowRemoveFlag) {

            if ($axmud::CLIENT->debugTableFitFlag) {

                $self->writeError(
                    'Can\'t remove table object \'' . $tableObj->type . '\' as it is protected',
                    $self->_objClass . '->removeTableObj',
                )
            }

            return undef;
        }

        # Check the table object still exists on this strip
        OUTER: foreach my $obj ($self->ivValues('tableObjHash')) {

            if ($obj eq $tableObj) {

                $existFlag = TRUE;
                last OUTER;
            }
        }

        if (! $existFlag) {

            if ($axmud::CLIENT->debugTableFitFlag) {

                $self->writeError(
                    'Specified table object doesn\'t exist (or no longer exists)',
                    $self->_objClass . '->removeTableObj',
                )
            }

            return undef;
        }


        # Remove the table object
        $axmud::CLIENT->desktopObj->removeWidget($self->table, $tableObj->packingBox);

        # Update IVs
        $self->ivDelete('tableObjHash', $tableObj->number);
        $self->ivDelete('tablezoneHash', $tableObj->zoneObj->number);

        # To avoid unfortunate Gtk2 spacing issues, the spacing specified in $self->initHash is
        #   only applied when there are two or more simple list/textview/pane objects in the table
        $count = 0;
        foreach my $otherObj ($self->ivValues('tableObjHash')) {

            if (
                $otherObj->type eq 'simple_list'
                || $otherObj->type eq 'text_view'
                || $otherObj->type eq 'pane'
            ) {
                $count++;
            }
        }

        if ($count <= 1) {

            $self->table->set_col_spacings(0);
            $self->table->set_row_spacings(0);

        } else {

            $self->table->set_col_spacings($self->ivShow('initHash', 'spacing'));
            $self->table->set_row_spacings($self->ivShow('initHash', 'spacing'));
        }

        # Notify all of this window's strip objects of the table object's demise
        foreach my $stripObj (
            sort {$a->number <=> $b->number} ($self->winObj->ivValues('stripHash'))
        ) {
            $stripObj->notify_removeTableObj($tableObj);
        }

        # Notify all of this strip's table objects of the table object's demise
        foreach my $otherTableObj (
            sort {$a->number <=> $b->number} ($self->ivValues('tableObjHash'))
        ) {
            if ($otherTableObj ne $tableObj) {

                $otherTableObj->notify_removeTableObj($tableObj);
            }
        }

        return 1;
    }

    sub removeAllTableObjs {

        # Can be called by anything
        # Removes all table objects (inheriting GA::Generic::Table) from this strip object's
        #   Gtk2::Table
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if any of the removal operations fail
        #   Otherwise returns the number of objects removed (may be zero)

        my ($self, $check) = @_;

        # Local variables
        my ($count, $failFlag);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->removeAllTableObjs', @_);
        }

        # Remove all table objects
        $count = 0;
        foreach my $tableObj (
            sort {$a->number <=> $b->number} ($self->ivValues('tableObjHash'))
        ) {
            if (! $self->removeTableObj($tableObj)) {
                $failFlag = TRUE;
            } else {
                $count++;
            }
        }

        if ($failFlag) {
            return undef;
        } else {
            return $count;
        }
    }

    sub resizeTableObj {

        # Can be called by anything
        # Resizes a table object (inheriting GA::Generic::Table) on this strip object's
        #   Gtk2::Table
        #
        # Expected arguments
        #   $tableObj   - The table object to resize
        #   $left, $right, $top, $bottom
        #       - The coordinates of the top-left ($left, $top) and bottom-right ($right, $bottom)
        #           corners of the table object on the table
        #
        # Return values
        #   'undef' on improper arguments, if the table object is protected from resizing, if the
        #       table object no longer exists on this strip, if the specified space on the table is
        #       invalid or already occupied by a tablezone, or if the resize operation fails
        #   1 otherwise

        my ($self, $tableObj, $left, $right, $top, $bottom, $check) = @_;

        # Local variables
        my ($flag, $string, $zoneObj);

        # Check for improper arguments
        if (
            ! defined $tableObj || ! defined $left || ! defined $right || ! defined $top
            || ! defined $bottom || defined $check
        ) {
             return $axmud::CLIENT->writeImproper($self->_objClass . '->resizeTableObj', @_);
        }

        # Don't resize the table object if it's protected
        if (! $tableObj->allowResizeFlag) {

            if ($axmud::CLIENT->debugTableFitFlag) {

                $self->writeError(
                    'Can\'t resize table object \'' . $tableObj->type . '\' as it is protected',
                    $self->_objClass . '->resizeTableObj',
                )
            }

            return undef;
        }

        # Check the table object still exists on this strip
        OUTER: foreach my $obj ($self->ivValues('tableObjHash')) {

            if ($obj eq $tableObj) {

                $flag = TRUE;
                last OUTER;
            }
        }

        if (! $flag) {

            if ($axmud::CLIENT->debugTableFitFlag) {

                $self->writeError(
                    'Specified table object doesn\'t exist (or no longer exists)',
                    $self->_objClass . '->resizeTableObj',
                )
            }

            return undef;
        }

        # Check that the specified area is not outside the bounds of the table
        $string = '(X ' . $left . '-' . $right . ', Y ' . $top . '-' . $bottom . ')';
        if (
            $left < 0 || $right <= $left || $right >= $self->tableSize
            || $top < 0 || $bottom <= $top || $bottom >= $self->tableSize
        ) {
            if ($axmud::CLIENT->debugTableFitFlag) {

                $self->writeError(
                    'Specified area ' . $string . ' is outside the bounds of the table',
                    $self->_objClass . '->resizeTableObj',
                )
            }

            return undef;
        }

        # Check that the specified space on the table is not already occupied by a tablezone
        foreach my $otherZoneObj ($self->ivValues('tablezoneHash')) {

            if (
                $tableObj->zoneObj ne $otherZoneObj
                && (
                    ($left >= $otherZoneObj->left && $left <= $otherZoneObj->right)
                    || ($right >= $otherZoneObj->left && $right <= $otherZoneObj->right)
                ) && (
                    ($top >= $otherZoneObj->top && $top <= $otherZoneObj->bottom)
                    || ($bottom >= $otherZoneObj->top && $bottom <= $otherZoneObj->bottom)
                )
            ) {
                if ($axmud::CLIENT->debugTableFitFlag) {

                    $self->writeError(
                        'Specified area ' . $string . ' is occupied by an existing table object',
                        $self->_objClass . '->resizeTableObj',
                    )
                }

               return undef;
            }
        }

        # Remove the old tablezone...
        $self->ivDelete('tablezoneHash', $tableObj->zoneObj->number);

        # ...and create a new one, assigning it to the table object
        $zoneObj = Games::Axmud::Obj::Tablezone->new(
            $self->tablezoneCount,
            $tableObj->_objClass,
            $left,
            $top,
            $right,
            $bottom,
        );

        if (! $zoneObj) {

            if ($axmud::CLIENT->debugTableFitFlag) {

                $self->writeError(
                    'Could not allocate space for the table object at the specified position '
                    . $string,
                    $self->_objClass . '->resizeTableObj',
                )
            }

            return undef;

        } else {

            $self->ivAdd('tablezoneHash', $zoneObj->number, $zoneObj);
            $self->ivIncrement('tablezoneCount');

            $tableObj->set_zoneObj($zoneObj);
        }

        # Resize the table object
        $axmud::CLIENT->desktopObj->removeWidget($self->table, $tableObj->packingBox);

        $self->table->attach_defaults(
            $tableObj->packingBox,
            $zoneObj->left,
            # Axmud uses 59,59, but Gtk expects 60,60
            ($zoneObj->right + 1),
            $zoneObj->top,
            ($zoneObj->bottom + 1),
        );

        # Inform the table object that it's been resized
        $tableObj->setWidgetsOnResize(
            $zoneObj->left,
            $zoneObj->right,
            $zoneObj->top,
            $zoneObj->bottom,
        );

        return 1;
    }

    sub replaceHolder {

        # Called by any code
        # Looks for a holder table object (GA::Table::Holder) with a specified ->id. If one is
        #   found, removes it and adds a different table object using the same size/position. If
        #   one is not found, returns 'undef'
        # (The calling code can call this function as often as it needs to, looking for various
        #   holders, and if none are found, can then call $self->addTableObj directly)
        #
        # Expected arguments
        #   $id - The holder ID; can be any non-empty string. If any holders have an ->id with this
        #           value, that is replaced. Values might include types of 'grid' window such as
        #           'map', or 'task' for task windows in general, or 'status_task' for the Status
        #           task in particular. If not specified, 'undef' or an empty string, 'task' is
        #           used as a default value
        #   $packageName
        #       - The package name of the replacement table object, e.g. GA::Table::Pane
        #
        # Optional arguments
        #   $objName
        #       - An optional name to give to the replacement table object, when it is created. If
        #           not specified, the table object's ->objName is given the same value as its
        #           ->number. If specified, $objName can be any string (avoid using short strings or
        #           numbers. No part of the code checks that table object names are unique; if two
        #           or more table objects share the same ->objName, usually the one with the lowest
        #           ->number 'wins')
        #   %initHash
        #       - A hash containing arbitrary data to use as the table object's initialisation
        #           settings. The table object should use default initialisation settings unless it
        #           can succesfully interpret one or more of the key-value pairs in the hash, if
        #           there are any
        #
        # Return values
        #   'undef' on improper arguments, if no holders with a matching ->id are found or if the
        #       replacement table object can't be created
        #   Otherwise returns the blessed reference to the replacement table object

        my ($self, $id, $packageName, $objName, %initHash) = @_;

        # Check for improper arguments
        if (! defined $id || ! defined $packageName) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->replaceHolder', @_);
        }

        foreach my $tableObj (sort {$a->number <=> $b->number} ($self->ivValues('tableObjHash'))) {

            if (
                $tableObj->type eq 'holder'
                && $tableObj->id
                && $tableObj->id eq $id
            ) {
                # Matching holder found. Remove it from the table
                if (! $self->removeTableObj($tableObj)) {

                    if ($axmud::CLIENT->debugTableFitFlag) {

                        $self->writeError(
                            'Could not replace holder table object due to internal error',
                            $self->_objClass . '->replaceHolder',
                        )
                    }

                    return undef;
                }

                # Add the replacement table object
                return $self->addTableObj(
                    $packageName,
                    $tableObj->zoneObj->left,
                    $tableObj->zoneObj->right,
                    $tableObj->zoneObj->top,
                    $tableObj->zoneObj->bottom,
                    $objName,
                    %initHash,
                );
            }
        }

        # No matching holder found
        if ($axmud::CLIENT->debugTableFitFlag) {

            $self->writeError(
                'Could not replace holder table object - no matching holder found',
                $self->_objClass . '->replaceHolder',
            )
        }

        return undef;
    }

    sub findPosn {

        # The parent window's winmap (GA::Obj::Winmap) specified a default size for new table
        #   objects, added to this strip object after its creation
        # This function checks the table, looking for an unoccupied space of the right size. If a
        #   space is found, the calling function can then call $self->addTableObj to create a
        #   table object in that space
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a list in the form
        #       (left, right, top, bottom)
        #   ...matching the table coordinates that can be used in the subsequent call to
        #       $self->addTableObj

        my ($self, $check) = @_;

        # Local variables
        my (
            $winmapObj, $width, $height,
            @emptyList,
        );

        # Check for improper arguments
        if (defined $check) {

             $axmud::CLIENT->writeImproper($self->_objClass . '->findPosn', @_);
             return @emptyList;
        }

        # Get the parent window's winmap and, from that, get the default size
        if ($self->winObj->winmap) {

            $winmapObj = $axmud::CLIENT->ivShow('winmapHash', $self->winObj->winmap);
            if ($winmapObj) {

                $width = $winmapObj->zoneWidth;
                $height = $winmapObj->zoneHeight;
            }
        }

        if (! defined $width) {

            # (Most standard winmaps use 30x30)
            $width = 30;
            $height = 30;
        }

        # Search left-to-right, then top-to-bottom
        OUTER: for (my $top = 0; $top < $self->tableSize; $top += $height) {

            INNER: for (my $left = 0; $left < $self->tableSize; $left += $width) {

                my ($right, $bottom);

                $right = $left + $width - 1;
                $bottom = $top + $height - 1;

                # Check that the specified position on the table is not already occupied by a
                #   tablezone
                foreach my $zoneObj ($self->ivValues('tablezoneHash')) {

                    if (
                        (
                            ($left >= $zoneObj->left && $left <= $zoneObj->right)
                            || ($right >= $zoneObj->left && $right <= $zoneObj->right)
                        ) && (
                            ($top >= $zoneObj->top && $top <= $zoneObj->bottom)
                            || ($bottom >= $zoneObj->top && $bottom <= $zoneObj->bottom)
                        )
                    ) {
                        # This position is occupied
                        next INNER;
                    }
                }

                # This position is free
                return ($left, $right, $top, $bottom);
            }
        }

        # All positions are occupied
        return @emptyList;
    }

    sub getPosn {

        # Can be called by anything
        # Returns the size and position of an existing table object
        #
        # Expected arguments
        #   $tableObj   - An existing table object
        #
        # Return values
        #   An empty list on improper arguments or if the table object doesn't exist in this strip
        #       object's table
        #   Otherwise, returns a list in the form
        #       (left, right, top, bottom)

        my ($self, $tableObj, $check) = @_;

        # Local variables
        my (
            $zoneObj,
            @emptyList,
        );

        # Check for improper arguments
        if (! defined $tableObj || defined $check) {

             $axmud::CLIENT->writeImproper($self->_objClass . '->getPosn', @_);
             return @emptyList;
        }

        # Check the table object exists on this strip object's table, and get the corresponding
        #   tablezone object (GA::Obj::Tablezone)
        if (
            ! $self->ivExists('tableObjHash', $tableObj->number)
            || $self->ivShow('tableObjHash', $tableObj->number) ne $tableObj
        ) {
            return @emptyList;

        } else {

            $zoneObj = $self->ivShow('tablezoneHash', $tableObj->number);

            return ($zoneObj->left, $zoneObj->right, $zoneObj->top, $zoneObj->bottom);
        }
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub vBox
        { $_[0]->{vBox} }
    sub table
        { $_[0]->{table} }

    sub tableSize
        { $_[0]->{tableSize} }

    sub tablezoneHash
        { my $self = shift; return %{$self->{tablezoneHash}}; }
    sub tablezoneCount
        { $_[0]->{tablezoneCount} }
    sub tableObjHash
        { my $self = shift; return %{$self->{tableObjHash}}; }
    sub tableObjCount
        { $_[0]->{tableObjCount} }
}

{ package Games::Axmud::Strip::GaugeBox;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Strip Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Win::Internal->drawWidgets or ->addStripObj
        # Creates the GA::Strip::GaugeBox - a non-compulsory strip object optionally containing one
        #   or more gauge levels (or none, when this strip object is marked not visible)
        #
        # Expected arguments
        #   $number     - The strip object's number within the parent window (matches
        #                   GA::Win::Internal->stripCount, or -1 for a temporary strip object
        #                   created to access its default IVs)
        #   $winObj     - The parent window object (GA::Win::Internal). 'temp' for temporary strip
        #                   objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the strip object's
        #                   initialisation settings. The strip object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - (This type of strip object requires no initialisation settings)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $winObj, %initHash) = @_;

        # Local variables
        my %modHash;

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $winObj) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'strip_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard strip object IVs
            # -------------------------

            # The strip object's number within the parent window (matches
            #   GA::Win::Internal->stripCount, or -1 for a temporary strip object created to access
            #   its default IVs)
            number                      => $number,
            # The type of strip object (custom strip objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in strip objects)
            type                        => 'gauge_box',
            # The parent window object (GA::Win::Internal). 'temp' for temporary strip objects
            winObj                      => $winObj,

            # Flag set to TRUE if the strip object is visible (has actually drawn widgets in the
            #   window), set to FALSE if it is not visible (has drawn no widgets in the window, but
            #   still exists in GA::Win::Internal->stripHash, etc)
            # The flag might be set to FALSE in strip objects like GA::Strip::GaugeBox, which might
            #   have gauges to draw, or not, depending on current conditions. (Most strip objects
            #   have this flag set to TRUE all the time)
            # If FALSE, GA::Win::Internal->drawWidgets and ->addStripObj don't draw any widgets when
            #   called by this object's functions
            # NB Strip objects are created with this flag set to TRUE or FALSE, but once created,
            #   the flag's value shouldn't be modified by anything other than
            #   GA::Win::Internal->hideStripObj and ->revealStripObj (which in turn call
            #   $self->set_visibleFlag)
            visibleFlag                 => FALSE,      # Wait until the first gauge is drawn
            # Flag set to TRUE is the strip object should be given its share of any extra space
            #   within the packing box (the extra space is divided equally between all children of
            #   the box whose ->expandFlag is TRUE)
            expandFlag                  => FALSE,
            # Flag set to TRUE if any space given to the strip object by the 'expand' option is
            #   actually allocated within the strip object, FALSE if it is used as padding outside
            #   it (on both sides)
            fillFlag                    => TRUE,       # Force canvas to use available width
            # Flag set to TRUE if the strip object should be packed into its window with a small
            #   gap between strip objects to either side; FALSE if not (can be set to FALSE if the
            #   the strip object's widgets are drawn in a way, such that a gap is not necessary,
            #   for example in the toolbar strip object)
            spacingFlag                 => TRUE,
            # Flag set to TRUE if only one instance of this strip object should be added to the
            #   parent window, set to FALSE if any number of instances can be added
            jealousyFlag                => TRUE,
            # Flag set to TRUE if this strip object can be added when $axmud::BLIND_MODE_FLAG is
            #   TRUE, FALSE if it can't be added (because it's not useful for visually-impaired
            #   users)
            blindFlag                   => FALSE,
            # Flag set to TRUE if the main container widget, stored in $self->packingBox, should be
            #   allowed to accept the focus, FALSE if not. The restriction is applied during the
            #   call to GA::Win::Internal->drawWidgets and ->addStripObj. Even if FALSE, widgets in
            #   the container widget can be set to accept the focus (e.g. the Gtk2::Entry in
            #   GA::Strip::MenuBar)
            allowFocusFlag              => FALSE,

            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of strip object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this strip object and
            #   its widget(s). Can be any value, including 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => undef,

            # The container widget for this strip object (usually a Gtk2::HBox or Gtk2::VBox). This
            #   widget is the one added to the window's main Gtk2::HBox or Gtk2::VBox
            packingBox                  => undef,       # Gtk2::VBox

            # Other IVs
            # ---------

            # Widgets
            frame                       => undef,       # Gtk2::Frame
            canvas                      => undef,       # Gnome2::Canvas
            # A list of Gnome2::Canvas::Item objects drawn in the gauge box, which are destroyed
            #   every time $self->drawGauges is called
            gaugeCanvasList             => [],          # Gnome2::Canvas::Item

            # The size of the Gnome2::Canvas used to display gauges (width is the same as the
            #   available space, so only height specified here)
            # The height (in pixels) of gauges. The total height of the gauge will be this value,
            #   plus the spacing above and below it. (Width is the same as the available space, so
            #   only height specified here)
            gaugeHeight                 => 15,
            # Spacing (padding) used between the gauges, and between the edges of the gauge box
            gaugeSpacingX               => 5,
            gaugeSpacingY               => 5,
            # The font and size to use for gauge labels. These default values produce a font that's
            #   about the right the size for a gauge of height $self->gaugeHeight
            gaugeLabelFont              => 'Monospace',
            gaugeLabelFontSize          => 10,
            # Registry hash of GA::Obj::GaugeLevel objects, one for each gauge level drawn in the
            #   gauge box for a single session
            # Hash in the form
            #   $gaugeLevelHash{unique_number} = gauge_level_object
            # ...where 'unique_number' is unique across all sessions
            gaugeLevelHash              => {},
            # The number of gauge levels ever created (used to provide the unique number)
            gaugeLevelCount             => 0,
            # Maximum number of gauge levels (sanity check)
            gaugeLevelMax               => 8,
            # Number of GA::Obj::Gauge objects ever created (used to give each object a unique
            #   number)
            gaugeCount                  => 0,
            # Maximum number of gauges per level (sanity check)
            gaugeMax                    => 10,
            # A list of GA::Obj::Gauge objects that were drawn, the last time $self->updateGauges
            #   was called (may be an empty list)
            gaugeDrawnList              => [],
            # Calls to $self->updateGauges should be allowed to finish, before another call to
            #   the same function is allowed. This flag is set to TRUE at the beginning of a call,
            #   and FALSE at the end of it
            gaugeUpdateFlag             => FALSE,
            # Colour used to draw blank gauges
            gaugeBlankColour            => '#CDCDBA',
            # Default colour for the empty portion of gauges
            gaugeEmptyColour            => '#000000',
            # Default colour used for the full portion of gauges
            gaugeFullColour             => '#FFFFFF',
            # Default colour used for gauge labels
            gaugeLabelColour            => '#FF0000',
            # Colour (always) used to draw the borders of gauges
            gaugeBorderColour           => '#000000',
            # When the last gauge is removed, we should wait a few seconds before removing the
            #   gauge box entirely. For example, if the Status task resets, its gauges are
            #   removed for a moment, and re-drawn as soon as the task is ready
            # If defined, the time (matches GA::Client->clientTime) at which the gauge box should
            #   be removed, if no new gauges have been drawn in the mean time
            gaugeCheckTime              => undef,
            # The time to wait (in seconds)
            gaugeWaitTime               => 1,
            # When $self->addGaugeLevel is called with the no-redraw flag set to TRUE, this flag is
            #   set to TRUE. Then, the next time $self->updateGauges is called, that function knows
            #   that it needs to call $self->replaceStripObj to redraw the gauge box. (This flag is
            #   then set back to FALSE)
            gaugeNoDrawFlag             => FALSE,
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard strip object functions

    sub objEnable {

        # Called by GA::Win::Internal->drawWidgets or ->addStripObj
        # Sets up the strip object's widgets
        #
        # Expected arguments
        #   $winmapObj  - The winmap object (GA::Obj::Winmap) that specifies the layout of the
        #                   parent window
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $winmapObj, $check) = @_;

        # Check for improper arguments
        if (! defined $winmapObj || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # (IVs normally updated here are updated by $self->drawGaugeBox, when it is called)

        return 1;
    }

    sub objDestroy {

        # Called by GA::Win::Internal->removeStripObj, just before the strip is removed from its
        #   parent window, and also by ->winDestroy and ->resetWinmap, to give this object a chance
        #   to do any necessary tidying up
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objDestroy', @_);
        }

        if ($self->visibleFlag) {

            # Only polite to ->destroy Gnome2::Canvas objects when they're no longer needed
            foreach my $canvasObj ($self->gaugeCanvasList) {

                $canvasObj->destroy();
            }
        }

        return 1;
    }

#   sub setWidgetsIfSession {}              # Inherited from GA::Generic::Strip

#   sub setWidgetsChangeSession {}          # Inherited from GA::Generic::Strip

    # ->signal_connects

    # Other functions

    sub drawGaugeBox {

        # Called by $self->objEnable and ->addGaugeLevel
        # Draws a Gtk2::HBox to contain gauge levels
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
            $levelCount,
            %sessionHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->drawGaugeBox', @_);
        }

        # Create a packing box, if one doesn't exist already
        my $packingBox;
        if (! $self->packingBox) {

            # This function is being called for the first time
            $packingBox = Gtk2::VBox->new(FALSE, 0);
            $packingBox->set_border_width(0);

        } else {

            # This function is being called for a subsequent time. Remove its current contents, so
            #   new widgets can be created
            $packingBox = $self->packingBox;
            $axmud::CLIENT->desktopObj->removeWidget($packingBox, $self->frame);
        }

        # Different sessions might be using different numbers of gauge levels. Find the highest
        #   number of gauge levels used by the greediest session (might be 0, if there are no gauge
        #   levels at the moment)
        $levelCount = 0;
        foreach my $gaugeLevelObj ($self->ivValues('gaugeLevelHash')) {

            my $num = $gaugeLevelObj->session->number;

            if (! exists $sessionHash{$num}) {
                $sessionHash{$num} = 1;
            } else {
                $sessionHash{$num} = $sessionHash{$num} + 1;
            }

            if ($levelCount < $sessionHash{$num}) {

                $levelCount = $sessionHash{$num};
            }
        }

        # If there are no gauges visible, draw a gauge box with room for one gauge level anyway, in
        #   the expectation that the first gauge might be added a moment from now
        if (! $levelCount) {

            $levelCount = 1;
        }

        # Add a Gnome2::Canvas
        my $frame = Gtk2::Frame->new(undef);
        $frame->set_border_width(0);
        $frame->set_size_request(
            -1,
            (
                2                           # Size of frame border
                + $self->gaugeSpacingY
                + ($levelCount * ($self->gaugeHeight + $self->gaugeSpacingY))
            ),
        );

        $packingBox->pack_start($frame, TRUE, TRUE, 0);

        my $canvas = Gnome2::Canvas->new();
        $frame->add($canvas);

        # Update IVs
        $self->ivPoke('packingBox', $packingBox);
        $self->ivPoke('frame', $frame);
        $self->ivPoke('canvas', $canvas);

        # Setup complete
        return 1;
    }

    sub removeGaugeBox {

        # Called by GA::Client->spinClientLoop or $self->removeSessionGauges
        # If this window's gauge box has been empty for too long, remove the gauge box entirely
        # (By waiting for a few seconds, we don't have to remove then re-draw the gauge box within
        #   the space of a second if, for example, the Status task resets)
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeGaugeBox', @_);
        }

        # Check that gauge box is actually drawn and doesn't currently contain any gauges
        if ($self->visibleFlag && ! $self->gaugeLevelHash) {

            # Destroy canvas objects
            foreach my $canvasObj ($self->gaugeCanvasList) {

                $canvasObj->destroy();
            }

            # Update IVs
            $self->ivUndef('gaugeCheckTime');

            # Mark the strip object as hidden
            $self->winObj->hideStripObj($self);
        }

        return 1;
    }

    sub addGaugeLevel {

        # Can be called by anything
        # Adds a new gauge level to this window's gauge box (a horizontal band of gauges, of which
        #   there can be 1 or more bands within the gauge box)
        # Updates IVs and redraws the gauge box (if it's not currently visible, draws it in the
        #   expectation that a gauge is about to be added)
        #
        # Expected arguments
        #   $session        - The calling GA::Session
        #
        # Optional arguments
        #   $noDrawFlag     - If set to TRUE, $self->drawGaugeBox is not called immediately (in the
        #                       expectation that the calling function has not finished modifying its
        #                       gauges yet). Otherwise set to FALSE (or 'undef'). If adding gauges
        #                       on multiple levels, all at the same time, set this flag to TRUE for
        #                       a better visual effect
        #
        # Return values
        #   'undef' on improper arguments or on failure
        #   Otherwise, returns the unique number of the gauge level created (the first one ever
        #       created, but not necessarily the first one visible currently, is 0)

        my ($self, $session, $noDrawFlag, $check) = @_;

        # Local variables
        my ($count, $newObj);

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addGaugeLevel', @_);
        }

        # Count the number of gauge levels for this session. If we're already at the maximum, do
        #   nothing
        $count = 0;
        foreach my $gaugeLevelObj ($self->ivValues('gaugeLevelHash')) {

            if ($gaugeLevelObj->session eq $session) {

                $count++;
            }
        }

        if ($count >= $self->gaugeLevelMax) {

            return undef;
        }

        # If the gauge box was due to be removed because it's been empty too long, we can now keep
        #   it (on the understanding that a new gauge is about to be added)
        $self->ivUndef('gaugeCheckTime');

        # Create a new gauge level object
        $newObj = Games::Axmud::Obj::GaugeLevel->new($session, $self->gaugeLevelCount);
        if (! $newObj) {

            return undef;
        }

        # Update IVs
        $self->ivAdd('gaugeLevelHash', $newObj->number, $newObj);
        $self->ivIncrement('gaugeLevelCount');

        # Redraw the gauge box at the right size
        if (! $noDrawFlag) {

            # Redraw the gauge box now
            $self->drawGaugeBox();
            if (! $self->visibleFlag) {
                $self->winObj->revealStripObj($self);
            } else {
                $self->winObj->replaceStripObj($self);
            }

        } else {

            # Redraw the gauge box the next time $self->updateGauges is called
            $self->ivPoke('gaugeNoDrawFlag', TRUE);
        }

        return $newObj->number;
    }

    sub removeGaugeLevel {

        # Can be called by anything
        # Removes an existing gauge level from this window's gauge box (a horizontal band of gauges,
        #   of which there can be 1 or more bands within the gauge box)
        # Any gauges that are currently drawn on that level are destroyed
        # Updates IVs. Redraws the gauge box, or removes it altogether if there are no gauge levels
        #   left
        #
        # Expected arguments
        #   $session    - The calling GA::Session
        #   $level      - The unique number of the gauge level to remove (matches a key in
        #                   $self->gaugeLevelHash). The gauge level must belong to the specified
        #                   $session
        #
        # Optional arguments
        #   $noDrawFlag - If set to TRUE, $self->updateGauges is not called immediately (in the
        #                   expectation that the calling function has not finished modifying its
        #                   gauges yet). Otherwise set to FALSE (or 'undef')
        #
        # Return values
        #   'undef' on improper arguments or on failure
        #   Otherwise returns the number of gauges removed (might be 0)

        my ($self, $session, $level, $noDrawFlag, $check) = @_;

        # Local variables
        my (
            $gaugeLevelObj, $count,
            @list,
        );

        # Check for improper arguments
        if (! defined $level || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeGaugeLevel', @_);
        }

        # Do nothing if the gauge level doesn't exist or if it doesn't match the specified session
        $gaugeLevelObj = $self->ivShow('gaugeLevelHash', $level);
        if (! defined $gaugeLevelObj || $gaugeLevelObj->session ne $session) {

            return undef;
        }

        # Update IVs
        $count = $gaugeLevelObj->ivPairs('gaugeHash');
        $self->ivDelete('gaugeLevelHash', $level);

        # If there are no gauges levels left (in any session), set the time (shortly in the future)
        #   when the gauge box will be removed entirely, if no new gauges have been drawn in the
        #   mean time
        if (! $self->gaugeLevelHash) {

            $self->ivPoke('gaugeCheckTime', ($axmud::CLIENT->clientTime + $self->gaugeWaitTime));
        }

        # If the strip object itself is marked visible ($self->visibleFlag), redraw the gauge box as
        #   the right size (even if it contains no gauges at this precise moment)
        $self->drawGaugeBox();
        if ($self->visibleFlag) {

            $self->winObj->replaceStripObj($self);
            if (! $noDrawFlag) {

                $self->updateGauges();
            }
        }

        return $count;
    }

    sub addGauge {

        # Can be called by anything
        # Adds a new graphical gauge to this window's gauge box, visible only when the calling
        #   GA::Session is the window's visible session. (Text gauges are added with a call to
        #   $self->addTextGauge)
        # If the gauge box itself is not yet visible, draws it
        #
        # Expected arguments
        #   $session        - The calling GA::Session
        #
        # Optional arguments
        #   $level          - The unique number of the GA::Obj::GaugeLevel object to use
        #                       (representing a horizontal band of gauges, of which there can be
        #                       1 or more bands within the gauge box). If the $level number has
        #                       not been added via a call to $self->addGaugeLevel, the gauge is not
        #                       drawn (as a precaution against buggy code). However, if 'undef', the
        #                       gauge is added to the first visible level for the specified
        #                       GA::Session; if none exist for the session, one is created for it
        #                   - NB Ideally, anything that displays gauges (such as a task) should
        #                       create its own gauge level via a call to $self->addGaugeLevel
        #   $value          - The value to display (>= 0)...
        #   $maxValue       - ...and the maximum value (must be >= $value). If either $value or
        #                       $maxValue is undefined, the gauge is drawn a different colour than
        #                       usual
        #   $addFlag        - If TRUE, the total size of the gauge is ($value + $maxValue). If
        #                       FALSE (or 'undef'), the total size is $maxValue
        #   $label          - The label to use with the gauge. If 'undef' or an empty string, no
        #                       label is used
        #   $fullColour     - The colour to use in the 'full' part of the gauge - an Axmud colour
        #                       tag (standard, Xterm or RGB). If 'undef', an empty string or an
        #                       unrecognised colour tag, '#FFFFFF' is used
        #   $emptyColour    - The colour to use in the 'empty' part of the gauge - an Axmud colour
        #                       tag (standard, Xterm or RGB). If 'undef', an empty string or an
        #                       unrecognised colour tag, '#000000' is used
        #   $labelColour    - The label colour to use - - an Axmud colour tag (standard, Xterm or
        #                       RGB). If 'undef', an empty string or an unrecognised colour tag,
        #                       '#FF0000' is used
        #   $labelFlag      - If set to TRUE, the label text (if displayed) is supplemented with the
        #                       values; e.g. 'HP: 37/100'. If FALSE (or 'undef'), only the text in
        #                       $label is visible
        #
        # Return values
        #   'undef' on improper arguments or on failure
        #   Otherwise returns the GA::Obj::Gauge created to store details about the new gauge

        my (
            $self, $session, $level, $value, $maxValue, $addFlag, $label, $fullColour, $emptyColour,
            $labelColour, $labelFlag, $check,
        ) = @_;

        # Local variables
        my (
            $gaugeLevelObj, $newObj,
            @list, @gaugeList,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addGauge', @_);
        }

        if (! defined $level) {

            # If no level was specified, use the first available one. If there are none, create a
            #   new one
            # The first available level is the one with the lowest level number that belongs to
            #   the calling session
            foreach my $gaugeLevelObj ($self->ivValues('gaugeLevelHash')) {

                if (
                    $gaugeLevelObj->session eq $session
                    && (
                        ! defined $level
                        || $level > $gaugeLevelObj->number
                    )
                ) {
                    $level = $gaugeLevelObj->number;
                }
            }

            if (! defined $level) {

                $level = $self->addGaugeLevel($session);
                if (! defined $level) {

                    return undef;
                }
            }

        } elsif (! $self->ivExists('gaugeLevelHash', $level)) {

            # Specfied level has not been created, so as a precaution against buggy code, don't draw
            #   the gauge
            return undef;
        }

        # (For other parts of the code, it's more convenient that $self->addGaugeLevel returns the
        #   gauge level object's unique number, rather than the blessed reference itself. However,
        #   we need the blessed reference)
        $gaugeLevelObj = $self->ivShow('gaugeLevelHash', $level);

        # Apply a check on the maximum number of gauges per level
        if ($gaugeLevelObj->ivPairs('gaugeHash') >= $self->gaugeMax) {

            return undef;
        }

        # If the gauge box isn't currently visible, draw it
        if (! $self->visibleFlag) {

            $self->drawGaugeBox();
            $self->winObj->revealStripObj($self);
        }

        # If the gauge box was due to be removed because it's been empty too long, we can now keep
        #   it
        $self->ivUndef('gaugeCheckTime');

        # Set default values, translating any colour tags in RGB colour tags
        if ($fullColour) {

            $fullColour = $axmud::CLIENT->returnRGBColour($fullColour);
        }

        if (! $fullColour) {

            $fullColour = $self->gaugeFullColour;
        }

        if ($emptyColour) {

            $emptyColour = $axmud::CLIENT->returnRGBColour($emptyColour);
        }

        if (! $emptyColour) {

            $emptyColour = $self->gaugeEmptyColour;
        }

        if (! $addFlag) {
            $addFlag = FALSE;
        } else {
            $addFlag = TRUE;
        }

        if ($labelColour) {

            $labelColour = $axmud::CLIENT->returnRGBColour($labelColour);
        }

        if (! $labelColour) {

            $labelColour = $self->gaugeLabelColour;
        }

        if (! $labelFlag) {
            $labelFlag = FALSE;
        } else {
            $labelFlag = TRUE;
        }

        # Sanity check: $value and/or $maxValue can be 'undef', but if they're specified, they must
        #   be a valid floating-point number
        if (defined $value && ! $axmud::CLIENT->floatCheck($value)) {

            $value = undef;
        }

        if (defined $maxValue && ! $axmud::CLIENT->floatCheck($maxValue)) {

            $maxValue = undef;
        }

        # Create a new GA::Obj::Gauge object for this gauge (do this before drawing the gauge,
        #   because if $session isn't the current session, we don't draw it yet)
        # NB The FALSE argument means this is a graphical gauge, not a text gauge
        $newObj = Games::Axmud::Obj::Gauge->new(
            $session,
            $self->ivIncrement('gaugeCount'),
            $level,
            FALSE,
        );

        if (! $newObj) {

           return undef;

        } else {

            $gaugeLevelObj->ivAdd('gaugeHash', $newObj->number, $newObj);

            $newObj->ivPoke('value', $value);
            $newObj->ivPoke('maxValue', $maxValue);
            $newObj->ivPoke('addFlag', $addFlag);
            $newObj->ivPoke('label', $label);

            $newObj->ivPoke('fullColour', $fullColour);
            $newObj->ivPoke('emptyColour', $emptyColour);
            $newObj->ivPoke('labelColour', $labelColour);
            $newObj->ivPoke('labelFlag', $labelFlag);
        }

        # If $session is the visible one, redraw all of that session's gauges now
        if ($self->winObj->visibleSession && $self->winObj->visibleSession eq $session) {

            $self->updateGauges();
        }

       return $newObj;
    }

    sub addTextGauge {

        # Can be called by anything
        # Adds a new text gauge to the 'main' window's gauge box, visible only when the calling
        #   GA::Session is the current session. (Graphical gauges are added with a call to
        #   $self->addGauge)
        # If the gauge box itself is not yet visible, draws it
        #
        # Expected arguments
        #   $session        - The calling GA::Session
        #
        # Optional arguments
        #   $level          - The unique number of the GA::Obj::GaugeLevel object to use
        #                       (representing a horizontal band of gauges, of which there can be
        #                       1 or more band within the gauge box). If the $level number has
        #                       not been added via a call to $self->addGaugeLevel, the gauge is not
        #                       drawn (as a precaution against buggy code). However, if 'undef', the
        #                       gauge is added to the first visible level for the specified
        #                       GA::Session; if none exist for the session, one is created for it
        #                   - NB Ideally, anything that displays gauges (such as a task) should
        #                       create its own gauge level via a call to $self->addGaugeLevel
        #   $value          - The value to display (>= 0)...
        #   $maxValue       - ...and the maximum value (must be >= $value). If either $value or
        #                       $maxValue is undefined, the gauge is drawn a different colour than
        #                       usual
        #   $addFlag        - If TRUE, the total size of the gauge is ($value + $maxValue). If
        #                       FALSE (or 'undef'), the total size is $maxValue
        #   $label          - The label to use with the gauge. If 'undef' or an empty string, no
        #                       label is used
        #
        # Return values
        #   'undef' on improper arguments or on failure
        #   Otherwise returns the GA::Obj::Gauge created to store details about the new gauge

        my ($self, $session, $level, $value, $maxValue, $addFlag, $label, $check) = @_;

        # Local variables
        my (
            $gaugeLevelObj, $newObj,
            @list, @gaugeList,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addTextGauge', @_);
        }

        if (! defined $level) {

            # If no level was specified, use the first available one. If there are none, create a
            #   new one
            # The first available level is the one with the lowest level number that belongs to
            #   the calling session
            foreach my $gaugeLevelObj ($self->ivValues('gaugeLevelHash')) {

                if (
                    $gaugeLevelObj->session eq $session
                    && (
                        ! defined $level
                        || $level > $gaugeLevelObj->number
                    )
                ) {
                    $level = $gaugeLevelObj->number;
                }
            }

            if (! defined $level) {

                $level = $self->addGaugeLevel($session);
                if (! defined $level) {

                    return undef;
                }
            }

        } elsif (! $self->ivExists('gaugeLevelHash', $level)) {

            # Specfied level has not been created, so as a precaution against buggy code, don't draw
            #   the gauge
            return undef;
        }

        # (For other parts of the code, it's more convenient that $self->addGaugeLevel returns the
        #   gauge level object's unique number, rather than the blessed reference itself. However,
        #   we need the blessed reference)
        $gaugeLevelObj = $self->ivShow('gaugeLevelHash', $level);

        # Apply a check on the maximum number of gauges per level
        if ($gaugeLevelObj->ivPairs('gaugeHash') >= $self->gaugeMax) {

            return undef;
        }

        # If the gauge box isn't currently visible, draw it
        if (! $self->visibleFlag) {

            $self->drawGaugeBox();
            $self->winObj->revealStripObj($self);
        }

        # If the gauge box was due to be removed because it's been empty too long, we can now keep
        #   it
        $self->ivUndef('gaugeCheckTime');

        # Set default values
        if (! $addFlag) {
            $addFlag = FALSE;
        } else {
            $addFlag = TRUE;
        }

        # Sanity check: $value and/or $maxValue can be 'undef', but if they're specified, they must
        #   be a valid decimal number
        if (defined $value && ! $axmud::CLIENT->floatCheck($value)) {

            $value = undef;
        }

        if (defined $maxValue && ! $axmud::CLIENT->floatCheck($maxValue)) {

            $maxValue = undef;
        }

        # Create a new GA::Obj::Gauge object for this gauge (do this before drawing the gauge,
        #   because if $session isn't the current session, we don't draw it yet)
        # NB The TRUE argument means this is a text gauge, not a graphical gauge
        $newObj = Games::Axmud::Obj::Gauge->new(
            $session,
            $self->ivIncrement('gaugeCount'),
            $level,
            TRUE,
        );

        if (! $newObj) {

            return undef;

        } else {

            $gaugeLevelObj->ivAdd('gaugeHash', $newObj->number, $newObj);

            $newObj->ivPoke('value', $value);
            $newObj->ivPoke('maxValue', $maxValue);
            $newObj->ivPoke('addFlag', $addFlag);
            $newObj->ivPoke('label', $label);
        }

        # If $session is the visible one, redraw all of that session's gauges now
        if ($self->winObj->visibleSession && $self->winObj->visibleSession eq $session) {

            $self->updateGauges();
        }

        return $newObj;
    }

    sub removeGauges {

        # Can be called by anything
        # Removes one or more gauges. If the calling GA::Session is the visible one, redraws
        #   everything in the gauge box. If all gauges have now been removed, sets the time at
        #   which the gauge box itself is made invisible
        #
        # Expected arguments
        #   $session        - The calling GA::Session
        #   $keepLevelFlag  - Flag set to TRUE if the gauge level should not be destroyed, if all
        #                       its gauges are removed (probably because the calling code wants to
        #                       add new gauges to it in a moment); set to FALSE if the gauge level
        #                       should be destroyed if all its gauges are removed
        #
        # Optional arguments
        #   @objList        - A list of GA::Obj::Gauge objects (which don't have to belong to the
        #                       calling GA::Session). If it's an empty list, nothing is removed
        #
        # Return values
        #   'undef' on improper arguments or if we're not allowed to draw gauges at all
        #   Otherwise returns the number of gauges removed (might be 0)

        my ($self, $session, $keepLevelFlag, @objList) = @_;

        # Local variables
        my (
            $removeCount, $redrawFlag, $redrawAllFlag,
            @drawList,
        );

        # Check for improper arguments
        if (! defined $session) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeGauges', @_);
        }

        # Update registries
        $removeCount = 0;
        foreach my $gaugeObj (@objList) {

            my $gaugeLevelObj = $self->ivShow('gaugeLevelHash', $gaugeObj->level);

            # Remove the gauge from its gauge level
            if ($gaugeLevelObj->ivExists('gaugeHash', $gaugeObj->number)) {

                $gaugeLevelObj->ivDelete('gaugeHash', $gaugeObj->number);
                $removeCount++;

                # If the calling GA::Session is the visible one, redraw everything in the gauge
                #   box
                if (
                    $self->winObj->visibleSession
                    && $self->winObj->visibleSession eq $session
                    && $gaugeObj->session eq $session
                ) {
                    $redrawFlag = TRUE;

                    # If the gauge level is now empty, remove it (unless the calling function told
                    #   us not to do that)
                    if (! $keepLevelFlag && ! $gaugeLevelObj->gaugeHash) {

                        $self->ivDelete('gaugeLevelHash', $gaugeLevelObj->number);
                        $redrawAllFlag = TRUE;
                    }
                }
            }
        }

        # Redraw widgets, as required
        if ($redrawAllFlag) {

            # Redraw the gauge box as the right size (even if it contains no gauges at this precise
            #   moment)
            $self->drawGaugeBox();
            $self->winObj->replaceStripObj($self);

        } elsif ($redrawFlag) {

            # Redraw the gauges themselves
            $self->updateGauges();
        }

        # If there are no gauges left (in any session), set the time (shortly in the future) when
        #   the gauge box will be removed entirely, if no new gauges have been drawn in the mean
        #   time
        if ($redrawFlag || $redrawAllFlag) {

            if (! $self->gaugeLevelHash) {

                $self->ivPoke(
                    'gaugeCheckTime',
                    ($axmud::CLIENT->clientTime + $self->gaugeWaitTime),
                );
            }
        }

        return $removeCount;
    }

    sub removeSessionGauges {

        # Can be called by anything
        # Complementing $self->removeGauges, this is a short-cut which removes all gauges for a
        #   particular session, without the need for the calling function to specify the gauges
        #   to remove
        # (If the specified session isn't this window's visible session, then no visible gauges are
        #   removed, but IVs are still updated)
        #
        # Expected arguments
        #   $session        - The GA::Session whose gauges should be removed
        #
        # Optional arguments
        #   $boxFlag        - Set to TRUE when called by GA::Session->reactDisconnect. If there are
        #                       no gauges left, the 'main' window code normally waits a few seconds
        #                       before removing the gauge box. However, that won't work if the only
        #                       session has just disconnected, as its timer loop has terminated.
        #                       When the flag is TRUE, the gauge box is removed immediately. Set to
        #                       FALSE (or 'undef') otherwise
        #
        # Return values
        #   'undef' on improper arguments or if we're not allowed to draw gauges at all
        #   Otherwise returns the number of gauges removed (might be 0)

        my ($self, $session, $boxFlag, $check) = @_;

        # Local variables
        my (
            $result,
            @removeList,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeSessionGauges', @_);
        }

        # Get a list of gauges belonging to the specified session
        foreach my $gaugeLevelObj ($self->ivValues('gaugeLevelHash')) {

            if ($gaugeLevelObj->session eq $session) {

                push (@removeList, $gaugeLevelObj->ivValues('gaugeHash'));
            }
        }

        # The FALSE argument means 'don't keep an empty gauge level'
        $result = $self->removeGauges($session, FALSE, @removeList);

        # Remove the gauge box immediately, if instructed
        if (! $self->gaugeLevelHash && $boxFlag) {

            $self->removeGaugeBox();
        }

        return $result;
    }

    sub updateGauges {

        # Can be called by anything
        # Updates the gauges currently drawn in the gauge box, redrawing them. If this window's
        #   visible session has changed, a new set of gauges is drawn, replacing the previous ones
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
            $result,
            @drawList,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateGauges', @_);
        }

        # Do nothing if the gauge box isn't actually visible (because no gauges have been drawn by
        #   any session), or if another call to this function is still being processed
        if (! $self->visibleFlag || $self->gaugeUpdateFlag) {
            return undef;
        } else {
            $self->ivPoke('gaugeUpdateFlag', TRUE);
        }

        # If a recent call to $self->addGaugeLevel specified that the gauge box shouldn't be
        #   redrawn yet, then redraw it now
        if ($self->gaugeNoDrawFlag) {

            $self->drawGaugeBox();
            $self->winObj->replaceStripObj($self);
            $self->ivPoke('gaugeNoDrawFlag', FALSE);
        }

        # Compile an ordered list of gauges that should be visible (so that gauge levels and gauges
        #   are always drawn in the same order)
        foreach my $gaugeLevelObj (
            sort {$a->number <=> $b->number} ($self->ivValues('gaugeLevelHash'))
        ) {
            if (
                $self->winObj->visibleSession
                && $self->winObj->visibleSession eq $gaugeLevelObj->session
            ) {
                push (
                    @drawList,
                    sort {$a->number <=> $b->number} ($gaugeLevelObj->ivValues('gaugeHash')),
                );
            }
        }

        $result = $self->drawGauges(@drawList);
        # Subsequent calls to this function are now allowed again
        $self->ivPoke('gaugeUpdateFlag', FALSE);

        return $result;
    }

    sub drawGauges {

        # Called by $self->updateGauges or ->removeGauges (but not by any other code)
        # Draws 0, 1 or more gauges in the gauge box, destroying any canvas objects that were drawn
        #   on the previous call to this function
        # The calling function should ensure that only the current session's gauges are specified
        #   as arguments, and that all gauges belonging to that session are specified
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   @drawList       - A list of GA::Obj::Gauge objects (which must belong to the current
        #                       GA::Session). If it's an empty list, no new gauges are drawn
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, @drawList) = @_;

        # Local variables
        my (
            $rect, $boxWidth, $count, $root, $visLevel,
            @canvasObjList,
            %levelHash, %widthHash, %checkHash,
        );

        # (No improper arguments to check)

        # Destroy any existing canvas objects
        foreach my $canvasObj ($self->gaugeCanvasList) {

            $canvasObj->destroy;
        }

        $self->ivEmpty('gaugeCanvasList');

        # If there are no gauges to be drawn, end here
        if (! @drawList) {

            return undef;
        }

        # Get the current width of the gauge box
        $rect = $self->canvas->allocation();
        $self->canvas->set_scroll_region(
            0,
            0,
            $rect->width,
            $rect->height,
        );

        ($boxWidth) = $self->canvas->get_size();

        # Don't try to draw gauges in a very small space
        if ($boxWidth < 100) {

            return 1;
        }

        # Sort the gauges first by level, and then by the order they were created, so they are
        #   always drawn in the same order, top to bottom and then left to right
        @drawList = sort {

            if ($a->level != $b->level) {
                $a->level <=> $b->level
            } else {
                $a->number <=> $b->number
            }

        } (@drawList);

        # Count the number of gauges for each level...
        foreach my $gaugeObj (@drawList) {

            if (! exists ($levelHash{$gaugeObj->level})) {
                $levelHash{$gaugeObj->level} = 1;
            } else {
                $levelHash{$gaugeObj->level} += 1;
            }
        }

        # ...and then work out the gauge width for each level. Every gauge on the same level should
        #   be the same width. We leave $self->gaugeSpacingX pixels clear on one end of the gauge
        #   box, and $self->gaugeSpacingX pixels clear at the opposite end of each gauge we draw, so
        #   they appear equally-spaced
        foreach my $level (keys %levelHash) {

            $widthHash{$level} = int(($boxWidth - $self->gaugeSpacingX) / ($levelHash{$level}));
        }

        # Draw each gauge in turn
        $root = $self->canvas->root();
        $visLevel = -1;

        foreach my $gaugeObj (@drawList) {

            my (
                $blankFlag, $ratio, $w, $corrW, $f, $e, $x1, $x2, $x3, $x4, $l, $y1, $y2, $obj,
                $lText, $lCol,
            );

            if (! exists $checkHash{$gaugeObj->level}) {

                # First gauge drawn on this level
                $count = 0;
                $checkHash{$gaugeObj->level} = undef;
                $visLevel++;

            } else {

                # Not the first
                $count++;
            }

            if (! $gaugeObj->textFlag) {

                # How full/empty is the gauge?
                if (
                    ! defined $gaugeObj->value
                    || ! $axmud::CLIENT->floatCheck($gaugeObj->value)
                    || ! defined $gaugeObj->maxValue
                    || ! $axmud::CLIENT->floatCheck($gaugeObj->maxValue)
                ) {
                    # If either value is not defined, or if the values aren't numerical (for some
                    #   reason), then draw the gauge a different colour
                    $blankFlag = TRUE;
                    $ratio = 0;

                } elsif ($gaugeObj->maxValue <= 0 && $gaugeObj->value > 0) {

                    # The value is bigger than the maximum value, for some reason. Draw the gauge as
                    #   full
                    $ratio = 1;

                } elsif ($gaugeObj->value <= 0 || $gaugeObj->maxValue <= 0) {

                    # Otherwise, if either value is 0, gauge should definitely be drawn empty (and
                    #   this also avoids division by zero in the next code block)
                    $ratio = 0;

                } else {

                    if (! $gaugeObj->addFlag) {
                        $ratio = $gaugeObj->value / $gaugeObj->maxValue;
                    } else {
                        $ratio = $gaugeObj->value / ($gaugeObj->value + $gaugeObj->maxValue);
                    }
                }

                # (Sanity check)
                if ($ratio > 1) {

                    $ratio = 1;
                }
            }

            # Total gauge width
            $w = $widthHash{$gaugeObj->level};
            # Edge correction - if this gauge is almost at the far right side of the gauge box, but
            #   not quite (because of rounding errors introduced by int() in the setting of $f),
            #   make it a bit larger, so as to fill the whole gauge box
            $corrW = $w;
            $x4 = $w * ($count + 1);
            if (
                $x4 < ($boxWidth - $self->gaugeSpacingX)
                && $x4 >= ($boxWidth - $self->gaugeSpacingX - $count)
            ) {
                $corrW += $boxWidth - $self->gaugeSpacingX - ($w * ($count + 1));
            }

            if (! $gaugeObj->textFlag) {

                # Full/empty widths
                $f = int(($corrW - $self->gaugeSpacingX) * $ratio);
                $e = $w - $f;

                # Full gauge portion
                $x1 = $self->gaugeSpacingX + ($count * $w);
                $x2 = $x1 + $f;
                # Empty gauge portion
                $x3 = $x2;                  # By moving $x3 1 pixel left, we avoid double black line
                $x4 = $x1 + $corrW - $self->gaugeSpacingX;

                # Special case: if the ratio is very close to 0 (but not enough to draw a pixel in
                #   the 'full' portion of the gauge), then draw at least one pixel
                # (Actually, we need $x2 to be at least 2 pixels bigger than $x1, otherwise only the
                #   border of the 'full' portion of the gauge is visible
                if ($ratio > 0 && ($x2 - $x1) <= 1) {

                    $x2 = $x3 = $x1 + 2;

                # Likewise, if the ratio is very close to 1 (but not enough to draw a pixel in the
                #   'empty' portion of the gauge), then draw at least one pixel
                } elsif ($ratio < 1 && ($x4 - $x3) <= 1) {

                    $x2 = $x3 = $x4 - 2;
                }

                # Vertical position depends only on the level, and is the same for both portions
                #   (NB the visible level isn't necessarily the same as the GA::Obj::GaugeLevel
                #   object's unique number)
                $y1 = $self->gaugeSpacingY
                        + ($visLevel * ($self->gaugeHeight + $self->gaugeSpacingY));
                $y2 = $y1 + $self->gaugeHeight - 1;

                if ($blankFlag) {

                    # Draw a blank gauge, because one or more values are unspecified (the labels are
                    #   still drawn, though)
                    $obj = Gnome2::Canvas::Item->new(
                        $root,
                        'Gnome2::Canvas::Rect',
                        x1 => $x1,
                        y1 => $y1,
                        x2 => $x4,
                        y2 => $y2,
                        fill_color => $self->gaugeBlankColour,
                        outline_color => $self->gaugeBorderColour,
                    );

                    $obj->raise_to_top();
                    push (@canvasObjList, $obj);

                } else {

                    # Full gauge portion
                    $obj = Gnome2::Canvas::Item->new(
                        $root,
                        'Gnome2::Canvas::Rect',
                        x1 => $x1,
                        y1 => $y1,
                        x2 => $x2,
                        y2 => $y2,
                        fill_color => $gaugeObj->fullColour,
                        outline_color => $self->gaugeBorderColour,
                    );

                    $obj->raise_to_top();
                    push (@canvasObjList, $obj);

                    # Empty gauge portion
                    $obj = Gnome2::Canvas::Item->new(
                        $root,
                        'Gnome2::Canvas::Rect',
                        x1 => $x3,
                        y1 => $y1,
                        x2 => $x4,
                        y2 => $y2,
                        fill_color => $gaugeObj->emptyColour,
                        outline_color => $self->gaugeBorderColour,
                    );

                    $obj->raise_to_top();
                    push (@canvasObjList, $obj);
                }

                # Draw a label over the gauge, if one is specified
                if ($gaugeObj->label) {

                    if (! $gaugeObj->labelFlag) {

                        $lText = $gaugeObj->label;

                    } else {

                        $lText = $gaugeObj->label . ': ';
                        if (! defined $gaugeObj->value) {
                            $lText .= '?';
                        } else {
                            $lText .= $gaugeObj->value;
                        }

                        if ($gaugeObj->addFlag) {
                            $lText .= '-';
                        } else {
                            $lText .= '/';
                        }

                        if (! defined $gaugeObj->maxValue) {
                            $lText .= '?';
                        } else {
                            $lText .= $gaugeObj->maxValue;
                        }
                    }

                    if ($blankFlag) {
                        $lCol = $self->gaugeLabelColour;
                    } else {
                        $lCol = $gaugeObj->labelColour;
                    }

                    $obj = Gnome2::Canvas::Item->new(
                        $root,
                        'Gnome2::Canvas::Text',
                        x => $x1 + $self->gaugeSpacingX,
                        y => $y1,
                        fill_color => $lCol,
                        font => $self->gaugeLabelFont,
                        size_points => $self->gaugeLabelFontSize,
                        anchor => 'GTK_ANCHOR_NW',
                        text => $lText,
                    );

                    $obj->raise_to_top();
                    push (@canvasObjList, $obj);
                }

            } else {

                # Text gauges use the full available width
                $x1 = $self->gaugeSpacingX + ($count * $w);
                $y1 = $self->gaugeSpacingY
                        + ($visLevel * ($self->gaugeHeight + $self->gaugeSpacingY));

                $lText = '';
                if ($gaugeObj->label) {

                    $lText .= $gaugeObj->label . ': ';
                }

                if (! defined $gaugeObj->value) {
                    $lText .= '?';
                } else {
                    $lText .= $gaugeObj->value;
                }

                # (Don't show a maximum value if the world isn't supplying one)
                if (defined $gaugeObj->maxValue) {

                    if ($gaugeObj->addFlag) {
                        $lText .= '-';
                    } else {
                        $lText .= '/';
                    }

                    $lText .= $gaugeObj->maxValue;
                }

                $obj = Gnome2::Canvas::Item->new(
                    $root,
                    'Gnome2::Canvas::Text',
                    x => $x1,
                    y => $y1,
                    font => $self->gaugeLabelFont,
                    size_points => $self->gaugeLabelFontSize,
                    anchor => 'GTK_ANCHOR_NW',
                    text => $lText,
                );

                $obj->raise_to_top();
                push (@canvasObjList, $obj);
            }
        }

        # Store the canvas objects drawn, so they can be destroyed on the next call to this
        #   function
        $self->ivPoke('gaugeDrawnList', @drawList);
        $self->ivPoke('gaugeCanvasList', @canvasObjList);

        return 1;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub frame
        { $_[0]->{frame} }
    sub canvas
        { $_[0]->{canvas} }
    sub gaugeCanvasList
        { my $self = shift; return @{$self->{gaugeCanvasList}}; }

    sub gaugeHeight
        { $_[0]->{gaugeHeight} }
    sub gaugeSpacingX
        { $_[0]->{gaugeSpacingX} }
    sub gaugeSpacingY
        { $_[0]->{gaugeSpacingY} }
    sub gaugeLabelFont
        { $_[0]->{gaugeLabelFont} }
    sub gaugeLabelFontSize
        { $_[0]->{gaugeLabelFontSize} }
    sub gaugeLevelHash
        { my $self = shift; return %{$self->{gaugeLevelHash}}; }
    sub gaugeLevelCount
        { $_[0]->{gaugeLevelCount} }
    sub gaugeLevelMax
        { $_[0]->{gaugeLevelMax} }
    sub gaugeCount
        { $_[0]->{gaugeCount} }
    sub gaugeMax
        { $_[0]->{gaugeMax} }
    sub gaugeDrawnList
        { my $self = shift; return @{$self->{gaugeDrawnList}}; }
    sub gaugeUpdateFlag
        { $_[0]->{gaugeUpdateFlag} }
    sub gaugeBlankColour
        { $_[0]->{gaugeBlankColour} }
    sub gaugeEmptyColour
        { $_[0]->{gaugeEmptyColour} }
    sub gaugeFullColour
        { $_[0]->{gaugeFullColour} }
    sub gaugeLabelColour
        { $_[0]->{gaugeLabelColour} }
    sub gaugeBorderColour
        { $_[0]->{gaugeBorderColour} }
    sub gaugeCheckTime
        { $_[0]->{gaugeCheckTime} }
    sub gaugeWaitTime
        { $_[0]->{gaugeWaitTime} }
    sub gaugeNoDrawFlag
        { $_[0]->{gaugeNoDrawFlag} }
}

{ package Games::Axmud::Strip::Entry;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Strip Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Win::Internal->drawWidgets or ->addStripObj
        # Creates the GA::Strip::Entry - a non-compulsory strip object containing a Gtk2::Entry
        #
        # Expected arguments
        #   $number     - The strip object's number within the parent window (matches
        #                   GA::Win::Internal->stripCount, or -1 for a temporary strip object
        #                   created to access its default IVs)
        #   $winObj     - The parent window object (GA::Win::Internal). 'temp' for temporary strip
        #                   objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the strip object's
        #                   initialisation settings. The strip object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - This type of strip object recognises these initialisation settings:
        #
        #                   'func' - Reference to a function to call when the user types something
        #                       in the entry box and presses 'return'. If not specified or 'undef',
        #                       it's up to the calling code to create its own ->signal_connect.
        #                       Ignored in 'main' windows, for which a ->signal_connect is always
        #                       created by this strip object. To obtain a reference to an OOP
        #                       method, you can use the generic object function
        #                       Games::Axmud->getMethodRef()
        #                   'id' - A value passed to the function which identifies the button. If
        #                       specified, can be any value except 'undef'. It's up to the
        #                       calling code to keep track of the widgets it has created and their
        #                       corresponding 'id' values
        #                   'wipe_flag' - TRUE if a 'wipe entry' button should be drawn to the left
        #                       of the entry box, FALSE if not (default is FALSE)
        #                   'console_flag' - TRUE if a 'toggle console' button should be drawn to
        #                       the right of the entry box, FALSE if not (default is FALSE)
        #                   'input_flag' - TRUE if a 'toggle expand' button (for opening the quick
        #                       input window) should be drawn to the right of the entry box, FALSE
        #                       if not (default is FALSE)
        #                   'cancel_flag' - TRUE if a 'cancel repeating/excess commands' button
        #                       should be drawn to the right of the entry box, FALSE if not (default
        #                       is FALSE)
        #                   'switch_flag' - TRUE if a 'switch active pane' button should be drawn to
        #                       the right of the entry box, FALSE if not (default is FALSE)
        #                   'scroll_flag' - TRUE if a 'scroll lock' button should be drawn to the
        #                       right of the entry box, FALSE if not (default is FALSE)
        #                   'split_flag' - TRUE if a 'split screen' button should be drawn to the
        #                       right of the entry box, FALSE if not (default is FALSE)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $winObj, %initHash) = @_;

        # Local variables
        my %modHash;

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $winObj) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Default initialisation settings
        %modHash = (
            'func'                      => undef,
            'id'                        => '',
            'wipe_flag'                 => FALSE,
            'console_flag'              => FALSE,
            'input_flag'                => FALSE,
            'cancel_flag'               => FALSE,
            'switch_flag'               => FALSE,
            'scroll_flag'               => FALSE,
            'split_flag'                => FALSE,
        );

        # Interpret the initialisation settings in %initHash, if any
        foreach my $key (keys %modHash) {

            if ($key eq 'id' && ! defined $initHash{$key}) {

                $modHash{$key} = '';        # 'id' value must not be 'undef'

            } elsif ($key eq 'func' || $key eq 'id') {

                $modHash{$key} = $initHash{$key};

            } elsif (exists $initHash{$key}) {

                if ($initHash{$key}) {
                    $modHash{$key} = TRUE;
                } else {
                    $modHash{$key} = FALSE;
                }
            }
        }

        # Setup
        my $self = {
            _objName                    => 'strip_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard strip object IVs
            # -------------------------

            # The strip object's number within the parent window (matches
            #   GA::Win::Internal->stripCount, or -1 for a temporary strip object created to
            #   access its default IVs)
            number                      => $number,
            # The type of strip object (custom strip objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in strip objects)
            type                        => 'entry',
            # The parent window object (GA::Win::Internal). 'temp' for temporary strip objects
            winObj                      => $winObj,

            # Flag set to TRUE if the strip object is visible (has actually drawn widgets in the
            #   window), set to FALSE if it is not visible (has drawn no widgets in the window, but
            #   still exists in GA::Win::Internal->stripHash, etc)
            # The flag might be set to FALSE in strip objects like GA::Strip::GaugeBox, which might
            #   have gauges to draw, or not, depending on current conditions. (Most strip objects
            #   have this flag set to TRUE all the time)
            # If FALSE, GA::Win::Internal->drawWidgets and ->addStripObj don't draw any widgets when
            #   called by this object's functions
            # NB Strip objects are created with this flag set to TRUE or FALSE, but once created,
            #   the flag's value shouldn't be modified by anything other than
            #   GA::Win::Internal->hideStripObj and ->revealStripObj (which in turn call
            #   $self->set_visibleFlag)
            visibleFlag                 => TRUE,
            # Flag set to TRUE is the strip object should be given its share of any extra space
            #   within the packing box (the extra space is divided equally between all children of
            #   the box whose ->expandFlag is TRUE)
            expandFlag                  => FALSE,
            # Flag set to TRUE if any space given to the strip object by the 'expand' option is
            #   actually allocated within the strip object, FALSE if it is used as padding outside
            #   it (on both sides)
            fillFlag                    => FALSE,
            # Flag set to TRUE if the strip object should be packed into its window with a small
            #   gap between strip objects to either side; FALSE if not (can be set to FALSE if the
            #   the strip object's widgets are drawn in a way, such that a gap is not necessary,
            #   for example in the toolbar strip object)
            spacingFlag                 => TRUE,
            # Flag set to TRUE if only one instance of this strip object should be added to the
            #   parent window, set to FALSE if any number of instances can be added
            jealousyFlag                => TRUE,
            # Flag set to TRUE if this strip object can be added when $axmud::BLIND_MODE_FLAG is
            #   TRUE, FALSE if it can't be added (because it's not useful for visually-impaired
            #   users)
            blindFlag                   => TRUE,
            # Flag set to TRUE if the main container widget, stored in $self->packingBox, should be
            #   allowed to accept the focus, FALSE if not. The restriction is applied during the
            #   call to GA::Win::Internal->drawWidgets and ->addStripObj. Even if FALSE, widgets in
            #   the container widget can be set to accept the focus (e.g. the Gtk2::Entry in
            #   GA::Strip::MenuBar)
            allowFocusFlag              => FALSE,

            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of strip object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this strip object and
            #   its widget(s). Can be any value, including 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => undef,

            # The container widget for this strip object (usually a Gtk2::HBox or Gtk2::VBox). This
            #   widget is the one added to the window's main Gtk2::HBox or Gtk2::VBox
            packingBox                  => undef,       # Gtk2::HBox

            # Other IVs
            # ---------

            # Widgets
            entry                       => undef,       # Gtk2::Entry
            wipeButton                  => undef,       # Gtk2::ToolButton
            consoleButton               => undef,       # Gtk2::ToolButton
            inputButton                 => undef,       # Gtk2::ToolButton
            cancelButton                => undef,       # Gtk2::ToolButton
            switchButton                => undef,       # Gtk2::ToolButton
            scrollButton                => undef,       # Gtk2::ToolButton
            splitButton                 => undef,       # Gtk2::ToolButton

            # List of currently-existing pane objects. New pane objects are added to the end of the
            #   list. The first pane object in the list is the one to which the scroll and split
            #   buttons apply. Clicking the switch buttons moves the first pane in the list to the
            #   end, so that the next pane object becomes the one to which the scroll and split
            #   buttons apply
            # Keypresses captured by GA::Win::Internal are also applied to the first pane object
            #   in the list
            paneObjList                 => [],

            # For 'main' windows, when GA::Client->autoCompleteMode = 'auto', the first time the
            #   user presses the 'up' or 'down' arrow key, this IV is set to the contents of the
            #   entry box (even if it's an empty string). The IV is set back to 'undef' as soon as
            #   the user presses the ENTER key
            originalEntryText           => undef,
            # Any code can temporarily desensitise the entry box, when required, by calling
            #   $self->captureEntry, which adds an entry to this hash IV
            # The entry box remains potentially desensitised until the next call to
            #   $self->captureEntry removes the entry in the hash IV
            # 'Potentially desensitised' means that the entry box is desensitised when any of the
            #   sessions in this hash IV are the parent window's visible session, but is
            #   sensitised when some other session is the parent window's visible session
            # Hash in the form
            #   $captureHash{session_number} = undef
            captureHash                 => {},
            # The current state of the console button, representing the icon to use when the button
            #   isn't flashing. Set to 'empty', 'system', 'debug' or 'error' (or 'undef' if the
            #   button isn't visible)
            consoleIconType             => undef,
            # The temporary state of the console button, representing the icon to use when the
            #   button is flashing. Set to 'system', 'debug' or 'error' (or 'undef' if the button
            #   isn't visible)
            consoleIconTempType         => undef,
            # When a system message is waiting to be displayed in a Session Console window, the
            #   button may be made to flash by periodic calls to $self->set_consoleIconFlash. When
            #   not flashing, this value is set to TRUE; when flashing, it is alternately set to
            #   FALSE and TRUE
            consoleIconFlashFlag        => TRUE,

            # Special echo mode. This flag is set by a call to $self->set_specialEchoFlag
            # When TRUE, characters are sent to the world, one at a time, as soon as they're typed
            # When false, instructions aren't executed until the user presses their RETURN key
            specialEchoFlag             => FALSE,
            # When special echo mode is enabled and the entry box contains a non-world command (for
            #   example, a client command), this is flag is set to TRUE (so that the escape, tab,
            #   backspace and delete keys are applied to the contents of the entry, not sent to the
            #   world directly)
            specialPreserveFlag         => FALSE,
            # When special echo mode is enabled and ->specialPreserveFlag is TRUE, meaning that a
            #   world command is being typed in the entry box (one letter at a time), the world
            #   command is stored here, so it can be passed to the GA::Session
            # At all other times, this IV is set to an empty string
            specialWorldCmd             => '',
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard strip object functions

    sub objEnable {

        # Called by GA::Win::Internal->drawWidgets or ->addStripObj
        # Sets up the strip object's widgets
        #
        # Expected arguments
        #   $winmapObj  - The winmap object (GA::Obj::Winmap) that specifies the layout of the
        #                   parent window
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $winmapObj, $check) = @_;

        # Check for improper arguments
        if (! defined $winmapObj || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Create a packing box
        my $hBox = Gtk2::HBox->new(FALSE, 0);
        $hBox->set_border_width(0);

        # Draw a Gtk2::Entry box (compulsory) and any buttons specified by $self->initHash
        #   (->signal_connects for each appear later in the function)

        # Draw a 'wipe entry' icon as a toolbutton (optional)
        my $wipeButton;
        if ($self->ivShow('initHash', 'wipe_flag') && ! $axmud::BLIND_MODE_FLAG) {

            $wipeButton = Gtk2::ToolButton->new(
                Gtk2::Image->new_from_file($axmud::SHARE_DIR . $axmud::CLIENT->constWipeIconPath),
                'Clear command entry box',
            );
            $hBox->pack_start($wipeButton, FALSE, FALSE, 0);
            $wipeButton->set_tooltip_text('Clear command entry box');
        }

        # Draw a Gtk2::Entry box
        my $entry = Gtk2::Entry->new();

        # ('spare' 'main' windows look nicer if there's no padding around the entry box)
        if ($winmapObj->name eq 'main_wait') {
            $hBox->pack_start($entry, TRUE, TRUE, 0);
        } else {
            $hBox->pack_start($entry, TRUE, TRUE, 5);
        }

        # The entry is the only 'internal' window widget which can accept focus
        $entry->can_focus(TRUE);
        # For 'main' windows, the entry starts desensitised. Afterwards, it is sensitised or
        #   desensitised (as appropriate) by $self->setWidgetsIfSession. For other kinds of
        #   'internal' window, the entry starts sensitised
        # Any other parts of the code which need to desensitise the entry temporarily should call
        #   $self->captureEntry
        if ($self->winObj->winType eq 'main') {

            $entry->set_sensitive(FALSE);
        }

        # Draw a 'toggle console' icon as a toolbutton (optional)
        my $consoleButton;
        if ($self->ivShow('initHash', 'console_flag') && ! $axmud::BLIND_MODE_FLAG) {

            $consoleButton = Gtk2::ToolButton->new(
                Gtk2::Image->new_from_file(
                    $axmud::SHARE_DIR . $axmud::CLIENT->constEmptyIconPath,
                ),
                'Open Session Console window',
            );
            $hBox->pack_start($consoleButton, FALSE, FALSE, 0);
            $consoleButton->set_tooltip_text('Open Session Console window');
            $consoleButton->set_sensitive(FALSE);

            $self->ivPoke('consoleIconType', 'empty');
            $self->ivPoke('consoleIconTempType', 'empty');
        }

        # Draw a 'toggle expand' icon as a toolbutton (optional)
        my $inputButton;
        if ($self->ivShow('initHash', 'input_flag') && ! $axmud::BLIND_MODE_FLAG) {

            $inputButton = Gtk2::ToolButton->new(
                Gtk2::Image->new_from_file($axmud::SHARE_DIR . $axmud::CLIENT->constMultiIconPath),
                'Open Quick Input window',
            );
            $hBox->pack_start($inputButton, FALSE, FALSE, 0);
            $inputButton->set_tooltip_text('Open Quick Input window');
            $inputButton->set_sensitive(FALSE);
        }

        # Draw a 'cancel repeating/excess commands' icon as a toolbutton (optional)
        my $cancelButton;
        if ($self->ivShow('initHash', 'cancel_flag') && ! $axmud::BLIND_MODE_FLAG) {

            $cancelButton = Gtk2::ToolButton->new(
                Gtk2::Image->new_from_file($axmud::SHARE_DIR . $axmud::CLIENT->constCancelIconPath),
                'Cancel repeating/excess commands',
            );
            $hBox->pack_start($cancelButton, FALSE, FALSE, 0);
            $cancelButton->set_tooltip_text('Cancel repeating/excess commands');
            $cancelButton->set_sensitive(FALSE);
        }

        # Draw a 'switch active pane' icon as a toolbutton (optional)
        my $switchButton;
        if ($self->ivShow('initHash', 'switch_flag') && ! $axmud::BLIND_MODE_FLAG) {

            $switchButton = Gtk2::ToolButton->new(
                Gtk2::Image->new_from_file($axmud::SHARE_DIR . $axmud::CLIENT->constSwitchIconPath),
                'Switch active pane',
            );
            $hBox->pack_start($switchButton, FALSE, FALSE, 0);
            $switchButton->set_tooltip_text('Switch active pane');
            $switchButton->set_sensitive(FALSE);
        }

        # Draw a 'scroll lock' icon as a toolbutton (optional)
        my $scrollButton;
        if ($self->ivShow('initHash', 'scroll_flag') && ! $axmud::BLIND_MODE_FLAG) {

            $scrollButton = Gtk2::ToolButton->new(
                Gtk2::Image->new_from_file($axmud::SHARE_DIR . $axmud::CLIENT->constLockIconPath),
                'Apply/release scroll lock',
            );
            $hBox->pack_start($scrollButton, FALSE, FALSE, 0);
            $scrollButton->set_tooltip_text('Apply/release scroll lock');
            $scrollButton->set_sensitive(FALSE);
        }

        # Draw a 'split screen' icon as a toolbutton, and place it in the HBox (optional)
        my $splitButton;
        if ($self->ivShow('initHash', 'split_flag') && ! $axmud::BLIND_MODE_FLAG) {

            $splitButton = Gtk2::ToolButton->new(
                Gtk2::Image->new_from_file(
                    $axmud::SHARE_DIR . $axmud::CLIENT->constRestoreIconPath,
                ),
                'Split/restore screen',
            );
            $hBox->pack_start($splitButton, FALSE, FALSE, 0);
            $splitButton->set_tooltip_text('Split/restore screen');
            $splitButton->set_sensitive(FALSE);
        }

        # Update IVs
        $self->ivPoke('funcRef', $self->ivShow('initHash', 'func'));
        $self->ivPoke('funcID', $self->ivShow('initHash', 'id'));
        $self->ivPoke('packingBox', $hBox);
        $self->ivPoke('entry', $entry);
        $self->ivPoke('wipeButton', $wipeButton);
        $self->ivPoke('consoleButton', $consoleButton);
        $self->ivPoke('inputButton', $inputButton);
        $self->ivPoke('cancelButton', $cancelButton);
        $self->ivPoke('switchButton', $switchButton);
        $self->ivPoke('scrollButton', $scrollButton);
        $self->ivPoke('splitButton', $splitButton);

        # Get a list of pane objects that already exist, and update our list of pane objects in
        #   this window
        # (New panes are added to this list via a call to $self->notify_addTableObj, and old panes
        #   are removed from it via a call to $self->notify_removeTableObj)
        if ($self->winObj->tableStripObj) {

            foreach my $tableObj (
                sort {$a->number <=> $b->number}
                ($self->winObj->tableStripObj->ivValues('tableObjHash'))
            ) {
                if ($tableObj->type eq 'pane') {

                    $self->ivPush('paneObjList', $tableObj);
                }
            }
        }

        # Create ->signal_connects for each ($wipeButton manipulates $entry, and perhaps others will
        #   in the future too, so we'll wait until now to do ->signal_connects)
        $self->setEntrySignals();           # 'activate'
        $self->setWipeSignals();            # 'clicked'
        $self->setConsoleSignals();         # 'clicked'
        $self->setInputSignals();           # 'clicked'
        $self->setCancelSignals();          # 'clicked'
        $self->setSwitchSignals();          # 'clicked'
        $self->setScrollSignals();          # 'clicked'
        $self->setSplitSignals();           # 'clicked'

        return 1;
    }

    sub objDestroy {

        # Called by GA::Win::Internal->removeStripObj, just before the strip is removed from its
        #   parent window, and also by ->winDestroy and ->resetWinmap, to give this object a chance
        #   to do any necessary tidying up
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objDestroy', @_);
        }

        # (No tidying up required for this type of strip object)
        #   ...

        return 1;
    }

    sub setWidgetsIfSession {

        # Called by GA::Win::Internal->setWidgetsIfSession
        # Allows this strip object to sensitise or desensitise its widgets, depending on whether
        #   the parent window has a ->visibleSession at the moment
        # (NB Only 'main' windows have a ->visibleSession; for other 'grid' windows, the flag
        #   argument will be FALSE)
        #
        # Expected arguments
        #   $flag   - TRUE if the parent window has a visible session, FALSE if not
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->setWidgetsIfSession', @_);
        }

        # Sensitise/desensitise entry box
        if ($self->entry) {

            if ($flag) {

                if ($self->ivExists('captureHash', $self->winObj->visibleSession->number)) {

                    $self->entry->set_sensitive(FALSE);

                } else {

                    $self->entry->set_sensitive(TRUE);
                    $self->entry->grab_focus();
                }

            } else {

                $self->entry->set_sensitive(FALSE);
            }
        }

        # Sensitise/desensitise buttons
        if ($self->wipeButton) {

            $self->wipeButton->set_sensitive($flag);
        }

        if ($self->inputButton) {

            $self->inputButton->set_sensitive($flag);
        }

        if ($self->consoleButton) {

            $self->consoleButton->set_sensitive($flag);
        }

        if ($self->cancelButton) {

            $self->cancelButton->set_sensitive($flag);
        }

        if ($self->switchButton) {

            $self->switchButton->set_sensitive($flag);
        }

        if ($self->scrollButton) {

            $self->scrollButton->set_sensitive($flag);
            # Restore default icon, too
            $self->scrollButton->set_icon_widget(
                Gtk2::Image->new_from_file($axmud::SHARE_DIR . $axmud::CLIENT->constLockIconPath),
            );
        }

        if ($self->splitButton) {

            $self->splitButton->set_sensitive($flag);
            # Restore default icon, too
            $self->splitButton->set_icon_widget(
                Gtk2::Image->new_from_file(
                    $axmud::SHARE_DIR . $axmud::CLIENT->constRestoreIconPath,
                ),
            );
        }

        return 1;
    }

    sub setWidgetsChangeSession {

        # Called by GA::Win::Internal->setWidgetsChangeSession
        # Allows this strip object to update its widgets whenever the visible session in any 'main'
        #   window changes
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($textViewObj, $iv);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->setWidgetsChangeSession',
                @_,
            );
        }

        # Update button icons to match the visible session
        if ($self->winObj->visibleSession) {

            # (->defaultTabObj won't be set yet, if GA::Session->start is still executing)
            if ($self->winObj->visibleSession->defaultTabObj) {

                $textViewObj = $self->winObj->visibleSession->defaultTabObj->textViewObj;
            }

            if ($self->consoleButton) {

                # e.g. constEmptyIconPath
                $iv = 'const' . ucfirst($self->winObj->visibleSession->systemMsgMode) . 'IconPath';

                $self->consoleButton->set_icon_widget(
                    Gtk2::Image->new_from_file($axmud::SHARE_DIR . $axmud::CLIENT->$iv),
                );

                $self->ivPoke('consoleIconType', $self->winObj->visibleSession->systemMsgMode);
                $self->ivPoke('consoleIconFlashFlag', TRUE);
            }

            if ($self->scrollButton) {

                if (! $textViewObj || $textViewObj->scrollLockFlag) {

                    $self->scrollButton->set_icon_widget(
                        Gtk2::Image->new_from_file(
                            $axmud::SHARE_DIR . $axmud::CLIENT->constLockIconPath
                        ),
                    );

                } else {

                    $self->scrollButton->set_icon_widget(
                        Gtk2::Image->new_from_file(
                            $axmud::SHARE_DIR . $axmud::CLIENT->constScrollIconPath
                        ),
                    );
                }
            }

            if ($self->splitButton) {

                if (! $textViewObj || $textViewObj->splitScreenMode eq 'split') {

                    $self->splitButton->set_icon_widget(
                        Gtk2::Image->new_from_file(
                            $axmud::SHARE_DIR . $axmud::CLIENT->constRestoreIconPath,
                        ),
                    );

                } else {

                    $self->splitButton->set_icon_widget(
                        Gtk2::Image->new_from_file(
                            $axmud::SHARE_DIR . $axmud::CLIENT->constSplitIconPath,
                        ),
                    );
                }
            }
        }

        if ($self->entry) {

            if (! $axmud::CLIENT->sessionHash) {

                # If there are no sessions at all, the entry box must be empty
                $self->entry->set_text('');

            } else {

                # If the current current session's server has suggested that the client stop
                #   ECHOing, and the client has agreed, text in the entry box must be obscured
                # If not, or if special echo mode is on, it must be un-obscured (in case it was
                #   obscured by the previous session)
                # In either case, text in the entry box is removed when switching sessions
                if (
                    $self->winObj->visibleSession->echoMode eq 'client_agree'
                    && ! $self->specialEchoFlag
                ) {
                    $self->obscureEntry(TRUE);
                } else {
                    $self->obscureEntry(FALSE);
                }

                # Set (or reset) icons showing recordings in progress
                if ($self->winObj->visibleSession->recordingPausedFlag) {
                    $self->entry->set_icon_from_stock('secondary', 'gtk-media-pause');
                } elsif ($self->winObj->visibleSession->recordingFlag) {
                    $self->entry->set_icon_from_stock('secondary', 'gtk-media-record');
                } else {
                    $self->entry->set_icon_from_stock('secondary', undef);
                }
            }
        }

        return 1;
    }

    # ->signal_connects

    sub setEntrySignals {

        # Called by $self->objEnable
        # Set up a ->signal_connect to watch out for the user input in the entry box
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my %shortHash;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setEntrySignals', @_);
        }

        # Deal with user pressing their ENTER key
        $self->entry->signal_connect('activate' => sub {

            my ($instruct, $thisFuncRef, $successFlag, $type);

            $instruct = $self->entry->get_text();
            $thisFuncRef = $self->funcRef;

            # The entry box's behaviour depends on whether the parent window is a 'main' window, or
            #   not
            if ($self->winObj->winType eq 'main') {

                if (
                    $self->specialEchoFlag
                    && ! $self->specialPreserveFlag
                    && $self->specialWorldCmd
                    && $self->winObj->visibleSession
                ) {
                    # Pass the stored world command to the visible session, calling ->dispatchCmd
                    #   directly, since it already checks for special echo mode
                    $self->winObj->visibleSession->dispatchCmd($self->specialWorldCmd);
                    # Also update the instruction buffer, since we bypassed GA::Session->doInstruct
                    $self->winObj->visibleSession->updateInstructBuffer(
                        $self->specialWorldCmd,
                        'world',
                    );

                } elsif ($self->winObj->visibleSession) {

                    # Pass the typed instruction to the visible session
                    ($successFlag, $type) = $self->winObj->visibleSession->doInstruct($instruct);

                    if (
                        defined $type
                        && $self->winObj->visibleSession->echoMode ne 'client_agree'
                        && (
                            (
                                $axmud::CLIENT->preserveWorldCmdFlag
                                && (
                                    $type eq 'world' || $type eq 'multi' || $type eq 'speed'
                                    || $type eq 'bypass'
                                )
                            ) || (
                                $axmud::CLIENT->preserveOtherCmdFlag
                                && (
                                    $type ne 'world' && $type ne 'multi' && $type ne 'speed'
                                    && $type ne 'bypass'
                                )
                            )
                        )
                    ) {
                        # Preserve the typed command and select all of the text
                        $self->entry->grab_focus();

                    } else {

                        # Empty the entry box
                        $self->entry->set_text('');
                    }

                    # Reset the text stored for the benefit of GA::Session->autoCompleteBuffer
                    $self->ivUndef('originalEntryText');

                } else {

                    $self->entry->set_text('');

                    # Reset the text stored for the benefit of GA::Session->autoCompleteBuffer
                    $self->ivUndef('originalEntryText');
                }

            # For other 'internal' windows, redirect the entry box's contents to the specified
            #   function (if any)
            } elsif ($thisFuncRef) {

                &$thisFuncRef($self, $self->entry, $self->funcID, $instruct);

                $self->entry->set_text('');
            }

            # Update IVs
            $self->entry->set_icon_from_stock('primary', undef);
            $self->ivPoke('specialPreserveFlag', FALSE);
            $self->ivPoke('specialWorldCmd', '');

            return 1;
        });

        # Deal with user entering or removing any character(s) from the entry box, during special
        #   echo mode
        # In special echo mode, world commands are sent to the world immediately, one character at a
        #   time; but non-world commands (such as client commands) behave as normal. Forced client
        #   commands also behave as normal
        # To implement this we need to work out when the user is typing an instruction that begins
        #   with a recognised instruction sigil, and when they're not

        # Most instruction sigils are one character long, but GA::Client->constForcedSigil is two.
        #   In any case, some user might edit GA::Client->new to alter the literal values
        # Save a bit of time by compiling a hash of strings that start a multi-character sigil
        #   (for example, for the forced world command sigil ',,' add an entry for ',')
        # We assume that the user has followed the instructions in GA::Client->new, and has made
        #   sure each sigil starts with a different character
        foreach my $type (qw(client forced echo perl script multi speed bypass)) {

            my $iv = 'const' . ucfirst($type) . 'Sigil';        # e.g. 'constClientSigil'

            if (length ($axmud::CLIENT->$iv) > 1) {

                for (my $num = 1; $num <= length($axmud::CLIENT->$iv); $num++) {

                    $shortHash{substr($axmud::CLIENT->$iv, 0, $num)} = undef;
                }
            }
        }

        $self->entry->signal_connect('changed' => sub {

            my $instruct = $self->entry->get_text();

            if (! $self->specialEchoFlag || $instruct eq '') {

                # Special echo mode is off or the command entry box is empty, so do nothing with
                #   ordinary keypresses
                return undef;

            } else {

                # Special echo mode is on. Trim initial whitespace, so we can work out whether
                #   $instruct starts with an instruction sigil, or not; but if $instruct actually
                #   contains just space character(s), don't trim it
                $instruct =~ s/^\s*(\S.*)/$1/;

                # Is the whole of instruct a partial multi-character sigil (for example, a single
                #   comma from the forced world command sigil ',,') ?
                foreach my $short (keys %shortHash) {

                    if ($instruct eq $short) {

                        # Decide what to do once the the user has typed another character
                        # Meanwhile, set the entry icon for non-world commands
                        $self->entry->set_icon_from_stock('primary', 'gtk-disconnect');
                        # Don't let GA::Win::Internal->setKeyPressEvent intercept the escape, tab,
                        #   backspace and delete keys, which should instead apply to our entry box
                        $self->ivPoke('specialPreserveFlag', TRUE);
                        $self->ivPoke('specialWorldCmd', '');

                        return undef;
                    }
                }

                # Now check that $instruct begins with an instruction sigil that's currently
                #   enabled
                foreach my $type (qw(client forced echo perl script multi speed bypass)) {

                    my ($constIV, $flagIV);

                    $constIV = 'const' . ucfirst($type) . 'Sigil';      # e.g. 'constClientSigil'
                    $flagIV = $type . 'SigilFlag';                      # e.g. 'echoSigilFlag'

                    if (
                        index($instruct, $axmud::CLIENT->$constIV) == 0
                        && (
                            # The IVs ->clientSigilFlag and ->forcedSigilFlag don't exist
                            $type eq 'client'
                            || $type eq 'forced'
                            || $axmud::CLIENT->$flagIV
                        )
                    ) {
                        # $instruct begins with an instruction sigil that's enabled. Set the entry
                        #   icon for non-world commands
                        $self->entry->set_icon_from_stock('primary', 'gtk-disconnect');
                        # Don't let GA::Win::Internal->setKeyPressEvent intercept the escape, tab,
                        #   backspace and delete keys, which should instead apply to our entry box
                        $self->ivPoke('specialPreserveFlag', TRUE);
                        $self->ivPoke('specialWorldCmd', '');

                        return undef;
                    }
                }

                # $instruct is part of a world command, so send it to the world immediately (the
                #   TRUE argument means to encode $instruct using the session's current character
                #   set)
                $self->winObj->visibleSession->put($instruct, TRUE);
                # Reset the entry box, and set the icon for world commands
                $self->entry->set_text('');
                $self->entry->set_icon_from_stock('primary', 'gtk-connect');
                # Update IVs
                $self->ivPoke('specialPreserveFlag', FALSE);
                $self->ivPoke('specialWorldCmd', $self->specialWorldCmd . $instruct);

                return undef;
            }
        });

        return 1;
    }

    sub setWipeSignals {

        # Called by $self->objEnable
        # Set up a ->signal_connect to watch out for the button being clicked
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setWipeSignals', @_);
        }

        if ($self->wipeButton) {

            $self->wipeButton->signal_connect('clicked' => sub {

                $self->entry->set_text('');

                # Update IVs. Clicking the button means that the user wants to start typing a new
                #   world command, without having pressed their RETURN key (for example, if they've
                #   just been navigating menus)
                $self->ivPoke('specialPreserveFlag', FALSE);
                $self->ivPoke('specialWorldCmd', '');
                # Remove the icon, too
                $self->entry->set_icon_from_stock('primary', undef);
            });
        }

        return 1;
    }

    sub setConsoleSignals {

        # Called by $self->objEnable
        # Set up a ->signal_connect to watch out for the button being clicked
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setInputSignals', @_);
        }

        if ($self->consoleButton) {

            $self->consoleButton->signal_connect('clicked' => sub {

                if ($self->winObj->visibleSession) {

                    if (! $self->winObj->visibleSession->consoleWin) {

                        # Open an Session Console window
                        $self->winObj->createFreeWin(
                            'Games::Axmud::OtherWin::SessionConsole',
                            $self->winObj,
                            $self->winObj->visibleSession,
                            undef,                              # Let the window set its own title
                        );

                    } else {

                        # Close the existing window
                        $self->winObj->visibleSession->consoleWin->winDestroy();
                    }
                }
            });
        }

        return 1;
    }

    sub setInputSignals {

        # Called by $self->objEnable
        # Set up a ->signal_connect to watch out for the button being clicked
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setInputSignals', @_);
        }

        if ($self->inputButton) {

            $self->inputButton->signal_connect('clicked' => sub {

                if ($self->winObj->visibleSession) {

                    $self->winObj->visibleSession->pseudoCmd('quickinput');
                }
            });
        }

        return 1;
    }

    sub setCancelSignals {

        # Called by $self->objEnable
        # Set up a ->signal_connect to watch out for the button being clicked
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setCancelSignals', @_);
        }

        if ($self->cancelButton) {

            $self->cancelButton->signal_connect('clicked' => sub {

                if (
                    $self->winObj->visibleSession
                    && (
                        $self->winObj->visibleSession->status eq 'connected'
                        || $self->winObj->visibleSession->status eq 'offline'
                    )
                ) {
                    $self->winObj->visibleSession->pseudoCmd('stopcommand');
                }
            });
        }

        return 1;
    }

    sub setSwitchSignals {

        # Called by $self->objEnable
        # Set up a ->signal_connect to watch out for the button being clicked
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setSwitchSignals', @_);
        }

        if ($self->switchButton) {

            $self->switchButton->signal_connect('clicked' => sub {

                # The first pane object in $self->paneObjList is the new 'active' pane object, to
                #   which the scroll and split buttons are applied
                if ($self->paneObjList) {

                    my $paneObj = $self->ivShift('paneObjList');
                    $self->ivPush('paneObjList', $paneObj);

                    # Briefly increase the size of the 'active' pane object's border width, so the
                    #   user can see which one it is
                    $axmud::CLIENT->paneModifyBorder($self->ivFirst('paneObjList'));
                }
            });
        }

        return 1;
    }

    sub setScrollSignals {

        # Called by $self->objEnable
        # Set up a ->signal_connect to watch out for the button being clicked
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setScrollSignals', @_);
        }

        if ($self->scrollButton) {

            $self->scrollButton->signal_connect('clicked' => sub {

                my $paneObj;

                # Get the active pane object and toggle the scroll lock for the visible tab
                if ($self->paneObjList) {

                    $paneObj = $self->ivFirst('paneObjList');
                    $paneObj->toggleScrollLock();
                }
            });
        }

        return 1;
    }

    sub setSplitSignals {

        # Called by $self->objEnable
        # Set up a ->signal_connect to watch out for the button being clicked
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setSplitSignals', @_);
        }

        if ($self->splitButton) {

            $self->splitButton->signal_connect('clicked' => sub {

                my $paneObj;

                # Get the active pane object and toggle the split screen for the visible tab
                if ($self->paneObjList) {

                    $paneObj = $self->ivFirst('paneObjList');
                    $paneObj->toggleSplitScreen();
                }
            });
        }

        return 1;
    }

    # Other functions

    sub captureEntry {

        # Can be called by any code which wants to make temporarily set the Gtk2::Entry as
        #   insensitive, and called again to restore its previous state (which might be
        #   sensitive, or not)
        #
        # Expected arguments
        #   $session    - The calling GA::Session
        #   $flag       - Set to TRUE to desensitise the entry, FALSE to restore it to its previous
        #                   state (which might be insensitive) by calling $self->setWidgetsIfSession
        #
        # Return values
        #   'undef' on improper arguments or if the entry is already captured (or not captured) by
        #       the calling session
        #   1 otherwise

        my ($self, $session, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $session || ! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->captureEntry', @_);
        }

        if (
            $flag eq TRUE && $self->ivExists('captureHash', $session->number)
            || $flag eq FALSE && ! $self->ivExists('captureHash', $session->number)
        ) {
            # No changes to make
            return undef;
        }

        if ($flag) {
            $self->ivAdd('captureHash', $session->number, undef);
        } else {
            $self->ivDelete('captureHash', $session->number);
        }

        $self->seWidgetsIfSession();

        return 1;
    }

    sub obscureEntry {

        # Called by GA::Session->updateEcho and ->setWidgetsChangeSession
        # Empties the entry box, and modifies the box so that any text typed into it is either
        #   obscured, or not (as required)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $flag   - Flag set to TRUE if the entry box should be obscured, FALSE (or 'undef') if it
        #               should be shown
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->obscureEntry', @_);
        }

        if ($self->entry) {

            $self->entry->set_text('');
            if ($flag) {
                $self->entry->set_visibility(FALSE);
            } else {
                $self->entry->set_visibility(TRUE);
            }

            $self->winObj->winShowAll($self->_objClass . '->obscureEntry');
        }

        return 1;
    }

    sub commandeerEntry {

        # Called by GA::Obj::TextView->setButtonPressEvent and ->createPopupMenu
        # When an MXP <SEND>..</SEND> construction (or any other code) wants to insert a command
        #   into the client's command line (instead of sending it to the world directly), this
        #   function is called
        # The command is copied into the entry box (but only if the calling session is this window's
        #   visible session, which it almost certainly is)
        #
        # Expected arguments
        #   $session        - The calling GA::Session
        #   $cmd            - The command to display in the entry box
        #
        # Return values
        #   'undef' on improper arguments, if $session is not this window's visible session or if
        #       the $cmd is not displayed
        #   1 if the $cmd is displayed

        my ($self, $session, $cmd, $check) = @_;

        # Check for improper arguments
        if (! defined $session || ! defined $cmd || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->commandeerEntry', @_);
        }

        if (! $self->winObj->visibleSession || $self->winObj->visibleSession ne $session) {

            # Do nothing
            return undef;

        } else {

            $self->entry->set_text($cmd);
            $self->entry->set_visibility(TRUE);
            $self->entry->grab_focus();

            $self->winObj->winShowAll($self->_objClass . '->commandeerEntry');

            return 1;
        }
    }

    sub applyBackspace {

        # Called by GA::Win::Internal->setKeyPressEvent when the user presses the backspace key in
        #   special echo mode
        # $self->specialWorldCmd stores a copy of the world command that's being sent to the world,
        #   one character at a time; amend the copy by removing its final character
        # (This doesn't guarantee that the world command stored in ->specialWorldCmd is exactly the
        #   same as the command the world thinks it's receiving, but it should be close enough)
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->applyBackspace', @_);
        }

        # The calling function has done most of the checking, so just update ->specialWorldCmd
        if ($self->specialWorldCmd ne '') {

            $self->ivPoke(
                'specialWorldCmd',
                substr($self->specialWorldCmd, 0, ((length ($self->specialWorldCmd)) - 1)),
            );
        }

        return 1;
    }

    sub updateScrollButton {

        # Called by GA::Table::Pane->toggleScrollLock and ->toggleSplitScreen, and by
        #   $self->setScrollSignals
        # Updates the icon shown on the 'scroll lock' button, which indicates whether the scroll
        #   lock is applied to the active textview, or not
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $flag   - TRUE if the scroll lock is applied on the active textview, FALSE if it is not.
        #               Set to 'undef' if the calling function doesn't know whether the scroll lock
        #               is applied in the active textview, or not
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $flag, $check) = @_;

        # Local variables
        my ($paneObj, $tabNum, $tabObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateScrollButton', @_);
        }

        if (! defined $flag) {

            # Is there an active textview, and is its scroll lock applied?
            if ($self->paneObjList) {

                $paneObj = $self->ivFirst('paneObjList');
                if ($paneObj) {

                    if (! $paneObj->notebook) {
                        $tabNum = 0;
                    } else {
                        $tabNum = $paneObj->notebook->get_current_page();
                    }

                    if (defined $tabNum) {

                        $tabObj = $paneObj->ivShow('tabObjHash', $tabNum);
                        $flag = $tabObj->textViewObj->scrollLockFlag;
                    }
                }
            }
        }

        # Do nothing if the button isn't visible...
        if ($self->scrollButton) {

            if (! $flag) {

                $self->scrollButton->set_icon_widget(
                    Gtk2::Image->new_from_file(
                        $axmud::SHARE_DIR . $axmud::CLIENT->constScrollIconPath
                    ),
                );

            } else {

                # (Default)
                $self->scrollButton->set_icon_widget(
                    Gtk2::Image->new_from_file(
                        $axmud::SHARE_DIR . $axmud::CLIENT->constLockIconPath
                    ),
                );
            }

            $self->winObj->winShowAll($self->_objClass . '->updateScrollButton');
        }

        return 1;
    }

    sub updateSplitButton {

        # Called by GA::Table::Pane->toggleSplitScreen
        # Updates the icon shown on the 'split screen' button, which indicates whether the split
        #   screen is applied to the active textview, or not
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $flag   - TRUE if the split screen is applied on the active textview, FALSE if it is
        #               not. Set to 'undef' if the calling function doesn't know whether the split
        #               screen lock is applied in the active textview, or not
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $flag, $check) = @_;

        # Local variables
        my ($paneObj, $tabNum, $tabObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateSplitButton', @_);
        }

        if (! defined $flag) {

            # Is there an active textview, and is its split screen applied?
            if ($self->paneObjList) {

                $paneObj = $self->ivFirst('paneObjList');
                if ($paneObj) {

                    if (! $paneObj->notebook) {
                        $tabNum = 0;
                    } else {
                        $tabNum = $paneObj->notebook->get_current_page();
                    }

                    if (defined $tabNum) {

                        $tabObj = $paneObj->ivShow('tabObjHash', $tabNum);
                        if ($tabObj->textViewObj->splitScreenMode eq 'split') {
                            $flag = TRUE;
                        } else {
                            $flag = FALSE;
                        }
                    }
                }
            }
        }

        # Do nothing if the button isn't visible...
        if ($self->splitButton) {

            if (! $flag) {

                $self->splitButton->set_icon_widget(
                    Gtk2::Image->new_from_file(
                        $axmud::SHARE_DIR . $axmud::CLIENT->constRestoreIconPath
                    ),
                );

            } else {

                # (Default)
                $self->splitButton->set_icon_widget(
                    Gtk2::Image->new_from_file(
                        $axmud::SHARE_DIR . $axmud::CLIENT->constSplitIconPath
                    ),
                );
            }

            $self->winObj->winShowAll($self->_objClass . '->updateSplitButton');
        }

        return 1;
    }

    sub updateConsoleButton {

        # Called by GA::Session->add_systemMsg and ->reset_systemMsg
        # The argument corresponds to the icon to draw on the console button
        #
        # Expected arguments
        #   $type       - One of the strings 'empty', 'system', 'debug' or 'error', corresponding to
        #                   one of the icons in ../share/icons/button that's used to draw the
        #                   button when it's not flashing
        #
        # Optional arguments
        #   $tempType   - One of the strings 'system', 'debug' or 'error', corresponding to the icon
        #                   that's used to draw the button when it's flashing ('undef' when $type is
        #                   'empty')
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $type, $tempType, $check) = @_;

        # Local variables
        my $iv;

        # Check for improper arguments
        if (
            ! defined $type
            || ($type ne 'empty' && $type ne 'system' && $type ne 'debug' && $type ne 'error')
            || (
                defined $tempType && $tempType ne 'system' && $tempType ne 'debug'
                && $tempType ne 'error'
            )
            || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateConsoleButton', @_);
        }

        if ($self->consoleButton) {

            if (! $self->consoleIconFlashFlag) {
                $iv = 'constEmptyIconPath';
            } elsif ($tempType) {
                $iv = 'const' . ucfirst($tempType) . 'IconPath';
            } else {
                $iv = 'const' . ucfirst($type) . 'IconPath';
            }

            $self->consoleButton->set_icon_widget(
                Gtk2::Image->new_from_file($axmud::SHARE_DIR . $axmud::CLIENT->$iv),
            );

            $self->ivPoke('consoleIconType', $type);
            $self->ivPoke('consoleIconTempType', $tempType);
            $self->ivPoke('consoleIconFlashFlag', TRUE);

            $self->winObj->winShowAll($self->_objClass . '->updateConsoleButton');
        }

        return 1;
    }

    ##################
    # Accessors - set

    sub notify_addTableObj {

        # Called by GA::Strip::Table->addTableObj whenever a table object is added to the window's
        #   Gtk2::Table

        my ($self, $tableObj, $check) = @_;

        # Check for improper arguments
        if (! defined $tableObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->notify_addTableObj', @_);
        }

        if ($tableObj->type eq 'pane') {

            # Add the pane object to the list of pane objects which can be made active with the
            #   switch button
            $self->ivPush('paneObjList', $tableObj);
        }

        return 1;
    }

    sub set_consoleIconFlash {

        # Called by GA::Client->spinClientLoop to flash the console button

        my ($self, $check) = @_;

        # Local variables
        my $iv;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_consoleIconFlash', @_);
        }

        # (The calling function has already compared IVs against this window's visible session)

        if ($self->consoleButton && $self->consoleIconType) {

            if ($self->consoleIconFlashFlag) {

                $self->consoleButton->set_icon_widget(
                    Gtk2::Image->new_from_file(
                        $axmud::SHARE_DIR . $axmud::CLIENT->constEmptyIconPath,
                    ),
                );

                $self->ivPoke('consoleIconFlashFlag', FALSE);

            } else {

                $iv = 'const' . ucfirst($self->consoleIconTempType) . 'IconPath';

                $self->consoleButton->set_icon_widget(
                    Gtk2::Image->new_from_file($axmud::SHARE_DIR . $axmud::CLIENT->$iv),
                );

                $self->ivPoke('consoleIconFlashFlag', TRUE);
            }

            $self->consoleButton->show_all();
        }

        return 1;
    }

    sub reset_consoleIconFlash {

        # Called by GA::Session->spinMaintainLoop to stop the console button's flashing

        my ($self, $check) = @_;

        # Local variables
        my $iv;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->reset_consoleIconFlash', @_);
        }

        if ($self->consoleButton && $self->consoleIconType) {

            $iv = 'const' . ucfirst($self->consoleIconType) . 'IconPath';

            $self->consoleButton->set_icon_widget(
                Gtk2::Image->new_from_file($axmud::SHARE_DIR . $axmud::CLIENT->$iv),
            );

            $self->consoleButton->show_all();

            $self->ivPoke('consoleIconTempType', 'empty');
            $self->ivPoke('consoleIconFlashFlag', TRUE);
        }

        return 1;
    }

    sub set_originalEntryText {

        # Called by GA::Win::Internal->setKeyPressEvent

        my ($self, $text, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_originalEntryText', @_);
        }

        $self->ivPoke('originalEntryText', $text);

        return 1;
    }

    sub set_recordIcon {

        # Called by Games::Axmud::Cmd::Record->do, etc
        # Updates the entry icon showing the session's recording status (but only if it's the
        #   visible session)

        my ($self, $session, $check) = @_;

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_recordIcon', @_);
        }

        if (
            $self->entry
            && $self->winObj->visibleSession
            && $self->winObj->visibleSession eq $session
        ) {
            if ($session->recordingPausedFlag) {
                $self->entry->set_icon_from_stock('secondary', 'gtk-media-pause');
            } elsif ($session->recordingFlag) {
                $self->entry->set_icon_from_stock('secondary', 'gtk-media-record');
            } else {
                $self->entry->set_icon_from_stock('secondary', undef);
            }
        }

        # (No IVs to update)

        return 1;
    }

    sub notify_removeTableObj {

        # Called by GA::Strip::Table->removeTableObj whenever a table object is removed from the
        #   window's Gtk2::Table

        my ($self, $tableObj, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (! defined $tableObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->notify_removeTableObj', @_);
        }

        # Remove the pane object from the list of pane objects which can be made active with the
        #   switch button
        foreach my $paneObj ($self->paneObjList) {

            if ($paneObj ne $tableObj) {

                push (@list, $paneObj);
            }
        }

        $self->ivPoke('paneObjList', @list);

        return 1;
    }

    sub set_specialEchoFlag {

        # Called by GA::Session->updateSpecialEcho

        my ($self, $flag, $check) = @_;

        # Check for improper arguments
        if (! defined $flag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_specialEchoFlag', @_);
        }

        if (! $flag) {

            $self->ivPoke('specialEchoFlag', FALSE);
            $self->ivPoke('specialPreserveFlag', FALSE);
            $self->ivPoke('specialWorldCmd', '');

        } else {

            $self->ivPoke('specialEchoFlag', TRUE);
        }

        if ($self->entry) {

            $self->entry->set_text('');
            $self->entry->set_icon_from_stock('primary', undef);
        }

        return 1;
    }

    ##################
    # Accessors - get

    sub entry
        { $_[0]->{entry} }
    sub wipeButton
        { $_[0]->{wipeButton} }
    sub consoleButton
        { $_[0]->{consoleButton} }
    sub inputButton
        { $_[0]->{inputButton} }
    sub cancelButton
        { $_[0]->{cancelButton} }
    sub switchButton
        { $_[0]->{switchButton} }
    sub scrollButton
        { $_[0]->{scrollButton} }
    sub splitButton
        { $_[0]->{splitButton} }

    sub paneObjList
        { my $self = shift; return @{$self->{paneObjList}}; }

    sub originalEntryText
        { $_[0]->{originalEntryText} }
    sub captureHash
        { my $self = shift; return %{$self->{captureHash}}; }
    sub consoleIconType
        { $_[0]->{consoleIconType} }
    sub consoleIconTempType
        { $_[0]->{consoleIconTempType} }
    sub consoleIconFlashFlag
        { $_[0]->{consoleIconFlashFlag} }

    sub specialEchoFlag
        { $_[0]->{specialEchoFlag} }
    sub specialPreserveFlag
        { $_[0]->{specialPreserveFlag} }
    sub specialWorldCmd
        { $_[0]->{specialWorldCmd} }
}

{ package Games::Axmud::Strip::ConnectInfo;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Strip Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Win::Internal->drawWidgets or ->addStripObj
        # Creates the GA::Strip::ConnectInfo - a non-compulsory strip object containing
        #   Gtk2::Labels and blinkers
        #
        # Expected arguments
        #   $number     - The strip object's number within the parent window (matches
        #                   GA::Win::Internal->stripCount, or -1 for a temporary strip object
        #                   created to access its default IVs)
        #   $winObj     - The parent window object (GA::Win::Internal). 'temp' for temporary strip
        #                   objects
        #
        # Optional arguments
        #   %initHash   - A hash containing arbitrary data to use as the strip object's
        #                   initialisation settings. The strip object should use default
        #                   initialisation settings unless it can succesfully interpret one or more
        #                   of the key-value pairs in the hash, if there are any
        #               - (This type of strip object requires no initialisation settings)
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my ($class, $number, $winObj, %initHash) = @_;

        # Local variables
        my %modHash;

        # Check for improper arguments
        if (! defined $class || ! defined $number || ! defined $winObj) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Setup
        my $self = {
            _objName                    => 'strip_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard strip object IVs
            # -------------------------

            # The strip object's number within the parent window (matches
            #   GA::Win::Internal->stripCount, or -1 for a temporary strip object created to access
            #   its default IVs)
            number                      => $number,
            # The type of strip object (custom strip objects should use a ->type starting with
            #   'custom_' to avoid clashing with future built-in strip objects)
            type                        => 'connect_info',
            # The parent window object (GA::Win::Internal). 'temp' for temporary strip objects
            winObj                      => $winObj,

            # Flag set to TRUE if the strip object is visible (has actually drawn widgets in the
            #   window), set to FALSE if it is not visible (has drawn no widgets in the window, but
            #   still exists in GA::Win::Internal->stripHash, etc)
            # The flag might be set to FALSE in strip objects like GA::Strip::GaugeBox, which might
            #   have gauges to draw, or not, depending on current conditions. (Most strip objects
            #   have this flag set to TRUE all the time)
            # If FALSE, GA::Win::Internal->drawWidgets and ->addStripObj don't draw any widgets when
            #   called by this object's functions
            # NB Strip objects are created with this flag set to TRUE or FALSE, but once created,
            #   the flag's value shouldn't be modified by anything other than
            #   GA::Win::Internal->hideStripObj and ->revealStripObj (which in turn call
            #   $self->set_visibleFlag)
            visibleFlag                 => TRUE,
            # Flag set to TRUE is the strip object should be given its share of any extra space
            #   within the packing box (the extra space is divided equally between all children of
            #   the box whose ->expandFlag is TRUE)
            expandFlag                  => FALSE,
            # Flag set to TRUE if any space given to the strip object by the 'expand' option is
            #   actually allocated within the strip object, FALSE if it is used as padding outside
            #   it (on both sides)
            fillFlag                    => FALSE,
            # Flag set to TRUE if the strip object should be packed into its window with a small
            #   gap between strip objects to either side; FALSE if not (can be set to FALSE if the
            #   the strip object's widgets are drawn in a way, such that a gap is not necessary,
            #   for example in the toolbar strip object)
            spacingFlag                 => TRUE,
            # Flag set to TRUE if only one instance of this strip object should be added to the
            #   parent window, set to FALSE if any number of instances can be added
            jealousyFlag                => TRUE,
            # Flag set to TRUE if this strip object can be added when $axmud::BLIND_MODE_FLAG is
            #   TRUE, FALSE if it can't be added (because it's not useful for visually-impaired
            #   users)
            blindFlag                   => FALSE,
            # Flag set to TRUE if the main container widget, stored in $self->packingBox, should be
            #   allowed to accept the focus, FALSE if not. The restriction is applied during the
            #   call to GA::Win::Internal->drawWidgets and ->addStripObj. Even if FALSE, widgets in
            #   the container widget can be set to accept the focus (e.g. the Gtk2::Entry in
            #   GA::Strip::MenuBar)
            allowFocusFlag              => FALSE,

            # Initialisation settings stored as a hash (see the comments above)
            initHash                    => \%modHash,
            # Reference to a function to call when some widget is used. This IV is set only when
            #   required by this type of strip object. It can be set by a call to
            #   $self->set_func() or by some setting in $self->initHash, which is applied in the
            #   call to $self->objEnable(). To obtain a reference to an OOP method, you can use the
            #   generic object function Games::Axmud->getMethodRef()
            funcRef                     => undef,
            # A value passed to ->funcRef when it is called which identifies this strip object and
            #   its widget(s). Can be any value, including 'undef'. It can be set by a call to
            #   $self->set_id() or by some setting in $self->initHash, which is applied in the call
            #   to $self->objEnable()
            funcID                      => undef,

            # The container widget for this strip object (usually a Gtk2::HBox or Gtk2::VBox). This
            #   widget is the one added to the window's main Gtk2::HBox or Gtk2::VBox
            packingBox                  => undef,       # Gtk2::HBox or Gtk2::VBox

            # Other IVs
            # ---------

            # Widgets
            hostLabel                   => undef,       # Gtk2::Label
            frame                       => undef,       # Gtk2::Frame
            canvas                      => undef,       # Gnome2::Canvas
            timeLabel                   => undef,       # Gtk2::Label

            # The Gnome2::Canvas::Item objects that are drawn as blinkers - little blobs of colour
            #   which are lit up (briefly) when data is sent to and forth from the world, drawn on a
            #   Gnome2::Canvas
            # This version of Axmud implements the following blinker numbers:
            #   0   - blinker turned on when data is received from the world
            #   1   - blinker turned on when telnet option/protocol data (invisible to users) is
            #           received from the world
            #   2   - blinker turned on when a world command is sent
            # In each window, only the window object's ->visibleSession can light up blinkers; when
            #   the visible session changes, all blinkers are reset
            #
            # Hash of blinker objects (GA::Obj::Blinker), one for each blinker, in the form
            #   $blinkerHash{number} = blessed_reference_to_blinker_object
            blinkerHash                 => {},
            # Number of blinker objects created
            blinkerCount                => 3,
            # The portion of the Gnome2::Canvas required for each blinker, in pixels
            blinkerWidth                => 20,
            blinkerHeight               => 10,
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    # Standard strip object functions

    sub objEnable {

        # Called by GA::Win::Internal->drawWidgets or ->addStripObj
        # Sets up the strip object's widgets
        #
        # Expected arguments
        #   $winmapObj  - The winmap object (GA::Obj::Winmap) that specifies the layout of the
        #                   parent window
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $winmapObj, $check) = @_;

        # Check for improper arguments
        if (! defined $winmapObj || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objEnable', @_);
        }

        # Create a packing box
        my $hBox = Gtk2::HBox->new(FALSE, 0);
        $hBox->set_border_width(0);

        # Add two labels and a Gtk2::Canvas for drawing blinkers
        my $hostLabel = Gtk2::Label->new();
        $hBox->pack_start($hostLabel, FALSE, FALSE, 0);
        $hostLabel->set_markup($self->winObj->hostLabelText);

        my $frame = Gtk2::Frame->new(undef);
        $hBox->pack_end($frame, FALSE, FALSE, 0);
        $frame->set_border_width(0);
        # (The frame is already a little higher than the canvas, but the width isn't, so we'll add
        #   a few pixels)
        $frame->set_size_request(
            (($self->blinkerWidth * $self->blinkerCount) + 5),
            $self->blinkerHeight,
        );

        $frame->set_tooltip_text("Command sent | Text received\nOut-of-bounds data received");

        my $canvas = Gnome2::Canvas->new();
        $canvas->set_scroll_region(
            0,
            0,
            ($self->blinkerCount * $self->blinkerWidth),
            $self->blinkerHeight,
        );
        $frame->add($canvas);

        my $timeLabel = Gtk2::Label->new();
        $hBox->pack_end($timeLabel, FALSE, FALSE, 0);
        $timeLabel->set_markup($self->winObj->timeLabelText);
        $timeLabel->set_tooltip_text("Connected | delayed Quit\nWorld idle | User idle");

        # Update IVs
        $self->ivPoke('packingBox', $hBox);
        $self->ivPoke('hostLabel', $hostLabel);
        $self->ivPoke('frame', $canvas);
        $self->ivPoke('canvas', $canvas);
        $self->ivPoke('timeLabel', $timeLabel);

        # Create blinker objects (GA::Obj::Blinker)
        $self->createStandardBlinkers();

        # Draw the blinkers for the first time to set their 'off' colours
        $self->drawBlinker(
            -1,             # Draw all three blinkers
            FALSE,          # ...using their 'off' colour
        );

        return 1;
    }

    sub objDestroy {

        # Called by GA::Win::Internal->removeStripObj, just before the strip is removed from its
        #   parent window, and also by ->winDestroy and ->resetWinmap, to give this object a chance
        #   to do any necessary tidying up
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->objDestroy', @_);
        }

        # Only polite to ->destroy the Gnome2::Canvas and its items
        if ($self->canvas) {

            foreach my $blinkerObj ($self->ivValues('blinkerHash')) {

                if (defined $blinkerObj->canvasItem) {

                    $blinkerObj->canvasItem->destroy();
                }
            }

            $self->canvas->destroy();
        }

        return 1;
    }

#   sub setWidgetsIfSession {}              # Inherited from GA::Generic::Strip

#   sub setWidgetsChangeSession {}          # Inherited from GA::Generic::Strip

    # ->signal_connects

    # Other functions

    sub createStandardBlinkers {

        # Called by $self->objEnable
        # Creates blinker objects (GA::Obj::Blinker)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef'

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createStandardBlinkers', @_);
        }

        for (my $count = 0; $count < $self->blinkerCount; $count++) {

            my $blinkerObj = Games::Axmud::Obj::Blinker->new($count);
            if ($blinkerObj) {

                $self->ivAdd('blinkerHash', $blinkerObj->number, $blinkerObj);
            }
        }

        return 1;
    }

    sub drawBlinker {

        # Called by GA::Client->spinClientLoop or GA::Win::Internal->resetBlinkers
        # Draws one (or all) of the blinkers in this strip object
        #
        # Expected arguments
        #   $choice     - Which blinker to draw. -1 to draw all blinkers, or one of the keys in
        #                   $self->blinkerHash (matching GA::Obj::Blinker->number)
        #
        # Optional arguments
        #   $onFlag     - TRUE if the blinker(s) should be drawn 'on', FALSE (or 'undef') if the
        #                       blinker(s) should be drawn 'off'
        #
        # Return values
        #   'undef'

        my ($self, $choice, $onFlag, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (! defined $choice || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->drawBlinker', @_);
        }

        # Check that the blinker widgets are actually drawn (unlikely that they aren't)
        if (! $self->canvas) {

            return undef;
        }

        # Compile a list of blinkers to draw
        if ($choice == -1) {

            for (my $count = 0; $count < $self->blinkerCount; $count++) {

                push (@list, $count);
            }

        } else {

            push (@list, $choice);
        }

        # Draw each blinker in turn
        foreach my $number (@list) {

            my ($blinkerObj, $colour, $canvasItem);

            # Draw this blinker
            $blinkerObj = $self->ivShow('blinkerHash', $number);
            if ($blinkerObj) {

                # Set the colour to use
                if (! $onFlag) {
                    $colour = $blinkerObj->offColour;
                } else {
                    $colour = $blinkerObj->onColour;
                }

                # Destroy the old canvas item, so it can be replaced
                if ($blinkerObj->canvasItem) {

                    $blinkerObj->canvasItem->destroy();
                }

                $canvasItem = Gnome2::Canvas::Item->new(
                    $self->canvas->root(),
                    'Gnome2::Canvas::Rect',
                    x1 => (($self->blinkerWidth * $number) + 2),        # 2 / 22 / 42...
                    y1 => 1,                                            # 1
                    x2 => (($self->blinkerWidth * ($number + 1) - 2)),  # 18 / 38 / 58...
                    y2 => ($self->blinkerHeight - 1),                   # 9
                    fill_color => $colour,
                    outline_color => '#000000',
                );

                $canvasItem->raise_to_top();

                # Update IVs
                $blinkerObj->ivPoke('canvasItem', $canvasItem);
                if (! $onFlag) {
                    $blinkerObj->ivPoke('onFlag', FALSE);
                } else {
                    $blinkerObj->ivPoke('onFlag', TRUE);
                }
            }
        }

        return undef;
    }

    ##################
    # Accessors - set

    sub set_hostLabel {

        my ($self, $text, $tooltip, $check) = @_;

        # Check for improper arguments
        if (! defined $text || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_hostLabel', @_);
        }

        $self->hostLabel->set_markup($text);
        if (defined $tooltip) {

            $self->hostLabel->set_tooltip_text($tooltip);

        } else {

            # Make sure any earlier tooltip is no longer visible
            $self->hostLabel->set_tooltip_text('');
        }

        return 1;
    }

    sub set_timeLabel {

        my ($self, $text, $check) = @_;

        # Check for improper arguments
        if (! defined $text || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->set_timeLabel', @_);
        }

        $self->timeLabel->set_markup($text);

        return 1;
    }

    ##################
    # Accessors - get

     sub hostLabel
        { $_[0]->{hostLabel} }
     sub frame
        { $_[0]->{frame} }
     sub canvas
        { $_[0]->{canvas} }
     sub timeLabel
        { $_[0]->{timeLabel} }

     sub blinkerHash
        { my $self = shift; return %{$self->{blinkerHash}}; }
     sub blinkerCount
        { $_[0]->{blinkerCount} }
     sub blinkerWidth
        { $_[0]->{blinkerWidth} }
     sub blinkerHeight
        { $_[0]->{blinkerHeight} }
}

{ package Games::Axmud::Strip::Custom;

    # Any user-written strip objects should inherit from this object

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Strip Games::Axmud);

    ##################
    # Constructors

#   sub new {}                              # Inherited from GA::Generic::Strip

    ##################
    # Methods

    # Standard strip object functions

#   sub objEnable {}                        # Inherited from GA::Generic::Strip

#   sub objDestroy {}                       # Inherited from GA::Generic::Strip

#   sub setWidgetsIfSession {}              # Inherited from GA::Generic::Strip

#   sub setWidgetsChangeSession {}          # Inherited from GA::Generic::Strip

    # ->signal_connects

    # Other functions

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

# Package must return a true value
1
