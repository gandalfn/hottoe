posix_dep = meson.get_compiler('vala').find_library('posix')

test_manager = executable(
    'test-manager',
    [
        'TestManager.vala'
    ],
    dependencies: [
        posix_dep,
        hottoe_dep,
        dependency('granite'),
        dependency('gtk+-3.0')
    ],
    install: false
)
benchmark('manager', test_manager, timeout: 3600)

test_equalizer = executable(
    'test-equalizer',
    [
        join_paths(meson.source_root(), 'src', 'Settings', 'Equalizer.vala'),
        join_paths(meson.source_root(), 'src', 'Services', 'EqualizerManager.vala'),
        'TestEqualizer.vala'
    ],
    dependencies: [
        posix_dep,
        hottoe_dep,
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('gstreamer-1.0')
    ],
    install: false
)
benchmark('equalizer', test_equalizer, timeout: 3600)

test_spectrum = executable(
    'test-spectrum',
    [
        'TestSpectrum.vala'
    ],
    dependencies: [
        posix_dep,
        hottoe_dep,
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('gstreamer-1.0')
    ],
    install: false
)
benchmark('spectrum', test_spectrum, timeout: 3600)
