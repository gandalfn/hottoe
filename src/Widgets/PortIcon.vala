/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * PortIcon.vala
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

public class PantheonSoundControl.Widgets.PortIcon : PantheonSoundControl.Widgets.Icon {
    private unowned Port m_port;
    private GLib.Binding m_port_icon_bind;
    private GLib.Binding m_port_symbol_bind;

    [CCode (notify = false)]
    public unowned Port port {
        get {
            return m_port;
        }
        set {
            if (m_port != value) {
                if (m_port != null) {
                    m_port.remove_toggle_ref (on_port_destroyed);
                    m_port_icon_bind.unbind ();
                    m_port_symbol_bind.unbind ();
                }
                m_port = value;
                if (m_port != null) {
                    m_port.add_toggle_ref (on_port_destroyed);
                    m_port_icon_bind = m_port.bind_property ("icon-name", m_icon,
                                                             "icon-name", GLib.BindingFlags.SYNC_CREATE,
                                                             on_port_icon_changed);
                    m_port_symbol_bind = m_port.bind_property ("icon-name", m_symbol,
                                                               "icon-name", GLib.BindingFlags.SYNC_CREATE,
                                                               on_port_symbol_changed);
                } else {
                    if (use_symbolic) {
                        m_icon.icon_name = "audio-card-symbolic";
                    } else {
                        m_icon.icon_name = "audio-card";
                    }
                    m_symbol.icon_name = "";
                    m_symbol.hide ();
                }
            }
        }
    }

    public override GLib.Icon gicon {
       owned get {
            string port_icon_name = port.icon_name;
            string icon_name = port_icon_name;

            switch (port_icon_name) {
                case "headset-output":
                case "headset-input":
                    icon_name = "audio-headset";
                    break;

                case "phone-output":
                case "phone-input":
                    icon_name = "phone";
                    break;

                default:
                    break;
            }

            if (use_symbolic) {
                if (icon_name == "audio-speakers") {
                    icon_name = "audio-card-symbolic";
                } else {
                    icon_name += "-symbolic";
                }
            }

            return new GLib.ThemedIcon.with_default_fallbacks (icon_name);
        }
    }

    public PortIcon (Port? in_port = null, Icon.Size in_size = Icon.Size.LARGE, bool in_use_symbolic = false) {
        GLib.Object (
            size: in_size,
            use_symbolic: in_use_symbolic,
            port: in_port
        );
    }

    ~PortIcon () {
        if (m_port != null) {
            m_port.remove_toggle_ref (on_port_destroyed);
        }
    }

    private bool on_port_icon_changed (GLib.Binding in_bind, GLib.Value in_from, ref GLib.Value inout_to) {
        string port_icon_name = (string)in_from;
        string icon_name = port_icon_name;

        switch (port_icon_name) {
            case "headset-output":
            case "headset-input":
                icon_name = "audio-headset";
                break;

            case "phone-output":
            case "phone-input":
                icon_name = "phone";
                break;

            default:
                break;
        }

        if (use_symbolic) {
            if (icon_name == "audio-speakers") {
                icon_name = "audio-card-symbolic";
            } else {
                icon_name += "-symbolic";
            }
        }

        inout_to.set_string (icon_name);

        return true;
    }

    private bool on_port_symbol_changed (GLib.Binding in_bind, GLib.Value in_from, ref GLib.Value inout_to) {
        string port_icon_name = (string)in_from;
        string icon_name = "";

        switch (port_icon_name) {
            case "headset-input":
            case "phone-input":
                icon_name = "audio-input-microphone";
                m_symbol.show ();
                break;

            case "video-display":
                if (m_port.direction == Direction.OUTPUT) {
                    icon_name = "audio-speakers";
                    m_symbol.show ();
                } else if (m_port.direction == Direction.INPUT) {
                    icon_name = "audio-input-microphone";
                    m_symbol.show ();
                } else {
                    m_symbol.hide ();
                }
                break;

            default:
                m_symbol.hide ();
                break;
        }

        if (use_symbolic) {
            icon_name += "-symbolic";
        }

        inout_to.set_string (icon_name);

        return true;
    }

    private void on_port_destroyed (GLib.Object in_object, bool in_is_last_ref) {
        if (in_is_last_ref) {
            m_port = null;
        }
    }
}