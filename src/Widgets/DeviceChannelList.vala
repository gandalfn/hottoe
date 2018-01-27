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
    public Direction direction { get; construct; }
    public Gtk.IconSize icon_size { get; set; default = Gtk.IconSize.DND; }
    public int icon_pixel_size { get; set; default = 32; }
    public bool show_labels { get; set; default = false; }
    public bool show_balance { get; set; default = false; }
    public double monitor_nb_bars { get; set; default = 8.0; }

    public DeviceChannelList (Device inDevice, Direction inDirection = Direction.INPUT | Direction.OUTPUT) {
        Object (
            device: inDevice,
            direction: inDirection
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
        if (inChannel.direction in direction) {
            var view = new ChannelView (inChannel);
            bind_property("icon-size", view, "icon-size", GLib.BindingFlags.SYNC_CREATE);
            bind_property("icon-pixel-size", view, "icon-pixel-size", GLib.BindingFlags.SYNC_CREATE);
            bind_property("show-labels", view, "show-labels", GLib.BindingFlags.SYNC_CREATE);
            bind_property("show-balance", view, "show-balance", GLib.BindingFlags.SYNC_CREATE);
            bind_property("monitor-nb-bars", view, "monitor-nb-bars", GLib.BindingFlags.SYNC_CREATE);
            view.show_all ();
            add (view);
        }
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