/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Indicator.vala
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

public class Hottoe.Indicator : Wingpanel.Indicator {
    private Manager m_manager;
    private Widgets.IndicatorIcon? m_indicator_icon;
    private Widgets.IndicatorView m_indicator_view;
    private uint m_timeout_active;

    construct {
        // TODO: Disable desktop notification since we have a problem when wingpanel has
        // emitter and receiver of notification
        Services.DesktopNotification.enabled = false;

        m_manager = Manager.get ("pulseaudio");
        m_manager.start ();

        m_indicator_icon = new Widgets.IndicatorIcon (m_manager);

        m_indicator_view = new Widgets.IndicatorView (m_manager);
        m_indicator_view.open_settings.connect (show_settings);
    }

    public Indicator (Wingpanel.IndicatorManager.ServerType in_server_type) {
        // very ugly hack when set code name to set position of indicator before
        // sound indicator since they are sorted by name and type name
        Object (code_name: Wingpanel.Indicator.SYNC,
                display_name: _("Sound Devices"),
                description: _("The Sound Devices indicator"),
                visible: true);
    }

    public override Gtk.Widget get_display_widget () {
        return m_indicator_icon;
    }

    public override Gtk.Widget? get_widget () {
        return m_indicator_view;
    }

    public override void opened () {
        if (m_manager != null) {
            if (m_timeout_active != 0) {
                GLib.Source.remove (m_timeout_active);
                m_timeout_active = 0;
            }
            m_manager.enable_monitoring = true;
        }

        Services.DesktopNotification.enabled = false;
        Services.SoundNotification.enabled = true;
    }

    public override void closed () {
        if (m_manager != null) {
            if (m_timeout_active != 0) {
                GLib.Source.remove (m_timeout_active);
                m_timeout_active = 0;
            }

            m_timeout_active = GLib.Timeout.add_seconds (2, ()=> {
                m_manager.enable_monitoring = false;

                return true;
            });
        }

        // TODO: Disable desktop notification since we have a problem when wingpanel has
        // emitter and receiver of notification
        Services.DesktopNotification.enabled = false;
        Services.SoundNotification.enabled = false;
    }

    private void show_settings () {
        close ();

        try {
            GLib.AppInfo.launch_default_for_uri ("settings://sound-devices", null);
        } catch (Error e) {
            warning ("%s\n", e.message);
        }
    }
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType in_server_type) {
    debug ("Activating Sound Devices Indicator");

    if (in_server_type != Wingpanel.IndicatorManager.ServerType.SESSION) {
        debug ("Wingpanel is not in session, not loading chat");
        return null;
    }

    var indicator = new Hottoe.Indicator (in_server_type);
    return indicator;
}

