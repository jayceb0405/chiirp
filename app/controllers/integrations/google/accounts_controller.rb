# frozen_string_literal: true

# app/controllers/integrations/google/accounts_controller.rb
module Integrations
  module Google
    class AccountsController < Google::IntegrationsController
      before_action :primary_user_api_integration, only: %i[update]
      before_action :authorize_user_for_accounts_locations_config!
      # (GET) show Google accounts to select from
      # /integrations/google/accounts
      # integrations_google_accounts_path
      # integrations_google_accounts_url
      def show
        render partial: 'integrations/google/js/show', locals: { cards: %w[accounts_show] }
      end

      # (PUT/PATCH) save Google account selections
      # /integrations/google/accounts
      # integrations_google_accounts_path
      # integrations_google_accounts_url
      def update
        @client_api_integration.update(user_id: (@client_api_integration.user_id.to_i.positive? ? @client_api_integration.user_id : current_user.id), active_accounts: params_accounts)

        validate_locations
        @client_api_integration.save

        render partial: 'integrations/google/js/show', locals: { cards: %w[accounts_show] }
      end

      private

      def params_accounts
        sanitized_params = params.permit(active_accounts: [])

        sanitized_params.dig(:active_accounts)&.compact_blank || []
      end

      def validate_locations
        ggl_client = Integrations::Ggl::Base.new(@primary_user_api_integration&.token, I18n.t('tenant.id'))

        @client_api_integration.active_locations_messages.each do |account_id, locations|
          unless @client_api_integration.active_accounts.include?(account_id)

            locations.each do |location_id, config|
              if config.dig('agent_id').present?
                ggl_client.business_messages_unlaunch_agent(config['agent_id']) if ggl_client.business_messages_launched_agent(config['agent_id'])&.dig(:businessMessages, :launchDetails, :LOCATION, :launchState)&.casecmp?('LAUNCH_STATE_LAUNCHED')
                @client_api_integration.active_locations_messages[account_id][location_id]['agent_launched'] = false
              end

              if config.dig('location_id').present?
                ggl_client.business_messages_unlaunch_location(config['location_id']) if ggl_client.business_messages_launched_location(config['location_id'])&.dig(:launchState)&.casecmp?('LAUNCH_STATE_LAUNCHED')
                @client_api_integration.active_locations_messages[account_id][location_id]['location_launched'] = false
              end
            end

            @client_api_integration.active_locations_reviews.except!(account_id)
          end
        end

        @client_api_integration.active_locations_reviews.slice!(@client_api_integration.active_accounts.join(','))
        @client_api_integration.active_accounts.each do |account|
          @client_api_integration.active_locations_messages.merge({ account => {} }) unless @client_api_integration.active_locations_messages.key?(account)
          @client_api_integration.active_locations_reviews.merge({ account => {} }) unless @client_api_integration.active_locations_reviews.key?(account)
        end
      end
    end
  end
end
