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

public class PantheonSoundControl.Widgets.DeviceSettingsPage  : Granite.SimpleSettingsPage {
    public unowned Device device { get; construct; }
    public bool active_device { get; private set; }

    construct {
        hscrollbar_policy = Gtk.PolicyType.NEVER;
        vscrollbar_policy = Gtk.PolicyType.NEVER;

        device.changed.connect (on_device_changed);
        on_device_changed ();
    }

    public DeviceSettingsPage (Device inDevice) {
        GLib.Object (
            device: inDevice,
            activatable: true,
            description: inDevice.description,
            icon_name: inDevice.icon_name,
            title: inDevice.display_name,
            status: inDevice.description
        );

        update_status ();

        status_switch.notify["active"].connect (update_status);
    }

    private void update_status () {
        if (status_switch.active) {
            status_type = Granite.SettingsPage.StatusType.SUCCESS;
            status = device.description + _(" (Default)");
        } else {
            status_type = Granite.SettingsPage.StatusType.NONE;
            status = device.description;
        }
    }

    private void on_device_changed () {
        active_device = device.get_output_ports ().length > 0 ||
                        device.get_input_ports ().length > 0;
    }
}