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

public class KeybindingManager : Object
{
    private Gee.List<Keybinding> bindings = new Gee.ArrayList<Keybinding> ();
    private static uint[] lock_modifiers = {
        0,
        Gdk.ModifierType.MOD2_MASK, // NUM_LOCK
        Gdk.ModifierType.LOCK_MASK, // CAPS_LOCK
        Gdk.ModifierType.MOD5_MASK, // SCROLL_LOCK
        Gdk.ModifierType.MOD2_MASK|Gdk.ModifierType.LOCK_MASK,
        Gdk.ModifierType.MOD2_MASK|Gdk.ModifierType.MOD5_MASK,
        Gdk.ModifierType.LOCK_MASK|Gdk.ModifierType.MOD5_MASK,
        Gdk.ModifierType.MOD2_MASK|Gdk.ModifierType.LOCK_MASK|Gdk.ModifierType.MOD5_MASK
    };
 
    private class Keybinding
    {
        public Keybinding (string accelerator, int keycode, Gdk.ModifierType modifiers, KeybindingHandlerFunc handler)
        {
            this.accelerator = accelerator;
            this.keycode = keycode;
            this.modifiers = modifiers;
            this.handler = handler;
        }
 
        public string accelerator { get; set; }
        public int keycode { get; set; }
        public Gdk.ModifierType modifiers { get; set; }
        public KeybindingHandlerFunc handler { get; set; }
    }
 
    public delegate void KeybindingHandlerFunc (Gdk.Event event);
 
    public KeybindingManager ()
    {
        Gdk.Window rootwin = Gdk.get_default_root_window ();
        if (rootwin != null) {
            rootwin.add_filter (event_filter);
        }
    }

    public void bind (string accelerator, KeybindingHandlerFunc handler)
    {
        uint keysym;
        Gdk.ModifierType modifiers;
        Gtk.accelerator_parse (accelerator, out keysym, out modifiers);
 
        Gdk.Window rootwin = Gdk.get_default_root_window ();  
        unowned X.Display display = (rootwin.get_display () as Gdk.X11.Display).get_xdisplay ();
        X.ID xid = (rootwin as Gdk.X11.Window).get_xid ();
        int keycode = display.keysym_to_keycode (keysym);            
 
        if (keycode != 0) {
            Gdk.error_trap_push ();
 
            foreach (uint lock_modifier in lock_modifiers) {     
                display.grab_key (keycode, modifiers|lock_modifier, xid, false, X.GrabMode.Async, X.GrabMode.Async);
            }

            Gdk.flush();
 
            Keybinding binding = new Keybinding (accelerator, keycode, modifiers, handler);
            bindings.add (binding);
        }
    }

    public void unbind(string accelerator)
    { 
        Gdk.Window rootwin = Gdk.get_default_root_window ();  
        unowned X.Display display = (rootwin.get_display () as Gdk.X11.Display).get_xdisplay ();
        X.ID xid = (rootwin as Gdk.X11.Window).get_xid ();
 
        Gee.List<Keybinding> remove_bindings = new Gee.ArrayList<Keybinding> ();
        foreach (Keybinding binding in bindings) {
            if (str_equal (accelerator, binding.accelerator)) {
                foreach (uint lock_modifier in lock_modifiers) {
                    display.ungrab_key (binding.keycode, binding.modifiers, xid);
                }
                remove_bindings.add (binding);                    
            }
        }
 
        bindings.remove_all (remove_bindings);
    }

    public Gdk.FilterReturn event_filter (Gdk.XEvent gdk_xevent, Gdk.Event gdk_event)
    {
        Gdk.FilterReturn filter_return = Gdk.FilterReturn.CONTINUE;
 
        void* pointer = &gdk_xevent;
        X.Event* xevent = (X.Event*) pointer;
 
         if (xevent->type == X.EventType.KeyPress) {
            foreach (Keybinding binding in bindings) {
                uint event_mods = xevent.xkey.state & ~ (lock_modifiers[7]);
                if (xevent->xkey.keycode == binding.keycode && event_mods == binding.modifiers) {
                    binding.handler (gdk_event);
                }
            }
         }
 
        return filter_return;
    }
}
