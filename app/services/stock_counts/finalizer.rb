module StockCounts
  class Finalizer
    def initialize(session:, user:)
      @session = session
      @user = user
    end

    def finalize!
      session.assign_attributes(status: :completed, completed_at: Time.current, performed_by: user)
      raise ActiveRecord::RecordInvalid, session unless session.valid?

      session.transaction do
        create_adjustments!
        session.save!
        session.stock_count_events.create!(
          user:,
          event_type: "finalized",
          details: "Finalized with #{session.inventory_adjustments.count} adjustment(s)."
        )
      end

      session
    end

    private
      attr_reader :session, :user

      def create_adjustments!
        if session.location.blank?
          session.errors.add(:location, "is required before adjustments can be created")
          raise ActiveRecord::RecordInvalid, session
        end

        adjustments = variance_items.map do |item|
          {
            business_id: session.business_id,
            product_id: item.product_id,
            stock_count_session_id: session.id,
            created_by_id: user.id,
            adjustment_quantity: item.variance,
            reason: item.variance_reason,
            notes: item.notes,
            created_at: Time.current,
            updated_at: Time.current
          }
        end

        InventoryAdjustment.insert_all!(adjustments) if adjustments.any?

        variance_items.each do |item|
          StockMovement.create!(
            business: session.business,
            movement_type: :adjustment,
            product: item.product,
            quantity: item.variance,
            to_location: session.location,
            occurred_on: session.count_date,
            reference: session,
            notes: "Manual count #{session.reference_number}: #{item.variance_reason}"
          )
        end
      end

      def variance_items
        @variance_items ||= session.stock_count_items.includes(:product).select(&:variance_present?)
      end
  end
end
