namespace :admin do
  desc "Ensure a system admin exists"
  task ensure: :environment do
    email_address = ENV.fetch("ADMIN_EMAIL", "").strip.downcase
    password = ENV.fetch("ADMIN_PASSWORD", "")

    if email_address.empty? || password.empty?
      puts "Skipping admin:ensure because ADMIN_EMAIL or ADMIN_PASSWORD is blank."
      next
    end

    user = User.find_or_initialize_by(email_address: email_address)

    if user.new_record?
      user.password = password
      user.password_confirmation = password
      user.approved = true
      user.approved_at = Time.current
      user.approved_by = nil
      user.system_admin = true
      user.save!

      puts "Created system admin for #{email_address}."
    else
      updates = {}
      updates[:system_admin] = true unless user.system_admin?
      updates[:approved] = true unless user.approved?
      updates[:approved_at] = Time.current if user.approved_at.blank?

      user.update!(updates) if updates.any?

      puts "System admin already exists for #{email_address}."
    end
  end
end
