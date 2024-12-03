# frozen_string_literal: true

# app/controllers/integrations/email/v1/connections_controller.rb
module Integrations
  module Email
    module V1
      class ConnectionsController < Integrations::Email::V1::IntegrationsController
        # (GET) Email integration configuration screen
        # /integrations/email/v1/connections/edit
        # edit_integrations_email_v1_connections_path
        # edit_integrations_email_v1_connections_url
        def edit
          # ensure that the inbound_username is set
          @client_api_integration.save if @client_api_integration.inbound_username.blank?

          render partial: 'integrations/email/v1/js/show', locals: { cards: %w[menu connections_edit] }
        end

        # (PATCH/PUT) Email integration configuration save
        # /integrations/email/v1/connections
        # integrations_email_v1_connections_path
        # integrations_email_v1_connections_url
        def update
          unless Integration::Email::V1::Base.new(@client_api_integration).connected?
            @client_api_integration.update(params_credentials)

            Integrations::Email::V1::CreateAccountJob.perform_later(client_api_integration: @client_api_integration, data: sanitized_params) if @client_api_integration.domain.present?
          end

          render partial: 'integrations/email/v1/js/show', locals: { cards: %w[] }
        end

        # (DELETE) Email integration configuration delete
        # /integrations/email/v1/connections
        # integrations_email_v1_connections_path
        # integrations_email_v1_connections_url
        def destroy
          Integrations::Email::V1::DestroyAccountJob.perform_later(client_api_integration: @client_api_integration)

          render partial: 'integrations/email/v1/js/show', locals: { cards: %w[] }
        end

        private

        def params_credentials
          params.require(:emails).permit(:domain)
        end

        def sanitized_params
          {
            username: @client_api_integration.username,
            ips:      @client_api_integration.ips,
            domain:   @client_api_integration.domain
          }
        end
      end
    end
  end
end
