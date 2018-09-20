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
# Games::Axmud::Obj::Desktop
# The main desktop object. Arranges windows on one or more workspaces, each containing one or more
#   workspace grids

{ package Games::Axmud::Obj::Desktop;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Client->start
        #
        # Expected arguments
        #   (none besides $class)
        #
        # Return values
        #   'undef' on improper arguments or if a GA::Obj::Desktop object already exists
        #   Blessed reference to the newly-created object on success

        my ($class, $check) = @_;

        # Check for improper arguments
        if (! defined $class || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Only one desktop object can exist
        if ($axmud::CLIENT->desktopObj) {

            return undef;
        }

        # Setup
        my $self = {
            _objName                    => 'desktop',
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Widget registries
            # -----------------

            # Registry hash of all workspace objects which still exist. Workspace objects
            #   (GA::Obj::Workspace) handle a single workspace on the desktop, on which 'grid'
            #   windows can be arranged on a 3-dimensional grid to avoid overlapping (each grid is
            #   handled by a workspace grid object, GA::Obj::WorkspaceGrid)
            # If GA::Client->shareMainWinFlag = TRUE, all sessions share a single 'main' window,
            #   so each session has its own workspace grid object on every workspace. If
            #   GA::CLIENT->shareMainFlag = FALSE, all sessions have their own 'main' window, so
            #   there is only one workspace grid for each workspace, shared by all sessions
            # NB The workspace object corresponding to the workspace from which Axmud was launched
            #   has the number 0, and cannot be deleted. Unlike GA::Client->initWorkspaceHash,
            #   subsequent workspaces don't have to be numbered sequentially (1, 2, 3...) but are
            #   still numbered in the order in which they're created
            # Hash in the form
            #   $workspaceHash{unique_number} = blessed_reference_to_workspace_object
            workspaceHash               => {},
            # Number of workspace objects ever created (used to give each workspace object a unique
            #   number)
            workspaceCount              => 0,
            # The 'default' workspace is the workspace in which Axmud is opened (#0), and is also
            #   stored here for convenience
            defaultWorkspaceObj         => undef,
            defaultWorkspace            => undef,

            # Registry hash of workspace grid objects which still exist. Each workspace objects
            #   usually has one or more workspace grid objects (or none, if
            #   GA::Obj::Workspace->gridEnableFlag is TRUE)
            # Each workspace grid object either belongs to a single session
            #   (GA::Client->shareMainWinFlag = TRUE), or is shared between all sessions
            #   (GA::CLIENT->shareMainWinFlag = FALSE)
            # A workspace grid is divided up into zones. Zones can't use partial gridblocks so a
            #   zone size of 15x15 is possible, but not 20.5x15
            # Zones can specify that only certain window types can be placed in them, or can specify
            #   that all window types may be placed in them.
            # Hash in the form
            #   $gridHash{unique_number} = blessed_reference_to_workspace_grid_object
            gridHash                    => {},
            # Number of workspace grid objects ever created for this workspace (used to give every
            #   workspace grid object a unique number)
            gridCount                   => 0,

            # Registry hash of all 'grid' windows which still exist. 'grid' windows are any window
            #   specified by GA::Client->constGridWinTypeHash, specifically, windows which can be
            #   placed on a workspace grid (unlike temporary 'free' windows, which are never placed
            #   on a workspace grid)
            # 'Grid' windows are handled by GA::Win::Internal or GA::Win::External objects
            # Hash in the form
            #   $gridWinHash{unique_number} = blessed_reference_to_grid_window_object
            gridWinHash                 => {},
            # Number of 'grid' window objects ever created (used to give each 'grid' window object a
            #   unique number)
            gridWinCount                => 0,

            # Registry hash of all 'free' windows which still exist (except 'dialogue' windows,
            #   which are not stored in any registry because they automatically close with their
            #   parent window; all code in this object assumes that 'free' windows exclude
            #   'dialogue' windows)
            # 'Free' windows are any window specified by GA::Client->constFreeWinTypeHash
            #   (specifically, any temporary window which is never placed on a workspace grid)
            # 'Free' windows are handled by various objects inheriting from GA::Generic::FreeWin
            # Hash in the form
            #   $freeWinHash{unique_number} = blessed_reference_to_free_window_object
            freeWinHash                 => {},
            # Number of 'free' window objects ever created (used to give each 'free' window object a
            #   unique number)
            freeWinCount                => 0,

            # Registry hash of all textview objects (created by all sessions) which still exist.
            #   Textview objects (GA::Obj::TextView) handle a single Gtk2::Textview
            # NB The code is at liberty to create its own Gtk2::TextViews, not handled by textview
            #   objects, if the code doesn't need the full functionality of a textview object. Those
            #   Gtk2::TextViews are not stored here
            # Hash in the form
            #   $textViewHash{unique_number} = blessed_reference_to_textview_object
            textViewHash                => {},
            # Number of textview objects ever created (used to give each textview object a unique
            #   number)
            textViewCount               => 0,

            # Other IVs
            # ---------

            # $self->start will set this flag to FALSE if it's not possible to create workspace
            #   grids at all (because the desktop is too small, etc). If set to TRUE, workspace
            #   grids are only created when both this flag and GA::Client->activateGridFlag are
            #   TRUE
            gridPermitFlag              => TRUE,
            # The number of workspaces that Axmud can potentially use is specified by
            #   GA::Client->initWorkspaceHash. On each workspace allowed, Axmud tests whether a
            #   workspace grid can be placed on it. If that test fails, Axmud takes the following
            #   action:
            #       - If it's the default (first) workspace, the workspace object's
            #           ->gridEnableFlag is set to FALSE. Windows are not arranged on a grid on that
            #           single workspace, and no more workspace objects can be created
            #       - For subsequent workspaces, if the test fails that workspace object is deleted,
            #           and windows can only be opened on previously-created workspaces
            # In either case, if the test fails, this flag is set to FALSE to prevent more
            #   workspaces being created
            newWorkspaceFlag            => TRUE,

            # A list of Gtk2::Gdk::Pixbufs corresponding to the icons stored in the '/icons/win'
            #   sub-directory for 'main' windows
            mainWinIconList             => [],
            # A list of Gtk2::Gdk::Pixbufs for 'map' windows
            mapWinIconList              => [],
            # A list of Gtk2::Gdk::Pixbufs for 'protocol' windows
            protocolWinIconList         => [],
            # A list of Gtk2::Gdk::Pixbufs for 'fixed' windows
            fixedWinIconList            => [],
            # A list of Gtk2::Gdk::Pixbufs for 'custom' windows
            customWinIconList           => [],
            # A list of Gtk2::Gdk::Pixbufs for 'external' windows (the pixbufs are created, but not
            #   used - 'external' windows keep their own icons)
            externalWinIconList         => [],

            # A list of Gtk2::Gdk::Pixbufs for 'viewer' windows
            viewerWinIconList           => [],
            # A list of Gtk2::Gdk::Pixbufs for 'edit' windows
            editWinIconList             => [],
            # A list of Gtk2::Gdk::Pixbufs for 'pref' windows
            prefWinIconList             => [],
            # A list of Gtk2::Gdk::Pixbufs for 'wiz' windows
            wizWinIconList              => [],
            # A list of Gtk2::Gdk::Pixbufs for 'dialogue' windows
            dialogueWinIconList         => [],
            # A list of Gtk2::Gdk::Pixbufs for 'other' windows
            otherWinIconList            => [],
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    sub start {

        # Called by GA::Client->start immediately after the call to $self->new
        # Sets up the desktop object with its first (default) workspace, sets up pixbufs for all
        #   window icons, sets up rc styles for each type of window
        # Then creates a spare 'main' window, which doesn't belong to any session, and which will
        #   be re-used by the first session that opens
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the start process fails
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($zonemap, $screen, $workspace, $workspaceObj, $winObj);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->start', @_);
        }

        # GA::Client->initWorkspaceHash should contain at least the following key-value pair:
        #   ->initWorkspaceHash{0} = default_zonemap_for_default_workspace
        # If it doesn't (for some reason), get the default workspace's default zonemap from the
        #   constant hash instead
        if (! $axmud::CLIENT->ivExists('initWorkspaceHash', 0)) {
            $zonemap = $axmud::CLIENT->ivShow('constInitWorkspaceHash', 0);
        } else {
            $zonemap = $axmud::CLIENT->ivShow('initWorkspaceHash', 0);
        }

        # Set up pixbufs for all Axmud-created windows
        if (! $self->prepareIcons()) {

            $axmud::CLIENT->writeWarning(
                'Could not create icon pixbufs for windows',
                $self->_objClass . '->start',
            );
        }

        # On MSWin and in Axmud 'blind' mode, workspace grids are currently disabled in all
        #   circumstances
        if ($axmud::BLIND_MODE_FLAG || $^O eq 'MSWin32') {

            $self->ivPoke('gridPermitFlag', FALSE);
        }

        # Create the default (first) workspace object, representing the workspace in which Axmud
        #   starts
        # Gnome2::Wnck doesn't exist on MS Windows, so we need to check for that
        if ($^O ne 'MSWin32') {

            $screen = Gnome2::Wnck::Screen->get_default();
            if ($screen) {

                $screen->force_update();
                $workspace = $screen->get_active_workspace();
            }
        }

        $workspaceObj = $self->add_workspace($workspace, $screen);
        if (! $workspaceObj) {

            return $axmud::CLIENT->writeError(
                'Could not set up default workspace',
                $self->_objClass . '->start',
            );

        } else {

            $self->ivPoke('defaultWorkspaceObj', $workspaceObj);
            $self->ivPoke('defaultWorkspace', $workspace);

            # Find the available size of the workspace, panels and window controls. Set the
            #   workspace's default zonemap
            $workspaceObj->start($zonemap);

            # The default workspace object performs certain tests on the workspace. If those tests
            #   fail, workspace grids are disabled on that workspace and no additional workspaces
            #   are used
            if (! $workspaceObj->gridEnableFlag) {

                $self->ivPoke('gridPermitFlag', FALSE);
                $self->ivPoke('newWorkspaceFlag', FALSE);
            }
        }

        # Create the spare 'main' window on the default workspace, but not placed onto any
        #   workspace grid
        # (Don't do it in Axmud test mode, which skips the Connections window and goes straight to
        #    the first session)
        if (! $axmud::TEST_MODE_FLAG) {

            $winObj = $workspaceObj->createSimpleGridWin(
                'main',                         # Window type
                'main',                         # Window name
                undef,                          # Window title set automatically
                'main_wait',                    # Use a minimal winmap, replaced by first session
                'Games::Axmud::Win::Internal',  # Package name
                undef,                          # No known Gtk2::Window
                undef,                          # No known Gnome2::Wnck::Window
                $axmud::CLIENT,                 # Owner
                undef,                          # No owner session
            );

            if (! $winObj) {

                return $axmud::CLIENT->writeError(
                    'Could not create spare \'main\' window',
                    $self->_objClass . '->start',
                );

            } else {

                # (GA::Client->mainWin is normally set by calls to GA::Client->setCurrentSession)
                $axmud::CLIENT->set_mainWin($winObj);
            }
        }

        return 1;
    }

    sub stop {

        # Called by GA::Client->stop
        # Closes any remaining 'internal' windows, restores 'external' windows to their original
        #   size/position, closes any remaining 'free' windows
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my ($workspaceCount, $gridCount, $gridWinCount, $freeWinCount, $textViewCount, $msg);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->stop', @_);
        }

        # Close down workspace objects (which closes down its workspace grids and windows), youngest
        #   first
        foreach my $workspaceObj (
            sort {$b->number <=> $a->number} ($self->ivValues('workspaceHash'))
        ) {
            if ($workspaceObj->number != 0) {

                $self->del_workspace($workspaceObj);

            } else {

                $workspaceObj->stop();
                $self->ivDelete('workspaceHash', 0);
            }
        }

        $self->ivUndef('defaultWorkspaceObj');
        $self->ivUndef('defaultWorkspace');

        # Check there are no workspaces, workspace grids, 'grid' windows, 'free' windows or
        #   textviews left (for error-detection purposes)
        $workspaceCount = $self->ivPairs('workspaceHash');
        if ($workspaceCount) {

            if ($workspaceCount == 1) {
                $msg = 'There was 1 un-closed workspace object';
            } else {
                $msg = 'There were ' . $workspaceCount . ' un-closed workspace objects';
            }

            $msg .= ' on desktop shutdown';

            $axmud::CLIENT->writeWarning($msg, $self->_objClass . '->stop');
        }

        $gridCount = $self->ivPairs('gridHash');
        if ($gridCount) {

            if ($gridCount == 1) {
                $msg = 'There was 1 un-closed workspace grid object';
            } else {
                $msg = 'There were ' . $gridCount . ' un-closed workspace grid objects';
            }

            $msg .= ' on desktop shutdown';

            $axmud::CLIENT->writeWarning($msg, $self->_objClass . '->stop');
        }

        $gridWinCount = $self->ivPairs('gridWinHash');
        if ($gridWinCount) {

            if ($gridWinCount == 1) {
                $msg = 'There was 1 un-closed \'grid\' window object';
            } else {
                $msg = 'There were ' . $gridWinCount . ' un-closed \'grid\' window objects';
            }

            $msg .= ' on desktop shutdown';

            $axmud::CLIENT->writeWarning($msg, $self->_objClass . '->stop');
        }

        $freeWinCount = $self->ivPairs('freeWinHash');
        if ($freeWinCount) {

            if ($freeWinCount == 1) {
                $msg = 'There was 1 un-closed \'free\' window object';
            } else {
                $msg = 'There were ' . $freeWinCount . ' un-closed \'free\' window objects';
            }

            $msg .= ' on desktop shutdown';

            $axmud::CLIENT->writeWarning($msg, $self->_objClass . '->stop');
        }

        $textViewCount = $self->ivPairs('textViewHash');
        if ($textViewCount) {

            if ($textViewCount == 1) {
                $msg = 'There was 1 un-closed textview object';
            } else {
                $msg = 'There were ' . $textViewCount . ' un-closed textview objects';
            }

            $msg .= ' on desktop shutdown';

            $axmud::CLIENT->writeWarning($msg, $self->_objClass . '->stop');
        }

        return 1;
    }

    sub setupWorkspaces {

        # Called by GA::Client->start
        # The earlier call to $self->start sets up the default workspace; this function sets up
        #   any further workspaces specified by GA::Client->initWorkspaceHash
        # Each workspace is handled by a workspace object (GA::Obj::Workspace). The workspace object
        #   performs certain tests on the workspace. If those tests fail, that workspace is not
        #   used, the workspace object is discarded, and no additional workspaces are used
        # If the test failed on the default workspace created by $self->start, that workspace is
        #   still used, but this function uses no additional workspaces
        # If $self->newWorkspaceFlag was set to FALSE by $self->start, this function uses no
        #   additional workspaces
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (@initList, @useList);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setupWorkspaces', @_);
        }

        if ($self->gridPermitFlag && $self->newWorkspaceFlag) {

            # Get a list of Gnome2::Workspaces, in the order in which they should be used. The order
            #   depends on GA::Client->initWorkspaceDir; the returned list doesn't include the
            #   default workspace
            @useList = $self->detectWorkspaces();

            # GA::Client->initWorkspaceHash specifies the Gnome2::Workspaces that Axmud should use
            #   initially. If it specifies more workspaces than the 'default' one, create a new
            #   workspace object for them (but not if we've run out of available workspaces)
            @initList = sort {$a <=> $b} ($axmud::CLIENT->ivKeys('initWorkspaceHash'));
            foreach my $num (@initList) {

                my ($workspace, $zonemap, $workspaceObj);

                # The default workspace already exists
                if ($num) {

                    $workspace = shift @useList;
                    $zonemap = $axmud::CLIENT->ivShow('initWorkspaceHash', $num);
                    if ($workspace) {

                        $self->useWorkspace($workspace, $zonemap);
                    }
                }
            }
        }

        return 1;
    }

    sub useWorkspace {

        # Called by $self->setupWorkspaces or GA::Cmd::AddWorkspace->do
        # Creates a workspace object (GA::Obj::Workspace) for the specified Gnome2::Workspace
        #
        # Expected arguments
        #   $workspace  - The Gnome2::Workspace to use
        #
        # Optional arguments
        #   $zonemap    - The name of the default zonemap for the workspace object. If 'undef',
        #                   this function chooses a default zonemap
        #
        # Return values
        #   'undef' on improper arguments, if new workspaces can't be added, if the workspace object
        #       can't be created or if tests performed on the workspace fail
        #   Otherwise returns the blessed reference of the workspace object created

        my ($self, $workspace, $zonemap, $check) = @_;

        # Local variables
        my $workspaceObj;

        # Check for improper arguments
        if (! defined $workspace || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->useWorkspace', @_);
        }

        # If tests failed during a previous call to this function, use no additional workspaces
        if (! $self->newWorkspaceFlag) {

            return undef;
        }

        # If no default zonemap was specified, choose one
        if (! $zonemap) {

            if ($axmud::CLIENT->shareMainWinFlag) {
                $zonemap = 'basic';
            } else {
                $zonemap = 'horizontal';
            }
        }

        # Create the workspace object and set it up
        $workspaceObj = $self->add_workspace($workspace, $workspace->get_screen());
        if (! $workspaceObj) {

            return undef;

        } else {

            $workspaceObj->start($zonemap);

            # $workspaceObj->start performed certain tests on the workspace. If those tests failed,
            #   that workspace object must be discarded and no additional workspaces can be used
            if (! $workspaceObj->gridEnableFlag) {

                $self->ivPoke('newWorkspaceFlag', FALSE);
                $self->del_workspace($workspaceObj);

                return undef;

            } else {

                 return $workspaceObj;
            }
        }
    }

    sub detectWorkspaces {

        # Called by $self->setupWorkspaces and $self->detectUnusedWorkspaces
        # Get a list of Gnome2::Workspaces, in the order in which they should be used. The order
        #   depends on GA::Client->initWorkspaceDir; the returned list doesn't include the
        #   default workspace
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise returns the list of Gnome2::Workspace objects

        my ($self, $check) = @_;

        # Local variables
        my (
            $workspace, $otherWorkspace,
            @emptyList, @useList,
        );

        # Check for improper arguments
        if (defined $check) {

             $axmud::CLIENT->writeImproper($self->_objClass . '->detectWorkspaces', @_);
             return @emptyList;
        }

        $workspace = $self->defaultWorkspace;

        # 'move_left'   - move left from the default workspace until we reach the left-most
        #                   workspace (and then stop)
        if ($axmud::CLIENT->initWorkspaceDir eq 'move_left') {

            do {

                $otherWorkspace = $workspace->get_neighbor('WNCK_MOTION_LEFT');

                if ($otherWorkspace) {

                    push (@useList, $otherWorkspace);
                    $workspace = $otherWorkspace;
                }

            } until (! $otherWorkspace);

        # 'move_right'  - move right from the default workspace until we reach the right-most
        #                   workspace (and then stop)
        } elsif ($axmud::CLIENT->initWorkspaceDir eq 'move_right') {

            do {

                $otherWorkspace = $workspace->get_neighbor('WNCK_MOTION_RIGHT');

                if ($otherWorkspace) {

                    push (@useList, $otherWorkspace);
                    $workspace = $otherWorkspace;
                }

            } until (! $otherWorkspace);

        # 'start_left'  - after finding the default workspace, the next workspace should be the
        #                   left-most one, after that move right until we reach the right-most
        #                   workspace (and then stop)
        } elsif ($axmud::CLIENT->initWorkspaceDir eq 'start_left') {

            do {

                $otherWorkspace = $workspace->get_neighbor('WNCK_MOTION_LEFT');

                if ($otherWorkspace) {

                    push (@useList, $otherWorkspace);
                    $workspace = $otherWorkspace;
                }

            } until (! $otherWorkspace);

            @useList = reverse @useList;
            $workspace = $self->defaultWorkspace;

            do {

                $otherWorkspace = $workspace->get_neighbor('WNCK_MOTION_RIGHT');

                if ($otherWorkspace) {

                    push (@useList, $otherWorkspace);
                    $workspace = $otherWorkspace;
                }

            } until (! $otherWorkspace);

        # 'start_right' - after finding the default workspace, the next workspace should be the
        #   right-most one, after that move left until we reach the left-most workspace (and then
        #   stop)
        } elsif ($axmud::CLIENT->initWorkspaceDir eq 'start_right') {

            do {

                $otherWorkspace = $workspace->get_neighbor('WNCK_MOTION_RIGHT');

                if ($otherWorkspace) {

                    push (@useList, $otherWorkspace);
                    $workspace = $otherWorkspace;
                }

            } until (! $otherWorkspace);

            @useList = reverse @useList;
            $workspace = $self->defaultWorkspace;

            do {

                $otherWorkspace = $workspace->get_neighbor('WNCK_MOTION_LEFT');

                if ($otherWorkspace) {

                    push (@useList, $otherWorkspace);
                    $workspace = $otherWorkspace;
                }

            } until (! $otherWorkspace);
        }

        return @useList;
    }

    sub detectUnusedWorkspaces {

        # Called by GA::Cmd::ListWorkspace->do
        # Calls $self->detectWorkspaces to get a list of Gnome2::Workspaces, then removes from that
        #   list any workspace already in use by Axmud (i.e. any workspace for which there is a
        #   workspace object, GA::Obj::Workspace)
        # Returns a list of the remaining workspaces (which may be empty)
        #
        # NB On MS Windows, Gnome2::Wnck does not exist, so this function currently returns an
        #   empty list
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   An empty list on improper arguments or if there are no unused workspaces
        #   Otherwise returns the list of Gnome2::Workspace objects

        my ($self, $check) = @_;

        # Local variables
        my (@emptyList, @list, @modList);

        # Check for improper arguments
        if (defined $check) {

             $axmud::CLIENT->writeImproper($self->_objClass . '->detectUnusedWorkspaces', @_);
             return @emptyList;
        }

        if ($^O eq 'MSWin32') {

            return @emptyList;

        } else {

            @list = $self->detectWorkspaces();

            OUTER: foreach my $workspace (@list) {

                INNER: foreach my $workspaceObj ($self->ivValues('workspaceHash')) {

                    if ($workspaceObj->wnckWorkspace eq $workspace) {

                        next OUTER;
                    }
                }

                # This workspace is unused
                push (@modList, $workspace);
            }

            # Operation complete
            return @modList;
        }
    }

    sub listWorkspaces {

        # Can be called by any function that wants to create a new 'grid' window
        # If the function wants the window to appear on a particular workspace only, it can call
        #   GA::Obj::Workspace->createGridWin directly
        # If it wants the window to appear on the first available workspace, it can call this
        #   function first. This function returns an ordered list of workspaces, with the preferred
        #   workspace (if specified) first in the list. The calling function can then call
        #   GA::Obj::Workspace->createGridWin for each workspace on the list until a new window
        #   object is actually created
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $preferObj  - The preferred GA::Obj::Workspace. If specified, it is placed at the
        #                   beginning of the returned list, and the remaining workspace objects are
        #                   added to the list in the order in which they were created. If not
        #                   specified, all workspace objects are added to the returned list in the
        #                   order in which they were created, the 'default' workspace first
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, the list of GA::Obj::Workspace objects described above

        my ($self, $preferObj, $check) = @_;

        # Local variables
        my (@emptyList, @returnList);

        # Check for improper arguments
        if (defined $check) {

             $axmud::CLIENT->writeImproper($self->_objClass . '->listWorkspaces', @_);
             return @emptyList;
        }

        foreach my $workspaceNum (sort {$a <=> $b} ($self->ivKeys('workspaceHash'))) {

            my $workspaceObj = $self->ivShow('workspaceHash', $workspaceNum);

            if (! defined $preferObj || $preferObj ne $workspaceObj) {

                push (@returnList, $workspaceObj);
            }
        }

        if (defined $preferObj) {

            unshift (@returnList, $preferObj);
        }

        return @returnList;
    }

    sub removeSessionWorkspaceGrids {

        # Called by GA::Session->stop
        # If each session has its own workspace grids, remove them (which closes any 'grid' windows
        #   on the workspace grid, except for that session's 'main' window)
        # If sessions share a single workspace grid, do nothing
        #
        # Expected arguments
        #   $session    - The GA::Session which is closing
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Check for improper arguments
        if (! defined $session || defined $check) {

             return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->removeSessionWorkspaceGrids',
                @_,
            );
        }

        if ($axmud::CLIENT->shareMainWinFlag) {

            foreach my $workspaceGridObj (
                sort {$a->number <=> $b->number} ($self->ivValues('gridHash'))
            ) {
                if ($workspaceGridObj->owner && $workspaceGridObj->owner eq $session) {

                    $workspaceGridObj->workspaceObj->removeWorkspaceGrid(
                        $workspaceGridObj,
                        $session,
                    );
                }
            }
        }

        return 1;
    }

    sub removeSessionWindows {

        # Called by GA::Session->stop
        # When the session closes, the earlier call to $self->removeSessionWorkspaceGrids removes
        #   any workspace grids used exclusively by that session
        # Look for any remaining 'grid' windows controlled by the session (there will probably be
        #   some if GA::CLIENT->shareMainWinFlag = FALSE). However, the session's 'main' window is
        #   not closed by this function
        #
        # Expected arguments
        #   $session    - The GA::Session which is closing
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Check for improper arguments
        if (! defined $session || defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->removeSessionWindows', @_);
        }

        foreach my $gridWinObj ($self->ivValues('gridWinHash')) {

            if (
                $gridWinObj->winType ne 'main'
                && (
                    ($gridWinObj->session && $gridWinObj->session eq $session)
                    # Possible, though unlikely, that ->owner is set, but ->session isn't
                    || ($gridWinObj->owner && $gridWinObj->owner eq $session)
                )
            ) {
                $gridWinObj->winDestroy();
            }
        }

        return 1;
    }

    sub activateWorkspaceGrids {

        # Called by GA::Cmd::ActivateGrid->do
        # For every workspace object, creates workspace grids for every session (or a single
        #   workspace grid, if sessions don't share a 'main' window), places existing windows on the
        #   correct grid and updates IVs
        # If workspace grids are already activated generally, does nothing
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $zonemap    - If specified, the name of the zonemap (matches a key in
        #                   GA::Client->zonemapHash) to be used as the default zonemap on every
        #                   workspace (and which is applied to every new workspace grid)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $zonemap, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper(
                $self->_objClass . '->activateWorkspaceGrids',
                @_,
            );
        }

        if (! $axmud::CLIENT->activateGridFlag) {

            $axmud::CLIENT->set_activateGridFlag(TRUE);

            foreach my $workspaceObj ($self->ivValues('workspaceHash')) {

                $workspaceObj->enableWorkspaceGrids($zonemap);
            }
        }

        return 1;
    }

    sub disactivateWorkspaceGrids {

        # Called by GA::Cmd::DisactivateGrid->do
        # Disables workspace grids for every workspace object and updates IVs. If workspace grids
        #   are already disactivated generally, does nothing
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
                $self->_objClass . '->disactivateWorkspaceGrids',
                @_,
            );
        }

        if ($axmud::CLIENT->activateGridFlag) {

            foreach my $workspaceObj ($self->ivValues('workspaceHash')) {

                $workspaceObj->disableWorkspaceGrids();
            }

            $axmud::CLIENT->set_activateGridFlag(FALSE);
        }

        return 1;
    }

    sub prepareIcons {

        # Called by $self->start
        # Sets up Gtk2::Gdk::Pixbufs for use as icons in 'grid' and 'free' windows
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if there's an error in creating any pixbuf (even after
        #       an error, the function will continue trying to create icons)
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            $failFlag,
            @list,
        );

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->prepareIcons', @_);
        }

        # Compile a list of window types
        @list = (
            $axmud::CLIENT->ivKeys('constGridWinTypeHash'),
            $axmud::CLIENT->ivKeys('constFreeWinTypeHash'),
        );

        # Different types of Axmud windows have their own icons
        OUTER: foreach my $type (@list) {

            my @iconList;

            INNER: foreach my $size ($axmud::CLIENT->constIconSizeList) {

                my ($path, $icon);

                # e.g. '/icons/win/icon_main_win_16.png'
                $path = $axmud::SHARE_DIR . '/icons/win/icon_' . $type . '_win_' . $size . '.png';
                if (! -e $path) {

                    # Continue trying to create the other icons
                    $failFlag = TRUE;

                } else {

                    $icon = Gtk2::Gdk::Pixbuf->new_from_file($path);
                    if (! $icon) {

                        # Continue trying to create the other icons
                        $failFlag = TRUE;

                    } else {

                        push (@iconList, $icon);
                    }
                }
            }

            # Update IVs
            if (@iconList) {

                $self->ivPush($type . 'WinIconList', @iconList);
            }
        }

        if ($failFlag) {

            # At least one icon couldn't be created
            return undef;

        } else {

            # All icons created
            return 1;
        }
    }

    sub getTextViewStyle {

        # Can be called by anything
        # Shortcut to $self->setTextViewStyle. Takes the name of colour scheme as an argument, and
        #   calls $self->setTextViewStyle with the correct arguments for that colour scheme
        #
        # Expected arguments
        #   $name       - The name of a colour scheme (matching a key in
        #                   GA::CLIENT->colourSchemeHash). If the colour scheme doesn't exist,
        #                   Axmud default colours/fonts are used
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the return value of the call to $self->setTextViewStyle

        my ($self, $name, $check) = @_;

        # Local variables
        my $obj;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->getTextViewStyle', @_);
        }

        # Get the corresponding colour scheme
        $obj = $axmud::CLIENT->ivShow('colourSchemeHash', $name);
        if (! $obj) {

            return $self->setTextViewStyle();

        } else {

            return $self->setTextViewStyle(
                $axmud::CLIENT->returnRGBColour($obj->textColour),
                $axmud::CLIENT->returnRGBColour($obj->backgroundColour),
                $obj->font,
                $obj->fontSize,
            );
        }
    }

    sub setTextViewStyle {

        # Can be called by anything
        #
        # Gtk2 uses rc files to specify the style (colours and fonts) used in a Gtk2 widget
        #   (Gtk2::TextViews in particular)
        # This function should be called immediately before creating a Gtk2::TextView, so that
        #   the correct colours/fonts are used
        # (To create a textview using the system's preferred colours and fonts, don't call this
        #   function at all; instead, use the subclass GA::Gtk::TextView)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $fgColour   - The RGB colour to use for the foreground text, e.g. '#000000'. If 'undef',
        #                   the Axmud default colour is used
        #   $bgColour   - The RGB colour to use for the background, e.g. '#FFFFFF'. If 'undef', the
        #                   Axmud default colour is used
        #   $font       - The font to use in the new style
        #   $fontSize   - The font size to use in the new style. If either $font or $fontSize are
        #                   'undef', the Axmud default font is used
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $fgColour, $bgColour, $font, $fontSize, $check) = @_;

        # Local variables
        my ($style, $rcString);

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setTextViewStyle', @_);
        }

        # Use Axmud default colours/fonts, if none were specified
        if (! defined $fgColour) {

            $fgColour = $axmud::CLIENT->constTextColour;
        }

        if (! defined $bgColour) {

            $bgColour = $axmud::CLIENT->constBackgroundColour;
        }

        if (! defined $font || ! defined $fontSize) {

            $font = $axmud::CLIENT->constFont;
            $fontSize = $axmud::CLIENT->constFontSize;
        }

        # Prepare the string to use
        $style = $axmud::NAME_SHORT . '_textview';

        $rcString = "style \"" . $style . "\" {\n";

        if ($font && $fontSize) {

            $rcString .= "font_name = \"" . $font . " " . $fontSize . "\"\n";
        }

        if ($fgColour) {

            $rcString .= "text[NORMAL] = \"" . $fgColour . "\"\n";
        }

        if ($bgColour) {

            $rcString .= "base[NORMAL] = \"" . $bgColour . "\"\n"
        }

        $rcString .= "}\n";
        $rcString .= "widget_class \"*TextView\" style \"" . $style . "\"\n";

        # Apply the style
        Gtk2::Rc->parse_string($rcString);

        return 1;
    }

    sub restrictWidgets {

        # Many menu bar and toolbar items can be sensitised, or desensitised, depending on
        #   conditions
        # This function can be called by anything, any time one of those conditions changes, so that
        #   menu bar/toolbar items in all 'internal' windows can be sensitised or desensitised with
        #   a single function call
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

            return $axmud::CLIENT->writeImproper($self->_objClass . '->restrictWidgets', @_);
        }

        foreach my $winObj ($self->ivValues('gridWinHash')) {

            if (
                $winObj->winType eq 'main'
                || $winObj->winType eq 'protocol'
                || $winObj->winType eq 'custom'
            ) {
                # Update menu bars in all 'internal' windows
                $winObj->restrictMenuBars();
                # Update toolbars in all 'internal' windows
                $winObj->restrictToolbars();
            }
        }

        return 1;
    }

    # 'grid' windows

    sub swapGridWin {

        # Called by GA::Cmd::SwapWindow->do or by any other function
        # Swaps the size and position, exactly, of two 'grid' windows, first checking that each is
        #   allowed into the other's zone
        #
        # Expected arguments
        #   $winObj1     - Blessed reference to the first window object (inheriting from
        #                   GA::Generic::GridWin)
        #   $winObj2     - Blessed reference to the second window object
        #
        # Return values
        #   'undef' on improper arguments or if the windows can't be swapped
        #   1 if the swapping operation succeeds

        my ($self, $winObj1, $winObj2, $check) = @_;

        # Local variables
        my ($zoneObj1, $zoneObj2, $holder);

        # Check for improper arguments
        if (! defined $winObj1 || ! defined $winObj2 || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->swapGridWin', @_);
        }

        # Check that each window is a 'grid' window
        if (
            $winObj1->winCategory ne 'grid'
            || ! $self->ivExists('gridWinHash', $winObj1->number)
            || ! $winObj1->areaObj
            || ! $winObj1->areaObj->zoneObj
        ) {
            return $self->writeError(
                'Can\'t swap windows - 1st window is not a \'grid\' window',
                $self->_objClass . '->swapGridWin',
            );

        } else {

            $zoneObj1 = $winObj1->areaObj->zoneObj;
        }

        if (
            $winObj2->winCategory ne 'grid'
            || ! $self->ivExists('gridWinHash', $winObj2->number)
            || ! $winObj2->areaObj
            || ! $winObj2->areaObj->zoneObj
        ) {
            return $self->writeError(
                'Can\'t swap windows - 2nd window is not a \'grid\' window',
                $self->_objClass . '->swapGridWin',
            );

        } else {

            $zoneObj2 = $winObj2->areaObj->zoneObj;
        }

        # Check that each window is allowed in the other's zone - unless they are already in the
        #   same zone, in which case, don't bother
        if ($zoneObj1 ne $zoneObj2) {

            if (
                ! $zoneObj1->checkWinAllowed(
                    $winObj2->winType,
                    $winObj2->winName,
                    $winObj2->session,
                )
            ) {
                return $self->writeError(
                    'Can\'t swap windows - 1st window not allowed in 2nd window\'s zone',
                    $self->_objClass . '->swapGridWin',
                );

            } elsif (
                ! $zoneObj2->checkWinAllowed(
                    $winObj1->winType,
                    $winObj1->winName,
                    $winObj1->session,
                )
            ) {
                return $self->writeError(
                    'Can\'t swap windows - 2nd window not allowed in 1st window\'s zone',
                    $self->_objClass . '->swapGridWin',
                );
            }
        }

        # Add the windows to their new zones
        $holder = $winObj1->workspaceObj;
        $winObj1->set_workspaceObj($winObj2->workspaceObj);
        $winObj2->set_workspaceObj($holder);

        $holder = $winObj1->workspaceGridObj;
        $winObj1->set_workspaceGridObj($winObj2->workspaceGridObj);
        $winObj2->set_workspaceGridObj($holder);

        $holder = $winObj1->areaObj;
        $winObj1->set_areaObj($winObj2->areaObj);
        $winObj1->areaObj->set_win($winObj2);
        $winObj2->set_areaObj($holder);
        $winObj2->areaObj->set_win($winObj1);

        # Move and resize the windows
        $winObj1->workspaceObj->moveResizeWin(
            $winObj1,
            $winObj1->areaObj->xPosPixels,
            $winObj1->areaObj->yPosPixels,
            $winObj1->areaObj->widthPixels,
            $winObj1->areaObj->heightPixels,
        );

        $winObj2->workspaceObj->moveResizeWin(
            $winObj2,
            $winObj2->areaObj->xPosPixels,
            $winObj2->areaObj->yPosPixels,
            $winObj2->areaObj->widthPixels,
            $winObj2->areaObj->heightPixels,
        );

        # Restack the windows in the correct layer
        $winObj1->areaObj->zoneObj->restackWin();
        if ($winObj1->areaObj->zoneObj ne $winObj2->areaObj->zoneObj) {

            $winObj2->areaObj->zoneObj->restackWin();
        }

        # Operation complete
        return 1;
    }

    sub revealGridWins {

        # Called by GA::Session->stop, ->reactDisconnect and GA::Win::Internal->setVisibleSession
        # When a session is made the current session, all of its 'grid' windows on the same
        #   workspace grid as its 'main' window (but not the 'main' window itself) must be made
        #   visible
        # Do nothing if GA::CLIENT->shareMainWinFlag = FALSE, when all sessions have their own
        #   'main' window and share workspace grids
        # If GA::Client->gridInvisWinFlag is TRUE, the windows are made visible after earlier being
        #   made invisible; otherwise they are just restored after being minimised
        #
        # Expected arguments
        #   $session    - The GA::Session whose windows should be made visible
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Local variables
        my (
            $mainWinObj,
            @winObjList,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->revealGridWins', @_);
        }

        if ($axmud::CLIENT->shareMainWinFlag) {

            # Get a list of windows owned by the specified session (but ignore the shared 'main'
            #   window)
            foreach my $winObj ($self->ivValues('gridWinHash')) {

                if (
                    $winObj->winType ne 'main'
                    && $winObj->session
                    && $winObj->session eq $session
                ) {
                    push (@winObjList, $winObj);
                }
            }

            # Perform the action on any windows in @winObjList which are in the same workspace
            #   as the session's 'main' window
            if ($session->mainWin && $session->mainWin->workspaceObj) {

                foreach my $winObj (@winObjList) {

                    if (
                        $winObj->workspaceObj
                        && $winObj->workspaceObj eq $session->mainWin->workspaceObj
                    ) {
                        if ($axmud::CLIENT->gridInvisWinFlag || ! $winObj->wnckWin) {

                            # Make the window visible
                            $winObj->setVisible();

                        } else {

                            # Unminimise the window
                            $winObj->wnckWin->unminimize(time());
                        }
                    }
                }
            }
        }

        return 1;
    }

    sub hideGridWins {

        # Called by GA::Win::Internal->setVisibleSession
        # When a session ceases being the current session, all of its 'grid' windows on the same
        #   workspace grid as its 'main' window (but not the 'main' window itself) must be hidden
        # Do nothing if GA::CLIENT->shareMainWinFlag = FALSE, when all sessions have their own
        #   'main' window and share workspace grids
        # If GA::Client->gridInvisWinFlag is TRUE, the windows are made invisible; otherwise they
        #   are just minimised. However, window objects that don't have their ->wnckWindow set are
        #   always made invisible
        #
        # Expected arguments
        #   $session    - The GA::Session whose windows should be made not visible
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Local variables
        my (
            $mainWinObj,
            @winObjList,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->hideGridWins', @_);
        }

        if ($axmud::CLIENT->shareMainWinFlag) {

            # Get a list of windows owned by the specified session (but ignore the shared 'main'
            #   window)
            foreach my $winObj ($self->ivValues('gridWinHash')) {

                if (
                    $winObj->winType ne 'main'
                    && $winObj->session
                    && $winObj->session eq $session
                ) {
                    push (@winObjList, $winObj);
                }
            }

            # Perform the action on any windows in @winObjList which are in the same workspace
            #   as the session's 'main' window
            if ($session->mainWin && $session->mainWin->workspaceObj) {

                foreach my $winObj (@winObjList) {

                    if (
                        $winObj->workspaceObj
                        && $winObj->workspaceObj eq $session->mainWin->workspaceObj
                    ) {
                        if ($axmud::CLIENT->gridInvisWinFlag || ! $winObj->wnckWin) {

                            # Make the window invisible
                            $winObj->setInvisible();

                        } else {

                            # Minimise the window
                            $winObj->wnckWin->minimize();
                        }
                    }
                }
            }
        }

        return 1;
    }

    sub listGridWins {

        # Returns an ordered list of 'grid' windows of a certain type (or of all 'grid' windows, if
        #   no type is specified)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $type   - A window type, matching a key in GA::Client->constGridWinTypeHash, or the
        #               string 'internal', matching the window types 'main', 'protocol' and
        #               'custom'. If 'undef', all 'grid' windows are returned
        #
        # Return values
        #   An empty list on improper arguments, if $type is not a valid 'grid' window type or if
        #       there are no 'grid' windows of that type open
        #   Otherwise, returns a list of 'grid' windows in the order in which they were created

        my ($self, $type, $check) = @_;

        # Local variables
        my (@emptyList, @list);

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->listGridWins', @_);
            return @emptyList;
        }

        # Check $type is a valid 'grid' window type (or the valid string 'internal')
        if (
            defined $type
            && $type ne 'internal'
            && ! $axmud::CLIENT->ivExists('constGridWinTypeHash', $type)
        ) {
            return @emptyList;
        }

        # Get the list of windows
        foreach my $winObj (sort {$a->number cmp $b->number} ($self->ivValues('gridWinHash'))) {

            if (
                ! defined $type
                || $winObj->winType eq $type
                || (
                    $type eq 'internal'
                    && (
                        $winObj->winType eq 'main'
                        || $winObj->winType eq 'protocol'
                        || $winObj->winType eq 'custom'
                    )
                )
            ) {
                push (@list, $winObj);
            }
        }

        return @list;
    }

    sub listSessionGridWins {

        # Returns an ordered list of 'grid' windows used by the specified session (either the
        #   the window's ->session matches the specified session, or it's a 'main' window for the
        #   specified session)
        #
        # Expected arguments
        #   $session        - The GA::Session which should be matched against 'grid' windows
        #
        # Optional arguments
        #   $internalFlag   - If TRUE, only 'internal' windows ('main', 'protocol' and 'custom'
        #                       windows) are returned. If FALSE or 'undef', 'map' and 'fixed'
        #                       windows are returned too. 'external' windows are never returned
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a list of matching 'grid' windows in the order in which they were
        #       created

        my ($self, $session, $internalFlag, $check) = @_;

        # Local variables
        my (@emptyList, @list);

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->listSessionGridWins', @_);
            return @emptyList;
        }

        # Get the list of windows
        foreach my $winObj (sort {$a->number cmp $b->number} ($self->ivValues('gridWinHash'))) {

            if (
                $winObj->winType ne 'external'
                && (
                    ! $internalFlag
                    || $winObj->winType eq 'main'
                    || $winObj->winType eq 'protocol'
                    || $winObj->winType eq 'custom'
                ) && (
                    ($winObj->session && $winObj->session eq $session)
                    || $session->mainWin eq $winObj
                )
            ) {
                push (@list, $winObj);
            }
        }

        return @list;
    }

    sub claimZones {

        # Called by GA::Obj::Zone->addArea during the process in which a window is moved into a
        #   zone, when GA::CLIENT->shareMainWinFlag = FALSE
        # If the zone's ->ownerString is defined, that zone is reserved for a single session. The
        #   IV's value can be any non-empty string. All zones with the same ->ownerString are
        #   reserved for a particular session
        # The first session to place one of its windows into any 'owned' zone claims all of
        #   those zones for itself. If ->ownerString IV is 'undef', the zone is available for any
        #   session to use (subject to restriction described in the comments in
        #   GA::Obj::Zone->new)
        # This function is called when a window is moved into a zone whose ->ownerString is set, but
        #   whose ->owner shows the zone hasn't been claimed by a session
        # This function checks every zone across all workspace grids, and 'claims' any zone with the
        #   same ->ownerString for the session
        #
        # Expected arguments
        #   $session        - The GA::Session which claims the calling zone object
        #   $ownerString    - That zone's ->ownerString
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 otherwise

        my ($self, $session, $ownerString, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (! defined $session || ! defined $ownerString || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->claimZones', @_);
        }

        # Get a list of zone objects with the same $ownerString
        foreach my $workspaceGridObj ($self->ivValues('gridHash')) {

            foreach my $zoneObj ($workspaceGridObj->ivValues('zoneHash')) {

                if (defined $zoneObj->ownerString && $zoneObj->ownerString eq $ownerString) {

                    push (@list, $zoneObj);

                    if ($zoneObj->owner) {

                        # No zone with this $ownerString should have an ->owner session set, so
                        #   give up with an error message
                        return $axmud::CLIENT->writeError(
                            'General error assigning owners to zones',
                            $self->_objClass . '->claimZones',
                        );
                    }
                }
            }
        }

        # We now have a list of 0, 1 or more zones that can be claimed by the session
        foreach my $zoneObj (@list) {

            $zoneObj->set_owner($session);
        }

        return 1;
    }

    sub relinquishZones {

        # Called by GA::Obj::Zone->removeArea when a window is removed from a zone, and there are
        #   no more windows left in the zone and when GA::CLIENT->shareMainWinFlag = FALSE
        # If the zone's ->ownerString is defined, that zone is reserved for a single session. The
        #   IV's value can be any non-empty string. All zones with the same ->ownerString are
        #   reserved for a particular session
        # The first session to place one of its windows into any 'owned' zone claims all of
        #   those zones for itself. If ->ownerString IV is 'undef', the zone is available for any
        #   session to use (subject to restriction described in the comments in
        #   GA::Obj::Zone->new)
        # This function is called when the zone's ->ownerString and ->owner are both set. It checks
        #   every zone across all workspace grids, counting how many windows are in zones with the
        #   same ->ownerString. If there are none, it 'relinquishes' all of these zones for use by a
        #   different session
        #
        # Expected arguments
        #   $ownerString    - The calling zone's ->ownerString
        #
        # Return values
        #   'undef' on improper arguments or if there's an error
        #   1 otherwise

        my ($self, $ownerString, $check) = @_;

        # Local variables
        my @list;

        # Check for improper arguments
        if (! defined $ownerString || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->relinquishZones', @_);
        }

        # Get a list of zone objects with the same $ownerString
        foreach my $workspaceGridObj ($self->ivValues('gridHash')) {

            foreach my $zoneObj ($workspaceGridObj->ivValues('zoneHash')) {

                if (defined $zoneObj->ownerString && $zoneObj->ownerString eq $ownerString) {

                    push (@list, $zoneObj);

                    if (! $zoneObj->owner) {

                        # All zones with this $ownerString should have an ->owner session set, so
                        #  give up with an error message
                        return $axmud::CLIENT->writeError(
                            'General error relinquishing zones from their owners',
                            $self->_objClass . '->relinquishZones',
                        );
                    }
                }
            }
        }

        # We have a list of 0, 1 or more zones that can be relinquished
        foreach my $zoneObj (@list) {

            $zoneObj->reset_owner();
        }

        return 1;
    }

    sub convertSpareMainWin {

        # Called by GA::Session->setMainWin
        # When there are no sessions, the single 'main' window is called a spare 'main' window
        # When a new session starts, the spare 'main' window must be converted into a normal
        #   'main' window (owned by a session, not by the GA::Client, and using a winmap that's
        #   not 'main_wait')
        #
        # Expected arguments
        #   $session    - The calling GA::Session
        #   $winObj     - The existing spare 'main' window object
        #
        # Optional arguments
        #   $winmap     - The winmap to use. Set only if a winmap has been marked as the default
        #                   winmap for this world; otherwise 'undef'
        #
        # Return values
        #   'undef' on improper arguments or if the spare 'main' window can't be converted
        #   1 otherwise

        my ($self, $session, $winObj, $winmap, $check) = @_;

        # Local variables
        my ($winmapObj, $successFlag);

        # Check for improper arguments
        if (! defined $session || ! defined $winObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->convertSpareMainWin', @_);
        }

        # Update IVs
        $winObj->set_owner($session);
        $winObj->set_session($session);

        # Position it on a workspace grid (if grids are activated generally)
        if ($axmud::CLIENT->activateGridFlag && $self->gridPermitFlag) {

            OUTER: foreach my $workspaceObj ($axmud::CLIENT->desktopObj->listWorkspaces()) {

                foreach my $gridObj (
                    sort {$a->number <=> $b->number} ($workspaceObj->ivValues('gridHash'))
                ) {
                    if ($gridObj->repositionGridWin($winObj)) {

                        # 'main' window repositioned. Decide which winmap to use, if none was
                        #   specified by the calling function
                        if (! $winmap) {

                            # Use the default winmap for the window's new zone
                            $winmapObj = $winObj->workspaceObj->getWinmap(
                                'main',
                                undef,
                                $winObj->areaObj->zoneObj,
                            );

                            $winmap = $winmapObj->name;
                        }

                        # ->repositionGridWin is also called by
                        #   GA::Obj::WorkspaceGrid->applyZonemap, so its ->gridWinHash IV hasn't
                        #   been modified
                        $gridObj->add_gridWin($winObj);
                        # Window IVs must also be updated
                        $winObj->set_workspaceGridObj($gridObj);
                        $winObj->set_workspaceObj($gridObj->workspaceObj);

                        $self->updateWidgets($self->_objClass . '->convertSpareMainWin');

                        # Position operation complete
                        $successFlag = TRUE;
                        last OUTER;
                    }
                }
            }

            if (! $successFlag) {

                # Could not position the 'main' window on any workspace grid, for some reason
                return undef;
            }
        }

        # Reset the window's winmap
        if (! $winmap) {

            if ($axmud::CLIENT->activateGridFlag) {
                $winmap = $axmud::CLIENT->constDefaultEnabledWinmap;
            } else {
                $winmap = $axmud::CLIENT->constDefaultDisabledWinmap;
            }
        }

        $winObj->resetWinmap($winmap);

        return 1;
    }

    sub deconvertSpareMainWin {

        # Called by GA::Session->stop
        # When a session terminates and there are no sessions left, the last remaining 'main'
        #   window must be converted into a spare 'main' window (owned by GA::Client, not a session,
        #   and using the 'main_wait' winmap)
        #
        # Expected arguments
        #   $winObj     - The existing spare 'main' window object
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $winObj, $check) = @_;

        # Check for improper arguments
        if (! defined $winObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deconvertSpareMainWin', @_);
        }

        $winObj->resetWinmap('main_wait');
        $winObj->set_owner($axmud::CLIENT);
        $winObj->set_session();

        $self->updateWidgets($self->_objClass . '->deconvertSpareMainWin');

        # Operation complete
        return 1;
    }

    # 'free' windows

    sub listFreeWins {

        # Returns an ordered list of 'free' windows of a certain type (or of all 'free' windows, if
        #   no type is specified)
        # NB 'dialogue' windows are not stored in this object's IVs, and are not returned in the
        #   list
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $type   - A window type, matching a key in GA::Client->constFreeWinTypeHash. If 'undef',
        #               all 'free' windows except 'dialogue' windows are returned
        #
        # Return values
        #   An empty list on improper arguments, if $type is not a valid 'free' window type or if
        #       there are no 'free' windows of that type open
        #   Otherwise, returns a list of 'free' windows in the order in which they were created

        my ($self, $type, $check) = @_;

        # Local variables
        my (@emptyList, @list);

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->listFreeWins', @_);
            return @emptyList;
        }

        # Check $type is a valid 'free' window type
        if (
            defined $type
            && ! $axmud::CLIENT->ivExists('constFreeWinTypeHash', $type)
        ) {
            return @emptyList;
        }

        # Get the list of windows
        foreach my $winObj (sort {$a->number <=> $b->number} ($self->ivValues('freeWinHash'))) {

            if (! defined $type || $winObj->winType eq $type) {

                push (@list, $winObj);
            }
        }

        return @list;
    }

    sub listSessionFreeWins {

        # Returns an ordered list of 'free' windows used by the specified session (when the
        #   the window's ->session matches the specified session; does not include 'dialogue'
        #   windows)
        #
        # Expected arguments
        #   $session        - The GA::Session which should be matched against 'free' windows
        #
        # Optional arguments
        #   $singleFlag     - If set to TRUE, this functions gives up when it finds the first
        #                       matching window, returning a list containing just that window;
        #                       if set to FALSE (or 'undef'), a list of all matching windows are
        #                       returned
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, returns a list of matching 'free' windows in the order in which they were
        #       created

        my ($self, $session, $singleFlag, $check) = @_;

        # Local variables
        my (@emptyList, @list);

        # Check for improper arguments
        if (defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->listSessionFreeWins', @_);
            return @emptyList;
        }

        # Get the list of windows
        foreach my $winObj (sort {$a->number <=> $b->number} ($self->ivValues('freeWinHash'))) {

            if ($winObj->session && $winObj->session eq $session) {

                push (@list, $winObj);

                if ($singleFlag) {

                    # Calling function doesn't care how many matching windows there are, only that
                    #   there is at least one
                    return @list;
                }
            }
        }

        return @list;
    }

    # Widgets

    sub updateWidgets {

        # Can be called by anything. Updates Gtk2's events queue
        # Used for debugging, so that we can track all lines of code like this, if we need to:
        #   Gtk2->main_iteration() while Gtk2->events_pending();
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $string    - For debugging purposes. Describes the calling function, e.g.
        #                   ->updateWidgets($self->_objClass . '->callingFunction');
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $string, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateWidgets', @_);
        }

        # Update Gtk2's events queue
        Gtk2->main_iteration() while Gtk2->events_pending();

        # Optionally, write information about the calling function to the terminal (for debugging)
#        if ($string) {
#
#           print "->updateWidgets() call from " . $string . " at " . $axmud::CLIENT->getTime()
#               . "\n";
#
#        } else {
#
#           print "->updateWidgets() call from unspecified function at " . $axmud::CLIENT->getTime()
#               . "\n";
#        }

        return 1
    }

    sub removeWidget {

        # Can be called by anything
        # Calls to a Gtk2 widgets ->remove function will cause a crash, if the child is no longer
        #   inside its parent
        # This function checks the child is inside its parent and, if so, calls the ->remove
        #   function; otherwise it does nothing
        #
        # Expected arguments
        #   $parent     - The parent Gtk2 widget
        #   $child      - The child Gtk2 widget
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $parent, $child, $check) = @_;

        # Check for improper arguments
        if (! defined $parent || ! defined $child || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->removeWidget', @_);
        }

        OUTER: foreach my $widget ($parent->get_children()) {

            if ($widget eq $child) {

                $parent->remove($child);
                return 1;
            }
        }

        return 1;
    }

    sub bufferGetText {

        # Can be called by anything
        # Gets the entire text displayed in a Gtk2::TextView from its Gtk2::TextBuffer and returns
        #   it as a string, often containing newline characters
        #
        # Expected arguments
        #   $buffer     - The Gtk2::TextBuffer whose text should be extracted
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns the buffer's contents as a string (may be an empty string)

        my ($self, $buffer, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->bufferGetText', @_);
        }

        return $buffer->get_text(
            $buffer->get_start_iter(),
            $buffer->get_end_iter(),
            # Include hidden chars
            TRUE,
        );
    }

    ##################
    # Accessors - set

    sub add_freeWin {

        # Called by GA::Generic::Win->createFreeWin

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_freeWin', @_);
        }

        # ($self->freeWinCount is already the same as $winObj->number)
        $self->ivAdd('freeWinHash', $self->freeWinCount, $obj);
        $self->ivIncrement('freeWinCount');

        return 1;
    }

    sub del_freeWin {

        # Called by GA::Generic::FreeWin->winDestroy

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_freeWin', @_);
        }

        if (! $self->ivExists('freeWinHash', $obj->number)) {

            return undef;

        } else {

            $self->ivDelete('freeWinHash', $obj->number);

            return 1;
        }
    }

    sub add_grid {

        # Called by GA::Obj::Workspace->addWorkspaceGrid
        #
        # Expected arguments
        #   $workspaceObj   - The calling workspace object
        #
        # Optional arguments
        #   $session        - (GA::Client->shareMainWinFlag = TRUE) The GA::Session object which
        #                       controls this workspace grid
        #                   - (GA::Client->shareMainWinFlag = FALSE) 'undef' (the grid is shared
        #                       between all sessions)

        my ($self, $workspaceObj, $session, $check) = @_;

        # Local variables
        my $gridObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_grid', @_);
        }

        $gridObj = Games::Axmud::Obj::WorkspaceGrid->new($self->gridCount, $workspaceObj, $session);
        if (! $gridObj) {

            return undef;

        } else {

            $self->ivAdd('gridHash', $self->gridCount, $gridObj);
            $self->ivIncrement('gridCount');

            return $gridObj;
        }
    }

    sub del_grid {

        # Called by GA::Obj::Workspace->removeWorkspaceGrid
        #
        # Expected arguments
        #   $obj        - The workspace grid object to remove
        #
        # Optional arguments
        #   $session    - If defined, that session's 'main' window is disengaged (removed from its
        #                   workspace grid, but not destroyed)

        my ($self, $obj, $session, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_grid', @_);
        }

        if (! $self->ivExists('gridHash', $obj->number)) {

            return undef;

        } else {

            $obj->stop($session);

            $self->ivDelete('gridHash', $obj->number);

            return 1;
        }
    }

    sub add_gridWin {

        # Called by GA::Obj::Workspace->createGridWin, ->createSimpleGridWin

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_gridWin', @_);
        }

        # ($self->gridWinCount is already the same as $winObj->number)
        $self->ivAdd('gridWinHash', $self->gridWinCount, $obj);
        $self->ivIncrement('gridWinCount');

        return 1;
    }

    sub del_gridWin {

        # Called by GA::Win::Internal->winDestroy, etc

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_gridWin', @_);
        }

        if (! $self->ivExists('gridWinHash', $obj->number)) {

            return undef;

        } else {

            $self->ivDelete('gridWinHash', $obj->number);

            return 1;
        }
    }

    sub add_textView {

        # Can be called by anything, most commonly by GA::Table::Pane->addTab and
        #   ->addSimpleTab

        my ($self, $session, $winObj, $paneObj, $check) = @_;

        # Local variables
        my $textViewObj;

        # Check for improper arguments
        if (! defined $session || ! defined $winObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_textView', @_);
        }

        $textViewObj
            = Games::Axmud::Obj::TextView->new($session, $self->textViewCount, $winObj, $paneObj);

        if (! $textViewObj) {

            return undef;

        } else {

            $self->ivAdd('textViewHash', $textViewObj->number, $textViewObj);
            $self->ivIncrement('textViewCount');

            return $textViewObj;
        }
    }

    sub del_textView {

        # GA::Obj::TextView->objDestroy

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_textView', @_);
        }

        if (! $self->ivExists('textViewHash', $obj->number)) {

            return undef;

        } else {

            $self->ivDelete('textViewHash', $obj->number);

            return 1;
        }
    }

    sub add_workspace {

        # Called by $self->start and $self->setupWorkspaces
        my ($self, $workspace, $screen, $check) = @_;

        # Local variables
        my $workspaceObj;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->add_workspace', @_);
        }

        $workspaceObj
            = Games::Axmud::Obj::Workspace->new($self->workspaceCount, $workspace, $screen);

        if (! $workspaceObj) {

            return undef;

        } else {

            $self->ivAdd('workspaceHash', $self->workspaceCount, $workspaceObj);
            $self->ivIncrement('workspaceCount');

            return $workspaceObj;
        }
    }

    sub del_workspace {

        # Called by $self->stop and ->setupWorkspaces

        my ($self, $obj, $check) = @_;

        # Check for improper arguments
        if (! defined $obj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->del_workspace', @_);
        }

        # (Workspace from which Axmud was launched cannot be deleted by this function, but is
        #   deleted directly by $self->stop)
        if ($obj->number == 0 || ! $self->ivExists('workspaceHash', $obj->number)) {

            return undef;

        } else {

            $obj->stop();

            $self->ivDelete('workspaceHash', $obj->number);

            return 1;
        }
    }

    ##################
    # Accessors - get

    sub workspaceHash
        { my $self = shift; return %{$self->{workspaceHash}}; }
    sub workspaceCount
        { $_[0]->{workspaceCount} }
    sub defaultWorkspaceObj
        { $_[0]->{defaultWorkspaceObj} }
    sub defaultWorkspace
        { $_[0]->{defaultWorkspace} }

    sub gridHash
        { my $self = shift; return %{$self->{gridHash}}; }
    sub gridCount
        { $_[0]->{gridCount} }

    sub gridWinHash
        { my $self = shift; return %{$self->{gridWinHash}}; }
    sub gridWinCount
        { $_[0]->{gridWinCount} }

    sub freeWinHash
        { my $self = shift; return %{$self->{freeWinHash}}; }
    sub freeWinCount
        { $_[0]->{freeWinCount} }

    sub textViewHash
        { my $self = shift; return %{$self->{textViewHash}}; }
    sub textViewCount
        { $_[0]->{textViewCount} }

    sub gridPermitFlag
        { $_[0]->{gridPermitFlag} }
    sub newWorkspaceFlag
        { $_[0]->{newWorkspaceFlag} }

    sub mainWinIconList
        { my $self = shift; return @{$self->{mainWinIconList}}; }
    sub mapWinIconList
        { my $self = shift; return @{$self->{mapWinIconList}}; }
    sub protocolWinIconList
        { my $self = shift; return @{$self->{protocolWinIconList}}; }
    sub fixedWinIconList
        { my $self = shift; return @{$self->{fixedWinIconList}}; }
    sub customWinIconList
        { my $self = shift; return @{$self->{customWinIconList}}; }
    sub externalWinIconList
        { my $self = shift; return @{$self->{externalWinIconList}}; }

    sub viewerWinIconList
        { my $self = shift; return @{$self->{viewerWinIconList}}; }
    sub editWinIconList
        { my $self = shift; return @{$self->{editWinIconList}}; }
    sub prefWinIconList
        { my $self = shift; return @{$self->{prefWinIconList}}; }
    sub wizWinIconList
        { my $self = shift; return @{$self->{wizWinIconList}}; }
    sub dialogueWinIconList
        { my $self = shift; return @{$self->{dialogueWinIconList}}; }
    sub otherWinIconList
        { my $self = shift; return @{$self->{otherWinIconList}}; }
}

# Package must return true
1
