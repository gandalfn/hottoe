/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * ClientIcon.vala
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

public class PantheonSoundControl.Widgets.ClientIcon : PantheonSoundControl.Widgets.Icon {
    private Wnck.Window m_Window;
    private Gdk.Pixbuf m_WindowIcon;

    public unowned Client client { get; construct; }

    public override GLib.Icon gicon {
       owned get {
            GLib.Icon ret;
            if (m_WindowIcon != null) {
                ret = m_WindowIcon;
            } else {
                ret = new GLib.ThemedIcon ("application-default-icon");
            }
            return ret;
        }
    }

    static construct {
        Wnck.set_default_mini_icon_size (64);
    }

    construct {
        client.notify["pid"].connect (on_client_pid_changed);

        on_client_pid_changed ();
    }

    public ClientIcon (Client inClient, Icon.Size inSize = Icon.Size.LARGE, bool inUseSymbolic = false) {
        GLib.Object (
            size: inSize,
            use_symbolic: inUseSymbolic,
            client: inClient
        );
    }

    private void on_client_pid_changed () {
        message (@"$(client.name) pid changed $(client.pid)");

        if (m_Window != null) {
            m_Window.icon_changed.disconnect (on_icon_changed);
            m_Window = null;
        }

        unowned Wnck.Screen screen = Wnck.Screen.get_default();
        screen.force_update ();
        foreach (unowned Wnck.Window win in screen.get_windows()) {
            message(@"window pid $(win.get_pid ())");
            if (win.get_pid () == client.pid) {
                m_Window = win;
                m_Window.icon_changed.connect (on_icon_changed);
                break;
            }
        }

        on_icon_changed ();
    }

    private void on_icon_changed () {
        if (m_Window != null) {
            m_WindowIcon = m_Window.get_mini_icon ();
        } else {
            m_WindowIcon = null;
        }

        if (m_WindowIcon != null) {
            m_Icon.pixbuf = m_WindowIcon.scale_simple (size.to_pixel_size (),
                                                       size.to_pixel_size (),
                                                       Gdk.InterpType.BILINEAR);
        } else {
            m_Icon.icon_name = "application-default-icon";
        }
    }
}