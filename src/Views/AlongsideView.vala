public class AlongsideView: OptionsView {
    public signal void next_step (string path, string os, uint64 bytes);
    public uint64 minimum_size { get; construct; }

    public AlongsideView (uint64 minimum_size) {
        Object (
            cancellable: true,
            artwork: "disks",
            title: _("Install Alongside Another OS"),
            minimum_size: minimum_size
        );
    }

    construct {
        base.next_button.label = _("Select OS to Install Alongside");
        base.next.connect (() => next_step ("", "", 0));
        this.show_all ();
    }

    public void update_options () {
        this.clear_options ();
        var install_options = InstallOptions.get_default ();
        foreach (var option in install_options.get_options ().get_alongside_options ()) {
            var os = Utils.string_from_utf8 (option.get_os ());
            var device = Utils.string_from_utf8 (option.get_device ());
            var free = option.get_sectors_free () * 512;
            var total = option.get_sectors_total () * 512;
            var partition = option.get_partition ();
            var path = Utils.string_from_utf8 (option.get_path ());

            this.add_option (
                "drive-harddisk-solidstate",
                _("%s on %s").printf (os, device),
                (partition == -1)
                    ? _("Unused Space (%s free)").printf (GLib.format_size (free))
                    : _("Shrink %s (%s of %s free)").printf (path, GLib.format_size (free), GLib.format_size (total)),
                (button) => {
                    if (button.active) {
                        this.options.get_children ().foreach ((child) => {
                            ((Gtk.ToggleButton)child).active = child == button;
                        });

                        install_options.selected_option = new Distinst.InstallOption () {
                            tag = Distinst.InstallOptionVariant.ALONGSIDE,
                            option = (void*) option,
                            encrypt_pass = null,
                            sectors = 0
                        };

                        //  this.set_scale_ranges (minimum_size / 2048, free);
                        next_button.sensitive = true;
                    } else {
                        next_button.sensitive = false;
                    }
                }
            );
        }

        this.options.show_all ();
    }
}