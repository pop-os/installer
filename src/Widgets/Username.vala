const int UT_NAMESIZE = 32;
const int MAX_NAME_LEN = UT_NAMESIZE - 1;

public class Username : Gtk.Box {
    public signal void changed ();
    public new signal void activate ();

    private Gtk.Entry realname_entry;
    private Gtk.Entry username_entry;

    construct {
        var realname_label = new Granite.HeaderLabel (_("Full Name"));
        realname_entry = new Gtk.Entry ();
        realname_entry.grab_focus ();
        realname_entry.activate.connect (() => activate());
        realname_entry.changed.connect (() => {
            string realname = validate_realname (realname_entry.get_text ());
            realname_entry.set_text (realname);
            username_entry.set_text (validate (realname));
        });

        var username_label = new Granite.HeaderLabel (_("User Name"));
        username_entry = new Gtk.Entry ();
        username_entry.set_max_length (31);
        username_entry.activate.connect(() => activate());
        username_entry.changed.connect (() => {
            username_entry.set_text (validate (username_entry.get_text ()));
            changed ();
        });

        add (realname_label);
        add (realname_entry);
        add (username_label);
        add (username_entry);
        add (new Gtk.Label(_("This will be used to name your home folder.")) {
            margin_top = 4,
            xalign = (float) 0.0
        });
    }

    public string get_real_name () {
        return realname_entry.get_text ();
    }

    public string get_user_name () {
        return username_entry.get_text ();
    }

    public new void grab_focus () {
        realname_entry.grab_focus ();
    }

    public bool is_ready () {
        string username = username_entry.get_text ();
        return realname_entry.get_text_length () != 0
            && username_entry.get_text_length () != 0
            && str_contains_alpha(username)
            && !is_forbidden(username);
    }

    private string validate (string input) {
        var text = new StringBuilder ();

        for (int i = 0; i < input.length; i++) {
            char c = input[i];

            // The first char must be alphabetic.
            // The following may be alphanumeric, and '_', '.', or '-'.
            bool append = text.str.length == 0
                ? c.isalpha ()
                : c.isalnum () || c == '_' || c == '.' || c == '-';

            if (append) {
                text.append_c (c.tolower ());

                // Ensure that the validated string is no more than `MAX_NAME_LEN` in length.
                if (text.str.length == MAX_NAME_LEN) break;
            }
        }

        return (owned) text.str;
    }
}

// Strip any `:` from real names.
private string validate_realname(string input) {
    var text = new StringBuilder ();

    int i = 0;
    char c = input[i];

    while (c != '\0') {
        if (c != ':') {
            text.append_c (c);
        }

        i += 1;
        c = input[i];
    }

    return (owned) text.str;
}

// True if string contains alphabetic characters.
private bool str_contains_alpha(string input) {
    if (input.length == 0) {
        return false;
    }

    for (int i = 0; i < input.length; i++) {
        if (input[i].isalpha ()) {
            return true;
        }
    }

    return false;
}

// Forbidden usernames
const string[] FORBIDDEN = {
    "adm",
    "administrator",
    "lpadmin",
    "sbuild",
    "sudo",
    "libvirt",
    "docker"
};

// Check if a username is forbidden
private bool is_forbidden(string input) {
    for (int i = 0; i < FORBIDDEN.length; i++) {
        if (strcmp (FORBIDDEN[i], input) == 0) {
            return true;
        }
    }

    // Also check if username already exists
    if (Posix.getpwnam (input) != null) return true;

    return false;
}