class SuppliersController < ApplicationController
  require "uri"
  require "rack/utils"

  before_action :set_supplier, only: %i[show edit update destroy]
  before_action :require_owner!, only: %i[destroy]

  def index
    @suppliers = current_business.suppliers.order(:name)
  end

  def show; end
  def new
    @supplier = current_business.suppliers.new
    @cancel_path = safe_return_to || suppliers_path
  end
  def edit; end

  def create
    @supplier = current_business.suppliers.new(supplier_params)
    @cancel_path = safe_return_to || suppliers_path
    if @supplier.save
      redirect_to supplier_redirect_target, notice: "Supplier created."
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

    def supplier_redirect_target
      return @supplier unless safe_return_to.present?

      uri = URI.parse(safe_return_to)
      query = Rack::Utils.parse_nested_query(uri.query).merge("supplier_id" => @supplier.id.to_s)
      uri.query = query.to_query.presence
      uri.to_s
    end

    def safe_return_to
      @safe_return_to ||= url_from(params[:return_to])
    end
end
