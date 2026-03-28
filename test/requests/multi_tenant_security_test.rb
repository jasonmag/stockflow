require "test_helper"

class MultiTenantSecurityTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email_address: "owner-security@example.com", password: "password123", password_confirmation: "password123")
    @staff = User.create!(email_address: "staff-security@example.com", password: "password123", password_confirmation: "password123")
    @system_admin = User.create!(email_address: "sysadmin-security@example.com", password: "password123", password_confirmation: "password123", system_admin: true)

    @business_one = Business.create!(name: "Business One")
    @business_two = Business.create!(name: "Business Two")

    Membership.create!(user: @owner, business: @business_one, role: :owner)
    Membership.create!(user: @owner, business: @business_two, role: :owner)
    Membership.create!(user: @staff, business: @business_one, role: :staff)

    @category_one = Category.create!(business: @business_one, name: "Ops")
    @supplier_one = Supplier.create!(business: @business_one, name: "Supplier One")
    @supplier_two = Supplier.create!(business: @business_two, name: "Supplier Two")
    @location_one = Location.create!(business: @business_one, name: "Warehouse One", location_type: :warehouse)
    @location_two = Location.create!(business: @business_two, name: "Warehouse Two", location_type: :warehouse)
    @customer_one = Customer.create!(business: @business_one, name: "Market One")
    @product_one = Product.create!(business: @business_one, name: "Prod One", unit: "pc")
    @product_two = Product.create!(business: @business_two, name: "Prod Two", unit: "pc")
  end

  test "staff cannot access owner-only operations pages" do
    sign_in_as(@staff)

    get new_expense_path

    assert_redirected_to root_path
    assert_equal "Not authorized.", flash[:alert]
  end

  test "staff cannot create new inventory products" do
    sign_in_as(@staff)

    assert_no_difference("Product.count") do
      post products_path, params: {
        product: {
          name: "Staff Product",
          unit: "pc",
          inventory_type: "stock_item"
        }
      }
    end

    assert_redirected_to root_path
    assert_equal "Not authorized.", flash[:alert]
  end

  test "non-system admin cannot access admin namespace" do
    sign_in_as(@owner)

    get admin_root_path

    assert_redirected_to root_path
    assert_equal "Only system admins can do that.", flash[:alert]
  end

  test "system admin can access admin namespace without memberships" do
    sign_in_as(@system_admin)

    get admin_root_path

    assert_response :success
  end

  test "system admin cannot access regular dashboard without impersonation" do
    post session_path, params: {
      email_address: @system_admin.email_address,
      password: "password123",
      login_scope: "admin"
    }
    follow_redirect!

    get dashboard_path

    assert_redirected_to admin_root_path
    assert_equal "Use impersonation to access store operations.", flash[:alert]
  end

  test "system admin can impersonate an owner to access regular dashboard" do
    post session_path, params: {
      email_address: @system_admin.email_address,
      password: "password123",
      login_scope: "admin"
    }
    follow_redirect!

    post admin_impersonation_path, params: { user_id: @owner.id, business_id: @business_one.id }
    assert_redirected_to dashboard_path

    get dashboard_path
    assert_response :success

    delete admin_impersonation_path
    assert_redirected_to admin_root_path
  end

  test "system admin can impersonate a staff user to access regular dashboard" do
    post session_path, params: {
      email_address: @system_admin.email_address,
      password: "password123",
      login_scope: "admin"
    }
    follow_redirect!

    post admin_impersonation_path, params: { user_id: @staff.id, business_id: @business_one.id }
    assert_redirected_to dashboard_path

    get dashboard_path
    assert_response :success
  end

  test "cannot remove last owner membership from a business" do
    sign_in_as(@system_admin)

    owner_membership = Membership.find_by!(user: @owner, business: @business_one)

    delete admin_membership_path(owner_membership)

    assert_redirected_to admin_user_path(@owner)
    assert_equal "Cannot remove the last store admin account for this business.", flash[:alert]
    assert Membership.exists?(owner_membership.id)
  end

  test "business owner can add members to current business" do
    ActiveJob::Base.queue_adapter = :test
    ActionMailer::Base.deliveries.clear
    sign_in_as(@owner)
    patch switch_business_path, params: { business_id: @business_one.id }

    assert_difference("Membership.count", 1) do
      perform_enqueued_jobs do
        post add_member_business_path, params: {
          membership: {
            email_address: "new-member@example.com",
            role: "staff"
          }
        }
      end
    end

    membership = Membership.order(:id).last
    assert_equal @business_one.id, membership.business_id
    assert_equal "staff", membership.role
    assert_equal "new-member@example.com", membership.user.email_address
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal [ "new-member@example.com" ], ActionMailer::Base.deliveries.last.to
  ensure
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "business owner can remove members from current business" do
    sign_in_as(@owner)
    patch switch_business_path, params: { business_id: @business_one.id }

    membership = Membership.find_by!(user: @staff, business: @business_one)

    assert_difference("Membership.count", -1) do
      delete remove_member_business_path(membership_id: membership.id)
    end

    assert_redirected_to members_business_path
    assert_equal "Member removed from Business One.", flash[:notice]
    assert_not Membership.exists?(membership.id)
  end

  test "business owner cannot remove last owner membership from current business" do
    sign_in_as(@owner)
    patch switch_business_path, params: { business_id: @business_one.id }

    membership = Membership.find_by!(user: @owner, business: @business_one)

    assert_no_difference("Membership.count") do
      delete remove_member_business_path(membership_id: membership.id)
    end

    assert_redirected_to members_business_path
    assert_equal "Cannot remove the last store admin account for this business.", flash[:alert]
    assert Membership.exists?(membership.id)
  end

  test "staff cannot access owner member management page" do
    sign_in_as(@staff)

    get members_business_path

    assert_redirected_to root_path
    assert_equal "Only owners can do that.", flash[:alert]
  end

  test "staff cannot access owner business settings page" do
    sign_in_as(@staff)

    get edit_business_path

    assert_redirected_to root_path
    assert_equal "Only owners can do that.", flash[:alert]
  end

  test "system admin can create business stores" do
    sign_in_as(@system_admin)

    assert_difference("Business.count", 1) do
      post admin_businesses_path, params: {
        business: {
          name: "Business Three",
          reminder_lead_days: 5
        }
      }
    end

    assert_redirected_to admin_business_path(Business.order(:id).last)
  end

  test "system admin can manage business memberships from admin business page" do
    sign_in_as(@system_admin)
    extra_user = User.create!(email_address: "new-admin-business-member@example.com", password: "password123", password_confirmation: "password123")

    assert_difference("Membership.count", 1) do
      post admin_memberships_path, params: {
        redirect_to: "business",
        membership: {
          user_id: extra_user.id,
          business_id: @business_one.id,
          role: "staff"
        }
      }
    end

    membership = Membership.find_by!(user: extra_user, business: @business_one)
    assert_redirected_to admin_business_path(@business_one)
    assert_equal "Membership created.", flash[:notice]

    patch admin_membership_path(membership), params: {
      redirect_to: "business",
      membership: {
        role: "owner"
      }
    }

    assert_redirected_to admin_business_path(@business_one)
    assert_equal "owner", membership.reload.role

    assert_difference("Membership.count", -1) do
      delete admin_membership_path(membership), params: { redirect_to: "business" }
    end

    assert_redirected_to admin_business_path(@business_one)
    assert_equal "Membership removed.", flash[:notice]
  end

  test "system admin can invite users from admin business page" do
    ActiveJob::Base.queue_adapter = :test
    ActionMailer::Base.deliveries.clear
    sign_in_as(@system_admin)

    assert_difference("User.count", 1) do
      assert_difference("Membership.count", 1) do
        perform_enqueued_jobs do
          post invite_member_admin_business_path(@business_one), params: {
            membership: {
              email_address: "invited-from-admin@example.com",
              role: "staff"
            }
          }
        end
      end
    end

    invited_user = User.find_by!(email_address: "invited-from-admin@example.com")
    membership = Membership.find_by!(user: invited_user, business: @business_one)

    assert_equal "staff", membership.role
    assert_redirected_to admin_business_path(@business_one)
    assert_equal "Member invited to Business One. A set-password email has been sent.", flash[:notice]
    assert_equal [ "invited-from-admin@example.com" ], ActionMailer::Base.deliveries.last.to
  ensure
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "purchase rejects supplier from another business" do
    sign_in_as(@owner)

    assert_no_difference("Purchase.count") do
      post purchases_path, params: {
        purchase: {
          supplier_id: @supplier_two.id,
          purchased_on: Date.current,
          receiving_location_id: @location_one.id,
          funding_source: "Cash",
          purchase_items_attributes: {
            "0" => {
              product_id: @product_one.id,
              quantity: 1,
              unit_cost_cents: 100
            }
          }
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "delivery rejects item product from another business" do
    sign_in_as(@owner)

    assert_no_difference("Delivery.count") do
      post deliveries_path, params: {
        delivery: {
          customer_id: @customer_one.id,
          delivered_on: Date.current,
          from_location_id: @location_one.id,
          delivery_items_attributes: {
            "0" => {
              product_id: @product_two.id,
              quantity: 1
            }
          }
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "stock movement rejects cross-business location" do
    sign_in_as(@owner)

    assert_no_difference("StockMovement.count") do
      post stock_movements_path, params: {
        stock_movement: {
          movement_type: :out,
          product_id: @product_one.id,
          quantity: 1,
          from_location_id: @location_two.id,
          occurred_on: Date.current
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
