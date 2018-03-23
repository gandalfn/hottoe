/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * PlugChooserRow.vala
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

public class SukaHottoe.Widgets.PlugChooserRow : Gtk.Grid {
    public unowned Plug plug { get; construct; }

    construct {
        hexpand = true;
        row_spacing = 6;
        column_spacing = 6;

        var icon = new ClientIcon (plug.client, Icon.Size.EXTRA_LARGE);
        icon.margin_start = 6;
        attach (icon, 0, 0, 1, 1);

        var title = new Gtk.Label ("");
        title.use_markup = true;
        title.hexpand = true;
        title.xalign = 0.0f;
        attach (title, 1, 0, 1, 1);

        plug.client.bind_property ("name", title, "label", GLib.BindingFlags.SYNC_CREATE, (b, f, ref t) => {
            t.set_string ("<b>%s</b>".printf ((string)f));
            return true;
        });
    }

    public PlugChooserRow (Plug in_plug) {
        GLib.Object (
            plug: in_plug
        );
    }
}