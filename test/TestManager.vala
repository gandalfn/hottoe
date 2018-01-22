static void on_device_changed (PantheonSoundControl.Device inDevice) {
    print (@"Device changed $(inDevice)\n");
    PantheonSoundControl.Port? hdmiPort = null;
    foreach (var port in inDevice.get_output_ports ()) {
        if (port.name.has_prefix ("hdmi")) {
            print(@"HDMI device !!! \n");
            hdmiPort = port;
            break;
        }
    }
    if (hdmiPort != null) {
        var profile = inDevice.get_profiles ()[0];
        if (profile != null) {
            print (@"Set default profile %s\n", profile.name);
            inDevice.active_profile = profile;
        }
    }
}

static void on_device_added (PantheonSoundControl.Device inDevice) {
    print (@"Device added $(inDevice)\n");
    inDevice.changed.connect (on_device_changed);
}

static void on_channel_changed (PantheonSoundControl.Channel inChannel) {
    print (@"Channel changed $(inChannel)\n");
}

static void on_channel_added (PantheonSoundControl.Channel inChannel) {
    print (@"Channel added $(inChannel)\n");
    inChannel.changed.connect (on_channel_changed);
}

static void on_client_changed (PantheonSoundControl.Client inClient) {
    print (@"Client changed $(inClient)\n");
}

static void on_client_added (PantheonSoundControl.Client inClient) {
    print (@"Client added $(inClient)\n");
    inClient.changed.connect (on_client_changed);
}

static int main (string[] inArgs) {
    Granite.Services.Logger.initialize ("test-manager");
    Granite.Services.Logger.DisplayLevel =  Granite.Services.LogLevel.DEBUG;

    var loop = new MainLoop();

    PantheonSoundControl.Manager? mgr = PantheonSoundControl.Manager.get ("pulseaudio");

    mgr.device_added.connect(on_device_added);

    mgr.channel_added.connect(on_channel_added);

    mgr.client_added.connect(on_client_added);

    mgr.start ();

    loop.run();

    return 0;
}