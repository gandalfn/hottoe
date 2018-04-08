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

public class SukaHottoe.Widgets.Equalizer : Gtk.Grid {
    private Settings.Equalizer m_settings;
    private GLib.List<unowned Gtk.Scale> m_scales;

    public unowned Device device { get; construct; }

    construct {
        // Get settings
        m_settings = new Settings.Equalizer (device.name);

        // Create equalizer
        var scale_container = new Gtk.Grid ();
        scale_container.column_spacing = 12;
        scale_container.margin = 18;
        scale_container.margin_bottom = 0;

        m_scales = new GLib.List<unowned Gtk.Scale> ();

        int cpt = 0;
        foreach (var freq in m_settings.frequencies) {
            var scale = new Gtk.Scale.with_range (Gtk.Orientation.VERTICAL, -80, 80, 1);
            scale.add_mark (0, Gtk.PositionType.LEFT, null);
            scale.draw_value = false;
            scale.inverted = true;
            scale.vexpand = true;

            int freq_val = int.parse (freq);
            string decibel = null;
            if (freq_val > 1000) {
                decibel = "%ik".printf(freq_val / 1000);
            } else {
                decibel = "%i".printf(freq_val);
            }
            var label = new Gtk.Label (decibel);

            var holder = new Gtk.Grid ();
            holder.orientation = Gtk.Orientation.VERTICAL;
            holder.row_spacing = 6;
            holder.add (scale);
            holder.add (label);

            scale_container.add (holder);
            scale.set_value (int.parse (m_settings.values[cpt]));
            scale.value_changed.connect (on_scale_value_changed);
            cpt++;

            m_scales.append (scale);
        }

        add (scale_container);
    }

    public Equalizer (Device in_device) {
        GLib.Object (
            device: in_device
        );
    }

    private void on_scale_value_changed () {
        string[] values = {};
        foreach (var scale in m_scales) {
            values += "%i".printf((int)scale.get_value ());
        }
        m_settings.values = values;
    }
}