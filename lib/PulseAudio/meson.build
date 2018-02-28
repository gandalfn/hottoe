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
        'InputPlug.vala'
    ],
    dependencies: [
        pantheon_sound_control_dep,
        dependency('gio-2.0'),
        dependency('gee-0.8'),
        meson.get_compiler('vala').find_library('posix'),
        dependency('libpulse'),
        dependency('libpulse-mainloop-glib')
    ],
    install: true,
    install_dir: backend_path
)
