module Inventory
  class StockValidator
    attr_reader :error_message

    def initialize(delivery:)
      @delivery = delivery
      @error_message = nil
    end

    def valid?
      return fail_with("No delivery items") if delivery.delivery_items.empty?
      return fail_with("From location required") if delivery.from_location.blank?

      on_hand = Inventory::OnHandCalculator.new(business: delivery.business).per_product_and_location

      delivery.delivery_items.all? do |item|
        available = on_hand.dig(item.product_id, delivery.from_location_id).to_f
        next true if available >= item.quantity.to_f

        fail_with("Insufficient stock for #{item.product.name}: available #{available}, needed #{item.quantity}")
      end
    end

    private
      attr_reader :delivery

      def fail_with(message)
        @error_message = message
        false
      end
  end
end
