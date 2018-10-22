public class Installer.TimezoneView : AbstractInstallerView {
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

        var title = new Gtk.Label (_("Select a Timezone"));
        title.get_style_context ().add_class ("h2");
        title.valign = Gtk.Align.START;
        title.halign = Gtk.Align.CENTER;
        title.wrap = true;

        var artwork = new Gtk.Grid ();
        artwork.get_style_context ().add_class ("encrypt");
        artwork.get_style_context ().add_class ("artwork");
        artwork.vexpand = true;

        content_area.attach (artwork,  0, 0);
        content_area.attach (title,    0, 1);
        content_area.attach (variants, 1, 0, 1, 2);

        next_button = new Gtk.Button.with_label (_("Select"));
        next_button.sensitive = false;
        next_button.can_default = true;
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        next_button.clicked.connect (() => {
            var conf = Configuration.get_default ();
            conf.timezone = active_region;
            GLib.AtomicInt.set (ref conf.timezone_set, 1);
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
        next_button.has_default = true;
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
        this.variants.show_variants (_("Select Zone"), "<b>%s</b>".printf (zone_name));
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