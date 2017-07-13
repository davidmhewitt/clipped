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
    private const int MIN_HEIGHT = 300;

    public PreferencesWindow (bool first_run = false) {
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
        button_box.margin_right = 10;
        button_box.set_layout (Gtk.ButtonBoxStyle.END);
        button_box.pack_end (close_button);

        var content_grid = new Gtk.Grid ();
        content_grid.attach (create_general_settings_widgets (first_run), 0, 1, 1, 1);
        content_grid.attach (button_box, 0, 2, 1, 1);

        ((Gtk.Container) get_content_area ()).add (content_grid);
    }

    private Gtk.Grid create_general_settings_widgets (bool first_run) {
        string autostart_warning = 
            _("<b>Note:</b> From now on, Clipped will automatically start in the background when you log in.") + " " +
            _("If you wish to change this behaviour, visit <a href=\"settings://applications/startup\">Application Settings\u2026</a>");
              

        var autostart_warning_label = create_label (autostart_warning);
        autostart_warning_label.use_markup = true;
        autostart_warning_label.max_width_chars = 60;
        autostart_warning_label.wrap = true;

        Gtk.Grid general_grid = new Gtk.Grid ();
        general_grid.margin = 12;
        general_grid.hexpand = true;
        general_grid.column_spacing = 12;
        general_grid.row_spacing = 6;

        general_grid.attach (autostart_warning_label, 0, 0, 1, 1);

        return general_grid;
    }

    private Gtk.Label create_heading (string text) {
        var label = new Gtk.Label (text);
        label.get_style_context ().add_class ("h4");
        label.halign = Gtk.Align.START;

        return label;
    }

    private Gtk.Switch create_switch () {
        var toggle = new Gtk.Switch ();
        toggle.halign = Gtk.Align.START;
        toggle.hexpand = true;

        return toggle;
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

    private Gtk.Entry create_entry () {
        var entry = new Gtk.Entry ();
        entry.halign = Gtk.Align.START;
        entry.hexpand = true;

        return entry;
    }

    private Gtk.Button create_button (string label) {
        var button = new Gtk.Button.with_label (label);
        button.halign = Gtk.Align.START;
        button.hexpand = true;

        return button;
    }
}

