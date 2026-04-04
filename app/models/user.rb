class User < ApplicationRecord
  has_secure_password
  belongs_to :approved_by, class_name: "User", optional: true
  has_many :sessions, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :businesses, through: :memberships
  has_many :created_stock_count_sessions, class_name: "StockCountSession", foreign_key: :created_by_id, inverse_of: :created_by
  has_many :performed_stock_count_sessions, class_name: "StockCountSession", foreign_key: :performed_by_id, inverse_of: :performed_by
  has_many :approved_stock_count_sessions, class_name: "StockCountSession", foreign_key: :approved_by_id, inverse_of: :approved_by
  has_many :inventory_adjustments, foreign_key: :created_by_id, inverse_of: :created_by

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
