class BusinessesController < ApplicationController
  before_action :require_owner!, only: %i[edit update members add_member]

  def switch
    business = Current.user.businesses.find(params[:business_id])
    session[:current_business_id] = business.id
    redirect_back fallback_location: root_path, notice: "Switched business to #{business.name}."
  end

  def members
    @business = current_business
    @memberships = @business.memberships.includes(:user).order(:role, :created_at)
  end

  def edit
    @business = current_business
  end

  def update
    @business = current_business

    if @business.update(business_params)
      redirect_to edit_business_path, notice: "Business settings updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def add_member
    business = current_business
    email = membership_params[:email_address].to_s.strip.downcase
    role = membership_params[:role]
    password = membership_params[:password]

    user = User.find_by(email_address: email)

    if user.nil?
      if password.blank?
        redirect_to members_business_path, alert: "Password is required when creating a new member account."
        return
      end

      user = User.new(email_address: email, password:, password_confirmation: password)
      unless user.save
        redirect_to members_business_path, alert: user.errors.full_messages.to_sentence
        return
      end
    end

    membership = business.memberships.new(user:, role:)
    if membership.save
      redirect_to members_business_path, notice: "Member added to #{business.name}."
    else
      redirect_to members_business_path, alert: membership.errors.full_messages.to_sentence
    end
  end

  private
    def business_params
      params.require(:business).permit(:contact_email, :contact_phone, :address, :reminder_lead_days, :purchase_funding_sources)
    end

    def membership_params
      params.require(:membership).permit(:email_address, :role, :password)
    end
end
