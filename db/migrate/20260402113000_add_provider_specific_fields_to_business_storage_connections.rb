class AddProviderSpecificFieldsToBusinessStorageConnections < ActiveRecord::Migration[8.0]
  def change
    add_column :business_storage_connections, :tenant_id, :text
    add_column :business_storage_connections, :app_key, :text
    add_column :business_storage_connections, :app_secret, :text
    add_column :business_storage_connections, :storage_account_name, :string
    add_column :business_storage_connections, :bucket_name, :string
    add_column :business_storage_connections, :container_name, :string
    add_column :business_storage_connections, :region, :string
    add_column :business_storage_connections, :endpoint, :string
    add_column :business_storage_connections, :drive_id, :string
    add_column :business_storage_connections, :site_id, :string
  end
end
