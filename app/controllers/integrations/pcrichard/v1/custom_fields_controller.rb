# frozen_string_literal: true

# app/controllers/integrations/pcrichard/v1/custom_fields_controller.rb
module Integrations
  module Pcrichard
    module V1
      class CustomFieldsController < Pcrichard::V1::IntegrationsController
        # (GET) edit custom fields used to hold PC Richard model options
        # /integrations/pcrichard/v1/custom_fields/edit
        # edit_integrations_pcrichard_v1_custom_fields_path
        # edit_integrations_pcrichard_v1_custom_fields_url
        def edit
          render partial: 'integrations/pcrichard/v1/js/show', locals: { cards: %w[custom_fields_edit] }
        end

        # (PATCH/PUT) update custom fields used to hold PC Richard model options
        # /integrations/pcrichard/v1/custom_fields
        # integrations_pcrichard_v1_custom_fields_path
        # integrations_pcrichard_v1_custom_fields_url
        def update
          @client_api_integration.update(custom_fields: params_custom_fields)

          render partial: 'integrations/pcrichard/v1/js/show', locals: { cards: %w[custom_fields_edit] }
        end

        private

        def params_custom_fields
          sanitized_params = params.require(:custom_fields).permit(:option_01, :option_02, :option_03, :option_04, :option_05, :option_06, :installation_charge, :receipt_notes, :internal_notes)

          sanitized_params.each { |k, v| sanitized_params[k] = v.to_i }
        end
      end
    end
  end
end
