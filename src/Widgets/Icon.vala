/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Icon.vala
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

public abstract class Hottoe.Widgets.Icon : Gtk.Grid {
    public enum Size {
        SMALL,
        MEDIUM,
        LARGE,
        EXTRA_LARGE,
        FULL;

        public int to_pixel_size () {
            switch (this) {
                case SMALL:
                    return 16;

                case MEDIUM:
                    return 24;

                case LARGE:
                    return 32;

                case EXTRA_LARGE:
                    return 48;

                case FULL:
                    return 64;
            }

            return 32;
        }
    }

    protected Gtk.Image m_icon;
    protected Gtk.Image m_symbol;
    protected Gtk.Overlay m_overlay;

    public Size size { get; construct set; default = Size.LARGE; }
    public bool use_symbolic { get; construct; default = false; }
    public abstract GLib.Icon gicon { owned get; }

    construct {
        m_icon = new Gtk.Image ();
        m_icon.use_fallback = true;

        m_symbol = new Gtk.Image ();
        m_symbol.no_show_all = true;
        m_symbol.halign = Gtk.Align.END;
        m_symbol.valign = Gtk.Align.END;

        m_overlay = new Gtk.Overlay ();
        m_overlay.width_request = size.to_pixel_size ();
        m_overlay.height_request = size.to_pixel_size ();
        m_overlay.add (m_icon);
        m_overlay.add_overlay (m_symbol);

        add (m_overlay);

        bind_property ("size", m_overlay, "height-request", GLib.BindingFlags.SYNC_CREATE, (b, f, ref t) => {
            t.set_int (((Size)f).to_pixel_size ());
            return true;
        });
        bind_property ("size", m_overlay, "width-request", GLib.BindingFlags.SYNC_CREATE, (b, f, ref t) => {
            t.set_int (((Size)f).to_pixel_size ());
            return true;
        });
        bind_property ("size", m_icon, "pixel-size", GLib.BindingFlags.SYNC_CREATE, (b, f, ref t) => {
            t.set_int (((Size)f).to_pixel_size ());
            return true;
        });
        bind_property ("size", m_symbol, "pixel-size", GLib.BindingFlags.SYNC_CREATE, (b, f, ref t) => {
            t.set_int (((Size)f).to_pixel_size () / 2);
            return true;
        });
    }
}