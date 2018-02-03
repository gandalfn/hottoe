/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * SoundNotification.vala
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

public class PantheonSoundControl.Services.SoundNotification : Services.Notification {
    private Canberra.Proplist m_props;
    private unowned Channel m_channel;

    public static bool enabled { get; set; }

    public SoundNotification.volume_change (Channel? in_channel = null) {
        m_channel = in_channel;

        Canberra.Proplist.create (out m_props);
        m_props.sets (Canberra.PROP_CANBERRA_CACHE_CONTROL, "volatile");
        m_props.sets (Canberra.PROP_EVENT_ID, "audio-volume-change");
    }

    public override void send () {
        unowned Canberra.Context? ctx = CanberraGtk.context_get ();
        if (ctx != null) {
            if (m_channel != null) {
                uint32 index;
                m_channel.get ("index", out index);
                ctx.change_device ("%lu".printf (index));
            }
            ctx.play_full (0, m_props);
            ctx.change_device (null);
        }
    }
}