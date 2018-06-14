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
 * Based from noise presetlist authored by: Scott Ringwelski <sgringwe@mtu.edu>
 * https://github.com/elementary/music/blob/master/src/Widgets/PresetList.vala
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
 */

public class Hottoe.Widgets.PresetList : Gtk.ComboBox {
    private const string SEPARATOR_NAME = "<separator_item_unique_name>";

    // We cannot make these constants due to issues with N_()
    private static string AUTOMATIC_MODE = _("Automatic");
    private static string DELETE_PRESET = _("Delete Current");

    private int m_ncustompresets;
    private bool m_modifying_list;
    private bool m_automatic_selected;

    private Gtk.ListStore m_store;

    public signal void preset_selected (Hottoe.Equalizer.Preset in_preset);
    public signal void automatic_preset_chosen ();
    public signal void delete_preset_chosen ();

    public bool automatic_chosen {
        get {
            return m_automatic_selected;
        }
    }

    [CCode (notify = false)]
    public Hottoe.Equalizer.Preset last_selected_preset { get; set; }

    construct {
        m_ncustompresets = 0;
        m_modifying_list = false;
        m_automatic_selected = false;

        m_store = new Gtk.ListStore (2, typeof (GLib.Object), typeof (string));

        set_model (m_store);
        set_id_column (1);

        set_row_separator_func ((model, iter) => {
            string content = "";
            model.get (iter, 1, out content);

            return content == SEPARATOR_NAME;
        });

        var cell = new Gtk.CellRendererText ();
        cell.ellipsize = Pango.EllipsizeMode.END;

        pack_start (cell, true);
        add_attribute (cell, "text", 1);

        changed.connect (listSelectionChange);

        show_all ();

        m_store.clear ();

        Gtk.TreeIter iter;
        m_store.append (out iter);
        m_store.set (iter, 0, null, 1, AUTOMATIC_MODE);

        addSeparator ();
    }

    public void addSeparator () {
        Gtk.TreeIter iter;
        m_store.append (out iter);
        m_store.set (iter, 0, null, 1, SEPARATOR_NAME);
    }

    public void addPreset(Hottoe.Equalizer.Preset in_preset) {
        m_modifying_list = true;

        if (!in_preset.is_default) {
            /* If the number of custom presets is zero, add a separator */
            if (m_ncustompresets < 1)
                addSeparator();

            m_ncustompresets++;
        }

        Gtk.TreeIter iter;
        m_store.append(out iter);
        m_store.set(iter, 0, in_preset, 1, in_preset.name);

        m_modifying_list = false;
        m_automatic_selected = false;

        set_active_iter(iter);
    }

    public void removeCurrentPreset () {
        m_modifying_list = true;

        Gtk.TreeIter iter;
        for (int i = 0; m_store.get_iter_from_string (out iter, i.to_string ()); ++i) {
            GLib.Object o;
            m_store.get (iter, 0, out o);

            if (o != null && o is Hottoe.Equalizer.Preset && ((Hottoe.Equalizer.Preset)o) == last_selected_preset) {
                if (!((Hottoe.Equalizer.Preset)o).is_default) {
                    m_ncustompresets--;
                    m_store.remove(ref iter);
                    break;
                }
            }
        }

        /* If there are no custom presets, remove the separator */
        if (m_ncustompresets < 1) {
            remove_separator_item (-1);
        }

        m_modifying_list = false;

        selectAutomaticPreset();
    }

    public virtual void listSelectionChange () {
        if (!m_modifying_list) {
            Gtk.TreeIter it;
            get_active_iter (out it);

            GLib.Object o;
            m_store.get (it, 0, out o);

            if (o != null && o is Hottoe.Equalizer.Preset) {
                last_selected_preset = o as Hottoe.Equalizer.Preset;

                if (!(o as Hottoe.Equalizer.Preset).is_default)
                    add_delete_preset_option ();
                else
                    remove_delete_option ();

                m_automatic_selected = false;
                preset_selected (o as Hottoe.Equalizer.Preset);
            } else {
                string option;
                m_store.get (it, 1, out option);

                if (option == AUTOMATIC_MODE) {
                    m_automatic_selected = true;
                    remove_delete_option ();
                    automatic_preset_chosen ();
                } else if (option == DELETE_PRESET) {
                    delete_preset_chosen ();
                }
            }
        }
    }

    public void selectAutomaticPreset() {
        m_automatic_selected = true;
        automatic_preset_chosen ();
        set_active (0);
    }

    public void selectPreset(string? in_preset_name) {

        if (!(in_preset_name == null || in_preset_name.length < 1)) {
            Gtk.TreeIter iter;
            for (int i = 0; m_store.get_iter_from_string (out iter, i.to_string()); ++i) {
                GLib.Object o;
                m_store.get(iter, 0, out o);

                if (o != null && o is Hottoe.Equalizer.Preset && (o as Hottoe.Equalizer.Preset).name == in_preset_name) {
                    set_active_iter (iter);
                    m_automatic_selected = false;
                    preset_selected (o as Hottoe.Equalizer.Preset);
                    return;
                }
            }
        }

        selectAutomaticPreset ();
    }

    public Hottoe.Equalizer.Preset? getSelectedPreset () {
        Hottoe.Equalizer.Preset? ret = null;
        Gtk.TreeIter it;
        get_active_iter(out it);

        GLib.Object o;
        m_store.get(it, 0, out o);

        if (o != null && o is Hottoe.Equalizer.Preset) {
            ret = o as Hottoe.Equalizer.Preset;
        }

        return ret;
    }

    public Gee.Collection<Hottoe.Equalizer.Preset> getPresets () {
        var rv = new Gee.LinkedList<Hottoe.Equalizer.Preset> ();

        Gtk.TreeIter iter;
        for (int i = 0; m_store.get_iter_from_string (out iter, i.to_string()); ++i) {
            GLib.Object o;
            m_store.get (iter, 0, out o);

            if (o != null && o is Hottoe.Equalizer.Preset) {
                rv.add (o as Hottoe.Equalizer.Preset);
            }
        }

        return rv;
    }

    private void remove_delete_option () {
        Gtk.TreeIter iter;
        for (int i = 0; m_store.get_iter_from_string (out iter, i.to_string()); ++i) {
            string text;
            m_store.get (iter, 1, out text);

            if (text != null && text == DELETE_PRESET) {
                m_store.remove (ref iter);

                // Also remove the separator ...
                remove_separator_item (1);
            }
        }
    }

    private void remove_separator_item (int in_index) {
        int count = 0, nitems = m_store.iter_n_children (null);
        Gtk.TreeIter iter;

        for (int i = nitems - 1; m_store.get_iter_from_string(out iter, i.to_string()); --i) {
            count++;
            string text;
            m_store.get (iter, 1, out text);

            if ((nitems - in_index == count || in_index == -1) && text != null && text == SEPARATOR_NAME) {
                m_store.remove (ref iter);
                break;
            }
        }
    }

    private void add_delete_preset_option () {
        bool already_added = false;
        Gtk.TreeIter last_iter, new_iter;

        for (int i = 0; m_store.get_iter_from_string(out last_iter, i.to_string()); ++i) {
            string text;
            m_store.get (last_iter, 1, out text);

            if (text != null && text == SEPARATOR_NAME) {
                new_iter = last_iter;

                if (m_store.iter_next (ref new_iter)) {
                    m_store.get (new_iter, 1, out text);
                    already_added = (text == DELETE_PRESET);
                }

                break;
            }
        }

        if (!already_added) {
            // Add option
            m_store.insert_after (out new_iter, last_iter);
            m_store.set (new_iter, 0, null, 1, DELETE_PRESET);

            last_iter = new_iter;

            // Add separator
            m_store.insert_after (out new_iter, last_iter);
            m_store.set (new_iter, 0, null, 1, SEPARATOR_NAME);
        }
    }
}