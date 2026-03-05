class Customer < ApplicationRecord
  belongs_to :business
  has_many :receivables, dependent: :restrict_with_error
  has_many :deliveries, dependent: :restrict_with_error

  validates :name, presence: true
end
