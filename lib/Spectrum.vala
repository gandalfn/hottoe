/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Spectrum.vala
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

public abstract class SukaHottoe.Spectrum : GLib.Object {
    public unowned Channel channel { get; construct; }
    public uint bands { get; set; default = 20; }
    public int threshold { get; set; default = -80; }
    public int sample_rate { get; construct; default = 44100; }
    public int interval { get; construct; default = 100; }
    public bool enabled { get; set; default = false; }

    public signal void updated ();

    public virtual unowned float[]? get_magnitudes () {
        return null;
    }
}