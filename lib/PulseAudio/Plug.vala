/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Plug.vala
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

internal abstract class PantheonSoundControl.PulseAudio.Plug : PantheonSoundControl.Plug {
    internal class Monitor : PantheonSoundControl.Plug.Monitor, PantheonSoundControl.PulseAudio.Monitor {
        private bool m_Active;
        private global::PulseAudio.Stream m_Stream;

        public override bool active {
            get {
                return m_Active;
            }
            set {
                if (m_Active != value) {
                    if (value) {
                        m_Active = value;
                        if (m_Stream != null) {
                            stop (m_Stream);
                        }
                        m_Stream = start ((Channel)plug.channel, (int)((Plug)plug).index);
                    } else {
                        m_Active = value;
                        if (m_Stream != null) {
                            stop (m_Stream);
                            m_Stream = null;
                        }
                    }
                }
            }
        }

        public Monitor (Plug inPlug) {
            Object (
                plug: inPlug
            );
        }

        ~Monitor () {
            if (m_Stream != null) {
                stop (m_Stream);
                m_Stream = null;
            }
        }
    }

    protected unowned Client?  m_Client;
    protected unowned Channel? m_Channel;

    public uint32 index { get; construct; }
    public global::PulseAudio.CVolume? cvolume { get; set; default = null; }
    public global::PulseAudio.ChannelMap? channel_map { get; set; default = null; }

    public override unowned PantheonSoundControl.Client client {
        get {
            return m_Client;
        }
    }

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

    public override PantheonSoundControl.Plug.Monitor create_monitor () {
        return new Monitor (this);
    }

    public override string to_string () {
        return @"plug: $(index), name: $(name)\n";
    }

    public static int compare (Plug inA, Plug inB) {
        return (int)inA.index - (int)inB.index;
    }

    public static double volume_to_double (global::PulseAudio.Volume inVolume) {
        double tmp = (double)(inVolume - global::PulseAudio.Volume.MUTED);
        return 100 * tmp / (double)(global::PulseAudio.Volume.NORM - global::PulseAudio.Volume.MUTED);
    }

    public static global::PulseAudio.Volume double_to_volume (double inVolume) {
        double tmp = (double)(global::PulseAudio.Volume.NORM - global::PulseAudio.Volume.MUTED) * inVolume / 100;
        return (global::PulseAudio.Volume)tmp + global::PulseAudio.Volume.MUTED;
    }
}
