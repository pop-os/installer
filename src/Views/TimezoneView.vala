public class Installer.TimezoneView : AbstractInstallerView {
    Gtk.Label select_label;
    Gtk.Stack select_stack;
    Gtk.Button next_button;
    Distinst.Timezones timezones;
    VariantWidget variants;
    unowned Distinst.Region? active_region;

    public signal void next_step ();

    construct {
        timezones = new Distinst.Timezones ();
        variants = new VariantWidget ();

        var zones = timezones.zones ();
        var zone = zones.next ();
        while (zone != null) {
            var zone_name = Utils.string_from_utf8 (zone.name ());
            var zone_row = new ZoneRow (zone_name);
            variants.main_listbox.add (zone_row);
            zone = zones.next ();
        }

        variants.main_listbox.select_row (variants.main_listbox.get_row_at_index (0));
        variants.main_listbox.row_activated.connect (row_activated);
        variants.variant_listbox.row_selected.connect (set_active_region);
        variants.key_press_event.connect ((event) => {
            switch (event.keyval) {
                case Gdk.Key.Return:
                    if (next_button.sensitive) {
                        next_button.clicked ();
                    }
                    return true;
                case Gdk.Key.Left:
                    if (event.state != Gdk.ModifierType.MOD1_MASK) {
                        break;
                    }
                case Gdk.Key.Escape:
                    variants.back_button.clicked ();
                    return true;
            }

            return false;
        });

        select_label = new Gtk.Label (_("Select a Timezone"));
        select_label.get_style_context ().add_class ("h2");
        select_label.valign = Gtk.Align.START;
        select_label.halign = Gtk.Align.START;
        select_label.wrap = true;

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.row_spacing = 12;
        grid.add (select_label);
        grid.add (this.variants);

        var artwork = new Gtk.Grid ();
        artwork.get_style_context ().add_class ("encrypt");
        artwork.get_style_context ().add_class ("artwork");
        artwork.vexpand = true;

        content_area.attach (artwork, 0, 0);
        content_area.attach (grid,    1, 0, 1, 2);

        next_button = new Gtk.Button.with_label (_("Select"));
        next_button.sensitive = false;
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        next_button.clicked.connect (() => {
            Configuration.get_default ().timezone = active_region;
            next_step ();
        });

        action_area.add (next_button);

        this.show_all ();
    }

    private void set_active_region (Gtk.ListBoxRow? row) {
        if (row == null) {
            active_region = null;
            return;
        }

        var region_row = (RegionRow) row;
        active_region = region_row.region;
    }

    private void row_activated (Gtk.ListBoxRow? row) {
        if (row == null) {
            return;
        }

        int nrow = row.get_index ();
        var zone = this.timezones.zones ().nth (nrow);
        if (zone == null) {
            stderr.printf ("no zone found at row %d\n", nrow);
            return;
        }

        variants.clear_variants ();
        var regions = zone.regions ();
        var region = regions.next ();
        while (region != null) {
            var region_name = Utils.string_from_utf8 (region.name ());
            this.variants.variant_listbox.add (new RegionRow (region, region_name));
            region = regions.next ();
        }

        var zone_name = Utils.string_from_utf8 (zone.name ());
        this.variants.variant_listbox.select_row (variants.variant_listbox.get_row_at_index (0));
        this.variants.show_variants (_("Select Region"), "<b>%s</b>".printf (zone_name));
        next_button.sensitive = true;
    }

    public class ZoneRow : Gtk.ListBoxRow {
        public ZoneRow (string name) {
            var label = new Gtk.Label (name);
            label.halign = Gtk.Align.START;
            add (label);
            this.show_all ();
        }
    }

    public class RegionRow : Gtk.ListBoxRow {
        public unowned Distinst.Region region;

        public RegionRow (Distinst.Region region, string name) {
            this.region = region;
            var label = new Gtk.Label (name);
            label.halign = Gtk.Align.START;
            add (label);
            this.show_all ();
        }
    }
}