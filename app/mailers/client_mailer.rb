# frozen_string_literal: true

class ClientMailer < ApplicationMailer
  default from: "Chiirp Support <support@#{I18n.t('tenant.domain')}>"
  layout 'standard_mailer'
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.client_mailer.failed_charge_notification.subject
  #

  # send a failed charge notification to the client
  # params:
  #   client_id: integer
  #   amount: float
  #   charge_reason: string
  #   content: string
  #   link_url: string
  #   link_text: string
  def failed_charge_notification
    @client = Client.find_by(id: params[:client_id])

    @email = @client.contact&.email.presence || @client.def_user.email

    return unless @client && @email.present?

    @header = 'UH-OH, YOUR PAYMENT TO CHIIRP FAILED'
    params[:link_text] ||= 'Check and update your billing info'

    mail to: @email, subject: 'Failed charge notification'
  end
end
