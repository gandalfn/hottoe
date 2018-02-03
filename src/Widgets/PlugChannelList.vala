/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * PlugChannelList.vala
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

public class PantheonSoundControl.Widgets.PlugChannelList : Gtk.Grid {
    private Gee.LinkedList<ChannelRadioButton> m_group;

    public unowned Plug plug { get; construct; }

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;

        plug.notify["channel"].connect (on_plug_channel_changed);

        plug.manager.channel_added.connect (on_channel_added);
        plug.manager.channel_removed.connect (on_channel_removed);

        m_group = new Gee.LinkedList<ChannelRadioButton> ();

        Channel[] channels;
        if (plug.direction == Direction.INPUT) {
            channels = plug.manager.get_input_channels ();
        } else if (plug.direction == Direction.OUTPUT) {
            channels = plug.manager.get_output_channels ();
        }

        foreach (unowned Channel channel in channels) {
            var button = new ChannelRadioButton (channel, m_group);
            m_group.add (button);
            button.active = channel == plug.channel;
            button.notify["active"].connect (on_channel_activated);
            add (button);
        }
    }

    public PlugChannelList (Plug in_plug) {
        GLib.Object (
            plug: in_plug
        );
    }

    private void on_channel_added (Channel in_channel) {
        if (in_channel.direction == plug.direction) {
            var button = new ChannelRadioButton (in_channel, m_group);
            m_group.add (button);
            button.active = in_channel == plug.channel;
            button.notify["active"].connect (on_channel_activated);
            button.show_all ();
            add (button);
        }
    }

    private void on_channel_removed (Channel in_channel) {
        get_children ().foreach ((child) => {
            unowned ChannelRadioButton? button = child as ChannelRadioButton;
            if (button != null && button.channel == in_channel) {
                m_group.remove (button);
                child.destroy ();
            }
        });
    }

    private void on_plug_channel_changed () {
        get_children ().foreach ((child) => {
            unowned ChannelRadioButton? button = child as ChannelRadioButton;
            if (button != null && button.channel == plug.channel) {
                button.active = true;
            }
        });
    }

    private void on_channel_activated (GLib.Object in_object, GLib.ParamSpec in_pspec) {
        var button = in_object as ChannelRadioButton;
        if (button.active) {
            plug.channel = button.channel;
        }
    }
}