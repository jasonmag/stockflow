class DashboardController < ApplicationController
  def index
    @upcoming_payables = current_business.payables.upcoming.limit(10)
    @overdue_payables = current_business.payables.overdue_list.limit(10)
    @upcoming_receivables = current_business.receivables.due_soon.limit(10)
    @overdue_receivables = current_business.receivables.overdue_list.limit(10)

    totals = Inventory::OnHandCalculator.new(business: current_business).totals_by_product
    @low_stock_products = current_business.products.where.not(reorder_level: nil).select do |product|
      totals[product.id].to_f <= product.reorder_level.to_f
    end

    month_range = Date.current.beginning_of_month..Date.current
    expenses_mtd = current_business.expenses.where(occurred_on: month_range)
    @expenses_total = expenses_mtd.sum(:amount_cents)
    @cash_expenses_total = expenses_mtd.where(funding_source: current_business.purchase_funding_source_names_for(:cash)).sum(:amount_cents)
    @collections_total = current_business.collections.where(collected_on: month_range).sum(:amount_cents)
    @payments_total = current_business.payments.where(paid_on: month_range).sum(:amount_cents)
    @net_cashflow = @collections_total - @expenses_total - @payments_total
    @today_deliveries = current_business.deliveries.where(delivered_on: Date.current, status: :delivered)
  end
end
