class StockCountSessionsController < ApplicationController
  before_action :set_stock_count_session, only: %i[show edit update finalize approve export]
  before_action :ensure_editable!, only: %i[edit update finalize]
  before_action :require_owner!, only: %i[approve]
  before_action :load_filters, only: %i[new create edit update]

  def index
    @stock_count_sessions = current_business.stock_count_sessions.includes(:location, :created_by, :performed_by, :approved_by).recent_first
  end

  def show
    @stock_count_items = @stock_count_session.stock_count_items.includes(:product).joins(:product).order("products.name")
    @stock_count_events = @stock_count_session.stock_count_events.includes(:user).order(created_at: :desc)
  end

  def new
    @stock_count_session = current_business.stock_count_sessions.new(
      count_date: Date.current,
      count_time: Time.current.strftime("%H:%M"),
      count_type: :end_of_day
    )
  end

  def create
    @stock_count_session = current_business.stock_count_sessions.new(stock_count_session_params)
    @stock_count_session.created_by = Current.user

    StockCounts::SessionBuilder.new(session: @stock_count_session, scope_params: count_scope_params).build!
    redirect_to edit_stock_count_session_path(@stock_count_session), notice: "Manual count session created."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def edit
    @stock_count_items = @stock_count_session.stock_count_items.includes(:product).joins(:product).order("products.name")
  end

  def update
    @stock_count_session.assign_attributes(stock_count_session_update_params)

    StockCountSession.transaction do
      @stock_count_session.save!
      if @stock_count_session.draft? && @stock_count_session.stock_count_items.any? { |item| item.actual_quantity.present? }
        @stock_count_session.update!(status: :in_progress)
      end
      @stock_count_session.stock_count_events.create!(
        user: Current.user,
        event_type: "saved_progress",
        details: "Draft progress saved."
      )
    end

    redirect_to edit_stock_count_session_path(@stock_count_session), notice: "Manual count progress saved."
  rescue ActiveRecord::RecordInvalid
    @stock_count_items = @stock_count_session.stock_count_items.includes(:product).joins(:product).order("products.name")
    render :edit, status: :unprocessable_entity
  end

  def finalize
    StockCounts::Finalizer.new(session: @stock_count_session, user: Current.user).finalize!
    redirect_to stock_count_session_path(@stock_count_session), notice: "Manual count finalized."
  rescue ActiveRecord::RecordInvalid
    @stock_count_items = @stock_count_session.stock_count_items.includes(:product).joins(:product).order("products.name")
    flash.now[:alert] = @stock_count_session.errors.full_messages.to_sentence.presence || "Unable to finalize manual count."
    render :edit, status: :unprocessable_entity
  end

  def approve
    @stock_count_session.update!(status: :approved, approved_by: Current.user)
    @stock_count_session.stock_count_events.create!(
      user: Current.user,
      event_type: "approved",
      details: "Session approved."
    )
    redirect_to stock_count_session_path(@stock_count_session), notice: "Manual count approved."
  end

  def variance_report
    @variance_rows = variance_scope.order("stock_count_sessions.count_date DESC, products.name ASC")

    respond_to do |format|
      format.html
      format.csv do
        send_data variance_report_csv, filename: "stock-variance-report-#{Date.current}.csv", type: "text/csv"
      end
    end
  end

  def export
    respond_to do |format|
      format.csv do
        send_data session_csv(@stock_count_session), filename: "#{@stock_count_session.reference_number.parameterize}.csv", type: "text/csv"
      end
      format.pdf do
        send_data StockCounts::SessionReportPdfGenerator.new(session: @stock_count_session).render,
                  filename: "#{@stock_count_session.reference_number.parameterize}.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  private
    def set_stock_count_session
      @stock_count_session = current_business.stock_count_sessions.find(params[:id])
    end

    def ensure_editable!
      return unless @stock_count_session.locked?

      redirect_to @stock_count_session, alert: "Completed manual counts can no longer be edited."
    end

    def load_filters
      @inventory_type_options = current_business.products.distinct.order(:inventory_type).pluck(:inventory_type).compact_blank
      @available_products = current_business.products.where(active: true).order(:name)
      @locations = current_business.locations.order(:name)
    end

    def stock_count_session_params
      params.require(:stock_count_session).permit(:count_date, :count_time, :location_id, :count_type, :notes)
    end

    def stock_count_session_update_params
      params.require(:stock_count_session).permit(:count_date, :count_time, :location_id, :count_type, :notes,
                                                  stock_count_items_attributes: %i[id actual_quantity variance_reason notes])
    end

    def count_scope_params
      {
        inventory_type: params.dig(:stock_count_session, :inventory_type),
        product_ids: Array(params.dig(:stock_count_session, :product_ids)).reject(&:blank?)
      }
    end

    def variance_scope
      scope = current_business.stock_count_items.joins(:product, :stock_count_session).where.not(variance: 0)
      if params[:start_date].present? && params[:end_date].present?
        scope = scope.where(stock_count_sessions: { count_date: params[:start_date]..params[:end_date] })
      end
      scope = scope.where(product_id: params[:product_id]) if params[:product_id].present?
      scope = scope.where(stock_count_sessions: { location_id: params[:location_id] }) if params[:location_id].present?
      scope
    end

    def variance_report_csv
      to_csv([
        [ "Date", "Reference", "Product", "Variance", "Reason", "Adjusted Quantity", "Location" ]
      ] + @variance_rows.map do |item|
        [
          item.stock_count_session.count_date,
          item.stock_count_session.reference_number,
          item.product.name,
          item.variance.to_s("F"),
          item.variance_reason,
          item.variance.to_s("F"),
          item.stock_count_session.display_location
        ]
      end)
    end

    def session_csv(session)
      to_csv([
        [ "Reference", "Count Date", "Count Time", "Product", "Expected Quantity", "Actual Quantity", "Variance", "Reason", "Notes" ]
      ] + session.stock_count_items.includes(:product).joins(:product).order("products.name").map do |item|
        [
          session.reference_number,
          session.count_date,
          session.count_time.strftime("%H:%M"),
          item.product.name,
          item.expected_quantity.to_s("F"),
          item.actual_quantity&.to_s("F"),
          item.variance.to_s("F"),
          item.variance_reason,
          item.notes
        ]
      end)
    end

    def to_csv(rows)
      rows.map do |row|
        row.map { |value| csv_escape(value) }.join(",")
      end.join("\n")
    end

    def csv_escape(value)
      text = value.to_s
      return text unless text.include?(",") || text.include?("\"") || text.include?("\n")

      "\"#{text.gsub("\"", "\"\"")}\""
    end
end
