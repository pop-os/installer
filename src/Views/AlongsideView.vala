/**
 * This view is for selecting a location to install alongside an existing operationg system.
 * 
 * Possible install options on this view are:
 * 
 * - Shrinking the largest existing partition on a disk, if possible.
 * - Installing to the largest unused region on a disk, if possible.
 */
public class AlongsideView: OptionsView {
    public signal void next_step (bool use_scale, string os, uint64 free, uint64 total);

    // Whether to use the resize view for choosing a size or not.
    public bool set_scale = false;
    // The number of free sectors that the selected install option has.
    public uint64 selected_free = 0;
    // The number of total sectors that the option has.
    public uint64 selected_total = 0;
    // The OS that is installed to, or may have ownership of, the option.
    public string selected_os = "";

    // Possible labels that the next button will have, depending on which option is selected.
    private string NEXT_LABEL[3];

    public AlongsideView () {
        Object (
            cancellable: true,
            artwork: "disks",
            title: _("Install Alongside Another OS")
        );
    }

    construct {
        NEXT_LABEL = new string[3] {
            _("Install"),
            _("Resize OS"),
            _("Install Alongside")
        };

        next_button.label = NEXT_LABEL[2];
        next.connect (() => next_step (set_scale, selected_os, selected_free, selected_total));
        show_all ();
    }

    // Clears existing options in the view, and creates new installation options.
    public void update_options () {
        base.clear_options ();
        var install_options = InstallOptions.get_default ();
        foreach (var option in install_options.get_options ().get_alongside_options ()) {
            var os = Utils.string_from_utf8 (option.get_os ());
            var device = Utils.string_from_utf8 (option.get_device ());
            var free = option.get_sectors_free ();
            var total = option.get_sectors_total ();
            var partition = option.get_partition ();
            var path = Utils.string_from_utf8 (option.get_path ());

            string logo = Utils.get_distribution_logo_from_alongside (option);

            string label;
            string details;
            if (partition == -1) {
                label = _("Unused space on %s").printf (device);
                details = _("%s available").printf (GLib.format_size (free * 512));
            } else {
                label = _("%s on %s").printf (os, device);
                details = _("Shrink %s (%s free)")
                    .printf (
                        path,
                        GLib.format_size (free * 512)
                    );
            }

            base.add_option (logo, label, details, (button) => {
                unowned string next_label = NEXT_LABEL[partition == -1 ? 0 : 1];
                button.key_press_event.connect ((event) => handle_key_press (button, event));
                button.notify["active"].connect (() => {
                    if (button.active) {
                        base.options.get_children ().foreach ((child) => {
                            ((Gtk.ToggleButton)child).active = child == button;
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
                        next_button.label = NEXT_LABEL[2];
                        next_button.sensitive = false;
                    }
                });
            });
        }

        base.options.show_all ();
        base.select_first_option ();
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