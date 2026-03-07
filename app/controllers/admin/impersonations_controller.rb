module Admin
  class ImpersonationsController < BaseController
    def create
      user = User.find(params[:user_id])
      business = Business.find(params[:business_id])

      unless user.owner_of?(business)
        redirect_to admin_business_path(business), alert: "Only store admin accounts can be impersonated."
        return
      end

      session[:impersonated_user_id] = user.id
      session[:current_business_id] = business.id
      redirect_to dashboard_path, notice: "Now impersonating #{user.email_address} for #{business.name}."
    end

    def destroy
      session.delete(:impersonated_user_id)
      session.delete(:current_business_id)
      redirect_to admin_root_path, notice: "Impersonation ended."
    end
  end
end
