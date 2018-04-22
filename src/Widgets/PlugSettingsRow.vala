/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * PlugSettingsRow.vala
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

public class SukaHottoe.Widgets.PlugSettingsRow : Gtk.Grid {
    private Gtk.Scale m_volume;

    public unowned Plug plug { get; construct; }

    construct {
        hexpand = true;
        row_spacing = 6;
        column_spacing = 6;

        var icon_box = new Gtk.EventBox ();
        var icon = new ClientIcon (plug.client, Icon.Size.EXTRA_LARGE);
        icon.margin_start = 6;
        icon_box.add (icon);
        attach (icon_box, 0, 0, 1, 3);

        var title_box = new Gtk.EventBox ();
        var title = new Gtk.Label ("");
        title.use_markup = true;
        title.hexpand = true;
        title.xalign = 0.0f;
        title.yalign = 1.0f;
        title_box.add (title);
        attach (title_box, 1, 0, 1, 1);

        m_volume = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL,
                                             plug.volume_muted,
                                             plug.volume_max,
                                             (plug.volume_max - plug.volume_muted) / 20.0);
        m_volume.adjustment.page_increment = 5;
        m_volume.set_size_request (200, -1);
        m_volume.draw_value = false;
        m_volume.hexpand = true;
        attach (m_volume, 1, 1, 1, 1);

        m_volume.clear_marks ();
        m_volume.add_mark (plug.volume_muted, Gtk.PositionType.BOTTOM, null);
        m_volume.add_mark (plug.volume_norm, Gtk.PositionType.BOTTOM, null);

        var switch_widget = new Gtk.Switch ();
        switch_widget.active = true;
        switch_widget.valign = Gtk.Align.START;
        switch_widget.margin_start = 6;
        switch_widget.margin_end = 12;
        attach (switch_widget, 2, 1, 1, 1);

        var vumeter = new VuMeter.plug (plug);
        vumeter.margin_start = 6;
        vumeter.margin_end = 24;
        vumeter.nb_bars = 25;
        attach (vumeter, 1, 2, 2, 1);

        switch_widget.bind_property ("active", m_volume, "sensitive", GLib.BindingFlags.SYNC_CREATE);
        switch_widget.bind_property ("active", title, "sensitive", GLib.BindingFlags.SYNC_CREATE);
        switch_widget.bind_property ("active", icon, "sensitive", GLib.BindingFlags.SYNC_CREATE);
        switch_widget.bind_property ("active", vumeter, "sensitive", GLib.BindingFlags.SYNC_CREATE);

        plug.bind_property ("volume", m_volume.adjustment, "value", GLib.BindingFlags.BIDIRECTIONAL |
                                                                    GLib.BindingFlags.SYNC_CREATE);
        plug.bind_property ("is_muted", switch_widget, "active", GLib.BindingFlags.BIDIRECTIONAL |
                                                                 GLib.BindingFlags.SYNC_CREATE |
                                                                 GLib.BindingFlags.INVERT_BOOLEAN);

        plug.client.bind_property ("name", title, "label", GLib.BindingFlags.SYNC_CREATE, (b, f, ref t) => {
            t.set_string ("<b>%s</b>".printf ((string)f));
            return true;
        });

        add_events (Gdk.EventMask.SCROLL_MASK);
        icon_box.add_events (Gdk.EventMask.SCROLL_MASK);
        title_box.add_events (Gdk.EventMask.SCROLL_MASK);
        switch_widget.add_events (Gdk.EventMask.SCROLL_MASK);

        // delegate all scroll events to the scale
        scroll_event.connect (on_scroll);
        icon_box.scroll_event.connect (on_scroll);
        title_box.scroll_event.connect (on_scroll);
        switch_widget.scroll_event.connect (on_scroll);
    }

    public PlugSettingsRow (Plug in_plug) {
        GLib.Object (
            plug: in_plug
        );
    }

    private bool on_scroll (Gdk.EventScroll in_event) {
        m_volume.scroll_event (in_event);

        return Gdk.EVENT_STOP;
    }
}