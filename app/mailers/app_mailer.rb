# class AppMailer < ActionMailer::Base
class AppMailer < Devise::Mailer
  # give access to all helpers defined within `application_helper`
  helper :application

  # Optional. eg. `confirmation_url`
  include Devise::Controllers::UrlHelpers

  # to make sure that your mailer uses the devise views
  default template_path: 'devise/mailer'

  default from: "#{I18n.t('tenant.name')} Support <support@#{I18n.t('tenant.domain')}>"
  default reply_to: "#{I18n.t('tenant.name')} Support <support@#{I18n.t('tenant.domain')}>"

  def confirmation_instructions(record, token, opts = {})
    opts[:from] = "#{I18n.t('tenant.name')} Support <support@#{I18n.t('tenant.domain')}>"
    opts[:reply_to] = "#{I18n.t('tenant.name')} Support <support@#{I18n.t('tenant.domain')}>"
    super
  end

  def reset_password_instructions(record, token, opts = {})
    opts[:from] = "#{I18n.t('tenant.name')} Support <support@#{I18n.t('tenant.domain')}>"
    opts[:reply_to] = "#{I18n.t('tenant.name')} Support <support@#{I18n.t('tenant.domain')}>"
    super
  end

  def unlock_instructions(record, token, opts = {})
    opts[:from] = "#{I18n.t('tenant.name')} Support <support@#{I18n.t('tenant.domain')}>"
    opts[:reply_to] = "#{I18n.t('tenant.name')} Support <support@#{I18n.t('tenant.domain')}>"
    super
  end

  def invitation_instructions(record, token, opts = {})
    opts[:host] = I18n.t("tenant.#{Rails.env}.app_host")
    opts[:from] = "#{I18n.t('tenant.name')} Support <support@#{I18n.t('tenant.domain')}>"
    opts[:reply_to] = "#{I18n.t('tenant.name')} Support <support@#{I18n.t('tenant.domain')}>"
    super
  end
end
