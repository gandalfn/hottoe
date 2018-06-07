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

internal class Hottoe.PulseAudio.Equalizer : Hottoe.Equalizer {
    private Module m_sink_module;
    private dynamic Gst.Element m_source;
    private dynamic Gst.Element m_equalizer;
    private dynamic Gst.Element m_sink;
    private Gst.Pipeline m_pipeline;
    private bool m_channel_set;
    private Hottoe.Equalizer.Preset m_preset;

    public override Hottoe.Equalizer.Preset preset {
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

                        band.set_property ("freq", freq);
                        band.set_property ("bandwidth", bandwidth);
                        on_preset_freq_changed (cpt);
                    }
                }
                m_preset.changed.connect (on_preset_freq_changed);
            }
        }
    }

    static construct {
        unowned string[]? args = null;
        Gst.init (ref args);
    }

    construct {
        m_sink_module = null;
        foreach (var module in ((Manager)device.manager).get_modules ()) {
            if (module.name == "module-null-sink") {
                foreach (var arg in module.get_arguments ()) {
                    if (arg.name == "sink_name") {
                        if (arg.val == name) {
                            m_sink_module = module;
                            break;
                        }
                    }
                }
            }
            if (m_sink_module != null) break;
        }
        if (m_sink_module == null) {
            m_sink_module = new Module ((Manager)device.manager, "module-null-sink");

            Module.Arg[] args = {};
            args += Module.Arg ("sink_name", name);
            args += Module.Arg ("sink_properties", "device.icon_name='media-eq-symbolic'" +
                                                   @"device.description='$(description)'" +
                                                   "device.equalizer='1'" +
                                                   "application.id='com.gitlab.mithrandirn.hottoe'");
            args += Module.Arg ("channels", "2");
            m_sink_module.load.begin (args);
        }

        m_pipeline = new Gst.Pipeline (name);

        var props = Gst.Structure.from_string ("props," +
                                               "media.role=music," +
                                               "application.id=com.gitlab.mithrandirn.hottoe", null);

        m_source = Gst.ElementFactory.make ("pulsesrc", "source");
        m_source.set ("volume", 1.0,
                      "mute", false,
                      "provide-clock", false,
                      "slave-method", Gst.Audio.BaseSrcSlaveMethod.RE_TIMESTAMP,
                      "stream-properties", props);

        m_equalizer = Gst.ElementFactory.make ("equalizer-10bands", "equalizer");

        m_sink = Gst.ElementFactory.make ("pulsesink", "sink");
        m_sink.set ("volume", 1.0,
                    "mute", false,
                    "provide-clock", true,
                    "stream-properties", props,
                    // TODO: manage device without output
                    "device", device.get_output_channels ()[0].name);

        m_pipeline.add (m_source);
        m_pipeline.add (m_equalizer);
        m_pipeline.add (m_sink);

        m_source.link (m_equalizer);
        m_equalizer.link (m_sink);

        device.manager.channel_added.connect (on_channel_added);

        string channel_name = @"$(name).monitor";
        foreach (var channel in device.manager.get_input_channels ()) {
            if (channel.name == channel_name) {
                m_source.set_property ("device", channel_name);
                m_channel_set = true;
                m_pipeline.set_state (Gst.State.PLAYING);
                break;
            }
        }
    }

    public Equalizer (Device in_device, string in_name, string in_description) {
        GLib.Object (
            device: in_device,
            name: in_name,
            description: in_description
        );
    }

    ~Equalizer () {
        if (m_pipeline != null) {
            m_pipeline.set_state (Gst.State.PAUSED);
            m_pipeline = null;
        }
        if (m_sink_module != null) {
            m_sink_module = null;
        }
    }

    private void on_channel_added (Hottoe.Manager in_manager, Hottoe.Channel in_channel) {
        if (in_channel.direction == Direction.INPUT && in_channel.name == @"$(name).monitor") {
            in_channel.changed.connect (() => {
                m_source.set_property ("device", @"$(name).monitor");
                m_channel_set = true;
                m_pipeline.set_state (Gst.State.PLAYING);
            });
        }
    }

    private void on_preset_freq_changed (int in_index) {
        GLib.Object? band = ((Gst.ChildProxy)m_equalizer).get_child_by_index (in_index);
        if (band != null) {
            float gain = m_preset[in_index].val;
            if (gain < 0) {
                gain *= 0.24f;
            } else {
                gain *= 0.12f;
            }
            band.set_property ("gain", gain);
        }
    }
}