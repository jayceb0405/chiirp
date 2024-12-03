# frozen_string_literal: true

# app/controllers/integrations/housecall/import_jobs_controller.rb
module Integrations
  module Housecall
    class ImportJobsController < Housecall::IntegrationsController
      # (GET) show import Jobs screen
      # /integrations/housecall/import_jobs
      # integrations_housecall_import_jobs_path
      # integrations_housecall_import_jobs_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/housecall/js/show', locals: { cards: %w[import_jobs_show] } }
          format.html { redirect_to integrations_housecall_path }
        end
      end

      # (PUT/PATCH) import Price Book
      # /integrations/housecall/import_jobs
      # integrations_housecall_import_jobs_path
      # integrations_housecall_import_jobs_url
      def update
        sanitized_params = params_update

        data = {
          actions:             sanitized_params[:actions],
          date_range_type:     sanitized_params[:date_range_type],
          process_events:      sanitized_params[:process_events],
          scheduled_end_min:   sanitized_params[:date_range_type] == 'end' ? Time.use_zone(@client_api_integration.client.time_zone) { Chronic.parse(sanitized_params[:date_range].split(' to ').first) } : '',
          scheduled_end_max:   sanitized_params[:date_range_type] == 'end' ? Time.use_zone(@client_api_integration.client.time_zone) { Chronic.parse(sanitized_params[:date_range].split(' to ').last) } : '',
          scheduled_start_min: sanitized_params[:date_range_type] == 'start' ? Time.use_zone(@client_api_integration.client.time_zone) { Chronic.parse(sanitized_params[:date_range].split(' to ').first) } : '',
          scheduled_start_max: sanitized_params[:date_range_type] == 'start' ? Time.use_zone(@client_api_integration.client.time_zone) { Chronic.parse(sanitized_params[:date_range].split(' to ').last) } : '',
          user_id:             current_user.id,
          work_status:         sanitized_params[:status]
        }
        Integration::Housecallpro::V1::Base.new(@client_api_integration).delay(
          run_at:              Time.current,
          priority:            DelayedJob.job_priority('housecallpro_import_jobs'),
          queue:               DelayedJob.job_queue('housecallpro_import_jobs'),
          contact_id:          0,
          contact_campaign_id: 0,
          user_id:             current_user.id,
          triggeraction_id:    0,
          process:             'housecallpro_import_jobs',
          group_process:       0,
          data:
        ).import_jobs(data)

        respond_to do |format|
          format.json { render json: response, status: (response[:error].present? ? 415 : :ok) }
          format.js { render partial: 'integrations/housecall/js/show', locals: { cards: %w[import_jobs_show] } }
          format.html { redirect_to integrations_housecall_path }
        end
      end

      private

      def params_update
        sanitized_params = params.require(:import_job).permit(:date_range_type, :date_range, :process_events, status: [], actions: %i[campaign_id group_id stage_id tag_id] + [{ stop_campaign_ids: [] }])

        sanitized_params[:actions][:campaign_id]       = sanitized_params.dig(:actions, :campaign_id)&.to_i
        sanitized_params[:actions][:group_id]          = sanitized_params.dig(:actions, :group_id)&.to_i
        sanitized_params[:actions][:stage_id]          = sanitized_params.dig(:actions, :stage_id)&.to_i
        sanitized_params[:actions][:tag_id]            = sanitized_params.dig(:actions, :tag_id)&.to_i
        sanitized_params[:actions][:stop_campaign_ids] = sanitized_params.dig(:actions, :stop_campaign_ids)&.compact_blank
        sanitized_params[:actions][:stop_campaign_ids] = [0] if sanitized_params.dig(:actions, :stop_campaign_ids)&.include?('0')
        sanitized_params[:date_range_type]             = 'start' if %w[start end].exclude?(sanitized_params.dig(:date_range_type))
        sanitized_params[:process_events]              = sanitized_params.dig(:process_events).to_bool
        sanitized_params[:status]                      = sanitized_params.dig(:status).compact_blank

        sanitized_params
      end
    end
  end
end
