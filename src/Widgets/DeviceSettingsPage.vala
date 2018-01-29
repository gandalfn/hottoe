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

public class PantheonSoundControl.Widgets.DeviceSettingsPage  : Granite.SettingsPage {
    private Gtk.Grid m_OutputGrid;
    private Gtk.Grid m_InputGrid;
    private Gtk.StackSwitcher m_OutputInputSwitcher;
    private Gtk.Stack m_OutputInputStack;

    private Gtk.ComboBox m_ProfileSettings;

    public unowned Device device { get; construct; }

    construct {
        var headerIcon = new Gtk.Image.from_icon_name ("audio-card", Gtk.IconSize.DIALOG);
        headerIcon.pixel_size = 64;
        headerIcon.valign = Gtk.Align.START;

        var titleLabel = new Gtk.Label ("");
        titleLabel.xalign = 0;
        titleLabel.get_style_context ().add_class ("h2");

        var headerArea = new Gtk.Grid ();
        headerArea.column_spacing = 12;
        headerArea.row_spacing = 3;
        headerArea.attach (headerIcon, 0, 0, 1, 2);
        headerArea.attach (titleLabel, 1, 0, 1, 1);

        var renderer = new Gtk.CellRendererText ();

        var combo = new Gtk.ComboBox ();
        m_ProfileSettings = new Gtk.ComboBox ();
        m_ProfileSettings.width_request = 180;
        m_ProfileSettings.pack_start (renderer, true);
        m_ProfileSettings.add_attribute (renderer, "text", 0);

        Gtk.ListStore profilesList = new Gtk.ListStore (2, typeof (string), typeof (string));
        m_ProfileSettings.set_model (profilesList);

        m_ProfileSettings.changed.connect (() => {
            Gtk.TreeIter iter;
            if (m_ProfileSettings.get_active_iter (out iter)) {
                GLib.Value name;
                m_ProfileSettings.get_model ().get_value (iter, 1, out name);
                foreach (var profile in device.get_profiles ()) {
                    if (profile.name == (string)name) {
                        device.active_profile = profile;
                        break;
                    }
                }
            }
        });
        headerArea.attach (m_ProfileSettings, 1, 1, 1, 1);

        var statusSwitch = new Gtk.Switch ();
        statusSwitch.hexpand = true;
        statusSwitch.halign = Gtk.Align.END;
        statusSwitch.valign = Gtk.Align.CENTER;
        headerArea.attach (statusSwitch, 2, 0, 1, 1);
        statusSwitch.button_press_event.connect (() => {
            return statusSwitch.active;
        });

        var contentArea = new Gtk.Grid ();
        contentArea.orientation = Gtk.Orientation.VERTICAL;
        contentArea.vexpand = true;

        m_OutputGrid = new Gtk.Grid ();
        m_OutputGrid.orientation = Gtk.Orientation.VERTICAL;
        m_OutputGrid.row_spacing = 24;
        m_OutputGrid.margin_start = 12;

        var outputChannels = new DeviceChannelList (device, Direction.OUTPUT);
        outputChannels.show_labels = true;
        outputChannels.show_balance = true;
        outputChannels.icon_size = Gtk.IconSize.DIALOG;
        outputChannels.icon_pixel_size = 48;
        outputChannels.monitor_nb_bars = 20.0;
        m_OutputGrid.add (outputChannels);

        var outputPlugs = new PlugSettingsList (device, Direction.OUTPUT);
        m_OutputGrid.add (outputPlugs);

        m_InputGrid = new Gtk.Grid ();
        m_InputGrid.orientation = Gtk.Orientation.VERTICAL;
        m_InputGrid.row_spacing = 24;
        m_InputGrid.margin_start = 12;

        var inputChannels = new DeviceChannelList (device, Direction.INPUT);
        inputChannels.show_labels = true;
        inputChannels.show_balance = true;
        inputChannels.icon_size = Gtk.IconSize.DIALOG;
        inputChannels.icon_pixel_size = 48;
        inputChannels.monitor_nb_bars = 20.0;
        m_InputGrid.add (inputChannels);

        var inputPlugs = new PlugSettingsList (device, Direction.INPUT);
        m_InputGrid.add (inputPlugs);

        m_OutputInputStack = new Gtk.Stack ();
        m_OutputInputStack.margin_top = 24;
        m_OutputInputStack.expand = true;

        m_OutputInputSwitcher = new Gtk.StackSwitcher ();
        m_OutputInputSwitcher.halign = Gtk.Align.CENTER;
        m_OutputInputSwitcher.homogeneous = true;
        m_OutputInputSwitcher.margin_top = 12;
        m_OutputInputSwitcher.stack = m_OutputInputStack;

        m_OutputInputStack.add_titled (m_OutputGrid, "output", _("Output"));
        m_OutputInputStack.add_titled (m_InputGrid, "input", _("Input"));
        contentArea.add (m_OutputInputSwitcher);
        contentArea.add (m_OutputInputStack);

        var grid = new Gtk.Grid ();
        grid.margin = 12;
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (headerArea);
        grid.add (contentArea);

        add (grid);

        device.manager.bind_property ("default-output-device", statusSwitch, "active",
                                      GLib.BindingFlags.BIDIRECTIONAL |
                                      GLib.BindingFlags.SYNC_CREATE,
                                      (b, f, ref t) => {
            unowned Device? defaultDevice = (Device)f;
            t.set_boolean (defaultDevice == device);
            return true;
        }, (b, f, ref t) => {
            bool ret = false;
            if ((bool)f) {
                t.set_object (device);
                ret = true;
            }
            return ret;
        });

        device.bind_property ("display-name", titleLabel, "label", GLib.BindingFlags.SYNC_CREATE);
        device.bind_property ("icon-name", headerIcon, "icon-name", GLib.BindingFlags.SYNC_CREATE);

        device.changed.connect (on_device_changed);

        // TODO: fix channel added /removed for a device
        device.channel_added.connect (on_device_channels_changed);
        device.manager.channel_added.connect (on_device_channels_changed);
        device.channel_removed.connect (on_device_channels_changed);
        device.manager.channel_removed.connect (on_device_channels_changed);
        on_device_changed ();
    }

    public DeviceSettingsPage (Device inDevice) {
        GLib.Object (
            device: inDevice
        );
    }

    private void on_device_changed () {
        Gtk.ListStore profilesList = (Gtk.ListStore)m_ProfileSettings.get_model ();
        Gtk.TreeIter iter;

        int activeRow = 0, cpt = 0;
        profilesList.clear ();

        foreach (var profile in device.get_profiles ()) {
            profilesList.append (out iter);
            profilesList.set (iter, 0, profile.description, 1, profile.name);

            if (device.active_profile == profile) {
                activeRow = cpt;
            }
            cpt++;
        }
        m_ProfileSettings.set_active (activeRow);

        on_device_channels_changed  ();
    }

    private void on_device_channels_changed () {
        bool haveOutput = device.get_output_channels ().length > 0;
        bool haveInput = device.get_input_channels ().length > 0;

        m_OutputGrid.visible = haveOutput;
        m_InputGrid.visible = haveInput;

        m_OutputInputSwitcher.visible = haveOutput && haveInput;
    }
}