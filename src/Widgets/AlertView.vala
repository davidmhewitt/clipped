/*
 *  Copyright (C) 2012-2017 Granite Developers (https://launchpad.net/granite)
 *
 *  This program or library is free software; you can redistribute it
 *  and/or modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 3 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General
 *  Public License along with this library; if not, write to the
 *  Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301 USA.
 *
 *  Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Clipped.Widgets.AlertView : Gtk.Grid {
    /**
     * The first line of text, should be short and not contain markup.
     */
    public string title {
        get {
            return title_label.label;
        }
        set {
            title_label.label = value;
        }
    }

    /**
     * The second line of text, explaining why this alert is shown.
     * You may need to escape it with #escape_text or #printf_escaped
     */
    public string description {
        get {
            return description_label.label;
        }
        set {
            description_label.label = value;
        }
    }

    /**
     * The icon name
     */
    public string icon_name {
        owned get {
            return image.icon_name;
        }
        set {
            image.set_from_icon_name (value, Gtk.IconSize.DIALOG);
        }
    }

    private Gtk.Label title_label;
    private Gtk.Label description_label;
    private Gtk.Image image;

    /**
     * Makes new AlertView
     *
     * @param title the first line of text
     * @param description the second line of text
     * @param icon_name the icon to be shown
     */
    public AlertView (string title, string description, string icon_name) {
        Object (title: title, description: description, icon_name: icon_name);
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);

        title_label = new Gtk.Label (null);
        title_label.hexpand = true;
        title_label.get_style_context ().add_class ("h2");
        title_label.max_width_chars = 45;
        title_label.wrap = true;
        title_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        title_label.xalign = 0;

        description_label = new Gtk.Label (null);
        description_label.hexpand = true;
        description_label.wrap = true;
        description_label.use_markup = true;
        description_label.xalign = 0;
        description_label.valign = Gtk.Align.START;

        image = new Gtk.Image ();
        var image_box = new Gtk.EventBox ();
        image_box.margin_top = 6;
        image_box.valign = Gtk.Align.START;
        image_box.add (image);

        column_spacing = 12;
        row_spacing = 6;
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
        vexpand = true;
        margin = 24;

        attach (image_box, 1, 1, 1, 2);
        attach (title_label, 2, 1, 1, 1);
        attach (description_label, 2, 2, 1, 1);
    }
}

