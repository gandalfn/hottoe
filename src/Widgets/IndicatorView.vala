/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * IndicatorView.vala
 * Copyright (C) Nicolas Bruguier 2018 <gandalfn@club-internet.fr>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 */

public class PantheonSoundControl.Widgets.IndicatorView : Gtk.Box {
    private DeviceList m_device_list;
    private ClientList m_client_list;

    public unowned Manager manager { get; construct; }

    public signal void open_settings ();

    construct {
        orientation = Gtk.Orientation.VERTICAL;

        m_device_list = new DeviceList (manager);

        add (m_device_list);

        m_client_list = new ClientList (manager);

        add (m_client_list);

        var scan_button = new Wingpanel.Widgets.Button (_("Scan Sound Devices…"));
        scan_button.clicked.connect (() => {
            try {
                GLib.Process.spawn_command_line_async ("xrandr");
            }
            catch (GLib.Error err) {
                critical (err.message);
            }
        });
        add (scan_button);

        var settings_button = new Wingpanel.Widgets.Button (_("Sound Devices Settings…"));
        add (settings_button);
        settings_button.clicked.connect (() => {
            open_settings ();
        });
    }

    public IndicatorView (Manager in_manager) {
        GLib.Object (
            manager: in_manager
        );
    }
}