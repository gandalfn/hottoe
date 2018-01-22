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

internal class PantheonSoundControl.PulseAudio.Operations : GLib.Object {
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
            unref();
        }

        public abstract bool compare (Operation inOther);
    }

    public class Subscribe : Operation {
        public delegate void Callback (bool inSuccess);

        public Callback? callback;

        public Subscribe (global::PulseAudio.Context inContext, global::PulseAudio.Context.SubscriptionMask inMask, owned Callback? inCallback) {
            debug (@"new subscribe operation");
            callback = (owned)inCallback;
            operation = inContext.subscribe (inMask, on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is Subscribe;
        }

        private void on_finish (global::PulseAudio.Context inContext, bool inSuccess) {
            debug (@"finish subscribe");
            if (callback != null) {
                callback (inSuccess);
            }

            finish ();
        }
    }

    public class GetServerInfo : Operation {
        public delegate void Callback (global::PulseAudio.ServerInfo? inInfo);

        public Callback? callback;

        public GetServerInfo (global::PulseAudio.Context inContext, owned Callback? inCallback) {
            debug (@"new get server info operation");
            callback = (owned)inCallback;
            operation = inContext.get_server_info (on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is GetServerInfo;
        }

        private void on_finish (global::PulseAudio.Context inContext, global::PulseAudio.ServerInfo? inInfo) {
            if (inInfo != null) {
                debug (@"finish get server info");
                if (callback != null) {
                    callback (inInfo);
                }
                finish ();
            }
        }
    }

    public class GetCardInfoList : Operation {
        public delegate void Callback (global::PulseAudio.CardInfo? inInfo);

        public Callback? callback;

        public GetCardInfoList (global::PulseAudio.Context inContext, owned Callback? inCallback) {
            debug (@"new card info list operation");
            callback = (owned)inCallback;
            operation = inContext.get_card_info_list (on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is GetCardInfoList;
        }

        private void on_finish (global::PulseAudio.Context inContext, global::PulseAudio.CardInfo? inInfo) {
            if (inInfo != null) {
                debug (@"finish card info list");
                if (callback != null) {
                    callback (inInfo);
                }
            } else {
                debug (@"finish and destroy card info list");
                finish ();
            }
        }
    }

    public class GetCardInfoByIndex : Operation {
        public delegate void Callback (global::PulseAudio.CardInfo? inInfo);

        public uint32 index;
        public Callback? callback;

        public GetCardInfoByIndex (global::PulseAudio.Context inContext, uint32 inIndex, owned Callback? inCallback) {
            debug (@"new card info by index $(inIndex) operation");
            index = inIndex;
            callback = (owned)inCallback;
            operation = inContext.get_card_info_by_index (index, on_finish);
        }

        public override bool compare (Operation inOther) {
            bool ret = inOther is GetCardInfoByIndex;
            if (ret) {
                ret = (index == ((GetCardInfoByIndex) inOther).index);
            }
            return ret;
        }

        private void on_finish (global::PulseAudio.Context inContext, global::PulseAudio.CardInfo? inInfo) {
            if (inInfo != null) {
                debug (@"finish card info by index $(index)");
                if (callback != null) {
                    callback (inInfo);
                }
            } else {
                debug (@"finish and destroy card info by index $(index)");
                finish ();
            }
        }
    }

    public class GetSinkInfoList : Operation {
        public delegate void Callback (global::PulseAudio.SinkInfo? inInfo);

        public Callback? callback;

        public GetSinkInfoList (global::PulseAudio.Context inContext, owned Callback? inCallback) {
            debug (@"new get sink info list operation");
            callback = (owned)inCallback;
            operation = inContext.get_sink_info_list (on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is GetSinkInfoList;
        }

        private void on_finish (global::PulseAudio.Context inContext, global::PulseAudio.SinkInfo? inInfo) {
            if (inInfo != null) {
                debug (@"finish get sink info list");
                if (callback != null) {
                    callback (inInfo);
                }
            } else {
                debug (@"finish and destroy get sink info list");
                finish ();
            }
        }
    }

    public class GetSinkInfoByIndex : Operation {
        public delegate void Callback (global::PulseAudio.SinkInfo? inInfo);

        public uint32 index;
        public Callback? callback;

        public GetSinkInfoByIndex (global::PulseAudio.Context inContext, uint32 inIndex, owned Callback? inCallback) {
            debug (@"new get sink info by index $(inIndex) operation");
            index = inIndex;
            callback = (owned)inCallback;
            operation = inContext.get_sink_info_by_index (index, on_finish);
        }

        public override bool compare (Operation inOther) {
            bool ret = inOther is GetSinkInfoByIndex;
            if (ret) {
                ret = (index == ((GetSinkInfoByIndex) inOther).index);
            }
            return ret;
        }

        private void on_finish (global::PulseAudio.Context inContext, global::PulseAudio.SinkInfo? inInfo) {
            if (inInfo != null) {
                debug (@"finish sink info by index $(index)");
                if (callback != null) {
                    callback (inInfo);
                }
            } else {
                debug (@"finish and destroy sink info by index $(index)");
                finish ();
            }
        }
    }

    public class GetSourceInfoList : Operation {
        public delegate void Callback (global::PulseAudio.SourceInfo? inInfo);

        public Callback? callback;

        public GetSourceInfoList (global::PulseAudio.Context inContext, owned Callback? inCallback) {
            debug (@"new get source info list operation");
            callback = (owned)inCallback;
            operation = inContext.get_source_info_list (on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is GetSourceInfoList;
        }

        private void on_finish (global::PulseAudio.Context inContext, global::PulseAudio.SourceInfo? inInfo) {
            if (inInfo != null) {
                debug (@"finish source info list");
                if (callback != null) {
                    callback (inInfo);
                }
            } else {
                debug (@"finish and destroy source info list");
                finish ();
            }
        }
    }

    public class GetSourceInfoByIndex : Operation {
        public delegate void Callback (global::PulseAudio.SourceInfo? inInfo);

        public uint32 index;
        public Callback? callback;

        public GetSourceInfoByIndex (global::PulseAudio.Context inContext, uint32 inIndex, owned Callback? inCallback) {
            debug (@"new get source info by index $(inIndex) operation");
            index = inIndex;
            callback = (owned)inCallback;
            operation = inContext.get_source_info_by_index (index, on_finish);
        }

        public override bool compare (Operation inOther) {
            bool ret = inOther is GetSourceInfoByIndex;
            if (ret) {
                ret = (index == ((GetSourceInfoByIndex) inOther).index);
            }
            return ret;
        }

        private void on_finish (global::PulseAudio.Context inContext, global::PulseAudio.SourceInfo? inInfo) {
            if (inInfo != null) {
                debug (@"finish source info by index $(index)");
                if (callback != null) {
                    callback (inInfo);
                }
            } else {
                debug (@"finish and destroy source info by index $(index)");
                finish ();
            }
        }
    }

    public class SetCardProfileByIndex : Operation {
        public delegate void Callback (bool inSuccess);

        public uint32 index;
        public string profile_name;
        public Callback? callback;

        public SetCardProfileByIndex (global::PulseAudio.Context inContext, uint32 inIndex, string inProfileName, owned Callback? inCallback) {
            debug (@"new set card profile by index $(inIndex) operation");
            index = inIndex;
            profile_name = inProfileName;
            callback = (owned)inCallback;
            operation = inContext.set_card_profile_by_index (inIndex, inProfileName, on_finish);
        }

        public override bool compare (Operation inOther) {
            bool ret = false;

            if (inOther is SetCardProfileByIndex) {
                ret = ((SetCardProfileByIndex)inOther).index == index;
            }

            return ret;
        }

        private void on_finish (global::PulseAudio.Context inContext, bool inSuccess) {
            debug (@"finish set profile by index $(index)");
            if (callback != null) {
                callback (inSuccess);
            }
            finish ();
        }
    }

    public class SetDefaultSource : Operation {
        public delegate void Callback (bool inSuccess);

        public string channel_name;
        public Callback? callback;

        public SetDefaultSource (global::PulseAudio.Context inContext, string inChannelName, owned Callback? inCallback) {
            debug (@"new set default source $(inChannelName) operation");
            channel_name = inChannelName;
            callback = (owned)inCallback;
            operation = inContext.set_default_source (channel_name, on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is SetDefaultSource;
        }

        private void on_finish (global::PulseAudio.Context inContext, bool inSuccess) {
            debug (@"finish set default source $(channel_name)");
            if (callback != null) {
                callback (inSuccess);
            }
            finish ();
        }
    }

    public class SetDefaultSink : Operation {
        public delegate void Callback (bool inSuccess);

        public string channel_name;
        public Callback? callback;

        public SetDefaultSink (global::PulseAudio.Context inContext, string inChannelName, owned Callback? inCallback) {
            debug (@"new set default sink $(inChannelName) operation");
            channel_name = inChannelName;
            callback = (owned)inCallback;
            operation = inContext.set_default_sink (channel_name, on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is SetDefaultSink;
        }

        private void on_finish (global::PulseAudio.Context inContext, bool inSuccess) {
            debug (@"finish set default sink $(channel_name)");
            if (callback != null) {
                callback (inSuccess);
            }
            finish ();
        }
    }

    public class SetSourcePortByIndex : Operation {
        public delegate void Callback (bool inSuccess);

        public uint32 index;
        public string port_name;
        public Callback? callback;

        public SetSourcePortByIndex (global::PulseAudio.Context inContext, uint32 inIndex, string inPortName, owned Callback? inCallback) {
            debug (@"new set source port by index $(index) port $(inPortName) operation");
            index = inIndex;
            port_name = inPortName;
            callback = (owned)inCallback;
            operation = inContext.set_source_port_by_index (index, port_name, on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is SetSourcePortByIndex;
        }

        private void on_finish (global::PulseAudio.Context inContext, bool inSuccess) {
            debug (@"finish set source port by index $(index) port $(port_name)");
            if (callback != null) {
                callback (inSuccess);
            }
            finish ();
        }
    }

    public class SetSinkPortByIndex : Operation {
        public delegate void Callback (bool inSuccess);

        public uint32 index;
        public string port_name;
        public Callback? callback;

        public SetSinkPortByIndex (global::PulseAudio.Context inContext, uint32 inIndex, string inPortName, owned Callback? inCallback) {
            debug (@"new set sink port by index $(index) port $(inPortName) operation");
            index = inIndex;
            port_name = inPortName;
            callback = (owned)inCallback;
            operation = inContext.set_sink_port_by_index (index, port_name, on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is SetSinkPortByIndex;
        }

        private void on_finish (global::PulseAudio.Context inContext, bool inSuccess) {
            debug (@"finish set sink port by index $(index) port $(port_name)");
            if (callback != null) {
                callback (inSuccess);
            }
            finish ();
        }
    }

    public class SetSourceVolumeByIndex : Operation {
        public delegate void Callback (bool inSuccess);

        public uint32 index;
        public global::PulseAudio.CVolume volume;
        public Callback? callback;

        public SetSourceVolumeByIndex (global::PulseAudio.Context inContext, uint32 inIndex, global::PulseAudio.CVolume inVolume, owned Callback? inCallback) {
            debug (@"new set source volume by index $(index) operation");
            index = inIndex;
            volume = inVolume;
            callback = (owned)inCallback;
            operation = inContext.set_source_volume_by_index (index, volume, on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is SetSourceVolumeByIndex;
        }

        private void on_finish (global::PulseAudio.Context inContext, bool inSuccess) {
            debug (@"finish set source volume index $(index)");
            if (callback != null) {
                callback (inSuccess);
            }
            finish ();
        }
    }

    public class SetSinkVolumeByIndex : Operation {
        public delegate void Callback (bool inSuccess);

        public uint32 index;
        public global::PulseAudio.CVolume volume;
        public Callback? callback;

        public SetSinkVolumeByIndex (global::PulseAudio.Context inContext, uint32 inIndex, global::PulseAudio.CVolume inVolume, owned Callback? inCallback) {
            debug (@"new set sink volume by index $(index) operation");
            index = inIndex;
            volume = inVolume;
            callback = (owned)inCallback;
            operation = inContext.set_sink_volume_by_index (index, volume, on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is SetSinkVolumeByIndex;
        }

        private void on_finish (global::PulseAudio.Context inContext, bool inSuccess) {
            debug (@"finish set sink volume index $(index)");
            if (callback != null) {
                callback (inSuccess);
            }
            finish ();
        }
    }

    public class SetSourceMuteByIndex : Operation {
        public delegate void Callback (bool inSuccess);

        public uint32 index;
        public bool mute;
        public Callback? callback;

        public SetSourceMuteByIndex (global::PulseAudio.Context inContext, uint32 inIndex, bool inMute, owned Callback? inCallback) {
            debug (@"new set source mute by index $(index) operation");
            index = inIndex;
            mute = inMute;
            callback = (owned)inCallback;
            operation = inContext.set_source_mute_by_index (index, mute, on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is SetSourceMuteByIndex;
        }

        private void on_finish (global::PulseAudio.Context inContext, bool inSuccess) {
            debug (@"finish set source mute index $(index)");
            if (callback != null) {
                callback (inSuccess);
            }
            finish ();
        }
    }

    public class SetSinkMuteByIndex : Operation {
        public delegate void Callback (bool inSuccess);

        public uint32 index;
        public bool mute;
        public Callback? callback;

        public SetSinkMuteByIndex (global::PulseAudio.Context inContext, uint32 inIndex, bool inMute, owned Callback? inCallback) {
            debug (@"new set sink mute by index $(index) operation");
            index = inIndex;
            mute = inMute;
            callback = (owned)inCallback;
            operation = inContext.set_sink_mute_by_index (index, mute, on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is SetSinkMuteByIndex;
        }

        private void on_finish (global::PulseAudio.Context inContext, bool inSuccess) {
            debug (@"finish set sink mute index $(index)");
            if (callback != null) {
                callback (inSuccess);
            }
            finish ();
        }
    }

    public class GetClientInfoList : Operation {
        public delegate void Callback (global::PulseAudio.ClientInfo? inInfo);

        public Callback? callback;

        public GetClientInfoList (global::PulseAudio.Context inContext, owned Callback? inCallback) {
            debug (@"new get client info list operation");
            callback = (owned)inCallback;
            operation = inContext.get_client_info_list (on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is GetClientInfoList;
        }

        private void on_finish (global::PulseAudio.Context inContext, global::PulseAudio.ClientInfo? inInfo) {
            if (inInfo != null) {
                debug (@"finish client info list");
                if (callback != null) {
                    callback (inInfo);
                }
            } else {
                debug (@"finish and destroy client info list");
                finish ();
            }
        }
    }

    public class GetClientInfo : Operation {
        public delegate void Callback (global::PulseAudio.ClientInfo? inInfo);

        public uint32 index;
        public Callback? callback;

        public GetClientInfo (global::PulseAudio.Context inContext, uint32 inIndex, owned Callback? inCallback) {
            debug (@"new get client info by index $(inIndex) operation");
            index = inIndex;
            callback = (owned)inCallback;
            operation = inContext.get_client_info (index, on_finish);
        }

        public override bool compare (Operation inOther) {
            bool ret = inOther is GetClientInfo;
            if (ret) {
                ret = (index == ((GetClientInfo) inOther).index);
            }
            return ret;
        }

        private void on_finish (global::PulseAudio.Context inContext, global::PulseAudio.ClientInfo? inInfo) {
            if (inInfo != null) {
                debug (@"finish client info $(index)");
                if (callback != null) {
                    callback (inInfo);
                }
            } else {
                debug (@"finish and destroy client info $(index)");
                finish ();
            }
        }
    }

    public class SetSourceOutputVolume : Operation {
        public delegate void Callback (bool inSuccess);

        public uint32 index;
        public global::PulseAudio.CVolume volume;
        public Callback? callback;

        public SetSourceOutputVolume (global::PulseAudio.Context inContext, uint32 inIndex, global::PulseAudio.CVolume inVolume, owned Callback? inCallback) {
            debug (@"new set source output volume $(index) operation");
            index = inIndex;
            volume = inVolume;
            callback = (owned)inCallback;
            operation = inContext.set_source_output_volume(index, volume, on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is SetSourceOutputVolume;
        }

        private void on_finish (global::PulseAudio.Context inContext, bool inSuccess) {
            debug (@"finish set source output volume $(index)");
            if (callback != null) {
                callback (inSuccess);
            }
            finish ();
        }
    }

    public class SetSinkInputVolume : Operation {
        public delegate void Callback (bool inSuccess);

        public uint32 index;
        public global::PulseAudio.CVolume volume;
        public Callback? callback;

        public SetSinkInputVolume (global::PulseAudio.Context inContext, uint32 inIndex, global::PulseAudio.CVolume inVolume, owned Callback? inCallback) {
            debug (@"new set sink input volume $(index) operation");
            index = inIndex;
            volume = inVolume;
            callback = (owned)inCallback;
            operation = inContext.set_sink_input_volume(index, volume, on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is SetSinkInputVolume;
        }

        private void on_finish (global::PulseAudio.Context inContext, bool inSuccess) {
            debug (@"finish set sink input volume $(index)");
            if (callback != null) {
                callback (inSuccess);
            }
            finish ();
        }
    }

    public class SetSourceOutputMute : Operation {
        public delegate void Callback (bool inSuccess);

        public uint32 index;
        public bool mute;
        public Callback? callback;

        public SetSourceOutputMute (global::PulseAudio.Context inContext, uint32 inIndex, bool inMute, owned Callback? inCallback) {
            debug (@"new set source output mute $(index) operation");
            index = inIndex;
            mute = inMute;
            callback = (owned)inCallback;
            operation = inContext.set_source_output_mute (index, mute, on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is SetSourceOutputMute;
        }

        private void on_finish (global::PulseAudio.Context inContext, bool inSuccess) {
            debug (@"finish set source output mute $(index)");
            if (callback != null) {
                callback (inSuccess);
            }
            finish ();
        }
    }

    public class SetSinkInputMute : Operation {
        public delegate void Callback (bool inSuccess);

        public uint32 index;
        public bool mute;
        public Callback? callback;

        public SetSinkInputMute (global::PulseAudio.Context inContext, uint32 inIndex, bool inMute, owned Callback? inCallback) {
            debug (@"new set sink input mute $(index) operation");
            index = inIndex;
            mute = inMute;
            callback = (owned)inCallback;
            operation = inContext.set_sink_input_mute (index, mute, on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is SetSinkInputMute;
        }

        private void on_finish (global::PulseAudio.Context inContext, bool inSuccess) {
            debug (@"finish set sink input mute $(index)");
            if (callback != null) {
                callback (inSuccess);
            }
            finish ();
        }
    }

    public class MoveSourceOutputByIndex : Operation {
        public delegate void Callback (bool inSuccess);

        public uint32 index;
        public uint32 source;
        public Callback? callback;

        public MoveSourceOutputByIndex (global::PulseAudio.Context inContext, uint32 inIndex, uint32 inSource, owned Callback? inCallback) {
            debug (@"new move source output $(index) operation");
            index = inIndex;
            source = inSource;
            callback = (owned)inCallback;
            operation = inContext.move_source_output_by_index (index, source, on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is MoveSourceOutputByIndex;
        }

        private void on_finish (global::PulseAudio.Context inContext, bool inSuccess) {
            debug (@"finish set source output $(index)");
            if (callback != null) {
                callback (inSuccess);
            }
            finish ();
        }
    }

    public class MoveSinkInputByIndex : Operation {
        public delegate void Callback (bool inSuccess);

        public uint32 index;
        public uint32 sink;
        public Callback? callback;

        public MoveSinkInputByIndex (global::PulseAudio.Context inContext, uint32 inIndex, uint32 inSink, owned Callback? inCallback) {
            debug (@"new move sink input $(index) operation");
            index = inIndex;
            sink = inSink;
            callback = (owned)inCallback;
            operation = inContext.move_sink_input_by_index (index, sink, on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is MoveSinkInputByIndex;
        }

        private void on_finish (global::PulseAudio.Context inContext, bool inSuccess) {
            debug (@"finish move sink input $(index)");
            if (callback != null) {
                callback (inSuccess);
            }
            finish ();
        }
    }

    public class GetSourceOutputInfoList : Operation {
        public delegate void Callback (global::PulseAudio.SourceOutputInfo? inInfo);

        public Callback? callback;

        public GetSourceOutputInfoList (global::PulseAudio.Context inContext, owned Callback? inCallback) {
            debug (@"new get source output info list operation");
            callback = (owned)inCallback;
            operation = inContext.get_source_output_info_list (on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is GetSourceOutputInfoList;
        }

        private void on_finish (global::PulseAudio.Context inContext, global::PulseAudio.SourceOutputInfo? inInfo) {
            if (inInfo != null) {
                debug (@"finish source output info list");
                if (callback != null) {
                    callback (inInfo);
                }
            } else {
                debug (@"finish and destroy source output info list");
                finish ();
            }
        }
    }

    public class GetSinkInputInfoList : Operation {
        public delegate void Callback (global::PulseAudio.SinkInputInfo? inInfo);

        public Callback? callback;

        public GetSinkInputInfoList (global::PulseAudio.Context inContext, owned Callback? inCallback) {
            debug (@"new get sink input info list operation");
            callback = (owned)inCallback;
            operation = inContext.get_sink_input_info_list (on_finish);
        }

        public override bool compare (Operation inOther) {
            return inOther is GetSinkInputInfoList;
        }

        private void on_finish (global::PulseAudio.Context inContext, global::PulseAudio.SinkInputInfo? inInfo) {
            if (inInfo != null) {
                debug (@"finish sink input info list");
                if (callback != null) {
                    callback (inInfo);
                }
            } else {
                debug (@"finish and destroy sink input info list");
                finish ();
            }
        }
    }

    public class GetSourceOutputInfo : Operation {
        public delegate void Callback (global::PulseAudio.SourceOutputInfo? inInfo);

        public uint32 index;
        public Callback? callback;

        public GetSourceOutputInfo (global::PulseAudio.Context inContext, uint32 inIndex, owned Callback? inCallback) {
            debug (@"new get source output info by index $(inIndex) operation");
            index = inIndex;
            callback = (owned)inCallback;
            operation = inContext.get_source_output_info (index, on_finish);
        }

        public override bool compare (Operation inOther) {
            bool ret = inOther is GetSourceOutputInfo;
            if (ret) {
                ret = (index == ((GetSourceOutputInfo) inOther).index);
            }
            return ret;
        }

        private void on_finish (global::PulseAudio.Context inContext, global::PulseAudio.SourceOutputInfo? inInfo) {
            if (inInfo != null) {
                debug (@"finish source output info $(index)");
                if (callback != null) {
                    callback (inInfo);
                }
            } else {
                debug (@"finish and destroy source output info $(index)");
                finish ();
            }
        }
    }

    public class GetSinkInputInfo : Operation {
        public delegate void Callback (global::PulseAudio.SinkInputInfo? inInfo);

        public uint32 index;
        public Callback? callback;

        public GetSinkInputInfo (global::PulseAudio.Context inContext, uint32 inIndex, owned Callback? inCallback) {
            debug (@"new get sink input info by index $(inIndex) operation");
            index = inIndex;
            callback = (owned)inCallback;
            operation = inContext.get_sink_input_info (index, on_finish);
        }

        public override bool compare (Operation inOther) {
            bool ret = inOther is GetSinkInputInfo;
            if (ret) {
                ret = (index == ((GetSinkInputInfo) inOther).index);
            }
            return ret;
        }

        private void on_finish (global::PulseAudio.Context inContext, global::PulseAudio.SinkInputInfo? inInfo) {
            if (inInfo != null) {
                debug (@"finish sink input info $(index)");
                if (callback != null) {
                    callback (inInfo);
                }
            } else {
                debug (@"finish and destroy sink input info $(index)");
                finish ();
            }
        }
    }

    private Operation? head;
    private unowned Operation? tail;
    private global::PulseAudio.Context context;

    public Operations (global::PulseAudio.Context inContext) {
        context = inContext;
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

    public void subscribe (global::PulseAudio.Context.SubscriptionMask inMask, owned Subscribe.Callback? inCallback = null) {
        push (new Subscribe (context, inMask, (owned)inCallback));
    }

    public void get_server_info (owned GetServerInfo.Callback? inCallback) {
        push (new GetServerInfo (context, (owned)inCallback));
    }

    public void get_card_info_list (owned GetCardInfoList.Callback? inCallback) {
        push (new GetCardInfoList (context, (owned)inCallback));
    }

    public void get_card_info_by_index (uint32 inIndex, owned GetCardInfoByIndex.Callback? inCallback) {
        push (new GetCardInfoByIndex (context, inIndex, (owned)inCallback));
    }

    public void set_card_profile_by_index (uint32 inIndex, string inName, owned SetCardProfileByIndex.Callback? inCallback = null) {
        push (new SetCardProfileByIndex (context, inIndex, inName, (owned)inCallback));
    }

    public void get_sink_info_list (owned GetSinkInfoList.Callback? inCallback) {
        push (new GetSinkInfoList (context, (owned)inCallback));
    }

    public void get_sink_info_by_index (uint32 inIndex, owned GetSinkInfoByIndex.Callback? inCallback) {
        push (new GetSinkInfoByIndex (context, inIndex, (owned)inCallback));
    }

    public void get_source_info_list (owned GetSourceInfoList.Callback? inCallback) {
        push (new GetSourceInfoList (context, (owned)inCallback));
    }

    public void get_source_info_by_index (uint32 inIndex, owned GetSourceInfoByIndex.Callback? inCallback) {
        push (new GetSourceInfoByIndex (context, inIndex, (owned)inCallback));
    }

    public void set_default_source (string inChannelName, owned SetDefaultSource.Callback? inCallback = null) {
        push (new SetDefaultSource (context, inChannelName, (owned)inCallback));
    }

    public void set_default_sink (string inChannelName, owned SetDefaultSink.Callback? inCallback = null) {
        push (new SetDefaultSink (context, inChannelName, (owned)inCallback));
    }

    public void set_source_port_by_index (uint32 inIndex, string inPortName, owned SetSourcePortByIndex.Callback? inCallback = null) {
        push (new SetSourcePortByIndex (context, inIndex, inPortName, (owned)inCallback));
    }

    public void set_sink_port_by_index (uint32 inIndex, string inPortName, owned SetSinkPortByIndex.Callback? inCallback = null) {
        push (new SetSinkPortByIndex (context, inIndex, inPortName, (owned)inCallback));
    }

    public void set_source_volume_by_index (uint32 inIndex, global::PulseAudio.CVolume inVolume, owned SetSourceVolumeByIndex.Callback? inCallback = null) {
        push (new SetSourceVolumeByIndex (context, inIndex, inVolume, (owned)inCallback));
    }

    public void set_sink_volume_by_index (uint32 inIndex, global::PulseAudio.CVolume inVolume, owned SetSinkVolumeByIndex.Callback? inCallback = null) {
        push (new SetSinkVolumeByIndex (context, inIndex, inVolume, (owned)inCallback));
    }

    public void set_source_mute_by_index (uint32 inIndex, bool inMute, owned SetSourceMuteByIndex.Callback? inCallback = null) {
        push (new SetSourceMuteByIndex (context, inIndex, inMute, (owned)inCallback));
    }

    public void set_sink_mute_by_index (uint32 inIndex, bool inMute, owned SetSinkMuteByIndex.Callback? inCallback = null) {
        push (new SetSinkMuteByIndex (context, inIndex, inMute, (owned)inCallback));
    }

    public global::PulseAudio.Stream create_stream (string inName, global::PulseAudio.SampleSpec inSampleSpec, global::PulseAudio.ChannelMap? inChannelMap = null, global::PulseAudio.Proplist? inProplist = null) {
        return new global::PulseAudio.Stream (context, inName, inSampleSpec, inChannelMap, inProplist);
    }

    public void get_client_info_list (owned GetClientInfoList.Callback? inCallback) {
        push (new GetClientInfoList (context, (owned)inCallback));
    }

    public void get_client_info (uint32 inIndex, owned GetClientInfo.Callback? inCallback) {
        push (new GetClientInfo (context, inIndex, (owned)inCallback));
    }

    public void set_source_output_volume (uint32 inIndex, global::PulseAudio.CVolume inVolume, owned SetSourceOutputVolume.Callback? inCallback = null) {
        push (new SetSourceOutputVolume (context, inIndex, inVolume, (owned)inCallback));
    }

    public void set_sink_input_volume (uint32 inIndex, global::PulseAudio.CVolume inVolume, owned SetSinkInputVolume.Callback? inCallback = null) {
        push (new SetSinkInputVolume (context, inIndex, inVolume, (owned)inCallback));
    }

    public void set_source_output_mute (uint32 inIndex, bool inMute, owned SetSourceOutputMute.Callback? inCallback = null) {
        push (new SetSourceOutputMute (context, inIndex, inMute, (owned)inCallback));
    }

    public void set_sink_input_mute (uint32 inIndex, bool inMute, owned SetSinkInputMute.Callback? inCallback = null) {
        push (new SetSinkInputMute (context, inIndex, inMute, (owned)inCallback));
    }

    public void move_source_output_by_index (uint32 inIndex, uint32 inSource, owned MoveSourceOutputByIndex.Callback? inCallback = null) {
        push (new MoveSourceOutputByIndex (context, inIndex, inSource, (owned)inCallback));
    }

    public void move_sink_input_by_index (uint32 inIndex, uint32 inSink, owned MoveSinkInputByIndex.Callback? inCallback = null) {
        push (new MoveSinkInputByIndex (context, inIndex, inSink, (owned)inCallback));
    }

    public void get_source_output_info_list (owned GetSourceOutputInfoList.Callback? inCallback) {
        push (new GetSourceOutputInfoList (context, (owned)inCallback));
    }

    public void get_source_output_info (uint32 inIndex, owned GetSourceOutputInfo.Callback? inCallback) {
        push (new GetSourceOutputInfo (context, inIndex, (owned)inCallback));
    }

    public void get_sink_input_info_list (owned GetSinkInputInfoList.Callback? inCallback) {
        push (new GetSinkInputInfoList (context, (owned)inCallback));
    }

    public void get_sink_input_info (uint32 inIndex, owned GetSinkInputInfo.Callback? inCallback) {
        push (new GetSinkInputInfo (context, inIndex, (owned)inCallback));
    }

    private void push (Operation inOperation) {
        for (unowned Operation item = tail; item != null; item = item.prev) {
            if (inOperation.compare (item)) {
                item.cancel ();
                break;
            }
        }

        if (head == null) {
            head = inOperation;
            inOperation.prev = null;
            inOperation.next = null;
            inOperation.parent = this;
            tail = head;
        } else {
            unowned Operation? prev = tail;
            tail = inOperation;
            inOperation.prev = prev;
            inOperation.next = prev.next;
            if (inOperation.next != null) {
                inOperation.next.prev = inOperation;
            }
            prev.next = inOperation;
            inOperation.parent = this;
        }
    }
}
