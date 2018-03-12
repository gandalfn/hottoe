/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Equalizer.vala
 * Copyright (C) Nicolas Bruguier 2018 <gandalfn@club-internet.fr>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 */

internal class SukaHottoe.PulseAudio.Equalizer : SukaHottoe.Equalizer {
    private Module m_sink_module;
    private dynamic Gst.Element m_source;
    private dynamic Gst.Element m_equalizer;
    private dynamic Gst.Element m_sink;
    private Gst.Pipeline m_pipeline;
    private Device m_device;
    private bool m_channel_set;
    private SukaHottoe.Equalizer.Preset m_preset;

    public override SukaHottoe.Device device {
        get {
            return m_device;
        }
        set {
            if (m_device != value) {
                m_device = (Device)value;

                if (m_channel_set) m_pipeline.set_state (Gst.State.PAUSED);
                m_sink.set_property("device", m_device.name);
                if (m_channel_set) m_pipeline.set_state (Gst.State.PLAYING);
            }
        }
    }

    public override SukaHottoe.Equalizer.Preset preset {
        get {
            return m_preset;
        }
        set {
            if (m_preset != null) {
                m_preset.changed.disconnect (on_preset_freq_changed);
            }

            m_preset = value;

            if (m_preset != null) {
                float last_freq = 0;
                for (int cpt = 0; cpt < m_preset.length; cpt++) {
                    GLib.Object? band = ((Gst.ChildProxy)m_equalizer).get_child_by_index (cpt);

                    if (band != null) {
                        float freq = m_preset[cpt].freq;
                        float bandwidth = freq - last_freq;
                        last_freq = freq;

                        band.set_property("freq", freq);
                        band.set_property("bandwidth", bandwidth);
                        on_preset_freq_changed (cpt);
                    }
                }
                m_preset.changed.connect (on_preset_freq_changed);
            }
        }
    }

    construct {
        m_sink_module = new Module((Manager)device.manager, "module-null-sink");

        Module.Arg[] args = {};
        args += Module.Arg("sink_name", name);
        args += Module.Arg("sink_properties", @"device.icon_name='media-eq-symbolic'device.description='$(description)'");
        args += Module.Arg("channels", "2");
        m_sink_module.load.begin (args);

        manager.channel_added.connect(on_channel_added);

        m_pipeline = new Gst.Pipeline (name);

        m_source = Gst.ElementFactory.make ("pulsesrc", "source");
        m_source.set_property("volume", 1.0);
        m_source.set_property("mute", false);
        m_source.set_property("provide_clock", false);

        m_equalizer = Gst.ElementFactory.make ("equalizer-10bands", "equalizer");

        m_sink = Gst.ElementFactory.make ("pulsesink", "sink");
        m_sink.set_property("volume", 1.0);
        m_sink.set_property("mute", false);
        m_sink.set_property("provide_clock", true);

        m_pipeline.add (m_source);
        m_pipeline.add (m_equalizer);
        m_pipeline.add (m_sink);

        m_pipeline.link_many (m_source, m_equalizer, m_sink);
    }

    public Equalizer(string in_name, string in_description, Manager in_manager) {
        GLib.Object(
            manager: in_manager,
            name: in_name,
            description: in_description
        );
    }

    private void on_channel_added(SukaHottoe.Manager in_manager, SukaHottoe.Channel in_channel) {
        if (in_channel.direction == Direction.OUTPUT && in_channel.name == name) {
            m_pipeline.set_state (Gst.State.PAUSED);
            m_source.set_property ("device", name + ".monitor");
            m_pipeline.set_state (Gst.State.PLAYING);
            m_channel_set = true;
        }
    }

    private void on_preset_freq_changed(int in_index) {
        GLib.Object? band = ((Gst.ChildProxy)m_equalizer).get_child_by_index (in_index);
        if (band != null) {
            float gain = m_preset[in_index].val;
            if (gain < 0) {
                gain *= 0.24f;
            } else {
                gain *= 0.12f;
            }
            band.set_property("gain", gain);
        }
    }
}