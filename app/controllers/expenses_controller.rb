class ExpensesController < ApplicationController
  before_action :set_expense, only: %i[show edit update destroy]
  before_action :require_owner!, only: %i[destroy]

  def index
    @expenses = current_business.expenses.includes(:category).order(occurred_on: :desc)
    @expenses = @expenses.where(occurred_on: params[:start_date]..params[:end_date]) if params[:start_date].present? && params[:end_date].present?
    @expenses = @expenses.where(category_id: params[:category_id]) if params[:category_id].present?
    @expenses = @expenses.where(funding_source: params[:funding_source]) if params[:funding_source].present?
    @expenses = @expenses.where("payee LIKE ?", "%#{params[:payee]}%") if params[:payee].present?

    mtd = current_business.expenses.for_month_to_date
    @personal_out_of_pocket_mtd = mtd.personal.sum(:amount_cents)
    @business_paid_mtd = mtd.business.sum(:amount_cents)
    @total_expenses_mtd = mtd.sum(:amount_cents)
  end

  def show; end
  def new; @expense = current_business.expenses.new(occurred_on: Date.current); end
  def edit; end

  def create
    @expense = current_business.expenses.new(expense_params)
    if @expense.save
      redirect_to @expense, notice: "Expense created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @expense.update(expense_params)
      redirect_to @expense, notice: "Expense updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy
    redirect_to expenses_path, notice: "Expense deleted."
  end

  private
    def set_expense
      @expense = current_business.expenses.find(params[:id])
    end

    def expense_params
      params.require(:expense).permit(:occurred_on, :payee, :category_id, :amount_cents, :currency, :funding_source, :payment_method, :notes, :receipt)
    end
end
