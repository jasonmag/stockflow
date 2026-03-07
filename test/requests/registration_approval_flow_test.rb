require "test_helper"

class RegistrationApprovalFlowTest < ActionDispatch::IntegrationTest
  setup do
    @system_admin = User.create!(
      email_address: "admin-registration@example.com",
      password: "password123",
      password_confirmation: "password123",
      system_admin: true
    )
    @business = Business.create!(name: "Approval Biz")
  end

  test "regular registration creates pending user without business assignment" do
    assert_difference("User.count", 1) do
      post registration_path, params: {
        user: {
          email_address: "pending-user@example.com",
          password: "password123",
          password_confirmation: "password123"
        },
        membership: {
          business_id: @business.id
        }
      }
    end

    user = User.find_by!(email_address: "pending-user@example.com")
    assert_equal false, user.approved?
    assert_empty user.businesses
    assert_redirected_to login_path
  end

  test "pending regular user cannot sign in" do
    User.create!(
      email_address: "pending-login@example.com",
      password: "password123",
      password_confirmation: "password123",
      approved: false
    )

    post session_path, params: {
      email_address: "pending-login@example.com",
      password: "password123",
      login_scope: "user"
    }

    assert_redirected_to login_path
    assert_equal "Your account is pending super admin approval.", flash[:alert]
  end

  test "super admin can approve a pending registration" do
    pending_user = User.create!(
      email_address: "approve-me@example.com",
      password: "password123",
      password_confirmation: "password123",
      approved: false
    )

    post session_path, params: {
      email_address: @system_admin.email_address,
      password: "password123",
      login_scope: "admin"
    }
    follow_redirect!

    patch approve_admin_user_path(pending_user)

    assert_redirected_to admin_user_path(pending_user)
    pending_user.reload
    assert pending_user.approved?
    assert_not_nil pending_user.approved_at
    assert_equal @system_admin.id, pending_user.approved_by_id
  end
end
