module Admin
  class BusinessesController < BaseController
    def index
      @businesses = Business.includes(:memberships).order(:name)
    end

    def show
      @business = Business.find(params[:id])
      @memberships = @business.memberships.includes(:user).order(:role, :created_at)
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

    private
      def business_params
        params.require(:business).permit(:name, :contact_email, :contact_phone, :address, :reminder_lead_days)
      end
  end
end
