# frozen_string_literal: true

# app/controllers/integrations/cardx/integrations_controller.rb
module Integrations
  module Cardx
    class IntegrationsController < ApplicationController
      class IntegrationsControllerWebhookSourceInvalid < StandardError; end

      skip_before_action :verify_authenticity_token, only: %i[endpoint]
      before_action :authenticate_user!, except: %i[endpoint]
      before_action :authorize_user!, except: %i[endpoint]
      before_action :client_api_integration, except: %i[endpoint]
      before_action :client_api_integration_from_uuid, only: %i[endpoint]

      HTTP_REQUEST_HEADER_KEY = 'X-Chiirp-CardX-Integration-Key'

      def show
        respond_to do |format|
          format.js { render partial: 'integrations/cardx/js/show', locals: { cards: %w[overview] } }
          format.html { render 'integrations/cardx/show', locals: { partial_to_show: params.dig(:card).present? ? "integrations/cardx/#{params[:card]}/index" : '' } }
        end
      end

      def endpoint
        unless webhook_source_validated?
          error = IntegrationsControllerWebhookSourceInvalid.new('CardX Integration Controller: Webhook auth fail')
          error.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(error) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('Integrations::Cardx::IntegrationsController#endpoint')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(params)

            Appsignal.set_tags(
              error_level: 'error',
              error_code:  0
            )
            Appsignal.add_custom_data(
              http_request_header_key: request.headers[HTTP_REQUEST_HEADER_KEY],
              webhook_api_key:         params[:webhook_api_key],
              file:                    __FILE__,
              line:                    __LINE__
            )
          end

          render plain: 'unauthorized', content_type: 'text/plain', layout: false, status: :unauthorized and return
        end

        data = {
          'client_api_integration_id' => @client_api_integration.id,
          'email'                     => params.dig(:pt_billing_email_address),
          'name'                      => params.dig(:pt_payment_name),
          'city'                      => params.dig(:pt_billing_city),
          'state'                     => params.dig(:pt_billing_state),
          'gateway_account'           => params.dig(:pt_gateway_account),
          'card_type'                 => params.dig(:cardxPricingInfo, :data, :attributes, :cardType),
          'transaction_amount'        => params.dig(:pt_transaction_amount)&.to_f,
          'surcharge_amount'          => params.dig(:cardxPricingInfo, :data, :attributes, :surchargeAmount)&.to_f,
          'authorization_code'        => params.dig(:pt_authorization_code),
          'date'                      => params.dig(:date)&.to_time,
          'contact_id'                => params.dig(:pt_account_code_1),
          'job_id'                    => params.dig(:pt_account_code_2),
          'raw_params'                => params.to_unsafe_h
        }
        Integration::Cardx::Event.new(data).delay(
          run_at:              Time.current,
          priority:            DelayedJob.job_priority('cardx_process_event'),
          queue:               DelayedJob.job_queue('cardx_process_event'),
          user_id:             0,
          contact_id:          params.dig(:pt_account_code_1) || 0,
          triggeraction_id:    0,
          contact_campaign_id: 0,
          group_process:       0,
          process:             'cardx_process_event',
          data:
        ).process

        head :no_content
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'user', session) && current_user.client.integrations_allowed.include?('cardx')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access CardX Integrations. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration
        return if (@client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'cardx', name: ''))

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration_from_uuid
        @client_api_integration = ClientApiIntegration.where(target: 'cardx', name: '').where("data->>'webhook_api_key' = ?", params[:webhook_api_key]).first
      end

      def webhook_source_validated?
        return false unless @client_api_integration
        return false if request.headers.exclude?(HTTP_REQUEST_HEADER_KEY)

        request.headers[HTTP_REQUEST_HEADER_KEY] == @client_api_integration.webhook_header_token
      end
    end
  end
end
