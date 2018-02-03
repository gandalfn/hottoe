/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * DesktopNotification.vala
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

public class PantheonSoundControl.Services.DesktopNotification : Services.Notification {
    private string m_id;
    private GLib.Notification m_notification;

    public static bool enabled { get; set; }

    public DesktopNotification.device_available (Device in_device) {
        m_id = "sound-device-available";
        m_notification = new GLib.Notification (_("Sound device available"));
        string body = in_device.display_name;
        if (in_device.active_profile != null) {
            body += @"\n$(in_device.active_profile.description)";
        }
        m_notification.set_body (body);
        var device_icon = new Widgets.DeviceIcon (in_device);
        m_notification.set_icon (device_icon.gicon);
    }

    public DesktopNotification.device_not_available (Device in_device) {
        m_id = "sound-device-not-available";
        m_notification = new GLib.Notification (_("Sound device disconnected"));
        string body = in_device.display_name;
        if (in_device.active_profile != null) {
            body += @"\n$(in_device.active_profile.description)";
        }
        m_notification.set_body (body);
        var device_icon = new Widgets.DeviceIcon (in_device);
        m_notification.set_icon (device_icon.gicon);
    }

    public override void send () {
        if (enabled && m_notification != null) {
            GLib.Application.get_default ().send_notification (m_id, m_notification);
        }
    }
}