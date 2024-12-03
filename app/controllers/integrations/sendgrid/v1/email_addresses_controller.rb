# frozen_string_literal: true

# app/controllers/integrations/sendgrid/v1/email_addresses_controller.rb
module Integrations
  module Sendgrid
    module V1
      class EmailAddressesController < Sendgrid::V1::IntegrationsController
        # (GET) show email addresses edit screen
        # /integrations/sendgrid/v1/email_addresses/edit
        # edit_integrations_sendgrid_v1_email_addresses_path
        # edit_integrations_sendgrid_v1_email_addresses_url
        def edit
          render partial: 'integrations/sendgrid/v1/js/show', locals: { cards: %w[email_addresses_edit] }
        end

        # (PATCH/PUT) update email addresses
        # /integrations/sendgrid/v1/email_addresses
        # integrations_sendgrid_v1_email_addresses_path
        # integrations_sendgrid_v1_email_addresses_url
        def update
          @client_api_integration.update(email_addresses: params.require(:client_api_integration).permit(:email_addresses).dig(:email_addresses).to_s.delete(' '))

          render partial: 'integrations/sendgrid/v1/js/show', locals: { cards: %w[email_addresses_edit] }
        end
      end
    end
  end
end
