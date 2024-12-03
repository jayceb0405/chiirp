# frozen_string_literal: true

# app/controllers/integrations/servicetitan/balance_updates_controller.rb
module Integrations
  module Servicetitan
    class BalanceUpdatesController < Servicetitan::IntegrationsController
      # (GET) show ServiceTitan api key form
      # /integrations/servicetitan/balance_update
      # integrations_servicetitan_balance_update_path
      # integrations_servicetitan_balance_update_url
      def show; end

      # (PUT) update ClientApiIntegration balance_actions
      # /integrations/servicetitan/balance_update
      # integrations_servicetitan_balance_update_path
      # integrations_servicetitan_balance_update_url
      def update
        @client_api_integration.update(update_balance_actions: balance_actions_params)
      end

      private

      def balance_actions_params
        response         = @client_api_integration.update_balance_actions
        sanitized_params = params.require(:update_balance_actions).permit(:campaign_id_0, :group_id_0, :stage_id_0, :tag_id_0, :campaign_id_increase, :group_id_increase, :stage_id_increase, :tag_id_increase, :campaign_id_decrease, :group_id_decrease, :stage_id_decrease, :tag_id_decrease, :update_balance_window_days, :update_invoice_window_days, :update_open_estimate_window_days, :update_open_job_window_days, stop_campaign_ids_0: [], stop_campaign_ids_decrease: [], stop_campaign_ids_increase: [])

        response[:campaign_id_0]                    = sanitized_params[:campaign_id_0].to_i if sanitized_params.include?(:campaign_id_0)
        response[:stop_campaign_ids_0]              = sanitized_params[:stop_campaign_ids_0].compact_blank.map(&:to_i) if sanitized_params.include?(:stop_campaign_ids_0)
        response[:stop_campaign_ids_0]              = [0] if sanitized_params[:stop_campaign_ids_0]&.include?(0) # no need to keep other ids
        response[:group_id_0]                       = sanitized_params[:group_id_0].to_i if sanitized_params.include?(:group_id_0)
        response[:stage_id_0]                       = sanitized_params[:stage_id_0].to_i if sanitized_params.include?(:stage_id_0)
        response[:tag_id_0]                         = sanitized_params[:tag_id_0].to_i if sanitized_params.include?(:tag_id_0)
        response[:campaign_id_increase]             = sanitized_params[:campaign_id_increase].to_i if sanitized_params.include?(:campaign_id_increase)
        response[:stop_campaign_ids_increase]       = sanitized_params[:stop_campaign_ids_increase].compact_blank.map(&:to_i) if sanitized_params.include?(:stop_campaign_ids_increase)
        response[:stop_campaign_ids_increase]       = [0] if sanitized_params[:stop_campaign_ids_increase]&.include?(0) # no need to keep other ids
        response[:group_id_increase]                = sanitized_params[:group_id_increase].to_i if sanitized_params.include?(:group_id_increase)
        response[:stage_id_increase]                = sanitized_params[:stage_id_increase].to_i if sanitized_params.include?(:stage_id_increase)
        response[:tag_id_increase]                  = sanitized_params[:tag_id_increase].to_i if sanitized_params.include?(:tag_id_increase)
        response[:campaign_id_decrease]             = sanitized_params[:campaign_id_decrease].to_i if sanitized_params.include?(:campaign_id_decrease)
        response[:stop_campaign_ids_decrease]       = sanitized_params[:stop_campaign_ids_decrease].compact_blank.map(&:to_i) if sanitized_params.include?(:stop_campaign_ids_decrease)
        response[:stop_campaign_ids_decrease]       = [0] if sanitized_params[:stop_campaign_ids_decrease]&.include?(0) # no need to keep other ids
        response[:group_id_decrease]                = sanitized_params[:group_id_decrease].to_i if sanitized_params.include?(:group_id_decrease)
        response[:stage_id_decrease]                = sanitized_params[:stage_id_decrease].to_i if sanitized_params.include?(:stage_id_decrease)
        response[:tag_id_decrease]                  = sanitized_params[:tag_id_decrease].to_i if sanitized_params.include?(:tag_id_decrease)
        response[:update_balance_window_days]       = sanitized_params[:update_balance_window_days].to_i if sanitized_params.include?(:update_balance_window_days)
        response[:update_invoice_window_days]       = sanitized_params[:update_invoice_window_days].to_i if sanitized_params.dig(:update_invoice_window_days)
        response[:update_open_estimate_window_days] = sanitized_params[:update_open_estimate_window_days].to_i if sanitized_params.include?(:update_open_estimate_window_days)
        response[:update_open_job_window_days]      = sanitized_params[:update_open_job_window_days].to_i if sanitized_params.include?(:update_open_job_window_days)

        response
      end
    end
  end
end
