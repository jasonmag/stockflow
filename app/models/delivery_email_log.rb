class DeliveryEmailLog < ApplicationRecord
  belongs_to :delivery
  belongs_to :sent_by_user, class_name: "User"

  enum :status, { queued: 0, sent: 1, failed: 2 }

  validates :recipients, :subject, presence: true
end
