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
    private string m_Id;
    private GLib.Notification m_Notification;

    public static bool enabled { get; set; }

    public DesktopNotification.device_available (Device inDevice) {
        m_Id = "sound-device-available";
        m_Notification = new GLib.Notification (_("Sound device %s available").printf (inDevice.display_name));
        if (inDevice.active_profile != null) {
            m_Notification.set_body (inDevice.active_profile.description);
        }
        var deviceIcon = new Widgets.DeviceIcon (inDevice);
        m_Notification.set_icon (deviceIcon.gicon);
    }

    public DesktopNotification.device_not_available (Device inDevice) {
        m_Id = "sound-device-not-available";
        m_Notification = new GLib.Notification (_("Sound device %s disconnected").printf (inDevice.display_name));
        if (inDevice.active_profile != null) {
            m_Notification.set_body (inDevice.active_profile.description);
        }
        var deviceIcon = new Widgets.DeviceIcon (inDevice);
        m_Notification.set_icon (deviceIcon.gicon);
    }

    public override void send () {
        if (enabled && m_Notification != null) {
            GLib.Application.get_default ().send_notification (m_Id, m_Notification);
        }
    }
}