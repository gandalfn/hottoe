static int main (string[] inArgs) {
    Granite.Services.Logger.initialize ("test-manager");
    Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;

    Gst.init(ref inArgs);

    var loop = new MainLoop ();

    SukaHottoe.Manager? mgr = SukaHottoe.Manager.get ("pulseaudio");


    SukaHottoe.Settings.Equalizer eq = new SukaHottoe.Settings.Equalizer("equalizer-1");
    eq.name = "equalizer-test";
    eq.device = "alsa_output.pci-0000_00_1f.3.analog-stereo";
    eq.values = { "25", "50", "35", "0", "0", "-20", "-20", "-20", "0", "0" };

    mgr.start ();

    SukaHottoe.Services.EqualizerManager eq_mgr = null;

    mgr.ready.connect (() => {
        var settings = new SukaHottoe.Settings.Main ();
        eq_mgr = new SukaHottoe.Services.EqualizerManager(settings, mgr);
    });

    loop.run ();

    return 0;
}