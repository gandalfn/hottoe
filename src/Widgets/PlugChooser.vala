/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * PlugChooser.vala
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

public class Hottoe.Widgets.PlugChooser : Gtk.Popover {
    private Gtk.ListBox m_plug_list;

    public unowned Device device { get; construct; }
    public Direction direction { get; construct; }
    public int available {
        get {
            Gtk.ListBoxRow? row = null;
            int ret = 0, cpt = 0;
            while ((row = m_plug_list.get_row_at_index (cpt)) != null) {
                unowned PlugChooserRow? pr = row.get_child () as PlugChooserRow;
                if (pr.plug.client != null && !pr.plug.client.is_mine &&
                    pr.plug.channel != null && !(pr.plug.channel in device)) {
                    ret++;
                }
                cpt++;
            }

            return ret;
        }
    }

    public signal void plug_selected (Plug in_plug);

    construct {
        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.height_request = 200;
        scrolled.width_request = 350;
        scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;

        m_plug_list = new Gtk.ListBox ();
        m_plug_list.expand = true;
        m_plug_list.set_filter_func (filter_function);
        scrolled.add (m_plug_list);

        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.row_spacing = 6;
        grid.attach (scrolled, 0, 0, 1, 1);

        add (grid);

        m_plug_list.row_activated.connect (on_plug_selected);

        if (Direction.INPUT in direction) {
            foreach (unowned Plug plug in device.manager.get_input_plugs ()) {
                on_plug_added (plug);
            }
        }
        if (Direction.OUTPUT in direction) {
            foreach (unowned Plug plug in device.manager.get_output_plugs ()) {
                on_plug_added (plug);
            }
        }

        device.manager.plug_added.connect (on_plug_added);
        device.manager.plug_removed.connect (on_plug_removed);
    }

    public PlugChooser (Gtk.Widget in_widget, Device in_device, Direction in_direction) {
        GLib.Object (
            relative_to: in_widget,
            device: in_device,
            direction: in_direction
        );
    }

    private void on_plug_added (Plug in_plug) {
        if (in_plug.direction in direction) {
            in_plug.notify["channel"].connect (on_plug_channel_changed);

            bool found = false;
            Gtk.ListBoxRow? row = null;
            int cpt = 0;
            while ((row = m_plug_list.get_row_at_index (cpt)) != null) {
                unowned PlugChooserRow? pr = row.get_child () as PlugChooserRow;
                if (pr.plug == in_plug) {
                    found = true;
                    break;
                }
                cpt++;
            }
            if (!found) {
                var r = new PlugChooserRow (in_plug);
                r.show_all ();
                m_plug_list.prepend (r);
            }
        }
    }

    private void on_plug_removed (Plug in_plug) {
        in_plug.notify["channel"].disconnect (on_plug_channel_changed);

        Gtk.ListBoxRow? row = null;
        int cpt = 0;
        while ((row = m_plug_list.get_row_at_index (cpt)) != null) {
            unowned PlugChooserRow? pr = row.get_child () as PlugChooserRow;
            if (pr != null && pr.plug == in_plug) {
                row.destroy ();
            }
            cpt++;
        }
    }

    private void on_plug_selected (Gtk.ListBoxRow in_row) {
        var row = in_row.get_child () as PlugChooserRow;
        plug_selected (row.plug);
        hide ();
    }

    private bool filter_function (Gtk.ListBoxRow in_row) {
        var row = in_row.get_child () as PlugChooserRow;
        return row.plug.client != null && !row.plug.client.is_mine &&
               row.plug.channel != null && !(row.plug.channel in device);
    }

    private void on_plug_channel_changed (GLib.Object in_object, GLib.ParamSpec? in_spec) {
        m_plug_list.invalidate_filter ();
    }
}