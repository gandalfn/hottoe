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

internal class PantheonSoundControl.PulseAudio.InputChannel : Channel {
    private bool m_IsMuted;
    private double m_BaseVolume;

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
            return m_IsMuted;
        }
        set {
            m_IsMuted = value;
            ((Manager) manager).operations.set_source_mute_by_index (index, m_IsMuted);
        }
    }

    public override double volume_base {
        get {
            return m_BaseVolume;
        }
    }

    public override double volume_max {
        get {
            return volume_to_double (global::PulseAudio.Volume.NORM);
        }
    }

    public override unowned PantheonSoundControl.Port? port {
        get {
            return m_ActivePort;
        }
        set {
            if (m_ActivePort != value) {
                if (value != null) {
                    ((Manager)manager).operations.set_source_port_by_index (index, m_ActivePort.name, (s) => {
                        if (s) {
                            if (m_ActivePort != null) {
                                m_ActivePort.device.channel_removed (this);
                            }
                            m_ActivePort = (Port)value;
                            m_ActivePort.weak_ref (on_active_port_destroyed);
                            device = (Device)m_ActivePort.device;
                            notify_property ("port");
                        }
                    });
                } else if (m_ActivePort != null) {
                    m_ActivePort.weak_unref (on_active_port_destroyed);
                    m_ActivePort = null;
                    device = null;
                    notify_property ("port");
                }
            }
        }
    }

    public InputChannel (Manager inManager, global::PulseAudio.SourceInfo inSourceInfo) {
        GLib.Object (
            manager: inManager,
            direction: PantheonSoundControl.Direction.INPUT,
            index: inSourceInfo.index,
            monitor_index: inSourceInfo.index,
            name: inSourceInfo.name,
            description: inSourceInfo.description
        );

        update (inSourceInfo);
    }

    ~InputChannel () {
        if (m_ActivePort != null) {
            m_ActivePort.weak_unref (on_active_port_destroyed);
            m_ActivePort = null;
        }
    }

    public bool update (global::PulseAudio.SourceInfo inSourceInfo) {
        bool updated = false;

        if (inSourceInfo.active_port != null && (m_ActivePort == null || m_ActivePort.name != inSourceInfo.active_port.name)) {
            bool foundPort = false;
            foreach (var dev in manager.get_devices ()) {
                foreach (var port in dev.get_input_ports ()) {
                    if (port.name == inSourceInfo.active_port.name) {
                        if (m_ActivePort != null) {
                            m_ActivePort.weak_unref (on_active_port_destroyed);
                        }
                        m_ActivePort = (Port)port;
                        m_ActivePort.weak_ref (on_active_port_destroyed);
                        device = (Device)m_ActivePort.device;
                        notify_property ("port");
                        updated = true;
                        foundPort = true;
                        break;
                    }
                }
                if (foundPort) break;
            }

            if (!foundPort &&  m_ActivePort != null) {
                m_ActivePort.weak_unref (on_active_port_destroyed);
                m_ActivePort = null;
                device = null;
                notify_property ("port");
            }
        }

        bool sendVolumeUpdate = (cvolume == null || volume != Channel.volume_to_double (inSourceInfo.volume.max ()));
        cvolume = inSourceInfo.volume;
        if (sendVolumeUpdate) {
            notify_property ("volume");
            updated = true;
        }

        bool sendBalanceUpdate = (cvolume == null || channel_map == null || balance != inSourceInfo.volume.get_balance (inSourceInfo.channel_map));
        channel_map = inSourceInfo.channel_map;
        if (sendBalanceUpdate) {
            notify_property ("balance");
            updated = true;
        }

        if (inSourceInfo.mute != m_IsMuted) {
            m_IsMuted = inSourceInfo.mute;
            notify_property ("is-muted");
            updated = true;
        }

        if (m_BaseVolume != inSourceInfo.base_volume) {
            m_BaseVolume = Channel.volume_to_double (inSourceInfo.base_volume);
            notify_property ("volume-base");
        }

        if (updated) {
            changed ();
        }

        return updated;
    }

    private void on_active_port_destroyed () {
        m_ActivePort = null;
        notify_property ("port");
    }
}
