static int main (string[] in_args) {
    Granite.Services.Logger.initialize ("test-manager");
    Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;

    Gst.init (ref in_args);

    var loop = new MainLoop ();

    SukaHottoe.Manager? mgr = SukaHottoe.Manager.get ("pulseaudio");

    mgr.start ();

    SukaHottoe.Spectrum spectrum = null;

    mgr.notify["is-ready"].connect (() => {
        foreach (var device in mgr.get_devices ()) {
            foreach (var channel in device.get_output_channels ()) {
                print("channel %s\n", channel.name);
                spectrum = mgr.create_spectrum (channel, 44100, 100);
                spectrum.enabled = true;
                spectrum.threshold = -90;
                spectrum.updated.connect (() => {
                    int cpt = 0;
                    foreach (float val in spectrum.get_magnitudes ()) {
                        double freq = (double) ((44100.0 / 2.0) * cpt + 44100.0 / 4.0) / 20;
                        print("%f = %f ", freq, val + 20);
                        cpt++;
                    }
                    print("\n");
                });
                return;
            }
        }
    });

    loop.run ();

    return 0;
}