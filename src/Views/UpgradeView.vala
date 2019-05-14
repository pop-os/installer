public class Installer.UpgradeView : AbstractInstallerView {
    public signal void on_success ();
    public signal void on_error ();

    private uint timeout_signal;

    /// Holds UI events generated from a background thread.
    private AsyncQueue<Object> queue = new AsyncQueue<Object> ();

    private string[] DESCS = {
        _("System is being upgraded. This process may take a while. Do not reboot the system, and keep it plugged in."),
        _("An error occurred while upgrading the system. Attempting to repair the issue. Do not reboot the system, and keep it plugged in."),
        _("Repairs were successful. The upgrade process is now resuming.  Do not reboot the system, and keep it plugged in.")
    };
    
    private string[] BARS = {
        _("Upgrading installation to the new release"),
        _("Problems found during upgrade -- repairing them"),
        _("Resuming upgrade of installation to the new release")
    };

    public UpgradeView () {
        Object (
            artwork: "disks",
            title: _("Upgrade OS")
        );
    }

    ~UpgradeView () {
        if (0 != timeout_signal) {
            Source.remove (timeout_signal);
        }
    }

    construct {
        var desc_label = new Gtk.Label (_("Performing upgrade to the next release."));
        desc_label.hexpand = true;
        desc_label.max_width_chars = 60;
        desc_label.wrap = true;
        desc_label.get_style_context ().add_class ("h3");

        var bar = new Gtk.ProgressBar ();
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

        content_area.attach (progress, 1, 0, 1, 2);
        show_all ();

        // Handle all signals from background threads as they are received.
        timeout_signal = Timeout.add (16, () => {
            Object? data = queue.try_pop ();
            if (null != data) {
                if (data is UpgradeViewLabelEvent) {
                    UpgradeViewLabelEvent labels = (UpgradeViewLabelEvent) data;
                    desc_label.label = DESCS[labels.index];
                    bar.text = BARS[labels.index];
                } else if (data is UpgradeViewProgressEvent) {
                    bar.fraction = ((UpgradeViewProgressEvent) data).fraction;
                } else if (data is UpgradeViewResult) {
                    if (0 == ((UpgradeViewResult) data).result) {
                        on_success ();
                    } else {
                        on_error ();
                    }
                }
            }

            return true;
        });
    }

    /// Attempts an upgrade of the installed system.
    public void upgrade (Distinst.Disks disks, Distinst.RecoveryOption recovery) {
        new Thread<void*> (null, () => {
            int result = Distinst.upgrade (disks, recovery, upgrade_callback);

            // Ensure that a progress of 100 is always given at the end.
            upgrade_callback (Distinst.UpgradeEvent () {
                tag = Distinst.UpgradeTag.PACKAGE_PROGRESS,
                percent = 100
            });

            queue.push ((Object) new UpgradeViewResult (result));
            return null;
        });
    }

    /// Re-attempts an upgrade after using the recovery shell.
    public void resume_upgrade (Distinst.Disks disks) {
        new Thread<void*> (null, () => {
            int result = Distinst.resume_upgrade (disks, upgrade_callback, attempt_repair);

            // Ensure that a progress of 100 is always given at the end.
            upgrade_callback (Distinst.UpgradeEvent () {
                tag = Distinst.UpgradeTag.PACKAGE_PROGRESS,
                percent = 100
            });

            queue.push ((Object) new UpgradeViewResult (result));
            return null;
        });
    }

    /// Provided as a callback to distinst to handle all upgrade events sent to the UI.
    private void upgrade_callback (Distinst.UpgradeEvent event) {
        int label = -1;

        switch (event.tag) {
            case Distinst.UpgradeTag.PACKAGE_PROGRESS:
                queue.push ((Object) new UpgradeViewProgressEvent ((double) event.percent / 100));
                return;
            case Distinst.UpgradeTag.ATTEMPTING_UPGRADE:
                label = 0;
                break;
            case Distinst.UpgradeTag.ATTEMPTING_REPAIR:
                label = 1;
                break;
            case Distinst.UpgradeTag.RESUMING_UPGRADE:
                label = 2;
                break;
        }

        if (-1 != label) {
            queue.push ((Object) new UpgradeViewLabelEvent (label));
        }
    }
}

/// Provided as a callback to distinst to open GNOME Terminal chroot'd to the upgrade target.
void attempt_repair (uint8[] target_path) {
    spawn_chrooted_terminal ("gnome-terminal", Utils.string_from_utf8 (target_path));
}

/// Spawns a terminal with a chroot'd session to the upgrade target.
void spawn_chrooted_terminal (string term, string target) {
    try {
        string args[] = {
            term, "--wait",
            "--",
            "systemd-nspawn",
            "--bind", "/dev",
            "--bind", "/sys",
            "--bind", "/proc",
            "--bind", "/dev/mapper/control",
            "--property=DeviceAllow=block-sd rw",
            "--property=DeviceAllow=block-devices-mapper rw",
            "-D", target, "bash", null
        };

        var child = new GLib.Subprocess.newv (args, GLib.SubprocessFlags.NONE);
        child.wait ();
    } catch (GLib.Error error) {
        critical (@"could not execute $term");
    }
}

class UpgradeViewLabelEvent: Object {
    public int index { get; set; }

    public UpgradeViewLabelEvent (int index) {
        Object (index: index);
    }
}

class UpgradeViewProgressEvent: Object {
    public double fraction { get; set; }

    public UpgradeViewProgressEvent (double fraction) {
        Object (fraction: fraction);
    }
}

class UpgradeViewResult: Object {
    public int result { get; set; }

    public UpgradeViewResult (int result) {
        Object (result: result);
    }
}