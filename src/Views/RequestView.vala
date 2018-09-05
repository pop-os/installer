public class RequestView : AbstractInstallerView {
    private int received = 0;
    private Gtk.Label title;
    private Gtk.Label question;

    construct {
        title = new Gtk.Label (null);
        title.hexpand = true;
        title.halign = Gtk.Align.CENTER;
        title.valign = Gtk.Align.START;
        title.get_style_context ().add_class ("h2");

        question = new Gtk.Label (null);
        question.justify = Gtk.Justification.CENTER;
        question.use_markup = true;
        question.hexpand = true;

        var no = new Gtk.Button.with_mnemonic (_("_No"));
        no.halign = Gtk.Align.END;
        no.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        no.clicked.connect (() => received = 1);

        var yes = new Gtk.Button.with_mnemonic (_("_Yes"));
        yes.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        yes.halign = Gtk.Align.START;
        yes.clicked.connect (() => received = 2);

        content_area.valign = Gtk.Align.CENTER;
        content_area.attach (title,    0, 0, 2, 1);
        content_area.attach (question, 0, 1, 2, 1);
        content_area.attach (no,       0, 2);
        content_area.attach (yes,      1, 2);
    }

    public void set_question (string title, string question) {
        this.title.label = title;
        this.question.label = question;
    }

    public int recv () {
        while (received == 0) {
            Thread.usleep (100);
        }

        int answer = received;
        received = 0;
        return answer;
    }
}