class ProductPricesController < ApplicationController
  before_action :set_product
  before_action :set_product_price, only: :destroy

  def create
    @product_price = @product.product_prices.new(product_price_params)

    if @product_price.save
      redirect_to @product, notice: "Product price saved."
    else
      load_product_pricing
      render "products/show", status: :unprocessable_entity
    end
  end

  def destroy
    if @product_price.effective_on <= Date.current
      redirect_to @product, alert: "Only upcoming prices can be deleted."
      return
    end

    @product_price.destroy
    redirect_to @product, notice: "Upcoming product price deleted."
  end

  private
    def set_product
      @product = current_business.products.find(params[:product_id])
    end

    def set_product_price
      @product_price = @product.product_prices.find(params[:id])
    end

    def product_price_params
      params.require(:product_price).permit(:price_decimal, :effective_on)
    end

    def load_product_pricing
      @product_prices = @product.product_prices
      @current_product_price = @product.current_product_price
      @next_product_price = @product.next_product_price
      @product_purchase_price = @product.product_purchase_prices.new(effective_on: Date.current)
      @product_purchase_prices = @product.product_purchase_prices
      @current_product_purchase_price = @product.current_product_purchase_price
      @next_product_purchase_price = @product.next_product_purchase_price
    end
end
