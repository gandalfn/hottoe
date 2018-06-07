/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * DeviceIcon.vala
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

public class Hottoe.Widgets.DeviceIcon : Hottoe.Widgets.Icon {
    public unowned Device device { get; construct; }

    public override GLib.Icon gicon {
       owned get {
            string dev_icon_name = device.icon_name;
            string icon_name = dev_icon_name;

            switch (dev_icon_name) {
                case "audio-card-pci":
                    icon_name = "audio-card";
                    break;

                case "audio-card-bluetooth":
                    icon_name = "bluetooth";
                    break;
            }

            if ("HDMI" in device.display_name) {
                icon_name = "video-display";
            }

            return new GLib.ThemedIcon.with_default_fallbacks (icon_name);
        }
    }

    construct {
        string dev_icon_name = device.icon_name;
        string icon_name = dev_icon_name;

        switch (dev_icon_name) {
            case "audio-card-bluetooth":
                icon_name = "bluetooth";
                break;
        }

        if ("HDMI" in device.display_name) {
            icon_name = "video-display";
        }

        m_icon.icon_name = icon_name;
    }

    public DeviceIcon (Device in_device, Icon.Size in_size = Icon.Size.LARGE, bool in_use_symbolic = false) {
        GLib.Object (
            size: in_size,
            use_symbolic: in_use_symbolic,
            device: in_device
        );
    }
}