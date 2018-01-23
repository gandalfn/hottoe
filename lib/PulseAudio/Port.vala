/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Port.vala
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

internal class PantheonSoundControl.PulseAudio.Port : PantheonSoundControl.Port {
    public Port (Device inDevice, global::PulseAudio.CardPortInfo inInfo) {
        var icon_name = inInfo.proplist.gets (global::PulseAudio.Proplist.PROP_DEVICE_ICON_NAME);
        if (icon_name == null) {
            icon_name = inInfo.name;
        }
        Object (
            device: inDevice,
            name: inInfo.name,
            description: inInfo.description,
            icon_name: icon_name,
            direction: direction_from_pa_direction (inInfo.direction)
        );

        debug (@"Create $(direction) port $(name)");
    }

    public override string to_string () {
        return @"\tport: $(name), description: $(description), icon_name: $(icon_name) direction: $(direction)\n";
    }

    public static int compare (Port inA, Port inB) {
        return GLib.strcmp (inA.name, inB.name);
    }

    private static PantheonSoundControl.Port.Direction direction_from_pa_direction (global::PulseAudio.Direction inDirection) {
        switch (inDirection) {
            case global::PulseAudio.Direction.INPUT:
                return PantheonSoundControl.Port.Direction.INPUT;

            case global::PulseAudio.Direction.OUTPUT:
                return PantheonSoundControl.Port.Direction.OUTPUT;
        }

        return PantheonSoundControl.Port.Direction.OUTPUT;
    }
}
