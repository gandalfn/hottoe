/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Monitor.vala
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

internal interface Hottoe.PulseAudio.Monitor : Hottoe.Monitor {
    protected global::PulseAudio.Stream start (Channel in_channel, int in_plug_index = -1) {
        var ss = global::PulseAudio.SampleSpec () {
            channels = 1,
            format = global::PulseAudio.SampleFormat.FLOAT32NE,
            rate = 25
        };

        var stream = ((Manager)in_channel.manager).operations.create_stream (_("Peak detect"), ss);
        stream.set_read_callback (on_read);
        stream.set_suspended_callback (on_suspended);
        if (in_plug_index >= 0) {
            stream.set_monitor_stream (in_plug_index);
        }

        var flags = global::PulseAudio.Stream.Flags.DONT_MOVE |
                    global::PulseAudio.Stream.Flags.PEAK_DETECT |
                    global::PulseAudio.Stream.Flags.ADJUST_LATENCY |
                    global::PulseAudio.Stream.Flags.START_UNMUTED;

        var attr = global::PulseAudio.Stream.BufferAttr () {
            fragsize = (uint32)sizeof (float),
            maxlength = uint32.MAX
        };

        if (stream.connect_record ( "%u".printf (in_channel.monitor_index), attr, flags) < 0) {
            critical (@"Error on create monitor stream");
        }

        return stream;
    }

    protected void stop (global::PulseAudio.Stream in_stream) {
        if (in_stream != null) {
            paused ();

            in_stream.set_read_callback (null);
            in_stream.set_suspended_callback (null);
            in_stream.disconnect ();
            in_stream.flush ();
        }
    }

    private void on_read (global::PulseAudio.Stream in_stream, size_t in_length) {
        if (in_stream != null) {
            void* buffer;

            if (in_stream.peek (out buffer, out in_length) >= 0) {
                if (buffer != null) {
                    unowned float[] data = (float[])buffer;
                    data.length = (int)(in_length / sizeof (float));

                    if (data.length > 0) {
                        peak (data[data.length - 1]);
                    }
                }

                in_stream.drop ();
            } else {
                critical (@"Failed to read data from stream");
            }
        }
    }

    private void on_suspended (global::PulseAudio.Stream in_stream) {
        paused ();
    }
}