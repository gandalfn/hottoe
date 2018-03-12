project('com.github.gandalfn.suka-hottoe', [ 'c', 'vala' ], version: '0.2.0')

gettext_name = meson.project_name()

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
                     language: 'c')

add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
                      language: 'vala')

meson.add_install_script('meson/post_install.py')

subdir('lib')
subdir('src')
subdir('test')
subdir('po')
subdir('data')