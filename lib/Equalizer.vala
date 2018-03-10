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

public abstract class SukaHottoe.Equalizer : GLib.Object {
    public struct Frequency {
        public int freq;
        public int val;

        public Frequency (int in_freq, int in_val) {
            freq = in_freq;
            val = in_val;
        }
    }

    public class Preset : GLib.Object  {
        private Frequency[] m_frequencies;

        public string name { get; set; }
        public int length {
            get {
                return 10;
            }
        }

        public signal void changed (int in_index);

        construct {
            m_frequencies = new Frequency[10];
        }

        public Preset (string in_name) {
            GLib.Object (
                name: in_name
            );
        }

        public Preset.copy (Preset in_preset) {
            this (in_preset.name);

            m_frequencies = in_preset.m_frequencies;
        }

        public new Frequency @get (int in_index)
            requires (in_index >= 0 && in_index < 10)  {
            return m_frequencies[in_index];
        }

        public new void @set (int in_index, Frequency in_val)
            requires (in_index >= 0 && in_index < 10)  {
            if (m_frequencies[in_index] != in_val) {
                m_frequencies[in_index] = in_val;
                changed(in_index);
            }
        }
    }

    public string name { get; construct; }
    public unowned Manager manager { get; construct; }
    public abstract unowned Device device { get; set; }

    public abstract Preset preset { get; set; }

    public Equalizer(string in_name, Manager in_manager) {
        GLib.Object(
            manager: in_manager,
            name: in_name
        );
    }
}