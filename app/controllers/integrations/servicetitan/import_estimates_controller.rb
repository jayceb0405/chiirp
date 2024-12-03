# frozen_string_literal: true

# app/controllers/integrations/servicetitan/import_estimates_controller.rb
module Integrations
  module Servicetitan
    class ImportEstimatesController < Servicetitan::IntegrationsController
      # (GET) show import estimates screen
      # /integrations/servicetitan/import_estimates
      # integrations_servicetitan_import_estimates_path
      # integrations_servicetitan_import_estimates_url
      def show
        render partial: 'integrations/servicetitan/import_estimates/js/show', locals: { cards: %w[show] }
      end

      # (PUT/PATCH) import estimates
      # /integrations/servicetitan/import_estimates
      # integrations_servicetitan_import_estimates_path
      # integrations_servicetitan_import_estimates_url
      def update
        Integrations::Servicetitan::V2::Estimates::Import::ByClientJob.perform_later(**params_update.merge({ client_id: current_user.client_id, user_id: current_user.id }).to_unsafe_h.symbolize_keys)

        render partial: 'integrations/servicetitan/import_estimates/js/show', locals: { cards: %w[show] }
      end

      private

      def params_update
        sanitized_params = params.require(:import_estimate).permit(:active, :contact_id, :date_range, :date_range_type, :orphaned_only, :process_events, :status, :total, actions: %i[campaign_id group_id stage_id tag_id] + [{ stop_campaign_ids: [] }])

        sanitized_params[:active]         = sanitized_params.dig(:active).nil? ? true : sanitized_params[:active].to_bool
        sanitized_params[:contact_id]     = sanitized_params.dig(:contact_id).to_i
        sanitized_params[:created_at_max] = Time.use_zone(@client_api_integration.client.time_zone) { Chronic.parse(sanitized_params[:date_range].split(' to ').last) } if sanitized_params.dig(:date_range_type).to_s.casecmp?('created') && sanitized_params.dig(:date_range).present?
        sanitized_params[:created_at_min] = Time.use_zone(@client_api_integration.client.time_zone) { Chronic.parse(sanitized_params[:date_range].split(' to ').first) } if sanitized_params.dig(:date_range_type).to_s.casecmp?('created') && sanitized_params.dig(:date_range).present?
        sanitized_params[:process_events] = sanitized_params.dig(:process_events).to_bool
        sanitized_params[:orphaned_only]  = sanitized_params.dig(:orphaned_only).nil? ? true : sanitized_params[:orphaned_only].to_bool
        sanitized_params[:total_max]      = sanitized_params[:total].split(';').last.to_d if sanitized_params.dig(:total).present?
        sanitized_params[:total_min]      = sanitized_params[:total].split(';').first.to_d if sanitized_params.dig(:total).present?
        sanitized_params[:updated_at_max] = Time.use_zone(@client_api_integration.client.time_zone) { Chronic.parse(sanitized_params[:date_range].split(' to ').last) } if sanitized_params.dig(:date_range_type).to_s.casecmp?('updated') && sanitized_params.dig(:date_range).present?
        sanitized_params[:updated_at_min] = Time.use_zone(@client_api_integration.client.time_zone) { Chronic.parse(sanitized_params[:date_range].split(' to ').first) } if sanitized_params.dig(:date_range_type).to_s.casecmp?('updated') && sanitized_params.dig(:date_range).present?
        sanitized_params.delete(:date_range)
        sanitized_params.delete(:date_range_type)
        sanitized_params.delete(:total)

        sanitized_params[:actions][:campaign_id]       = sanitized_params.dig(:actions, :campaign_id).to_i
        sanitized_params[:actions][:group_id]          = sanitized_params.dig(:actions, :group_id).to_i
        sanitized_params[:actions][:stage_id]          = sanitized_params.dig(:actions, :stage_id).to_i
        sanitized_params[:actions][:tag_id]            = sanitized_params.dig(:actions, :tag_id).to_i
        sanitized_params[:actions][:stop_campaign_ids] = sanitized_params.dig(:actions, :stop_campaign_ids)&.compact_blank
        sanitized_params[:actions][:stop_campaign_ids] = [0] if sanitized_params.dig(:actions, :stop_campaign_ids)&.include?('0')

        sanitized_params
      end
    end
  end
end
