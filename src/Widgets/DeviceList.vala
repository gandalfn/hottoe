/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * DeviceList.vala
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

public class Hottoe.Widgets.DeviceList : Gtk.ScrolledWindow {
    private Gtk.Grid m_list_grid;
    private Gtk.RadioButton m_default_device_group;

    public unowned Manager manager { get; construct; }

    public DeviceList (Manager in_manager) {
        Object (
            manager: in_manager
        );
    }

    construct {
        hscrollbar_policy = Gtk.PolicyType.NEVER;
        vscrollbar_policy = Gtk.PolicyType.NEVER;

        m_list_grid = new Gtk.Grid ();
        m_list_grid.orientation = Gtk.Orientation.VERTICAL;

        add (m_list_grid);

        m_default_device_group = new Gtk.RadioButton (null);

        manager.device_added.connect (on_device_added);
        manager.device_removed.connect (on_device_removed);
    }

    private void on_device_added (Device in_device) {
        var view = new DeviceView (in_device);
        view.hexpand = true;
        view.group = m_default_device_group;
        view.show_all ();
        m_list_grid.add (view);
    }

    private void on_device_removed (Device in_device) {
        m_list_grid.get_children ().foreach ((child) => {
            unowned DeviceView? view = child as DeviceView;
            if (view != null && view.device == in_device) {
                child.destroy ();
            }
        });

        var notification = new Services.DesktopNotification.device_not_available (in_device);
        notification.send ();
    }
}