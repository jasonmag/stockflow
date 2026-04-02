class AddPurchaseImageStorageTrackingToPurchases < ActiveRecord::Migration[8.0]
  def change
    change_table :purchases, bulk: true do |t|
      t.string :purchase_image_storage_file_id
      t.string :purchase_image_storage_url
      t.integer :purchase_image_storage_blob_id
      t.datetime :purchase_image_storage_synced_at
      t.text :purchase_image_storage_error
    end
  end
end
