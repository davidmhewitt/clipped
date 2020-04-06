/* Copyright 2015 Marvin Beckers <beckersmarvin@gmail.com>
 *
 * This program is free software: you can redistribute it
 * and/or modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be
 * useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 * Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see http://www.gnu.org/licenses/.
 */

public class Clipped.PreferencesWindow : Gtk.Dialog {
    private const int MIN_WIDTH = 420;
    private const int MIN_HEIGHT = 350;

    private GLib.Settings settings;

    public PreferencesWindow (bool first_run = false) {
        settings = new GLib.Settings ("com.github.davidmhewitt.clipped.settings");

        // Window properties
        title = _("Preferences");
        set_size_request (MIN_WIDTH, MIN_HEIGHT);
        resizable = false;
        window_position = Gtk.WindowPosition.CENTER;

        var close_button = new Gtk.Button.with_label (_("Close"));
        close_button.clicked.connect (() => {
            this.destroy ();
        });

        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_box.margin_end = 10;
        button_box.set_layout (Gtk.ButtonBoxStyle.END);
        button_box.pack_end (close_button);

        var content_grid = new Gtk.Grid ();
        content_grid.attach (create_general_settings_widgets (first_run), 0, 1, 1, 1);
        content_grid.attach (button_box, 0, 2, 1, 1);

        ((Gtk.Container)get_content_area ()).add (content_grid);
    }

    private Gtk.Grid create_general_settings_widgets (bool first_run) {
        string autostart_warning =
            _("<b>Note:</b> From now on, Clipped will automatically start in the background when you log in.") + " " +
            _("If you wish to change this behaviour, visit <a href=\"settings://applications/startup\">Application Settings\u2026</a>");

        var autostart_warning_label = new Gtk.Label (autostart_warning);
        autostart_warning_label.halign = Gtk.Align.START;
        autostart_warning_label.use_markup = true;
        autostart_warning_label.max_width_chars = 50;
        autostart_warning_label.wrap = true;

        Gtk.Grid general_grid = new Gtk.Grid ();
        general_grid.margin = 12;
        general_grid.hexpand = true;
        general_grid.column_spacing = 12;
        general_grid.row_spacing = 6;

        var general_header = create_heading (_("General Settings"));

        var accel = "";
        string ? accel_path = null;

        CustomShortcutSettings.init ();
        foreach (var shortcut in CustomShortcutSettings.list_custom_shortcuts ()) {
            if (shortcut.command == Application.SHOW_PASTE_CMD) {
                accel = shortcut.shortcut;
                accel_path = shortcut.relocatable_schema;
            }
        }

        var paste_shortcut_label = create_label (_("Paste Shortcut:"));
        var paste_shortcut_entry = new Widgets.ShortcutEntry (accel);
        paste_shortcut_entry.shortcut_changed.connect ((new_shortcut) => {
            if (accel_path != null) {
                CustomShortcutSettings.edit_shortcut (accel_path, new_shortcut);
            }
        });


        var retention_label = create_label (_("Days to keep infrequently used items:"));
        var retention_spinner = create_spinbutton (1, 90, 1);
        settings.bind ("days-to-keep-entries", retention_spinner, "value", SettingsBindFlags.DEFAULT);


        var notification_label = create_label (_("Show notification when adding data to clipboard:"));
        var notification_switch = create_switch ();
        settings.bind ("show-notification", notification_switch, "active", SettingsBindFlags.DEFAULT);

        if (first_run) {
            general_grid.attach (autostart_warning_label, 0, 0, 2, 1);
        }

        general_grid.attach (general_header, 0, 1, 1, 1);

        general_grid.attach (paste_shortcut_label, 0, 2, 1, 1);
        general_grid.attach (paste_shortcut_entry, 1, 2, 1, 1);

        general_grid.attach (retention_label, 0, 3, 1, 1);
        general_grid.attach (retention_spinner, 1, 3, 1, 1);


        general_grid.attach (notification_label, 0, 4, 1, 1);
        general_grid.attach (notification_switch, 1, 4, 1, 1);

        return general_grid;
    }

    private Gtk.Label create_heading (string text) {
        var label = new Gtk.Label (text);
        label.get_style_context ().add_class ("h4");
        label.halign = Gtk.Align.START;

        return label;
    }

    private Gtk.Label create_label (string text) {
        var label = new Gtk.Label (text);
        label.hexpand = true;
        label.halign = Gtk.Align.END;
        label.margin_start = 20;

        return label;
    }

    private Gtk.SpinButton create_spinbutton (double min, double max, double step) {
        var button = new Gtk.SpinButton.with_range (min, max, step);
        button.halign = Gtk.Align.START;
        button.hexpand = true;

        return button;
    }

    private Gtk.Switch create_switch () {
        var button = new Gtk.Switch ();
        button.halign = Gtk.Align.START;
        button.hexpand = true;

        return button;
    }
}
