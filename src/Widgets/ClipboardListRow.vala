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

public class Clipped.Widgets.ClipboardListRow : Gtk.ListBoxRow {

    public int id;

    private const string KEYCAP_CSS = """
        .keycap {
            margin-top: 2px;
            padding-bottom: 3px;
            padding-left: 6px;
            padding-right: 6px;
            color: #2e3436;
            background-color: #ffffff;
            border: 1px solid;
            border-color: #cfcfcd;
            border-radius: 5px;
            box-shadow: inset 0 -3px #ededec;
            font-size: 150%;
        }
    """;

    public ClipboardListRow (uint? index, ClipboardStore.ClipboardEntry entry) {
        id = entry.id;

        var provider = new Gtk.CssProvider ();
        try {
            provider.load_from_data (KEYCAP_CSS, -1);
        } catch (Error e) {
            warning ("Failed to load custom CSS for keycap labels: %s", e.message);
        }

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.row_spacing = 3;
        grid.margin = 12;
        grid.margin_bottom = grid.margin_top = 6;

        add (grid);

        if (index != null) {
            var shortcut = new Gtk.Label (index.to_string ());
            shortcut.get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
            shortcut.get_style_context ().add_class ("keycap");
            shortcut.set_size_request (20, 25);
            grid.attach (shortcut, 0, 0, 1, 1);
        }

        var sanitised_text = entry.text.replace ("\n", "");
        var text = new Gtk.Label (sanitised_text);
        text.get_style_context ().add_class ("h3");
        text.ellipsize = Pango.EllipsizeMode.MIDDLE;
        text.lines = 1;
        text.single_line_mode = true;
        text.max_width_chars = 60;

        var delete_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.BUTTON) {
            tooltip_markup = Granite.markup_accel_tooltip ({"Delete"}, _("Delete this history")),
            halign = Gtk.Align.END,
            hexpand = true
        };
        delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        delete_button.clicked.connect (() => {
            MainWindow paste_window = ((Clipped.Application) GLib.Application.get_default ()).window;
            paste_window.delete_entry (this);
        });

        grid.attach (text, 1, 0, 1, 1);
        grid.attach (delete_button, 2, 0, 1, 1);

        show_all ();
    }
}
