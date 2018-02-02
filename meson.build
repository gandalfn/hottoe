project('pantheon-sound-control', [ 'c', 'vala' ], version: '0.1.0')

gettext_name = meson.project_name()

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
                     language: 'c')

add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
                      language: 'vala')

subdir('lib')
subdir('src')
subdir('test')
subdir('po')