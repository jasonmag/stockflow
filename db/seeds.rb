def ensure_user(email:, password:, system_admin: false)
  user = User.find_or_initialize_by(email_address: email)
  user.password = password
  user.password_confirmation = password
  user.system_admin = system_admin
  user.save!
  user
end

def ensure_membership(user:, business:, role:)
  membership = Membership.find_or_initialize_by(user:, business:)
  membership.role = role
  membership.save!
  membership
end

def seed_business_data(business:, owner_user:, staff_user:)
  ensure_membership(user: owner_user, business:, role: :owner)
  ensure_membership(user: staff_user, business:, role: :staff)

  Category.find_or_create_by!(business:, name: "Transport")
  Category.find_or_create_by!(business:, name: "Utilities")
  Supplier.find_or_create_by!(business:, name: "#{business.name} Supplier")

  ["Groceries Mart", "FreshStop Supermarket"].each do |name|
    Customer.find_or_create_by!(business:, name:)
  end

  warehouse = Location.find_or_create_by!(business:, name: "#{business.name} Warehouse") do |location|
    location.location_type = :warehouse
  end

  [
    ["Canned Corn", "CC-001", "pc", 20],
    ["Instant Noodles", "IN-010", "box", 10],
    ["Bottled Water", "BW-100", "case", 8]
  ].each do |name, sku, unit, reorder_level|
    product = Product.find_or_create_by!(business:, name:) do |record|
      record.sku = sku
      record.unit = unit
      record.reorder_level = reorder_level
      record.active = true
    end

    next if business.stock_movements.where(product:, movement_type: :in).exists?

    StockMovement.create!(
      business:,
      movement_type: :in,
      product:,
      quantity: 50,
      unit_cost_cents: 1000,
      to_location: warehouse,
      occurred_on: Date.current,
      notes: "Seed stock"
    )
  end
end

system_admin = ensure_user(
  email: "admin@stockflow.local",
  password: "password123",
  system_admin: true
)

north_owner = ensure_user(
  email: "owner.north@stockflow.local",
  password: "password123"
)

south_owner = ensure_user(
  email: "owner.south@stockflow.local",
  password: "password123"
)

store_staff = ensure_user(
  email: "staff@stockflow.local",
  password: "password123"
)

north_business = Business.find_or_create_by!(name: "Stockflow North Trading") do |business|
  business.contact_email = "north.ops@stockflow.local"
  business.contact_phone = "+63 917 100 0000"
  business.address = "Quezon City"
  business.reminder_lead_days = 7
end

south_business = Business.find_or_create_by!(name: "Stockflow South Trading") do |business|
  business.contact_email = "south.ops@stockflow.local"
  business.contact_phone = "+63 917 200 0000"
  business.address = "Makati"
  business.reminder_lead_days = 7
end

seed_business_data(business: north_business, owner_user: north_owner, staff_user: store_staff)
seed_business_data(business: south_business, owner_user: south_owner, staff_user: store_staff)

puts "Seed complete"
puts "System admin: admin@stockflow.local / password123"
puts "North store admin: owner.north@stockflow.local / password123"
puts "South store admin: owner.south@stockflow.local / password123"
puts "Store staff: staff@stockflow.local / password123"
