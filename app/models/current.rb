class Current < ActiveSupport::CurrentAttributes
  attribute :session, :business
  delegate :user, to: :session, allow_nil: true
end
