# frozen_string_literal: true

# app/controllers/integrations/fieldpulse/integrations_controller.rb
module Integrations
  module Fieldpulse
    class IntegrationsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: %i[endpoint]
      before_action :authenticate_user!, except: %i[endpoint]
      before_action :authorize_user!, except: %i[endpoint]
      before_action :client_api_integration, except: %i[endpoint]
      before_action :client_api_integration_events, except: %i[endpoint]

      # (GET/POST) FieldPulse webhook endpoint
      # /integrations/fieldpulse/endpoint
      # integrations_fieldpulse_endpoint_path
      # integrations_fieldpulse_endpoint_url
      def endpoint
        Rails.logger.info "params_endpoint: #{params_endpoint.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
        unsafe_params = (params&.to_unsafe_hash || {}).deep_symbolize_keys
        client_count  = 0

        ClientApiIntegration.joins(:client).where(target: 'fieldpulse', name: '').where('clients.data @> ?', { active: true }.to_json).where('client_api_integrations.data @> ?', { company_id: unsafe_params.dig(:company).split('_').last.to_i }.to_json).each do |client_api_integration|
          client_count += 1
          "Integrations::Fieldpulse::V#{client_api_integration.data.dig('credentials', 'version')}::ProcessEventJob".constantize.perform_later(
            client_api_integration_id: client_api_integration.id,
            client_id:                 client_api_integration.client.id,
            process_events:            true,
            raw_params:                unsafe_params
          )
        end

        render plain: client_count.positive? ? 'ok' : 'not found', content_type: 'text/plain', layout: false, status: client_count.positive? ? :ok : :not_found
      end

      # (GET) show FieldPulse integration overview screen
      # /integrations/fieldpulse
      # integrations_fieldpulse_path
      # integrations_fieldpulse_url
      def show
        client_api_integration = current_user.client.client_api_integrations.find_by(target: 'fieldpulse', name: '')
        path                   = send(:"integrations_fieldpulse_v#{Integration::Fieldpulse::Base.new(client_api_integration).current_version}_path")

        respond_to do |format|
          format.js { render js: "window.location = '#{path}'" and return false }
          format.html { redirect_to path and return false }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'user', session) && current_user.client.integrations_allowed.include?('fieldpulse')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access FieldPulse Integrations. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration
        return if (@client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'fieldpulse', name: ''))

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration_events
        return if (@client_api_integration_events = current_user.client.client_api_integrations.find_or_create_by(target: 'fieldpulse', name: 'events'))

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def params_endpoint
        params.permit(:trigger, :message, data: {}).to_h
      end
      # example of a webhook endpoint
      # {
      #   trigger: 'Job Workflow Custom Status Update',
      #   message: 'UPDATE ON JOBS FOR status_id',
      #   data:    {
      #     old_value: 920838,
      #     new_value: 920839,
      #     object:    {
      #       id:                     8345173,
      #       job_type:               'Job for JimBob Martin',
      #       customer_id:            7796731,
      #       status:                 6,
      #       status_id:              920839,
      #       status_workflow_id:     173020,
      #       in_progress_status_log: 808,
      #       updated_at:             '2024-11-19 22:32:55'
      #     }
      #   },
      #   company: 'FieldPulse_Chiirp_114785'
      # }
    end
  end
end
