# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/client
class ClientMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/client/failed_charge_notification
  def failed_charge_notification
    ClientMailer.with(client_id: 1, amount: 10.0, charge_reason: 'credits', link_url: 'https://app.chiirp.com', content: 'Chiirp 2nd Credit Card attempt failed. Please update your credit card information.').failed_charge_notification
  end
end
