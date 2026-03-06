module Admin
  class MembershipsController < BaseController
    def create
      membership = Membership.new(membership_params)
      if membership.save
        redirect_to admin_user_path(membership.user_id), notice: "Membership created."
      else
        redirect_back fallback_location: admin_users_path, alert: membership.errors.full_messages.to_sentence
      end
    end

    def update
      membership = Membership.find(params[:id])
      if membership.update(membership_update_params)
        redirect_to admin_user_path(membership.user_id), notice: "Membership updated."
      else
        redirect_back fallback_location: admin_user_path(membership.user_id), alert: membership.errors.full_messages.to_sentence
      end
    end

    def destroy
      membership = Membership.find(params[:id])
      user_id = membership.user_id
      membership.destroy
      redirect_to admin_user_path(user_id), notice: "Membership removed."
    end

    private
      def membership_params
        params.require(:membership).permit(:user_id, :business_id, :role)
      end

      def membership_update_params
        params.require(:membership).permit(:role)
      end
  end
end
