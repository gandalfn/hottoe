static int main (string[] in_args) {
    Granite.Services.Logger.initialize ("test-manager");
    Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;

    Gst.init (ref in_args);

    var loop = new MainLoop ();

    Hottoe.Manager? mgr = Hottoe.Manager.get ("pulseaudio");

    mgr.start ();

    Hottoe.Services.EqualizerManager eq_mgr = null;

    mgr.notify["is-ready"].connect (() => {
        eq_mgr = new Hottoe.Services.EqualizerManager (mgr);
    });

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