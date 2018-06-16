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

public class Hottoe.Widgets.Spectrum : Gtk.Grid {
    private class Meter : Gtk.DrawingArea {
        private unowned Spectrum m_spectrum;
        private int m_band;
        private double m_max;

        construct {
            width_request = 8;
            hexpand = true;
            vexpand = true;
        }

        public Meter (Spectrum in_spectrum, int in_band) {
            m_spectrum = in_spectrum;
            m_band = in_band;
        }

        public override bool draw (Cairo.Context in_ctx) {
            int width = get_allocated_width ();
            int height = get_allocated_height ();

            var gradient = new Cairo.Pattern.linear (0, height, 0, 0);
            gradient.add_color_stop_rgb (0.0,
                                         (double)0x68 / (double)0xff,
                                         (double)0xb7 / (double)0xff,
                                         (double)0x23 / (double)0xff);

            gradient.add_color_stop_rgb (m_spectrum.iec_scale (-10),
                                         (double)0xd4 / (double)0xff,
                                         (double)0x8e / (double)0xff,
                                         (double)0x15 / (double)0xff);

            gradient.add_color_stop_rgb (m_spectrum.iec_scale (-5),
                                         (double)0xc6 / (double)0xff,
                                         (double)0x26 / (double)0xff,
                                         (double)0x2e / (double)0xff);

            double gain = m_spectrum[m_band];

            in_ctx.set_source (gradient);
            in_ctx.rectangle (0, height - height * gain, width, height * gain);
            in_ctx.fill ();

            if (gain >= m_max) {
                m_max = gain;
            } else {
                double pos = (double)height * m_max;
                pos -= 4.0;
                m_max = double.max (0.0, pos / (double)height);
            }

            in_ctx.rectangle (0, height - height * m_max, width, 4.0);
            in_ctx.fill ();

            return true;
        }
    }

    private Hottoe.Spectrum m_spectrum;
    private double[] m_magnitudes;
    private Gtk.Grid m_bands;

    public unowned Device device { get; construct; }
    public int interval { get; construct; default = 50; }
    public bool enabled { get; set; default = true; }
    public int nb_bars { get; set; default = 10; }
    public int nb_bands { get; set; default = 20; }
    public double smoothing { get; set; default = 0.00007; }

    construct {
        orientation = Gtk.Orientation.VERTICAL;

        m_bands = new Gtk.Grid ();
        m_bands.orientation = Gtk.Orientation.HORIZONTAL;
        m_bands.column_spacing = 6;
        m_bands.row_homogeneous = true;
        m_bands.column_homogeneous = true;

        on_nb_bands_changed ();

        var db_label = new Gtk.Label ("-70");
        db_label.margin_end = 5;
        attach (db_label, 0, 0);

        var freq_label = new Gtk.Label ("1.0");
        freq_label.margin_top = 5;
        attach (freq_label, 0, 1);

        attach (m_bands, 1, 0);

        device.manager.channel_added.connect (on_channel_added);

        foreach (var channel in device.get_output_channels ()) {
            on_channel_added (device.manager, channel);
        }

        notify["nb-bands"].connect (on_nb_bands_changed);
    }

    public Spectrum (Device in_device, int in_interval) {
        GLib.Object (
            device: in_device,
            interval: in_interval
        );
    }

    private void on_nb_bands_changed () {
        // Remove all old band meter
        get_children ().foreach ((child) => {
            child.destroy ();
        });

        // Create new magnitudes array
        m_magnitudes = new double[nb_bands];

        // Add all band meter
        for (int cpt = 0; cpt < nb_bands; ++cpt) {
            m_bands.attach (new Meter (this, cpt), cpt, 0);
        }

        show_all ();
    }

    private void on_channel_added (Hottoe.Manager in_manager, Hottoe.Channel in_channel) {
        if (m_spectrum == null && in_channel.direction == Direction.OUTPUT && in_channel in device) {
            m_spectrum = in_manager.create_spectrum (in_channel, 32000, interval);
            m_spectrum.threshold = -80;
            m_spectrum.bands = nb_bands;
            m_spectrum.updated.connect (on_spectrum_updated);
            bind_property ("enabled", m_spectrum, "enabled", GLib.BindingFlags.SYNC_CREATE);
        }
    }

    private void on_spectrum_updated () {
        float[] magnitudes = m_spectrum.get_magnitudes ();
        bool updated = false;

        for (int band = 0; band < nb_bands; ++band) {
            double val = magnitudes[band];

            if (m_magnitudes[band] != val) {
                m_magnitudes[band] = val;
                updated = true;
            }
        }

        //if (updated) {
            queue_draw ();
        //}
    }

    private double
    iec_scale (double inDB) {
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
            def = 100.0;

        return def / 100.0;
    }

    private new double @get (int in_index)
        requires (in_index >= 0 && in_index < m_magnitudes.length) {
        return iec_scale (10.0 + m_magnitudes[in_index]);
    }

    public override bool draw (Cairo.Context in_ctx) {
        // Draw scales
        in_ctx.save ();
        {
            Gtk.Allocation allocation;
            get_allocation (out allocation);

            Gtk.Allocation bands_allocation;
            m_bands.get_allocation (out bands_allocation);
            bands_allocation.x -= allocation.x;
            bands_allocation.y -= allocation.y;

            foreach (var child in m_bands.get_children ()) {
                Gtk.Allocation band_allocation;
                child.get_allocation (out band_allocation);

                in_ctx.save ();
                {
                    in_ctx.translate (band_allocation.x - allocation.x, band_allocation.y - allocation.y);

                    in_ctx.set_source_rgb ((double)0xfa / (double)0xff,
                                           (double)0xfa / (double)0xff,
                                           (double)0xfa / (double)0xff);

                    in_ctx.rectangle (0, 0, band_allocation.width, band_allocation.height);
                    in_ctx.fill ();
                }
                in_ctx.restore ();
            }

            in_ctx.set_source_rgb ((double)0x7e / (double)0xff,
                                   (double)0x80 / (double)0xff,
                                   (double)0x87 / (double)0xff);
            in_ctx.save ();
            {
                in_ctx.set_dash ({1, 1}, 0);

                int[] db_range = { 0, -10, -20, -30, -40, -50, -60, -70 };
                foreach (int db in db_range) {
                    double x = bands_allocation.x;
                    double y = bands_allocation.y + (bands_allocation.height * iec_scale (db));

                    in_ctx.move_to (x, y);
                    in_ctx.line_to (x + bands_allocation.width, y);
                    in_ctx.stroke ();
                }
            }
            in_ctx.restore ();

            in_ctx.move_to (bands_allocation.x - 1.5, bands_allocation.y);
            in_ctx.line_to (bands_allocation.x - 1.5, bands_allocation.y + bands_allocation.height + 1.5);
            in_ctx.line_to (bands_allocation.x + 1.5 + bands_allocation.width, bands_allocation.y + 1.5 + bands_allocation.height);
            in_ctx.set_line_width (3.0);
            in_ctx.stroke ();

            // Draw bands
            in_ctx.translate (bands_allocation.x, bands_allocation.y);
            m_bands.draw (in_ctx);
        }
        in_ctx.restore ();

        return true;
    }
}