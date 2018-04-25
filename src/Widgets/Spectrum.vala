/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Spectrum.vala
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

public class SukaHottoe.Widgets.Spectrum : Gtk.DrawingArea {
    private SukaHottoe.Spectrum m_spectrum;
    private int64 m_last_frame;
    private Granite.Drawing.BufferSurface m_back;
    private Granite.Drawing.BufferSurface m_front;

    public unowned Device device { get; construct; }
    public bool enabled { get; set; default = true; }
    public int nb_bars { get; set; default = 10; }
    public int nb_bands { get; set; default = 20; }

    construct {
        on_nb_bands_changed ();

        device.manager.channel_added.connect (on_channel_added);

        foreach (var channel in device.get_output_channels ()) {
            on_channel_added (device.manager, channel);
        }

        notify["nb-bands"].connect (on_nb_bands_changed);
    }

    public Spectrum (Device in_device) {
        GLib.Object (
            device: in_device
        );
    }

    public override bool draw (Cairo.Context in_ctx)
        requires (nb_bars > 0) {
        int width = get_allocated_width ();
        int height = get_allocated_height ();

        double yellow = iec_scale(-10);
        double red = iec_scale(-5);

        float[] magnitudes = m_spectrum.get_magnitudes ();

        m_front.context.set_source_rgb ((double)245 / (double)255,
                                        (double)245 / (double)255,
                                        (double)245 / (double)255);
        m_front.context.paint ();
        m_front.context.set_source_surface (m_back.surface, 0, 0);
        m_front.context.paint_with_alpha (0.85);

        for (int band = 0; band < nb_bands; ++band) {
            m_front.context.save ();
            {
                m_front.context.translate (band * 20, 0);
                double val = iec_scale (20 + magnitudes[band]);
                m_front.context.set_source_rgba ((double)0x68/(double)0xff,
                                        (double)0xb7/(double)0xff,
                                        (double)0x23/(double)0xff,
                                        1.0);
                m_front.context.rectangle (0, height - height * val, 12, height * val);
                m_front.context.fill();
            }
            m_front.context.restore ();
        }

        in_ctx.set_source_surface (m_front.surface, 0, 0);
        in_ctx.paint ();

        m_back.context.set_source_surface (m_front.surface, 0, 0);
        m_back.context.paint ();

        return true;
    }

    public override void size_allocate (Gtk.Allocation in_allocation) {
        base.size_allocate (in_allocation);

        m_back = new Granite.Drawing.BufferSurface (in_allocation.width, in_allocation.height);
        m_front = new Granite.Drawing.BufferSurface (in_allocation.width, in_allocation.height);
    }

    private void on_nb_bands_changed () {
        width_request = 20 * nb_bands;
    }

    private void on_channel_added (SukaHottoe.Manager in_manager, SukaHottoe.Channel in_channel) {
        if (m_spectrum == null && in_channel.direction == Direction.OUTPUT && in_channel in device) {
            m_spectrum = in_manager.create_spectrum (in_channel);
            m_spectrum.threshold = -90;
            bind_property ("enabled", m_spectrum, "enabled", GLib.BindingFlags.SYNC_CREATE);
            add_tick_callback (on_tick);
        }
    }

    private bool on_tick (Gtk.Widget in_widget, Gdk.FrameClock in_frame_clock) {
        int64 current_frame = in_frame_clock.get_frame_time ();
        if (current_frame - m_last_frame > 50) {
            queue_draw ();
            m_last_frame = current_frame;
        }
        return true;
    }

    private double
    iec_scale (double inDB)
    {
        double def = 0.0;

        if (inDB < -70.0)
            def = 0.0;
        else if (inDB < -60.0)
            def = (inDB + 70.0) * 0.25;
        else if (inDB < -50.0)
            def = (inDB + 60.0) * 0.5 + 2.5;
        else if (inDB < -40.0)
            def = (inDB + 50.0) * 0.75 + 7.5;
        else if (inDB < -30.0)
            def = (inDB + 40.0) * 1.5 + 15.0;
        else if (inDB < -20.0)
            def = (inDB + 30.0) * 2.0 + 30.0;
        else if (inDB < 0.0)
            def = (inDB + 20.0) * 2.5 + 50.0;
        else
            def = inDB * 5.0 + 90.0;

        return def / 100.0;
    }
}