/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * DeviceSettingsPage.vala
 * Copyright (C) Nicolas Bruguier 2018 <gandalfn@club-internet.fr>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 */

public class SukaHottoe.Widgets.DeviceSettingsPage : Granite.SettingsPage {
    private Gtk.Grid m_output_grid;
    private Gtk.Grid m_input_grid;
    private Gtk.StackSwitcher m_output_input_switcher;
    private Gtk.Stack m_output_input_stack;

    private Gtk.ComboBox m_profile_settings;

    public unowned Device device { get; construct; }

    construct {
        var header_icon = new DeviceIcon (device, Icon.Size.FULL);
        header_icon.valign = Gtk.Align.START;

        var title_label = new Gtk.Label ("");
        title_label.xalign = 0;
        title_label.get_style_context ().add_class ("h2");

        var header_area = new Gtk.Grid ();
        header_area.column_spacing = 12;
        header_area.row_spacing = 3;
        header_area.attach (header_icon, 0, 0, 1, 2);
        header_area.attach (title_label, 1, 0, 1, 1);

        var renderer = new Gtk.CellRendererText ();

        var combo = new Gtk.ComboBox ();
        m_profile_settings = new Gtk.ComboBox ();
        m_profile_settings.width_request = 180;
        m_profile_settings.pack_start (renderer, true);
        m_profile_settings.add_attribute (renderer, "text", 0);

        Gtk.ListStore profiles_list = new Gtk.ListStore (2, typeof (string), typeof (string));
        m_profile_settings.set_model (profiles_list);

        m_profile_settings.changed.connect (() => {
            Gtk.TreeIter iter;
            if (m_profile_settings.get_active_iter (out iter)) {
                GLib.Value name;
                m_profile_settings.get_model ().get_value (iter, 1, out name);
                foreach (var profile in device.get_profiles ()) {
                    if (profile.name == (string)name) {
                        device.active_profile = profile;
                        break;
                    }
                }
            }
        });
        header_area.attach (m_profile_settings, 1, 1, 1, 1);

        var status_switch = new Gtk.Switch ();
        status_switch.hexpand = true;
        status_switch.halign = Gtk.Align.END;
        status_switch.valign = Gtk.Align.CENTER;
        header_area.attach (status_switch, 2, 0, 1, 1);
        status_switch.button_press_event.connect (() => {
            return status_switch.active;
        });

        var content_area = new Gtk.Grid ();
        content_area.orientation = Gtk.Orientation.VERTICAL;
        content_area.vexpand = true;

        m_output_grid = new Gtk.Grid ();
        m_output_grid.orientation = Gtk.Orientation.VERTICAL;
        m_output_grid.row_spacing = 24;
        m_output_grid.margin_start = 12;

        var output_channels = new DeviceChannelList (device, Direction.OUTPUT);
        output_channels.show_labels = true;
        output_channels.show_balance = true;
        output_channels.icon_size = Icon.Size.EXTRA_LARGE;
        output_channels.monitor_nb_bars = 25.0;
        m_output_grid.add (output_channels);

        var grid_eq_spec = new Gtk.Grid ();
        grid_eq_spec.orientation = Gtk.Orientation.HORIZONTAL;
        grid_eq_spec.column_spacing = 12;

        var output_equalizer = new Widgets.Equalizer(device);
        grid_eq_spec.add (output_equalizer);

        var output_spectrum = new Widgets.Spectrum(device, 40);
        grid_eq_spec.add (output_spectrum);

        m_output_grid.add (grid_eq_spec);

        var output_plugs = new PlugSettingsList (device, Direction.OUTPUT);
        m_output_grid.add (output_plugs);

        m_input_grid = new Gtk.Grid ();
        m_input_grid.orientation = Gtk.Orientation.VERTICAL;
        m_input_grid.row_spacing = 24;
        m_input_grid.margin_start = 12;

        var input_channels = new DeviceChannelList (device, Direction.INPUT);
        input_channels.show_labels = true;
        input_channels.show_balance = true;
        input_channels.icon_size = Icon.Size.EXTRA_LARGE;
        input_channels.monitor_nb_bars = 25.0;
        m_input_grid.add (input_channels);

        var input_plugs = new PlugSettingsList (device, Direction.INPUT);
        m_input_grid.add (input_plugs);

        m_output_input_stack = new Gtk.Stack ();
        m_output_input_stack.margin_top = 24;
        m_output_input_stack.expand = true;

        m_output_input_switcher = new Gtk.StackSwitcher ();
        m_output_input_switcher.halign = Gtk.Align.CENTER;
        m_output_input_switcher.homogeneous = true;
        m_output_input_switcher.margin_top = 12;
        m_output_input_switcher.stack = m_output_input_stack;

        m_output_input_stack.add_titled (m_output_grid, "output", _("Output"));
        m_output_input_stack.add_titled (m_input_grid, "input", _("Input"));
        content_area.add (m_output_input_switcher);
        content_area.add (m_output_input_stack);

        var grid = new Gtk.Grid ();
        grid.margin = 12;
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (header_area);
        grid.add (content_area);

        add (grid);

        device.manager.bind_property ("default-output-device", status_switch, "active",
                                      GLib.BindingFlags.BIDIRECTIONAL |
                                      GLib.BindingFlags.SYNC_CREATE,
                                      (b, f, ref t) => {
            unowned Device? default_device = (Device)f;
            t.set_boolean (default_device == device);
            return true;
        }, (b, f, ref t) => {
            bool ret = false;
            if ((bool)f) {
                t.set_object (device);
                ret = true;
            }
            return ret;
        });

        device.bind_property ("display-name", title_label, "label", GLib.BindingFlags.SYNC_CREATE);

        device.changed.connect (on_device_changed);

        // TODO: fix channel added /removed for a device
        device.channel_added.connect (on_device_channels_changed);
        device.manager.channel_added.connect (on_device_channels_changed);
        device.channel_removed.connect (on_device_channels_changed);
        device.manager.channel_removed.connect (on_device_channels_changed);
        on_device_changed ();
    }

    public DeviceSettingsPage (Device in_device) {
        GLib.Object (
            device: in_device
        );
    }

    private void on_device_changed () {
        Gtk.ListStore profiles_list = (Gtk.ListStore)m_profile_settings.get_model ();
        Gtk.TreeIter iter;

        int active_row = 0, cpt = 0;
        profiles_list.clear ();

        foreach (var profile in device.get_profiles ()) {
            profiles_list.append (out iter);
            profiles_list.set (iter, 0, profile.description, 1, profile.name);

            if (device.active_profile == profile) {
                active_row = cpt;
            }
            cpt++;
        }
        m_profile_settings.set_active (active_row);

        on_device_channels_changed ();
    }

    private void on_device_channels_changed () {
        bool have_output = device.get_output_channels ().length > 0;
        bool have_input = device.get_input_channels ().length > 0;

        bool switch_on_output = have_output && m_output_grid.visible != have_output;

        m_output_grid.visible = have_output;
        m_input_grid.visible = have_input;

        m_output_input_switcher.visible = have_output && have_input;

        // If output become visible switch on it
        if (switch_on_output) {
            m_output_input_stack.set_visible_child (m_output_grid);
        }
    }
}