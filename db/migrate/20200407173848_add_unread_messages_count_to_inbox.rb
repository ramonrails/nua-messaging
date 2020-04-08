class AddUnreadMessagesCountToInbox < ActiveRecord::Migration[5.0]
  def up
    # Add a new column to Inbox that reflects this number.
    add_column :inboxes, :unread_messages_count, :integer, default: 0

    # update existing in-boxes for their current values
    Inbox.find_each do |box|
      box.update_attribute :unread_messages_count, box.messages.unread.count
    end
  end

  def down
    remove_column :inboxes, :unread_messages_count
  end
  
end
