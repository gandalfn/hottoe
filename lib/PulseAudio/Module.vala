/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Module.vala
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

internal class Hottoe.PulseAudio.Module : GLib.Object {
    public struct Arg {
        public string name;
        public string val;

        public Arg (string in_name, string in_val) {
            name = in_name;
            val = in_val;
        }
    }

    private string? m_args;

    public uint32 index { get; construct set; default = global::PulseAudio.INVALID_INDEX; }
    public unowned Manager? manager { get; construct; }
    public string name { get; construct set; }
    public bool loaded {
        get {
            return index != global::PulseAudio.INVALID_INDEX;
        }
    }

    public Module (Manager in_manager, string in_name, uint32 in_index = global::PulseAudio.INVALID_INDEX) {
        GLib.Object (
            manager: in_manager,
            name: in_name,
            index: in_index
        );
    }

    ~Module () {
        unload ();
    }

    public Arg[] get_arguments () {
        Arg[] ret = {};
        if (m_args != null) {
            foreach (var arg in m_args.split (" ")) {
                string[] val = arg.split ("=", 2);
                ret += Arg (val[0], val[1]);
            }
        }
        return ret;
    }

    public async bool load (Arg[]? in_args = null) {
        m_args = null;
        if (in_args != null) {
            foreach (unowned Arg? arg in in_args) {
                if (m_args == null) {
                    m_args = @"$(arg.name)=$(arg.val)";
                } else {
                    m_args += @" $(arg.name)=$(arg.val)";
                }
            }
        }
        manager.operations.load_module (name, m_args, (i) => {
            index = i;
            load.callback ();
        });

        yield;

        return index != global::PulseAudio.INVALID_INDEX;
    }

    public void unload () {
        if (index != global::PulseAudio.INVALID_INDEX) {
            manager.operations.unload_module (index, null);
            index = global::PulseAudio.INVALID_INDEX;
        }
    }

    public bool update (global::PulseAudio.ModuleInfo in_info) {
        bool updated = false;

        if (in_info.name != name) {
            name = in_info.name;
            updated = true;
        }

        if (in_info.index != index) {
            index = in_info.index;
            updated = true;
        }

        if (in_info.argument != m_args) {
            m_args = in_info.argument;
            updated = true;
        }

        return updated;
    }

    public static int compare (Module in_a, Module in_b) {
        return (int)in_a.index - (int)in_b.index;
    }
}