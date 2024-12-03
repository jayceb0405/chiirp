# frozen_string_literal: true

# app/controllers/integrations/housecall/import_estimates_controller.rb
module Integrations
  module Housecall
    class ImportEstimatesController < Housecall::IntegrationsController
      # (GET) refresh HCP technicians
      # /integrations/housecall/import_estimates/refresh_technicians
      # integrations_housecall_import_estimates_refresh_technicians_path
      # integrations_housecall_import_estimates_refresh_technicians_url
      def refresh_technicians
        Integration::Housecallpro::V1::Base.new(@client_api_integration).refresh_technicians
      end

      # (GET) show import Estimates screen
      # /integrations/housecall/import_estimates
      # integrations_housecall_import_estimates_path
      # integrations_housecall_import_estimates_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/housecall/js/show', locals: { cards: %w[import_estimates_show] } }
          format.html { redirect_to integrations_housecall_path }
        end
      end

      # (PUT/PATCH) import Housecall Pro Estimates
      # /integrations/housecall/import_estimates
      # integrations_housecall_import_estimates_path
      # integrations_housecall_import_estimates_url
      def update
        sanitized_params = params_update

        data = {
          actions:             sanitized_params[:actions],
          approval_statuses:   sanitized_params[:approval_statuses],
          date_range_type:     sanitized_params[:date_range_type],
          ext_tech_ids:        sanitized_params[:ext_tech_ids],
          lead_sources:        sanitized_params[:lead_sources],
          scheduled_end_min:   sanitized_params[:date_range_type] == 'end' ? Time.use_zone(@client_api_integration.client.time_zone) { Chronic.parse(sanitized_params[:date_range].split(' to ').first) } : '',
          scheduled_end_max:   sanitized_params[:date_range_type] == 'end' ? Time.use_zone(@client_api_integration.client.time_zone) { Chronic.parse(sanitized_params[:date_range].split(' to ').last) } : '',
          scheduled_start_min: sanitized_params[:date_range_type] == 'start' ? Time.use_zone(@client_api_integration.client.time_zone) { Chronic.parse(sanitized_params[:date_range].split(' to ').first) } : '',
          scheduled_start_max: sanitized_params[:date_range_type] == 'start' ? Time.use_zone(@client_api_integration.client.time_zone) { Chronic.parse(sanitized_params[:date_range].split(' to ').last) } : '',
          tag_ids_exclude:     sanitized_params[:tag_ids_exclude],
          tag_ids_include:     sanitized_params[:tag_ids_include],
          user_id:             current_user.id,
          work_statuses:       sanitized_params[:work_statuses]
        }
        Integration::Housecallpro::V1::Base.new(@client_api_integration).delay(
          run_at:              Time.current,
          priority:            DelayedJob.job_priority('housecallpro_import_estimates'),
          queue:               DelayedJob.job_queue('housecallpro_import_estimates'),
          contact_id:          0,
          contact_campaign_id: 0,
          user_id:             current_user.id,
          triggeraction_id:    0,
          process:             'housecallpro_import_estimates',
          group_process:       0,
          data:
        ).import_estimates(data)

        respond_to do |format|
          format.json { render json: response, status: (response[:error].present? ? 415 : :ok) }
          format.js { render partial: 'integrations/housecall/js/show', locals: { cards: %w[import_estimates_show] } }
          format.html { redirect_to integrations_housecall_path }
        end
      end

      private

      def params_update
        sanitized_params = params.require(:import_estimate).permit(:date_range_type, :date_range, actions: %i[campaign_id group_id stage_id tag_id] + [{ stop_campaign_ids: [] }], approval_statuses: [], ext_tech_ids: [], lead_sources: [], tag_ids_exclude: [], tag_ids_include: [], work_statuses: [])

        sanitized_params[:actions][:campaign_id]       = sanitized_params.dig(:actions, :campaign_id)&.to_i
        sanitized_params[:actions][:group_id]          = sanitized_params.dig(:actions, :group_id)&.to_i
        sanitized_params[:actions][:stage_id]          = sanitized_params.dig(:actions, :stage_id)&.to_i
        sanitized_params[:actions][:tag_id]            = sanitized_params.dig(:actions, :tag_id)&.to_i
        sanitized_params[:actions][:stop_campaign_ids] = sanitized_params.dig(:actions, :stop_campaign_ids)&.compact_blank
        sanitized_params[:actions][:stop_campaign_ids] = [0] if sanitized_params.dig(:actions, :stop_campaign_ids)&.include?('0')
        sanitized_params[:approval_statuses]           = sanitized_params.dig(:approval_statuses).compact_blank || []
        sanitized_params[:date_range_type]             = 'start' if %w[start end].exclude?(sanitized_params.dig(:date_range_type))
        sanitized_params[:ext_tech_ids]                = sanitized_params.dig(:ext_tech_ids)&.compact_blank || []
        sanitized_params[:lead_sources]                = sanitized_params.dig(:lead_sources)&.compact_blank&.map(&:to_i) || []
        sanitized_params[:tag_ids_exclude]             = sanitized_params.dig(:tag_ids_exclude)&.compact_blank&.map(&:to_i) || []
        sanitized_params[:tag_ids_include]             = sanitized_params.dig(:tag_ids_include)&.compact_blank&.map(&:to_i) || []
        sanitized_params[:work_statuses]               = sanitized_params.dig(:work_statuses).compact_blank || []

        sanitized_params
      end
    end
  end
end
