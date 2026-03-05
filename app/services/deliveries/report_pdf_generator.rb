require "prawn"

module Deliveries
  class ReportPdfGenerator
    def initialize(delivery:)
      @delivery = delivery
    end

    def generate_and_attach!
      pdf_data = build_pdf.render

      delivery.report_pdf.purge if delivery.report_pdf.attached?
      delivery.report_pdf.attach(
        io: StringIO.new(pdf_data),
        filename: "delivery-report-#{delivery.delivery_number}.pdf",
        content_type: "application/pdf"
      )
    end

    private
      attr_reader :delivery

      def build_pdf
        Prawn::Document.new(page_size: "A4") do |pdf|
          pdf.text(delivery.business.name, size: 16, style: :bold)
          pdf.text("Delivery Report", size: 14, style: :bold)
          pdf.move_down 8
          pdf.text("Delivery No: #{delivery.delivery_number}")
          pdf.text("Delivered On: #{delivery.delivered_on}")
          pdf.text("Customer: #{delivery.customer.name}")
          pdf.text("Address: #{delivery.customer.address}") if delivery.customer.address.present?
          pdf.move_down 10

          pdf.text("Items", style: :bold)
          delivery.delivery_items.each_with_index do |item, index|
            line = "#{index + 1}. #{item.product.name} (#{item.product.unit}) x #{item.quantity}"
            if show_prices?
              line += " @ #{format_currency(item.unit_price_cents)} = #{format_currency(item.unit_price_cents.to_i * item.quantity.to_f)}"
            end
            pdf.text(line)
          end
          pdf.move_down 8
          pdf.text("Notes: #{delivery.notes}") if delivery.notes.present?
          pdf.move_down 20
          pdf.text("Delivered by: ____________________")
          pdf.text("Received by: ____________________")
          pdf.text("Date: ____________________")

          pdf.number_pages "Page <page> of <total>", at: [pdf.bounds.right - 120, 0], size: 9
        end
      end

      def show_prices?
        delivery.show_prices? && delivery.delivery_items.any? { |item| item.unit_price_cents.present? }
      end

      def format_currency(cents)
        format("%.2f", cents.to_f / 100.0)
      end
  end
end
