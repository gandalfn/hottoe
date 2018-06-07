shared_module(
    'pulseaudio-backend',
    [
        'Operations.vala',
        'Manager.vala',
        'Device.vala',
        'Port.vala',
        'Profile.vala',
        'Channel.vala',
        'OutputChannel.vala',
        'InputChannel.vala',
        'Monitor.vala',
        'Client.vala',
        'Plug.vala',
        'OutputPlug.vala',
        'InputPlug.vala',
        'Module.vala',
        'Equalizer.vala',
        'Spectrum.vala'
    ],
    dependencies: [
        hottoe_dep,
        dependency('gio-2.0'),
        dependency('gee-0.8'),
        meson.get_compiler('vala').find_library('posix'),
        dependency('libpulse'),
        dependency('libpulse-mainloop-glib'),
        dependency('gstreamer-1.0'),
        dependency('gstreamer-audio-1.0')
    ],
    install: true,
    install_dir: backend_path
)
