/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Equalizer.vala
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

public abstract class Hottoe.Equalizer : GLib.Object {
    public struct Frequency {
        public int freq;
        public int val;

        public Frequency (int in_freq, int in_val) {
            freq = in_freq;
            val = in_val;
        }
    }

    public abstract class Preset : GLib.Object {
        protected Frequency[] m_frequencies;

        public string name { get; set; }
        public abstract int length { get; }

        public signal void changed (int in_index);

        public Preset (string in_name) {
            GLib.Object (
                name: in_name
            );
        }

        public abstract Preset copy ();

        public new Frequency @get (int in_index)
            requires (in_index >= 0 && in_index < m_frequencies.length) {
            return m_frequencies[in_index];
        }

        public new void @set (int in_index, Frequency in_frequency)
            requires (in_index >= 0 && in_index < m_frequencies.length) {
            if (m_frequencies[in_index] != in_frequency) {
                m_frequencies[in_index] = in_frequency;
                changed (in_index);
            }
        }

        public void set_freq (int in_index, int in_freq)
            requires (in_index >= 0 && in_index < m_frequencies.length) {
            if (m_frequencies[in_index].freq != in_freq) {
                m_frequencies[in_index].freq = in_freq;
                changed (in_index);
            }
        }

        public void set_val (int in_index, int in_val)
            requires (in_index >= 0 && in_index < m_frequencies.length) {
            if (m_frequencies[in_index].val != in_val) {
                m_frequencies[in_index].val = in_val;
                changed (in_index);
            }
        }
    }

    public class Preset10Bands : Preset {
        public override int length {
            get {
                return m_frequencies.length;
            }
        }

        construct {
            m_frequencies = new Frequency[10];
            m_frequencies[0] = Frequency (60, 0);
            m_frequencies[1] = Frequency (170, 0);
            m_frequencies[2] = Frequency (310, 0);
            m_frequencies[3] = Frequency (600, 0);
            m_frequencies[4] = Frequency (1000, 0);
            m_frequencies[5] = Frequency (3000, 0);
            m_frequencies[6] = Frequency (6000, 0);
            m_frequencies[7] = Frequency (12000, 0);
            m_frequencies[8] = Frequency (14000, 0);
            m_frequencies[9] = Frequency (16000, 0);
        }

        public Preset10Bands (string in_name) {
            base (in_name);
        }

        public override Preset copy () {
            var ret = new Preset10Bands (name);

            ret.m_frequencies = m_frequencies;

            return ret;
        }
    }

    public unowned Device device { get; construct; }
    public string name { get; construct; }
    public string description { get; construct; }

    public abstract Preset preset { get; set; }
}