# frozen_string_literal: true

# app/controllers/integrations/salesrabbit/statuses_controller.rb
module Integrations
  module Salesrabbit
    class StatusesController < Integrations::Salesrabbit::IntegrationsController
      # (GET) show SalesRabbit status actions
      # /integrations/salesrabbit/status
      # integrations_salesrabbit_status_path
      # integrations_salesrabbit_status_url
      def show
        respond_to do |format|
          format.js   { render partial: 'integrations/salesrabbit/js/show', locals: { cards: %w[statuses] } }
          format.html { render 'integrations/salesrabbit/edit' }
        end
      end

      # (PUT/PATCH) save SalesRabbit status actions
      # /integrations/salesrabbit/status
      # integrations_salesrabbit_status_path
      # integrations_salesrabbit_status_url
      def update
        @client_api_integration.update(status_actions: params_status)

        respond_to do |format|
          format.js   { render partial: 'integrations/salesrabbit/js/show', locals: { cards: %w[statuses] } }
          format.html { render 'integrations/salesrabbit/edit' }
        end
      end

      private

      def params_status
        sanitized_params = params.permit(campaign_id: {}, group_id: {}, stage_id: {}, tag_id: {}, stop_campaign_ids: {})

        response = {}
        response[:campaigns]         = sanitized_params.dig(:campaign_id).to_h.transform_values(&:to_i)
        response[:groups]            = sanitized_params.dig(:group_id).to_h.transform_values(&:to_i)
        response[:stages]            = sanitized_params.dig(:stage_id).to_h.transform_values(&:to_i)
        response[:tags]              = sanitized_params.dig(:tag_id).to_h.transform_values(&:to_i)
        response[:stop_campaign_ids] = sanitized_params.dig(:stop_campaign_ids).to_h.transform_values { |stop_campaign_ids| stop_campaign_ids&.compact_blank }.transform_values { |stop_campaign_ids| stop_campaign_ids&.include?('0') ? [0] : stop_campaign_ids }

        response
      end
    end
  end
end
