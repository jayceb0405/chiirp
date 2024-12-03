Rails.application.config.after_initialize do
  I18n.available_locales.each do |locale|
    translations = I18n.t(:email_address, locale: locale)

    next unless translations.is_a? Hash

    EmailAddress::Config.error_messages translations.transform_keys(&:to_s), locale.to_s
  end
end
