public class UserView : AbstractInstallerView {
    public signal void next_step ();

    private ErrorRevealer confirm_entry_revealer;
    private ErrorRevealer pw_error_revealer;
    private Gtk.Button next_button;
    private Gtk.Entry name_entry;
    private Gtk.Entry user_entry;
    private ValidatedEntry confirm_entry;
    private ValidatedEntry pw_entry;
    private Gtk.LevelBar pw_levelbar;

    construct {
        var artwork = new Gtk.Grid ();
        artwork.get_style_context ().add_class ("encrypt");
        artwork.get_style_context ().add_class ("artwork");
        artwork.vexpand = true;

        var title_label = new Gtk.Label (_("Create User Account"));
        title_label.get_style_context ().add_class ("h2");
        title_label.valign = Gtk.Align.START;

        var description = new Gtk.Label (_("Define a username and password for the new account to create on the system."));
        description.margin_bottom = 12;
        description.max_width_chars = 60;
        description.use_markup = true;
        description.wrap = true;
        description.xalign = 0;

        var name_label = new Granite.HeaderLabel (_("Set Full Name"));

        name_entry = new Gtk.Entry ();
        name_entry.grab_focus ();

        var user_label = new Granite.HeaderLabel (_("Choose Username"));

        user_entry = new Gtk.Entry ();

        var pw_label = new Granite.HeaderLabel (_("Choose Account Password"));

        pw_entry = new ValidatedEntry ();
        pw_entry.visibility = false;

        pw_levelbar = new Gtk.LevelBar ();
        pw_levelbar = new Gtk.LevelBar.for_interval (0.0, 100.0);
        pw_levelbar.set_mode (Gtk.LevelBarMode.CONTINUOUS);
        pw_levelbar.add_offset_value ("low", 50.0);
        pw_levelbar.add_offset_value ("high", 75.0);
        pw_levelbar.add_offset_value ("middle", 75.0);

        pw_error_revealer = new ErrorRevealer (".");
        pw_error_revealer.label_widget.get_style_context ().add_class (Gtk.STYLE_CLASS_WARNING);

        var confirm_label = new Granite.HeaderLabel (_("Confirm Password"));

        confirm_entry = new ValidatedEntry ();
        confirm_entry.sensitive = false;
        confirm_entry.visibility = false;

        confirm_entry_revealer = new ErrorRevealer (".");
        confirm_entry_revealer.label_widget.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);

        pw_entry.changed.connect (() => {
            pw_entry.is_valid = check_password ();
            confirm_entry.is_valid = confirm_password ();
            update_next_button ();
        });

        confirm_entry.changed.connect (() => {
            confirm_entry.is_valid = confirm_password ();
            update_next_button ();
        });

        var password_grid = new Gtk.Grid ();
        password_grid.valign = Gtk.Orientation.CENTER;
        password_grid.orientation = Gtk.Orientation.VERTICAL;
        password_grid.row_spacing = 3;
        password_grid.add (description);
        password_grid.add (name_label);
        password_grid.add (name_entry);
        password_grid.add (user_label);
        password_grid.add (user_entry);
        password_grid.add (pw_label);
        password_grid.add (pw_entry);
        password_grid.add (pw_levelbar);
        password_grid.add (pw_error_revealer);
        password_grid.add (confirm_label);
        password_grid.add (confirm_entry);
        password_grid.add (confirm_entry_revealer);

        content_area.attach (artwork, 0, 0, 1, 1);
        content_area.attach (title_label, 0, 1, 1, 1);
        content_area.attach (password_grid, 1, 0, 1, 2);

        next_button = new Gtk.Button.with_label (_("Create Account"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        next_button.can_default = true;
        next_button.clicked.connect (() => {
            var config = Configuration.get_default ();
            config.username = user_entry.get_text ();
            config.fullname = name_entry.get_text ();
            config.password = pw_entry.get_text ();
            next_step ();
        });

        action_area.add (next_button);

        show_all ();
    }

    private bool check_password () {
        if (pw_entry.text == "") {
            confirm_entry.text = "";
            confirm_entry.sensitive = false;

            pw_levelbar.value = 0;

            pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
            pw_error_revealer.reveal_child = false;
        } else {
            confirm_entry.sensitive = true;

            var pwquality = new PasswordQuality.Settings ();
            void* error;
            var quality = pwquality.check (pw_entry.text, null, null, out error);

            if (quality >= 0) {
                pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-completed-symbolic");
                pw_error_revealer.reveal_child = false;

                pw_levelbar.value = quality;
            } else {
                pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-warning-symbolic");

                pw_error_revealer.reveal_child = true;
                pw_error_revealer.label = ((PasswordQuality.Error) quality).to_string (error);

                pw_levelbar.value = 0;
            }
            return true;
        }

        return false;
    }

    private bool confirm_password () {
        if (confirm_entry.text != "") {
            if (pw_entry.text != confirm_entry.text) {
                confirm_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
                confirm_entry_revealer.label = _("Passwords do not match");
                confirm_entry_revealer.reveal_child = true;
            } else {
                confirm_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-completed-symbolic");
                confirm_entry_revealer.reveal_child = false;
                return true;
            }
        } else {
            confirm_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
            confirm_entry_revealer.reveal_child = false;
        }

        return false;
    }

    private void update_next_button () {
        bool enable = name_entry.get_text_length () != 0
            && user_entry.get_text_length () != 0
            && pw_entry.is_valid
            && confirm_entry.is_valid;

        if (enable) {
            next_button.sensitive = true;
            next_button.has_default = true;
        } else {
            next_button.sensitive = false;
        }
    }
}