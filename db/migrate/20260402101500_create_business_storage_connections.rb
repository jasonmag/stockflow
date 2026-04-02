class CreateBusinessStorageConnections < ActiveRecord::Migration[8.0]
  def change
    create_table :business_storage_connections do |t|
      t.references :business, null: false, foreign_key: true, index: { unique: true }
      t.string :provider, null: false
      t.string :auth_method, null: false
      t.string :external_root_path, null: false
      t.string :connected_account_label, null: false
      t.string :status, null: false, default: "connected"
      t.datetime :connected_at
      t.datetime :last_verified_at
      t.text :last_error_message
      t.text :client_id
      t.text :client_secret
      t.text :access_key_id
      t.text :secret_access_key
      t.text :access_token
      t.text :refresh_token
      t.text :service_account_json
      t.timestamps
    end
  end
end
