class StockMovementsController < ApplicationController
  def index
    @stock_movements = current_business.stock_movements.includes(:product).order(occurred_on: :desc)
  end

  def new
    @stock_movement = current_business.stock_movements.new(occurred_on: Date.current)
  end

  def create
    @stock_movement = current_business.stock_movements.new(stock_movement_params)
    if @stock_movement.save
      redirect_to stock_movements_path, notice: "Stock movement created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def stock_movement_params
      params.require(:stock_movement).permit(:movement_type, :product_id, :quantity, :unit_cost_cents, :from_location_id, :to_location_id, :occurred_on, :notes)
    end
end
