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

public class Installer.TryInstallView : AbstractInstallerView {
    public signal void alongside_step ();
    public signal void custom_step ();
    public signal void next_step ();
    public signal void refresh_step ();

    private Gtk.Button next_button;

    construct {
        var type_grid = new Gtk.Grid ();
        type_grid.halign = Gtk.Align.CENTER;
        type_grid.valign = Gtk.Align.CENTER;
        type_grid.orientation = Gtk.Orientation.VERTICAL;
        type_grid.vexpand = true;
        type_grid.row_spacing = 6;

        var type_scrolled = new Gtk.ScrolledWindow (null, null);
        type_scrolled.vexpand = true;
        type_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
#if GTK_3_22
        type_scrolled.propagate_natural_height = true;
#endif
        type_scrolled.add (type_grid);

        var type_image = new Gtk.Image.from_icon_name ("system-os-installer", Gtk.IconSize.DIALOG);
        type_image.valign = Gtk.Align.START;

        var type_label = new Gtk.Label (_("Try or Install"));
        type_label.hexpand = true;
        type_label.get_style_context ().add_class ("h2");

        var artwork = new Gtk.Grid ();
        artwork.get_style_context ().add_class ("try-install");
        artwork.get_style_context ().add_class ("artwork");
        artwork.vexpand = true;

        // TODO: Once we support more options, give an example here
        // ("More options, such as…") if there's space…
        var decrypt_description = new Gtk.Label (_("More options may be available after unlocking encrypted storage"));

        var decrypt_button = new Gtk.Button.with_label (_("Unlock Encrypted Storage…"));

        var decrypt_infobar = new Gtk.InfoBar ();
        decrypt_infobar.message_type = Gtk.MessageType.INFO;

        var infobar_action_area = decrypt_infobar.get_action_area () as Gtk.Container;
        infobar_action_area.add (decrypt_button);

        var infobar_content_area = decrypt_infobar.get_content_area ();
        infobar_content_area.add (decrypt_description);

        var grid = new Gtk.Grid ();
        grid.margin = 12;
        grid.valign = Gtk.Align.FILL;
        grid.column_homogeneous = true;
        grid.attach (artwork,       0, 1, 1, 2);
        grid.attach (type_label,    1, 1);
        grid.attach (type_scrolled, 1, 2);
        
        content_area.margin = 0;
        content_area.valign = Gtk.Align.FILL;
        content_area.column_homogeneous = true;
        content_area.attach (decrypt_infobar, 0, 0); 
        content_area.attach (grid, 0, 1);

        var back_button = new Gtk.Button.with_label (_("Back"));
        back_button.clicked.connect (() => ((Gtk.Stack) get_parent ()).visible_child = previous_view);

        key_press_event.connect ((event) => {
            switch (event.keyval) {
                case Gdk.Key.Left:
                    if (event.state != Gdk.ModifierType.MOD1_MASK) {
                        break;
                    }
                case Gdk.Key.Escape:
                    back_button.clicked ();
                    return true;
            }

            return false;
        });

        next_button = new Gtk.Button.with_label (_("Next"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        next_button.sensitive = false;

        var demo_button = new InstallTypeButton (
            _("Try Demo Mode"),
            "desktop",
            _("Changes will not be saved, and data from your previous OS will be unchanged. Performance and features may not reflect the installed experience.")
        );

        var clean_install_button = new InstallTypeButton (
            _("Clean Install"),
            "gcleaner",
            _("Erase everything and install a fresh copy of %s.").printf (Utils.get_pretty_name ())
        );

        var refresh_install_button = new InstallTypeButton (
            _("Refresh Install"),
            "gcleaner",
            _("Reinstall while keeping user accounts and files. Applications will need to be reinstalled manually.")
        );

        var alongside_button = new InstallTypeButton (
            _("Install Alongside OS"),
            "gcleaner",
            _("Install alongside another operating system.")
        );

        var custom_button = new InstallTypeButton (
            _("Custom (Advanced)"),
            "disk-utility",
            _("Create, resize, or otherwise manage partitions manually. This method may lead to data loss.")
        );

        action_area.add (back_button);
        action_area.add (next_button);

        type_grid.add (demo_button);
        type_grid.add (clean_install_button);
        type_grid.add (refresh_install_button);
        type_grid.add (alongside_button);
        type_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        type_grid.add (custom_button);

        ulong next_button_handler_id;

        demo_button.key_press_event.connect ((event) => handle_key_press (demo_button, event));
        demo_button.clicked.connect (() => {
            if (demo_button.active) {
                type_grid.get_children ().foreach ((child) => {
                    if (child is Gtk.ToggleButton) {
                        ((Gtk.ToggleButton)child).active = child == demo_button;
                    }
                });

                next_button.label = demo_button.type_title;
                next_button.sensitive = true;
                next_button_handler_id = next_button.clicked.connect (Utils.demo_mode);
            } else {
                next_button.sensitive = false;
                next_button.label = _("Next");
                next_button.disconnect (next_button_handler_id);
            }
        });

        clean_install_button.key_press_event.connect ((event) => handle_key_press (clean_install_button, event));
        clean_install_button.clicked.connect (() => {
            if (clean_install_button.active) {
                type_grid.get_children ().foreach ((child) => {
                    if (child is Gtk.ToggleButton) {
                        ((Gtk.ToggleButton)child).active = child == clean_install_button;
                    }
                });

                next_button.label = clean_install_button.type_title;
                next_button.sensitive = true;
                next_button_handler_id = next_button.clicked.connect (() => next_step ());
            } else {
                next_button.sensitive = false;
                next_button.label = _("Next");
                next_button.disconnect (next_button_handler_id);
            }
        });

        refresh_install_button.key_press_event.connect ((event) => handle_key_press (refresh_install_button, event));
        refresh_install_button.clicked.connect (() => {
            if (refresh_install_button.active) {
                type_grid.get_children ().foreach ((child) => {
                    if (child is Gtk.ToggleButton) {
                        ((Gtk.ToggleButton)child).active = child == refresh_install_button;
                    }
                });

                next_button.label = refresh_install_button.type_title;
                next_button.sensitive = true;
                next_button_handler_id = next_button.clicked.connect (() => refresh_step ());
            } else {
                next_button.sensitive = false;
                next_button.label = _("Next");
                next_button.disconnect (next_button_handler_id);
            }
        });

        alongside_button.key_press_event.connect ((event) => handle_key_press (alongside_button, event));
        alongside_button.clicked.connect (() => {
            if (alongside_button.active) {
                type_grid.get_children ().foreach ((child) => {
                    if (child is Gtk.ToggleButton) {
                        ((Gtk.ToggleButton)child).active = child == alongside_button;
                    }
                });

                next_button.label = alongside_button.type_title;
                next_button.sensitive = true;
                next_button_handler_id = next_button.clicked.connect (() => alongside_step ());
            } else {
                next_button.sensitive = false;
                next_button.label = _("Next");
                next_button.disconnect (next_button_handler_id);
            }
        });

        custom_button.key_press_event.connect ((event) => handle_key_press (custom_button, event));
        custom_button.clicked.connect (() => {
            if (custom_button.active) {
                type_grid.get_children ().foreach ((child) => {
                    if (child is Gtk.ToggleButton) {
                        ((Gtk.ToggleButton)child).active = child == custom_button;
                    }
                });

                next_button.label = custom_button.type_title;
                next_button.sensitive = true;
                next_button_handler_id = next_button.clicked.connect (() => custom_step ());
            } else {
                next_button.sensitive = false;
                next_button.label = _("Next");
                next_button.disconnect (next_button_handler_id);
            }
        });

        var options = InstallOptions.get_default ();

        decrypt_button.clicked.connect (() => {
            var decrypt_dialog = new DecryptDialog ();
            decrypt_dialog.update_list ();
            decrypt_dialog.transient_for = (Gtk.Window) get_toplevel ();
            decrypt_dialog.run ();

            // The dialog will respond with a delete event once it has decrypted a LUKS partition.
            decrypt_dialog.response.connect ((resp) => {
                if (resp == Gtk.ResponseType.DELETE_EVENT) {
                    refresh_install_button.visible = options.get_options ().has_refresh_options ();
                    alongside_button.visible = options.get_options ().has_alongside_options ();

                    var nlocked = 0;
                    foreach (unowned Distinst.Partition partition in options.borrow_disks ().get_encrypted_partitions ()) {
                        string path = Utils.string_from_utf8 (partition.get_device_path ());
                        if (! options.is_unlocked (path)) {
                            nlocked += 1;
                        }
                    }

                    decrypt_infobar.visible = nlocked != 0;
                }
            });
        });

        show_all ();

        clean_install_button.grab_focus ();

        // Hide the info bar if no encrypted partitions are found.
        decrypt_infobar.visible = options.contains_luks ();

        refresh_install_button.visible = options.get_options ().has_refresh_options ();
        alongside_button.visible = options.get_options ().has_alongside_options ();
    }

    private bool handle_key_press (Gtk.Button button, Gdk.EventKey event) {
        if (event.keyval == Gdk.Key.Return) {
            button.clicked ();
            next_button.clicked ();
            return true;
        }

        return false;
    }
}
