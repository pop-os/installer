// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2017–2018 elementary LLC. (https://elementary.io)
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
 */

public class SuccessView : AbstractInstallerView {
    public static int RESTART_TIMEOUT = 30;

    public string? log { get; construct; }
    public bool upgrade { get; construct; }

    public SuccessView (string? log, bool upgrade) {
        Object (log: log, upgrade: upgrade);
    }

    construct {
        var artwork = new Gtk.Grid ();
        artwork.get_style_context ().add_class ("success");
        artwork.get_style_context ().add_class ("artwork");
        artwork.vexpand = true;

        var title_label = new Gtk.Label (upgrade ? _("Upgrade Complete") : _("Continue Setting Up"));
        title_label.halign = Gtk.Align.CENTER;
        title_label.max_width_chars = 30;
        title_label.valign = Gtk.Align.START;
        title_label.wrap = true;
        title_label.xalign = 0;
        title_label.get_style_context ().add_class ("h2");

        var description_label = new Gtk.Label (upgrade
            ? _("The system has been upgraded to the new release. You may now reboot.")
            : _("After restarting you can set up a new user, or you can shut down now and set up a new user later."));

        description_label.max_width_chars = 52;
        description_label.wrap = true;
        description_label.xalign = 0;
        description_label.use_markup = true;

        var grid = new Gtk.Grid ();
        grid.row_spacing = 6;
        grid.margin_left = 24;
        grid.valign = Gtk.Align.CENTER;
        grid.attach (description_label, 0, 0, 1, 1);

        Terminal? terminal = null;
        if (null != log) {
            var buffer = new Gtk.TextBuffer (null);
            buffer.text = log;
            terminal = new Terminal (buffer);
        }

        var label_area = new Gtk.Grid ();
        label_area.column_homogeneous = true;
        label_area.halign = Gtk.Align.FILL;
        label_area.valign = Gtk.Align.FILL;
        label_area.attach (artwork,       0, 0, 1, 1);
        label_area.attach (title_label, 0, 1, 1, 1);
        label_area.attach (grid,        1, 0, 1, 2);

        var content_stack = new Gtk.Stack ();
        content_stack.transition_type = Gtk.StackTransitionType.OVER_UP_DOWN;
        content_stack.add (label_area);
        content_area.attach (content_stack, 0, 0, 1, 1);

        if (null != terminal) {
            content_stack.add (terminal.container);
            terminal.toggled.connect ((active) => {
                content_stack.visible_child = active
                    ? (Gtk.Widget) terminal.container
                    : (Gtk.Widget) label_area;
            });

            action_area.add (terminal.toggle);
        }

        var shutdown_button = new Gtk.Button.with_label (_("Shut Down"));
        shutdown_button.clicked.connect (Utils.shutdown);

        var restart_button = new Gtk.Button.with_label (_("Restart Device"));
        restart_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        restart_button.clicked.connect (Utils.restart);

        action_area.add (shutdown_button);
        action_area.add (restart_button);

        show_all ();
    }
}
