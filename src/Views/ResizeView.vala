/*
 * Copyright (c) 2018 elementary, Inc. (https://elementary.io)
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
 */

public class ResizeView : AbstractInstallerView {
    private Gtk.SpinButton other_os_entry { get; set; }
    private Gtk.SpinButton our_os_entry { get; set; }

    private Gtk.Label our_os_size_label { get; set; }
    private Gtk.Label other_os_size_label { get; set; }
    private Gtk.Label other_os_label;
    private Gtk.Scale scale;

    public uint64 minimum_required { get; set; }
    private uint64 minimum;
    private uint64 true_minimum;
    private uint64 maximum;
    private uint64 used;
    private uint64 total;

    public signal void next_step ();


    const double STEPPING = 100 * 2 * 1024;

    public ResizeView (uint64 minimum_size) {
        Object (
            cancellable: true,
            minimum_required: minimum_size,
            artwork: "disks",
            title: ""
        );
    }

    construct {
        var secondary_label = new Gtk.Label (
            _("Each operating system needs space on your device. Drag the handle below to set how much space each operating system gets.")
        );
        secondary_label.max_width_chars = 60;
        secondary_label.wrap = true;
        secondary_label.xalign = 0;

        scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, new Gtk.Adjustment (0, 0, 0, STEPPING, STEPPING * 10, STEPPING * 100));
        scale.draw_value = false;
        scale.inverted = true;

        scale.show_fill_level = true;
        scale.get_style_context ().add_class (Granite.STYLE_CLASS_ACCENT);

        var our_os_label = new Gtk.Label (Utils.get_pretty_name ());
        our_os_label.halign = Gtk.Align.END;
        our_os_label.hexpand = true;

        var our_os_label_context = our_os_label.get_style_context ();
        our_os_label_context.add_class (Granite.STYLE_CLASS_H3_LABEL);
        our_os_label_context.add_class (Granite.STYLE_CLASS_ACCENT);

        our_os_size_label = new Gtk.Label (null);
        our_os_size_label.get_style_context().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        our_os_size_label.halign = Gtk.Align.END;
        our_os_size_label.use_markup = true;
        our_os_size_label.hexpand = true;

        other_os_label = new Gtk.Label (null);
        other_os_label.halign = Gtk.Align.START;
        other_os_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        other_os_size_label = new Gtk.Label ("");
        other_os_size_label.get_style_context().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        other_os_size_label.halign = Gtk.Align.START;
        other_os_size_label.hexpand = true;
        other_os_size_label.use_markup = true;

        var scale_grid = new Gtk.Grid ();
        scale_grid.halign = Gtk.Align.FILL;
        scale_grid.row_spacing = 6;

        Gtk.SpinButton our_entry;
        Gtk.SpinButton other_entry;

        scale_grid.attach (scale,          0, 0, 2, 1);
        scale_grid.attach (other_os_label, 0, 1);
        scale_grid.attach (our_os_label,   1, 1);
        scale_grid.attach (create_entry (out other_entry, Gtk.Align.START), 0, 2);
        scale_grid.attach (create_entry (out our_entry, Gtk.Align.END),    1, 2);
        scale_grid.attach (other_os_size_label, 0, 3);
        scale_grid.attach (our_os_size_label,   1, 3);

        other_os_entry = other_entry;
        our_os_entry = our_entry;

        var grid = new Gtk.Grid ();
        grid.row_spacing = 12;
        grid.valign = Gtk.Align.CENTER;

        grid.attach (secondary_label, 0, 0);
        grid.attach (scale_grid,      0, 1);

        content_area.attach (grid, 1, 0, 1, 2);

        var next_button = new Gtk.Button.with_label (_("Resize and Install"));
        next_button.can_default = true;
        next_button.has_default = true;
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        next_button.clicked.connect (() => {
            unowned Distinst.InstallOption? selected = InstallOptions.get_default ().get_selected_option();
            if (selected == null) {
                critical (_("selected option not found in alongside view"));
                return;
            }

            selected.sectors = (uint64) scale.get_value ();
            next_step ();
        });

        action_area.add (next_button);
        update_size_labels ((int) scale.get_value ());
        show_all ();

        bool open = true;
        scale.value_changed.connect (() => {
            if (open) {
                open = false;

                constrain_scale (scale);
                double our_size = scale.get_value ();
                other_os_entry.set_value (((double) total - our_size) / SECTORS_AS_GIB);
                our_os_entry.set_value (our_size / SECTORS_AS_GIB);

                open = true;
            }

            update_size_labels ((uint64) scale.get_value ());
        });

        our_os_entry.value_changed.connect(() => {
            if (open) {
                open = false;

                constrain_entry (our_os_entry, true_minimum, maximum);
                double our_size = our_os_entry.get_value ();
                other_os_entry.set_value (((double) total / SECTORS_AS_GIB) - our_size);
                scale.set_value (our_size * SECTORS_AS_GIB);

                open = true;
            }
        });

        other_os_entry.value_changed.connect(() => {
            if (open) {
                open = false;

                constrain_entry (other_os_entry, total - maximum, total - true_minimum);
                double other_size = other_os_entry.get_value ();
                our_os_entry.set_value (((double) total / SECTORS_AS_GIB) - other_size);
                scale.set_value ((double) total - (other_size * SECTORS_AS_GIB));

                open = true;
            }
        });

        scale.grab_focus ();
    }

    public void update_options (string? os, uint64 free, uint64 total) {
        title_label.label = _("Resize %s").printf (os == null ? _("Partition") : _("OS"));

        this.total = total;
        used = total - free;
        minimum = minimum_required + (2 * 1024);

        const int HEADROOM = 5 * 2 * 1024 * 1024;

        maximum = total - used - InstallOptions.SHRINK_OVERHEAD;
        true_minimum = minimum + HEADROOM > maximum ? minimum : minimum + HEADROOM;

        double max_range = (double) total / SECTORS_AS_GIB;
        our_os_entry.set_range (0.0, max_range);
        our_os_entry.set_increments (0.5, 5);

        other_os_entry.set_range (0.0, max_range);
        other_os_entry.set_increments (0.5, 5);

        var quarter = total / 4;
        var half = quarter * 2;
        var three_quarters = quarter * 3;

        scale.clear_marks ();
        scale.set_range (0, total);
        scale.add_mark (minimum, Gtk.PositionType.BOTTOM, _("Min"));

        if (quarter < maximum && quarter > minimum) {
            scale.add_mark (quarter, Gtk.PositionType.BOTTOM, "25%");
        }

        if (half < maximum && half > minimum) {
            scale.add_mark (half, Gtk.PositionType.BOTTOM, "50%");
        }

        if (three_quarters < maximum && three_quarters > minimum) {
            scale.add_mark (three_quarters, Gtk.PositionType.BOTTOM, "75%");
        }

        scale.add_mark (maximum, Gtk.PositionType.BOTTOM, _("Max"));
        scale.fill_level = total - used;
        scale.set_value (total / 2);

        other_os_label.label = os == null ? _("Partition") : os;
    }

    private void constrain_scale (Gtk.Scale scale) {
        double scale_value = scale.get_value ();
        if (scale_value < true_minimum) {
            scale.set_value (true_minimum);
        } else if (scale_value > maximum) {
            scale.set_value (maximum);
        }
    }

    private void constrain_entry (Gtk.SpinButton entry, uint64 minimum, uint64 maximum) {
        double entry_value = entry.get_value ();
        double min = minimum / SECTORS_AS_GIB;
        double max = maximum / SECTORS_AS_GIB;

        if (entry_value < min) {
            entry.set_value (min);
        } else if (entry_value > max) {
            entry.set_value (max);
        }
    }

    private void update_size_labels (uint64 our_os_size) {
        uint64 other_os_size = total - our_os_size;

        our_os_size_label.label = _("""%s Free""".printf (
            "%.1f GiB".printf ((double) (our_os_size - minimum) / SECTORS_AS_GIB)
        ));

        other_os_size_label.label = _("""%s Free""".printf (
           "%.1f GiB".printf ((double) (other_os_size - used) / SECTORS_AS_GIB)
        ));
    }
}

Gtk.Box create_entry (out Gtk.SpinButton entry, Gtk.Align alignment) {
    entry = new Gtk.SpinButton (null, 1.0, 1);

    var label = new Gtk.Label (_("GiB"));

    var container = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
    container.add (entry);
    container.add (label);
    container.halign = alignment;

    return container;
}
