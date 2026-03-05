class PaymentsController < ApplicationController
  def index
    @payments = current_business.payments.order(paid_on: :desc)
  end
end
