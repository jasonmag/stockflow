class StockMovementsController < ApplicationController
  before_action :build_stock_movement_form_copy, only: %i[new create new_self_consumption new_spoilage]

  def index
    @stock_movements = current_business.stock_movements.includes(:product, :from_location, :to_location).order(occurred_on: :desc, created_at: :desc, id: :desc)
    @current_inventory_rows = build_current_inventory_rows
  end

  def new
    @stock_movement = current_business.stock_movements.new(occurred_on: Date.current)
  end

  def new_self_consumption
    @stock_movement = build_preset_stock_movement(:self_consumption)
    @stock_movement_form_title = "Record Self Consumption"
    @stock_movement_form_description = "Deduct stock used internally for operations, staff use, or product sampling."
    render :new
  end

  def new_spoilage
    @stock_movement = build_preset_stock_movement(:spoilage)
    @stock_movement_form_title = "Record Spoilage"
    @stock_movement_form_description = "Deduct damaged, expired, contaminated, or unsellable stock from inventory."
    render :new
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
      params.require(:stock_movement).permit(:movement_type, :reason_code, :product_id, :quantity, :unit_cost_decimal, :unit_cost_cents, :from_location_id, :to_location_id, :occurred_on, :notes)
    end

    def build_preset_stock_movement(reason_code)
      current_business.stock_movements.new(
        movement_type: :out,
        reason_code:,
        occurred_on: Date.current
      )
    end

    def build_stock_movement_form_copy
      @stock_movement_form_title =
        case params.dig(:stock_movement, :reason_code).presence || params[:reason_code].presence
        when "self_consumption"
          "Record Self Consumption"
        when "spoilage"
          "Record Spoilage"
        else
          "New Stock Movement"
        end

      @stock_movement_form_description =
        case params.dig(:stock_movement, :reason_code).presence || params[:reason_code].presence
        when "self_consumption"
          "Deduct stock used internally for operations, staff use, or product sampling."
        when "spoilage"
          "Deduct damaged, expired, contaminated, or unsellable stock from inventory."
        else
          "Record stock in, out, transfers, or adjustments."
        end
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
