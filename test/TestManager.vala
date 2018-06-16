static void on_device_changed (Hottoe.Device in_device) {
    print (@"Device changed $(in_device)\n");
    Hottoe.Port? hdmi_port = null;
    foreach (var port in in_device.get_output_ports ()) {
        if (port.name.has_prefix ("hdmi")) {
            print (@"HDMI device !!! \n");
            hdmi_port = port;
            break;
        }
    }
    if (hdmi_port != null) {
        var profile = in_device.get_profiles ()[0];
        if (profile != null) {
            print (@"Set default profile %s\n", profile.name);
            in_device.active_profile = profile;
        }
    }
}

static void on_device_added (Hottoe.Device in_device) {
    print (@"Device added $(in_device)\n");
    in_device.changed.connect (on_device_changed);
}

static void on_channel_changed (Hottoe.Channel in_channel) {
    print (@"Channel changed $(in_channel)\n");
}

static void on_channel_added (Hottoe.Channel in_channel) {
    print (@"Channel added $(in_channel)\n");
    in_channel.changed.connect (on_channel_changed);
}

static void on_client_changed (Hottoe.Client in_client) {
    print (@"Client changed $(in_client)\n");
}

static void on_client_added (Hottoe.Client in_client) {
    print (@"Client added $(in_client)\n");
    in_client.changed.connect (on_client_changed);
}

static int main (string[] in_args) {
    Granite.Services.Logger.initialize ("test-manager");
    Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;

    var loop = new MainLoop ();

    Hottoe.Manager? mgr = Hottoe.Manager.get ("pulseaudio");

    mgr.device_added.connect (on_device_added);

    mgr.channel_added.connect (on_channel_added);

    mgr.client_added.connect (on_client_added);

    mgr.start ();

    Posix.termios ios_old;
    Posix.tcgetattr (0, out ios_old);
    Posix.termios ios_new = ios_old;
    ios_new.c_lflag &= ~(Posix.ICANON);
    ios_new.c_lflag &= ~(Posix.ECHO);
    Posix.tcsetattr (0, Posix.TCSANOW, ios_new);

    var stdin = new GLib.IOChannel.unix_new (0);
    stdin.add_watch (GLib.IOCondition.OUT, (source, condition) => {
        char key = 0;
        size_t size = 1;
        try {
            source.read_chars ((char[])&key, out size);
            if (size > 0) {
                if (key == 'q') {
                    loop.quit ();
                    return false;
                }
            }
        } catch (GLib.Error err) {
        }
        return true;
    });

    loop.run ();

    Posix.tcsetattr (0, Posix.TCSANOW, ios_old);

    return 0;
}