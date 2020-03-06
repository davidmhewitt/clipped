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

class Clipped.ClipboardManager : GLib.Object {
    private Gtk.Clipboard clipboard = null;
    private Regex blackregex = null;
    private Wnck.Screen screen = null;

    public signal void on_text_copied (string text);

    public ClipboardManager (string blackregex_pattern) {
        clipboard = Gtk.Clipboard.get (Gdk.SELECTION_CLIPBOARD);
        screen = Wnck.Screen.get_default();
        set_blackregex (blackregex_pattern);
    }

    ~ClipboardManager () {
        clipboard.owner_change.disconnect (on_clipboard_event);
    }

    public virtual void start () {
        clipboard.owner_change.connect (on_clipboard_event);
    }

    private void on_clipboard_event () {
        string? text = request_text ();
        bool text_available = (text != null && text != "") || clipboard.wait_is_text_available ();

        if (text_available) {
            if (text != null && text != "") {
                if (blackregex != null) {
                    string title = request_title ();
                    if (title.length == 0) {
                        // in the case a blackregex is set but we cannot retrieve the window title
                        // due to libwinck not ready, or other reason, we must assume it would be a match
                        // or risk leaking the secure data.
                        return;
                    }
                    if (blackregex.match (title)) {
                        return;
                    }
                }
                on_text_copied (text);
            }
        }
    }

    private string? request_text () {
        string? result = clipboard.wait_for_text ();
        return result;
    }
    
    private string request_title () {
        var window = screen.get_active_window ();
        if (window == null) {
            screen.force_update();
            window = screen.get_active_window ();
            if (window == null) {
                return "";
            }
        }

        return window.get_name () ?? "";
    }

    public void paste () {
        perform_key_event ("<Control>v", true, 100);
        perform_key_event ("<Control>v", false, 0);
    }

    public void set_blackregex (string? pattern) {
        if (pattern == null || pattern.length == 0) {
            blackregex = null;
            return;
        }
        try {
            blackregex = new Regex (pattern);
        } catch (GLib.RegexError ex) {
            warning("Error while parsing regex.");
        }
    }

    private static void perform_key_event (string accelerator, bool press, ulong delay) {
        uint keysym;
        Gdk.ModifierType modifiers;
        Gtk.accelerator_parse (accelerator, out keysym, out modifiers);
        unowned X.Display display = Gdk.X11.get_default_xdisplay ();
        int keycode = display.keysym_to_keycode (keysym);

        if (keycode != 0) {
            if (Gdk.ModifierType.CONTROL_MASK in modifiers) {
                int modcode = display.keysym_to_keycode (Gdk.Key.Control_L);
                XTest.fake_key_event (display, modcode, press, delay);
            }

            if (Gdk.ModifierType.SHIFT_MASK in modifiers) {
                int modcode = display.keysym_to_keycode (Gdk.Key.Shift_L);
                XTest.fake_key_event (display, modcode, press, delay);
            }

            XTest.fake_key_event (display, keycode, press, delay);
        }
    }
}
