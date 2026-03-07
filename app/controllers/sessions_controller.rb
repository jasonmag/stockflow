class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new admin_new create]
  skip_before_action :ensure_system_admin_uses_impersonation!, only: :destroy
  skip_before_action :ensure_business_selected, only: :destroy
  skip_before_action :ensure_staff_can_manage_operations!, only: :destroy
  rate_limit to: 10, within: 3.minutes, only: :create, with: lambda {
    redirect_to(
      params[:login_scope] == "admin" ? admin_login_url : login_url,
      alert: "Try again later."
    )
  }

  def new
  end

  def admin_new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      if params[:login_scope] == "admin" && !user.system_admin?
        redirect_to admin_login_path, alert: "System admin access is required for admin login."
        return
      end

      start_new_session_for user
      session[:current_business_id] ||= user.businesses.first&.id
      redirect_to(params[:login_scope] == "admin" ? admin_root_path : dashboard_path)
    else
      redirect_to(
        params[:login_scope] == "admin" ? admin_login_path : login_path,
        alert: "Try another email address or password."
      )
    end
  end

  def destroy
    terminate_session
    redirect_to root_path
  end
end
