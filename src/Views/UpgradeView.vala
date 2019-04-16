public class Installer.UpgradeView : AbstractInstallerView {
    public signal void on_success ();
    public signal void on_error ();

    private Gtk.Label desc_label;
    private Gtk.ProgressBar bar;

    construct {
        stderr.printf ("constructing upgrade view\n");
        var artwork = new Gtk.Grid ();
        artwork.get_style_context ().add_class ("disks");
        artwork.get_style_context ().add_class ("artwork");
        artwork.vexpand = true;

        var label = new Gtk.Label (_("Upgrade OS"));
        label.max_width_chars = 60;
        label.valign = Gtk.Align.START;
        label.get_style_context ().add_class ("h2");

        desc_label = new Gtk.Label (_("Performing upgrade to the next release."));
        desc_label.hexpand = true;
        desc_label.max_width_chars = 60;
        desc_label.wrap = true;
        desc_label.get_style_context ().add_class ("h3");

        bar = new Gtk.ProgressBar ();
        bar.text = _("Initializing upgrade process");
        bar.show_text = true;
        bar.pulse_step = 0.05;
        bar.ellipsize = Pango.EllipsizeMode.END;
        bar.hexpand = true;

        var progress = new Gtk.Grid ();
        progress.valign = Gtk.Align.CENTER;
        progress.orientation = Gtk.Orientation.VERTICAL;
        progress.vexpand = true;
        progress.hexpand = true;
        progress.row_spacing = 24;
        progress.attach (desc_label, 0, 0, 1, 1);
        progress.attach (bar, 0, 1, 1, 1);

        content_area.attach (artwork, 0, 0, 1, 1);
        content_area.attach (label, 0, 1, 1, 1);
        content_area.attach (progress, 1, 0, 1, 2);
        show_all ();
    }

    /**
     * Attempts to chroot and upgrade an existing system in the recovery environment.
     *
     * This implementation spawns a background thread to perform the request.
     **/
    public void upgrade (Distinst.Disks disks, Distinst.RecoveryOption recovery) {
        new Thread<void*> (null, () => {
            int result = Distinst.upgrade (
                disks,
                recovery,
                upgrade_callback,
                attempt_repair
            );

            // Ensure that a progress of 100 is always given at the end.
            upgrade_callback (Distinst.UpgradeEvent () {
                tag = Distinst.UpgradeTag.PACKAGE_PROGRESS,
                percent = 100
            });

            Idle.add (() => {
                if (0 == result) {
                    on_success ();
                } else {
                    on_error ();
                }

                return Source.REMOVE;
            });

            return null;
        });
    }

    private void upgrade_callback (Distinst.UpgradeEvent event) {
        string? desc = null;
        string? bar_text = null;

        switch (event.tag) {
            case Distinst.UpgradeTag.PACKAGE_PROGRESS:
                Idle.add (() => {
                    bar.fraction = (double) event.percent / 100;;
                    return Source.REMOVE;
                });
                return;
            case Distinst.UpgradeTag.ATTEMPTING_REPAIR:
                desc = _("An error occurred while upgrading the system. Attempting to repair the issue. Do not reboot the system, and keep it plugged in.");
                bar_text = _("Attempting repair of upgrade");
                break;
            case Distinst.UpgradeTag.ATTEMPTING_UPGRADE:
                desc = _("System is being upgraded. This process may take a while. Do not reboot the system, and keep it plugged in.");
                bar_text = _("Attempting upgrade");
                break;
            case Distinst.UpgradeTag.RESUMING_UPGRADE:
                desc = _("Repairs were succssful. The upgrade process is now resuming.  Do not reboot the system, and keep it plugged in.");
                bar_text = _("Resuming attempt to upgrade");
                break;
        }

        if (desc != null) {
            Idle.add (() => {
                desc_label.label = desc;
                bar.text = bar_text;
                return Source.REMOVE;
            });
        }
    }

    private string from_message (uint8[] message) {
        int line_index = message.length;
        for (int index = 0; index < message.length; index++) {
            if (message[index] == '\n') {
                line_index = index;
                break;
            }
        }

        return Utils.string_from_utf8 (message[0:line_index]);
    }

    private bool attempt_repair () {
        return false;
    }
}


