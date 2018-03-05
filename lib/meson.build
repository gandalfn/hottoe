backend_path = join_paths(get_option('prefix'), get_option('libdir'), meson.project_name())

libsuka_hottoe_inc = include_directories('.')

libsuka_hottoe = library(
    meson.project_name(),
    [
        'Direction.vala',
        'Plug.vala',
        'Client.vala',
        'Monitor.vala',
        'Channel.vala',
        'Profile.vala',
        'Port.vala',
        'Device.vala',
        'Manager.vala'
    ],
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('gmodule-2.0'),
        dependency('gee-0.8')
    ],
    c_args: [ '-DBACKEND_PATH="' + backend_path + '"'],
    include_directories: libsuka_hottoe_inc,
    install: true,
    install_dir : [true, true, true],
    version: meson.project_version()
)

suka_hottoe_dep = declare_dependency(
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0')
    ],
    link_with: libsuka_hottoe,
    include_directories: libsuka_hottoe_inc)

subdir('PulseAudio')