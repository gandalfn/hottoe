/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * IndicatorIcon.vala
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

public class PantheonSoundControl.Widgets.IndicatorIcon : Gtk.Grid {
    private PortIcon m_icon;
    private unowned GLib.Binding m_channel_bind;

    public unowned Manager manager { get; construct; }

    construct {
        m_icon = new PortIcon (null, Icon.Size.SMALL, true);

        manager.channel_added.connect (on_default_channel_changed);
        manager.channel_removed.connect (on_default_channel_changed);
        manager.notify["default-output-channel"].connect (on_default_channel_changed);

        on_default_channel_changed ();

        valign = Gtk.Align.CENTER;

        add (m_icon);
    }

    public IndicatorIcon (Manager in_manager) {
        GLib.Object (
            manager: in_manager
        );
    }

    private void on_default_channel_changed () {
        if (m_channel_bind != null) {
            m_channel_bind.unbind ();
            m_channel_bind = null;
        }

        var default_channel = manager.default_output_channel;

        if (default_channel != null) {
            m_channel_bind = default_channel.bind_property ("port", m_icon, "port", GLib.BindingFlags.SYNC_CREATE);
        } else {
            m_icon.port = null;
        }
    }
}