ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
end

class ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  private
    def sign_in_as(user, password: "password123")
      post session_path, params: { email_address: user.email_address, password: password }
      follow_redirect! if response.redirect?
    end
end
