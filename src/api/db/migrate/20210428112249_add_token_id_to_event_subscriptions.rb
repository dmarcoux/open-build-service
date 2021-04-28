class AddTokenIdToEventSubscriptions < ActiveRecord::Migration[6.0]
  def change
    add_column :event_subscriptions, :token_id, :integer
    add_index :event_subscriptions, :token_id
  end
end
