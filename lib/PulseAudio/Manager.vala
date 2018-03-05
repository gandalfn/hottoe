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

namespace SukaHottoe.PulseAudio {
    internal class Manager : SukaHottoe.Manager {
        private global::PulseAudio.Context m_context;
        private global::PulseAudio.GLibMainLoop m_loop;
        private bool m_is_ready = false;
        private uint m_reconnect_timer_id = 0U;
        private Gee.TreeSet<Device> m_devices;
        private Gee.TreeSet<Channel> m_input_channels;
        private Gee.TreeSet<Channel> m_output_channels;
        private Gee.TreeSet<Client> m_clients;
        private Gee.TreeSet<Plug> m_input_plugs;
        private Gee.TreeSet<Plug> m_output_plugs;
        private string m_default_sink_name;
        private string m_default_source_name;

        public Operations operations { get; private set; }

        public override unowned SukaHottoe.Channel? default_input_channel {
            get {
                unowned SukaHottoe.Channel? ret = null;
                if (m_default_source_name != null) {
                    var channel = get_channel (m_default_source_name);
                    ret = channel;
                }
                return ret;
            }
        }

        public override unowned SukaHottoe.Channel? default_output_channel {
            get {
                unowned SukaHottoe.Channel? ret = null;
                if (m_default_source_name != null) {
                    var channel = get_channel (m_default_sink_name);
                    ret = channel;
                }
                return ret;
            }
        }

        [CCode (notify = false)]
        public override unowned SukaHottoe.Device? default_input_device {
            get {
                unowned SukaHottoe.Device? ret = null;
                if (m_default_source_name != null) {
                    var channel = get_channel (m_default_source_name);
                    if (channel != null) {
                        foreach (var device in m_devices) {
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
                        if (channelName != m_default_source_name) {
                            operations.set_default_source (channelName, (s) => {
                                if (s) {
                                    m_default_source_name = channelName;
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
        public override unowned SukaHottoe.Device? default_output_device {
            get {
                unowned SukaHottoe.Device? ret = null;
                if (m_default_sink_name != null) {
                    var channel = get_channel (m_default_sink_name);
                    if (channel != null) {
                        foreach (var device in m_devices) {
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
                        if (channelName != m_default_sink_name) {
                            operations.set_default_sink (channelName, (s) => {
                                if (s) {
                                    m_default_sink_name = channelName;
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
            m_loop = new global::PulseAudio.GLibMainLoop ();
            m_devices = new Gee.TreeSet<Device> (Device.compare);
            m_input_channels = new Gee.TreeSet<Channel> (Channel.compare);
            m_output_channels = new Gee.TreeSet<Channel> (Channel.compare);
            m_clients = new Gee.TreeSet<Client> (Client.compare);
            m_input_plugs = new Gee.TreeSet<Plug> (Plug.compare);
            m_output_plugs = new Gee.TreeSet<Plug> (Plug.compare);
        }

        public Manager () {
        }

        public override void start () {
            reconnect_to_pulse.begin ();
        }

        public override Device[] get_devices () {
            return m_devices.to_array ();
        }

        public override Channel[] get_output_channels () {
            return m_output_channels.to_array ();
        }

        public override Channel[] get_input_channels () {
            return m_input_channels.to_array ();
        }

        public override Plug[] get_input_plugs () {
            return m_input_plugs.to_array ();
        }

        public override Plug[] get_output_plugs () {
            return m_output_plugs.to_array ();
        }

        public override SukaHottoe.Channel get_channel (string in_channel_name) {
            SukaHottoe.Channel ret = m_input_channels.first_match ((c) => {
                return c.name == in_channel_name;
            });

            if (ret == null) {
                ret = m_output_channels.first_match ((c) => {
                    return c.name == in_channel_name;
                });
            }

            return ret;
        }

        public override Client[] get_clients () {
            return m_clients.to_array ();
        }

        private bool reconnect_timeout () {
            if (m_reconnect_timer_id != 0U) {
                m_reconnect_timer_id = 0U;
                reconnect_to_pulse.begin ();
            }
            return false; // G_SOURCE_REMOVE
        }

        private async void reconnect_to_pulse () {
            if (m_is_ready) {
                operations = null;
                m_context.disconnect ();
                m_context = null;
                m_is_ready = false;
            }

            var props = new global::PulseAudio.Proplist ();
            props.sets (global::PulseAudio.Proplist.PROP_APPLICATION_ID, "com.github.gandalfn.suka-hottoe");
            m_context = new global::PulseAudio.Context (m_loop.get_api (), null, props);
            m_context.set_state_callback (context_state_callback);

            if (m_context.connect (null, global::PulseAudio.Context.Flags.NOFAIL, null) < 0) {
                warning ("pa_context_connect() failed: %s\n", global::PulseAudio.strerror (m_context.errno ()));
            }

            operations = new Operations (m_context);
        }

        private void context_state_callback (global::PulseAudio.Context in_context) {
            switch (in_context.get_state ()) {
                case global::PulseAudio.Context.State.READY:
                    debug ("Context ready");
                    in_context.set_subscribe_callback (subscribe_callback);
                    operations.subscribe (global::PulseAudio.Context.SubscriptionMask.SERVER |
                                          global::PulseAudio.Context.SubscriptionMask.CARD |
                                          global::PulseAudio.Context.SubscriptionMask.SINK |
                                          global::PulseAudio.Context.SubscriptionMask.SOURCE |
                                          global::PulseAudio.Context.SubscriptionMask.CLIENT |
                                          global::PulseAudio.Context.SubscriptionMask.SINK_INPUT |
                                          global::PulseAudio.Context.SubscriptionMask.SOURCE_OUTPUT);
                    operations.get_server_info (server_info_callback);
                    operations.get_card_info_list (card_info_callback);
                    operations.get_sink_info_list (sink_info_callback);
                    operations.get_source_info_list (source_info_callback);
                    operations.get_client_info_list (client_info_callback);
                    operations.get_source_output_info_list (source_output_info_callback);
                    operations.get_sink_input_info_list (sink_input_info_callback);
                    m_is_ready = true;
                    break;

                case global::PulseAudio.Context.State.FAILED:
                case global::PulseAudio.Context.State.TERMINATED:
                    debug ("Context terminated");
                    operations.cancel_all ();
                    if (m_reconnect_timer_id == 0U) {
                        m_reconnect_timer_id = GLib.Timeout.add_seconds (2, reconnect_timeout);
                    }
                    break;

                default:
                    m_is_ready = false;
                    break;
            }
        }

        /*
        * This is the main signal callback
        */

        private void subscribe_callback (global::PulseAudio.Context in_context,
                                         global::PulseAudio.Context.SubscriptionEventType in_event_type,
                                         uint32 in_index) {
            var source_type = in_event_type & global::PulseAudio.Context.SubscriptionEventType.FACILITY_MASK;
            switch (source_type) {
                case global::PulseAudio.Context.SubscriptionEventType.SERVER:
                    operations.get_server_info (server_info_callback);
                    break;

                case global::PulseAudio.Context.SubscriptionEventType.CARD:
                    var event_type = in_event_type & global::PulseAudio.Context.SubscriptionEventType.TYPE_MASK;
                    switch (event_type) {
                        case global::PulseAudio.Context.SubscriptionEventType.NEW:
                        case global::PulseAudio.Context.SubscriptionEventType.CHANGE:
                            debug ("Card change event");
                            operations.get_card_info_by_index (in_index, card_info_callback);
                            break;

                        case global::PulseAudio.Context.SubscriptionEventType.REMOVE:
                            debug ("Remove Card event");
                            var device = m_devices.first_match ((d) => {
                                return d.index == in_index;
                            });
                            if (device != null) {
                                m_devices.remove (device);
                                device_removed (device);
                            }
                            break;
                    }
                    break;

                case global::PulseAudio.Context.SubscriptionEventType.SINK:
                    var event_type = in_event_type & global::PulseAudio.Context.SubscriptionEventType.TYPE_MASK;
                    switch (event_type) {
                        case global::PulseAudio.Context.SubscriptionEventType.NEW:
                        case global::PulseAudio.Context.SubscriptionEventType.CHANGE:
                            debug ("Sink change event");
                            operations.get_sink_info_by_index (in_index, sink_info_callback);
                            break;

                        case global::PulseAudio.Context.SubscriptionEventType.REMOVE:
                            debug ("Remove sink event");
                            var channel = m_output_channels.first_match ((d) => {
                                return d.index == in_index;
                            });
                            if (channel != null) {
                                debug (@"Remove channel $(channel.name)");
                                m_output_channels.remove (channel);
                                channel_removed (channel);
                            }
                            break;
                    }
                    break;

                case global::PulseAudio.Context.SubscriptionEventType.SOURCE:
                    var event_type = in_event_type & global::PulseAudio.Context.SubscriptionEventType.TYPE_MASK;
                    switch (event_type) {
                        case global::PulseAudio.Context.SubscriptionEventType.NEW:
                        case global::PulseAudio.Context.SubscriptionEventType.CHANGE:
                            debug ("Source change event");
                            operations.get_source_info_by_index (in_index, source_info_callback);
                            break;

                        case global::PulseAudio.Context.SubscriptionEventType.REMOVE:
                            debug ("Remove source event");
                            var channel = m_input_channels.first_match ((d) => {
                                return d.index == in_index;
                            });
                            if (channel != null) {
                                debug (@"Remove channel $(channel.name)");
                                m_input_channels.remove (channel);
                                channel_removed (channel);
                            }
                            break;
                    }
                    break;

                case global::PulseAudio.Context.SubscriptionEventType.CLIENT:
                    var event_type = in_event_type & global::PulseAudio.Context.SubscriptionEventType.TYPE_MASK;
                    switch (event_type) {
                        case global::PulseAudio.Context.SubscriptionEventType.NEW:
                        case global::PulseAudio.Context.SubscriptionEventType.CHANGE:
                            debug ("Client change event");
                            operations.get_client_info (in_index, client_info_callback);
                            break;

                        case global::PulseAudio.Context.SubscriptionEventType.REMOVE:
                            debug (@"Remove client event $(in_index)");
                            var client = m_clients.first_match ((c) => {
                                return c.index == in_index;
                            });
                            if (client != null) {
                                m_clients.remove (client);
                                client_removed (client);
                            }
                            break;
                    }
                    break;

                case global::PulseAudio.Context.SubscriptionEventType.SINK_INPUT:
                    var event_type = in_event_type & global::PulseAudio.Context.SubscriptionEventType.TYPE_MASK;
                    switch (event_type) {
                        case global::PulseAudio.Context.SubscriptionEventType.NEW:
                        case global::PulseAudio.Context.SubscriptionEventType.CHANGE:
                            debug ("Sink input change event");
                            operations.get_sink_input_info (in_index, sink_input_info_callback);
                            break;

                        case global::PulseAudio.Context.SubscriptionEventType.REMOVE:
                            debug ("Remove sink input event");
                            var plug = m_output_plugs.first_match ((p) => {
                                return p.index == in_index;
                            });
                            if (plug != null) {
                                debug (@"Remove sink input $(plug.name)");
                                if (plug.client != null) {
                                    plug.client.plug_removed (plug);
                                }
                                m_output_plugs.remove (plug);
                                plug_removed (plug);
                            }
                            break;
                    }
                    break;

                case global::PulseAudio.Context.SubscriptionEventType.SOURCE_OUTPUT:
                    var event_type = in_event_type & global::PulseAudio.Context.SubscriptionEventType.TYPE_MASK;
                    switch (event_type) {
                        case global::PulseAudio.Context.SubscriptionEventType.NEW:
                        case global::PulseAudio.Context.SubscriptionEventType.CHANGE:
                            debug ("Source output change event");
                            operations.get_source_output_info (in_index, source_output_info_callback);
                            break;

                        case global::PulseAudio.Context.SubscriptionEventType.REMOVE:
                            debug ("Remove source output event");
                            var plug = m_input_plugs.first_match ((p) => {
                                return p.index == in_index;
                            });
                            if (plug != null) {
                                debug (@"Remove source output $(plug.name)");
                                if (plug.client != null) {
                                    plug.client.plug_removed (plug);
                                }
                                m_input_plugs.remove (plug);
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

        private void server_info_callback (global::PulseAudio.ServerInfo? in_info) {
            if (in_info != null) {
                if (m_default_source_name != in_info.default_source_name) {
                    m_default_source_name = in_info.default_source_name;
                    notify_property ("default-input-device");
                    notify_property ("default-input-channel");
                }
                if (m_default_sink_name != in_info.default_sink_name) {
                    m_default_sink_name = in_info.default_sink_name;
                    notify_property ("default-output-device");
                    notify_property ("default-output-channel");
                }
            }
        }

        private void card_info_callback (global::PulseAudio.CardInfo? in_info) {
            if (in_info != null) {
                debug ("Card %s changed :", in_info.name);

                var devIndex = in_info.index;
                Device device = m_devices.first_match ((d) => {
                    return devIndex == d.index;
                });
                if (device == null) {
                    device = new Device (this, in_info);
                    m_devices.add (device);

                    debug (@"Add device $(device.name)");

                    device_added (device);
                } else {
                    debug (@"Update device $(device.name)");

                    device.update (in_info);
                }
            }
        }

        private void sink_info_callback (global::PulseAudio.SinkInfo? in_info) {
            if (in_info != null) {
                debug ("Sink %s changed :", in_info.name);

                var channelIndex = in_info.index;
                if (!in_info.name.has_suffix (".monitor")) {
                    OutputChannel channel = m_output_channels.first_match ((d) => {
                        return channelIndex == d.index;
                    }) as OutputChannel;
                    if (channel == null) {
                        channel = new OutputChannel (this, in_info);
                        m_output_channels.add (channel);

                        debug (@"Add channel $(channel.name)");

                        channel_added (channel);

                        // Send default output device notification if new channel matches default
                        if (m_default_sink_name == channel.name) {
                            notify_property ("default-output-device");
                            notify_property ("default-output-channel");
                        }
                    } else {
                        debug (@"Update channel $(channel.name)");

                        channel.update (in_info);
                    }
                }
            }
        }

        private void source_info_callback (global::PulseAudio.SourceInfo? in_info) {
            if (in_info != null) {
                debug ("Source %s changed :", in_info.name);

                var channelIndex = in_info.index;
                if (!in_info.name.has_suffix (".monitor")) {
                    InputChannel channel = m_input_channels.first_match ((d) => {
                        return channelIndex == d.index;
                    }) as InputChannel;
                    if (channel == null) {
                        channel = new InputChannel (this, in_info);
                        m_input_channels.add (channel);

                        debug (@"Add channel $(channel.name)");

                        channel_added (channel);

                        // Send default input device notification if new channel matches default
                        if (m_default_source_name == channel.name) {
                            notify_property ("default-input-device");
                            notify_property ("default-input-channel");
                        }
                    } else {
                        debug (@"Update channel $(channel.name)");

                        channel.update (in_info);
                    }
                }
            }
        }

        private void client_info_callback (global::PulseAudio.ClientInfo? in_info) {
            if (in_info != null) {
                debug ("Client %u changed :", in_info.index);

                var clientIndex = in_info.index;
                Client client = m_clients.first_match ((c) => {
                    return clientIndex == c.index;
                }) as Client;
                if (client == null) {
                    client = new Client (this, in_info);
                    m_clients.add (client);

                    debug (@"Add client $(client.index)");

                    client_added (client);
                } else {
                    debug (@"Update client $(client.index)");

                    client.update (in_info);
                }
            }
        }

        private void sink_input_info_callback (global::PulseAudio.SinkInputInfo? in_info) {
            if (in_info != null) {
                debug ("Sink input %s changed :", in_info.name);

                var plugIndex = in_info.index;
                OutputPlug plug = m_output_plugs.first_match ((p) => {
                    return plugIndex == p.index;
                }) as OutputPlug;
                if (plug == null) {
                    var sinkIndex = in_info.sink;
                    if (m_output_channels.first_match ((c) => { return sinkIndex == c.index; }) != null) {
                        plug = new OutputPlug (this, in_info);
                        m_output_plugs.add (plug);

                        debug (@"Add plug $(plug.name)");

                        plug_added (plug);
                    }
                } else {
                    debug (@"Update plug $(plug.name)");

                    plug.update (in_info);
                }
            }
        }

        private void source_output_info_callback (global::PulseAudio.SourceOutputInfo? in_info) {
            if (in_info != null) {
                debug ("Source output %s changed :", in_info.name);

                var plugIndex = in_info.index;
                InputPlug plug = m_input_plugs.first_match ((p) => {
                    return plugIndex == p.index;
                }) as InputPlug;
                if (plug == null) {
                    var sourceIndex = in_info.source;
                    if (m_input_channels.first_match ((c) => { return sourceIndex == c.index; }) != null) {
                        plug = new InputPlug (this, in_info);
                        m_input_plugs.add (plug);

                        debug (@"Add plug $(plug.name)");

                        plug_added (plug);
                    }
                } else {
                    debug (@"Update plug $(plug.name)");

                    plug.update (in_info);
                }
            }
        }
    }

    [CCode (cname = "suka_hottoe_pulseaudio_load")]
    public static SukaHottoe.Manager? load () {
        return new Manager ();
    }
}