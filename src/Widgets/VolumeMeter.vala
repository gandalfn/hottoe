/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * VolumeMeter.vala
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

public class PantheonSoundControl.Widgets.VolumeMeter : Gtk.LevelBar {
    private int m_Current;
    private double m_Levels[5];
    private Monitor m_Monitor;

    public Monitor monitor {
        get {
            return m_Monitor;
        }
    }

    public double volume_level { get; set; }
    public double nb_bars { get; set; default = 8.0; }

    construct {
        mode = Gtk.LevelBarMode.DISCRETE;
        min_value = 0.0;
        max_value = nb_bars;

        add_offset_value ("low",    nb_bars);
        add_offset_value ("middle", nb_bars * 0.9875);
        add_offset_value ("high",   nb_bars * 0.95);
    }

    public VolumeMeter (Channel inChannel) {
        m_Monitor = inChannel.create_monitor ();
        m_Monitor.peak.connect (on_monitor_peak);
        m_Monitor.paused.connect (on_monitor_paused);

        inChannel.manager.bind_property ("enable-monitoring", m_Monitor, "active", GLib.BindingFlags.SYNC_CREATE);
        m_Monitor.bind_property ("active", this, "sensitive");
        inChannel.bind_property ("volume", this, "volume-level", GLib.BindingFlags.SYNC_CREATE);

        notify["nb-bars"].connect (() => {
            max_value = nb_bars;

            add_offset_value ("low",    nb_bars);
            add_offset_value ("middle", nb_bars * 0.9875);
            add_offset_value ("high",   nb_bars * 0.95);
        });
    }

    private void on_monitor_peak (float inData) {
        m_Levels[m_Current] = inData * (volume_level / 100.0);
        double sum = 0.0;
        foreach (var level in m_Levels) {
            sum += level;
        }
        value = ((sum / m_Levels.length) * nb_bars).clamp (0.0, nb_bars);

        m_Current = (m_Current + 1) % m_Levels.length;
        message (@"value: $(value)");
    }

    private void on_monitor_paused () {
        value = 0.0;
    }
}