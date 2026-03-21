class AddReferenceToPurchases < ActiveRecord::Migration[8.0]
  def change
    add_column :purchases, :reference, :string
  end
end
