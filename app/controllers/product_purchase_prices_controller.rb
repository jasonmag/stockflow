class ProductPurchasePricesController < ApplicationController
  before_action :set_product
  before_action :set_product_purchase_price, only: :destroy

  def create
    @product_purchase_price = @product.product_purchase_prices.new(product_purchase_price_params)

    if @product_purchase_price.save
      redirect_to @product, notice: "Product purchase price saved."
    else
      load_product_pricing
      render "products/show", status: :unprocessable_entity
    end
  end

  def destroy
    if @product_purchase_price.effective_on <= Date.current
      redirect_to @product, alert: "Only upcoming purchase prices can be deleted."
      return
    end

    @product_purchase_price.destroy
    redirect_to @product, notice: "Upcoming purchase price deleted."
  end

  private
    def set_product
      @product = current_business.products.find(params[:product_id])
    end

    def set_product_purchase_price
      @product_purchase_price = @product.product_purchase_prices.find(params[:id])
    end

    def product_purchase_price_params
      params.require(:product_purchase_price).permit(:price_decimal, :effective_on)
    end

    def load_product_pricing
      @product_price = @product.product_prices.new(effective_on: Date.current)
      @product_prices = @product.product_prices
      @current_product_price = @product.current_product_price
      @next_product_price = @product.next_product_price
      @product_purchase_prices = @product.product_purchase_prices
      @current_product_purchase_price = @product.current_product_purchase_price
      @next_product_purchase_price = @product.next_product_purchase_price
    end
end
