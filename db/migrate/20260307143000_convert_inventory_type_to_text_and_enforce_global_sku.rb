class ConvertInventoryTypeToTextAndEnforceGlobalSku < ActiveRecord::Migration[8.0]
  class MigrationProduct < ApplicationRecord
    self.table_name = "products"
  end

  INVENTORY_TYPE_MAP = {
    0 => "stock_item",
    1 => "raw_material",
    2 => "finished_good",
    3 => "consumable",
    4 => "spare_part"
  }.freeze

  def up
    add_column :products, :inventory_type_text, :string, null: false, default: "stock_item"

    MigrationProduct.reset_column_information
    MigrationProduct.find_each do |product|
      raw_value = product.read_attribute(:inventory_type)
      mapped_value = INVENTORY_TYPE_MAP[raw_value.to_i] || raw_value.to_s.presence || "stock_item"
      product.update_columns(inventory_type_text: mapped_value)
    end

    remove_column :products, :inventory_type
    rename_column :products, :inventory_type_text, :inventory_type

    ensure_global_unique_skus!
    add_index :products, :sku, unique: true
  end

  def down
    remove_index :products, :sku
    add_column :products, :inventory_type_old, :integer, null: false, default: 0

    MigrationProduct.reset_column_information
    reverse_map = INVENTORY_TYPE_MAP.invert

    MigrationProduct.find_each do |product|
      int_value = reverse_map[product.read_attribute(:inventory_type).to_s] || 0
      product.update_columns(inventory_type_old: int_value)
    end

    remove_column :products, :inventory_type
    rename_column :products, :inventory_type_old, :inventory_type
  end

  private
    def ensure_global_unique_skus!
      MigrationProduct.reset_column_information
      seen = {}

      MigrationProduct.find_each do |product|
        sku = product.sku.to_s.strip
        if sku.blank? || seen.key?(sku)
          sku = generate_long_sku
          sku = generate_long_sku while seen.key?(sku) || MigrationProduct.exists?(sku: sku)
          product.update_columns(sku: sku)
        end
        seen[sku] = true
      end
    end

    def generate_long_sku
      "SKU#{SecureRandom.hex(24).upcase}"
    end
end
