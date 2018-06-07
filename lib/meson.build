backend_path = join_paths(get_option('prefix'), get_option('libdir'), meson.project_name())

libhottoe_inc = include_directories('.')

libhottoe = library(
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
        'Equalizer.vala',
        'Spectrum.vala',
        'Manager.vala'
    ],
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('gmodule-2.0'),
        dependency('gee-0.8')
    ],
    c_args: [ '-DBACKEND_PATH="' + backend_path + '"'],
    include_directories: libhottoe_inc,
    install: true,
    install_dir : [true, true, true],
    version: meson.project_version()
)

hottoe_dep = declare_dependency(
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0')
    ],
    link_with: libhottoe,
    include_directories: libhottoe_inc)

subdir('PulseAudio')