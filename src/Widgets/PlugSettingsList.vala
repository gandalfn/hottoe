/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * PlugSettingsList.vala
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

public class PantheonSoundControl.Widgets.PlugSettingsList : Gtk.Grid {
    private Gtk.ListBox m_Plugs;

    public unowned Device device { get; construct; }
    public Direction direction { get; construct; }

    construct {
        column_spacing = 12;
        row_spacing = 12;

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.hexpand = scrolled.vexpand = true;

        var header_label = new Gtk.Label (_("Clients:"));
        header_label.margin_start = 12;
        header_label.margin_top = 6;
        header_label.halign = Gtk.Align.START;
        header_label.get_style_context ().add_class ("h4");

        m_Plugs = new Gtk.ListBox ();
        m_Plugs.selection_mode = Gtk.SelectionMode.NONE;
        scrolled.add (m_Plugs);

        var add_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        add_button.tooltip_text = _("Add Client…");

        var toolbar = new Gtk.ActionBar ();
        toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        toolbar.add (add_button);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        main_box.add (header_label);
        main_box.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_box.add (scrolled);
        main_box.add (toolbar);

        var frame = new Gtk.Frame (null);
        frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        frame.add (main_box);

        add (frame);

        device.manager.plug_added.connect (on_plug_added);
        device.manager.plug_removed.connect (on_plug_removed);
    }

    public PlugSettingsList (Device inDevice, Direction inDirection) {
        GLib.Object (
            device: inDevice,
            direction: inDirection
        );
    }

    private void add_plug (Plug inPlug) {
        if (!inPlug.client.is_mine && inPlug.channel != null && inPlug.channel in device && inPlug.direction in direction) {
            bool found = false;
            foreach (var child in m_Plugs.get_children ()) {
                unowned PlugSettingsRow? row = ((Gtk.ListBoxRow) child).get_child () as PlugSettingsRow;
                if (row != null && row.plug == inPlug) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                PlugSettingsRow row  = new PlugSettingsRow (inPlug);
                row.margin_bottom = 12;
                row.show_all ();
                m_Plugs.add (row);
            }
        }
    }

    private void remove_plug (Plug inPlug) {
        foreach (unowned Gtk.Widget? child in m_Plugs.get_children ()) {
            unowned PlugSettingsRow? row = ((Gtk.ListBoxRow) child).get_child () as PlugSettingsRow;
            if (row != null && row.plug == inPlug) {
                child.destroy ();
                break;
            }
        }
    }

    private void on_plug_added (Plug inPlug) {
        inPlug.notify["channel"].connect (on_plug_channel_changed);

        add_plug (inPlug);
    }

    private void on_plug_removed (Plug inPlug) {
        inPlug.notify["channel"].disconnect (on_plug_channel_changed);

        remove_plug (inPlug);
    }

    private void on_plug_channel_changed (GLib.Object inObject, GLib.ParamSpec? inSpec) {
        unowned Plug plug = (Plug)inObject;

        if (!plug.client.is_mine && plug.channel != null && plug.channel in device && plug.direction in direction) {
            add_plug (plug);
        } else {
            remove_plug (plug);
        }
    }
}