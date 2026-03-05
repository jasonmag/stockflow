class LocationsController < ApplicationController
  before_action :set_location, only: %i[show edit update destroy]
  before_action :require_owner!, only: %i[destroy]

  def index
    @locations = current_business.locations.order(:name)
  end

  def show; end
  def new; @location = current_business.locations.new; end
  def edit; end

  def create
    @location = current_business.locations.new(location_params)
    if @location.save
      redirect_to @location, notice: "Location created."
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
end
