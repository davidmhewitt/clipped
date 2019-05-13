/*
* Copyright (c) 2017 David Hewitt (https://github.com/davidmhewitt)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: David Hewitt <davidmhewitt@gmail.com>
*/

public class Clipped.Application : Gtk.Application {
    private static Clipped.Application? _instance = null;
    private ClipboardManager manager;
    private MainWindow? window = null;

    public const string SHOW_PASTE_CMD = "com.github.davidmhewitt.clipped --show-paste-window";
    private const string SHOW_PASTE_SHORTCUT = "<Control><Alt>v";
    private string version_string;

    private ClipboardStore clipboard_store;

    private bool show_paste = false;
    private bool show_preferences = false;
    private bool already_running = false;
    private int? queued_paste = null;

    construct {
        application_id = "com.github.davidmhewitt.clipped";
        flags = ApplicationFlags.HANDLES_COMMAND_LINE;
        version_string = "1.1.1";

        CustomShortcutSettings.init ();

        window_removed.connect ((closed_window) => {
            if (queued_paste != null) {
                clipboard_store.select_item (queued_paste);
                manager.paste ();
            }
            if (closed_window == window) {
                close_window ();
            }
        });
    }

    public override void activate () {
        var settings = new GLib.Settings (application_id + ".settings");
        var first_run = settings.get_boolean ("first-run");
        var retention_period = settings.get_uint ("days-to-keep-entries");

        clipboard_store = new ClipboardStore (retention_period);

        settings.changed["days-to-keep-entries"].connect (() => {
            clipboard_store.set_retention_days (settings.get_uint ("days-to-keep-entries"));
        });

        manager = new ClipboardManager ();
        manager.start ();

        manager.on_text_copied.connect ((text) => {
            clipboard_store.insert_text_item (text);
        });

        if (first_run) {
            install_autostart ();
            set_default_shortcut ();
            show_preferences = true;
            settings.set_boolean ("first-run", false);
        }

        if (show_preferences) {
            if (window != null) {
                close_window ();
            }
            var prefs = new PreferencesWindow (first_run);
            prefs.show_all ();
            add_window (prefs);
        }

        if (show_paste || (already_running && !show_preferences)) {
            unowned List<Gtk.Window> windows = get_windows ();
            if (windows.length () > 0) {
                window = (MainWindow)windows.data;
                close_window ();
                return;
            }

            queued_paste = null;
            window = new MainWindow (clipboard_store.get_most_recent_items ());
            add_window (window);

            window.search_changed.connect ((text) => {
                if (text == "") {
                    load_entries (clipboard_store.get_most_recent_items ());
                } else {
                    load_entries (clipboard_store.search (text));
                }
            });

            // Sometimes wingpanel will focus out the window on startup, so wait 200ms
            // before connecting the focus out handler
            Timeout.add (200, () => {
                window.focus_out_event.connect (() => {
                    close_window ();
                    return false;
                });

                return false;
            });

            window.paste_item.connect ((id) => {
                queued_paste = id;
            });

            window.delete_item.connect ((id) => {
                clipboard_store.delete_item (id);
            });
        }
    }

    private void close_window () {
        if (window != null) {
            Timeout.add (250, () => {
                window.destroy ();
                window = null;
                return false;
            });
        }

        queued_paste = null;
    }

    private void set_default_shortcut () {
        CustomShortcutSettings.init ();
        foreach (var shortcut in CustomShortcutSettings.list_custom_shortcuts ()) {
            if (shortcut.command == SHOW_PASTE_CMD) {
                CustomShortcutSettings.edit_shortcut (shortcut.relocatable_schema, SHOW_PASTE_SHORTCUT);
                return;
            }
        }
        var shortcut = CustomShortcutSettings.create_shortcut ();
        if (shortcut != null) {
            CustomShortcutSettings.edit_shortcut (shortcut, SHOW_PASTE_SHORTCUT);
            CustomShortcutSettings.edit_command (shortcut, SHOW_PASTE_CMD);
        }
    }

    private void install_autostart () {
        var desktop_file_name = application_id + ".desktop";
        var desktop_file_path = new DesktopAppInfo (desktop_file_name).filename;
        var desktop_file = File.new_for_path (desktop_file_path);
        var dest_path = Path.build_path (   Path.DIR_SEPARATOR_S,
                                            Environment.get_user_config_dir (),
                                            "autostart",
                                            desktop_file_name);
        var dest_file = File.new_for_path (dest_path);
        try {
            desktop_file.copy (dest_file, FileCopyFlags.OVERWRITE);
        } catch (Error e) {
            warning ("Error making copy of desktop file for autostart: %s", e.message);
        }

        var keyfile = new KeyFile ();
        try {
            keyfile.load_from_file (dest_path, KeyFileFlags.NONE);
            keyfile.set_boolean ("Desktop Entry", "X-GNOME-Autostart-enabled", true);
            keyfile.save_to_file (dest_path);
        } catch (Error e) {
            warning ("Error enabling autostart: %s", e.message);
        }
    }

    private void load_entries (Gee.ArrayList<ClipboardStore.ClipboardEntry?> entries) {
        window.clear_list ();
        foreach (var item in entries) {
            window.add_entry (item);
        }
    }

	public override int command_line (ApplicationCommandLine command_line) {
        show_paste = show_preferences = false;
		bool version = false;

		OptionEntry[] options = new OptionEntry[3];
		options[0] = { "version", 0, 0, OptionArg.NONE, ref version, "Display version number", null };
        options[1] = { "show-paste-window", 0, 0, OptionArg.NONE, ref show_paste, "Display paste history window", null };
        options[2] = { "preferences", 0, 0, OptionArg.NONE, ref show_preferences, "Display preferences window", null };

		// We have to make an extra copy of the array, since .parse assumes
		// that it can remove strings from the array without freeing them.
		string[] args = command_line.get_arguments ();
		string[] _args = new string[args.length];
		for (int i = 0; i < args.length; i++) {
			_args[i] = args[i];
		}

		try {
			var opt_context = new OptionContext ();
			opt_context.set_help_enabled (true);
			opt_context.add_main_entries (options, null);
			unowned string[] tmp = _args;
			opt_context.parse (ref tmp);
		} catch (OptionError e) {
			command_line.print ("error: %s\n", e.message);
			command_line.print ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
			return 0;
		}

		if (version) {
			command_line.print ("%s\n", version_string);
			return 0;
		}

        hold ();
        activate ();
        already_running = true;
		return 0;
	}

    public static new Clipped.Application get_default () {
        if (_instance == null) {
            _instance = new Clipped.Application ();
        }
        return _instance;
    }
}

int main (string[] args) {
    var app = Clipped.Application.get_default ();
    return app.run (args);
}
