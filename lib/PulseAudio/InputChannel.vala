/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * InputChannel.vala
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

internal class SukaHottoe.PulseAudio.InputChannel : Channel {
    private bool m_is_muted;
    private double m_base_volume;

    public override double volume {
        get {
            return cvolume != null ? Channel.volume_to_double (cvolume.max ()) : 0.0;
        }
        set {
            global::PulseAudio.CVolume? cvol = cvolume;
            if (cvol != null) {
                cvol.scale (Channel.double_to_volume (value));
                ((Manager) manager).operations.set_source_volume_by_index (index, cvol);
            }
        }
    }

    public override float balance {
        get {
            return cvolume != null && channel_map != null ? cvolume.get_balance (channel_map) : 0.5f;
        }
        set {
            global::PulseAudio.CVolume? cvol = cvolume;
            if (cvol != null && channel_map != null) {
                cvol.set_balance (channel_map, value);
                ((Manager) manager).operations.set_source_volume_by_index (index, cvol);
            }
        }
    }

    public override bool is_muted {
        get {
            return m_is_muted;
        }
        set {
            m_is_muted = value;
            ((Manager) manager).operations.set_source_mute_by_index (index, m_is_muted);
        }
    }

    public override double volume_base {
        get {
            return m_base_volume;
        }
    }

    public override double volume_max {
        get {
            return volume_to_double (global::PulseAudio.Volume.NORM);
        }
    }

    public override unowned SukaHottoe.Port? port {
        get {
            return m_active_port;
        }
        set {
            if (m_active_port != value) {
                if (value != null) {
                    ((Manager)manager).operations.set_source_port_by_index (index, m_active_port.name, (s) => {
                        if (s) {
                            if (m_active_port != null) {
                                m_active_port.device.channel_removed (this);
                            }
                            m_active_port = (Port)value;
                            m_active_port.weak_ref (on_active_port_destroyed);
                            device = (Device)m_active_port.device;
                            notify_property ("port");
                        }
                    });
                } else if (m_active_port != null) {
                    m_active_port.weak_unref (on_active_port_destroyed);
                    m_active_port = null;
                    device = null;
                    notify_property ("port");
                }
            }
        }
    }

    public InputChannel (Manager in_manager, global::PulseAudio.SourceInfo in_source_info) {
        GLib.Object (
            manager: in_manager,
            direction: SukaHottoe.Direction.INPUT,
            index: in_source_info.index,
            id: in_source_info.proplist.gets (global::PulseAudio.Proplist.PROP_APPLICATION_ID),
            monitor_index: in_source_info.index,
            name: in_source_info.name,
            description: in_source_info.description
        );

        update (in_source_info);
    }

    ~InputChannel () {
        if (m_active_port != null) {
            m_active_port.weak_unref (on_active_port_destroyed);
            m_active_port = null;
        }
    }

    public bool update (global::PulseAudio.SourceInfo in_source_info) {
        bool updated = false;

        if (in_source_info.active_port != null &&
            (m_active_port == null || m_active_port.name != in_source_info.active_port.name)) {
            bool foundPort = false;
            foreach (var dev in manager.get_devices ()) {
                foreach (var port in dev.get_input_ports ()) {
                    if (port.name == in_source_info.active_port.name) {
                        if (m_active_port != null) {
                            m_active_port.weak_unref (on_active_port_destroyed);
                        }
                        m_active_port = (Port)port;
                        m_active_port.weak_ref (on_active_port_destroyed);
                        device = (Device)m_active_port.device;
                        notify_property ("port");
                        updated = true;
                        foundPort = true;
                        break;
                    }
                }
                if (foundPort) break;
            }

            if (!foundPort && m_active_port != null) {
                m_active_port.weak_unref (on_active_port_destroyed);
                m_active_port = null;
                device = null;
                notify_property ("port");
            }
        }

        bool send_volume_update = (cvolume == null ||
                                   volume != Channel.volume_to_double (in_source_info.volume.max ()));
        cvolume = in_source_info.volume;
        if (send_volume_update) {
            notify_property ("volume");
            updated = true;
        }

        bool send_balance_update = (cvolume == null ||
                                    channel_map == null ||
                                    balance != in_source_info.volume.get_balance (in_source_info.channel_map));
        channel_map = in_source_info.channel_map;
        if (send_balance_update) {
            notify_property ("balance");
            updated = true;
        }

        if (in_source_info.mute != m_is_muted) {
            m_is_muted = in_source_info.mute;
            notify_property ("is-muted");
            updated = true;
        }

        if (m_base_volume != in_source_info.base_volume) {
            m_base_volume = Channel.volume_to_double (in_source_info.base_volume);
            notify_property ("volume-base");
        }

        changed ();

        return updated;
    }

    private void on_active_port_destroyed () {
        m_active_port = null;
        notify_property ("port");
    }
}
