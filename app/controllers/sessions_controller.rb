class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new admin_new create]
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
      start_new_session_for user
      session[:current_business_id] ||= user.businesses.first&.id
      redirect_to after_authentication_url
    else
      redirect_to(
        params[:login_scope] == "admin" ? admin_login_path : login_path,
        alert: "Try another email address or password."
      )
    end
  end

  def destroy
    terminate_session
    redirect_to login_path
  end
end
