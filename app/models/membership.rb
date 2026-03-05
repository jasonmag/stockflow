class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :business

  enum :role, { owner: 0, staff: 1 }

  validates :role, presence: true
end
