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

internal interface PantheonSoundControl.PulseAudio.Monitor : PantheonSoundControl.Monitor {
    protected global::PulseAudio.Stream start (Channel inChannel, int inPlugIndex = -1) {
        var ss = global::PulseAudio.SampleSpec () {
            channels = 1,
            format = global::PulseAudio.SampleFormat.FLOAT32NE,
            rate = 25
        };

        global::PulseAudio.Stream stream = ((Manager)inChannel.manager).operations.create_stream (_("Peak detect"), ss);
        stream.set_read_callback (on_read);
        stream.set_suspended_callback (on_suspended);
        if (inPlugIndex >= 0) {
            stream.set_monitor_stream (inPlugIndex);
        }

        var flags = global::PulseAudio.Stream.Flags.DONT_MOVE      |
                    global::PulseAudio.Stream.Flags.PEAK_DETECT    |
                    global::PulseAudio.Stream.Flags.ADJUST_LATENCY |
                    global::PulseAudio.Stream.Flags.START_UNMUTED;

        var attr = global::PulseAudio.Stream.BufferAttr () {
            fragsize = (uint32)sizeof (float),
            maxlength = uint32.MAX
        };

        if (stream.connect_record ( "%u".printf (inChannel.monitor_index), attr, flags) < 0) {
            critical (@"Error on create monitor stream");
        }

        return stream;
    }

    protected void stop (global::PulseAudio.Stream inStream) {
        if (inStream != null) {
            paused ();

            inStream.set_read_callback (null);
            inStream.set_suspended_callback (null);
            inStream.disconnect ();
            inStream.flush ();
        }
    }

    private void on_read (global::PulseAudio.Stream inStream, size_t inLength) {
        if (inStream != null) {
            void* buffer;

            if (inStream.peek (out buffer, out inLength) >= 0) {
                if (buffer != null) {
                    unowned float[] data = (float[])buffer;
                    data.length = (int)(inLength / sizeof (float));

                    if (data.length > 0) {
                        peak (data[data.length - 1]);
                    }
                }

                inStream.drop ();
            } else {
                critical (@"Failed to read data from stream");
            }
        }
    }

    private void on_suspended (global::PulseAudio.Stream inStream) {
        paused ();
    }
}