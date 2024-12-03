class ApplicationMailer < ActionMailer::Base
  default from: "Support <support@#{I18n.t("tenant.domain")}>"
  layout "mailer"
end
