module StockCounts
  class SessionReportPdfGenerator
    def initialize(session:)
      @session = session
    end

    def render
      Prawn::Document.new(page_size: "A4", margin: 36) do |pdf|
        pdf.text "Manual Count Report", size: 18, style: :bold
        pdf.move_down 8
        pdf.text "Reference: #{session.reference_number}"
        pdf.text "Count Date: #{session.count_date}"
        pdf.text "Count Time: #{session.count_time.strftime('%H:%M')}"
        pdf.text "Count Type: #{session.count_type.humanize}"
        pdf.text "Location: #{session.display_location}"
        pdf.text "Status: #{session.status.humanize}"
        pdf.move_down 12

        pdf.table(
          [
            [ "Product", "Expected", "Actual", "Variance", "Reason" ]
          ] + rows,
          header: true,
          width: pdf.bounds.width
        )
      end.render
    end

    private
      attr_reader :session

      def rows
        session.stock_count_items.includes(:product).joins(:product).order("products.name").map do |item|
          [
            item.product.name,
            item.expected_quantity.to_s("F"),
            item.actual_quantity&.to_s("F") || "-",
            item.variance.to_s("F"),
            item.variance_reason.presence || "-"
          ]
        end
      end
  end
end
