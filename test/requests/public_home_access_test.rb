require "test_helper"

class PublicHomeAccessTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "home-test-owner@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @system_admin = User.create!(
      email_address: "home-test-admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      system_admin: true
    )
    @business = Business.create!(name: "Home Test Biz")
    Membership.create!(user: @user, business: @business, role: :owner)
  end

  test "non-authenticated users can access home and about pages" do
    get root_path
    assert_response :success

    get about_path
    assert_response :success
  end

  test "logging out redirects to public home" do
    sign_in_as(@user)

    delete session_path

    assert_redirected_to root_path
  end

  test "admin logout redirects to public home" do
    post session_path, params: {
      email_address: @system_admin.email_address,
      password: "password123",
      login_scope: "admin"
    }
    follow_redirect!
    assert_response :success

    delete session_path

    assert_redirected_to root_path
  end

  test "user login redirects to user dashboard" do
    post session_path, params: {
      email_address: @user.email_address,
      password: "password123",
      login_scope: "user"
    }

    assert_redirected_to dashboard_path
  end

  test "admin login redirects to admin dashboard for system admin" do
    post session_path, params: {
      email_address: @system_admin.email_address,
      password: "password123",
      login_scope: "admin"
    }

    assert_redirected_to admin_root_path
  end

  test "admin login rejects non-system admin accounts" do
    post session_path, params: {
      email_address: @user.email_address,
      password: "password123",
      login_scope: "admin"
    }

    assert_redirected_to admin_login_path
    assert_equal "System admin access is required for admin login.", flash[:alert]
  end
end
