# frozen_string_literal: true

# app/controllers/integrations/dope/v1/automations_controller.rb
module Integrations
  module Dope
    module V1
      # support for configuring automation actions used to send API calls to Dope Marketing
      class AutomationsController < Dope::V1::IntegrationsController
        # (GET)
        # /integrations/dope/v1/automations
        # integrations_dope_v1_automations_path
        # integrations_dope_v1_automations_url
        def index
          render partial: 'integrations/dope/v1/js/show', locals: { cards: %w[automations_index] }
        end

        # (PATCH/PUT) update automations
        # /integrations/dope/v1/automations/:id
        # integrations_dope_v1_automation_path(:id)
        # integrations_dope_v1_automation_url(:id)
        def update
          sanitized_params = params.permit(:id, :name, :tag_id)

          if (automation = @client_api_integration.automations.find { |a| a.dig('id') == sanitized_params.dig(:id).to_s })
            @client_api_integration.automations.delete(automation)
          end

          @client_api_integration.automations << { id: sanitized_params.dig(:id).to_s, name: sanitized_params.dig(:name).to_s, tag_id: sanitized_params.dig(:tag_id).to_i }
          @client_api_integration.save

          render js: '', layout: false, status: :ok
        end
      end
    end
  end
end
