module StockCounts
  class SessionBuilder
    def initialize(session:, scope_params:)
      @session = session
      @scope_params = scope_params
    end

    def build!
      session.transaction do
        session.save!
        populate_items!
        session.stock_count_events.create!(
          user: session.created_by,
          event_type: "created",
          details: "Session created with #{session.stock_count_items.count} items."
        )
      end

      session
    end

    private
      attr_reader :session, :scope_params

      def populate_items!
        products = scoped_products
        expected_quantities = expected_quantities_for(products)
        timestamp = Time.current

        rows = products.map do |product|
          {
            stock_count_session_id: session.id,
            product_id: product.id,
            expected_quantity: expected_quantities.fetch(product.id, 0),
            variance: 0,
            created_at: timestamp,
            updated_at: timestamp
          }
        end

        StockCountItem.insert_all!(rows) if rows.any?
      end

      def scoped_products
        scope = session.business.products.where(active: true).order(:name)
        scope = scope.where(inventory_type: scope_params[:inventory_type]) if scope_params[:inventory_type].present?
        if scope_params[:product_ids].present?
          scope = scope.where(id: scope_params[:product_ids])
        end
        scope.to_a
      end

      def expected_quantities_for(products)
        calculator = Inventory::OnHandCalculator.new(business: session.business)
        counts = if session.location_id.present?
          calculator.per_product_and_location.transform_values { |locations| locations[session.location_id].to_d }
        else
          calculator.totals_by_product.transform_values(&:to_d)
        end

        products.to_h { |product| [ product.id, counts[product.id].to_d ] }
      end
  end
end
