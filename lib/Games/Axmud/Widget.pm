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
# All packages for sub-classes of Gtk2 objects (used to set external rc styles)

{ package Games::Axmud::Widget::TextView::Gtk2;

    use strict;
    use diagnostics;
    use warnings;

    # Include module here, as well as in axmud.pl, so that .../t/00-compile.t won't fail
    use Gtk2;

    # Use this sub-class, rather than Gtk2::TextView, to create a textview with the system's
    #   preferred colours and fonts
    # (In an ideal world, we'd call it GA::Gtk2::TextView, but GA::Obj::Desktop->setTextViewStyle
    #   needs an object whose class doesn't end with 'TextView')
    use Glib::Object::Subclass 'Gtk2::TextView';
}

# Package must return a true value
1
