module Admin
  class MembershipsController < BaseController
    def create
      membership = Membership.new(membership_params)
      if membership.save
        redirect_to membership_redirect_path(membership), notice: "Membership created."
      else
        redirect_to membership_failure_redirect_path(membership), alert: membership.errors.full_messages.to_sentence
      end
    end

    def update
      membership = Membership.find(params[:id])
      if membership.update(membership_update_params)
        redirect_to membership_redirect_path(membership), notice: "Membership updated."
      else
        redirect_to membership_redirect_path(membership), alert: membership.errors.full_messages.to_sentence
      end
    end

    def destroy
      membership = Membership.find(params[:id])
      if membership.destroy
        redirect_to membership_redirect_path(membership), notice: "Membership removed."
      else
        redirect_to membership_redirect_path(membership), alert: membership.errors.full_messages.to_sentence
      end
    end

    private
      def membership_params
        params.require(:membership).permit(:user_id, :business_id, :role)
      end

      def membership_update_params
        params.require(:membership).permit(:role)
      end

      def membership_redirect_path(membership)
        if params[:redirect_to] == "business"
          admin_business_path(membership.business_id)
        else
          admin_user_path(membership.user_id)
        end
      end

      def membership_failure_redirect_path(membership)
        if params[:redirect_to] == "business" && membership.business_id.present?
          admin_business_path(membership.business_id)
        elsif membership.user_id.present?
          admin_user_path(membership.user_id)
        else
          admin_users_path
        end
      end
  end
end
