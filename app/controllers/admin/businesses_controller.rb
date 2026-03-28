module Admin
  class BusinessesController < BaseController
    def index
      @businesses = Business.includes(:memberships).order(:name)
    end

    def show
      @business = Business.find(params[:id])
      @memberships = @business.memberships.includes(:user).order(:role, :created_at)
      @available_users = User.where.not(id: @memberships.select(:user_id)).order(:email_address)
    end

    def new
      @business = Business.new
    end

    def create
      @business = Business.new(business_params)
      if @business.save
        redirect_to admin_business_path(@business), notice: "Business created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def invite_member
      business = Business.find(params[:id])
      email = membership_params[:email_address].to_s.strip.downcase
      role = membership_params[:role]

      user = User.find_by(email_address: email)
      new_user = user.nil?

      if new_user
        generated_password = SecureRandom.base58(24)
        user = User.new(
          email_address: email,
          password: generated_password,
          password_confirmation: generated_password
        )

        unless user.save
          redirect_to admin_business_path(business), alert: user.errors.full_messages.to_sentence
          return
        end
      end

      membership = business.memberships.new(user:, role:)
      if membership.save
        MembershipInvitationMailer.invite(
          user:,
          business:,
          inviter: Current.authenticated_user,
          role:,
          new_user:
        ).deliver_later

        redirect_to admin_business_path(business), notice: invitation_notice_for(business, new_user)
      else
        redirect_to admin_business_path(business), alert: membership.errors.full_messages.to_sentence
      end
    end

    private
      def business_params
        params.require(:business).permit(:name, :contact_email, :contact_phone, :address, :reminder_lead_days)
      end

      def membership_params
        params.require(:membership).permit(:email_address, :role)
      end

      def invitation_notice_for(business, new_user)
        if new_user
          "Member invited to #{business.name}. A set-password email has been sent."
        else
          "Member added to #{business.name}. An invitation email has been sent."
        end
      end
  end
end
