module Authentication
  extend ActiveSupport::Concern
  MAX_RETURN_TO_URL_BYTES = 512

  included do
    before_action :require_authentication
    helper_method :authenticated?, :impersonating?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
      Current.impersonated_user = impersonated_user_for(Current.session)
      Current.session
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = storable_return_path
      redirect_to(request.path.start_with?("/admin") ? admin_login_path : login_path)
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        Current.impersonated_user = nil
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session&.destroy
      Current.session = nil
      Current.business = nil
      Current.impersonated_user = nil
      session.delete(:return_to_after_authenticating)
      session.delete(:impersonated_user_id)
      cookies.delete(:session_id)
    end

    def impersonating?
      Current.impersonating?
    end

    def impersonated_user_for(active_session)
      return nil unless active_session&.user&.system_admin?

      user_id = session[:impersonated_user_id]
      return nil if user_id.blank?

      User.find_by(id: user_id)
    end

    def storable_return_path
      return request.path unless request.get?

      fullpath = request.fullpath
      fullpath.bytesize <= MAX_RETURN_TO_URL_BYTES ? fullpath : request.path
    end
end
