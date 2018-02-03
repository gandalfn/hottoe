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
    private int m_nb_ports;
    private Gtk.Label m_title_label;
    private Gtk.Revealer m_content;
    private Gtk.RadioButton m_default_check;

    public unowned Device device { get; construct; }

    public string title_label {
        set {
            m_title_label.set_markup ("<b>%s</b>".printf (value));
        }
    }

    public Gtk.Grid content_area { get; set; }

    public Gtk.RadioButton group {
        set {
            m_default_check.join_group (value);
        }
    }

    public DeviceView (Device in_device) {
        Object (
            device: in_device
        );
    }

    construct {
        m_default_check = new Gtk.RadioButton (null);
        m_default_check.margin_top = 6;
        m_default_check.margin_start = 6;
        m_default_check.halign = Gtk.Align.START;
        m_default_check.valign = Gtk.Align.CENTER;

        m_title_label = new Gtk.Label ("");
        m_title_label.xalign = 0;
        m_title_label.get_style_context ().add_class ("h3");

        var check_area = new Gtk.Grid ();
        check_area.attach (m_title_label, 0, 0, 1, 1);

        var description_label = new Gtk.Label ("");
        description_label.xalign = 0;
        description_label.wrap = true;

        check_area.attach (description_label, 0, 1, 1, 1);

        m_default_check.add (check_area);

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
        grid.add (m_default_check);
        grid.add (content_area);
        grid.add (new Wingpanel.Widgets.Separator ());

        m_content = new Gtk.Revealer ();
        m_content.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;

        m_content.add (grid);

        add (m_content);

        device.bind_property ("display-name", this, "title-label", GLib.BindingFlags.SYNC_CREATE);
        device.bind_property ("active-profile", description_label, "label", GLib.BindingFlags.SYNC_CREATE,
                              (b, f, ref t) => {
            unowned Profile profile = (Profile)f;

            if (profile != null) {
                t.set_string (profile.description);
            } else {
                t.set_string ("");
            }
            return true;
        });
        device.bind_property ("active", m_content, "reveal_child", GLib.BindingFlags.SYNC_CREATE);
        device.manager.bind_property ("default-output-device", m_default_check, "active", GLib.BindingFlags.SYNC_CREATE,
                                      (b, f, ref t) => {
            unowned Device? default_device = (Device)f;
            t.set_boolean (default_device == device);
            return true;
        });
        m_default_check.toggled.connect (() => {
            if (m_default_check.active) {
                device.manager.default_output_device = device;
                device.manager.default_input_device = device;
            }
        });

        device.changed.connect (on_device_changed);

        on_device_changed ();
    }

    private void on_device_changed () {
        int nb_ports = device.get_output_ports ().length + device.get_input_ports ().length;

        // device ports has changed check default profile
        if (nb_ports != m_nb_ports) {
            // If device profile is set to "off" on nb ports change set top most priority profile
            if (device.active_profile != null && device.active_profile.name == "off") {
                var profile = device.get_profiles ()[0];
                if (profile != null && profile.name != device.active_profile.name) {
                    device.active_profile = profile;
                }
            }
            m_nb_ports = nb_ports;

            if (m_nb_ports > 0) {
                var notification = new Services.DesktopNotification.device_available (device);
                notification.send ();
            } else {
                var notification = new Services.DesktopNotification.device_not_available (device);
                notification.send ();
            }
        }
    }
}