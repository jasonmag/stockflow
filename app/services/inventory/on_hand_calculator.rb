module Inventory
  class OnHandCalculator
    def initialize(business:, as_of: nil)
      @business = business
      @as_of = as_of
    end

    def per_product_and_location
      data = Hash.new { |h, k| h[k] = Hash.new(0.0) }

      movements.find_each do |movement|
        case movement.movement_type.to_sym
        when :in
          data[movement.product_id][movement.to_location_id] += movement.quantity.to_f
        when :out
          data[movement.product_id][movement.from_location_id] -= movement.quantity.to_f
        when :transfer
          data[movement.product_id][movement.from_location_id] -= movement.quantity.to_f
          data[movement.product_id][movement.to_location_id] += movement.quantity.to_f
        when :adjustment
          location_id = movement.to_location_id || movement.from_location_id
          data[movement.product_id][location_id] += movement.quantity.to_f
        end
      end

      data
    end

    def totals_by_product
      per_product_and_location.transform_values { |locations| locations.values.sum }
    end

    private
      attr_reader :business
      attr_reader :as_of

      def movements
        @movements ||= begin
          scope = business.stock_movements.includes(:product)
          scope = scope.where("created_at <= ?", as_of) if as_of.present?
          scope
        end
      end
  end
end
