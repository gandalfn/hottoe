/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Manager.vala
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

[CCode (cname = "BACKEND_PATH")]
extern const string BACKEND_PATH;

public abstract class SukaHottoe.Manager : GLib.Object {
    private static Gee.TreeSet<Backend> s_backends = null;

    internal class Backend : GLib.Object {
        [CCode (has_target = false)]
        private delegate Manager? LoadFunc ();

        private GLib.Module m_module;
        private LoadFunc m_load_func;

        public string name { get; construct; }

        public Backend (string in_name) {
            GLib.Object (name: in_name);

            debug ("Load backend %s", in_name);

            if (GLib.Module.supported ()) {
                string path = GLib.Path.build_filename (BACKEND_PATH, "lib%s-backend.so".printf (in_name.down ()));

                m_module = GLib.Module.open (path, GLib.ModuleFlags.BIND_LAZY);
                if (m_module != null) {
                    void* function;
                    string loadMethodName = "suka_hottoe_%s_load".printf (in_name.down ());

                    m_module.symbol (loadMethodName, out function);
                    if (function != null) {
                        m_load_func = (LoadFunc) function;
                    } else {
                        critical ("%s not found in %s", loadMethodName, path);
                    }
                } else {
                    critical (GLib.Module.error ());
                }
            } else {
                critical ("Suka Hottoe sound backend loading is not supported by this system!");
            }
        }

        public Manager? load () {
            Manager? ret = null;
            if (m_load_func != null) {
                ret = m_load_func ();
            }
            return ret;
        }

        public static int compare (Backend in_a, Backend in_b) {
            return GLib.strcmp (in_a.name, in_b.name);
        }
    }

    public bool enable_monitoring { get; set; default = false; }

    public abstract unowned Channel? default_input_channel { get; }
    public abstract unowned Channel? default_output_channel { get; }

    public abstract unowned Device? default_input_device { get; set; }
    public abstract unowned Device? default_output_device { get; set; }

    public static new Manager? get (string in_backend) {
        if (s_backends == null) {
            s_backends = new Gee.TreeSet<Backend> (Backend.compare);
        }

        var backend = s_backends.first_match ((b) => {
            return b.name == in_backend;
        });
        if (backend == null) {
            backend = new Backend (in_backend);
            s_backends.add (backend);
        }

        return backend.load ();
    }

    public signal void device_added (Device inDevice);
    public signal void device_removed (Device inDevice);

    public signal void channel_added (Channel inChannel);
    public signal void channel_removed (Channel inChannel);

    public signal void client_added (Client inClient);
    public signal void client_removed (Client inClient);

    public signal void plug_added (Plug inPlug);
    public signal void plug_removed (Plug inPlug);

    public abstract void start ();

    public abstract Device[] get_devices ();
    public abstract Channel[] get_output_channels ();
    public abstract Channel[] get_input_channels ();
    public abstract Channel get_channel (string in_channel_name);
    public abstract Client[] get_clients ();
    public abstract Plug[] get_input_plugs ();
    public abstract Plug[] get_output_plugs ();
}
