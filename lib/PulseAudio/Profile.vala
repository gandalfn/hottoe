/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Profile.vala
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

internal class SukaHottoe.PulseAudio.Profile : SukaHottoe.Profile {
    public uint32 priority { get; construct; }

    public Profile (global::PulseAudio.CardProfileInfo in_info) {
        Object (
            name: in_info.name,
            description: in_info.description,
            priority: in_info.priority
        );

        debug (@"Create profile $(name) description: $(description) priority: $(priority)");
    }

    public override string to_string () {
        return @"\t\tprofile: $(name), description: $(description), priority: $(priority)";
    }

    public static int compare (Profile in_a, Profile in_b) {
        return (int)in_b.priority - (int)in_a.priority;
    }
}
