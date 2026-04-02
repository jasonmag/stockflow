class GoogleDriveAttachmentSync
  class Error < StandardError; end

  def initialize(record:, attachment_name:, folder_name:, tracking_prefix:, filename_prefix:, replace_existing: false)
    @record = record
    @attachment_name = attachment_name
    @folder_name = folder_name
    @tracking_prefix = tracking_prefix
    @filename_prefix = filename_prefix
    @replace_existing = replace_existing
  end

  def sync!
    return unless attachment.attached?

    connection = business.storage_connection
    return unless connection&.provider == "google_drive"
    return if already_synced? && !replace_existing

    token_response = google_drive_oauth_client.refresh_access_token(refresh_token: connection.refresh_token)
    access_token = token_response.fetch(:access_token)
    connection.update!(access_token:)

    delete_existing_file!(access_token:)

    parent_folder_id = google_drive_oauth_client.ensure_child_folder(
      access_token:,
      parent_folder_id: connection.external_root_path,
      name: folder_name
    )

    upload_response = attachment.blob.open do |file|
      google_drive_oauth_client.upload_file(
        access_token:,
        io: file,
        filename: drive_filename,
        content_type: attachment.blob.content_type,
        parent_folder_id:
      )
    end

    record.update_columns(
      "#{tracking_prefix}_file_id" => upload_response.fetch(:id),
      "#{tracking_prefix}_url" => upload_response[:web_view_link],
      "#{tracking_prefix}_blob_id" => attachment.blob_id,
      "#{tracking_prefix}_synced_at" => Time.current,
      "#{tracking_prefix}_error" => nil,
      updated_at: Time.current
    )
  rescue StandardError => e
    record.update_columns(
      "#{tracking_prefix}_error" => e.message,
      updated_at: Time.current
    )
    raise Error, e.message
  end

  private
    attr_reader :record, :attachment_name, :folder_name, :tracking_prefix, :filename_prefix, :replace_existing

    def attachment
      @attachment ||= record.public_send(attachment_name)
    end

    def business
      record.business
    end

    def already_synced?
      record.public_send("#{tracking_prefix}_file_id").present? &&
        record.public_send("#{tracking_prefix}_blob_id") == attachment.blob_id
    end

    def delete_existing_file!(access_token:)
      existing_file_id = record.public_send("#{tracking_prefix}_file_id")
      return if existing_file_id.blank?

      google_drive_oauth_client.delete_file(access_token:, file_id: existing_file_id)
    rescue StandardError
      # If the previous file is already gone, continue with the replacement upload.
      true
    end

    def google_drive_oauth_client
      @google_drive_oauth_client ||= GoogleDriveOauthClient.new(
        client_id: ENV["GOOGLE_DRIVE_CLIENT_ID"].presence || Rails.application.credentials.dig(:google_drive, :client_id).presence,
        client_secret: ENV["GOOGLE_DRIVE_CLIENT_SECRET"].presence || Rails.application.credentials.dig(:google_drive, :client_secret).presence
      )
    end

    def drive_filename
      "#{filename_prefix}-#{attachment.blob.filename}"
    end
end
