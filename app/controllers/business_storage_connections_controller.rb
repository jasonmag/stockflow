class BusinessStorageConnectionsController < ApplicationController
  before_action :require_owner!
  before_action :set_storage_connection, only: %i[update destroy google_drive_callback]

  def connect_google_drive
    unless google_drive_oauth_configured?
      redirect_to edit_business_path, alert: "Google Drive OAuth is not configured."
      return
    end

    state = SecureRandom.hex(24)
    session[:google_drive_oauth_state] = state

    redirect_to google_drive_oauth_client.authorization_uri(
      state:,
      redirect_uri: google_drive_callback_business_storage_connection_url
    ), allow_other_host: true
  end

  def google_drive_callback
    if params[:error].present?
      redirect_to edit_business_path, alert: "Google Drive access was not granted."
      return
    end

    if params[:state].blank? || params[:state] != session.delete(:google_drive_oauth_state)
      redirect_to edit_business_path, alert: "Google Drive authorization could not be verified."
      return
    end

    token_response = google_drive_oauth_client.exchange_code(
      code: params[:code],
      redirect_uri: google_drive_callback_business_storage_connection_url
    )
    profile = google_drive_oauth_client.drive_profile(access_token: token_response.fetch(:access_token))

    connection = @storage_connection || current_business.build_storage_connection
    connection.assign_attributes(
      provider: "google_drive",
      auth_method: "oauth2",
      connected_account_label: profile[:email_address].presence || profile[:display_name],
      external_root_path: connection.external_root_path.presence || "root",
      access_token: token_response.fetch(:access_token),
      refresh_token: token_response[:refresh_token].presence || connection.refresh_token
    )

    if connection.save
      redirect_to edit_business_path, notice: "Google Drive connected."
    else
      @storage_connection = connection
      load_business_settings
      render "businesses/edit", status: :unprocessable_entity
    end
  rescue StandardError => error
    redirect_to edit_business_path, alert: error.message
  end

  def update
    @business = current_business

    if @storage_connection.update(storage_connection_params)
      redirect_to edit_business_path, notice: "Storage connection updated."
    else
      load_business_settings
      render "businesses/edit", status: :unprocessable_entity
    end
  end

  def destroy
    @storage_connection.destroy
    redirect_to edit_business_path, notice: "Storage connection removed."
  end

  private
    def set_storage_connection
      @storage_connection = current_business.storage_connection
      @business = current_business
    end

    def storage_connection_params
      permitted = params.require(:storage_connection).permit(
        :external_root_path,
        :connected_account_label
      ).to_h
      permitted.merge(provider: "google_drive", auth_method: "oauth2")
    end

    def load_business_settings
      @purchase_funding_sources = current_business.purchase_funding_sources.order(:name)
      @products = current_business.products.order(:name)
      @suppliers = current_business.suppliers.order(:name)
      @locations = current_business.locations.order(:name)
      @storage_connection ||= current_business.build_storage_connection(
        provider: @business.file_storage_provider,
        external_root_path: @business.file_storage_location
      )
    end

    def google_drive_oauth_configured?
      google_drive_client_id.present? && google_drive_client_secret.present?
    end

    def google_drive_oauth_client
      @google_drive_oauth_client ||= GoogleDriveOauthClient.new(
        client_id: google_drive_client_id,
        client_secret: google_drive_client_secret
      )
    end

    def google_drive_client_id
      ENV["GOOGLE_DRIVE_CLIENT_ID"].presence || Rails.application.credentials.dig(:google_drive, :client_id).presence
    end

    def google_drive_client_secret
      ENV["GOOGLE_DRIVE_CLIENT_SECRET"].presence || Rails.application.credentials.dig(:google_drive, :client_secret).presence
    end
end
