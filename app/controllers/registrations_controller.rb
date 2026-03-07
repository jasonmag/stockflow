class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params.merge(approved: false, approved_at: nil, approved_by: nil, system_admin: false))
    if @user.save
      redirect_to login_path, notice: "Registration submitted. Wait for super admin approval before signing in."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def registration_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end
end
