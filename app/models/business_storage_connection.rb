class BusinessStorageConnection < ApplicationRecord
  GOOGLE_DRIVE_FOLDER_URL_PATTERN = %r{\Ahttps://drive\.google\.com/drive(?:/u/\d+)?/folders/([^/?#]+)}i

  AUTH_METHODS = {
    "oauth2" => "OAuth 2.0"
  }.freeze

  PROVIDER_AUTH_METHODS = {
    "google_drive" => "oauth2"
  }.freeze

  PROVIDER_DOCUMENTATION_URLS = {
    "google_drive" => "https://developers.google.com/workspace/drive/api/guides/api-specific-auth"
  }.freeze

  SENSITIVE_FIELDS = %w[
    access_token
    refresh_token
  ].freeze

  belongs_to :business

  encrypts :access_token, :refresh_token

  validates :provider, presence: true, inclusion: { in: Business::FILE_STORAGE_PROVIDERS.keys }
  validates :auth_method, presence: true, inclusion: { in: AUTH_METHODS.keys }
  validates :connected_account_label, presence: true
  validate :require_credentials_for_provider
  validate :external_root_path_must_be_external

  before_validation :normalize_values
  before_validation :assign_auth_method_from_provider
  after_commit :sync_business_storage_settings!, on: %i[create update]
  after_destroy_commit :clear_business_storage_settings!

  def self.auth_method_options
    AUTH_METHODS.map { |value, label| [ label, value ] }
  end

  def provider_label
    Business::FILE_STORAGE_PROVIDERS[provider]
  end

  def auth_method_label
    AUTH_METHODS[auth_method]
  end

  def connected?
    status == "connected"
  end

  def expected_auth_method
    PROVIDER_AUTH_METHODS[provider]
  end

  def documentation_url
    PROVIDER_DOCUMENTATION_URLS[provider]
  end

  private
    def normalize_values
      normalize_external_root_path
      self.status = "connected" if status.blank?
      self.connected_at ||= Time.current if status == "connected"
    end

    def normalize_external_root_path
      return if external_root_path.blank?
      return unless provider == "google_drive"

      value = external_root_path.to_s.strip
      match = value.match(GOOGLE_DRIVE_FOLDER_URL_PATTERN)
      self.external_root_path = match ? match[1] : value
    end

    def assign_auth_method_from_provider
      self.auth_method = expected_auth_method if expected_auth_method.present?
    end

    def require_credentials_for_provider
      validate_presence(:refresh_token, "can't be blank for Google Drive")
      validate_presence(:external_root_path, "can't be blank for Google Drive")
    end

    def external_root_path_must_be_external
      return if external_root_path.blank?

      normalized_path = external_root_path.to_s.downcase
      local_patterns = [
        "storage/",
        "/storage",
        "tmp/storage",
        "local",
        "server",
        "localhost",
        "file://",
        "c:\\",
        "/mnt/",
        "/var/",
        "/home/"
      ]

      return unless local_patterns.any? { |pattern| normalized_path.include?(pattern) }

      errors.add(:external_root_path, "must point to external storage, not local server storage")
    end

    def validate_presence(field, message)
      errors.add(field, message) if public_send(field).blank?
    end

    def sync_business_storage_settings!
      business.update_columns(
        file_storage_provider: provider,
        file_storage_location: storage_location_reference,
        updated_at: Time.current
      )
    end

    def clear_business_storage_settings!
      business.update_columns(
        file_storage_provider: nil,
        file_storage_location: nil,
        updated_at: Time.current
      )
    end

    def storage_location_reference
      external_root_path
    end
end
