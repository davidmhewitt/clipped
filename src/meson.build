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

executable(
    meson.project_name(),
    sources,
    dependencies: [
        dependency('gtk+-3.0'),
        dependency('granite', version: '>= 5.4.0'),
        dependency('gio-unix-2.0'),
        dependency('sqlite3'),
        dependency('gee-0.8'),
        dependency('gdk-x11-3.0'),
        dependency('xtst'),
        dependency('x11')
    ],
    install: true
)
