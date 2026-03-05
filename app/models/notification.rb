class Notification < ApplicationRecord
  belongs_to :business
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  enum :status, { unread: 0, read: 1 }

  validates :message, :due_on, presence: true
end
