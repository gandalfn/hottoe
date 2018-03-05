i18n = import('i18n')
desktop_file = i18n.merge_file(
    'desktop',
    input: meson.project_name() + '.desktop.in',
    output: meson.project_name() + '.desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications'),
    po_dir: join_paths(meson.source_root(), 'po'),
    type: 'desktop'
)

appdata_file = i18n.merge_file(
    'appdata',
    input: meson.project_name() + '.appdata.xml.in',
    output: meson.project_name() + '.appdata.xml',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo'),
    po_dir: join_paths(meson.source_root(), 'po')
)

install_data('com.github.gandalfn.suka-hottoe',
             install_dir : get_option('bindir'),
             install_mode : ['rwxr-xr-x'])

install_data('com.github.gandalfn.suka-hottoe.svg',
             install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', '64x64', 'apps'))

# test(
#     'Validate desktop file',
#     find_program('desktop-file-validate'),
#     args: desktop_file
# )

# test(
#     'Validate appdata file',
#     find_program('appstreamcli'),
#     args: ['validate', appdata_file]
# )