/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * ClientView.vala
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

public class PantheonSoundControl.Widgets.ClientView : Gtk.Grid {
    private Gtk.Image m_ClientIcon;
    private Gtk.Label m_ClientLabel;
    private Gtk.Revealer m_Content;
    private Gtk.Grid m_Plugs;
    private Wnck.Window m_Window;

    public unowned Client client { get; construct; }
    public bool active { get; set; default = false; }

    static construct {
        Wnck.set_default_mini_icon_size (48);
    }

    construct {
        hexpand = true;

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.margin_bottom = 6;

        m_ClientIcon = new Gtk.Image ();
        m_ClientIcon.margin_start = 6;
        m_ClientIcon.pixel_size = 32;
        m_ClientIcon.halign = Gtk.Align.START;

        grid.attach (m_ClientIcon, 0, 0, 1, 1);

        m_ClientLabel = new MaxWidthLabel (180);
        m_ClientLabel.xalign = 0;
        m_ClientLabel.hexpand = true;
        m_ClientLabel.ellipsize = Pango.EllipsizeMode.END;
        m_ClientLabel.get_style_context ().add_class ("h3");

        grid.attach (m_ClientLabel, 1, 0, 1, 1);

        m_Plugs = new Gtk.Grid ();
        m_Plugs.vexpand = true;
        m_Plugs.valign = Gtk.Align.CENTER;
        m_Plugs.orientation = Gtk.Orientation.VERTICAL;

        grid.attach (m_Plugs, 2, 0, 1, 1);

        m_Content = new Gtk.Revealer ();
        m_Content.reveal_child = false;
        m_Content.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;

        m_Content.add (grid);

        add (m_Content);

        m_Content.bind_property ("reveal-child", this, "active");

        client.plug_added.connect_after (on_client_plug_added);
        client.plug_removed.connect_after (on_client_plug_removed);

        client.notify["pid"].connect (on_pid_changed);
        on_pid_changed ();
    }

    public ClientView (Client inClient) {
        GLib.Object (
            client: inClient
        );
    }

    private void on_pid_changed () {
        if (m_Window != null) {
            m_Window.name_changed.disconnect (on_name_changed);
            m_Window.icon_changed.disconnect (on_icon_changed);
            m_Window = null;
        }

        unowned Wnck.Screen screen = Wnck.Screen.get_default();
        foreach (unowned Wnck.Window win in screen.get_windows()) {
            if (win.get_pid () == client.pid) {
                m_Window = win;
                m_Window.name_changed.connect (on_name_changed);
                m_Window.icon_changed.connect (on_icon_changed);
                break;
            }
        }

        on_name_changed ();
        on_icon_changed ();

        m_Content.reveal_child = m_Window != null && (client.get_plugs ().length > 0);
    }

    private void on_name_changed () {
        if (m_Window != null) {
            if (m_Window.has_name ()) {
                if ("\n" in m_Window.get_name ()) {
                    m_ClientLabel.label = client.name;
                } else {
                    m_ClientLabel.label = m_Window.get_name ();
                }
            }
        } else {
            m_ClientLabel.label = client.name;
        }
    }

    private void on_icon_changed () {
        if (m_Window != null) {
            m_ClientIcon.pixbuf = m_Window.get_mini_icon ();
        } else {
            m_ClientIcon.icon_name = "application-default-icon";
        }
    }

    private void on_client_plug_added (Plug inPlug) {
        message (@"client $(client.name) plug added $(client.get_plugs ().length > 0)");

        var plug = new PlugChannelList (inPlug);
        plug.show_all ();
        m_Plugs.add (plug);

        m_Content.reveal_child = m_Window != null && (client.get_plugs ().length > 0);
    }

    private void on_client_plug_removed (Plug inPlug) {
        message (@"client $(client.name) plug removed");

        m_Plugs.get_children ().foreach ((child) => {
            unowned PlugChannelList? list = child as PlugChannelList;
            if (list != null && list.plug == inPlug) {
                child.destroy ();
            }
        });

        m_Content.reveal_child = m_Window != null && (client.get_plugs ().length > 0);
    }
}
