class PurchasesController < ApplicationController
  before_action :set_purchase, only: %i[show edit update destroy receive]
  before_action :require_owner!, only: %i[destroy]

  def index
    @purchases = current_business.purchases.includes(:supplier).order(purchased_on: :desc)
  end

  def show; end

  def new
    @purchase = current_business.purchases.new(purchased_on: Date.current)
    @purchase.purchase_items.build
  end

  def edit
    @purchase.purchase_items.build if @purchase.purchase_items.empty?
  end

  def create
    @purchase = current_business.purchases.new(purchase_params)
    if @purchase.save
      redirect_to @purchase, notice: "Purchase created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @purchase.update(purchase_params)
      redirect_to @purchase, notice: "Purchase updated."
    else
      render :edit, status: :unprocessable_entity
    end
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

    def purchase_params
      params.require(:purchase).permit(:supplier_id, :purchased_on, :receiving_location_id, :funding_source, :notes, :status,
                                       purchase_items_attributes: %i[id product_id quantity unit_cost_cents _destroy])
    end
end
