class SuppliersController < ApplicationController
  before_action :set_supplier, only: %i[show edit update destroy]
  before_action :require_owner!, only: %i[destroy]

  def index
    @suppliers = current_business.suppliers.order(:name)
  end

  def show; end
  def new; @supplier = current_business.suppliers.new; end
  def edit; end

  def create
    @supplier = current_business.suppliers.new(supplier_params)
    if @supplier.save
      redirect_to @supplier, notice: "Supplier created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @supplier.update(supplier_params)
      redirect_to @supplier, notice: "Supplier updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @supplier.destroy
    redirect_to suppliers_path, notice: "Supplier deleted."
  end

  private
    def set_supplier
      @supplier = current_business.suppliers.find(params[:id])
    end

    def supplier_params
      params.require(:supplier).permit(:name, :contact_name, :contact_email, :contact_phone, :address)
    end
end
