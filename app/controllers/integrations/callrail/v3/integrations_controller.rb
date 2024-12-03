# frozen_string_literal: true

# app/controllers/integrations/callrail/v3/integrations_controller.rb
module Integrations
  module Callrail
    module V3
      class IntegrationsController < ApplicationController
        skip_before_action :verify_authenticity_token, only: %i[endpoint]
        before_action :authenticate_user!, except: %i[endpoint]
        before_action :authorize_user!, except: %i[endpoint]
        before_action :client_api_integration, except: %i[endpoint]
        before_action :client_api_integration_from_uuid, only: %i[endpoint]

        def show
          respond_to do |format|
            format.js { render partial: 'integrations/callrail/v3/js/show', locals: { cards: %w[overview] } }
            format.html { render 'integrations/callrail/v3/show', locals: { partial_to_show: params.dig(:card).present? ? "integrations/callrail/v3/#{params[:card]}/index" : '' } }
            format.html { render 'integrations/callrail/v3/show' }
          end
        end

        # (POST) CallRail integration webhook endpoint
        # /integrations/callrail/v3/:webhook_api_key/endpoint
        # integrations_callrail_v3_endpoint_path
        # integrations_callrail_v3_endpoint_url
        def endpoint
          render plain: 'unauthorized', content_type: 'text/plain', layout: false, status: :unauthorized and return unless webhook_source_validated?

          sanitized_params = params_endpoint

          data = {
            'client_api_integration_id' => @client_api_integration.id,
            'company_id'                => sanitized_params[:company_resource_id],
            'type'                      => sanitized_params[:type] || 'inbound_post_call',
            'customer_phone_number'     => sanitized_params[:customer_phone_number]&.clean_phone(@client_api_integration.client.primary_area_code),
            'call_type'                 => sanitized_params[:call_type],
            'answered'                  => sanitized_params[:answered],
            'direction'                 => sanitized_params[:direction],
            'keywords'                  => sanitized_params[:keywords],
            'tracking_phone_number'     => sanitized_params[:tracking_phone_number]&.clean_phone(@client_api_integration.client.primary_area_code),
            'lead_status'               => sanitized_params[:lead_status],
            'source_name'               => sanitized_params[:source_name],
            'tags'                      => sanitized_params[:tags],
            'customer_name'             => sanitized_params[:customer_name],
            'customer_city'             => sanitized_params[:customer_city],
            'customer_state'            => sanitized_params[:customer_state],
            'customer_country'          => sanitized_params[:customer_country],
            'form_data'                 => sanitized_params[:form_data],
            'resource_id'               => sanitized_params[:resource_id],
            'raw_params'                => params.to_unsafe_h
          }
          Integrations::Callrail::V3::EventJob.perform_later(**data)

          head :no_content
        end

        private

        def authorize_user!
          super

          return if current_user.access_controller?('integrations', 'user', session) && current_user.client.integrations_allowed.include?('callrail')

          sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access CallRail Integrations. Please contact your account admin.', '', { persistent: 'OK' })

          respond_to do |format|
            format.js { render js: "window.location = '#{root_path}'" and return false }
            format.html { redirect_to root_path and return false }
          end
        end

        def client_api_integration
          return if (@client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'callrail', name: ''))

          respond_to do |format|
            format.js { render js: "window.location = '#{root_path}'" and return false }
            format.html { redirect_to root_path and return false }
          end
        end

        def client_api_integration_from_uuid
          @client_api_integration = ClientApiIntegration.where(target: 'callrail', name: '').where("data->>'webhook_api_key' = ?", params[:webhook_api_key]).first
        end

        def webhook_source_validated?
          return false if params.exclude?(:timestamp) || Time.zone.parse(params[:timestamp]) < 5.minutes.ago
          return false unless request.headers.include?('SIGNATURE')
          return false unless @client_api_integration

          calculated_hmac = Base64.strict_encode64(
            OpenSSL::HMAC.digest(
              'sha1',
              @client_api_integration.credentials['webhook_signature_token'],
              request.body.read
            )
          )

          ActiveSupport::SecurityUtils.secure_compare(
            calculated_hmac,
            request.headers['SIGNATURE']
          )
        end

        def params_endpoint
          params.permit(:company_resource_id, :customer_phone_number, :type, :call_type, :direction, :keywords, :answered, :tracking_phone_number, :lead_status, :resource_id, :source_name, :customer_name, :customer_city, :customer_state, :customer_country, tags: [], form_data: {})
        end
      end
    end
  end
end
