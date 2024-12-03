# Preview all emails at http://localhost:3000/rails/mailers/user
class UserMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/user/contacts_export_notification
  def contacts_export_notification
    UserMailer.with(user_id: 80).contacts_export_notification
  end
end
