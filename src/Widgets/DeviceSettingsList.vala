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
            foreach (unowned Gtk.Widget m_ListBox_child in m_ListBox.get_children ()) {
                if (((DeviceSettingsListRow) m_ListBox_child).page.device.name == value) {
                    m_ListBox.select_row ((Gtk.ListBoxRow) m_ListBox_child);
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

        on_sidebar_changed ();
        stack.add.connect (on_sidebar_changed);
        stack.remove.connect (on_sidebar_changed);

        manager.device_added.connect (on_device_added);
    }

    private void on_sidebar_changed () {
        m_ListBox.get_children ().foreach ((m_ListBox_child) => {
            m_ListBox_child.destroy ();
        });

        stack.get_children ().foreach ((child) => {
            if (child is DeviceSettingsPage) {
                var row = new DeviceSettingsListRow ((DeviceSettingsPage) child);
                m_ListBox.add (row);
            }
        });

        m_ListBox.show_all ();
    }

    private void on_device_added (Device inDevice) {
        var page = new DeviceSettingsPage (inDevice);
        page.show_all ();
        stack.add_named (page, inDevice.name);

        if (page.active_device && visible_device == null) {
            visible_device = inDevice.name;
        }
    }
}