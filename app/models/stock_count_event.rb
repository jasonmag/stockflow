class StockCountEvent < ApplicationRecord
  belongs_to :stock_count_session
  belongs_to :user

  validates :event_type, presence: true
end
