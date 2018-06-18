/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Spectrum.vala
 * Copyright (C) Nicolas Bruguier 2018 <gandalfn@club-internet.fr>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */


public class Hottoe.Gst.Spectrum : global::Gst.Audio.Filter {
    public static global::Gst.DebugCategory? s_Debug;

    private GLib.Mutex m_lock;
    private Slice m_slice;
    private float[] m_magnitudes;
    private uint m_num_frames;
    private uint64 m_interval;
    private int m_frame_rate;
    private uint64 m_frames_per_interval;

    public uint bands {
        get {
            return m_magnitudes != null ? m_magnitudes.length : 15;
        }
        set {
            if (m_magnitudes == null || m_magnitudes.length != value) {
                m_lock.lock ();
                m_magnitudes = new float [value];
                flush ();
                m_lock.unlock ();
            }
        }
    }

    public uint64 interval {
        get {
            return m_interval;
        }
        set {
            m_lock.lock ();
            if (m_interval != value) {
                m_interval = value;
                m_frames_per_interval = global::Gst.Util.uint64_scale (m_interval, m_frame_rate, global::Gst.SECOND / 10);
                flush ();

                global::Gst.Debug.log (s_Debug, global::Gst.DebugLevel.DEBUG,
                                       GLib.Log.FILE, GLib.Log.METHOD, GLib.Log.LINE,
                                       this, @"interval: $m_interval frames_per_interval: $m_frames_per_interval");
            }
            m_lock.unlock ();
        }
    }

    public float smoothing { get; set; default = 0.00007f; }
    public float scale { get; set; default = 1.0f; }
    public float threshold { get; set; default = -90.0f; }
    public float gamma { get; set; default = 2.0f; }

    static construct {
        s_Debug.init ("HOTTOE_SPECTRUM", 0, "hottoe audio spectrum analyser element");

        passthrough_on_same_caps = true;

        set_static_metadata ("Hottoe Spectrum analyzer",
                             "Filter/Analyzer/Audio",
                             "Run an FFT on the audio signal, output logarithm spectrum data",
                             "Nicolas Bruguier <gandalfn@club-internet.fr>");

        string formats = null;
        if (GLib.ByteOrder.HOST == GLib.ByteOrder.LITTLE_ENDIAN) {
            formats = global::Gst.Audio.caps_make ("{ S16LE, S24LE, S32LE, F32LE, F64LE }");
        } else {
            formats = global::Gst.Audio.caps_make ("{ S16BE, S24BE, S32BE, F32BE, F64BE }");
        }

        var caps = global::Gst.Caps.from_string (formats + ",layout = (string) interleaved");
        add_pad_templates (caps);
    }

    construct {
        m_lock = GLib.Mutex ();

        m_magnitudes = new float [15];
        m_interval = global::Gst.SECOND / 10;

        notify["interval"].connect (flush);
    }

    private void flush () {
        GLib.Memory.set (m_magnitudes, 0, sizeof (float) * m_magnitudes.length);

        if (m_slice != null) {
            m_slice.clear ();
        }

        m_num_frames = 0;
    }

    public override bool setup (global::Gst.Audio.Info in_info) {
        global::Gst.Debug.log (s_Debug, global::Gst.DebugLevel.DEBUG,
                               GLib.Log.FILE, GLib.Log.METHOD, GLib.Log.LINE,
                               this, "setup spectrum");

        bool ret = true;

        m_lock.lock ();

        // Create slice buffer from the format
        switch (in_info.format) {
            case global::Gst.Audio.Format.S16:
                m_slice = new SliceS16 (64, in_info.rate);
                break;

            case global::Gst.Audio.Format.S24:
                m_slice = new SliceS24 (64, in_info.rate);
                break;

            case global::Gst.Audio.Format.S32:
                m_slice = new SliceS32 (64, in_info.rate);
                break;

            case global::Gst.Audio.Format.F32:
                m_slice = new SliceFloat (64, in_info.rate);
                break;

            case global::Gst.Audio.Format.F64:
                m_slice = new SliceDouble (64, in_info.rate);
                break;

            default:
                ret = false;
                break;
        }

        m_frame_rate = in_info.rate;
        m_frames_per_interval = global::Gst.Util.uint64_scale (m_interval, m_frame_rate, global::Gst.SECOND / 10);
        flush ();

        global::Gst.Debug.log (s_Debug, global::Gst.DebugLevel.DEBUG,
                               GLib.Log.FILE, GLib.Log.METHOD, GLib.Log.LINE,
                               this, @"interval: $m_interval frames_per_interval: $m_frames_per_interval");

        m_lock.unlock ();

        return ret;
    }

    public override bool start () {
        global::Gst.Debug.log (s_Debug, global::Gst.DebugLevel.DEBUG,
                               GLib.Log.FILE, GLib.Log.METHOD, GLib.Log.LINE,
                               this, "start spectrum");

        flush ();

        return true;
    }

    public override bool stop () {
        global::Gst.Debug.log (s_Debug, global::Gst.DebugLevel.DEBUG,
                               GLib.Log.FILE, GLib.Log.METHOD, GLib.Log.LINE,
                               this, "stop spectrum");

        flush ();

        return true;
    }

    public override  global::Gst.FlowReturn transform_ip (global::Gst.Buffer in_buf) {
        m_lock.lock ();

        global::Gst.MapInfo info;
        in_buf.map (out info, global::Gst.MapFlags.READ);

        unowned uint8[]? data = info.data;
        float max_value = (1UL << ((bps << 3) - 1)) - 1;

        int pos = 0;
        int length = data.length;
        do {
            int nb = m_slice.collect (data[pos:data.length], length, channels, max_value);
            pos = data.length - nb;
            length -= pos;
            if (nb > 0) {
                m_slice.process (m_magnitudes, gamma, smoothing, scale);
                m_slice.clear ();
            }
            m_num_frames += pos;
            if (m_num_frames >= m_frames_per_interval) {
                var msg = new Message (m_magnitudes);
                msg.post (this);

                flush ();
            }
            if (length <= 0) {
                break;
            }
        } while (true);


        in_buf.unmap (info);
        m_lock.unlock ();
        return global::Gst.FlowReturn.OK;
    }
}

[CCode (cname = "hottoe_gst_spectrum_init")]
public static bool plugin_init (Gst.Plugin in_plugin) {
    return Gst.Element.register (in_plugin, "hspectrum", Gst.Rank.NONE, typeof (Hottoe.Gst.Spectrum));
}