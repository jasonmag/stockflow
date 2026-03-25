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
          funding_source: "Cash",
          payment_method: "credit",
          notes: "Delivery fuel",
          receipt: fixture_file_upload("receipt.txt", "text/plain")
        }
      }
    end

    assert_equal "cash", Expense.last.payment_method
    assert_redirected_to expense_path(Expense.last)
  end

  test "new money forms default to the business currency" do
    @business.update!(currency: "USD")

    get new_expense_path
    assert_response :success
    assert_select "input[name='expense[currency]'][value='USD'][readonly]"

    get new_payable_path
    assert_response :success
    assert_select "input[name='payable[currency]'][value='USD'][readonly]"

    get new_receivable_path
    assert_response :success
    assert_select "input[name='receivable[currency]'][value='USD'][readonly]"
  end

  test "money forms always save using the business currency" do
    @business.update!(currency: "USD")

    post expenses_path, params: {
      expense: {
        occurred_on: Date.current,
        payee: "Fuel Station",
        category_id: @category.id,
        amount_cents: 12000,
        currency: "PHP",
        funding_source: "Cash",
        payment_method: "cash",
        notes: "Delivery fuel",
        receipt: fixture_file_upload("receipt.txt", "text/plain")
      }
    }
    assert_equal "USD", Expense.last.currency

    post payables_path, params: {
      payable: {
        payable_type: "supplier",
        payee: "Vendor",
        amount_cents: 5000,
        currency: "PHP",
        due_on: Date.current,
        status: "unpaid"
      }
    }
    assert_equal "USD", Payable.last.currency

    post receivables_path, params: {
      receivable: {
        customer_id: @customer.id,
        reference: "INV-1",
        delivered_on: Date.current,
        due_on: Date.current + 7.days,
        amount_cents: 7000,
        currency: "PHP",
        status: "pending"
      }
    }
    assert_equal "USD", Receivable.last.currency
  end

  test "expense form shows payables category and payable selector" do
    payable = @business.payables.create!(
      payable_type: :supplier,
      payee: "Vendor One",
      amount_cents: 2500,
      currency: "PHP",
      due_on: Date.current,
      status: :unpaid
    )

    get new_expense_path

    assert_response :success
    assert_select "select[name='expense[category_id]'] option", text: "Payables"
    assert_select "select[name='expense[payable_ids][]'][multiple]"
    assert_includes response.body, payable.payee
  end

  test "credit expense creates payable entry" do
    @business.purchase_funding_sources.create!(name: "Corporate Card", source_type: :credit)

    assert_difference("Payable.count", 1) do
      post expenses_path, params: {
        expense: {
          occurred_on: Date.current,
          payee: "Fuel Station",
          category_id: @category.id,
          amount_cents: 12000,
          currency: "PHP",
          funding_source: "Corporate Card",
          payment_method: "cash",
          notes: "Delivery fuel",
          receipt: fixture_file_upload("receipt.txt", "text/plain")
        }
      }
    end

    payable = Payable.last
    assert_equal Expense.last, payable.expense
    assert_equal "credit_card", payable.payable_type
    assert_equal "Fuel Station", payable.payee
    assert_equal 12000, payable.amount_cents
    assert_equal Date.current, payable.due_on
  end

  test "payables expense creates payments for selected payables" do
    payables_category = @business.categories.find_or_create_by!(name: "Payables")
    payable_one = @business.payables.create!(
      payable_type: :supplier,
      payee: "Vendor One",
      amount_cents: 1200,
      currency: "PHP",
      due_on: Date.current,
      status: :unpaid
    )
    payable_two = @business.payables.create!(
      payable_type: :utilities,
      payee: "Power Co",
      amount_cents: 800,
      currency: "PHP",
      due_on: Date.current,
      status: :unpaid
    )

    assert_difference("Payment.count", 2) do
      post expenses_path, params: {
        expense: {
          occurred_on: Date.current,
          payee: "Will Be Replaced",
          category_id: payables_category.id,
          amount_cents: 1,
          currency: "PHP",
          funding_source: "Cash",
          payment_method: "cash",
          payable_ids: [payable_one.id, payable_two.id],
          notes: "Settled vendor balances",
          receipt: fixture_file_upload("receipt.txt", "text/plain")
        }
      }
    end

    expense = Expense.last
    assert_equal 2000, expense.amount_cents
    assert_equal "Vendor One, Power Co", expense.payee
    assert_equal [payable_one.id, payable_two.id].sort, expense.covered_payables.pluck(:id).sort
    assert_equal [expense.id], payable_one.reload.payments.pluck(:expense_id).uniq
    assert_equal [expense.id], payable_two.reload.payments.pluck(:expense_id).uniq
    assert_equal "paid", payable_one.reload.status
    assert_equal "paid", payable_two.reload.status
  end

  test "payables index shows show and edit actions on each row" do
    payable = @business.payables.create!(
      payable_type: :supplier,
      payee: "Sample Supplier",
      amount_cents: 15000,
      currency: "PHP",
      due_on: Date.current,
      status: :unpaid
    )

    get payables_path

    assert_response :success
    assert_select "a[href='#{payable_path(payable)}']", text: "Show"
    assert_select "a[href='#{edit_payable_path(payable)}']", text: "Edit"
  end

  test "owner can update business funding source settings" do
    patch business_path, params: {
      business: {
        reminder_lead_days: 5,
        currency: "USD"
      }
    }

    assert_redirected_to edit_business_path
    assert_equal 5, @business.reload.reminder_lead_days
    assert_equal "USD", @business.currency
  end

  test "business settings shows currency selector" do
    get edit_business_path

    assert_response :success
    assert_select "select[name='business[currency]'] option[selected='selected']", text: "PHP"
    assert_select "select[name='business[currency]'] option", text: "USD"
  end

  test "business owner can create purchase funding source settings" do
    assert_difference("PurchaseFundingSource.count", 1) do
      post purchase_funding_sources_path, params: {
        purchase_funding_source: {
          name: "GCash",
          source_type: "cash"
        }
      }
    end

    assert_redirected_to purchase_funding_sources_path
    source = PurchaseFundingSource.order(:id).last
    assert_equal "GCash", source.name
    assert_equal "cash", source.source_type
  end

  test "business settings shows supplier and location management links" do
    get edit_business_path

    assert_response :success
    assert_select "h2", text: "Purchase Funding Sources"
    assert_select "a[href='#{purchase_funding_sources_path}']", text: "View Funding Sources"
    assert_select "a[href='#{new_purchase_funding_source_path}']", text: "Add New Funding Source"
    assert_includes response.body, "Cash (Cash)"
    assert_includes response.body, "Credit (Credit)"
    assert_select "h2", text: "Products"
    assert_select "a[href='#{new_product_path(return_to: edit_business_path)}']", text: "Add New Product Variant"
    assert_select "a[href='#{products_path}']", text: "View Products"
    assert_includes response.body, @product.name
    assert_select "h2", text: "Suppliers"
    assert_select "a[href='#{new_supplier_path(return_to: edit_business_path)}']", text: "Add New Supplier"
    assert_select "a[href='#{suppliers_path}']", text: "View Suppliers"
    assert_select "h2", text: "Locations"
    assert_select "a[href='#{new_location_path(return_to: edit_business_path)}']", text: "Add New Location"
    assert_select "a[href='#{locations_path}']", text: "View Locations"
    assert_includes response.body, @supplier.name
    assert_includes response.body, @location.name
  end

  test "purchase form uses business funding source settings" do
    @business.purchase_funding_sources.destroy_all
    @business.purchase_funding_sources.create!(name: "GCash", source_type: :cash)
    @business.purchase_funding_sources.create!(name: "Corporate Card", source_type: :credit)

    get new_purchase_path

    assert_response :success
    assert_select "select[name='purchase[funding_source]'] option", text: "GCash"
    assert_select "select[name='purchase[funding_source]'] option", text: "Corporate Card"
    assert_select "select[name='purchase[funding_source]'] option", text: "Cash", count: 0
    assert_select "select[name='purchase[funding_source]'] option", text: "Credit", count: 0
  end

  test "purchase form links to add a new funding source and returns to purchase flow" do
    get new_purchase_path

    assert_response :success
    assert_select "a[href='#{new_purchase_funding_source_path(return_to: new_purchase_path)}']", text: "Add new funding source"
  end

  test "purchase form links to add a new supplier and returns to purchase flow" do
    get new_purchase_path

    assert_response :success
    assert_select "a[href='#{new_supplier_path(return_to: new_purchase_path)}']", text: "Add new supplier"
  end

  test "purchase form links to add a new location and returns to purchase flow" do
    get new_purchase_path

    assert_response :success
    assert_select "a[href='#{new_location_path(return_to: new_purchase_path)}']", text: "Add new location"
  end

  test "purchase form auto-fills purchase order name from purchased on date" do
    get new_purchase_path

    assert_response :success
    assert_select "input[name='purchase[reference]'][value='PO-#{Date.current}'][readonly]"
    assert_select "input[name='purchase[purchased_on]'][value='#{Date.current}']"
  end

  test "purchase form includes product selection for purchase items" do
    get new_purchase_path

    assert_response :success
    assert_select "[data-controller='nested-purchase-items'] button", text: "Add another product"
    assert_select "a[href='#{new_product_path(return_to: new_purchase_path)}']", text: "Add new inventory variant"
    assert_select "[data-controller='nested-purchase-items'] template"
    assert_select "section", text: /Product/
    assert_select "div", text: "Product", count: 1
    assert_select "div", text: "Quantity", count: 1
    assert_select "div", text: "Unit cost", count: 1
    assert_select "div", text: "Sub-total", count: 1
    assert_select "select[name='purchase[purchase_items_attributes][0][product_id]'] option", text: "Select product"
    assert_select "select[name='purchase[purchase_items_attributes][0][product_id]'] option", text: @product.name
    assert_select "input[name='purchase[purchase_items_attributes][0][unit_cost_decimal]'][data-action*='keydown.enter->nested-purchase-items#addFromUnitCost'][data-action*='keydown.tab->nested-purchase-items#addFromUnitCost']"
    assert_select "[data-controller='purchase-item-total'] [data-purchase-item-total-target='subtotal']", text: "PHP 0.00"
    assert_select "[data-nested-purchase-items-target='item'] button", text: "Remove"
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
          funding_source: "Cash",
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
    assert_equal "PO-#{Date.current}", Purchase.last.reference
    assert_redirected_to purchase_path(Purchase.last)
  end

  test "create purchase ignores trailing blank purchase item rows" do
    assert_difference("Purchase.count", 1) do
      post purchases_path, params: {
        purchase: {
          supplier_id: @supplier.id,
          purchased_on: Date.current,
          receiving_location_id: @location.id,
          funding_source: "Cash",
          status: "draft",
          purchase_items_attributes: {
            "0" => {
              product_id: @product.id,
              quantity: 2,
              unit_cost_decimal: "12.50"
            },
            "1" => {
              product_id: "",
              quantity: "",
              unit_cost_decimal: ""
            }
          }
        }
      }
    end

    assert_redirected_to purchase_path(Purchase.last)
    assert_equal 1, Purchase.last.purchase_items.count
  end

  test "create purchase saves multiple purchase items" do
    second_product = @business.products.where.not(id: @product.id).first || Product.create!(business: @business, name: "Extra Product", unit: "pc", active: true)

    assert_difference("Purchase.count", 1) do
      post purchases_path, params: {
        purchase: {
          supplier_id: @supplier.id,
          purchased_on: Date.current,
          receiving_location_id: @location.id,
          funding_source: "Cash",
          status: "draft",
          purchase_items_attributes: {
            "0" => {
              product_id: @product.id,
              quantity: 2,
              unit_cost_decimal: "12.50"
            },
            "171256-abc" => {
              product_id: second_product.id,
              quantity: 3,
              unit_cost_decimal: "7.25"
            }
          }
        }
      }
    end

    purchase = Purchase.last
    assert_redirected_to purchase_path(purchase)
    assert_equal 2, purchase.purchase_items.count
    assert_equal [@product.id, second_product.id].sort, purchase.purchase_items.pluck(:product_id).sort
  end

  test "create purchase with received status adds items to inventory" do
    assert_difference("StockMovement.count", 1) do
      post purchases_path, params: {
        purchase: {
          supplier_id: @supplier.id,
          purchased_on: Date.current,
          receiving_location_id: @location.id,
          funding_source: "Cash",
          status: "received",
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

    movement = StockMovement.last
    assert_equal "in", movement.movement_type
    assert_equal @location.id, movement.to_location_id
    assert_equal Purchase.last, movement.reference
    assert Purchase.last.received_at.present?
  end

  test "received purchase creates expense entry" do
    assert_difference("Expense.count", 1) do
      post purchases_path, params: {
        purchase: {
          supplier_id: @supplier.id,
          purchased_on: Date.current,
          receiving_location_id: @location.id,
          funding_source: "Cash",
          status: "received",
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

    expense = Expense.last
    assert_equal Purchase.last, expense.purchase
    assert_equal "Purchases", expense.category.name
    assert_equal 2500, expense.amount_cents
    assert_equal "Cash", expense.funding_source
    assert_equal "cash", expense.payment_method
  end

  test "received purchase with credit funding source creates payable entry" do
    @business.purchase_funding_sources.create!(name: "Corporate Card", source_type: :credit)

    assert_difference("Payable.count", 1) do
      post purchases_path, params: {
        purchase: {
          supplier_id: @supplier.id,
          purchased_on: Date.current,
          receiving_location_id: @location.id,
          funding_source: "Corporate Card",
          status: "received",
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

    assert_equal Expense.last, Payable.last.expense
    assert_equal "credit_card", Payable.last.payable_type
  end

  test "update purchase refreshes purchase order name when purchased on changes" do
    purchase = Purchase.create!(business: @business, supplier: @supplier, purchased_on: Date.current, receiving_location: @location, funding_source: "Cash", status: :draft)
    new_date = Date.current + 3.days

    patch purchase_path(purchase), params: {
      purchase: {
        supplier_id: @supplier.id,
        purchased_on: new_date,
        receiving_location_id: @location.id,
        funding_source: "Cash",
        status: "draft",
        purchase_items_attributes: {}
      }
    }

    assert_redirected_to purchase_path(purchase)
    assert_equal "PO-#{new_date}", purchase.reload.reference
  end

  test "update purchase to received adds items to inventory" do
    purchase = Purchase.create!(business: @business, supplier: @supplier, purchased_on: Date.current, receiving_location: @location, funding_source: "Cash", status: :draft)
    purchase.purchase_items.create!(product: @product, quantity: 5, unit_cost_cents: 100)

    assert_difference("StockMovement.count", 1) do
      patch purchase_path(purchase), params: {
        purchase: {
          supplier_id: @supplier.id,
          purchased_on: purchase.purchased_on,
          receiving_location_id: @location.id,
          funding_source: "Cash",
          status: "received",
          purchase_items_attributes: {
            "0" => {
              id: purchase.purchase_items.first.id,
              product_id: @product.id,
              quantity: 5,
              unit_cost_decimal: "1.00"
            }
          }
        }
      }
    end

    movement = StockMovement.last
    assert_equal purchase.reload, movement.reference
    assert_equal "received", purchase.status
  end

  test "update purchase to received creates expense entry" do
    purchase = Purchase.create!(business: @business, supplier: @supplier, purchased_on: Date.current, receiving_location: @location, funding_source: "Cash", status: :draft)
    purchase.purchase_items.create!(product: @product, quantity: 3, unit_cost_cents: 200)

    assert_difference("Expense.count", 1) do
      patch purchase_path(purchase), params: {
        purchase: {
          supplier_id: @supplier.id,
          purchased_on: purchase.purchased_on,
          receiving_location_id: @location.id,
          funding_source: "Cash",
          status: "received",
          purchase_items_attributes: {
            "0" => {
              id: purchase.purchase_items.first.id,
              product_id: @product.id,
              quantity: 3,
              unit_cost_decimal: "2.00"
            }
          }
        }
      }
    end

    assert_equal purchase.reload, Expense.last.purchase
    assert_equal 600, Expense.last.amount_cents
  end

  test "update purchase saves multiple purchase items" do
    purchase = Purchase.create!(business: @business, supplier: @supplier, purchased_on: Date.current, receiving_location: @location, funding_source: "Cash", status: :draft)
    existing_item = purchase.purchase_items.create!(product: @product, quantity: 3, unit_cost_cents: 200)
    second_product = @business.products.where.not(id: @product.id).first || Product.create!(business: @business, name: "Extra Product", unit: "pc", active: true)

    patch purchase_path(purchase), params: {
      purchase: {
        supplier_id: @supplier.id,
        purchased_on: purchase.purchased_on,
        receiving_location_id: @location.id,
        funding_source: "Cash",
        status: "draft",
        purchase_items_attributes: {
          "0" => {
            id: existing_item.id,
            product_id: @product.id,
            quantity: 4,
            unit_cost_decimal: "2.25"
          },
          "171256-abc" => {
            product_id: second_product.id,
            quantity: 2,
            unit_cost_decimal: "7.50"
          }
        }
      }
    }

    assert_redirected_to purchase_path(purchase)
    purchase.reload
    assert_equal 2, purchase.purchase_items.count
    assert_equal [@product.id, second_product.id].sort, purchase.purchase_items.pluck(:product_id).sort
  end

  test "received purchase cannot be edited" do
    purchase = Purchase.create!(business: @business, supplier: @supplier, purchased_on: Date.current, receiving_location: @location, funding_source: "Cash", status: :received)

    get edit_purchase_path(purchase)

    assert_redirected_to purchase_path(purchase)
    assert_equal "Received purchases can no longer be edited.", flash[:alert]
  end

  test "received purchase cannot be updated" do
    purchase = Purchase.create!(business: @business, supplier: @supplier, purchased_on: Date.current, receiving_location: @location, funding_source: "Cash", status: :received)

    patch purchase_path(purchase), params: {
      purchase: {
        supplier_id: @supplier.id,
        purchased_on: Date.current + 1.day,
        receiving_location_id: @location.id,
        funding_source: "Cash",
        status: "received",
        purchase_items_attributes: {}
      }
    }

    assert_redirected_to purchase_path(purchase)
    assert_equal "Received purchases can no longer be edited.", flash[:alert]
    assert_equal Date.current, purchase.reload.purchased_on
  end

  test "purchase actions show delete only for draft purchases" do
    draft_purchase = Purchase.create!(business: @business, supplier: @supplier, purchased_on: Date.current, receiving_location: @location, funding_source: "Cash", status: :draft)
    received_purchase = Purchase.create!(business: @business, supplier: @supplier, purchased_on: Date.current, receiving_location: @location, funding_source: "Cash", status: :received)

    get purchases_path

    assert_response :success
    assert_select "form[action='#{purchase_path(draft_purchase)}'] button", text: "Delete"
    assert_select "form[action='#{purchase_path(received_purchase)}'] button", text: "Delete", count: 0

    get purchase_path(draft_purchase)

    assert_response :success
    assert_select "form[action='#{purchase_path(draft_purchase)}'] button", text: "Delete"

    get purchase_path(received_purchase)

    assert_response :success
    assert_select "form[action='#{purchase_path(received_purchase)}'] button", text: "Delete", count: 0
  end

  test "draft purchase can be deleted" do
    purchase = Purchase.create!(business: @business, supplier: @supplier, purchased_on: Date.current, receiving_location: @location, funding_source: "Cash", status: :draft)

    assert_difference("Purchase.count", -1) do
      delete purchase_path(purchase)
    end

    assert_redirected_to purchases_path
    assert_equal "Purchase deleted.", flash[:notice]
  end

  test "received purchase cannot be deleted" do
    purchase = Purchase.create!(business: @business, supplier: @supplier, purchased_on: Date.current, receiving_location: @location, funding_source: "Cash", status: :received)

    assert_no_difference("Purchase.count") do
      delete purchase_path(purchase)
    end

    assert_redirected_to purchase_path(purchase)
    assert_equal "Received purchases can no longer be deleted.", flash[:alert]
  end

  test "create supplier from purchase flow redirects back with supplier selected" do
    assert_difference("Supplier.count", 1) do
      post suppliers_path(return_to: new_purchase_path), params: {
        supplier: {
          name: "Fresh Vendor"
        }
      }
    end

    assert_redirected_to new_purchase_path(supplier_id: Supplier.last.id)
  end

  test "create location from purchase flow redirects back with location selected" do
    assert_difference("Location.count", 1) do
      post locations_path(return_to: new_purchase_path), params: {
        location: {
          name: "Back Room",
          location_type: "storage"
        }
      }
    end

    assert_redirected_to new_purchase_path(receiving_location_id: Location.last.id)
  end

  test "create funding source from purchase flow redirects back with funding source selected" do
    assert_difference("PurchaseFundingSource.count", 1) do
      post purchase_funding_sources_path(return_to: new_purchase_path), params: {
        purchase_funding_source: {
          name: "Bank Transfer",
          source_type: "credit"
        }
      }
    end

    assert_redirected_to new_purchase_path(funding_source: "Bank Transfer")
  end

  test "create product from purchase flow redirects back to purchase form" do
    assert_difference("Product.count", 1) do
      post products_path(return_to: new_purchase_path), params: {
        product: {
          name: "New Variant",
          unit: "pc",
          inventory_type: "consumable",
          active: true
        }
      }
    end

    assert_redirected_to new_purchase_path
  end

  test "delivery form matches purchase flow affordances" do
    get new_delivery_path

    assert_response :success
    assert_select "input[name='delivery_number_preview'][value='Auto-generated on save'][readonly]"
    assert_select "a[href='#{new_customer_path(return_to: new_delivery_path)}']", text: "Add new customer"
    assert_select "a[href='#{new_location_path(return_to: new_delivery_path)}']", text: "Add new location"
    assert_select "a[href='#{new_product_path(return_to: new_delivery_path)}']", text: "Add new inventory variant"
    assert_select "[data-controller='nested-delivery-items'] button", text: "Add another product"
    assert_select "[data-controller='nested-delivery-items'] template"
    assert_select "div", text: "Product", count: 1
    assert_select "div", text: "Quantity", count: 1
    assert_select "div", text: "Unit price", count: 1
    assert_select "div", text: "Sub-total", count: 1
    assert_select "[data-controller='delivery-item-total'] [data-delivery-item-total-target='subtotal']", text: "PHP 0.00"
    assert_select "[data-nested-delivery-items-target='item'] button", text: "Remove"
    assert_select "[data-nested-delivery-items-target='overall']", text: "PHP 0.00"
  end

  test "create customer from delivery flow redirects back with customer selected" do
    assert_difference("Customer.count", 1) do
      post customers_path(return_to: new_delivery_path), params: {
        customer: {
          name: "Corner Shop"
        }
      }
    end

    assert_redirected_to new_delivery_path(customer_id: Customer.last.id)
  end

  test "create location from delivery flow redirects back with location selected" do
    assert_difference("Location.count", 1) do
      post locations_path(return_to: new_delivery_path), params: {
        location: {
          name: "Delivery Hub",
          location_type: "storage"
        }
      }
    end

    assert_redirected_to new_delivery_path(from_location_id: Location.last.id)
  end

  test "create delivery with delivered status creates stock-out movements" do
    StockMovement.create!(business: @business, movement_type: :in, product: @product, quantity: 10, unit_cost_cents: 100, to_location: @location, occurred_on: Date.current)

    assert_difference("StockMovement.count", 1) do
      post deliveries_path, params: {
        delivery: {
          customer_id: @customer.id,
          delivered_on: Date.current,
          from_location_id: @location.id,
          status: "delivered",
          delivery_items_attributes: {
            "0" => {
              product_id: @product.id,
              quantity: 4,
              unit_price_decimal: "2.50"
            }
          }
        }
      }
    end

    delivery = Delivery.last
    assert_equal "delivered", delivery.status
    assert delivery.inventory_delivered?
    assert_equal delivery, StockMovement.last.reference
    assert delivery.marked_delivered_at.present?
  end

  test "delivered delivery cannot be edited" do
    delivery = Delivery.create!(business: @business, customer: @customer, delivered_on: Date.current, from_location: @location, status: :delivered)

    get edit_delivery_path(delivery)

    assert_redirected_to delivery_path(delivery)
    assert_equal "Delivered records can no longer be edited.", flash[:alert]
  end

  test "delivered delivery cannot be updated" do
    delivery = Delivery.create!(business: @business, customer: @customer, delivered_on: Date.current, from_location: @location, status: :delivered)

    patch delivery_path(delivery), params: {
      delivery: {
        customer_id: @customer.id,
        delivered_on: Date.current + 1.day,
        from_location_id: @location.id,
        status: "delivered",
        delivery_items_attributes: {}
      }
    }

    assert_redirected_to delivery_path(delivery)
    assert_equal "Delivered records can no longer be edited.", flash[:alert]
    assert_equal Date.current, delivery.reload.delivered_on
  end

  test "stock movements index shows current counts by location in a separate table" do
    second_location = Location.create!(business: @business, name: "Storefront", location_type: :storage)
    StockMovement.create!(business: @business, movement_type: :in, product: @product, quantity: 5, unit_cost_cents: 100, to_location: @location, occurred_on: Date.current - 1.day)
    StockMovement.create!(business: @business, movement_type: :transfer, product: @product, quantity: 2, from_location: @location, to_location: second_location, occurred_on: Date.current)

    get stock_movements_path

    assert_response :success
    assert_select "h2", text: "Current Counts By Location"
    assert_select "h3", text: "Warehouse"
    assert_select "h3", text: "Storefront"
    assert_select "th", text: "Current Count"
    assert_select "td", text: "3"
    assert_select "td", text: "2"
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
    purchase = Purchase.create!(business: @business, supplier: @supplier, purchased_on: Date.current, receiving_location: @location, funding_source: "Cash", status: :draft)
    purchase.purchase_items.create!(product: @product, quantity: 5, unit_cost_cents: 100)

    assert_difference("StockMovement.count", 1) do
      patch receive_purchase_path(purchase)
    end

    movement = StockMovement.last
    assert_equal "in", movement.movement_type
    assert_equal @location.id, movement.to_location_id
  end

  test "receive purchase creates expense once" do
    purchase = Purchase.create!(business: @business, supplier: @supplier, purchased_on: Date.current, receiving_location: @location, funding_source: "Cash", status: :draft)
    purchase.purchase_items.create!(product: @product, quantity: 5, unit_cost_cents: 100)

    assert_difference("Expense.count", 1) do
      patch receive_purchase_path(purchase)
    end

    assert_no_difference("Expense.count") do
      patch receive_purchase_path(purchase)
    end
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

  test "mark delivered reduces current inventory count" do
    StockMovement.create!(business: @business, movement_type: :in, product: @product, quantity: 10, unit_cost_cents: 100, to_location: @location, occurred_on: Date.current)
    delivery = Delivery.create!(business: @business, customer: @customer, delivered_on: Date.current, from_location: @location, status: :draft)
    delivery.delivery_items.create!(product: @product, quantity: 4)

    patch mark_delivered_delivery_path(delivery)

    get stock_movements_path

    assert_response :success
    assert_select "h3", text: "Warehouse"
    assert_select "td", text: "6"
  end

  test "mark delivered logs action date and uses it in inventory movement" do
    StockMovement.create!(business: @business, movement_type: :in, product: @product, quantity: 10, unit_cost_cents: 100, to_location: @location, occurred_on: Date.current)
    delivery = Delivery.create!(business: @business, customer: @customer, delivered_on: Date.current - 3.days, from_location: @location, status: :draft)
    delivery.delivery_items.create!(product: @product, quantity: 4)

    patch mark_delivered_delivery_path(delivery)

    delivery.reload
    movement = StockMovement.order(:id).last
    assert delivery.marked_delivered_at.present?
    assert_equal Date.current, delivery.marked_delivered_at.to_date
    assert_equal Date.current, movement.occurred_on
  end

  test "stock movements index shows delivery customer as destination" do
    StockMovement.create!(business: @business, movement_type: :in, product: @product, quantity: 10, unit_cost_cents: 100, to_location: @location, occurred_on: Date.current)
    delivery = Delivery.create!(business: @business, customer: @customer, delivered_on: Date.current, from_location: @location, status: :draft)
    delivery.delivery_items.create!(product: @product, quantity: 4)

    patch mark_delivered_delivery_path(delivery)
    get stock_movements_path

    assert_response :success
    assert_select "td", text: @location.name
    assert_select "td", text: @customer.name
  end

  test "stock movements index shows purchase supplier as source" do
    post purchases_path, params: {
      purchase: {
        supplier_id: @supplier.id,
        purchased_on: Date.current,
        receiving_location_id: @location.id,
        funding_source: "Cash",
        status: "received",
        purchase_items_attributes: {
          "0" => {
            product_id: @product.id,
            quantity: 2,
            unit_cost_decimal: "12.50"
          }
        }
      }
    }

    get stock_movements_path

    assert_response :success
    assert_select "td", text: @supplier.name
    assert_select "td", text: @location.name
  end

  test "receive purchase logs action date and uses it in inventory movement" do
    purchase = Purchase.create!(business: @business, supplier: @supplier, purchased_on: Date.current - 3.days, receiving_location: @location, funding_source: "Cash", status: :draft)
    purchase.purchase_items.create!(product: @product, quantity: 2, unit_cost_cents: 1250)

    patch receive_purchase_path(purchase)

    purchase.reload
    movement = StockMovement.order(:id).last
    assert purchase.received_at.present?
    assert_equal Date.current, purchase.received_at.to_date
    assert_equal Date.current, movement.occurred_on
  end

  test "mark delivered only deducts inventory once" do
    StockMovement.create!(business: @business, movement_type: :in, product: @product, quantity: 10, unit_cost_cents: 100, to_location: @location, occurred_on: Date.current)
    delivery = Delivery.create!(business: @business, customer: @customer, delivered_on: Date.current, from_location: @location, status: :draft)
    delivery.delivery_items.create!(product: @product, quantity: 4)

    patch mark_delivered_delivery_path(delivery)

    assert_no_difference("StockMovement.count") do
      patch mark_delivered_delivery_path(delivery)
    end

    totals = Inventory::OnHandCalculator.new(business: @business).totals_by_product
    assert_equal 6.0, totals[@product.id]
  end

  test "generate delivery pdf attaches report" do
    delivery = Delivery.create!(business: @business, customer: @customer, delivered_on: Date.current, from_location: @location, status: :draft)
    delivery.delivery_items.create!(product: @product, quantity: 1)

    post generate_pdf_delivery_path(delivery)

    assert delivery.reload.report_pdf.attached?
  end

  test "preview delivery pdf streams inline without saving a delivery" do
    assert_no_difference("Delivery.count") do
      get preview_pdf_deliveries_path, params: {
        delivery: {
          customer_id: @customer.id,
          delivered_on: Date.current,
          from_location_id: @location.id,
          status: "draft",
          show_prices: "1",
          notes: "Preview only",
          delivery_items_attributes: {
            "0" => {
              product_id: @product.id,
              quantity: 2,
              unit_price_decimal: "12.50"
            }
          }
        }
      }
    end

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_includes response.headers["Content-Disposition"], "inline"
  end

  test "preview saved delivery pdf streams inline" do
    delivery = Delivery.create!(business: @business, customer: @customer, delivered_on: Date.current, from_location: @location, status: :draft)
    delivery.delivery_items.create!(product: @product, quantity: 1, unit_price_cents: 1250)

    get preview_pdf_delivery_path(delivery)

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_includes response.headers["Content-Disposition"], "inline"
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
