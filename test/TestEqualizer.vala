static int main (string[] inArgs) {
    Granite.Services.Logger.initialize ("test-manager");
    Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;

    Gst.init(ref inArgs);

    var loop = new MainLoop ();

    SukaHottoe.Manager? mgr = SukaHottoe.Manager.get ("pulseaudio");

    mgr.start ();

    SukaHottoe.Services.EqualizerManager eq_mgr = new SukaHottoe.Services.EqualizerManager(mgr);

    loop.run ();

    return 0;
}