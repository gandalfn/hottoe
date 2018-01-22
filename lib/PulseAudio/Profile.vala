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

internal class PantheonSoundControl.PulseAudio.Profile : PantheonSoundControl.Profile {
    public uint32 priority { get; construct; }

    public Profile (global::PulseAudio.CardProfileInfo inInfo) {
        Object (
            name: inInfo.name,
            description: inInfo.description,
            priority: inInfo.priority
        );

        debug (@"Create profile $(name) description: $(description) priority: $(priority)");
    }

    public override string to_string () {
        return @"\t\tprofile: $(name), description: $(description), priority: $(priority)";
    }

    public static int compare (Profile inA, Profile inB) {
        return (int)inB.priority - (int)inA.priority;
    }
}
