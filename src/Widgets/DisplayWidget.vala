/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * DisplayWidget.vala
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

public class PantheonSoundControl.Widgets.DisplayWidget  : Gtk.Grid {
    private Gtk.Image m_IconDevice;
    private unowned GLib.Binding m_ChannelBind;

    public unowned Manager manager { get; construct; }

    construct {
        m_IconDevice = new Gtk.Image ();
        m_IconDevice.icon_name = "audio-card-symbolic";
        m_IconDevice.icon_size = Gtk.IconSize.SMALL_TOOLBAR;

        manager.channel_added.connect (on_default_channel_changed);
        manager.channel_removed.connect (on_default_channel_changed);
        manager.notify["default-output-channel"].connect (on_default_channel_changed);

        on_default_channel_changed ();

        valign = Gtk.Align.CENTER;

        add (m_IconDevice);
    }

    public DisplayWidget (Manager inManager) {
        GLib.Object (
            manager: inManager
        );
    }

    private void on_default_channel_changed () {
        if (m_ChannelBind != null) {
            m_ChannelBind.unbind ();
            m_ChannelBind = null;
        }

        var defaultChannel = manager.default_output_channel;

        if (defaultChannel != null) {
            m_ChannelBind = defaultChannel.bind_property ("port", m_IconDevice, "icon-name", GLib.BindingFlags.SYNC_CREATE, (b, f, ref t) => {
                unowned Port? port = (Port)f;
                if (port != null) {
                    string i = port.icon_name;
                    if (i == "audio-speakers") {
                        i = "audio-card-symbolic";
                    } else {
                        i += "-symbolic";
                    }
                    t.set_string (i);
                }
                return true;
            });
        }
    }
}