/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Client.vala
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

internal class SukaHottoe.PulseAudio.Client : SukaHottoe.Client {
    private Gee.TreeSet<unowned Plug> m_plugs;

    public uint32 index { get; construct; }
    public string id { get; construct set; }

    public override bool is_mine {
        get {
            return pid == Posix.getpid () || id == "com.github.gandalfn.suka-hottoe";
        }
    }

    construct {
        m_plugs = new Gee.TreeSet<unowned Plug> ();
    }

    public Client (Manager in_manager, global::PulseAudio.ClientInfo in_info) {
        string pid_str = in_info.proplist.gets (global::PulseAudio.Proplist.PROP_APPLICATION_PROCESS_ID);
        int pid = 0;
        if (pid_str != null) {
            pid = int.parse (pid_str);
        }

        GLib.Object (
            manager: in_manager,
            index: in_info.index,
            id: in_info.proplist.gets (global::PulseAudio.Proplist.PROP_APPLICATION_ID),
            name: in_info.name,
            pid: pid
        );
    }

    public override void plug_added (SukaHottoe.Plug in_plug) {
        m_plugs.add ((Plug) in_plug);
    }

    public override void plug_removed (SukaHottoe.Plug in_plug) {
        m_plugs.remove ((Plug) in_plug);
    }

    public override Plug[] get_plugs () {
        return m_plugs.to_array ();
    }

    public override string to_string () {
        return @"client: $(index), name: $(name), pid $(pid)";
    }

    public void update (global::PulseAudio.ClientInfo in_info) {
        bool updated = false;
        name = in_info.name;

        string pid_str = in_info.proplist.gets (global::PulseAudio.Proplist.PROP_APPLICATION_PROCESS_ID);
        if (pid_str != null && pid != int.parse (pid_str)) {
            pid = int.parse (pid_str);
            updated = true;
        }

        string idStr = in_info.proplist.gets (global::PulseAudio.Proplist.PROP_APPLICATION_ID);
        if (idStr != id) {
            id = idStr;
            updated = true;
        }

        if (updated) {
            notify_property ("is-mine");
        }
    }

    public static int compare (Client in_a, Client in_b) {
        return (int)in_a.index - (int)in_b.index;
    }
}
