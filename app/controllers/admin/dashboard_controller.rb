module Admin
  class DashboardController < BaseController
    def index
      @business_count = Business.count
      @user_count = User.count
      @membership_count = Membership.count
      @system_admin_count = User.where(system_admin: true).count
      @recent_businesses = Business.order(created_at: :desc).limit(10)
      @recent_users = User.order(created_at: :desc).limit(10)
    end
  end
end
