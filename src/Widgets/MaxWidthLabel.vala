/*
* Copyright (c) 2015-2017 elementary LLC. (http://launchpad.net/wingpanel-indicator-sound)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

public class SukaHottoe.Widgets.MaxWidthLabel : Gtk.Label {
    private int max_width;

    public MaxWidthLabel (int in_max_width) {
        max_width = in_max_width;
    }

    public override void get_preferred_width (out int out_minimum_width, out int out_natural_width) {
        base.get_preferred_width (out out_minimum_width, out out_natural_width);
        if (out_minimum_width > max_width) {
            out_minimum_width = max_width;
        }
        if (out_natural_width > max_width) {
            out_natural_width = max_width;
        }
    }
}
