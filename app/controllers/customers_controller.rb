class CustomersController < ApplicationController
  before_action :set_customer, only: %i[show edit update destroy]
  before_action :require_owner!, only: %i[destroy]

  def index
    @customers = current_business.customers.order(:name)
  end

  def show; end
  def new; @customer = current_business.customers.new; end
  def edit; end

  def create
    @customer = current_business.customers.new(customer_params)
    if @customer.save
      redirect_to @customer, notice: "Customer created."
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
end
