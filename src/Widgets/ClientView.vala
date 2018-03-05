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

public class SukaHottoe.Widgets.ClientView : Gtk.Grid {
    private Gtk.Revealer m_content;
    private Gtk.Grid m_plugs;

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

        var client_label = new MaxWidthLabel (180);
        client_label.xalign = 0;
        client_label.hexpand = true;
        client_label.ellipsize = Pango.EllipsizeMode.END;
        client_label.get_style_context ().add_class ("h3");

        grid.attach (client_label, 1, 0, 1, 1);

        m_plugs = new Gtk.Grid ();
        m_plugs.vexpand = true;
        m_plugs.valign = Gtk.Align.CENTER;
        m_plugs.orientation = Gtk.Orientation.VERTICAL;

        grid.attach (m_plugs, 2, 0, 1, 1);

        m_content = new Gtk.Revealer ();
        m_content.reveal_child = false;
        m_content.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;

        m_content.add (grid);

        add (m_content);

        m_content.bind_property ("reveal-child", this, "active", GLib.BindingFlags.SYNC_CREATE);
        client.bind_property ("name", client_label, "label", GLib.BindingFlags.SYNC_CREATE);

        client.plug_added.connect_after (on_client_plug_added);
        client.plug_removed.connect_after (on_client_plug_removed);

        client.notify["is-mine"].connect (on_is_mine_changed);
        on_is_mine_changed ();
    }

    public ClientView (Client in_client) {
        GLib.Object (
            client: in_client
        );
    }

    private void on_is_mine_changed () {
        m_content.reveal_child = !client.is_mine && (client.get_plugs ().length > 0);
    }

    private void on_client_plug_added (Plug in_plug) {
        var plug = new PlugChannelList (in_plug);
        plug.show_all ();
        m_plugs.add (plug);

        m_content.reveal_child = !client.is_mine && (client.get_plugs ().length > 0);
    }

    private void on_client_plug_removed (Plug in_plug) {
        m_plugs.get_children ().foreach ((child) => {
            unowned PlugChannelList? list = child as PlugChannelList;
            if (list != null && list.plug == in_plug) {
                child.destroy ();
            }
        });

        m_content.reveal_child = !client.is_mine && (client.get_plugs ().length > 0);
    }
}
