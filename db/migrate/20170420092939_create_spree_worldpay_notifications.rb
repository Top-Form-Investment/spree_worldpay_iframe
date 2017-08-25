class CreateSpreeWorldpayNotifications < ActiveRecord::Migration
  def self.up
    create_table :spree_worldpay_notifications do |t|
      t.text :response
      t.text :event_type
      t.integer :order_id
      t.timestamps
    end
  end

  def self.down
    drop_table :spree_worldpay_notifications
  end
end
