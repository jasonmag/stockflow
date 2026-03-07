class Current < ActiveSupport::CurrentAttributes
  attribute :session, :business, :impersonated_user

  def user
    impersonated_user || session&.user
  end

  def authenticated_user
    session&.user
  end

  def impersonating?
    authenticated_user&.system_admin? && impersonated_user.present?
  end
end
