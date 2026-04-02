encryption_credentials = Rails.application.credentials[:active_record_encryption] || {}

primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"].presence || encryption_credentials[:primary_key].presence
deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"].presence || encryption_credentials[:deterministic_key].presence
key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"].presence || encryption_credentials[:key_derivation_salt].presence

if primary_key.present? && deterministic_key.present? && key_derivation_salt.present?
  ActiveRecord::Encryption.configure(
    primary_key:,
    deterministic_key:,
    key_derivation_salt:
  )
end
