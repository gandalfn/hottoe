/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * DeviceSettingsListRow.vala
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

private class SukaHottoe.Widgets.DeviceSettingsListRow : Gtk.ListBoxRow {
    private Gtk.Revealer m_content;
    private Gtk.Image m_status_icon;
    private Gtk.Label m_status_label;
    private Gtk.Label m_title_label;

    public unowned DeviceSettingsPage page { get; construct; }

    public DeviceSettingsListRow (DeviceSettingsPage page) {
        Object (
            page: page
        );
    }

    construct {
        m_title_label = new Gtk.Label (page.device.display_name);
        m_title_label.ellipsize = Pango.EllipsizeMode.END;
        m_title_label.xalign = 0;
        m_title_label.get_style_context ().add_class ("h3");

        m_status_icon = new Gtk.Image ();
        m_status_icon.halign = Gtk.Align.END;
        m_status_icon.valign = Gtk.Align.START;

        m_status_label = new Gtk.Label (null);
        m_status_label.use_markup = true;
        m_status_label.ellipsize = Pango.EllipsizeMode.END;
        m_status_label.xalign = 0;

        var icon = new DeviceIcon (page.device, Icon.Size.LARGE);

        var overlay = new Gtk.Overlay ();
        overlay.width_request = 38;
        overlay.add (icon);
        overlay.add_overlay (m_status_icon);

        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.column_spacing = 6;
        grid.attach (overlay, 0, 0, 1, 2);
        grid.attach (m_title_label, 1, 0, 1, 1);
        grid.attach (m_status_label, 1, 1, 1, 1);

        m_content = new Gtk.Revealer ();
        m_content.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;

        m_content.add (grid);

        add (m_content);

        page.device.bind_property ("display-name", m_title_label, "label", GLib.BindingFlags.SYNC_CREATE);
        page.device.bind_property ("active", m_content, "reveal_child", GLib.BindingFlags.SYNC_CREATE);
        page.device.manager.bind_property ("default-output-device", m_status_icon, "icon-name",
                                           GLib.BindingFlags.SYNC_CREATE, (b, f, ref t) => {
            unowned Device? default_device = (Device)f;
            if (default_device == page.device) {
                t.set_string ("emblem-default");
                m_status_icon.show ();
            } else {
                t.set_string ("");
                m_status_icon.hide ();
            }
            return true;
        });
        page.device.bind_property ("active-profile", m_status_label, "label",
                                   GLib.BindingFlags.SYNC_CREATE, (b, f, ref t) => {
            unowned Profile? profile = (Profile)f;
            if (profile != null) {
                t.set_string (profile.description);
            } else {
                t.set_string ("");
            }
            return true;
        });
    }
}