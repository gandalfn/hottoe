/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * PlugSettingsList.vala
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

public class PantheonSoundControl.Widgets.PlugSettingsList : Gtk.Grid {
    private Gtk.ListBox m_plugs;
    private PlugChooser m_plugs_chooser;

    public unowned Device device { get; construct; }
    public Direction direction { get; construct; }

    construct {
        column_spacing = 12;
        row_spacing = 12;

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.hexpand = scrolled.vexpand = true;

        var header_label = new Gtk.Label (_("Clients:"));
        header_label.margin_start = 12;
        header_label.margin_top = 6;
        header_label.halign = Gtk.Align.START;
        header_label.get_style_context ().add_class ("h4");

        m_plugs = new Gtk.ListBox ();
        m_plugs.selection_mode = Gtk.SelectionMode.NONE;
        scrolled.add (m_plugs);

        var add_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        add_button.tooltip_text = _("Add Client…");

        m_plugs_chooser = new PlugChooser(add_button, device, direction);
        m_plugs_chooser.modal = true;
        m_plugs_chooser.plug_selected.connect(on_plug_selected);
        add_button.clicked.connect(() => {
            if (m_plugs_chooser.available > 0) {
                m_plugs_chooser.show_all();
            }
        });

        var toolbar = new Gtk.ActionBar ();
        toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        toolbar.add (add_button);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        main_box.add (header_label);
        main_box.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_box.add (scrolled);
        main_box.add (toolbar);

        var frame = new Gtk.Frame (null);
        frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        frame.add (main_box);

        add (frame);

        device.manager.plug_added.connect (on_plug_added);
        device.manager.plug_removed.connect (on_plug_removed);
    }

    public PlugSettingsList (Device in_device, Direction in_direction) {
        GLib.Object (
            device: in_device,
            direction: in_direction
        );
    }

    private void add_plug (Plug in_plug) {
        if (in_plug.client != null && !in_plug.client.is_mine &&
            in_plug.channel != null && in_plug.channel in device &&
            in_plug.direction in direction) {
            bool found = false;
            foreach (var child in m_plugs.get_children ()) {
                unowned PlugSettingsRow? row = ((Gtk.ListBoxRow) child).get_child () as PlugSettingsRow;
                if (row != null && row.plug == in_plug) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                PlugSettingsRow row = new PlugSettingsRow (in_plug);
                row.margin_bottom = 12;
                row.show_all ();
                m_plugs.add (row);
            }
        }
    }

    private void remove_plug (Plug in_plug) {
        foreach (unowned Gtk.Widget? child in m_plugs.get_children ()) {
            unowned PlugSettingsRow? row = ((Gtk.ListBoxRow) child).get_child () as PlugSettingsRow;
            if (row != null && row.plug == in_plug) {
                child.destroy ();
                break;
            }
        }
    }

    private void on_plug_added (Plug in_plug) {
        in_plug.notify["channel"].connect (on_plug_channel_changed);

        add_plug (in_plug);
    }

    private void on_plug_removed (Plug in_plug) {
        in_plug.notify["channel"].disconnect (on_plug_channel_changed);

        remove_plug (in_plug);
    }

    private void on_plug_channel_changed (GLib.Object in_object, GLib.ParamSpec? in_spec) {
        unowned Plug plug = (Plug)in_object;

        if (plug.client != null && !plug.client.is_mine &&
            plug.channel != null && plug.channel in device &&
            plug.direction in direction) {
            add_plug (plug);
        } else {
            remove_plug (plug);
        }
    }

    private void on_plug_selected(Plug in_plug) {
        if (direction == Direction.OUTPUT) {
            in_plug.channel = device.get_output_channels()[0];
        } else {
            in_plug.channel = device.get_input_channels()[0];
        }
    }
}