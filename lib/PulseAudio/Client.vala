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

internal class PantheonSoundControl.PulseAudio.Client : PantheonSoundControl.Client {
    private Gee.TreeSet<unowned Plug> m_Plugs;

    public uint32 index { get; construct; }

    construct {
        m_Plugs = new Gee.TreeSet<unowned Plug> ();
    }

    public Client (Manager inManager, global::PulseAudio.ClientInfo inInfo) {
        string pidStr = inInfo.proplist.gets (global::PulseAudio.Proplist.PROP_APPLICATION_PROCESS_ID);
        int pid = 0;
        if (pidStr != null) {
            pid = int.parse (pidStr);
        }

        GLib.Object (
            manager: inManager,
            index: inInfo.index,
            name: inInfo.name,
            pid: pid
        );
    }

    public override void plug_added (PantheonSoundControl.Plug inPlug) {
        m_Plugs.add ((Plug) inPlug);
    }

    public override void plug_removed (PantheonSoundControl.Plug inPlug) {
        m_Plugs.remove ((Plug) inPlug);
    }

    public override Plug[] get_plugs () {
        return m_Plugs.to_array ();
    }

    public override string to_string () {
        return @"client: $(index), name: $(name), pid $(pid)";
    }

    public void update (global::PulseAudio.ClientInfo inInfo) {
        name = inInfo.name;

        string pidStr = inInfo.proplist.gets (global::PulseAudio.Proplist.PROP_APPLICATION_PROCESS_ID);
        if (pidStr != null) {
            pid = int.parse (pidStr);
        }
    }

    public static int compare (Client inA, Client inB) {
        return (int)inA.index - (int)inB.index;
    }
}
