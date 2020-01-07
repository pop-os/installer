/**
 * This view is for selecting a location to install alongside an existing operationg system.
 *
 * Possible install options on this view are:
 *
 * - Shrinking the largest existing partition on a disk, if possible.
 * - Installing to the largest unused region on a disk, if possible.
 */
public class AlongsideView: OptionsView {
    public signal void next_step (bool use_scale, string? os, uint64 free, uint64 total);

    // Whether to use the resize view for choosing a size or not.
    public bool set_scale = false;
    // The number of free sectors that the selected install option has.
    public uint64 selected_free = 0;
    // The number of total sectors that the option has.
    public uint64 selected_total = 0;
    // The OS that is installed to, or may have ownership of, the option.
    public string? selected_os;

    // Possible labels that the next button will have, depending on which option is selected.
    private string NEXT_LABEL[5];

    public AlongsideView () {
        Object (
            cancellable: true,
            artwork: "disks",
            title: _("Install Alongside Another OS")
        );
    }

    construct {
        NEXT_LABEL = new string[5] {
            _("Install"),
            _("Resize Partition"),
            _("Resize OS"),
            _("Install Alongside"),
            _("Erase and Install"),
        };

        next_button.label = NEXT_LABEL[3];
        next.connect (() => next_step (set_scale, selected_os, selected_free, selected_total));
        show_all ();
    }

    // Clears existing options in the view, and creates new installation options.
    public void update_options () {
        base.clear_options ();

        var options = InstallOptions.get_default ();

        add_alongside_options ();

        if (options.get_options ().has_erase_options ()) {
            add_erase_options ();
        }

        base.options.show_all ();
        base.select_first_option ();
    }

    private void add_alongside_options () {
        var install_options = InstallOptions.get_default ();
        unowned string? install_device = install_options.get_install_device_path ();

        foreach (var option in install_options.get_options ().get_alongside_options ()) {
            var device = Utils.string_from_utf8 (option.get_device ());

            if (install_device != null && install_device == device) {
                debug ("skipping %s because it is on the install device\n", device);
                continue;
            }

            string? os = Utils.string_from_utf8 (option.get_os ());
            os = os == "none" ? null : os;

            var free = option.get_sectors_free ();
            var total = option.get_sectors_total ();
            var partition = option.get_partition ();
            var partition_path = Utils.string_from_utf8 (option.get_path ());
            string logo = Utils.get_distribution_logo_from_alongside (option);

            string label;
            string details;
            if (partition == -1) {
                label = _("Unused space on %s").printf (device);
                details = _("%.1f GiB available").printf ((double) free / SECTORS_AS_GIB);
            } else {
                label = _("%s on %s").printf (os == null ? _("Partition") : os, device);
                details = _("Shrink %s (%.1f GiB free)")
                    .printf (
                        partition_path,
                        (double) free / SECTORS_AS_GIB
                    );
            }

            base.add_option (logo, label, details, (button) => {
                unowned string next_label;
                if (partition == -1) {
                    next_label = NEXT_LABEL[0];
                } else if (os == null) {
                    next_label = NEXT_LABEL[1];
                } else {
                    next_label = NEXT_LABEL[2];
                }

                button.key_press_event.connect ((event) => handle_key_press (button, event));
                button.notify["active"].connect (() => {
                    if (button.active) {
                        base.options.get_children ().foreach ((child) => {
                            if (child is Gtk.ToggleButton) {
                                ((Gtk.ToggleButton)child).active = child == button;
                            }
                        });

                        install_options.selected_option = new Distinst.InstallOption () {
                            tag = Distinst.InstallOptionVariant.ALONGSIDE,
                            option = (void*) option,
                            encrypt_pass = null,
                            sectors = (partition == -1) ? 0 : free - 1
                        };

                        set_scale = partition != -1;
                        selected_os = os;
                        selected_free = free;
                        selected_total = total;
                        next_button.label = next_label;
                        next_button.sensitive = true;
                    } else {
                        next_button.label = NEXT_LABEL[3];
                        next_button.sensitive = false;
                    }
                });
            });
        }
    }

    private void add_erase_options () {
        var install_options = InstallOptions.get_default ();
        unowned Distinst.InstallOptions options = install_options.get_updated_options ();
        unowned string? install_device = install_options.get_install_device_path ();

        foreach (unowned Distinst.EraseOption disk in options.get_erase_options ()) {
            string device_path = Utils.string_from_utf8 (disk.get_device_path ());

            if (install_device != null && install_device == device_path && !install_options.has_recovery ()) {
                continue;
            }

            string logo = Utils.string_from_utf8 (disk.get_linux_icon ());
            string label = Utils.string_from_utf8 (disk.get_model ());
            string details = "Erase %s %.1f GiB".printf (
                Utils.string_from_utf8 (disk.get_device_path ()),
                (double) disk.get_sectors () / SECTORS_AS_GIB
            );

            base.add_option(logo, label, details, (button) => {
                if (disk.meets_requirements ()) {
                    button.key_press_event.connect ((event) => handle_key_press (button, event));
                    button.notify["active"].connect (() => {
                        if (button.active) {
                            base.options.get_children ().foreach ((child) => {
                                if (child is Gtk.ToggleButton) {
                                    ((Gtk.ToggleButton)child).active = child == button;
                                }
                            });

                            if (install_options.has_recovery ()) {
                                var recovery = options.get_recovery_option ();

                                install_options.selected_option = new Distinst.InstallOption () {
                                    tag = Distinst.InstallOptionVariant.RECOVERY,
                                    option = (void*) recovery,
                                    encrypt_pass = null
                                };
                            } else {
                                install_options.selected_option = new Distinst.InstallOption () {
                                    tag = Distinst.InstallOptionVariant.ERASE,
                                    option = (void*) disk,
                                    encrypt_pass = null
                                };
                            }

                            set_scale = false;
                            next_button.label = NEXT_LABEL[4];
                            next_button.sensitive = true;
                        } else {
                            next_button.sensitive = false;
                            next_button.label = NEXT_LABEL[3];
                        }
                    });
                } else {
                    button.sensitive = false;
                }
            });
        }

        base.sort_sensitive ();
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
