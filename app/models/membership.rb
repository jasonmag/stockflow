class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :business

  enum :role, { owner: 0, staff: 1 }

  validates :role, presence: true
  validate :first_membership_for_business_must_be_owner, on: :create
  validate :business_must_keep_an_owner_on_role_change, on: :update
  before_destroy :business_must_keep_an_owner_on_destroy

  private
    def first_membership_for_business_must_be_owner
      return if role == "owner"
      return if business.memberships.where(role: :owner).exists?

      errors.add(:role, "must be owner for the first membership in a business.")
    end

    def business_must_keep_an_owner_on_role_change
      return unless role_previously_was == "owner"
      return if role == "owner"
      return if business.memberships.where(role: :owner).where.not(id: id).exists?

      errors.add(:role, "cannot remove the last store admin account for this business.")
    end

    def business_must_keep_an_owner_on_destroy
      return unless owner?
      return if business.memberships.where(role: :owner).where.not(id: id).exists?

      errors.add(:base, "Cannot remove the last store admin account for this business.")
      throw :abort
    end
end
