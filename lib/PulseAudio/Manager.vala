/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Manager.vala
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

namespace PantheonSoundControl.PulseAudio {
    internal class Manager : PantheonSoundControl.Manager {
        private global::PulseAudio.Context m_Context;
        private global::PulseAudio.GLibMainLoop m_Loop;
        private bool m_IsReady = false;
        private uint m_ReconnectTimerId = 0U;
        private Gee.TreeSet<Device> m_Devices;
        private Gee.TreeSet<Channel> m_InputChannels;
        private Gee.TreeSet<Channel> m_OutputChannels;
        private Gee.TreeSet<Client> m_Clients;
        private Gee.TreeSet<Plug> m_InputPlugs;
        private Gee.TreeSet<Plug> m_OutputPlugs;
        private string m_DefaultSinkName;
        private string m_DefaultSourceName;

        public Operations operations { get; private set; }

        public override unowned PantheonSoundControl.Channel? default_input_channel {
            get {
                unowned PantheonSoundControl.Channel? ret = null;
                if (m_DefaultSourceName != null) {
                    var channel = get_channel (m_DefaultSourceName);
                    ret = channel;
                }
                return ret;
            }
        }

        public override unowned PantheonSoundControl.Channel? default_output_channel {
            get {
                unowned PantheonSoundControl.Channel? ret = null;
                if (m_DefaultSourceName != null) {
                    var channel = get_channel (m_DefaultSinkName);
                    ret = channel;
                }
                return ret;
            }
        }

        [CCode (notify = false)]
        public override unowned PantheonSoundControl.Device? default_input_device {
            get {
                unowned PantheonSoundControl.Device? ret = null;
                if (m_DefaultSourceName != null) {
                    var channel = get_channel (m_DefaultSourceName);
                    if (channel != null) {
                        foreach (var device in m_Devices) {
                            if (channel in device) {
                                ret = device;
                                break;
                            }
                        }
                    }
                }
                return ret;
             }
             set {
                if (value != null) {
                    var channels = value.get_input_channels ();
                    if (channels.length > 0) {
                        string channelName = channels[0].name;
                        if (channelName != m_DefaultSourceName) {
                            operations.set_default_source (channelName, (s) => {
                                if (s) {
                                    m_DefaultSourceName = channelName;
                                    notify_property ("default-input-device");
                                    notify_property ("default-input-channel");
                                }
                            });
                        }
                    }
                }
             }
        }

        [CCode (notify = false)]
        public override unowned PantheonSoundControl.Device? default_output_device {
            get {
                unowned PantheonSoundControl.Device? ret = null;
                if (m_DefaultSinkName != null) {
                    var channel = get_channel (m_DefaultSinkName);
                    if (channel != null) {
                        foreach (var device in m_Devices) {
                            if (channel in device) {
                                ret = device;
                                break;
                            }
                        }
                    }
                }
                return ret;
            }
            set {
                if (value != null) {
                    var channels = value.get_output_channels ();
                    if (channels.length > 0) {
                        string channelName = channels[0].name;
                        if (channelName != m_DefaultSinkName) {
                            operations.set_default_sink (channelName, (s) => {
                                if (s) {
                                    m_DefaultSinkName = channelName;
                                    notify_property ("default-output-device");
                                    notify_property ("default-output-channel");
                                }
                            });
                        }
                    }
                }
            }
        }

        construct {
            m_Loop = new global::PulseAudio.GLibMainLoop ();
            m_Devices = new Gee.TreeSet<Device> (Device.compare);
            m_InputChannels = new Gee.TreeSet<Channel> (Channel.compare);
            m_OutputChannels = new Gee.TreeSet<Channel> (Channel.compare);
            m_Clients = new Gee.TreeSet<Client> (Client.compare);
            m_InputPlugs = new Gee.TreeSet<Plug> (Plug.compare);
            m_OutputPlugs = new Gee.TreeSet<Plug> (Plug.compare);
        }

        public Manager () {
        }

        public override void start () {
            reconnect_to_pulse.begin ();
        }

        public override Device[] get_devices () {
            return m_Devices.to_array ();
        }

        public override Channel[] get_output_channels () {
            return m_OutputChannels.to_array ();
        }

        public override Channel[] get_input_channels () {
            return m_InputChannels.to_array ();
        }

        public override Plug[] get_input_plugs () {
            return m_InputPlugs.to_array ();
        }

        public override Plug[] get_output_plugs () {
            return m_OutputPlugs.to_array ();
        }

        public override PantheonSoundControl.Channel get_channel (string inChannelName) {
            PantheonSoundControl.Channel ret = m_InputChannels.first_match ((c) => {
                return c.name == inChannelName;
            });

            if (ret == null) {
                ret = m_OutputChannels.first_match ((c) => {
                    return c.name == inChannelName;
                });
            }

            return ret;
        }

        public override Client[] get_clients () {
            return m_Clients.to_array ();
        }

        private bool reconnect_timeout () {
            if (m_ReconnectTimerId != 0U) {
                m_ReconnectTimerId = 0U;
                reconnect_to_pulse.begin ();
            }
            return false; // G_SOURCE_REMOVE
        }

        private async void reconnect_to_pulse () {
            if (m_IsReady) {
                operations = null;
                m_Context.disconnect ();
                m_Context = null;
                m_IsReady = false;
            }

            var props = new global::PulseAudio.Proplist ();
            props.sets (global::PulseAudio.Proplist.PROP_APPLICATION_ID, "com.github.gandalfn.pantheon-sound-control");
            m_Context = new global::PulseAudio.Context (m_Loop.get_api (), null, props);
            m_Context.set_state_callback (context_state_callback);

            if (m_Context.connect (null, global::PulseAudio.Context.Flags.NOFAIL, null) < 0) {
                warning ("pa_context_connect() failed: %s\n", global::PulseAudio.strerror (m_Context.errno ()));
            }

            operations = new Operations (m_Context);
        }

        private void context_state_callback (global::PulseAudio.Context inContext) {
            switch (inContext.get_state ()) {
                case global::PulseAudio.Context.State.READY:
                    debug ("Context ready");
                    inContext.set_subscribe_callback (subscribe_callback);
                    operations.subscribe (global::PulseAudio.Context.SubscriptionMask.SERVER     |
                                          global::PulseAudio.Context.SubscriptionMask.CARD       |
                                          global::PulseAudio.Context.SubscriptionMask.SINK       |
                                          global::PulseAudio.Context.SubscriptionMask.SOURCE     |
                                          global::PulseAudio.Context.SubscriptionMask.CLIENT     |
                                          global::PulseAudio.Context.SubscriptionMask.SINK_INPUT |
                                          global::PulseAudio.Context.SubscriptionMask.SOURCE_OUTPUT);
                    operations.get_server_info (server_info_callback);
                    operations.get_card_info_list (card_info_callback);
                    operations.get_sink_info_list (sink_info_callback);
                    operations.get_source_info_list (source_info_callback);
                    operations.get_client_info_list (client_info_callback);
                    operations.get_source_output_info_list (source_output_info_callback);
                    operations.get_sink_input_info_list (sink_input_info_callback);
                    m_IsReady = true;
                    break;

                case global::PulseAudio.Context.State.FAILED:
                case global::PulseAudio.Context.State.TERMINATED:
                    debug ("Context terminated");
                    operations.cancel_all ();
                    if (m_ReconnectTimerId == 0U) {
                        m_ReconnectTimerId = GLib.Timeout.add_seconds (2, reconnect_timeout);
                    }
                    break;

                default:
                    m_IsReady = false;
                    break;
            }
        }

        /*
        * This is the main signal callback
        */

        private void subscribe_callback (global::PulseAudio.Context inContext, global::PulseAudio.Context.SubscriptionEventType inEventType, uint32 inIndex) {
            var source_type = inEventType & global::PulseAudio.Context.SubscriptionEventType.FACILITY_MASK;
            switch (source_type) {
                case global::PulseAudio.Context.SubscriptionEventType.SERVER:
                    operations.get_server_info (server_info_callback);
                    break;

                case global::PulseAudio.Context.SubscriptionEventType.CARD:
                    var event_type = inEventType & global::PulseAudio.Context.SubscriptionEventType.TYPE_MASK;
                    switch (event_type) {
                        case global::PulseAudio.Context.SubscriptionEventType.NEW:
                        case global::PulseAudio.Context.SubscriptionEventType.CHANGE:
                            debug ("Card change event");
                            operations.get_card_info_by_index (inIndex, card_info_callback);
                            break;

                        case global::PulseAudio.Context.SubscriptionEventType.REMOVE:
                            debug ("Remove Card event");
                            var device = m_Devices.first_match ((d) => {
                                return d.index == inIndex;
                            });
                            if (device != null) {
                                m_Devices.remove (device);
                                device_removed (device);
                            }
                            break;
                    }
                    break;

                case global::PulseAudio.Context.SubscriptionEventType.SINK:
                    var event_type = inEventType & global::PulseAudio.Context.SubscriptionEventType.TYPE_MASK;
                    switch (event_type) {
                        case global::PulseAudio.Context.SubscriptionEventType.NEW:
                        case global::PulseAudio.Context.SubscriptionEventType.CHANGE:
                            debug ("Sink change event");
                            operations.get_sink_info_by_index (inIndex, sink_info_callback);
                            break;

                        case global::PulseAudio.Context.SubscriptionEventType.REMOVE:
                            debug ("Remove sink event");
                            var channel = m_OutputChannels.first_match ((d) => {
                                return d.index == inIndex;
                            });
                            if (channel != null) {
                                debug (@"Remove channel $(channel.name)");
                                m_OutputChannels.remove (channel);
                                channel_removed (channel);
                            }
                            break;
                    }
                    break;

                case global::PulseAudio.Context.SubscriptionEventType.SOURCE:
                    var event_type = inEventType & global::PulseAudio.Context.SubscriptionEventType.TYPE_MASK;
                    switch (event_type) {
                        case global::PulseAudio.Context.SubscriptionEventType.NEW:
                        case global::PulseAudio.Context.SubscriptionEventType.CHANGE:
                            debug ("Source change event");
                            operations.get_source_info_by_index (inIndex, source_info_callback);
                            break;

                        case global::PulseAudio.Context.SubscriptionEventType.REMOVE:
                            debug ("Remove source event");
                            var channel = m_InputChannels.first_match ((d) => {
                                return d.index == inIndex;
                            });
                            if (channel != null) {
                                debug (@"Remove channel $(channel.name)");
                                m_InputChannels.remove (channel);
                                channel_removed (channel);
                            }
                            break;
                    }
                    break;

                case global::PulseAudio.Context.SubscriptionEventType.CLIENT:
                    var event_type = inEventType & global::PulseAudio.Context.SubscriptionEventType.TYPE_MASK;
                    switch (event_type) {
                        case global::PulseAudio.Context.SubscriptionEventType.NEW:
                        case global::PulseAudio.Context.SubscriptionEventType.CHANGE:
                            debug ("Client change event");
                            operations.get_client_info (inIndex, client_info_callback);
                            break;

                        case global::PulseAudio.Context.SubscriptionEventType.REMOVE:
                            debug (@"Remove client event $(inIndex)");
                            var client = m_Clients.first_match ((c) => {
                                return c.index == inIndex;
                            });
                            if (client != null) {
                                m_Clients.remove (client);
                                client_removed (client);
                            }
                            break;
                    }
                    break;

                case global::PulseAudio.Context.SubscriptionEventType.SINK_INPUT:
                    var event_type = inEventType & global::PulseAudio.Context.SubscriptionEventType.TYPE_MASK;
                    switch (event_type) {
                        case global::PulseAudio.Context.SubscriptionEventType.NEW:
                        case global::PulseAudio.Context.SubscriptionEventType.CHANGE:
                            debug ("Sink input change event");
                            operations.get_sink_input_info (inIndex, sink_input_info_callback);
                            break;

                        case global::PulseAudio.Context.SubscriptionEventType.REMOVE:
                            debug ("Remove sink input event");
                            var plug = m_OutputPlugs.first_match ((p) => {
                                return p.index == inIndex;
                            });
                            if (plug != null) {
                                debug (@"Remove sink input $(plug.name)");
                                if (plug.client != null) {
                                    plug.client.plug_removed (plug);
                                }
                                m_OutputPlugs.remove (plug);
                                plug_removed (plug);
                            }
                            break;
                    }
                    break;

                case global::PulseAudio.Context.SubscriptionEventType.SOURCE_OUTPUT:
                    var event_type = inEventType & global::PulseAudio.Context.SubscriptionEventType.TYPE_MASK;
                    switch (event_type) {
                        case global::PulseAudio.Context.SubscriptionEventType.NEW:
                        case global::PulseAudio.Context.SubscriptionEventType.CHANGE:
                            debug ("Source output change event");
                            operations.get_source_output_info (inIndex, source_output_info_callback);
                            break;

                        case global::PulseAudio.Context.SubscriptionEventType.REMOVE:
                            debug ("Remove source output event");
                            var plug = m_InputPlugs.first_match ((p) => {
                                return p.index == inIndex;
                            });
                            if (plug != null) {
                                debug (@"Remove source output $(plug.name)");
                                if (plug.client != null) {
                                    plug.client.plug_removed (plug);
                                }
                                m_InputPlugs.remove (plug);
                                plug_removed (plug);
                            }
                            break;
                    }
                    break;
            }
        }

        /*
        * Retrieve object informations
        */

        private void server_info_callback (global::PulseAudio.ServerInfo? inInfo) {
            if (inInfo != null) {
                if (m_DefaultSourceName != inInfo.default_source_name) {
                    m_DefaultSourceName = inInfo.default_source_name;
                    notify_property ("default-input-device");
                    notify_property ("default-input-channel");
                }
                if (m_DefaultSinkName != inInfo.default_sink_name) {
                    m_DefaultSinkName = inInfo.default_sink_name;
                    notify_property ("default-output-device");
                    notify_property ("default-output-channel");
                }
            }
        }

        private void card_info_callback(global::PulseAudio.CardInfo? inInfo) {
            if (inInfo != null) {
                debug ("Card %s changed :", inInfo.name);

                var devIndex = inInfo.index;
                Device device = m_Devices.first_match ((d) => {
                    return devIndex == d.index;
                });
                if (device == null) {
                    device = new Device (this, inInfo);
                    m_Devices.add (device);

                    debug (@"Add device $(device.name)");

                    device_added (device);
                } else {
                    debug (@"Update device $(device.name)");

                    device.update (inInfo);
                }
            }
        }

        private void sink_info_callback(global::PulseAudio.SinkInfo? inInfo) {
            if (inInfo != null) {
                debug ("Sink %s changed :", inInfo.name);

                var channelIndex = inInfo.index;
                if (!inInfo.name.has_suffix (".monitor")) {
                    OutputChannel channel = m_OutputChannels.first_match ((d) => {
                        return channelIndex == d.index;
                    }) as OutputChannel;
                    if (channel == null) {
                        channel = new OutputChannel (this, inInfo);
                        m_OutputChannels.add (channel);

                        debug (@"Add channel $(channel.name)");

                        channel_added (channel);

                        // Send default output device notification if new channel matches default
                        if (m_DefaultSinkName == channel.name) {
                            notify_property ("default-output-device");
                            notify_property ("default-output-channel");
                        }
                    } else {
                        debug (@"Update channel $(channel.name)");

                        channel.update (inInfo);
                    }
                }
            }
        }

        private void source_info_callback(global::PulseAudio.SourceInfo? inInfo) {
            if (inInfo != null) {
                debug ("Source %s changed :", inInfo.name);

                var channelIndex = inInfo.index;
                if (!inInfo.name.has_suffix (".monitor")) {
                    InputChannel channel = m_InputChannels.first_match ((d) => {
                        return channelIndex == d.index;
                    }) as InputChannel;
                    if (channel == null) {
                        channel = new InputChannel (this, inInfo);
                        m_InputChannels.add (channel);

                        debug (@"Add channel $(channel.name)");

                        channel_added (channel);

                        // Send default input device notification if new channel matches default
                        if (m_DefaultSourceName == channel.name) {
                            notify_property ("default-input-device");
                            notify_property ("default-input-channel");
                        }
                    } else {
                        debug (@"Update channel $(channel.name)");

                        channel.update (inInfo);
                    }
                }
            }
        }

        private void client_info_callback(global::PulseAudio.ClientInfo? inInfo) {
            if (inInfo != null) {
                debug ("Client %u changed :", inInfo.index);

                var clientIndex = inInfo.index;
                Client client = m_Clients.first_match ((c) => {
                    return clientIndex == c.index;
                }) as Client;
                if (client == null) {
                    client = new Client (this, inInfo);
                    m_Clients.add (client);

                    debug (@"Add client $(client.index)");

                    client_added (client);
                } else {
                    debug (@"Update client $(client.index)");

                    client.update (inInfo);
                }
            }
        }

        private void sink_input_info_callback(global::PulseAudio.SinkInputInfo? inInfo) {
            if (inInfo != null) {
                debug ("Sink input %s changed :", inInfo.name);

                var plugIndex = inInfo.index;
                OutputPlug plug = m_OutputPlugs.first_match ((p) => {
                    return plugIndex == p.index;
                }) as OutputPlug;
                if (plug == null) {
                    var sinkIndex = inInfo.sink;
                    if (m_OutputChannels.first_match ((c) => { return sinkIndex == c.index; }) != null) {
                        plug = new OutputPlug (this, inInfo);
                        m_OutputPlugs.add (plug);

                        debug (@"Add plug $(plug.name)");

                        plug_added (plug);
                    }
                } else {
                    debug (@"Update plug $(plug.name)");

                    plug.update (inInfo);
                }
            }
        }

        private void source_output_info_callback(global::PulseAudio.SourceOutputInfo? inInfo) {
            if (inInfo != null) {
                debug ("Source output %s changed :", inInfo.name);

                var plugIndex = inInfo.index;
                InputPlug plug = m_InputPlugs.first_match ((p) => {
                    return plugIndex == p.index;
                }) as InputPlug;
                if (plug == null) {
                    var sourceIndex = inInfo.source;
                    if (m_InputChannels.first_match ((c) => { return sourceIndex == c.index; }) != null) {
                        plug = new InputPlug (this, inInfo);
                        m_InputPlugs.add (plug);

                        debug (@"Add plug $(plug.name)");

                        plug_added (plug);
                    }
                } else {
                    debug (@"Update plug $(plug.name)");

                    plug.update (inInfo);
                }
            }
        }
    }

    [CCode (cname = "pantheon_sound_pulseaudio_load")]
    public static PantheonSoundControl.Manager? load () {
        return new Manager ();
    }
}