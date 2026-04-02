class PurchasesController < ApplicationController
  before_action :set_purchase, only: %i[show edit update destroy receive]
  before_action :ensure_editable!, only: %i[edit update]
  before_action :require_owner!, only: %i[destroy]
  before_action :ensure_destroyable!, only: %i[destroy]
  before_action :load_form_options, only: %i[new edit create update]

  def index
    @purchases = current_business.purchases.includes(:supplier).order(purchased_on: :desc)
  end

  def show; end

  def new
    @purchase = current_business.purchases.new(
      purchased_on: Date.current,
      supplier_id: params[:supplier_id],
      receiving_location_id: params[:receiving_location_id],
      funding_source: params[:funding_source]
    )
    @purchase.reference = "PO-#{@purchase.purchased_on}" if @purchase.purchased_on.present?
    @purchase.purchase_items.build
  end

  def edit
    @purchase.reference = "PO-#{@purchase.purchased_on}" if @purchase.purchased_on.present? && @purchase.reference.blank?
    @purchase.purchase_items.build if @purchase.purchase_items.empty?
  end

  def create
    @purchase = current_business.purchases.new(purchase_params)

    Purchase.transaction do
      @purchase.save!
      sync_expense_reference!(@purchase)
      sync_inventory_if_received!(@purchase)
    end

    sync_purchase_image_storage!(@purchase)
    redirect_to @purchase, notice: "Purchase created."
  rescue ActiveRecord::RecordInvalid
    load_form_options
    render :new, status: :unprocessable_entity
  rescue GoogleDriveAttachmentSync::Error => e
    redirect_to @purchase, alert: "Purchase saved, but photo upload to Google Drive failed: #{e.message}"
  end

  def update
    Purchase.transaction do
      @purchase.update!(purchase_params)
      sync_expense_reference!(@purchase)
      sync_inventory_if_received!(@purchase)
    end

    sync_purchase_image_storage!(@purchase)
    redirect_to @purchase, notice: "Purchase updated."
  rescue ActiveRecord::RecordInvalid
    load_form_options
    render :edit, status: :unprocessable_entity
  rescue GoogleDriveAttachmentSync::Error => e
    redirect_to @purchase, alert: "Purchase updated, but photo upload to Google Drive failed: #{e.message}"
  end

  def destroy
    @purchase.destroy
    redirect_to purchases_path, notice: "Purchase deleted."
  end

  def receive
    @purchase.receive!
    redirect_to @purchase, notice: "Purchase received and stock-in movements created."
  rescue StandardError => e
    redirect_to @purchase, alert: e.message
  end

  private
    def set_purchase
      @purchase = current_business.purchases.find(params[:id])
    end

    def ensure_editable!
      return unless @purchase.received?

      redirect_to @purchase, alert: "Received purchases can no longer be edited."
    end

    def ensure_destroyable!
      return unless @purchase.received?

      redirect_to @purchase, alert: "Received purchases can no longer be deleted."
    end

    def purchase_params
      permitted = params.require(:purchase).permit(:supplier_id, :purchased_on, :receiving_location_id, :funding_source, :notes, :status, :purchase_image)
      raw_items = params[:purchase]&.[](:purchase_items_attributes)

      return permitted unless raw_items.present?

      permitted[:purchase_items_attributes] = normalize_purchase_item_attributes(raw_items)
      permitted
    end

    def normalize_purchase_item_attributes(raw_items)
      items =
        case raw_items
        when ActionController::Parameters
          raw_items.to_unsafe_h.values
        when Hash
          raw_items.values
        else
          Array(raw_items)
        end

      items.filter_map do |attributes|
        next if attributes.blank?

        ActionController::Parameters.new(attributes.to_h).permit(:id, :product_id, :quantity, :unit_cost_decimal, :unit_cost_cents, :_destroy)
      end
    end

    def load_form_options
      current_purchase_id = @purchase&.id
      @expense_reference_options = current_business.expenses
        .includes(:category)
        .where(purchase_id: [ nil, current_purchase_id ])
        .order(occurred_on: :desc, id: :desc)
    end

    def sync_inventory_if_received!(purchase)
      purchase.receive! if purchase.received? && !purchase.inventory_received?
    end

    def sync_expense_reference!(purchase)
      selected_expense_id = params.dig(:purchase, :expense_id).presence
      selected_expense = selected_expense_id.present? ? current_business.expenses.find(selected_expense_id) : nil

      if selected_expense&.purchase.present? && selected_expense.purchase != purchase
        purchase.errors.add(:expense, "is already linked to another purchase")
        raise ActiveRecord::RecordInvalid, purchase
      end

      current_expense = purchase.expense
      return if current_expense == selected_expense

      current_expense&.update!(purchase: nil) if current_expense.present?
      selected_expense&.update!(purchase:)
    end

    def sync_purchase_image_storage!(purchase)
      GoogleDriveAttachmentSync.new(
        record: purchase,
        attachment_name: :purchase_image,
        folder_name: "Purchases",
        tracking_prefix: "purchase_image_storage",
        filename_prefix: purchase.reference.presence || "purchase-#{purchase.id}"
      ).sync!
    end
end
