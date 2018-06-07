/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * InputPlug.vala
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

internal class Hottoe.PulseAudio.InputPlug : Plug {
    private bool m_is_muted;

    public override double volume {
        get {
            return cvolume != null ? Plug.volume_to_double (cvolume.max ()) : 0.0;
        }
        set {
            global::PulseAudio.CVolume? cvol = cvolume;
            if (cvol != null) {
                cvol.scale (Plug.double_to_volume (value));
                ((Manager) manager).operations.set_source_output_volume (index, cvol);
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
                ((Manager) manager).operations.set_source_output_volume (index, cvol);
            }
        }
    }

    public override bool is_muted {
        get {
            return m_is_muted;
        }
        set {
            m_is_muted = value;
            ((Manager) manager).operations.set_source_output_mute (index, m_is_muted);
        }
    }

    public override double volume_max {
        get {
            return volume_to_double (global::PulseAudio.Volume.UI_MAX);
        }
    }

    [CCode (notify = false)]
    public override unowned Hottoe.Channel? channel {
        get {
            return m_channel;
        }
        set {
            if (m_channel != value) {
                if (m_channel != null) {
                    m_channel.weak_unref (on_channel_destroyed);
                    m_channel = null;
                }
                if (value != null) {
                    ((Manager)manager).operations.move_source_output_by_index (index, ((Channel) value).index, (s) => {
                        if (s) {
                            m_channel = (Channel)value;
                            m_channel.weak_ref (on_channel_destroyed);
                            notify_property ("channel");
                        }
                    });
                } else {
                    m_channel = (Channel)value;
                    if (m_channel != null) {
                        m_channel.weak_ref (on_channel_destroyed);
                    }
                    notify_property ("channel");
                }
            }
        }
    }

    public InputPlug (Manager in_manager, global::PulseAudio.SourceOutputInfo in_info) {
        GLib.Object (
            manager: in_manager,
            direction: Hottoe.Direction.INPUT,
            index: in_info.index,
            id: in_info.proplist.gets (global::PulseAudio.Proplist.PROP_APPLICATION_ID),
            name: in_info.name
        );

        update (in_info);
    }

    ~InputPlug () {
        if (m_channel != null) {
            m_channel.weak_unref (on_channel_destroyed);
            m_channel = null;
        }
    }

    public bool update (global::PulseAudio.SourceOutputInfo in_info) {
        bool updated = false;

        if (m_client == null || m_client.index != in_info.client) {
            bool foundClient = false;
            foreach (var c in manager.get_clients ()) {
                if (((Client) c).index == in_info.client) {
                    if (m_client != null) {
                        m_client.plug_removed (this);
                    }
                    m_client = (Client)c;
                    m_client.plug_added (this);
                    notify_property ("client");
                    foundClient = true;
                    updated = true;
                    break;
                }
            }

            if (!foundClient && m_client != null) {
                m_client.plug_removed (this);
                m_client = null;
                notify_property ("client");
            }
        }

        if (m_channel == null || m_channel.index != in_info.source) {
            foreach (var c in manager.get_input_channels ()) {
                if (((Channel) c).index == in_info.source) {
                    channel = c;
                    break;
                }
            }
        }

        bool send_volume_update = (cvolume == null ||
                                   volume != Plug.volume_to_double (in_info.volume.max ()));
        cvolume = in_info.volume;
        if (send_volume_update) {
            notify_property ("volume");
            updated = true;
        }

        bool send_balance_update = (cvolume == null ||
                                    channel_map == null ||
                                    balance != in_info.volume.get_balance (in_info.channel_map));
        channel_map = in_info.channel_map;
        if (send_balance_update) {
            notify_property ("balance");
            updated = true;
        }

        if (in_info.mute != m_is_muted) {
            m_is_muted = in_info.mute;
            notify_property ("is-muted");
            updated = true;
        }

        if (updated) {
            changed ();
        }

        return updated;
    }

    private void on_channel_destroyed () {
        m_channel = null;
        notify_property ("channel");
    }
}
