# Copyright 2004 by the Gtk3-Perl team
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU
# Lesser Public License as published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser Public License for more details.
#
# You should have received a copy of the GNU Lesser Public License along with this program. If not,
# see <http://www.gnu.org/licenses/>.
#
#
# Games::Axmud::Obj::WMCtrl, a modification of X11::WMCtrl (v0.03) by Gavin Brown
#
# Packaged along with Axmud, renamed and reduced to alleviate various problems
# List of changes (besides cosmetic ones):
#   - Added 'use warnings' as the lack of it causes Kwalitee errors
#   - Commented out $VERSION as it causes Kwalitee errors
#   - Removed POD stuff
#   - Modified ->new so it returns 'undef', rather than doing a Perl die(), if wmctrl is not
#       available on the user's system
#   - Modified ->get_windows which (rarely) creates a 'PERL WARNING: Use of uninitialized value
#       $data in split' error
#   - Commented out the close() function, which Axmud doesn't need anyway, and which sometimes
#       produces an unexplained Perl error

package Games::Axmud::Obj::WMCtrl;

use vars qw($VERSION);
use strict;
use warnings;

#our $VERSION = '0.03';

#sub new {
#   my $self = {};
#   $self->{package} = shift;
#   bless($self, $self->{package});
#   chomp($self->{wmctrl} = `which wmctrl 2> /dev/null`);
#   die("can't find the wmctrl program") if (! -x $self->{wmctrl});
#   return $self;
#}
sub new {
    my $self = {};
    $self->{package} = shift;
    bless($self, $self->{package});
    chomp($self->{wmctrl} = `which wmctrl 2> /dev/null`);
    if (! -x $self->{wmctrl}) {
        return undef;
    } else {
        return $self;
    }
}

sub get_window_manager {
    my $self = shift;
    my $data = $self->wmctrl('-m');
    my $wm = {};
    foreach my $line (split(/\n/, $data)) {
        my ($name, $value) = split(/:/, $line, 2);
        $value =~ s/^\s+//g;
        $value =~ s/\s+$//g;
        $value = ($value =~ 'OFF' ? undef : 1);
        $name = ($name =~ /showing the desktop/i ? 'show_desktop' : $name);
        $wm->{lc($name)} = $value;
    }
    return $wm;
}

#sub get_windows {
#   my $self = shift;
#   my $data = $self->wmctrl('-l');
#   my @windows;
#   foreach my $line (split(/\n/, $data)) {
#       my ($id, $strand) = split(/ +/, $line, 2);
#       my ($workspace, $host, $title);
#       if ($strand =~ /^-1/) {
#           $strand =~ s/^-1//;
#           $workspace = -1;
#           ($host, $title) = split(/ /, $strand, 2);
#       } else {
#           ($workspace, $host, $title) = split(/ /, $strand, 3);
#       }
#       push(@windows, {
#           id      => $id,
#           workspace   => $workspace,
#           host        => $host,
#           title       => $title,
#       });
#   }
#   return @windows;
#}
sub get_windows {
    my $self = shift;
    my $data = $self->wmctrl('-l');
    my @windows;
    if (defined $data) {
        foreach my $line (split(/\n/, $data)) {
            my ($id, $strand) = split(/ +/, $line, 2);
            my ($workspace, $host, $title);
            if ($strand =~ /^-1/) {
                $strand =~ s/^-1//;
                $workspace = -1;
                ($host, $title) = split(/ /, $strand, 2);
            } else {
                ($workspace, $host, $title) = split(/ /, $strand, 3);
            }
            push(@windows, {
                id      => $id,
                workspace   => $workspace,
                host        => $host,
                title       => $title,
            });
        }
    }
    return @windows;
}

sub get_workspaces {
    my $self = shift;
    my $data = $self->wmctrl('-d');
    my $workspaces = {};
    foreach my $line (split(/\n/, $data)) {
        my ($workspace, $strand) = split(/ /, $line, 2);
        my ($name, undef) = split(/  /, reverse($strand), 2);
        $name = reverse($name);
        $workspaces->{$workspace} = $name;
    }
    return $workspaces;
}

sub switch {
    my ($self, $workspace) = @_;
    $self->wmctrl('-s', $workspace);
    return 1;
}

sub activate {
    my ($self, $window) = @_;
    $self->wmctrl('-a', $window);
    return 1;
}

#sub close {
#   my ($self, $window) = @_;
#   $self->wmctrl('-c', $window);
#   return 1;
#}

sub move_activate {
    my ($self, $window) = @_;
    $self->wmctrl('-R', $window);
    return 1;
}

sub move_to {
    my ($self, $window, $workspace) = @_;
    $self->wmctrl('-r', $window, '-t', $workspace);
    return 1;
}

sub maximize {
    my ($self, $window) = @_;
    $self->modify_state($window, 'add', 'maximized_vert', 'maximized_horz');
    return 1;
}

sub unmaximize {
    my ($self, $window) = @_;
    $self->modify_state($window, 'remove', 'maximized_vert', 'maximized_horz');
    return 1;
}

sub minimize {
    my ($self, $window) = @_;
    $self->unmaximize($window);
    $self->modify_state($window, 'add', 'hidden');
    return 1;
}

sub unminimize {
    my ($self, $window) = @_;
    $self->modify_state($window, 'remove', 'hidden');
    return 1;
}

sub shade {
    my ($self, $window) = @_;
    $self->modify_state($window, 'add', 'shaded');
    return 1;
}

sub unshade {
    my ($self, $window) = @_;
    $self->modify_state($window, 'remove', 'shaded');
    return 1;
}

sub stick {
    my ($self, $window) = @_;
    $self->modify_state($window, 'add', 'sticky');
    return 1;
}

sub unstick {
    my ($self, $window) = @_;
    $self->modify_state($window, 'remove', 'sticky');
    return 1;
}

sub fullscreen {
    my ($self, $window) = @_;
    $self->modify_state($window, 'add', 'fullscreen');
    return 1;
}

sub unfullscreen {
    my ($self, $window) = @_;
    $self->modify_state($window, 'remove', 'fullscreen');
    return 1;
}

sub wmctrl {
    my $self = shift;
    my @args = @_;
    open(WMCTRL, sprintf('%s %s|', $self->{wmctrl}, join(' ', @args)));
    my $data;
    while (<WMCTRL>) {
        $data .= $_;
    }
    close(WMCTRL);
    return $data;
}

sub modify_state {
    my ($self, $window, $mod, @params) = @_;
    die("invalid modifier '$mod'") if ($mod !~ /^(add|remove)$/i);
    die("invalid number of params") if (scalar(@params) > 2);
    $self->wmctrl('-r', $window, '-b', join(',', $mod, @params));
    return 1;
}

1;
