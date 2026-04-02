class AddStorageTrackingToExpensesAndDeliveries < ActiveRecord::Migration[8.0]
  def change
    change_table :expenses, bulk: true do |t|
      t.string :receipt_storage_file_id
      t.string :receipt_storage_url
      t.integer :receipt_storage_blob_id
      t.datetime :receipt_storage_synced_at
      t.text :receipt_storage_error
    end

    change_table :deliveries, bulk: true do |t|
      t.string :report_pdf_storage_file_id
      t.string :report_pdf_storage_url
      t.integer :report_pdf_storage_blob_id
      t.datetime :report_pdf_storage_synced_at
      t.text :report_pdf_storage_error
    end
  end
end
