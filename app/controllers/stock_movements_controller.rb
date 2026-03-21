class StockMovementsController < ApplicationController
  def index
    @stock_movements = current_business.stock_movements.includes(:product, :from_location, :to_location).order(occurred_on: :desc, created_at: :desc, id: :desc)
    @current_inventory_rows = build_current_inventory_rows
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

    def build_current_inventory_rows
      counts = Inventory::OnHandCalculator.new(business: current_business).per_product_and_location
      products = current_business.products.index_by(&:id)
      locations = current_business.locations.index_by(&:id)

      grouped_rows = counts.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |(product_id, location_counts), rows|
        location_counts.each do |location_id, quantity|
          next if location_id.blank?
          next unless products[product_id] && locations[location_id]
          next if quantity.to_f.zero?

          rows[locations[location_id].name] << {
            product_name: products[product_id].name,
            quantity: quantity.to_f
          }
        end
      end

      grouped_rows
        .transform_values { |rows| rows.sort_by { |row| row[:product_name] } }
        .sort.to_h
    end
end
