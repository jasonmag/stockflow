class MembershipInvitationMailer < ApplicationMailer
  def invite(user:, business:, inviter:, role:, new_user:)
    @user = user
    @business = business
    @inviter = inviter
    @role = role
    @new_user = new_user
    @set_password_url = edit_password_url(@user.password_reset_token)
    @login_url = login_url

    mail(
      to: @user.email_address,
      subject: invitation_subject
    )
  end

  private
    def invitation_subject
      "Invitation to join #{@business.name} on Stockflow"
    end
end
