class CustomersController < ApplicationController
  require "uri"
  require "rack/utils"

  before_action :set_customer, only: %i[show edit update destroy]
  before_action :require_owner!, only: %i[destroy]

  def index
    @customers = current_business.customers.order(:name)
  end

  def show; end
  def new
    @customer = current_business.customers.new
    @cancel_path = safe_return_to || customers_path
  end
  def edit; end

  def create
    @customer = current_business.customers.new(customer_params)
    @cancel_path = safe_return_to || customers_path
    if @customer.save
      redirect_to customer_redirect_target, notice: "Customer created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @customer.update(customer_params)
      redirect_to @customer, notice: "Customer updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @customer.destroy
    redirect_to customers_path, notice: "Customer deleted."
  end

  private
    def set_customer
      @customer = current_business.customers.find(params[:id])
    end

    def customer_params
      params.require(:customer).permit(:name, :contact_name, :contact_email, :contact_phone, :address)
    end

    def customer_redirect_target
      return @customer unless safe_return_to.present?

      uri = URI.parse(safe_return_to)
      query = Rack::Utils.parse_nested_query(uri.query).merge("customer_id" => @customer.id.to_s)
      uri.query = query.to_query.presence
      uri.to_s
    end

    def safe_return_to
      @safe_return_to ||= url_from(params[:return_to])
    end
end
