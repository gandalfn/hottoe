/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * OutputPlug.vala
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

internal class PantheonSoundControl.PulseAudio.OutputPlug : Plug {
    private bool m_IsMuted;

    public override double volume {
        get {
            return cvolume != null ? Plug.volume_to_double (cvolume.max ()) : 0.0;
        }
        set {
            global::PulseAudio.CVolume? cvol = cvolume;
            if (cvol != null) {
                cvol.scale (Plug.double_to_volume (value));
                ((Manager) manager).operations.set_sink_input_volume (index, cvol);
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
                ((Manager) manager).operations.set_sink_input_volume (index, cvol);
            }
        }
    }

    public override bool is_muted {
        get {
            return m_IsMuted;
        }
        set {
            m_IsMuted = value;
            ((Manager) manager).operations.set_sink_input_mute (index, m_IsMuted);
        }
    }

    public override double volume_max {
        get {
            return volume_to_double (global::PulseAudio.Volume.UI_MAX);
        }
    }

    public override unowned PantheonSoundControl.Channel? channel {
        get {
            return m_Channel;
        }
        set {
            if (m_Channel != value) {
                if (m_Channel != null && value != null) {
                    ((Manager) manager).operations.move_sink_input_by_index (index, ((Channel) value).index, (s) => {
                        if (s) {
                            m_Channel = (Channel)value;
                        }
                    });
                } else {
                    m_Channel = (Channel)value;
                }
            }
        }
    }

    public OutputPlug (Manager inManager, global::PulseAudio.SinkInputInfo inInfo) {
        GLib.Object (
            manager: inManager,
            direction: PantheonSoundControl.Channel.Direction.OUTPUT,
            index: inInfo.index,
            name: inInfo.name
        );

        update (inInfo);
    }

    public bool update (global::PulseAudio.SinkInputInfo inInfo) {
        bool updated = false;

        if (m_Client == null || m_Client.index != inInfo.client) {
            bool foundClient = false;
            foreach (var c in manager.get_clients ()) {
                if (((Client) c).index == inInfo.client) {
                    if (m_Client != null) {
                        m_Client.plug_removed (this);
                    }
                    m_Client = (Client)c;
                    m_Client.plug_added (this);
                    notify_property ("client");
                    foundClient = true;
                    updated = true;
                }
            }

            if (!foundClient && m_Client != null) {
                m_Client.plug_removed (this);
                m_Client = null;
                notify_property ("client");
            }
        }

        if (m_Channel == null || m_Channel.index != inInfo.sink) {
            foreach (var c in manager.get_output_channels ()) {
                if (((Channel) c).index == inInfo.sink) {
                    channel = c;
                    notify_property ("channel");
                    updated = true;
                    break;
                }
            }
        }

        bool sendVolumeUpdate = (cvolume == null || volume != Plug.volume_to_double (inInfo.volume.max ()));
        cvolume = inInfo.volume;
        if (sendVolumeUpdate) {
            notify_property ("volume");
            updated = true;
        }

        bool sendBalanceUpdate = (cvolume == null || channel_map == null || balance != inInfo.volume.get_balance (inInfo.channel_map));
        channel_map = inInfo.channel_map;
        if (sendBalanceUpdate) {
            notify_property ("balance");
            updated = true;
        }

        if (inInfo.mute != m_IsMuted) {
            m_IsMuted = inInfo.mute;
            notify_property ("is-muted");
            updated = true;
        }

        if (updated) {
            changed ();
        }

        return updated;
    }
}
