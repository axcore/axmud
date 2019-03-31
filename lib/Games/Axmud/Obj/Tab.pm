# Copyright (C) 2011-2019 A S Lewis
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
# Games::Axmud::Obj::Tab
# Tab objects, used by pane objects (GA::Table::Pane) to store details about the tab(s) it
#   contains

{ package Games::Axmud::Obj::Tab;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Table::Pane->addSimpleTab and ->addTab
        # Creates the GA::Obj::Tab, used by pane objects (GA::Table::Pane) to store details about
        #   the tab(s) it contains
        #
        # Expected arguments
        #   $number         - Unique number of this tab within the parent pane object
        #   $paneObj        - The parent GA::Table::Pane object
        #   $session        - The GA::Session which controls this tab
        #   $defaultFlag    - Flag set to TRUE if the textview object (GA::Obj::Textview) for this
        #                       tab will be $self->session's default textview object (where text
        #                       received from the world is usually displayed), FALSE otherwise
        #   $textViewObj    - The textview object  that handles the widgets contained in this tab
        #   $packableObj    - The textview object packs a single widget (a Gtk3::TextView or a
        #                       Gtk3::VPaned) into a Gtk3::ScrolledWindow. The Gtk3::ScrolledWindow
        #   $packedObj      - The single widget packed into the Gtk3::ScrolledWindow
        #
        # Optional arguments
        #   $tabWidget      - For 'normal' tabs, the widget that is added to a page in the
        #                       Gtk3::Notebook (a Gtk3::VBox). Set to 'undef' for simple tabs
        #   $tabLabel       - For 'normal' tabs, the Gtk3::Label used. Set to 'undef' for simple
        #                       tabs
        #
        # Return values
        #   'undef' on improper arguments
        #   Blessed reference to the newly-created object on success

        my (
            $class, $number, $paneObj, $session, $defaultFlag, $textViewObj, $packableObj,
            $packedObj, $tabWidget, $tabLabel, $check,
        ) = @_;

        # Local variables
        my $flag;

        # Check for improper arguments
        if (! defined $class || ! defined $paneObj || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Use TRUE or FALSE
        if (! $defaultFlag) {
            $flag = FALSE;
        } else {
            $flag = TRUE;
        }

        # Setup
        my $self = {
            _objName                    => 'tab',
            _objClass                   => $class,
            _parentFile                 => undef,       # No parent file object
            _parentWorld                => undef,       # No parent file object
            _privFlag                   => TRUE,        # All IVs are private

            # IVs
            # ---

            # Unique number of this tab within the parent pane object
            number                      => $number,
            # The parent GA::Table::Pane object
            paneObj                     => $paneObj,
            # The GA::Session which controls this tab
            session                     => $session,
            # Flag set to TRUE if the textview object (GA::Obj::Textview) for this tab will be
            #   $self->session's default textview object (where text received from the world is
            #   usually displayed), FALSE otherwise
            defaultFlag                 => $flag,
            # The textview object  that handles the widgets contained in this tab
            textViewObj                 => $textViewObj,

            # The textview object packs a single widget (a Gtk3::TextView or a Gtk3::VPaned) into
            #   a Gtk3::ScrolledWindow. The Gtk3::ScrolledWindow
            packableObj                 => $packableObj,
            # The single widget packed into the Gtk3::ScrolledWindow
            packedObj                   => $packedObj,

            # For 'normal' tabs, the widget that is added to a page in the Gtk3::Notebook (a
            #   Gtk3::VBox). Set to 'undef' for simple tabs
            tabWidget                   => $tabWidget,
            # For 'normal' tabs, the Gtk3::Label used. Set to 'undef' for simple tabs
            tabLabel                    => $tabLabel,
        };

        # Bless the object into existence
        bless $self, $class;

        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub number
        { $_[0]->{number} }
    sub paneObj
        { $_[0]->{paneObj} }
    sub session
        { $_[0]->{session} }
    sub defaultFlag
        { $_[0]->{defaultFlag} }
    sub textViewObj
        { $_[0]->{textViewObj} }

    sub packableObj
        { $_[0]->{packableObj} }
    sub packedObj
        { $_[0]->{packedObj} }

    sub tabWidget
        { $_[0]->{tabWidget} }
    sub tabLabel
        { $_[0]->{tabLabel} }
}

# Package must return a true value
1
