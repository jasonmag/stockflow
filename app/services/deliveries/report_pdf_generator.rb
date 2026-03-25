require "prawn"

module Deliveries
  class ReportPdfGenerator
    def initialize(delivery:)
      @delivery = delivery
    end

    def render
      build_pdf.render
    end

    def generate_and_attach!
      pdf_data = render

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
        Prawn::Document.new(page_size: "A4", margin: 36) do |pdf|
          pdf.text(delivery.business.name, size: 16, style: :bold)
          pdf.text("Delivery", size: 14, style: :bold)
          pdf.text("Delivery No: #{delivery.delivery_number_preview}", size: 12, style: :bold)
          pdf.move_down 8
          pdf.text("Delivery to #{customer_name}")
          pdf.text("Address: #{customer_address}") if customer_address.present?
          pdf.move_down 10

          pdf.text("Items", style: :bold)
          if preview_items.empty?
            pdf.text("No items added yet.")
          else
            pdf.move_down 6
            render_items_table(pdf)
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
        delivery.show_prices?
      end

      def format_currency(cents)
        format("%.2f", cents.to_f / 100.0)
      end

      def preview_items
        @preview_items ||= delivery.delivery_items.reject(&:marked_for_destruction?)
      end

      def customer_name
        delivery.customer&.name.presence || "Not selected"
      end

      def customer_address
        delivery.customer&.address
      end

      def product_name_for(item)
        item.product&.name.presence || "Product not selected"
      end

      def product_unit_for(item)
        item.product&.unit
      end

      def render_items_table(pdf)
        headers = ["#", "Product", "Quantity"]
        widths = [30, 0, 90]

        if show_prices?
          headers += ["Unit Price", "Sub-total"]
          widths += [75, 75]
        end

        widths[1] = pdf.bounds.width - widths.excluding(0).sum

        draw_table_row(pdf, headers, widths, header: true)

        preview_items.each_with_index do |item, index|
          row = [
            (index + 1).to_s,
            product_name_for(item),
            format_quantity(item.quantity)
          ]

          if show_prices?
            row += [
              format_currency(item.unit_price_cents),
              format_currency(item.unit_price_cents.to_i * item.quantity.to_f)
            ]
          end

          draw_table_row(pdf, row, widths)
        end
      end

      def draw_table_row(pdf, values, widths, header: false)
        row_height = 24
        ensure_table_space!(pdf, row_height)

        top = pdf.cursor
        left = pdf.bounds.left

        x = left
        widths.each_with_index do |width, index|
          pdf.stroke_rectangle [x, top], width, row_height
          pdf.text_box(
            values[index].to_s,
            at: [x + 4, top - 6],
            width: width - 8,
            height: row_height - 8,
            size: 9,
            style: (header ? :bold : :normal),
            align: numeric_column?(index, widths.length) ? :right : :left,
            valign: :center,
            overflow: :shrink_to_fit
          )
          x += width
        end

        pdf.move_down row_height
      end

      def ensure_table_space!(pdf, row_height)
        return unless pdf.cursor < row_height + 40

        pdf.start_new_page
      end

      def numeric_column?(index, column_count)
        numeric_columns = [0, 2]
        numeric_columns += [3, 4] if column_count == 5
        numeric_columns.include?(index)
      end

      def format_quantity(quantity)
        value = quantity.to_f
        value == value.to_i ? value.to_i.to_s : format("%.2f", value)
      end
  end
end
