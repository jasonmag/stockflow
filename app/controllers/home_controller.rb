class HomeController < ApplicationController
  allow_unauthenticated_access only: %i[index about]

  def index
    redirect_to dashboard_path if Current.user
  end

  def about
  end
end
