public class RefreshView: OptionsView {
    public signal void next_step (bool retain_old);
    private bool retain_old;

    public RefreshView () {
        Object (
            cancellable: true,
            artwork: "disks",
            title: _("Refresh Install")
        );
    }

    construct {
        base.next_button.label = _("Refresh Install");
        base.next.connect (() => next_step (retain_old));
        this.show_all ();
    }

    public void update_options () {
        base.clear_options ();
        var install_options = InstallOptions.get_default ();
        unowned Distinst.Disks disks = install_options.borrow_disks ();
        foreach (var option in install_options.get_options ().get_refresh_options ()) {
            var os = Utils.string_from_utf8 (option.get_os_name ());
            var version = Utils.string_from_utf8 (option.get_os_version ());
            var uuid = Utils.string_from_utf8 (option.get_root_part ());

            unowned Distinst.Partition? partition = disks.get_partition_by_uuid (uuid);
            if (partition == null) {
                stderr.printf ("did not find partition with UUID \"%s\"\n", uuid);
                continue;
            }

            var device_path = Utils.string_from_utf8 (partition.get_device_path ());
            bool can_retain_old = option.can_retain_old ();

            this.add_option (
                // TODO: Replace this with the distribution's logo.
                "drive-harddisk-solidstate",
                _("%s (%s) at %s").printf (os, version, device_path),
                null,
                (button) => {
                    button.notify["active"].connect (() => {
                        if (button.active) {
                            this.options.get_children ().foreach ((child) => {
                                ((Gtk.ToggleButton)child).active = child == button;
                            });

                            install_options.selected_option = new Distinst.InstallOption () {
                                tag = Distinst.InstallOptionVariant.REFRESH,
                                option = (void*) option,
                                encrypt_pass = null
                            };

                            next_button.sensitive = true;
                            retain_old = can_retain_old;
                        } else {
                            next_button.sensitive = false;
                            retain_old = false;
                        }
                    });
                }
            );
        }

        this.options.show_all ();
    }
}
