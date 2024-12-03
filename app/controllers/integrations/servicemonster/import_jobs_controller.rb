# frozen_string_literal: true

# app/controllers/integrations/servicemonster/import_jobs_controller.rb
module Integrations
  module Servicemonster
    # support for importing Job data from Servicemonster
    class ImportJobsController < Servicemonster::IntegrationsController
      # (GET) show import Jobs screen
      # /integrations/servicemonster/import_jobs
      # integrations_servicemonster_import_jobs_path
      # integrations_servicemonster_import_jobs_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/servicemonster/js/show', locals: { cards: %w[import_jobs_show] } }
          format.html { redirect_to integrations_servicemonster_path }
        end
      end

      # (PUT/PATCH) import ServiceMonster jobs
      # /integrations/servicemonster/import_jobs
      # integrations_servicemonster_import_jobs_path
      # integrations_servicemonster_import_jobs_url
      def update
        data = params_update.merge({
                                     client_api_integration_id: @client_api_integration.id,
                                     client_id:                 @client_api_integration.client_id,
                                     user_id:                   current_user.id
                                   })
        Integration::Servicemonster.delay(
          run_at:              Time.current,
          priority:            DelayedJob.job_priority('servicemonster_import_jobs'),
          queue:               DelayedJob.job_queue('servicemonster_import_jobs'),
          contact_id:          0,
          contact_campaign_id: 0,
          user_id:             current_user.id,
          triggeraction_id:    0,
          process:             'servicemonster_import_jobs',
          group_process:       0,
          data:
        ).import_jobs(data)

        respond_to do |format|
          format.json { render json: response, status: (response[:error].present? ? 415 : :ok) }
          format.js { render partial: 'integrations/servicemonster/js/show', locals: { cards: %w[import_jobs_show] } }
          format.html { redirect_to integrations_servicemonster_path }
        end
      end

      private

      def params_update
        sanitized_params = params.require(:import_job).permit(:commercial, :end_period, :order_type, :residential, :start_period, :total, account_types: [], account_sub_types: [], appointment_status: [], ext_tech_ids: [], job_types: [], line_items: [], order_groups: [], order_subgroups: [], actions: %i[campaign_id group_id stage_id tag_id] + [{ stop_campaign_ids: [] }])

        sanitized_params[:actions][:campaign_id]       = sanitized_params[:actions][:campaign_id].to_i
        sanitized_params[:actions][:group_id]          = sanitized_params[:actions][:group_id].to_i
        sanitized_params[:actions][:stage_id]          = sanitized_params[:actions][:stage_id].to_i
        sanitized_params[:actions][:tag_id]            = sanitized_params[:actions][:tag_id].to_i
        sanitized_params[:actions][:stop_campaign_ids] = sanitized_params[:actions][:stop_campaign_ids]&.compact_blank
        sanitized_params[:actions][:stop_campaign_ids] = [0] if sanitized_params[:actions][:stop_campaign_ids]&.include?('0')
        sanitized_params[:account_types]               = sanitized_params.dig(:account_types).compact_blank
        sanitized_params[:account_sub_types]           = sanitized_params.dig(:account_sub_types).compact_blank
        sanitized_params[:appointment_status]          = sanitized_params.dig(:appointment_status).compact_blank
        sanitized_params[:commercial]                  = sanitized_params.dig(:commercial).to_bool
        sanitized_params[:ext_tech_ids]                = sanitized_params.dig(:ext_tech_ids).compact_blank
        sanitized_params[:job_types]                   = sanitized_params.dig(:job_types).compact_blank
        sanitized_params[:line_items]                  = sanitized_params.dig(:line_items).compact_blank
        sanitized_params[:order_groups]                = sanitized_params.dig(:order_groups).compact_blank
        sanitized_params[:order_subgroups]             = sanitized_params.dig(:order_subgroups).compact_blank
        sanitized_params[:residential]                 = sanitized_params.dig(:residential).to_bool
        sanitized_params[:scheduled_end_min]           = sanitized_params.dig(:end_period).present? ? Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:end_period].split(' to ').first) } : ''
        sanitized_params[:scheduled_end_max]           = sanitized_params.dig(:end_period).present? ? Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:end_period].split(' to ').last) } : ''
        sanitized_params[:scheduled_start_min]         = sanitized_params.dig(:start_period).present? ? Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:start_period].split(' to ').first) } : ''
        sanitized_params[:scheduled_start_max]         = sanitized_params.dig(:start_period).present? ? Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:start_period].split(' to ').last) } : ''
        sanitized_params[:total_min]                   = sanitized_params.dig(:total)&.split(';')&.first.to_i
        sanitized_params[:total_max]                   = sanitized_params.dig(:total)&.split(';')&.last.to_i

        sanitized_params.delete(:end_period)
        sanitized_params.delete(:start_period)
        sanitized_params.delete(:total)

        sanitized_params
      end
    end
  end
end
