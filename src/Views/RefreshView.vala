public class Installer.RefreshView : AbstractInstallerView {
    public signal void next_step ();

    private Gtk.Grid refresh_list;
    private Gtk.Button next_button;

    public RefreshView () {
        Object (cancellable: true);
    }

    construct {
        var title = new Gtk.Label (_("Select a refresh target"));
        title.max_width_chars = 60;
        title.valign = Gtk.Align.START;
        title.get_style_context ().add_class ("h2");

        refresh_list = new Gtk.Grid ();
        refresh_list.expand = true;

        var scrolled_list = new Gtk.ScrolledWindow (null, null);
        scrolled_list.vexpand = true;
        scrolled_list.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scrolled_list.add (refresh_list);

        next_button = new Gtk.Button.with_label (_("Refresh Install"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        next_button.sensitive = false;
        next_button.clicked.connect (() => next_step ());
        action_area.add (next_button);

        content_area.attach (title, 0, 0);
        content_area.attach (scrolled_list, 0, 1);

        this.margin_start = 48;
        this.margin_end = 48;

        show_all ();
    }

    public void update_options () {
        refresh_list.get_children ().foreach ((child) => child.destroy());

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
            var label = new Gtk.Label (_("%s (%s) at %s").printf (os, version, device_path));
            label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            var button = new Gtk.ToggleButton ();
            button.margin = 6;
            button.hexpand = true;
            button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            button.add(label);
            button.clicked.connect (() => {
                if (button.active) {
                    refresh_list.get_children ().foreach ((child) => {
                        ((Gtk.ToggleButton)child).active = child == button;
                    });

                    install_options.selected_option = new Distinst.InstallOption () {
                        tag = Distinst.InstallOptionVariant.REFRESH,
                        option = (void*) option,
                        encrypt_pass = null
                    };

                    next_button.sensitive = true;
                } else {

                    next_button.sensitive = false;
                }
            });

            refresh_list.add (button);
        }

        refresh_list.show_all ();
    }
}
