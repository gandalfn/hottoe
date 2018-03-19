executable(
    'test-manager',
    [
        'TestManager.vala'
    ],
    dependencies: [
        suka_hottoe_dep,
        dependency('granite'),
        dependency('gtk+-3.0')
    ],
    install: false
)

executable(
    'test-equalizer',
    [
        join_paths(meson.source_root(), 'src', 'Settings', 'Equalizer.vala'),
        join_paths(meson.source_root(), 'src', 'Services', 'EqualizerManager.vala'),
        'TestEqualizer.vala'
    ],
    dependencies: [
        suka_hottoe_dep,
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('gstreamer-1.0')
    ],
    install: false
)