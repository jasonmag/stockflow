class LocationsController < ApplicationController
  require "uri"
  require "rack/utils"

  before_action :set_location, only: %i[show edit update destroy]
  before_action :require_owner!, only: %i[destroy]

  def index
    @locations = current_business.locations.order(:name)
  end

  def show; end
  def new
    @location = current_business.locations.new
    @cancel_path = safe_return_to || locations_path
  end
  def edit; end

  def create
    @location = current_business.locations.new(location_params)
    @cancel_path = safe_return_to || locations_path
    if @location.save
      redirect_to location_redirect_target, notice: "Location created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @location.update(location_params)
      redirect_to @location, notice: "Location updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @location.destroy
    redirect_to locations_path, notice: "Location deleted."
  end

  private
    def set_location
      @location = current_business.locations.find(params[:id])
    end

    def location_params
      params.require(:location).permit(:name, :location_type)
    end

    def location_redirect_target
      return @location unless safe_return_to.present?

      uri = URI.parse(safe_return_to)
      location_param = uri.path == new_delivery_path ? "from_location_id" : "receiving_location_id"
      query = Rack::Utils.parse_nested_query(uri.query).merge(location_param => @location.id.to_s)
      uri.query = query.to_query.presence
      uri.to_s
    end

    def safe_return_to
      @safe_return_to ||= url_from(params[:return_to])
    end
end
