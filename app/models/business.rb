class Business < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :categories, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :payables, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :locations, dependent: :destroy
  has_many :stock_movements, dependent: :destroy
  has_many :suppliers, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :receivables, dependent: :destroy
  has_many :collections, dependent: :destroy
  has_many :deliveries, dependent: :destroy
  has_many :notifications, dependent: :destroy

  validates :name, presence: true
  validates :reminder_lead_days, numericality: { greater_than_or_equal_to: 0 }
end
