public class Username : Gtk.Box {
    private Gtk.Entry realname_entry;
    private Gtk.Entry username_entry;

    construct {
        var realname_label = new Granite.HeaderLabel (_("Real Name"));
        realname_entry = new Gtk.Entry ();
        realname_entry.grab_focus ();
        realname_entry.changed.connect (() => {
            username_entry.set_text (realname_entry.get_text());
        });

        var username_label = new Granite.HeaderLabel (_("User Name"));
        username_entry = new Gtk.Entry ();
        username_entry.set_max_length (31);
        username_entry.changed.connect (() => {
            username_entry.set_text (validate (username_entry.get_text ()));
        });

        this.add (realname_label);
        this.add (realname_entry);
        this.add (username_label);
        this.add (username_entry);
    }

    public string get_real_name () {
        return this.realname_entry.get_text ();
    }

    public string get_user_name () {
        return this.username_entry.get_text ();
    }

    public bool is_ready () {
        return this.realname_entry.get_text_length () != 0
            && this.username_entry.get_text_length () != 0;
    }

    private string validate (string input) {
        var text = new StringBuilder ();

        int i = 0;
        char c = input[i];
        while (c != '\0') {
            char cl = c.tolower ();
            if (cl.isalnum () || cl == '_') {
                text.append_c (cl);
            }
            i++;
            c = input[i];
        }

        return (owned) text.str;
    }
}