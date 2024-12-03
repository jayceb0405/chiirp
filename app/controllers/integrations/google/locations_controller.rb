# frozen_string_literal: true

# app/controllers/integrations/google/locations_controller.rb
module Integrations
  module Google
    class LocationsController < Google::IntegrationsController
      before_action :primary_user_api_integration, only: %i[update]
      before_action :authorize_user_for_accounts_locations_config!
      # (GET) show Google locations to select from
      # /integrations/google/locations
      # integrations_google_locations_path
      # integrations_google_locations_url
      def show
        render partial: 'integrations/google/js/show', locals: { cards: %w[locations_show] }
      end

      # (PUT/PATCH) save Google locations selections
      # /integrations/google/locations
      # integrations_google_locations_path
      # integrations_google_locations_url
      def update
        if current_user.access_controller?('integrations', 'google_messages', session)
          sanitized_params = params_locations_messages
          @client_api_integration.active_locations_messages = unlaunch_locations_messages(@client_api_integration.active_locations_messages, sanitized_params)
          @client_api_integration.active_locations_messages = add_locations_messages(@client_api_integration.active_locations_messages, sanitized_params)
        end

        if current_user.access_controller?('integrations', 'google_reviews', session)
          sanitized_params = params_locations_reviews
          @client_api_integration.active_locations_reviews  = remove_locations_reviews(@client_api_integration.active_locations_reviews, sanitized_params)
          @client_api_integration.active_locations_reviews  = add_locations_reviews(@client_api_integration.active_locations_reviews, sanitized_params)
        end

        @client_api_integration.active_locations_names = params_locations_names

        @client_api_integration.save

        render partial: 'integrations/google/js/show', locals: { cards: %w[locations_show] }
      end
      # ex: active_locations_messages
      # {
      #   "account_id" => {
      #     "location_id"   => {
      #       "verified"    => Boolean,
      #       "brand_id"    => String,
      #       "agent_id"    => String,
      #       "location_id" => String
      #     }
      #   }
      # }
      #
      # ex: active_locations_reviews
      # {
      #   "account_id" => [
      #     location_id (String),
      #     ...
      #   ]
      # }

      private

      def add_locations_messages(active_locations, new_active_locations)
        JsonLog.info 'Integrations::Google::LocationsController.add_locations_messages', { active_locations:, new_active_locations: }
        active_locations = {} if active_locations.nil?
        return active_locations unless @primary_user_api_integration

        ggl_client = Integrations::Ggl::Base.new(@primary_user_api_integration.token, @client_api_integration.client.tenant)

        new_active_locations&.each do |account_id, locations|
          locations&.each do |location_id|
            if active_locations.dig(account_id)

              if active_locations[account_id].dig(location_id).present?

                if active_locations[account_id][location_id].dig('agent_id').present?
                  ggl_client.business_messages_launch_agent(active_locations[account_id][location_id]['agent_id']) unless ggl_client.business_messages_launched_agent(active_locations[account_id][location_id]['agent_id'])&.dig(:businessMessages, :launchDetails, :LOCATION, :launchState)&.casecmp?('LAUNCH_STATE_LAUNCHED')
                  active_locations[account_id][location_id]['agent_launched'] = true
                end

                if active_locations[account_id][location_id].dig('location_id').present?
                  ggl_client.business_messages_launch_location(active_locations[account_id][location_id]['location_id']) unless ggl_client.business_messages_launched_location(active_locations[account_id][location_id]['location_id'])&.dig(:launchState)&.casecmp?('LAUNCH_STATE_LAUNCHED')
                  active_locations[account_id][location_id]['location_launched'] = true
                end
              else
                active_locations[account_id][location_id] = {}
                result = Integration::Google.create_brand(@client_api_integration, account_id, location_id)
                JsonLog.info 'Integrations::Google::LocationsController.add_locations_messages', { result: }

                sweetalert_error('Google Brand Creation Failed!', result[:message], '', { persistent: 'OK' }) unless result[:success]
              end
            else
              active_locations[account_id] = { location_id => {} }
              result = Integration::Google.create_brand(@client_api_integration, account_id, location_id)
              JsonLog.info 'Integrations::Google::LocationsController.add_locations_messages', { result: }

              sweetalert_error('Google Brand Creation Failed!', result[:message], '', { persistent: 'OK' }) unless result[:success]
            end
          end
        end

        active_locations
      end

      def add_locations_reviews(active_locations, new_active_locations)
        active_locations = {} if active_locations.nil?

        new_active_locations&.each do |account_id, locations|
          locations&.each do |location_id|
            unless active_locations.dig(account_id)&.include?(location_id)

              if active_locations.dig(account_id)
                active_locations[account_id] << location_id
              else
                active_locations[account_id]  = [location_id]
              end

              load_reviews(account_id, location_id)
            end
          end
        end

        active_locations
      end

      def load_reviews(account_id, location_id)
        Integration::Google.delay(
          run_at:              Time.current,
          priority:            DelayedJob.job_priority('google_reviews_load'),
          queue:               DelayedJob.job_queue('google_reviews_load'),
          user_id:             @client_api_integration.user_id,
          contact_id:          0,
          triggeraction_id:    0,
          contact_campaign_id: 0,
          group_process:       1,
          process:             'google_reviews_load',
          data:                { client_api_integration: @client_api_integration, account_id:, location_id:, start_date: Chronic.parse('1/1/2000') }
        ).load_reviews(@client_api_integration, account_id, location_id, Chronic.parse('1/1/2000'))
      end

      def unlaunch_locations_messages(active_locations, new_active_locations)
        JsonLog.info 'Integrations::Google::LocationsController.unlaunch_locations_messages', { active_locations:, new_active_locations: }
        return active_locations unless @primary_user_api_integration

        ggl_client = Integrations::Ggl::Base.new(@primary_user_api_integration.token, @client_api_integration.client.tenant)

        active_locations&.each do |account_id, locations|
          locations&.each do |location_id, config|
            unless new_active_locations&.dig(account_id)&.include?(location_id)

              if config.dig('agent_id').present?
                ggl_client.business_messages_unlaunch_agent(config['agent_id']) if ggl_client.business_messages_launched_agent(config['agent_id'])&.dig(:businessMessages, :launchDetails, :LOCATION, :launchState)&.casecmp?('LAUNCH_STATE_LAUNCHED')
                active_locations[account_id][location_id]['agent_launched'] = false
              end

              if config.dig('location_id').present?
                ggl_client.business_messages_unlaunch_location(config['location_id']) if ggl_client.business_messages_launched_location(config['location_id'])&.dig(:launchState)&.casecmp?('LAUNCH_STATE_LAUNCHED')
                active_locations[account_id][location_id]['location_launched'] = false
              end
            end
          end
        end

        active_locations
      end

      def remove_locations_reviews(active_locations, new_active_locations)
        active_locations&.each do |account_id, locations|
          locations&.each do |location_id|
            unless new_active_locations&.dig(account_id)&.include?(location_id)
              active_locations[account_id].delete(location_id)
              Review.where(account: account_id, location: location_id).destroy_all

              @client_api_integration.reviews_links&.dig(account_id)&.except!(location_id)
            end
          end
        end

        active_locations
      end

      def params_locations_messages
        sanitized_params = params.require(:messages).permit(locations: {})

        sanitized_params.dig(:locations).each do |account, _locations|
          sanitized_params[:locations][account] = sanitized_params[:locations][account].compact_blank
        end

        sanitized_params[:locations]&.compact_blank || {}
      end

      def params_locations_names
        params.permit(locations_names: {}).dig(:locations_names).to_h
      end

      def params_locations_reviews
        sanitized_params = params.require(:reviews).permit(locations: {})

        sanitized_params.dig(:locations).each do |account, _locations|
          sanitized_params[:locations][account] = sanitized_params[:locations][account].compact_blank
        end

        sanitized_params[:locations]&.compact_blank || {}
      end
    end
  end
end
