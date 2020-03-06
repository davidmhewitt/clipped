sources = files(
    'Settings/CustomShortcutSettings.vala',
    'Settings/Shortcut.vala',
    'Widgets/AlertView.vala',
    'Widgets/ClipboardListBox.vala',
    'Widgets/ClipboardListRow.vala',
    'Widgets/ShortcutEntry.vala',
    'Application.vala',
    'ClipboardManager.vala',
    'ClipboardStore.vala',
    'MainWindow.vala',
    'PreferencesWindow.vala'
)
add_global_arguments('-DWNCK_I_KNOW_THIS_IS_UNSTABLE', language : 'c')

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
        dependency('x11'),
        dependency('libwnck-3.0')
    ],
    install: true
)
