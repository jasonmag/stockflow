class ExpensesController < ApplicationController
  before_action :set_expense, only: %i[show edit update destroy]
  before_action :require_owner!, only: %i[destroy]
  before_action :load_form_options, only: %i[new edit create update]

  def index
    @expenses = current_business.expenses.includes(:category).order(occurred_on: :desc)
    @suppliers = current_business.suppliers.order(:name)
    @expenses = @expenses.where(occurred_on: params[:start_date]..params[:end_date]) if params[:start_date].present? && params[:end_date].present?
    @expenses = @expenses.where(category_id: params[:category_id]) if params[:category_id].present?
    @expenses = @expenses.where(funding_source: params[:funding_source]) if params[:funding_source].present?
    @expenses = @expenses.where(payee: params[:payee]) if params[:payee].present?

    mtd = current_business.expenses.for_month_to_date
    @cash_expenses_mtd = mtd.where(funding_source: current_business.purchase_funding_source_names_for(:cash)).sum(:amount_cents)
    @credit_expenses_mtd = mtd.where(funding_source: current_business.purchase_funding_source_names_for(:credit)).sum(:amount_cents)
    @total_expenses_mtd = mtd.sum(:amount_cents)
  end

  def show; end
  def new; @expense = current_business.expenses.new(occurred_on: Date.current, currency: current_business.currency); end
  def edit; end

  def create
    @expense = current_business.expenses.new(expense_params)
    if @expense.save
      sync_expense_receipt_storage!(@expense)
      redirect_to @expense, notice: "Expense created."
    else
      load_form_options
      render :new, status: :unprocessable_entity
    end
  rescue GoogleDriveAttachmentSync::Error => e
    redirect_to @expense, alert: "Expense saved, but receipt upload to Google Drive failed: #{e.message}"
  end

  def update
    if @expense.update(expense_params)
      sync_expense_receipt_storage!(@expense)
      redirect_to @expense, notice: "Expense updated."
    else
      load_form_options
      render :edit, status: :unprocessable_entity
    end
  rescue GoogleDriveAttachmentSync::Error => e
    redirect_to @expense, alert: "Expense updated, but receipt upload to Google Drive failed: #{e.message}"
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
      params.require(:expense).permit(:occurred_on, :payee, :category_id, :amount_decimal, :amount_cents, :currency, :funding_source, :payment_method, :notes, :receipt, payable_ids: [])
    end

    def load_form_options
      @payables_category = current_business.categories.find_or_create_by!(name: "Payables")
      @expense_categories = current_business.categories.order(:name)
      @suppliers = current_business.suppliers.order(:name)
      @coverable_payables = current_business.payables.where(status: %i[unpaid overdue]).order(:due_on, :payee)
    end

    def sync_expense_receipt_storage!(expense)
      GoogleDriveAttachmentSync.new(
        record: expense,
        attachment_name: :receipt,
        folder_name: "Expenses",
        tracking_prefix: "receipt_storage",
        filename_prefix: "expense-#{expense.id}"
      ).sync!
    end
end
