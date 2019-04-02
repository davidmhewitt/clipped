project('com.github.davidmhewitt.clipped','vala', 'c', version: '1.1.0')

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()),
    language:'c'
)

subdir('src')

executable(
    meson.project_name(),
    sources,
    dependencies: [
        dependency('gtk+-3.0'),
        dependency('gio-unix-2.0'),
        dependency('sqlite3'),
        dependency('gee-0.8'),
        dependency('gdk-x11-3.0'),
        dependency('xtst'),
        dependency('x11')
    ],
    install: true
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')