class PayablesController < ApplicationController
  before_action :set_payable, only: %i[show edit update destroy mark_paid]
  before_action :require_owner!, only: %i[destroy]

  def index
    @upcoming_payables = current_business.payables.upcoming.order(:due_on)
    @overdue_payables = current_business.payables.overdue_list.order(:due_on)
    @payables = current_business.payables.order(due_on: :desc)
  end

  def show
    @payments = @payable.payments.order(paid_on: :desc)
  end

  def new
    @payable = current_business.payables.new(due_on: Date.current)
  end

  def edit; end

  def create
    @payable = current_business.payables.new(payable_params)
    if @payable.save
      redirect_to @payable, notice: "Payable created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @payable.update(payable_params)
      redirect_to @payable, notice: "Payable updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @payable.destroy
    redirect_to payables_path, notice: "Payable deleted."
  end

  def mark_paid
    payment = current_business.payments.new(
      payable: @payable,
      paid_on: Date.current,
      amount_cents: @payable.amount_cents,
      method: params[:method] || :cash,
      notes: params[:notes]
    )

    if payment.save
      @payable.update!(status: :paid)
      redirect_to payables_path, notice: "Payable marked paid."
    else
      redirect_to @payable, alert: payment.errors.full_messages.to_sentence
    end
  end

  private
    def set_payable
      @payable = current_business.payables.find(params[:id])
    end

    def payable_params
      params.require(:payable).permit(:payable_type, :payee, :amount_cents, :currency, :due_on, :status, :notes, :recurring_rule)
    end
end
