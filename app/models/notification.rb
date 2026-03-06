class Notification < ApplicationRecord
  belongs_to :business
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  enum :status, { unread: 0, read: 1 }

  validates :message, :due_on, presence: true
  validate :user_has_business_membership

  private
    def user_has_business_membership
      return if user.blank? || business.blank?
      return if user.memberships.where(business_id: business_id).exists?

      errors.add(:user, "must belong to the notification business")
    end
end
