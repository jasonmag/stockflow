class PurchaseFundingSource < ApplicationRecord
  belongs_to :business

  enum :source_type, { cash: "cash", credit: "credit" }

  validates :name, :source_type, presence: true
  validates :name, uniqueness: { scope: :business_id, case_sensitive: false }
end
