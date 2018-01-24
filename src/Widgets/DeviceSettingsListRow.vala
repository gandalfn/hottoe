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

private class PantheonSoundControl.Widgets.DeviceSettingsListRow : Gtk.ListBoxRow {
    private Gtk.Revealer m_Content;
    private Gtk.Image m_StatusIcon;
    private Gtk.Label m_StatusLabel;
    private Gtk.Label m_TitleLabel;

    public unowned DeviceSettingsPage page { get; construct; }

    public string status {
        set {
            m_StatusLabel.label = "<span font_size='small'>%s</span>".printf (value);
            m_StatusLabel.no_show_all = false;
            m_StatusLabel.show ();
        }
    }

    public string title {
        set {
            m_TitleLabel.label = value;
        }
    }

    public DeviceSettingsListRow (DeviceSettingsPage page) {
        Object (
            page: page
        );
    }

    construct {
        m_TitleLabel = new Gtk.Label (page.title);
        m_TitleLabel.ellipsize = Pango.EllipsizeMode.END;
        m_TitleLabel.xalign = 0;
        m_TitleLabel.get_style_context ().add_class ("h3");

        m_StatusIcon = new Gtk.Image ();
        m_StatusIcon.halign = Gtk.Align.END;
        m_StatusIcon.valign = Gtk.Align.START;

        m_StatusLabel = new Gtk.Label (null);
        m_StatusLabel.no_show_all = true;
        m_StatusLabel.use_markup = true;
        m_StatusLabel.ellipsize = Pango.EllipsizeMode.END;
        m_StatusLabel.xalign = 0;

        var icon = new Gtk.Image ();
        icon.icon_name = page.icon_name;
        icon.pixel_size =  32;

        var overlay = new Gtk.Overlay ();
        overlay.width_request = 38;
        overlay.add (icon);
        overlay.add_overlay (m_StatusIcon);

        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.column_spacing = 6;
        grid.attach (overlay, 0, 0, 1, 2);
        grid.attach (m_TitleLabel, 1, 0, 1, 1);
        grid.attach (m_StatusLabel, 1, 1, 1, 1);

        m_Content = new Gtk.Revealer ();
        m_Content.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;

        m_Content.add (grid);

        add (m_Content);

        page.bind_property ("icon-name", icon, "icon-name");
        page.bind_property ("status", this, "status");
        page.bind_property ("title", this, "title");
        page.device.bind_property ("active", m_Content, "reveal_child", GLib.BindingFlags.SYNC_CREATE);
        page.device.manager.bind_property ("default-output-device", m_StatusIcon, "icon-name",
                                           GLib.BindingFlags.SYNC_CREATE, (b, f, ref t) => {
            unowned Device? defaultDevice = (Device)f;
            if (defaultDevice == page.device) {
                t.set_string ("account-logged-in");
                m_StatusIcon.show ();
            } else {
                t.set_string ("");
                m_StatusIcon.hide ();
            }
            return true;
        });

        if (page.status != null) {
            status = page.status;
        }
    }
}