require "json"
require "net/http"
require "uri"
require "securerandom"

class GoogleDriveOauthClient
  AUTHORIZATION_ENDPOINT = "https://accounts.google.com/o/oauth2/v2/auth".freeze
  TOKEN_ENDPOINT = "https://oauth2.googleapis.com/token".freeze
  DRIVE_ABOUT_ENDPOINT = "https://www.googleapis.com/drive/v3/about?fields=user(displayName,emailAddress)".freeze
  DRIVE_UPLOAD_ENDPOINT = "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,webViewLink".freeze
  DRIVE_FILES_ENDPOINT = "https://www.googleapis.com/drive/v3/files".freeze
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

  def refresh_access_token(refresh_token:)
    response = post_form(
      TOKEN_ENDPOINT,
      client_id: @client_id,
      client_secret: @client_secret,
      refresh_token:,
      grant_type: "refresh_token"
    )

    {
      access_token: response.fetch("access_token"),
      expires_in: response["expires_in"]
    }
  end

  def upload_file(access_token:, io:, filename:, content_type:, parent_folder_id: nil)
    boundary = "stockflow-#{SecureRandom.hex(12)}"
    metadata = { name: filename }
    metadata[:parents] = [ parent_folder_id ] if parent_folder_id.present? && parent_folder_id != "root"

    body = +""
    body << "--#{boundary}\r\n"
    body << "Content-Type: application/json; charset=UTF-8\r\n\r\n"
    body << JSON.generate(metadata)
    body << "\r\n--#{boundary}\r\n"
    body << "Content-Type: #{content_type.presence || 'application/octet-stream'}\r\n\r\n"
    body << io.read
    body << "\r\n--#{boundary}--\r\n"

    uri = URI(DRIVE_UPLOAD_ENDPOINT)
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{access_token}"
    request["Content-Type"] = "multipart/related; boundary=#{boundary}"
    request.body = body

    response = perform_request(uri, request)

    {
      id: response.fetch("id"),
      web_view_link: response["webViewLink"]
    }
  end

  def find_child_folder(access_token:, parent_folder_id:, name:)
    uri = URI(DRIVE_FILES_ENDPOINT)
    query = [
      "mimeType='application/vnd.google-apps.folder'",
      "trashed=false",
      "name='#{name.to_s.gsub("'", "\\\\'")}'"
    ]
    query << "'#{parent_folder_id}' in parents" if parent_folder_id.present? && parent_folder_id != "root"

    uri.query = URI.encode_www_form(
      q: query.join(" and "),
      fields: "files(id,name)",
      pageSize: 1,
      supportsAllDrives: true,
      includeItemsFromAllDrives: true
    )

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{access_token}"
    response = perform_request(uri, request)
    response.fetch("files", []).first
  end

  def create_folder(access_token:, name:, parent_folder_id: nil)
    uri = URI(DRIVE_FILES_ENDPOINT)
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{access_token}"
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(
      {
        name:,
        mimeType: "application/vnd.google-apps.folder",
        parents: parent_folder_id.present? && parent_folder_id != "root" ? [ parent_folder_id ] : nil
      }.compact
    )

    perform_request(uri, request)
  end

  def ensure_child_folder(access_token:, parent_folder_id:, name:)
    existing_folder = find_child_folder(access_token:, parent_folder_id:, name:)
    return existing_folder.fetch("id") if existing_folder.present?

    create_folder(access_token:, name:, parent_folder_id:).fetch("id")
  end

  def delete_file(access_token:, file_id:)
    uri = URI("#{DRIVE_FILES_ENDPOINT}/#{file_id}")
    request = Net::HTTP::Delete.new(uri)
    request["Authorization"] = "Bearer #{access_token}"

    perform_request(uri, request)
    true
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
      return payload if response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPNoContent)

      error_message = payload["error_description"].presence || payload["error"].presence || "Google Drive authorization failed"
      raise StandardError, error_message
    end
end
