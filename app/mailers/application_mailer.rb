class ApplicationMailer < ActionMailer::Base
  default from: ENV["MAILER_FROM"].presence || Rails.application.credentials.dig(:mailer, :from).presence || "info@jasonmag.com"
  layout "mailer"
end
