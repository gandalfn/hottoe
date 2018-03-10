/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Operations.vala
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

internal class SukaHottoe.PulseAudio.Operations : GLib.Object {
    public abstract class Operation : GLib.Object {
        public unowned Operations parent;
        public unowned Operation? prev;
        public Operation next;
        public global::PulseAudio.Operation operation;

        ~Operation () {
            debug (@"destroy operation");
        }

        public void cancel () {
            debug (@"cancel operation $(operation.get_state ())");

            if (operation.get_state () == global::PulseAudio.Operation.State.RUNNING) {
                operation.cancel ();
            }

            finish ();
        }

        public void finish () {
            ref ();
            {
                if (parent != null) {
                    unowned Operation? nextSaved = next;

                    if (this == parent.head) {
                        parent.head = next;
                    } else {
                        prev.next = next;
                    }

                    if (this == parent.tail) {
                        parent.tail = prev;
                    } else {
                        nextSaved.prev = prev;
                    }

                    prev = null;
                    next = null;
                    parent = null;
                }
            }
            unref ();
        }

        public abstract bool compare (Operation in_other);
    }

    public class Subscribe : Operation {
        public delegate void Callback (bool in_success);

        public Callback? callback;

        public Subscribe (global::PulseAudio.Context in_context,
                          global::PulseAudio.Context.SubscriptionMask in_mask,
                          owned Callback? in_callback) {
            debug (@"new subscribe operation");
            callback = (owned)in_callback;
            operation = in_context.subscribe (in_mask, on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is Subscribe;
        }

        private void on_finish (global::PulseAudio.Context in_context, bool in_success) {
            debug (@"finish subscribe");
            if (callback != null) {
                callback (in_success);
            }

            finish ();
        }
    }

    public class GetServerInfo : Operation {
        public delegate void Callback (global::PulseAudio.ServerInfo? in_info);

        public Callback? callback;

        public GetServerInfo (global::PulseAudio.Context in_context, owned Callback? in_callback) {
            debug (@"new get server info operation");
            callback = (owned)in_callback;
            operation = in_context.get_server_info (on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is GetServerInfo;
        }

        private void on_finish (global::PulseAudio.Context in_context, global::PulseAudio.ServerInfo? in_info) {
            if (in_info != null) {
                debug (@"finish get server info");
                if (callback != null) {
                    callback (in_info);
                }
                finish ();
            }
        }
    }

    public class GetCardInfoList : Operation {
        public delegate void Callback (global::PulseAudio.CardInfo? in_info);

        public Callback? callback;

        public GetCardInfoList (global::PulseAudio.Context in_context, owned Callback? in_callback) {
            debug (@"new card info list operation");
            callback = (owned)in_callback;
            operation = in_context.get_card_info_list (on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is GetCardInfoList;
        }

        private void on_finish (global::PulseAudio.Context in_context, global::PulseAudio.CardInfo? in_info) {
            if (in_info != null) {
                debug (@"finish card info list");
                if (callback != null) {
                    callback (in_info);
                }
            } else {
                debug (@"finish and destroy card info list");
                finish ();
            }
        }
    }

    public class GetCardInfoByIndex : Operation {
        public delegate void Callback (global::PulseAudio.CardInfo? in_info);

        public uint32 index;
        public Callback? callback;

        public GetCardInfoByIndex (global::PulseAudio.Context in_context,
                                   uint32 in_index,
                                   owned Callback? in_callback) {
            debug (@"new card info by index $(in_index) operation");
            index = in_index;
            callback = (owned)in_callback;
            operation = in_context.get_card_info_by_index (index, on_finish);
        }

        public override bool compare (Operation in_other) {
            bool ret = in_other is GetCardInfoByIndex;
            if (ret) {
                ret = (index == ((GetCardInfoByIndex) in_other).index);
            }
            return ret;
        }

        private void on_finish (global::PulseAudio.Context in_context, global::PulseAudio.CardInfo? in_info) {
            if (in_info != null) {
                debug (@"finish card info by index $(index)");
                if (callback != null) {
                    callback (in_info);
                }
            } else {
                debug (@"finish and destroy card info by index $(index)");
                finish ();
            }
        }
    }

    public class GetSinkInfoList : Operation {
        public delegate void Callback (global::PulseAudio.SinkInfo? in_info);

        public Callback? callback;

        public GetSinkInfoList (global::PulseAudio.Context in_context, owned Callback? in_callback) {
            debug (@"new get sink info list operation");
            callback = (owned)in_callback;
            operation = in_context.get_sink_info_list (on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is GetSinkInfoList;
        }

        private void on_finish (global::PulseAudio.Context in_context, global::PulseAudio.SinkInfo? in_info) {
            if (in_info != null) {
                debug (@"finish get sink info list");
                if (callback != null) {
                    callback (in_info);
                }
            } else {
                debug (@"finish and destroy get sink info list");
                finish ();
            }
        }
    }

    public class GetSinkInfoByIndex : Operation {
        public delegate void Callback (global::PulseAudio.SinkInfo? in_info);

        public uint32 index;
        public Callback? callback;

        public GetSinkInfoByIndex (global::PulseAudio.Context in_context,
                                   uint32 in_index,
                                   owned Callback? in_callback) {
            debug (@"new get sink info by index $(in_index) operation");
            index = in_index;
            callback = (owned)in_callback;
            operation = in_context.get_sink_info_by_index (index, on_finish);
        }

        public override bool compare (Operation in_other) {
            bool ret = in_other is GetSinkInfoByIndex;
            if (ret) {
                ret = (index == ((GetSinkInfoByIndex) in_other).index);
            }
            return ret;
        }

        private void on_finish (global::PulseAudio.Context in_context, global::PulseAudio.SinkInfo? in_info) {
            if (in_info != null) {
                debug (@"finish sink info by index $(index)");
                if (callback != null) {
                    callback (in_info);
                }
            } else {
                debug (@"finish and destroy sink info by index $(index)");
                finish ();
            }
        }
    }

    public class GetSourceInfoList : Operation {
        public delegate void Callback (global::PulseAudio.SourceInfo? in_info);

        public Callback? callback;

        public GetSourceInfoList (global::PulseAudio.Context in_context, owned Callback? in_callback) {
            debug (@"new get source info list operation");
            callback = (owned)in_callback;
            operation = in_context.get_source_info_list (on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is GetSourceInfoList;
        }

        private void on_finish (global::PulseAudio.Context in_context, global::PulseAudio.SourceInfo? in_info) {
            if (in_info != null) {
                debug (@"finish source info list");
                if (callback != null) {
                    callback (in_info);
                }
            } else {
                debug (@"finish and destroy source info list");
                finish ();
            }
        }
    }

    public class GetSourceInfoByIndex : Operation {
        public delegate void Callback (global::PulseAudio.SourceInfo? in_info);

        public uint32 index;
        public Callback? callback;

        public GetSourceInfoByIndex (global::PulseAudio.Context in_context,
                                     uint32 in_index,
                                     owned Callback? in_callback) {
            debug (@"new get source info by index $(in_index) operation");
            index = in_index;
            callback = (owned)in_callback;
            operation = in_context.get_source_info_by_index (index, on_finish);
        }

        public override bool compare (Operation in_other) {
            bool ret = in_other is GetSourceInfoByIndex;
            if (ret) {
                ret = (index == ((GetSourceInfoByIndex) in_other).index);
            }
            return ret;
        }

        private void on_finish (global::PulseAudio.Context in_context, global::PulseAudio.SourceInfo? in_info) {
            if (in_info != null) {
                debug (@"finish source info by index $(index)");
                if (callback != null) {
                    callback (in_info);
                }
            } else {
                debug (@"finish and destroy source info by index $(index)");
                finish ();
            }
        }
    }

    public class SetCardProfileByIndex : Operation {
        public delegate void Callback (bool in_success);

        public uint32 index;
        public string profile_name;
        public Callback? callback;

        public SetCardProfileByIndex (global::PulseAudio.Context in_context,
                                      uint32 in_index,
                                      string in_profile_name,
                                      owned Callback? in_callback) {
            debug (@"new set card profile by index $(in_index) operation");
            index = in_index;
            profile_name = in_profile_name;
            callback = (owned)in_callback;
            operation = in_context.set_card_profile_by_index (in_index, in_profile_name, on_finish);
        }

        public override bool compare (Operation in_other) {
            bool ret = false;

            if (in_other is SetCardProfileByIndex) {
                ret = ((SetCardProfileByIndex)in_other).index == index;
            }

            return ret;
        }

        private void on_finish (global::PulseAudio.Context in_context, bool in_success) {
            debug (@"finish set profile by index $(index)");
            if (callback != null) {
                callback (in_success);
            }
            finish ();
        }
    }

    public class SetDefaultSource : Operation {
        public delegate void Callback (bool in_success);

        public string channel_name;
        public Callback? callback;

        public SetDefaultSource (global::PulseAudio.Context in_context,
                                 string in_channel_name,
                                 owned Callback? in_callback) {
            debug (@"new set default source $(in_channel_name) operation");
            channel_name = in_channel_name;
            callback = (owned)in_callback;
            operation = in_context.set_default_source (channel_name, on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is SetDefaultSource;
        }

        private void on_finish (global::PulseAudio.Context in_context, bool in_success) {
            debug (@"finish set default source $(channel_name)");
            if (callback != null) {
                callback (in_success);
            }
            finish ();
        }
    }

    public class SetDefaultSink : Operation {
        public delegate void Callback (bool in_success);

        public string channel_name;
        public Callback? callback;

        public SetDefaultSink (global::PulseAudio.Context in_context,
                               string in_channel_name,
                               owned Callback? in_callback) {
            debug (@"new set default sink $(in_channel_name) operation");
            channel_name = in_channel_name;
            callback = (owned)in_callback;
            operation = in_context.set_default_sink (channel_name, on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is SetDefaultSink;
        }

        private void on_finish (global::PulseAudio.Context in_context, bool in_success) {
            debug (@"finish set default sink $(channel_name)");
            if (callback != null) {
                callback (in_success);
            }
            finish ();
        }
    }

    public class SetSourcePortByIndex : Operation {
        public delegate void Callback (bool in_success);

        public uint32 index;
        public string port_name;
        public Callback? callback;

        public SetSourcePortByIndex (global::PulseAudio.Context in_context, uint32 in_index,
                                     string in_port_name,
                                     owned Callback? in_callback) {
            debug (@"new set source port by index $(index) port $(in_port_name) operation");
            index = in_index;
            port_name = in_port_name;
            callback = (owned)in_callback;
            operation = in_context.set_source_port_by_index (index, port_name, on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is SetSourcePortByIndex;
        }

        private void on_finish (global::PulseAudio.Context in_context, bool in_success) {
            debug (@"finish set source port by index $(index) port $(port_name)");
            if (callback != null) {
                callback (in_success);
            }
            finish ();
        }
    }

    public class SetSinkPortByIndex : Operation {
        public delegate void Callback (bool in_success);

        public uint32 index;
        public string port_name;
        public Callback? callback;

        public SetSinkPortByIndex (global::PulseAudio.Context in_context,
                                   uint32 in_index,
                                   string in_port_name,
                                   owned Callback? in_callback) {
            debug (@"new set sink port by index $(index) port $(in_port_name) operation");
            index = in_index;
            port_name = in_port_name;
            callback = (owned)in_callback;
            operation = in_context.set_sink_port_by_index (index, port_name, on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is SetSinkPortByIndex;
        }

        private void on_finish (global::PulseAudio.Context in_context, bool in_success) {
            debug (@"finish set sink port by index $(index) port $(port_name)");
            if (callback != null) {
                callback (in_success);
            }
            finish ();
        }
    }

    public class SetSourceVolumeByIndex : Operation {
        public delegate void Callback (bool in_success);

        public uint32 index;
        public global::PulseAudio.CVolume volume;
        public Callback? callback;

        public SetSourceVolumeByIndex (global::PulseAudio.Context in_context,
                                       uint32 in_index,
                                       global::PulseAudio.CVolume in_volume,
                                       owned Callback? in_callback) {
            debug (@"new set source volume by index $(index) operation");
            index = in_index;
            volume = in_volume;
            callback = (owned)in_callback;
            operation = in_context.set_source_volume_by_index (index, volume, on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is SetSourceVolumeByIndex;
        }

        private void on_finish (global::PulseAudio.Context in_context, bool in_success) {
            debug (@"finish set source volume index $(index)");
            if (callback != null) {
                callback (in_success);
            }
            finish ();
        }
    }

    public class SetSinkVolumeByIndex : Operation {
        public delegate void Callback (bool in_success);

        public uint32 index;
        public global::PulseAudio.CVolume volume;
        public Callback? callback;

        public SetSinkVolumeByIndex (global::PulseAudio.Context in_context,
                                     uint32 in_index,
                                     global::PulseAudio.CVolume in_volume,
                                     owned Callback? in_callback) {
            debug (@"new set sink volume by index $(index) operation");
            index = in_index;
            volume = in_volume;
            callback = (owned)in_callback;
            operation = in_context.set_sink_volume_by_index (index, volume, on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is SetSinkVolumeByIndex;
        }

        private void on_finish (global::PulseAudio.Context in_context, bool in_success) {
            debug (@"finish set sink volume index $(index)");
            if (callback != null) {
                callback (in_success);
            }
            finish ();
        }
    }

    public class SetSourceMuteByIndex : Operation {
        public delegate void Callback (bool in_success);

        public uint32 index;
        public bool mute;
        public Callback? callback;

        public SetSourceMuteByIndex (global::PulseAudio.Context in_context,
                                     uint32 in_index,
                                     bool in_mute,
                                     owned Callback? in_callback) {
            debug (@"new set source mute by index $(index) operation");
            index = in_index;
            mute = in_mute;
            callback = (owned)in_callback;
            operation = in_context.set_source_mute_by_index (index, mute, on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is SetSourceMuteByIndex;
        }

        private void on_finish (global::PulseAudio.Context in_context, bool in_success) {
            debug (@"finish set source mute index $(index)");
            if (callback != null) {
                callback (in_success);
            }
            finish ();
        }
    }

    public class SetSinkMuteByIndex : Operation {
        public delegate void Callback (bool in_success);

        public uint32 index;
        public bool mute;
        public Callback? callback;

        public SetSinkMuteByIndex (global::PulseAudio.Context in_context,
                                   uint32 in_index,
                                   bool in_mute,
                                   owned Callback? in_callback) {
            debug (@"new set sink mute by index $(index) operation");
            index = in_index;
            mute = in_mute;
            callback = (owned)in_callback;
            operation = in_context.set_sink_mute_by_index (index, mute, on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is SetSinkMuteByIndex;
        }

        private void on_finish (global::PulseAudio.Context in_context, bool in_success) {
            debug (@"finish set sink mute index $(index)");
            if (callback != null) {
                callback (in_success);
            }
            finish ();
        }
    }

    public class GetClientInfoList : Operation {
        public delegate void Callback (global::PulseAudio.ClientInfo? in_info);

        public Callback? callback;

        public GetClientInfoList (global::PulseAudio.Context in_context, owned Callback? in_callback) {
            debug (@"new get client info list operation");
            callback = (owned)in_callback;
            operation = in_context.get_client_info_list (on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is GetClientInfoList;
        }

        private void on_finish (global::PulseAudio.Context in_context, global::PulseAudio.ClientInfo? in_info) {
            if (in_info != null) {
                debug (@"finish client info list");
                if (callback != null) {
                    callback (in_info);
                }
            } else {
                debug (@"finish and destroy client info list");
                finish ();
            }
        }
    }

    public class GetClientInfo : Operation {
        public delegate void Callback (global::PulseAudio.ClientInfo? in_info);

        public uint32 index;
        public Callback? callback;

        public GetClientInfo (global::PulseAudio.Context in_context, uint32 in_index, owned Callback? in_callback) {
            debug (@"new get client info by index $(in_index) operation");
            index = in_index;
            callback = (owned)in_callback;
            operation = in_context.get_client_info (index, on_finish);
        }

        public override bool compare (Operation in_other) {
            bool ret = in_other is GetClientInfo;
            if (ret) {
                ret = (index == ((GetClientInfo) in_other).index);
            }
            return ret;
        }

        private void on_finish (global::PulseAudio.Context in_context, global::PulseAudio.ClientInfo? in_info) {
            if (in_info != null) {
                debug (@"finish client info $(index)");
                if (callback != null) {
                    callback (in_info);
                }
            } else {
                debug (@"finish and destroy client info $(index)");
                finish ();
            }
        }
    }

    public class SetSourceOutputVolume : Operation {
        public delegate void Callback (bool in_success);

        public uint32 index;
        public global::PulseAudio.CVolume volume;
        public Callback? callback;

        public SetSourceOutputVolume (global::PulseAudio.Context in_context,
                                      uint32 in_index,
                                      global::PulseAudio.CVolume in_volume,
                                      owned Callback? in_callback) {
            debug (@"new set source output volume $(index) operation");
            index = in_index;
            volume = in_volume;
            callback = (owned)in_callback;
            operation = in_context.set_source_output_volume (index, volume, on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is SetSourceOutputVolume;
        }

        private void on_finish (global::PulseAudio.Context in_context, bool in_success) {
            debug (@"finish set source output volume $(index)");
            if (callback != null) {
                callback (in_success);
            }
            finish ();
        }
    }

    public class SetSinkInputVolume : Operation {
        public delegate void Callback (bool in_success);

        public uint32 index;
        public global::PulseAudio.CVolume volume;
        public Callback? callback;

        public SetSinkInputVolume (global::PulseAudio.Context in_context,
                                   uint32 in_index,
                                   global::PulseAudio.CVolume in_volume,
                                   owned Callback? in_callback) {
            debug (@"new set sink input volume $(index) operation");
            index = in_index;
            volume = in_volume;
            callback = (owned)in_callback;
            operation = in_context.set_sink_input_volume (index, volume, on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is SetSinkInputVolume;
        }

        private void on_finish (global::PulseAudio.Context in_context, bool in_success) {
            debug (@"finish set sink input volume $(index)");
            if (callback != null) {
                callback (in_success);
            }
            finish ();
        }
    }

    public class SetSourceOutputMute : Operation {
        public delegate void Callback (bool in_success);

        public uint32 index;
        public bool mute;
        public Callback? callback;

        public SetSourceOutputMute (global::PulseAudio.Context in_context,
                                    uint32 in_index,
                                    bool in_mute,
                                    owned Callback? in_callback) {
            debug (@"new set source output mute $(index) operation");
            index = in_index;
            mute = in_mute;
            callback = (owned)in_callback;
            operation = in_context.set_source_output_mute (index, mute, on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is SetSourceOutputMute;
        }

        private void on_finish (global::PulseAudio.Context in_context, bool in_success) {
            debug (@"finish set source output mute $(index)");
            if (callback != null) {
                callback (in_success);
            }
            finish ();
        }
    }

    public class SetSinkInputMute : Operation {
        public delegate void Callback (bool in_success);

        public uint32 index;
        public bool mute;
        public Callback? callback;

        public SetSinkInputMute (global::PulseAudio.Context in_context,
                                 uint32 in_index,
                                 bool in_mute,
                                 owned Callback? in_callback) {
            debug (@"new set sink input mute $(index) operation");
            index = in_index;
            mute = in_mute;
            callback = (owned)in_callback;
            operation = in_context.set_sink_input_mute (index, mute, on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is SetSinkInputMute;
        }

        private void on_finish (global::PulseAudio.Context in_context, bool in_success) {
            debug (@"finish set sink input mute $(index)");
            if (callback != null) {
                callback (in_success);
            }
            finish ();
        }
    }

    public class MoveSourceOutputByIndex : Operation {
        public delegate void Callback (bool in_success);

        public uint32 index;
        public uint32 source;
        public Callback? callback;

        public MoveSourceOutputByIndex (global::PulseAudio.Context in_context,
                                        uint32 in_index,
                                        uint32 in_source,
                                        owned Callback? in_callback) {
            debug (@"new move source output $(index) operation");
            index = in_index;
            source = in_source;
            callback = (owned)in_callback;
            operation = in_context.move_source_output_by_index (index, source, on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is MoveSourceOutputByIndex;
        }

        private void on_finish (global::PulseAudio.Context in_context, bool in_success) {
            debug (@"finish set source output $(index)");
            if (callback != null) {
                callback (in_success);
            }
            finish ();
        }
    }

    public class MoveSinkInputByIndex : Operation {
        public delegate void Callback (bool in_success);

        public uint32 index;
        public uint32 sink;
        public Callback? callback;

        public MoveSinkInputByIndex (global::PulseAudio.Context in_context,
                                     uint32 in_index,
                                     uint32 in_sink,
                                     owned Callback? in_callback) {
            debug (@"new move sink input $(index) operation");
            index = in_index;
            sink = in_sink;
            callback = (owned)in_callback;
            operation = in_context.move_sink_input_by_index (index, sink, on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is MoveSinkInputByIndex;
        }

        private void on_finish (global::PulseAudio.Context in_context, bool in_success) {
            debug (@"finish move sink input $(index)");
            if (callback != null) {
                callback (in_success);
            }
            finish ();
        }
    }

    public class GetSourceOutputInfoList : Operation {
        public delegate void Callback (global::PulseAudio.SourceOutputInfo? in_info);

        public Callback? callback;

        public GetSourceOutputInfoList (global::PulseAudio.Context in_context, owned Callback? in_callback) {
            debug (@"new get source output info list operation");
            callback = (owned)in_callback;
            operation = in_context.get_source_output_info_list (on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is GetSourceOutputInfoList;
        }

        private void on_finish (global::PulseAudio.Context in_context, global::PulseAudio.SourceOutputInfo? in_info) {
            if (in_info != null) {
                debug (@"finish source output info list");
                if (callback != null) {
                    callback (in_info);
                }
            } else {
                debug (@"finish and destroy source output info list");
                finish ();
            }
        }
    }

    public class GetSinkInputInfoList : Operation {
        public delegate void Callback (global::PulseAudio.SinkInputInfo? in_info);

        public Callback? callback;

        public GetSinkInputInfoList (global::PulseAudio.Context in_context, owned Callback? in_callback) {
            debug (@"new get sink input info list operation");
            callback = (owned)in_callback;
            operation = in_context.get_sink_input_info_list (on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is GetSinkInputInfoList;
        }

        private void on_finish (global::PulseAudio.Context in_context, global::PulseAudio.SinkInputInfo? in_info) {
            if (in_info != null) {
                debug (@"finish sink input info list");
                if (callback != null) {
                    callback (in_info);
                }
            } else {
                debug (@"finish and destroy sink input info list");
                finish ();
            }
        }
    }

    public class GetSourceOutputInfo : Operation {
        public delegate void Callback (global::PulseAudio.SourceOutputInfo? in_info);

        public uint32 index;
        public Callback? callback;

        public GetSourceOutputInfo (global::PulseAudio.Context in_context,
                                    uint32 in_index,
                                    owned Callback? in_callback) {
            debug (@"new get source output info by index $(in_index) operation");
            index = in_index;
            callback = (owned)in_callback;
            operation = in_context.get_source_output_info (index, on_finish);
        }

        public override bool compare (Operation in_other) {
            bool ret = in_other is GetSourceOutputInfo;
            if (ret) {
                ret = (index == ((GetSourceOutputInfo) in_other).index);
            }
            return ret;
        }

        private void on_finish (global::PulseAudio.Context in_context, global::PulseAudio.SourceOutputInfo? in_info) {
            if (in_info != null) {
                debug (@"finish source output info $(index)");
                if (callback != null) {
                    callback (in_info);
                }
            } else {
                debug (@"finish and destroy source output info $(index)");
                finish ();
            }
        }
    }

    public class GetSinkInputInfo : Operation {
        public delegate void Callback (global::PulseAudio.SinkInputInfo? in_info);

        public uint32 index;
        public Callback? callback;

        public GetSinkInputInfo (global::PulseAudio.Context in_context, uint32 in_index, owned Callback? in_callback) {
            debug (@"new get sink input info by index $(in_index) operation");
            index = in_index;
            callback = (owned)in_callback;
            operation = in_context.get_sink_input_info (index, on_finish);
        }

        public override bool compare (Operation in_other) {
            bool ret = in_other is GetSinkInputInfo;
            if (ret) {
                ret = (index == ((GetSinkInputInfo) in_other).index);
            }
            return ret;
        }

        private void on_finish (global::PulseAudio.Context in_context, global::PulseAudio.SinkInputInfo? in_info) {
            if (in_info != null) {
                debug (@"finish sink input info $(index)");
                if (callback != null) {
                    callback (in_info);
                }
            } else {
                debug (@"finish and destroy sink input info $(index)");
                finish ();
            }
        }
    }

    public class LoadModule : Operation {
        public string name;
        public string args;
        public delegate void Callback (uint32 in_index);

        public Callback? callback;

        public LoadModule (global::PulseAudio.Context in_context,
                           string in_name,
                           string? in_args,
                           owned Callback? in_callback) {
            debug (@"load module $(in_name) operation");
            name = in_name;
            args = in_args;
            callback = (owned)in_callback;
            operation = in_context.load_module (name, args, on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is LoadModule &&
                   ((LoadModule)in_other).name == name &&
                   ((LoadModule)in_other).args == args;
        }

        private void on_finish (global::PulseAudio.Context in_context, uint32 in_index) {
            debug (@"finish load module $(in_index)");
            if (callback != null) {
                callback (in_index);
            }
            finish ();
        }
    }

    public class UnloadModule : Operation {
        public delegate void Callback (bool in_success);

        public uint32 index;
        public Callback? callback;

        public UnloadModule (global::PulseAudio.Context in_context,
                             uint32 in_index,
                             owned Callback? in_callback) {
            debug (@"unload module $(index) operation");
            index = in_index;
            callback = (owned)in_callback;
            operation = in_context.unload_module (index, on_finish);
        }

        public override bool compare (Operation in_other) {
            return in_other is UnloadModule &&
                   ((UnloadModule)in_other).index == index;
        }

        private void on_finish (global::PulseAudio.Context in_context, bool in_success) {
            debug (@"finish unload module $(index)");
            if (callback != null) {
                callback (in_success);
            }
            finish ();
        }
    }

    private Operation? head;
    private unowned Operation? tail;
    private global::PulseAudio.Context context;

    public Operations (global::PulseAudio.Context in_context) {
        context = in_context;
    }

    ~Operations () {
        cancel_all ();
    }

    public void cancel_all () {
        while (head != null) {
            head.cancel ();
        }
        tail = null;
    }

    public void subscribe (global::PulseAudio.Context.SubscriptionMask in_mask,
                           owned Subscribe.Callback? in_callback = null) {
        push (new Subscribe (context, in_mask, (owned)in_callback));
    }

    public void get_server_info (owned GetServerInfo.Callback? in_callback) {
        push (new GetServerInfo (context, (owned)in_callback));
    }

    public void get_card_info_list (owned GetCardInfoList.Callback? in_callback) {
        push (new GetCardInfoList (context, (owned)in_callback));
    }

    public void get_card_info_by_index (uint32 in_index, owned GetCardInfoByIndex.Callback? in_callback) {
        push (new GetCardInfoByIndex (context, in_index, (owned)in_callback));
    }

    public void set_card_profile_by_index (uint32 in_index,
                                           string in_name,
                                           owned SetCardProfileByIndex.Callback? in_callback = null) {
        push (new SetCardProfileByIndex (context, in_index, in_name, (owned)in_callback));
    }

    public void get_sink_info_list (owned GetSinkInfoList.Callback? in_callback) {
        push (new GetSinkInfoList (context, (owned)in_callback));
    }

    public void get_sink_info_by_index (uint32 in_index, owned GetSinkInfoByIndex.Callback? in_callback) {
        push (new GetSinkInfoByIndex (context, in_index, (owned)in_callback));
    }

    public void get_source_info_list (owned GetSourceInfoList.Callback? in_callback) {
        push (new GetSourceInfoList (context, (owned)in_callback));
    }

    public void get_source_info_by_index (uint32 in_index, owned GetSourceInfoByIndex.Callback? in_callback) {
        push (new GetSourceInfoByIndex (context, in_index, (owned)in_callback));
    }

    public void set_default_source (string in_channel_name, owned SetDefaultSource.Callback? in_callback = null) {
        push (new SetDefaultSource (context, in_channel_name, (owned)in_callback));
    }

    public void set_default_sink (string in_channel_name, owned SetDefaultSink.Callback? in_callback = null) {
        push (new SetDefaultSink (context, in_channel_name, (owned)in_callback));
    }

    public void set_source_port_by_index (uint32 in_index,
                                          string in_port_name,
                                          owned SetSourcePortByIndex.Callback? in_callback = null) {
        push (new SetSourcePortByIndex (context, in_index, in_port_name, (owned)in_callback));
    }

    public void set_sink_port_by_index (uint32 in_index,
                                        string in_port_name,
                                        owned SetSinkPortByIndex.Callback? in_callback = null) {
        push (new SetSinkPortByIndex (context, in_index, in_port_name, (owned)in_callback));
    }

    public void set_source_volume_by_index (uint32 in_index,
                                            global::PulseAudio.CVolume in_volume,
                                            owned SetSourceVolumeByIndex.Callback? in_callback = null) {
        push (new SetSourceVolumeByIndex (context, in_index, in_volume, (owned)in_callback));
    }

    public void set_sink_volume_by_index (uint32 in_index,
                                          global::PulseAudio.CVolume in_volume,
                                          owned SetSinkVolumeByIndex.Callback? in_callback = null) {
        push (new SetSinkVolumeByIndex (context, in_index, in_volume, (owned)in_callback));
    }

    public void set_source_mute_by_index (uint32 in_index,
                                         bool in_mute,
                                         owned SetSourceMuteByIndex.Callback? in_callback = null) {
        push (new SetSourceMuteByIndex (context, in_index, in_mute, (owned)in_callback));
    }

    public void set_sink_mute_by_index (uint32 in_index,
                                        bool in_mute,
                                        owned SetSinkMuteByIndex.Callback? in_callback = null) {
        push (new SetSinkMuteByIndex (context, in_index, in_mute, (owned)in_callback));
    }

    public global::PulseAudio.Stream create_stream (string in_name,
                                                    global::PulseAudio.SampleSpec in_sample_spec,
                                                    global::PulseAudio.ChannelMap? in_channel_map = null,
                                                    global::PulseAudio.Proplist? in_proplist = null) {
        return new global::PulseAudio.Stream (context, in_name, in_sample_spec, in_channel_map, in_proplist);
    }

    public void get_client_info_list (owned GetClientInfoList.Callback? in_callback) {
        push (new GetClientInfoList (context, (owned)in_callback));
    }

    public void get_client_info (uint32 in_index, owned GetClientInfo.Callback? in_callback) {
        push (new GetClientInfo (context, in_index, (owned)in_callback));
    }

    public void set_source_output_volume (uint32 in_index,
                                          global::PulseAudio.CVolume in_volume,
                                          owned SetSourceOutputVolume.Callback? in_callback = null) {
        push (new SetSourceOutputVolume (context, in_index, in_volume, (owned)in_callback));
    }

    public void set_sink_input_volume (uint32 in_index,
                                       global::PulseAudio.CVolume in_volume,
                                       owned SetSinkInputVolume.Callback? in_callback = null) {
        push (new SetSinkInputVolume (context, in_index, in_volume, (owned)in_callback));
    }

    public void set_source_output_mute (uint32 in_index,
                                        bool in_mute,
                                        owned SetSourceOutputMute.Callback? in_callback = null) {
        push (new SetSourceOutputMute (context, in_index, in_mute, (owned)in_callback));
    }

    public void set_sink_input_mute (uint32 in_index,
                                     bool in_mute,
                                     owned SetSinkInputMute.Callback? in_callback = null) {
        push (new SetSinkInputMute (context, in_index, in_mute, (owned)in_callback));
    }

    public void move_source_output_by_index (uint32 in_index,
                                             uint32 in_source,
                                             owned MoveSourceOutputByIndex.Callback? in_callback = null) {
        push (new MoveSourceOutputByIndex (context, in_index, in_source, (owned)in_callback));
    }

    public void move_sink_input_by_index (uint32 in_index,
                                          uint32 in_sink,
                                          owned MoveSinkInputByIndex.Callback? in_callback = null) {
        push (new MoveSinkInputByIndex (context, in_index, in_sink, (owned)in_callback));
    }

    public void get_source_output_info_list (owned GetSourceOutputInfoList.Callback? in_callback) {
        push (new GetSourceOutputInfoList (context, (owned)in_callback));
    }

    public void get_source_output_info (uint32 in_index, owned GetSourceOutputInfo.Callback? in_callback) {
        push (new GetSourceOutputInfo (context, in_index, (owned)in_callback));
    }

    public void get_sink_input_info_list (owned GetSinkInputInfoList.Callback? in_callback) {
        push (new GetSinkInputInfoList (context, (owned)in_callback));
    }

    public void get_sink_input_info (uint32 in_index, owned GetSinkInputInfo.Callback? in_callback) {
        push (new GetSinkInputInfo (context, in_index, (owned)in_callback));
    }

    public void load_module (string in_name, string? in_args, owned LoadModule.Callback? in_callback) {
        push (new LoadModule (context, in_name, in_args, (owned)in_callback));
    }

    public void unload_module (uint32 in_index, owned UnloadModule.Callback? in_callback) {
        push (new UnloadModule (context, in_index, (owned)in_callback));
    }

    private void push (Operation in_operation) {
        for (unowned Operation item = tail; item != null; item = item.prev) {
            if (in_operation.compare (item)) {
                item.cancel ();
                break;
            }
        }

        if (head == null) {
            head = in_operation;
            in_operation.prev = null;
            in_operation.next = null;
            in_operation.parent = this;
            tail = head;
        } else {
            unowned Operation? prev = tail;
            tail = in_operation;
            in_operation.prev = prev;
            in_operation.next = prev.next;
            if (in_operation.next != null) {
                in_operation.next.prev = in_operation;
            }
            prev.next = in_operation;
            in_operation.parent = this;
        }
    }
}
