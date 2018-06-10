appdata_file = i18n.merge_file(
    'appdata',
    input: meson.project_name() + '.appdata.xml.in',
    output: meson.project_name() + '.appdata.xml',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo'),
    po_dir: join_paths(meson.source_root(), 'po')
)

install_data(
    meson.project_name() + '.svg',
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', '64x64', 'apps')
)

install_data(
    meson.project_name() + '.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

run_target('validate', command : ['appstreamcli',
                                  'validate',
                                  '--pedantic',
                                  join_paths(meson.current_build_dir(), meson.project_name() + '.appdata.xml')])