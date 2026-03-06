module Admin
  class BusinessesController < BaseController
    def index
      @businesses = Business.includes(:memberships).order(:name)
    end

    def show
      @business = Business.find(params[:id])
      @memberships = @business.memberships.includes(:user).order(:role, :created_at)
    end
  end
end
