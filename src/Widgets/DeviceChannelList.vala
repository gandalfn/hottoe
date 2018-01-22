/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * DeviceChannelList.vala
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

public class PantheonSoundControl.Widgets.DeviceChannelList : Gtk.Grid {
    public unowned Device device { get; construct; }

    public DeviceChannelList (Device inDevice) {
        Object (
            device: inDevice
        );
    }

    construct {
        orientation = Gtk.Orientation.VERTICAL;
        row_spacing = 12;

        device.channel_added.connect (on_channel_added);

        // connect onto manager channel_removed since the signal can be not emitted from
        // device if the port associated to channel has been removed before the chanel
        // has been destroyed
        device.manager.channel_removed.connect (on_channel_removed);
    }

    private void on_channel_added (Channel inChannel) {
        var view = new ChannelView (inChannel);
        view.show_all ();
        add (view);
    }

    private void on_channel_removed (Channel inChannel) {
        get_children ().foreach ((child) => {
            unowned ChannelView? view = child as ChannelView;
            if (view != null && view.channel == inChannel) {
                child.destroy ();
            }
        });
    }
}