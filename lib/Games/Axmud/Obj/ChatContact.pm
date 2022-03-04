# Copyright (C) 2011-2022 A S Lewis
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
# Games::Axmud::Obj::ChatContact
# Stores a chat contact

{ package Games::Axmud::Obj::ChatContact;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Creates a new instance of the chat contact object
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $name       - A unique string name for this chat contact (max 16 chars, containing
        #                   A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable.
        #                   Must not exist as a key in the global hash of reserved names,
        #                   GA::CLIENT->constReservedHash)
        #   $protocol   - Which chat protocol to use by default with this contact (currently 0 for
        #                   MudMaster, 1 for zChat)
        #
        # Optional arguments
        #   $ip         - The contact's advertised IP address ('undef' if not advertised)
        #   $port       - The contact's advertised port ('undef' if not advertised)
        #   $email      - The contact's advertised email ('undef' if none)
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $protocol, $ip, $port, $email, $check) = @_;

        # Local variables
        my $path;

        # Check for improper arguments
        if (! defined $class || ! defined $session || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        # Check that $name is valid and not already in use by another chat contact
        if (! $axmud::CLIENT->nameCheck($name, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $class . '->new',
            );

        } elsif ($axmud::CLIENT->ivExists('chatContactHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: there is already a chat contact called \'' . $name . '\'',
                $class . '->new',
            );
        }

        # Make sure $protocol is '0' or '1' (which matches a key in GA::Task::Chat->constOptHash)
        if (! $protocol) {
            $protocol = 0;      # MudMaster protocol
        } else {
            $protocol = 1;      # zChat protocol
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'contacts',
            _parentWorld                => undef,
            _privFlag                   => FALSE,        # All IVs are public

            # IVs
            # ---

            #  A unique name for the chat contact (hopefully the same one that the contacts
            #   themselves are broadcasting) (max 16 chars, containing A-Za-z0-9_ - 1st char can't
            #   be number, non-Latin alphabets acceptable. Must not exist as a key in the global
            #   hash of reserved names, GA::CLIENT->constReservedHash)
            name                        => $name,
            # Which chat protocol to use by default with this contact (currently 0 for MudMaster, 1
            #   for zChat)
            protocol                    => $protocol,
            # Contact's advertised IP address ('undef' if not advertised)
            ip                          => $ip,
            # Contact's advertised port ('undef' if not advertised)
            port                        => $port,
            # Contact's advertised email ('undef' if not advertised)
            email                       => $email,

            # The last icon send by the contact - set to a Gtk3::Gdk::Pixbuf
            lastIcon                    => undef,       # Set below
            # A scaled copy of the last icon (at size 16x16) for use in the 'edit' window's simple
            #   list
            lastIconScaled              => undef,       # Set below
        };

        # Bless the object into existence
        bless $self, $class;

        # Create a Gtk3::Gdk::Pixbuf for the icon to be used as the chat contact's default icon
        $path = $axmud::SHARE_DIR . $axmud::CLIENT->constChatContactIcon;
        if (-e $path) {

            my $pixBuffer = Gtk3::Gdk::Pixbuf->new_from_file($path);
            if ($pixBuffer) {

                # Create a scaled copy of this icon
                my $pixBuffer2 = Gtk3::Gdk::Pixbuf->new_from_file_at_scale($path, 16, 16, 1);
                if ($pixBuffer2) {

                    # Update IVs
                    $self->{lastIcon} = $pixBuffer;
                    $self->{lastIconScaled} = $pixBuffer2;
                }
            }
        }

        return $self;
    }

    ##################
    # Methods

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }
    sub protocol
        { $_[0]->{protocol} }
    sub ip
        { $_[0]->{ip} }
    sub port
        { $_[0]->{port} }
    sub email
        { $_[0]->{email} }

    sub lastIcon
        { $_[0]->{lastIcon} }
    sub lastIconScaled
        { $_[0]->{lastIconScaled} }
}

# Package must return a true value
1
