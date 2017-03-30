using Gdk;
using Gee;
using Gtk;

using Xmpp;
using Dino.Entities;

namespace Dino.Ui.ConversationSelector {

public class ChatRow : ConversationRow {

    public ChatRow(StreamInteractor stream_interactor, Conversation conversation) {
        base(stream_interactor, conversation);
        has_tooltip = true;
        query_tooltip.connect ((x, y, keyboard_tooltip, tooltip) => {
            tooltip.set_custom(generate_tooltip());
            return true;
        });
        update_avatar();
    }

    public override void on_show_received(Show show) {
        update_avatar();
    }

    public override void network_connection(bool connected) {
        if (!connected) {
            set_avatar((new AvatarGenerator(AVATAR_SIZE, AVATAR_SIZE, image.scale_factor)).set_greyscale(true).draw_conversation(stream_interactor, conversation), image.scale_factor);
        } else {
            update_avatar();
        }
    }

    public void on_updated_roster_item(Roster.Item roster_item) {
        if (roster_item.name != null) {
            display_name = roster_item.name;
            update_name();
        }
        update_avatar();
    }

    public void update_avatar() {
        ArrayList<Jid> full_jids = stream_interactor.get_module(PresenceManager.IDENTITY).get_full_jids(conversation.counterpart, conversation.account);
        set_avatar((new AvatarGenerator(AVATAR_SIZE, AVATAR_SIZE, image.scale_factor))
            .set_greyscale(full_jids == null)
            .draw_conversation(stream_interactor, conversation), image.scale_factor);
    }

    private Widget generate_tooltip() {
        Builder builder = new Builder.from_resource("/org/dino-im/conversation_selector/chat_row_tooltip.ui");
        Box main_box = builder.get_object("main_box") as Box;
        Box inner_box = builder.get_object("inner_box") as Box;
        Label jid_label = builder.get_object("jid_label") as Label;

        jid_label.label = conversation.counterpart.to_string();

        ArrayList<Jid>? full_jids = stream_interactor.get_module(PresenceManager.IDENTITY).get_full_jids(conversation.counterpart, conversation.account);
        if (full_jids != null) {
            for (int i = 0; i < full_jids.size; i++) {
                inner_box.add(get_fulljid_box(full_jids[i]));
            }
        }
        return main_box;
    }
}

}