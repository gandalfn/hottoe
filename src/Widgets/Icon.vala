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

public abstract class PantheonSoundControl.Widgets.Icon : Gtk.Grid {
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

    protected Gtk.Image m_Icon;
    protected Gtk.Image m_Symbol;
    protected Gtk.Overlay m_Overlay;

    public Size size { get; construct set; default = Size.LARGE; }

    construct {
        m_Icon = new Gtk.Image ();
        m_Icon.use_fallback = true;

        m_Symbol = new Gtk.Image ();
        m_Symbol.no_show_all = true;
        m_Symbol.halign = Gtk.Align.END;
        m_Symbol.valign = Gtk.Align.END;

        m_Overlay = new Gtk.Overlay ();
        m_Overlay.width_request = size.to_pixel_size ();
        m_Overlay.height_request = size.to_pixel_size ();
        m_Overlay.add (m_Icon);
        m_Overlay.add_overlay (m_Symbol);

        add (m_Overlay);

        bind_property ("size", m_Icon, "pixel-size", GLib.BindingFlags.SYNC_CREATE, (b, f, ref t) => {
            t.set_int (((Size)f).to_pixel_size ());
            return true;
        });
        bind_property ("size", m_Symbol, "pixel-size", GLib.BindingFlags.SYNC_CREATE, (b, f, ref t) => {
            t.set_int (((Size)f).to_pixel_size () / 2);
            return true;
        });
    }
}