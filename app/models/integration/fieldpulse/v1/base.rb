# frozen_string_literal: true

# app/models/integration/fieldpulse/v1/base.rb
module Integration
  module Fieldpulse
    module V1
      class Base < Integration::Fieldpulse::Base
        attr_reader :error, :message, :result, :success
        alias success? success

        include Integration::Fieldpulse::V1::Contacts
        include Integration::Fieldpulse::V1::Customers
        include Integration::Fieldpulse::V1::ImportContacts
        include Integration::Fieldpulse::V1::JobStatusWorkflows
        # include Integration::Fieldpulse::V1::JobStatusWorkflowStatuses
        include Integration::Fieldpulse::V1::Jobs
        include Integration::Fieldpulse::V1::LeadSources
        include Integration::Fieldpulse::V1::Teams
        include Integration::Fieldpulse::V1::Users

        # client_id = xx
        # client_api_integration = ClientApiIntegration.find_by(client_id: client_id, target: 'fieldpulse', name: ''); fp_model = Integration::Fieldpulse::V1::Base.new(client_api_integration); fp_model.valid_credentials?; fp_client = Integrations::FieldPulse::V1::Base.new(client_api_integration.api_key)

        EVENT_TYPE_OPTIONS = [
          # %w[Estimate estimate],
          %w[Job job]
          # %w[Invoice invoice]
        ].freeze

        # validate the access_token & refresh if necessary
        # jb_model.valid_credentials?
        def valid_credentials?
          @client_api_integration.api_key.present? && @client_api_integration&.credentials&.dig('version').presence.to_i.positive?
        end

        private

        def reset_attributes
          @error   = 0
          @message = ''
          @result  = nil
          @success = false
        end

        def update_attributes_from_client
          @error   = @fp_client.error
          @message = @fp_client.message
          @result  = @fp_client.result
          @success = @fp_client.success?
        end
      end
    end
  end
end
