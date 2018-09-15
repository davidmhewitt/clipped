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

public class Clipped.MainWindow : Gtk.Dialog {

    public signal void search_changed (string search_term);
    public signal void paste_item (int id);

    private const string SEARCH_CSS =
    """
        .large-search-entry {
            font-size: 175%;
        }
    """;

    private const string BACKGROUND_CSS =
    """
        .background {
            background-color: #fff;
        }
    """;
    private Widgets.ClipboardListBox list_box;
    private Gtk.Stack stack;
    private Widgets.AlertView empty_alert;
    private Gtk.SearchEntry search_headerbar;

    public MainWindow (Gee.ArrayList<ClipboardStore.ClipboardEntry?> entries) {
        icon_name = "com.github.davidmhewitt.clipped";

        set_keep_above (true);
        window_position = Gtk.WindowPosition.CENTER;

        set_default_size (768, 500);

        search_headerbar = new Gtk.SearchEntry ();
        search_headerbar.placeholder_text = _("Search Clipboard History\u2026");
        search_headerbar.hexpand = true;
        search_headerbar.key_press_event.connect ((event) => {
            switch (event.keyval) {
                case Gdk.Key.Escape:
                    close ();
                    return true;
                default:
                    return false;
            }
        });
        search_headerbar.search_changed.connect (() => {
            search_changed (search_headerbar.text);
        });

        var font_size_provider = new Gtk.CssProvider ();
        try {
            font_size_provider.load_from_data (SEARCH_CSS, -1);
        } catch (Error e) {
            warning ("Failed to load CSS style for search box: %s", e.message);
        }
        var style_context = search_headerbar.get_style_context ();
        style_context.add_provider (font_size_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        style_context.add_class ("large-search-entry");

        var background_provider = new Gtk.CssProvider ();
        try {
            background_provider.load_from_data (BACKGROUND_CSS, -1);
        } catch (Error e) {
            warning ("Failed to load CSS style for search window background");
        }
        get_style_context ().add_provider (background_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var list_box_scroll = new Gtk.ScrolledWindow (null, null);
        list_box_scroll.vexpand = true;
        list_box = new Widgets.ClipboardListBox ();
        list_box_scroll.add (list_box);
        list_box_scroll.show_all ();

        list_box.row_activated.connect ((row) => {
            paste_item ((row as Widgets.ClipboardListRow).id);
            destroy ();
        });

        empty_alert = new Widgets.AlertView (_("No Clipboard Items Found"), "", "edit-find-symbolic");
        empty_alert.show_all ();

        stack = new Gtk.Stack ();
        stack.add_named (list_box_scroll, "listbox");
        stack.add_named (empty_alert, "empty");

        update_stack_visibility ();

        foreach (var item in entries) {
            add_entry (item);
        }

        (get_content_area () as Gtk.Container).add (stack);

        key_press_event.connect ((event) => {
            switch (event.keyval) {
                case Gdk.Key.@0:
                case Gdk.Key.@1:
                case Gdk.Key.@2:
                case Gdk.Key.@3:
                case Gdk.Key.@4:
                case Gdk.Key.@5:
                case Gdk.Key.@6:
                case Gdk.Key.@7:
                case Gdk.Key.@8:
                case Gdk.Key.@9:
                    uint val = event.keyval - Gdk.Key.@0;
                    if (val == 0) {
                        val = 10;
                    }
                    list_box.select_row (list_box.get_row_at_index ((int)val - 1));
                    var rows = list_box.get_selected_rows ();
                    if (rows.length () > 0) {
                        rows.nth_data (0).grab_focus ();
                    }
                    list_box.activate_cursor_row ();
                    return true;
                case Gdk.Key.Down:
                case Gdk.Key.Up:
                    bool has_selection = list_box.get_selected_rows ().length () > 0;
                    if (!has_selection) {
                        list_box.select_row (list_box.get_row_at_index (0));
                    }
                    var rows = list_box.get_selected_rows ();
                    if (rows.length () > 0) {
                        rows.nth_data (0).grab_focus ();
                    }
                    if (has_selection) {
                        list_box.key_press_event (event);
                    }
                    return true;
                case Gdk.Key.Return:
                    return false;
                default:
                    break;
            }

            if (event.keyval != Gdk.Key.Escape && !search_headerbar.is_focus) {
                search_headerbar.grab_focus ();
                search_headerbar.key_press_event (event);
                return true;
            }
            return false;
        });

        set_titlebar (search_headerbar);

        show_all ();
        get_action_area ().visible = false;
    }

    public void add_entry (ClipboardStore.ClipboardEntry entry) {
        uint? index = list_box.get_children ().length () + 1;
        if (index == 10) {
            index = 0;
        }
        if (index > 10) {
            index = null;
        }
        list_box.add (new Widgets.ClipboardListRow (index, entry));
        update_stack_visibility ();
    }

    private void update_stack_visibility () {
        if (list_box.get_children ().length () > 0) {
            stack.visible_child_name = "listbox";
        } else {
            stack.visible_child_name = "empty";
            if (search_headerbar.text.length > 0) {
                empty_alert.description = _("Try changing search terms.");
            } else {
                empty_alert.description = _("Items must be copied before they appear in Clipped");
            }
        }
    }

    public void clear_list () {
        foreach (var child in list_box.get_children ()) {
            list_box.remove (child);
        }
        update_stack_visibility ();
    }
}
