/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * DeviceView.vala
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

public class PantheonSoundControl.Widgets.DeviceView : Gtk.Grid {
    private int m_NbPorts;
    private Gtk.Label m_TitleLabel;
    private Gtk.Revealer m_Content;
    private Gtk.RadioButton m_DefaultCheck;

    public unowned Device device { get; construct; }

    public string title_label {
        set {
            m_TitleLabel.set_markup ("<b>%s</b>".printf (value));
        }
    }

    public Gtk.Grid content_area { get; set; }

    public Gtk.RadioButton group {
        set {
            m_DefaultCheck.join_group (value);
        }
    }

    public DeviceView (Device inDevice) {
        Object (
            device: inDevice
        );
    }

    construct {
        m_DefaultCheck = new Gtk.RadioButton (null);
        m_DefaultCheck.margin_top = 6;
        m_DefaultCheck.margin_start = 6;
        m_DefaultCheck.halign = Gtk.Align.START;
        m_DefaultCheck.valign = Gtk.Align.CENTER;

        m_TitleLabel = new Gtk.Label ("");
        m_TitleLabel.xalign = 0;
        m_TitleLabel.get_style_context ().add_class ("h3");

        var check_area = new Gtk.Grid ();
        check_area.attach (m_TitleLabel, 0, 0, 1, 1);

        var description_label = new Gtk.Label ("");
        description_label.xalign = 0;
        description_label.wrap = true;

        check_area.attach (description_label, 0, 1, 1, 1);

        m_DefaultCheck.add (check_area);

        content_area = new Gtk.Grid ();
        content_area.column_spacing = 12;
        content_area.row_spacing = 12;
        content_area.vexpand = true;

        var channel_list = new DeviceChannelList (device);
        channel_list.margin_start = 16;
        content_area.add (channel_list);

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.row_spacing = 12;
        grid.add (m_DefaultCheck);
        grid.add (content_area);
        grid.add (new Wingpanel.Widgets.Separator ());

        m_Content = new Gtk.Revealer ();
        m_Content.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;

        m_Content.add (grid);

        add (m_Content);

        device.bind_property ("display-name", this, "title-label", GLib.BindingFlags.SYNC_CREATE);
        device.bind_property ("active-profile", description_label, "label", GLib.BindingFlags.SYNC_CREATE, (b, f, ref t) => {
            unowned Profile profile = (Profile)f;

            if (profile != null) {
                t.set_string (profile.description);
            } else {
                t.set_string ("");
            }
            return true;
        });
        device.bind_property ("active", m_Content, "reveal_child", GLib.BindingFlags.SYNC_CREATE);
        device.manager.bind_property ("default-output-device", m_DefaultCheck, "active", GLib.BindingFlags.SYNC_CREATE, (b, f, ref t) => {
            unowned Device? defaultDevice = (Device)f;
            t.set_boolean (defaultDevice == device);
            return true;
        });
        m_DefaultCheck.toggled.connect (() => {
            if (m_DefaultCheck.active) {
                device.manager.default_output_device = device;
                device.manager.default_input_device = device;
            }
        });

        device.changed.connect (on_device_changed);

        on_device_changed ();
    }

    private void on_device_changed () {
        int nbPorts = device.get_output_ports().length + device.get_input_ports().length;

        // device ports has changed check default profile
        if (nbPorts != m_NbPorts) {
            // If device profile is set to "off" on nb ports change set top most priority profile
            if (device.active_profile != null && device.active_profile.name == "off") {
                var profile = device.get_profiles ()[0];
                if (profile != null && profile.name != device.active_profile.name) {
                    device.active_profile = profile;
                }
            }
            m_NbPorts = nbPorts;

            if (m_NbPorts > 0) {
                var notification = new Services.DesktopNotification.device_available (device);
                notification.send ();
            } else {
                var notification = new Services.DesktopNotification.device_not_available (device);
                notification.send ();
            }
        }
    }
}