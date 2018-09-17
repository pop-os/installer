public delegate void CreateOptions (ref int noptions, Gtk.Grid option_list);

public class Installer.OptionSelectView : AbstractInstallerView {
    private Gtk.Stack content_stack;
    private Gtk.Grid option_list;
    private Gtk.Grid main_content;
    public Gtk.Button back_button;
    public Gtk.Button next_button;
    public int noptions = 0;
    public string title { get; construct; }
    public string? description { get; construct; }
    public string button_desc { get; construct; }
    public signal void next ();
    public signal void back ();

    public OptionSelectView (string button_desc, string title, string description) {
        Object (
            cancellable: true,
            description: description,
            title: title,
            button_desc: button_desc
        );
    }

    construct {
        var title = new Gtk.Label (this.title);
        title.max_width_chars = 60;
        title.valign = Gtk.Align.START;
        title.get_style_context ().add_class ("h2");

        option_list = new Gtk.Grid ();
        option_list.expand = true;

        var scrolled_list = new Gtk.ScrolledWindow (null, null);
        scrolled_list.vexpand = true;
        scrolled_list.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scrolled_list.add (option_list);

        next_button = new Gtk.Button.with_label (this.button_desc);
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        next_button.sensitive = false;
        next_button.clicked.connect (() => next ());

        main_content = new Gtk.Grid ();
        main_content.column_spacing = 12;
        main_content.row_spacing = 12;
        main_content.attach (title, 0, 0);

        if (description != null) {
            var description = new Gtk.Label (this.description);
            description.use_markup = true;
            description.halign = Gtk.Align.CENTER;
            description.justify = Gtk.Justification.CENTER;
            description.visible = false;
            main_content.attach (description, 0, 1);
        }

        main_content.attach (scrolled_list, 0, 2);

        content_stack = new Gtk.Stack ();
        content_stack.add (main_content);
        content_stack.visible_child = main_content;

        content_area.add (content_stack);

        this.margin_start = 48;
        this.margin_end = 48;

        back_button = new Gtk.Button.with_label (_("Back"));
        action_area.add (back_button);
        action_area.add (next_button);

        back_button.clicked.connect (() => {
            if (this.is_main ()) {
                back_button.visible = false;
                cancel_button.visible = true;
                cancel_button.clicked ();
            } else {
                this.switch_to_main ();
            }
        });
    }

    public void select_first_option () {
        var widget = option_list.get_children ().nth_data (0);
        if (widget is Gtk.Button) {
            ((Gtk.Button)widget).clicked ();
            next_button.clicked ();
        } else {
            stderr.printf ("select_first_option: not a button\n");
        }
    }

    public void update_options (CreateOptions func) {
        option_list.get_children ().foreach ((child) => child.destroy());
        noptions = 0;

        func (ref noptions, option_list);
        option_list.show_all ();
    }

    public bool is_main () {
        return content_stack.visible_child == main_content;
    }

    public void switch_to_main () {
        content_stack.visible_child = main_content;
        var ctx = this.next_button.get_style_context ();
        ctx.add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        ctx.remove_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
    }

    public void switch_to (Gtk.Widget widget) {
        foreach (var child in content_stack.get_children ()) {
            if (child == widget) {
                content_stack.visible_child = widget;
                return;
            }
        }

        content_stack.add (widget);
        content_stack.visible_child = widget;
    }
}

public class Installer.AlongsideView : OptionSelectView {
    public signal void next_step ();
    public uint64 minimum_size { get; construct; }
    private Gtk.Grid sector_selector;
    private Gtk.Scale scale;
    private Gtk.Entry scale_entry;
    private uint64 scale_min;
    private Gtk.Label scale_min_label;
    private uint64 scale_max;
    private Gtk.Label scale_max_label;

    public AlongsideView (uint64 minimum_size) {
        Object (
            cancellable: true,
            minimum_size: minimum_size,
            button_desc: _("Install Alongside"),
            title: _("Select an OS to install alongside"),
            description: null
        );
    }

    construct {
        var title = new Gtk.Label (_("Select the amount of space to assign to the new install."));
        title.get_style_context ().add_class ("h2");
        title.halign = Gtk.Align.CENTER;

        scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 1, 1);
        scale.set_value_pos (Gtk.PositionType.BOTTOM);
        scale.hexpand = true;

        scale_entry = new Gtk.Entry ();
        scale_entry.input_purpose = Gtk.InputPurpose.DIGITS;
        scale_entry.halign = Gtk.Align.START;

        scale_min_label = new Gtk.Label (null);
        scale_min_label.halign = Gtk.Align.START;
        scale_min_label.use_markup = true;
        
        scale_max_label = new Gtk.Label (null);
        scale_max_label.halign = Gtk.Align.END;
        scale_max_label.use_markup = true;

        var scale_grid = new Gtk.Grid ();
        scale_grid.row_spacing = 12;
        scale_grid.column_spacing = 12;
        scale_grid.hexpand = true;
        scale_grid.vexpand = true;
        scale_grid.valign = Gtk.Align.CENTER;
        scale_grid.attach (scale_entry, 0, 0);
        scale_grid.attach (scale_min_label, 1, 0);
        scale_grid.attach (scale, 2, 0);
        scale_grid.attach (scale_max_label, 3, 0);

        sector_selector = new Gtk.Grid ();
        sector_selector.attach (title, 0, 0);
        sector_selector.attach (scale_grid, 0, 1);
        sector_selector.show_all ();

        scale_entry.changed.connect (() => {
            uint64 new_value = 0;
            scale_entry.get_text ().scanf ("%lldd", &new_value);
            scale.set_value ((double) new_value);
        });

        scale.value_changed.connect (() => {
            scale_entry.set_text ("%lld".printf (this.get_scale_value ()));
        });

        scale.format_value.connect ((mebibytes) => {
            return "%lld MiB".printf ((uint64) mebibytes);
        });

        this.next.connect (() => {
            if (this.is_main ()) {
                this.switch_to ((Gtk.Grid) sector_selector);
                base.next_button.label = this.button_desc;
                var ctx = base.next_button.get_style_context ();
                ctx.add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                ctx.remove_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                return;
            }

            unowned Distinst.InstallOption? selected = InstallOptions.get_default ().get_selected_option();
            if (selected == null) {
                critical (_("selected option not found in alongside view"));
                return;
            }

            selected.sectors = this.get_scale_value () * 2048;
            this.next_step ();
        });

        this.show_all ();
    }

    private uint64 get_scale_value () {
        return (uint64) scale.get_value ();
    }

    private void set_scale_ranges (uint64 min, uint64 max) {
        scale.set_range ((double) min, (double) max);
        scale_min = min;
        scale_min_label.label = "<b>MiB</b>";
        scale_max = max;
        scale_max_label.label = "<b>%lld MiB</b>".printf (max);
        scale_entry.set_text ("%lld".printf (min));
    }

    public new void update_options () {
        base.update_options ((ref noptions, option_list) => {
            var install_options = InstallOptions.get_default ();
            foreach (var option in install_options.get_options ().get_alongside_options ()) {
                var os = Utils.string_from_utf8 (option.get_os ());
                var device = Utils.string_from_utf8 (option.get_device ());
                var free = option.get_sectors_free () / 2048;
                var partition = option.get_partition ();

                var label = new Gtk.Label (
                    partition == -1
                        ? _("Alongside %s on %s (unused region: %lld MiB free)").printf (os, device, free)
                        : _("Alongside %s on %s (shrink part%d: %lld MiB free)").printf (os, device, partition, free)
                );
                label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

                var button = new Gtk.ToggleButton ();
                button.hexpand = true;
                button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
                button.add(label);
                button.clicked.connect (() => {
                    if (button.active) {
                        option_list.get_children ().foreach ((child) => {
                            ((Gtk.ToggleButton)child).active = child == button;
                        });

                        install_options.selected_option = new Distinst.InstallOption () {
                            tag = Distinst.InstallOptionVariant.ALONGSIDE,
                            option = (void*) option,
                            encrypt_pass = null,
                            sectors = 0
                        };

                        this.set_scale_ranges (minimum_size / 2048, free);
                        next_button.sensitive = true;
                    } else {
                        next_button.sensitive = false;
                    }
                });

                option_list.attach (button, 0, noptions);
                noptions += 1;
            }
        });
    }
}

public class Installer.RefreshView: OptionSelectView {
    public signal void next_step (bool retain_old);
    private bool retain_old;

    public RefreshView () {
        Object (
            cancellable: true,
            button_desc: _("Refresh Install"),
            title: _("Select a refresh target"),
            description: _("Perform a new installation over an existing Linux install; retaining user accounts and files.
<b>Applications installed on the system will not be restored, and thus will require to be reinstalled.</b>")
        );
    }

    construct {
        base.next.connect (() => next_step (retain_old));
        this.show_all ();
    }

    public new void update_options () {
        base.update_options ((ref noptions, option_list) => {
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
                button.hexpand = true;
                button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
                button.add(label);
                button.clicked.connect (() => {
                    if (button.active) {
                        option_list.get_children ().foreach ((child) => {
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

                option_list.attach (button, 0, noptions);
                noptions += 1;
            }
        });
    }
}
