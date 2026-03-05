class BusinessesController < ApplicationController
  def switch
    business = Current.user.businesses.find(params[:business_id])
    session[:current_business_id] = business.id
    redirect_back fallback_location: root_path, notice: "Switched business to #{business.name}."
  end
end
