backend_path = join_paths(get_option('prefix'), get_option('libdir'), meson.project_name())

libpantheon_sound_control_inc = include_directories('.')

libpantheon_sound_control = library(
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
    include_directories: libpantheon_sound_control_inc,
    install: true
)

pantheon_sound_control_dep = declare_dependency(
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0')
    ],
    link_with: libpantheon_sound_control,
    include_directories: libpantheon_sound_control_inc)

subdir('PulseAudio')