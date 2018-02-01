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
    private Gtk.Revealer m_Content;
    private Gtk.Grid m_Plugs;

    public unowned Client client { get; construct; }
    public bool active { get; set; default = false; }

    construct {
        hexpand = true;

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.margin_bottom = 6;

        var clientIcon = new ClientIcon (client, Icon.Size.EXTRA_LARGE);
        clientIcon.margin_start = 6;
        clientIcon.halign = Gtk.Align.START;

        grid.attach (clientIcon, 0, 0, 1, 1);

        var clientLabel = new MaxWidthLabel (180);
        clientLabel.xalign = 0;
        clientLabel.hexpand = true;
        clientLabel.ellipsize = Pango.EllipsizeMode.END;
        clientLabel.get_style_context ().add_class ("h3");

        grid.attach (clientLabel, 1, 0, 1, 1);

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

        m_Content.bind_property ("reveal-child", this, "active", GLib.BindingFlags.SYNC_CREATE);
        client.bind_property ("name", clientLabel, "label", GLib.BindingFlags.SYNC_CREATE);

        client.plug_added.connect_after (on_client_plug_added);
        client.plug_removed.connect_after (on_client_plug_removed);

        client.notify["is-mine"].connect (on_is_mine_changed);
        on_is_mine_changed ();
    }

    public ClientView (Client inClient) {
        GLib.Object (
            client: inClient
        );
    }

    private void on_is_mine_changed () {
        m_Content.reveal_child = !client.is_mine && (client.get_plugs ().length > 0);
    }

    private void on_client_plug_added (Plug inPlug) {
        var plug = new PlugChannelList (inPlug);
        plug.show_all ();
        m_Plugs.add (plug);

        m_Content.reveal_child = !client.is_mine && (client.get_plugs ().length > 0);
    }

    private void on_client_plug_removed (Plug inPlug) {
        m_Plugs.get_children ().foreach ((child) => {
            unowned PlugChannelList? list = child as PlugChannelList;
            if (list != null && list.plug == inPlug) {
                child.destroy ();
            }
        });

        m_Content.reveal_child = !client.is_mine && (client.get_plugs ().length > 0);
    }
}
