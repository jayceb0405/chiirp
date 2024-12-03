# frozen_string_literal: true

module PaymentRequestable
  def payment_request_url(contact:, amount:, job_id: nil)
    return '' unless (client_api_integration = contact.client.client_api_integrations.find_by(target: 'cardx', name: ''))
    return '' unless (cx_client = Integrations::CardX::Base.new(client_api_integration.account)).valid_credentials?

    url = cx_client.lightbox_url(name: contact.fullname, amount:, email: contact.email, zip: contact.zipcode, redirect: client_api_integration.redirect, job_id:, contact_id: contact.id)
    generate_short_code_from_url!(url, contact:)
  end

  def generate_short_code_from_url!(url, contact:)
    # generate a short code; trying again up to n times if code is a duplicate
    count = 0
    begin
      count += 1
      ShortCode.create!(client: contact.client, url:).to_s
    rescue ActiveRecord::RecordInvalid
      retry unless count >= 5
      raise
    end
  end
end
