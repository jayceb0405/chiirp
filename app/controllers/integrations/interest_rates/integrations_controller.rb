# frozen_string_literal: true

# app/controllers/integrations/interest_rates/integrations_controller.rb
module Integrations
  module InterestRates
    # endpoints supporting Interest Rates integrations
    class IntegrationsController < ApplicationController
      before_action :authenticate_user!
      before_action :authorize_user!
      before_action :client
      before_action :client_api_integration

      # (GET) edit interest rate integration
      # /integrations/interest_rates/integration/edit
      # edit_integrations_interest_rates_integration_path
      # edit_integrations_interest_rates_integration_url
      def edit
        respond_to do |format|
          format.js { render partial: 'integrations/interest_rates/js/show', locals: { cards: %w[form] } }
          format.html { render 'integrations/interest_rates/edit' }
        end
      end

      # (GET)
      # /integrations/interest_rates/integration/instructions
      # integrations_interest_rates_integration_instructions_path
      # integrations_interest_rates_integration_instructions_url
      def instructions
        respond_to do |format|
          format.js { render partial: 'integrations/interest_rates/js/show', locals: { cards: %w[instructions] } }
          format.html { render 'integrations/interest_rates/edit' }
        end
      end

      # (PUT/PATCH) update interest rate integration
      # /integrations/interest_rates/integration
      # integrations_interest_rates_integration_path
      # integrations_interest_rates_integration_url
      def update
        @client_api_integration.update(client_api_integration_params)

        respond_to do |format|
          format.js { render partial: 'integrations/interest_rates/js/show', locals: { cards: %w[form] } }
          format.html { render 'integrations/interest_rates/edit' }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'client', session) && current_user.client.integrations_allowed.include?('interest_rates')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access Interest Rates Integrations. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration_params
        response = params.require(:client_api_integration).permit(:custom_field_id, :differential, :mortgage_rate_type_id, :campaign_id, :group_id, :stage_id, :tag_id, stop_campaign_ids: [])

        response[:custom_field_id]   = response[:custom_field_id].to_i if response.include?(:custom_field_id)
        response[:differential]      = response[:differential].to_d if response.include?(:differential)
        response[:campaign_id]       = response[:campaign_id].to_i if response.include?(:campaign_id)
        response[:group_id]          = response[:group_id].to_i if response.include?(:group_id)
        response[:stage_id]          = response[:stage_id].to_i if response.include?(:stage_id)
        response[:tag_id]            = response[:tag_id].to_i if response.include?(:tag_id)
        response[:stop_campaign_ids] = response[:stop_campaign_ids].compact_blank if response.include?(:stop_campaign_ids)
        response[:stop_campaign_ids] = [0] if response.dig(:stop_campaign_ids)&.include?('0')

        response
      end

      def client
        return if (@client = current_user.client)

        sweetalert_error('Client NOT found!', 'We were not able to access the Client you requested.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration
        @client_api_integration = @client.client_api_integrations.find_or_create_by(target: 'interest_rates', name: '')
      end
    end
  end
end
