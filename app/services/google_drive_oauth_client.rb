require "json"
require "net/http"
require "uri"

class GoogleDriveOauthClient
  AUTHORIZATION_ENDPOINT = "https://accounts.google.com/o/oauth2/v2/auth".freeze
  TOKEN_ENDPOINT = "https://oauth2.googleapis.com/token".freeze
  DRIVE_ABOUT_ENDPOINT = "https://www.googleapis.com/drive/v3/about?fields=user(displayName,emailAddress)".freeze
  DRIVE_SCOPE = "https://www.googleapis.com/auth/drive.file".freeze

  def initialize(client_id:, client_secret:)
    @client_id = client_id
    @client_secret = client_secret
  end

  def authorization_uri(state:, redirect_uri:)
    uri = URI(AUTHORIZATION_ENDPOINT)
    uri.query = URI.encode_www_form(
      client_id: @client_id,
      redirect_uri:,
      response_type: "code",
      access_type: "offline",
      prompt: "consent",
      include_granted_scopes: "true",
      scope: DRIVE_SCOPE,
      state:
    )
    uri.to_s
  end

  def exchange_code(code:, redirect_uri:)
    response = post_form(
      TOKEN_ENDPOINT,
      code:,
      client_id: @client_id,
      client_secret: @client_secret,
      redirect_uri:,
      grant_type: "authorization_code"
    )

    {
      access_token: response.fetch("access_token"),
      refresh_token: response["refresh_token"],
      expires_in: response["expires_in"]
    }
  end

  def drive_profile(access_token:)
    uri = URI(DRIVE_ABOUT_ENDPOINT)
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{access_token}"

    response = perform_request(uri, request)
    user = response.fetch("user")

    {
      display_name: user["displayName"],
      email_address: user["emailAddress"]
    }
  end

  private
    def post_form(url, params)
      uri = URI(url)
      request = Net::HTTP::Post.new(uri)
      request.set_form_data(params)
      perform_request(uri, request)
    end

    def perform_request(uri, request)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      body = response.body.presence || "{}"
      payload = JSON.parse(body)
      return payload if response.is_a?(Net::HTTPSuccess)

      error_message = payload["error_description"].presence || payload["error"].presence || "Google Drive authorization failed"
      raise StandardError, error_message
    end
end
