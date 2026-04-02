class ReceivablesController < ApplicationController
  before_action :set_receivable, only: %i[show edit update destroy mark_collected]
  before_action :require_owner!, only: %i[destroy]

  def index
    @due_soon = current_business.receivables.due_soon.order(:due_on)
    @overdue = current_business.receivables.overdue_list.order(:due_on)
    @receivables = current_business.receivables.order(due_on: :desc)
  end

  def show; end
  def new; @receivable = current_business.receivables.new(due_on: Date.current, currency: current_business.currency); end
  def edit; end

  def create
    @receivable = current_business.receivables.new(receivable_params)
    if @receivable.save
      redirect_to @receivable, notice: "Receivable created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @receivable.update(receivable_params)
      redirect_to @receivable, notice: "Receivable updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @receivable.destroy
    redirect_to receivables_path, notice: "Receivable deleted."
  end

  def mark_collected
    collection = current_business.collections.new(
      receivable: @receivable,
      collected_on: Date.current,
      amount_cents: @receivable.amount_cents,
      method: params[:method] || :cash,
      notes: params[:notes]
    )

    if collection.save
      @receivable.update!(status: :collected)
      redirect_to receivables_path, notice: "Receivable marked collected."
    else
      redirect_to @receivable, alert: collection.errors.full_messages.to_sentence
    end
  end

  private
    def set_receivable
      @receivable = current_business.receivables.find(params[:id])
    end

    def receivable_params
      params.require(:receivable).permit(:customer_id, :reference, :delivered_on, :due_on, :amount_decimal, :amount_cents, :currency, :status, :notes)
    end
end
