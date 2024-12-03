# frozen_string_literal: true

# app/controllers/integrations/jobber/v20220915/integrations_controller.rb
module Integrations
  module Jobber
    module V20220915
      class IntegrationsController < ApplicationController
        # rubocop:disable Rails/LexicallyScopedActionFilter
        skip_before_action :verify_authenticity_token, only: %i[auth_code endpoint]
        before_action :authenticate_user!, except: %i[auth_code endpoint]
        before_action :authorize_user!, except: %i[auth_code endpoint]
        before_action :client_api_integration, except: %i[auth_code endpoint]
        before_action :validate_webhook_source, only: %i[endpoint]
        # rubocop:enable Rails/LexicallyScopedActionFilter

        # (POST) Jobber webhook endpoint
        # /integrations/jobber/v20220915/endpoint
        # integrations_jobber_v20220915_endpoint_path
        # integrations_jobber_v20220915_endpoint_url
        def endpoint
          sanitized_params = params_endpoint
          client_api_integration_count = 0

          ClientApiIntegration.joins(:client).where(target: 'jobber', name: '').where('client_api_integrations.data @> ?', { account: { id: sanitized_params.dig(:webHookEvent, :accountId) } }.to_json).where('clients.data @> ?', { active: true }.to_json).find_each do |client_api_integration|
            client_api_integration_count += 1
            data = {
              client_api_integration_id: client_api_integration.id,
              account_id:                sanitized_params[:webHookEvent][:accountId],
              item_id:                   sanitized_params.dig(:webHookEvent, :itemId),
              process_events:            true,
              raw_params:                params.except(:integration),
              topic:                     sanitized_params.dig(:webHookEvent, :topic)
            }
            Integration::Jobber::V20220915::Event.new(data).delay(
              run_at:              Time.current,
              priority:            DelayedJob.job_priority('jobber_process_event'),
              queue:               DelayedJob.job_queue('jobber_process_event'),
              user_id:             0,
              contact_id:          0,
              triggeraction_id:    0,
              contact_campaign_id: 0,
              group_process:       0,
              process:             'jobber_process_event',
              data:
            ).process
          end

          if client_api_integration_count.positive?
            render plain: 'ok', content_type: 'text/plain', layout: false, status: :ok
          else
            render plain: 'not found', content_type: 'text/plain', layout: false, status: :not_found
          end
        end

        # (GET) show main Jobber integration screen
        # /integrations/jobber/v20220915
        # integrations_jobber_v20220915_path
        # integrations_jobber_v20220915_url
        def show
          respond_to do |format|
            format.js { render partial: 'integrations/jobber/v20220915/js/show', locals: { cards: %w[overview] } }
            format.html { render 'integrations/jobber/v20220915/show', locals: { partial_to_show: params.dig(:card).present? ? "integrations/jobber/v20220915/#{params[:card]}/index" : '' } }
          end
        end

        private

        def authorize_user!
          super

          return if current_user.access_controller?('integrations', 'user', session) && current_user.client.integrations_allowed.include?('jobber')

          sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access Jobber Integrations. Please contact your account admin.', '', { persistent: 'OK' })

          respond_to do |format|
            format.js { render js: "window.location = '#{root_path}'" and return false }
            format.html { redirect_to root_path and return false }
          end
        end

        def client_api_integration
          return if (@client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'jobber', name: ''))

          respond_to do |format|
            format.js { render js: "window.location = '#{root_path}'" and return false }
            format.html { redirect_to root_path and return false }
          end
        end

        def params_endpoint
          params.require(:data).permit(webHookEvent: %i[accountId appId itemId occuredAt topic])
        end

        def validate_webhook_source
          calculated_hmac = Base64.strict_encode64(
            OpenSSL::HMAC.digest(
              'sha256',
              Rails.configuration.x.jobber.client_secret || '',
              ActiveSupport::JSON.encode({ data: params.permit(:data).dig(:data) })
            )
          )

          ActiveSupport::SecurityUtils.secure_compare(
            calculated_hmac,
            request.headers['X-Jobber-Hmac-SHA256']
          )
        rescue StandardError
          render plain: 'unauthorized', content_type: 'text/plain', layout: false, status: :unauthorized and return false
        end
      end
    end
  end
end
