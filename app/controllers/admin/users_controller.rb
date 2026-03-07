module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[show edit update approve]

    def index
      @users = User.includes(:memberships).order(:email_address)
    end

    def show
      @memberships = @user.memberships.includes(:business).order(:created_at)
      @available_businesses = Business.where.not(id: @user.business_ids).order(:name)
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "User updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def approve
      if @user.update(approved: true, approved_at: Time.current, approved_by: Current.authenticated_user)
        redirect_to admin_user_path(@user), notice: "User approved."
      else
        redirect_to admin_user_path(@user), alert: @user.errors.full_messages.to_sentence
      end
    end

    private
      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        params.require(:user).permit(:system_admin)
      end
  end
end
