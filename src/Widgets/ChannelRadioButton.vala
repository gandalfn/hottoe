/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * ChannelRadioButton.vala
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

public class Hottoe.Widgets.ChannelRadioButton : Wingpanel.Widgets.Container {
    private bool m_active;
    private Gtk.Image m_check_icon;

    public unowned Channel channel { get; construct; }
    public unowned Gee.LinkedList<ChannelRadioButton> group { get; construct; }

    [CCode (notify = false)]
    public bool active {
        get {
            return m_active;
        }
        set {
            if (value != m_active) {
                m_active = value;
                if (m_active) {
                    m_check_icon.show ();

                    foreach (var crb in group) {
                        if (crb != this) {
                            crb.active = false;
                        }
                    }
                } else {
                    m_check_icon.hide ();
                }
                notify_property ("active");
            }
        }
    }

    construct {
        m_active = true;

        valign = Gtk.Align.CENTER;
        halign = Gtk.Align.CENTER;

        foreach (var crb in group) {
            if (crb.active) {
                m_active = false;
                break;
            }
        }

        var icon = new PortIcon (channel.port, Icon.Size.LARGE);

        m_check_icon = new Gtk.Image ();
        m_check_icon.icon_name = "emblem-default";
        m_check_icon.no_show_all = true;
        m_check_icon.halign = Gtk.Align.END;
        m_check_icon.valign = Gtk.Align.START;

        var overlay = new Gtk.Overlay ();
        overlay.width_request = 32;
        overlay.height_request = 32;
        overlay.add (icon);
        overlay.add_overlay (m_check_icon);

        content_widget.hexpand = false;
        content_widget.add (overlay);

        channel.bind_property ("port", icon, "port");

        clicked.connect (() => {
            if (!m_active) {
                active = true;
            }
        });

        if (!m_active) {
            m_check_icon.hide ();
        }
    }

    public ChannelRadioButton (Channel in_channel, Gee.LinkedList<ChannelRadioButton> in_group) {
        GLib.Object (
            content_widget: new Gtk.Grid (),
            channel: in_channel,
            group: in_group
        );
    }
}