// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2018 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Michael Aaron Murphy <michael@system76.com>
 *
 */

public class ErrorDialog : Gtk.Dialog {
    public string msg { get; construct; }

    public ErrorDialog (string title, string msg) {
        Object (
            title: title,
            msg: msg,
            deletable: true,
            resizable: false
        );
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("dialog-error", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.START;

        var primary_label = new Gtk.Label (msg);
        primary_label.max_width_chars = 50;
        primary_label.selectable = false;
        primary_label.wrap = true;
        primary_label.xalign = 0;
        primary_label.get_style_context ().add_class ("primary");

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.margin_start = grid.margin_end = 12;
        grid.attach (image, 0, 0, 1, 2);
        grid.attach (primary_label, 1, 0, 1, 1);
        grid.show_all ();

        get_content_area ().add (grid);
        set_modal (true);
        set_keep_above (true);
        stick ();
    }

    public void run (Gtk.Window toplevel) {
        transient_for = toplevel;
        window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
        show_all ();
    }
}
