class AddFileStorageSettingsToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :file_storage_provider, :string
    add_column :businesses, :file_storage_location, :string
  end
end
