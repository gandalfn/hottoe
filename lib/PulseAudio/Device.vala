/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * Device.vala
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

internal class PantheonSoundControl.PulseAudio.Device : PantheonSoundControl.Device {
    private Gee.TreeSet<Port> m_Ports;
    private Gee.ArrayList<Profile> m_Profiles;
    private unowned Profile? m_ActiveProfile;

    public uint32 index { get; construct; default = 0U; }

    public override bool active {
        get {
            return m_Ports.size > 0;
        }
    }

    public override unowned PantheonSoundControl.Profile? active_profile {
        get {
            return m_ActiveProfile;
        }
        set {
            if (value != m_ActiveProfile) {
                if (m_ActiveProfile != null) {
                    m_ActiveProfile.weak_unref (on_active_profile_destroyed);
                }

                if (value != null) {
                    if (get_profile (value.name) != null) {
                        debug ("%s set default profile %s", name, value.name);

                        m_ActiveProfile = (Profile?)value;
                        m_ActiveProfile.weak_ref (on_active_profile_destroyed);
                    } else {
                        critical ("Invalid profile %s", value.name);

                        m_ActiveProfile = null;
                    }
                } else {
                    debug ("%s set default profile off", name);
                    m_ActiveProfile = null;
                }

                ((Manager)manager).operations.set_card_profile_by_index (index, m_ActiveProfile == null ? "off" : m_ActiveProfile.name);
            }
        }
    }

    construct {
        m_Ports = new Gee.TreeSet<Port> (Port.compare);
        m_Profiles = new Gee.ArrayList<Profile> ();
        m_ActiveProfile = null;
    }

    public Device (Manager inManager, global::PulseAudio.CardInfo inInfo) {
        var description = inInfo.proplist.gets (global::PulseAudio.Proplist.PROP_DEVICE_DESCRIPTION);
        var display_name = inInfo.proplist.gets ("alsa.card_name");
        if (display_name == null) {
            display_name = description;
        }
        var icon_name = inInfo.proplist.gets (global::PulseAudio.Proplist.PROP_DEVICE_ICON_NAME);
        Object (
            manager: inManager,
            index: inInfo.index,
            name: inInfo.name,
            display_name: display_name,
            description: description,
            icon_name: icon_name == "audio-card-pci" ? "audio-card" : icon_name
        );

        debug (@"Create device $(name) index: $(index)");

        update (inInfo);
    }

    ~Device () {
        if (m_ActiveProfile != null) {
            m_ActiveProfile.weak_unref (on_active_profile_destroyed);
            m_ActiveProfile = null;
        }
    }

    public bool update (global::PulseAudio.CardInfo inInfo) {
        bool updated = false;

        m_Profiles.clear ();

        foreach (unowned global::PulseAudio.CardProfileInfo? profileInfo in inInfo.profiles) {
            var profileName = profileInfo.name;
            Profile profile = m_Profiles.first_match ((p) => {
                return p.name == profileName;
            });
            if (profile != null && !profileInfo.available) {
                m_Profiles.remove (profile);
            }
            else if (profile == null && profileInfo.available) {
                profile = new Profile (profileInfo);
                m_Profiles.add (profile);
            }
        }

        m_Profiles.sort (Profile.compare);

        int oldSize = m_Ports.size;
        foreach (unowned global::PulseAudio.CardPortInfo? portInfo in inInfo.ports) {
            var portName = portInfo.name;
            Port port = m_Ports.first_match ((p) => {
                return p.name == portName;
            });
            if (port != null && portInfo.available == global::PulseAudio.PortAvailable.NO) {
                m_Ports.remove (port);
                updated |= true;
            }
            else if (port == null && portInfo.available != global::PulseAudio.PortAvailable.NO) {
                port = new Port (this, portInfo);
                m_Ports.add (port);
                updated |= true;
            }
        }

        int newSize = m_Ports.size;
        if (oldSize != newSize && (oldSize == 0 || newSize == 0)) {
            notify_property ("active");
        }

        bool foundProfile = false;
        if (inInfo.active_profile != null) {
            foreach (var profile in m_Profiles) {
                if (profile.name == inInfo.active_profile.name) {
                    bool profileUpdated = m_ActiveProfile != profile;

                    updated |= profileUpdated;

                    if (m_ActiveProfile != null) {
                        m_ActiveProfile.weak_unref (on_active_profile_destroyed);
                    }
                    m_ActiveProfile = (Profile)profile;
                    m_ActiveProfile.weak_ref (on_active_profile_destroyed);
                    foundProfile = true;

                    if (profileUpdated) {
                        notify_property ("active-profile");
                    }
                    break;
                }
            }
        }
        if (!foundProfile) {
            if (m_ActiveProfile != null) {
                m_ActiveProfile.weak_unref (on_active_profile_destroyed);
            }
            m_ActiveProfile = null;

            if (inInfo.active_profile != null && inInfo.active_profile.name != "off") {
                debug ("%s set default profile off", name);
                ((Manager)manager).operations.set_card_profile_by_index (index, "off");
                updated = true;
            }
        }

        if (updated) {
            changed ();
        }

        return updated;
    }

    public override PantheonSoundControl.Profile get_profile (string inName) {
        return m_Profiles.first_match ((p) => {
            return p.name == inName;
        });
    }

    public override Profile[] get_profiles () {
        return m_Profiles.to_array ();
    }

    public override Port[] get_output_ports () {
        Port[] ret = {};
        foreach (var port in m_Ports) {
            if (port.direction == PantheonSoundControl.Port.Direction.OUTPUT) {
                ret += port;
            }
        }
        return ret;
    }

    public override Port[] get_input_ports () {
        Port[] ret = {};
        foreach (var port in m_Ports) {
            if (port.direction == PantheonSoundControl.Port.Direction.INPUT) {
                ret += port;
            }
        }
        return ret;
    }

    public override bool contains (PantheonSoundControl.Channel inChannel) {
        return inChannel.port != null && (Port)inChannel.port in m_Ports;
    }

    public override string to_string () {
        string ret = @"device: $(index), name: $(name), description: $(description) icon_name: $(icon_name)\n";
        foreach (var port in m_Ports) {
            ret += @"$(port)\n";
        }
        foreach (var profile in m_Profiles) {
            ret += @"$(profile)\n";
        }
        if (m_ActiveProfile != null) {
            ret += @"active profile:\n$(m_ActiveProfile)\n";
        }
        return ret;
    }

    private void on_active_profile_destroyed (GLib.Object inObject) {
        m_ActiveProfile = null;
    }

    public static int compare (Device inA, Device inB) {
        return (int)inA.index - (int)inB.index;
    }
}
