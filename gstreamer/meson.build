gstreamer_dep = dependency('gstreamer-1.0')

shared_module(
    'suka-hottoe',
    [
        'src/Slice.vala',
        'src/SliceS16.vala',
        'src/SliceS24.vala',
        'src/SliceS32.vala',
        'src/SliceDouble.vala',
        'src/SliceFloat.vala',
        'src/Spectrum.vala',
        'src/plugin.c'
    ],
    dependencies: [
        gstreamer_dep,
        dependency('gstreamer-base-1.0'),
        dependency('gstreamer-audio-1.0'),
        dependency('gstreamer-fft-1.0')
    ],
    install: true,
    install_dir: gstreamer_dep.get_pkgconfig_variable('pluginsdir')
)