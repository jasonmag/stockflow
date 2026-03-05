class DeliveryReportEmailJob < ApplicationJob
  queue_as :default

  def perform(delivery_email_log_id)
    log = DeliveryEmailLog.find(delivery_email_log_id)

    DeliveryReportMailer.send_report(
      log.delivery_id,
      parse_recipients(log.recipients),
      log.subject,
      log.message
    ).deliver_now

    log.update!(status: :sent, sent_at: Time.current, error_message: nil)
  rescue StandardError => e
    log&.update!(status: :failed, error_message: e.message)
    raise
  end

  private
    def parse_recipients(raw)
      raw.to_s.split(/[;,]/).map(&:strip).reject(&:blank?)
    end
end
