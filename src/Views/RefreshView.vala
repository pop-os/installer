public class Installer.RefreshView : AbstractInstallerView {
    public signal void next_step (bool retain_old);

    private Gtk.Grid refresh_list;
    private Gtk.Button next_button;
    private bool retain_old;
    public int noptions = 0;

    public RefreshView () {
        Object (cancellable: true);
    }

    construct {
        var title = new Gtk.Label (_("Select a refresh target"));
        title.max_width_chars = 60;
        title.valign = Gtk.Align.START;
        title.get_style_context ().add_class ("h2");

        var description = new Gtk.Label (_("Perform a new installation over an existing Linux install; retaining user accounts and files.
<b>Applications installed on the system will not be restored, and thus will require to be reinstalled.</b>"));
        description.use_markup = true;
        description.halign = Gtk.Align.CENTER;
        description.justify = Gtk.Justification.CENTER;

        refresh_list = new Gtk.Grid ();
        refresh_list.expand = true;

        var scrolled_list = new Gtk.ScrolledWindow (null, null);
        scrolled_list.vexpand = true;
        scrolled_list.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scrolled_list.add (refresh_list);

        var retain_label = new Gtk.Label (_("<b>Keep backup of original install at /linux.old</b>\nThis can be used to restore the system in the event that the installer fails."));
        retain_label.use_markup = true;

        next_button = new Gtk.Button.with_label (_("Refresh Install"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        next_button.sensitive = false;
        next_button.clicked.connect (() => next_step (retain_old));
        action_area.add (next_button);

        content_area.attach (title, 0, 0);
        content_area.attach (description, 0, 1);
        content_area.attach (scrolled_list, 0, 2);

        this.margin_start = 48;
        this.margin_end = 48;

        show_all ();
    }

    public void select_first_option () {
        var widget = refresh_list.get_children ().nth_data (0);
        if (widget is Gtk.Button) {
            ((Gtk.Button)widget).clicked ();
            next_button.clicked ();
        } else {
            stderr.printf ("select_first_option: not a button\n");
        }
        
    }

    public void update_options () {
        refresh_list.get_children ().foreach ((child) => child.destroy());
        noptions = 0;

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

            bool can_retain_old = option.can_retain_old ();

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
                    retain_old = can_retain_old;
                } else {
                    next_button.sensitive = false;
                    retain_old = false;
                }
            });

            refresh_list.add (button);
            noptions += 1;
        }

        refresh_list.show_all ();
    }
}
