class ApplicationController < ActionController::Base
  include Authentication
  before_action :set_current_business
  before_action :ensure_business_selected
  helper_method :current_business, :owner?

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private
    def set_current_business
      return unless Current.user

      business = Current.user.businesses.find_by(id: session[:current_business_id]) || Current.user.businesses.first
      session[:current_business_id] = business&.id
      Current.business = business
    end

    def current_business
      Current.business
    end

    def ensure_business_selected
      return unless Current.user
      return if current_business.present?

      redirect_to new_session_path, alert: "No business membership assigned."
    end

    def owner?
      current_business && Current.user&.owner_of?(current_business)
    end

    def require_owner!
      redirect_to root_path, alert: "Only owners can do that." unless owner?
    end

    def ensure_staff_can_manage_operations!
      return if owner?
      return if %w[stock_movements deliveries dashboard].include?(controller_name)

      redirect_to root_path, alert: "Not authorized."
    end
end
