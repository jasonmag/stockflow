class DeliveriesController < ApplicationController
  before_action :set_delivery, only: %i[show edit update destroy generate_pdf download_pdf email_pdf mark_delivered]
  before_action :require_owner!, only: %i[destroy]

  def index
    @deliveries = current_business.deliveries.includes(:customer).order(delivered_on: :desc)
    @deliveries = @deliveries.where(customer_id: params[:customer_id]) if params[:customer_id].present?
    @deliveries = @deliveries.where(status: params[:status]) if params[:status].present?
    if params[:start_date].present? && params[:end_date].present?
      @deliveries = @deliveries.where(delivered_on: params[:start_date]..params[:end_date])
    end
  end

  def show
    @email_logs = @delivery.delivery_email_logs.order(created_at: :desc)
  end

  def new
    @delivery = current_business.deliveries.new(delivered_on: Date.current)
    @delivery.delivery_items.build
  end

  def edit
    @delivery.delivery_items.build if @delivery.delivery_items.empty?
  end

  def create
    @delivery = current_business.deliveries.new(delivery_params)
    if @delivery.save
      redirect_to @delivery, notice: "Delivery created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @delivery.update(delivery_params)
      redirect_to @delivery, notice: "Delivery updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @delivery.delivered?
      redirect_to @delivery, alert: "Cannot delete delivered record."
    else
      @delivery.destroy
      redirect_to deliveries_path, notice: "Delivery deleted."
    end
  end

  def generate_pdf
    Deliveries::ReportPdfGenerator.new(delivery: @delivery).generate_and_attach!
    redirect_to @delivery, notice: "PDF generated."
  end

  def download_pdf
    if @delivery.report_pdf.attached?
      redirect_to rails_blob_path(@delivery.report_pdf, disposition: "attachment")
    else
      redirect_to @delivery, alert: "Generate PDF first."
    end
  end

  def email_pdf
    recipients = parse_recipients(params[:recipients])
    if recipients.empty? || recipients.any? { |email| !email.match?(URI::MailTo::EMAIL_REGEXP) }
      redirect_to @delivery, alert: "Invalid recipients format."
      return
    end

    Deliveries::ReportPdfGenerator.new(delivery: @delivery).generate_and_attach! unless @delivery.report_pdf.attached?

    log = @delivery.delivery_email_logs.create!(
      sent_by_user: Current.user,
      recipients: recipients.join(", "),
      subject: params[:subject].presence || "Delivery Report #{@delivery.delivery_number}",
      message: params[:message].to_s,
      status: :queued
    )

    DeliveryReportEmailJob.perform_later(log.id)
    redirect_to @delivery, notice: "Delivery report email queued."
  end

  def mark_delivered
    @delivery.mark_delivered!
    redirect_to @delivery, notice: "Delivery marked as delivered."
  rescue ActiveRecord::RecordInvalid
    redirect_to @delivery, alert: @delivery.errors.full_messages.to_sentence
  end

  private
    def set_delivery
      @delivery = current_business.deliveries.find(params[:id])
    end

    def delivery_params
      params.require(:delivery).permit(:customer_id, :delivered_on, :from_location_id, :notes, :show_prices, :status,
                                       delivery_items_attributes: %i[id product_id quantity unit_price_cents _destroy])
    end

    def parse_recipients(raw)
      raw.to_s.split(/[;,]/).map(&:strip).reject(&:blank?)
    end
end
