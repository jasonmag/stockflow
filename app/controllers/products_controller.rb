class ProductsController < ApplicationController
  require "uri"
  require "rack/utils"

  before_action :set_product, only: %i[show edit update destroy]
  before_action :load_product_field_options, only: %i[new edit create update]
  before_action :require_owner!, only: %i[new create destroy]

  def index
    @products = current_business.products.order(:name)
  end

  def show; end
  def new
    @product = current_business.products.new(active: true)
    @cancel_path = safe_return_to || products_path
  end
  def edit; end

  def create
    @product = current_business.products.new(product_params)
    @cancel_path = safe_return_to || products_path
    if @product.save
      redirect_to product_redirect_target, notice: "Product created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: "Product updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: "Product deleted."
  end

  private
    def set_product
      @product = current_business.products.find(params[:id])
    end

    def product_params
      params.require(:product).permit(
        :name, :unit, :inventory_type, :brand, :barcode, :description, :base_cost_decimal, :reorder_level, :active
      )
    end

    def load_product_field_options
      defaults = [ "stock_item", "raw_material", "finished_good", "consumable", "spare_part" ]
      @inventory_type_options = (
        current_business.products.where.not(inventory_type: [ nil, "" ]).distinct.order(:inventory_type).pluck(:inventory_type) + defaults
      ).uniq

      @unit_options = (
        current_business.products.where.not(unit: [ nil, "" ]).distinct.order(:unit).pluck(:unit) +
        %w[pc box case pack bottle kg g liter ml]
      ).uniq
    end

    def product_redirect_target
      return @product unless safe_return_to.present?

      uri = URI.parse(safe_return_to)
      query = Rack::Utils.parse_nested_query(uri.query)
      uri.query = query.to_query.presence
      uri.to_s
    end

    def safe_return_to
      @safe_return_to ||= url_from(params[:return_to])
    end
end
