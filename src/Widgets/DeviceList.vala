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

public class PantheonSoundControl.Widgets.DeviceList : Gtk.ScrolledWindow {
    private Gtk.Grid m_ListGrid;
    private Gtk.RadioButton m_DefaultDeviceGroup;

    public unowned Manager manager { get; construct; }

    public DeviceList (Manager inManager) {
        Object (
            manager: inManager
        );
    }

    construct {
        hscrollbar_policy = Gtk.PolicyType.NEVER;
        vscrollbar_policy = Gtk.PolicyType.NEVER;

        m_ListGrid = new Gtk.Grid ();
        m_ListGrid.orientation = Gtk.Orientation.VERTICAL;

        add (m_ListGrid);

        m_DefaultDeviceGroup = new Gtk.RadioButton (null);

        manager.device_added.connect (on_device_added);
    }

    private void on_device_added (Device inDevice) {
        var view = new DeviceView (inDevice);
        view.hexpand = true;
        view.group = m_DefaultDeviceGroup;
        m_ListGrid.add (view);
    }
}