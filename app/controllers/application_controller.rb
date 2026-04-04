class ApplicationController < ActionController::Base
  include Authentication
  before_action :set_current_business
  before_action :ensure_system_admin_uses_impersonation!
  before_action :ensure_business_selected
  before_action :ensure_staff_can_manage_operations!
  helper_method :current_business, :owner?, :system_admin?, :impersonating?, :recaptcha_enabled?

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private
    def set_current_business
      return unless Current.user

      if system_admin? && Current.user.businesses.empty?
        session.delete(:current_business_id)
        Current.business = nil
        return
      end

      business = Current.user.businesses.find_by(id: session[:current_business_id]) || Current.user.businesses.first
      session[:current_business_id] = business&.id
      Current.business = business
    end

    def current_business
      Current.business
    end

    def ensure_business_selected
      return unless Current.user
      return if admin_namespace?
      return if current_business.present?

      redirect_to login_path, alert: "No business membership assigned."
    end

    def owner?
      current_business && Current.user&.owner_of?(current_business)
    end

    def system_admin?
      Current.authenticated_user&.system_admin?
    end

    def ensure_system_admin_uses_impersonation!
      return unless system_admin?
      return if admin_namespace? || impersonating?

      redirect_to admin_root_path, alert: "Use impersonation to access store operations."
    end

    def require_owner!
      redirect_to root_path, alert: "Only owners can do that." unless owner?
    end

    def require_system_admin!
      redirect_to root_path, alert: "Only system admins can do that." unless system_admin?
    end

    def ensure_staff_can_manage_operations!
      return unless Current.user
      return if admin_namespace?
      return if system_admin? || owner?
      return if %w[stock_movements stock_count_sessions deliveries dashboard user_guides notifications businesses business_storage_connections sessions].include?(controller_name)

      redirect_to root_path, alert: "Not authorized."
    end

    def admin_namespace?
      controller_path.start_with?("admin/")
    end

    def recaptcha_enabled?
      Recaptcha.configuration.site_key.present? && Recaptcha.configuration.secret_key.present?
    end

    def verify_recaptcha_if_enabled(view:, action:, model: nil, minimum_score: 0.5)
      return true unless recaptcha_enabled?

      verified = verify_recaptcha(
        model:,
        action:,
        minimum_score:,
        message: "reCAPTCHA verification failed. Please try again."
      )
      return true if verified

      flash.now[:alert] = "reCAPTCHA verification failed. Please try again."
      render view, status: :unprocessable_entity
      false
    end
end
