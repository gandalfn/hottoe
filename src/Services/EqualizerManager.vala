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

public class SukaHottoe.Services.EqualizerManager : GLib.Object {
    public class Item : GLib.Object {
        private Equalizer m_equalizer;

        public Settings.Equalizer settings { get; construct; }
        public Manager manager { get; construct; }

        construct {
            m_equalizer = manager.create_equalizer (settings.id, settings.name);
            m_equalizer.preset = new Equalizer.Preset10Bands(settings.id);

            manager.device_added.connect (on_device_added);

            settings.notify["device"].connect (on_device_changed);
            settings.notify["values"].connect (on_values_changed);
        }

        public Item (Settings.Equalizer in_settings, Manager in_manager)  {
            GLib.Object (
                manager: in_manager,
                settings: in_settings
            );
        }

        private void on_device_added (Device in_device) {
            if (in_device.name == settings.device) {
                m_equalizer.device = in_device;
            }
        }

        private void on_device_changed () {
            foreach (var device in manager.get_devices ()) {
                if (device.name == settings.device) {
                    on_device_added (device);
                    break;
                }
            }
        }

        private void on_values_changed () {
            int cpt = 0;
            foreach (var val in settings.values) {
                m_equalizer.preset[cpt].val = int.parse (val);
                cpt++;
            }
        }

        public static int compare (Item in_a, Item in_b) {
            return GLib.strcmp (in_a.settings.id, in_b.settings.id);
        }
    }

    private Gee.TreeSet<Item> m_items;

    public Settings.Main settings { get; construct; }
    public Manager manager { get; construct; }

    construct {
        m_items = new Gee.TreeSet<Item> (Item.compare);

        settings.notify["equalizers"].connect (on_equalizers_changed);

        on_equalizers_changed ();
    }

    public EqualizerManager(Settings.Main in_settings, Manager in_manager) {
        GLib.Object (
            settings: in_settings,
            manager: in_manager
        );
    }

    private void on_equalizers_changed () {
        foreach (var equalizer_id in settings.equalizers) {
            Item? item = m_items.first_match ((i) => {
                return i.settings.id == equalizer_id;
            });

            if (item == null) {
                Settings.Equalizer equalizer_setting = new Settings.Equalizer(equalizer_id);

                item = new Item (equalizer_setting, manager);
                m_items.add (item);
            }
        }

        var to_remove = new Gee.TreeSet<Item> (Item.compare);
        foreach (var item in m_items) {
            bool found = false;
            foreach (var equalizer_id in settings.equalizers) {
                if (equalizer_id == item.settings.id) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                to_remove.add (item);
            }
        }
        foreach (var item in to_remove) {
            m_items.remove (item);
        }
    }
}