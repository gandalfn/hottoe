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


public class SukaHottoe.Gst.Spectrum : global::Gst.Audio.Filter {
    public static global::Gst.DebugCategory? s_Debug;

    private GLib.Mutex m_lock;
    private Slice m_slice;

    public uint bands { get; set; }

    static construct {
        s_Debug.init ("SUKA_HOTTOE_SPECTRUM", 0, "suka hottoe audio spectrum analyser element");

        passthrough_on_same_caps = true;

        set_static_metadata ("SukaHottoe Spectrum analyzer",
                             "Filter/Analyzer/Audio",
                             "Run an FFT on the audio signal, output logarithm spectrum data",
                             "Nicolas Bruguier <gandalfn@club-internet.fr>");

        string formats = null;
        if (GLib.ByteOrder.HOST == GLib.ByteOrder.LITTLE_ENDIAN)   {
            formats = global::Gst.Audio.caps_make ("{ S16LE, S24LE, S32LE, F32LE, F64LE }");
        } else {
            formats = global::Gst.Audio.caps_make ("{ S16BE, S24BE, S32BE, F32BE, F64BE }");
        }

        var caps = global::Gst.Caps.from_string (formats + ",layout = (string) interleaved");
        add_pad_templates (caps);
    }

    construct {
        m_lock = GLib.Mutex ();
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

        m_lock.unlock ();

        return ret;
    }

    public override bool start () {
        global::Gst.Debug.log (s_Debug, global::Gst.DebugLevel.DEBUG,
                               GLib.Log.FILE, GLib.Log.METHOD, GLib.Log.LINE,
                               this, "start spectrum");
        return true;
    }

    public override bool stop () {
        global::Gst.Debug.log (s_Debug, global::Gst.DebugLevel.DEBUG,
                               GLib.Log.FILE, GLib.Log.METHOD, GLib.Log.LINE,
                               this, "stop spectrum");

        return true;
    }

    public override  global::Gst.FlowReturn transform_ip (global::Gst.Buffer in_buf) {
        m_lock.lock ();

        global::Gst.MapInfo info;
        in_buf.map (out info, global::Gst.MapFlags.READ);

        uint8[] data = info.data;
        float max_value = (1UL << ((bps << 3) - 1)) - 1;

        float[] magnitudes = new float[12];
        int pos = 0;
        int length = data.length;
        do {
            int nb = m_slice.collect(data[pos:data.length], length, channels, max_value);
            pos = data.length - nb;
            length -= pos;
            if (nb > 0) {
                global::Gst.Debug.log (s_Debug, global::Gst.DebugLevel.DEBUG,
                                       GLib.Log.FILE, GLib.Log.METHOD, GLib.Log.LINE,
                                       this, @"nb: $nb, pos: $pos");
                m_slice.process (magnitudes, 2.0f, 0.00007f, 0.05f);
                m_slice.clear ();
            }
            if (length <= 0) {
                break;
            }
        } while (true);

        string vals = "";
        for (int cpt = 0; cpt < magnitudes.length; ++cpt) {
            vals += @"$(magnitudes[cpt])|";
        }

        global::Gst.Debug.log (s_Debug, global::Gst.DebugLevel.DEBUG,
                               GLib.Log.FILE, GLib.Log.METHOD, GLib.Log.LINE,
                               this, vals);

        in_buf.unmap (info);
        m_lock.unlock ();
        return global::Gst.FlowReturn.OK;
    }
}

[CCode (cname = "suka_hottoe_gst_spectrum_init")]
public static bool plugin_init (Gst.Plugin in_plugin) {
    return Gst.Element.register (in_plugin, "shspectrum", Gst.Rank.NONE, typeof (SukaHottoe.Gst.Spectrum));
}