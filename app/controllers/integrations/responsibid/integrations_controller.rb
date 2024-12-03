# frozen_string_literal: true

# app/controllers/integrations/responsibid/integrations_controller.rb
module Integrations
  module Responsibid
    # Support for all general ResponsiBid integration endpoints used with Chiirp
    class IntegrationsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: %i[webhook]
      before_action :authenticate_user!, except: %i[webhook]
      before_action :authorize_user!, except: %i[webhook]
      before_action :client_api_integration, except: %i[webhook]
      before_action :client_api_integration_from_api_key, only: %i[webhook]

      # (POST) webhook from ResponsiBid
      # /integrations/responsibid/endpoint/:api_key
      # integrations_responsibid_endpoint_path(:api_key)
      # integrations_responsibid_endpoint_url(:api_key)
      def webhook
        rb_client = Integrations::ResponsiBid.new
        parsed_webhook = rb_client.parse_webhook(params.to_unsafe_hash)

        if rb_client.success?
          api_key = params.permit(:api_key).dig(:api_key).to_s

          Integrations::Responsibid::EventProcessJob.set(wait_until: 30.seconds.from_now).perform_later(
            client_api_integration_id: @client_api_integration.id,
            client_id:                 @client_api_integration.client_id,
            event_id:                  @client_api_integration.api_key == api_key ? nil : api_key,
            parsed_webhook:,
            raw_params:                params.to_unsafe_hash.except(:integration)
          )
        end

        respond_to do |format|
          format.json { render json: { status: 200, message: 'Success' } }
          format.html { render plain: 'Success', content_type: 'text/plain', layout: false, status: :ok }
        end
      end

      # (GET) show ResponsiBid integration
      # /integrations/responsibid
      # integrations_responsibid_path
      # integrations_responsibid_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/responsibid/js/show', locals: { cards: %w[overview] } }
          format.html { render 'integrations/responsibid/show' }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'client', session) && current_user.client.integrations_allowed.include?('responsibid')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access ResponsiBid Integrations. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration
        return if (@client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'responsibid', name: ''))

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration_from_api_key
        api_key = params.permit(:api_key).dig(:api_key).to_s
        return if api_key.present? && ((@client_api_integration = ClientApiIntegration.find_by(target: 'responsibid', name: '', api_key:)) ||
        (@client_api_integration = ClientApiIntegration.where(target: 'responsibid', name: '').where('data::text ILIKE ?', "%#{api_key}%").first))

        respond_to do |format|
          format.json { render json: { status: 404, message: 'Company not found.' } and return }
          format.html { render plain: 'Company not found.', content_type: 'text/plain', layout: false, status: :not_found and return }
        end
      end
    end
  end
end
