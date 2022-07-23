using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/file_send_overlay.ui")]
public class FileSendOverlay : Gtk.EventBox {

    public signal void close();
    public signal void send_file(File file);

    [GtkChild] public unowned Button close_button;
    [GtkChild] public unowned Button send_button;
    [GtkChild] public unowned SizingBin file_widget_insert;
    [GtkChild] public unowned Label info_label;
    [GtkChild] public unowned CheckButton enable_scaling;

    private bool can_send = true;

    public File scale_file(File file, int MAX_WIDTH=1200, int MAX_HEIGHT=1200) throws GLib.Error {
            Gdk.Pixbuf pixbuf;
            try {
                pixbuf = new Gdk.Pixbuf.from_file_at_size(file.get_path(), MAX_WIDTH, MAX_HEIGHT);
            } catch (Error error) {
                warning("Can't load picture %s - %s", file.get_path(), error.message);
                return null;
            }

            pixbuf = pixbuf.apply_embedded_orientation();

            string newpath = Path.build_filename(Environment.get_user_cache_dir(),
                                "tosend.jpg");
            if (pixbuf.save(newpath, "jpeg", "quality", "90", null)) {
                return File.new_for_path (newpath);
            } else {
                return null;
            }
    }

    public FileSendOverlay(File file, FileInfo file_info) {
        close_button.clicked.connect(() => {
            this.close();
            this.destroy();
        });
        send_button.clicked.connect((source) => {
            if (enable_scaling.get_active()) {
                File scaledfile = scale_file(file);
                send_file(scaledfile);
            } else {
                send_file(file);
            }
            this.close();
            this.destroy();
        });

        load_file_widget.begin(file, file_info);

        this.realize.connect(() => {
            if (can_send) {
                send_button.grab_focus();
            } else {
                close_button.grab_focus();
            }
        });

        this.key_release_event.connect((event) => {
            if (event.keyval == Gdk.Key.Escape) {
                this.destroy();
            }
            return false;
        });
    }

    private async void load_file_widget(File file, FileInfo file_info) {
        string file_name = file_info.get_display_name();
        string mime_type = file_info.get_content_type();

        bool is_image = false;

        foreach (PixbufFormat pixbuf_format in Pixbuf.get_formats()) {
            foreach (string supported_mime_type in pixbuf_format.get_mime_types()) {
                if (supported_mime_type == mime_type) {
                    is_image = true;
                }
            }
        }

        Widget? widget = null;
        if (is_image) {
            FileImageWidget image_widget = new FileImageWidget() { visible=true };
            try {
                yield image_widget.load_from_file(file, file_name);
                widget = image_widget;
            } catch (Error e) { }
            enable_scaling.visible = true;
        }

        if (widget == null) {
            FileDefaultWidget default_widget = new FileDefaultWidget() { visible=true };
            default_widget.name_label.label = file_name;
            default_widget.update_file_info(mime_type, FileTransfer.State.COMPLETE, (long)file_info.get_size());
            widget = default_widget;
        }

        file_widget_insert.add(widget);
    }

    public void set_file_too_large() {
        info_label.label= _("The file exceeds the server's maximum upload size.");
        Util.force_error_color(info_label);
        send_button.sensitive = false;
        can_send = false;
    }
}

}
