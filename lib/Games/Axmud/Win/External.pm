# Copyright (C) 2011-2024 A S Lewis
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
# Games::Axmud::Win::External
# Object handling 'external' windows (any window that can be placed on the workspace grid, but which
#   is not created/controlled by Axmud). Doesn't include 'free' windows

{ package Games::Axmud::Win::External;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(
        Games::Axmud::Generic::GridWin Games::Axmud::Generic::Win Games::Axmud
    );

    ##################
    # Constructors

    sub new {

        # Called by GA::Obj::Workspace->createGridWin and ->createSimpleGridWin
        # Creates an 'external' 'grid' window (any window that can be placed on the workspace grid,
        #   but which is not created/controlled by Axmud)
        #
        # Expected arguments
        #   $number     - Unique number for this window object
        #   $winType    - The window type, must be 'external'
        #   $winName    - The 'external' window's name (e.g. 'Notepad')
        #   $workspaceObj
        #               - The GA::Obj::Workspace object for the workspace in which this window is
        #                   created
        #
        # Optional arguments
        #   $owner      - The owner, if known. Can be any blessed reference, typically it's an
        #                   GA::Session or a task (inheriting from GA::Generic::Task); could also
        #                   be GA::Client
        #   $session    - The owner's session. If $owner is a GA::Session, that session. If it's
        #                   something else (like a task), the task's session. If $owner is 'undef',
        #                   so is $session
        #   $workspaceGridObj
        #               - The GA::Obj::WorkspaceGrid object into whose grid this window has been
        #                   placed. 'undef' in $workspaceObj->gridEnableFlag = FALSE
        #   $areaObj    - The GA::Obj::Area (a region of a workspace grid zone) which handles this
        #                   window. 'undef' in $workspaceObj->gridEnableFlag = FALSE
        #   $winmap     - On calls to GA::Win::Internal->new, this argument describes the ->name
        #                   of an a GA::Obj::Winmap object. 'external' windows don't use winmaps
        #                   so, if specified, this argument is ignored
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $winType, $winName, $workspaceObj, $owner, $session, $workspaceGridObj,
            $areaObj, $winmap, $check,
        ) = @_;

        # Check for improper arguments
        if (
            ! defined $class || ! defined $number || ! defined $winType || ! defined $winName
            || ! defined $workspaceObj || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that the $winType is valid
        if ($winType ne 'external') {

            return $axmud::CLIENT->writeError(
                'Internal window error: invalid \'external\' window type \'' . $winType . '\'',
                $class . '->new',
            );
        }

        # Setup
        my $self = {
            _objName                    => 'external_win_' . $number,
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # Standard window object IVs
            # --------------------------

            # Unique number for this window object
            number                      => $number,
            # The window category - 'grid' or 'free'
            winCategory                 => 'grid',
            # The window type, must be 'external'
            winType                     => $winType,
            # The external window's name (e.g. 'Notepad')
            winName                     => $winName,
            # The GA::Obj::Workspace object for the workspace in which this window is created
            workspaceObj                => $workspaceObj,
            # The owner, if known ('undef' if not). If set, can be any blessed reference, typically
            #   it's a GA::Session or a task (inheriting from GA::Generic::Task). When there are
            #   no sessions running but there's a single 'main' window open, the owner is the
            #   GA::Client. When the window closes, the owner is informed via a call to its
            #   ->del_winObj function
            owner                       => $owner,
            # The owner's session ('undef' if not). If ->owner is a GA::Session, that session. If
            #   it's something else (like a task), the task's sesssion. If ->owner is 'undef', so is
            #   ->session
            session                     => $session,
            # When GA::Session->pseudoCmd is called to execute a client command, the mode in which
            #   it should be called (usually 'win_error' or 'win_only', which causes errors to be
            #   displayed in a 'dialogue' window)
            pseudoCmdMode               => 'win_error',

            # The window widget. For most window objects, the Gtk3::Window. For pseudo-windows, the
            #   parent 'main' window's Gtk3::Window
            # The code should use this IV when it wants to do something to the window itself
            #   (minimise it, make it active, etc)
            winWidget                   => undef,
            # The window container. For most window objects, the Gtk3::Window. For pseudo-windows,
            #   the parent GA::Table::PseudoWin table object
            # The code should use this IV when it wants to add, modify or remove widgets inside the
            #   window itself
            winBox                      => undef,
            # Flag set to TRUE if the window actually exists (after a call to $self->winEnable),
            #   FALSE if not
            enabledFlag                 => FALSE,
            # Flag set to TRUE if the Gtk3 window itself is visible (after a call to
            #   $self->setVisible), FALSE if it is not visible (after a call to $self->setInvisible)
            visibleFlag                 => TRUE,
            # Registry hash of 'free' windows for which this window is the parent (always empty,
            #   because 'external' windows can be a parent window to a 'free' window)
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

            # The container widget into which all other widgets are packed (not required for an
            #   'external' window)
            packingBox                  => undef,

            # Standard IVs for 'grid' windows

            # The GA::Obj::WorkspaceGrid object into whose grid this window has been placed. 'undef'
            #   in $workspaceObj->gridEnableFlag = FALSE
            workspaceGridObj            => $workspaceGridObj,
            # The GA::Obj::Area object for this window. An area object is a part of a zone's
            #   internal grid, handling a single window (this one). Set to 'undef' in
            #   $workspaceObj->gridEnableFlag = FALSE
            areaObj                     => $areaObj,
            # For pseudo-windows (in which a window object is created, but its widgets are drawn
            #   inside a GA::Table::PseudoWin table object), the table object created. Always
            #   'undef' for 'external' windows which can't be pseudo-windows
            pseudoWinTableObj           => undef,
            # The name of the GA::Obj::Winmap object that specifies the Gtk3::Window's layout when
            #   it is first created. Always 'undef' for 'external' windows
            winmap                      => undef,

            # Standard IVs for 'external' windows

            # The X11::WMCtrl internal ID for this window
            internalID                  => undef,
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    sub winSetup {

        # Called by GA::Obj::Workspace->createGridWin or ->createSimpleGridWin
        # The actual window already exists, but we still need to update IVs
        #
        # Expected arguments
        #   $internalID     - The X11::WMCtrl internal ID for this window
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $internalID, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winSetup', @_);
        }

        # Update IVs
        $self->ivPoke('internalID', $internalID);

        return 1;
    }

    sub winEnable {

        # Called by GA::Obj::Workspace->createGridWin or ->createSimpleGridWin
        # Used for consistency with 'internal' windows
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   $listRef    - Reference to a list of functions for 'internal' windows. If specified,
        #                   ignored
        #
        # Return values
        #   'undef' on improper arguments
        #   1 on success

        my ($self, $listRef, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->winEnable', @_);
        }

        # Update IVs to be consistent with 'internal' windows
        $self->ivPoke('enabledFlag', TRUE);

        return 1;
    }

    sub winDisengage {

        # Called by GA::Cmd->BanishWindow->do
        #
        # Destroys the window object, but not the window itself, leaving the 'external' window free
        #   to pursue its own dreams
        # Marks the area of the zone the window used to occupy as free, and available for other
        #   workspace grid windows
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the window has already been disengaged in a previous
        #       call to this function
        #   1 if the window is disengaged

        my ($self, $check) = @_;

        # Local variables
        my ($zoneObj, $flag);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->winDisengage', @_);
        }

        if (! $self->internalID) {

            # Window already disengaged in a previous call to this function
            return undef;
        }

        # 'External' windows can't have child windows. But, the IV storing child windows exists, so
        #   in case someone decides to add some child windows anyway, close them
        foreach my $winObj ($self->ivValues('childFreeWinHash')) {

            $winObj->winDestroy();
        }

        # Inform the parent workspace grid object (if any)
        if ($self->workspaceGridObj) {

            $self->workspaceGridObj->del_gridWin($self);
        }

        # Inform the desktop object
        $axmud::CLIENT->desktopObj->del_gridWin($self);

        # Look for other 'grid' windows (besides this one) handling the same 'external' window. If
        #   there are none, it's safe to minimise the 'external' window
        if (defined $self->internalID) {

            OUTER: foreach my $winObj ($axmud::CLIENT->desktopObj->ivValues('gridWinHash')) {

                if (
                    $winObj->winType eq 'external'
                    && $self->internalID
                    && $winObj->internalID
                    && $self->internalID eq $winObj->internalID
                ) {
                    $flag = TRUE;
                    last OUTER;
                }
            }

            if (! $flag) {

                # Minimise the window so that, visually, it appears to have been removed from
                #   Axmud's control
                $self->minimise();
            }
        }

        # Operation complete
        $self->ivUndef('internalID');

        return 1;
    }

    sub winDestroy {

        # Called by ->signal_connects in $self->setDeleteEvent and ->setWindowClosedEvent
        # Marks the area of the zone the window used to occupy as free, and available for other
        #   workspace grid windows
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the window has already been disengaged in a previous
        #       call to this function
        #   1 if the window is disengaged

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->winDestroy', @_);
        }

        if (! $self->internalID) {

            # Window already disengaged in a previous call to this function
            return undef;
        }

        # 'External' windows can't have child windows. But, the IV storing child windows exists,
        #   so in case someone decides to add some child windows anyway, close them
        foreach my $winObj ($self->ivValues('childFreeWinHash')) {

            $winObj->winDestroy();
        }

        # Inform the parent workspace grid object (if any)
        if ($self->workspaceGridObj) {

            $self->workspaceGridObj->del_gridWin($self);
        }

        # Inform the desktop object
        $axmud::CLIENT->desktopObj->del_gridWin($self);

        # Inform the ->owner, if there is one
        if ($self->owner) {

            $self->owner->del_winObj($self);
        }

        # Operation complete
        $self->ivUndef('internalID');

        return 1;
    }

#   sub winShowAll {}       # Inherited from GA::Generic::Win

#   sub drawWidgets {}      # Inherited from GA::Generic::Win

#   sub redrawWidgets {}    # Inherited from GA::Generic::Win

    # ->signal_connects

    sub setDeleteEvent {

        # Called by $self->winEnable
        # Does nothing (there is no way to detect that the 'external' window has closed)
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $winBox, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setDeleteEvent', @_);
        }

        # (Do nothing)

        return 1;
    }

    sub setWindowClosedEvent {

        # Called by $self->winEnable
        # Does nothing (there is no way to detect that the 'external' window has closed)
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

             return $axmud::CLIENT->writeImproper($self->_objClass . '->setWindowClosedEvent', @_);
        }

        # (Do nothing)

        return 1;
    }

    # Other functions

    sub minimise {

        # Can be called by anything
        # Minimises the 'external' window
        #
        # NB The author of X11::WMCtrl reports that 'Currently minimize() and unminimize() don't
        #   work. This appears to be a problem with wmctrl itself'
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the window can't be minimised
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->minimise', @_);
        }

        if (! $self->internalID) {

            return undef;

        } else {

            # Unmaximise the window
            $axmud::CLIENT->desktopObj->wmCtrlObj->wmctrl(
                '-r',
                $self->internalID,
                '-i',
                '-b',
                'remove,maximised_vert,maximised_horz',
            );

            # Then minimise it
            $axmud::CLIENT->desktopObj->wmCtrlObj->wmctrl(
                '-r',
                $self->internalID,
                '-i',
                '-b',
                'add,hidden',
            );

            return 1
        }
    }

    sub unminimise {

        # Can be called by anything
        # Unminimises the 'external' window
        #
        # NB The author of X11::WMCtrl reports that 'Currently minimize() and unminimize() don't
        #   work. This appears to be a problem with wmctrl itself'
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments or if the window can't be unminimised
        #   1 otherwise

        my ($self, $check) = @_;

        # Check for improper arguments
        if (defined $check) {

             return $axmud::CLIENT->writeImproper($self->_objClass . '->unminimise', @_);
        }

        if (! $self->internalID) {

            return undef;

        } else {

            # Unminimise the window
            $axmud::CLIENT->desktopObj->wmCtrlObj->wmctrl(
                '-r',
                $self->internalID,
                '-i',
                '-b',
                'remove,hidden',
            );

            return 1;
        }
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub internalID
        { $_[0]->{internalID} }
}

# Package must return a true value
1
