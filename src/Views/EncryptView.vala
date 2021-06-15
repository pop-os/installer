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
 */

public class EncryptView : AbstractInstallerView {
    public signal void next_step ();

    public Gtk.CheckButton reuse_password;

    private ErrorRevealer confirm_entry_revealer;
    private ErrorRevealer pw_error_revealer;
    private Gtk.Button next_button;
    private ValidatedEntry confirm_entry;
    private ValidatedEntry pw_entry;
    private Gtk.LevelBar pw_levelbar;
    private Gtk.Stack stack;
    private Gtk.Grid choice_grid;

    public EncryptView () {
        Object (
            cancellable: false,
            title: _("Drive Encryption"),
            artwork: "encrypt"
        );
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("drive-harddisk", Gtk.IconSize.DIALOG);

        var overlay_image = new Gtk.Image.from_icon_name ("security-high", Gtk.IconSize.DND) {
            halign = Gtk.Align.END,
            valign = Gtk.Align.END
        };

        var overlay = new Gtk.Overlay () {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.END,
            width_request = 60
        };

        overlay.add (image);
        overlay.add_overlay (overlay_image);

        var protect_image = new Gtk.Image.from_icon_name ("security-high-symbolic", Gtk.IconSize.LARGE_TOOLBAR);

        var protect_label = new Gtk.Label (_("Encrypting this drive protects data from being read by others with physical access to this device.")) {
            max_width_chars = 52,
            wrap = true,
            xalign = 0
        };

        var performance_image = new Gtk.Image.from_icon_name ("utilities-system-monitor-symbolic", Gtk.IconSize.LARGE_TOOLBAR);

        var performance_label = new Gtk.Label (_("Drive encryption may minimally impact read and write speed when performing intense tasks.")) {
            max_width_chars = 52,
            wrap = true,
            xalign = 0
        };

        var restart_image = new Gtk.Image.from_icon_name ("system-restart-symbolic", Gtk.IconSize.LARGE_TOOLBAR);

        var restart_label = new Gtk.Label (_("The encryption password will be required each time you turn on this device or restart.")) {
            max_width_chars = 52,
            wrap = true,
            xalign = 0
        };

        reuse_password = new Gtk.CheckButton.with_label("Encryption password is the same as user account password.") {
            margin_top = 36
        };

        reuse_password.toggled.connect(() => {
            next_button.label = reuse_password.active ? _("Encrypt") : _("Set Password");
        });

        choice_grid = new Gtk.Grid ();
        choice_grid.orientation = Gtk.Orientation.VERTICAL;
        choice_grid.column_spacing = 12;
        choice_grid.row_spacing = 32;
        choice_grid.attach (protect_image, 0, 0, 1, 1);
        choice_grid.attach (protect_label, 1, 0, 1, 1);
        choice_grid.attach (performance_image, 0, 1, 1, 1);
        choice_grid.attach (performance_label, 1, 1, 1, 1);
        choice_grid.attach (restart_image, 0, 2, 1, 1);
        choice_grid.attach (restart_label, 1, 2, 1, 1);
        choice_grid.attach (reuse_password, 0, 3, 2, 1);

        var description = new Gtk.Label (_("If you forget the encryption password, <b>you will not be able to recover data.</b> This is a unique password for this device, not the password for your user account."));
        description.margin_bottom = 12;
        description.max_width_chars = 60;
        description.use_markup = true;
        description.wrap = true;
        description.xalign = 0;

        var pw_label = new Granite.HeaderLabel (_("Choose Encryption Password"));

        pw_error_revealer = new ErrorRevealer (".");
        pw_error_revealer.label_widget.get_style_context ().add_class (Gtk.STYLE_CLASS_WARNING);

        pw_entry = new ValidatedEntry ();
        pw_entry.visibility = false;

        pw_levelbar = new Gtk.LevelBar ();
        pw_levelbar = new Gtk.LevelBar.for_interval (0.0, 100.0);
        pw_levelbar.set_mode (Gtk.LevelBarMode.CONTINUOUS);
        pw_levelbar.add_offset_value ("low", 50.0);
        pw_levelbar.add_offset_value ("high", 75.0);
        pw_levelbar.add_offset_value ("middle", 75.0);

        var confirm_label = new Granite.HeaderLabel (_("Confirm Password"));

        confirm_entry = new ValidatedEntry ();
        confirm_entry.sensitive = false;
        confirm_entry.visibility = false;

        confirm_entry_revealer = new ErrorRevealer (".");
        confirm_entry_revealer.label_widget.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);

        var password_grid = new Gtk.Grid ();
        password_grid.orientation = Gtk.Orientation.VERTICAL;
        password_grid.row_spacing = 3;
        password_grid.add (description);
        password_grid.add (pw_label);
        password_grid.add (pw_entry);
        password_grid.add (pw_levelbar);
        password_grid.add (pw_error_revealer);
        password_grid.add (confirm_label);
        password_grid.add (confirm_entry);
        password_grid.add (confirm_entry_revealer);

        stack = new Gtk.Stack ();
        stack.homogeneous = false;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        stack.valign = Gtk.Align.CENTER;
        stack.vexpand = true;
        stack.add (choice_grid);
        stack.add (password_grid);

        content_area.attach (stack, 1, 0, 1, 2);

        var no_encrypt_button = new Gtk.Button.with_label (_("Don't Encrypt"));
        var back_button = new Gtk.Button.with_label (_("Back"));

        next_button = new Gtk.Button.with_label (_("Set Password"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        next_button.can_default = true;

        action_area.add (no_encrypt_button);
        action_area.add (back_button);
        action_area.add (next_button);

        next_button.grab_focus ();

        no_encrypt_button.clicked.connect (() => {
            next_step ();
        });

        back_button.clicked.connect (() => {
            stack.visible_child = choice_grid;
            next_button.label = _("Set Password");
            next_button.sensitive = true;
            back_button.hide ();
        });

        next_button.clicked.connect (() => {
            var config = Configuration.get_default ();
            bool reuse = reuse_password.active;
            if (!reuse && stack.visible_child == choice_grid) {
                stack.visible_child = password_grid;
                pw_entry.grab_focus ();
                next_button.label = _("Set Password");
                back_button.show ();
                update_next_button ();
            } else if (reuse) {
                config.encryption_password = config.password;
                next_step ();
            } else if (stack.visible_child == password_grid) {
                config.encryption_password = pw_entry.text;
                next_step ();
            }
        });

        pw_entry.changed.connect (() => {
            pw_entry.is_valid = check_password ();
            confirm_entry.is_valid = confirm_password ();
            update_next_button ();
        });

        confirm_entry.changed.connect (() => {
            confirm_entry.is_valid = confirm_password ();
            update_next_button ();
        });

        show_all ();
        back_button.hide ();
    }

    public void reset () {
        stack.visible_child = choice_grid;
        reuse_password.active = false;
        pw_entry.text = null;
        confirm_entry.text = null;

    }

    private bool check_password () {
        if (pw_entry.text == "") {
            confirm_entry.text = "";
            confirm_entry.sensitive = false;

            pw_levelbar.value = 0;

            pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
            pw_error_revealer.reveal_child = false;
        } else {
            confirm_entry.sensitive = true;

            var pwquality = new PasswordQuality.Settings ();
            void* error;
            var quality = pwquality.check (pw_entry.text, null, null, out error);

            if (quality >= 0) {
                pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-completed-symbolic");
                pw_error_revealer.reveal_child = false;

                pw_levelbar.value = quality;
            } else {
                pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-warning-symbolic");

                pw_error_revealer.reveal_child = true;
                pw_error_revealer.label = ((PasswordQuality.Error) quality).to_string (error);

                pw_levelbar.value = 0;
            }
            return true;
        }

        return false;
    }

    private bool confirm_password () {
        if (confirm_entry.text != "") {
            if (pw_entry.text != confirm_entry.text) {
                confirm_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
                confirm_entry_revealer.label = _("Passwords do not match");
                confirm_entry_revealer.reveal_child = true;
            } else {
                confirm_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-completed-symbolic");
                confirm_entry_revealer.reveal_child = false;
                return true;
            }
        } else {
            confirm_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
            confirm_entry_revealer.reveal_child = false;
        }

        return false;
    }

    private void update_next_button () {
        if (reuse_password.active || (pw_entry.is_valid && confirm_entry.is_valid)) {
            next_button.sensitive = true;
            next_button.has_default = true;
        } else {
            next_button.sensitive = false;
        }
    }
}
