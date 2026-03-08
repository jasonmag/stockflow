namespace :admin do
  desc "Ensure a super admin exists using ADMIN_EMAIL and ADMIN_PASSWORD"
  task ensure: :environment do
    email = ENV.fetch("ADMIN_EMAIL", "").strip.downcase
    password = ENV.fetch("ADMIN_PASSWORD", "")

    if email.empty? || password.empty?
      warn "ADMIN_EMAIL and ADMIN_PASSWORD must be set."
      next
    end

    user = User.find_or_initialize_by(email: email)
    if user.new_record?
      company = Company.order(:id).first || Company.create!(name: "Admin Company", address: "")
      user.company = company
      user.role = :super_admin
      user.password = password
      user.password_confirmation = password
      user.save!
      puts "Created super admin for #{email}."
    else
      user.update!(role: :super_admin) unless user.super_admin?
      puts "Super admin already exists for #{email}."
    end
  end
end
