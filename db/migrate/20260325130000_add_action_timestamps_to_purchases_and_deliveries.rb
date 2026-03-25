class AddActionTimestampsToPurchasesAndDeliveries < ActiveRecord::Migration[8.0]
  def change
    add_column :deliveries, :marked_delivered_at, :datetime
    add_column :purchases, :received_at, :datetime
  end
end
