class DeliveryReportMailer < ApplicationMailer
  def send_report(delivery_id, recipients, subject, message)
    @delivery = Delivery.find(delivery_id)
    @message = message

    attachments["delivery-report-#{@delivery.delivery_number}.pdf"] =
      Deliveries::ReportPdfGenerator.new(delivery: @delivery).render

    mail(to: recipients, subject: subject)
  end
end
