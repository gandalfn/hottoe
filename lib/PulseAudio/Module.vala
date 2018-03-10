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

internal class SukaHottoe.PulseAudio.Module : GLib.Object {
    public struct Arg {
        public string name;
        public string val;

        public Arg(string in_name, string in_val) {
            name = in_name;
            val = in_val;
        }
    }

    private uint32 m_index = global::PulseAudio.INVALID_INDEX;

    public unowned Manager? manager { get; construct; }
    public string name { get; construct; }
    public uint32 index {
        get {
            return m_index;
        }
    }

    public Module (Manager in_manager, string in_name) {
        GLib.Object (
            manager: in_manager,
            name: in_name
        );
    }

    ~Module() {
        unload();
    }

    public async bool load (Arg[]? in_args = null) {
        string? args = null;
        if (in_args != null) {
            foreach (unowned Arg? arg in in_args) {
                if (args == null) {
                    args += @"$(arg.name)=$(arg.val)";
                } else {
                    args += @" $(arg.name)=$(arg.val)";
                }
            }
        }
        manager.operations.load_module (name, args, (i) => {
            m_index = i;
            load.callback ();
        });

        yield;

        return m_index != global::PulseAudio.INVALID_INDEX;
    }

    public void unload () {
        if (m_index != global::PulseAudio.INVALID_INDEX) {
            manager.operations.unload_module (m_index, null);
            m_index = global::PulseAudio.INVALID_INDEX;
        }
    }
}