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

public class ErrorView : AbstractInstallerView {
    public bool upgrade { get; construct; }
    public uint64 minimum_disk_size { get; construct; }
    public string log { get; construct; }

    public ErrorView (string log, uint64 minimum_disk_size, bool upgrade) {
        Object (log: log, minimum_disk_size: minimum_disk_size, upgrade: upgrade);
    }

    construct {
        var artwork = new Gtk.Grid ();
        artwork.get_style_context ().add_class ("error");
        artwork.get_style_context ().add_class ("artwork");
        artwork.vexpand = true;

        var title_label = new Gtk.Label (upgrade
            ? _("Could Not Upgrade")
            : _("Could Not Install"));

        title_label.halign = Gtk.Align.CENTER;
        title_label.max_width_chars = 30;
        title_label.valign = Gtk.Align.START;
        title_label.wrap = true;
        title_label.xalign = 0;
        title_label.get_style_context ().add_class ("h2");

        var grid = new Gtk.Grid ();
        grid.row_spacing = 6;
        grid.margin_left = 24;
        grid.valign = Gtk.Align.CENTER;

        var description_label = new_description_label (null);
        grid.attach (description_label, 0, 0, 1, 1);

        if (upgrade) {
            description_label.label = _("Upgrading to the next release failed. Your device may not boot correctly on the next start. There are two options:");
            var recovery_shell = new_description_label (_("• Use a recovery shell to attempt to manually fix the problem"));
            var refresh = new_description_label (_("• Use the installer to perform a system refresh."));

            grid.attach (recovery_shell, 0, 1, 1, 1);
            grid.attach (refresh,        0, 2, 1, 1);
        } else {
            description_label.label = _("Installing %s failed, possibly due to a hardware error. Your device may not restart properly. You can try the following:").printf (Utils.get_pretty_name ());
            var try_again = new_description_label (_("• Try the installation again"));
            var demo_recover = new_description_label (_("• Use Demo Mode and try to manually recover"));
            var restart = new_description_label (_("• Restart your device to boot from another drive"));

            grid.attach (try_again ,    0, 1, 1, 1);
            grid.attach (demo_recover,  0, 2, 1, 1);
            grid.attach (restart, 0, 3, 1, 1);
        }

        Gtk.ScrolledWindow? terminal_output = null;
        if (null != log) {
            var terminal_view = new Gtk.TextView ();
            terminal_view.buffer.text = log;
            terminal_view.bottom_margin = terminal_view.top_margin = terminal_view.left_margin = terminal_view.right_margin = 12;
            terminal_view.editable = false;
            terminal_view.cursor_visible = true;
            terminal_view.monospace = true;
            terminal_view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
            terminal_view.get_style_context ().add_class ("terminal");

            terminal_output = new Gtk.ScrolledWindow (null, null);
            terminal_output.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
            terminal_output.propagate_natural_width = true;
            terminal_output.add (terminal_view);
            terminal_output.vexpand = true;
            terminal_output.hexpand = true;
        }

        var label_area = new Gtk.Grid ();
        label_area.column_homogeneous = true;
        label_area.halign = Gtk.Align.CENTER;
        label_area.valign = Gtk.Align.FILL;
        label_area.attach (artwork,       0, 0, 1, 1);
        label_area.attach (title_label, 0, 1, 1, 1);
        label_area.attach (grid,        1, 0, 1, 2);

        var content_stack = new Gtk.Stack ();
        content_stack.add (label_area);

        if (null != terminal_output) {
            content_stack.add (terminal_output);

            var terminal_button = new Gtk.ToggleButton ();
            terminal_button.halign = Gtk.Align.END;
            terminal_button.image = new Gtk.Image.from_icon_name ("utilities-terminal-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            terminal_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

            action_area.add (terminal_button);

            terminal_button.toggled.connect (() => {
                if (terminal_button.active) {
                    content_stack.visible_child = terminal_output;
                } else {
                    content_stack.visible_child = label_area;
                }
            });
        }

        content_area.attach (content_stack, 0, 0, 1, 1);

        var restart_button = new Gtk.Button.with_label (_("Restart Device"));
        restart_button.clicked.connect (Utils.restart);

        if (upgrade) {
            var recovery_shell = new Gtk.Button.with_label (_("Try Recovery Shell"));
            recovery_shell.clicked.connect (() => {
                //  try {
                //      var child = new GLib.Subprocess.newv ({"gnome-terminal"}, GLib.SubprocessFlags.NONE);
                //      child.wait ();
                //  } catch (GLib.Error error) {
                //      critical ("could not execute gnome-terminal");
                //  }
            });

            var refresh_os = new Gtk.Button.with_label (_("Refresh OS"));
            refresh_os.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            refresh_os.clicked.connect (() => {
                ((Gtk.Stack) get_parent ()).visible_child = previous_view;
            });

            action_area.add (recovery_shell);
            action_area.add (refresh_os);
        } else {
            var demo_button = new Gtk.Button.with_label (_("Try Demo Mode"));
            demo_button.clicked.connect (Utils.demo_mode);

            var install_button = new Gtk.Button.with_label (_("Try Installing Again"));
            install_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            install_button.clicked.connect (() => {
                // This object is moved during install, so this will restore the default settings.
                var options = InstallOptions.get_default ();
                options.set_minimum_size (minimum_disk_size);
                options.get_options ();

                ((Gtk.Stack) get_parent ()).visible_child = previous_view;
            });

            action_area.add (demo_button);
            action_area.add (install_button);
        }

        show_all ();
    }

    private Gtk.Label new_description_label (string? txt) {
        var label = new Gtk.Label(txt);
        label.max_width_chars = 52;
        label.wrap = true;
        label.xalign = 0;
        label.use_markup = true;
        return label;
    }
}
