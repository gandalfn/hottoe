/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Spectrum.vala
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

internal class Hottoe.PulseAudio.Spectrum : Hottoe.Spectrum {
    private dynamic Gst.Element m_source;
    private dynamic Gst.Element m_spectrum;
    private dynamic Gst.Element m_sink;
    private Gst.Pipeline m_pipeline;
    private float[] m_magnitudes;

    static construct {
        string[]? args = {};
        args += "--gst-debug=SUKA_HOTTOE_SPECTRUM:9";
        unowned string[]? a = args;
        Gst.init (ref a);
    }

    construct {
        message("create spectrum");
        m_magnitudes = new float[bands];
        m_pipeline = new Gst.Pipeline ("hottoe-spectrum");

        var props = Gst.Structure.from_string ("props," +
                                               "media.role=music," +
                                               "application.id=com.gitlab.mithrandirn.hottoe", null);

        m_source = Gst.ElementFactory.make ("pulsesrc", "source");
        m_source.set ("volume", 1.0,
                      "mute", false,
                      "stream-properties", props,
                      "device", channel.name + ".monitor");

        var audioconvert = Gst.ElementFactory.make ("audioconvert", "audioconvert");

        m_spectrum = Gst.ElementFactory.make ("shspectrum", "shspectrum");
        m_spectrum.set ("bands", bands,
                        "threshold", (float)threshold,
                        "interval", (uint64)(interval * 1000 * 1000));

        m_sink = Gst.ElementFactory.make ("fakesink", "sink");
        m_sink.set ("sync", true);

        var caps = new Gst.Caps.simple("audio/x-raw", "rate", typeof(int), sample_rate);

        m_pipeline.add (m_source);
        m_pipeline.add (audioconvert);
        m_pipeline.add (m_spectrum);
        m_pipeline.add (m_sink);

        m_source.link (audioconvert);
        audioconvert.link_filtered (m_spectrum, caps);
        m_spectrum.link (m_sink);

        bind_property("bands", m_spectrum, "bands");
        bind_property("threshold", m_spectrum, "threshold");

        Gst.Bus bus = m_pipeline.get_bus ();
        bus.add_watch (0, on_bus_callback);

        notify["enabled"].connect (on_enabled_changed);
        notify["bands"].connect (() =>  {
            m_magnitudes = new float[bands];
        });
    }

    public Spectrum(Hottoe.Channel in_channel, int in_sample_rate, int in_interval) {
        GLib.Object (
            channel: in_channel,
            sample_rate: in_sample_rate,
            interval: in_interval
        );
    }

    ~Spectrum () {
        if (m_pipeline != null) {
            m_pipeline.set_state (Gst.State.PAUSED);
            m_pipeline = null;
        }
    }

    public override unowned float[]? get_magnitudes () {
        return m_magnitudes;
    }

    private bool on_bus_callback (Gst.Bus in_bus, Gst.Message in_message) {
        switch (in_message.type) {
            case Gst.MessageType.ELEMENT:
                unowned Gst.Structure struct = in_message.get_structure();
                string name = struct.get_name ();

                if (name == "shspectrum") {
                    var vals = struct.get_value ("magnitude");
                    for (int cpt = 0; cpt < bands; ++cpt) {
                        var mag = Gst.ValueList.get_value(vals, cpt);

                        if (mag != null) {
                            m_magnitudes[cpt] = (float)mag;
                        }
                    }
                    updated();
                }
                break;
            default:
                break;
        }
        return true;
    }

    private void on_enabled_changed () {
        if (m_pipeline != null) {
            if (enabled) {
                m_pipeline.set_state (Gst.State.PLAYING);
            } else {
                m_pipeline.set_state (Gst.State.PAUSED);
            }
        }
    }
}