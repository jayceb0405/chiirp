class UserMailer < ApplicationMailer
  default from: "Chiirp Support <support@#{I18n.t('tenant.domain')}>"
  layout 'standard_mailer'

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.contacts_export_notification.subject
  #
  def contacts_export_notification
    @user = User.find_by(id: params[:user_id])

    attachments['contacts.csv'] = params[:csv]

    mail to: @user.email, subject: 'Contacts export'
  end

  def two_factor_authentication
    @user = User.find_by(id: params[:user_id])

    mail to: @user.email, subject: 'Two Factor Authentication'
  end
end
