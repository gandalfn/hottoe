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

public class Hottoe.Widgets.ClientIcon : Hottoe.Widgets.Icon {
    private Wnck.Window m_window;
    private Gdk.Pixbuf m_window_icon;

    public unowned Client client { get; construct; }

    public override GLib.Icon gicon {
       owned get {
            GLib.Icon ret;
            if (m_window_icon != null) {
                ret = m_window_icon;
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

    public ClientIcon (Client in_client, Icon.Size in_size = Icon.Size.LARGE, bool in_use_symbolic = false) {
        GLib.Object (
            size: in_size,
            use_symbolic: in_use_symbolic,
            client: in_client
        );
    }

    private void on_client_pid_changed () {
        if (m_window != null) {
            m_window.icon_changed.disconnect (on_icon_changed);
            m_window = null;
        }

        unowned Wnck.Screen screen = Wnck.Screen.get_default ();
        screen.force_update ();
        foreach (unowned Wnck.Window win in screen.get_windows ()) {
            if (win.get_pid () == client.pid) {
                m_window = win;
                m_window.icon_changed.connect (on_icon_changed);
                break;
            }
        }

        on_icon_changed ();
    }

    private void on_icon_changed () {
        if (m_window != null) {
            m_window_icon = m_window.get_mini_icon ();
        } else {
            m_window_icon = null;
        }

        if (m_window_icon != null) {
            m_icon.pixbuf = m_window_icon.scale_simple (size.to_pixel_size (),
                                                       size.to_pixel_size (),
                                                       Gdk.InterpType.BILINEAR);
        } else {
            m_icon.icon_name = "application-default-icon";
        }
    }
}