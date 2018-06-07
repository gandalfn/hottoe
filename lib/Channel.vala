/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Channel.vala
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

public abstract class Hottoe.Channel : GLib.Object {
    public abstract class Monitor : Hottoe.Monitor {
        public unowned Channel? channel { get; construct; }
    }

    public unowned Manager manager { get; construct; }
    public Direction direction { get; construct; }
    public string name { get; construct; }
    public string description { get; construct; }
    public abstract unowned Port? port { get; set; }
    public abstract double volume { get; set; }
    public abstract float balance { get; set; }
    public abstract bool is_muted { get; set; }
    public abstract bool is_mine { get; }

    public abstract double volume_muted { get; }
    public abstract double volume_base { get; }
    public abstract double volume_norm { get; }
    public abstract double volume_max { get; }

    public signal void changed ();

    public abstract Monitor create_monitor ();
    public abstract string to_string ();
}