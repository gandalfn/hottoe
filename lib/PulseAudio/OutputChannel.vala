/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * OutputChannel.vala
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

internal class PantheonSoundControl.PulseAudio.OutputChannel : Channel {
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
                ((Manager) manager).operations.set_sink_volume_by_index (index, cvol);
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
                ((Manager) manager).operations.set_sink_volume_by_index (index, cvol);
            }
        }
    }

    public override bool is_muted {
        get {
            return m_IsMuted;
        }
        set {
            m_IsMuted = value;
            ((Manager) manager).operations.set_sink_mute_by_index (index, m_IsMuted);
        }
    }

    public override double volume_base {
        get {
            return m_BaseVolume;
        }
    }

    public override double volume_max {
        get {
            return volume_to_double (global::PulseAudio.Volume.UI_MAX);
        }
    }

    [CCode (notify = false)]
    public override unowned PantheonSoundControl.Port? port {
        get {
            return m_ActivePort;
        }
        set {
            if (m_ActivePort != value) {
                if (value != null) {
                    ((Manager)manager).operations.set_sink_port_by_index (index, m_ActivePort.name, (s) => {
                        if (s) {
                            if (m_ActivePort != null) {
                                m_ActivePort.weak_unref (on_active_port_destroyed);
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
                    device = (Device)m_ActivePort.device;
                    notify_property ("port");
                }
            }
        }
    }

    public OutputChannel (Manager inManager, global::PulseAudio.SinkInfo inSinkInfo) {
        GLib.Object (
            manager: inManager,
            direction: PantheonSoundControl.Channel.Direction.OUTPUT,
            index: inSinkInfo.index,
            monitor_index: inSinkInfo.monitor_source,
            name: inSinkInfo.name,
            description: inSinkInfo.description
        );

        update (inSinkInfo);
    }

    ~OutputChannel () {
        if (m_ActivePort != null) {
            m_ActivePort.weak_unref (on_active_port_destroyed);
            m_ActivePort = null;
        }
    }

    public bool update (global::PulseAudio.SinkInfo inSinkInfo) {
        bool updated = false;

        if (inSinkInfo.active_port != null && (m_ActivePort == null || m_ActivePort.name != inSinkInfo.active_port.name)) {
            bool foundPort = false;
            foreach (var dev in manager.get_devices ()) {
                foreach (var port in dev.get_output_ports ()) {
                    if (port.name == inSinkInfo.active_port.name) {
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

        bool sendVolumeUpdate = (cvolume == null || volume != Channel.volume_to_double (inSinkInfo.volume.max ()));
        cvolume = inSinkInfo.volume;
        if (sendVolumeUpdate) {
            notify_property ("volume");
            updated = true;
        }

        bool sendBalanceUpdate = (cvolume == null || channel_map == null || balance != inSinkInfo.volume.get_balance (inSinkInfo.channel_map));
        channel_map = inSinkInfo.channel_map;
        if (sendBalanceUpdate) {
            notify_property ("balance");
            updated = true;
        }

        if (inSinkInfo.mute != m_IsMuted) {
            m_IsMuted = inSinkInfo.mute;
            notify_property ("is-muted");
            updated = true;
        }

        if (m_BaseVolume != inSinkInfo.base_volume) {
            m_BaseVolume = Channel.volume_to_double (inSinkInfo.base_volume);
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
