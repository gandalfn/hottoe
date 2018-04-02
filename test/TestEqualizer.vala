static int main (string[] in_args) {
    Granite.Services.Logger.initialize ("test-manager");
    Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;

    Gst.init (ref in_args);

    var loop = new MainLoop ();

    SukaHottoe.Manager? mgr = SukaHottoe.Manager.get ("pulseaudio");

    mgr.start ();

    SukaHottoe.Services.EqualizerManager eq_mgr = null;

    mgr.notify["is-ready"].connect (() => {
        eq_mgr = new SukaHottoe.Services.EqualizerManager (mgr);
    });

    loop.run ();

    return 0;
}