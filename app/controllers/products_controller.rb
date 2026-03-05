class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy]
  before_action :require_owner!, only: %i[destroy]

  def index
    @products = current_business.products.order(:name)
  end

  def show; end
  def new; @product = current_business.products.new(active: true); end
  def edit; end

  def create
    @product = current_business.products.new(product_params)
    if @product.save
      redirect_to @product, notice: "Product created."
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
      params.require(:product).permit(:name, :sku, :unit, :reorder_level, :active)
    end
end
