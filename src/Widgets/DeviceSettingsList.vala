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

public class Hottoe.Widgets.DeviceSettingsList : Gtk.ScrolledWindow {
    private Gtk.ListBox m_list_box;

    public unowned Manager manager { get; construct; }

    public Gtk.Stack stack { get; private set; }

    public string? visible_device {
        get {
            var selected_row = m_list_box.get_selected_row ();

            if (selected_row == null) {
                return null;
            } else {
                return ((DeviceSettingsListRow) selected_row).name;
            }
        }
        set {
            foreach (unowned Gtk.Widget child in m_list_box.get_children ()) {
                if (((DeviceSettingsListRow) child).page.device.name == value) {
                    m_list_box.select_row ((Gtk.ListBoxRow) child);
                    break;
                }
            }
        }
    }

    public DeviceSettingsList (Manager in_manager) {
        Object (
            manager: in_manager
        );
    }

    construct {
        hscrollbar_policy = Gtk.PolicyType.NEVER;
        vscrollbar_policy = Gtk.PolicyType.NEVER;
        width_request = 200;

        m_list_box = new Gtk.ListBox ();
        m_list_box.activate_on_single_click = true;
        m_list_box.selection_mode = Gtk.SelectionMode.SINGLE;

        add (m_list_box);

        m_list_box.row_selected.connect ((row) => {
            stack.visible_child = ((DeviceSettingsListRow) row).page;
        });

        stack = new Gtk.Stack ();

        manager.device_added.connect (on_device_added);
        manager.device_removed.connect (on_device_removed);
    }

    private void on_device_added (Device in_device) {
        var page = new DeviceSettingsPage (in_device);
        page.show_all ();
        stack.add_named (page, in_device.name);

        var row = new DeviceSettingsListRow (page);
        row.show_all ();
        m_list_box.add (row);

        if (in_device.active && visible_device == null) {
            visible_device = in_device.name;
        }

        in_device.notify["active"].connect (on_device_active_changed);
    }

    private void on_device_removed (Device in_device) {
        unowned DeviceSettingsListRow? selected_row = m_list_box.get_selected_row () as DeviceSettingsListRow;
        bool selected_removed = selected_row != null && selected_row.page.device == in_device;

        in_device.notify["active"].disconnect (on_device_active_changed);

        foreach (unowned Gtk.Widget child in m_list_box.get_children ()) {
            unowned DeviceSettingsListRow? row = child as DeviceSettingsListRow;
            if (row != null) {
                if (row.page.device == in_device) {
                    row.page.destroy ();
                    row.destroy ();
                } else if (selected_removed && row.page.device.active) {
                    visible_device = row.page.device.name;
                }
            }
        }
    }

    private void on_device_active_changed () {
        bool need_update = false;
        var list_row = m_list_box.get_selected_row ();
        if (list_row != null) {
            unowned DeviceSettingsListRow? row = list_row as DeviceSettingsListRow;
            need_update = row == null || !row.page.device.active;
        } else {
            need_update = true;
        }

        if (need_update) {
            foreach (unowned Gtk.Widget child in m_list_box.get_children ()) {
                unowned DeviceSettingsListRow? row_child = child as DeviceSettingsListRow;
                if (row_child != null && row_child.page.device.active) {
                    visible_device = row_child.page.device.name;
                    break;
                }
            }
        }
    }
}