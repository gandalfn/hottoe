/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * SwitchboardPlug.vala
 * Copyright (C) Nicolas Bruguier 2018 <gandalfn@club-internet.fr>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */


public class SukaHottoe.SwitchboardPlug : Switchboard.Plug {
    private Manager m_manager;
    private Widgets.DeviceSettingsView? m_view;

    construct {
        m_manager = Manager.get ("pulseaudio");
    }

    public SwitchboardPlug () {
        var settings = new Gee.TreeMap<string, string?> (null, null);
        settings.set ("sound-devices", null);
        Object (
            category: Category.HARDWARE,
            code_name: "hardware-suka-hottoe",
            display_name: _("Sound Devices"),
            description: _("Configure sound devices"),
            icon: "audio-card",
            supported_settings: settings
        );
    }

    public override Gtk.Widget get_widget () {
        if (m_view == null) {
            m_manager = Manager.get ("pulseaudio");

            m_view = new Widgets.DeviceSettingsView (m_manager);
            m_view.show_all ();

            m_manager.start ();
        }
        return m_view;
    }

    public override void shown () {
        if (m_manager != null) {
            m_manager.enable_monitoring = true;
        }
    }

    public override void hidden () {
        if (m_manager != null) {
            m_manager.enable_monitoring = false;
        }
    }

    public override void search_callback (string in_location) {
    }

    // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
    public override async Gee.TreeMap<string, string> search (string in_search) {
        var search_results = new Gee.TreeMap<string, string> ((GLib.CompareDataFunc<string>)GLib.strcmp,
                                                              (Gee.EqualDataFunc<string>)GLib.str_equal);
        return search_results;
    }
}


public Switchboard.Plug get_plug (GLib.Module in_module) {
    debug ("Activating Sound Device plug");
    return new SukaHottoe.SwitchboardPlug ();
}