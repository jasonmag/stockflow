Recaptcha.configure do |config|
  config.site_key = ENV["RECAPTCHA_SITE_KEY"].presence || Rails.application.credentials.dig(:recaptcha, :v3, :site_key).presence
  config.secret_key = ENV["RECAPTCHA_SECRET_KEY"].presence || Rails.application.credentials.dig(:recaptcha, :v3, :secret_key).presence
end
