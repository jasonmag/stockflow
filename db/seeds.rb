owner = User.find_or_create_by!(email_address: "owner@stockflow.local") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
end

business = Business.find_or_create_by!(name: "Stockflow Demo Trading") do |b|
  b.contact_email = "ops@stockflow.local"
  b.contact_phone = "+63 917 000 0000"
  b.address = "Manila"
  b.reminder_lead_days = 7
end

Membership.find_or_create_by!(user: owner, business:) do |m|
  m.role = :owner
end

["Groceries Mart", "FreshStop Supermarket"].each do |name|
  Customer.find_or_create_by!(business:, name:)
end

home = Location.find_or_create_by!(business:, name: "Home Storage") { |l| l.location_type = :home }
warehouse = Location.find_or_create_by!(business:, name: "Main Warehouse") { |l| l.location_type = :warehouse }

products = [
  ["Canned Corn", "CC-001", "pc", 20],
  ["Instant Noodles", "IN-010", "box", 10],
  ["Bottled Water", "BW-100", "case", 8]
].map do |name, sku, unit, reorder|
  Product.find_or_create_by!(business:, name:) do |p|
    p.sku = sku
    p.unit = unit
    p.reorder_level = reorder
    p.active = true
  end
end

Category.find_or_create_by!(business:, name: "Transport")
Category.find_or_create_by!(business:, name: "Utilities")
supplier = Supplier.find_or_create_by!(business:, name: "Metro Supplier Inc")

products.each do |product|
  next if business.stock_movements.where(product: product, movement_type: :in).exists?

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

puts "Seed complete"
puts "Owner login: owner@stockflow.local / password123"
