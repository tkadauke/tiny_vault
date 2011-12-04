class PasswordResetsMailer < ActionMailer::Base
  def password_reset_instructions(user)
    subject       I18n.t("password_reset_mailer.subject")
    from          "TinyVault <#{TinyVault::Config.email_sender_address}>"
    recipients    user.email
    sent_on       Time.now

    @edit_password_reset_path = edit_password_reset_path(user.perishable_token)
  end
end
