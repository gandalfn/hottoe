/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * SliceS16.vala
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

public class SukaHottoe.Gst.SliceS16 : SukaHottoe.Gst.Slice {
    public SliceS16 (int in_rate, int in_sample_rate) {
        global::Gst.Debug.log (Spectrum.s_Debug, global::Gst.DebugLevel.DEBUG,
                               GLib.Log.FILE, GLib.Log.METHOD, GLib.Log.LINE,
                               this, @"create S16 slice with rate: $in_rate, sample_rate: $in_sample_rate");
        GLib.Object (
            rate: in_rate,
            sample_rate: in_sample_rate
        );
    }

    public override int collect (void* in_input, int in_len, uint in_channels, float in_max_value)
        requires (in_len > 0)
        requires (in_channels > 0)
        requires (in_max_value != 0.0) {
        int ret = 0;
        unowned int16[] input = (int16[])in_input;
        input.length = in_len / (int)sizeof(int16);

        for (int cpt = 0; cpt < input.length; cpt += (int)in_channels) {
            float total = 0.0f;

            // Get the average of each channels sample
            for (uint channel = 0; channel < in_channels; ++channel) {
                total += (float)input[cpt + channel] / in_max_value;
            }
            total /= (float)in_channels;

            ++ret;

            // push buffer value
            if (push (total)) {
                break;
            }
        }

        return ret;
    }
}
