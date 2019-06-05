// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2016-2017 elementary LLC. (https://elementary.io)
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
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Installer.MainWindow : Gtk.Dialog {
    private Gtk.Stack stack;

    private DecryptionView decryption_view = null;
    private DiskView disk_view = null;
    private EncryptView encrypt_view = null;
    private ErrorView error_view = null;
    private Installer.CheckView check_view = null;
    private KeyboardLayoutView keyboard_layout_view = null;
    private LanguageView language_view = null;
    private PartitioningView partitioning_view = null;
    private ProgressView progress_view = null;
    private RefreshView refresh_view = null;
    private SuccessView success_view = null;
    private TryInstallView try_install_view = null;
    private UpgradeView upgrade_view = null;

    private bool check_ignored = false;

    private uint64 minimum_disk_size;

    private DateTime? start_date = null;
    private DateTime? end_date = null;

    enum StartupOperation {
        REFRESH,
        UPGRADE
    }

    public MainWindow () {
        Object (
            deletable: false,
            height_request: 700,
            icon_name: "system-os-installer",
            resizable: true,
            width_request: 950,
            use_header_bar: 1
        );
    }

    construct {
        LogHelper.get_default ();

        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        get_content_area ().add (stack);
        get_style_context ().add_class ("os-installer");

        unowned InstallOptions options = InstallOptions.get_default ();
        unowned Distinst.RecoveryOption? recovery_option = options.get_options ().get_recovery_option ();
        StartupOperation operation;
        string? new_title = null;

        const uint64 DEFAULT_MINIMUM_SIZE = 5000000000;
        minimum_disk_size = Distinst.minimum_disk_size (DEFAULT_MINIMUM_SIZE / 512);

        options.set_minimum_size (minimum_disk_size);

        if (null != recovery_option) {
            if (recovery_option.get_upgrade_mode ()) {
                operation = StartupOperation.UPGRADE;
                new_title = _("Upgrading to %s").printf (Utils.get_pretty_name ());
            } else if (recovery_option.get_refresh_mode ()) {
                operation = StartupOperation.REFRESH;
                new_title = _("Refresh OS");
            }
        }

        weak Gtk.HeaderBar? headerbar = (Gtk.HeaderBar) get_header_bar ();
        if (new_title != null) {
            info ("%s", new_title);
            headerbar.title = new_title;
            startup_decrypt (recovery_option, operation);
        } else {
            headerbar.title = _("Install %s").printf (Utils.get_pretty_name ());
            language_view = new LanguageView ();
            stack.add (language_view);

            language_view.next_step.connect (() => load_keyboard_view ());
        }
    }

    private void exec_post_decrypt_operation (StartupOperation operation, Distinst.RecoveryOption recovery_option) {
        if (operation == StartupOperation.UPGRADE) {
            load_upgrade_view (recovery_option);
        } else {
            load_refresh_mode (recovery_option);
        }
    }

    private void load_refresh_mode (Distinst.RecoveryOption recovery_option) {
        unowned Configuration configuration = Configuration.get_default ();
        configuration.cached_locale = Utils.string_from_utf8 (recovery_option.get_language ());
        configuration.keyboard_layout = Utils.string_from_utf8 (recovery_option.get_kbd_layout ());
        unowned uint8[]? variant = recovery_option.get_kbd_variant ();
        if (null != variant) {
            configuration.keyboard_variant = Utils.string_from_utf8 (variant);
        }

        load_refresh_view ();
    }

    private void startup_decrypt (Distinst.RecoveryOption recovery_option, StartupOperation operation) {
        unowned uint8[] luks_uuid = recovery_option.get_luks_uuid ();
        unowned uint8[] root_uuid = recovery_option.get_root_uuid ();
        unowned Distinst.Disks disks = InstallOptions.get_default ().borrow_disks ();

        if (luks_uuid.length != 0 && (luks_uuid != root_uuid)) {
            decryption_view = new DecryptionView ();
            stack.add (decryption_view);
            decryption_view.decrypt.connect ((passphrase) => {
                if (null != passphrase) {
                    string uuid = Utils.string_from_utf8 (luks_uuid);
                    unowned Distinst.Partition? partition = disks.get_partition_by_uuid (uuid);

                    if (null == partition) {
                        debug ("unable to find partition after decryption");
                        return;
                    }

                    unowned uint8[] device_path = partition.get_device_path ();

                    int result = disks.decrypt_partition (
                        Utils.string_from_utf8 (device_path),
                        Distinst.LvmEncryption () {
                            physical_volume = "cryptdata",
                            password = passphrase
                        }
                    );

                    if (result == 0) {
                        stderr.printf ("rescanning\n");
                        InstallOptions.get_default ().rescan ();
                        exec_post_decrypt_operation (operation, recovery_option);
                    }
                }
            });
        } else {
            exec_post_decrypt_operation (operation, recovery_option);
        }
    }

    private void load_upgrade_view (Distinst.RecoveryOption option) {
        if (null == upgrade_view) {
            upgrade_view = new UpgradeView ();
            upgrade_view.on_success.connect (() => load_success_view (null, true));
            upgrade_view.on_error.connect (() => load_error_view (LogHelper.get_default ().buffer.text, true));

            stack.add (upgrade_view);
        }

        stack.visible_child = upgrade_view;
        unowned Distinst.Disks disks = InstallOptions.get_default ().borrow_disks ();
        upgrade_view.upgrade (disks, option);
    }

    /*
     * We need to load all the view after the language has being chosen and set.
     * We need to rebuild the view everytime the next button is clicked to reflect language changes.
     */

    private void load_keyboard_view () {
        if (keyboard_layout_view != null) {
            keyboard_layout_view.destroy ();
        }

        keyboard_layout_view = new KeyboardLayoutView ();
        keyboard_layout_view.previous_view = language_view;
        stack.add (keyboard_layout_view);
        stack.visible_child = keyboard_layout_view;

        keyboard_layout_view.next_step.connect (() => {
            var opts = InstallOptions.get_default ();
            if (!opts.is_oem_mode ()) {
                load_try_install_view ();
            } else {
                unowned Configuration config = Configuration.get_default ();
                unowned Distinst.InstallOptions options = opts.get_options ();
                var recovery = options.get_recovery_option ();

                var lang = Utils.string_from_utf8 (recovery.get_language ());
                var lang_parts = lang.split ("_", 2);
                config.lang = lang_parts[0];
                if (lang_parts.length >= 2) {
                    var country_parts = lang_parts[1].split (".", 2);
                    config.country = country_parts[0];
                }

                config.keyboard_layout = Utils.string_from_utf8 (recovery.get_kbd_layout ());

                var variant = recovery.get_kbd_variant ();
                if (null != variant) {
                    config.keyboard_variant = Utils.string_from_utf8 (variant);
                }

                InstallOptions.get_default ().selected_option = new Distinst.InstallOption () {
                    tag = Distinst.InstallOptionVariant.REFRESH,
                    option = (void*) recovery,
                    encrypt_pass = null
                };

                load_encrypt_view ();
            }
        });
    }

    private void load_try_install_view () {
        if (try_install_view != null) {
            try_install_view.destroy ();
        }

        try_install_view = new TryInstallView ();
        try_install_view.previous_view = keyboard_layout_view;
        stack.add (try_install_view);
        stack.visible_child = try_install_view;

        try_install_view.custom_step.connect (load_partitioning_view);
        try_install_view.next_step.connect (load_disk_view);
        try_install_view.refresh_step.connect (load_refresh_view);
    }

    private void load_refresh_view () {
        if (refresh_view == null) {
            refresh_view = new RefreshView ();
            refresh_view.previous_view = try_install_view;
            refresh_view.next_step.connect ((retain_old) => {
                Configuration.get_default ().retain_old = retain_old;
                load_progress_view ();
            });
            refresh_view.cancel.connect (() => {
                stack.visible_child = try_install_view;
            });
            stack.add (refresh_view);
        }

        stack.visible_child = refresh_view;
        refresh_view.update_options ();
    }

    private void set_check_view_visible (bool show) {
        if (show) {
            check_view.previous_view = stack.visible_child;
            stack.visible_child = check_view;
        } else if (check_view.previous_view != null) {
            stack.visible_child = check_view.previous_view;
            check_view.previous_view = null;
        }
    }

    private void load_check_view () {
        if (check_view != null) {
            check_view.destroy ();
        }

        check_view = new Installer.CheckView (minimum_disk_size);
        stack.add (check_view);

        check_view.status_changed.connect ((met_requirements) => {
            if (!check_ignored) {
                set_check_view_visible (!met_requirements);
            }
        });

        check_view.cancel.connect (() => {
            stack.visible_child = try_install_view;
            check_view.previous_view = null;
            check_view.destroy ();
        });

        check_view.next_step.connect (() => {
            check_ignored = true;
            set_check_view_visible (false);
        });

        set_check_view_visible (!check_ignored && !check_view.check_requirements ());
    }

    private void load_disk_view () {
        if (disk_view != null) {
            disk_view.destroy ();
        }

        disk_view = new DiskView ();
        disk_view.previous_view = try_install_view;
        stack.add (disk_view);
        stack.visible_child = disk_view;
        disk_view.load.begin (minimum_disk_size);

        disk_view.cancel.connect (() => {
            stack.visible_child = try_install_view;
        });

        disk_view.next_step.connect (() =>  load_encrypt_view ());

        load_check_view ();
    }

    private void load_partitioning_view () {
        if (partitioning_view != null) {
            partitioning_view.destroy ();
        }

        partitioning_view = new PartitioningView (minimum_disk_size);
        partitioning_view.previous_view = try_install_view;
        stack.add (partitioning_view);
        stack.visible_child = partitioning_view;

        partitioning_view.cancel.connect (() => {
            stack.visible_child = try_install_view;
        });

        partitioning_view.next_step.connect (() => {
            unowned Configuration config = Configuration.get_default ();
            config.luks = (owned) partitioning_view.luks;
            config.mounts = (owned) partitioning_view.mounts;
            load_progress_view ();
        });

        load_check_view ();
    }

    private void load_encrypt_view () {
        if (encrypt_view != null) {
            encrypt_view.destroy ();
        }

        encrypt_view = new EncryptView ();
        encrypt_view.previous_view = disk_view;
        stack.add (encrypt_view);
        stack.visible_child = encrypt_view;

        encrypt_view.next_step.connect (() => load_progress_view ());
    }

    private void load_progress_view () {
        check_ignored = true;

        if (progress_view != null) {
            progress_view.destroy ();
        }

        progress_view = new ProgressView ();
        stack.add (progress_view);
        stack.visible_child = progress_view;

        progress_view.on_success.connect (() => {
            load_success_view (progress_view.get_log (), false);
        });

        progress_view.on_error.connect (() => {
            load_error_view (progress_view.get_log (), false);
        });

        start_date = new DateTime.now_local ();
        end_date = null;

        if (progress_view.test_label != null) {
            progress_view.test_label.set_text (_("Test Mode") + " 0.00");
        }

        var time_source = GLib.Timeout.add (10, () => {
            end_date = new DateTime.now_local ();
            if (progress_view.test_label != null) {
                var time_span = end_date.difference (start_date);
                progress_view.test_label.set_text (_("Test Mode") + " %.2f".printf ((double) time_span / 1000000.0));
            }
            return GLib.Source.CONTINUE;
        });

        progress_view.on_success.connect (() => {
            end_date = new DateTime.now_local ();
            GLib.Source.remove (time_source);
        });

        progress_view.on_error.connect (() => {
            end_date = new DateTime.now_local ();
            GLib.Source.remove (time_source);
        });

        progress_view.start_installation ();
    }

    private void load_success_view (string? log, bool upgrade) {
        if (success_view != null) {
            success_view.destroy ();
        }

        success_view = new SuccessView (log, upgrade);
        stack.add (success_view);
        stack.visible_child = success_view;

        if (success_view.test_label != null && start_date != null && end_date != null) {
            var time_span = end_date.difference (start_date);
            success_view.test_label.set_text (_("Test Mode") + " %.2f".printf ((double) time_span / 1000000.0));
        }
    }

    private void load_error_view (string? log, bool upgrade) {
        if (error_view != null) {
            error_view.destroy ();
        }

        error_view = new ErrorView (log, minimum_disk_size, upgrade);
        error_view.previous_view = try_install_view;
        error_view.refresh_view.connect (load_refresh_view);
        error_view.recovery_shell.connect (() => {
            unowned Distinst.Disks disks = InstallOptions.get_default ().borrow_disks ();
            stack.visible_child = upgrade_view;
            upgrade_view.resume_upgrade (disks);
        });

        stack.add (error_view);
        stack.visible_child = error_view;
    }

    public override void close () {}
}
