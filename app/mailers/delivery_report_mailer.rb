class DeliveryReportMailer < ApplicationMailer
  def send_report(delivery_id, recipients, subject, message)
    @delivery = Delivery.find(delivery_id)
    @message = message

    if @delivery.report_pdf.attached?
      attachments[@delivery.report_pdf.filename.to_s] = @delivery.report_pdf.download
    end

    mail(to: recipients, subject: subject)
  end
end
