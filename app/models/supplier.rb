class Supplier < ApplicationRecord
  belongs_to :business
  has_many :purchases, dependent: :restrict_with_error

  validates :name, presence: true
end
