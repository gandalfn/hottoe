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

public class PantheonSoundControl.Widgets.PlugSettingsRow : Gtk.Grid {
    private Gtk.Image m_Icon;
    private Gtk.Label m_Title;
    private Gtk.Scale m_Volume;
    private Wnck.Window m_Window;

    public unowned Plug plug { get; construct; }

    static construct {
        Wnck.set_default_mini_icon_size (48);
    }

    construct {
        hexpand = true;
        row_spacing = 6;
        column_spacing = 6;

        var iconBox = new Gtk.EventBox ();
        m_Icon = new Gtk.Image ();
        m_Icon.margin_start = 6;
        m_Icon.pixel_size = 48;
        iconBox.add (m_Icon);
        attach (iconBox, 0, 0, 1, 3);

        var titleBox = new Gtk.EventBox ();
        m_Title = new Gtk.Label ("");
        m_Title.use_markup = true;
        m_Title.hexpand = true;
        m_Title.xalign = 0.0f;
        m_Title.yalign = 1.0f;
        titleBox.add (m_Title);
        attach (titleBox, 1, 0, 1, 1);

        m_Volume = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, plug.volume_muted, plug.volume_max, (plug.volume_max - plug.volume_muted) / 20.0);
        m_Volume.adjustment.page_increment = 5;
        m_Volume.set_size_request (200, -1);
        m_Volume.draw_value = false;
        m_Volume.hexpand = true;
        attach (m_Volume, 1, 1, 1, 1);

        m_Volume.clear_marks ();
        m_Volume.add_mark (plug.volume_muted, Gtk.PositionType.BOTTOM, null);
        m_Volume.add_mark (plug.volume_norm, Gtk.PositionType.BOTTOM, null);

        var switchWidget = new Gtk.Switch ();
        switchWidget.active = true;
        switchWidget.valign = Gtk.Align.START;
        switchWidget.margin_start = 6;
        switchWidget.margin_end = 12;
        attach (switchWidget, 2, 1, 1, 1);

        var vumeter = new VolumeMeter.plug (plug);
        vumeter.margin_start = 6;
        vumeter.margin_end = 24;
        vumeter.nb_bars = 20;
        attach (vumeter, 1, 2, 2, 1);

        switchWidget.bind_property ("active", m_Volume, "sensitive", GLib.BindingFlags.SYNC_CREATE);
        switchWidget.bind_property ("active", m_Title, "sensitive", GLib.BindingFlags.SYNC_CREATE);
        switchWidget.bind_property ("active", m_Icon, "sensitive", GLib.BindingFlags.SYNC_CREATE);
        switchWidget.bind_property ("active", vumeter, "sensitive", GLib.BindingFlags.SYNC_CREATE);

        plug.bind_property ("volume", m_Volume.adjustment, "value", GLib.BindingFlags.BIDIRECTIONAL |
                                                                    GLib.BindingFlags.SYNC_CREATE);
        plug.bind_property ("is_muted", switchWidget, "active", GLib.BindingFlags.BIDIRECTIONAL |
                                                                GLib.BindingFlags.SYNC_CREATE   |
                                                                GLib.BindingFlags.INVERT_BOOLEAN);

        plug.client.notify["pid"].connect (on_pid_changed);
        on_pid_changed ();

        add_events (Gdk.EventMask.SCROLL_MASK);
        iconBox.add_events (Gdk.EventMask.SCROLL_MASK);
        titleBox.add_events (Gdk.EventMask.SCROLL_MASK);
        switchWidget.add_events (Gdk.EventMask.SCROLL_MASK);

        // delegate all scroll events to the scale
        scroll_event.connect (on_scroll);
        iconBox.scroll_event.connect (on_scroll);
        titleBox.scroll_event.connect (on_scroll);
        switchWidget.scroll_event.connect (on_scroll);
    }

    public PlugSettingsRow (Plug inPlug) {
        GLib.Object (
            plug: inPlug
        );
    }

    private bool on_scroll (Gdk.EventScroll event) {
        m_Volume.scroll_event (event);

        return Gdk.EVENT_STOP;
    }

    private void on_pid_changed () {
        if (m_Window != null) {
            m_Window.name_changed.disconnect (on_name_changed);
            m_Window.icon_changed.disconnect (on_icon_changed);
            m_Window = null;
        }

        unowned Wnck.Screen screen = Wnck.Screen.get_default();
        foreach (unowned Wnck.Window win in screen.get_windows()) {
            if (win.get_pid () == plug.client.pid) {
                m_Window = win;
                m_Window.name_changed.connect (on_name_changed);
                m_Window.icon_changed.connect (on_icon_changed);
                break;
            }
        }

        on_name_changed ();
        on_icon_changed ();
    }

    private void on_name_changed () {
        if (m_Window != null) {
            if (m_Window.has_name ()) {
                if ("\n" in m_Window.get_name ()) {
                    m_Title.label = "<b>%s</b>".printf (plug.client.name);
                } else {
                    m_Title.label = "<b>%s</b>".printf (m_Window.get_name ());
                }
            }
        } else {
            m_Title.label = plug.client.name;
        }
    }

    private void on_icon_changed () {
        if (m_Window != null) {
            m_Icon.pixbuf = m_Window.get_mini_icon ();
        } else {
            m_Icon.icon_name = "application-default-icon";
        }
    }
}