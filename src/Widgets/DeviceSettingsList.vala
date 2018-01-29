/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * DeviceSettingsList.vala
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

public class PantheonSoundControl.Widgets.DeviceSettingsList : Gtk.ScrolledWindow {
    private Gtk.ListBox m_ListBox;

    public unowned Manager manager { get; construct; }

    public Gtk.Stack stack { get; private set; }

    public string? visible_device {
        get {
            var selected_row = m_ListBox.get_selected_row ();

            if (selected_row == null) {
                return null;
            } else {
                return ((DeviceSettingsListRow) selected_row).name;
            }
        }
        set {
            foreach (unowned Gtk.Widget child in m_ListBox.get_children ()) {
                if (((DeviceSettingsListRow) child).page.device.name == value) {
                    m_ListBox.select_row ((Gtk.ListBoxRow) child);
                    break;
                }
            }
        }
    }

    public DeviceSettingsList (Manager inManager) {
        Object (
            manager: inManager
        );
    }

    construct {
        hscrollbar_policy = Gtk.PolicyType.NEVER;
        vscrollbar_policy = Gtk.PolicyType.NEVER;
        width_request = 200;

        m_ListBox = new Gtk.ListBox ();
        m_ListBox.activate_on_single_click = true;
        m_ListBox.selection_mode = Gtk.SelectionMode.SINGLE;

        add (m_ListBox);

        m_ListBox.row_selected.connect ((row) => {
            stack.visible_child = ((DeviceSettingsListRow) row).page;
        });

        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        manager.device_added.connect (on_device_added);
        manager.device_removed.connect (on_device_removed);
    }

    private void on_device_added (Device inDevice) {
        var page = new DeviceSettingsPage (inDevice);
        page.show_all ();
        stack.add_named (page, inDevice.name);

        var row = new DeviceSettingsListRow (page);
        row.show_all ();
        m_ListBox.add (row);

        if (inDevice.active && visible_device == null) {
            visible_device = inDevice.name;
        }

        inDevice.notify["active"].connect (on_device_active_changed);
    }

    private void on_device_removed (Device inDevice) {
        inDevice.notify["active"].disconnect (on_device_active_changed);

        foreach (unowned Gtk.Widget child in m_ListBox.get_children ()) {
            unowned DeviceSettingsListRow? row = child as DeviceSettingsListRow;
            if (row != null && row.page.device == inDevice) {
                row.page.destroy ();
                row.destroy ();
                break;
            }
        }
    }

    private void on_device_active_changed () {
        bool needUpdate = false;
        var listRow = m_ListBox.get_selected_row ();
        if (listRow != null) {
            unowned DeviceSettingsListRow? row = listRow as DeviceSettingsListRow;
            needUpdate = row == null || !row.page.device.active;
        } else {
            needUpdate = true;
        }

        if (needUpdate) {
            foreach (unowned Gtk.Widget child in m_ListBox.get_children ()) {
                unowned DeviceSettingsListRow? rowChild = child as DeviceSettingsListRow;
                if (rowChild != null && rowChild.page.device.active) {
                    visible_device = rowChild.page.device.name;
                    break;
                }
            }
        }
    }
}