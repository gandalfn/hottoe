/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Slice.vala
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

public abstract class SukaHottoe.Gst.Slice : GLib.Object {
    private global::Gst.FFT.F32 m_fft;
    private float[] m_buffer;
    private global::Gst.FFT.F32Complex[] m_spectrum;
    private int m_length;

    public int rate { get; construct; }
    public int sample_rate { get; construct; }
    public int length  {
        get {
            return m_length;
        }
    }

    construct {
        // calculate the number of samples in slice
        int samples = 2;

	    while (samples * rate < sample_rate) {
            samples <<= 1;
        }

        global::Gst.Debug.log (Spectrum.s_Debug, global::Gst.DebugLevel.DEBUG,
                               GLib.Log.FILE, GLib.Log.METHOD, GLib.Log.LINE,
                               this, @"create slice with rate: $rate, sample_rate: $sample_rate, samples: $samples");

        m_length = 0;

        // allocate slice buffer
        m_buffer = new float[samples];

        // create fft
        m_fft = new global::Gst.FFT.F32 (samples, false);

        // create spectrum complex array
        m_spectrum = global::Gst.FFT.F32Complex.alloc((samples / 2) + 1);
    }

    public bool push (float in_value)
        requires (m_length < m_buffer.length) {
        m_buffer[m_length++] = in_value;

        return m_length >= m_buffer.length;
    }

    public void clear () {
        GLib.Memory.set (m_buffer, 0, sizeof(float) * m_buffer.length);
        m_length = 0;

        GLib.Memory.set (m_spectrum, 0, sizeof(global::Gst.FFT.F32Complex) * m_spectrum.length);
    }

    public abstract int collect (void* in_input, int in_len, uint in_channels, float in_max_value);

    public void process (float[] inout_magnitudes, float in_gamma, float in_smoothing, float in_scale) {
        // Process FFT
        m_fft.window (m_buffer, global::Gst.FFT.Window.HAMMING);
        m_fft.fft (m_buffer, m_spectrum);

        int f_start = 0;
        int freqs = m_spectrum.length / 2;
        float smoothing = GLib.Math.powf (in_smoothing, (float)m_buffer.length / (float)sample_rate);

        for (int cpt = 0; cpt < inout_magnitudes.length; ++cpt) {
            int f_end = (int)GLib.Math.round(GLib.Math.powf(((float)(cpt + 1)) / (float)inout_magnitudes.length, in_gamma) * freqs);
            if (f_end > freqs) {
                f_end = freqs;
            }

            int f_width = f_end - f_start;
            if (f_width <= 0) {
                f_width = 1;
            }

            float bin_power = inout_magnitudes[cpt];
            for (int offset = 0; offset < f_width; ++offset) {
                global::Gst.FFT.F32Complex s = m_spectrum[f_start + offset];
                float p = (4.0f * (s.r * s.r) + (s.i * s.i)) / (float)(m_buffer.length * m_buffer.length);
                if (p > bin_power) {
                    bin_power = p;
                }
            }

            inout_magnitudes[cpt] = inout_magnitudes[cpt] * smoothing + (bin_power * in_scale * (1.0f - smoothing));

            f_start = f_end;
        }
    }
}