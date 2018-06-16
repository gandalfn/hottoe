/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * EqualizerManager.vala
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

public class Hottoe.Services.EqualizerManager : GLib.Object {
    public class Item : GLib.Object {
        public Settings.Equalizer settings { get; construct; }
        public unowned Device device { get; construct; }

        construct {
            if (device.get_output_channels ().length > 0) {
                settings.enabled = true;
            }

            settings.notify["values"].connect (on_values_changed);
            settings.bind_property ("enabled", device, "enable_equalizer", GLib.BindingFlags.SYNC_CREATE);
            device.notify["enable_equalizer"].connect (on_device_equalizer_changed);
            device.notify["equalizer"].connect (on_device_equalizer_changed);

            on_device_equalizer_changed ();
        }

        public Item (Settings.Equalizer in_settings, Device in_device) {
            GLib.Object (
                device: in_device,
                settings: in_settings
            );
        }

        private void on_values_changed () {
            if (device.enable_equalizer && device.equalizer != null) {
                int cpt = 0;
                foreach (var val in settings.values) {
                    device.equalizer.preset.set_val (cpt, int.parse (val));
                    cpt++;
                }
            }
        }

        private void on_device_equalizer_changed () {
            if (device.enable_equalizer && device.equalizer != null) {
                var preset = new Equalizer.Preset10Bands (settings.device);
                int cpt = 0;
                foreach (var freq in settings.frequencies) {
                    preset.set_freq (cpt, int.parse (freq));
                }
                device.equalizer.preset = preset;
                on_values_changed ();
            }
        }

        public static int compare (Item in_a, Item in_b) {
            return GLib.strcmp (in_a.device.name, in_b.device.name);
        }
    }

    private Gee.TreeSet<Item> m_items;

    public Manager manager { get; construct; }

    construct {
        m_items = new Gee.TreeSet<Item> (Item.compare);

        manager.notify["is-ready"].connect (on_manager_ready);

        if (manager.is_ready) {
            on_manager_ready ();
        }
    }

    public EqualizerManager (Manager in_manager) {
        GLib.Object (
            manager: in_manager
        );
    }

    private void on_manager_ready () {
        if (manager.is_ready) {
            manager.device_added.connect (on_device_added);
            manager.device_removed.connect (on_device_removed);
            foreach (var device in manager.get_devices ()) {
                on_device_added (device);
            }
        } else {
            m_items.clear ();
            manager.device_added.disconnect (on_device_added);
            manager.device_removed.disconnect (on_device_removed);
        }
    }

    private void on_device_added (Device in_device) {
        bool found = false;
        foreach (var item in m_items) {
            if (item.device == in_device) {
                found = true;
                break;
            }
        }
        if (!found) {
            Settings.Equalizer settings = new Settings.Equalizer (in_device.name);
            m_items.add (new Item (settings, in_device));
        }
    }

    private void on_device_removed (Device in_device) {
        foreach (var item in m_items) {
            if (item.device == in_device) {
                m_items.remove (item);
                break;
            }
        }
    }
}