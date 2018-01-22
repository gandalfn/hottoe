/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * ClientList.vala
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

public class PantheonSoundControl.Widgets.ClientList : Gtk.Grid {
    private Gtk.Revealer m_Content;
    private Gtk.Grid m_ListGrid;

    public unowned Manager manager { get; construct; }

    public ClientList (Manager inManager) {
        Object (
            manager: inManager
        );
    }

    construct {
        orientation = Gtk.Orientation.VERTICAL;

        m_ListGrid = new Gtk.Grid ();
        m_ListGrid.orientation = Gtk.Orientation.VERTICAL;

        var content_area = new Gtk.Grid ();
        content_area.orientation = Gtk.Orientation.VERTICAL;
        content_area.add (m_ListGrid);
        content_area.add (new Wingpanel.Widgets.Separator ());

        m_Content = new Gtk.Revealer ();
        m_Content.reveal_child = false;
        m_Content.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        m_Content.add (content_area);

        add (m_Content);

        manager.client_added.connect (on_client_added);
        manager.client_removed.connect (on_client_removed);
    }

    private void on_client_added (Client inClient) {
        var view = new ClientView (inClient);
        view.hexpand = true;
        view.show_all ();
        m_ListGrid.add (view);

        view.notify["active"].connect (on_client_active_changed);
        on_client_active_changed ();
    }

    private void on_client_removed (Client inClient) {
        m_ListGrid.get_children ().foreach ((child) => {
            unowned ClientView? view = child as ClientView;
            if (view != null && view.client == inClient) {
                child.destroy ();
            }
        });

        on_client_active_changed ();
    }

    private void on_client_active_changed () {
        bool viewVisible = false;

        m_ListGrid.get_children ().foreach ((child) => {
            unowned ClientView? view = child as ClientView;
            if (view != null && view.active) {
                viewVisible = true;
            }
        });
        m_Content.reveal_child = viewVisible;
    }
}