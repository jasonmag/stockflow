class AddPurchaseFundingSourcesToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :purchase_funding_sources, :text, null: false, default: "personal\nbusiness"
  end
end
