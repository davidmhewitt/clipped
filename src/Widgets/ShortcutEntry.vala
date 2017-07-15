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

public class Clipped.Widgets.ShortcutEntry : Gtk.TreeView {

    public signal void shortcut_changed (string new_shortcut);

    public ShortcutEntry (string accel) {
        var shortcut = new Shortcut.parse (accel);

        var cell_edit = new Gtk.CellRendererAccel ();
        cell_edit.editable = true;
        this.insert_column_with_attributes (-1, null, cell_edit, "text", 0);
        this.headers_visible = false;
        this.get_column (0).expand = true;

        cell_edit.accel_edited.connect ((path, key, mods) =>  {
            var new_shortcut = new Shortcut (key, mods);
            change_shortcut (path, new_shortcut);
            shortcut_changed (new_shortcut.to_gsettings ());
        });

        Gtk.TreeIter iter;
        var store = new Gtk.ListStore (1, typeof (string));
        store.append (out iter);
        store.set (iter, 0, shortcut.to_readable ());

        model = store;
    }

    private void change_shortcut (string path, Shortcut? shortcut) {
        Gtk.TreeIter  iter;

        model.get_iter (out iter, new Gtk.TreePath.from_string (path));

        (model as Gtk.ListStore).set (iter, 0, shortcut.to_readable ());
    }
}
