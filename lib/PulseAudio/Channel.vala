/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Channel.vala
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

internal abstract class SukaHottoe.PulseAudio.Channel : SukaHottoe.Channel {
    internal class Monitor : SukaHottoe.Channel.Monitor, SukaHottoe.PulseAudio.Monitor {
        private bool m_active;
        private global::PulseAudio.Stream m_stream;

        public override bool active {
            get {
                return m_active;
            }
            set {
                if (m_active != value) {
                    if (value) {
                        m_active = value;
                        if (m_stream != null) {
                            stop (m_stream);
                        }
                        m_stream = start ((Channel)channel);
                    } else {
                        m_active = value;
                        if (m_stream != null) {
                            stop (m_stream);
                            m_stream = null;
                        }
                    }
                }
            }
        }

        public Monitor (Channel in_channel) {
            Object (
                channel: in_channel
            );
        }

        ~Monitor () {
            if (m_stream != null) {
                stop (m_stream);
                m_stream = null;
            }
        }
    }

    protected unowned Port? m_active_port;
    protected unowned Device? m_device;

    [CCode (notify = false)]
    protected unowned Device? device {
        set {
            if (value != m_device) {
                if (m_device != null) {
                    m_device.channel_removed (this);
                }
                m_device = value;
                if (m_device != null) {
                    m_device.channel_added (this);
                }
            } else {
                // send devicce changed in case of the channel port change but
                // for the same device
                m_device.changed ();
            }
        }
    }

    public uint32 index { get; construct; }
    public uint32 monitor_index { get; construct; }
    public global::PulseAudio.CVolume? cvolume { get; set; default = null; }
    public global::PulseAudio.ChannelMap? channel_map { get; set; default = null; }

    public override double volume_muted {
        get {
            return volume_to_double (global::PulseAudio.Volume.MUTED);
        }
    }

    public override double volume_norm {
        get {
            return volume_to_double (global::PulseAudio.Volume.NORM);
        }
    }

    public override SukaHottoe.Channel.Monitor create_monitor () {
        return new Monitor (this);
    }

    public override string to_string () {
        string ret = @"channel: $(index), name: $(name), description: $(description)\n";
        if (m_active_port != null) {
            ret += @"active port:\n$(m_active_port)\n";
        }
        return ret;
    }

    public static int compare (Channel in_a, Channel in_b) {
        return (int)in_a.index - (int)in_b.index;
    }

    public static double volume_to_double (global::PulseAudio.Volume in_volume) {
        double tmp = (double)(in_volume - global::PulseAudio.Volume.MUTED);
        return 100 * tmp / (double)(global::PulseAudio.Volume.NORM - global::PulseAudio.Volume.MUTED);
    }

    public static global::PulseAudio.Volume double_to_volume (double in_volume) {
        double tmp = (double)(global::PulseAudio.Volume.NORM - global::PulseAudio.Volume.MUTED) * in_volume / 100;
        return (global::PulseAudio.Volume)tmp + global::PulseAudio.Volume.MUTED;
    }
}
