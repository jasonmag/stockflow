class User < ApplicationRecord
  has_secure_password
  belongs_to :approved_by, class_name: "User", optional: true
  has_many :sessions, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :businesses, through: :memberships

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true
  scope :pending_approval, -> { where(approved: false).order(:created_at) }

  def owner_of?(business)
    memberships.where(business:, role: :owner).exists?
  end

  def role_for(business)
    memberships.find_by(business:)&.role
  end

  def pending_approval?
    !approved?
  end
end
