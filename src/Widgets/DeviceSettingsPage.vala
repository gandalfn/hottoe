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
        var profileSettings = new Gtk.ComboBox ();
        profileSettings.width_request = 180;
        profileSettings.pack_start (renderer, true);
        profileSettings.add_attribute (renderer, "text", 0);
        headerArea.attach (profileSettings, 1, 1, 1, 1);

        var statusSwitch = new Gtk.Switch ();
        statusSwitch.hexpand = true;
        statusSwitch.halign = Gtk.Align.END;
        statusSwitch.valign = Gtk.Align.CENTER;
        headerArea.attach (statusSwitch, 2, 0, 1, 1);
        statusSwitch.button_press_event.connect (() => {
            return statusSwitch.active;
        });

        Gtk.ListStore profilesList = new Gtk.ListStore (2, typeof (string), typeof (string));
        Gtk.TreeIter iter;

        int activeRow = 0, cpt = 0;
        foreach (var profile in device.get_profiles ()) {
            profilesList.append (out iter);
            profilesList.set (iter, 0, profile.description, 1, profile.name);

            if (device.active_profile == profile) {
                activeRow = cpt;
            }
            cpt++;
        }
        profileSettings.set_model (profilesList);
        profileSettings.set_active (activeRow);

        var contentArea = new Gtk.Grid ();
        contentArea.orientation = Gtk.Orientation.VERTICAL;
        contentArea.column_spacing = 12;
        contentArea.row_spacing = 12;
        contentArea.vexpand = true;

        var outputGrid = new Gtk.Grid ();
        outputGrid.orientation = Gtk.Orientation.VERTICAL;
        outputGrid.row_spacing = 24;
        outputGrid.margin_start = 12;

        var outputChannels = new DeviceChannelList (device, Direction.OUTPUT);
        outputChannels.show_labels = true;
        outputChannels.show_balance = true;
        outputChannels.icon_size = Gtk.IconSize.DIALOG;
        outputChannels.icon_pixel_size = 48;
        outputChannels.monitor_nb_bars = 20.0;
        outputGrid.add (outputChannels);

        var outputPlugs = new PlugSettingsList (device, Direction.OUTPUT);
        outputGrid.add (outputPlugs);

        var inputGrid = new Gtk.Grid ();
        inputGrid.orientation = Gtk.Orientation.VERTICAL;
        inputGrid.row_spacing = 24;
        inputGrid.margin_start = 12;
        var inputChannels = new DeviceChannelList (device, Direction.INPUT);
        inputChannels.show_labels = true;
        inputChannels.show_balance = true;
        inputChannels.icon_size = Gtk.IconSize.DIALOG;
        inputChannels.icon_pixel_size = 48;
        inputChannels.monitor_nb_bars = 20.0;
        inputGrid.add (inputChannels);

        var inputPlugs = new PlugSettingsList (device, Direction.INPUT);
        inputGrid.add (inputPlugs);

        var stack = new Gtk.Stack ();
        stack.expand = true;

        var stack_switcher = new Gtk.StackSwitcher ();
        stack_switcher.halign = Gtk.Align.CENTER;
        stack_switcher.homogeneous = true;
        stack_switcher.margin = 12;
        stack_switcher.stack = stack;

        stack.add_titled (outputGrid, "output", _("Output"));
        stack.add_titled (inputGrid, "input", _("Input"));
        contentArea.add (stack_switcher);
        contentArea.add (stack);

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
    }

    public DeviceSettingsPage (Device inDevice) {
        GLib.Object (
            device: inDevice
        );
    }
}