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

    construct {
        status_switch.notify["active"].connect (() => {
            if (!status_switch.active && device.manager.default_output_device == device) {
                status_switch.active = true;
            } else if (status_switch.active && device.manager.default_output_device != device) {
                device.manager.default_output_device = device;
            }
        });

        device.manager.bind_property ("default-output-device", status_switch, "active",
                                      GLib.BindingFlags.SYNC_CREATE,
                                      (b, f, ref t) => {
            unowned Device? defaultDevice = (Device)f;
            t.set_boolean (defaultDevice == device);
            return true;
        });

        device.manager.bind_property ("default-output-device", this, "status",
                                     GLib.BindingFlags.SYNC_CREATE,
                                     (b, f, ref t) => {
            unowned Device? defaultDevice = (Device)f;
            if (defaultDevice == device) {
                t.set_string (device.description + _(" (Default)"));
            } else {
                t.set_string (device.description);
            }
            return true;
        });
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
    }
}