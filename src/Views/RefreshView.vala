// Copyright 2018-2021 System76
// SPDX-License-Identifier: GPL-3.0-or-later

public class RefreshView: OptionsView {
    public signal void choose_another();
    public signal void refresh();
    public signal void install();

    public string os { get; construct; }
    public string version { get; construct; }

    private Gtk.ToggleButton install_button;
    private Gtk.ToggleButton refresh_button;
    private Gtk.Button choose_another_button;

    public RefreshView(string os, string version) {
        Object (
            cancellable: true,
            artwork: "try-install",
            title: _("Install"),
            os: os,
            version: version
        );
    }

    construct {
        this.cancel_button.set_label(_("Back"));
        this.cancel_button.clicked.connect (() => {
            ((Gtk.Stack) get_parent ()).visible_child = this.previous_view;
        });

        this.description.set_text(_("%s is not installed and Refresh Install is unavailable.").printf(this.os));
        this.description.hide();

        string refresh_icon = "view-refresh";
        string refresh_title = _("Refresh Install");
        string refresh_description = _(
"Reinstall %s while keeping user accounts and files.
Applications will need to be reinstalled manually."
        ).printf(this.os);

        string install_icon = "system-os-installer";
        string install_title = _("Clean Install");
        string install_description = _(
"Erase everything and install a fresh copy of %s."
        ).printf(this.os);


        base.add_option(
            refresh_icon,
            refresh_title,
            refresh_description,
            (button) => {
                this.refresh_button = button;
                button.notify["active"].connect(() => {
                    if (button.active) {
                        this.next_button.sensitive = button.active;
                        install_button.active = false;
                    } else if (!install_button.active) {
                        this.next_button.sensitive = false;
                    }
                });
                button.key_press_event.connect((event) => handle_key_press(button, event));
            }
        );

        base.add_option(
            install_icon,
            install_title,
            install_description,
            (button) => {
                this.install_button = button;
                button.notify["active"].connect(() => {
                    if (button.active) {
                        this.next_button.sensitive = button.active;
                        refresh_button.active = false;
                    } else if (!refresh_button.active) {
                        this.next_button.sensitive = false;
                    }
                });
                button.key_press_event.connect((event) => handle_key_press(button, event));
            }
        );

        choose_another_button = new Gtk.Button.with_label(_("Select Another Partition"));
        choose_another_button.clicked.connect(() => this.choose_another());
        choose_another_button.set_no_show_all(true);
        choose_another_button.hide();

        var demo_button = new Gtk.Button.with_label (_("Try Demo Mode"));
        demo_button.clicked.connect (Utils.demo_mode);

        this.action_area.homogeneous = false;
        this.action_area.add(choose_another_button);
        this.action_area.add(demo_button);
        this.action_area.set_child_secondary(demo_button, true);
        this.action_area.set_child_non_homogeneous(demo_button, true);

        this.next_button.label = _("Next");
        this.next_button.get_style_context().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        this.next.connect(() => {
            if (refresh_button.active) {
                this.refresh();
            } else if (install_button.active) {
                this.install();
            }
        });

        this.show_all();
    }

    public void disable_refresh() {
        this.description.show();
        this.refresh_button.hide();
        this.title_label.set_text(_("Install"));
    }

    public void enable_refresh() {
        this.description.hide();
        this.refresh_button.show();
        this.title_label.set_text(_("Refresh or Install"));
    }

    public void search_failure(string why, bool can_select) {
        this.description.show();

        if (can_select) {
            this.choose_another_button.show();
        } else {
            this.choose_another_button.hide();
        }
    }

    private bool handle_key_press (Gtk.Button button, Gdk.EventKey event) {
        if (event.keyval == Gdk.Key.Return && next_button.sensitive) {
            next_button.clicked ();
            return true;
        } else if (event.keyval == Gdk.Key.Return && !next_button.sensitive) {
            return true;
        }
        return false;
    }

    public void reset() {
        base.select_first_option(false);
    }
}
