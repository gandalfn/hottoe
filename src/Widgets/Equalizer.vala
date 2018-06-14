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
 *
 * Based from noise equalizer authored by: Scott Ringwelski <sgringwe@mtu.edu>
 * https://github.com/elementary/music/blob/master/src/Widgets/EqualizerPopover.vala
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
 */

public class Hottoe.Widgets.Equalizer : Gtk.Grid {
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
        scale_container.halign = Gtk.Align.CENTER;

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
            if (freq_val >= 1000) {
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

        var eq_switch = new Gtk.Switch ();
        eq_switch.valign = Gtk.Align.CENTER;
        eq_switch.set_active (m_settings.enabled);

        var preset_combo = new PresetList ();
        preset_combo.hexpand = true;
        foreach (var preset in Hottoe.Equalizer.get_default_presets ()) {
            preset.is_default = true;
            preset_combo.addPreset (preset);
        }

        var side_list = new Gtk.Grid ();
        side_list.add (preset_combo);

        var new_preset_entry = new Gtk.Entry ();
        new_preset_entry.hexpand = true;
        new_preset_entry.secondary_icon_name = "document-save-symbolic";
        new_preset_entry.secondary_icon_tooltip_text = _("Save preset");

        var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.BOTH);
        size_group.add_widget (preset_combo);
        size_group.add_widget (new_preset_entry);

        var bottom_controls = new Gtk.Grid ();
        bottom_controls.column_spacing = 12;
        bottom_controls.margin = 12;
        bottom_controls.margin_top = 0;
        bottom_controls.hexpand = false;
        bottom_controls.add (eq_switch);
        bottom_controls.add (side_list);

        var layout = new Gtk.Grid ();
        layout.orientation = Gtk.Orientation.VERTICAL;
        layout.row_spacing = 12;

        layout.add (scale_container);
        layout.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        layout.add (bottom_controls);
        layout.show_all ();

        add (layout);

        preset_combo.bind_property("active", m_settings, "enabled",
                                   GLib.BindingFlags.SYNC_CREATE |
                                   GLib.BindingFlags.BIDIRECTIONAL);
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