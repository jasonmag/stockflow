require "test_helper"

class MvpFlowsTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @user = User.create!(email_address: "owner@example.com", password: "password123", password_confirmation: "password123")
    @business = Business.create!(name: "Demo Biz")
    Membership.create!(user: @user, business: @business, role: :owner)

    @category = Category.create!(business: @business, name: "Transport")
    @customer = Customer.create!(business: @business, name: "Sample Market")
    @supplier = Supplier.create!(business: @business, name: "Sample Supplier")
    @location = Location.create!(business: @business, name: "Warehouse", location_type: :warehouse)
    @product = Product.create!(business: @business, name: "Canned Goods", unit: "pc", active: true)

    sign_in_as(@user)
  end

  test "create expense" do
    assert_difference("Expense.count", 1) do
      post expenses_path, params: {
        expense: {
          occurred_on: Date.current,
          payee: "Fuel Station",
          category_id: @category.id,
          amount_cents: 12000,
          currency: "PHP",
          funding_source: "business",
          payment_method: "cash",
          notes: "Delivery fuel",
          receipt: fixture_file_upload("receipt.txt", "text/plain")
        }
      }
    end

    assert_redirected_to expense_path(Expense.last)
  end

  test "owner can update business funding source settings" do
    patch business_path, params: {
      business: {
        reminder_lead_days: 5,
        purchase_funding_sources: "GCash\nCorporate Card"
      }
    }

    assert_redirected_to edit_business_path
    assert_equal [ "GCash", "Corporate Card" ], @business.reload.purchase_funding_source_keys
  end

  test "settings page shows saved funding source options after update" do
    patch business_path, params: {
      business: {
        purchase_funding_sources: "GCash\nCorporate Card"
      }
    }

    follow_redirect!

    assert_response :success
    assert_includes response.body, "GCash\nCorporate Card"
  end

  test "purchase form uses business funding source settings" do
    @business.update!(purchase_funding_source_keys: [ "GCash", "Corporate Card" ])

    get new_purchase_path

    assert_response :success
    assert_select "select[name='purchase[funding_source]'] option", text: "GCash"
    assert_select "select[name='purchase[funding_source]'] option", text: "Corporate Card"
    assert_select "select[name='purchase[funding_source]'] option", text: "Cash Personal", count: 0
    assert_select "select[name='purchase[funding_source]'] option", text: "Cash Business", count: 0
  end

  test "purchase form includes searchable product dropdown for purchase items" do
    get new_purchase_path

    assert_response :success
    assert_select "[data-controller='nested-purchase-items'] button", text: "Add another product"
    assert_select "[data-controller='nested-purchase-items'] template"
    assert_select "section", text: /Product/
    assert_select "div", text: "Product", count: 1
    assert_select "div", text: "Quantity", count: 1
    assert_select "div", text: "Unit cost", count: 1
    assert_select "div", text: "Sub-total", count: 1
    assert_select "[data-controller='product-lookup'] input[type='hidden'][name='purchase[purchase_items_attributes][0][product_id]']"
    assert_select "[data-controller='product-lookup'] input[type='text'][placeholder='Select product']"
    assert_select "[data-controller='product-lookup'] button[aria-label='Toggle product options']"
    assert_select "[data-controller='product-lookup'] .product-lookup-item", text: @product.name
    assert_select "[data-controller='purchase-item-total'] [data-purchase-item-total-target='subtotal']", text: "PHP 0.00"
    assert_select "[data-nested-purchase-items-target='overall']", text: "PHP 0.00"
  end

  test "create purchase rejects funding sources disabled in business settings" do
    @business.update!(purchase_funding_source_keys: [ "GCash" ])

    assert_no_difference("Purchase.count") do
      post purchases_path, params: {
        purchase: {
          supplier_id: @supplier.id,
          purchased_on: Date.current,
          receiving_location_id: @location.id,
          funding_source: "Corporate Card",
          status: "draft",
          purchase_items_attributes: {
            "0" => {
              product_id: @product.id,
              quantity: 2,
              unit_cost_decimal: "1.00"
            }
          }
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Funding source is not enabled in store settings"
  end

  test "create purchase converts decimal unit cost to cents" do
    assert_difference("Purchase.count", 1) do
      post purchases_path, params: {
        purchase: {
          supplier_id: @supplier.id,
          purchased_on: Date.current,
          receiving_location_id: @location.id,
          funding_source: "Cash Business",
          status: "draft",
          purchase_items_attributes: {
            "0" => {
              product_id: @product.id,
              quantity: 2,
              unit_cost_decimal: "12.50"
            }
          }
        }
      }
    end

    assert_equal 1250, Purchase.last.purchase_items.last.unit_cost_cents
    assert_redirected_to purchase_path(Purchase.last)
  end

  test "create product with inventory attributes" do
    assert_difference("Product.count", 1) do
      post products_path, params: {
        product: {
          name: "Vending Cup",
          sku: "VC-777",
          unit: "pc",
          inventory_type: "consumable",
          brand: "Demo Brand",
          barcode: "1234567890123",
          description: "Paper cup for vending use",
          base_cost_decimal: "2.5000",
          reorder_level: 30,
          active: true
        }
      }
    end

    product = Product.last
    assert_equal "consumable", product.inventory_type
    assert_equal "Demo Brand", product.brand
    assert product.sku.present?
    assert_operator product.sku.length, :>=, 30
    assert_equal 250, product.base_cost_cents
    assert_redirected_to product_path(product)
  end

  test "mark payable paid" do
    payable = Payable.create!(business: @business, payable_type: :supplier, payee: "Vendor", amount_cents: 1000, currency: "PHP", due_on: Date.current, status: :unpaid)

    assert_difference("Payment.count", 1) do
      patch mark_paid_payable_path(payable)
    end

    assert payable.reload.paid?
  end

  test "receive purchase creates stock-in movements" do
    purchase = Purchase.create!(business: @business, supplier: @supplier, purchased_on: Date.current, receiving_location: @location, funding_source: "Cash Business", status: :draft)
    purchase.purchase_items.create!(product: @product, quantity: 5, unit_cost_cents: 100)

    assert_difference("StockMovement.count", 1) do
      patch receive_purchase_path(purchase)
    end

    movement = StockMovement.last
    assert_equal "in", movement.movement_type
    assert_equal @location.id, movement.to_location_id
  end

  test "create delivery and mark delivered creates stock-out movements" do
    StockMovement.create!(business: @business, movement_type: :in, product: @product, quantity: 10, unit_cost_cents: 100, to_location: @location, occurred_on: Date.current)

    delivery = Delivery.create!(business: @business, customer: @customer, delivered_on: Date.current, from_location: @location, status: :draft)
    delivery.delivery_items.create!(product: @product, quantity: 4)

    assert_difference("StockMovement.count", 1) do
      patch mark_delivered_delivery_path(delivery)
    end

    assert delivery.reload.delivered?
    movement = StockMovement.last
    assert_equal "out", movement.movement_type
    assert_equal delivery, movement.reference
  end

  test "generate delivery pdf attaches report" do
    delivery = Delivery.create!(business: @business, customer: @customer, delivered_on: Date.current, from_location: @location, status: :draft)
    delivery.delivery_items.create!(product: @product, quantity: 1)

    post generate_pdf_delivery_path(delivery)

    assert delivery.reload.report_pdf.attached?
  end

  test "email delivery pdf enqueues job and creates email log" do
    ActiveJob::Base.queue_adapter = :test
    delivery = Delivery.create!(business: @business, customer: @customer, delivered_on: Date.current, from_location: @location, status: :draft)
    delivery.delivery_items.create!(product: @product, quantity: 1)

    assert_difference("DeliveryEmailLog.count", 1) do
      assert_enqueued_with(job: DeliveryReportEmailJob) do
        post email_pdf_delivery_path(delivery), params: {
          recipients: "ops@example.com;finance@example.com",
          subject: "DR Test",
          message: "Please see attached"
        }
      end
    end

    assert_equal "queued", DeliveryEmailLog.last.status
  ensure
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
