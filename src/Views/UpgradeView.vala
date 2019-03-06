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

        var label = new Gtk.Label (_("Upgrade release"));
        label.max_width_chars = 60;
        label.valign = Gtk.Align.START;
        label.get_style_context ().add_class ("h2");

        desc_label = new Gtk.Label (_("Performing upgrade to the next release."));
        desc_label.hexpand = true;
        desc_label.max_width_chars = 60;
        desc_label.wrap = true;

        bar = new Gtk.ProgressBar ();
        bar.text = "Upgrade in process";
        bar.show_text = true;
        bar.pulse_step = 0.05;

        var progress = new Gtk.Grid ();
        progress.halign = Gtk.Align.CENTER;
        progress.valign = Gtk.Align.CENTER;
        progress.orientation = Gtk.Orientation.VERTICAL;
        progress.vexpand = true;
        progress.row_spacing = 6;
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
                tag = Distinst.UpgradeTag.PROGRESS,
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
        switch (event.tag) {
            case Distinst.UpgradeTag.ATTEMPTING_REPAIR:
                desc_label.label = _("Attempting to repair the install");
                break;
            case Distinst.UpgradeTag.ATTEMPTING_UPGRADE:
                desc_label.label = _("Attempting to upgrade the install");
                break;
            case Distinst.UpgradeTag.DPKG_INFO:
                bar.text = _("dpkg-info: %s").printf (Utils.string_from_utf8 (event.message));
                break;
            case Distinst.UpgradeTag.DPKG_ERR:
                bar.text = _("dpkg-err: %s").printf (Utils.string_from_utf8 (event.message));
                break;
            case Distinst.UpgradeTag.UPGRADE_INFO:
                bar.text = _("apt-info: %s").printf (Utils.string_from_utf8 (event.message));
                break;
            case Distinst.UpgradeTag.UPGRADE_ERR:
                bar.text = _("apt-err: %s").printf (Utils.string_from_utf8 (event.message));
                break;
            case Distinst.UpgradeTag.PROGRESS:
                bar.fraction = (double) event.percent / 100;
                break;
            case Distinst.UpgradeTag.RESUMING_UPGRADE:
                bar.text = _("Recovered from upgrade failure: resuming upgrade attempt.");
                break;
        }
    }

    private bool attempt_repair () {
        return false;
    }
}


