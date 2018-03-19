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

internal class SukaHottoe.PulseAudio.Device : SukaHottoe.Device {
    private Gee.TreeSet<Port> m_ports;
    private Gee.ArrayList<Profile> m_profiles;
    private unowned Profile? m_active_profile;
    private bool m_enable_equalizer;
    private Equalizer m_equalizer;

    public uint32 index { get; construct; default = 0U; }

    public override bool active {
        get {
            return m_ports.size > 0;
        }
    }

    public override unowned SukaHottoe.Profile? active_profile {
        get {
            return m_active_profile;
        }
        set {
            if (value != m_active_profile) {
                if (m_active_profile != null) {
                    m_active_profile.weak_unref (on_active_profile_destroyed);
                }

                if (value != null) {
                    if (get_profile (value.name) != null) {
                        debug ("%s set default profile %s", name, value.name);

                        m_active_profile = (Profile?)value;
                        m_active_profile.weak_ref (on_active_profile_destroyed);
                    } else {
                        critical ("Invalid profile %s", value.name);

                        m_active_profile = null;
                    }
                } else {
                    debug ("%s set default profile off", name);
                    m_active_profile = null;
                }

                var profile_name = m_active_profile == null ? "off" : m_active_profile.name;
                ((Manager)manager).operations.set_card_profile_by_index (index, profile_name);
            }
        }
    }

    public override bool enable_equalizer {
        get {
            return m_enable_equalizer;
        }
        set {
            if (m_enable_equalizer != value) {
                m_enable_equalizer = value;
                on_manager_is_ready_nofify ();
            }
        }
    }

    public override unowned SukaHottoe.Equalizer? equalizer {
        get {
            return m_equalizer;
        }
    }

    construct {
        m_ports = new Gee.TreeSet<Port> (Port.compare);
        m_profiles = new Gee.ArrayList<Profile> ();
        m_active_profile = null;

        manager.notify["is-ready"].connect (on_manager_is_ready_nofify);
    }

    public Device (Manager in_manager, global::PulseAudio.CardInfo in_info) {
        var description = in_info.proplist.gets (global::PulseAudio.Proplist.PROP_DEVICE_DESCRIPTION);
        var display_name = in_info.proplist.gets ("alsa.card_name");
        if (display_name == null) {
            display_name = description;
        }
        Object (
            manager: in_manager,
            index: in_info.index,
            name: in_info.name,
            icon_name: in_info.proplist.gets (global::PulseAudio.Proplist.PROP_DEVICE_ICON_NAME),
            display_name: display_name,
            description: description
        );

        debug (@"Create device $(name) index: $(index)");

        update (in_info);
    }

    ~Device () {
        if (m_active_profile != null) {
            m_active_profile.weak_unref (on_active_profile_destroyed);
            m_active_profile = null;
        }
    }

    public bool update (global::PulseAudio.CardInfo in_info) {
        bool updated = false;

        m_profiles.clear ();

        foreach (unowned global::PulseAudio.CardProfileInfo? profileInfo in in_info.profiles) {
            var profile_name = profileInfo.name;
            Profile profile = m_profiles.first_match ((p) => {
                return p.name == profile_name;
            });
            if (profile != null && !profileInfo.available) {
                m_profiles.remove (profile);
            } else if (profile == null && profileInfo.available) {
                profile = new Profile (profileInfo);
                m_profiles.add (profile);
            }
        }

        m_profiles.sort (Profile.compare);

        int old_size = m_ports.size;
        foreach (unowned global::PulseAudio.CardPortInfo? portInfo in in_info.ports) {
            var port_name = portInfo.name;
            Port port = m_ports.first_match ((p) => {
                return p.name == port_name;
            });
            if (port != null && portInfo.available == global::PulseAudio.PortAvailable.NO) {
                m_ports.remove (port);
                updated |= true;
            } else if (port == null && portInfo.available != global::PulseAudio.PortAvailable.NO) {
                port = new Port (this, portInfo);
                m_ports.add (port);
                updated |= true;
            }
        }

        int newSize = m_ports.size;
        if (old_size != newSize && (old_size == 0 || newSize == 0)) {
            notify_property ("active");
        }

        bool found_profile = false;
        if (in_info.active_profile != null) {
            foreach (var profile in m_profiles) {
                if (profile.name == in_info.active_profile.name) {
                    bool profile_updated = m_active_profile != profile;

                    updated |= profile_updated;

                    if (m_active_profile != null) {
                        m_active_profile.weak_unref (on_active_profile_destroyed);
                    }
                    m_active_profile = (Profile)profile;
                    m_active_profile.weak_ref (on_active_profile_destroyed);
                    found_profile = true;

                    if (profile_updated) {
                        notify_property ("active-profile");
                    }
                    break;
                }
            }
        }
        if (!found_profile) {
            if (m_active_profile != null) {
                m_active_profile.weak_unref (on_active_profile_destroyed);
            }
            m_active_profile = null;

            if (in_info.active_profile != null && in_info.active_profile.name != "off") {
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

    public override SukaHottoe.Profile get_profile (string in_name) {
        return m_profiles.first_match ((p) => {
            return p.name == in_name;
        });
    }

    public override Profile[] get_profiles () {
        return m_profiles.to_array ();
    }

    public override Port[] get_output_ports () {
        Port[] ret = {};
        foreach (var port in m_ports) {
            if (port.direction == SukaHottoe.Direction.OUTPUT) {
                ret += port;
            }
        }
        return ret;
    }

    public override Port[] get_input_ports () {
        Port[] ret = {};
        foreach (var port in m_ports) {
            if (port.direction == SukaHottoe.Direction.INPUT) {
                ret += port;
            }
        }
        return ret;
    }

    public override bool contains (SukaHottoe.Channel in_channel) {
        return in_channel.port != null && (Port)in_channel.port in m_ports;
    }

    public override string to_string () {
        string ret = @"device: $(index), name: $(name), description: $(description) icon_name: $(icon_name)\n";
        foreach (var port in m_ports) {
            ret += @"$(port)\n";
        }
        foreach (var profile in m_profiles) {
            ret += @"$(profile)\n";
        }
        if (m_active_profile != null) {
            ret += @"active profile:\n$(m_active_profile)\n";
        }
        return ret;
    }

    private void on_manager_is_ready_nofify () {
        if (manager.is_ready && enable_equalizer && m_equalizer == null) {
            string eq_name = @"$(name).equalizer";
            string eq_desc = @"$(display_name)-Equalizer".replace (" ", "-");
            m_equalizer = new Equalizer (this, eq_name, eq_desc);
        } else if (!manager.is_ready || !enable_equalizer) {
            m_equalizer = null;
        }
    }

    private void on_active_profile_destroyed (GLib.Object in_object) {
        m_active_profile = null;
    }

    public static int compare (Device in_a, Device in_b) {
        return (int)in_a.index - (int)in_b.index;
    }
}
