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

public class PantheonSoundControl.Widgets.ChannelRadioButton : Wingpanel.Widgets.Container {
    private bool m_Active;
    private Gtk.Image m_CheckIcon;

    public unowned Channel channel { get; construct; }
    public unowned Gee.LinkedList<ChannelRadioButton> group { get; construct; }

    [CCode (notify = false)]
    public bool active {
        get {
            return m_Active;
        }
        set {
            if (value != m_Active) {
                m_Active = value;
                if (m_Active) {
                    m_CheckIcon.show ();

                    foreach (var crb in group) {
                        if (crb != this) {
                            crb.active = false;
                        }
                    }
                } else {
                    m_CheckIcon.hide ();
                }
                notify_property ("active");
            }
        }
    }

    construct {
        m_Active = true;

        valign = Gtk.Align.CENTER;
        halign = Gtk.Align.CENTER;

        foreach (var crb in group) {
            if (crb.active) {
                m_Active = false;
                break;
            }
        }

        var icon = new Gtk.Image.from_icon_name (channel.port != null ? channel.port.icon_name : "audio-port", Gtk.IconSize.LARGE_TOOLBAR);
        icon.pixel_size = 24;

        m_CheckIcon = new Gtk.Image ();
        m_CheckIcon.icon_name = "account-logged-in";
        m_CheckIcon.no_show_all = true;
        m_CheckIcon.halign = Gtk.Align.END;
        m_CheckIcon.valign = Gtk.Align.START;

        var overlay = new Gtk.Overlay ();
        overlay.width_request = 32;
        overlay.height_request = 32;
        overlay.add (icon);
        overlay.add_overlay (m_CheckIcon);

        content_widget.hexpand = false;
        content_widget.add (overlay);

        channel.bind_property ("port", icon, "icon-name", GLib.BindingFlags.DEFAULT, (b, f, ref t) => {
            unowned Port? port = (Port)f;
            if (port != null) {
                t.set_string (port.icon_name);
            }
            return true;
        });

        clicked.connect (() => {
            if (!m_Active) {
                active = true;
            }
        });

        if (!m_Active) {
            m_CheckIcon.hide ();
        }
    }

    public ChannelRadioButton (Channel inChannel, Gee.LinkedList<ChannelRadioButton> inGroup) {
        GLib.Object (
            content_widget: new Gtk.Grid (),
            channel: inChannel,
            group: inGroup
        );
    }
}