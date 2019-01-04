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

        scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, new Gtk.Adjustment (0, 0, 0, 204800, 2048000, 2048000));
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

        our_os_size_label = new Gtk.Label ("");
        our_os_size_label.halign = Gtk.Align.END;
        our_os_size_label.hexpand = true;
        our_os_size_label.use_markup = true;

        other_os_label = new Gtk.Label (null);
        other_os_label.halign = Gtk.Align.START;
        other_os_label.hexpand = true;
        other_os_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        other_os_size_label = new Gtk.Label ("");
        other_os_size_label.halign = Gtk.Align.START;
        other_os_size_label.hexpand = true;
        other_os_size_label.use_markup = true;

        var scale_grid = new Gtk.Grid ();
        scale_grid.halign = Gtk.Align.FILL;

        scale_grid.attach (scale,               0, 0, 2);
        scale_grid.attach (other_os_label,      0, 1);
        scale_grid.attach (our_os_label,        1, 1);
        scale_grid.attach (other_os_size_label, 0, 2);
        scale_grid.attach (our_os_size_label,   1, 2);

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

        scale.value_changed.connect (() => {
            constrain_scale (scale);
            update_size_labels ((int) scale.get_value ());
        });

        scale.grab_focus ();
    }

    public void update_options (string? os, uint64 free, uint64 total) {
        title_label.label = _("Resize %s").printf (os == null ? _("Partition") : _("OS"));

        this.total = total;
        used = total - free;
        minimum = minimum_required > used ? minimum_required + 1 : used + 1;

        const int HEADROOM = 9765625;

        maximum = total - used - InstallOptions.SHRINK_OVERHEAD;
        true_minimum = minimum + HEADROOM > maximum ? minimum : minimum + HEADROOM;

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
        var scale_value = scale.get_value ();
        if (scale_value < true_minimum) {
            scale.set_value (true_minimum);
        } else if (scale_value > maximum) {
            scale.set_value (maximum);
        }
    }

    private void update_size_labels (uint64 our_os_size) {
        uint64 other_os_size = total - our_os_size;

        our_os_size_label.label = _("""%s <span alpha="67%">(%s Free)</span>""".printf (
            GLib.format_size (our_os_size * 512),
            GLib.format_size ((our_os_size - minimum) * 512)
        ));

        other_os_size_label.label = _("""%s <span alpha="67%">(%s Free)</span>""".printf (
            GLib.format_size (other_os_size * 512),
            GLib.format_size ((other_os_size - used) * 512)
        ));
    }
}
