/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Message.vala
 * Copyright (C) Nicolas Bruguier 2018 <gandalfn@club-internet.fr>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

public class SukaHottoe.Gst.Message : GLib.Object {
    private global::Gst.Structure m_structure;

    public Message (float[] in_magnitudes) {
        m_structure = new global::Gst.Structure ("shspectrum",
                                                 "bands", typeof(int), 0);

        GLib.Value container = GLib.Value (typeof (global::Gst.ValueList));

        foreach (float magnitude in in_magnitudes) {
            global::Gst.ValueList.append_value(container, 10.0f * (float)GLib.Math.log10(magnitude));
        }
        m_structure.set_value ("magnitude", container);
    }

    public void post(global::Gst.Element in_element) {
        global::Gst.Message msg = new global::Gst.Message.element(in_element, (owned)m_structure);
        in_element.post_message (msg);
    }
}